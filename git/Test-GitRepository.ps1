#Requires -Version 7.5
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string] $Path
)

$invoker = Join-Path $PSScriptRoot '..' 'core' 'Invoke-Tool.ps1' -Resolve

$repoPath = $PSCmdlet.GetResolvedProviderPathFromPSPath($Path)

try {
    Write-Verbose "Checking if '$repoPath' is inside a Git work tree"
    & $invoker git -C $repoPath rev-parse --is-inside-work-tree | Out-Null
    $true
}
catch {
    Write-Verbose "'$repoPath' is not inside a Git work tree"
    $false
}
