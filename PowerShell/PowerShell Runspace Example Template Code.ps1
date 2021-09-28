#requires -version 2
[CmdletBinding()]
param(

    # Self-explanatory. Maximum thread count.
    [Int32]
    $MaximumThreadCount = 32,

    # Maximum wait time in seconds.
    [Int32]
    $MaximumWaitTimeSeconds = 300,

    [String[]]
    $ComputerName = @(
        '192.168.0.1',
        '192.168.0.2',
        '192.168.0.3',
        '192.168.0.4',
        '192.168.0.5'
    )

)

$StartTime = Get-Date

Write-Verbose "[$($StartTime.ToString('yyyy\-MM\-dd HH\:mm\:ss'))] Script started."

<#
$ComputerName = @(
    '192.168.0.1',
    '192.168.0.2',
    '192.168.0.3',
    '192.168.0.4',
    '192.168.0.5'
)
#>

# Need this for the runspaces.
$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault() 

# If you want to return data, use a synchronized hashtable and add it to the
# initial session state variable.
$Data = [HashTable]::Synchronized(@{})

# Ugly line separation some places, to increase readability (shorter lines, 
# always helps when they fit on GitHub...).
$InitialSessionState.Variables.Add((
    New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry `
    -ArgumentList 'Data', $Data, ''))

# Create a runspace pool based on the initial session state variable,
# maximum thread count and $Host variable (convenient).
$RunspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(
    1, $MaximumThreadCount, $InitialSessionState, $Host)

# This seems to work best. Single-threaded apartment?
$RunspacePool.ApartmentState = 'STA'

# Open/prepare the runspace pool.
$RunspacePool.Open()

# Used for the collection of the runspaces that accumulate.
$Runspaces = @()

# This is the custom script block executed for each runspace.
$ScriptBlock = {
    
    Param([String] $ComputerName)

    $Ping = Test-Connection -ComputerName $ComputerName -Quiet
    
    # For testing a timeout... Temporary, obviously.
    #Start-Sleep -Seconds 20

    <#
    [PSCustomObject]@{
        ComputerName = $Computer
        Ping = $Ping
    }
    #>

    $Data[$ComputerName] = [PSCustomObject]@{

        Ping = $Ping
        TimeFinished = [DateTime]::Now

    }

}

[Decimal] $ID = 0

$Runspaces = @(foreach ($Computer in $ComputerName) {
    
    $PowerShellInstance = [System.Management.Automation.PowerShell]::Create().AddScript($ScriptBlock)
    [void]$PowerShellInstance.AddParameter('ComputerName', $Computer)
    $PowerShellInstance.RunspacePool = $RunspacePool
    
    # This is "returned"/passed down the pipeline and collected outside the foreach loop
    # in the variable $Runspaces, an array. To avoid array concatenation (slow when the
    # array is large). Handle and PowerShell become $null. What now...
    [PSCustomObject]@{
        Handle = $PowerShellInstance.BeginInvoke()
        PowerShell = $PowerShellInstance
        ID = ++$ID
    }

})

$WaitStartTime = Get-Date

while ($True) {

    if (($TotalWaitedSeconds = ([DateTime]::Now - $WaitStartTime).TotalSeconds) -gt $MaximumWaitTimeSeconds) {
        
        Write-Verbose "Timeout of $MaximumWaitTimeSeconds seconds reached."
        Write-Verbose "Running EndInvoke() and Dispose() on threads."
        
        $TempStartTime = Get-Date
        $Runspaces | ForEach-Object {

            $_.PowerShell.EndInvoke($_.Handle)
            $_.PowerShell.Dispose()
            $_.PowerShell, $_.Handle = $null, $null

        }
        
        Write-Verbose "Ending and disposing of threads took $('{0:N3}' -f ((Get-Date) - $TempStartTime).TotalSeconds) seconds."
        Write-Verbose "Closing runspace pool."
        
        $TempStartTime = Get-Date
        $RunspacePool.Close()
        
        Write-Verbose "Closing the runspace pool took $('{0:N3}' -f ((Get-Date) - $TempStartTime).TotalSeconds) seconds."
        
        break
    
    }
    
    if (($Runspaces | Select-Object -ExpandProperty Handle | Select-Object -ExpandProperty IsCompleted) -contains $True) {

        $FinishedThreadCount = @(($FinishedRunspaces = $Runspaces | Where-Object {$True -eq $_.Handle.IsCompleted})).Count
        
        Write-Verbose "$FinishedThreadCount threads have finished. Running EndInvoke() and Dispose() on them."
        
        $TempStartTime = Get-Date
        $FinishedRunspaces | ForEach-Object {

            $_.PowerShell.EndInvoke($_.Handle)
            $_.PowerShell.Dispose()
            $_.PowerShell, $_.Handle = $null, $null

        }
        
        Write-Verbose "Ending and disposing of $FinishedThreadCount threads took $(
            '{0:N3}' -f (([DateTime]::Now - $TempStartTime).TotalSeconds)) seconds."
        

    }
    
    if (($Runspaces | Select-Object -ExpandProperty Handle | Select-Object -ExpandProperty IsCompleted) -contains $False) {
        
        $UnfinishedThreadCount = @($Runspaces | Where-Object {$False -eq $_.Handle.IsCompleted}).Count
        Write-Verbose "Waiting for $UnfinishedThreadCount threads to finish. Waited for $('{0:N3}' -f $TotalWaitedSeconds) seconds."
        
        Start-Sleep -Milliseconds 250
        
    }
    else {
        
        Write-Verbose "All threads finished." # Running EndInvoke() and Dispose() on threads."
        
        # These are handled above as they finish. This turned out redundant.
        <#$TempStartTime = Get-Date
        $Runspaces | ForEach-Object {

            $_.PowerShell.EndInvoke($_.Handle)
            $_.PowerShell.Dispose()
            $_.PowerShell, $_.Handle = $null, $null

        }
        
        Write-Verbose "Ending and disposing of threads took $('{0:N3}' -f (((Get-Date) - $TempStartTime).TotalSeconds)) seconds."
        #>
        Write-Verbose "Closing runspace pool."
        
        $TempStartTime = Get-Date
        $RunspacePool.Close()
        
        Write-Verbose "Closing the runspace pool took $('{0:N3}' -f (((Get-Date) - $TempStartTime).TotalSeconds)) seconds."
        

        # Return the hashtable with results.
        $Data
        
        # Exit the infinite loop.
        break

    }

}

$EndTime = Get-Date

Write-Verbose "[$($EndTime.ToString('yyyy\-MM\-dd HH\:mm\:ss'))] Script finished."
Write-Verbose "Total minutes elapsed: $('{0:N5}' -f ($EndTime - $StartTime).TotalMinutes)"

<#

PS /home/joakim/Documents> $r = ./Runspaces.ps1 -Verbose                

VERBOSE: [2021-09-28 20:41:21] Script started.
VERBOSE: Waiting for 5 threads to finish. Waited for 0.001 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 0.255 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 0.512 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 0.768 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 1.041 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 1.297 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 1.553 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 1.810 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 2.066 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 2.323 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 2.579 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 2.839 seconds.
VERBOSE: 3 threads have finished. Running EndInvoke() and Dispose() on them.
VERBOSE: Ending and disposing of 3 threads took 0.004 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 3.095 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 3.360 seconds.
VERBOSE: 1 threads have finished. Running EndInvoke() and Dispose() on them.
VERBOSE: Ending and disposing of 1 threads took 0.001 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 3.615 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 3.875 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 4.131 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 4.387 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 4.643 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 4.907 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 5.161 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 5.416 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 5.672 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 5.930 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 6.186 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 6.442 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 6.698 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 6.956 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 7.212 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 7.467 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 7.723 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 7.978 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 8.237 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 8.492 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 8.748 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 9.004 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 9.262 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 9.517 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 9.773 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 10.029 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 10.287 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 10.543 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 10.799 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 11.056 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 11.311 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 11.564 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 11.818 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 12.073 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 12.329 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 12.587 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 12.843 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 13.099 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 13.353 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 13.609 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 13.862 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 14.118 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 14.374 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 14.632 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 14.888 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 15.145 seconds.
VERBOSE: 1 threads have finished. Running EndInvoke() and Dispose() on them.
VERBOSE: Ending and disposing of 1 threads took 0.001 seconds.
VERBOSE: All threads finished.
VERBOSE: Closing runspace pool.
VERBOSE: Closing the runspace pool took 0.002 seconds.
VERBOSE: [2021-09-28 20:41:37] Script finished.
VERBOSE: Total minutes elapsed: 0.25795
PS /home/joakim/Documents> 

#>
