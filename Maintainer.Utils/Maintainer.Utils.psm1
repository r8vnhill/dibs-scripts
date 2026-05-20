#Requires -Version 7.6

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Private' 'Common.ps1')
. (Join-Path $PSScriptRoot 'Private' 'GitLabRepository.ps1')
. (Join-Path $PSScriptRoot 'Private' 'GitLabRepositorySubmodule.ps1')
. (Join-Path $PSScriptRoot 'Public' 'New-DibsGitLabRepository.ps1')
. (Join-Path $PSScriptRoot 'Public' 'New-DibsGitLabRepositorySubmodule.ps1')

Export-ModuleMember -Function New-DibsGitLabRepository, New-DibsGitLabRepositorySubmodule
