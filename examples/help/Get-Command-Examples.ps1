#Requires -Version 7.5
Set-StrictMode -Version 3.0
# Examples: discover and filter commands with Get-Command
# Note: These are interactive snippets. They return objects; no host writes.

# Explore a specific command object
$cmd = Get-Command -Name Get-Command
Get-Member -InputObject $cmd

# Filter by verb or noun
Get-Command -Verb Push
Get-Command -Noun *Item

# When you don't remember the exact name
Get-Command -Name *location*  # commands related to "location"

# Filter by type and module
Get-Command -CommandType Cmdlet -Module Microsoft.PowerShell.Management

# Show syntax for a specific command
Get-Command -Name Copy-Item -Syntax

# Find by parameter name or parameter type
Get-Command -ParameterName Force
Get-Command -ParameterType [switch]
