#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Name,

    [string] $Path,

    [switch] $GitManaged
)

[string]$base = if (
    $PSBoundParameters.ContainsKey('Path') -and -not [string]::IsNullOrWhiteSpace($Path)
) {
    $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
}
else {
    (Get-Location).ProviderPath
}

$target = Join-Path -Path $base -ChildPath $Name

$createdTarget = $false
$createdReadme = $false
$createdGit = $false

if ($PSCmdlet.ShouldProcess($target, 'Initialize project and create README.md')) {
    try {
        # Crear carpeta solo si no existe
        if (!(Test-Path -LiteralPath $target)) {
            New-Item -Path $target -ItemType Directory -ErrorAction Stop | Out-Null
            $createdTarget = $true
        }

        $helperPath = Join-Path -Path $PSScriptRoot -ChildPath 'New-Readme.ps1'
        $readmePath = Join-Path -Path $target -ChildPath 'README.md'

        # Crear README.md solo si no existe
        if (!(Test-Path -LiteralPath $readmePath)) {

            $scParams = @{
                LiteralPath = $readmePath
                Encoding    = 'UTF8'
                Force       = $true
                ErrorAction = 'Stop'
            }

            & $helperPath -Name $Name -Verbose:$VerbosePreference | Set-Content @scParams
            $createdReadme = $true
        }

        # Inicializar git si corresponde y si aún no es repo
        if ($GitManaged -and !(Test-Path -LiteralPath (Join-Path $target '.git'))) {
            $gitInitPath = Join-Path $PSScriptRoot '..' 'git' 'Initialize-Repository.ps1'
            $gitInitParams = @{
                LiteralPath = $target
                Verbose     = $VerbosePreference
                ErrorAction = 'Stop'
            }
            & $gitInitPath @gitInitParams | Out-Null
            $createdGit = $true
        }

        return [pscustomobject]@{
            ProjectPath   = $target
            ReadmeCreated = $createdReadme
            RepoCreated   = $createdGit
        }
    }
    catch {
        # Rollback selectivo
        if ($createdGit) {
            Remove-Item -LiteralPath (
                Join-Path $target '.git'
            ) -Recurse -Force -ErrorAction SilentlyContinue
        }
        if ($createdReadme) {
            Remove-Item -LiteralPath (
                Join-Path $target 'README.md'
            ) -Force -ErrorAction SilentlyContinue
        }
        if ($createdTarget) {
            Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue
        }

        throw [System.AggregateException]::new(
            "The project could not be initialized at '$target'.", $_.Exception)
    }
}
