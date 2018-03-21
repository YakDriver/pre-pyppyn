Write-Host ("*****************************************************************************")
Write-Host ("Running Watchmaker test script: WINDOWS")
Write-Host ("*****************************************************************************")
Write-Host ((Get-WmiObject -class Win32_OperatingSystem).Caption)

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

            Write-Host ("Bucket: " + $UserdataProps.S3Bucket)
            Write-Host ("Dist Path: " + $UserdataProps.DistPath)
            Write-Host ("S3 Prefix: " + $UserdataProps.S3Prefix)

            Write-S3Object -BucketName ($UserdataProps.S3Bucket) -Folder ($UserdataProps.DistPath) -KeyPrefix ($UserdataProps.S3Prefix) -SearchPattern *.exe
            Write-Host "6"
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


