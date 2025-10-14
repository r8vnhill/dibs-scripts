#Requires -Version 7.5
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Collections.Generic.List[string]] $Path
)

$result = [ordered]@{
    Deleted = [System.Collections.Generic.List[string]]::new()
    Errors  = [System.Collections.Generic.List[ordered]]::new()
}

foreach ($p in $Path) {
    if ($PSCmdlet.ShouldProcess($p, 'Remove item')) {
        $err = $null
        $params = @{
            LiteralPath   = $p
            Force         = $true
            ErrorAction   = 'SilentlyContinue'
            ErrorVariable = 'err'
        }
        Remove-Item @params

        if ($err) {
            $result.Errors.Add([ordered]@{
                    Path    = $p
                    Message = $err[0].Exception.Message
                })
        }
        else {
            $result.Deleted.Add($p)
        }
    }
}

if ($result.Deleted) {
    Write-Output ('Deleted items: {0}' -f ($result.Deleted -join ', '))
}

if ($result.Errors) {
    Write-Warning ('Errors encountered for {0} item(s):' -f $result.Errors.Count)
    foreach ($e in $result.Errors) {
        Write-Warning ('[{0}] {1}' -f $e.Path, $e.Message)
    }
}
