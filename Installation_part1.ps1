<# Set Variables for Download URLs #>
$ScriptWebArchive = "https://parsecscripts.s3.amazonaws.com/Parsec-Cloud-Preparation-Tool-rt.zip" 
$TightVNCLocation = "https://www.tightvnc.com/download/2.8.59/tightvnc-2.8.59-gpl-setup-64bit.msi" 


<# Set AWS Credentials #>
Write-host "Please enter your AWS IAM Credntials:"
$AwsAccessKey = Read-host "Access Key"
$AwsSecretKey = Read-host "Secret Key"

<# Set Windows Administrator PAssword #>
$Password = Read-Host "Enter a new Windows Password for Administrator" -AsSecureString
$UserAccount = Get-LocalUser -Name "Administrator"
$UserAccount | Set-LocalUser -Password $Password
$VncPassword = Read-Host "Enter VNC Password (used for connecting via VNC Viewer) - can be the same as Windows Password" -MaskInput

<# Install NuGet Provider (Required for the remainder of the setup)#>
Install-PackageProvider -Name NuGet -Force

<# Run Parsec Installation Scripts #>
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 
$LocalArchivePath = "$ENV:UserProfile\Downloads\Parsec-Cloud-Preparation-Tool"  
(New-Object System.Net.WebClient).DownloadFile($ScriptWebArchive, "$LocalArchivePath.zip")  
Expand-Archive "$LocalArchivePath.zip" -DestinationPath $LocalArchivePath -Force  
CD $LocalArchivePath\Parsec-Cloud-Preparation-Tool-master\ | powershell.exe .\loader.ps1

Get-Job | Wait-Job

<# Install AWS Tools for Powershell, set credentials, and download NVidia Gaming driver from S3 #>
Install-Module -Name AWS.Tools.Installer -SkipPublisherCheck -Force

Get-Job | Wait-Job

Set-AWSCredential `
                 -AccessKey $AwsAccessKey `
                 -SecretKey $AwsSecretKey `
                 -StoreAs default

Get-Job | Wait-Job

$Bucket = "nvidia-gaming"
$KeyPrefix = "windows/latest"
$LocalPath = "$home\Desktop\NVIDIA"
$Objects = Get-S3Object -BucketName $Bucket -KeyPrefix $KeyPrefix -Region us-east-1
foreach ($Object in $Objects) {
    $LocalFileName = $Object.Key
    if ($LocalFileName -ne '' -and $Object.Size -ne 0) {
        $LocalFilePath = Join-Path $LocalPath $LocalFileName
        Copy-S3Object -BucketName $Bucket -Key $Object.Key -LocalFile $LocalFilePath -Region us-east-1
        $NewFileName = $LocalFileName + "_unzipped"
        Expand-Archive -LiteralPath $LocalFilePath -DestinationPath "$home\Desktop\GraphicsDriver"
    }
}

<# VNC Server Installation#>

$MSIInstallArguments = @(
    "/i"
    '"C:\Users\Administrator\Downloads\TightVNCServer.msi"'
    "/quiet"
    "/norestart"
    "SERVER_REGISTER_AS_SERVICE=1"
    "SERVER_ADD_FIREWALL_EXCEPTION=1"
    "VIEWER_ADD_FIREWALL_EXCEPTION=1"
    "SERVER_ALLOW_SAS=1"
    "SET_USEVNCAUTHENTICATION=1"
    "VALUE_OF_USEVNCAUTHENTICATION=1"
    "SET_PASSWORD=1"
    "VALUE_OF_PASSWORD=$VncPassword"
)
Write-host "Installing TightVNC Server"
$TightVNCLocalPath = "$ENV:UserProfile\Downloads\TightVNCServer"  
(New-Object System.Net.WebClient).DownloadFile($TightVNCLocation, "$TightVNCLocalPath.msi")  
Start-Process msiexec.exe -Wait -ArgumentList $MSIInstallArguments
$ipinfo = Invoke-RestMethod http://ipinfo.io/json | Select -exp ip
Write-host "TightVNC Server installed." 




Write-Host "Please wait before starting the NVidia Installation until Parsec has finished installing"
<# Launch Graphics Driver Installation #>
Start-Process -Filepath "C:\Users\Administrator\Desktop\GraphicsDriver\Windows\445.87_grid_vgaming_win10_64bit_international_whql.exe" -Wait
Write-Host "You have finished the first part of the installation. Please reboot, connect via VNC and launch the second PowerShell script. Connect to VNC Server using a VNC Viewer Application via IP Address and your Windows Password: "$ipinfo 
