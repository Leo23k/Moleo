package main

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"strings"
	"sync/atomic"
	"time"
)

type guiAnalyzeEntry struct {
	Name  string `json:"name"`
	Path  string `json:"path"`
	Size  int64  `json:"size"`
	IsDir bool   `json:"is_dir"`
	State string `json:"state"`
}

type guiAnalyzeFile struct {
	Name string `json:"name"`
	Path string `json:"path"`
	Size int64  `json:"size"`
}

type guiAnalyzeEvent struct {
	Type        string            `json:"type"`
	Path        string            `json:"path,omitempty"`
	State       string            `json:"state,omitempty"`
	Error       string            `json:"error,omitempty"`
	Files       int64             `json:"files_scanned,omitempty"`
	Dirs        int64             `json:"dirs_scanned,omitempty"`
	Bytes       int64             `json:"bytes_scanned,omitempty"`
	CurrentPath string            `json:"current_path,omitempty"`
	TotalSize   int64             `json:"total_size,omitempty"`
	TotalFiles  int64             `json:"total_files,omitempty"`
	Entries     []guiAnalyzeEntry `json:"entries,omitempty"`
	LargeFiles  []guiAnalyzeFile  `json:"large_files,omitempty"`
}

// runGUIJSON exposes the existing scanner to Moleo as NDJSON without changing
// the interactive Analyze command or introducing another filesystem walker.
func runGUIJSON(path string, stdout, stderr io.Writer) int {
	target, isOverview, err := resolveScanTarget(path, nil)
	if err != nil {
		fmt.Fprintln(stderr, err)
		return 1
	}
	if isOverview {
		fmt.Fprintln(stderr, "analyze GUI mode requires a directory path")
		return 1
	}
	info, err := os.Stat(target)
	if err != nil || !info.IsDir() {
		if err != nil {
			fmt.Fprintf(stderr, "cannot scan %s: %v\n", target, err)
		} else {
			fmt.Fprintf(stderr, "cannot scan %s: path is not a directory\n", target)
		}
		return 1
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go watchGUICancel(os.Stdin, cancel)
	var filesScanned, dirsScanned, bytesScanned int64
	var currentPath atomic.Value
	currentPath.Store(target)
	resultChan := make(chan scanResult, 1)
	errChan := make(chan error, 1)
	go func() {
		result, scanErr := scanPathConcurrent(ctx, target, nil, &filesScanned, &dirsScanned, &bytesScanned, &currentPath)
		if scanErr != nil {
			errChan <- scanErr
			return
		}
		resultChan <- result
	}()

	encoder := json.NewEncoder(stdout)
	ticker := time.NewTicker(250 * time.Millisecond)
	defer ticker.Stop()
	for {
		select {
		case result := <-resultChan:
			entries := make([]guiAnalyzeEntry, 0, len(result.Entries))
			for _, entry := range result.Entries {
				entries = append(entries, guiAnalyzeEntry{Name: entry.Name, Path: entry.Path, Size: entry.Size, IsDir: entry.IsDir, State: entry.State.String()})
			}
			largeFiles := make([]guiAnalyzeFile, 0, len(result.LargeFiles))
			for _, file := range result.LargeFiles {
				largeFiles = append(largeFiles, guiAnalyzeFile{Name: file.Name, Path: file.Path, Size: file.Size})
			}
			if err := encoder.Encode(guiAnalyzeEvent{Type: "result", Path: target, State: result.State.String(), TotalSize: result.TotalSize, TotalFiles: result.TotalFiles, Entries: entries, LargeFiles: largeFiles}); err != nil {
				fmt.Fprintf(stderr, "cannot write analyze result: %v\n", err)
				return 1
			}
			return 0
		case err := <-errChan:
			fmt.Fprintf(stderr, "analyze scan failed: %v\n", err)
			return 1
		case <-ticker.C:
			path, _ := currentPath.Load().(string)
			if err := encoder.Encode(guiAnalyzeEvent{Type: "progress", Files: atomic.LoadInt64(&filesScanned), Dirs: atomic.LoadInt64(&dirsScanned), Bytes: atomic.LoadInt64(&bytesScanned), CurrentPath: path}); err != nil {
				cancel()
				fmt.Fprintf(stderr, "cannot write analyze progress: %v\n", err)
				return 1
			}
		}
	}
}

func watchGUICancel(input io.Reader, cancel context.CancelFunc) {
	scanner := bufio.NewScanner(input)
	if scanner.Scan() && strings.EqualFold(strings.TrimSpace(scanner.Text()), "cancel") {
		cancel()
	}
}
