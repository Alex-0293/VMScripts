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

$res = Import-Module AlexkVMUtils -PassThru -Force
if ($res) {

    $RemoteUser     = Get-VarFromAESFile $Global:GlobalKey1 $Global:UserValuePath
    $RemotePass     = Get-VarFromAESFile $Global:GlobalKey1 $Global:PasswordValuePath
    $Credentials    = New-Object System.Management.Automation.PSCredential -ArgumentList (Get-VarToString $RemoteUser), $RemotePass
    
    $ScriptBlock = {
        param ($Computer, $Credentials)

        $AllVM = Get-ExistingVM -Computer $Computer -credentials $Credentials
        return $AllVM
    }
        
    $Job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Computer, $Credentials


    
    Write-Host "Select action:
       [1 ] Show VM.                [7 ] Rename VM.            [12] Create new VM.           [17] Show VM checkpoints.                      [20] Connect VM console.
       [2 ] Start VM.               [8 ] Remove VM.            [13] Import exported VM.      [18] Restore VM checkpoint.                    [21] Connect VM RDP.
       [3 ] Stop VM.                [9 ] Move VM storage.      [14] Export existing VM.      [19] Create new checkpoint for existing VM.    [22] Connect VM SSH.
       [4 ] Restart VM.             [10] Add boot ISO.         [15] Set boot order. 
       [5 ] Shutdown and start VM.  [11] Remove boot ISO.      [16] Set VM RAM size.
       [6 ] Get VM settings.                  
       
    " -ForegroundColor Cyan

    $Answer = Read-Host  
    Write-host "Getting VM list..." -ForegroundColor DarkCyan
    while ($Job.State -ne "Completed"){
        start-sleep -Seconds 1
    }
    $AllVM      = Receive-Job $Job
    $AllVMNames = $AllVM | Select-Object VMName, State,  VMId    
    $AllVMInfo = $AllVM | Select-Object CreationTime, StatusDescriptions, VMName, State, Uptime, AutomaticStartDelay, Generation, Version, ProcessorCount, MemoryAssigned, MemoryDemand, ParentCheckpointName, Path, Notes  

    switch ($Answer) {
        "1" {
            Write-Host "[1] Show VM."
            $VMId = ($AllVMInfo | Out-GridView -OutputMode Single -Title "Select VM.").VMId
        }
        "2" {
            Write-Host "[2] Start VM."
            $VMId = ($AllVMNames | Out-GridView -OutputMode Single -Title "Select VM.").VMId
            $VM = $AllVM | Where-Object {$_.id -eq $VMId} 
            if ($VM) {
                $VMName = $VM.name 
                Start-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName  
                Start-VMConsole  -Computer $Computer -Credentials $Credentials -VM $VM    
            }
        }
        "3" {
            Write-Host "[3] Stop VM."     
            $VMId = ($AllVMNames | Out-GridView -OutputMode Single -Title "Select VM.").VMId
    $VM = $AllVM | Where-Object {$_.id -eq $VMId} 
            if ($VM) {
                $VMName = $VM.name 
                Stop-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName      
            }  
        }
        "4" {
            Write-Host "[4] Restart VM." 
            $VMId = ($AllVMNames | Out-GridView -OutputMode Single -Title "Select VM.").VMId
            $VM = $AllVM | Where-Object {$_.id -eq $VMId} 
            if ($VM) {
                $VMName = $VM.name 
                Restart-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName -RestartMode "Reset" 
            }
        }
        "5" {
            Write-Host "[5] Shutdown and start VM." 
            $VMId = ($AllVMNames | Out-GridView -OutputMode Single -Title "Select VM.").VMId
            $VM = $AllVM | Where-Object {$_.id -eq $VMId} 
            if ($VM) {
                $VMName = $VM.name 
                Restart-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName -RestartMode "Shutdown" 
                Start-VMConsole  -Computer $Computer -Credentials $Credentials -VM $VM
            }
        }
        "6" {
            Write-Host "[6] Get VM settings."
            $VMId = ($AllVMNames | Out-GridView -OutputMode Single -Title "Select VM.").VMid
            $VM = $AllVM | Where-Object {$_.id -eq $VMId} 
            if ($VM) {
                Get-VMSettings -Computer $Computer -Credentials $Credentials -VM $VM   
            } 
        }
        "7" {
            Write-Host "[7] Rename VM."  
            $VMId = ($AllVMNames | Out-GridView -OutputMode Single -Title "Select VM.").VMId
            $VM = $AllVM | Where-Object {$_.id -eq $VMId} 
            if ($VM) {
                $VMName = $VM.name
                $NewVMName = Read-Host "Enter new name for VM [$VMName]"
                Rename-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName -NewVMName $NewVMName                       
            }  
        }
        "8" {
            Write-Host "[8] Remove VM."        
            $VMId = ($AllVMNames | Out-GridView -OutputMode Single -Title "Select VM.").VMId
            $VM = $AllVM | Where-Object {$_.id -eq $VMId} 
            if ($VM) {
                $VMName = $VM.name               
                $LastState = $VM.state

                if ($LastState -ne "Off") {
                    Stop-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                }  

                Remove-CustomVM -Computer $Computer -Credentials $Credentials -VM $VM -DeleteVMFolder                       
            }   
        }
        "9" {
            Write-Host "[9] Move VM storage"
            $VMId = ($AllVMNames | Out-GridView -OutputMode Single -Title "Select VM.").VMId
            $VM = $AllVM | Where-Object {$_.id -eq $VMId} 
            if ($VM) {
                $VMName = $VM.name 
                $VMPath = $VM.Path
                $NewVMPath = Read-Host "Enter new path for VM [$VMName] with path [$VMPath]"
                Move-CustomVMStorage -Computer $Computer -Credentials $Credentials -VM $VM -NewStoragePath $NewVMPath
            }  
        }
        "10" {
            Write-Host "[10] Add boot ISO"
            $VMId = ($AllVMNames | Out-GridView -OutputMode Single -Title "Select VM.").VMId
            $VM = $AllVM | Where-Object {$_.id -eq $VMId} 
            if ($VM) {
                $VMName = $VM.name 
                $ISOFilePath = Show-OpenDialog -Type "file" -InitPath $IsoPath -Description "Choose ISO file." -FileFilter "ISO Files (*.iso)|*.iso"
                Add-BootISO -Computer $Computer -Credentials $Credentials -VMName $VMName -ISOFilePath $ISOFilePath
                Get-VMSettings -Computer $Computer -Credentials $Credentials -VM $VM  
            } 
        }
        "11" {
            Write-Host "[11] Remove boot ISO."
            $VMId = ($AllVMNames | Out-GridView -OutputMode Single -Title "Select VM.").VMId
            $VM = $AllVM | Where-Object {$_.id -eq $VMId} 
            if ($VM) {
                $VMName = $VM.name 
                Remove-DVDWithISO -Computer $Computer -Credentials $Credentials -VMName $VMName
                Get-VMSettings -Computer $Computer -Credentials $Credentials -VM $VM  
            }  
        }
        "12" {
            Write-Host "[12] Create new VM."  
            if (-not $NewVMName) {
                while (-not $NewVMName){
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
        "13" {
            Write-Host "[13] Import exported VM."
            $ExportPath     = Convert-FSPath $Global:InitialExportPath $Computer
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
        "14" {
            Write-Host "[14] Export existing VM."
            $VMId = ($AllVMNames | Out-GridView -OutputMode Single -Title "Select VM.").VMId
            $VM = $AllVM | Where-Object {$_.id -eq $VMId} 
            if ($VM) { 
                $VMName = $VM.name
                $LastState = $VM.state

                if ($LastState -ne "Off") {
                    Stop-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                }

                Export-ExistingVM  -Computer $Computer -Credentials $Credentials -VM $VM  -ExportPath $Global:InitialExportPath -RemoveIndex

                if ($LastState -eq "Running") {
                    Start-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                }

            }
        }
        "15" {
            Write-Host "[15] Set boot order."
            $VMId = ($AllVMNames | Out-GridView -OutputMode Single -Title "Select VM.").VMId
            $VM = $AllVM | Where-Object {$_.id -eq $VMId} 
            if ($VM) {
                $VMName = $VM.name 
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
        "16" {
            Write-Host "[16] Set VM RAM size."
            $VMId = ($AllVMNames | Out-GridView -OutputMode Single -Title "Select VM.").VMId
            $VM = $AllVM | Where-Object {$_.id -eq $VMId} 
            if ($VM) {
                $VMName = $VM.name            
                [int] $Answer = Read-Host "Enter new VM startup RAM size in Gb."
                $StartupRAMSize = $Answer * ([math]::Pow(1024, 3))
                Set-VMRamSize -VMName $VMName  -Computer $Computer -Credentials $Credentials -StartupRAMSize $StartupRAMSize
            } 
        }
        "17" {
            Write-Host "[17] Show VM checkpoints."
            $VMName = "*"
            $VMSnapshot = Get-ExistingVMSnapshots -Computer $Computer -credentials $Credentials -VMName $VMName | Out-GridView -OutputMode Single -Title "Select VM Snapshot." 
        }
        "18" {
            Write-Host "[18] Restore VM checkpoint."    
            $VMId = ($AllVMNames | Out-GridView -OutputMode Single -Title "Select VM.").VMId
            $VM = $AllVM | Where-Object {$_.id -eq $VMId} 
            if ($VM) {
                $VMName = $VM.name 
                $VMSnapshot = Get-ExistingVMSnapshots -Computer $Computer -credentials $Credentials -VMName $VMName | Out-GridView -OutputMode Single -Title "Select VM Snapshot to restore." 
                if ($VMSnapshot) {                 
                    $LastState = $VM.state

                    if ($LastState -ne "Off") {
                        Stop-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                    }  

                    $VMSnapshotName = $VMSnapshot.Name
                    Restore-CustomVMSnapshot -Computer $Computer -Credentials $Credentials -VMName $VMName -SnapshotName $VMSnapshotName

                    if ($LastState -eq "Running") {
                        Start-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                    }

                }              
            } 
        }
        "19" {
            Write-Host "[19] Create new checkpoint for existing VM."      
            $Answer = Read-Host "Enter checkpoint name or select from the list:
            [1] Clean install
            [2] Installed updates
            [3] Installed remoting and KVM tools
            [4] Configured        
        "
            $VMId = ($AllVMNames | Out-GridView -OutputMode Single -Title "Select VM.").VMId
            $VM = $AllVM | Where-Object {$_.id -eq $VMId} 
            $VMName = $VM.Name
            switch ($Answer) {
                "1" { $CheckpointName = "Clean install" }
                "2" { $CheckpointName = "Installed updates" }
                "3" { $CheckpointName = "Installed remoting and KVM tools" }
                "4" { $CheckpointName = "Configured" }
                Default { [string] $CheckpointName = $Answer }
            }
            $VM = Get-ExistingVM  -Computer $Computer -Credentials $Credentials -VMName $VMName
            if ($VM) {
                $LastState = $VM.state

                if ($LastState -ne "Off") {
                    Stop-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                }   

                Add-VMCheckPoint -Computer $Computer -Credentials $Credentials -VMName $VMName -NewCheckpointName $CheckpointName

                if ($LastState -eq "Running") {
                    Start-CustomVM -Computer $Computer -Credentials $Credentials -VMName $VMName
                }
            }
        }
        "20" {
            Write-Host "[20] Connect VM console."
            $VMId = ($AllVMNames | Out-GridView -OutputMode Single -Title "Select VM.").VMId
            $VM = $AllVM | Where-Object { $_.id -eq $VMId } 
            if ($VM) {
                Start-VMConsole  -Computer $Computer -Credentials $Credentials -VM $VM    
            }
        }
        "21" {
            Write-Host "[21] Connect VM RDP."
            $Global:MaxVMNetworkWaitRetry = 100
            $VMId = ($AllVMNames | Out-GridView -OutputMode Single -Title "Select VM.").VMId
            $VM = $AllVM | Where-Object { $_.id -eq $VMId } 
            if ($VM) {
                $VMName = $VM.Name
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
                Start-VMConsole  -Computer $Computer -Credentials $Credentials -IP $Global:VMIp  
            }
        }
        Default {Write-host "Select existed value!" -ForegroundColor Red}
    }
}
else {

}

################################# Script end here ###################################
. "$GlobalSettings\$SCRIPTSFolder\Finish.ps1" 