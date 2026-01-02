<#
.SYNOPSIS
Sets or updates a GitLab remote for a local repository.

.DESCRIPTION
Validates that the path is a Git repository, normalizes the GitLab project name,
builds the HTTPS remote URL, and then adds or updates the remote. Returns a result
object describing the action taken.

.PARAMETER Path
Directory path to the local Git repository.

.PARAMETER User
GitLab user or group name that owns the repository.

.PARAMETER Name
Repository name (will be normalized for GitLab naming rules).

.PARAMETER Remote
Remote name to add or update. Defaults to origin.

.OUTPUTS
PSCustomObject with Path, RemoteName, RemoteUrl, Action, and Reason properties.

.EXAMPLE
PS> .\git\Set-GitLabRemote.ps1 -Path C:\work\my-repo -User acme -Name "My Project"

Path        RemoteName RemoteUrl                                  Action Reason
----        ---------- ---------                                  ------ ------
C:\work\... origin     https://gitlab.com/acme/my-project.git      Added  Remote 'origin' created.

.EXAMPLE
PS> .\git\Set-GitLabRemote.ps1 -Path . -User acme -Name tools-api -Remote upstream -WhatIf
WhatIf: Performing the operation "Set Git remote" on target "C:\work\repo remote upstream -> https://gitlab.com/acme/tools-api.git".
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

    [ValidateNotNullOrWhiteSpace()]
    [string] $Remote = 'origin'
)

Set-StrictMode -Version 3.0

$testRepo = Join-Path $PSScriptRoot 'Test-GitRepository.ps1' -Resolve
$convertName = Join-Path $PSScriptRoot 'ConvertTo-ValidGitLabName.ps1' -Resolve
$invoker = Join-Path $PSScriptRoot '..' 'tools' 'Invoke-Tool.ps1' -Resolve

if ((& $testRepo -Path $Path).Status -ne 'IsRepository') {
    throw [System.InvalidOperationException]::new(
        "Path '$Path' is not a valid Git repository."
    )
}

$repoPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
$remoteUrl = 'https://gitlab.com/{0}/{1}.git' -f $User, (& $convertName -Name $Name)

$result = [PSCustomObject]@{
    Path       = $repoPath
    RemoteName = $Remote
    RemoteUrl  = $remoteUrl
    Action     = 'None'
    Reason     = ''
}

$target = '{0} remote {1} -> {2}' -f $repoPath, $Remote, $remoteUrl
if (!$PSCmdlet.ShouldProcess($target, 'Set Git remote')) {
    $result.Action = 'Skipped'
    $result.Reason = 'Operation cancelled by user.'
}
else {
    try {
        try {
            & $invoker git -C $repoPath remote get-url $Remote | Out-Null
            & $invoker git -C $repoPath remote set-url $Remote $remoteUrl | Out-Null
            $result.Action = 'Updated'
            $result.Reason = "Remote '$Remote' URL updated."
        }
        catch {
            & $invoker git -C $repoPath remote add $Remote $remoteUrl | Out-Null
            $result.Action = 'Added'
            $result.Reason = "Remote '$Remote' created."
        }
    }
    catch {
        $result.Action = 'Failed'
        $result.Reason = $_
    }
}

$result
