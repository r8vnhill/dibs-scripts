#Requires -Version 7.0
[CmdletBinding()]
[OutputType([string])]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Name
)

Write-Verbose "Creating README.md for project '$Name'"

return @"
# $Name

Project initialized on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss').

Learn more about READMEs at https://www.makeareadme.com/.
"@
