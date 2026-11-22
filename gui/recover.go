package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"

	wruntime "github.com/wailsapp/wails/v2/pkg/runtime"
)

// Recovery never deletes or overwrites: restores go to the original path
// only when it is free, and everything else is copied to a folder the
// user picks.

// ---- Recycle Bin restore -----------------------------------------------

type BinEntry struct {
	ID       string    `json:"id"`
	Name     string    `json:"name"`
	Original string    `json:"original"`
	Deleted  time.Time `json:"deleted"`
	Size     int64     `json:"size"`
	IsDir    bool      `json:"isDir"`
}

func (a *App) ListBin() []BinEntry {
	items := listRecycleBin()
	out := make([]BinEntry, 0, len(items))
	a.mu.Lock()
	a.binItems = map[string]binItem{}
	for i, it := range items {
		id := fmt.Sprintf("b%d", i)
		a.binItems[id] = it
		fi, _ := os.Lstat(it.RPath)
		out = append(out, BinEntry{ID: id, Name: filepath.Base(it.Original), Original: it.Original,
			Deleted: it.Deleted, Size: it.Size, IsDir: fi != nil && fi.IsDir()})
	}
	a.mu.Unlock()
	sort.Slice(out, func(i, j int) bool { return out[i].Deleted.After(out[j].Deleted) })
	return out
}

// freeName returns p, or "name (restored N).ext" when p is taken.
func freeName(p string) string {
	if _, err := os.Lstat(p); os.IsNotExist(err) {
		return p
	}
	ext := filepath.Ext(p)
	base := strings.TrimSuffix(p, ext)
	for i := 1; ; i++ {
		c := fmt.Sprintf("%s (restored %d)%s", base, i, ext)
		if _, err := os.Lstat(c); os.IsNotExist(err) {
			return c
		}
	}
}

type RestoreResult struct {
	Restored []string `json:"restored"`
	Errors   []string `json:"errors"`
}

func (a *App) RestoreBin(ids []string) *RestoreResult {
	res := &RestoreResult{}
	for _, id := range ids {
		a.mu.Lock()
		it, ok := a.binItems[id]
		a.mu.Unlock()
		if !ok {
			continue
		}
		dest := freeName(it.Original)
		if err := os.MkdirAll(filepath.Dir(dest), 0755); err != nil {
			res.Errors = append(res.Errors, err.Error())
			continue
		}
		// Same volume, so this is an instant rename.
		if err := os.Rename(it.RPath, dest); err != nil {
			res.Errors = append(res.Errors, fmt.Sprintf("%s: %v", it.Original, err))
			continue
		}
		_ = os.Remove(it.IPath)
		res.Restored = append(res.Restored, dest)
	}
	return res
}

// ---- Lost recordings and temp media ------------------------------------

type LostFile struct {
	Path     string    `json:"path"`
	Name     string    `json:"name"`
	Size     int64     `json:"size"`
	Modified time.Time `json:"modified"`
	Source   string    `json:"source"`
}

var mediaExt = map[string]bool{
	".mp4": true, ".mkv": true, ".webm": true, ".mov": true, ".avi": true, ".wmv": true,
	".m4a": true, ".wav": true, ".mp3": true, ".png": true, ".jpg": true, ".jpeg": true, ".gif": true,
}

var videoExt = map[string]bool{".mp4": true, ".mkv": true, ".webm": true, ".mov": true, ".avi": true, ".wmv": true, ".m4a": true, ".wav": true}

type lostSource struct {
	name  string
	globs []string
	any   bool // accept every file, not just media extensions (e.g. temp recordings without one)
	video bool // only video/audio (busy folders like %TEMP%)
}

var lostSources = []lostSource{
	{"Snipping Tool", []string{`%LOCALAPPDATA%\Packages\Microsoft.ScreenSketch_8wekyb3d8bbwe\TempState`,
		`%LOCALAPPDATA%\Packages\Microsoft.ScreenSketch_8wekyb3d8bbwe\LocalState`,
		`%LOCALAPPDATA%\Packages\Microsoft.ScreenSketch_8wekyb3d8bbwe\LocalCache`,
		`%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\TempState\ScreenClip`}, true, false},
	{"Xbox Game Bar", []string{`%LOCALAPPDATA%\Packages\Microsoft.XboxGamingOverlay_8wekyb3d8bbwe\LocalState`,
		`%LOCALAPPDATA%\Packages\Microsoft.XboxGamingOverlay_8wekyb3d8bbwe\TempState`, `%USERPROFILE%\Videos\Captures`}, false, false},
	{"Clipchamp", []string{`%LOCALAPPDATA%\Packages\Clipchamp.Clipchamp_yxz26nhyzhsrt\LocalState`}, false, false},
	{"Camera / Voice Recorder", []string{`%LOCALAPPDATA%\Packages\Microsoft.WindowsCamera_8wekyb3d8bbwe\TempState`,
		`%LOCALAPPDATA%\Packages\Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe\TempState`}, false, false},
	{"OBS / NVIDIA / AMD", []string{`%USERPROFILE%\Videos\OBS`, `%USERPROFILE%\Videos\NVIDIA`, `%USERPROFILE%\Videos\Radeon ReLive`, `%LOCALAPPDATA%\Temp\Highlights`}, false, false},
	{"Temp folder", []string{`%TEMP%`}, false, true},
	{"Screen recordings folder", []string{`%USERPROFILE%\Videos\Screen Recordings`, `%USERPROFILE%\OneDrive\Videos\Screen Recordings`}, false, false},
}

// FindLostMedia lists recordings and images left in app temp folders in the
// last 60 days, e.g. after a crash or power loss during recording.
func (a *App) FindLostMedia() []LostFile {
	cutoff := time.Now().AddDate(0, 0, -60)
	var out []LostFile
	seen := map[string]bool{}
	for _, src := range lostSources {
		for _, g := range src.globs {
			root, ok := expandEnv(g)
			if !ok {
				continue
			}
			filepath.WalkDir(root, func(p string, d fs.DirEntry, err error) error {
				if err != nil {
					return nil
				}
				if isLink(d) && d.IsDir() {
					return filepath.SkipDir
				}
				if d.IsDir() {
					return nil
				}
				info, e := d.Info()
				if e != nil || info.Size() < 32*1024 || info.ModTime().Before(cutoff) {
					return nil
				}
				ext := strings.ToLower(filepath.Ext(p))
				if !mediaExt[ext] && !(src.any && (ext == "" || ext == ".tmp" || ext == ".part")) {
					return nil
				}
				if src.video && !videoExt[ext] {
					return nil
				}
				if !mediaExt[ext] && !looksLikeMedia(p) {
					return nil
				}
				key := strings.ToLower(p)
				if seen[key] {
					return nil
				}
				seen[key] = true
				out = append(out, LostFile{Path: p, Name: d.Name(), Size: info.Size(), Modified: info.ModTime(), Source: src.name})
				return nil
			})
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Modified.After(out[j].Modified) })
	return out
}

// looksLikeMedia sniffs MP4/WebM/PNG/JPEG headers for files without a
// media extension.
func looksLikeMedia(p string) bool {
	f, err := os.Open(p)
	if err != nil {
		return false
	}
	defer f.Close()
	b := make([]byte, 12)
	if n, _ := io.ReadFull(f, b); n < 12 {
		return false
	}
	switch {
	case string(b[4:8]) == "ftyp", string(b[4:8]) == "mdat", string(b[4:8]) == "moov", string(b[4:8]) == "free":
		return true
	case b[0] == 0x1A && b[1] == 0x45 && b[2] == 0xDF && b[3] == 0xA3: // WebM/MKV
		return true
	case b[0] == 0x89 && string(b[1:4]) == "PNG", b[0] == 0xFF && b[1] == 0xD8:
		return true
	}
	return false
}

// PickSaveFolder asks where recovered copies go.
func (a *App) PickSaveFolder() (string, error) {
	return wruntime.OpenDirectoryDialog(a.ctx, wruntime.OpenDialogOptions{Title: "Choose where to save recovered files"})
}

func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.OpenFile(dst, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0644)
	if err != nil {
		return err
	}
	if _, err := io.Copy(out, in); err != nil {
		out.Close()
		os.Remove(dst)
		return err
	}
	return out.Close()
}

func copyTree(src, dst string) error {
	fi, err := os.Stat(src)
	if err != nil {
		return err
	}
	if !fi.IsDir() {
		return copyFile(src, dst)
	}
	return filepath.WalkDir(src, func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil
		}
		rel, _ := filepath.Rel(src, p)
		target := filepath.Join(dst, rel)
		if d.IsDir() {
			return os.MkdirAll(target, 0755)
		}
		if isLink(d) {
			return nil
		}
		return copyFile(p, target)
	})
}

// SaveCopies copies files into destDir; a playable extension is added to
// extensionless recordings that look like MP4.
func (a *App) SaveCopies(paths []string, destDir string) *RestoreResult {
	res := &RestoreResult{}
	for _, p := range paths {
		name := filepath.Base(p)
		if ext := strings.ToLower(filepath.Ext(name)); !mediaExt[ext] && looksLikeMedia(p) {
			name += ".mp4"
		}
		dst := freeName(filepath.Join(destDir, name))
		if err := copyTree(p, dst); err != nil {
			res.Errors = append(res.Errors, fmt.Sprintf("%s: %v", name, err))
			continue
		}
		res.Restored = append(res.Restored, dst)
	}
	return res
}

// ---- Previous versions (Volume Shadow Copies) --------------------------

type ShadowVersion struct {
	Shadow  string `json:"shadow"`
	Created string `json:"created"`
	Path    string `json:"path"` // the item inside the shadow copy
	Size    int64  `json:"size"`
	IsDir   bool   `json:"isDir"`
}

var (
	reShadowVol = regexp.MustCompile(`(?i)Shadow Copy Volume:\s*(\S+)`)
	reOrigVol   = regexp.MustCompile(`(?i)Original Volume:\s*\(([A-Z]:)\)`)
	reCreated   = regexp.MustCompile(`(?i)creation time:\s*(.+)`)
)

// FindPreviousVersions looks for target (a file or folder, which may have
// been deleted) inside every shadow copy of its drive. Needs administrator.
func (a *App) FindPreviousVersions(target string) ([]ShadowVersion, error) {
	if !a.IsAdmin() {
		return nil, errors.New("previous versions need administrator: use Run as administrator")
	}
	target = filepath.Clean(target)
	vol := filepath.VolumeName(target)
	if len(vol) != 2 {
		return nil, errors.New("enter a full path such as C:\\Users\\you\\Documents\\file.docx")
	}
	out, err := hidden("vssadmin", "list", "shadows").CombinedOutput()
	if err != nil && len(out) == 0 {
		return nil, fmt.Errorf("vssadmin failed: %v", err)
	}
	var res []ShadowVersion
	var created, origVol string
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if m := reCreated.FindStringSubmatch(line); m != nil {
			created = strings.TrimSpace(m[1])
		}
		if m := reOrigVol.FindStringSubmatch(line); m != nil {
			origVol = m[1]
		}
		if m := reShadowVol.FindStringSubmatch(line); m != nil && strings.EqualFold(origVol, vol) {
			inside := m[1] + target[2:]
			if fi, err := os.Stat(inside); err == nil {
				v := ShadowVersion{Shadow: m[1], Created: created, Path: inside, IsDir: fi.IsDir(), Size: fi.Size()}
				res = append(res, v)
			}
		}
	}
	if len(res) == 0 && !strings.Contains(string(out), "Shadow Copy Volume") {
		return nil, errors.New("this PC has no shadow copies (System Protection is off or no restore points exist)")
	}
	sort.Slice(res, func(i, j int) bool { return res[i].Created > res[j].Created })
	return res, nil
}

// ---- Deep scan with Windows File Recovery (winfr) -----------------------

func winfrPath() string {
	if p, err := exec.LookPath("winfr.exe"); err == nil {
		return p
	}
	p := filepath.Join(os.Getenv("LOCALAPPDATA"), `Microsoft\WindowsApps\winfr.exe`)
	if _, err := os.Stat(p); err == nil {
		return p
	}
	return ""
}

func (a *App) WinfrInstalled() bool { return winfrPath() != "" }

// OpenWinfrStore opens Microsoft's Windows File Recovery page in the Store.
func (a *App) OpenWinfrStore() {
	hidden("cmd", "/c", "start", "", "ms-windows-store://pdp/?productid=9N26S50LN705").Start()
}

var reFilter = regexp.MustCompile(`^[\w\\.*\- ()]+$`)

// StartDeepScan runs winfr from sourceDrive (e.g. "C:") into destDir,
// which must be on another drive. mode is "regular" or "extensive";
// filter is a pattern such as "*.mp4" or "\Users\me\Videos\".
// Output streams as "recover:line"; "recover:done" ends it.
func (a *App) StartDeepScan(sourceDrive, destDir, mode, filter string) error {
	exe := winfrPath()
	if exe == "" {
		return errors.New("Windows File Recovery is not installed")
	}
	if !a.IsAdmin() {
		return errors.New("deep scan needs administrator: use Run as administrator")
	}
	sourceDrive = strings.ToUpper(strings.TrimRight(sourceDrive, `\`))
	if len(sourceDrive) != 2 || sourceDrive[1] != ':' {
		return errors.New("choose a source drive")
	}
	if strings.EqualFold(filepath.VolumeName(destDir), sourceDrive) {
		return errors.New("save to a different drive than the one being scanned, or recovered data may overwrite what you want back")
	}
	if mode != "regular" && mode != "extensive" {
		mode = "regular"
	}
	if filter == "" || !reFilter.MatchString(filter) {
		return errors.New("enter a file pattern such as *.mp4 or \\Users\\you\\Videos\\")
	}
	cmd := hidden(exe, sourceDrive, destDir, "/"+mode, "/n", filter)
	cmd.Stdin = strings.NewReader("y\ny\ny\n")
	pipe, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}
	cmd.Stderr = cmd.Stdout
	if err := cmd.Start(); err != nil {
		return err
	}
	a.mu.Lock()
	a.winfr = cmd
	a.mu.Unlock()
	go func() {
		sc := bufio.NewScanner(pipe)
		sc.Split(scanCRLF)
		for sc.Scan() {
			if l := strings.TrimSpace(sc.Text()); l != "" {
				wruntime.EventsEmit(a.ctx, "recover:line", l)
			}
		}
		err := cmd.Wait()
		msg := ""
		if err != nil {
			msg = err.Error()
		}
		a.mu.Lock()
		a.winfr = nil
		a.mu.Unlock()
		wruntime.EventsEmit(a.ctx, "recover:done", msg, destDir)
	}()
	return nil
}

func (a *App) StopDeepScan() {
	a.mu.Lock()
	defer a.mu.Unlock()
	if a.winfr != nil && a.winfr.Process != nil {
		a.winfr.Process.Kill()
	}
}

// scanCRLF splits on \n or \r so progress lines that redraw with \r arrive.
func scanCRLF(data []byte, atEOF bool) (int, []byte, error) {
	for i, b := range data {
		if b == '\n' || b == '\r' {
			return i + 1, data[:i], nil
		}
	}
	if atEOF && len(data) > 0 {
		return len(data), data, nil
	}
	return 0, nil, nil
}
