<#
.SYNOPSIS
    Checks whether a Windows service matches an expected status.

.DESCRIPTION
    This script accepts service names and expected status values, retrieves each service
    with `Get-Service`, and returns compliance results as objects with the service name,
    current status, and a boolean match flag. It supports pipeline input by property name
    for both parameters.

.PARAMETER Name
    The service name to evaluate. This parameter is mandatory and accepts pipeline input
    by property name.

.PARAMETER ExpectedStatus
    The expected service status to compare against (for example, Running or Stopped). This
    parameter is mandatory, accepts pipeline input by property name, and has alias
    `expected_status`.

.EXAMPLE
    PS> ./Test-ServiceCompliance.ps1 -Name "Spooler" -ExpectedStatus "Running"

    Returns a compliance object indicating whether the Spooler service is currently
    Running.

.EXAMPLE
    PS> [pscustomobject]@{ Name = "Spooler"; expected_status = "Running" } | 
    PS>     ./Test-ServiceCompliance.ps1

    Uses property-name pipeline binding and the `expected_status` alias for
    ExpectedStatus.
#>
#Requires -Version 7.5
[CmdletBinding()]
param(
    [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
    [string] $Name,

    [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
    [Alias('expected_status')]
    [string] $ExpectedStatus
)
begin {
    Set-StrictMode -Version 3.0
}
process {
    Get-Service -Name $Name -ErrorAction SilentlyContinue | ForEach-Object {
        [pscustomobject]@{
            Name   = $Name
            Status = $_.Status.ToString()
            Match  = $_.Status -eq $ExpectedStatus
        }
    }
}
