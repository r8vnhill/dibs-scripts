#Requires -Version 7.5
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Name,

    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string] $Path
)

$base = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
$target = Join-Path $base $Name
$readmePath = Join-Path $target 'README.md'
$helperPath = Join-Path $PSScriptRoot 'New-Readme.ps1' -Resolve

Write-Verbose (@'
Base path: {0}
Project destination: {1}
Helper: {2}
'@ -f $base, $target, $helperPath)

if (!(Test-Path -Path $readmePath -PathType Leaf)) {
    if ($PSCmdlet.ShouldProcess($readmePath, 'Create README.md')) {
        $content = & $helperPath -Name $Name -Verbose:$VerbosePreference
        Set-Content -Path $readmePath -Encoding UTF8 -Value $content

        Write-Information ('README.md created successfully at {0}' -f $readmePath)
    }
}
else {
    Write-Warning ('README.md already exists at {0}; creation skipped.' -f $readmePath)
}
