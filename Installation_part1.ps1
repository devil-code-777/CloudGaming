<# Set Variables for Download URLs #>
$ScriptWebArchive = "https://parsecscripts.s3.amazonaws.com/Parsec-Cloud-Preparation-Tool-rt.zip" 

<# Set AWS Credentials #>
Write-host "Please enter your AWS IAM Credntials:"
$AwsAccessKey = Read-host "Access Key"
$AwsSecretKey = Read-host "Secret Key" -AsSecureString

<# Set Windows Administrator PAssword #>
$Password = Read-Host "Enter a new Windows Password for Administrator" -AsSecureString
$UserAccount = Get-LocalUser -Name "Administrator"
$UserAccount | Set-LocalUser -Password $Password

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

Write-Host "Please wait before starting the NVidia Installation until Parsec has finished installing"
<# Launch Graphics Driver Installation #>
Start-Process -Filepath "C:\Users\Administrator\Desktop\GraphicsDriver\Windows\445.87_grid_vgaming_win10_64bit_international_whql.exe" -Wait