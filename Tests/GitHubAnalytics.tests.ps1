<#
.Synopsis
   Tests for GitHubAnalytics.psm1 module
#>

# TODO If appveyor build, get GitHubApi token from AppVeyor variable, otherwise - check for ApiTokens.psm1 file

[String] $root = Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'GitHubAnalytics.psm1') -Force


