# GitHubKit

PowerShell wrapper for GitHub API.

Currently contains GitHubAnalytics and GitHubLabels


## Examples

### Querying issues

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

### Querying pull requests

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

### Querying collaborators

```powershell
$collaborators = Get-GitHubRepositoryCollaborators`
-repositoryUrl @('https://github.com/PowerShell/DscResources')
```

### Querying contributors

```powershell
$contributors = Get-GitHubRepositoryContributors`
-repositoryUrl @('https://github.com/PowerShell/DscResources', 'https://github.com/PowerShell/xWebAdministration')
```

```powershell
$contributors = Get-GitHubRepositoryContributors`
-repositoryUrl @('https://github.com/PowerShell/DscResources','https://github.com/PowerShell/xWebAdministration')

$uniqueContributors = Get-GitHubRepositoryUniqueContributors -contributors $contributors
```

### Quering teams / organization membership

Here is how you can make sure that everybody in the org has an appropriate team assignment:
```powershell
$members = Get-GitHubOrganizationMembers -organizationName 'PowerShell'
$everyone = Get-GitHubTeamMembers -organizationName 'PowerShell' -teamName Everyone
$linux = Get-GitHubTeamMembers -organizationName 'PowerShell'-teamName 'Linux'
$linuxguests = Get-GitHubTeamMembers -organizationName 'PowerShell' -teamName 'Linux Guests'
compare-object ($everyone.login + $linux.login + $linuxguests.login | sort | unique) $members.login
```
If compare outputs somebody, this user needs attention and probably assignment.

