#Requires -Version 7.5
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string] $Path
)
Set-StrictMode -Version 3.0

$target = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
$existsBefore = Test-Path -LiteralPath $target -PathType Container

$deleted = $false

if ($existsBefore -and $PSCmdlet.ShouldProcess($target, 'Remove work folder recursively')) {
    $removeParams = @{
        LiteralPath = $target
        Recurse     = $true
        Force       = $true
        Verbose     = $PSBoundParameters['Verbose']
        WhatIf      = $PSBoundParameters['WhatIf']
        Confirm     = $PSBoundParameters['Confirm']
    }

    Remove-Item @removeParams
    $deleted = $true
}

[PSCustomObject]@{
    TargetPath   = $target
    ExistsBefore = $existsBefore
    Deleted      = $deleted
}
