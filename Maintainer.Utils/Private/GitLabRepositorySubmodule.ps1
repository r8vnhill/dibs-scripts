function Assert-NewDibsGitLabRepositorySubmoduleRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Group,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ParentRepositoryPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $SubmodulePath
    )

    Assert-NewDibsGitLabRepositoryIdentity -Name $Name -Group $Group

    $normalizedParentRepositoryPath = Resolve-NewRepositoryDestinationPath -DestinationPath $ParentRepositoryPath
    if (-not (Test-Path -LiteralPath $normalizedParentRepositoryPath -PathType Container)) {
        throw (Get-MaintainerInvalidOperation `
                -ErrorId 'ParentRepositoryMissing' `
                -Message "Parent repository path '$normalizedParentRepositoryPath' does not exist.")
    }

    $normalizedRelativeSubmodulePath = $SubmodulePath -replace '\\', '/'
    if ([string]::IsNullOrWhiteSpace($normalizedRelativeSubmodulePath)) {
        throw (Get-MaintainerInvalidOperation `
                -ErrorId 'InvalidSubmodulePath' `
                -Message 'Submodule path must not be empty.')
    }

    if ([System.IO.Path]::IsPathRooted($normalizedRelativeSubmodulePath)) {
        throw (Get-MaintainerInvalidOperation `
                -ErrorId 'SubmodulePathRooted' `
                -Message "Submodule path '$SubmodulePath' must be relative to the parent repository.")
    }

    if ($normalizedRelativeSubmodulePath -match '(^|/)\.\.(?:/|$)') {
        throw (Get-MaintainerInvalidOperation `
                -ErrorId 'SubmodulePathTraversal' `
                -Message "Submodule path '$SubmodulePath' must not traverse outside the parent repository.")
    }

    $normalizedSubmodulePath = [System.IO.Path]::GetFullPath($normalizedRelativeSubmodulePath, $normalizedParentRepositoryPath)
    $parentPrefix = $normalizedParentRepositoryPath.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    ) + [System.IO.Path]::DirectorySeparatorChar

    if (-not $normalizedSubmodulePath.StartsWith($parentPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw (Get-MaintainerInvalidOperation `
                -ErrorId 'SubmodulePathOutsideParent' `
                -Message "Submodule path '$SubmodulePath' must resolve inside the parent repository.")
    }

    if ((Split-Path -Leaf $normalizedSubmodulePath) -ne $Name) {
        throw (Get-MaintainerInvalidOperation `
                -ErrorId 'SubmodulePathLeafMismatch' `
                -Message "Submodule path '$SubmodulePath' must end with repository name '$Name'.")
    }

    if (Test-Path -LiteralPath $normalizedSubmodulePath) {
        throw (Get-MaintainerInvalidOperation `
                -ErrorId 'SubmodulePathAlreadyExists' `
                -Message "Submodule path '$normalizedSubmodulePath' already exists in the parent repository.")
    }

    $gitmodulesPath = Join-Path $normalizedParentRepositoryPath '.gitmodules'
    if (Test-Path -LiteralPath $gitmodulesPath -PathType Leaf) {
        $gitmodulesContent = Get-Content -LiteralPath $gitmodulesPath -Raw
        if ($gitmodulesContent -match "(?m)^\s*path\s*=\s*$([regex]::Escape($normalizedRelativeSubmodulePath))\s*$") {
            throw (Get-MaintainerInvalidOperation `
                    -ErrorId 'SubmodulePathAlreadyRegistered' `
                    -Message "Submodule path '$normalizedRelativeSubmodulePath' is already registered in .gitmodules.")
        }
    }

    [PSCustomObject]@{
        ParentRepositoryPath = $normalizedParentRepositoryPath
        SubmodulePath        = $normalizedRelativeSubmodulePath
        AbsolutePath         = $normalizedSubmodulePath
    }
}

function Assert-NewDibsGitLabRepositorySubmoduleWorkTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ParentRepositoryPath
    )

    try {
        $showTopLevelResult = Invoke-MaintainerTool `
            -WorkingDirectory $ParentRepositoryPath `
            -Name 'git' `
            -Arguments @('-C', $ParentRepositoryPath, 'rev-parse', '--show-toplevel')
        $topLevel = [string](@($showTopLevelResult.Output)[0])
        if ([string]::IsNullOrWhiteSpace($topLevel)) {
            throw 'git rev-parse --show-toplevel returned no output.'
        }

        $normalizedTopLevel = [System.IO.Path]::GetFullPath($topLevel, (Get-Location).ProviderPath)
        if ($normalizedTopLevel -ne $ParentRepositoryPath) {
            throw "Parent repository path '$ParentRepositoryPath' must be the repository root ($normalizedTopLevel)."
        }

        $bareRepositoryResult = Invoke-MaintainerTool `
            -WorkingDirectory $ParentRepositoryPath `
            -Name 'git' `
            -Arguments @('-C', $ParentRepositoryPath, 'rev-parse', '--is-bare-repository')
        $isBareRepository = [string](@($bareRepositoryResult.Output)[0])
        if ($isBareRepository -ne 'false') {
            throw "Parent repository path '$ParentRepositoryPath' must not be a bare repository."
        }

        return $normalizedTopLevel
    }
    catch {
        throw (Get-MaintainerInvalidOperation `
                -ErrorId 'ParentRepositoryNotGitWorkTree' `
                -Message "Parent repository path '$ParentRepositoryPath' is not a Git work tree. $($_.Exception.Message)")
    }
}
