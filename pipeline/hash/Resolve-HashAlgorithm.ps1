#Requires -Version 7.5
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string] $Algorithm,

    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [bool] $IsAllowed
)

begin {
    $hashers = @{
        MD5    = { [System.Security.Cryptography.MD5]::Create() }
        SHA1   = { [System.Security.Cryptography.SHA1]::Create() }
        SHA256 = { [System.Security.Cryptography.SHA256]::Create() }
        SHA384 = { [System.Security.Cryptography.SHA384]::Create() }
        SHA512 = { [System.Security.Cryptography.SHA512]::Create() }
    }
}
process {
    if (!$IsAllowed) {
        [PSCustomObject]@{
            Algorithm = $Algorithm
            Error     = "The algorithm '$Algorithm' is not allowed."
        }
    }
    elseif ($hashers.ContainsKey($Algorithm)) {
        [PSCustomObject]@{
            Algorithm = $Algorithm
            Hasher    = $hashers[$Algorithm]
        }
    }
    else {
        [PSCustomObject]@{
            Algorithm = $Algorithm
            Error     = "Unsupported algorithm: $Algorithm"
        }
    }
}

