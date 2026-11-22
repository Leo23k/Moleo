package main

import (
	"container/heap"
	"crypto/sha256"
	"errors"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	wruntime "github.com/wailsapp/wails/v2/pkg/runtime"
)

type BigFile struct {
	Path     string    `json:"path"`
	Name     string    `json:"name"`
	Size     int64     `json:"size"`
	Modified time.Time `json:"modified"`
	Warn     string    `json:"warn"`
	Kind     string    `json:"kind"`
}

var skipNames = map[string]bool{"pagefile.sys": true, "hiberfil.sys": true, "swapfile.sys": true, "dumpstack.log.tmp": true}

// walkFiles visits every regular file under root in parallel, never
// following links. visit must be safe for concurrent use.
func walkFiles(root string, cancel *atomic.Bool, visit func(path string, d fs.DirEntry, info fs.FileInfo)) {
	sem := make(chan struct{}, runtime.NumCPU()*4)
	var wg sync.WaitGroup
	var walk func(dir string)
	walk = func(dir string) {
		if cancel.Load() {
			return
		}
		entries, err := os.ReadDir(dir)
		if err != nil {
			return
		}
		for _, e := range entries {
			t := e.Type()
			if t&fs.ModeSymlink != 0 || t&fs.ModeIrregular != 0 {
				continue
			}
			p := filepath.Join(dir, e.Name())
			if e.IsDir() {
				select {
				case sem <- struct{}{}:
					wg.Add(1)
					go func() { defer wg.Done(); walk(p); <-sem }()
				default:
					walk(p)
				}
				continue
			}
			if info, err := e.Info(); err == nil {
				visit(p, e, info)
			}
		}
	}
	walk(root)
	wg.Wait()
}

type bigHeap []BigFile

func (h bigHeap) Len() int           { return len(h) }
func (h bigHeap) Less(i, j int) bool { return h[i].Size < h[j].Size }
func (h bigHeap) Swap(i, j int)      { h[i], h[j] = h[j], h[i] }
func (h *bigHeap) Push(x any)        { *h = append(*h, x.(BigFile)) }
func (h *bigHeap) Pop() any          { o := *h; x := o[len(o)-1]; *h = o[:len(o)-1]; return x }

func fileKind(name string) string {
	switch strings.ToLower(filepath.Ext(name)) {
	case ".iso", ".img", ".vhd", ".vhdx", ".vmdk", ".qcow2":
		return "disk image"
	case ".exe", ".msi", ".msix", ".appx":
		return "installer"
	case ".zip", ".7z", ".rar", ".tar", ".gz", ".xz", ".zst":
		return "archive"
	case ".mp4", ".mkv", ".mov", ".avi", ".webm", ".wmv":
		return "video"
	case ".bak", ".old", ".tmp", ".dmp", ".log", ".etl":
		return "temporary"
	}
	return ""
}

// FindLargeFiles returns the biggest files under root (at least minMB),
// emitting "files:progress" (files checked, current folder).
func (a *App) FindLargeFiles(root string, minMB int, limit int) ([]BigFile, error) {
	if fi, err := os.Stat(root); err != nil || !fi.IsDir() {
		return nil, errors.New("not a folder: " + root)
	}
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	min := int64(minMB) << 20
	a.filesCancel.Store(false)
	var mu sync.Mutex
	h := &bigHeap{}
	var count atomic.Int64
	stop := a.progressTicker("files:progress", &count)
	walkFiles(root, &a.filesCancel, func(p string, d fs.DirEntry, info fs.FileInfo) {
		count.Add(1)
		if info.Size() < min || skipNames[strings.ToLower(d.Name())] {
			return
		}
		mu.Lock()
		if h.Len() < limit {
			heap.Push(h, BigFile{Path: p, Size: info.Size(), Modified: info.ModTime()})
		} else if (*h)[0].Size < info.Size() {
			(*h)[0] = BigFile{Path: p, Size: info.Size(), Modified: info.ModTime()}
			heap.Fix(h, 0)
		}
		mu.Unlock()
	})
	stop()
	if a.filesCancel.Load() {
		return nil, errors.New("cancelled")
	}
	out := []BigFile(*h)
	for i := range out {
		out[i].Name = filepath.Base(out[i].Path)
		out[i].Warn = pathWarning(out[i].Path)
		out[i].Kind = fileKind(out[i].Name)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Size > out[j].Size })
	return out, nil
}

func (a *App) CancelFiles() { a.filesCancel.Store(true) }

func (a *App) progressTicker(event string, count *atomic.Int64) func() {
	done := make(chan struct{})
	go func() {
		t := time.NewTicker(200 * time.Millisecond)
		defer t.Stop()
		for {
			select {
			case <-done:
				return
			case <-t.C:
				if a.ctx != nil {
					wruntime.EventsEmit(a.ctx, event, count.Load())
				}
			}
		}
	}()
	return func() { close(done) }
}

// RecycleFiles moves files (not folders) to the Recycle Bin.
func (a *App) RecycleFiles(paths []string) error {
	for _, p := range paths {
		if !isRegularFile(p) {
			return errors.New("not a file: " + p)
		}
	}
	return recycle(paths)
}

// ---- duplicates --------------------------------------------------------

type DupGroup struct {
	Size  int64     `json:"size"`
	Files []BigFile `json:"files"`
	Waste int64     `json:"waste"`
}

func hashFile(p string, limit int64) (string, error) {
	f, err := os.Open(p)
	if err != nil {
		return "", err
	}
	defer f.Close()
	h := sha256.New()
	var r io.Reader = f
	if limit > 0 {
		r = io.LimitReader(f, limit)
	}
	if _, err := io.Copy(h, r); err != nil {
		return "", err
	}
	return string(h.Sum(nil)), nil
}

// FindDuplicates groups files under roots with identical content
// (same size, then same first 64 KB, then same full SHA-256).
func (a *App) FindDuplicates(roots []string, minKB int) ([]DupGroup, error) {
	if len(roots) == 0 {
		return nil, errors.New("choose a folder")
	}
	min := int64(minKB) << 10
	if min < 1 {
		min = 1
	}
	a.filesCancel.Store(false)
	var count atomic.Int64
	stop := a.progressTicker("files:progress", &count)
	defer stop()

	var mu sync.Mutex
	bySize := map[int64][]BigFile{}
	seen := map[string]bool{}
	appdata := strings.ToLower(filepath.Join(os.Getenv("USERPROFILE"), "AppData"))
	for _, root := range roots {
		// Skip AppData unless the user chose a folder inside it.
		skipAppdata := !strings.HasPrefix(strings.ToLower(filepath.Clean(root))+`\`, appdata+`\`)
		walkFiles(root, &a.filesCancel, func(p string, d fs.DirEntry, info fs.FileInfo) {
			count.Add(1)
			lp := strings.ToLower(p)
			if info.Size() < min || (skipAppdata && strings.HasPrefix(lp, appdata+`\`)) || strings.Contains(lp, `\.git\`) || strings.Contains(lp, `\node_modules\`) {
				return
			}
			mu.Lock()
			if !seen[lp] {
				seen[lp] = true
				bySize[info.Size()] = append(bySize[info.Size()], BigFile{Path: p, Name: d.Name(), Size: info.Size(), Modified: info.ModTime()})
			}
			mu.Unlock()
		})
	}
	if a.filesCancel.Load() {
		return nil, errors.New("cancelled")
	}

	// Hash candidates in parallel, first a 64 KB prefix, then the whole file.
	type job struct{ files []BigFile }
	var jobs []job
	for _, fs := range bySize {
		if len(fs) > 1 {
			jobs = append(jobs, job{fs})
		}
	}
	var groups []DupGroup
	var gmu sync.Mutex
	var wg sync.WaitGroup
	sem := make(chan struct{}, runtime.NumCPU())
	split := func(files []BigFile, limit int64) [][]BigFile {
		m := map[string][]BigFile{}
		for _, f := range files {
			if a.filesCancel.Load() {
				return nil
			}
			h, err := hashFile(f.Path, limit)
			if err != nil {
				continue
			}
			m[h] = append(m[h], f)
		}
		var out [][]BigFile
		for _, v := range m {
			if len(v) > 1 {
				out = append(out, v)
			}
		}
		return out
	}
	for _, j := range jobs {
		wg.Add(1)
		sem <- struct{}{}
		go func(files []BigFile) {
			defer wg.Done()
			defer func() { <-sem }()
			for _, part := range split(files, 64<<10) {
				full := [][]BigFile{part}
				if part[0].Size > 64<<10 {
					full = split(part, 0)
				}
				for _, g := range full {
					sort.Slice(g, func(i, k int) bool { return g[i].Modified.Before(g[k].Modified) })
					for i := range g {
						g[i].Warn = pathWarning(g[i].Path)
					}
					gmu.Lock()
					groups = append(groups, DupGroup{Size: g[0].Size, Files: g, Waste: g[0].Size * int64(len(g)-1)})
					gmu.Unlock()
				}
			}
		}(j.files)
	}
	wg.Wait()
	if a.filesCancel.Load() {
		return nil, errors.New("cancelled")
	}
	sort.Slice(groups, func(i, j int) bool { return groups[i].Waste > groups[j].Waste })
	if len(groups) > 500 {
		groups = groups[:500]
	}
	return groups, nil
}

// HomeDir is the user's profile folder.
func (a *App) HomeDir() string { return os.Getenv("USERPROFILE") }
