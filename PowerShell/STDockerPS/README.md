# STDockerPS

Turn "docker ps" output into custom PowerShell objects based on the output text format
as of 2018-04-12.

Install from the official Microsoft PowerShell Gallery with this command:

`Install-Module -Name STDockerPS`

or for your user only (does not require elevation/administrator console):

`Install-Module -Name STDockerPS -Scope CurrentUser`

![alt tag](/img/stdockerps2.0.7.png)

![alt tag](/img/stdockerps_psobject-methods.png)

![alt tag](/img/stdockerps_psobject-properties.png)

![alt tag](/img/stdockerps_pic2.png)

```powershell
PS C:\temp\STDockerPs> $Containers = dockerps -a -full # '-full' is for dockerps, not docker ps

PS C:\temp\STDockerPs> $Containers.Count
26

PS C:\temp\STDockerPs> $Containers | Format-Table

CONTAINER_ID IMAGE                COMMAND CREATED      STATUS                  PORTS NAMES 
------------ -----                ------- -------      ------                  ----- ----- 
81c9bfe072e2 microsoft/nanoserver "cmd"   38 hours ago Up 33 seconds                 temp40
9d6cc0aac547 microsoft/nanoserver "cmd"   38 hours ago Exited (0) 13 hours ago       temp39
67ca71717171 microsoft/nanoserver "cmd"   38 hours ago Exited (0) 10 hours ago       temp38
eafcabb612da microsoft/nanoserver "cmd"   38 hours ago Up 38 hours                   temp37
796438a6e850 microsoft/nanoserver "cmd"   38 hours ago Up 38 hours                   temp36
a4b49a9c0692 microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp35
f4294be07862 microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp34
8ee7021bec8f microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp33
48754acd5513 microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp32
c66589488683 microsoft/nanoserver "cmd"   38 hours ago Up 38 hours                   temp31
4e4d98ee2785 microsoft/nanoserver "cmd"   38 hours ago Up 38 hours                   temp30
c362874ad565 microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp14
163833b7c87c microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp13
e95d69336508 microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp12
cd2eee18a56f microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp11
d6c3938082ee microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp25
d4f084fe6f14 microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp24
34f411fc6746 microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp23
0a4b6d83de48 microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp22
708a82ec3d9b microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp21
17bfc4330461 microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp20
f4ad1ea8c9c6 microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp19
d944d38f46c9 microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp18
1725e43dd75b microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp17
3d6e6590f025 microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp16
0000974ceb1c microsoft/nanoserver "cmd"   38 hours ago Exited (0) 38 hours ago       temp15



PS C:\temp\STDockerPs> $Containers[0].StartContainer( @{ '-PSForce' = 1; '-Verbose' = 1 } )
VERBOSE: Running: docker container start   81c9bfe072e2
81c9bfe072e2

PS C:\temp\STDockerPs> $Container = dockerps -a | where { $_.CONTAINER_ID -eq $Containers[0].CONTAINER_ID }

# Need "-Full" to get methods (a lot slower).

PS C:\temp\STDockerPs> $Container = dockerps -a -full | where { $_.CONTAINER_ID -eq $Containers[0].CONTAINER_ID }

PS C:\temp\STDockerPs> $Container.STATUS
Up About a minute

PS C:\temp\STDockerPs> $Container.StopContainer()
81c9bfe072e2

PS C:\temp\STDockerPs> $Container.RmContainer( @{ '-PSForce' = 1 } )
81c9bfe072e2

```
