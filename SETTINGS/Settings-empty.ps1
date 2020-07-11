# Rename this file to Settings.ps1
######################### value replacement #####################
    
    [string]$Global:Computer                      = ""         
    [string]$Global:UserValuePath                 = ""         
    [string]$Global:PasswordValuePath             = ""         
    [string]$Global:VMKeyPath                     = ""         
    [string]$Global:NewVMName                     = ""         
    [string]$Global:SShIdentityFilePath           = ""         
    [string]$Global:ExportedXMLFilePath           = ""          # Exported repo and sub folders from Keepass
    [string]$Global:SafeModeAdministratorPassword = ""          # Exported repo and sub folders from Keepass

######################### no replacement ########################    
    [string]$Global:DefaultBrowserPath         = "C:\Program Files\Mozilla Firefox\firefox.exe"
    [string]$Global:BrowserStartArgument       = "-private-window"
    [string]$Global:InitialExportPath          = "G:\EXPORT\REPO\"
    [string]$Global:ImportPath                 = "D:\DATA\HYPER-V\IMPORTED"
    [string]$Global:RDPShortcutsFolderPath     = "G:\RDP\"
    [string]$Global:IsoPath                    = "\\srv1\g$\ISO\"   
    [string]$Global:BGInfoInstallerURL         = "https://download.sysinternals.com/files/BGInfo.zip"
    [string]$Global:BGInfoInstallerSettingsURL = "https://raw.githubusercontent.com/Alex-0293/VMScripts/master/DATA/custom.bgi"
    [string]$Global:TaskbandURL                = "https://raw.githubusercontent.com/Alex-0293/VMScripts/master/DATA/TASKBAND/taskband.zip"
    [string]$Global:DomainName                 = "Test.local"
    [Array] $Global:RouteableSwitches          = @("LAN", "EXT" )
 
    [int16] $Global:MaxVMNetworkWaitRetry      = 10
    

    
    $LAN = "LAN"
    $WAN = "EXT"
    $LAN_WAN = @($LAN, $WAN)

    [PSCustomObject] $Global:NetConfigs = [PSCustomObject]@{
        LAN = $Lan
        WAN = $Wan
        LAN_WAN = $LAN_WAN
    }

    [PSCustomObject] $Global:StartupConfigs = [PSCustomObject]@{
        CD_IDE_NET_FDD = @("CD", "IDE", "LegacyNetworkAdapter", "Floppy")
        IDE_CD_NET_FDD = @("IDE", "CD", "LegacyNetworkAdapter", "Floppy")
        NET_IDE_CD_FDD = @("LegacyNetworkAdapter","IDE", "CD", "Floppy")
    }

    $VM_Gen1_4CPU_M2Gb_H64Gb = @{
        
        generation                  = 1
        memorySize                  = 2 * ([math]::Pow(1024, 3))
        processorCount              = 4
        enabledNestedVirtualization = $false
        newVHDSizeBytes             = 64 * ([math]::Pow(1024, 3))
        bootFromNetwork             = $false
        addToCluster                = $false
        useDefaultStorage           = $false 
    }
    $VM_Gen1_4CPU_M4Gb_H64Gb = @{
        
        generation                  = 1
        memorySize                  = 4 * ([math]::Pow(1024, 3))
        processorCount              = 4
        enabledNestedVirtualization = $false
        newVHDSizeBytes             = 64 * ([math]::Pow(1024, 3))
        bootFromNetwork             = $false
        addToCluster                = $false
        useDefaultStorage           = $false 
    }
    $VM_Gen1_4CPU_M8Gb_H64Gb = @{
        
        generation                  = 1
        memorySize                  = 8 * ([math]::Pow(1024, 3))
        processorCount              = 4
        enabledNestedVirtualization = $false
        newVHDSizeBytes             = 64 * ([math]::Pow(1024, 3))
        bootFromNetwork             = $false
        addToCluster                = $false
        useDefaultStorage           = $false 
    }
    $VM_Gen1_4CPU_M2Gb_H128Gb = @{
        
        generation                  = 1
        memorySize                  = 2 * ([math]::Pow(1024, 3))
        processorCount              = 4
        enabledNestedVirtualization = $false
        newVHDSizeBytes             = 128 * ([math]::Pow(1024, 3))
        bootFromNetwork             = $false
        addToCluster                = $false
        useDefaultStorage           = $false 
    }
    $VM_Gen1_4CPU_M4Gb_H128Gb = @{
        
        generation                  = 1
        memorySize                  = 4 * ([math]::Pow(1024, 3))
        processorCount              = 4
        enabledNestedVirtualization = $false
        newVHDSizeBytes             = 128 * ([math]::Pow(1024, 3))
        bootFromNetwork             = $false
        addToCluster                = $false
        useDefaultStorage           = $false 
    }
    $VM_Gen1_4CPU_M8Gb_H128Gb = @{
        
        generation                  = 1
        memorySize                  = 8 * ([math]::Pow(1024, 3))
        processorCount              = 4
        enabledNestedVirtualization = $false
        newVHDSizeBytes             = 128 * ([math]::Pow(1024, 3))
        bootFromNetwork             = $false
        addToCluster                = $false
        useDefaultStorage           = $false 
    }
    $VM_Gen2_4CPU_M2Gb_H64Gb = @{
        
        generation                  = 2
        memorySize                  = 2 * ([math]::Pow(1024, 3))
        processorCount              = 4
        enabledNestedVirtualization = $false
        newVHDSizeBytes             = 64 * ([math]::Pow(1024, 3))
        bootFromNetwork             = $false
        addToCluster                = $false
        useDefaultStorage           = $false 
    }
    $VM_Gen2_4CPU_M4Gb_H64Gb = @{
        
        generation                  = 2
        memorySize                  = 4 * ([math]::Pow(1024, 3))
        processorCount              = 4
        enabledNestedVirtualization = $false
        newVHDSizeBytes             = 64 * ([math]::Pow(1024, 3))
        bootFromNetwork             = $false
        addToCluster                = $false
        useDefaultStorage           = $false 
    }
    $VM_Gen2_4CPU_M8Gb_H64Gb = @{
        
        generation                  = 2
        memorySize                  = 8 * ([math]::Pow(1024, 3))
        processorCount              = 4
        enabledNestedVirtualization = $false
        newVHDSizeBytes             = 64 * ([math]::Pow(1024, 3))
        bootFromNetwork             = $false
        addToCluster                = $false
        useDefaultStorage           = $false 
    }
    $VM_Gen2_4CPU_M2Gb_H128Gb = @{
        
        generation                  = 2
        memorySize                  = 2 * ([math]::Pow(1024, 3))
        processorCount              = 4
        enabledNestedVirtualization = $false
        newVHDSizeBytes             = 128 * ([math]::Pow(1024, 3))
        bootFromNetwork             = $false
        addToCluster                = $false
        useDefaultStorage           = $false 
    }
    $VM_Gen2_4CPU_M4Gb_H128Gb = @{
        
        generation                  = 2
        memorySize                  = 4 * ([math]::Pow(1024, 3))
        processorCount              = 4
        enabledNestedVirtualization = $false
        newVHDSizeBytes             = 128 * ([math]::Pow(1024, 3))
        bootFromNetwork             = $false
        addToCluster                = $false
        useDefaultStorage           = $false 
    }
    $VM_Gen2_4CPU_M8Gb_H128Gb = @{
        
        generation                  = 2
        memorySize                  = 8 * ([math]::Pow(1024, 3))
        processorCount              = 4
        enabledNestedVirtualization = $false
        newVHDSizeBytes             = 128 * ([math]::Pow(1024, 3))
        bootFromNetwork             = $false
        addToCluster                = $false
        useDefaultStorage           = $false 
    }
    

    [PSCustomObject] $Global:VMConfigs = [PSCustomObject]@{
        VM_Gen1_4CPU_M2Gb_H64Gb  = $VM_Gen1_4CPU_M2Gb_H64Gb
        VM_Gen1_4CPU_M4Gb_H64Gb  = $VM_Gen1_4CPU_M4Gb_H64Gb
        VM_Gen1_4CPU_M8Gb_H64Gb  = $VM_Gen1_4CPU_M8Gb_H64Gb
        VM_Gen1_4CPU_M2Gb_H128Gb = $VM_Gen1_4CPU_M2Gb_H128Gb
        VM_Gen1_4CPU_M4Gb_H128Gb = $VM_Gen1_4CPU_M4Gb_H128Gb
        VM_Gen1_4CPU_M8Gb_H128Gb = $VM_Gen1_4CPU_M8Gb_H128Gb
        VM_Gen2_4CPU_M2Gb_H64Gb  = $VM_Gen2_4CPU_M2Gb_H64Gb
        VM_Gen2_4CPU_M4Gb_H64Gb  = $VM_Gen2_4CPU_M4Gb_H64Gb
        VM_Gen2_4CPU_M8Gb_H64Gb  = $VM_Gen2_4CPU_M8Gb_H64Gb
        VM_Gen2_4CPU_M2Gb_H128Gb = $VM_Gen2_4CPU_M2Gb_H128Gb
        VM_Gen2_4CPU_M4Gb_H128Gb = $VM_Gen2_4CPU_M4Gb_H128Gb
        VM_Gen2_4CPU_M8Gb_H128Gb = $VM_Gen2_4CPU_M8Gb_H128Gb
    }    

    [bool]  $Global:LocalSettingsSuccessfullyLoaded = $true
    # Error trap
    trap {
        $Global:LocalSettingsSuccessfullyLoaded = $False
        exit 1
    }
