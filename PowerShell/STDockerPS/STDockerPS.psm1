#requires -version 2
function GetDockerContainerCommands {
    # List all "docker container --help" commands (or at least attempt to).
    # I made the leading whitespace mandatory to avoid the exception with the last
    # line with "Run 'docker container COMMAND --help' for more information on a command."
    # Not sure which is more rubust, I'm not a shrink and can't read minds either. :p
    
    # Cache results, obvious optimization... Should replace these docker client things
    # and parsing with API calls when possible.
    if (-not $Script:DockerContainerCommands) {
        $Script:DockerContainerCommands = @{}
    }
    else {
        $Script:DockerContainerCommands.Keys
        return
    }
    [Regex]::Matches(( (@(docker container --help) | 
    Select-String -Pattern '^\s*Commands:\s*$' -Context 10000).Context.DisplayPostContext -join "`n"), 
    '(?m)^\s+(\S+)\s+.+') | ForEach-Object -Begin {
        $HashTable = @{}
        } -Process {
        $HashTable.($_.Groups[1].Value) = $True
        } -End {
        $HashTable.Keys
    }
    if ($Script:DockerContainerCommands.Keys.Count -lt 1) {
        $Script:DockerContainerCommands = $HashTable
    }
}

function dockerps {
<#
.SYNOPSIS
    Turn "docker ps" output into custom PowerShell objects. Add docker container methods
    to the objects by specifying the "-Full" parameter to dockerps, at the expense of
    speed and some CPU usage.

.DESCRIPTION
    The parsing to "objectify" relies on the column widths in this case, rather than my usual
    approach of using regular expressions, since it seems more robust for this
    case/output at hand. Will use API calls later, when possible.

    Use the parameter "-OmitNames" (will not be tab completed) to omit the name column for the
    containers. This is to get more condensed output. Just "-Omit" will work as a minimum.
    
    Use the parameter "-Full" (will not be tab completed) to add docker methods to the custom
    PowerShell objects dockerps returns. These are dynamically generated for each container and
    attached to each object. Therefore it uses some CPU and is a bit slower than without this
    parameter, but without you do not get the methods, only data/properties (no "docker interaction"
    through the objects themselves). The methods are tacked on and not special-cased. They assume
    a container ID belongs at the end.

    Otherwise, "docker ps --help" is what you should read for further information about the
    available parameters.

    -q / --quiet is special-cased to work identically as in the native "docker ps -q" (lists
    only container IDs).

.PARAMETER OmitNames
    Omit the container name column. Not tab completed. "-Omit" is the shortest allowed form.
.PARAMETER Full
    Add docker container methods to the custom PowerShell objects dockerps returns, at the
    expense of speed and some CPU usage. Not tab completed.

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

.EXAMPLE
PS C:\> $x = dockerps -a -full
PS C:\> $x[4].RestartContainer( @{ PSForce = 1 } )
a4b49a9c0692

PS C:\temp\STDockerPs> dockerps -a | ft

CONTAINER_ID IMAGE                COMMAND CREATED      STATUS                   PORTS NAMES 
------------ -----                ------- -------      ------                   ----- ----- 
9d6cc0aac547 microsoft/nanoserver "cmd"   42 hours ago Exited (0) 6 minutes ago       temp39
67ca71717171 microsoft/nanoserver "cmd"   42 hours ago Up About an hour               temp38
eafcabb612da microsoft/nanoserver "cmd"   42 hours ago Up 42 hours                    temp37
796438a6e850 microsoft/nanoserver "cmd"   42 hours ago Up 42 hours                    temp36
a4b49a9c0692 microsoft/nanoserver "cmd"   42 hours ago Up 8 seconds                   temp35
f4294be07862 microsoft/nanoserver "cmd"   42 hours ago Up About an hour               temp34
8ee7021bec8f microsoft/nanoserver "cmd"   42 hours ago Up About an hour               temp33
48754acd5513 microsoft/nanoserver "cmd"   42 hours ago Up About an hour               temp32
c66589488683 microsoft/nanoserver "cmd"   42 hours ago Up 42 hours                    temp31
4e4d98ee2785 microsoft/nanoserver "cmd"   42 hours ago Up 42 hours                    temp30

.EXAMPLE
PS C:\temp\STDockerPs> docker ps # the native command that returns text..
CONTAINER ID        IMAGE                  COMMAND             CREATED              STATUS              PORTS               NAMES
0ee74ffb1c94        microsoft/nanoserver   "powershell"        10 seconds ago       Up 8 seconds                            temp14
6c692d226125        microsoft/nanoserver   "powershell"        19 seconds ago       Up 16 seconds                           temp13
168a95901a92        microsoft/nanoserver   "powershell"        28 seconds ago       Up 25 seconds                           temp12
e016f93d662d        microsoft/nanoserver   "powershell"        30 seconds ago       Up 27 seconds                           temp11
542cf524b3e2        microsoft/nanoserver   "powershell"        32 seconds ago       Up 29 seconds                           temp10
c08e1e9ff5d7        microsoft/nanoserver   "powershell"        34 seconds ago       Up 31 seconds                           temp9
0e91d4d8a945        microsoft/nanoserver   "powershell"        36 seconds ago       Up 33 seconds                           temp8
393413eae3d1        microsoft/nanoserver   "powershell"        38 seconds ago       Up 35 seconds                           temp7
dbb26f999892        microsoft/nanoserver   "cmd"               48 seconds ago       Up 45 seconds                           temp6
d449d533d010        microsoft/nanoserver   "cmd"               About a minute ago   Up About a minute                       temp5

# dockerps and objects with methods, restarting all containers running powershell

PS C:\temp\STDockerPs> @(dockerps -a -full).Where({
    $_.COMMAND -like '"powershell*'
}).RestartContainer( @{ PSForce = 1 } )
0ee74ffb1c94
6c692d226125
168a95901a92
e016f93d662d
542cf524b3e2
c08e1e9ff5d7
0e91d4d8a945
393413eae3d1

PS C:\temp\STDockerPs> dockerps -a | ft

CONTAINER_ID IMAGE                COMMAND      CREATED       STATUS                       PORTS NAMES 
------------ -----                -------      -------       ------                       ----- ----- 
0ee74ffb1c94 microsoft/nanoserver "powershell" 3 minutes ago Up 45 seconds                      temp14
6c692d226125 microsoft/nanoserver "powershell" 3 minutes ago Up 43 seconds                      temp13
168a95901a92 microsoft/nanoserver "powershell" 3 minutes ago Up 41 seconds                      temp12
e016f93d662d microsoft/nanoserver "powershell" 3 minutes ago Up 39 seconds                      temp11
542cf524b3e2 microsoft/nanoserver "powershell" 3 minutes ago Up 37 seconds                      temp10
c08e1e9ff5d7 microsoft/nanoserver "powershell" 3 minutes ago Up 34 seconds                      temp9 
0e91d4d8a945 microsoft/nanoserver "powershell" 3 minutes ago Up 32 seconds                      temp8 
393413eae3d1 microsoft/nanoserver "powershell" 3 minutes ago Up 30 seconds                      temp7 
dbb26f999892 microsoft/nanoserver "cmd"        4 minutes ago Up 4 minutes                       temp6 
d449d533d010 microsoft/nanoserver "cmd"        4 minutes ago Up 4 minutes                       temp5 

.EXAMPLE
PS C:\temp\STDockerPs> $x[0].LsContainer(@{ PSForce = 1; Verbose = 1; '"# comment key' = 1})
VERBOSE: Running: docker container ls  "#  0ee74ffb1c94

CONTAINER ID        IMAGE                  COMMAND             CREATED             STATUS              PORTS               NAMES
0ee74ffb1c94        microsoft/nanoserver   "powershell"        2 weeks ago         Up 11 hours                             temp14
6c692d226125        microsoft/nanoserver   "powershell"        2 weeks ago         Up 11 hours                             temp13
168a95901a92        microsoft/nanoserver   "powershell"        2 weeks ago         Up 11 hours                             temp12
e016f93d662d        microsoft/nanoserver   "powershell"        2 weeks ago         Up 11 hours                             temp11

This runs the command "docker container ls" in a very, very inconvenient way. It's similar to
SQL injection, except opposite, and ... not. Adding the keys "-PSForce" (to avoid being prompted)
and/or "-Verbose" is supported. I made the dash optional for this so you can skip the quotes
around the key, i.e.: @{ PSForce = 1; Verbose = 1 } # this will work.

You can add more custom parameters that go before the ID, as hashtable keys. The values are ignored 
and if you don't want the ID
at the end, you can use the "comment key" you see above. All you need to add is: '"#' = 1
to the hashtable and it will end the string and comment out the container ID that's the remainder
of the line. It's for flexibility at this point. I don't see how security is even related now?
It's a tool for the Docker administrators. If somehow it evolved into an "end user" tool, then
I can see it, but I don't see that for this.

#>  
    if ($Args -match '-q|--quiet') {
        docker ps ($Args -replace '-Omit.*|-Full')
        return
    }
    else {
        $PreservedArgs = $Args | ForEach-Object { $_ } # deep copy
        $OldEAP = $ErrorActionPreference
        $ErrorActionPreference = "Stop"
        try {
            $DockerPSOutput = @(@(docker ps ($Args -replace '-Omit.*|-Full')) | Where-Object {
                $_ -match '\S'
            })
        }
        catch {
            Write-Error -Message "Caught an error: $_" -ErrorAction Stop
            return
        }
        $ErrorActionPreference = $OldEAP
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
    
    $TextInfo = [CultureInfo]::CurrentCulture.TextInfo
    
    $DockerPSOutput | Select-Object -Skip 1 | ForEach-Object {
    
        Write-Verbose -Message "Current line: $_ (length: $($_.Length))." #-Verbose
        $Indexes[-1] = ([String]$_).Length
    
        # Avoid spaces in the titles, for easier access later.
        $Object = "" | Select-Object -Property ($MyPSHeaders = @($Headers -replace ' ', '_'))
        
        foreach ($i in 0..($Indexes.Count - 2)) {
            $Object.($MyPSHeaders[$i]) = $_.SubString(
                $Indexes[$i], ($Indexes[$i + 1] - $Indexes[$i])
            ).Trim()
        }
        
        if ($PreservedArgs -match '-Full') {
            foreach ($Command in @(GetDockerContainerCommands)) {
                $TitleCommand = $TextInfo.ToTitleCase($Command)
                $Object | Add-Member -MemberType ScriptMethod -Name "${TitleCommand}Container" -Value ([ScriptBlock]::Create("
                    [CmdletBinding()]
                    Param([HashTable] `$InternalArgs = @{})
                    function $TitleCommand-DockerContainer {
                        [CmdletBinding(
                            SupportsShouldProcess = `$True,
                            ConfirmImpact = 'High')]
                        Param(
                            [System.Object] `$This2,
                            [HashTable] `$InternalArgs)
                        if (`$InternalArgs.Keys -match '-?PSForce' -or `
                            `$PSCmdlet.ShouldProcess(`"[OPERATION: $Command] `$(`$This2.CONTAINER_ID) (`$(`$This2.NAMES))`")) {
                            `$OldEAP = `$ErrorActionPreference
                            `$ErrorActionPreference = 'Stop'
                            try {
                                if (`$InternalArgs.Keys -match '^-?Verbose$') {
                                    Write-Verbose -Verbose `"Running: docker container $Command `$(`$InternalArgs.Keys -replace '-?PSForce|-?Verbose') `$(`$This2.CONTAINER_ID)`"
                                }
                                # Wrap in a powershell.exe call to allow for commenting out the ID (this is, admittedly, a little weird...)
                                powershell -command `"docker container $Command `$(`$InternalArgs.Keys -replace '-?PSForce|-?Verbose') `$(`$This2.CONTAINER_ID)`"
                            }
                            catch {
                                Write-Error -Message `$_.ToString()
                            }
                            `$ErrorActionPreference = `$OldEAP
                        }
                    }
                    $TitleCommand-DockerContainer -This2 `$this -InternalArgs `$InternalArgs
                "))
            }
        }
        if ($PreservedArgs -match '-Omit') {
            $Object | Select-Object -Property ($MyPSHeaders[0..($Headers.Count - 2)])
        }
        else {
            $Object
        }
    }
}

function dockerpsq {
    <#
    .SYNOPSIS
        Query for a container ID or name and get an object back.
        
        Use the "-Full" parameter to also get docker container methods
        attached to the object or objects returned. This is a bit slower.

    .PARAMETER Any
        Default, position 0. Pass in either name or ID wildcard string.
    .PARAMETER Identity
        Container ID to query for. Wildcards supported.
    .PARAMETER Name
        Container name to query for. Wildcards supported.
    .PARAMETER Full
        Add docker script methods to the returned PowerShell objects.
    
    .EXAMPLE
    PS C:\temp\STDockerPs> dockerpsq temp34, c6658*


    CONTAINER_ID : f4294be07862
    IMAGE        : microsoft/nanoserver
    COMMAND      : "cmd"
    CREATED      : 2 months ago
    STATUS       : Exited (0) 7 weeks ago
    PORTS        : 
    NAMES        : temp34

    CONTAINER_ID : c66589488683
    IMAGE        : microsoft/nanoserver
    COMMAND      : "cmd"
    CREATED      : 2 months ago
    STATUS       : Exited (0) 7 weeks ago
    PORTS        : 
    NAMES        : temp31
    
    #>
    [CmdletBinding(
        DefaultParameterSetName = "Any"
    )]
    Param(
        [Parameter(ParameterSetName="Any",
                   Mandatory = $True,
                   Position = 0)][String[]] $Container,
        [Parameter(ParameterSetName="ID",
                   Mandatory = $True)][String[]] $Identity,
        [Parameter(ParameterSetName="Name",
                   Mandatory = $True)][String[]] $Name,
        [Switch] $Full)
    @(dockerps -a $( if ($Full) { "-Full" } )) | ForEach-Object {
        if ($PSCmdlet.ParameterSetName -eq "Any") {
            foreach ($Cont in $Container) {
                if ($_.CONTAINER_ID -like $Cont -or $_.NAMES -like $Cont) {
                    $_
                }
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq "Identity") {
            foreach ($Id in $Identity) {
                if ($_.CONTAINER_ID -like $Id) {
                    $_
                }
            }
        }
        if ($PSCmdlet.ParameterSetName -eq "Name") {
            foreach ($Nom in $Name) {
                if ($_.NAMES -like $Nom) {
                    $_
                }
            }
        
        }
    }
}
