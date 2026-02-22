#Requires -Version 7.5
<#
.SYNOPSIS
    Computes a SHA-256 fingerprint for each input path.
.DESCRIPTION
    Processes one element at a time and emits structured output for valid files.
    For invalid inputs, writes one non-terminating error per item.

    Validation flow:
    - Resolve the path with Get-Item.
    - Reject directories.
    - Compute SHA-256 with Get-FileHash.

    Errors are emitted with Write-Error so callers can control behavior with
    -ErrorAction and collect records via -ErrorVariable.
.PARAMETER Path
    File path to fingerprint.
    Accepts pipeline input by value and by property name (Path, FullName,
    LiteralPath).
.OUTPUTS
    [pscustomobject] with Path, SizeBytes, LastWriteUtc, Sha256.
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Mandatory)]
    [Alias('FullName', 'LiteralPath')]
    [string] $Path
)

begin {
    Set-StrictMode -Version 3.0
}

process {
    $item = Get-Item -LiteralPath $Path -ErrorAction Ignore

    if ($null -eq $item) {
        $errorParams = @{
            Message      = (
                "Failed to fingerprint '{0}': Path does not exist or is inaccessible." -f
                $Path
            )
            Category     = 'ObjectNotFound'
            TargetObject = $Path
            ErrorId      = 'GetFileFingerprint.ItemNotFound'
        }
        Write-Error @errorParams
    }
    elseif ($item.PSIsContainer) {
        $errorParams = @{
            Message      = ('Expected a file, got a directory: {0}' -f $Path)
            Category     = 'InvalidType'
            TargetObject = $Path
            ErrorId      = 'GetFileFingerprint.ExpectedFile'
        }
        Write-Error @errorParams
    }
    else {
        $hashParams = @{
            LiteralPath = $item.FullName
            Algorithm   = 'SHA256'
            ErrorAction = 'Ignore'
        }
        $hash = Get-FileHash @hashParams

        if ($null -eq $hash) {
            $errorParams = @{
                Message      = (
                    "Failed to fingerprint '{0}': Unable to compute SHA256 hash." -f $Path
                )
                Category     = 'ReadError'
                TargetObject = $Path
                ErrorId      = 'GetFileFingerprint.HashFailed'
            }
            Write-Error @errorParams
        }
        else {
            [pscustomobject]@{
                Path         = $item.FullName
                SizeBytes    = $item.Length
                LastWriteUtc = $item.LastWriteTimeUtc
                Sha256       = $hash.Hash
            }
        }
    }
}
