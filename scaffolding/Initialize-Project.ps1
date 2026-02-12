<#
.SYNOPSIS
    Initializes a project folder and optionally creates a README.md file.

.DESCRIPTION
    This script creates a target project directory under a given base path and uses
    `New-Readme.ps1` to generate README content when `README.md` does not already exist.
    It supports `ShouldProcess`, so `-WhatIf` and `-Confirm` are available for safe
    execution.

.PARAMETER Name
    The project folder name to create under the specified base path. This parameter is
    mandatory and must not be null, empty, or whitespace.

.PARAMETER Path
    The existing base directory where the project folder will be created. This parameter
    is mandatory and must resolve to a valid container path.

.EXAMPLE
    PS> ./Initialize-Project.ps1 -Name "MyApp" -Path "C:\Projects"

    Creates `C:\Projects\MyApp` if needed and creates `README.md` when it does not exist.

.EXAMPLE
    PS> ./Initialize-Project.ps1 -Name "MyApp" -Path "C:\Projects" -WhatIf

    Shows what actions would be performed without creating or writing files.
#>
#Requires -Version 7.5
# [!code focus:2]
[CmdletBinding(SupportsShouldProcess,
    ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    # [!code focus:2]
    [ValidateNotNullOrWhiteSpace()]
    [string] $Name,

    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string] $Path
)

Set-StrictMode -Version 3.0

# [!code focus:1]
$base = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
$target = Join-Path $base $Name
$readmePath = Join-Path $target 'README.md'
# [!code focus:1]
$helperPath = Join-Path $PSScriptRoot 'New-Readme.ps1' -Resolve

$existsBefore = Test-Path -LiteralPath $readmePath -PathType Leaf
$created = $false
$skipped = $false

if (!(Test-Path -LiteralPath $target -PathType Container)) {
    New-Item -Path $target -ItemType Directory -Force | Out-Null
}

if (!$existsBefore) {
    # [!code focus:5]
    if ($PSCmdlet.ShouldProcess($readmePath, 'Create README.md')) {
        $content = & $helperPath -Name $Name -Verbose:$PSBoundParameters['Verbose']
        Set-Content -Path $readmePath -Encoding UTF8 -Value $content
        $created = $true
    }
}
else {
    $skipped = $true
}

[PSCustomObject]@{
    BasePath     = $base
    TargetPath   = $target
    ReadmePath   = $readmePath
    HelperPath   = $helperPath
    ExistsBefore = $existsBefore
    Created      = $created
    Skipped      = $skipped
}
