<#
.SYNOPSIS
    Doubles integers from the pipeline and returns structured output.

.DESCRIPTION
    This script accepts one integer at a time from the pipeline, tracks how many values
    were processed, and emits a PSCustomObject with both the original and doubled values.

.PARAMETER Number
    The integer value to process. This parameter is mandatory and accepts pipeline input.

.EXAMPLE
    PS> 1..3 | ./Get-DoubledNumber.ps1

    Processes 1, 2, and 3 from the pipeline and returns objects with Original and Doubled properties.

.EXAMPLE
    PS> 5 | ./Get-DoubledNumber.ps1 -Verbose

    Processes 5 and shows begin/process/end verbose messages.
#>
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
