Import-Module "$((Get-Item -LiteralPath "$($PSScriptRoot)").Parent.Parent.FullName)\Misc\KVWindowsUpdate.psm1"
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $AutomaticUpdateEnabled,

        [System.String]
        $AutomaticUpdateOption,

        [System.String]
        $UpdateServer,

        [System.String]
        $UpdateTargetGroup,

        [ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday','All')]
        [System.String]
        $ScheduledInstallDay,

        [ValidateSet(01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23)]
        [System.UInt32]
        $ScheduledInstallHour
    )
    Write-Verbose 'Getting all the existing settings on the system'

    $AutomaticUpdate = (Get-AutomaticUpdate).AutomaticUpdateEnabled
    $UpdateOption = (Get-UpdateOption).AutoUpdateOption
    $Server = (Get-UpdateServer).WSUSServer
    $TargetGroup = (Get-UpdateTargetGroup).TargetGroup
    $InstallDay = (Get-UpdateScheduledInstallDay).ScheduledUpdateInstallDay
    $InstallHour = (Get-UpdateScheduledInstallHour).ScheduledUpdateInstallHour

    $returnValue = @{
        Ensure = $Ensure
        AutomaticUpdateEnabled = $AutomaticUpdate
        AutomaticUpdateOption = $UpdateOption
        UpdateServer = $Server
        UpdateTargetGroup = $TargetGroup
        ScheduledInstallDay = $InstallDay
        ScheduledInstallHour = $InstallHour
    }
    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $AutomaticUpdateEnabled,

        [ValidateSet('NotifyBeforeDownload','AutoDownloadAndNotifyForInstall','AutoDownloadAndScheduleInstallation','UsersCanConfigureAutomaticUpdates')]
        [System.String]
        $AutomaticUpdateOption,

        [System.String]
        $UpdateServer,

        [System.String]
        $UpdateTargetGroup,

        [ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday','All')]
        [System.String]
        $ScheduledInstallDay,

        [ValidateSet(01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23)]
        [System.UInt32]
        $ScheduledInstallHour
    )
    $targetResource = Get-TargetResource @PSBoundParameters

    if ($PSBoundParameters.ContainsKey('AutomaticUpdateEnabled')) {
        if ($Ensure -eq 'Present') {
            if ($targetResource.AutomaticUpdateEnabled -ne $AutomaticUpdateEnabled) {
                Write-Verbose "Changing setting 'Automatic Update' to Enabled"
                Set-AutomaticUpdate -Enabled $true
            } else {
                Write-Verbose "Changing setting 'Automatic Update' to Disabled"
                Set-AutomaticUpdate -Enabled $false
            }
        } else {
            Write-Verbose 'Removing Automatic Update setting'
            Remove-AutomaticUpdate
        }
    }
 
    if ($PSBoundParameters.ContainsKey('AutomaticUpdateOption')) {
        if ($Ensure -eq 'Present') {
            if ($targetResource.AutomaticUpdateOption -ne $AutomaticUpdateOption) {
                Write-Verbose "Changing Automatic Update Option to $AutomaticUpdateOption"
                Set-UpdateOption -Setting $AutomaticUpdateOption
            }
        } else {
            Write-Verbose "Removing Automatic Update Option"
            Remove-UpdateOption
        }
    }

    if ($PSBoundParameters.ContainsKey('UpdateServer')) {
        if ($Ensure -eq 'Present') {
            if ($targetResource.UpdateServer -ne $UpdateServer) {
                Write-Verbose "Changing Update Server to the following URL: $UpdateServer"
                Set-UpdateServer -URL $UpdateServer -Enabled $true
            }
        } else {
            Write-Verbose "Removing Update Server"
            Remove-UpdateServer
        }
    }

    if ($PSBoundParameters.ContainsKey('UpdateTargetGroup')) {
        if ($Ensure -eq 'Present') {
            if ($targetResource.UpdateTargetGroup -ne $UpdateTargetGroup) {
                Write-Verbose "Changing Update Target Group to $UpdateTargetGroup"
                Set-UpdateTargetGroup -Name $UpdateTargetGroup
            }
        } else {
            Write-Verbose 'Removing Update Target Group'
            Remove-UpdateTargetGroup
        }
    }

    if ($PSBoundParameters.ContainsKey('ScheduledInstallDay')) {
        if ($Ensure -eq 'Present') {
            if ($targetResource.ScheduledInstallDay -ne $ScheduledInstallDay) {
                Write-Verbose "Changing Update Scheduled Install Day to $ScheduledInstallDay"
                Set-UpdateScheduledInstallDay -Day $ScheduledInstallDay
            }
        } else {
            Write-Verbose 'Removing Update Scheduled Install Day'
            Remove-UpdateScheduledInstallDay
        }
    }

    if ($PSBoundParameters.ContainsKey('ScheduledInstallHour')) {
        if ($Ensure -eq 'Present') {
            if ($targetResource.ScheduledInstallTime -ne $ScheduledInstallHour) {
                Write-Verbose "Changing Update Scheduled Install Hour to $ScheduledInstallHour"
                Set-UpdateScheduledInstallHour -Hour $ScheduledInstallHour
            }
        } else {
            Write-Verbose 'Removing Update Scheduled Install Hour'
            Remove-UpdateScheduledInstallHour
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $AutomaticUpdateEnabled,

        [ValidateSet('NotifyBeforeDownload','AutoDownloadAndNotifyForInstall','AutoDownloadAndScheduleInstallation','UsersCanConfigureAutomaticUpdates')]
        [System.String]
        $AutomaticUpdateOption,

        [System.String]
        $UpdateServer,

        [System.String]
        $UpdateTargetGroup,

        [ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday','All')]
        [System.String]
        $ScheduledInstallDay,

        [ValidateSet(01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23)]
        [System.UInt32]
        $ScheduledInstallHour
    )
    if ($PSBoundParameters.ContainsKey('Ensure')) {
        [void]$PSBoundParameters.Remove('Ensure')
    }

    $targetResource = Get-TargetResource @PSBoundParameters

    if ($targetResource.Ensure -ne $Ensure) 
    {
        Write-Verbose "Ensure is $Ensure"
        return $false
    }
    if ($targetResource.AutomaticUpdateEnabled -ne $AutomaticUpdateEnabled) 
    {
        Write-Verbose "AutomaticUpdateEnabled is not set to $AutomaticUpdateEnabled"
        return $false
    }
    if (($targetResource.AutomaticUpdateOption -ne $AutomaticUpdateOption) -and ($AutomaticUpdateEnabled -eq $true))
    {
        Write-Verbose "AutomaticUpdateOption is not set to $AutomaticUpdateOption"
        return $false
    }
    if (($targetResource.UpdateServer -ne $UpdateServer) -and ($AutomaticUpdateEnabled -eq $true))
    {
        Write-Verbose "UpdateServer is not set to $UpdateServer"
        return $false
    }
    if (($targetResource.UpdateTargetGroup -ne $UpdateTargetGroup) -and ($AutomaticUpdateEnabled -eq $true))
    {
        Write-Verbose "UpdateTargetGroup is not set to $UpdateTargetGroup"
        return $false
    }
    if (($targetResource.ScheduledInstallDay -ne $ScheduledInstallDay) -and ($AutomaticUpdateEnabled -eq $true))
    {
        Write-Verbose "ScheduledInstallDay is not set to $ScheduledInstallDay"
        return $false
    }
    if (($targetResource.ScheduledInstallHour -ne $ScheduledInstallHour) -and ($AutomaticUpdateEnabled -eq $true))
    {
        Write-Verbose "ScheduledInstallHour is not set to $ScheduledInstallHour"
        return $false
    }
    Write-Verbose "All settings are applied successfully"
    return $true
}


Export-ModuleMember -Function *-TargetResource

