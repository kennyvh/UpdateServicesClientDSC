$regPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
$regPathAU = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
if (-not (Test-Path -path $regPath)) {
    New-Item $regPath -ItemType Directory
}
if (-not (Test-Path -path $regPathAU)) {
    New-Item $regPathAU -ItemType Directory
}

function Set-NonAdminsToApproveUpdate {
    param (
        [Parameter()]
        [bool]$Enabled = $false
    )
    if ($Enabled) {
        $value = 1
    } else {
        $value = 0
    }

    $regitemConfigured = testNonAdminsToApproveUpdatesExists
    if ($regitemConfigured) {
        Set-ItemProperty -Path $regPath -Name ElevateNonAdmins -Value $value -Force
    } else {
        New-ItemProperty -Path $regPath -Name ElevateNonAdmins -PropertyType DWORD -Value $value -Force
    }
}

function testNonAdminsToApproveUpdatesExists {
    try {
        Get-ItemProperty -Path $regPath -Name ElevateNonAdmins -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Get-NonAdminsToApproveUpdate {
    $ElevateNonAdmins = Get-ItemProperty -Path $regPath -Name ElevateNonAdmins -ErrorAction SilentlyContinue
    return $ElevateNonAdmins
}

function Set-UpdateTargetGroup {
    param (
        [Parameter(Mandatory=$true)]
        [String]$Name     
    )
    $regItemConfigured = testUpdateTargetGroupExists
    if ($regItemConfigured) {
        Set-ItemProperty -Path $regPath -Name TargetGroup -Value $Name -Force
        Set-ItemProperty -Path $regPath -Name TargetGroupEnabled -Value 1 -Force 
    } else {
        $null = New-ItemProperty -Path $regPath -Name TargetGroupEnabled -PropertyType DWORD -Value 1 -Force
        $null = New-ItemProperty -Path $regPath -Name TargetGroup -PropertyType String -Value $Name -Force
    }
}

function testUpdateTargetGroupExists {
    try {
        Get-ItemProperty -Path $regPath -Name TargetGroup -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Get-UpdateTargetGroup {
    $targetGroup = Get-ItemProperty -Path $regPath -Name TargetGroup -ErrorAction SilentlyContinue
    if ($targetGroup) {
        $registryPath = $targetGroup.PSPath.Replace('Microsoft.PowerShell.Core\Registry::','')
    } else {
        $registryPath = ''
    }
    return (
        [PSCustomObject]@{
            TargetGroup = $targetGroup.TargetGroup
            RegistryPath = $registryPath
        }
    )
}

function Remove-UpdateTargetGroup {
    $regItemConfigured = testUpdateTargetGroupExists
    if ($regItemConfigured) {
        try {
            Get-Item -Path $regPath -ErrorAction Stop | Remove-ItemProperty -Name TargetGroup
            Get-Item -Path $regPath -ErrorAction Stop | Remove-ItemProperty -Name TargetGroupEnabled
        } catch {
            $Err = $_
            Write-Error $Err
        }
    }  
}

function Set-UpdateServer {
    param (
        [Parameter(Mandatory=$true)]
        [string]$URL,

        [Parameter()]
        [bool]$Enabled = $true
    )
    $regItemConfigured = testUpdateServer
    if ($regItemConfigured) {
        Set-ItemProperty -Path $regPath -Name WUServer -Value $URL -Force
        Set-ItemProperty -Path $regPath -Name WUStatusServer -Value $URL -Force
        if ($Enabled) {
            Set-ItemProperty -Path $regPathAU -Name UseWUServer -Value 1 -Force
        } else {
            Set-ItemProperty -Path $regPathAU -Name UseWUServer -Value 0 -Force
        }
    } else {
        $null = New-ItemProperty -Path $regPath -Name WUServer -PropertyType String -Value $URL -Force
        $null = New-ItemProperty -Path $regPath -Name WUStatusServer -PropertyType String -Value $URL -Force
        if ($Enabled) {
            $null = New-ItemProperty -Path $regPathAU -Name UseWUServer -PropertyType DWORD -Value 1 -Force
        } else {
            $null = New-ItemProperty -Path $regPathAU -Name UseWUServer -PropertyType DWORD -Value 0 -Force
        }
    }
}

function testUpdateServer {
    try {
        Get-ItemProperty -Path $regPath -Name WUServer -ErrorAction Stop
        Get-ItemProperty -Path $regPath -Name WUStatusServer -ErrorAction Stop
        Get-ItemProperty -Path $regPathAU -Name UseWUServer -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Get-UpdateServer {
    $UpdateServer = Get-ItemProperty -Path $regPath -Name WUServer -ErrorAction SilentlyContinue
    $UpdateServerEnabled = Get-ItemProperty -Path $regPathAU -Name UseWUServer -ErrorAction SilentlyContinue

    if ($UpdateServer) {
        $registryPath = $UpdateServer.PSPath.Replace('Microsoft.PowerShell.Core\Registry::','')
    } else {
        $registryPath = ''
    }

    if ($UpdateServerEnabled.UseWUServer -eq 1) {
        $Value = $true
    } else {
        $Value = $false
    }

    return (
        [PSCustomObject]@{
            WSUSServer = $UpdateServer.WUServer
            RegistryPath = $registryPath
            Enabled = $Value
        }
    )
}

function Remove-UpdateServer {
    try {
        Get-Item -Path $regPath -ErrorAction Stop | Remove-ItemProperty -Name WUServer
        Get-Item -Path $regPathAU -ErrorAction Stop | Remove-ItemProperty -Name UseWUServer
        Get-Item -Path $regPath -ErrorAction Stop | Remove-ItemProperty -Name WUStatusServer
    } catch {
        $err = $_
        Write-Error $err
    } 
}

function Get-UpdateOption {
    $AUOption = Get-ItemProperty -Path $regPathAU -Name AUOptions -ErrorAction SilentlyContinue

    if ($AUOption) {
        $registryPath = $AUOption.PSPath.Replace('Microsoft.PowerShell.Core\Registry::','')
    } else {
        $registryPath = ''
    }

    switch ($AUOption.AUOptions) {
        2 { $value = 'NotifyBeforeDownload'; break }
        3 { $value = 'AutoDownloadAndNotifyForInstall'; break }
        4 { $value = 'AutoDownloadAndScheduleInstallation'; break }
        5 { $value = 'UsersCanConfigureAutomaticUpdates'; break }
        default { $value = 'There is no automatic update option configured' }
    }
    return (
        [PSCustomObject]@{
            AutoUpdateOption = $value
            RegistryPath = $registryPath
        }
    )
}

function testUpdateOptionsExist {
    try {
        Get-ItemProperty -Path $regPathAU -Name AUOptions -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Set-UpdateOption {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('NotifyBeforeDownload','AutoDownloadAndNotifyForInstall','AutoDownloadAndScheduleInstallation','UsersCanConfigureAutomaticUpdates')]
        [string]$Setting
    )
    switch ($Setting) {
        'NotifyBeforeDownload'                { $value = 2; break }
        'AutoDownloadAndNotifyForInstall'     { $value = 3; break }
        'AutoDownloadAndScheduleInstallation' { $value = 4; break }
        'UsersCanConfigureAutomaticUpdates'   { $value = 5; break }
    }
    $regItemConfigured = testUpdateOptionsExist
    if ($regItemConfigured) {
        Set-ItemProperty -Path $regPathAU -Name AUOptions -Value $value -Force
    } else {
        $null = New-ItemProperty -Path $regPathAU -Name AUOptions -PropertyType DWORD -Value $value -Force
    }
}

function Remove-UpdateOption {
    $regItemConfigured = testUpdateOptionsExist
    if ($regItemConfigured) {
        try {
            Get-Item -Path $regPathAU -ErrorAction Stop | Remove-ItemProperty -Name AUOptions
        } catch {
            $err = $_
            Write-Error $err
        }
    }
}

function Set-UpdateScheduledInstallDay {
    param (
        [parameter(Mandatory=$true)]
        [ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')]
        [string]$Day
    )
    switch ($day) {
        'Monday'    { $value = 2; break }
        'Tuesday'   { $value = 3; break }
        'Wednesday' { $value = 4; break }
        'Thursday'  { $value = 5; break }
        'Friday'    { $value = 6; break }
        'Saturday'  { $value = 7; break }
        'Sunday'    { $value = 1; break }
    }
    if ((Get-UpdateOption).Value -eq '4') {
        if (testUpdateScheduledInstallDayExists) {
            Set-ItemProperty -Path $regPathAU -Name ScheduledInstallDay -Value $value -Force
        } else {
            $null = New-ItemProperty -Path $regPathAU -Name ScheduledInstallDay -PropertyType DWORD -Value $value -Force
        }
    } else {
        Write-Error 'This only works if Update Option is set to AutoDownloadAndScheduleInstallation'
    }
}

function Get-UpdateScheduledInstallDay {
    $updateScheduleInstallDay = Get-ItemProperty -Path $regPathAU -Name ScheduledInstallDay -ErrorAction SilentlyContinue
    if ($updateScheduleInstallDay) {
        $registryPath = $updateScheduleInstallDay.PSPath.Replace('Microsoft.PowerShell.Core\Registry::','')
    } else {
        $registryPath = ''
    }
    switch ($updateScheduleInstallDay.ScheduledInstallDay) {
        1 { $value = 'Sunday' }
        2 { $value = 'Monday' }
        3 { $value = 'Tuesday' }
        4 { $value = 'Wednesday' }
        5 { $value = 'Thursday' }
        6 { $value = 'Friday' }
        7 { $value = 'Saturday' }
        default { $value = 'There is no scheduled install day configured' }
    }
    return (
        [PSCustomObject]@{
            ScheduledUpdateInstallDay = $value
            RegistryPath = $registryPath
        }
    )
}

function testUpdateScheduledInstallDayExists {
    try {
        Get-ItemProperty -Path $regPathAU -Name ScheduledInstallDay -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Remove-UpdateScheduledInstallDay {
    if (testUpdateScheduledInstallDayExists) {
        try {
            Get-Item -Path $regPathAU -ErrorAction Stop | Remove-ItemProperty -Name ScheduledInstallDay
        } catch {
            $Err = $_
            Write-Error $Err
        }
    }
}

function Set-UpdateScheduledInstallHour {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23)]
        [int]$Hour
    )
    if (testUpdateScheduledInstallHourExists) {
        Set-ItemProperty -Path $regPathAU -Name ScheduledInstallTime -Value $Hour -Force
    } else {
        $null = New-ItemProperty -Path $regPathAU -Name ScheduledInstallTime -PropertyType DWORD -Value $Hour -Force
    }
}

function Get-UpdateScheduledInstallHour {
    $updateScheduleInstallHour = Get-ItemProperty -Path $regPathAU -Name ScheduledInstallTime -ErrorAction SilentlyContinue
    if ($updateScheduleInstallHour) {
        $registryPath = $updateScheduleInstallHour.PSPath.Replace('Microsoft.PowerShell.Core\Registry::','')
    } else {
        $registryPath = ''
    }
    return (
        [PSCustomObject]@{
            ScheduledUpdateInstallHour = $updateScheduleInstallHour.ScheduledInstallTime
            RegistryPath = $registryPath
        }
    )
}

function testUpdateScheduledInstallHourExists {
    try {
        Get-ItemProperty -Path $regPathAU -Name ScheduledInstallTime -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Remove-UpdateScheduledInstallHour {
    if (testUpdateScheduledInstallHourExists) {
        try {
            Get-Item -Path $regPathAU -ErrorAction Stop | Remove-ItemProperty -Name ScheduledInstallTime
        } catch {
            $Err = $_
            Write-Error $Err
        }
    }
}

function Set-AutomaticUpdate {
    param (
        [Parameter()]
        [bool]$Enabled = $true
    )

    if ($Enabled) {
        $value = 0
    } else {
        $value = 1
    }

    $regitemConfigured = testAutomaticUpdateExists
    if ($regitemConfigured) {
        Set-ItemProperty -Path $regPathAU -Name NoAutoUpdate -Value $value -Force
    } else {
        $null = New-ItemProperty -Path $regPathAU -Name NoAutoUpdate -PropertyType DWORD -Value $value -Force
    }
}

function Get-AutomaticUpdate {
    $automaticUpdate = Get-ItemProperty -Path $regPathAU -Name NoAutoUpdate -ErrorAction SilentlyContinue
    if ($automaticUpdate) {
        $registryPath = $automaticUpdate.PSPath.Replace('Microsoft.PowerShell.Core\Registry::','')
    } else {
        $registryPath = ''
    }
    if ($automaticUpdate.NoAutoUpdate -eq 0) {
        $value = $true
    } else {
        $value = $false
    }
    return (
        [PSCustomObject]@{
            AutomaticUpdateEnabled = $value
            RegistryPath = $registryPath
        }
    )
}

function Remove-AutomaticUpdate {
    $regitemConfigured = testAutomaticUpdateExists
    if ($regitemConfigured) {
        Get-Item -Path $regPathAU | Remove-ItemProperty -Name NoAutoUpdate
    }
}

function testAutomaticUpdateExists {
    try {
        Get-ItemProperty -Path $regPathAU -Name NoAutoUpdate -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

Export-ModuleMember -Function *-*