#Requires -Version 7.5
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ $_.Scheme -in @('http','https') })]
    [uri] $Uri,

    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $OutFile
)

$invoker = Join-Path $PSScriptRoot '..' 'core' 'Invoke-Tool.ps1' -Resolve

if ($PSCmdlet.ShouldProcess("$Uri to $OutFile", 'Download file')) {
    try {
        & $invoker wget -O $OutFile $Uri
        Write-Output ("Downloaded $Uri to $OutFile using wget")
    }
    catch {
        Write-Warning ('wget failed: {0}' -f $_.Exception.Message)
        try {
            & $invoker curl -o $OutFile $Uri
            Write-Output ("Downloaded $Uri to $OutFile using curl")
        }
        catch {
            Write-Warning ('curl failed: {0}' -f $_.Exception.Message)
            throw [System.Exception]::new("Both wget and curl failed to download $Uri")
        }
    }
}