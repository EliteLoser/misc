#requires -version 2
function DockerPs {
<#
.SYNOPSIS
    Turn "docker ps" output into custom PowerShell objects. By default omit the name column
    (so long as it remains the last one and names can't have spaces).

.DESCRIPTION
    The parsing to "objectify" relies on the column widths in this case, rather than my usual
    approach of using regular expressions, since it seems more robust for this
    case/output at hand.

    I omit the names of the containers by default (long story), but for now it's so it
    fits better into a default-sized PowerShell window. To include the names, add the parameter
    "-names" (will not be tab completed).
    
    Otherwise "docker ps --help" is what you should read  for further information about the
    available parameters.

    -q / --quiet is special-cased to work identically as in the native "docker ps -q" (lists
    only container IDs).

.PARAMETER Names
    Include the container name column.

.EXAMPLE
dockerps


CONTAINER_ID : d92cb8edaf53
IMAGE        : microsoft/nanoserver
COMMAND      : "powershell"
CREATED      : 19 hours ago
STATUS       : Up 19 hours
PORTS        : 

CONTAINER_ID : 9c45b67925db
IMAGE        : microsoft/nanoserver
COMMAND      : "powershell"
CREATED      : 19 hours ago
STATUS       : Up 19 hours
PORTS        : 

CONTAINER_ID : 520649cfb9d7
IMAGE        : microsoft/nanoserver
COMMAND      : "cmd"
CREATED      : 20 hours ago
STATUS       : Up 20 hours
PORTS        : 

.EXAMPLE
$Var = dockerps

$Var.CONTAINER_ID # list all container IDs
$Var.COMMAND # list all commands
$Var.STATUS # list all statuses
$Var.IMAGE # list all image titles

.EXAMPLE
PS C:\temp\STDockerPs> @(dockerps | Where { $_.IMAGE -like "microsoft/*" }).Count
3

PS C:\temp\STDockerPs> @(dockerps | Where { $_.IMAGE -like "microsoft/*" }).Command
"powershell"
"powershell"
"cmd"


.EXAMPLE
(dockerps -names)[2].Names
temp1

.EXAMPLE
(dockerps -names)[0]


CONTAINER_ID : d92cb8edaf53
IMAGE        : microsoft/nanoserver
COMMAND      : "powershell"
CREATED      : 19 hours ago
STATUS       : Up 19 hours
PORTS        : 
NAMES        : temp3
#>  
    if ($Args -match '-q|--quiet') {
        docker ps -q
        return
    }
    
    elseif ($Args -match '-names') {
        $DockerPSOutput = @(docker ps ($Args -replace '-names'))
    }
    
    else {
        $DockerPSOutput = @(docker ps $Args) -replace '\s+\S+$'
    }
    
    $DockerPSTitles = $DockerPSOutput | Select-Object -First 1
    
    # Since we ((for) now) have a predictable and logical starting point for each
    # column (same char as the header), I will play with SubString to PSobjectify the stuff...
    
    $Indexes = @()
    $Headers = @("CONTAINER ID", "IMAGE", "COMMAND", "CREATED", "STATUS",
        "PORTS")
    if ($Args -match '-names') {
        $Headers += "NAMES"
    }
    $Indexes += $DockerPSTitles.IndexOf($Headers[0])
    $Indexes += $DockerPSTitles.IndexOf($Headers[1])
    $Indexes += $DockerPSTitles.IndexOf($Headers[2])
    $Indexes += $DockerPSTitles.IndexOf($Headers[3])
    $Indexes += $DockerPSTitles.IndexOf($Headers[4])
    $Indexes += $DockerPSTitles.IndexOf($Headers[5])
    if ($Args -match '-names') {
        $Indexes += $DockerPSTitles.IndexOf($Headers[6])
    }
    $Indexes += $DockerPSTitles.Length
    $DockerPSOutput | Select-Object -Skip 1 | ForEach-Object {
        Write-Verbose -Message "Current line: $_"
        $Object = "" | Select-Object -Property ($Headers -replace ' ', '_')
        foreach ($i in 0..($Indexes.Count - 2)) {
            $CurrentHeader = $Headers[$i] -replace ' ', '_' # avoid spaces in the titles for easier access later...
            $Object.$CurrentHeader = $_.PadRight($Indexes[-1], " ").SubString($Indexes[$i], ($Indexes[$i + 1] - $Indexes[$i])).TrimEnd()
        }
        $Object
    }

}
