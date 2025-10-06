#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Root,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Owner,
    
    [ValidateRange(1900, 3000)]
    [int] $Year = (Get-Date).Year
)

$rootPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Root)

$bsd2Url = 'https://raw.githubusercontent.com/spdx/license-list-data/master/text/BSD-2-Clause.txt'
$licenseText = (Invoke-WebRequest -Uri $bsd2Url).Content `
    -replace '<year>', $Year `
    -replace '<owner>', $Owner

$readmes = Get-ChildItem -Path $rootPath -Recurse -File -Filter README.md

foreach ($readme in $readmes) {
    $dir = Split-Path -Parent $readme.FullName
    $licensePath = Join-Path $dir 'LICENSE'

    if (-not (Test-Path -LiteralPath $licensePath)) {
        if ($PSCmdlet.ShouldProcess($licensePath, 'Create LICENSE (BSD-2)')) {
            Set-Content -Value $licenseText -LiteralPath $licensePath -Encoding utf8
            Write-Output "LICENSE created -> $licensePath"
        }
    }
    else {
        Write-Warning "LICENSE already present -> $licensePath"
    }

    $readmeText = Get-Content -Raw -LiteralPath $readme.FullName
    if ($readmeText -notmatch '(?im)^##\s*License\b') {
        $section = @'

## License

This project is licensed under the **BSD 2-Clause** license.  
See the [LICENSE](./LICENSE) file for details.

'@
        $new = $readmeText.TrimEnd() + [Environment]::NewLine + $section
        if ($PSCmdlet.ShouldProcess($readme.FullName, 'Append License section')) {
            Set-Content -LiteralPath $readme.FullName -Encoding utf8 -NoNewline:$false -Value $new
            Write-Output "License section appended -> $($readme.FullName)"
        }
    }
    else {
        Write-Warning "README already has a License section -> $($readme.FullName)"
    }
}
