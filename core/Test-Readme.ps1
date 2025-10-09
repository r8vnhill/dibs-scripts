#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path (Join-Path $_ 'README.md') -PathType Leaf })]
    [string] $Path
)

$readmePath = Join-Path $Path 'README.md'
Write-Verbose ('Checking for README.md at {0}' -f $readmePath)

$content = Get-Content -Path $readmePath -Raw
$hasH1 = $content -match '^#\s+.+'
$hasMarker = $content -match 'Project initialized on'

if ($hasH1 -and $hasMarker) {
    Write-Verbose 'README.md looks good.'
    $true
}
else {
    Write-Verbose 'README.md does not follow expected format.'
    $false
}
