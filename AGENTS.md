# AI Agent Guide

Context and essential rules for agents working in this subproject.

## Decision Protocol

- Never make product, architecture, pedagogy, content-order, or style-policy decisions on your own.
- When a choice is required, present viable alternatives with their tradeoffs and wait for confirmation from the user.
- You may proceed with low-risk mechanical changes only when the existing repository pattern makes the decision unambiguous.
- If an instruction conflicts with project patterns, stop and ask before changing direction.

## Project Shape

- This is the PowerShell companion repository for DIBS scripting lessons.
- Scripts are organized by domain and lesson area: `core/`, `scaffolding/`, `git/`, `maintenance/`, `operations/`, `pipeline/`, `models/`, `examples/`, and `tools/`.
- `tests/` contains fixtures and Pester-style checks used by lesson examples.
- `core/Invoke-Tool.ps1` and `tools/Invoke-Tool.ps1` show the preferred wrapper pattern for external CLI calls.

## Workflow

- Target PowerShell 7.5+.
- Run static analysis with `pwsh ./tools/Invoke-PSSA.ps1`.
- Keep `PSScriptAnalyzerSettings.psd1` as the source of style and linting rules.
- Use the narrowest script invocation needed to validate a change before running the full analyzer.
- Do not modify changelogs unless the user explicitly asks for changelog updates.

## Code Conventions

- Add `#Requires -Version 7.5` when a script depends on 7.5+ behavior.
- Prefer advanced parameters with validation attributes such as `ValidateNotNullOrWhiteSpace` and `ValidateScript`.
- Prefer terminating errors and `$ErrorActionPreference = 'Stop'` over ad hoc host output.
- Return structured objects instead of formatted text so examples stay pipeline-friendly.
- Use `core/Invoke-Tool.ps1` when invoking external commands for consistent output and exit-code handling.
- Follow the inclusive documentation guidance from the Astro site lesson at `../astro-website/src/pages/notes/software-libraries/api-design/documentation/index.astro`: prefer precise, clear, respectful terminology over loaded metaphors or unnecessarily punitive wording.
- Avoid terms such as `violation` or `violations` in new messages, docs, test names, and public function output when a more descriptive alternative works. Prefer `finding`, `issue`, `not allowed`, `policy mismatch`, or a domain-specific name.
- Do not rename existing script parameters, object properties, or documented outputs mechanically. If compatibility is involved, propose aliases, deprecation, release notes, or a migration path first.
