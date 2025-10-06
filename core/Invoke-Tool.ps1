#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Name,

    [Parameter(ValueFromRemainingArguments)]
    [ValidateNotNull()]
    [string[]] $Rest = @()
)

$cmds = Get-Command -Name $Name -CommandType Application -ErrorAction Stop
if ($cmds.Count -gt 1) {
    Write-Warning (
        "Se encontraron varios ejecutables llamados '{0}'. Se usará: {1}" -f $Name, 
        $cmds[0].Source)
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
    return [pscustomobject]@{
        ToolPath = $path
        ExitCode = $LASTEXITCODE
        Output   = $out
    }
}

$nl = [Environment]::NewLine
$msg = ('{0} {1} devolvió código {2}.{3}Salida:{3}{4}' -f $Name, ($Rest -join ' '), 
    $LASTEXITCODE, $nl, ($out -join $nl))
throw [System.Exception]::new($msg)
