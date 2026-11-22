# Moleo (desktop app)

A Go + Wails desktop front end for Mole for Windows: Clean, Apps, Optimize,
Analyze, Status and Recover, in English or Vietnamese.

## Build

```powershell
wails build        # -> build/bin/Moleo.exe
wails dev          # live reload while editing frontend/src
```

The app finds `mole.ps1` by walking up from the executable, so run it from
inside this repository (Apps and Optimize call the CLI scripts in `bin/`).

## Credits

Planet textures in `frontend/src/assets/planets/` are from
[Solar System Scope](https://www.solarsystemscope.com/textures/), licensed
under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), based on NASA
data.
