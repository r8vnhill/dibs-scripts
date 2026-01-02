<# 
.SYNOPSIS
Checks whether a path is a Git repository.

.DESCRIPTION
Resolves the provided directory path and runs `git rev-parse --is-inside-work-tree`.
Returns an object with Status set to `IsRepository` or `NotRepository`, and Error
populated when the Git check fails.

.PARAMETER Path
Directory path to test.

.OUTPUTS
PSCustomObject with Status and Error properties.

.EXAMPLE
PS> .\git\Test-GitRepository.ps1 -Path C:\work\my-repo

Status       Error
------       -----
IsRepository

.EXAMPLE
PS> .\git\Test-GitRepository.ps1 -Path C:\work\not-a-repo

Status        Error
------        -----
NotRepository <error details>
#>
#Requires -Version 7.5
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string] $Path
)

Set-StrictMode -Version 3.0

$invoker = Join-Path $PSScriptRoot '..' 'tools' 'Invoke-Tool.ps1' -Resolve

$result = [PSCustomObject]@{
    Status = 'Pending'
    Error  = $null
}

try {
    $repoPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
    & $invoker git -C $repoPath rev-parse --is-inside-work-tree | Out-Null
    $result.Status = 'IsRepository'
}
catch {
    $result.Status = 'NotRepository'
    $result.Error = $_
}

$result
