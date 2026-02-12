# DIBS PowerShell Scripts — Course Companion

[![PowerShell 7.5+](https://img.shields.io/badge/PowerShell-7.5%2B-5391FE?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![Style: PSScriptAnalyzer](https://img.shields.io/badge/style-PSScriptAnalyzer-006CBE?logo=powershell&logoColor=white)](./tools/Invoke-PSSA.ps1)
[![License: BSD-2-Clause](https://img.shields.io/badge/License-BSD%202--Clause-orange.svg)](./LICENSE)

Companion repository for the course “Diseño e Implementación de Bibliotecas de Software (DIBS)”.
The lessons (notes) are written in Spanish, while the source code and this repository are in English for broader reach.

> Status: Lessons 1–4 (Introduction, discovery, scripting, and structured output)

## Table of Contents

- [DIBS PowerShell Scripts — Course Companion](#dibs-powershell-scripts--course-companion)
	- [Table of Contents](#table-of-contents)
	- [What you'll find in this repo](#what-youll-find-in-this-repo)
	- [Lessons at a glance](#lessons-at-a-glance)
	- [Requirements and setup](#requirements-and-setup)
	- [Quick start](#quick-start)
	- [Key files and patterns](#key-files-and-patterns)
	- [Development](#development)
	- [Roadmap](#roadmap)
	- [License](#license)

## What you'll find in this repo

- A practical, minimal PowerShell workspace organized by operational domain.
- Idiomatic examples that favor clarity over cleverness (beginner‑friendly).
- Folder structure:
	- `core/` — reusable helpers (e.g., `Invoke-Tool.ps1` for external command invocation).
	- `scaffolding/` — project bootstrap (e.g., `Initialize-Project.ps1`, `New-Readme.ps1`).
	- `git/`, `maintenance/`, `pipeline/`, `operations/` — domain-specific utilities.
	- `models/`, `examples/`, `tools/` — supporting modules, examples, and helpers.
	- `tests/` — test data (fixtures, checksums, service lists).

## Lessons at a glance

| Lesson       | Topic                                 | Resources                                                                                                                                        |
| ------------ | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Lesson 2** | Built‑in discovery and help           | [Notes](https://dibs.ravenhill.cl/notes/software-libraries/scripting/help/) • `examples/help/` (GetCommand, GetHelp, template examples)          |
| **Lesson 3** | First script and parameter validation | [Notes](https://dibs.ravenhill.cl/notes/software-libraries/scripting/first-script/) • `scaffolding/New-Readme.ps1`, `core/Test-Readme.ps1`       |
| **Lesson 4** | Structured output in PowerShell       | [Notes](https://dibs.ravenhill.cl/notes/software-libraries/scripting/structured-output/) • `models/`, `tools/network/Test-ConnectionSummary.ps1` |

## Requirements and setup

- **PowerShell 7.5+** (Windows, macOS, Linux)
- **VS Code + PowerShell extension** (recommended)

## Quick start

1. **Clone and open in VS Code:**
   ```powershell
   git clone <repo> scripts
   code scripts
   ```

2. **Run the linter** (auto-installs PSScriptAnalyzer if missing):
   ```powershell
   pwsh ./tools/Invoke-PSSA.ps1
   ```

3. **Try a script** — create a project and README (Lesson 3 example):
   ```powershell
   $result = ./scaffolding/Initialize-Project.ps1 -Name "MyApp" -Path "C:\Temp"
   $result | Format-List
   ```

## Key files and patterns

- `PSScriptAnalyzerSettings.psd1` — canonical style rules (indentation, whitespace, approved verbs).
- `core/Invoke-Tool.ps1` — wrapper for external CLI invocation (normalizes encoding/exit codes).
- `scaffolding/Initialize-Project.ps1` — example: creates project folder + README, returns structured result.
- `tools/Invoke-PSSA.ps1` — linter runner (installs PSScriptAnalyzer if needed).

**Script conventions:**
- File header: `#Requires -Version 7.5` when using 7.5+ features.
- Advanced parameters with validation (e.g., `ValidateNotNullOrWhiteSpace`, `ValidateScript`).
- Prefer terminating errors (`$ErrorActionPreference = 'Stop'`) over `Write-Host`.
- Use `core/Invoke-Tool.ps1` when invoking external tools (git, etc.) for consistent output.
- Return objects instead of formatted text for pipeline composability.

## Development

Run the linter locally to check for style and logic errors:

```powershell
pwsh ./tools/Invoke-PSSA.ps1
```

In VS Code, use the "Run PSScriptAnalyzer" task (Error‑level findings will fail the run).

## Roadmap

This repository will grow as new lessons are added.

## License

BSD 2‑Clause — see [`LICENSE`](./LICENSE).

