#Requires -Version 7.5
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $Name,

    [Parameter(ValueFromRemainingArguments)]
    [ValidateNotNull()]
    [string[]] $Rest = @()
)

Set-StrictMode -Version 3.0

$cmds = Get-Command -Name $Name -CommandType Application -ErrorAction Stop
if ($cmds.Count -gt 1) {
    Write-Warning ("Multiple executables named '{0}' were found. Using: {1}" -f 
        $Name, $cmds[0].Source)
}
$path = $cmds[0].Source

$originalEncoding = [Console]::OutputEncoding
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $out = & $path @Rest 2>&1
}
finally {
    [Console]::OutputEncoding = $originalEncoding
}

if ($LASTEXITCODE -eq 0) {
    [PSCustomObject]@{
        ToolPath = $path
        ExitCode = $LASTEXITCODE
        Output   = $out
    }
}
else {
    $nl = [Environment]::NewLine
    $msg = ('{0} {1} returned exit code {2}.{3}Output:{3}{4}' -f $Name, ($Rest -join ' '), 
        $LASTEXITCODE, $nl, ($out -join $nl))
    throw [System.Exception]::new($msg)
}
