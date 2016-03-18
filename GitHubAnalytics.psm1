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

<#
    .SYNOPSIS Function which returns number of issues created/merged in every week in specific repositories
    .PARAM
        repositoryUrl Array of repository urls which we want to get pull requests from
    .PARAM 
        numberOfWeeks How many weeks we want to obtain data for
    .PARAM 
        dataType Whether we want to get information about created or merged issues in specific weeks
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        Get-GitHubWeeklyIssuesForRepository -repositoryUrl @('https://github.com/powershell/xpsdesiredstateconfiguration', 'https://github.com/powershell/xactivedirectory') -datatype closed

#>
function Get-GitHubWeeklyIssuesForRepository
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $repositoryUrl,
        [int] $numberOfWeeks = 12,
        [Parameter(Mandatory=$true)]
        [ValidateSet("created","closed")]
        [string] $dataType,
        $gitHubAccessToken = $script:gitHubToken
    )

    $weekDates = Get-WeekDates -numberOfWeeks $numberOfWeeks
    $endOfWeek = Get-Date
    $results = @()
    $totalIssues = 0

    foreach ($week in $weekDates)
    {
        Write-Host "Getting issues from week of $week"

        $issues = $null

        if ($dataType -eq "closed")
        {
            $issues = Get-GitHubIssuesForRepository `
            -repositoryUrl $repositoryUrl -state 'all' -closedOnOrAfter $week -closedOnOrBefore $endOfWeek    
        }
        elseif ($dataType -eq "created")
        {
            $issues = Get-GitHubIssuesForRepository `
            -repositoryUrl $repositoryUrl -state 'all' -createdOnOrAfter $week -createdOnOrBefore $endOfWeek
        }
        
        $endOfWeek = $week
        
        if (($issues -ne $null) -and ($issues.Count -eq $null))
        {
            $count = 1
        }
        else
        {
            $count = $issues.Count
        }
        
        $totalIssues += $count

        $results += @{"BeginningOfWeek"=$week; "Issues"=$count}
    }

    $results += @{"BeginningOfWeek"="total"; "Issues"=$totalIssues}
    return $results    
}

<#
    .SYNOPSIS Function which returns repositories with biggest number of issues meeting specified criteria
    .PARAM
        repositoryUrl Array of repository urls which we want to get issues from
    .PARAM 
        state Whether we want to get information about open issues, closed or both
    .PARAM
        createdOnOrAfter Get information about issues created after specific date
    .PARAM
        closedOnOrAfter Get information about issues closed after specific date
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        Get-GitHubTopIssuesRepository -repositoryUrl @('https://github.com/powershell/xsharepoint', 'https://github.com/powershell/xCertificate', 'https://github.com/powershell/xwebadministration') -state open

#>
function Get-GitHubTopIssuesRepository
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $repositoryUrl,
        [ValidateSet("open", "closed", "all")]
        [String] $state = "open",
        [DateTime] $createdOnOrAfter,
        [DateTime] $closedOnOrAfter,
        $gitHubAccessToken = $script:gitHubToken
    )
    
    if (($state -eq "open") -and ($closedOnOrAfter -ne $null))
    {
        Throw "closedOnOrAfter cannot be specified if state is open"
    }

    $repositoryIssues = @{}

    foreach ($repository in $repositoryUrl)
    {
        if (($closedOnOrAfter -ne $null) -and ($createdOnOrAfter -ne $null))
        {
            $issues = Get-GitHubIssuesForRepository `
            -repositoryUrl $repository `
            -state $state -closedOnOrAfter $closedOnOrAfter -createdOnOrAfter $createdOnOrAfter
        }
        elseif (($closedOnOrAfter -ne $null) -and ($createdOnOrAfter -eq $null))
        {
            $issues = Get-GitHubIssuesForRepository `
            -repositoryUrl $repository `
            -state $state -closedOnOrAfter $closedOnOrAfter
        }
        elseif (($closedOnOrAfter -eq $null) -and ($createdOnOrAfter -ne $null))
        {
            $issues = Get-GitHubIssuesForRepository `
            -repositoryUrl $repository `
            -state $state -createdOnOrAfter $createdOnOrAfter
        }
        elseif (($closedOnOrAfter -eq $null) -and ($createdOnOrAfter -eq $null))
        {
            $issues = Get-GitHubIssuesForRepository `
            -repositoryUrl $repository `
            -state $state
        }

        if (($issues -ne $null) -and ($issues.Count -eq $null))
        {
            $count = 1
        }
        else
        {
            $count = $issues.Count
        }

        $repositoryName = Get-GitHubRepositoryNameFromUrl -repositoryUrl $repository
        $repositoryIssues.Add($repositoryName, $count)
    }

    $repositoryIssues = $repositoryIssues.GetEnumerator() | Sort-Object Value -Descending

    return $repositoryIssues
}