# [DONE] Create GitLab Repository And Add It As A Submodule

## Summary

Add a maintainer workflow that creates a GitLab repository and then registers it as a submodule in an existing parent
repository.

Keep the design compositional, but avoid mixing responsibilities:

- repository creation owns the GitLab project;
- submodule registration owns the checkout inside the parent repository;
- validation happens before any external tool is invoked;
- `-WhatIf` must not create a remote repository or mutate the parent repo.

This workflow should build on the existing maintainer repository-creation contract, but it should not change that
helper’s observable behavior.

## Public API

Add a new public function to `scripts/Maintainer.Utils.psm1`:

```powershell
New-DibsGitLabRepositorySubmodule `
    -Group dibs-course `
    -Name python-companion `
    -ParentRepositoryPath E:\teaching\DIBS\projects `
    -SubmodulePath companions/python-companion
```

Recommended defaults:

```powershell
New-DibsGitLabRepositorySubmodule `
    -Name python-companion `
    -ParentRepositoryPath E:\teaching\DIBS\projects `
    -SubmodulePath companions/python-companion
```

Where:

- `Group` defaults to `dibs-course`.
- `Visibility` defaults to `public`.
- `DefaultBranch` defaults to `main`.
- `Readme` defaults to `README.md`.
- `SubmodulePath` is relative to `ParentRepositoryPath`.
- `ParentRepositoryPath` must be an existing Git work tree.

## Key Design Decision

Do not create the repository by cloning directly into the final submodule path.

Instead, use one of these safe approaches:

1. Prefer adding support to the repository creation helper for a no-local-clone mode if `glab repo create` supports the
   required flag in the current wrapper.
2. Or create the repository in a temporary maintainer workspace, then remove the temporary clone after obtaining the
   remote URL.
3. Then run `git submodule add <remoteUrl> <SubmodulePath>` from the parent repository.

This avoids a lifecycle conflict where the creation helper clones the repo first, and `git submodule add` then tries to
clone into an already-existing path.

## Implementation Plan

### 1. Lock the composed workflow contract with tests first

Add failing Pester tests in `tests/Maintainer.Utils.Tests.ps1` for the new public function before implementing
production code.

Cover the visible contract:

- creates a GitLab repository using the existing maintainer creation boundary;
- adds the created repository as a submodule under the requested relative path;
- returns structured output;
- honours `-WhatIf`;
- rejects invalid parent repository paths;
- rejects unsafe or conflicting submodule paths;
- does not invoke external tools after validation failure.

Use fake tool invocations rather than real `glab` or `git` calls.

### 2. Add the composed public function

Add `New-DibsGitLabRepositorySubmodule` to `Maintainer.Utils.psm1`.

Suggested signature:

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
    [string] $ParentRepositoryPath,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $SubmodulePath,

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

Keep the function short by extracting validation and command-building helpers.

### 3. Validate the parent repository before tool execution

Before creating anything, validate that:

- `ParentRepositoryPath` exists;
- it is a directory;
- it is a Git work tree;
- the parent repository is not bare;
- the parent repo path can be normalized to a full path.

The Git work tree check should go through `Invoke-MaintainerTool` with:

```powershell
git -C <ParentRepositoryPath> rev-parse --show-toplevel
```

If the module already has an internal Git repository validation helper, reuse it instead of introducing duplicate logic.

### 4. Validate the submodule destination before tool execution

Validate that `SubmodulePath`:

- is relative, not rooted;
- does not contain parent traversal such as `..`;
- is not empty;
- does not resolve outside `ParentRepositoryPath`;
- does not already exist in the working tree;
- does not already appear in `.gitmodules`;
- has a leaf name that is coherent with `Name`, unless explicitly overridden.

The strict default should be:

```text
leaf(SubmodulePath) == Name
```

This preserves predictable `git submodule add` behavior and prevents accidental registration under an unrelated path.

### 5. Reuse repository creation without changing its existing contract

Call the existing repository creation helper from the composed workflow.

However, the composed workflow needs a remote URL for `git submodule add`. Prefer this priority order:

1. use a `RemoteUrl` field if the existing helper already returns one;
2. derive the URL from returned `ProjectPath` and the configured GitLab host;
3. add a small internal helper that builds the expected clone URL from stable metadata.

Do not modify the existing helper’s public behavior unless a separate TDD cycle first locks and extends that contract.

### 6. Add the submodule through `Invoke-MaintainerTool`

After repository creation succeeds, run:

```powershell
git -C <ParentRepositoryPath> submodule add <RemoteUrl> <SubmodulePath>
```

Use array arguments, not shell strings:

```powershell
@(
    '-C'
    $normalizedParentRepositoryPath
    'submodule'
    'add'
    $remoteUrl
    $SubmodulePath
)
```

This keeps quoting stable across spaces, Windows paths, and CI environments.

### 7. Make `-WhatIf` cover the full composed operation

When `ShouldProcess` returns false:

- do not create the GitLab repository;
- do not add the submodule;
- do not mutate `.gitmodules`;
- return structured command metadata for both planned operations.

The planned output should make clear that nothing was created.

### 8. Return structured output

Return a stable object:

```powershell
[pscustomobject]@{
    Group                = $Group
    Name                 = $Name
    ProjectPath          = "$Group/$Name"
    Visibility           = $Visibility
    DefaultBranch        = $DefaultBranch
    ParentRepositoryPath = $normalizedParentRepositoryPath
    SubmodulePath        = $normalizedSubmodulePath
    RemoteUrl            = $remoteUrl
    Created              = $created
    SubmoduleAdded       = $submoduleAdded
    Repository           = $repositoryResult
    Commands             = [pscustomobject]@{
        CreateRepository = $createRepositoryCommand
        AddSubmodule     = $addSubmoduleCommand
    }
    ToolOutput           = $toolOutput
}
```

Keep `Repository` as the raw structured output from the creation helper so the new workflow does not flatten away useful
data.

## Test Plan

### Contract tests

Add Pester coverage for:

1. **Happy path**
   - invokes the repository creation helper once;
   - invokes `git submodule add` once;
   - uses the parent repository as the Git working directory;
   - passes the expected remote URL and submodule path;
   - returns `Created = $true` and `SubmoduleAdded = $true`.

2. **WhatIf**
   - invokes no external tools;
   - returns `Created = $false`;
   - returns `SubmoduleAdded = $false`;
   - includes planned command metadata.

3. **Invalid parent repository**
   - rejects missing path;
   - rejects non-directory path;
   - rejects directory that is not a Git work tree;
   - does not create the GitLab repository.

4. **Invalid submodule path**
   - rejects rooted paths;
   - rejects parent traversal;
   - rejects existing paths;
   - rejects paths already present in `.gitmodules`;
   - rejects destination leaf mismatch by default.

5. **Repository creation failure**
   - does not attempt `git submodule add`;
   - surfaces the original terminating error.

6. **Submodule add failure**
   - reports repository creation as successful;
   - reports submodule addition as failed;
   - preserves the tool failure output.

7. **Command shape**
   - asserts argument arrays exactly;
   - asserts no shell-string invocation;
   - asserts command metadata is stable.

## Documentation Plan

Update `scripts/README.md` with:

- when to use `New-DibsGitLabRepository`;
- when to use `New-DibsGitLabRepositorySubmodule`;
- an example for `python-companion`;
- a note that the submodule path is relative to the parent repository;
- a note that `-WhatIf` previews both the repository creation and submodule add steps;
- a warning that the workflow intentionally does not modify `git/New-IndexRepo.ps1`.

## Verification

1. Run the focused Pester file:

```powershell
pwsh -NoProfile -File ./tools/Invoke-Pester.ps1 `
    -Path ./scripts/tests/Maintainer.Utils.Tests.ps1
```

2. Run the PowerShell analyser on touched files:

```powershell
pwsh -NoProfile -File ./tools/Invoke-PSSA.ps1 `
    -Path ./scripts/Maintainer.Utils.psm1,./scripts/tests/Maintainer.Utils.Tests.ps1
```

3. Run a manual dry run:

```powershell
New-DibsGitLabRepositorySubmodule `
    -Name python-companion `
    -ParentRepositoryPath E:\teaching\DIBS\projects `
    -SubmodulePath companions/python-companion `
    -WhatIf
```

4. For the real path, verify:

```powershell
git -C E:\teaching\DIBS\projects submodule status
git -C E:\teaching\DIBS\projects config --file .gitmodules --get-regexp submodule
```

5. Confirm that `.gitmodules` and the submodule gitlink are staged or visible as expected in the parent repository.

## Decisions

- Implement this as a composed maintainer workflow, not as a replacement for the existing repository creation helper.
- Keep `git/New-IndexRepo.ps1` unchanged.
- Use `git submodule add` as the only operation that materializes the submodule inside the parent repository.
- Keep all external command execution behind `Invoke-MaintainerTool`.
- Prefer TDD with fake tool boundaries over manual-only validation.

## Further Considerations

1. If the repository creation helper currently always clones locally, consider a later small refactor to support a
   `-SkipLocalClone` or `-NoClone` mode, backed by tests.
2. If different GitLab hosts are expected, expose an explicit `-GitLabHost` parameter instead of relying on ambient
   `glab` configuration.
3. If maintainers need SSH clone URLs instead of HTTPS, add a separate `-CloneProtocol` parameter later; do not mix that
   concern into the first implementation slice.
