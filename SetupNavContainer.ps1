if (!(Test-Path function:Log)) {
    function Log([string]$line, [string]$color = "Gray") {
        ("<font color=""$color"">" + [DateTime]::Now.ToString([System.Globalization.DateTimeFormatInfo]::CurrentInfo.ShortTimePattern.replace(":mm",":mm:ss")) + " $line</font>") | Add-Content -Path "c:\demo\status.txt"
        Write-Host -ForegroundColor $color $line 
    }
}

Import-Module -name navcontainerhelper -DisableNameChecking

. (Join-Path $PSScriptRoot "settings.ps1")



$imageName = $navDockerImage.Split(',')[0]

docker ps --filter name=$containerName -a -q | % {
    Log "Removing container $containerName"
    docker rm $_ -f | Out-Null
}

$BackupsUrl = "https://www.dropbox.com/s/5ue798dqqgbq273/DBBackups.zip?dl=1"
$BackupFolder = "C:\DOWNLOAD\Backups"
$Filename = "$BackupFolder\dbBackups.zip"
New-Item $BackupFolder -itemtype directory -ErrorAction ignore | Out-Null
if (!(Test-Path $Filename)) {
    Download-File -SourceUrl $BackupsUrl  -destinationFile $Filename
}

[Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.Filesystem") | Out-Null
[System.IO.Compression.ZipFile]::ExtractToDirectory($Filename,$BackupFolder )

$ServersToCreate = Import-Csv "c:\demo\servers.csv"
$ServersToCreate |%{
    
    $containerName = $_.Server
    $bakupPath = "$BackupFolder\$($_.Backup)"
    $containerFolder = Join-Path C:\DEMO\Extensions\ $containerName
    New-Item -Path $containerFolder -ItemType Directory -ErrorAction Ignore | Out-Null
    $myFolder = Join-Path $containerFolder "my"
    New-Item -Path $myFolder -ItemType Directory -ErrorAction Ignore | Out-Null

    $dbBackupFileName = Split-Path $bakupPath -Leaf
    Copy-Item -Path $bakupPath -Destination "$myFolder\" -Recurse -Force 

    Start-Sleep -Seconds 10
    
    
#    CreateDevServerContainer -devContainerName $d -devImageName 'navdocker.azurecr.io/dynamics-nav:devpreview-september'
   # Copy-Item -Path "c:\myfolder\SetupNavUsers.ps1" -Destination "c:\DEMO\$d\my\SetupNavUsers.ps1"

   $securePassword = ConvertTo-SecureString -String $adminPassword -Key $passwordKey
   $credential = New-Object System.Management.Automation.PSCredential($navAdminUsername, $securePassword)
   $additionalParameters = @("--env bakfile=""C:\Run\my\${dbBackupFileName}""",
                             "--env RemovePasswordKeyFile=N"                             
                             )
                             #"--env publicFileSharePort=8080",                             
                             #--publish  8080:8080",
                             #"--publish  443:443", 
                             #"--publish  7046-7049:7046-7049",                              
                             #"
   $myScripts = @()
   Get-ChildItem -Path "c:\myfolder" | % { $myscripts += $_.FullName }
   
   
   
   Log "Running $imageName (this will take a few minutes)"
   New-NavContainer -accept_eula `
                    -containerName $containerName `
                    -auth Windows `
                    -includeCSide `
                    -doNotExportObjectsToText `
                    -credential $credential `
                    -additionalParameters $additionalParameters `
                    -myScripts $myscripts `
                    -imageName $imageName
   
   

    Copy-Item -Path "c:\DEMO\$containerName\my\*.vsix" -Destination "c:\DEMO\" -Recurse -Force -ErrorAction Ignore
    Copy-Item -Path "C:\DEMO\RestartNST.ps1" -Destination "c:\DEMO\$containerName\my\RestartNST.ps1" -Force -ErrorAction Ignore

    $country = Get-NavContainerCountry -containerOrImageName $imageName
    $navVersion = Get-NavContainerNavVersion -containerOrImageName $imageName
    $locale = Get-LocaleFromCountry $country
    
    $containerFolder = "C:\Demo\Extensions\$containerName"
    Log "Copying .vsix and Certificate to $containerFolder"
    docker exec -it $containerName powershell "copy-item -Path 'C:\Run\*.vsix' -Destination '$containerFolder' -force
    copy-item -Path 'C:\Run\*.cer' -Destination $containerFolder -force
    copy-item -Path 'C:\Program Files\Microsoft Dynamics NAV\*\Service\CustomSettings.config' -Destination '$containerFolder' -force
    if (Test-Path 'c:\inetpub\wwwroot\http\NAV' -PathType Container) {
        [System.IO.File]::WriteAllText('$containerFolder\clickonce.txt','http://${publicDnsName}:8080/NAV')
    }"
    [System.IO.File]::WriteAllText("$containerFolder\Version.txt",$navVersion)
    [System.IO.File]::WriteAllText("$containerFolder\Country.txt", $country)

    # Install Certificate on host
$certFile = Get-Item "$containerFolder\*.cer"
if ($certFile) {
    $certFileName = $certFile.FullName
    Log "Importing $certFileName to trusted root"
    $pfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2 
    $pfx.import($certFileName)
    $store = new-object System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreName]::Root,"localmachine")
    $store.open("MaxAllowed") 
    $store.add($pfx) 
    $store.close()
}

}



Log "Using image $imageName"
Log "Country $country"
Log "Version $navVersion"
Log "Locale $locale"

# Copy .vsix and Certificate to container folder
$demoFolder= "C:\Demo\"
$containerFolder = "C:\Demo\Extensions\$containerName"
Log "Copying .vsix and Certificate to $demoFolder"
docker exec -it $containerName powershell "copy-item -Path 'C:\Run\*.vsix' -Destination '$demoFolder' -force
copy-item -Path 'C:\Run\*.cer' -Destination $demoFolder -force"


Log -color Green "Container output"
docker logs $containerName | % { log $_ }

Log -color Green "Container setup complete!"
