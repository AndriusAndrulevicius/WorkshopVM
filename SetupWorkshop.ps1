﻿. (Join-Path $PSScriptRoot "Install-VS2017Community.ps1")

try {
     $Folder = "C:\DOWNLOAD\AdobeReader"
     New-Item $Folder -itemtype directory -ErrorAction ignore | Out-Null
    
    # if (!(Test-Path $Filename)) {
    #     Log "Downloading Adobe Reader"
    #     $WebClient = New-Object System.Net.WebClient
    #     $WebClient.Download-File("http://ardownload.adobe.com/pub/adobe/reader/win/11.x/11.0.10/en_US/AdbeRdr11010_en_US.exe", $Filename)
    # }
    
    # Log "Installing Adobe Reader (this should only take a few minutes)"
    # Start-Process $Filename -ArgumentList "/msi /qn" -Wait -Passthru | Out-Null
    # Start-Sleep -Seconds 10

    #1CF Setup report builder
    Log "Installing .NET"
    Install-WindowsFeature Net-Framework-Core 

    Log "Installing SQL Report Builder"
    $sqlrepbuilderURL= "https://download.microsoft.com/download/2/E/1/2E1C4993-7B72-46A4-93FF-3C3DFBB2CEE0/ENU/x86/ReportBuilder3.msi"
    $sqlrepbuilderPath = "c:\download\ReportBuilder3.msi"

    Download-File -sourceUrl $sqlrepbuilderURL -destinationFile  $sqlrepbuilderPath
    Start-Process "C:\Windows\System32\msiexec.exe" -argumentList "/i $sqlrepbuilderPath /quiet" -wait

    #1CF Setup GIT
    Log "Installing GIT"
    $gitUrl = "https://www.dropbox.com/s/xezrif8i2210dx3/Git-2.15.0-64-bit.exe?dl=1"
    $gitSavePath = "C:\Download\git.exe"

    Download-File -sourceUrl $gitUrl -destinationFile $gitSavePath
    #$commandLineGitOptions = '/Dir="G:\Git" /SetupType=default /SP- /VERYSILENT /SUPPRESSMSGBOXES /FORCECLOSEAPPLICATIONS'
    $commandLineGitOptions = '/SetupType=default /SP- /VERYSILENT /SUPPRESSMSGBOXES /FORCECLOSEAPPLICATIONS'
    Start-Process -Wait -FilePath $gitSavePath -ArgumentList $commandLineGitOptions

    #1CF Setup P4Merge

    Log "Installing P4Merge"
    $p4mUrl = "https://www.dropbox.com/s/yvb0xxcitew43eh/p4vinst.exe?dl=1"
    $p4mSavePath = "C:\Download\p4m.exe"

    Download-File -sourceUrl $p4mUrl -destinationFile $p4mSavePath
    #$commandLineMergeOptions = '/b"C:\Downloads\p4vinst64.exe" /S /V"/qn ALLUSERS=1 REBOOT=ReallySuppress"'
    $commandLineMergeOptions = '/S /V"/qn ALLUSERS=1 REBOOT=ReallySuppress"'
    Start-Process -Wait -FilePath $p4mSavePath -ArgumentList $commandLineMergeOptions


    #1CF install Signtool not needed as visual studio will be installed    
    # $SignToolUrl = "https://download.microsoft.com/download/A/6/A/A6AC035D-DA3F-4F0C-ADA4-37C8E5D34E3D/winsdk_web.exe"
    # $signtoolPath = "C:\Download\winsdk_web.exe"
    # $commandLineSignToolOptions = '/SetupType=default /SP- /VERYSILENT /SUPPRESSMSGBOXES /FORCECLOSEAPPLICATIONS '
    
    # Download-File -sourceUrl $SignToolUrl -destinationFile $signtoolPath
    # Start-Process -Wait -FilePath $signtoolPath -ArgumentList $commandLineSignToolOptions
    


} catch {
    Log -color Red -line ($Error[0].ToString() + " (" + ($Error[0].ScriptStackTrace -split '\r\n')[0] + ")")
}
