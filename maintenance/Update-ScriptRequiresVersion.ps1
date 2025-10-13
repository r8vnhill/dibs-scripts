#Requires -Version 7.5
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string] $Root,

    [Version] $Version = $PSVersionTable.PSVersion
)

$rootPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Root)
$targetVersion = '{0}.{1}' -f $Version.Major, $Version.Minor
$requiresLine = '#Requires -Version {0}' -f $targetVersion
$rxRequires = '(?im)^\s*#\s*Requires\s+-Version\s+([0-9]+(?:\.[0-9]+)?)\s*$'

$foundScripts = Get-ChildItem -LiteralPath $rootPath -Recurse -File -Filter *.ps1
foreach ($script in $foundScripts) {
    $text = Get-Content -LiteralPath $script.FullName -Raw
    $matches = [regex]::Matches($text, $rxRequires)
    $count = $matches.Count

    if ($count -eq 0) {
        $newText = '{0}{1}{2}' -f $requiresLine, [Environment]::NewLine, $text
        if ($newText -ne $text) {
            Write-Information (
                '[{0}] Insert #Requires -> {1}' -f $script.Name, $requiresLine)
            if ($PSCmdlet.ShouldProcess($script.FullName, 
                    'Insert #Requires -Version {0}' -f $targetVersion)) {
                Set-Content -LiteralPath $script.FullName -Encoding utf8 -Value $newText
            }
        }
    }
    elseif ($count -eq 1) {
        $current = $matches[0].Groups[1].Value
        if ($current -ne $targetVersion) {
            $newText = $text -replace $rxRequires, $requiresLine
            Write-Information ('[{0}] Update #Requires {1} -> {2}' -f $script.Name,
                $current, $targetVersion)
            if ($PSCmdlet.ShouldProcess($script.FullName, 
                    'Update #Requires -Version {0}' -f $targetVersion)) {
                Set-Content -LiteralPath $script.FullName -Encoding utf8 -Value $newText
            }
        }
        else {
            Write-Verbose ('[{0}] OK (version {1}T)' -f $script.Name, $current)
        }
    }
    else {
        Write-Warning ('[{0}] Multiple #Requires -Version lines found ({1}); skipping.' -f 
            $script.Name, $count)
    }
}
