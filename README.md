# GiPS
[![Build status](https://ci.appveyor.com/api/projects/status/x4g36pbltk67l0n5?svg=true)](https://ci.appveyor.com/project/PowerShell/gips)

PowerShell wrapper for GitHub API.

## Usage
1) Rename ApiTokensTemplate.psm1 to ApiTokens.psm1 and update value of $global:gitHubApiToken with GitHub token for your account
  * You can obtain it from https://github.com/settings/tokens). 
  * If you don't provide GitHub token, you can still use this module, but you will be limited to 60 queries per hour. 
 
2) Import module you want to use and call it's function, e.g.

 ```powershell
Import-Module .\GitHubAnalytics.psm1
$issues = Get-GitHubIssuesForRepository -repositoryUrl @('https://github.com/PowerShell/GitHubKit')
```


## Runnig tests
1) Install [Pester](http://www.powershellgallery.com/packages/Pester/3.4.0) 

```powershell
Install-Module -Name Pester 
```

2) Start test pass

```powershell
Invoke-Pester
```


## Examples

### GitHubAnalytics

#### Querying issues

```powershell
$issues = Get-GitHubIssuesForRepository `
-repositoryUrl @('https://github.com/PowerShell/xPSDesiredStateConfiguration')
```

```powershell
$issues = Get-GitHubWeeklyIssuesForRepository `
-repositoryUrl @('https://github.com/powershell/xpsdesiredstateconfiguration',`
'https://github.com/powershell/xactivedirectory') -datatype closed
```

```powershell
$issues = Get-GitHubTopIssuesRepository `
-repositoryUrl @('https://github.com/powershell/xsharepoint',`
'https://github.com/powershell/xCertificate', 'https://github.com/powershell/xwebadministration') -state open
```

#### Querying pull requests

```powershell
$pullRequests = Get-GitHubPullRequestsForRepository `
-repositoryUrl @('https://github.com/PowerShell/xPSDesiredStateConfiguration')
```

```powershell
$pullRequests = Get-GitHubWeeklyPullRequestsForRepository `
-repositoryUrl @('https://github.com/powershell/xpsdesiredstateconfiguration',`
'https://github.com/powershell/xwebadministration') -datatype merged
```

```powershell
$pullRequests = Get-GitHubTopPullRequestsRepository `
-repositoryUrl @('https://github.com/powershell/xsharepoint', 'https://github.com/powershell/xwebadministration')`
-state closed -mergedOnOrAfter 2015-04-20
```

#### Querying collaborators

```powershell
$collaborators = Get-GitHubRepositoryCollaborators`
-repositoryUrl @('https://github.com/PowerShell/DscResources')
```

#### Querying contributors

```powershell
$contributors = Get-GitHubRepositoryContributors`
-repositoryUrl @('https://github.com/PowerShell/DscResources', 'https://github.com/PowerShell/xWebAdministration')
```

```powershell
$contributors = Get-GitHubRepositoryContributors`
-repositoryUrl @('https://github.com/PowerShell/DscResources','https://github.com/PowerShell/xWebAdministration')

$uniqueContributors = Get-GitHubRepositoryUniqueContributors -contributors $contributors
```

#### Quering teams / organization membership

Here is how you can make sure that everybody in the org has an appropriate team assignment:
```powershell
$members = Get-GitHubOrganizationMembers -organizationName 'PowerShell'
$everyone = Get-GitHubTeamMembers -organizationName 'PowerShell' -teamName Everyone
$linux = Get-GitHubTeamMembers -organizationName 'PowerShell'-teamName 'Linux'
$linuxguests = Get-GitHubTeamMembers -organizationName 'PowerShell' -teamName 'Linux Guests'
compare-object ($everyone.login + $linux.login + $linuxguests.login | sort | unique) $members.login
```
If compare outputs somebody, this user needs attention and probably assignment.

### GitHubLabels

#### Getting labels for given repository
```powershell
$labels = Get-GitHubLabel -repositoryName DesiredStateConfiguration -ownerName Powershell
```

#### Adding new label to the repository
```powershell
New-GitHubLabel -repositoryName DesiredStateConfiguration -ownerName PowerShell -labelName TestLabel -labelColor BBBBBB
```

#### Removing specific label from the repository
```powershell
Remove-GitHubLabel -repositoryName desiredstateconfiguration -ownerName powershell -labelName TestLabel
```

#### Updating specific label with new name and color
```powershell
Update-GitHubLabel -repositoryName DesiredStateConfiguration -ownerName Powershell -labelName TestLabel -newLabelName NewTestLabel -labelColor BBBB00
```
