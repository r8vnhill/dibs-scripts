<#
.SYNOPSIS
Creates a GitLab repository if it does not already exist.

.DESCRIPTION
Normalizes the repository name for GitLab, checks if it exists via `glab repo view`,
and creates it when missing. Returns an object with the normalized name, visibility,
and a Status object describing whether it was created or why it was skipped/failed.

.PARAMETER Name
Repository name to create (will be normalized for GitLab naming rules).

.PARAMETER Public
Create the repository as public. Defaults to private when omitted.

.OUTPUTS
PSCustomObject with Name, Visibility, and Status properties.

.EXAMPLE
PS> .\git\New-GitLabRepository.ps1 -Name "My Project"

Name       Visibility Status
----       ---------- ------
my-project private    @{Created=False; Reason=...}

.EXAMPLE
PS> .\git\New-GitLabRepository.ps1 -Name "tools-api" -Public -WhatIf
WhatIf: Performing the operation "Create GitLab repository (public)" on target "tools-api".
#>
#Requires -Version 7.5
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $Name,

    [switch] $Public
)

Set-StrictMode -Version 3.0

$normalized = & (Join-Path $PSScriptRoot 'ConvertTo-ValidGitLabName.ps1') -Name $Name
$visibility = if ($Public.IsPresent) { 'public' } else { 'private' }
$invoker = Join-Path $PSScriptRoot '..' 'tools' 'Invoke-Tool.ps1' -Resolve

$repository = [PSCustomObject]@{
    Name       = $normalized
    Visibility = $visibility
    Status     = [PSCustomObject]@{
        Created = $false
        Reason  = ''
    }
}

try {
    & $invoker glab repo view $repository.Name | Out-Null
    $repository.Status.Reason = '{0} already exists on GitLab.' -f $repository.Name
}
catch {
    if ($PSCmdlet.ShouldProcess($normalized, "Create GitLab repository ($visibility)")) {
        try {
            $args = @('repo', 'create', $normalized, '--defaultBranch', 'main',
                ('--{0}' -f $visibility))

            $result = & $invoker glab @args
            $repository.Status.Created = $true
            $repository.Status.Reason = $result
        }
        catch {
            $repository.Status.Reason = $_
        }
    }
    else {
        $repository.Status.Reason = 'Creation cancelled by user.'
    }
}

$repository
