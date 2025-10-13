#Requires -Version 7.5
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Mandatory)]
    [int] $Number
)
begin {
    Write-Verbose 'Starting pipeline...'
    $count = 0
}
process {
    Write-Verbose "Processing number: $Number"
    $count++
    [pscustomobject]@{
        Original = $Number
        Doubled  = $Number * 2
    }
}
end {
    Write-Verbose "Processed $count numbers in total."
}

