<#
.SYNOPSIS
    Generates the initial content for a README.md file.

.DESCRIPTION
    This script creates a basic README template containing the project name,
    initialization date, and a link to further documentation on writing good READMEs.
    It is designed as a simple, reusable utility script for project setup automation.

.PARAMETER Name
    The name of the project for which the README file will be generated.
    This parameter is mandatory and must be a non-empty string.

.EXAMPLE
    PS> ./New-Readme.ps1 -Name "MyApp"

    Generates a README.md template for a project named “MyApp”.
    To see verbose output, run with `-Verbose`.

.EXAMPLE
    PS> ./New-Readme.ps1 -Name "Keen" -Verbose

    Creates README content for “Keen” and prints an informational message before output.
#>
#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]  # Prevents empty or null names
    [string] $Name
)

Write-Verbose "Creating README.md for project '$Name'"

@'
# {0}

Project initialized on {1}.

Learn more about READMEs at https://www.makeareadme.com/.
'@ -f $Name, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
