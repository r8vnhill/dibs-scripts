#Requires -Version 7.5
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string] $Path,

    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $User,

    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $Name,

    [switch] $Public,

    [ValidateNotNullOrWhiteSpace()]
    [string] $Remote = 'origin'
)

Set-StrictMode -Version 3.0

$createGitLabRepo = Join-Path $PSScriptRoot 'New-GitLabRepository.ps1' -Resolve
$setGitRemote = Join-Path $PSScriptRoot 'Set-GitRemote.ps1' -Resolve

$forwardBoundParams = @{}
if ($PSBoundParameters.ContainsKey('WhatIf')) {
    $forwardBoundParams['WhatIf'] = $PSBoundParameters['WhatIf']
}
if ($PSBoundParameters.ContainsKey('Confirm')) {
    $forwardBoundParams['Confirm'] = $PSBoundParameters['Confirm']
}

$gitLab = & $createGitLabRepo -Name $Name -Public:$Public @forwardBoundParams

$remoteParams = @{}
$remoteParams += $forwardBoundParams
$remoteParams += @{ Path = $Path; User = $User; Name = $Name; Remote = $Remote }

$remoteResult = & $setGitRemote @remoteParams

[PSCustomObject]@{
    Path   = $Path
    GitLab = $gitLab
    Remote = $remoteResult
}
