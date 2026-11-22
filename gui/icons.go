package main

import (
	_ "embed"
	"encoding/base64"
	"encoding/json"
	"os"
	"path/filepath"
	"time"
	"unicode/utf16"
)

//go:embed icons.ps1
var iconsScript string

func iconCachePath() string {
	d := filepath.Join(os.Getenv("LOCALAPPDATA"), "Moleo")
	_ = os.MkdirAll(d, 0755)
	return filepath.Join(d, "icons.json")
}

// AppIcons returns {lowercase app name: base64 PNG}. Results are cached for
// a day; refresh forces a new extraction.
func (a *App) AppIcons(refresh bool) (map[string]string, error) {
	cache := iconCachePath()
	if !refresh {
		if fi, err := os.Stat(cache); err == nil && time.Since(fi.ModTime()) < 24*time.Hour {
			if b, err := os.ReadFile(cache); err == nil {
				var m map[string]string
				if json.Unmarshal(b, &m) == nil {
					return m, nil
				}
			}
		}
	}
	u := utf16.Encode([]rune(iconsScript))
	buf := make([]byte, len(u)*2)
	for i, c := range u {
		buf[2*i], buf[2*i+1] = byte(c), byte(c>>8)
	}
	out, err := hidden(filepath.Join(os.Getenv("SystemRoot"), "System32", "WindowsPowerShell", "v1.0", "powershell.exe"),
		"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-EncodedCommand", base64.StdEncoding.EncodeToString(buf)).Output()
	if err != nil && len(out) == 0 {
		return nil, err
	}
	m := map[string]string{}
	if err := json.Unmarshal([]byte(lastJSONLine(string(out))), &m); err != nil {
		return nil, err
	}
	b, _ := json.Marshal(m)
	_ = os.WriteFile(cache, b, 0644)
	return m, nil
}
