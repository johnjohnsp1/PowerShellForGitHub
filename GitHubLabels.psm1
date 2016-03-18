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

<#
    .SYNOPSIS Function to get single or all labels of given repository
    .PARAM
        repositoryName Name of the repository
    .PARAM 
        ownerName Owner of the repository
    .PARAM
        labelName Name of the label to get. Function will return all labels for given repository if labelName is not specified.
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        Get-GitHubLabel -repositoryName DesiredStateConfiguration -ownerName Powershell -labelName TestLabel
        Get-GitHubLabel -repositoryName DesiredStateConfiguration -ownerName Powershell
#>
function Get-GitHubLabel 
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$repositoryName,
        [Parameter(Mandatory=$true)]
        [string]$ownerName,
        [string]$labelName, 
        [string]$gitHubAccessToken = $script:gitHubToken
        )
        
        $headers = @{"Authorization"="token $gitHubAccessToken"}
        
        if ($labelName -eq "")
        {
            $url = "$script:gitHubApiReposUrl/{0}/{1}/labels" -f $ownerName, $repositoryName    
            Write-Host "Getting all labels for repository $repositoryName"
            $result = Invoke-WebRequest $url -Method Get -Headers $headers
            
            if ($result.StatusCode -ne 200) 
            {
                Write-Error "Couldn't obtain labels. Result: $result"
                return
            } 
            Write-Host "Got all labels"
        }
        else 
        {
            $url = "$script:gitHubApiReposUrl/{0}/{1}/labels/{2}" -f $ownerName, $repositoryName, $labelName
            Write-Host "Getting label $labelName for repository $repositoryName"
            $result = Invoke-WebRequest $url -Method Get -Headers $headers
            
            if ($result.StatusCode -ne 200) 
            {
                Write-Error "Couldn't obtain label $labelName. Result: $result"
                return
            } 
            Write-Host "Got label $labelName"
        }
        
        $labels = ConvertFrom-Json -InputObject $result.content
        return $labels
}

<#
    .SYNOPSIS Function to create label in given repository
    .PARAM
        repositoryName Name of the repository
    .PARAM 
        ownerName Owner of the repository
    .PARAM
        labelName Name of the label to create
    .PARAM
        gitHubAccessToken GitHub API Access Token.
            Get github token from https://github.com/settings/tokens 
            If you don't provide it, you can still use this script, but you will be limited to 60 queries per hour.
    .EXAMPLE
        New-GitHubLabel -repositoryName DesiredStateConfiguration -ownerName PowerShell -labelName TestLabel -labelColor BBBBBB
#>
function New-GitHubLabel 
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$repositoryName,
        [Parameter(Mandatory=$true)]
        [string]$ownerName,
        [Parameter(Mandatory=$true)]
        [string]$labelName, 
        [string]$labelColor = "EEEEEE",
        [string]$gitHubAccessToken = $script:gitHubToken
        )
        
        $headers = @{"Authorization"="token $gitHubAccessToken"}
        $hashTable = @{"name"=$labelName; "color"=$labelColor}
        $data = $hashTable | ConvertTo-Json
        $url = "$script:gitHubApiReposUrl/{0}/{1}/labels" -f $ownerName, $repositoryName
        
        Write-Host "Creating Label:" $labelName
        $result = Invoke-WebRequest $url -Method Post -Body $data -Headers $headers
        
        if ($result.StatusCode -eq 201) 
        {
            Write-Host $labelName "was created"
        } 
        else 
        {
            Write-Error $labelName "was not created. Result: $result"
        }      
}