#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Root,

    [switch] $UpdateStamp
)

$rootPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Root)
$files = Get-ChildItem -Path $rootPath -Recurse -File -Filter README.md

foreach ($file in $files) {
    $original = Get-Content -LiteralPath $file.FullName -Raw

    # 1) Quitar espacios en blanco al final de cada línea
    $clean = [regex]::Replace($original, '[ \t]+(?=\r?\n)', '')

    # 2) Asegurar salto de línea final
    if (-not $clean.EndsWith([Environment]::NewLine)) {
        $clean += [Environment]::NewLine
    }

    # 3) Agregar/actualizar sello de fecha si se pidió -UpdateStamp
    if ($UpdateStamp) {
        $stamp = "Last updated: $(Get-Date)"
        if ($clean -match '(?im)^\s*Last updated: .*$') {
            $clean = [regex]::Replace($clean, '(?im)^\s*Last updated: .*$', $stamp, 1)
        }
        else {
            $clean = $clean + $stamp + [Environment]::NewLine
        }
    }

    # Aplicar cambios solo si hubo modificaciones, respetando -WhatIf
    if (($clean -ne $original) -and (
            $PSCmdlet.ShouldProcess(
                $file.FullName, 'Normalize Markdown whitespace and stamp'))) {
        Set-Content -LiteralPath $file.FullName -Encoding utf8 -NoNewline:$false `
            -Value $clean
        Write-Output "Fixed -> $($file.FullName)"
    }
    else {
        Write-Verbose "No changes -> $($file.FullName)"
    }
}
