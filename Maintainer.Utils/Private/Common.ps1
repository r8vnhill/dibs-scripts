function Resolve-NewRepositoryDestinationPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $DestinationPath
    )

    [System.IO.Path]::GetFullPath($DestinationPath, (Get-Location).ProviderPath)
}

function Get-MaintainerInvalidOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ErrorId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Message
    )

    $exception = [System.InvalidOperationException]::new($Message)
    [System.Management.Automation.ErrorRecord]::new(
        $exception,
        $ErrorId,
        [System.Management.Automation.ErrorCategory]::InvalidOperation,
        $null
    )
}

function Invoke-MaintainerTool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $WorkingDirectory,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [string[]] $Arguments
    )

    $invoker = Join-Path $PSScriptRoot '..' '..' 'tools' 'Invoke-Tool.ps1' -Resolve
    $previousLocation = Get-Location

    try {
        Set-Location -LiteralPath $WorkingDirectory
        & $invoker -Name $Name @Arguments
    }
    finally {
        Set-Location -LiteralPath $previousLocation.ProviderPath
    }
}
