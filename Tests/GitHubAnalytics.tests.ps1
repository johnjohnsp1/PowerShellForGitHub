<#
.Synopsis
   Tests for GitHubAnalytics.psm1 module
#>

if ($env:AppVeyor)
{
    $global:gitHubApiToken = $env:token
}

[String] $root = Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)
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
        $issues = Get-GitHubIssuesForRepository -repositoryUrl @($repositoryUrl)

        It 'Should return expected number of issues' {
            @($issues).Count | Should be 3
        }
    }
    
    Context 'When time range specified' {
        $issues = Get-GitHubIssuesForRepository -repositoryUrl @($repositoryUrl) -createdOnOrAfter '2016-05-06' -createdOnOrBefore '2016-05-08'

        It 'Should return expected number of issues' {
            @($issues).Count | Should be 3
        }
    }
    
    Context 'When state and time range specified' {
        $issues = Get-GitHubIssuesForRepository -repositoryUrl @($repositoryUrl) -createdOnOrAfter '2016-04-01' -state closed

        It 'Should return expected number of issues' {
            @($issues).Count | Should be 2
        }
    }
}

Describe 'Obtaininig repository with biggest number of issues' {
    Context 'When no addional conditions specified' {
        $issues = Get-GitHubTopIssuesRepository -repositoryUrl @($script:repositoryUrl,$script:repositoryUrl2)

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
        $pullRequests = Get-GitHubPullRequestsForRepository -repositoryUrl @($script:repositoryUrl)

        It 'Should return expected number of PRs' {
            @($pullRequests).Count | Should be 2
        }
    }
    
    Context 'When state and time range specified' {
        $pullRequests = Get-GitHubPullRequestsForRepository `
            -repositoryUrl @($script:repositoryUrl) `
            -state closed -mergedOnOrAfter 2016-04-10 -mergedOnOrBefore 2016-05-07

        It 'Should return expected number of PRs' {
            @($pullRequests).Count | Should be 3
        }
    }
}

Describe 'Obtaininig repository with biggest number of pull requests' {
    Context 'When no addional conditions specified' {
        $pullRequests = Get-GitHubTopPullRequestsRepository -repositoryUrl @($script:repositoryUrl,$script:repositoryUrl2)

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
        $pullRequests = Get-GitHubTopPullRequestsRepository -repositoryUrl @($script:repositoryUrl,$script:repositoryUrl2) -state closed -mergedOnOrAfter 2015-04-20
        
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

Describe 'Obtaininig collaborators for repository' {
    $collaborators = Get-GitHubRepositoryCollaborators -repositoryUrl @($script:repositoryUrl)

    It 'Should return expected number of collaborators' {
        @($collaborators).Count | Should be 1
    }    
}

Describe 'Obtaininig contributors for repository' {
    $contributors = Get-GitHubRepositoryContributors -repositoryUrl @($script:repositoryUrl)

    It 'Should return expected number of contributors' {
        @($contributors).Count | Should be 1
    }
}

Describe 'Obtaininig organization members' {
    $members = Get-GitHubOrganizationMembers -organizationName $script:organizationName

    It 'Should return expected number of organization members' {
        @($members).Count | Should be 1
    }
}

Describe 'Obtaininig organization teams' {
    $teams = Get-GitHubTeams -organizationName $script:organizationName

    It 'Should return expected number of organization teams' {
        @($teams).Count | Should be 2
    }
}

Describe 'Obtaininig organization team members' {
    $members = Get-GitHubTeamMembers -organizationName $script:organizationName -teamName $script:organizationTeamName

    It 'Should return expected number of organization team members' {
        @($members).Count | Should be 1
    }
}

Describe 'Getting repositories from organization' {
    $repositories = Get-GitHubOrganizationRepository -organization $script:organizationName

    It 'Should return expected number of organization repositories' {
        @($repositories).Count | Should be 2
    }
}

Describe 'Getting unique contributors from contributors array' {
    $contributors = Get-GitHubRepositoryContributors -repositoryUrl @($script:repositoryUrl)
    $uniqueContributors = Get-GitHubRepositoryUniqueContributors -contributors $contributors

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