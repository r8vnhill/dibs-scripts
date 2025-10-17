using module ./Person.psm1

#Requires -Version 7.5
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $FirstName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [string] $LastName
)

function Script:New-Person {
    [OutputType([Person])]
    param ()
    
    [Person]::new($FirstName, $LastName)    
}

New-Person
