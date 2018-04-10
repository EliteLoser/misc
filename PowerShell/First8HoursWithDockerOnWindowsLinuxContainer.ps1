# Joakim Borger Svendsen. My first 8 hours with Docker - I went with Docker for Windows
# with Windows containers (the non-default option (that can be changed later)).
# Later I "switched" (right click the icon in the systray) to Linux containers and
# back to Windows. It went flawlessly, to my astonishment.

#######################################################

################## LINUX VERSION ######################

#######################################################


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
$FileSizeBytes = 1MB
$RandomDir = "/RandomData"

if (-not (Test-Path -LiteralPath "$TargetWriteDirectory\RandomData\RandomData.psm1")) {
    Save-Module -Name RandomData -LiteralPath $TargetWriteDirectory
}

# Just assigning $foo = docker # works, just think this is probably more robust for whitespace weirdness...
# Start a detached instance of microsoft/nanoserver with cmd.exe waiting for commands.
# Without "--tty", the container is immediately stopped afterwards (and leaves remains
# unless you used "--rm").
Write-Verbose -Verbose "Creating a CentOS/Linux container that will be deleted when it is stopped/exits."
$ContainerID = ([String](docker run -d --name BenchmarkTempLinux `
    --rm --tty --mount type=bind,source=$TargetWriteDirectory,target=/RandomData centos bash)).Trim()
if ($LASTEXITCODE -ne 0) {
    Read-Host -Prompt "Something went wrong. Taking a break here. Press Ctrl-C to abort the script or press enter to continue"
}
else {
    "Successfully created a CentOS container with docker."
}

"`ndocker ps condensed output:`n"

@(docker ps -l) -replace '\s+\w+$'

<#
# Create a directory for writing the data to.
## now created by the docker mount
Write-Verbose -Verbose "Creating '$RandomDir' in the container ($ContainerID)."
docker exec $ContainerID bash -c "mkdir '$RandomDir'"
if ($LASTEXITCODE -ne 0) {
    Read-Host -Prompt "Something went wrong. Taking a break here. Press Ctrl-C to abort the script or press enter to continue"
}
#>

docker exec $ContainerID bash -c "curl https://packages.microsoft.com/config/rhel/7/prod.repo > /etc/yum.repos.d/microsoft.repo; yum -y install powershell"
if ($LASTEXITCODE -ne 0) {
    Read-Host -Prompt "Something went wrong. Taking a break here. Press Ctrl-C to abort the script or press enter to continue"
}
else {
    "Successfully installed PowerShell on the CentOS VM"
}

$GotTheEndTime = $False
$StartTime = Get-Date
Write-Verbose -Verbose "Saved start time before writing data."

<#
docker exec $ContainerID powershell -Command "Remove-Item -Path C:\RandomData\*
    foreach (`$i in 1..$NumberOfFiles) {
    [void] (fsutil file createnew C:\RandomData\RandomFile`$i.binary $FileSizeBytes)
}"
#>

docker exec $ContainerID pwsh -Command "
    Install-Module -Name RandomData -Scope CurrentUser -Force -EA Stop # pass exception?
    New-RandomData -Path $RandomDir -Count $NumberOfFiles -Size $FileSizeBytes -LineLength 128 -Extension .binary -Verbose
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
