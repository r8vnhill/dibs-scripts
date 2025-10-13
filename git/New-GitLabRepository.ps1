#Requires -Version 7.5
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

$visibility = if ($Public.IsPresent) { 'public' } else { 'private' }

$invoker = Join-Path $PSScriptRoot '..' 'core' 'Invoke-Tool.ps1' -Resolve

$repository = [ordered]@{
    Name       = $normalized
    Visibility = $visibility
    Created    = $false
    Output     = @()
    Message    = ''
}

try {
    & $invoker glab repo view $normalized | Out-Null
    Write-Verbose "Repository '$normalized' already exists. Not creating it again."
    $repository.Message = 'Repository already exists'
}
catch {
    Write-Verbose "Repo '$normalized' not found. Will attempt to create it."

    if ($PSCmdlet.ShouldProcess($normalized, "Create GitLab repository ($visibility)")) {
        try {
            $args = @('repo', 'create', $normalized, '--defaultBranch', 'main')
            if ($Public) { $args += '--public' } else { $args += '--private' }

            $result = & $invoker glab $args
            $repository.Output  = $result.Output
            $repository.Created = $true
            $repository.Message = 'Repository created'

            Write-Verbose ("Created '{0}' as {1}.{2}{3}" -f $normalized, $visibility, 
                [Environment]::NewLine, ($repository.Output -join [Environment]::NewLine))
        }
        catch {
            throw [System.AggregateException]::new(
                "Failed to create repository '$Name' ('$normalized').", $_.Exception)
        }
    }
}

[pscustomobject]$repository

