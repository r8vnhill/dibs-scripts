#Requires -Version 7.5
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ $_.Scheme -in @('http', 'https') })]
    [uri] $Uri,

    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $OutFile
)

$invoker = Join-Path $PSScriptRoot '..' 'core' 'Invoke-Tool.ps1' -Resolve
$candidates = [ordered]@{
    wget = { param($U, $O) @('-O', $O, $U) }
    curl = { param($U, $O) @('-o', $O, $U) }
}
$success = $false

if ($PSCmdlet.ShouldProcess("$Uri to $OutFile", 'Download file')) {
    foreach ($tool in $candidates.Keys) {
        try {
            & $invoker $tool @($candidates[$tool].Invoke($Uri, $OutFile))
            Write-Output ("Downloaded $Uri to $OutFile using $tool")
            $success = $true
            break
        }
        catch {
            Write-Warning ("$tool failed: {0}" -f $_.Exception.Message)
        }
    }
    if (!$success) {
        throw [System.Exception]::new('All download methods failed.')
    }
}
