#Requires -Version 7.5
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [ValidateScript({ Test-Path -LiteralPath $_ })]
    [string] $Source,

    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string] $Destination,

    [switch] $Recurse
)

Set-StrictMode -Version 3.0

$result = @{
    Source      = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Source)
    Destination = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Destination)
}
$result.Target = Join-Path $result.Destination (Split-Path -Leaf $result.Source)

try {
    $shouldProcess = $PSCmdlet.ShouldProcess($result.Source, 'Copy to {0}' -f $result.Destination)
    if ($shouldProcess) {
        if (Test-Path -LiteralPath $result.Target) {
            $result.Status = 'Skipped'
            $result.Reason = ('Target already exists: {0}' -f $result.Target)
        }
        else {
            $copyParams = @{
                LiteralPath = $result.Source
                Destination = $result.Destination
                Recurse     = $Recurse
                ErrorAction = 'Stop'
            }

            Copy-Item @copyParams
            $result.Status = 'Copied'
        }
    }
    else {
        # Make cancellation explicit so callers don't need to infer it from missing Status
        $result.Status = 'Cancelled'
        $result.Reason = 'ShouldProcess returned False (confirmation declined or -WhatIf)'
    }
}
catch {
    $result.Status = 'Failed'
    $result.Error = [PSCustomObject]@{
        Kind    = $_.Exception.GetType().Name
        Message = $_.Exception.Message
    }
}
finally {
    [PSCustomObject]$result
}
