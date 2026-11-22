package main

import (
	"os"
	"sort"
	"strings"
	"time"

	"github.com/shirou/gopsutil/v3/cpu"
	"github.com/shirou/gopsutil/v3/host"
	"github.com/shirou/gopsutil/v3/mem"
	"github.com/shirou/gopsutil/v3/net"
	"github.com/shirou/gopsutil/v3/process"
)

type ProcInfo struct {
	Name string  `json:"name"`
	PID  int32   `json:"pid"`
	CPU  float64 `json:"cpu"`
	Mem  uint64  `json:"mem"`
}

type StatusSnapshot struct {
	Host      string      `json:"host"`
	OS        string      `json:"os"`
	Uptime    uint64      `json:"uptime"`
	CPUModel  string      `json:"cpuModel"`
	Cores     int         `json:"cores"`
	CPU       float64     `json:"cpu"`
	PerCore   []float64   `json:"perCore"`
	MemTotal  uint64      `json:"memTotal"`
	MemUsed   uint64      `json:"memUsed"`
	SwapTotal uint64      `json:"swapTotal"`
	SwapUsed  uint64      `json:"swapUsed"`
	Drives    []DriveInfo `json:"drives"`
	NetRx     float64     `json:"netRx"` // bytes/s
	NetTx     float64     `json:"netTx"`
	TopCPU    []ProcInfo  `json:"topCpu"`
	TopMem    []ProcInfo  `json:"topMem"`
	Battery   int         `json:"battery"` // -1 when there is none
	Charging  bool        `json:"charging"`
}

type statusState struct {
	lastNet  time.Time
	rx, tx   uint64
	procPrev map[int32]float64 // pid -> total cpu seconds
	procTime time.Time
	model    string
}

// Status returns one snapshot; the page polls it every second or two.
func (a *App) Status() (*StatusSnapshot, error) {
	s := &StatusSnapshot{Battery: -1}
	st := &a.status
	if hi, err := host.Info(); err == nil {
		s.Host, s.Uptime = hi.Hostname, hi.Uptime
		s.OS = strings.TrimSpace(hi.Platform + " " + hi.PlatformVersion)
	}
	if st.model == "" {
		if ci, err := cpu.Info(); err == nil && len(ci) > 0 {
			st.model = strings.TrimSpace(ci[0].ModelName)
		}
	}
	s.CPUModel = st.model
	s.Cores, _ = cpu.Counts(true)
	if per, err := cpu.Percent(300*time.Millisecond, true); err == nil && len(per) > 0 {
		s.PerCore = per
		var sum float64
		for _, p := range per {
			sum += p
		}
		s.CPU = sum / float64(len(per))
	}
	if vm, err := mem.VirtualMemory(); err == nil {
		s.MemTotal, s.MemUsed = vm.Total, vm.Used
	}
	if sw, err := mem.SwapMemory(); err == nil {
		s.SwapTotal, s.SwapUsed = sw.Total, sw.Used
	}
	s.Drives = a.ListDrives()

	if io, err := net.IOCounters(false); err == nil && len(io) > 0 {
		now := time.Now()
		if !st.lastNet.IsZero() {
			dt := now.Sub(st.lastNet).Seconds()
			if dt > 0 && io[0].BytesRecv >= st.rx && io[0].BytesSent >= st.tx {
				s.NetRx = float64(io[0].BytesRecv-st.rx) / dt
				s.NetTx = float64(io[0].BytesSent-st.tx) / dt
			}
		}
		st.lastNet, st.rx, st.tx = now, io[0].BytesRecv, io[0].BytesSent
	}

	s.TopCPU, s.TopMem = topProcesses(st, s.Cores)
	s.Battery, s.Charging = batteryStatus()
	return s, nil
}

func topProcesses(st *statusState, cores int) ([]ProcInfo, []ProcInfo) {
	procs, err := process.Processes()
	if err != nil {
		return nil, nil
	}
	now := time.Now()
	dt := now.Sub(st.procTime).Seconds()
	prev := st.procPrev
	next := make(map[int32]float64, len(procs))
	var list []ProcInfo
	self := int32(os.Getpid())
	for _, p := range procs {
		if p.Pid == 0 || p.Pid == 4 {
			continue
		}
		name, err := p.Name()
		if err != nil || name == "" {
			continue
		}
		info := ProcInfo{Name: name, PID: p.Pid}
		if t, err := p.Times(); err == nil {
			total := t.User + t.System
			next[p.Pid] = total
			if old, ok := prev[p.Pid]; ok && dt > 0 && cores > 0 {
				info.CPU = (total - old) / dt / float64(cores) * 100
			}
		}
		if m, err := p.MemoryInfo(); err == nil {
			info.Mem = m.RSS
		}
		if p.Pid == self {
			info.Name += " (Moleo)"
		}
		list = append(list, info)
	}
	st.procPrev, st.procTime = next, now

	// Merge processes with the same name (e.g. many chrome.exe).
	merged := map[string]*ProcInfo{}
	for _, p := range list {
		if m, ok := merged[p.Name]; ok {
			m.CPU += p.CPU
			m.Mem += p.Mem
		} else {
			cp := p
			merged[p.Name] = &cp
		}
	}
	var all []ProcInfo
	for _, m := range merged {
		all = append(all, *m)
	}
	byCPU := append([]ProcInfo{}, all...)
	sort.Slice(byCPU, func(i, j int) bool { return byCPU[i].CPU > byCPU[j].CPU })
	byMem := append([]ProcInfo{}, all...)
	sort.Slice(byMem, func(i, j int) bool { return byMem[i].Mem > byMem[j].Mem })
	return byCPU[:min(6, len(byCPU))], byMem[:min(6, len(byMem))]
}
