#Requires -Version 7.5
Set-StrictMode -Version 3.0
<#!
.SYNOPSIS
    Minimal comment-based help template.
.DESCRIPTION
    Use this as a starting point to document your scripts. Keep it concise.
.PARAMETER Path
    Target path to process.
.EXAMPLE
    .\CommentBasedHelp-Template.ps1 -Path .
#>

param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $Path
)

# Your script logic here
