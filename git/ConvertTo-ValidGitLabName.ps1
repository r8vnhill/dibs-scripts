#Requires -Version 7.5
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $Name
)

Set-StrictMode -Version 3.0

$normalized = $Name.ToLowerInvariant() -replace '\s+', '-' -replace '[^a-z0-9-]', ''
if ([string]::IsNullOrWhiteSpace($normalized)) {
    throw [System.ArgumentException]::new(
        "Name '$Name' is not valid after normalizing to '$normalized' (only [a-z0-9-])."
    )
}

$normalized
