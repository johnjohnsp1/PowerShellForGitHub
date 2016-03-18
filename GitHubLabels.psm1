<#
    .SYNOPSIS PowerShell module for GitHub labels
#>

# Import module which defines $global:gitHubApiToken with your GitHub API access token. Create this file it if it doesn't exist.
# You can get GitHub token from https://github.com/settings/tokens
# If you don't provide it, you can still use this module, but you will be limited to 60 queries per hour.
$apiTokensFilePath = "$PSScriptRoot\ApiTokens.psm1"
if (Test-Path $apiTokensFilePath)
{
    Write-Host "Importing $apiTokensFilePath"
    Import-Module  -force $apiTokensFilePath
}
else
{
    Write-Host "$apiTokensFilePath does not exist, skipping import"
}

$script:gitHubToken = $global:gitHubApiToken
$script:gitHubApiUrl = "https://api.github.com"
$script:gitHubApiReposUrl = "https://api.github.com/repos"