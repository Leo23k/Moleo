package main

import (
	"strings"
	"unsafe"

	"golang.org/x/sys/windows"
)

// Clearing an app's cache while the app runs can leave it broken until it
// restarts (for example, a browser's GPU cache: video then draws wrongly).
// Cache entries are therefore tied to the processes that use them.

// cacheOwners maps a Clean entry name (without " cache") to process names.
var cacheOwners = map[string][]string{
	"Chrome": {"chrome.exe"}, "Edge": {"msedge.exe"}, "Brave": {"brave.exe"},
	"Opera": {"opera.exe"}, "Vivaldi": {"vivaldi.exe"}, "Cốc Cốc": {"browser.exe"},
	"Firefox": {"firefox.exe"},
	"Discord": {"discord.exe", "discordptb.exe", "discordcanary.exe"}, "Slack": {"slack.exe"},
	"Teams (classic)": {"teams.exe"}, "Microsoft Teams": {"ms-teams.exe"}, "Messenger": {"messenger.exe"},
	"Signal": {"signal.exe"}, "Element": {"element.exe"}, "Zalo": {"zalo.exe"}, "Skype": {"skype.exe"},
	"WhatsApp (desktop)": {"whatsapp.exe"},
	"VS Code":            {"code.exe"}, "VS Code extension": {"code.exe"}, "VS Code Insiders": {"code - insiders.exe"},
	"VSCodium": {"vscodium.exe"}, "GitHub Desktop": {"githubdesktop.exe"}, "Postman": {"postman.exe"},
	"Insomnia": {"insomnia.exe"}, "Docker Desktop": {"docker desktop.exe"}, "MongoDB Compass": {"mongodbcompass.exe"},
	"Unity Hub": {"unity hub.exe"}, "Unity": {"unity.exe", "unity hub.exe"},
	"Claude": {"claude.exe"}, "Codex": {"codex.exe"}, "ChatGPT": {"chatgpt.exe"}, "Cursor": {"cursor.exe"},
	"Windsurf": {"windsurf.exe"}, "Antigravity": {"antigravity.exe"}, "Trae": {"trae.exe"}, "Kiro": {"kiro.exe"},
	"Perplexity": {"perplexity.exe"}, "LM Studio": {"lm studio.exe"}, "Jan": {"jan.exe"}, "Ollama app": {"ollama app.exe"},
	"Figma": {"figma.exe"}, "Notion": {"notion.exe"}, "Obsidian": {"obsidian.exe"}, "Logseq": {"logseq.exe"},
	"Spotify (web)": {"spotify.exe"}, "Canva": {"canva.exe"},
	"Steam (web)": {"steam.exe", "steamwebhelper.exe"}, "Steam app": {"steam.exe"}, "Riot Client": {"riotclientservices.exe"},
	"Battle.net": {"battle.net.exe"}, "Epic Games web": {"epicgameslauncher.exe"}, "GOG Galaxy": {"galaxyclient.exe"},
	"EA app": {"eadesktop.exe"}, "Ubisoft Connect": {"upc.exe"},
	"Sublime Text": {"sublime_text.exe"}, "Zed": {"zed.exe"},
	// Entries matched by their full name.
	"Claude Code logs & temp": {"claude.exe"}, "Codex logs & cache": {"codex.exe"},
	"JetBrains caches & logs": {"idea64.exe", "pycharm64.exe", "webstorm64.exe", "goland64.exe", "rider64.exe", "clion64.exe", "phpstorm64.exe", "rustrover64.exe", "datagrip64.exe"},
	"Visual Studio caches":    {"devenv.exe"}, "Docker Desktop logs": {"docker desktop.exe"},
	"Office temp & web add-in cache": {"winword.exe", "excel.exe", "powerpnt.exe", "outlook.exe", "onenote.exe"},
	"OneDrive logs":                  {"onedrive.exe"}, "C/C++ IntelliSense cache": {"code.exe", "cursor.exe"},
	"Adobe media cache": {"adobe premiere pro.exe", "afterfx.exe", "photoshop.exe", "adobe media encoder.exe"},
}

// Graphics shader caches are used by every app that draws with the GPU.
var shaderCaches = map[string]bool{
	"NVIDIA shader cache": true, "AMD shader cache": true, "Intel shader cache": true,
	"DirectX shader cache": true, "Vulkan cache": true,
}

const shaderWarn = "Used by the graphics driver for every app. Games and video may stutter or draw wrongly until it rebuilds; clear it right before a restart."

func runningProcesses() map[string]bool {
	out := map[string]bool{}
	snap, err := windows.CreateToolhelp32Snapshot(windows.TH32CS_SNAPPROCESS, 0)
	if err != nil {
		return out
	}
	defer windows.CloseHandle(snap)
	var pe windows.ProcessEntry32
	pe.Size = uint32(unsafe.Sizeof(pe))
	for err = windows.Process32First(snap, &pe); err == nil; err = windows.Process32Next(snap, &pe) {
		out[strings.ToLower(windows.UTF16ToString(pe.ExeFile[:]))] = true
	}
	return out
}

func ownerKey(name string) string {
	for _, suffix := range []string{" cache & logs", " web cache & logs", " caches & logs", " cache"} {
		if strings.HasSuffix(name, suffix) {
			return strings.TrimSuffix(name, suffix)
		}
	}
	return name
}

// runningOwner returns the display name of a running app that uses e's
// cache, or "".
func runningOwner(e *CleanEntry, procs map[string]bool) string {
	key := e.Name
	if _, ok := cacheOwners[key]; !ok {
		key = ownerKey(e.Name)
	}
	for _, p := range cacheOwners[key] {
		if procs[p] {
			return key
		}
	}
	return ""
}
