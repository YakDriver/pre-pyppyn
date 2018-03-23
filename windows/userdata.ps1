<powershell>

$ErrorActionPreference = "Continue"

function Tfi-Out
{
  # Writes messages to a Terrafirm log file. If a second parameter is included, it will display success/failure outcome.
  Param
  (
    [String]$Msg,
	  $Success = $null
  )
  
  # result is succeeded or failed or nothing if success is null
  If( $Success -ne $null )  
  {
    If ($Success)
    {
      $OutResult = ": Succeeded"
    }
    Else
    {
      $OutResult = ": Failed"
    }
  }
  
  "$(Get-Date): $Msg $OutResult" | Out-File "${tfi_win_userdata_log}" -Append -Encoding utf8
}

function Test-Command
{
  # Tests commands and handles errors that result. Can also re-try commands is -Tries is set > 1. 
  param (
    [Parameter(Mandatory=$true)][string]$Test,
    [Parameter(Mandatory=$false)][int]$Tries = 1,
    [Parameter(Mandatory=$false)][int]$SecondsDelay = 2
  )
  $TryCount = 0
  $Completed = $false
  $MsgFailed = "Command [{0}] failed" -f $Test
  $MsgSucceeded = "Command [{0}] succeeded." -f $Test

  While (-not $Completed)
  {
    Try
    {
      $Result = @{}
      # Invokes commands and in the same context captures the $? and $LastExitCode
      Invoke-Expression -Command ($Test+';$Result = @{ Success = $?; ExitCode = $LastExitCode }') | Out-String -OutVariable CommandOutput
      Tfi-Out $CommandOutput
      If (($False -eq $Result.Success) -Or ((($Result.ExitCode) -ne $null) -And (0 -ne ($Result.ExitCode)) ))
      {
        Throw $MsgFailed
      }
      Else
      {
        Tfi-Out $MsgSucceeded
        $Completed = $true
      }
    }
    Catch
    {
      $TryCount++
      If ($TryCount -ge $Tries)
      {
        $Completed = $true
        Tfi-Out ("Command [{0}] failed the maximum number of {1} time(s)." -f $Test, $Tries)
        Tfi-Out ("Error code (if available): {0}" -f ($Result.ExitCode))
        $PSCmdlet.ThrowTerminatingError($PSItem)
      }
      Else
      {
        $Msg = $PSItem.ToString()
        If ($Msg -ne $MsgFailed) { Tfi-Out $Msg }
        Tfi-Out ("Command [{0}] failed. Retrying in {1} second(s)." -f $Test, $SecondsDelay)
        Start-Sleep $SecondsDelay
      }
    }
  }
}

# directory needed by logs and for various other purposes
Invoke-Expression -Command "mkdir C:\Temp" -ErrorAction SilentlyContinue

Enable-PSRemoting -Force -ErrorAction Continue
Tfi-Out "Enable-PSRemoting -Force -ErrorAction Continue" $?

# close winrm
Start-Process -FilePath "winrm" -ArgumentList "set winrm/config/service/auth @{Basic=`"false`"}" -Wait
Tfi-Out "Set winrm/config/service/auth basic=false" $?

# declare an array to hold the status (number and message)
$UserdataStatus=@(1,"Error: Install not completed (should never see this error)")

Try {

  Tfi-Out "Start install"

  # time wam install
  $StartDate=Get-Date

  # ---------- begin of wam install ----------
  $GitRepo = "${tfi_git_repo}"
  $GitRef = "${tfi_git_ref}"

  Tfi-Out "Security protocol before bootstrap: $([Net.ServicePointManager]::SecurityProtocol | Out-String)"

  $BootstrapUrl = "https://raw.githubusercontent.com/plus3it/watchmaker/develop/docs/files/bootstrap/watchmaker-bootstrap.ps1"
  $PythonUrl = "https://www.python.org/ftp/python/3.6.4/python-3.6.4-amd64.exe"
  $GitUrl = "https://github.com/git-for-windows/git/releases/download/v2.16.2.windows.1/Git-2.16.2-64-bit.exe"
  $PypiUrl = "https://pypi.org/simple"

  # Use TLS, as git won't do SSL now
  [Net.ServicePointManager]::SecurityProtocol = "Ssl3, Tls, Tls11, Tls12"

  # Download bootstrap file
  $Stage = "download bootstrap"
  $BootstrapFile = "$${Env:Temp}\$($${BootstrapUrl}.split("/")[-1])"
  (New-Object System.Net.WebClient).DownloadFile($BootstrapUrl, $BootstrapFile)

  # Install python and git
  $Stage = "install python/git"
  & "$BootstrapFile" `
      -PythonUrl "$PythonUrl" `
      -GitUrl "$GitUrl" `
      -Verbose -ErrorAction Stop

  Tfi-Out "Upgrade pip..."
  Test-Command "python -m pip install --upgrade pip" -Tries 2
  
  Tfi-Out "Installing aws-cli..."
  Test-Command "pip install awscli" -Tries 2

  # Clone watchmaker
  Tfi-Out "Cloning watchmaker..."
  $BaseDir = "C:\git"
  New-Item $BaseDir -ItemType Directory 
  cd $BaseDir
  Test-Command "git clone `"$GitRepo`" --recursive" -Tries 2
  cd watchmaker
  If ($GitRef)
  {
    # decide whether to switch to pull request or branch
    If($GitRef -match "^[0-9]+$")
    {
      Test-Command "git fetch origin pull/$GitRef/head:pr-$GitRef" -Tries 2
      Test-Command "git checkout pr-$GitRef"
    }
    Else
    {
      Test-Command "git checkout $GitRef"
    }
  }

  Tfi-Out "Cloning pyppyn..."
  cd $BaseDir
  Test-Command "git clone https://github.com/YakDriver/pyppyn.git"
  cd $BaseDir\pyppyn  

  Tfi-Out "Creating virtual environment..."
  Test-Command "python -m venv venv"
  $VenvBin="$BaseDir\pyppyn\venv\Scripts"
  cd $VenvBin
  Test-Command ".\activate"
  Test-Command "python -c `"import sys; print('Inside venv' if sys.base_prefix != sys.prefix else 'Outside venv')`""
  
  Tfi-Out "Installing pre-requisities for watchmaker..."
  Test-Command "pip install --index-url=`"$PypiUrl`" --upgrade pip setuptools boto3" -Tries 2

  Tfi-Out "Installing watchmaker distribution..."
  cd $BaseDir\watchmaker
  Test-Command "pip install --index-url=`"$PypiUrl`" --editable ."

  Tfi-Out "Install pyinstaller..."
  Test-Command "pip3 install --upgrade pyinstaller pyyaml backoff six click pypiwin32 defusedxml packaging"

  Tfi-Out "Verifying installation..."
  If(Test-Path -Path "$VenvBin\watchmaker-script.py")
  {
    Tfi-Out "watchmaker installed correctly"
  }
  Else
  {
    Tfi-Out "ERROR: watchmaker did not install correctly (try 1)"
    cd $BaseDir\watchmaker
    Test-Command "pip install --editable ."
  }

  Tfi-Out "Re-verifying installation..."
  If(Test-Path -Path "$VenvBin\watchmaker-script.py")
  {
    Tfi-Out "Building standalone..."

    copy $VenvBin\watchmaker-script.py $BaseDir\pyppyn\pyinstaller

    cd $BaseDir\pyppyn\pyinstaller
    Test-Command "python generate-standalone.py"

    $UserdataPropsFile = "C:\Temp\pyppyn.properties"
    "S3Bucket=${tfi_s3_bucket}" | Out-File $UserdataPropsFile -Append
    "DistPath=$BaseDir\pyppyn\pyinstaller\dist" | Out-File $UserdataPropsFile -Append
    "S3Prefix=${tfi_build_date}/${tfi_build_hour}_${tfi_build_id}" | Out-File $UserdataPropsFile -Append

    $UserdataStatus=@(0,"Well, we got this far")
  }

}
Catch
{
  $ErrorMessage = [String]$_.Exception + "Invocation Info: " + ($PSItem.InvocationInfo | Format-List * | Out-String)
  Tfi-Out ("*** ERROR caught ($Stage) ***")
  Tfi-Out $ErrorMessage

  # setup userdata status for passing to the test script via a file
  $ErrCode = 1  # trying to set this to $lastExitCode does not work (always get 0)
  $UserdataStatus=@($ErrCode,"Error at: " + $Stage + " [$ErrorMessage]")
}

$ErrorActionPreference = "Continue"

# Set Administrator password, for logging in before wam changes Administrator account name to ${tfi_rm_user}
$Admin = [adsi]("WinNT://./${tfi_rm_user}, user")
$Admin.psbase.invoke("SetPassword", "${tfi_rm_pass}")
Tfi-Out "Set admin (${tfi_rm_user}) password (${tfi_rm_pass})" $?

# initial winrm setup
Start-Process -FilePath "winrm" -ArgumentList "quickconfig -q"
Tfi-Out "WinRM quickconfig" $?
Start-Process -FilePath "winrm" -ArgumentList "set winrm/config/service @{AllowUnencrypted=`"true`"}" -Wait
Tfi-Out "Set winrm/config/service allowunencrypted=true" $?
Start-Process -FilePath "winrm" -ArgumentList "set winrm/config/service/auth @{Basic=`"true`"}" -Wait
Tfi-Out "Set winrm/config/service/auth basic=true" $?
Start-Process -FilePath "winrm" -ArgumentList "set winrm/config @{MaxTimeoutms=`"1900000`"}"
Tfi-Out "Set winrm timeout" $?

# write the status to a file for reading by test script
$UserdataStatus | Out-File C:\Temp\userdata_status
Tfi-Out "Write userdata status file" $?

# upload logs to S3 bucket
$S3Keyfix="Win" + (((Get-WmiObject -class Win32_OperatingSystem).Caption) -replace '.+(\d\d)\s(.{2}).+','$1$2')
If ($S3Keyfix.Substring($S3Keyfix.get_Length()-2) -eq 'Da') {
    $S3Keyfix=$S3Keyfix -replace ".{2}$"
}

$ArtifactPrefix = "${tfi_build_date}/${tfi_build_hour}_${tfi_build_id}/$S3Keyfix"
Tfi-Out "Copying executable to $ArtifactPrefix"
Write-S3Object -BucketName "${tfi_s3_bucket}" -Folder "$BaseDir\pyppyn\pyinstaller\dist" -KeyPrefix "$ArtifactPrefix" -SearchPattern "*.exe"

Tfi-Out "Writing logs to $ArtifactPrefix"
Write-S3Object -BucketName "${tfi_s3_bucket}" -Folder "C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Log" -KeyPrefix "$ArtifactPrefix/cloud/"
Write-S3Object -BucketName "${tfi_s3_bucket}" -Folder "C:\\Program Files\\Amazon\\Ec2ConfigService\\Logs" -KeyPrefix "$ArtifactPrefix/cloud/"

Start-Process -FilePath "winrm" -ArgumentList "set winrm/config/service/auth @{Basic=`"true`"}" -Wait
Tfi-Out "Set winrm/config/service/auth basic=true" $?

Write-S3Object -BucketName "${tfi_s3_bucket}/$ArtifactPrefix" -File "${tfi_win_userdata_log}"

</powershell>