function New-DibsGitLabRepositorySubmodule {
    <#
    .SYNOPSIS
    Creates a GitLab repository and registers it as a submodule in a parent repository.

    .DESCRIPTION
    Composes repository creation with git submodule add so maintainers can publish a new
    repository and register it inside an existing parent repository in one workflow. The
    repository is created in a temporary maintainer workspace so the final submodule path stays
    free for git submodule add.

    .PARAMETER Name
    Repository name to create and register as a submodule.

    .PARAMETER Group
    GitLab group or namespace for the repository. Defaults to dibs-course.

    .PARAMETER ParentRepositoryPath
    Path to the existing parent Git repository that will receive the submodule.

    .PARAMETER SubmodulePath
    Relative submodule path inside the parent repository.

    .PARAMETER Visibility
    GitLab project visibility. Defaults to public.

    .PARAMETER DefaultBranch
    Initial default branch name. Defaults to main.

    .PARAMETER Readme
    README filename passed to glab so the repository is initialized before clone.

    .OUTPUTS
    PSCustomObject with repository metadata, command metadata, and tool output.

    .EXAMPLE
    PS> New-DibsGitLabRepositorySubmodule -Name python-companion -ParentRepositoryPath E:\teaching\DIBS\projects -SubmodulePath companions/python-companion -WhatIf
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
        [string] $ParentRepositoryPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $SubmodulePath,

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
    $submoduleRequest = Assert-NewDibsGitLabRepositorySubmoduleRequest `
        -Name $Name `
        -Group $Group `
        -ParentRepositoryPath $ParentRepositoryPath `
        -SubmodulePath $SubmodulePath

    $remoteUrl = Get-MaintainerGitLabCloneUrl -ProjectPath $projectPath
    $createRepositoryCommand = [PSCustomObject]@{
        Executable       = 'New-DibsGitLabRepository'
        Arguments        = @(
            '-Group'
            $Group
            '-Name'
            $Name
            '-DestinationPath'
            ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), 'dibs-maintainer', [Guid]::NewGuid().ToString('N'), $Name))
            '-Visibility'
            $Visibility
            '-DefaultBranch'
            $DefaultBranch
            '-Readme'
            $Readme
        )
        WorkingDirectory = [System.IO.Path]::GetTempPath()
    }

    $addSubmoduleCommand = [PSCustomObject]@{
        Executable       = 'git'
        Arguments        = @(
            '-C'
            $submoduleRequest.ParentRepositoryPath
            'submodule'
            'add'
            $remoteUrl
            $submoduleRequest.SubmodulePath
        )
        WorkingDirectory = $submoduleRequest.ParentRepositoryPath
    }

    if (-not $PSCmdlet.ShouldProcess($projectPath, 'Create GitLab repository and add submodule')) {
        return [PSCustomObject]@{
            Group                = $Group
            Name                 = $Name
            ProjectPath          = $projectPath
            Visibility           = $Visibility
            DefaultBranch        = $DefaultBranch
            ParentRepositoryPath = $submoduleRequest.ParentRepositoryPath
            SubmodulePath        = $submoduleRequest.SubmodulePath
            RemoteUrl            = $remoteUrl
            Created              = $false
            SubmoduleAdded       = $false
            Repository           = $null
            Commands             = [PSCustomObject]@{
                CreateRepository = $createRepositoryCommand
                AddSubmodule     = $addSubmoduleCommand
            }
            ToolOutput           = $null
        }
    }

    $null = Assert-NewDibsGitLabRepositorySubmoduleWorkTree -ParentRepositoryPath $submoduleRequest.ParentRepositoryPath

    $creationWorkspaceParent = Join-Path ([System.IO.Path]::GetTempPath()) 'dibs-maintainer'
    $creationWorkspace = Join-Path $creationWorkspaceParent ([Guid]::NewGuid().ToString('N'))
    $creationDestinationPath = Join-Path $creationWorkspace $Name
    $createRepositoryCommand.Arguments[5] = $creationDestinationPath
    $repositoryResult = $null
    $submoduleToolOutput = $null
    $submoduleAdded = $false
    $created = $false

    try {
        New-Item -ItemType Directory -Path $creationWorkspace -Force | Out-Null

        $repositoryResult = New-DibsGitLabRepository `
            -Name $Name `
            -Group $Group `
            -DestinationPath $creationDestinationPath `
            -Visibility $Visibility `
            -DefaultBranch $DefaultBranch `
            -Readme $Readme `
            -Confirm:$false
        if ($null -ne $repositoryResult -and -not $repositoryResult.PSObject.Properties.Match('Created')) {
            $repositoryResult | Add-Member -NotePropertyName Created -NotePropertyValue $true -Force
        }
        $created = $true

        $submoduleToolOutput = Invoke-MaintainerTool `
            -WorkingDirectory $submoduleRequest.ParentRepositoryPath `
            -Name 'git' `
            -Arguments @(
                '-C'
                $submoduleRequest.ParentRepositoryPath
                'submodule'
                'add'
                $remoteUrl
                $submoduleRequest.SubmodulePath
            )
        $submoduleAdded = $true
    }
    catch {
        if ($null -ne $repositoryResult -and -not $submoduleAdded) {
            $submoduleToolOutput = $_
        }
        elseif ($null -eq $repositoryResult) {
            throw
        }
    }
    finally {
        if (Test-Path -LiteralPath $creationWorkspace) {
            Remove-Item -LiteralPath $creationWorkspace -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    $repositorySummary = if ($null -ne $repositoryResult) {
        [PSCustomObject]@{
            Group           = $repositoryResult.Group
            Name            = $repositoryResult.Name
            ProjectPath     = $repositoryResult.ProjectPath
            Visibility      = $repositoryResult.Visibility
            DefaultBranch   = $repositoryResult.DefaultBranch
            Readme          = $repositoryResult.Readme
            DestinationPath = $repositoryResult.DestinationPath
            Created         = $created
            Command         = $repositoryResult.Command
            ToolOutput      = $repositoryResult.ToolOutput
        }
    }

    [PSCustomObject]@{
        Group                = $Group
        Name                 = $Name
        ProjectPath          = $projectPath
        Visibility           = $Visibility
        DefaultBranch        = $DefaultBranch
        ParentRepositoryPath = $submoduleRequest.ParentRepositoryPath
        SubmodulePath        = $submoduleRequest.SubmodulePath
        RemoteUrl            = $remoteUrl
        Created              = $created
        SubmoduleAdded       = $submoduleAdded
        Repository           = $repositorySummary
        Commands             = [PSCustomObject]@{
            CreateRepository = $createRepositoryCommand
            AddSubmodule     = $addSubmoduleCommand
        }
        ToolOutput           = [PSCustomObject]@{
            Repository   = $repositorySummary.ToolOutput
            AddSubmodule = $submoduleToolOutput
        }
    }
}
