#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^(https://|git@|ssh://)')]
    [string] $RemoteUrl,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $Path = '.',

    [ValidatePattern('^[\w.-]+$')]
    [string] $RemoteName = 'origin'
)

$invoker = Join-Path $PSScriptRoot '..' 'core' 'Invoke-Tool.ps1' -Resolve

$rp = Resolve-Path -LiteralPath $Path
$repoPath = if ($rp.ProviderPath) { $rp.ProviderPath } else { $rp.Path }

$result = @{
    RepoPath = $repoPath
    Remote   = $RemoteName
    Url      = $RemoteUrl
    Existed  = $false
    Changed  = $false
    Action   = 'none'
    Output   = @()
    Message  = ''
}

$inside = try {
    & $invoker git -C $repoPath rev-parse --is-inside-work-tree | Out-Null
    $true
}
catch { $false }

if (!$inside -and $WhatIfPreference) {
    $result.Action = 'skipped'
    $result.Message = 'WhatIf: would set remote after repository initialization'
}
elseif (!$inside) {
    throw [System.AggregateException]::new(
        "The path '$repoPath' is not a Git repository (or does not exist).",
        $_.Exception
    )
}
else {
    $currentUrl = try {
        $res = & $invoker git -C $repoPath remote get-url $RemoteName
        $res.Output.Trim()
    }
    catch { $null }

    $result.Existed = [bool]$currentUrl

    if ($null -ne $currentUrl) {
        if ([string]::Equals($currentUrl, $RemoteUrl, 'OrdinalIgnoreCase')) {
            $result.Action = 'none'
            $result.Message = 'Remote already configured'
        }
        elseif ($PSCmdlet.ShouldProcess("$RemoteName → $RemoteUrl", 'git remote set-url')) {
            $set = & $invoker git -C $repoPath remote set-url $RemoteName $RemoteUrl
            $result.Changed = $true
            $result.Action = 'set-url'
            $result.Output = $set.Output
            $result.Message = "Remote URL updated (was: $currentUrl)"
        }
        else {
            $result.Action = 'skipped'
            $result.Message = 'Operation skipped'
        }
    }
    elseif ($PSCmdlet.ShouldProcess("$RemoteName → $RemoteUrl", 'git remote add')) {
        $add = & $invoker git -C $repoPath remote add $RemoteName $RemoteUrl
        $result.Changed = $true
        $result.Action = 'add'
        $result.Output = $add.Output
        $result.Message = 'Remote added'
    }
    else {
        $result.Action = 'skipped'
        $result.Message = 'Operation skipped'
    }
}

[pscustomobject]$result
