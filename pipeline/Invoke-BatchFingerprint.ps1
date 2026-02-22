#Requires -Version 7.5
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [Alias('Id')]
    [string] $BatchId,

    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('FullName', 'LiteralPath')]
    [string[]] $Paths
)

begin {
    Set-StrictMode -Version 3.0
}

process {
    $batchErr = $null

    $childErrorParams = @{
        ErrorAction   = 'SilentlyContinue'
        ErrorVariable = 'batchErr'
    }
    $results = $Paths | & "$PSScriptRoot/Get-FileFingerprint.ps1" @childErrorParams

    $total = $Paths.Count
    $succeeded = @($results).Count
    $failed = $total - $succeeded
    
    $batchErrors = @($batchErr)
    $batchFailed = $batchErrors.Count -gt 0

    if ($batchFailed) {
        $batchErrorParams = @{
            Message      = ("Batch '{0}' failed (at least one item failed)." -f $BatchId)
            Category     = 'InvalidOperation'
            TargetObject = $BatchId
            ErrorId      = 'InvokeBatchFingerprint.BatchFailed'
        }
        Write-Error @batchErrorParams
    }

    [pscustomobject]@{
        BatchId     = $BatchId
        Total       = $total
        Succeeded   = $succeeded
        Failed      = $failed
        BatchFailed = $batchFailed
    }
}
