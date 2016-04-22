<#
.Synopsis
   Tests for GitHubAnalytics.psm1 module
#>

# TODO If appveyor build, get GitHubApi token from AppVeyor variable, otherwise - check for ApiTokens.psm1 file

[String] $root = Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)
Import-Module (Join-Path -Path $root -ChildPath 'GitHubAnalytics.psm1') -Force

$script:repositoryUrl = "https://github.com/KarolKaczmarek/TestRepository"

Describe 'Obtaininig issues for repository' {
    Context 'When no addional conditions specified' {
        $issues = Get-GitHubIssuesForRepository -repositoryUrl @($repositoryUrl)

        It 'Should return expected number of issues' {
            @($issues).Count | Should be 3
        }
    }
    
    Context 'When state and time range specified' {
        $issues = Get-GitHubIssuesForRepository `
            -repositoryUrl @($repositoryUrl) `
            -createdOnOrAfter '2016-04-10'

        It 'Should return expected number of issues' {
            @($issues).Count | Should be 1
        }
    }
}

Describe 'Obtaininig pull requests for repository' {
    Context 'When no addional conditions specified' {
        $pullRequests = Get-GitHubPullRequestsForRepository -repositoryUrl @($script:repositoryUrl)

        It 'Should return expected number of PRs' {
            @($pullRequests).Count | Should be 1
        }
    }
    
    Context 'When state and time range specified' {
        $pullRequests = Get-GitHubPullRequestsForRepository `
            -repositoryUrl @($script:repositoryUrl) `
            -state closed -mergedOnOrAfter 2016-04-10 -mergedOnOrBefore 2016-04-23

        It 'Should return expected number of PRs' {
            @($pullRequests).Count | Should be 2
        }
    }
}