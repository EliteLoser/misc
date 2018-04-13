#requires -version 2
function DockerPs {
<#
.SYNOPSIS
    Turn "docker ps" output into custom PowerShell objects.

.DESCRIPTION
    The parsing to "objectify" relies on the column widths in this case, rather than my usual
    approach of using regular expressions, since it seems more robust for this
    case/output at hand.

    Use the parameter -OmitNames (will not be tab completed), to omit the name column for the
    containers. This is to get more condensed output. Just "-Omit" will work as a minimum.
    
    Otherwise, "docker ps --help" is what you should read  for further information about the
    available parameters.

    -q / --quiet is special-cased to work identically as in the native "docker ps -q" (lists
    only container IDs).

.PARAMETER OmitNames
    Omit the container name column. Not tab completed. "-Omit" is the shortest allowed form.

.EXAMPLE
dockerps | select -first 3


CONTAINER_ID : 26b08e320d17
IMAGE        : microsoft/nanoserver
COMMAND      : "cmd"
CREATED      : 17 hours ago
STATUS       : Up 17 hours
PORTS        : 
NAMES        : temp1234temp1234

CONTAINER_ID : d92cb8edaf53
IMAGE        : microsoft/nanoserver
COMMAND      : "powershell"
CREATED      : 39 hours ago
STATUS       : Up 39 hours
PORTS        : 
NAMES        : temp3

CONTAINER_ID : 9c45b67925db
IMAGE        : microsoft/nanoserver
COMMAND      : "powershell"
CREATED      : 40 hours ago
STATUS       : Up 40 hours
PORTS        : 
NAMES        : temp2

.EXAMPLE
$Var = dockerps

$Var.CONTAINER_ID # list all container IDs (but use -q for (only) that)
$Var.COMMAND # list all commands
$Var.STATUS # list all statuses
$Var.IMAGE # list all image titles
$Var.NAMES # list all container names

.EXAMPLE
PS C:\temp\STDockerPs> @(dockerps | Where { $_.IMAGE -like "microsoft/*" }).Count
3

PS C:\temp\STDockerPs> @(dockerps | Where { $_.IMAGE -like "microsoft/*" }).Command
"powershell"
"powershell"
"cmd"

.EXAMPLE
dockerps -omit | select -first 1


CONTAINER_ID : 26b08e320d17
IMAGE        : microsoft/nanoserver
COMMAND      : "cmd"
CREATED      : 17 hours ago
STATUS       : Up 17 hours
PORTS        : 

.EXAMPLE
dockerps | select -first 1


CONTAINER_ID : 26b08e320d17
IMAGE        : microsoft/nanoserver
COMMAND      : "cmd"
CREATED      : 17 hours ago
STATUS       : Up 17 hours
PORTS        : 
NAMES        : temp1234temp1234



.EXAMPLE
PS C:\temp\STDockerPs> (dockerps).CONTAINER_ID
26b08e320d17
d92cb8edaf53
9c45b67925db
520649cfb9d7

.EXAMPLE
(dockerps -a).CONTAINER_ID
26b08e320d17
d92cb8edaf53
9c45b67925db
520649cfb9d7
a0fc2bb9ad1b
e82a27f84cb6

#>  
    if ($Args -match '-q|--quiet') {
        docker ps ($Args -replace '-Omit.*')
        return
    }
    
    else {
        $PreservedArgs = $Args | ForEach-Object { $_ } # deep copy
        $DockerPSOutput = @(@(docker ps ($Args -replace '-Omit.*')) | Where-Object {
            $_ -match '\S'
        })
    }
    
    $DockerPSTitles = $DockerPSOutput | Select-Object -First 1
    
    # Since we ((for) now) have a predictable and logical starting point for each
    # column (same char as the header), I will play with SubString to PSobjectify the stuff...
    
    $Indexes = @()
    $Headers = @("CONTAINER ID", "IMAGE", "COMMAND", "CREATED", "STATUS",
        "PORTS", "NAMES")
    foreach ($Header in $Headers) {
        $Indexes += $DockerPSTitles.IndexOf($Header)
    }
    $Indexes += 0 # dummy value, replaced later for each container line, small "trick"..
    $DockerPSOutput | Select-Object -Skip 1 | ForEach-Object {
        Write-Verbose -Message "Current line: $_ (length: $($_.Length))." #-Verbose
        $Indexes[-1] = ([String]$_).Length
        # Avoid spaces in the titles, for easier access later.
        $Object = "" | Select-Object -Property ($MyPSHeaders = @($Headers -replace ' ', '_'))
        foreach ($i in 0..($Indexes.Count - 2)) {
            $Object.($MyPSHeaders[$i]) = $_.SubString(
                $Indexes[$i], ($Indexes[$i + 1] - $Indexes[$i])
            ).TrimEnd()
        }
        if ($PreservedArgs -match '-Omit') {
            $Object | Select-Object -Property ($MyPSHeaders[0..($Headers.Count - 2)])
        }
        else {
            $Object
        }
    }
}
