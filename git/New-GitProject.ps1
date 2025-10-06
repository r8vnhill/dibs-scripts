#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z0-9._-]+$')]
    [string] $Username,

    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z0-9._-]+$')]
    [string] $RepositoryName,

    [ValidatePattern('^[a-zA-Z0-9._-]*$')]
    [string] $Prefix = '',

    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string] $LiteralPath = '.',

    [switch] $Public
)

$result = @{
    NewRepository        = $null
    InitializeRepository = $null
    SetRemote            = $null
}

$newRepository = Join-Path $PSScriptRoot 'New-GitLabRepository.ps1' -Resolve
$initializeRepository = Join-Path $PSScriptRoot 'Initialize-Repository.ps1' -Resolve
$setRemote = Join-Path $PSScriptRoot 'Add-Remote.ps1' -Resolve

$forward = @{}
foreach ($k in 'WhatIf', 'Confirm') {
    if ($PSBoundParameters.ContainsKey($k)) { $forward[$k] = $PSBoundParameters[$k] }
}

$normalized = (
    $RepositoryName.ToLowerInvariant() -replace '\s+', '-' -replace '[^a-z0-9-]', '')

$repoSlug = if ([string]::IsNullOrEmpty($Prefix)) {
    $normalized
}
else {
    ($Prefix.Trim('-') + '-' + $normalized.Trim('-')).Trim('-')
}

$result.NewRepository = & $newRepository @forward -Name $repoSlug -Public:$Public
$remoteUrl = "git@gitlab.com:$Username/$repoSlug.git"
$result.InitializeRepository = & $initializeRepository @forward -LiteralPath $LiteralPath
$result.SetRemote = (
    & $setRemote @forward -Path $LiteralPath -RemoteName 'origin' -RemoteUrl $remoteUrl)

[pscustomobject]$result
