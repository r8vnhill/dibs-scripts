# DIBS PowerShell Scripts — Course Companion

[![PowerShell 7.5+](https://img.shields.io/badge/PowerShell-7.5%2B-5391FE?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![Style: PSScriptAnalyzer](https://img.shields.io/badge/style-PSScriptAnalyzer-006CBE?logo=powershell&logoColor=white)](./tools/Invoke-PSSA.ps1)
[![License: BSD-2-Clause](https://img.shields.io/badge/License-BSD%202--Clause-orange.svg)](./LICENSE)

Companion repository for the course “Diseño e Implementación de Bibliotecas de Software (DIBS)”.
The lessons (notes) are written in Spanish, while the source code and this repository are in English for broader reach.

> Status: Lesson 1 (Introduction to PowerShell scripting); Lesson 2 (Built‑in discovery and help)

## What you’ll find in this repo (Lesson 1)
- A practical, minimal PowerShell workspace for automation.
- Idiomatic examples that favor clarity over cleverness (beginner‑friendly).
- Scripts grouped by operational domain:
	- `core/` — reusable building blocks (e.g., `Invoke-Tool.ps1` for calling external CLIs reliably).
	- `scaffolding/` — project bootstrap helpers (e.g., `Initialize-Project.ps1`, `New-Readme.ps1`).
	- `git/`, `maintenance/`, `pipeline/`, `hash/` — self-contained utilities per domain.
	- `tools/` — tooling helpers (e.g., PSScriptAnalyzer runner `tools/Invoke-PSSA.ps1`).

## Lesson 2 — Built‑in discovery and help
- Online notes (Spanish): https://dibs.ravenhill.cl/notes/software-libraries/scripting/help/
- Examples in this repo (brief, runnable snippets):
	- `examples/help/Get-Command-Examples.ps1` — discover/filter commands, show syntax, search by parameter.
	- `examples/help/Get-Help-Examples.ps1` — quick help, about_* topics, parameter help (with optional -Online).
	- `examples/help/CommentBasedHelp-Template.ps1` — minimal comment‑based help template.

Run them directly to explore; they return objects and avoid host writes.

## Requirements
- PowerShell 7.5 or newer
- Windows/macOS/Linux supported (PowerShell 7 is cross‑platform)
- VS Code + PowerShell extension recommended

## Quick start
- Clone the repo and open it in VS Code.
- Run the linter (will auto‑install PSScriptAnalyzer if missing):

```powershell
pwsh ./tools/Invoke-PSSA.ps1
```

- Try the Lesson 1 scaffold script to create a project folder and a README:

```powershell
# Creates <base>/<Name>/README.md with a simple template
./scaffolding/Initialize-Project.ps1 -Name "MyApp" -Path "C:\\Temp"
```

It returns a PSCustomObject you can inspect programmatically:

```powershell
$result = ./scaffolding/Initialize-Project.ps1 -Name "Demo" -Path "C:\\Temp"
$result | Format-List
```

## How this repo is organized
- Each script is an advanced function with `[CmdletBinding()]` and parameter validation.
- We aim for predictable behavior and easy testing: scripts return objects instead of writing to host.

Representative files to explore:
- `core/Invoke-Tool.ps1` — wrapper for invoking external commands (normalizes encoding, exit codes, output capture).
- `scaffolding/Initialize-Project.ps1` — creates a project directory and README; returns a structured result.
- `tools/Invoke-PSSA.ps1` — runs PSScriptAnalyzer recursively (installs it if needed) and fails on Error‑severity rules.
- `PSScriptAnalyzerSettings.psd1` — canonical style rules (indentation, whitespace, approved verbs, etc.).

## Conventions used in scripts
- File header: `Requires -Version 7.5` when using 7.5+ features.
- Advanced parameters with validation (e.g., `ValidateNotNullOrWhiteSpace`, `ValidateScript`).
- Prefer terminating errors (`$ErrorActionPreference = 'Stop'`) and avoid `Write-Host`.
- When calling external tools (e.g., `git`), use `core/Invoke-Tool.ps1` for consistent output and error handling.

## Linting and style
- Run PSScriptAnalyzer locally:

```powershell
pwsh ./tools/Invoke-PSSA.ps1
```

- In VS Code, there’s a task named “Run PSScriptAnalyzer”. The linter fails the run when Error‑level findings exist.

## Roadmap
This repository will grow as new lessons are added

## License
BSD 2‑Clause — see [`LICENSE`](./LICENSE).

