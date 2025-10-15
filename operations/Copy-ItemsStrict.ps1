#Requires -Version 7.5
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Collections.Generic.List[string]] $Source,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]  $Destination,

    [switch] $Recurse
)

$result = @{
    Copied   = [System.Collections.Generic.List[string]]::new()
    Skipped  = [System.Collections.Generic.List[hashtable]]::new()
    Failures = [System.Collections.Generic.List[hashtable]]::new()
}

$destPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Destination)

try {
    foreach ($s in $Source) {
        $src = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($s)
        $target = Join-Path $destPath (Split-Path -Leaf $src)

        if ($PSCmdlet.ShouldProcess($src, "Copy to $destPath")) {
            if (!(Test-Path -LiteralPath $target)) {
                $copyParams = @{
                    LiteralPath = $src
                    Destination = $destPath
                    Recurse     = $Recurse
                    ErrorAction = 'Stop'
                }

                try {
                    Copy-Item @copyParams
                    $result.Copied.Add($src)
                }
                catch {
                    $result.Failures.Add(@{
                            File    = $src
                            Kind    = $_.Exception.GetType().Name
                            Message = $_.Exception.Message
                        })
                }
            }
            else {
                $result.Skipped.Add(@{
                        File   = $src
                        Reason = 'Exists'
                        Target = $target
                    })
            }
        }
    }

    Write-Verbose ('Copied items: {0}' -f ($result.Copied -join ', '))
    foreach ($s in $result.Skipped) {
        Write-Warning ('Skipped: {0} -> {1} ({2})' -f $s.File, $s.Target, $s.Reason)
    }
    foreach ($f in $result.Failures) {
        Write-Warning ('Failed: {0} ({1}) -> {2}' -f $f.File, $f.Kind, $f.Message)
    }
}
finally {
    Write-Output ('Finalizado. Copiados={0}, Omitidos={1}, Errores={2}' -f
        $result.Copied.Count, $result.Skipped.Count, $result.Failures.Count)
}
