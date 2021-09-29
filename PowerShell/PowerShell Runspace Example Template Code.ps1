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
    # array is large).
    [PSCustomObject]@{
        Handle = $PowerShellInstance.BeginInvoke()
        PowerShell = $PowerShellInstance
        ID = ++$ID
    }

})

$WaitStartTime = Get-Date

while ($True) {

    if (($TotalWaitedSeconds = ([DateTime]::Now - $WaitStartTime).TotalSeconds) -gt $MaximumWaitTimeSeconds) {
        
        Write-Verbose "Timeout of $MaximumWaitTimeSeconds seconds reached. Waited $TotalWaitedSeconds seconds."
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
        Write-Verbose "Waiting for $UnfinishedThreadCount threads to finish. Waited for $('{0:N3}' -f ([DateTime]::Now - $WaitStartTime).TotalSeconds) seconds."
        
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

PS /home/joakim/Documents> $Results = ./Runspaces.ps1 -Verbose

VERBOSE: [2021-09-29 19:26:59] Script started.
VERBOSE: Waiting for 5 threads to finish. Waited for 0.002 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 0.256 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 0.510 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 0.765 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 1.019 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 1.274 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 1.533 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 1.787 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 2.041 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 2.295 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 2.552 seconds.
VERBOSE: Waiting for 5 threads to finish. Waited for 2.807 seconds.
VERBOSE: 3 threads have finished. Running EndInvoke() and Dispose() on them.
VERBOSE: Ending and disposing of 3 threads took 0.001 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 3.064 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 3.328 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 3.581 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 3.835 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 4.089 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 4.345 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 4.599 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 4.853 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 5.107 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 5.362 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 5.616 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 5.869 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 6.123 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 6.379 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 6.633 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 6.887 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 7.140 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 7.394 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 7.651 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 7.905 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 8.158 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 8.412 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 8.665 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 8.922 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 9.176 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 9.429 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 9.683 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 9.939 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 10.194 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 10.448 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 10.702 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 10.956 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 11.212 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 11.465 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 11.719 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 11.972 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 12.229 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 12.482 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 12.736 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 12.990 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 13.243 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 13.500 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 13.754 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 14.007 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 14.261 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 14.515 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 14.771 seconds.
VERBOSE: Waiting for 2 threads to finish. Waited for 15.025 seconds.
VERBOSE: 1 threads have finished. Running EndInvoke() and Dispose() on them.
VERBOSE: Ending and disposing of 1 threads took 0.001 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 15.282 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 15.535 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 15.791 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 16.044 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 16.298 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 16.551 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 16.805 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 17.061 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 17.315 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 17.568 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 17.822 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 18.077 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 18.330 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 18.584 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 18.837 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 19.090 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 19.347 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 19.600 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 19.853 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 20.107 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 20.361 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 20.617 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 20.871 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 21.123 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 21.377 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 21.632 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 21.886 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 22.139 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 22.393 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 22.646 seconds.
VERBOSE: Waiting for 1 threads to finish. Waited for 22.903 seconds.
VERBOSE: 1 threads have finished. Running EndInvoke() and Dispose() on them.
VERBOSE: Ending and disposing of 1 threads took 0.001 seconds.
VERBOSE: All threads finished.
VERBOSE: Closing runspace pool.
VERBOSE: Closing the runspace pool took 0.001 seconds.
VERBOSE: [2021-09-29 19:27:22] Script finished.
VERBOSE: Total minutes elapsed: 0.38736
PS /home/joakim/Documents> $Results


Name                           Value
----                           -----
192.168.0.4                    @{Ping=False; TimeFinished=9/29/2021 7:27:14 PM}
192.168.0.2                    @{Ping=True; TimeFinished=9/29/2021 7:27:02 PM}
192.168.0.1                    @{Ping=True; TimeFinished=9/29/2021 7:27:02 PM}
192.168.0.3                    @{Ping=True; TimeFinished=9/29/2021 7:27:02 PM}
192.168.0.5                    @{Ping=False; TimeFinished=9/29/2021 7:27:22 PM}

PS /home/joakim/Documents> 

#>
