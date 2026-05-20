# [DONE] Split Maintainer Utils Pester Suite

## Summary

Split `scripts/tests/Maintainer.Utils.Tests.ps1` into focused Pester spec files discovered directly by Pester. Extract
shared test setup into a non-discovered support file and remove the oversized original suite after the split.

This cycle must preserve behaviour exactly:

- same module import path;
- same assertions;
- same mocks;
- same error IDs;
- same command metadata expectations;
- same public contracts;
- same final test count.

The only intended change is test-suite structure.

## Goals

- Make each public maintainer command easier to test and navigate.
- Keep Pester discovery simple: test files remain direct `.Tests.ps1` files.
- Avoid duplicate execution by deleting the original aggregate test file.
- Keep shared helpers small and test-specific.
- Avoid changing production module code.

## Non-Goals

- Do not change `Maintainer.Utils.psm1`.
- Do not change public function behaviour.
- Do not add new behavioural coverage in this cycle.
- Do not introduce a custom Pester configuration file.
- Do not move tests outside `scripts/tests`.

## Target File Layout

Create:

```text
scripts/tests/
├── Maintainer.Utils.TestSupport.ps1
├── Maintainer.Utils.NewDibsGitLabRepository.Tests.ps1
└── Maintainer.Utils.NewDibsGitLabRepositorySubmodule.Tests.ps1
```

Remove:

```text
scripts/tests/Maintainer.Utils.Tests.ps1
```

## Implementation Plan

### 1. Capture the current baseline

Run the current suite before moving anything:

```powershell
Invoke-Pester -Path '.\scripts\tests\Maintainer.Utils.Tests.ps1' -Output Detailed
```

Record:

- total test count;
- pass/fail result;
- `Describe` block names;
- any setup or mocks shared by both command suites.

Expected baseline:

```text
17 tests
17 passed
0 failed
```

If the baseline differs, update the expected split count before continuing.

### 2. Create the support file

Create:

```text
scripts/tests/Maintainer.Utils.TestSupport.ps1
```

This file should:

- import `../Maintainer.Utils.psm1` with `-Force`;
- define only shared helpers used by both split specs;
- avoid `Describe`, `Context`, and `It` blocks;
- avoid `.Tests.ps1` in its filename so Pester does not discover it directly.

Keep helpers small and mechanical. Good candidates are:

- module import setup;
- fake successful tool output;
- fake failed tool output;
- path-normalization helpers used by both specs.

Avoid moving assertion-specific logic into support helpers. Assertions should stay visible in the spec files.

### 3. Split the repository command spec

Create:

```text
scripts/tests/Maintainer.Utils.NewDibsGitLabRepository.Tests.ps1
```

At the top, dot-source the support file:

```powershell
. "$PSScriptRoot/Maintainer.Utils.TestSupport.ps1"
```

Move the existing block unchanged:

```powershell
Describe 'New-DibsGitLabRepository' {
    ...
}
```

Preserve:

- all `BeforeEach` and `AfterEach` behaviour;
- all mocks;
- all tool argument expectations;
- all structured-output assertions;
- all validation-failure assertions.

Only adjust paths or helper references required by the file split.

### 4. Split the submodule command spec

Create:

```text
scripts/tests/Maintainer.Utils.NewDibsGitLabRepositorySubmodule.Tests.ps1
```

Dot-source the same support file:

```powershell
. "$PSScriptRoot/Maintainer.Utils.TestSupport.ps1"
```

Move the existing block unchanged:

```powershell
Describe 'New-DibsGitLabRepositorySubmodule' {
    ...
}
```

Preserve the current coverage for:

- happy path;
- `-WhatIf`;
- validation failures before external tool invocation;
- repository-creation failure;
- submodule-add failure;
- command metadata.

### 5. Delete the original suite

Delete:

```text
scripts/tests/Maintainer.Utils.Tests.ps1
```

Do this only after both new spec files pass independently.

This prevents duplicate Pester discovery and makes the split unambiguous.

### 6. Update validation commands

Replace the old focused command:

```powershell
Invoke-Pester -Path '.\scripts\tests\Maintainer.Utils.Tests.ps1' -Output Detailed
```

with:

```powershell
Invoke-Pester -Path '.\scripts\tests\Maintainer.Utils.*.Tests.ps1' -Output Detailed
```

This pattern should discover only:

```text
Maintainer.Utils.NewDibsGitLabRepository.Tests.ps1
Maintainer.Utils.NewDibsGitLabRepositorySubmodule.Tests.ps1
```

It should not discover:

```text
Maintainer.Utils.TestSupport.ps1
```

Pester conventionally discovers test files by path/pattern, and keeping support files outside the `.Tests.ps1` naming
pattern avoids accidental direct execution. PSScriptAnalyzer can still analyse `.ps1`, `.psm1`, and `.psd1` files, so
the support file remains eligible for static analysis. :contentReference[oaicite:0]{index=0}

## Test Plan

### Focused test runs

Run each split spec independently:

```powershell
Invoke-Pester `
    -Path '.\scripts\tests\Maintainer.Utils.NewDibsGitLabRepository.Tests.ps1' `
    -Output Detailed
```

```powershell
Invoke-Pester `
    -Path '.\scripts\tests\Maintainer.Utils.NewDibsGitLabRepositorySubmodule.Tests.ps1' `
    -Output Detailed
```

Then run both through the new discovery pattern:

```powershell
Invoke-Pester `
    -Path '.\scripts\tests\Maintainer.Utils.*.Tests.ps1' `
    -Output Detailed
```

Expected result:

```text
17 tests
17 passed
0 failed
```

### Duplicate-discovery check

Confirm that the old file no longer exists:

```powershell
Test-Path '.\scripts\tests\Maintainer.Utils.Tests.ps1'
```

Expected result:

```powershell
False
```

Confirm that the support file is not matched by the focused test pattern:

```powershell
Get-ChildItem '.\scripts\tests\Maintainer.Utils.*.Tests.ps1'
```

Expected result:

```text
Maintainer.Utils.NewDibsGitLabRepository.Tests.ps1
Maintainer.Utils.NewDibsGitLabRepositorySubmodule.Tests.ps1
```

### Static analysis

Run static analysis on the affected files:

```powershell
pwsh ./tools/Invoke-PSSA.ps1
```

If the wrapper supports path-scoped analysis, prefer the narrower target:

```powershell
pwsh ./tools/Invoke-PSSA.ps1 `
    -Path ./scripts/tests/Maintainer.Utils.TestSupport.ps1,`
          ./scripts/tests/Maintainer.Utils.NewDibsGitLabRepository.Tests.ps1,`
          ./scripts/tests/Maintainer.Utils.NewDibsGitLabRepositorySubmodule.Tests.ps1
```

## Documentation Updates

Update docs only if they reference the removed exact path:

```text
scripts/tests/Maintainer.Utils.Tests.ps1
```

Replace it with the discovery pattern:

```text
scripts/tests/Maintainer.Utils.*.Tests.ps1
```

Do not add broader documentation unless the README already lists maintainer test entry points.

## Decisions

- Keep the support file named `Maintainer.Utils.TestSupport.ps1`, not `Maintainer.Utils.TestSupport.Tests.ps1`.
- Keep one spec file per public command.
- Delete the old aggregate file after migration.
- Preserve all current assertions and test data.
- Do not introduce production changes in this cycle.

## Risks And Mitigations

### Risk: Duplicate test execution

Mitigation:

- delete `Maintainer.Utils.Tests.ps1`;
- verify discovery with `Get-ChildItem`;
- assert the expected count remains `17`.

### Risk: Hidden assertions inside support helpers

Mitigation:

- support helpers should create setup data only;
- command-specific expectations stay in spec files.

### Risk: Test order or shared state changes

Mitigation:

- keep each spec self-contained;
- import the module with `-Force` from the support file;
- keep existing `BeforeEach` reset logic near the `Describe` that uses it.

### Risk: Documentation still references the old path

Mitigation:

- search for the old filename after deletion;
- update only direct references.
