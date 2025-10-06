#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('Name', 'HashAlgorithm')]
    [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512')]
    [string] $Algorithm = 'SHA256',

    [switch] $AllowInsecure
)

process {
    $isInsecure = $Algorithm -in @('MD5', 'SHA1')
    $isSecure = !$isInsecure
    $isAllowed = $isSecure -or $isInsecure -and $AllowInsecure

    [PSCustomObject]@{
        Algorithm  = $Algorithm
        IsInsecure = $isInsecure
        IsAllowed  = $isAllowed
        IsSecure   = $isSecure
    }
}
