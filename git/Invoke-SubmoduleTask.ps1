#Requires -Version 7.5
<#
.SYNOPSIS
    Runs a submodule "task" (status check or fetch+update) against a specific Git
    submodule working directory.

.DESCRIPTION
    Given a submodule name and its path on disk, this script can:

    - `Status` (default): report whether the submodule working tree is clean or has
      pending changes, using `git status --porcelain=v1 -z`.
    - `Fetch`: fetch and prune all remotes for the submodule, then update the submodule to
      the latest commit of the configured remote
      (`git submodule update --remote -- <Name>`), and finally report status.

    This script is an advanced function-style script (script cmdlet) that supports
    WhatIf/Confirm via `SupportsShouldProcess`. When `-Action Fetch` is selected, both the
    fetch step and the update step are guarded by ShouldProcess; if either step is skipped
    (e.g., because of `-WhatIf`), the output object records the skip reason.

    The script uses a helper invoker script (`tools/Invoke-Tool.ps1`) to execute `git`,
    ensuring consistent tooling execution and error behavior.

.PARAMETER Name
    The submodule name as it appears in `.gitmodules` / `git submodule status`.

    This parameter supports pipeline binding by property name.

.PARAMETER Path
    Filesystem path to the submodule working directory.

    Supports pipeline binding by property name. Also accepts `FullName` as an alias, which
    makes it convenient to pipe from `Get-ChildItem` results.

.PARAMETER Action
    Which operation to perform:

    - `Status` (default): only compute and return the cleanliness status.
    - `Fetch`: fetch/prune remotes, update the submodule to the latest configured remote
      commit, then compute status.

.INPUTS
    Objects with properties:
    - Name ([String])
    - Path ([String]) or FullName ([String])

.OUTPUTS
    [PSCustomObject] with the following properties:
    - Submodule: the submodule name
    - Path: submodule path
    - Action: the requested action (`Status` or `Fetch`)
    - Status: `Clean` or `DirtyOrPending`
    - Mode: `Executed` or `Skipped` (for Fetch when ShouldProcess returns false)
    - Reason: skip reason (`WhatIf` or `ShouldProcessFalse`), otherwise `$null`
    - Error: currently always `$null` on success (reserved for future enrichment)

.NOTES
    - Requires PowerShell 7.5 or later.
    - StrictMode 3.0 is enabled.
    - ConfirmImpact is Medium; use `-Confirm` to force prompting or `-WhatIf` to simulate.

.EXAMPLE
    Get the status of a single submodule.

    .\Invoke-SubmoduleTask.ps1 -Name 'docs-service' -Path .\services\docs-service
    
.EXAMPLE
    Fetch and update a submodule, then report whether it is clean.

    .\Invoke-SubmoduleTask.ps1 -Name 'docs-service' -Path .\services\docs-service -Action Fetch

.EXAMPLE
    Pipe a folder listing into the script using `FullName` and a computed `Name`.

    Get-ChildItem .\services -Directory |
        Select-Object @{ Name = 'Name'; Expression = { $_.Name } }, FullName |
        .\Invoke-SubmoduleTask.ps1 -Action Status

.EXAMPLE
    Preview what would be fetched/updated without making changes.

    .\Invoke-SubmoduleTask.ps1 -Name 'docs-service' -Path .\services\docs-service -Action Fetch -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string] $Name,

    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [Alias('FullName')]
    [string] $Path,

    [ValidateSet('Status', 'Fetch')]
    [string] $Action = 'Status'
)

begin {
    Set-StrictMode -Version 3.0
    $invoker = Join-Path $PSScriptRoot '..' 'tools' 'Invoke-Tool.ps1' -Resolve
}
process {
    try {
        $executionMode = 'Executed'
        $statusLabel = 'Unknown'
        $skipReason = $null

        if ($Action -eq 'Fetch') {
            $fetchTarget = '{0} ({1})' -f $Name, $Path
            $fetchAction = 'Fetch and prune all remotes'
            if (-not $PSCmdlet.ShouldProcess($fetchTarget, $fetchAction)) {
                $executionMode = 'Skipped'
                $skipReason = if ($WhatIfPreference) { 'WhatIf' } else { 'ShouldProcessFalse' }
            }
            else {
                & $invoker git -C $Path fetch --all --prune | Out-Null

                $repoRoot = Split-Path $Path -Parent
                $updateAction = 'Update submodule to latest configured remote commit'
                if (-not $PSCmdlet.ShouldProcess($fetchTarget, $updateAction)) {
                    $executionMode = 'Skipped'
                    $skipReason = if ($WhatIfPreference) { 'WhatIf' } else { 'ShouldProcessFalse' }
                }
                else {
                    & $invoker git -C $repoRoot submodule update --remote -- $Name | Out-Null
                }
            }
        }

        $statusResult = & $invoker git -C $Path status --porcelain=v1 -z
        $statusOutput = @($statusResult.Output)
        $statusPayload = [string]($statusOutput -join '')
        $hasPendingChanges = $statusPayload.Length -gt 0
        $statusLabel = if ($hasPendingChanges) { 'DirtyOrPending' } else { 'Clean' }

        [pscustomobject]@{
            Submodule = $Name
            Path      = $Path
            Action    = $Action
            Status    = $statusLabel
            Mode      = $executionMode
            Reason    = $skipReason
            Error     = $null
        }
    }
    catch {
        $errorParams = @{
            Message      = 'Failed to process submodule "{0}" at "{1}". {2}' -f @(
                $Name, $Path, $_.Exception.Message)
            Category     = [System.Management.Automation.ErrorCategory]::InvalidOperation
            TargetObject = $Path
            ErrorId      = 'Invoke-SubmoduleTask.Failed'
        }
        Write-Error @errorParams
    }
}
