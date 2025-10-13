#Requires -Version 7.5
[CmdletBinding()]
[OutputType([pscustomobject])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('FullName', 'Path')]
    [string] $LiteralPath,

    [long] $MinSizeBytes = 0
)

begin {
    Write-Verbose ('Starting {0}' -f $PSCmdlet.MyInvocation.MyCommand.Name)
}
process {
    try {
        $resolved = (Resolve-Path -LiteralPath $LiteralPath -ErrorAction Stop).Path
        $fileItem = Get-Item -LiteralPath $resolved -ErrorAction Stop
        if (-not $fileItem.PSIsContainer -and $fileItem.Length -ge $MinSizeBytes) {
            [pscustomobject]@{
                PSTypeName    = 'Demo.FileCandidate'
                Path          = $fileItem.FullName
                Length        = [long]$fileItem.Length
                LastWriteTime = $fileItem.LastWriteTime
            }
        }
    }
    catch {
        Write-Error -Message ("Normalize failed for '{0}': {1}" -f $LiteralPath, $_.Exception.Message) `
            -Category ReadError -TargetObject $LiteralPath
    }
}
end {
    Write-Verbose "Ending $($PSCmdlet.MyInvocation.MyCommand.Name)"
}

