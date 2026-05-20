function New-DibsGitLabRepository {
    <#
    .SYNOPSIS
    Creates and locally clones a maintainer-managed DIBS GitLab repository.

    .DESCRIPTION
    Creates a GitLab project under the requested group and relies on glab to clone it into the
    requested destination parent directory. The destination leaf must match the repository name
    because glab creates the local folder from the repository path.

    .PARAMETER Name
    Repository name to create. The destination path leaf must match this value.

    .PARAMETER Group
    GitLab group or namespace for the repository. Defaults to dibs-course.

    .PARAMETER DestinationPath
    Full destination path for the local clone. The parent directory must exist, and the
    destination itself must not already exist.

    .PARAMETER Visibility
    GitLab project visibility. Defaults to public.

    .PARAMETER DefaultBranch
    Initial default branch name. Defaults to main.

    .PARAMETER Readme
    README filename passed to glab so the repository is initialized before clone.

    .OUTPUTS
    PSCustomObject with repository metadata, command metadata, and tool output.

    .EXAMPLE
    PS> New-DibsGitLabRepository -Name python-companion -DestinationPath E:\teaching\DIBS\projects\python-companion -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $Group = 'dibs-course',

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $DestinationPath,

        [Parameter()]
        [ValidateSet('public', 'internal', 'private')]
        [string] $Visibility = 'public',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $DefaultBranch = 'main',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $Readme = 'README.md'
    )

    $projectPath = '{0}/{1}' -f $Group, $Name
    $normalizedDestinationPath = Resolve-NewRepositoryDestinationPath `
        -DestinationPath $DestinationPath
    $destinationParent = Split-Path -Parent $normalizedDestinationPath
    $visibilityFlag = Get-GitLabVisibilityFlag -Visibility $Visibility
    $arguments = @(
        'repo'
        'create'
        $projectPath
        $visibilityFlag
        '--defaultBranch'
        $DefaultBranch
        '--readme'
    )
    $commandMetadata = [PSCustomObject]@{
        Executable       = 'glab'
        Arguments        = $arguments
        WorkingDirectory = $destinationParent
    }

    Assert-NewDibsGitLabRepositoryRequest `
        -Name $Name `
        -Group $Group `
        -DestinationPath $normalizedDestinationPath

    $created = $false
    $toolOutput = $null
    $operation = 'Create GitLab repository and local clone'

    if ($PSCmdlet.ShouldProcess($projectPath, $operation)) {
        Assert-MaintainerGitLabAuthentication -WorkingDirectory $destinationParent

        $toolOutput = Invoke-MaintainerTool `
            -WorkingDirectory $destinationParent `
            -Name $commandMetadata.Executable `
            -Arguments $commandMetadata.Arguments
        $created = $true
    }

    [PSCustomObject]@{
        Group           = $Group
        Name            = $Name
        ProjectPath     = $projectPath
        Visibility      = $Visibility
        DefaultBranch   = $DefaultBranch
        Readme          = $Readme
        DestinationPath = $normalizedDestinationPath
        Created         = $created
        Command         = $commandMetadata
        ToolOutput      = $toolOutput
    }
}
