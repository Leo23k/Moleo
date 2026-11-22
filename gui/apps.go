package main

import (
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"
	"unicode/utf8"

	"golang.org/x/sys/windows"
	"golang.org/x/sys/windows/registry"
)

// ---- Uninstall (delegates to bin/uninstall.ps1 -GuiJson) ---------------

type AppRecord struct {
	ID          string `json:"Id"`
	Name        string `json:"Name"`
	Publisher   string `json:"Publisher"`
	Version     string `json:"Version"`
	SizeKB      int64  `json:"SizeKB"`
	SizeHuman   string `json:"SizeHuman"`
	SizeChecked bool   `json:"SizeChecked"`
	Source      string `json:"Source"`
}

type AppResult struct {
	ID      string `json:"Id"`
	Name    string `json:"Name"`
	State   string `json:"State"`
	Details string `json:"Details"`
}

func (a *App) appsRequest(action string, ids []string, out any) error {
	if ids == nil {
		ids = []string{}
	}
	req, _ := json.Marshal(map[string]any{"action": action, "ids": ids})
	raw, err := a.runScript(string(req)+"\n", `bin\uninstall.ps1`, "-GuiJson")
	if err != nil {
		return err
	}
	// The JSON reply is the last line that starts with '{'.
	lines := strings.Split(strings.TrimSpace(raw), "\n")
	for i := len(lines) - 1; i >= 0; i-- {
		if l := strings.TrimSpace(lines[i]); strings.HasPrefix(l, "{") {
			var env struct {
				State string `json:"State"`
				Error string `json:"Error"`
			}
			_ = json.Unmarshal([]byte(l), &env)
			if env.State == "error" || env.Error != "" {
				return errors.New(env.Error)
			}
			return json.Unmarshal([]byte(l), out)
		}
	}
	return fmt.Errorf("no reply from uninstall.ps1: %s", strings.TrimSpace(raw))
}

func (a *App) ListApps() ([]AppRecord, error) {
	var r struct{ Items []AppRecord }
	if err := a.appsRequest("inventory", nil, &r); err != nil {
		return nil, err
	}
	return r.Items, nil
}

// UninstallApps runs each app's uninstaller, then removes verified
// leftovers (files to the Recycle Bin, registry keys backed up first).
func (a *App) UninstallApps(ids []string) ([]AppResult, error) {
	var r struct{ Results []AppResult }
	if err := a.appsRequest("uninstall", ids, &r); err != nil {
		return nil, err
	}
	return r.Results, nil
}

// ---- Updates (winget) --------------------------------------------------

type UpdateItem struct {
	Name      string `json:"name"`
	ID        string `json:"id"`
	Version   string `json:"version"`
	Available string `json:"available"`
	Source    string `json:"source"`
}

var spinnerJunk = regexp.MustCompile(`^[\s\-\\|/█▒]*`)

// parseWingetTable reads winget's fixed-width table using the header's
// column offsets (counted in runes).
func parseWingetTable(out string) []UpdateItem {
	var items []UpdateItem
	var cols []int
	for _, raw := range strings.Split(out, "\n") {
		line := raw
		if i := strings.LastIndex(line, "\r"); i >= 0 && i < len(line)-1 {
			line = line[i+1:]
		}
		line = strings.TrimRight(line, "\r ")
		if cols == nil {
			if strings.Contains(line, " Id ") && strings.Contains(line, "Version") && strings.Contains(line, "Available") {
				line = spinnerJunk.ReplaceAllString(line, "")
				r := []rune(line)
				for _, h := range []string{"Name", "Id", "Version", "Available", "Source"} {
					idx := strings.Index(line, h)
					if h == "Id" {
						idx = strings.Index(line, " Id ") + 1
					}
					cols = append(cols, utf8.RuneCountInString(line[:max(idx, 0)]))
				}
				_ = r
			}
			continue
		}
		if strings.HasPrefix(line, "---") || strings.TrimSpace(line) == "" {
			continue
		}
		r := []rune(line)
		if len(r) < cols[3] {
			break // footer ("N upgrades available")
		}
		field := func(i int) string {
			start := cols[i]
			end := len(r)
			if i+1 < len(cols) {
				end = min(cols[i+1], len(r))
			}
			if start >= len(r) {
				return ""
			}
			return strings.TrimSpace(string(r[start:end]))
		}
		it := UpdateItem{Name: field(0), ID: field(1), Version: field(2), Available: field(3), Source: field(4)}
		if it.ID != "" && it.Available != "" {
			items = append(items, it)
		}
	}
	return items
}

func (a *App) ListUpdates() ([]UpdateItem, error) {
	out, err := hidden("winget", "upgrade", "--include-unknown", "--accept-source-agreements", "--disable-interactivity").Output()
	items := parseWingetTable(string(out))
	if len(items) == 0 && err != nil && !strings.Contains(string(out), "No installed package") {
		return nil, fmt.Errorf("winget failed: %v", err)
	}
	return items, nil
}

func (a *App) UpdateApp(id string) (string, error) {
	if !regexp.MustCompile(`^[\w.+\-]+$`).MatchString(id) {
		return "", errors.New("invalid package id")
	}
	out, err := hidden("winget", "upgrade", "--id", id, "--exact", "--silent",
		"--accept-source-agreements", "--accept-package-agreements", "--disable-interactivity").CombinedOutput()
	text := string(out)
	if i := strings.LastIndex(text, "\r"); i >= 0 {
		text = text[i+1:]
	}
	if err != nil {
		return strings.TrimSpace(text), fmt.Errorf("update failed: %v", err)
	}
	return strings.TrimSpace(text), nil
}

// ---- Startup ----------------------------------------------------------

type StartupItem struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	Command   string `json:"command"`
	Location  string `json:"location"`
	Enabled   bool   `json:"enabled"`
	NeedAdmin bool   `json:"needAdmin"`
	approved  approvedRef
}

// approvedRef points at the StartupApproved value Task Manager uses to
// enable/disable an entry without deleting it.
type approvedRef struct {
	Root  registry.Key
	Key   string
	Value string
}

const runKey = `Software\Microsoft\Windows\CurrentVersion\Run`
const approvedBase = `Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\`

func approvedEnabled(ref approvedRef) bool {
	k, err := registry.OpenKey(ref.Root, ref.Key, registry.QUERY_VALUE)
	if err != nil {
		return true
	}
	defer k.Close()
	b, _, err := k.GetBinaryValue(ref.Value)
	if err != nil || len(b) == 0 {
		return true
	}
	return b[0]&1 == 0 // 02/06 = enabled, 03/07 = disabled
}

func (a *App) ListStartup() ([]StartupItem, error) {
	var items []StartupItem
	add := func(root registry.Key, rootName, path, approvedSub string, admin bool) {
		k, err := registry.OpenKey(root, path, registry.QUERY_VALUE)
		if err != nil {
			return
		}
		defer k.Close()
		names, _ := k.ReadValueNames(0)
		for _, n := range names {
			cmd, _, err := k.GetStringValue(n)
			if err != nil || n == "" {
				continue
			}
			ref := approvedRef{root, approvedBase + approvedSub, n}
			items = append(items, StartupItem{Name: n, Command: cmd, Location: rootName + `\` + path,
				Enabled: approvedEnabled(ref), NeedAdmin: admin, approved: ref})
		}
	}
	add(registry.CURRENT_USER, "HKCU", runKey, "Run", false)
	add(registry.LOCAL_MACHINE, "HKLM", runKey, "Run", true)
	add(registry.LOCAL_MACHINE, "HKLM", `Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run`, "Run32", true)

	folders := []struct {
		dir   string
		root  registry.Key
		admin bool
	}{
		{filepath.Join(os.Getenv("APPDATA"), `Microsoft\Windows\Start Menu\Programs\Startup`), registry.CURRENT_USER, false},
		{filepath.Join(os.Getenv("ProgramData"), `Microsoft\Windows\Start Menu\Programs\StartUp`), registry.LOCAL_MACHINE, true},
	}
	for _, f := range folders {
		entries, _ := os.ReadDir(f.dir)
		for _, e := range entries {
			if e.IsDir() || strings.EqualFold(e.Name(), "desktop.ini") {
				continue
			}
			ref := approvedRef{f.root, approvedBase + "StartupFolder", e.Name()}
			items = append(items, StartupItem{Name: strings.TrimSuffix(e.Name(), filepath.Ext(e.Name())),
				Command: filepath.Join(f.dir, e.Name()), Location: f.dir,
				Enabled: approvedEnabled(ref), NeedAdmin: f.admin, approved: ref})
		}
	}
	sort.SliceStable(items, func(i, j int) bool { return strings.ToLower(items[i].Name) < strings.ToLower(items[j].Name) })
	a.mu.Lock()
	a.startupItems = map[string]StartupItem{}
	for i := range items {
		items[i].ID = fmt.Sprintf("s%d", i)
		a.startupItems[items[i].ID] = items[i]
	}
	a.mu.Unlock()
	return items, nil
}

func backupDir() string {
	d := filepath.Join(os.Getenv("LOCALAPPDATA"), "Moleo", "backups")
	_ = os.MkdirAll(d, 0755)
	return d
}

// SetStartup enables or disables an entry the way Task Manager does.
// The previous state of every startup entry is saved to a JSON backup
// before anything changes.
func (a *App) SetStartup(id string, enabled bool) error {
	a.mu.Lock()
	it, ok := a.startupItems[id]
	all := make([]StartupItem, 0, len(a.startupItems))
	for _, v := range a.startupItems {
		all = append(all, v)
	}
	a.mu.Unlock()
	if !ok {
		return errors.New("startup list changed, refresh it")
	}
	backup, _ := json.MarshalIndent(map[string]any{"time": time.Now(), "change": it.Name, "enabled": enabled, "entries": all}, "", "  ")
	name := filepath.Join(backupDir(), "startup-"+time.Now().Format("20060102-150405")+".json")
	if err := os.WriteFile(name, backup, 0644); err != nil {
		return fmt.Errorf("could not write backup: %w", err)
	}

	k, _, err := registry.CreateKey(it.approved.Root, it.approved.Key, registry.SET_VALUE)
	if err != nil {
		if it.NeedAdmin {
			return errors.New("this entry is for all users: run Moleo as administrator to change it")
		}
		return err
	}
	defer k.Close()
	data := make([]byte, 12)
	if enabled {
		data[0] = 2
	} else {
		data[0] = 3
		ft := windows.NsecToFiletime(time.Now().UnixNano())
		binary.LittleEndian.PutUint32(data[4:], ft.LowDateTime)
		binary.LittleEndian.PutUint32(data[8:], ft.HighDateTime)
	}
	return k.SetBinaryValue(it.approved.Value, data)
}

// OpenBackups shows the backup folder in Explorer.
func (a *App) OpenBackups() { hidden("explorer.exe", backupDir()).Start() }
