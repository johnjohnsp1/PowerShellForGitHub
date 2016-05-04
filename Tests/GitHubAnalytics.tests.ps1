<#
.Synopsis
   Tests for GitHubAnalytics.psm1 module
#>

# TODO If appveyor build, get GitHubApi token from AppVeyor variable and store it in $script:gitHubToken, otherwise - check for ApiTokens.psm1 file (this will be automatically done when importing GitHubAnalytics.psm1/GitHubLabels.psm1)
# TODO After importing GitHubAnalytics/GitHubLabels.psm1 we should check if we run on appveyor and $global:gitHubToken (currently in $script scope, but change it) is empty. if it is, obtain token from appveyor 

[String] $root = Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)
Import-Module (Join-Path -Path $root -ChildPath 'GitHubAnalytics.psm1') -Force

$script:gitHubAccountUrl = "https://github.com/KarolKaczmarek"
$script:organizationName = "GitHubOrgTest"
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
        $issues = Get-GitHubIssuesForRepository -repositoryUrl @($repositoryUrl) -createdOnOrAfter '2016-04-10'

        It 'Should return expected number of issues' {
            @($issues).Count | Should be 2
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
            @($issues[1].Value) | Should be 2
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
            -state closed -mergedOnOrAfter 2016-04-10 -mergedOnOrBefore 2016-04-23

        It 'Should return expected number of PRs' {
            @($pullRequests).Count | Should be 2
        }
    }
}

Describe 'Obtaininig repository with biggest number of pull requests' {
    Context 'When no addional conditions specified' {
        $pullRequests = Get-GitHubTopPullRequestsRepository -repositoryUrl @($script:repositoryUrl,$script:repositoryUrl2)

        It 'Should return expected number of pull requests for each repository' {
            @($pullRequests[0].Value) | Should be 2
            @($pullRequests[1].Value) | Should be 1
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
        @($teams).Count | Should be 3
    }
}

Describe 'Obtaininig organization team members' {
    $members = Get-GitHubTeamMembers -organizationName $script:organizationName -teamName $script:organizationTeamName

    It 'Should return expected number of organization team members' {
        @($members).Count | Should be 1
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



