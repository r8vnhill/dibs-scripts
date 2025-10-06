#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string[]] $Path
)

$deleted = @()
$errors = @()

foreach ($p in $Path) {
    if ($PSCmdlet.ShouldProcess($p, 'Remove item')) {
        $localErr = $null
        Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue -ErrorVariable localErr

        if ($localErr) {
            $errors += [pscustomobject]@{
                Path    = $p
                Message = $localErr[0].Exception.Message
            }
        }
        else {
            $deleted += $p
        }
    }
}

return [pscustomobject]@{
    Deleted = $deleted
    Errors  = $errors
}
