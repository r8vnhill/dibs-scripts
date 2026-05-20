function Assert-NewDibsGitLabRepositoryIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Group
    )

    if ($Name -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
        throw (Get-MaintainerInvalidOperation `
                -ErrorId 'InvalidRepositoryName' `
                -Message "Repository name '$Name' must start with a letter or digit and contain only letters, digits, dots, underscores, or hyphens.")
    }

    if ($Group -notmatch '^[A-Za-z0-9][A-Za-z0-9._/-]*$') {
        throw (Get-MaintainerInvalidOperation `
                -ErrorId 'InvalidRepositoryGroup' `
                -Message "Repository group '$Group' must start with a letter or digit and contain only letters, digits, dots, underscores, hyphens, or slashes.")
    }
}

function Get-MaintainerGitLabCloneUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectPath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $HostName = 'gitlab.com'
    )

    'https://{0}/{1}.git' -f $HostName.TrimEnd('/'), $ProjectPath.TrimStart('/')
}

function Get-GitLabVisibilityFlag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('public', 'internal', 'private')]
        [string] $Visibility
    )

    switch ($Visibility) {
        'public' { '--public' }
        'internal' { '--internal' }
        'private' { '--private' }
    }
}

function Assert-MaintainerGitLabAuthentication {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $WorkingDirectory
    )

    try {
        Invoke-MaintainerTool `
            -WorkingDirectory $WorkingDirectory `
            -Name 'glab' `
            -Arguments @('auth', 'status') |
            Out-Null
    }
    catch {
        throw (Get-MaintainerInvalidOperation `
                -ErrorId 'GitLabAuthenticationRequired' `
                -Message "GitLab authentication is required before creating repositories. Run 'glab auth login' or refresh your GitLab token, then retry. $($_.Exception.Message)")
    }
}

function Assert-NewDibsGitLabRepositoryRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Group,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $DestinationPath
    )

    Assert-NewDibsGitLabRepositoryIdentity -Name $Name -Group $Group

    $destinationParent = Split-Path -Parent $DestinationPath
    if (-not (Test-Path -LiteralPath $destinationParent -PathType Container)) {
        throw (Get-MaintainerInvalidOperation `
                -ErrorId 'DestinationParentMissing' `
                -Message "Destination parent directory '$destinationParent' does not exist.")
    }

    if (Test-Path -LiteralPath $DestinationPath) {
        throw (Get-MaintainerInvalidOperation `
                -ErrorId 'DestinationAlreadyExists' `
                -Message "Destination path '$DestinationPath' already exists.")
    }

    $destinationName = Split-Path -Leaf $DestinationPath
    if ($destinationName -ne $Name) {
        throw (Get-MaintainerInvalidOperation `
                -ErrorId 'DestinationNameMismatch' `
                -Message "Destination leaf '$destinationName' must match repository name '$Name'.")
    }
}
