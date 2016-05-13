<#
.Synopsis
   Tests for GitHubLabels.psm1 module
#>

if ($env:AppVeyor)
{
    $global:gitHubApiToken = $env:token
}

[String] $root = Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)
Import-Module (Join-Path -Path $root -ChildPath 'GitHubLabels.psm1') -Force

$script:gitHubAccountUrl = "https://github.com/gipstestaccount"
$script:accountName = "gipstestaccount"
$script:repositoryName = "TestRepository"
$script:repositoryUrl = "$script:gitHubAccountUrl/$script:repositoryName"
$script:expectedNumberOfLabels = 14

New-GitHubLabels -repositoryName $script:repositoryName -ownerName $script:accountName

Describe 'Getting labels from repository' {
    Context 'When querying for all labels' {
        $labels = Get-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName

        It 'Should return expected number of labels' {
            $($labels).Count | Should be $script:expectedNumberOfLabels
        }
    }

    Context 'When querying for specific label' {
        $label = Get-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName -labelName bug

        It 'Should return expected label' {
            $label.name | Should be "bug"
        }
    }
}

Describe 'Creating new label' {
    $labelName = "TestLabel"
    New-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName -labelName $labelName -labelColor BBBBBB
    $label = Get-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName -labelName $labelName

    AfterEach { 
        Remove-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName -labelName $labelName
    }

    It 'New label should be created' {
        $label.name | Should be $labelName
    }
}

Describe 'Removing label' {
    $labelName = "TestLabel"

    New-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName -labelName $labelName -labelColor BBBBBB
    $labels = Get-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName

    It 'Should return increased number of labels' {
        $($labels).Count | Should be ($script:expectedNumberOfLabels + 1)
    }

    Remove-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName -labelName $labelName
    $labels = Get-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName

    It 'Should return expected number of labels' {
        $($labels).Count | Should be $script:expectedNumberOfLabels
    }
}

Describe 'Updating label' {
    $labelName = "TestLabel"
    
    Context 'Updating label color' {
        New-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName -labelName $labelName -labelColor BBBBBB
        Update-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName -labelName $labelName -newLabelName $labelName -labelColor AAAAAA
        $label = Get-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName -labelName $labelName

        AfterEach { 
            Remove-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName -labelName $labelName
        }

        It 'Label should have different color' {
            $label.color | Should be AAAAAA
        }
    }
    
    Context 'Updating label name' {
        $newLabelName = $labelName + "2"
        New-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName -labelName $labelName -labelColor BBBBBB
        Update-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName -labelName $labelName -newLabelName $newLabelName -labelColor BBBBBB
        $label = Get-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName -labelName $newLabelName 

        AfterEach { 
            Remove-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName -labelName $newLabelName
        }

        It 'Label should have different color' {
            $label | Should not be $null
            $label.color | Should be BBBBBB
        }
    }
}

Describe 'Applying set of labels on repository' {
    $labelName = "TestLabel"

    New-GitHubLabels -repositoryName $script:repositoryName -ownerName $script:accountName

    # Add new label
    New-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName -labelName $labelName -labelColor BBBBBB
    $labels = Get-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName

    # Change color of existing label
    Update-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName -labelName "bug" -newLabelName "bug" -labelColor BBBBBB

    # Remove one of approved labels"
    Remove-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName -labelName "discussion"

    It 'Should return increased number of labels' {
        $($labels).Count | Should be ($script:expectedNumberOfLabels + 1)
    }

    New-GitHubLabels -repositoryName $script:repositoryName -ownerName $script:accountName
    $labels = Get-GitHubLabel -repositoryName $script:repositoryName -ownerName $script:accountName

    It 'Should return expected number of labels' {
        $($labels).Count | Should be $script:expectedNumberOfLabels
        $bugLabel = $labels | ?{$_.name -eq "bug"}
        $bugLabel.color | Should be "fc2929"
    }
}