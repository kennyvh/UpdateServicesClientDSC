$DSCModuleName   = 'UpdateServicesClientDSC'
$DSCResourceName = 'UpdateServicesClientDSC'

Import-Module "$((Get-Item -LiteralPath "$($PSScriptRoot)").Parent.Parent.FullName)\Misc\KVWindowsUpdate.psm1"

$configfile = Join-Path -Path $PSScriptRoot -ChildPath "$($DSCResourceName).config.ps1"
. $configfile

$workingFolder = "$env:temp\$DSCModuleName\$DSCResourceName"

try {
    Describe "$($DSCResourceName)_Integration" -Tag IntegrationTest {
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($DSCResourceName)_config -OutputPath `$workingFolder"
                Start-DscConfiguration -Path $workingFolder -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should not throw
        }

        It 'Should have set the resource and all the params should match' {
            $config = Get-DscConfiguration | Where-Object { $_.ConfigurationName -eq "$($DSCResourceName)_config" }
            $config.Ensure                 | Should Be $UpdateServicesClientDSC.Ensure
            $config.AutomaticUpdateEnabled | Should Be $UpdateServicesClientDSC.AutomaticUpdateEnabled
            $config.AutomaticUpdateOption  | Should Be $UpdateServicesClientDSC.AutomaticUpdateOption
            $config.UpdateServer           | Should Be $UpdateServicesClientDSC.UpdateServer
            $config.UpdateTargetGroup      | Should Be $UpdateServicesClientDSC.UpdateTargetGroup
        }
    }
}
finally
{
    Stop-DscConfiguration -Force
    Remove-DscConfigurationDocument -Stage Current
    Remove-DscConfigurationDocument -Stage Pending
    Remove-DscConfigurationDocument -Stage Previous
    Remove-AutomaticUpdate 
    Remove-UpdateOption
    Remove-UpdateServer
    Remove-UpdateTargetGroup
}



