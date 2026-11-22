package main

import (
	"os"
	"path/filepath"
	"runtime"
	"sync/atomic"
	"testing"
	"time"
)

func scanForTest(root string) *node {
	var f, b atomic.Int64
	var cur atomic.Value
	var cancel atomic.Bool
	return scanDir(root, filepath.Base(root), make(chan struct{}, runtime.NumCPU()*4), &f, &b, &cur, &cancel)
}

func TestScanAndLevel(t *testing.T) {
	root := t.TempDir()
	os.MkdirAll(filepath.Join(root, "big", "deep"), 0755)
	os.WriteFile(filepath.Join(root, "big", "deep", "a.bin"), make([]byte, 5000), 0644)
	os.WriteFile(filepath.Join(root, "small.txt"), make([]byte, 10), 0644)
	for i := 0; i < keepFilesPerDir+5; i++ {
		os.WriteFile(filepath.Join(root, "big", string(rune('a'+i%26))+string(rune('a'+i/26))+".f"), []byte("x"), 0644)
	}
	a := &App{}
	a.analyze.root, a.analyze.tree = root, scanForTest(root)
	if a.analyze.tree.size != 5000+10+int64(keepFilesPerDir+5) {
		t.Fatalf("size %d", a.analyze.tree.size)
	}
	lvl, err := a.AnalyzeLevel(filepath.Join(root, "big"))
	if err != nil {
		t.Fatal(err)
	}
	if lvl.Items[0].Name != "deep" || !lvl.Items[0].IsDir {
		t.Fatalf("%+v", lvl.Items[0])
	}
	var other AnalyzeItem
	for _, it := range lvl.Items {
		if it.Other {
			other = it
		}
	}
	if other.Files != 5 || other.Size != 5 {
		t.Fatalf("expected 5 grouped small files, got %+v", other)
	}
	a.dropFromTree(filepath.Join(root, "big", "deep"))
	if a.analyze.tree.size != 10+int64(keepFilesPerDir+5) {
		t.Fatalf("after drop size %d", a.analyze.tree.size)
	}
}

func TestScanProfileSpeed(t *testing.T) {
	if testing.Short() {
		t.Skip()
	}
	start := time.Now()
	n := scanForTest(os.Getenv("USERPROFILE"))
	t.Logf("%s: %.1f GB, %d files in %s", os.Getenv("USERPROFILE"), float64(n.size)/1e9, n.files, time.Since(start))
}
