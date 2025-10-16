## Quick orientation

This repository is a collection of PowerShell utility scripts (organised by feature area). Most scripts target PowerShell 7.5+ and follow a small number of explicit conventions enforced by PSScriptAnalyzer.

Top-level folders you should know:
- `core/` — reusable helpers used by other scripts (notably `core/Invoke-Tool.ps1`).
- `git/`, `maintenance/`, `pipeline/`, `hash/` — feature areas with self-contained cmdlets/scripts.
- `tools/` — tooling helpers; contains the PSScriptAnalyzer runner: `tools/Invoke-PSSA.ps1`.

Why this structure: scripts are grouped by operational domain (git, maintenance, pipeline, hash) and depend on a small core layer (`core/Invoke-Tool.ps1`) for running external commands reliably.

## Big-picture patterns an agent must follow
- Scripts use `[CmdletBinding()]`, advanced parameter validation attributes (e.g. `ValidateNotNullOrWhiteSpace`, `ValidateScript`) and a file-level `Requires -Version 7.5` directive (PowerShell file header) in many files — keep generated code compatible with PowerShell 7.5 syntax.
- `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'` are commonly used; prefer throwing terminating errors rather than writing non-terminating warnings.
- Style is enforced by `PSScriptAnalyzerSettings.psd1`: 4-space indentation, same-line open-braces, consistent whitespace and aligned assignments. Follow these exactly. See `PSScriptAnalyzerSettings.psd1` for the canonical rules.
- Avoid using `Write-Host` (rule: `PSAvoidUsingWriteHost`) and prefer emitting objects or structured hashtables for programmatic consumption (e.g., `core/Invoke-Tool.ps1` returns a hashtable containing ToolPath, ExitCode, Output).

## Developer workflows (explicit commands)
- Run the project's linter (primary automated check):

  pwsh ./tools/Invoke-PSSA.ps1

  This script will install PSScriptAnalyzer if missing and exit with non-zero on `Error`-severity findings. There's also a VS Code task labeled "Run PSScriptAnalyzer" in this workspace.

- How the CI expects lint behavior: PSSA is run recursively against repository paths and returns a non-zero exit code when any findings are `Error` severity.

## Reuse & integration points agents should prefer
- Use `core/Invoke-Tool.ps1` when you need to invoke external executables (git, other CLI). It normalizes encoding, captures stdout/stderr and returns an object-like hashtable. Many scripts rely on its behavior — keep the same output shape when creating new helpers.
- When interacting with Git, follow the existing pattern used in `git/Test-GitRepository.ps1`: call `Invoke-Tool` to run `git -C <path> ...` instead of invoking `git` directly from generated code.
- Module installation logic lives in `tools/Invoke-PSSA.ps1` — prefer its approach (try PSResourceGet, fallback to PowerShellGet) when adding module-install helpers.

## Project-specific conventions (examples)
- Indentation and braces: See `PSScriptAnalyzerSettings.psd1` — open brace on the same line, 4 spaces for indentation, align assignment statements.
- Parameter style: use typed parameters with validation attributes and `[CmdletBinding()]`. Example pattern:

  [CmdletBinding()]
  param(
      [Parameter(Mandatory)]
      [ValidateNotNullOrWhiteSpace()]
      [string] $Name
  )

- Error handling: set `$ErrorActionPreference = 'Stop'` and throw on unrecoverable conditions so PSSA/CI can detect failures.

## Files to inspect for examples or when extending the codebase
- `PSScriptAnalyzerSettings.psd1` — canonical style/enforcement.
- `tools/Invoke-PSSA.ps1` — linter runner + module-install pattern.
- `core/Invoke-Tool.ps1` — external command wrapper (encoding, exit code handling, output shape).
- `git/Test-GitRepository.ps1` — example of a script that checks a repo path using the `Invoke-Tool` pattern.
- `core/Initialize-Project.ps1`, `core/Apply-License.ps1` — other examples of expected parameter and output shapes.

## What the agent must not change without confirmation
- Do not modify `PSScriptAnalyzerSettings.psd1` or the `Invoke-PSSA.ps1` workflow unless you understand the downstream CI implications — small style changes can break automation.
- Avoid replacing `Invoke-Tool` behavior — many scripts parse its output or rely on its exception messages.

## Quick checklist for PRs the agent creates
- Ensure a file-level `Requires -Version 7.5` directive is present when using 7.5+ features.
- Follow the parameter-validation and `[CmdletBinding()]` pattern.
- Run `pwsh ./tools/Invoke-PSSA.ps1` locally and ensure there are no `Error`-level PSSA findings.
- When invoking external commands from generated code, use `core/Invoke-Tool.ps1` for parity.

If any of this is unclear or you'd like sections expanded (examples, tests, CI hooks), tell me which part to expand and I will iterate.
