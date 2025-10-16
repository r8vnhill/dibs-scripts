#Requires -Version 7.5
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string] $LiteralPath
)

$invoker = Join-Path $PSScriptRoot '..' 'core' 'Invoke-Tool.ps1' -Resolve

$repoPath = $PSCmdlet.GetResolvedProviderPathFromPSPath($LiteralPath)

$inside = try {
    & $invoker git -C $repoPath rev-parse --is-inside-work-tree | Out-Null
    $true
}
catch { $false }

if (!$inside) {
    if ($WhatIfPreference) {
        Write-Output "WhatIf: would initialize repository and set HEAD to main"
    }
    elseif ($PSCmdlet.ShouldProcess($repoPath, 'git init')) {
        & $invoker git -C $repoPath init | Out-Null
        & $invoker git -C $repoPath symbolic-ref HEAD refs/heads/main | Out-Null

        $state.InitializedGit = $true
        $state.Message = 'Repository initialized.'
    }
    else {
        $state.Message = 'Initialization skipped by user confirmation.'
    }
}
else {
    $state.Message = 'Repository already initialized. Nothing to do.'
}

$state
