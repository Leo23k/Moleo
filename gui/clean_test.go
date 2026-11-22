package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"
)

func TestExpandEnv(t *testing.T) {
	t.Setenv("MOLEO_X", `C:\x`)
	if p, ok := expandEnv(`%MOLEO_X%\a`); !ok || p != `C:\x\a` {
		t.Fatal(p)
	}
	if _, ok := expandEnv(`%MOLEO_MISSING_VAR%\a`); ok {
		t.Fatal("missing var should fail")
	}
}

func TestSafeRootRejectsUserFolders(t *testing.T) {
	for _, p := range []string{`C:\`, `C:\Windows`, `C:\Users\x\Documents`} {
		if isSafeRoot(p) && p != `C:\Windows` {
			t.Fatal(p)
		}
	}
}

func TestScanCleanLive(t *testing.T) {
	if testing.Short() {
		t.Skip()
	}
	start := time.Now()
	s, err := (&App{}).ScanClean()
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("locations=%d entries=%d bytes=%.2fGB in %s", s.Locations, len(s.Entries), float64(s.Bytes)/1e9, time.Since(start))
	for _, e := range s.Entries[:min(25, len(s.Entries))] {
		t.Logf("%-6s %-32s %8.1fMB %s", e.Category, e.Name, float64(e.Bytes)/1e6, e.Path)
	}
}

func TestClearRootKeepsRootAndSkipsJunctionTarget(t *testing.T) {
	base := t.TempDir()
	root := filepath.Join(base, "cache")
	keep := filepath.Join(base, "precious")
	os.MkdirAll(filepath.Join(root, "sub"), 0755)
	os.MkdirAll(keep, 0755)
	os.WriteFile(filepath.Join(root, "a.bin"), make([]byte, 100), 0644)
	os.WriteFile(filepath.Join(root, "sub", "b.bin"), make([]byte, 50), 0644)
	os.WriteFile(filepath.Join(keep, "doc.txt"), []byte("keep"), 0644)
	if out, err := exec.Command("cmd", "/c", "mklink", "/J", filepath.Join(root, "link"), keep).CombinedOutput(); err != nil {
		t.Fatalf("mklink: %v %s", err, out)
	}
	res := &CleanResult{}
	clearRoot(root, 0, res)
	if res.RemovedBytes != 150 || res.RemovedFiles != 2 {
		t.Fatalf("removed %d bytes %d files", res.RemovedBytes, res.RemovedFiles)
	}
	if _, err := os.Stat(root); err != nil {
		t.Fatal("root folder must stay")
	}
	if _, err := os.Stat(filepath.Join(keep, "doc.txt")); err != nil {
		t.Fatal("junction target was deleted")
	}
	left, _ := os.ReadDir(root)
	if len(left) != 0 {
		t.Fatalf("left behind: %v", left)
	}
}

func TestClearRootMinAge(t *testing.T) {
	root := t.TempDir()
	old := filepath.Join(root, "old.tmp")
	fresh := filepath.Join(root, "new.tmp")
	os.WriteFile(old, []byte("x"), 0644)
	os.WriteFile(fresh, []byte("y"), 0644)
	past := time.Now().Add(-48 * time.Hour)
	os.Chtimes(old, past, past)
	res := &CleanResult{}
	clearRoot(root, 24, res)
	if _, err := os.Stat(old); err == nil {
		t.Fatal("old file should be gone")
	}
	if _, err := os.Stat(fresh); err != nil {
		t.Fatal("fresh file must stay")
	}
}
