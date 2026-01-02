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
