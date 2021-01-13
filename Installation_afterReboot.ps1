<# Set Variables for Download URLs #>
$VCRedistLocation = "https://aka.ms/vs/16/release/vc_redist.x86.exe"  
$SteamLocation = "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe"  
$OriginLocation = "https://www.dm.origin.com/download"  

<# Set VM Resolution #>
$Screenwidth = Read-Host "Set your Screen width (Pixels) - default 1920"
    if($Screenwidth -eq "") {
    $Screenwidth = 1920
        Write-host "Screenwidth set to 1920px"}
        else {Write-host "Screenwidth set to $Screenwidth"}
$Screenheight = Read-Host "Set your Screen height (Pixels) - default 1080"
    if($Screenheight -eq "") {
    $Screenheight = 1080
        Write-host "Screenheight set to 1080px"}
        else {Write-host "Screenheight set to $Screenwidth"}
Write-host "You have set the screen resolution to $Screenwidth x $Screenheight. This will be reapplied at every startup." 


<# Once Graphics driver is installed: Update Registry #>
"Graphics Driver Installed?"
$ReadHost = Read-Host "(Y/N)"
Switch ($ReadHost){
    Y {
         Write-host "Setting up Windows Registry Entries for NVidia Gaming Drivers"
         New-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global" -Name "vGamingMarketplace" -PropertyType "DWord" -Value "2"
         Invoke-WebRequest -Uri "https://nvidia-gaming.s3.amazonaws.com/GridSwCert-Archive/GridSwCert-Windows_2020_04.cert" -OutFile "$Env:PUBLIC\Documents\GridSwCert.txt"
         New-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global\GridLicensing" -Name "FeatureType" -PropertyType "DWord" -Value "0"
         New-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global\GridLicensing" -Name "IgnoreSP" -PropertyType "DWord" -Value "1"
         cd "C:\Program Files\NVIDIA Corporation\NVSMI"
         .\nvidia-smi -ac "5001,1590"
         Write-host "Updating your Screen resolution"
         Set-DisplayResolution -Width $Screenwidth -Height $Screenheight -Force
        }
    N {
        Return
        }
    }

#Create Scripts to set resolution each time at startup
Write-host "Creating Scripts Directory in C:\Users\Administrator\Documents\Scripts"
New-Item -Path 'C:\Users\Administrator\Documents\Scripts' -ItemType Directory
New-Item C:\Users\Administrator\Documents\Scripts\SetResolution.ps1
Set-Content C:\Users\Administrator\Documents\Scripts\SetResolution.ps1 'Set-DisplayResolution -Width $Screenwidth -Height $Screenwidth -Force'
New-Item C:\Users\Administrator\Documents\Scripts\Startup.bat
Set-Content C:\Users\Administrator\Documents\Scripts\Startup.bat '@ECHO OFF
PowerShell -Command "Set-ExecutionPolicy Unrestricted" >> "%TEMP%\StartupLog.txt" 2>&1
PowerShell C:\Users\Administrator\Documents\Scirpts\SetResolution.ps1 >> "%TEMP%\StartupLog.txt" 2>&1'
Write-host "Created Script files SetResolutions.ps1 and Startup.bat"
Write-host "Creating a task schedule to run startup.bat at every Windows Startup."

$A = New-ScheduledTaskAction -Execute "C:\Users\Administrator\Documents\Scripts\Startup.bat"
$T = New-ScheduledTaskTrigger -AtLogon
$P = New-ScheduledTaskPrincipal "Administrator"
$S = New-ScheduledTaskSettingsSet 
$D = New-ScheduledTask -Action $A -Principal $P -Trigger $T -Settings $S
Register-ScheduledTask -TaskName "SetResolution" -InputObject $D 

Write-host "New Task 'SetResolution' created."

<# Install Visual C++ Redistributable 2015 32Bit (necessary for installing Origin)#>
Write-host "Installing Visual C++ Redistributable 2015 32Bit (prerequisite for Origin)"
$VCRedistLocalPath = "$ENV:UserProfile\Downloads\vc_redist.x86"  
(New-Object System.Net.WebClient).DownloadFile($VCRedistLocation, "$VCRedistLocalPath.exe")  
Start-Process -Filepath "$VCRedistLocalPath.exe" -ArgumentList '/S /quiet /norestart' -Wait
Write-host "Visual C++ Installed"


$ReadHostSteam = Read-Host "Do you want to install Steam? (Y/N)"
Switch ($ReadHostSteam){
    Y {
        <# Download and Install Steam #>
        Write-host "Installing Steam"
        $SteamLocalPath = "$ENV:UserProfile\Downloads\Steam"  
        (New-Object System.Net.WebClient).DownloadFile($SteamLocation, "$SteamLocalPath.exe") 
        Start-Process -Filepath "$SteamLocalPath.exe" -ArgumentList '/S' -Wait
        Write-host "Steam installed"
        }
    N {
        Return
        }
    }

$ReadHostSteam = Read-Host "Do you want to install EA Origin? (Y/N)"
Switch ($ReadHostSteam){
    Y {
        <# Download Origin #>
        "Installing Origin - this is a manual setup process. Please take over once the Origin Window opens"
        $OriginLocalPath = "$ENV:UserProfile\Downloads\Origin" 
        (New-Object System.Net.WebClient).DownloadFile($OriginLocation, "$OriginLocalPath.exe") 
        Start-Process -Filepath "$OriginLocalPath.exe"
        }
    N {
        Return
        }
    }

<# TODO: Add cleanup script#>
<# TODO: Update Display settings https://12noon.com/?page_id=641#>