package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestFindDuplicatesAndLarge(t *testing.T) {
	dir := t.TempDir()
	same := make([]byte, 200<<10)
	for i := range same {
		same[i] = byte(i)
	}
	other := append([]byte{}, same...)
	other[len(other)-1] ^= 1 // same size and prefix, different tail
	os.MkdirAll(filepath.Join(dir, "a"), 0755)
	os.WriteFile(filepath.Join(dir, "one.bin"), same, 0644)
	os.WriteFile(filepath.Join(dir, "a", "copy.bin"), same, 0644)
	os.WriteFile(filepath.Join(dir, "near.bin"), other, 0644)
	os.WriteFile(filepath.Join(dir, "big.iso"), make([]byte, 3<<20), 0644)

	a := &App{}
	groups, err := a.FindDuplicates([]string{dir}, 1)
	if err != nil {
		t.Fatal(err)
	}
	if len(groups) != 1 || len(groups[0].Files) != 2 || groups[0].Waste != int64(len(same)) {
		t.Fatalf("groups: %+v", groups)
	}
	big, err := a.FindLargeFiles(dir, 1, 10)
	if err != nil {
		t.Fatal(err)
	}
	if len(big) != 1 || big[0].Name != "big.iso" || big[0].Kind != "disk image" {
		t.Fatalf("large: %+v", big)
	}
}

func TestDestFor(t *testing.T) {
	if got := destFor(`C:\Users\me\.gradle`, "D:"); got != `D:\MoleoMoved\Users\me\.gradle` {
		t.Fatal(got)
	}
	if checkDest("C:", 0) == nil {
		t.Fatal("system drive must be refused")
	}
}

// Moves a temp folder to D: through a junction and back.
func TestMoveAndUndoLive(t *testing.T) {
	if testing.Short() {
		t.Skip()
	}
	if _, err := os.Stat(`D:\`); err != nil {
		t.Skip("no D: drive")
	}
	src := filepath.Join(t.TempDir(), "movetest")
	os.MkdirAll(filepath.Join(src, "sub"), 0755)
	os.WriteFile(filepath.Join(src, "sub", "f.txt"), []byte("hello"), 0644)
	a := &App{}
	id := "custom:" + src
	dst, err := a.MoveFolder(id, "D:")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(dst, `D:\MoleoMoved\`) || !isJunction(src) {
		t.Fatalf("dst=%s junction=%v", dst, isJunction(src))
	}
	if b, _ := os.ReadFile(filepath.Join(src, "sub", "f.txt")); string(b) != "hello" {
		t.Fatal("file not reachable through the junction")
	}
	if err := a.UndoMove(id); err != nil {
		t.Fatal(err)
	}
	if isJunction(src) {
		t.Fatal("junction still there after undo")
	}
	if b, _ := os.ReadFile(filepath.Join(src, "sub", "f.txt")); string(b) != "hello" {
		t.Fatal("file not back after undo")
	}
	os.RemoveAll(filepath.Join(`D:\MoleoMoved`, strings.TrimPrefix(src, filepath.VolumeName(src))))
}

func TestQuickItemsLive(t *testing.T) {
	if testing.Short() {
		t.Skip()
	}
	for _, it := range (&App{}).QuickItems() {
		t.Logf("%-16s avail=%v bytes=%d %s", it.ID, it.Available, it.Bytes, it.Estimate)
	}
	for _, c := range (&App{}).MoveCandidates() {
		t.Logf("move %-12s %-10s %d %s", c.ID, c.Kind, c.Bytes>>20, c.Path)
	}
}
