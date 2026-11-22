package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestRestoreBinNeverOverwrites(t *testing.T) {
	dir := t.TempDir()
	orig := filepath.Join(dir, "docs", "report.txt")
	os.MkdirAll(filepath.Dir(orig), 0755)
	os.WriteFile(orig, []byte("newer file that must survive"), 0644)
	r := filepath.Join(dir, "$RABC.txt")
	i := filepath.Join(dir, "$IABC.txt")
	os.WriteFile(r, []byte("deleted content"), 0644)
	os.WriteFile(i, []byte("meta"), 0644)

	a := &App{binItems: map[string]binItem{"b0": {Original: orig, RPath: r, IPath: i}}}
	res := a.RestoreBin([]string{"b0"})
	if len(res.Restored) != 1 || len(res.Errors) != 0 {
		t.Fatalf("%+v", res)
	}
	if got, _ := os.ReadFile(orig); string(got) != "newer file that must survive" {
		t.Fatal("existing file was overwritten")
	}
	if got, _ := os.ReadFile(res.Restored[0]); string(got) != "deleted content" {
		t.Fatalf("restored copy wrong: %s", res.Restored[0])
	}
	if _, err := os.Stat(i); !os.IsNotExist(err) {
		t.Fatal("$I metadata should be removed after restore")
	}
}

func TestLooksLikeMediaAndSaveCopy(t *testing.T) {
	dir := t.TempDir()
	rec := filepath.Join(dir, "recording-noext")
	mp4 := append([]byte{0, 0, 0, 0x18}, []byte("ftypmp42")...)
	os.WriteFile(rec, append(mp4, make([]byte, 100)...), 0644)
	if !looksLikeMedia(rec) {
		t.Fatal("mp4 header not detected")
	}
	out := filepath.Join(dir, "out")
	os.Mkdir(out, 0755)
	res := (&App{}).SaveCopies([]string{rec}, out)
	if len(res.Restored) != 1 || filepath.Ext(res.Restored[0]) != ".mp4" {
		t.Fatalf("%+v", res)
	}
	if _, err := os.Stat(rec); err != nil {
		t.Fatal("source must be kept")
	}
}

func TestFindLostMediaLive(t *testing.T) {
	if testing.Short() {
		t.Skip()
	}
	files := (&App{}).FindLostMedia()
	t.Logf("%d files", len(files))
	by := map[string]int{}
	for _, f := range files {
		by[f.Source]++
	}
	t.Logf("%v", by)
	for _, f := range files[:min(8, len(files))] {
		t.Logf("%s %8d %s", f.Source, f.Size, f.Path)
	}
}
