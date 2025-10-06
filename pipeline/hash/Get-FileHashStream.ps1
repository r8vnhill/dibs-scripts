#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [Alias('FullName', 'Path')]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $LiteralPath,

    [ValidateSet('MD5', 'SHA1', 'SHA256')]
    [string] $Algorithm = 'SHA256',

    [switch] $AllowInsecure,
    [switch] $IncludeLength
)

begin {
    if ($Algorithm -in @('MD5', 'SHA1') -and -not $AllowInsecure) {
        throw [System.ArgumentException]::new(
            "The algorithm '$Algorithm' is considered insecure. " +
            "Use -AllowInsecure to proceed anyway."
        )
    }
    switch ($Algorithm) {
        'SHA256' { $hasher = [System.Security.Cryptography.SHA256]::Create(); break }
        'SHA1' { $hasher = [System.Security.Cryptography.SHA1]::Create(); break }
        'MD5' { $hasher = [System.Security.Cryptography.MD5]::Create(); break }
        default { throw "Unsupported algorithm: $Algorithm" }
    }

    Write-Verbose "Initialized $Algorithm hasher."
}

process {
    try {
        $resolved = (Resolve-Path -LiteralPath $LiteralPath -ErrorAction Stop).Path
        $file = Get-Item -LiteralPath $resolved -ErrorAction Stop

        $stream = [System.IO.File]::OpenRead($resolved)
        try {
            $hasher.Initialize() | Out-Null
            $bytes = $hasher.ComputeHash($stream)
            $hashString = [Convert]::ToHexString($bytes).ToLowerInvariant()

            $result = @{
                Path      = $file.FullName
                Algorithm = $Algorithm
                Hash      = $hashString
            }
            if ($IncludeLength) { $result.Length = $file.Length }

            [pscustomobject]$result
        }
        finally {
            $stream.Dispose()
        }
    }
    catch {
        Write-Warning ("Could not hash '{0}': {1}" -f $LiteralPath, $_.Exception.Message)
    }
}

end {
    if ($hasher) {
        $hasher.Dispose()
        Write-Verbose "Disposed $Algorithm hasher."
    }
}
