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
    . "$env:AlexKFrameworkInitScript" -MyScriptRoot (Split-Path $PSCommandPath -Parent) -InitGlobal $InitGlobal -InitLocal $True
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
Function Set-Encrypt($Array) {
    foreach($item in $array) {    
        if ((Test-Path $item.AESKeyPath)) {
            $KeyData = convertto-securestring -String $Item.KeyData -AsPlainText -Force
            $Data = ConvertFrom-SecureString -Key (get-content $item.AESKeyPath) $KeyData 
            Set-Content $item.KeyFileName -Value $Data
        }
        else {
            write-host "AES file $($item.AESKeyPath) not exist."
        }       
    }
}

if (Test-Path $ExportedXMLFilePath ) {
    $XMLData = New-Object XML
    $XMLData.load($ExportedXMLFilePath)
    $Groups = $XMLData.KeePassFile.root.Group.Group

    [array] $Data = @()
    foreach ($Group in $Groups) {    
        $Strings = $Group.Entry.string
        $Counter = 1
        $Records = @() 
        $PSO = New-Object -TypeName "PSCustomObject"
        foreach ($Item in $Strings) {
            $Remain= $Counter % 5         
            if ($Remain){            
                if ($Item.key -ne "Password"){
                    Add-Member -InputObject $PSO -MemberType NoteProperty -Name $Item.key -Value $Item.value 
                }
                Else {
                    Add-Member -InputObject $PSO -MemberType NoteProperty -Name $Item.key -Value $Item.value."#text"
                } 
            }
            else {
                Add-Member -InputObject $PSO -MemberType NoteProperty -Name $Item.key -Value $Item.value 
                $Records += $PSO
                $PSO = New-Object -TypeName "PSCustomObject"
            }
            $Counter ++
        }

        #$Records | Format-Table
        $UserRecord = $Records | Where-Object { $_.Title -eq "username" } 

        $PSO = [PSCustomObject]@{
            Username = $UserRecord.UserName
            Password = $UserRecord.Password
            Group    = $Group.Name       
        }

        $Data += $PSO
    }

    $Data | Format-Table

    $AESKeyName     = split-path $Global:VMKeyPath -Leaf 

    $SettingPath    = "$ProjectRoot\$VALUESFolder"
    $AESKeyFilePath = "$ProjectRoot\$KEYSFolder\$AESKeyName"
    if (-not (Test-Path $AESKeyFilePath)) {
        if ( -not (test-path "$ProjectRoot\$VALUESFolder") ) {
            new-item -Path "$ProjectRoot\$VALUESFolder" -ItemType Directory
        }    
        if ( -not (Test-Path "$ProjectRoot\$KEYSFolder") ) {
            New-Item -Path "$ProjectRoot\$KEYSFolder" -ItemType Directory
        }
        
        $AESKey = New-Object Byte[] 32
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($AESKey)
        $AESKey | out-file $AESKeyFilePath
    }
    Else {
        $AESKey = Get-Content $AESKeyFilePath
    }

    foreach ($Item in $Data) {
        $DomainOrHostName = $Item.Group
        $Username         = $Item.Username
        $FileName         = "$($DomainOrHostName)_$($Username)_Login.dat"

        $Array = @()
        $PSO = [PSCustomObject]@{
            KeyFileName = "$SettingPath\$FileName"
            KeyData     = $Username
            AESKeyPath  = $AESKeyFilePath 
        }
        $Array += $PSO

        $FileName = "$($DomainOrHostName)_$($Username)_Password.dat"
        $PSO = [PSCustomObject]@{
            KeyFileName = "$SettingPath\$FileName"
            KeyData     = $Item.Password
            AESKeyPath  = $AESKeyFilePath 
        }
        $Array += $PSO
        
        Set-Encrypt $Array
    }
    # rundll32.exe keymgr.dll, KRShowKeyMgr    
}

################################# Script end here ###################################
. "$GlobalSettings\$SCRIPTSFolder\Finish.ps1" 