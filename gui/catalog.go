package main

// Cleanup catalog. Only rebuildable data is listed: caches, logs, temp
// files and crash dumps. Conversations, projects, settings, saved games,
// screenshots/recordings and local AI models are never targets.

type category struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
}

var categories = []category{
	{"system", "System Data", "Windows temporary files, crash dumps and graphics caches. Rebuilt automatically."},
	{"apps", "App caches & logs", "App and browser caches, plus old logs."},
	{"dev", "Developer Tools", "Package manager and IDE caches. The first build afterwards is slower."},
	{"ai", "AI Tools", "AI app and CLI caches. Conversations, projects, and local models are kept."},
	{"chat", "Communication", "Chat app caches. Old chat images and videos must re-download."},
	{"games", "Games", "Launcher web caches and game logs. Games and saves are kept."},
	{"bin", "Recycle Bin", "Empties selected Recycle Bin items permanently."},
}

type target struct {
	Category string
	Name     string
	Paths    []string // env vars and * globs allowed
	MinAge   int      // only delete files older than N hours (0 = all)
}

// Chromium cache leaves inside an Electron or browser profile.
var chromiumLeaves = []string{
	`Cache`, `Code Cache`, `GPUCache`, `DawnCache`, `DawnGraphiteCache`, `DawnWebGPUCache`,
	`GrShaderCache`, `ShaderCache`, `Service Worker\CacheStorage`, `Service Worker\ScriptCache`,
}

type electronApp struct {
	Category string
	Name     string
	Dirs     []string
}

var electronApps = []electronApp{
	// AI tools
	{"ai", "Claude", []string{`%APPDATA%\Claude`}},
	{"ai", "Codex", []string{`%APPDATA%\Codex`, `%LOCALAPPDATA%\Codex`}},
	{"ai", "ChatGPT", []string{`%APPDATA%\ChatGPT`}},
	{"ai", "Cursor", []string{`%APPDATA%\Cursor`}},
	{"ai", "Windsurf", []string{`%APPDATA%\Windsurf`}},
	{"ai", "Antigravity", []string{`%APPDATA%\Antigravity`}},
	{"ai", "Trae", []string{`%APPDATA%\Trae`}},
	{"ai", "Kiro", []string{`%APPDATA%\Kiro`}},
	{"ai", "Perplexity", []string{`%APPDATA%\Perplexity`}},
	{"ai", "LM Studio", []string{`%APPDATA%\LM Studio`}},
	{"ai", "Jan", []string{`%APPDATA%\Jan`}},
	{"ai", "Ollama app", []string{`%LOCALAPPDATA%\Ollama`}},
	// Communication
	{"chat", "Discord", []string{`%APPDATA%\discord`, `%APPDATA%\discordptb`, `%APPDATA%\discordcanary`}},
	{"chat", "Slack", []string{`%APPDATA%\Slack`}},
	{"chat", "Teams (classic)", []string{`%APPDATA%\Microsoft\Teams`}},
	{"chat", "Messenger", []string{`%APPDATA%\Messenger`}},
	{"chat", "Signal", []string{`%APPDATA%\Signal`}},
	{"chat", "Element", []string{`%APPDATA%\Element`}},
	{"chat", "Zalo", []string{`%APPDATA%\ZaloPC`, `%LOCALAPPDATA%\ZaloPC`}},
	{"chat", "Skype", []string{`%APPDATA%\Microsoft\Skype for Desktop`}},
	{"chat", "WhatsApp (desktop)", []string{`%APPDATA%\WhatsApp`}},
	// Developer tools
	{"dev", "VS Code", []string{`%APPDATA%\Code`}},
	{"dev", "VS Code Insiders", []string{`%APPDATA%\Code - Insiders`}},
	{"dev", "VSCodium", []string{`%APPDATA%\VSCodium`}},
	{"dev", "GitHub Desktop", []string{`%APPDATA%\GitHub Desktop`}},
	{"dev", "Postman", []string{`%APPDATA%\Postman`}},
	{"dev", "Insomnia", []string{`%APPDATA%\Insomnia`}},
	{"dev", "Docker Desktop", []string{`%APPDATA%\Docker Desktop`}},
	{"dev", "MongoDB Compass", []string{`%APPDATA%\MongoDB Compass`}},
	{"dev", "Unity Hub", []string{`%APPDATA%\UnityHub`}},
	// Apps
	{"apps", "Figma", []string{`%APPDATA%\Figma`}},
	{"apps", "Notion", []string{`%APPDATA%\Notion`}},
	{"apps", "Obsidian", []string{`%APPDATA%\obsidian`}},
	{"apps", "Logseq", []string{`%APPDATA%\Logseq`}},
	{"apps", "Spotify (web cache)", []string{`%LOCALAPPDATA%\Spotify\Browser`}},
	{"apps", "Canva", []string{`%APPDATA%\Canva`}},
	{"apps", "Microsoft Teams", []string{`%LOCALAPPDATA%\Packages\MSTeams_*\LocalCache\Microsoft\MSTeams\EBWebView\Default`}},
	// Browsers (all profiles)
	{"apps", "Chrome", []string{`%LOCALAPPDATA%\Google\Chrome\User Data\*`, `%LOCALAPPDATA%\Google\Chrome\User Data`}},
	{"apps", "Edge", []string{`%LOCALAPPDATA%\Microsoft\Edge\User Data\*`, `%LOCALAPPDATA%\Microsoft\Edge\User Data`}},
	{"apps", "Brave", []string{`%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\*`, `%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data`}},
	{"apps", "Opera", []string{`%APPDATA%\Opera Software\Opera Stable`, `%APPDATA%\Opera Software\Opera GX Stable`}},
	{"apps", "Vivaldi", []string{`%LOCALAPPDATA%\Vivaldi\User Data\*`}},
	{"apps", "Cốc Cốc", []string{`%LOCALAPPDATA%\CocCoc\Browser\User Data\*`}},
	// Games launchers
	{"games", "Steam (web)", []string{`%LOCALAPPDATA%\Steam\htmlcache`}},
	{"games", "Riot Client", []string{`%LOCALAPPDATA%\Riot Games\Riot Client\Data`}},
	{"games", "Battle.net", []string{`%APPDATA%\Battle.net`, `%LOCALAPPDATA%\Battle.net\BrowserCaches\*`}},
}

var targets = []target{
	// System
	{"system", "User temp files", []string{`%TEMP%`}, 24},
	{"system", "Windows temp files", []string{`%SystemRoot%\Temp`}, 24},
	{"system", "DirectX shader cache", []string{`%LOCALAPPDATA%\D3DSCache`, `%LOCALAPPDATA%\Microsoft\DirectX Shader Cache`}, 0},
	{"system", "NVIDIA shader cache", []string{`%LOCALAPPDATA%\NVIDIA\DXCache`, `%LOCALAPPDATA%\NVIDIA\GLCache`, `%LOCALAPPDATA%\NVIDIA Corporation\NV_Cache`, `%PROGRAMDATA%\NVIDIA Corporation\NV_Cache`}, 0},
	{"system", "AMD shader cache", []string{`%LOCALAPPDATA%\AMD\DXCache`, `%LOCALAPPDATA%\AMD\GLCache`, `%LOCALAPPDATA%\AMD\VkCache`, `%LOCALAPPDATA%\AMD\DxcCache`}, 0},
	{"system", "Intel shader cache", []string{`%LOCALAPPDATA%\Intel\ShaderCache`, `%APPDATA%\Intel\ShaderCache`}, 0},
	{"system", "Vulkan cache", []string{`%LOCALAPPDATA%\VulkanCache`}, 0},
	{"system", "Crash dumps", []string{`%LOCALAPPDATA%\CrashDumps`}, 0},
	{"system", "Windows error reports", []string{`%LOCALAPPDATA%\Microsoft\Windows\WER`, `%PROGRAMDATA%\Microsoft\Windows\WER\ReportArchive`, `%PROGRAMDATA%\Microsoft\Windows\WER\ReportQueue`}, 0},
	{"system", "Thumbnail cache", []string{`%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db`, `%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db`}, 0},
	{"system", "Windows Update download cache", []string{`%SystemRoot%\SoftwareDistribution\Download`}, 0},
	{"system", "Delivery Optimization cache", []string{`%SystemRoot%\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache`}, 0},
	{"system", "Windows logs", []string{`%SystemRoot%\Logs\CBS\*.log`, `%SystemRoot%\Logs\DISM\*.log`, `%SystemRoot%\Panther\*.log`}, 168},
	{"system", "Store app caches", []string{`%LOCALAPPDATA%\Packages\*\AC\INetCache`, `%LOCALAPPDATA%\Packages\Microsoft.WindowsStore_*\LocalCache`}, 0},
	{"system", "Internet cache", []string{`%LOCALAPPDATA%\Microsoft\Windows\INetCache\IE`}, 0},
	// Apps
	{"apps", "Firefox cache", []string{`%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*\cache2`, `%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*\startupCache`}, 0},
	{"apps", "Office temp & web add-in cache", []string{`%LOCALAPPDATA%\Microsoft\Office\16.0\Wef`, `%LOCALAPPDATA%\Microsoft\Office\OTele`}, 0},
	{"apps", "OneDrive logs", []string{`%LOCALAPPDATA%\Microsoft\OneDrive\logs`, `%LOCALAPPDATA%\Microsoft\OneDrive\setup\logs`}, 0},
	{"apps", "Google Drive logs", []string{`%LOCALAPPDATA%\Google\DriveFS\Logs`}, 0},
	{"apps", "Adobe media cache", []string{`%APPDATA%\Adobe\Common\Media Cache Files`, `%APPDATA%\Adobe\Common\Media Cache`, `%APPDATA%\Adobe\Common\Peak Files`, `%LOCALAPPDATA%\Adobe\*\CameraRaw\Cache`}, 0},
	{"apps", "Sublime Text cache", []string{`%LOCALAPPDATA%\Sublime Text\Cache`}, 0},
	{"apps", "Zed cache", []string{`%LOCALAPPDATA%\Zed\cache`}, 0},
	{"apps", "Electron cache", []string{`%LOCALAPPDATA%\electron\Cache`}, 0},
	// Developer
	{"dev", "npm cache", []string{`%LOCALAPPDATA%\npm-cache\_cacache`, `%APPDATA%\npm-cache\_cacache`}, 0},
	{"dev", "pnpm store", []string{`%LOCALAPPDATA%\pnpm\store`, `%LOCALAPPDATA%\pnpm-cache`}, 0},
	{"dev", "Yarn cache", []string{`%LOCALAPPDATA%\Yarn\Cache`, `%USERPROFILE%\.yarn\berry\cache`}, 0},
	{"dev", "Bun cache", []string{`%USERPROFILE%\.bun\install\cache`}, 0},
	{"dev", "pip cache", []string{`%LOCALAPPDATA%\pip\Cache`}, 0},
	{"dev", "uv cache", []string{`%LOCALAPPDATA%\uv\cache`}, 0},
	{"dev", "Poetry cache", []string{`%LOCALAPPDATA%\pypoetry\Cache`}, 0},
	{"dev", "Conda packages", []string{`%USERPROFILE%\.conda\pkgs`, `%USERPROFILE%\anaconda3\pkgs`, `%USERPROFILE%\miniconda3\pkgs`}, 0},
	{"dev", "Go build cache", []string{`%LOCALAPPDATA%\go-build`}, 0},
	{"dev", "Go module downloads", []string{`%USERPROFILE%\go\pkg\mod\cache\download`}, 0},
	{"dev", "Cargo registry cache", []string{`%USERPROFILE%\.cargo\registry\cache`, `%USERPROFILE%\.cargo\git\checkouts`}, 0},
	{"dev", "Rustup downloads", []string{`%USERPROFILE%\.rustup\downloads`, `%USERPROFILE%\.rustup\tmp`}, 0},
	{"dev", "NuGet cache", []string{`%LOCALAPPDATA%\NuGet\v3-cache`, `%LOCALAPPDATA%\NuGet\plugins-cache`, `%LOCALAPPDATA%\Temp\NuGetScratch`}, 0},
	{"dev", "Gradle cache", []string{`%USERPROFILE%\.gradle\caches`, `%USERPROFILE%\.gradle\wrapper\dists`}, 0},
	{"dev", "Maven repository", []string{`%USERPROFILE%\.m2\repository`}, 0},
	{"dev", "node-gyp cache", []string{`%LOCALAPPDATA%\node-gyp\Cache`}, 0},
	{"dev", "TypeScript cache", []string{`%LOCALAPPDATA%\Microsoft\TypeScript`}, 0},
	{"dev", "JetBrains caches & logs", []string{`%LOCALAPPDATA%\JetBrains\*\caches`, `%LOCALAPPDATA%\JetBrains\*\log`}, 0},
	{"dev", "Visual Studio caches", []string{`%LOCALAPPDATA%\Microsoft\VisualStudio\*\ComponentModelCache`, `%LOCALAPPDATA%\Microsoft\VisualStudio\*\ImageCache`}, 0},
	{"dev", "VS Code extension cache", []string{`%APPDATA%\Code\CachedData`, `%APPDATA%\Code\CachedExtensionVSIXs`, `%APPDATA%\Code\logs`}, 0},
	{"dev", "C/C++ IntelliSense cache", []string{`%LOCALAPPDATA%\Microsoft\vscode-cpptools`}, 0},
	{"dev", "Unity cache", []string{`%LOCALAPPDATA%\Unity\cache`, `%APPDATA%\Unity\Asset Store-5.x`}, 0},
	{"dev", "Docker Desktop logs", []string{`%LOCALAPPDATA%\Docker\log`}, 0},
	{"dev", "Playwright browsers", []string{`%LOCALAPPDATA%\ms-playwright`}, 0},
	{"dev", "Puppeteer browsers", []string{`%USERPROFILE%\.cache\puppeteer`}, 0},
	{"dev", "Terraform plugin cache", []string{`%APPDATA%\terraform.d\plugin-cache`}, 0},
	// AI CLIs
	{"ai", "Claude Code logs & temp", []string{`%LOCALAPPDATA%\claude-cli-nodejs\Cache`, `%USERPROFILE%\.claude\shell-snapshots`, `%USERPROFILE%\.claude\statsig`, `%USERPROFILE%\.claude\debug`}, 0},
	{"ai", "Codex logs & cache", []string{`%USERPROFILE%\.codex\log`, `%USERPROFILE%\.codex\cache`}, 0},
	{"ai", "Gemini CLI temp", []string{`%USERPROFILE%\.gemini\tmp`}, 0},
	{"ai", "Hugging Face download temp", []string{`%USERPROFILE%\.cache\huggingface\xet`}, 0},
	// Games
	{"games", "Epic Games web cache & logs", []string{`%LOCALAPPDATA%\EpicGamesLauncher\Saved\webcache*`, `%LOCALAPPDATA%\EpicGamesLauncher\Saved\Logs`}, 0},
	{"games", "Steam app cache", []string{`${ProgramFiles(x86)}\Steam\appcache\httpcache`, `${ProgramFiles(x86)}\Steam\logs`, `${ProgramFiles(x86)}\Steam\dumps`}, 0},
	{"games", "GOG Galaxy cache", []string{`%LOCALAPPDATA%\GOG.com\Galaxy\webcache`, `%PROGRAMDATA%\GOG.com\Galaxy\logs`}, 0},
	{"games", "EA app cache", []string{`%LOCALAPPDATA%\Electronic Arts\EA Desktop\cache`, `%LOCALAPPDATA%\EADesktop\cache`}, 0},
	{"games", "Ubisoft Connect cache", []string{`%LOCALAPPDATA%\Ubisoft Game Launcher\cache`, `%LOCALAPPDATA%\Ubisoft Game Launcher\logs`}, 0},
	{"games", "Game logs", []string{`%LOCALAPPDATA%\VALORANT\Saved\Logs`, `%LOCALAPPDATA%\FortniteGame\Saved\Logs`, `%LOCALAPPDATA%\Riot Games\Riot Client\Logs`}, 0},
}

// allTargets expands Electron apps into one target per app with every
// cache leaf, so each leaf is checked on its own.
func allTargets() []target {
	out := append([]target{}, targets...)
	for _, a := range electronApps {
		var paths []string
		for _, d := range a.Dirs {
			for _, leaf := range chromiumLeaves {
				paths = append(paths, d+`\`+leaf)
			}
		}
		out = append(out, target{Category: a.Category, Name: a.Name + " cache", Paths: paths})
	}
	return out
}

// catalogLocationCount is the number of individual locations checked.
func catalogLocationCount() int {
	n := 0
	for _, t := range allTargets() {
		n += len(t.Paths)
	}
	return n
}
