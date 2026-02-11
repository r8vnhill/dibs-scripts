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
