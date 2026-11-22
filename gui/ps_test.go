package main

import "testing"

// Guards the PowerShell path bug (a "\v" turned into a control character).
func TestListAppsLive(t *testing.T) {
	if testing.Short() {
		t.Skip()
	}
	a := &App{}
	a.root, _ = findRepoRoot()
	apps, err := a.ListApps()
	if err != nil {
		t.Fatal(err)
	}
	if len(apps) == 0 {
		t.Fatal("no apps")
	}
	t.Logf("%d apps, first %s", len(apps), apps[0].Name)
}

func TestOptimizeLive(t *testing.T) {
	if testing.Short() {
		t.Skip()
	}
	a := &App{}
	a.root, _ = findRepoRoot()
	tasks, err := a.OptimizeCatalog()
	if err != nil || len(tasks) == 0 {
		t.Fatal(err)
	}
	r, err := a.RunOptimizeTask("disk-health") // read-only check
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("%d tasks; disk-health: %s %q", len(tasks), r.State, r.Details)
}

func TestStatusLive(t *testing.T) {
	a := &App{}
	a.Status()
	s, err := a.Status()
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("%s %s cpu=%.0f%% mem=%d/%d rx=%.0f top=%v bat=%d", s.Host, s.CPUModel, s.CPU, s.MemUsed>>20, s.MemTotal>>20, s.NetRx, s.TopMem[:2], s.Battery)
}

func TestAppIconsLive(t *testing.T) {
	if testing.Short() {
		t.Skip()
	}
	m, err := (&App{}).AppIcons(true)
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("%d icons; valorant=%v docker=%v", len(m), m["valorant"] != "", m["docker desktop"] != "")
}
