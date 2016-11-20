$DSCResourceName = 'UpdateServicesClientDSC'

$root = (Resolve-Path $PSScriptRoot\..\..).Path

Import-Module (Join-Path $root "DSCResources\$DSCResourceName\$DSCResourceName.psm1") -Force

InModuleScope $DSCResourceName {
    Describe "$DSCResourceName\Get-TargetResource" -Tag UnitTest {
        Mock Get-AutomaticUpdate
        Mock Get-UpdateOption
        Mock Get-UpdateServer
        Mock Get-UpdateTargetGroup
        Mock Get-UpdateScheduledInstallDay
        Mock Get-UpdateScheduledInstallHour

        Context 'Invoking Get-TargetResource' {
            It 'Should return Ensure = Present and is a hashtable' {
                $props = @{
                    Ensure = 'Present'
                    AutomaticUpdateEnabled = $true
                }
                $Result = Get-TargetResource @props 
                $Result.Ensure | Should Be $props.Ensure
                $Result -is [System.Collections.Hashtable] | Should Be $true
            }

            It 'Should call all the mocks' {
                Assert-MockCalled -CommandName Get-AutomaticUpdate -Exactly 1
                Assert-MockCalled -CommandName Get-UpdateOption -Exactly 1
                Assert-MockCalled -CommandName Get-UpdateServer -Exactly 1
                Assert-MockCalled -CommandName Get-UpdateTargetGroup -Exactly 1
                Assert-MockCalled -CommandName Get-UpdateScheduledInstallDay -Exactly 1
                Assert-MockCalled -CommandName Get-UpdateScheduledInstallHour -Exactly 1
            }
        }
    }

    Describe "$DSCResourceName\Set-TargetResource" -Tag UnitTest {
        Mock Get-TargetResource -MockWith {
            [PSCustomObject]@{
                Ensure                 = 'Present'
                AutomaticUpdateEnabled = $true
                AutomaticUpdateOption  = 'NotifyBeforeDownload'
                UpdateServer           = 'https://wsus01.testdomain.local:8530'
                UpdateTargetGroup      = 'test'
            }
        }

        Mock Set-AutomaticUpdate -MockWith {
            [PSCustomObject]@{
                Enabled = $true
            }
        }

        Mock Remove-AutomaticUpdate

        Mock Set-UpdateOption -MockWith {
            [PSCustomObject]@{
                Setting = 'AutoDownloadAndNotifyForInstall'
            }
        }

        Mock Remove-UpdateOption

        Mock Set-UpdateServer -MockWith {
            [PSCustomObject]@{
                Enabled = $true
                URL = 'https://wsus01:8530'
            }
        }

        Mock Remove-UpdateServer

        Mock Set-UpdateTargetGroup -MockWith {
            [PSCustomObject]@{
                Name = 'test'
            }
        }

        Mock Remove-UpdateTargetGroup

        Context 'invoking Set-TargetResource' {
            It 'Should return $null' {
                $props = @{
                    Ensure                 = 'Present'
                    AutomaticUpdateEnabled = $true
                    AutomaticUpdateOption  = 'AutoDownloadAndNotifyForInstall'
                    UpdateServer           = 'https://wsus01:8530'
                    UpdateTargetGroup      = 'test'
                }
                { $Result = Set-TargetResource @props } | Should Not Throw
                $Result | Should BeNullOrEmpty
            }

            It 'Should call mock: Get-TargetResource' {
                Assert-MockCalled -CommandName Get-TargetResource -Exactly 1
            }
            It 'Should call mock: Set-UpdateOption' {
                Assert-MockCalled -CommandName Set-UpdateOption -Exactly 1
            }
            It 'Should call mock: Set-UpdateServer' {
                Assert-MockCalled -CommandName Set-UpdateServer -Exactly 1
            }
            It 'Should not call all the other mocks' {
                Assert-MockCalled -CommandName Set-AutomaticUpdate -Exactly 0
                Assert-MockCalled -CommandName Remove-AutomaticUpdate -Exactly 0
                Assert-MockCalled -CommandName Remove-UpdateOption -Exactly 0
                Assert-MockCalled -CommandName Remove-UpdateServer -Exactly 0
                Assert-MockCalled -CommandName Set-UpdateTargetGroup -Exactly 0
                Assert-MockCalled -CommandName Remove-UpdateTargetGroup -Exactly 0
            }
        }
    }

    Describe "$DSCResourceName\Test-TargetResource" -Tag UnitTest {
        Mock Get-TargetResource -MockWith {
            [PSCustomObject]@{
                Ensure                 = 'Present'
                AutomaticUpdateEnabled = $true
                AutomaticUpdateOption  = 'NotifyBeforeDownload'
                UpdateServer           = 'https://wsus01.testdomain.local:8530'
                UpdateTargetGroup      = 'test'
                ScheduledInstallDay    = 'Friday'
                ScheduledInstallHour   = '1'
            }
        }
        
        Context 'invoking Test-TargetResource with same settings' {
            It 'Should return $true' {
                $testprops = @{
                    Ensure                 = 'Present'
                    AutomaticUpdateEnabled = $true
                    AutomaticUpdateOption  = 'NotifyBeforeDownload'
                    UpdateServer           = 'https://wsus01.testdomain.local:8530'
                    UpdateTargetGroup      = 'test'
                    ScheduledInstallDay    = 'Friday'
                    ScheduledInstallHour   = '01'
                }

                $Result = Test-TargetResource @testprops
                $Result | Should Be $true
            }
            It 'Should call Get-TargetResource 1 time' {
                Assert-MockCalled -CommandName Get-TargetResource -Exactly 1
            }
        }

        Context 'invoking Test-TargetResource with different UpdateServer' {
            It 'Should return $false' {
                $properties = @{
                    Ensure                 = 'Present'
                    AutomaticUpdateEnabled = $true
                    AutomaticUpdateOption  = 'NotifyBeforeDownload'
                    UpdateServer           = 'https://wsus02:8530'
                    UpdateTargetGroup      = 'test'
                    ScheduledInstallDay    = 'Friday'
                    ScheduledInstallHour   = '01'
                }

                $Result = Test-TargetResource @properties
                $Result | Should Be $false
            }
            It 'Should call Get-TargetResource 1 time' {
                Assert-MockCalled -CommandName Get-TargetResource -Exactly 1
            }
        }
    }
}