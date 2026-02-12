<#
.SYNOPSIS
    Calculates file hashes and optionally validates them against an expected value.

.DESCRIPTION
    This script computes a file hash using the selected algorithm and returns a structured
    result that includes the actual hash and optional comparison data. When `ExpectedHash`
    is provided, `Match` is `$true` or `$false`; otherwise `Match` is `$null`. It supports
    pipeline input by property name for path and expected hash fields.

.PARAMETER Path
    The file path to hash. This parameter is mandatory, accepts pipeline input by property
    name, and supports aliases `FullName` and `LiteralPath`.

.PARAMETER ExpectedHash
    The expected hash value used for comparison. This parameter is optional, accepts
    pipeline input by property name, and supports alias `Hash`.

.PARAMETER Algorithm
    The hash algorithm used by `Get-FileHash`. Valid values are SHA1, SHA256, SHA384,
    SHA512, and MD5. The default is SHA256.

.EXAMPLE
    PS> ./Test-FileHash.ps1 -Path ".\app.dll"

    Returns the SHA256 hash for `.\app.dll` with `Match` set to `$null`.

.EXAMPLE
    PS> ./Test-FileHash.ps1 -Path ".\app.dll" -ExpectedHash "ABC123..." -Algorithm SHA512

    Computes a SHA512 hash and returns whether it matches the expected value.

.EXAMPLE
    PS> Get-ChildItem .\artifacts\*.zip | ./Test-FileHash.ps1

    Uses pipeline property-name binding via `FullName` to hash each file.
#>
#Requires -Version 7.5
[CmdletBinding()]
param(
    [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
    [Alias('FullName', 'LiteralPath')]
    [string] $Path,

    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('Hash')]
    [string] $ExpectedHash,

    [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
    [string] $Algorithm = 'SHA256'
)
begin {
    Set-StrictMode -Version 3.0
}
process {
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm $Algorithm).Hash

    [pscustomobject]@{
        Path         = $Path
        Algorithm    = $Algorithm
        ActualHash   = $actual
        ExpectedHash = $ExpectedHash
        Match        = if ($ExpectedHash) { $actual -eq $ExpectedHash } else { $null }
    }
}
