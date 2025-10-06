#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Name,

    [switch] $Public
)

$normalized = $Name.ToLowerInvariant() -replace '\s+', '-' -replace '[^a-z0-9-]', ''
if ([string]::IsNullOrWhiteSpace($normalized)) {
    throw [System.ArgumentException]::new(
        "Name '$Name' is not valid after normalizing to '$normalized' (only [a-z0-9-])."
    )
}

$visibility = if ($Public) { 'public' } else { 'private' }

$invoker = Join-Path $PSScriptRoot '..' 'core' 'Invoke-Tool.ps1' -Resolve

try {
    & $invoker glab repo view $normalized | Out-Null
    Write-Verbose "Repository '$normalized' already exists. Not creating it again."
    return [pscustomobject]@{
        Name       = $normalized
        Visibility = $visibility
        Created    = $false
        Output     = @()
        Message    = 'Repository already exists'
    }
}
catch {
    Write-Verbose "Repo '$normalized' not found. Will attempt to create it."
}

if ($PSCmdlet.ShouldProcess($normalized, "Create GitLab repository ($visibility)")) {
    try {
        $args = @('repo', 'create', $normalized, '--defaultBranch', 'main')
        if ($Public) { $args += '--public' } else { $args += '--private' }

        $result = & $invoker glab $args
        $out = $result.Output

        Write-Verbose ("Created '{0}' as {1}.{2}{3}" -f $normalized, $visibility, 
            [Environment]::NewLine, ($out -join [Environment]::NewLine))

        [pscustomobject]@{
            Name       = $normalized
            Visibility = $visibility
            Created    = $true
            Output     = $out
            Message    = 'Repository created'
        }
    }
    catch {
        throw [System.AggregateException]::new(
            "Failed to create repository '$Name' ('$normalized').", $_.Exception)
    }
}