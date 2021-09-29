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

