package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
	"unsafe"

	"golang.org/x/sys/windows"
)

// Moving space-hungry folders off the system drive.
//   - Personal folders (Downloads, Documents…) are relocated with
//     SHSetKnownFolderPath, exactly like the Location tab in Properties.
//   - Caches and other folders are moved and a junction is left behind,
//     so every program keeps finding them at the old path.
// Every move is recorded so it can be undone.

type MoveCandidate struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	Path      string `json:"path"`
	Bytes     int64  `json:"bytes"`
	Kind      string `json:"kind"` // known | junction
	Group     string `json:"group"`
	Moved     bool   `json:"moved"`
	MovedTo   string `json:"movedTo"`
	Note      string `json:"note"`
	Elsewhere bool   `json:"elsewhere"` // already off the system drive, not moved by Moleo
}

type moveRecord struct {
	ID   string    `json:"id"`
	Kind string    `json:"kind"`
	Src  string    `json:"src"`
	Dst  string    `json:"dst"`
	GUID string    `json:"guid,omitempty"`
	Time time.Time `json:"time"`
}

var knownFolders = []struct{ id, name, guid, sub string }{
	{"downloads", "Downloads", "{374DE290-123F-4565-9164-39C4925E467B}", "Downloads"},
	{"documents", "Documents", "{FDD39AD0-238F-46AF-ADB4-6C85480369C7}", "Documents"},
	{"videos", "Videos", "{18989B1D-99B5-455B-841C-AB7C74E4DDFC}", "Videos"},
	{"pictures", "Pictures", "{33E28130-4E1E-4676-835A-98395C3BC3BB}", "Pictures"},
	{"music", "Music", "{4BD8D571-6D19-48D3-BE97-422220080E43}", "Music"},
	{"desktop", "Desktop", "{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}", "Desktop"},
}

var junctionFolders = []struct{ id, name, path, group, note string }{
	{"npm", "npm cache", `%LOCALAPPDATA%\npm-cache`, "Developer caches", ""},
	{"pip", "pip cache", `%LOCALAPPDATA%\pip`, "Developer caches", ""},
	{"uv", "uv cache", `%LOCALAPPDATA%\uv`, "Developer caches", ""},
	{"pnpm", "pnpm store", `%LOCALAPPDATA%\pnpm`, "Developer caches", ""},
	{"gradle", "Gradle", `%USERPROFILE%\.gradle`, "Developer caches", ""},
	{"maven", "Maven repository", `%USERPROFILE%\.m2`, "Developer caches", ""},
	{"nuget", "NuGet packages", `%USERPROFILE%\.nuget`, "Developer caches", ""},
	{"gomod", "Go modules", `%USERPROFILE%\go`, "Developer caches", ""},
	{"cargo", "Cargo", `%USERPROFILE%\.cargo\registry`, "Developer caches", ""},
	{"conda", "Conda packages", `%USERPROFILE%\.conda`, "Developer caches", ""},
	{"playwright", "Playwright browsers", `%LOCALAPPDATA%\ms-playwright`, "Developer caches", ""},
	{"android", "Android SDK", `%LOCALAPPDATA%\Android\Sdk`, "Developer caches", "Close Android Studio first."},
	{"unity", "Unity cache", `%LOCALAPPDATA%\Unity\cache`, "Developer caches", "Close Unity first."},
	{"hf", "Hugging Face models", `%USERPROFILE%\.cache\huggingface`, "AI models", ""},
	{"ollama", "Ollama models", `%USERPROFILE%\.ollama\models`, "AI models", "Quit Ollama first."},
	{"lmstudio", "LM Studio models", `%USERPROFILE%\.lmstudio\models`, "AI models", "Quit LM Studio first."},
	{"docker", "Docker Desktop data", `%LOCALAPPDATA%\Docker\wsl`, "Virtual machines", "Quit Docker Desktop first."},
}

var moveMu sync.Mutex

func movesFile() string {
	d := filepath.Join(os.Getenv("LOCALAPPDATA"), "Moleo")
	_ = os.MkdirAll(d, 0755)
	return filepath.Join(d, "moves.json")
}

func loadMoves() map[string]moveRecord {
	m := map[string]moveRecord{}
	if b, err := os.ReadFile(movesFile()); err == nil {
		_ = json.Unmarshal(b, &m)
	}
	return m
}

func saveMoves(m map[string]moveRecord) error {
	b, _ := json.MarshalIndent(m, "", "  ")
	return os.WriteFile(movesFile(), b, 0644)
}

var (
	shell32                  = windows.NewLazySystemDLL("shell32.dll")
	procSHGetKnownFolderPath = shell32.NewProc("SHGetKnownFolderPath")
	procSHSetKnownFolderPath = shell32.NewProc("SHSetKnownFolderPath")
	procSHChangeNotify       = shell32.NewProc("SHChangeNotify")
	procCoTaskMemFree        = windows.NewLazySystemDLL("ole32.dll").NewProc("CoTaskMemFree")
)

func getKnownFolder(guid string) (string, error) {
	g, err := windows.GUIDFromString(guid)
	if err != nil {
		return "", err
	}
	var p *uint16
	r, _, _ := procSHGetKnownFolderPath.Call(uintptr(unsafe.Pointer(&g)), 0, 0, uintptr(unsafe.Pointer(&p)))
	if r != 0 {
		return "", fmt.Errorf("SHGetKnownFolderPath 0x%x", r)
	}
	defer procCoTaskMemFree.Call(uintptr(unsafe.Pointer(p)))
	return windows.UTF16PtrToString(p), nil
}

func setKnownFolder(guid, path string) error {
	g, err := windows.GUIDFromString(guid)
	if err != nil {
		return err
	}
	p, _ := windows.UTF16PtrFromString(path)
	r, _, _ := procSHSetKnownFolderPath.Call(uintptr(unsafe.Pointer(&g)), 0, 0, uintptr(unsafe.Pointer(p)))
	if r != 0 {
		return fmt.Errorf("Windows refused to change the folder location (0x%x)", r)
	}
	const shcneAssocChanged = 0x08000000
	procSHChangeNotify.Call(shcneAssocChanged, 0, 0, 0)
	return nil
}

func isJunction(p string) bool {
	fi, err := os.Lstat(p)
	return err == nil && (fi.Mode()&os.ModeSymlink != 0 || fi.Mode()&os.ModeIrregular != 0)
}

func (a *App) MoveCandidates() []MoveCandidate {
	records := loadMoves()
	var out []MoveCandidate
	for _, k := range knownFolders {
		p, err := getKnownFolder(k.guid)
		if err != nil {
			continue
		}
		c := MoveCandidate{ID: k.id, Name: k.name, Path: p, Kind: "known", Group: "Personal folders"}
		if r, ok := records[k.id]; ok {
			c.Moved, c.MovedTo = true, r.Dst
		} else if !strings.EqualFold(filepath.VolumeName(p), systemDrive()) {
			c.Moved, c.MovedTo, c.Elsewhere = true, p, true
		}
		out = append(out, c)
	}
	for _, j := range junctionFolders {
		p, ok := expandEnv(j.path)
		if !ok {
			continue
		}
		c := MoveCandidate{ID: j.id, Name: j.name, Path: p, Kind: "junction", Group: j.group, Note: j.note}
		if r, ok := records[j.id]; ok {
			c.Moved, c.MovedTo = true, r.Dst
		} else if _, err := os.Lstat(p); err != nil || isJunction(p) {
			continue // not installed, or already a link
		}
		out = append(out, c)
	}
	var wg sync.WaitGroup
	for i := range out {
		if out[i].Moved {
			continue
		}
		wg.Add(1)
		go func(c *MoveCandidate) { defer wg.Done(); c.Bytes = dirSize(c.Path) }(&out[i])
	}
	wg.Wait()
	// Drop empty developer folders; personal folders always show.
	kept := out[:0]
	for _, c := range out {
		if c.Kind == "known" || c.Moved || c.Bytes > 50<<20 {
			kept = append(kept, c)
		}
	}
	return kept
}

func destFor(src, drive string) string {
	rel := strings.TrimPrefix(src, filepath.VolumeName(src))
	return filepath.Join(strings.TrimRight(drive, `\`)+`\`, "MoleoMoved", rel)
}

func checkDest(drive string, need int64) error {
	drive = strings.ToUpper(strings.TrimRight(drive, `\`))
	if len(drive) != 2 || drive[1] != ':' {
		return errors.New("choose a drive")
	}
	if strings.EqualFold(drive, systemDrive()) {
		return errors.New("choose a drive other than the system drive")
	}
	if free := driveFree(drive); free > 0 && free < need+(1<<30) {
		return fmt.Errorf("not enough free space on %s", drive)
	}
	return nil
}

// MoveFolder moves a candidate (or any folder when id is "custom:<path>")
// to drive, e.g. "D:".
func (a *App) MoveFolder(id, drive string) (string, error) {
	moveMu.Lock()
	defer moveMu.Unlock()
	records := loadMoves()
	if _, ok := records[id]; ok {
		return "", errors.New("already moved")
	}
	var src, kind, guid string
	if strings.HasPrefix(id, "custom:") {
		src, kind = filepath.Clean(strings.TrimPrefix(id, "custom:")), "junction"
		if w := pathWarning(src); strings.Contains(w, "Windows") || strings.Contains(w, "Installed apps") || len(src) <= 3 {
			return "", errors.New("this folder cannot be moved safely")
		}
		if isJunction(src) {
			return "", errors.New("this folder is already a link")
		}
	} else {
		for _, k := range knownFolders {
			if k.id == id {
				kind, guid = "known", k.guid
				src, _ = getKnownFolder(k.guid)
			}
		}
		for _, j := range junctionFolders {
			if j.id == id {
				kind = "junction"
				src, _ = expandEnv(j.path)
			}
		}
	}
	if src == "" {
		return "", errors.New("unknown folder")
	}
	if strings.Contains(strings.ToLower(src), `\onedrive`) {
		return "", errors.New("this folder is synced by OneDrive: move it from OneDrive settings instead")
	}
	if fi, err := os.Stat(src); err != nil || !fi.IsDir() {
		return "", errors.New("folder not found: " + src)
	}
	if err := checkDest(drive, dirSize(src)); err != nil {
		return "", err
	}
	dst := destFor(src, drive)
	if err := os.MkdirAll(dst, 0755); err != nil {
		return "", err
	}

	if kind == "known" {
		if err := setKnownFolder(guid, dst); err != nil {
			return "", err
		}
		if err := robocopyMove(src, dst); err != nil {
			_ = setKnownFolder(guid, src)
			return "", err
		}
		_ = os.Mkdir(src, 0755) // some apps expect the old folder to exist
	} else {
		if err := robocopyMove(src, dst); err != nil {
			return "", err
		}
		// Files that were open stay behind: put everything back and stop.
		if left, _ := os.ReadDir(src); len(left) > 0 {
			_ = robocopyMove(dst, src)
			return "", errors.New("some files are in use. Close the program that uses this folder and try again")
		}
		_ = os.Remove(src)
		if out, err := runOK("cmd", "/c", "mklink", "/J", src, dst); err != nil {
			_ = os.MkdirAll(src, 0755)
			_ = robocopyMove(dst, src)
			return "", fmt.Errorf("could not create the link, moved back: %s", strings.TrimSpace(out))
		}
	}
	records[id] = moveRecord{ID: id, Kind: kind, Src: src, Dst: dst, GUID: guid, Time: time.Now()}
	return dst, saveMoves(records)
}

// UndoMove brings a moved folder back to where it was.
func (a *App) UndoMove(id string) error {
	moveMu.Lock()
	defer moveMu.Unlock()
	records := loadMoves()
	r, ok := records[id]
	if !ok {
		return errors.New("no record of this move")
	}
	if r.Kind == "known" {
		if err := setKnownFolder(r.GUID, r.Src); err != nil {
			return err
		}
		_ = os.MkdirAll(r.Src, 0755)
		if err := robocopyMove(r.Dst, r.Src); err != nil {
			return err
		}
	} else {
		if isJunction(r.Src) {
			if err := os.Remove(r.Src); err != nil {
				return err
			}
		}
		if err := os.MkdirAll(r.Src, 0755); err != nil {
			return err
		}
		if err := robocopyMove(r.Dst, r.Src); err != nil {
			return err
		}
	}
	delete(records, id)
	return saveMoves(records)
}

// PickFolderAny lets the user choose a folder to move.
func (a *App) MoveCustomCandidate(path string) (*MoveCandidate, error) {
	path = filepath.Clean(path)
	if fi, err := os.Stat(path); err != nil || !fi.IsDir() {
		return nil, errors.New("not a folder")
	}
	return &MoveCandidate{ID: "custom:" + path, Name: filepath.Base(path), Path: path, Kind: "junction", Group: "Your folders", Bytes: dirSize(path)}, nil
}
