#Requires -Version 7.4
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
$bsd2Url = 'https://raw.githubusercontent.com/spdx/license-list-data/master/text/BSD-2-Clause.txt'
$section = @'
## License

This project is licensed under the **BSD 2-Clause** license.  
See the [LICENSE](./LICENSE) file for details.
'@

$licenseText = (Invoke-RestMethod -Uri $bsd2Url) -replace '<year>', $Year -replace (
    '<owner>', $Owner)

$foundReadmes = Get-ChildItem -Path $rootPath -Recurse -File -Filter README.md

foreach ($readme in $foundReadmes) {
    $dir = $readme.DirectoryName
    $licensePath = Join-Path $dir 'LICENSE'

    if (!(Test-Path -LiteralPath $licensePath)) {
        if ($PSCmdlet.ShouldProcess($licensePath, 'Create LICENSE (BSD-2)')) {
            Set-Content -LiteralPath $licensePath -Encoding utf8 -Value $licenseText
            Write-Information ('LICENSE created -> {0}' -f $licensePath)
        }
    }
    else {
        Write-Warning ('LICENSE already present -> {0}' -f $licensePath)
    }

    $readmeText = Get-Content -LiteralPath $readme.FullName -Raw
    if ($readmeText -notmatch '(?im)^##\s*License\b') {
        if ($PSCmdlet.ShouldProcess($readme.FullName, 'Append License section')) {
            Add-Content -LiteralPath $readme.FullName -Encoding utf8 -Value (
                '{0}{0}{1}' -f [Environment]::NewLine, $section)
            Write-Information ('License section appended -> {0}' -f $readme.FullName)
        }
    }
    else {
        Write-Warning ('README already has a License section -> {0}' -f $readme.FullName)
    }
}
