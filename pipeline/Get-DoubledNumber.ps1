#Requires -Version 7.5
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline, Mandatory)]
    [int] $Number
)
begin {
    Set-StrictMode -Version 3.0
    Write-Verbose '[begin] Starting pipeline...'
    $count = 0
}
process {
    Write-Verbose "[process] Processing number: $Number"
    $count++
    [pscustomobject]@{
        Original = $Number
        Doubled  = $Number * 2
    }
}
end {
    Write-Verbose "[end] Processed $count numbers in total."
}
