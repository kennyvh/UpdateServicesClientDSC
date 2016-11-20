# UpdateServicesClientDSC
This Resource Module can be used to configure Windows Update Client settings. It's primary use case is non domain-joined computers and Nano Server. Althought it can also be used for domain-joined computers.

The project adopted the MIT license.

## Installation
To install the UpdateServicesClientDSC Module:
* You can download this repository and unzip the content under c:\Program Files\WindowsPowerShell\Modules
* In PowerShell: ```Install-Module UpdateServicesClientDSC```

## Resources
* **UpdateServicesClientDSC**: used to configure windows update client settings.

* **`[String]` Ensure** _(Write)_: Specify if the settings must be applied or not. { *Present* | Absent }. The Default is Present.
* **`[Bool]` AutomaticUpdateEnabled** _(Key)_: Speficy if Automatic Update must be enabled or not.
* **`[String]` AutomaticUpdateOption** _(Write)_: Specify the update option. { NotifyBeforeDownload | AutoDownloadAndNotifyForInstall | AutoDownloadAndScheduleInstallation | UsersCanConfigureAutomaticUpdates }
* **`[String]` UpdateServer** _(Write)_: Specify the URL of the WSUS server.
* **`[String]` UpdateTargetGroup** _(Write)_: Specify the target group that the computer must belong to. (This is configured in the WSUS server).
* **`[String]` ScheduledInstallDay** _(Write)_: Specify the day of the week that the computer is allowed to install updates. { Monday | Tuesday | Wednesday | Thursday | Friday | Saturday | Sunday }
* **`[UInt32]` ScheduledInstallHour** _(Write)_: Specify the hour of the day that the computer is allowed to install updates.

## Versions

### Unreleased

### 1.0.0.0
* Initial release of UpdateServicesClientDSC

## Examples

### Example UpdateServicesClientDSC

This configuration will configure the Windows Update settings.

```powershell
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
Start-DSCConfiguration -Path C:\temp -Wait -Force -Verbose
```
