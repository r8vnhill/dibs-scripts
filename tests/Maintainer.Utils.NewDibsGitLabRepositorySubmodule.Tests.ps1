#Requires -Version 7.6

. "$PSScriptRoot/Maintainer.Utils.TestSupport.ps1"

Describe 'New-DibsGitLabRepositorySubmodule' {
    It 'creates the repository and adds the submodule on the happy path' {
        InModuleScope Maintainer.Utils {
            $parent = Join-Path (Get-PSDrive TestDrive).Root 'parent-repo'
            New-Item -ItemType Directory -Path $parent | Out-Null
            $parentFullPath = [System.IO.Path]::GetFullPath($parent)
            $toolInvocations = [System.Collections.Generic.List[object]]::new()
            $repoInvocations = [System.Collections.Generic.List[object]]::new()

            Mock Invoke-MaintainerTool {
                $toolInvocations.Add([PSCustomObject]@{
                    WorkingDirectory = $WorkingDirectory
                    Name             = $Name
                    Arguments        = @($Arguments)
                })

                $argumentText = $Arguments -join ' '
                if ($argumentText -eq "-C $parentFullPath rev-parse --show-toplevel") {
                    return [PSCustomObject]@{
                        ToolPath = 'git'
                        ExitCode = 0
                        Output   = @($parentFullPath)
                    }
                }

                if ($argumentText -eq "-C $parentFullPath rev-parse --is-bare-repository") {
                    return [PSCustomObject]@{
                        ToolPath = 'git'
                        ExitCode = 0
                        Output   = @('false')
                    }
                }

                if ($argumentText -eq "-C $parentFullPath submodule add https://gitlab.com/dibs-course/python-companion.git companions/python-companion") {
                    return [PSCustomObject]@{
                        ToolPath = 'git'
                        ExitCode = 0
                        Output   = @('submodule added')
                    }
                }

                throw "Unexpected git invocation: $argumentText"
            }

            Mock New-DibsGitLabRepository {
                $repoInvocations.Add([PSCustomObject]@{
                    Name            = $Name
                    Group           = $Group
                    DestinationPath = $DestinationPath
                    Visibility      = $Visibility
                    DefaultBranch   = $DefaultBranch
                    Readme          = $Readme
                })

                [PSCustomObject]@{
                    Group           = $Group
                    Name            = $Name
                    ProjectPath     = "$Group/$Name"
                    Visibility      = $Visibility
                    DefaultBranch   = $DefaultBranch
                    Readme          = $Readme
                    DestinationPath = $DestinationPath
                    Created         = $true
                    Command         = [PSCustomObject]@{
                        Executable       = 'glab'
                        Arguments        = @(
                            'repo'
                            'create'
                            "$Group/$Name"
                            '--public'
                            '--defaultBranch'
                            $DefaultBranch
                            '--readme'
                        )
                        WorkingDirectory = (Split-Path -Parent $DestinationPath)
                    }
                    ToolOutput      = [PSCustomObject]@{
                        ToolPath = 'glab'
                        ExitCode = 0
                        Output   = @('created')
                    }
                }
            }

            $result = New-DibsGitLabRepositorySubmodule `
                -Name 'python-companion' `
                -ParentRepositoryPath $parent `
                -SubmodulePath 'companions/python-companion' `
                -Confirm:$false

            $result.Created | Should -BeTrue
            $result.SubmoduleAdded | Should -BeTrue
            $result.RemoteUrl | Should -Be 'https://gitlab.com/dibs-course/python-companion.git'
            $result.Repository.ProjectPath | Should -Be 'dibs-course/python-companion'
            $result.Commands.CreateRepository.Executable | Should -Be 'New-DibsGitLabRepository'
            $result.Commands.CreateRepository.Arguments | Should -Be @(
                '-Group'
                'dibs-course'
                '-Name'
                'python-companion'
                '-DestinationPath'
                $result.Repository.DestinationPath
                '-Visibility'
                'public'
                '-DefaultBranch'
                'main'
                '-Readme'
                'README.md'
            )
            $result.Commands.AddSubmodule.Arguments | Should -Be @(
                '-C'
                $parentFullPath
                'submodule'
                'add'
                'https://gitlab.com/dibs-course/python-companion.git'
                'companions/python-companion'
            )
            $repoInvocations.Count | Should -Be 1
            $toolInvocations.Count | Should -Be 3
            (Split-Path -Leaf $repoInvocations[0].DestinationPath) | Should -Be 'python-companion'
            (Split-Path -Parent $repoInvocations[0].DestinationPath) | Should -Not -BeNullOrEmpty
        }
    }

    It 'returns planned command metadata without invoking tools in WhatIf mode' {
        InModuleScope Maintainer.Utils {
            $parent = Join-Path (Get-PSDrive TestDrive).Root 'whatif-parent'
            New-Item -ItemType Directory -Path $parent | Out-Null

            Mock Invoke-MaintainerTool { throw 'unexpected invocation' }
            Mock New-DibsGitLabRepository { throw 'unexpected invocation' }

            $result = New-DibsGitLabRepositorySubmodule `
                -Name 'python-companion' `
                -ParentRepositoryPath $parent `
                -SubmodulePath 'companions/python-companion' `
                -WhatIf

            $result.Created | Should -BeFalse
            $result.SubmoduleAdded | Should -BeFalse
            $result.Repository | Should -BeNullOrEmpty
            $result.Commands.CreateRepository.Executable | Should -Be 'New-DibsGitLabRepository'
            $result.Commands.AddSubmodule.Executable | Should -Be 'git'
            Should -Invoke Invoke-MaintainerTool -Exactly 0 -Scope It
            Should -Invoke New-DibsGitLabRepository -Exactly 0 -Scope It
        }
    }

    It 'rejects a missing parent repository before invoking tools' {
        InModuleScope Maintainer.Utils {
            $parent = Join-Path (Get-PSDrive TestDrive).Root 'missing-parent'

            Mock Invoke-MaintainerTool { throw 'unexpected invocation' }
            Mock New-DibsGitLabRepository { throw 'unexpected invocation' }

            {
                New-DibsGitLabRepositorySubmodule `
                    -Name 'python-companion' `
                    -ParentRepositoryPath $parent `
                    -SubmodulePath 'companions/python-companion' `
                    -Confirm:$false
            } | Should -Throw -ErrorId 'ParentRepositoryMissing'

            Should -Invoke Invoke-MaintainerTool -Exactly 0 -Scope It
            Should -Invoke New-DibsGitLabRepository -Exactly 0 -Scope It
        }
    }

    It 'rejects rooted submodule paths' {
        InModuleScope Maintainer.Utils {
            $parent = Join-Path (Get-PSDrive TestDrive).Root 'rooted-parent'
            New-Item -ItemType Directory -Path $parent | Out-Null

            Mock Invoke-MaintainerTool { throw 'unexpected invocation' }
            Mock New-DibsGitLabRepository { throw 'unexpected invocation' }

            {
                New-DibsGitLabRepositorySubmodule `
                    -Name 'python-companion' `
                    -ParentRepositoryPath $parent `
                    -SubmodulePath 'C:\companions\python-companion' `
                    -Confirm:$false
            } | Should -Throw -ErrorId 'SubmodulePathRooted'
        }
    }

    It 'rejects parent traversal in submodule paths' {
        InModuleScope Maintainer.Utils {
            $parent = Join-Path (Get-PSDrive TestDrive).Root 'traversal-parent'
            New-Item -ItemType Directory -Path $parent | Out-Null

            Mock Invoke-MaintainerTool { throw 'unexpected invocation' }
            Mock New-DibsGitLabRepository { throw 'unexpected invocation' }

            {
                New-DibsGitLabRepositorySubmodule `
                    -Name 'python-companion' `
                    -ParentRepositoryPath $parent `
                    -SubmodulePath '..\python-companion' `
                    -Confirm:$false
            } | Should -Throw -ErrorId 'SubmodulePathTraversal'
        }
    }

    It 'rejects existing submodule paths' {
        InModuleScope Maintainer.Utils {
            $parent = Join-Path (Get-PSDrive TestDrive).Root 'existing-parent'
            $existing = Join-Path $parent 'companions\python-companion'
            New-Item -ItemType Directory -Path $existing -Force | Out-Null

            Mock Invoke-MaintainerTool { throw 'unexpected invocation' }
            Mock New-DibsGitLabRepository { throw 'unexpected invocation' }

            {
                New-DibsGitLabRepositorySubmodule `
                    -Name 'python-companion' `
                    -ParentRepositoryPath $parent `
                    -SubmodulePath 'companions/python-companion' `
                    -Confirm:$false
            } | Should -Throw -ErrorId 'SubmodulePathAlreadyExists'
        }
    }

    It 'rejects paths already declared in .gitmodules' {
        InModuleScope Maintainer.Utils {
            $parent = Join-Path (Get-PSDrive TestDrive).Root 'gitmodules-parent'
            New-Item -ItemType Directory -Path $parent | Out-Null
            Set-Content -LiteralPath (Join-Path $parent '.gitmodules') -Value @'
[submodule "companions/python-companion"]
	path = companions/python-companion
	url = https://gitlab.com/dibs-course/python-companion.git
'@

            Mock Invoke-MaintainerTool { throw 'unexpected invocation' }
            Mock New-DibsGitLabRepository { throw 'unexpected invocation' }

            {
                New-DibsGitLabRepositorySubmodule `
                    -Name 'python-companion' `
                    -ParentRepositoryPath $parent `
                    -SubmodulePath 'companions/python-companion' `
                    -Confirm:$false
            } | Should -Throw -ErrorId 'SubmodulePathAlreadyRegistered'
        }
    }

    It 'rejects leaf mismatches by default' {
        InModuleScope Maintainer.Utils {
            $parent = Join-Path (Get-PSDrive TestDrive).Root 'leaf-parent'
            New-Item -ItemType Directory -Path $parent | Out-Null

            Mock Invoke-MaintainerTool { throw 'unexpected invocation' }
            Mock New-DibsGitLabRepository { throw 'unexpected invocation' }

            {
                New-DibsGitLabRepositorySubmodule `
                    -Name 'python-companion' `
                    -ParentRepositoryPath $parent `
                    -SubmodulePath 'companions/not-python-companion' `
                    -Confirm:$false
            } | Should -Throw -ErrorId 'SubmodulePathLeafMismatch'
        }
    }

    It 'stops after repository creation fails' {
        InModuleScope Maintainer.Utils {
            $parent = Join-Path (Get-PSDrive TestDrive).Root 'repo-failure-parent'
            New-Item -ItemType Directory -Path $parent | Out-Null
            $parentFullPath = [System.IO.Path]::GetFullPath($parent)

            Mock Invoke-MaintainerTool {
                $argumentText = $Arguments -join ' '
                if ($argumentText -eq "-C $parentFullPath rev-parse --show-toplevel") {
                    return [PSCustomObject]@{ ToolPath = 'git'; ExitCode = 0; Output = @($parentFullPath) }
                }

                if ($argumentText -eq "-C $parentFullPath rev-parse --is-bare-repository") {
                    return [PSCustomObject]@{ ToolPath = 'git'; ExitCode = 0; Output = @('false') }
                }

                throw "Unexpected git invocation: $argumentText"
            }

            Mock New-DibsGitLabRepository {
                throw (Get-MaintainerInvalidOperation -ErrorId 'RepoCreationFailed' -Message 'Repository creation failed.')
            }

            {
                New-DibsGitLabRepositorySubmodule `
                    -Name 'python-companion' `
                    -ParentRepositoryPath $parent `
                    -SubmodulePath 'companions/python-companion' `
                    -Confirm:$false
            } | Should -Throw -ErrorId 'RepoCreationFailed'
        }
    }

    It 'reports submodule add failures without losing repository metadata' {
        InModuleScope Maintainer.Utils {
            $parent = Join-Path (Get-PSDrive TestDrive).Root 'submodule-failure-parent'
            New-Item -ItemType Directory -Path $parent | Out-Null
            $parentFullPath = [System.IO.Path]::GetFullPath($parent)

            Mock Invoke-MaintainerTool {
                $argumentText = $Arguments -join ' '
                if ($argumentText -eq "-C $parentFullPath rev-parse --show-toplevel") {
                    return [PSCustomObject]@{ ToolPath = 'git'; ExitCode = 0; Output = @($parentFullPath) }
                }

                if ($argumentText -eq "-C $parentFullPath rev-parse --is-bare-repository") {
                    return [PSCustomObject]@{ ToolPath = 'git'; ExitCode = 0; Output = @('false') }
                }

                if ($argumentText -eq "-C $parentFullPath submodule add https://gitlab.com/dibs-course/python-companion.git companions/python-companion") {
                    throw (Get-MaintainerInvalidOperation -ErrorId 'SubmoduleAddFailed' -Message 'Submodule add failed.')
                }

                throw "Unexpected git invocation: $argumentText"
            }

            Mock New-DibsGitLabRepository {
                [PSCustomObject]@{
                    Group           = $Group
                    Name            = $Name
                    ProjectPath     = "$Group/$Name"
                    Visibility      = $Visibility
                    DefaultBranch   = $DefaultBranch
                    Readme          = $Readme
                    DestinationPath = $DestinationPath
                    Created         = $true
                    Command         = [PSCustomObject]@{
                        Executable       = 'glab'
                        Arguments        = @('repo', 'create', "$Group/$Name", '--public', '--defaultBranch', $DefaultBranch, '--readme')
                        WorkingDirectory = (Split-Path -Parent $DestinationPath)
                    }
                    ToolOutput      = [PSCustomObject]@{ ToolPath = 'glab'; ExitCode = 0; Output = @('created') }
                }
            }

            $result = New-DibsGitLabRepositorySubmodule `
                -Name 'python-companion' `
                -ParentRepositoryPath $parent `
                -SubmodulePath 'companions/python-companion' `
                -Confirm:$false

            $result.Created | Should -BeTrue
            $result.SubmoduleAdded | Should -BeFalse
            $result.Repository.Created | Should -BeTrue
            $result.ToolOutput.AddSubmodule.FullyQualifiedErrorId | Should -Be 'SubmoduleAddFailed'
        }
    }
}
