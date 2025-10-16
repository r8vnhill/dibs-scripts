#Requires -Version 7.5
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $FirstName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $LastName
)

[PSCustomObject]@{
    FirstName = $FirstName
    LastName  = $LastName
}
