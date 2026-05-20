# [IMPLEMENTED] Maintainer GitLab Repo Wrapper

## Summary

Add a maintainer-only PowerShell function to `scripts/Maintainer.Utils.psm1` that creates and locally clones a GitLab
repository using `glab repo create`.

The wrapper should be general enough to create any maintainer-managed DIBS repository, while providing safe defaults for
the common course repository case.

The wrapper should preserve the repository’s scripting conventions: PowerShell 7.6 LTS, strict mode, terminating errors,
structured output, `SupportsShouldProcess`, and external CLI execution through `tools/Invoke-Tool.ps1`.

Implemented in:

- `Maintainer.Utils.psm1`
- `tests/Maintainer.Utils.Tests.ps1`
- `README.md`

## Behavioural Contract

The new function is:

```powershell
New-DibsGitLabRepository `
    -Group dibs-course `
    -Name python-companion `
    -DestinationPath E:\teaching\DIBS\projects\python-companion
```

For the common case, `-Group` may default to `dibs-course`:

```powershell
New-DibsGitLabRepository `
    -Name python-companion `
    -DestinationPath E:\teaching\DIBS\projects\python-companion
```

It creates:

- GitLab group/project: `<Group>/<Name>`
- visibility: public by default
- default branch: `main` by default
- initialized README: `README.md` by default
- local clone at the exact requested destination path

The wrapper runs `glab repo create` from the parent directory of `DestinationPath`, so the clone lands at:

```text
<DestinationParent>/<Name>
```

Because `glab repo create ... --readme README.md` clones into a directory named after the repository, the function
should reject destination paths whose final segment does not match `-Name`.

## Implementation Plan

### 1. Add the public maintainer function

Define `New-DibsGitLabRepository` in `scripts/Maintainer.Utils.psm1`.

Use:

```powershell
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Name,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $Group = 'dibs-course',

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $DestinationPath,

    [Parameter()]
    [ValidateSet('public', 'internal', 'private')]
    [string] $Visibility = 'public',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $DefaultBranch = 'main',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $Readme = 'README.md'
)
```

The operation target for `ShouldProcess` should be the GitLab project path:

```powershell
$projectPath = "$Group/$Name"
```

The operation description should mention both remote creation and local clone.

### 2. Derive repository metadata from parameters

Build metadata once and reuse it across validation, command construction, and structured output:

```powershell
$projectPath = "$Group/$Name"
$normalizedDestinationPath = Resolve-NewRepositoryDestinationPath `
    -DestinationPath $DestinationPath
$destinationParent = Split-Path -Parent $normalizedDestinationPath
$destinationName = Split-Path -Leaf $normalizedDestinationPath
```

The function should validate that:

```powershell
$destinationName -eq $Name
```

This preserves the “exact requested destination path” contract without hard-coding `python-companion`.

### 3. Validate filesystem preconditions before invoking `glab`

Before calling `tools/Invoke-Tool.ps1`, validate that:

- `Name` is not empty.
- `Group` is not empty.
- `DestinationPath` is normalized to a full path.
- The destination does not already exist.
- The parent directory exists.
- The destination leaf name equals `Name`.

Use terminating errors for failed preconditions.

Recommended error cases:

```text
DestinationAlreadyExists
DestinationParentMissing
DestinationNameMismatch
InvalidRepositoryName
InvalidRepositoryGroup
```

### 4. Invoke `glab` only through `tools/Invoke-Tool.ps1`

Construct the command as data.

For:

```powershell
New-DibsGitLabRepository `
    -Group dibs-course `
    -Name python-companion `
    -DestinationPath E:\teaching\DIBS\projects\python-companion
```

the command should be equivalent to:

```powershell
glab repo create dibs-course/python-companion `
    --public `
    --defaultBranch main `
    --readme README.md
```

Map `-Visibility` to the corresponding `glab` flag:

```powershell
$visibilityFlag = switch ($Visibility) {
    'public'   { '--public' }
    'internal' { '--internal' }
    'private'  { '--private' }
}
```

The argument array should be:

```powershell
@(
    'repo'
    'create'
    $projectPath
    $visibilityFlag
    '--defaultBranch'
    $DefaultBranch
    '--readme'
    $Readme
)
```

Call `tools/Invoke-Tool.ps1` with:

- working directory: destination parent
- executable: `glab`
- arguments as an array

Avoid shell-string invocation.

### 5. Support `-WhatIf` without touching GitLab or the filesystem

If `ShouldProcess` returns false:

- do not invoke `glab`
- do not create directories
- return a structured object with `Created = $false`
- include the command that would have been executed

### 6. Return structured output

Return a stable `PSCustomObject`:

```powershell
[pscustomobject]@{
    Group           = $Group
    Name            = $Name
    ProjectPath     = $projectPath
    Visibility      = $Visibility
    DefaultBranch   = $DefaultBranch
    Readme          = $Readme
    DestinationPath = $normalizedDestinationPath
    Created         = $created
    Command         = $commandMetadata
    ToolOutput      = $toolOutput
}
```

Where `Command` contains:

```powershell
[pscustomobject]@{
    Executable       = 'glab'
    Arguments        = $arguments
    WorkingDirectory = $destinationParent
}
```

## Test Plan

### Unit / contract tests

Add focused Pester coverage for `New-DibsGitLabRepository`.

Use fakes or mocks around the internal `Invoke-Tool` boundary so tests never create a real GitLab project.

Cover:

1. **Builds the expected default `glab repo create` invocation**
   - `Group = dibs-course`
   - `Name = python-companion`
   - project path is `dibs-course/python-companion`
   - visibility flag is `--public`
   - default branch is `main`
   - README is `README.md`
   - working directory is the destination parent

2. **Supports non-default repository metadata**
   - custom group
   - custom name
   - custom visibility
   - custom default branch
   - custom README filename

3. **Rejects an existing destination**
   - no tool invocation

4. **Rejects a missing parent directory**
   - no tool invocation

5. **Rejects a destination whose leaf does not match `-Name`**
   - no tool invocation

6. **Supports `-WhatIf`**
   - no tool invocation
   - returns `Created = $false`
   - includes command metadata

7. **Returns structured output on success**
   - `Group`
   - `Name`
   - `ProjectPath`
   - `Visibility`
   - `DefaultBranch`
   - `Readme`
   - `DestinationPath`
   - `Created = $true`
   - `Command`
   - `ToolOutput`

### Manual verification

For the Python companion repository:

```powershell
New-DibsGitLabRepository `
    -Name python-companion `
    -DestinationPath E:\teaching\DIBS\projects\python-companion `
    -WhatIf
```

Then run without `-WhatIf` only after reviewing the command metadata.

Verify:

- GitLab project exists at `dibs-course/python-companion`
- local clone exists at the requested `DestinationPath`
- `git remote get-url origin` points to the GitLab project
- `git branch --show-current` returns `main`
- README exists in the clone

## Assumptions

- The authenticated `glab` user has permission to create projects under the requested group.
- `dibs-course` is the default group, but the wrapper is not limited to that group.
- Repository creation and local clone are one operation driven by `glab repo create ... --readme README.md`.
- The local destination must be explicit.
- The destination leaf must match the repository name because `glab` clones into a directory named after the repository.
