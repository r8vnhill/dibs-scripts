<#
.SYNOPSIS
    Computes a SHA-256 “fingerprint” for each input path and outputs structured file
    metadata.
.DESCRIPTION
    This script is pipeline-aware and processes one element at a time. For each input, it:

    - Resolves the path with Get-Item (terminating on lookup failures via 
      `-ErrorAction Stop`).
    - Rejects directories (writes a non-terminating error and continues).
    - Computes a SHA-256 hash with Get-FileHash (terminating on hashing failures).
    - Emits a [pscustomobject] with stable, machine-friendly fields.

    Errors are reported per element using Write-Error so callers can choose the policy
    externally with -ErrorAction (e.g., Continue vs Stop). This design is useful for
    automation scenarios (audits, inventories, integrity checks) where you may want either
    resiliency or fail-fast.
.PARAMETER Path
    A file path to fingerprint.

    Accepts pipeline input:
    - By value (strings piped directly).
    - By property name (objects with Path, FullName, or LiteralPath properties).
.EXAMPLE
    # Tolerant mode (default): continues after per-item failures.
    'file1.txt','missing.txt','file2.txt' | 
        .\Get-FileFingerprint.ps1 |
        Format-Table -AutoSize
.EXAMPLE
    # Strict mode: stop at the first error.
    'file1.txt','missing.txt','file2.txt' |
        .\Get-FileFingerprint.ps1 -ErrorAction Stop
.EXAMPLE
    # Object pipeline: binds FullName from Get-ChildItem via ValueFromPipelineByPropertyName.
    Get-ChildItem -File . |
        .\Get-FileFingerprint.ps1 |
        Sort-Object SizeBytes -Descending
.OUTPUTS
    [pscustomobject] with:
    - Path         ([string])   Absolute/expanded file path.
    - SizeBytes    ([long])     File size in bytes.
    - LastWriteUtc ([datetime]) Last write time in UTC.
    - Sha256       ([string])   SHA-256 hash (hex).
#>

#Requires -Version 7.5
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Mandatory)]
    [Alias('FullName', 'LiteralPath')]
    [string] $Path
)

begin {
    Set-StrictMode -Version 3.0
}
process {
    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop

        if ($item.PSIsContainer) {
            Write-Error ('Expected a file, got a directory: {0}' -f $Path)
            return
        }

        $params = @{
            LiteralPath = $item.FullName
            Algorithm   = 'SHA256'
            ErrorAction = 'Stop'
        }
        $hash = Get-FileHash @params

        [pscustomobject]@{
            Path         = $item.FullName
            SizeBytes    = $item.Length
            LastWriteUtc = $item.LastWriteTimeUtc
            Sha256       = $hash.Hash
        }
    }
    catch {
        # Per-item error so callers can control behavior with -ErrorAction.
        Write-Error ("Failed to fingerprint '{0}': {1}" -f $Path, $_.Exception.Message)
    }
}
