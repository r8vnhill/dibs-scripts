#Requires -Version 7.0
[CmdletBinding(DefaultParameterSetName = 'ByObject')]
[OutputType([pscustomobject])]
param(
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByPath')]
    [Alias('FullName', 'Path', 'PSPath')]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $LiteralPath,

    [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ByObject')]
    [ValidateNotNull()]
    [System.IO.FileInfo] $InputObject
)

begin {
    $count = 0
    Write-Verbose ('Starting {0} (set: {1})' -f $PSCmdlet.MyInvocation.MyCommand.Name, 
        $PSCmdlet.ParameterSetName)
}

process {
    try {
        if ($PSCmdlet.ParameterSetName -eq 'ByObject') {
            $fileItem = $InputObject
            $target = $InputObject.FullName
        }
        else {
            $fileItem = Get-Item -LiteralPath $LiteralPath -ErrorAction Stop
            $target = $fileItem.FullName
        }

        $count++
        [pscustomobject]@{
            Name          = $fileItem.Name
            Path          = $fileItem.FullName
            Length        = $fileItem.Length
            LastWriteTime = $fileItem.LastWriteTime
        }
    }
    catch {
        Write-Warning ("Could not inspect '{0}': {1}" -f ($target ?? $LiteralPath), 
            $_.Exception.Message)
    }
}

end {
    Write-Verbose "Processed $count file(s)."
}
