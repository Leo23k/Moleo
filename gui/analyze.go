package main

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"
	"unsafe"

	wruntime "github.com/wailsapp/wails/v2/pkg/runtime"
	"golang.org/x/sys/windows"
)

// node is a directory in the scanned tree. Only the largest files of each
// directory are kept by name; the rest are summed into otherBytes so a
// whole drive fits in memory.
type node struct {
	name       string
	size       int64
	files      int64
	dirs       []*node
	bigFiles   []fileInfo
	otherBytes int64
	otherCount int64
	denied     bool
}

type fileInfo struct {
	name string
	size int64
}

const keepFilesPerDir = 40

type DriveInfo struct {
	Path  string `json:"path"`
	Label string `json:"label"`
	Total int64  `json:"total"`
	Free  int64  `json:"free"`
}

type AnalyzeItem struct {
	Name  string `json:"name"`
	Path  string `json:"path"`
	Size  int64  `json:"size"`
	Files int64  `json:"files"`
	IsDir bool   `json:"isDir"`
	Other bool   `json:"other"`
}

type AnalyzeLevel struct {
	Path  string        `json:"path"`
	Size  int64         `json:"size"`
	Files int64         `json:"files"`
	Items []AnalyzeItem `json:"items"`
	Root  string        `json:"root"`
}

type analyzeState struct {
	mu     sync.Mutex
	root   string
	tree   *node
	cancel atomic.Bool
}

func (a *App) ListDrives() []DriveInfo {
	var out []DriveInfo
	mask, _ := windows.GetLogicalDrives()
	for i := 0; i < 26; i++ {
		if mask&(1<<uint(i)) == 0 {
			continue
		}
		root := fmt.Sprintf(`%c:\`, 'A'+i)
		p, _ := windows.UTF16PtrFromString(root)
		t := windows.GetDriveType(p)
		if t != windows.DRIVE_FIXED && t != windows.DRIVE_REMOVABLE {
			continue
		}
		var free, total, totalFree uint64
		if windows.GetDiskFreeSpaceEx(p, &free, &total, &totalFree) != nil {
			continue
		}
		label := make([]uint16, 261)
		_ = windows.GetVolumeInformation(p, &label[0], uint32(len(label)), nil, nil, nil, nil, 0)
		out = append(out, DriveInfo{Path: root, Label: windows.UTF16ToString(label), Total: int64(total), Free: int64(totalFree)})
	}
	return out
}

// PickFolder lets the user choose any folder to analyze.
func (a *App) PickFolder() (string, error) {
	return wruntime.OpenDirectoryDialog(a.ctx, wruntime.OpenDialogOptions{Title: "Choose a folder to analyze"})
}

func (a *App) CancelAnalyze() { a.analyze.cancel.Store(true) }

// StartAnalyze scans root in the background, emitting "analyze:progress"
// and finally "analyze:done" (or "analyze:error").
func (a *App) StartAnalyze(root string) error {
	root = filepath.Clean(root)
	if fi, err := os.Stat(root); err != nil || !fi.IsDir() {
		return errors.New("not a folder: " + root)
	}
	if strings.HasSuffix(root, ":") {
		root += `\`
	}
	a.analyze.cancel.Store(false)
	go func() {
		var files, bytes atomic.Int64
		var current atomic.Value
		current.Store(root)
		stop := make(chan struct{})
		go func() {
			t := time.NewTicker(150 * time.Millisecond)
			defer t.Stop()
			for {
				select {
				case <-stop:
					return
				case <-t.C:
					wruntime.EventsEmit(a.ctx, "analyze:progress", files.Load(), bytes.Load(), current.Load())
				}
			}
		}()
		start := time.Now()
		sem := make(chan struct{}, runtime.NumCPU()*4)
		tree := scanDir(root, filepath.Base(root), sem, &files, &bytes, &current, &a.analyze.cancel)
		close(stop)
		if a.analyze.cancel.Load() {
			wruntime.EventsEmit(a.ctx, "analyze:error", "Scan cancelled")
			return
		}
		a.analyze.mu.Lock()
		a.analyze.root, a.analyze.tree = root, tree
		a.analyze.mu.Unlock()
		wruntime.EventsEmit(a.ctx, "analyze:done", root, time.Since(start).Seconds())
	}()
	return nil
}

func scanDir(path, name string, sem chan struct{}, files, bytes *atomic.Int64, current *atomic.Value, cancel *atomic.Bool) *node {
	n := &node{name: name}
	if cancel.Load() {
		return n
	}
	entries, err := os.ReadDir(path)
	if err != nil {
		n.denied = true
		return n
	}
	current.Store(path)
	var subs []string
	var fl []fileInfo
	for _, e := range entries {
		t := e.Type()
		if t&fs.ModeSymlink != 0 || t&fs.ModeIrregular != 0 {
			continue // links and junctions are not followed (no double counting)
		}
		if e.IsDir() {
			subs = append(subs, e.Name())
			continue
		}
		info, err := e.Info()
		if err != nil {
			continue
		}
		sz := info.Size()
		fl = append(fl, fileInfo{e.Name(), sz})
		n.size += sz
		n.files++
	}
	files.Add(n.files)
	bytes.Add(n.size)
	sort.Slice(fl, func(i, j int) bool { return fl[i].size > fl[j].size })
	if len(fl) > keepFilesPerDir {
		for _, f := range fl[keepFilesPerDir:] {
			n.otherBytes += f.size
			n.otherCount++
		}
		fl = fl[:keepFilesPerDir:keepFilesPerDir]
	}
	n.bigFiles = fl

	n.dirs = make([]*node, len(subs))
	var wg sync.WaitGroup
	for i, s := range subs {
		child := filepath.Join(path, s)
		select {
		case sem <- struct{}{}:
			wg.Add(1)
			go func(i int, child, s string) {
				defer wg.Done()
				n.dirs[i] = scanDir(child, s, sem, files, bytes, current, cancel)
				<-sem
			}(i, child, s)
		default:
			n.dirs[i] = scanDir(child, s, sem, files, bytes, current, cancel)
		}
	}
	wg.Wait()
	for _, d := range n.dirs {
		n.size += d.size
		n.files += d.files
	}
	return n
}

func (a *App) find(path string) (*node, string, error) {
	a.analyze.mu.Lock()
	defer a.analyze.mu.Unlock()
	if a.analyze.tree == nil {
		return nil, "", errors.New("nothing scanned yet")
	}
	root := a.analyze.root
	rel, err := filepath.Rel(root, filepath.Clean(path))
	if err != nil || strings.HasPrefix(rel, "..") {
		return nil, "", errors.New("path is outside the scanned folder")
	}
	n := a.analyze.tree
	if rel != "." {
		for _, part := range strings.Split(rel, string(filepath.Separator)) {
			var next *node
			for _, d := range n.dirs {
				if strings.EqualFold(d.name, part) {
					next = d
					break
				}
			}
			if next == nil {
				return nil, "", errors.New("folder not found in scan: " + path)
			}
			n = next
		}
	}
	return n, root, nil
}

// AnalyzeLevel returns the children of one scanned folder, largest first.
func (a *App) AnalyzeLevel(path string) (*AnalyzeLevel, error) {
	n, root, err := a.find(path)
	if err != nil {
		return nil, err
	}
	lvl := &AnalyzeLevel{Path: filepath.Clean(path), Size: n.size, Files: n.files, Root: root}
	if strings.HasSuffix(lvl.Path, ":") {
		lvl.Path += `\`
	}
	for _, d := range n.dirs {
		if d.size == 0 {
			continue
		}
		lvl.Items = append(lvl.Items, AnalyzeItem{Name: d.name, Path: filepath.Join(lvl.Path, d.name), Size: d.size, Files: d.files, IsDir: true})
	}
	for _, f := range n.bigFiles {
		lvl.Items = append(lvl.Items, AnalyzeItem{Name: f.name, Path: filepath.Join(lvl.Path, f.name), Size: f.size, Files: 1})
	}
	if n.otherBytes > 0 {
		lvl.Items = append(lvl.Items, AnalyzeItem{Name: fmt.Sprintf("%d smaller files", n.otherCount), Size: n.otherBytes, Files: n.otherCount, Other: true})
	}
	sort.Slice(lvl.Items, func(i, j int) bool { return lvl.Items[i].Size > lvl.Items[j].Size })
	return lvl, nil
}

// ---- Recycle Bin delete ----------------------------------------------

type shFileOpStruct struct {
	hwnd                  uintptr
	wFunc                 uint32
	pFrom                 *uint16
	pTo                   *uint16
	fFlags                uint16
	fAnyOperationsAborted int32
	hNameMappings         uintptr
	lpszProgressTitle     *uint16
}

var procSHFileOperation = windows.NewLazySystemDLL("shell32.dll").NewProc("SHFileOperationW")

// recycle moves paths to the Recycle Bin (never a permanent delete).
func recycle(paths []string) error {
	var buf []uint16
	for _, p := range paths {
		u, err := syscall.UTF16FromString(p)
		if err != nil {
			return err
		}
		buf = append(buf, u...) // includes the terminating NUL
	}
	buf = append(buf, 0) // list ends with a double NUL
	const foDelete = 3
	const fofAllowUndo, fofNoConfirmation, fofSilent, fofNoErrorUI = 0x40, 0x10, 0x4, 0x400
	op := shFileOpStruct{wFunc: foDelete, pFrom: &buf[0], fFlags: fofAllowUndo | fofNoConfirmation | fofSilent | fofNoErrorUI}
	r, _, _ := procSHFileOperation.Call(uintptr(unsafe.Pointer(&op)))
	if r != 0 {
		return fmt.Errorf("could not move to Recycle Bin (code 0x%x)", r)
	}
	if op.fAnyOperationsAborted != 0 {
		return errors.New("move to Recycle Bin was cancelled")
	}
	return nil
}

// RecyclePaths moves the chosen items to the Recycle Bin and updates the
// scanned tree so the treemap stays correct without a rescan.
func (a *App) RecyclePaths(paths []string) error {
	for _, p := range paths {
		clean := filepath.Clean(p)
		if len(clean) <= 3 || !isSafeRoot(clean) && !isRegularFile(clean) {
			return errors.New("refusing to remove " + p)
		}
	}
	if err := recycle(paths); err != nil {
		return err
	}
	for _, p := range paths {
		a.dropFromTree(filepath.Clean(p))
	}
	return nil
}

func isRegularFile(p string) bool {
	fi, err := os.Lstat(p)
	return err == nil && fi.Mode().IsRegular()
}

func (a *App) dropFromTree(p string) {
	parent, _, err := a.find(filepath.Dir(p))
	if err != nil {
		return
	}
	a.analyze.mu.Lock()
	defer a.analyze.mu.Unlock()
	name := filepath.Base(p)
	var removed, removedFiles int64
	for i, d := range parent.dirs {
		if strings.EqualFold(d.name, name) {
			removed, removedFiles = d.size, d.files
			parent.dirs = append(parent.dirs[:i], parent.dirs[i+1:]...)
			break
		}
	}
	for i, f := range parent.bigFiles {
		if removed == 0 && strings.EqualFold(f.name, name) {
			removed, removedFiles = f.size, 1
			parent.bigFiles = append(parent.bigFiles[:i], parent.bigFiles[i+1:]...)
			break
		}
	}
	// Subtract from every ancestor up to the root.
	rel, _ := filepath.Rel(a.analyze.root, filepath.Dir(p))
	n := a.analyze.tree
	n.size -= removed
	n.files -= removedFiles
	if rel != "." {
		for _, part := range strings.Split(rel, string(filepath.Separator)) {
			for _, d := range n.dirs {
				if strings.EqualFold(d.name, part) {
					n = d
					break
				}
			}
			n.size -= removed
			n.files -= removedFiles
		}
	}
}
