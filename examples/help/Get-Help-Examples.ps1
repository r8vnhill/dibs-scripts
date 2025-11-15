#Requires -Version 7.5
Set-StrictMode -Version 3.0
# Examples: read integrated help and concepts with Get-Help
# Note: Commands below may open a browser (-Online). Leave commented if undesired.

# Quick help (summary, parameters, examples)
Get-Help -Name Get-Help
Get-Help -Name Get-ChildItem -Examples
Get-Help -Name Get-Command -Full

# Open documentation in the browser (comment out to avoid side effects)
# Get-Help -Name Get-ChildItem -Online

# Explore conceptual topics (about_*)
Get-Help -Name about_Comparison_Operators
Get-Help -Name about_*

# Quick help shortcut for a single cmdlet
Get-Culture -?
# Help for a specific parameter
Get-Help -Name Out-String -Parameter Stream

# Optional: update local help (first-time setup)
# Update-Help -UICulture en-US
