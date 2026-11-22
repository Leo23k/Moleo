package main

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"sync"

	wruntime "github.com/wailsapp/wails/v2/pkg/runtime"
)

// Quick wins for a full system drive. Each item reports what it would free
// and runs one Windows tool when the user clicks it.

type QuickItem struct {
	ID         string   `json:"id"`
	Name       string   `json:"name"`
	Desc       string   `json:"desc"`
	Bytes      int64    `json:"bytes"`    // measured size, 0 when unknown
	Estimate   string   `json:"estimate"` // shown when Bytes is unknown
	Available  bool     `json:"available"`
	NeedsAdmin bool     `json:"needsAdmin"`
	Warn       string   `json:"warn"`
	Paths      []string `json:"paths,omitempty"`
}

func systemDrive() string {
	d := os.Getenv("SystemDrive")
	if d == "" {
		d = "C:"
	}
	return d
}

func fileSize(p string) int64 {
	if fi, err := os.Lstat(p); err == nil {
		return fi.Size()
	}
	return 0
}

func dirSize(p string) int64 {
	b, _ := measure(p, 0)
	return b
}

func findVHDX() []string {
	var out []string
	for _, g := range []string{
		`%LOCALAPPDATA%\Packages\*\LocalState\*.vhdx`,
		`%LOCALAPPDATA%\Docker\wsl\*\*.vhdx`,
		`%LOCALAPPDATA%\Docker\wsl\*\*\*.vhdx`,
		`%LOCALAPPDATA%\wsl\*\*.vhdx`,
		`%USERPROFILE%\AppData\Local\Podman\*\*.vhdx`,
	} {
		p, ok := expandEnv(g)
		if !ok {
			continue
		}
		m, _ := filepath.Glob(p)
		out = append(out, m...)
	}
	return out
}

var reShadowUsed = regexp.MustCompile(`(?i)Used Shadow Copy Storage space:\s*([\d.,]+)\s*(KB|MB|GB|TB)`)

func shadowStorageUsed() int64 {
	out, err := hidden("vssadmin", "list", "shadowstorage", "/for="+systemDrive()).Output()
	if err != nil {
		return 0
	}
	m := reShadowUsed.FindStringSubmatch(string(out))
	if m == nil {
		return 0
	}
	v, _ := strconv.ParseFloat(strings.ReplaceAll(m[1], ",", "."), 64)
	mult := map[string]float64{"KB": 1 << 10, "MB": 1 << 20, "GB": 1 << 30, "TB": 1 << 40}[strings.ToUpper(m[2])]
	return int64(v * mult)
}

func (a *App) QuickItems() []QuickItem {
	sd := systemDrive()
	var items []QuickItem
	var mu sync.Mutex
	var wg sync.WaitGroup
	add := func(it QuickItem) { mu.Lock(); items = append(items, it); mu.Unlock() }
	run := func(f func()) { wg.Add(1); go func() { defer wg.Done(); f() }() }

	run(func() {
		sz := fileSize(sd + `\hiberfil.sys`)
		add(QuickItem{ID: "hibernate", Name: "Hibernation file", Bytes: sz, Available: sz > 0, NeedsAdmin: true,
			Desc: "Turns off hibernation and deletes hiberfil.sys. Sleep still works; Fast Startup is turned off.",
			Warn: "You can turn it back on with: powercfg /hibernate on"})
	})
	run(func() {
		var paths []string
		var total int64
		for _, d := range []string{`\Windows.old`, `\$Windows.~BT`, `\$Windows.~WS`, `\$WinREAgent`} {
			p := sd + d
			if _, err := os.Lstat(p); err == nil {
				paths = append(paths, p)
				total += dirSize(p)
			}
		}
		add(QuickItem{ID: "windows-old", Name: "Previous Windows installation", Bytes: total, Available: len(paths) > 0, NeedsAdmin: true, Paths: paths,
			Desc: "Windows.old and leftover upgrade files.", Warn: "After this you cannot go back to the previous Windows version."})
	})
	run(func() {
		used := shadowStorageUsed()
		add(QuickItem{ID: "restore-points", Name: "Older restore points", Bytes: used, Available: true, NeedsAdmin: true,
			Estimate: "needs administrator to measure",
			Desc:     "Deletes every restore point on the system drive except the newest one.",
			Warn:     "You cannot roll Windows back to the deleted points."})
	})
	run(func() {
		add(QuickItem{ID: "component-store", Name: "Windows component store (WinSxS)", Available: true, NeedsAdmin: true, Estimate: "usually 1–5 GB",
			Desc: "Removes replaced versions of Windows components with DISM. Takes several minutes."})
	})
	run(func() {
		vhds := findVHDX()
		var total int64
		for _, v := range vhds {
			total += fileSize(v)
		}
		add(QuickItem{ID: "compact-vhdx", Name: "WSL and Docker virtual disks", Bytes: total, Available: len(vhds) > 0, NeedsAdmin: true, Paths: vhds,
			Estimate: "frees the empty space inside", Desc: "Virtual disks grow but never shrink. This shuts down WSL and compacts them.",
			Warn: "WSL and Docker are stopped while compacting."})
	})
	run(func() {
		out, _ := hidden("compact", "/compactos:query").Output()
		on := strings.Contains(strings.ToLower(string(out)), "is in the compact state")
		add(QuickItem{ID: "compact-os", Name: "Compress Windows files (Compact OS)", Available: !on, NeedsAdmin: true, Estimate: "usually 2–4 GB",
			Desc: "Compresses Windows system files. Slightly more CPU use when they load. Takes several minutes."})
	})
	wg.Wait()
	order := map[string]int{"hibernate": 0, "windows-old": 1, "compact-vhdx": 2, "restore-points": 3, "component-store": 4, "compact-os": 5}
	sort.Slice(items, func(i, j int) bool { return order[items[i].ID] < order[items[j].ID] })
	return items
}

// runStreaming runs a command and sends each output line as "space:line".
func (a *App) runStreaming(name string, args ...string) error {
	cmd := hidden(name, args...)
	pipe, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}
	cmd.Stderr = cmd.Stdout
	if err := cmd.Start(); err != nil {
		return err
	}
	sc := bufio.NewScanner(pipe)
	sc.Split(scanCRLF)
	for sc.Scan() {
		if l := strings.TrimSpace(strings.ReplaceAll(sc.Text(), "\x00", "")); l != "" && a.ctx != nil {
			wruntime.EventsEmit(a.ctx, "space:line", l)
		}
	}
	return cmd.Wait()
}

// RunQuick performs one quick item and returns the drive's free space after.
func (a *App) RunQuick(id string) (int64, error) {
	if !a.IsAdmin() {
		return 0, errors.New("this needs administrator: use Run as administrator")
	}
	sd := systemDrive()
	var err error
	switch id {
	case "hibernate":
		err = a.runStreaming("powercfg", "/hibernate", "off")
	case "windows-old":
		for _, d := range []string{`\Windows.old`, `\$Windows.~BT`, `\$Windows.~WS`, `\$WinREAgent`} {
			p := sd + d
			if _, e := os.Lstat(p); e != nil {
				continue
			}
			_ = a.runStreaming("takeown", "/F", p, "/R", "/A", "/D", "Y")
			_ = a.runStreaming("icacls", p, "/grant", "*S-1-5-32-544:F", "/T", "/C", "/Q")
			if e := os.RemoveAll(p); e != nil {
				err = e
			}
		}
	case "restore-points":
		ps := `$s = @(Get-CimInstance Win32_ShadowCopy | Where-Object { $_.VolumeName -eq (Get-CimInstance Win32_Volume -Filter "DriveLetter='` + sd + `'").DeviceID } | Sort-Object InstallDate)
if ($s.Count -le 1) { 'Only one restore point; nothing to delete.' } else { $s | Select-Object -SkipLast 1 | ForEach-Object { Remove-CimInstance $_; 'Deleted restore point from ' + $_.InstallDate } }`
		err = a.runStreaming("powershell", "-NoProfile", "-NonInteractive", "-Command", ps)
	case "component-store":
		err = a.runStreaming("dism", "/Online", "/Cleanup-Image", "/StartComponentCleanup")
	case "compact-vhdx":
		_ = a.runStreaming("wsl", "--shutdown")
		for _, v := range findVHDX() {
			script := filepath.Join(os.TempDir(), "moleo-compact.txt")
			body := fmt.Sprintf("select vdisk file=\"%s\"\nattach vdisk readonly\ncompact vdisk\ndetach vdisk\n", v)
			if e := os.WriteFile(script, []byte(body), 0644); e != nil {
				return 0, e
			}
			if e := a.runStreaming("diskpart", "/s", script); e != nil {
				err = e
			}
			os.Remove(script)
		}
	case "compact-os":
		err = a.runStreaming("compact", "/compactos:always")
	default:
		return 0, errors.New("unknown item")
	}
	return driveFree(sd), err
}

func driveFree(drive string) int64 {
	for _, d := range (&App{}).ListDrives() {
		if strings.EqualFold(d.Path[:2], drive[:2]) {
			return d.Free
		}
	}
	return 0
}

// ---- helpers shared with the move feature ------------------------------

func runOK(name string, args ...string) (string, error) {
	out, err := hidden(name, args...).CombinedOutput()
	return string(out), err
}

// robocopyMove moves a tree across drives; exit codes below 8 are success.
func robocopyMove(src, dst string) error {
	cmd := hidden("robocopy", src, dst, "/E", "/MOVE", "/COPY:DAT", "/DCOPY:T", "/R:1", "/W:1", "/NFL", "/NDL", "/NP", "/NJH", "/XJ")
	out, err := cmd.CombinedOutput()
	var ee *exec.ExitError
	if errors.As(err, &ee) && ee.ExitCode() < 8 {
		return nil
	}
	if err != nil {
		return fmt.Errorf("robocopy failed: %v %s", err, lastLines(string(out), 3))
	}
	return nil
}

func lastLines(s string, n int) string {
	lines := strings.Split(strings.TrimSpace(s), "\n")
	if len(lines) > n {
		lines = lines[len(lines)-n:]
	}
	return strings.TrimSpace(strings.Join(lines, " "))
}
