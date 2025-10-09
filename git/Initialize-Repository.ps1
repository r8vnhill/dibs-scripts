# Initialize-Repository.ps1
#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string] $LiteralPath
)

$invoker = Join-Path $PSScriptRoot '..' 'core' 'Invoke-Tool.ps1' -Resolve

$repoPath = $PSCmdlet.GetResolvedProviderPathFromPSPath($LiteralPath)

$state = @{
    Path           = $repoPath
    InitializedGit = $false
    Message        = ''
}

$inside = try {
    & $invoker git -C $repoPath rev-parse --is-inside-work-tree | Out-Null
    $true
}
catch { $false }

if (-not $inside) {
    if ($WhatIfPreference) {
        # Caso especial: sin repo y es WhatIf → no hacemos nada y lo decimos explícito
        $state.Message = 'WhatIf: would initialize repository and set HEAD to main'
    }
    elseif ($PSCmdlet.ShouldProcess($repoPath, 'git init')) {
        & $invoker git -C $repoPath init | Out-Null
        & $invoker git -C $repoPath symbolic-ref HEAD refs/heads/main | Out-Null
        $state.InitializedGit = $true
        $state.Message = 'Repository initialized.'
    }
    else {
        # Confirm cancelado / ShouldProcess = false
        $state.Message = 'Initialization skipped by user confirmation.'
    }
}
else {
    $state.Message = 'Repository already initialized. Nothing to do.'
}

[pscustomobject]$state
