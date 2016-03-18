<#
    .SYNOPSIS PowerShell module for GitHub analytics
#>

$apiTokensFilePath = "$PSScriptRoot\ApiTokens.psm1"
if (Test-Path $apiTokensFilePath)
{
    Write-Host "Importing $apiTokensFilePath"
    Import-Module  -force $apiTokensFilePath
}
else
{
    Write-Host "$apiTokensFilePath does not exist, skipping import"
    Write-Host @'
# This module should define $global:gitHubApiToken with your GitHub API access token. Create this file it if it doesn't exist.
# You can get GitHub token from https://github.com/settings/tokens
# If you don't provide it, you can still use this module, but you will be limited to 60 queries per hour.
'@
}

$script:gitHubToken = $global:gitHubApiToken 
$script:gitHubApiUrl = "https://api.github.com"
$script:gitHubApiReposUrl = "https://api.github.com/repos"
$script:gitHubApiOrgsUrl = "https://api.github.com/orgs"
$script:maxPageSize = 100

<#
    .SYNOPSIS Function which gets list of issues for given repository
    .PARAM
        repositoryUrl Array of repository urls which we want to get issues from
    .PARAM 
        state Whether we want to get open, closed or all issues
    .PARAM
        createdOnOrAfter Filter to only get issues created on or after specific date
    .PARAM
        createdOnOrBefore Filter to only get issues created on or before specific date    
    .PARAM
        closedOnOrAfter Filter to only get issues closed on or after specific date
    .PARAM
        ClosedOnOrBefore Filter to only get issues closed on or before specific date
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        $issues = Get-GitHubIssuesForRepository -repositoryUrl @('https://github.com/PowerShell/xPSDesiredStateConfiguration')
    .EXAMPLE
        $issues = Get-GitHubIssuesForRepository `
            -repositoryUrl @('https://github.com/PowerShell/xPSDesiredStateConfiguration', "https://github.com/PowerShell/xWindowsUpdate" ) `
            -createdOnOrAfter '2015-04-20'
#>
function Get-GitHubIssuesForRepository
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $repositoryUrl,
        [ValidateSet("open", "closed", "all")]
        [String] $state = "open",
        [DateTime] $createdOnOrAfter,
        [DateTime] $createdOnOrBefore,
        [DateTime] $closedOnOrAfter,
        [DateTime] $closedOnOrBefore,
        $gitHubAccessToken = $script:gitHubToken
    )

    $resultToReturn = @()

    $index = 0
    
    foreach ($repository in $repositoryUrl)
    {
        Write-Host "Getting issues for repository $repository" -ForegroundColor Yellow

        $repositoryName = Get-GitHubRepositoryNameFromUrl -repositoryUrl $repository
        $repositoryOwner = Get-GitHubRepositoryOwnerFromUrl -repositoryUrl $repository

        # Create query for issues
        $query = "$script:gitHubApiReposUrl/$repositoryOwner/$repositoryName/issues?state=$state"
            
        if (![string]::IsNullOrEmpty($gitHubAccessToken))
        {
            $query += "&access_token=$gitHubAccessToken"
        }
        
        # Obtain issues    
        $jsonResult = Invoke-WebRequest $query
        $issues = ConvertFrom-Json -InputObject $jsonResult.content
        
        foreach ($issue in $issues)
        {
            # GitHub considers pull request to be an issue, so let's skip pull requests.
            if ($issue.pull_request -ne $null)
            {
                continue
            }

            # Filter according to createdOnOrAfter
            $createdDate = Get-Date -Date $issue.created_at
            if (($createdOnOrAfter -ne $null) -and ($createdDate -lt $createdOnOrAfter))
            {
                continue  
            }

            # Filter according to createdOnOrBefore
            if (($createdOnOrBefore -ne $null) -and ($createdDate -gt $createdOnOrBefore))
            {
                continue  
            }

            if ($issue.closed_at -ne $null)
            {
                # Filter according to closedOnOrAfter
                $closedDate = Get-Date -Date $issue.closed_at
                if (($closedOnOrAfter -ne $null) -and ($closedDate -lt $closedOnOrAfter))
                {
                    continue  
                }

                # Filter according to closedOnOrBefore
                if (($closedOnOrBefore -ne $null) -and ($closedDate -gt $closedOnOrBefore))
                {
                    continue  
                }
            }
            else
            {
                # If issue isn't closed, but we specified filtering on closedOn, skip it
                if (($closedOnOrAfter -ne $null) -or ($closedOnOrBefore -ne $null))
                {
                    continue
                }
            }
            
            Write-Host "$index. $($issue.html_url) ## Created: $($issue.created_at) ## Closed: $($issue.closed_at)"
            $index++

            $resultToReturn += $issue
        }
    }

    return $resultToReturn
}

