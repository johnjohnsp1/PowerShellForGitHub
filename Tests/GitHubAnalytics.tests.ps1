<#
.Synopsis
   Tests for GitHubAnalytics.psm1 module
#>

[String] $root = Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

if ($env:AppVeyor)
{
    $global:gitHubApiToken = $env:token
    $message = 'This run is executed in the AppVeyor environment. 
GitHubApiToken won''t be decrypted in PR runs causing some tests to fail.
403 errors possible due to GitHub hourly limit for unauthenticated queries.
Define $global:gitHubApiToken manually and run tests on your machine first.'
    Write-Host $message -BackgroundColor Yellow -ForegroundColor Black
}

$apiTokensFilePath = "$root\ApiTokens.psm1"
if (Test-Path $apiTokensFilePath)
{
    Write-Host "Importing $apiTokensFilePath"
    Import-Module  -force $apiTokensFilePath
}
else
{
    Write-Host "$apiTokensFilePath does not exist, skipping import in tests"
}

$script:tokenExists = $true
if ($global:gitHubApiToken -eq $null)
{
    Write-Host "GitHubApiToken not defined, some of the tests will be skipped. `n403 errors possible due to GitHub hourly limit for unauthenticated queries." -BackgroundColor Yellow -ForegroundColor Black
    $script:tokenExists = $false
}
else
{
    Write-Host "GitHubApiToken has been defined in tests"
}

Import-Module (Join-Path -Path $root -ChildPath 'GitHubAnalytics.psm1') -Force

$script:gitHubAccountUrl = "https://github.com/gipstestaccount"
$script:organizationName = "GiPSTestOrg"
$script:organizationTeamName = "TestTeam1"
$script:repositoryName = "TestRepository"
$script:repository2Name = "TestRepository2"
$script:repositoryUrl = "$script:gitHubAccountUrl/$script:repositoryName"
$script:repositoryUrl2 = "$script:gitHubAccountUrl/$script:repository2Name"


Describe 'Obtaininig issues for repository' {
    Context 'When no addional conditions specified' {
        $issues = Get-GitHubIssueForRepository -repositoryUrl @($repositoryUrl)

        It 'Should return expected number of issues' {
            @($issues).Count | Should be 3
        }
    }
    
    Context 'When time range specified' {
        $issues = Get-GitHubIssueForRepository -repositoryUrl @($repositoryUrl) -createdOnOrAfter '2016-05-06' -createdOnOrBefore '2016-05-08'

        It 'Should return expected number of issues' {
            @($issues).Count | Should be 3
        }
    }
    
    Context 'When state and time range specified' {
        $issues = Get-GitHubIssueForRepository -repositoryUrl @($repositoryUrl) -createdOnOrAfter '2016-04-01' -state closed

        It 'Should return expected number of issues' {
            @($issues).Count | Should be 2
        }
    }
}

Describe 'Obtaininig repository with biggest number of issues' {
    Context 'When no addional conditions specified' {
        $issues = Get-GitHubTopIssueRepository -repositoryUrl @($script:repositoryUrl,$script:repositoryUrl2)

        It 'Should return expected number of issues for each repository' {
            @($issues[0].Value) | Should be 3
            @($issues[1].Value) | Should be 0
        }
        
        It 'Should return expected repository names' {
            @($issues[0].Name) | Should be $script:repositoryName
            @($issues[1].Name) | Should be $script:repository2Name
        }
    }
}

Describe 'Obtaininig pull requests for repository' {
    Context 'When no addional conditions specified' {
        $pullRequests = Get-GitHubPullRequestForRepository -repositoryUrl @($script:repositoryUrl)

        It 'Should return expected number of PRs' {
            @($pullRequests).Count | Should be 2
        }
    }
    
    Context 'When state and time range specified' {
        $pullRequests = Get-GitHubPullRequestForRepository `
            -repositoryUrl @($script:repositoryUrl) `
            -state closed -mergedOnOrAfter 2016-04-10 -mergedOnOrBefore 2016-05-07

        It 'Should return expected number of PRs' {
            @($pullRequests).Count | Should be 3
        }
    }
}

Describe 'Obtaininig repository with biggest number of pull requests' {
    Context 'When no addional conditions specified' {
        $pullRequests = Get-GitHubTopPullRequestRepository -repositoryUrl @($script:repositoryUrl,$script:repositoryUrl2)

        It 'Should return expected number of pull requests for each repository' {
            @($pullRequests[0].Value) | Should be 2
            @($pullRequests[1].Value) | Should be 0
        }
        
        It 'Should return expected repository names' {
            @($pullRequests[0].Name) | Should be $script:repositoryName
            @($pullRequests[1].Name) | Should be $script:repository2Name
        }
    }
    
    Context 'When state and time range specified' {
        $pullRequests = Get-GitHubTopPullRequestRepository -repositoryUrl @($script:repositoryUrl,$script:repositoryUrl2) -state closed -mergedOnOrAfter 2015-04-20
        
        It 'Should return expected number of pull requests for each repository' {
            @($pullRequests[0].Value) | Should be 3
            @($pullRequests[1].Value) | Should be 0
        }
        
        It 'Should return expected repository names' {
            @($pullRequests[0].Name) | Should be $script:repositoryName
            @($pullRequests[1].Name) | Should be $script:repository2Name
        }
    }
}

if ($script:tokenExists)
{
    Describe 'Obtaininig collaborators for repository' {
        $collaborators = Get-GitHubRepositoryCollaborator -repositoryUrl @($script:repositoryUrl)

        It 'Should return expected number of collaborators' {
            @($collaborators).Count | Should be 1
        }    
    }
}

Describe 'Obtaininig contributors for repository' {
    $contributors = Get-GitHubRepositoryContributor -repositoryUrl @($script:repositoryUrl)

    It 'Should return expected number of contributors' {
        @($contributors).Count | Should be 1
    }
}

if ($script:tokenExists)
{
    Describe 'Obtaininig organization members' {
        $members = Get-GitHubOrganizationMember -organizationName $script:organizationName

        It 'Should return expected number of organization members' {
            @($members).Count | Should be 1
        }
    }

    Describe 'Obtaininig organization teams' {
        $teams = Get-GitHubTeam -organizationName $script:organizationName

        It 'Should return expected number of organization teams' {
            @($teams).Count | Should be 2
        }
    }

    Describe 'Obtaininig organization team members' {
        $members = Get-GitHubTeamMember -organizationName $script:organizationName -teamName $script:organizationTeamName

        It 'Should return expected number of organization team members' {
            @($members).Count | Should be 1
        }
    }
}

Describe 'Getting repositories from organization' {
    $repositories = Get-GitHubOrganizationRepository -organization $script:organizationName

    It 'Should return expected number of organization repositories' {
        @($repositories).Count | Should be 2
    }
}

Describe 'Getting unique contributors from contributors array' {
    $contributors = Get-GitHubRepositoryContributor -repositoryUrl @($script:repositoryUrl)
    $uniqueContributors = Get-GitHubRepositoryUniqueContributor -contributors $contributors

    It 'Should return expected number of unique contributors' {
        @($uniqueContributors).Count | Should be 1
    }
}

Describe 'Getting repository name from url' {
    $name = Get-GitHubRepositoryNameFromUrl -repositoryUrl "https://github.com/KarolKaczmarek/TestRepository"

    It 'Should return expected repository name' {
        $name | Should be "TestRepository"
    }
}

Describe 'Getting repository owner from url' {
    $owner = Get-GitHubRepositoryOwnerFromUrl -repositoryUrl "https://github.com/KarolKaczmarek/TestRepository"

    It 'Should return expected repository owner' {
        $owner | Should be "KarolKaczmarek"
    }
}
