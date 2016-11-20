configuration Sample_WindowsUpdateClient {
    Import-DscResource -ModuleName UpdateServicesClientDSC
    Node localhost {
        UpdateServicesClientDSC UpdateSettings {
            Ensure = 'Present'
            AutomaticUpdateEnabled = $true
            AutomaticUpdateOption = 'AutoDownloadAndNotifyForInstall'
            UpdateServer = 'https://wsus01.dscdomain.local:8530'
            UpdateTargetGroup = 'test'
        }
    }
}
Sample_WindowsUpdateClient -OutputPath C:\temp