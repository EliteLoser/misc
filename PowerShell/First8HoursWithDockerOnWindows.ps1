# Joakim Borger Svendsen. My first 8 hours with Docker - I went with Docker for Windows
# with Windows containers (the non-default option (that can be changed later)).
# Later I "switched" (right click the icon in the systray) to Linux containers and
# back to Windows. It went flawlessly, to my astonishment.

# DOCKERFIRST8

# Tested on Windows Server 2016, on 2018-04-10
# Install Docker for Windows using the .exe file you can find from this link:
# https://docs.docker.com/docker-for-windows/install/#download-docker-for-windows

# I came up with a pretty useless test case (at least for me) that is benchmarking
# file writes to different target disks on the host...
# There's no need for the abstraction through the container if all
# you want is to measure the storage.. If you use identical code you can at least
# measure the difference between Linux/NanoServer... Python or PSv6?

# To install the image for Microsoft Windows Nano Server with PowerShell/.NET Core:
# docker pull microsoft/nanoserver

# Other useful images:
# docker pull centos
# docker pull vmware/powerclicore

# To start an interactive powershell.exe instance in a container
# that will be deleted upon exit:
# docker run --tty --interactive --rm microsoft/nanoserver powershell

# To start a detached, "persistent" container, add --tty and -d:
# $ContainerID = docker run --tty -d --rm microsoft/nanoserver cmd
# ... Then you can later issue commands to that with something like:
# docker exec $ContainerID cmd /c echo test
# or ...
# docker exec $ContainerID powershell -command "Import-Module FancyModule; Do-FancyModuleStuff"


$TargetWriteDirectory = "H:\RandomData"
$null = New-Item -ItemType Directory -Path $TargetWriteDirectory -Force -ErrorAction SilentlyContinue
$NumberOfFiles = 10
$FileSizeBytes = 10MB

if (-not (Test-Path -LiteralPath "$TargetWriteDirectory\RandomData\RandomData.psm1")) {
     Save-Module -Name RandomData -LiteralPath $TargetWriteDirectory
}

# Just assigning $foo = docker # works, just think this is probably more robust for whitespace weirdness...
# Start a detached instance of microsoft/nanoserver with cmd.exe waiting for commands.
# Without "--tty", the container is immediately stopped afterwards (and leaves remains
# unless you used "--rm").
Write-Verbose -Verbose "Creating a Nano Server container that will be deleted when it is stopped/exits."
$ContainerID = ([String](docker run -d --name BenchmarkTemp `
    --rm --tty --mount type=bind,source=$TargetWriteDirectory,target=C:\RandomData microsoft/nanoserver cmd)).Trim()
if ($LASTEXITCODE -ne 0) {
    Read-Host -Prompt "Something went wrong. Taking a break here. Press Ctrl-C to abort the script or press enter to continue"
}
else {
    "Successfully created a Microsoft Windows Nano Server container with docker."
}

"docker ps condensed output:`n"

@(docker ps -l) -replace '\s+\w+$'

<#
# Create a directory for writing the data to.
## now created by the docker mount
$RandomDir = "C:\RandomData"
Write-Verbose -Verbose "Creating '$RandomDir' in the container ($ContainerID)."
docker exec $ContainerID cmd /c md $RandomDir
if ($LASTEXITCODE -ne 0) {
    Read-Host -Prompt "Something went wrong. Taking a break here. Press Ctrl-C to abort the script or press enter to continue"
}
#>

$GotTheEndTime = $False
$StartTime = Get-Date
Write-Verbose -Verbose "Saved start time before writing data."

<#
docker exec $ContainerID powershell -Command "Remove-Item -Path C:\RandomData\*
    foreach (`$i in 1..$NumberOfFiles) {
    [void] (fsutil file createnew C:\RandomData\RandomFile`$i.binary $FileSizeBytes)
}"
#>

docker exec $ContainerID powershell -Command "
    Import-Module C:\RandomData\RandomData -EA Stop # pass exception?
    New-RandomData -Path C:\RandomData -Count $NumberOfFiles -Size $FileSizeBytes -LineLength 128 -Extension .binary -Verbose
"
if ($LASTEXITCODE -ne 0) {
    $EndTime = Get-Date
    $GotTheEndTime = $True
    Read-Host -Prompt "Something went wrong. Taking a break here. Press Ctrl-C to abort the script or press enter to continue"
}
if (-not $GotTheEndTime) {
    $EndTime = Get-Date
}

"Elapsed time:"

$EndTime - $StartTime

$null = docker container stop $ContainerID # will be deleted automatically
if ($LASTEXITCODE -ne 0) {
    Read-Host -Prompt "Something went wrong. Taking a break here. Press Ctrl-C to abort the script or press enter to continue"
}
else {
    "Successfully stopped and deleted the container."
}

# Prepare for a reboot using STDockerPS (exports the function "dockerps" - I guess there are APIs for this...)
# PS C:\temp\STDockerPs> dockerps | ft
#
#CONTAINER_ID IMAGE                COMMAND      CREATED    STATUS    PORTS NAMES           
#------------ -----                -------      -------    ------    ----- -----           
#b1e4f7865718 microsoft/nanoserver "powershell" 2 days ago Up 2 days       temp4           
#26b08e320d17 microsoft/nanoserver "cmd"        7 days ago Up 7 days       temp1234temp1234
#d92cb8edaf53 microsoft/nanoserver "powershell" 8 days ago Up 8 days       temp3           
#9c45b67925db microsoft/nanoserver "powershell" 8 days ago Up 8 days       temp2           
#520649cfb9d7 microsoft/nanoserver "cmd"        8 days ago Up 8 days       temp1           
#
#
#
#PS C:\temp\STDockerPs> @(dockerps).ForEach({
#    docker container stop $_.Container_ID
#    #docker container rm $_.Container_ID
#})
#b1e4f7865718
#26b08e320d17
#d92cb8edaf53
#9c45b67925db
#520649cfb9d7
#
#PS C:\temp\STDockerPs> dockerps | ft
#
#PS C:\temp\STDockerPs> 
#
#
