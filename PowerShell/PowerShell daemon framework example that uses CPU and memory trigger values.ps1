#requires -version 2
[CmdletBinding()]
Param()

# MIT license.
# Copyright (c) 2018. Svendsen Tech. Joakim Borger Svendsen, 
# 2018, March.
# Compatible with PowerShell version 2.

<#
To install as a service with nssm.exe (non-sucking service manager...) running as the SYSTEM account,
adapt the command below (paths, other).

$PowerShellServicePath = "c:\temp\testservice.ps1"
$ServiceName = "PowerShellTestService"
Start-Process -FilePath "C:\temp\nssm_x64.exe" -NoNewWindow -Wait `
    -ArgumentList "install $ServiceName ""C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe"" ""-NoProfile"" ""-ExecutionPolicy Bypass"" ""-NonInteractive"" ""-File $PowerShellServicePath"" "

#>

$Host.CurrentCulture.NumberFormat.NumberDecimalSeparator = '.'

# Set according to needs... adapt further, etc.
[Bool] $MeasureCpu = $True
[Bool] $MeasureMemory = $True

[String] $SmtpServer = "smtp.internal.example.com"
[String] $LogFile = "C:\temp\TestingThePowerShellService.txt"
[Decimal] $CpuTriggerValue = 80.0 # in percent
[Decimal] $MinimumFreeMemoryTriggerValueMB = 900

# The same intervals are used for both CPU and memory measurements, rename the
# script and run two in parallel for different intervals... or rewrite yourself
[Int32] $SleepSeconds = 20
[Int32] $SampleCount = 15
[Int32] $CatchCount = 0
[Int32] $HistoryMinutes = 5 # [Math]::Floor($SleepSeconds * $SampleCount / 60) + 3

function Write-Log {
    param(
        [string] $Message,
        [switch] $Verbose = $true)
    "[$([DateTime]::Now.ToString('yyyy\-MM\-dd HH\:mm\:ss'))] $Message" | Add-Content -LiteralPath $LogFile -Encoding UTF8
    Write-Verbose -Message "[$([DateTime]::Now.ToString('yyyy\-MM\-dd HH\:mm\:ss'))] $Message" -Verbose:$Verbose
}

$CpuData = @()
$MemoryData = @()
Write-Log -Message "Starting PowerShell Service."

# Simple service...
while ($True) {
    
    $DoBreak = $False
    while ($True) {
        if ($MeasureCpu) {
            try {
                $CpuUsageData = Get-Counter -Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop
                $DoBreak = $True
            }
            catch {
                $DoBreak = $False
                Write-Log -Message "Get-Counter failed to retrieve a cooked CPU usage value. Retrying in 5 seconds"
            }
        }
        if ($MeasureMemory) {
            try {
                $MemoryUsageData = Get-Counter -Counter '\Memory\Available Bytes' -ErrorAction Stop
                $DoBreak = $True
            }
            catch {
                $DoBreak = $False
                Write-Log -Message "Get-Counter failed to retrieve a cooked memory usage value. Retrying in 5 seconds"
            }
        }
        Start-Sleep -Seconds 5
        if ($DoBreak) {
            break
        }
        <#else {
            Send-MailMessage ... or increase a counter and then mail, or whatever
        }#>
    }
    # Now we have a cooked value or two that we will add to an array or two that contain(s) values for the last $HistoryMinutes
    # in custom PSObjects with a Timestamp from the counter data itself.
    if ($MeasureCpu) {
        $CpuData += New-Object -TypeName PSObject -Property @{
            DateTime = $CpuUsageData.Timestamp
            CookedValue = $CpuUsageData.CounterSamples.CookedValue
        }
    }
    if ($MeasureMemory) {
        $MemoryData += New-Object -TypeName PSObject -Property @{
            DateTime = $MemoryUsageData.Timestamp
            CookedValue = $MemoryUsageData.CounterSamples.CookedValue
        }
    }

    # Filter out elements older than $HistoryMinutes.
    $CpuData = @($CpuData | Where-Object {
        $_.DateTime -gt [DateTime]::Now.AddMinutes(-1 * $HistoryMinutes)
    })
    $MemoryData = @($MemoryData | Where-Object {
        $_.DateTime -gt [DateTime]::Now.AddMinutes(-1 * $HistoryMinutes)
    })

    # We should have at least $SampleCount samples before we act... 5 minutes in sample version.
    if ($MeasureCpu) {
        if (($Count = $CpuData.Count) -lt $SampleCount) {
            Write-Verbose -Verbose -Message "[$([DateTime]::Now.ToString('yyyy\-MM\-dd HH\:mm\:ss'))] Only $Count samples so far. Need $SampleCount. Collect more values."
            continue
        }
    }
    if ($MeasureMemory) {
        if (($MemCount = $MemoryData.Count) -lt $SampleCount) {
            Write-Verbose -Verbose -Message "[$([DateTime]::Now.ToString('yyyy\-MM\-dd HH\:mm\:ss'))] Only $Count samples so far. Need $SampleCount. Collect more values."
            continue
        }
    }
    # We have $SampleCount or more records. Process these and run command
    # (iisreset in this example) if necessary.
    # Calculate average and see if it's higher than $CpuTriggerValue or $FreeMemoryTriggerValue, if
    # it is, run iisreset and reset the $CpuData array, so we start over.
    $AverageCpuUsage = $CpuData |
        Measure-Object -Property CookedValue -Average |
        Select-Object -ExpandProperty Average
    $AverageMemoryUsage = $MemoryData |
        Measure-Object -Property CookedValue -Average |
        Select-Object -ExpandProperty Average
    if ($MeasureCpu -and $AverageCpuUsage -ge $CpuTriggerValue) {
        Write-Log "CPU usage alert triggered! CPU usage for the samples was $AverageCpuUsage % (trigger value: $CpuTriggerValue). Running command and emptying counter array."
        $ErrorActionPreference = "Stop"
        while ($True) {
            $ProcessResult = Start-Process -FilePath cmd -NoNewWindow -Wait -ErrorAction Stop -PassThru -ArgumentList '/c', 'echo 1'
            if ($ProcessResult.ExitCode -eq 0) {
                Write-Log -Message "Successfully ran cmd."
                
                # You can add a Send-MailMessage here if you want. Send-MailMessage -To whatever@whatever.org -From ...
                
                $CpuData = @()
                break
            }
            else {
                # Avoid insane amounts of spam in case it hangs...
                $CatchCount++
                if ($CatchCount -gt 1) {
                    if ($CatchCount -gt 99) {
                        $CatchCount = 0
                    }
                }
                else {
                    Send-MailMessage -SmtpServer $SmtpServer -Cc 'joakim@example.com' -From 'PS_Service@example.com' `
                        -To 'DistributionList@example.com' -Subject "Failed to iisreset on $Env:ComputerName! $(Get-Date)" `
                        -Body @"
PowerShell Service failed to run command on $Env:ComputerName!
$(Get-Date). Will try again in about $SleepSeconds seconds. After 100 repeated failures, you will get a new mail..."
"@
                }
            }
        }
        $ErrorActionPreference = "Continue"
    }
   if ($MeasureMemory -and ($AverageMemoryUsage/1MB) -le $MinimumFreeMemoryTriggerValueMB) {
        Write-Log "Memory usage alert triggered! Memory usage for the samples was $('{0:N4}' -f ($AverageMemoryUsage / 1MB)) MB (trigger value: $MinimumFreeMemoryTriggerValueMB MB). Running command and emptying counter array."
        $ErrorActionPreference = "Stop"
        while ($True) {
            $ProcessResult = Start-Process -FilePath cmd -NoNewWindow -Wait -ErrorAction Stop -PassThru -ArgumentList '/c', 'echo 1'
            if ($ProcessResult.ExitCode -eq 0) {
                Write-Log -Message "Successfully ran cmd."
                
                # You can add a Send-MailMessage here if you want. Send-MailMessage -To whatever@whatever.org -From ...
                
                $MemoryData = @()
                break
            }
            else {
                # Avoid insane amounts of spam in case it hangs...
                $CatchCount++
                if ($CatchCount -gt 1) {
                    if ($CatchCount -gt 99) {
                        $CatchCount = 0
                    }
                }
                else {
                    Send-MailMessage -SmtpServer $SmtpServer -Cc 'joakim@example.com' -From 'PS_Service@example.com' `
                        -To 'DistributionList@example.com' -Subject "PowerShell service failed to iisreset on $Env:ComputerName! $(Get-Date)" `
                        -Body @"
PowerShell Service failed to run command on $Env:ComputerName!
$(Get-Date). Will try again in about $SleepSeconds seconds. After 100 repeated failures, you will get a new mail..."
"@
                }
            }
        }
        $ErrorActionPreference = "Continue"
    }

    Write-Verbose -Verbose -Message "[$([DateTime]::Now.ToString('yyyy\-MM\-dd HH\:mm\:ss'))] Average CPU usage percent for $Count samples was $('{0:N2}' -f $AverageCpuUsage) %."
    Write-Verbose -Verbose -Message "[$([DateTime]::Now.ToString('yyyy\-MM\-dd HH\:mm\:ss'))] Average free memory for $Count samples was $('{0:N2}' -f ($AverageMemoryUsage/1MB)) MB."
    Start-Sleep -Seconds $SleepSeconds

    # Avoid memory leaks, especially on PS versions before 4 or 5 (not sure which version (apparently) got better at it).
    [System.GC]::Collect()

}
