# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
 
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole))
   {
    Write-Host "Running as Administrator"
   }
else
   {
    Write-Host "NOT Running as Administrator"
   }


Write-Host ("*****************************************************************************")
Write-Host ("Running Watchmaker test script: WINDOWS")
Write-Host ("*****************************************************************************")
Write-Host ((Get-WmiObject -class Win32_OperatingSystem).Caption)
Write-Host "Powershell Version: $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Get-AWSPowerShellVersion

$UserdataStatusFile = "C:\Temp\userdata_status"
$UserdataPropsFile = "C:\Temp\pyppyn.properties"
If (Test-Path -Path $UserdataStatusFile)
{   # file exists, read into variable
    $UserdataStatus=gc $UserdataStatusFile
}
Else
{   # error, no userdata status found
    # declare an array to hold the status (number and message)
    $UserdataStatus=@($lastExitCode,"No status returned by userdata")
}

$TestStatus=@(0,"Not run")

If ($UserdataStatus[0] -eq 0) 
{   # userdata was successful so now TRY the watchmaker tests

    Try 
    {   
        # userdata was successful so now try the watchmaker tests
        # put the tests between the dashed comments
        # NOTE: if tests don't have an error action of "Stop," by default or explicitly set, won't be caught
        # NOTE: default erroraction in powershell is "Continue"
        # ------------------------------------------------------------ Build TESTS BEGIN
        If (Test-Path -Path $UserdataPropsFile)
        {   # file exists!
            # Read in props file. Since it has paths with backslashes, requires special handling
            Write-Host "1"
            $FileContent = Get-Content $UserdataPropsFile -raw
            Write-Host "2"
            $FileContent = [Regex]::Escape($FileContent)
            Write-Host "3"
            $FileContent = $FileContent -replace "(\\r)?\\n", [Environment]::NewLine
            Write-Host "4"
            $UserdataProps = ConvertFrom-StringData($FileContent)
            Write-Host "5"

            #$TempExeDir = "C:\Temp\exe"
            #$TempName = "a.exe"
            #mkdir $TempExeDir
            #Copy-Item "$($UserdataProps.DistPath)\*.exe" -Destination $TempExeDir
            #$FileName = (Get-childitem $TempExeDir -include *.exe -recurse | Select -exp Name)
            #Rename-Item -Path "$TempExeDir\$FileName" -NewName $TempName
            #Write-Host "6"
            #Write-S3Object -BucketName $UserdataProps.S3Bucket -Key "$($UserdataProps.S3Prefix)/$FileName" -File "$TempExeDir\$TempName"
            Write-Host "7"
            Write-Host ("Bucket: " + $UserdataProps.S3Bucket)
            Write-Host ("Dist Path: " + $UserdataProps.DistPath)
            Write-Host ("S3 Prefix: " + $UserdataProps.S3Prefix)

            $BucketName = $UserdataProps.S3Bucket
            $Folder = $UserdataProps.DistPath
            $KeyPrefix = $UserdataProps.S3Prefix

            #Write-S3Object -BucketName "$($UserdataProps.S3Bucket)" -Folder "C:\Temp\" -KeyPrefix "$($UserdataProps.S3Prefix)" -SearchPattern "*.exe"
            #Write-Host "8"
            #Write-S3Object -BucketName "pyppyn" -Folder "C:\\git\\pyppyn\\pyinstaller\\dist\\" -KeyPrefix "20180321/1853_269fd71c5b95" -SearchPattern "*.exe"
            #Write-Host "8"
            ##Write-S3Object -BucketName "pyppyn" -Folder "C:\git\pyppyn\pyinstaller\dist" -KeyPrefix "20180321/1853_269fd71c5b96" -SearchPattern *.exe
            #Write-Host "9"
            #Get-ChildItem "WSMan:\localhost\Shell"
            #Get-ChildItem "WSMan:\localhost\Shell"
            #Get-ChildItem "WSMan:\localhost\Shell"

            #$f = new-object System.IO.FileStream C:\Temp\test.dat, Create, ReadWrite
            #$f.SetLength(14.5MB) #worked
            #$f.SetLength(40MB) #worked
            #$f.Close()
            #Write-Host (Get-Date -UFormat "%Y/%m/%d %T")
            #Write-S3Object -BucketName $BucketName -Folder "C:\Temp" -KeyPrefix $KeyPrefix -SearchPattern "*.dat"
            #Write-Host "9"

            #Write-Host (Get-Date -UFormat "%Y/%m/%d %T")
            #Write-S3Object -BucketName $BucketName -Folder $Folder -KeyPrefix $KeyPrefix -SearchPattern "*.exe"
            #Write-Host "10"

            

            #$WriteProps = @{
            #    'BucketName' = $UserdataProps.S3Bucket                  # S3 Bucket Name
            #    'Key'        = "$($UserdataProps.S3Prefix)/$FileName"   # Key used to identify the S3 Object
            #    'File'       = "$($UserdataProps.DistPath)\$FileName"   # Local File to upload
            #}
            #$WriteProps
            #Write-Host "11"
            Write-Host "Sleeping..."
            #Start-Sleep -s 20
            Write-Host (Get-Date -UFormat "%Y/%m/%d %T")
            #Write-S3Object @WriteProps
            #Write-Host "12"
            $FileName = (Get-ChildItem $UserdataProps.DistPath -Include "watchmaker*.exe" -Recurse | Select -exp Name)
            Write-Host ("Uploading $FileName...")
            aws s3 cp "$($UserdataProps.DistPath)\$FileName" "s3://$($UserdataProps.S3Bucket)/$($UserdataProps.S3Prefix)/$FileName"
            Write-Host "13"
        }
        Else
        {   
            Throw "Error: No props file found!"
        }


        # ------------------------------------------------------------ Build TESTS END
        
        # if we made it here through all the tests, consider it a success
        $TestStatus=@(0,"Success")
    }
    Catch
    {
        $TestStatus=@(1,"Testing error")
    }
}

# FINALLY after everything, give results
If ( $UserdataStatus[0] -eq 0 -and $TestStatus[0] -eq 0 )
{
    Write-Host (".............................................................................Success!")
}
Else
{
    Write-Host (".............................................................................FAILED!")
    Write-Host ("Userdata Status: ($UserdataStatus[0]) $UserdataStatus[1]")
    Write-Host ("Test Status    : ($TestStatus[0]) $TestStatus[1]")
    exit 1
}


