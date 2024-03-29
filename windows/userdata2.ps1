<powershell>
$StateFile = "C:\Temp\userdata_state.txt"
If(-Not (Test-Path -Path $StateFile))
{
  # PHASE 1

  # Close the instance to WinRM connections until instance is ready (probably already closed, but just in case)
  Start-Process -FilePath "winrm" -ArgumentList "set winrm/config/service/auth @{Basic=`"false`"}" -Wait

  # Set the admin password for WinRM connections
  $Admin = [adsi]("WinNT://./Administrator, user")
  $Admin.psbase.invoke("SetPassword", "${tfi_rm_pass}")
  
  # Create state file so after reboot it will know
  New-Item -Path $StateFile -ItemType "file" -Force

  # Make it so that userdata will run again after reboot
  $EC2SettingsFile="C:\Program Files\Amazon\Ec2ConfigService\Settings\Config.xml"
  $Xml = [xml](Get-Content $EC2SettingsFile)
  $XmlElement = $Xml.get_DocumentElement()
  $XmlElementToModify = $XmlElement.Plugins
  
  Foreach ($Element in $XmlElementToModify.Plugin)
  {
      If ($Element.name -eq "Ec2HandleUserData")
      {
          $Element.State="Enabled"
      }
  }
  $Xml.Save($EC2SettingsFile)

  # Download and install hotfix
  
  # Download self-extractor
  $DownloadUrl = "https://hotfixv4.trafficmanager.net/Windows%207/Windows%20Server2008%20R2%20SP1/sp2/Fix467402/7600/free/463984_intl_x64_zip.exe"
  $HotfixDir = "C:\hotfix"
  $HotfixFile = "$HotfixDir\KB2842230.exe"
  mkdir $HotfixDir
  (New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $HotfixFile)
  
  # Extract self-extractor
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory($HotfixFile, $HotfixDir)
  
  # Install 
  #Get-Item "$HotfixDir\*.msu" | Foreach {WUSA ""$_.FullName /quiet /norestart"" ; While(Get-Process "wusa.exe") { Start-Sleep -s 1 } }
  #Get-Item "$HotfixDir\*.msu" | Foreach { Start-Process -FilePath "wusa" -ArgumentList "/update $_.FullName /quiet /norestart" -Wait }
  Get-Item "$HotfixDir\*.msu" | Foreach { wusa ""$_.FullName /quiet /norestart"" ; While (@(Get-Process wusa -ErrorAction SilentlyContinue).Count -ne 0) { Start-Sleep 3 } }

  # Reboot
  Restart-Computer
}
Else 
{
  # PHASE 2

  # Open WinRM for remote-exec
  Start-Process -FilePath "winrm" -ArgumentList "quickconfig -q"
  Start-Process -FilePath "winrm" -ArgumentList "set winrm/config/service @{AllowUnencrypted=`"true`"}" -Wait
  Start-Process -FilePath "winrm" -ArgumentList "set winrm/config/service/auth @{Basic=`"true`"}" -Wait
  Start-Process -FilePath "winrm" -ArgumentList "set winrm/config @{MaxTimeoutms=`"1900000`"}"
}
</powershell>