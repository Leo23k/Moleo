package main

import (
	"os"
	"path/filepath"
	"strings"
)

// Warnings shown with a ⚠ next to items whose removal costs something:
// data that cannot come back, must be downloaded again, or that Windows
// and other apps rely on. English text; the UI translates it.

var cleanWarnings = map[string]string{
	"Windows Update download cache": "Updates that are not installed yet will download again.",
	"Crash dumps":                   "Only needed if you want to report or debug a crash.",
	"Maven repository":              "Large download: every project's dependencies must download again.",
	"Gradle cache":                  "Large download: every project's dependencies must download again.",
	"Conda packages":                "Environments may need packages to download again.",
	"Go module downloads":           "Modules download again on the next build.",
	"Cargo registry cache":          "Crates download again on the next build.",
	"NuGet cache":                   "Packages download again on the next restore.",
	"Playwright browsers":           "Browser tests will not run until browsers are installed again.",
	"Puppeteer browsers":            "Tests will not run until the browser downloads again.",
	"Unity cache":                   "Unity packages download again when you open a project.",
}

func cleanWarning(e *CleanEntry) string {
	switch e.Category {
	case "bin":
		return "Deleted permanently. This cannot be undone."
	case "chat":
		return "Old chat images and videos must download again; expired ones are gone."
	}
	return cleanWarnings[e.Name]
}

// pathWarning explains why a file or folder in the disk map matters.
func pathWarning(p string) string {
	clean := strings.ToLower(filepath.Clean(p))
	base := filepath.Base(clean)
	under := func(env string, subs ...string) bool {
		root := os.Getenv(env)
		if root == "" {
			return false
		}
		r := strings.ToLower(filepath.Join(append([]string{root}, subs...)...))
		return clean == r || strings.HasPrefix(clean, r+`\`)
	}
	switch {
	case base == "pagefile.sys" || base == "hiberfil.sys" || base == "swapfile.sys":
		return "Used by Windows. Change it in system settings instead of deleting it."
	case base == "system volume information":
		return "Windows restore points. Manage them in System Protection."
	case base == "$recycle.bin":
		return "The Recycle Bin. Empty it from the Clean tab."
	case under("SystemRoot"):
		return "Part of Windows. Deleting files here can stop Windows from starting."
	case under("ProgramFiles"), under("ProgramFiles(x86)"):
		return "Installed apps. Remove them from the Apps tab so they uninstall cleanly."
	case under("ProgramData"):
		return "Shared app data and settings. Apps may stop working."
	case under("USERPROFILE", "AppData"):
		return "App settings and data. Use the Clean tab for caches."
	case under("USERPROFILE", "Documents"), under("USERPROFILE", "Desktop"), under("USERPROFILE", "Pictures"),
		under("USERPROFILE", "Videos"), under("USERPROFILE", "Music"), under("USERPROFILE", "OneDrive"),
		under("OneDrive"):
		return "Your personal files. Check before removing."
	case base == ".git":
		return "Version history of a project. Removing it loses all commits."
	}
	return ""
}
