<#
    .NOTE
        .AUTHOR %Author%
        .DATE   %Date%
        .VER    %Ver%
        .LANG   %Lang%
        
    .LINK
        %ProjectURL%
    
    .COMPONENT
        %Component%

    .SYNOPSIS 

    .DESCRIPTION
        %Description% 

    .PARAMETER

    .EXAMPLE
        %Example%

#>
Param (
    [Parameter( Mandatory = $false, Position = 0, HelpMessage = "Initialize global settings." )]
    [bool] $InitGlobal = $true,
    [Parameter( Mandatory = $false, Position = 1, HelpMessage = "Initialize local settings." )]
    [bool] $InitLocal = $true   
)

$Global:ScriptInvocation = $MyInvocation
if ($env:AlexKFrameworkInitScript) { 
    . "$env:AlexKFrameworkInitScript" -MyScriptRoot (Split-Path $PSCommandPath -Parent) -InitGlobal $InitGlobal -InitLocal $InitLocal 
}
Else { 
    Write-Host "Environmental variable [AlexKFrameworkInitScript] does not exist!" -ForegroundColor Red
    exit 1
}
if ($LastExitCode) { exit 1 }

# Error trap
trap {
    if ($GlobalSettingsSuccessfullyLoaded) {
        Get-ErrorReporting $_
        . "$GlobalSettings\$SCRIPTSFolder\Finish.ps1" 
    }
    Else {
        Write-Host "[$($MyInvocation.MyCommand.path)] There is error before logging initialized." -ForegroundColor Red
    }   
    exit 1
}
################################# Script start here #################################
function Start-Action {
param (
    [Parameter( Mandatory = $true, Position = 0, HelpMessage = "VM action." )]
    [ValidateNotNullOrEmpty()]
    [int] $Action,
    [Parameter(Mandatory = $true, Position = 1, HelpMessage = "All VM list." )]
    [ValidateNotNull()]
    $VMList
)
     
    $AllVMInfo  = $VMList | Select-Object CreationTime, StatusDescriptions, VMName, State, Uptime, AutomaticStartDelay, Generation, Version, ProcessorCount, MemoryAssigned, MemoryDemand, ParentCheckpointName, Path, Notes

    switch ($Action) {
        "1" {
            Write-Host "[1] Show VM."
            $AllVMInfo | Out-GridView -OutputMode Single -Title "Select VM." | out-null
        }
        "2" {
            Write-Host "[2] Start VM."          
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName = $Item.name 
                    Start-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName    
                }                
            }
        }
        "3" {
            Write-Host "[3] Stop VM."     
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName = $Item.name 
                    Stop-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName    
                }                
            }
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
exit 1
            } 
        }
        "4" {
            Write-Host "[4] Restart VM."             
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName = $Item.name
                    Restart-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName -RestartMode "Reset" 
                }
            }
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                exit 1
            }
        }
        "5" {
            Write-Host "[5] Shutdown and start VM."             
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName = $Item.name
                    Restart-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName -RestartMode "Shutdown" 
                }
            }
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                exit 1
            }
        }
        "6" {
            Write-Host "[6] Get VM settings."
            if ($VM) {
                foreach ($Item in $VM) {
                    Get-VMSettings -Computer $Computer -Credentials $Credentials -VM $Item 
                } 
            }
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                exit 1
            } 
        }
        "7" {
            Write-Host "[7] Rename VM." 
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName = $Item.name
                    $NewVMName = Read-Host "Enter new name for VM [$VMName]"
                    Rename-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName -NewVMName $NewVMName 
                }                      
            }
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                exit 1
            }  
        }
        "8" {
            Write-Host "[8] Remove VM." 
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName    = $Item.name
                    $LastState = $VM.state

                    if ($LastState -ne "Off") {
                        Stop-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                    }  

                    Remove-CustomVM -Computer $Computer -Credentials $Credentials -VM $Item -DeleteVMFolder  
                }                     
            }
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                exit 1
            }  
        }
        "9" {
            Write-Host "[9] Move VM storage"            
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName = $Item.name
                    $VMPath = $Item.Path
                    $NewVMPath = Read-Host "Enter new path for VM [$VMName] with path [$VMPath]"
                    Move-CustomVMStorage -Computer $Computer -Credentials $Credentials -VM $Item -NewStoragePath $NewVMPath
                }
            }Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                exit 1
            }  
        }
        "10" {
            Write-Host "[10] Add boot ISO"            
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName = $Item.name
                    $ISOFilePath = Show-OpenDialog -Type "file" -InitPath $IsoPath -Description "Choose ISO file." -FileFilter "ISO Files (*.iso)|*.iso"
                    Add-BootISO -Computer $Computer -Credentials $Credentials -VMName $VMName -ISOFilePath $ISOFilePath
                    Get-VMSettings -Computer $Computer -Credentials $Credentials -VM $Item  
                }
            } Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                exit 1
            }
        }
        "11" {
            Write-Host "[11] Remove boot ISO."            
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName = $Item.name
                    Remove-DVDWithISO -Computer $Computer -Credentials $Credentials -VMName $VMName
                    Get-VMSettings -Computer $Computer -Credentials $Credentials -VM $Item 
                } 
            }  
        }
        "12" {
            Write-Host "[12] Optimize VM HDDs."            
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName = $Item.name
                    $LastState = $Item.state

                    if ($LastState -ne "Off") {
                        Stop-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                    }
                    Start-VMVHDOptimization  -Computer $Computer -Credentials $Credentials -VMName $VMName -Mode "Full" -OptimizeCheckpoints

                    if ($LastState -eq "Running") {
                        Start-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                    }
                }  
            }
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                exit 1
            }
        }
        "13" {
            Write-Host "[13] Create new VM."  
            if (-not $NewVMName) {
                while (-not $NewVMName) {
                    $NewVMName = Read-Host "Enter new VM name"
                    Write-Host "New VM name is: [$NewVMName]"   
                } 
            }
            $Answer = ($VMConfigs | Get-Member -type NoteProperty | Select-Object name | Out-GridView -OutputMode Single -Title "Select VM configuration.").name
            $VMConfig = $VMConfigs | Select-Object -ExpandProperty $Answer
   

            $Answer = Read-Host "Do you want to use only LAN or WAN and LAN network? [(L)/w]"

            if (($Answer.ToUpper() -eq "L") -or ($Answer.ToUpper() -eq "")) {
                $NetConfig = $NetConfigs.LAN
            }
            ElseIf ($Answer.ToUpper() -eq "W") {
                $NetConfig = $NetConfigs.LAN_WAN
            }
            $StartupConfig = $StartupConfigs.CD_IDE_NET_FDD

            $Answer = Read-Host "Do you want to use ISO file? [Y/(N)]"
            if ($Answer.ToUpper() -eq "Y") {
                $ISOFilePath = Show-OpenDialog -Type "file" -InitPath $IsoPath -Description "Choose ISO file." -FileFilter "ISO Files (*.iso)|*.iso"            
            }
            Write-Host "VM config:"
            $VMConfig 
            Write-Host "Net config:"
            $NetConfig
            $Answer = Read-Host "Do you want to use this settings? [Y/N]"
            if ($Answer.ToUpper() -eq "Y") {
                $NewVM = Add-NewCustomVM -Computer $Computer -Credentials $Credentials -NewVMName $NewVMName -Mode "New" -VMConfig $VMConfig -ImportPath $ImportPath  -IsoFilePath $ISOFilePath -StartupConfig $StartupConfig -NETConfig $NETConfig -RDPShortcutsFolderPath $RDPShortcutsFolderPath -StartVM
                Start-VMConsole  -Computer $Computer -Credentials $Credentials -VM $NewVM
            } 
        }
        "14" {
            Write-Host "[14] Import exported VM."
            $ExportPath = Convert-FSPath $Global:InitialExportPath $Computer
            $VMTemplatePath = Show-OpenDialog -Type "folder" -InitPath $ExportPath -Description "Choose VM template from repository."
            $VMTemplatePath = Convert-FSPath -CurrentPath $VMTemplatePath          

            $Answer = Read-Host "Do you want to use ISO file? [Y/(N)]"
            if ($Answer.ToUpper() -eq "Y") {
                $ISOFilePath = Show-OpenDialog -Type "file" -InitPath $IsoPath -Description "Choose ISO file." -FileFilter "ISO Files (*.iso)|*.iso"            
                $NewVM = Add-NewCustomVM -Computer $Computer -Credentials $Credentials -NewVMName $NewVMName -Mode "Import" -ImportPath $ImportPath  -IsoFilePath $ISOFilePath -VMTemplatePath $VMTemplatePath -RDPShortcutsFolderPath $RDPShortcutsFolderPath -AddNewSnapshot -StartVM -StartRDPConsole
            }
            Else {
                $NewVM = Add-NewCustomVM -Computer $Computer -Credentials $Credentials -NewVMName $NewVMName -Mode "Import" -ImportPath $ImportPath -VMTemplatePath $VMTemplatePath -RDPShortcutsFolderPath $RDPShortcutsFolderPath -AddNewSnapshot -StartVM -StartRDPConsole
            }
        }
        "15" {
            Write-Host "[15] Export existing VM."            
            if ($VM) {
                foreach ($Item in $VM) { 
                    $VMName = $VM.name
                    $LastState = $VM.state

                    if ($LastState -ne "Off") {
                        Stop-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                    }

                    Export-ExistingVM  -Computer $Computer -Credentials $Credentials -VM $Item  -ExportPath $Global:InitialExportPath -RemoveIndex

                    if ($LastState -eq "Running") {
                        Start-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                    }
                }
            }
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                exit 1
            }
        }
        "16" {
            Write-Host "[16] Set boot order."            
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName = $Item.name
                    $StartupOrder = Get-VMStartupOrder -Computer $Computer -Credentials $Credentials -VMName $VMName
                
                    $Next = $true
                    while ($Next) {
                        $FirstElement = $StartupOrder | Out-GridView -OutputMode Single -Title "Select first boot device."
                        if ($FirstElement) {
                            $StartupOrder = $StartupOrder -ne $FirstElement 
                            $NewStartupOrder = @()
                            $NewStartupOrder += $FirstElement
                            foreach ($item in $StartupOrder) {
                                $NewStartupOrder += $item 
                            }
                            $StartupOrder = $NewStartupOrder   
                        } 
                        else {
                            [array] $NewStartupOrder = @()
                            foreach ($item in $StartupOrder) {
                                $NewStartupOrder += $item.Value 
                            }
                            $Next = $false
                        }            
                    } 

                    Set-VMStartupOrder -VMName $VMName -StartupOrder $NewStartupOrder -Computer $Computer -Credentials $Credentials
                }
            }
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                exit 1
            }   
        }
        "17" {
            Write-Host "[17] Set VM RAM size."            
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName = $Item.name           
                    [int] $Answer = Read-Host "Enter new VM startup RAM size in Gb."
                    $StartupRAMSize = $Answer * 1Gb
                    Set-VMRamSize -VMName $VMName  -Computer $Computer -Credentials $Credentials -StartupRAMSize $StartupRAMSize
                }
            } 
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                exit 1
            }
        }
        "18" {
            Write-Host "[18] Show VM checkpoints."
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName = $Item.name
                    Get-ExistingVMSnapshots -Computer $Computer -credentials $Credentials -VMName $VMName | Out-GridView -OutputMode Single -Title "Select VM Snapshot." 
                }
            }
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                exit 1
            }
        }
        "19" {
            Write-Host "[19] Restore VM checkpoint." 
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName = $Item.name
                    $VMSnapshot = Get-ExistingVMSnapshots -Computer $Computer -credentials $Credentials -VMName $VMName | Out-GridView -OutputMode Single -Title "Select VM Snapshot to restore." 
                    if ($VMSnapshot) {                 
                        $LastState = $VM.state

                        if ($LastState -ne "Off") {
                            Stop-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                        }  

                        $VMSnapshotName = $VMSnapshot.Name
                        Restore-CustomVMCheckpoint -Computer $Computer -Credentials $Credentials -VMName $VMName -SnapshotName $VMSnapshotName

                        if ($LastState -eq "Running") {
                            Start-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                        }

                    }  
                }            
            } 
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                exit 1
            }
        }
        "20" {
            Write-Host "[20] Create new checkpoint for existing VM."      
            if ($VM) {
                foreach ($Item in $VM) {
                    $Answer = Read-Host "Enter checkpoint name or select from the list:
                    [1] Clean install
                    [2] Installed updates
                    [3] Installed remoting and KVM tools
                    [4] Configured        
                "                    
                    $VMName = $Item.Name
                    switch ($Answer) {
                        "1" { $CheckpointName = "Clean install" }
                        "2" { $CheckpointName = "Installed updates" }
                        "3" { $CheckpointName = "Installed remoting and KVM tools" }
                        "4" { $CheckpointName = "Configured" }
                        Default { [string] $CheckpointName = $Answer }
                    }
                    $ThisVM = Get-ExistingVM  -Computer $Computer -Credentials $Credentials -VMName $VMName
                    
                    $LastState = $ThisVM.state

                    if ($LastState -ne "Off") {
                        Stop-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                    }   

                    Add-VMCheckPoint -Computer $Computer -Credentials $Credentials -VMName $VMName -NewCheckpointName $CheckpointName

                    if ($LastState -eq "Running") {
                        Start-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                    }
                    
                }
            }
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                exit 1
            }
        }
        "21" {
            Write-Host "[21] Remove VM checkpoint." 
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName = $Item.name
                    $VMSnapshot = Get-ExistingVMSnapshots -Computer $Computer -credentials $Credentials -VMName $VMName | Out-GridView -OutputMode Single -Title "Select VM Snapshot to remove." 
            
                    if ($VMSnapshot) {                 
                        $LastState = $Item.state

                        if ($LastState -ne "Off") {
                            Stop-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                        }  

                        $VMSnapshotName = $VMSnapshot.Name
                        Remove-CustomVMCheckpoint -Computer $Computer -Credentials $Credentials -VMName $VMName -SnapshotName $VMSnapshotName                   

                        if ($LastState -eq "Running") {
                            Start-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                        }

                    } 
                }             
            } 
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                exit 1
            }
        }
        "22" {
            Write-Host "[22] Replace VM checkpoint." 
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName = $Item.name
                    $VMSnapshot = Get-ExistingVMSnapshots -Computer $Computer -credentials $Credentials -VMName $VMName | Select-Object -last 1| Out-GridView -OutputMode Single -Title "Select VM Snapshot to replace." 
                    if ($VMSnapshot) {                 
                        $LastState = $Item.state

                        if ($LastState -ne "Off") {
                            Stop-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                        }  

                        $VMSnapshotName = $VMSnapshot.Name
                        Remove-CustomVMCheckpoint -Computer $Computer -Credentials $Credentials -VMName $VMName -SnapshotName $VMSnapshotName
                        Add-VMCheckPoint -Computer $Computer -Credentials $Credentials -VMName $VMName -NewCheckpointName $VMSnapshotName

                        if ($LastState -eq "Running") {
                            Start-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                        }

                    } 
                }             
            }
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                exit 1
            } 
        }
        "23" {
            Write-Host "[23] Connect VM console."
            
            if ($VM) {
                foreach ($Item in $VM) {
                    Start-VMConsole  -Computer $Computer -Credentials $Credentials -VM $Item  
                }  
            }
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                exit 1
            }
        }
        "24" {
            Write-Host "[24] Connect VM RDP."
            $Global:MaxVMNetworkWaitRetry = 100
            
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName = $Item.Name
                    $Networks = Get-VMNetworks  -Computer $Computer -Credentials $Credentials -VMName $VMName
                    $RetryCounter = 1
                    while (@($Networks.IPAddresses).count -lt 2) {        
                        Write-Host "Waiting for network... ($($Networks.IPAddresses))"
                        Start-Sleep -seconds 1
                        $Networks = Get-VMNetworks  -Computer $Computer -Credentials $Credentials -VMName $VMName
                        if ($RetryCounter -gt $Global:MaxVMNetworkWaitRetry) {
                            Add-ToLog -Message "VM [$VMName] does not have ip addresses after [$Global:MaxVMNetworkWaitRetry] retries!" -logFilePath $ScriptLogFilePath -Display -Status "Error"
                            Exit 1
                        }
                    }
                    $Global:VMIp = ($Networks | Where-Object { $_.SwitchName -eq "LAN" } | Select-Object -ExpandProperty IPAddresses) | Select-Object -first 1
                    while ( ($Null -eq $HostName) -or ($Hostname -eq "") ) {
                        start-sleep 2
                        $HostName = ([System.Net.Dns]::GetHostByAddress($Global:VMIp).Hostname).split(".") | select-object -first 1 
                    }
                    Add-GuestCredentialsToVault $HostName 
                    Start-VMConsole  -Computer $Computer -Credentials $Credentials -IP $HostName 
                    start-sleep -Seconds 10
                    Remove-GuestCredentialsFromVault $HostName 
                }
            }
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
               exit 1
            }
        }
        "25" {
            Write-Host "[25] Connect VM SSH."
            
            if ($VM) {
                foreach ($Item in $VM) {
                    $VMName = $Item.Name
                    Add-ToLog -Message "Connecting ssh to VM [$VMName]." -logFilePath $ScriptLogFilePath -Display -Status "info"                    
                    $Networks = Get-VMNetworks  -Computer $Computer -Credentials $Credentials -VMName $VMName
                    $RetryCounter = 1
                    while (@($Networks.IPAddresses).count -lt 2) {        
                        Write-Host "Waiting for network... ($($Networks.IPAddresses))"
                        Start-Sleep -seconds 1
                        $Networks = Get-VMNetworks  -Computer $Computer -Credentials $Credentials -VMName $VMName
                        if ($RetryCounter -gt $Global:MaxVMNetworkWaitRetry) {
                            Add-ToLog -Message "VM [$VMName] does not have ip addresses after [$Global:MaxVMNetworkWaitRetry] retries!" -logFilePath $ScriptLogFilePath -Display -Status "Error"
                            Exit 1
                        }
                        $RetryCounter ++
                    }
                    $Global:VMIp = ($Networks | Where-Object { $_.SwitchName -eq "LAN" } | Select-Object -ExpandProperty IPAddresses) | Select-Object -first 1
                    $HostName = ([System.Net.Dns]::GetHostByAddress($Global:VMIp).Hostname).split(".") | Select-Object -first 1
                }
                $UserName = Get-GuestUsername $hostName
                $Id = "$UserName@$Global:VMIp"
                & ssh-keygen.exe -R $Global:VMIp
                $RemoteHostKey = (& ssh-keyscan.exe -t rsa $Global:VMIp)
                $RetryCounter = 1
                while (-not $RemoteHostKey) {
                    start-sleep 1
                    $RemoteHostKey = (& ssh-keyscan.exe -t rsa $Global:VMIp)
                    if ($RetryCounter -gt $Global:MaxVMNetworkWaitRetry) {
                        Add-ToLog -Message "VM [$VMName] does not have remote host key after [$Global:MaxVMNetworkWaitRetry] retries!" -logFilePath $ScriptLogFilePath -Display -Status "Error"
                        Exit 1
                    }
                    $RetryCounter ++
                }    
                & ssh-keyscan.exe -t rsa $Global:VMIp >> "$env:USERPROFILE\.ssh\known_hosts"  
                Start-Job -scriptblock { & wt.exe -p PowerShell ssh.exe $Using:Id -i $Using:SShIdentityFilePath }
            }
            Else {
                Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
               exit 1
            }
        }
        "26" {
            Write-Host "[26] Config guest host."
            $Res = Import-Module "AlexkWindowsGuestUtils" -PassThru -Force
            if ($Res) {
                if ($VM) {
                    foreach ($Item in $VM) { 
                        $VMName = $Item.Name
                        if ($Item.state -ne "Running"){
                            Start-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName     
                        }

                        
                        $Networks     = Get-VMNetworks  -Computer $Computer -Credentials $Credentials -VMName $VMName
                        $RetryCounter = 1
                        while (@($Networks.IPAddresses).count -lt 2) {        
                            Write-Host "Waiting for network... ($($Networks.IPAddresses))"
                            Start-Sleep -seconds 1
                            $Networks = Get-VMNetworks  -Computer $Computer -Credentials $Credentials -VMName $VMName
                            if ($RetryCounter -gt $Global:MaxVMNetworkWaitRetry) {
                                Add-ToLog -Message "VM [$VMName] does not have ip addresses after [$Global:MaxVMNetworkWaitRetry] retries!" -logFilePath $ScriptLogFilePath -Display -Status "Error"
                                Exit 1
                            }
                            $RetryCounter ++
                        }
                        
                        $GuestIP       = ($Networks | Where-Object { $_.SwitchName -eq "LAN" } | Select-Object -ExpandProperty IPAddresses) | Select-Object -first 1
                        $GuestHostName = ([System.Net.Dns]::GetHostByAddress($GuestIP).Hostname).split(".") | Select-Object -first 1
                        
                        $GuestCredentials = Get-GuestCredentials $GuestHostName
                        $GuestOSName = Get-GuestWindowsOSVersion $VMName $GuestCredentials
                        
                        while (-not ($Answer -in @("1","2","3","4"))) {
                            $Answer = Read-Host "Select config type:
                            [1] Install updates
                            [2] Install remoting
                            [3] Configure
                            [4] Rename        
                            "                    
                            switch ($Answer) {
                                "1" { $ConfigType = "Install updates" }
                                "2" { $ConfigType = "Install remoting" }
                                "3" { $ConfigType = "Configure" }
                                "4" { $ConfigType = "Rename" }
                                Default { Write-host "Wrong input. Select number from the list!" -ForegroundColor Red }
                            }
                        }
                        
                        . ./ConfigWindowsHost.ps1 -InitGlobal $false -InitLocal $false -VM $Item  -GuestOSName $GuestOSName -GuestIP $GuestIP -GuestHostName $GuestHostName -GuestCredentials $GuestCredentials -ConfigType $ConfigType
                        
                        #$NewGuestName = Read-Host "Enter new guest name"
                    }
                }
                Else {
                    Add-ToLog -Message "VM not chosen! Aborted." -logFilePath $ScriptLogFilePath -Display -Status "Warning"
                    exit 1
                }
            }
        }               
        Default { Write-Host "Select existed value!" -ForegroundColor Red }
    }
}


$res = Import-Module AlexkVMUtils -PassThru -Force
if ($res) {

    $RemoteUser     = Get-VarFromAESFile $Global:GlobalKey1 $Global:UserValuePath
    $RemotePass     = Get-VarFromAESFile $Global:GlobalKey1 $Global:PasswordValuePath
    $Credentials    = New-Object System.Management.Automation.PSCredential -ArgumentList (Get-VarToString $RemoteUser), $RemotePass
    
    $ScriptBlock = {
        param ($Computer, $Credentials)

        $VMList = Get-ExistingVM -Computer $Computer -credentials $Credentials
        return $VMList
    }
        
    $Job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Computer, $Credentials


    
    Write-Host "Select action:
       [1 ] Show VM.                [7 ] Rename VM.            [13] Create new VM.           [18] Show VM checkpoints.                      [23] Connect VM console.
       [2 ] Start VM.               [8 ] Remove VM.            [14] Import exported VM.      [19] Restore VM checkpoint.                    [24] Connect VM RDP.
       [3 ] Stop VM.                [9 ] Move VM storage.      [15] Export existing VM.      [20] Create new checkpoint for existing VM.    [25] Connect VM SSH.
       [4 ] Restart VM.             [10] Add boot ISO.         [16] Set boot order.          [21] Remove VM checkpoint.                     [26] Config guest host.
       [5 ] Shutdown and start VM.  [11] Remove boot ISO.      [17] Set VM RAM size.         [22] Replace VM checkpoint.
       [6 ] Get VM settings.        [12] Optimize VM HDDs.          
       
    " -ForegroundColor Cyan

    $Actions = Read-Host
    if ($Actions -eq 0){
        Exit 0
    }
    if ($Actions.Contains(",")) {
        $Actions = $Actions.split(",")
    }
    Write-host "Getting VM list..." -ForegroundColor DarkCyan

    while ($Job.State -ne "Completed"){
        start-sleep -Seconds 1
    }

    $VMList      = Receive-Job $Job    
    $AllVMNames  = $VMList | Select-Object VMName, State,  VMId   
    $NotChooseVM = @(1,13,14)
    
    $NeedVM = @(Compare-Object -ReferenceObject $NotChooseVM -DifferenceObject $Actions | Where-Object { $_.SideIndicator -eq "=>"}).count
    if ($NeedVM) {
        $VMId = ($AllVMNames | Out-GridView -Title "Select VM." -PassThru ).VMId
        $Global:VM = $VMList | Where-Object { $_.id -in $VMId }
        Write-host "Selected VM:
        $(($Global:VM | Select-Object VMName, State,  VMId | format-table -AutoSize | out-string).trim())" -ForegroundColor DarkMagenta
    }
    Else {
        $Global:VM = $Null
    }

    if (@($Actions).count -gt 1){
        foreach ($Action in $Actions) {
            $Action = $Action.trim()
            Start-Action $Action $VMList
        }
    }
    Else {  
        $Actions = ($Actions | Select-Object -First 1).trim()    
        Start-Action $Actions $VMList
    }   
}
else {

}

################################# Script end here ###################################
. "$GlobalSettings\$SCRIPTSFolder\Finish.ps1" 