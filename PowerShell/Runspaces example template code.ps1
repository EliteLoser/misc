#requires -version 2


$StartTime = Get-Date

Write-Verbose -Verbose "[$($StartTime.ToString('yyyy\-MM\-dd HH\:mm\:ss'))] Script started."

$ComputerName = @(
    '192.168.0.1',
    '192.168.0.2',
    '192.168.0.3',
    '192.168.0.4',
    '192.168.0.5'
)

# Self-explanatory. Maximum thread count.
$MaximumThreadCount = 32

# Maximum wait time in seconds.
$MaximumWaitTimeSeconds = 300

# Just need this for the runspaces.
$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault() 

# If you want to return data, use a synchronized hashtable and add it to the
# initial session state variable.
$Data = [HashTable]::Synchronized(@{})
$InitialSessionState.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'Data', $Data, ''))

# Create a runspace pool based on the initial session state variable,
# maximum thread count and $Host variable (convenient).
$RunspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaximumThreadCount, $InitialSessionState, $Host)

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
    
    <#
    [PSCustomObject]@{
        ComputerName = $Computer
        Ping = $Ping
    }
    #>

    $Data.$ComputerName = [PSCustomObject]@{
        Ping = $Ping
        TimeFinished = [DateTime]::Now
    }

}

foreach ($Computer in $ComputerName) {
    $PowerShellInstance = [System.Management.Automation.PowerShell]::Create().AddScript($ScriptBlock)
    $PowerShellInstance.RunspacePool = $RunspacePool
    $PowerShellInstance.AddParameter('ComputerName', $Computer)
    $Runspaces += $PowerShellInstance.BeginInvoke()
}

$WaitStartTime = Get-Date

while ($true) {

    if (([DateTime]::Now - $WaitStartTime).TotalSeconds -gt $MaximumWaitTimeSeconds) {
        Write-Verbose -Verbose "Timeout of $MaximumWaitTimeSeconds reached."
        break
    }
    
    if ($Runspaces.IsCompleted -contains $False) {
        Start-Sleep -Milliseconds 100
    }
    else {
        Write-Verbose -Verbose "Threads finished."
        $RunspacePool.Close()
        break
    }

}
$EndTime = Get-Date

Write-Verbose -Verbose "[$($EndTime.ToString('yyyy\-MM\-dd HH\:mm\:ss'))] Script finished."
Write-Verbose -Verbose "Total minutes elapsed: $('{0:N5}' -f ($EndTime - $StartTime).TotalMinutes)"

# Return the hashtable with results.
return $Data
