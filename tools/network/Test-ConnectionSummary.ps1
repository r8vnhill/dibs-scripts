#Requires -Version 7.5
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $Address
)

[PSCustomObject]@{
    Address   = $Address
    Status    = $Address -match '^[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*(?::\d+)?$'
    CheckedAt = Get-Date
}
