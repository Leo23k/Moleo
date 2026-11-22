package main

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"io"
	"os"
	"path/filepath"
	"testing"
)

func TestRunGUIJSONScansFixtureDirectory(t *testing.T) {
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, "fixture.bin"), bytes.Repeat([]byte("x"), 4096), 0600); err != nil {
		t.Fatal(err)
	}
	if err := os.Mkdir(filepath.Join(root, "child"), 0700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "child", "nested.bin"), []byte("nested"), 0600); err != nil {
		t.Fatal(err)
	}

	var stdout, stderr bytes.Buffer
	if code := runGUIJSON(root, &stdout, &stderr); code != 0 {
		t.Fatalf("runGUIJSON() = %d, stderr: %s", code, stderr.String())
	}
	var result guiAnalyzeEvent
	scanner := bufio.NewScanner(&stdout)
	for scanner.Scan() {
		var event guiAnalyzeEvent
		if err := json.Unmarshal(scanner.Bytes(), &event); err != nil {
			t.Fatalf("invalid NDJSON event %q: %v", scanner.Text(), err)
		}
		if event.Type == "result" {
			result = event
		}
	}
	if err := scanner.Err(); err != nil {
		t.Fatal(err)
	}
	if result.Type != "result" || result.Path != root || result.State != "complete" {
		t.Fatalf("unexpected scan result: %+v", result)
	}
	if len(result.Entries) != 2 || result.TotalSize < 4102 {
		t.Fatalf("fixture files were not measured: %+v", result)
	}
}

func TestWatchGUICancel(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	reader, writer := io.Pipe()
	done := make(chan struct{})
	go func() { defer close(done); watchGUICancel(reader, cancel) }()
	if _, err := writer.Write([]byte("cancel\n")); err != nil {
		t.Fatal(err)
	}
	_ = writer.Close()
	<-done
	if ctx.Err() != context.Canceled {
		t.Fatal("cancel command did not cancel the scan context")
	}
}

func TestRunGUIJSONRejectsMissingPath(t *testing.T) {
	var stdout, stderr bytes.Buffer
	if code := runGUIJSON(filepath.Join(t.TempDir(), "missing"), &stdout, &stderr); code == 0 {
		t.Fatal("runGUIJSON() accepted a missing directory")
	}
	if stdout.Len() != 0 || stderr.Len() == 0 {
		t.Fatalf("missing path should report stderr only; stdout=%q stderr=%q", stdout.String(), stderr.String())
	}
}
