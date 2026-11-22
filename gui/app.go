package main

import (
	"context"
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"syscall"
)

// App is bound to the frontend. Destructive work stays in the repo's
// PowerShell scripts, which own the safety rules (Recycle Bin, backups).
type App struct {
	ctx          context.Context
	root         string
	mu           sync.Mutex
	cleanEntries map[string]*CleanEntry
	startupItems map[string]StartupItem
	analyze      analyzeState
	binItems     map[string]binItem
	winfr        *exec.Cmd
	status       statusState
}

func NewApp() *App { return &App{} }

func (a *App) startup(ctx context.Context) {
	a.ctx = ctx
	a.root, _ = findRepoRoot()
}

// findRepoRoot walks up from the executable and the working directory
// until it finds mole.ps1.
func findRepoRoot() (string, error) {
	var starts []string
	if exe, err := os.Executable(); err == nil {
		starts = append(starts, filepath.Dir(exe))
	}
	if wd, err := os.Getwd(); err == nil {
		starts = append(starts, wd)
	}
	for _, dir := range starts {
		for d := dir; ; d = filepath.Dir(d) {
			if _, err := os.Stat(filepath.Join(d, "mole.ps1")); err == nil {
				return d, nil
			}
			if filepath.Dir(d) == d {
				break
			}
		}
	}
	return "", errors.New("mole.ps1 not found")
}

// Info reports whether the backend scripts were found.
func (a *App) Info() map[string]string {
	return map[string]string{"root": a.root}
}

// runScript runs a repo script with PowerShell 5.1 and returns stdout.
// input, when not empty, is written to the script's stdin.
func (a *App) runScript(input string, script string, args ...string) (string, error) {
	if a.root == "" {
		return "", errors.New("backend scripts not found (mole.ps1)")
	}
	full := append([]string{"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File",
		filepath.Join(a.root, script)}, args...)
	cmd := exec.Command(filepath.Join(os.Getenv("SystemRoot"), "System32", "WindowsPowerShell", "v1.0", "powershell.exe"), full...)
	cmd.Dir = a.root
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	if input != "" {
		cmd.Stdin = strings.NewReader(input)
	}
	out, err := cmd.Output()
	if ee, ok := err.(*exec.ExitError); ok {
		msg := strings.TrimSpace(string(ee.Stderr))
		if msg == "" {
			msg = strings.TrimSpace(string(out))
		}
		return string(out), errors.New(msg)
	}
	return string(out), err
}

// hidden runs a program without a console window.
func hidden(name string, args ...string) *exec.Cmd {
	cmd := exec.Command(name, args...)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	return cmd
}

// Reveal opens Explorer with the path selected.
func (a *App) Reveal(path string) {
	if fi, err := os.Stat(path); err == nil && fi.IsDir() {
		exec.Command("explorer.exe", path).Start()
		return
	}
	exec.Command("explorer.exe", "/select,", path).Start()
}
