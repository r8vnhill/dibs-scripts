<#
.SYNOPSIS
Creates a GitLab repository and sets the local Git remote.

.DESCRIPTION
Orchestrates GitLab repository creation and remote configuration by invoking
New-GitLabRepository.ps1 and Set-GitRemote.ps1. Returns a summary object with
the GitLab creation result and the remote update result.

.PARAMETER Path
Directory path to the local Git repository.

.PARAMETER User
GitLab user or group name that owns the repository.

.PARAMETER Name
Repository name to create and set as the remote target.

.PARAMETER Public
Create the repository as public. Defaults to private when omitted.

.PARAMETER Remote
Remote name to add or update. Defaults to origin.

.OUTPUTS
PSCustomObject with Path, GitLab, and Remote properties.

.EXAMPLE
PS> .\git\Publish-GitRepository.ps1 -Path C:\work\my-repo -User madoka -Name "My Project"

Path        GitLab                          Remote
----        -----                          ------
C:\work\... @{Name=...; Visibility=...}     @{Path=...; RemoteName=...}

.EXAMPLE
PS> .\git\Publish-GitRepository.ps1 -Path . -User sayaka -Name tools-api -Public -WhatIf
WhatIf: Performing the operation "Create GitLab repository (public)" on target "tools-api".
WhatIf: Performing the operation "Set Git remote" on target "C:\work\repo remote origin -> https://gitlab.com/sayaka/tools-api.git".
#>
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
