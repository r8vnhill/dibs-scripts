#Requires -Version 7.5
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string[]] $Source,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]  $Destination,

    [switch] $Recurse,
    [switch] $Overwrite
)

$copied = @()
$skipped = @()
$failures = @()

$destPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Destination)
if (!(Test-Path -LiteralPath $destPath) -and
    $PSCmdlet.ShouldProcess($destPath, 'Create destination directory')) {
    New-Item -ItemType Directory -Path $destPath -Force | Out-Null
}

try {
    foreach ($s in $Source) {
        $src = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($s)
        $target = Join-Path -Path $destPath -ChildPath (Split-Path -Leaf $src)

        if ($PSCmdlet.ShouldProcess($src, "Copy to $destPath")) {
            if (!$Overwrite -and (Test-Path -LiteralPath $target)) {
                $skipped += [pscustomobject]@{
                    File   = $src
                    Reason = 'Exists'
                    Target = $target
                }
                continue
            }

            $copyParams = @{
                LiteralPath = $src
                Destination = $destPath
                Recurse     = $Recurse
                Force       = $Overwrite
                ErrorAction = 'Stop'
            }

            try {
                Copy-Item @copyParams
                $copied += $src
            }
            catch {
                $failures += [pscustomobject]@{
                    File    = $src
                    Kind    = $PSItem.Exception.GetType().Name
                    Message = $PSItem.Exception.Message
                }
            }
        }
    }

    $result = [pscustomobject]@{
        Destination = $destPath
        Copied      = $copied
        Skipped     = $skipped
        Failures    = $failures
    }

    if ($failures.Count) {
        Write-Warning "Copiado parcial: $($failures.Count) error(es)"
    }

    return $result
}
finally {
    Write-Verbose ('Finalizado. Copiados={0}, Omitidos={1}, Errores={2}' -f $copied.Count,
        $skipped.Count, $failures.Count)
}

