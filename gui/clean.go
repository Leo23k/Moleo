package main

import (
	"encoding/binary"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"sync"
	"time"
	"unicode/utf16"

	"github.com/wailsapp/wails/v2/pkg/runtime"
	"golang.org/x/sys/windows"
)

type CleanEntry struct {
	ID       string   `json:"id"`
	Category string   `json:"category"`
	Name     string   `json:"name"`
	Path     string   `json:"path"`
	Bytes    int64    `json:"bytes"`
	Files    int      `json:"files"`
	roots    []string // existing roots to clear
	minAge   int
	binFiles []string // Recycle Bin: $R and $I files
}

type CleanScan struct {
	Categories []category    `json:"categories"`
	Entries    []*CleanEntry `json:"entries"`
	Locations  int           `json:"locations"`
	Bytes      int64         `json:"bytes"`
}

type CleanResult struct {
	RemovedBytes int64    `json:"removedBytes"`
	RemovedFiles int      `json:"removedFiles"`
	Skipped      int      `json:"skipped"`
	Errors       []string `json:"errors"`
}

var envPattern = regexp.MustCompile(`%([^%]+)%|\$\{([^}]+)\}`)

func expandEnv(p string) (string, bool) {
	ok := true
	out := envPattern.ReplaceAllStringFunc(p, func(m string) string {
		name := strings.Trim(m, "%${}")
		v := os.Getenv(name)
		if v == "" {
			ok = false
		}
		return v
	})
	return out, ok
}

// isSafeRoot refuses drive roots, Windows itself, user folders and
// anything that is a link, so a bad catalog entry cannot do harm.
func isSafeRoot(p string) bool {
	clean := filepath.Clean(p)
	if len(clean) < 8 || filepath.VolumeName(clean)+`\` == clean {
		return false
	}
	lower := strings.ToLower(clean)
	for _, env := range []string{"USERPROFILE", "SystemRoot", "ProgramFiles", "ProgramFiles(x86)", "ProgramData", "APPDATA", "LOCALAPPDATA"} {
		if v := os.Getenv(env); v != "" && strings.EqualFold(filepath.Clean(v), clean) {
			return false
		}
	}
	for _, bad := range []string{`\documents`, `\desktop`, `\pictures`, `\videos`, `\music`, `\downloads`, `\onedrive`} {
		if strings.HasSuffix(lower, bad) {
			return false
		}
	}
	if fi, err := os.Lstat(clean); err != nil || fi.Mode()&fs.ModeSymlink != 0 || fi.Mode()&fs.ModeIrregular != 0 {
		return false
	}
	return true
}

func isLink(d fs.DirEntry) bool {
	t := d.Type()
	return t&fs.ModeSymlink != 0 || t&fs.ModeIrregular != 0 // junctions show as irregular
}

func measure(root string, minAge int) (int64, int) {
	var size int64
	files := 0
	cutoff := time.Now().Add(-time.Duration(minAge) * time.Hour)
	fi, err := os.Lstat(root)
	if err != nil {
		return 0, 0
	}
	if !fi.IsDir() {
		if minAge == 0 || fi.ModTime().Before(cutoff) {
			return fi.Size(), 1
		}
		return 0, 0
	}
	filepath.WalkDir(root, func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil
		}
		if isLink(d) {
			if d.IsDir() {
				return filepath.SkipDir
			}
			return nil
		}
		if d.IsDir() {
			return nil
		}
		if info, e := d.Info(); e == nil && (minAge == 0 || info.ModTime().Before(cutoff)) {
			size += info.Size()
			files++
		}
		return nil
	})
	return size, files
}

func (a *App) ScanClean() (*CleanScan, error) {
	all := allTargets()
	entries := make([]*CleanEntry, len(all))
	var wg sync.WaitGroup
	sem := make(chan struct{}, 16)
	var done int32
	var dmu sync.Mutex
	for i, t := range all {
		wg.Add(1)
		go func(i int, t target) {
			defer wg.Done()
			sem <- struct{}{}
			defer func() {
				<-sem
				dmu.Lock()
				done++
				n := done
				dmu.Unlock()
				if a.ctx != nil {
					runtime.EventsEmit(a.ctx, "clean:progress", n, len(all), t.Name)
				}
			}()
			e := &CleanEntry{ID: fmt.Sprintf("t%d", i), Category: t.Category, Name: t.Name, minAge: t.MinAge}
			seen := map[string]bool{}
			for _, raw := range t.Paths {
				p, ok := expandEnv(raw)
				if !ok {
					continue
				}
				matches := []string{p}
				if strings.ContainsAny(p, "*?") {
					matches, _ = filepath.Glob(p)
				}
				for _, m := range matches {
					key := strings.ToLower(m)
					if seen[key] || !isSafeRoot(m) {
						continue
					}
					seen[key] = true
					b, f := measure(m, t.MinAge)
					if f == 0 {
						continue
					}
					e.roots = append(e.roots, m)
					e.Bytes += b
					e.Files += f
				}
			}
			if len(e.roots) > 0 {
				e.Path = e.roots[0]
				if len(e.roots) > 1 {
					e.Path += fmt.Sprintf("  (+%d more)", len(e.roots)-1)
				}
				entries[i] = e
			}
		}(i, t)
	}
	wg.Wait()

	scan := &CleanScan{Categories: categories, Locations: catalogLocationCount()}
	for _, e := range entries {
		if e != nil {
			scan.Entries = append(scan.Entries, e)
		}
	}
	scan.Entries = append(scan.Entries, scanRecycleBin()...)
	// Drop duplicates: a root claimed by an earlier entry is not counted twice.
	claimed := map[string]bool{}
	var kept []*CleanEntry
	for _, e := range scan.Entries {
		if len(e.roots) == 1 && claimed[strings.ToLower(e.roots[0])] {
			continue
		}
		for _, r := range e.roots {
			claimed[strings.ToLower(r)] = true
		}
		kept = append(kept, e)
		scan.Bytes += e.Bytes
	}
	scan.Entries = kept
	sort.SliceStable(scan.Entries, func(i, j int) bool {
		if scan.Entries[i].Category != scan.Entries[j].Category {
			return false
		}
		return scan.Entries[i].Bytes > scan.Entries[j].Bytes
	})
	a.mu.Lock()
	a.cleanEntries = map[string]*CleanEntry{}
	for _, e := range scan.Entries {
		a.cleanEntries[e.ID] = e
	}
	a.mu.Unlock()
	return scan, nil
}

// clearRoot deletes the contents of root (or root itself when it is a file).
// Locked files are skipped; links are never followed.
func clearRoot(root string, minAge int, res *CleanResult) {
	cutoff := time.Now().Add(-time.Duration(minAge) * time.Hour)
	fi, err := os.Lstat(root)
	if err != nil {
		return
	}
	if !fi.IsDir() {
		if minAge == 0 || fi.ModTime().Before(cutoff) {
			if os.Remove(root) == nil {
				res.RemovedBytes += fi.Size()
				res.RemovedFiles++
			} else {
				res.Skipped++
			}
		}
		return
	}
	var dirs []string
	filepath.WalkDir(root, func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil
		}
		if isLink(d) {
			if p != root && os.Remove(p) != nil { // remove the link itself, never its target
				res.Skipped++
			}
			if d.IsDir() {
				return filepath.SkipDir
			}
			return nil
		}
		if d.IsDir() {
			if p != root {
				dirs = append(dirs, p)
			}
			return nil
		}
		info, e := d.Info()
		if e != nil || (minAge > 0 && !info.ModTime().Before(cutoff)) {
			return nil
		}
		if err := os.Remove(p); err != nil {
			_ = os.Chmod(p, 0666) // clear read-only and retry once
			if os.Remove(p) != nil {
				res.Skipped++
				return nil
			}
		}
		res.RemovedBytes += info.Size()
		res.RemovedFiles++
		return nil
	})
	for i := len(dirs) - 1; i >= 0; i-- {
		_ = os.Remove(dirs[i]) // only succeeds when empty
	}
}

func (a *App) RunClean(ids []string) (*CleanResult, error) {
	a.mu.Lock()
	entries := a.cleanEntries
	a.cleanEntries = nil
	a.mu.Unlock()
	if entries == nil {
		return nil, errors.New("scan results expired, scan again")
	}
	res := &CleanResult{}
	for _, id := range ids {
		e := entries[id]
		if e == nil {
			continue
		}
		if len(e.binFiles) > 0 {
			for _, f := range e.binFiles {
				b, n := measure(f, 0)
				if err := os.RemoveAll(f); err != nil {
					res.Skipped++
					res.Errors = append(res.Errors, err.Error())
				} else {
					res.RemovedBytes += b
					res.RemovedFiles += n
				}
			}
			continue
		}
		for _, r := range e.roots {
			if isSafeRoot(r) {
				clearRoot(r, e.minAge, res)
			}
		}
	}
	return res, nil
}

// ---- Recycle Bin -------------------------------------------------------

type binItem struct {
	Original string
	Deleted  time.Time
	Size     int64
	RPath    string
	IPath    string
}

func currentUserSID() string {
	tok := windows.GetCurrentProcessToken()
	u, err := tok.GetTokenUser()
	if err != nil {
		return ""
	}
	return u.User.Sid.String()
}

// parseInfo2 reads a $I file (Vista+ formats 1 and 2).
func parseInfo2(path string) (orig string, size int64, deleted time.Time, ok bool) {
	b, err := os.ReadFile(path)
	if err != nil || len(b) < 24 {
		return
	}
	ver := binary.LittleEndian.Uint64(b[0:8])
	size = int64(binary.LittleEndian.Uint64(b[8:16]))
	ft := windows.Filetime{LowDateTime: binary.LittleEndian.Uint32(b[16:20]), HighDateTime: binary.LittleEndian.Uint32(b[20:24])}
	deleted = time.Unix(0, ft.Nanoseconds())
	var u []uint16
	switch ver {
	case 1:
		for i := 24; i+1 < len(b) && i < 24+520; i += 2 {
			u = append(u, binary.LittleEndian.Uint16(b[i:]))
		}
	case 2:
		if len(b) < 28 {
			return
		}
		n := int(binary.LittleEndian.Uint32(b[24:28]))
		for i := 0; i < n && 28+i*2+1 < len(b); i++ {
			u = append(u, binary.LittleEndian.Uint16(b[28+i*2:]))
		}
	default:
		return
	}
	orig = strings.TrimRight(string(utf16.Decode(u)), "\x00")
	return orig, size, deleted, true
}

func listRecycleBin() []binItem {
	sid := currentUserSID()
	if sid == "" {
		return nil
	}
	var items []binItem
	drives, _ := windows.GetLogicalDrives()
	for i := 0; i < 26; i++ {
		if drives&(1<<uint(i)) == 0 {
			continue
		}
		dir := fmt.Sprintf(`%c:\$Recycle.Bin\%s`, 'A'+i, sid)
		infos, _ := filepath.Glob(filepath.Join(dir, `$I*`))
		for _, ip := range infos {
			orig, size, del, ok := parseInfo2(ip)
			if !ok {
				continue
			}
			rp := filepath.Join(dir, `$R`+filepath.Base(ip)[2:])
			if _, err := os.Lstat(rp); err != nil {
				continue
			}
			items = append(items, binItem{orig, del, size, rp, ip})
		}
	}
	sort.Slice(items, func(i, j int) bool { return items[i].Size > items[j].Size })
	return items
}

func scanRecycleBin() []*CleanEntry {
	var out []*CleanEntry
	for i, it := range listRecycleBin() {
		out = append(out, &CleanEntry{
			ID: fmt.Sprintf("bin%d", i), Category: "bin",
			Name: filepath.Base(it.Original), Path: it.Original,
			Bytes: it.Size, Files: 1, binFiles: []string{it.RPath, it.IPath},
		})
	}
	return out
}
