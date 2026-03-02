#Requires -Version 7.5
<#
.SYNOPSIS
    Initializes a Git "index" repository at a given path and adds one or more
    GitLab-hosted submodules to it.

.DESCRIPTION
    Creates (or reuses) a directory at `RootPath`, initializes it as a Git repository, and
    then, for each pipeline input (or explicit parameter set), adds a submodule whose
    remote URL is derived from `GitLabUser` and `RemoteName`.

    This script is an advanced function-style script (script cmdlet) that supports:
    - WhatIf/Confirm via `SupportsShouldProcess`
    - Pipeline binding by property name for `RemoteName` and `LocalName`

    The script uses a helper invoker script (`tools/Invoke-Tool.ps1`) to execute `git`,
    ensuring consistent tooling execution and error handling across environments.

.PARAMETER RootPath
    Path where the index repository will be created/initialized.

    This path is resolved to a provider path using `GetUnresolvedProviderPathFromPSPath`,
    so relative paths and `PSDrive` paths are supported.

.PARAMETER GitLabUser
    The GitLab username (or group/namespace) used to construct the submodule remote URL.

    The URL format used is: `https://gitlab.com/<GitLabUser>/<RemoteName>.git`

.PARAMETER RemoteName
    The remote repository name on GitLab (without `.git`).

    This parameter supports pipeline binding by property name, enabling input objects
    like: `[PSCustomObject]@{ RemoteName = 'repo'; LocalName = 'path' }`.

.PARAMETER LocalName
    The directory name (relative to the index repository root) where the submodule will be
    checked out.

    This parameter supports pipeline binding by property name.

.INPUTS
    Objects with properties:
    - RemoteName ([String])
    - LocalName ([String])

.OUTPUTS
    By default, emits the output of: `git submodule status`

.NOTES
    - Requires PowerShell 7.5 or later.
    - Runs in StrictMode 3.0 for safer scripting.
    - Uses ConfirmImpact = Medium; use `-Confirm` to force prompting or `-WhatIf` to simulate changes.

.EXAMPLE
    Initialize an index repository and add a single submodule.

    .\New-IndexRepo.ps1 `
        -RootPath .\index-repo `
        -GitLabUser 'my-group' `
        -RemoteName 'docs-service' `
        -LocalName 'services/docs-service'

.EXAMPLE
    Add multiple submodules via pipeline input.

    @(
        [PSCustomObject]@{
            RemoteName = 'docs-service'
            LocalName = 'services/docs-service'
        },
        [PSCustomObject]@{
            RemoteName = 'auth-service'
            LocalName = 'services/auth-service'
        }
    ) | .\New-IndexRepo.ps1 -RootPath .\index-repo -GitLabUser 'my-group'
    ```

.EXAMPLE
    Preview changes without modifying anything.

    .\New-IndexRepo.ps1 `
        -RootPath .\index-repo `
        -GitLabUser 'my-group' `
        -RemoteName 'docs-service' `
        -LocalName 'services/docs-service' `
        -WhatIf
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $RootPath,

    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $GitLabUser,

    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $RemoteName,

    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $LocalName
)

begin {
    Set-StrictMode -Version 3.0
    $invoker = Join-Path $PSScriptRoot '..' 'tools' 'Invoke-Tool.ps1' -Resolve
    $canProcess = $true

    $repoPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($RootPath)

    if ($PSCmdlet.ShouldProcess($repoPath, 'Initialize index repository')) {
        New-Item -ItemType Directory -Path $repoPath -Force | Out-Null
        & $invoker git -C $repoPath init -ErrorAction Stop | Out-Null
    }
}

process {
    $url = 'https://gitlab.com/{0}/{1}.git' -f $GitLabUser, $RemoteName
    $target = Join-Path $repoPath $LocalName
    $action = 'Add submodule "{0}" from "{1}"' -f $LocalName, $url
    if ($PSCmdlet.ShouldProcess($target, $action)) {
        try {
            & $invoker git -C $repoPath submodule add $url $LocalName -ErrorAction Stop | 
                Out-Null
        }
        catch {
            $category = [System.Management.Automation.ErrorCategory]::InvalidOperation
            $errorParams = @{
                Message      = 'Failed to add submodule "{0}" at "{1}". {2}' -f @(
                    $LocalName, $target, $_.Exception.Message)
                Category     = $category
                TargetObject = $target
                ErrorId      = 'New-IndexRepo.SubmoduleAddFailed'
            }
            Write-Error @errorParams
        }
    }
}

end {
    & $invoker git -C $repoPath submodule status -ErrorAction Stop
}
