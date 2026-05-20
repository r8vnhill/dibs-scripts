#Requires -Version 7.6

. "$PSScriptRoot/Maintainer.Utils.TestSupport.ps1"

Describe 'New-DibsGitLabRepository' {
    It 'builds the expected default glab repo create invocation' {
        InModuleScope Maintainer.Utils {
            $parent = Join-Path (Get-PSDrive TestDrive).Root 'projects'
            New-Item -ItemType Directory -Path $parent | Out-Null
            $destination = Join-Path $parent 'python-companion'

            Mock Invoke-MaintainerTool {
                [PSCustomObject]@{
                    ToolPath = 'glab'
                    ExitCode = 0
                    Output   = @('created')
                }
            }

            $result = New-DibsGitLabRepository `
                -Name 'python-companion' `
                -DestinationPath $destination `
                -Confirm:$false

            $result.Group | Should -Be 'dibs-course'
            $result.Name | Should -Be 'python-companion'
            $result.ProjectPath | Should -Be 'dibs-course/python-companion'
            $result.Visibility | Should -Be 'public'
            $result.DefaultBranch | Should -Be 'main'
            $result.Readme | Should -Be 'README.md'
            $result.Created | Should -BeTrue
            $result.Command.Executable | Should -Be 'glab'
            $result.Command.WorkingDirectory | Should -Be ([System.IO.Path]::GetFullPath($parent))
            $result.Command.Arguments | Should -Be @(
                'repo'
                'create'
                'dibs-course/python-companion'
                '--public'
                '--defaultBranch'
                'main'
                '--readme'
            )

            Should -Invoke Invoke-MaintainerTool -Exactly 1 -Scope It -ParameterFilter {
                $WorkingDirectory -eq [System.IO.Path]::GetFullPath($parent) -and
                $Name -eq 'glab' -and
                ($Arguments -join ' ') -eq 'auth status'
            }
            Should -Invoke Invoke-MaintainerTool -Exactly 1 -Scope It -ParameterFilter {
                $WorkingDirectory -eq [System.IO.Path]::GetFullPath($parent) -and
                $Name -eq 'glab' -and
                ($Arguments -join ' ') -eq 'repo create dibs-course/python-companion --public --defaultBranch main --readme'
            }
        }
    }

    It 'supports non-default repository metadata' {
        InModuleScope Maintainer.Utils {
            $parent = Join-Path (Get-PSDrive TestDrive).Root 'custom'
            New-Item -ItemType Directory -Path $parent | Out-Null
            $destination = Join-Path $parent 'tools-api'

            Mock Invoke-MaintainerTool { 'ok' }

            $result = New-DibsGitLabRepository `
                -Group 'dibs-tools' `
                -Name 'tools-api' `
                -DestinationPath $destination `
                -Visibility 'private' `
                -DefaultBranch 'trunk' `
                -Readme 'ReadMe.md' `
                -Confirm:$false

            $result.ProjectPath | Should -Be 'dibs-tools/tools-api'
            $result.Visibility | Should -Be 'private'
            $result.DefaultBranch | Should -Be 'trunk'
            $result.Readme | Should -Be 'ReadMe.md'
            $result.Command.Arguments | Should -Be @(
                'repo'
                'create'
                'dibs-tools/tools-api'
                '--private'
                '--defaultBranch'
                'trunk'
                '--readme'
            )
        }
    }

    It 'rejects an existing destination before invoking glab' {
        InModuleScope Maintainer.Utils {
            $parent = Join-Path (Get-PSDrive TestDrive).Root 'existing'
            $destination = Join-Path $parent 'python-companion'
            New-Item -ItemType Directory -Path $destination | Out-Null

            Mock Invoke-MaintainerTool { throw 'unexpected invocation' }

            {
                New-DibsGitLabRepository `
                    -Name 'python-companion' `
                    -DestinationPath $destination `
                    -Confirm:$false
            } | Should -Throw -ErrorId 'DestinationAlreadyExists'

            Should -Invoke Invoke-MaintainerTool -Exactly 0 -Scope It
        }
    }

    It 'rejects a missing destination parent before invoking glab' {
        InModuleScope Maintainer.Utils {
            $destination = Join-Path (Join-Path (Get-PSDrive TestDrive).Root 'missing') 'python-companion'

            Mock Invoke-MaintainerTool { throw 'unexpected invocation' }

            {
                New-DibsGitLabRepository `
                    -Name 'python-companion' `
                    -DestinationPath $destination `
                    -Confirm:$false
            } | Should -Throw -ErrorId 'DestinationParentMissing'

            Should -Invoke Invoke-MaintainerTool -Exactly 0 -Scope It
        }
    }

    It 'rejects missing GitLab authentication before creating the repository' {
        InModuleScope Maintainer.Utils {
            $parent = Join-Path (Get-PSDrive TestDrive).Root 'unauthenticated'
            New-Item -ItemType Directory -Path $parent | Out-Null
            $destination = Join-Path $parent 'python-companion'

            Mock Invoke-MaintainerTool {
                $argumentText = $Arguments -join ' '
                if ($argumentText -eq 'auth status') {
                    throw [System.Exception]::new('glab auth status returned exit code 1. Output: not authenticated')
                }

                throw "Unexpected glab invocation: $argumentText"
            }

            {
                New-DibsGitLabRepository `
                    -Name 'python-companion' `
                    -DestinationPath $destination `
                    -Confirm:$false
            } | Should -Throw -ErrorId 'GitLabAuthenticationRequired'

            Should -Invoke Invoke-MaintainerTool -Exactly 1 -Scope It -ParameterFilter {
                $Name -eq 'glab' -and
                ($Arguments -join ' ') -eq 'auth status'
            }
            Should -Invoke Invoke-MaintainerTool -Exactly 0 -Scope It -ParameterFilter {
                $Name -eq 'glab' -and
                ($Arguments -join ' ') -like 'repo create *'
            }
        }
    }

    It 'rejects a destination whose leaf does not match the repository name' {
        InModuleScope Maintainer.Utils {
            $parent = Join-Path (Get-PSDrive TestDrive).Root 'mismatch'
            New-Item -ItemType Directory -Path $parent | Out-Null
            $destination = Join-Path $parent 'wrong-name'

            Mock Invoke-MaintainerTool { throw 'unexpected invocation' }

            {
                New-DibsGitLabRepository `
                    -Name 'python-companion' `
                    -DestinationPath $destination `
                    -Confirm:$false
            } | Should -Throw -ErrorId 'DestinationNameMismatch'

            Should -Invoke Invoke-MaintainerTool -Exactly 0 -Scope It
        }
    }

    It 'supports WhatIf without invoking glab' {
        InModuleScope Maintainer.Utils {
            $parent = Join-Path (Get-PSDrive TestDrive).Root 'whatif'
            New-Item -ItemType Directory -Path $parent | Out-Null
            $destination = Join-Path $parent 'python-companion'

            Mock Invoke-MaintainerTool { throw 'unexpected invocation' }

            $result = New-DibsGitLabRepository `
                -Name 'python-companion' `
                -DestinationPath $destination `
                -WhatIf

            $result.Created | Should -BeFalse
            $result.Command.Executable | Should -Be 'glab'
            $result.Command.Arguments | Should -Contain 'dibs-course/python-companion'
            $result.ToolOutput | Should -BeNullOrEmpty
            Should -Invoke Invoke-MaintainerTool -Exactly 0 -Scope It
        }
    }
}
