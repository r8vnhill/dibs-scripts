#Requires -Version 7.6

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Root module entry point for maintainer utilities.

.DESCRIPTION
Keeps the existing `Maintainer.Utils.psm1` import path stable while loading the implementation from nested module files.

The nested layout separates shared private support code from public maintainer commands:

- `Private/Common.ps1` contains shared helpers.
- `Private/GitLabRepository.ps1` contains GitLab repository implementation support.
- `Private/GitLabRepositorySubmodule.ps1` contains submodule workflow support.
- `Public/*.ps1` contains exported command entry points.

This root module should stay thin. Add new behavior to the nested files and export only stable public commands from 
here.
#>

$moduleRoot = Join-Path $PSScriptRoot 'Maintainer.Utils'

. (Join-Path $moduleRoot 'Private' 'Common.ps1')
. (Join-Path $moduleRoot 'Private' 'GitLabRepository.ps1')
. (Join-Path $moduleRoot 'Private' 'GitLabRepositorySubmodule.ps1')
. (Join-Path $moduleRoot 'Public' 'New-DibsGitLabRepository.ps1')
. (Join-Path $moduleRoot 'Public' 'New-DibsGitLabRepositorySubmodule.ps1')

Export-ModuleMember -Function @(
    'New-DibsGitLabRepository'
    'New-DibsGitLabRepositorySubmodule'
)