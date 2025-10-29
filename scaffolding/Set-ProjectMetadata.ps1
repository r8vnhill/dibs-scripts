#Requires -Version 7.5
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string] $Root,

    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $Owner,
    
    [ValidateRange(1900, 3000)]
    [int] $Year = (Get-Date).Year
)

$rootPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Root)
$metadataTemplate = @'
owner: __OWNER__
updated: __YEAR__
'@

$foundReadmes = Get-ChildItem -Path $rootPath -Recurse -File -Filter README.md
$results = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($readme in $foundReadmes) {
    $dir = $readme.DirectoryName
    $metadataPath = Join-Path $dir 'project-metadata.yml'
    $metadataExists = Test-Path -LiteralPath $metadataPath
    $metadataCreated = $false
    if (!$metadataExists -and $PSCmdlet.ShouldProcess(
            $metadataPath, 'Create project-metadata.yml')) {
        $metadataText = $metadataTemplate -replace '__OWNER__', $Owner -replace '__YEAR__', $Year
        Set-Content -LiteralPath $metadataPath -Encoding utf8 -Value $metadataText
        $metadataCreated = $true
    }

    $results.Add([PSCustomObject]@{
            Path     = $dir
            Metadata = if ($metadataCreated) { 'created' } else { 'exists' }
        })
}

$results
