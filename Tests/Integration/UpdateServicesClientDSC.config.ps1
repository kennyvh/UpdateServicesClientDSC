$UpdateServicesClientDSC = [PSObject]@{
    Ensure                 = 'Present'
    AutomaticUpdateEnabled = $true
    AutomaticUpdateOption  = 'AutoDownloadAndNotifyForInstall'
    UpdateServer           = 'https://wsus01.dscdomain.local:8530'
    UpdateTargetGroup      = 'test'
}

configuration UpdateServicesClientDSC_Config {
    Import-DscResource -ModuleName UpdateServicesClientDSC
    node localhost {
        UpdateServicesClientDSC Integration_Test {
            Ensure                 = $UpdateServicesClientDSC.Ensure
            AutomaticUpdateEnabled = $UpdateServicesClientDSC.AutomaticUpdateEnabled
            AutomaticUpdateOption  = $UpdateServicesClientDSC.AutomaticUpdateOption
            UpdateServer           = $UpdateServicesClientDSC.UpdateServer
            UpdateTargetGroup      = $UpdateServicesClientDSC.UpdateTargetGroup
        }
    }
}
