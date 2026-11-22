package main

import (
	"encoding/json"
	"errors"
	"os"
	"regexp"
	"strings"

	wruntime "github.com/wailsapp/wails/v2/pkg/runtime"
	"golang.org/x/sys/windows"
)

type OptimizeTask struct {
	ID          string `json:"Id"`
	Name        string `json:"Name"`
	Kind        string `json:"Kind"`
	Description string `json:"Description"`
	NeedsAdmin  bool   `json:"needsAdmin"`
}

type OptimizeResult struct {
	ID      string `json:"Id"`
	Name    string `json:"Name"`
	State   string `json:"State"`
	Details string `json:"Details"`
}

func lastJSONLine(raw string) string {
	lines := strings.Split(strings.TrimSpace(raw), "\n")
	for i := len(lines) - 1; i >= 0; i-- {
		if l := strings.TrimSpace(lines[i]); strings.HasPrefix(l, "{") || strings.HasPrefix(l, "[") {
			return l
		}
	}
	return ""
}

func (a *App) OptimizeCatalog() ([]OptimizeTask, error) {
	raw, err := a.runScript("", `bin\optimize.ps1`, "-GuiCatalog")
	if err != nil {
		return nil, err
	}
	var tasks []OptimizeTask
	if err := json.Unmarshal([]byte(lastJSONLine(raw)), &tasks); err != nil {
		return nil, errors.New("could not read the Optimize task list")
	}
	for i := range tasks {
		tasks[i].NeedsAdmin = strings.Contains(strings.ToLower(tasks[i].Description), "administrator")
	}
	return tasks, nil
}

var taskID = regexp.MustCompile(`^[a-z\-]+$`)

func (a *App) RunOptimizeTask(id string) (*OptimizeResult, error) {
	if !taskID.MatchString(id) {
		return nil, errors.New("invalid task")
	}
	raw, _ := a.runScript("", `bin\optimize.ps1`, "-GuiTask", id)
	var r OptimizeResult
	if err := json.Unmarshal([]byte(lastJSONLine(raw)), &r); err != nil {
		return &OptimizeResult{ID: id, State: "error", Details: strings.TrimSpace(raw)}, nil
	}
	return &r, nil
}

// IsAdmin reports whether Moleo runs elevated.
func (a *App) IsAdmin() bool {
	return windows.GetCurrentProcessToken().IsElevated()
}

// RelaunchAsAdmin starts an elevated copy (UAC prompt) and quits this one.
func (a *App) RelaunchAsAdmin() error {
	exe, err := os.Executable()
	if err != nil {
		return err
	}
	verb, _ := windows.UTF16PtrFromString("runas")
	file, _ := windows.UTF16PtrFromString(exe)
	cwd, _ := windows.UTF16PtrFromString(a.root)
	if err := windows.ShellExecute(0, verb, file, nil, cwd, windows.SW_NORMAL); err != nil {
		return errors.New("administrator start was cancelled")
	}
	wruntime.Quit(a.ctx)
	return nil
}
