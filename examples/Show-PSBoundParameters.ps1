#Requires -Version 7.5
[CmdletBinding()]
param(
    [string] $Name,
    [int] $Count = 1,
    [switch] $Shout
)

Set-StrictMode -Version 3.0

# Build a simple result describing effective values and what was bound
[PSCustomObject]@{
    BoundKeys      = $PSBoundParameters.Keys

    Name           = $Name
    BoundName      = $PSBoundParameters['Name']

    EffectiveCount = $Count
    BoundCount     = $PSBoundParameters['Count']

    Shout          = $Shout.IsPresent
    BoundShout     = $PSBoundParameters['Shout']

    Verbose        = $PSBoundParameters['Verbose']
}
