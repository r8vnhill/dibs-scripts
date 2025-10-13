#Requires -Version 7.5
[CmdletBinding()]
param(
    [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
    [Alias('FullName', 'Path')]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $LiteralPath
)
process {
    $item = Get-Item -LiteralPath $LiteralPath -ErrorAction Stop
    [pscustomobject]@{
        Path   = $item.FullName
        Length = $item.Length
    }
}
