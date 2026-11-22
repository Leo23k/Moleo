package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestPathWarning(t *testing.T) {
	home := os.Getenv("USERPROFILE")
	cases := map[string]bool{
		filepath.Join(os.Getenv("SystemRoot"), "System32"): true,
		filepath.Join(home, "Documents", "cv.docx"):        true,
		filepath.Join(home, "AppData"):                     true,
		`C:\pagefile.sys`:                                  true,
		`D:\Games\Cities`:                                  false,
		filepath.Join(home, "Documentsx"):                  false, // prefix must end at a separator
	}
	for p, want := range cases {
		if got := pathWarning(p) != ""; got != want {
			t.Errorf("%s: warn=%v, want %v", p, got, want)
		}
	}
}

func TestCleanWarning(t *testing.T) {
	if cleanWarning(&CleanEntry{Category: "bin"}) == "" || cleanWarning(&CleanEntry{Category: "dev", Name: "Maven repository"}) == "" {
		t.Fatal("expected warnings")
	}
	if cleanWarning(&CleanEntry{Category: "system", Name: "User temp files"}) != "" {
		t.Fatal("temp files should not warn")
	}
}

func TestRunningOwner(t *testing.T) {
	procs := map[string]bool{"chrome.exe": true, "code.exe": true, "claude.exe": true}
	cases := map[string]string{
		"Chrome cache": "Chrome", "VS Code extension cache": "VS Code extension", "VS Code cache": "VS Code",
		"Edge cache": "", "Claude Code logs & temp": "Claude Code logs & temp", "Codex logs & cache": "", "Epic Games web cache & logs": "", "User temp files": "",
	}
	for name, want := range cases {
		if got := runningOwner(&CleanEntry{Name: name}, procs); got != want {
			t.Errorf("%s: got %q want %q", name, got, want)
		}
	}
	if ownerKey("Epic Games web cache & logs") != "Epic Games web" || ownerKey("Steam app cache") != "Steam app" {
		t.Fatal("ownerKey")
	}
	if len(runningProcesses()) < 10 {
		t.Fatal("process list looks empty")
	}
}
