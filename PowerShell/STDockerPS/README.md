# STDockerPS

Turn "docker ps" output into custom PowerShell objects based on the output text format
as of 2018-06-19.

Exported functions: dockerps, dockerpsq

There's built-in help with examples (e.g. "Get-Help dockerps").

Install from the official Microsoft PowerShell Gallery with this command:

`Install-Module -Name STDockerPS`

or for your user only (does not require elevation/administrator console):

`Install-Module -Name STDockerPS -Scope CurrentUser`

Use the '-full' parameter for the dockerps function to also get dynamically generated methods attached to the objects, as demonstrated in the screenshots below. The methods are "dumb" and not custom for each docker command. They simply run "docker container <command_here> <container_ID_here>". You can cheat a bit and pass in parameters to the methods in a hashtable. If you pass keys that correspond to docker commands that go before the container ID, it should work.

I'll figure out something better later, hopefully. Maybe looking at source code and generating from that.

There are two hashtable keys (values are ignored) that are special-cased: -PSForce and -Verbose. The dash is optional, for significantly increased brevity when passing the hash. This means that both `$ContainerVar.RmContainer( @{ "-PSForce" = $True } )` and `$ContainerVar.RmContainer( @{ PSForce = 1 })` will work equivalently.

Using "PSForce" means it will not prompt (I made it prompt by default, seemed like a good idea at the time) before performing the requested action. Using "Verbose" means it will provide verbose output to output stream 4 while the ID is passed to STDOUT, output stream 1.

![alt tag](/img/stdockerps2.0.7.png)

![alt tag](/img/stdockerps-psobject-methods.png)

![alt tag](/img/stdockerps-psobject-properties.png)

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

PS C:\temp\STDockerPs> $Container.StopContainer() # prompted to confirm; answered 'yes'
81c9bfe072e2

PS C:\temp\STDockerPs> $Container.RmContainer( @{ '-PSForce' = 1 } )
81c9bfe072e2

```

Example of working on a collection of objects.

```
PS C:\> $Containers = dockerps -a -full; $Containers | ft

CONTAINER_ID IMAGE                COMMAND CREATED      STATUS                  PORTS NAMES 
------------ -----                ------- -------      ------                  ----- ----- 
9d6cc0aac547 microsoft/nanoserver "cmd"   40 hours ago Up 7 minutes                  temp39
67ca71717171 microsoft/nanoserver "cmd"   40 hours ago Exited (0) 13 hours ago       temp38
eafcabb612da microsoft/nanoserver "cmd"   40 hours ago Up 40 hours                   temp37
796438a6e850 microsoft/nanoserver "cmd"   40 hours ago Up 40 hours                   temp36
a4b49a9c0692 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 40 hours ago       temp35
f4294be07862 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 40 hours ago       temp34
8ee7021bec8f microsoft/nanoserver "cmd"   41 hours ago Exited (0) 40 hours ago       temp33
48754acd5513 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 40 hours ago       temp32
c66589488683 microsoft/nanoserver "cmd"   41 hours ago Up 41 hours                   temp31
4e4d98ee2785 microsoft/nanoserver "cmd"   41 hours ago Up 41 hours                   temp30
c362874ad565 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 41 hours ago       temp14
163833b7c87c microsoft/nanoserver "cmd"   41 hours ago Exited (0) 41 hours ago       temp13
e95d69336508 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 41 hours ago       temp12
cd2eee18a56f microsoft/nanoserver "cmd"   41 hours ago Exited (0) 41 hours ago       temp11
d6c3938082ee microsoft/nanoserver "cmd"   41 hours ago Exited (0) 41 hours ago       temp25
d4f084fe6f14 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 41 hours ago       temp24
34f411fc6746 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 41 hours ago       temp23
0a4b6d83de48 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 41 hours ago       temp22
708a82ec3d9b microsoft/nanoserver "cmd"   41 hours ago Exited (0) 41 hours ago       temp21
17bfc4330461 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 41 hours ago       temp20
f4ad1ea8c9c6 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 41 hours ago       temp19
d944d38f46c9 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 41 hours ago       temp18
1725e43dd75b microsoft/nanoserver "cmd"   41 hours ago Exited (0) 41 hours ago       temp17
3d6e6590f025 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 41 hours ago       temp16
0000974ceb1c microsoft/nanoserver "cmd"   41 hours ago Exited (0) 41 hours ago       temp15



PS C:\> $Containers.Where({ $_.STATUS -like 'Exited*'}).StartContainer( @{ PSForce = 1 } )
67ca71717171
a4b49a9c0692
f4294be07862
8ee7021bec8f
48754acd5513
c362874ad565
163833b7c87c
e95d69336508
cd2eee18a56f
d6c3938082ee
d4f084fe6f14
34f411fc6746
0a4b6d83de48
708a82ec3d9b
17bfc4330461
f4ad1ea8c9c6
d944d38f46c9
1725e43dd75b
3d6e6590f025
0000974ceb1c

PS C:\> dockerps -a | ft

CONTAINER_ID IMAGE                COMMAND CREATED      STATUS                        PORTS NAMES 
------------ -----                ------- -------      ------                        ----- ----- 
9d6cc0aac547 microsoft/nanoserver "cmd"   40 hours ago Up 10 minutes                       temp39
67ca71717171 microsoft/nanoserver "cmd"   40 hours ago Up About a minute                   temp38
eafcabb612da microsoft/nanoserver "cmd"   40 hours ago Up 40 hours                         temp37
796438a6e850 microsoft/nanoserver "cmd"   40 hours ago Up 40 hours                         temp36
a4b49a9c0692 microsoft/nanoserver "cmd"   41 hours ago Up About a minute                   temp35
f4294be07862 microsoft/nanoserver "cmd"   41 hours ago Up About a minute                   temp34
8ee7021bec8f microsoft/nanoserver "cmd"   41 hours ago Up About a minute                   temp33
48754acd5513 microsoft/nanoserver "cmd"   41 hours ago Up About a minute                   temp32
c66589488683 microsoft/nanoserver "cmd"   41 hours ago Up 41 hours                         temp31
4e4d98ee2785 microsoft/nanoserver "cmd"   41 hours ago Up 41 hours                         temp30
c362874ad565 microsoft/nanoserver "cmd"   41 hours ago Exited (0) About a minute ago       temp14
163833b7c87c microsoft/nanoserver "cmd"   41 hours ago Exited (0) 59 seconds ago           temp13
e95d69336508 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 57 seconds ago           temp12
cd2eee18a56f microsoft/nanoserver "cmd"   41 hours ago Exited (0) 56 seconds ago           temp11
d6c3938082ee microsoft/nanoserver "cmd"   41 hours ago Exited (0) 54 seconds ago           temp25
d4f084fe6f14 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 53 seconds ago           temp24
34f411fc6746 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 51 seconds ago           temp23
0a4b6d83de48 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 50 seconds ago           temp22
708a82ec3d9b microsoft/nanoserver "cmd"   41 hours ago Exited (0) 49 seconds ago           temp21
17bfc4330461 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 47 seconds ago           temp20
f4ad1ea8c9c6 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 46 seconds ago           temp19
d944d38f46c9 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 45 seconds ago           temp18
1725e43dd75b microsoft/nanoserver "cmd"   41 hours ago Exited (0) 43 seconds ago           temp17
3d6e6590f025 microsoft/nanoserver "cmd"   41 hours ago Exited (0) 42 seconds ago           temp16
0000974ceb1c microsoft/nanoserver "cmd"   41 hours ago Exited (0) 41 seconds ago           temp15
```

# dockerpsq Example

```
PS C:\Windows\system32> $c = dockerpsq -Name temp30 -Full

PS C:\Windows\system32> $c.StartContainer(( $DoIt = @{ PSForce = 1 } ))
4e4d98ee2785

PS C:\Windows\system32> $c | ft

CONTAINER_ID IMAGE                COMMAND CREATED      STATUS                 PORTS NAMES 
------------ -----                ------- -------      ------                 ----- ----- 
4e4d98ee2785 microsoft/nanoserver "cmd"   2 months ago Exited (0) 7 weeks ago       temp30



PS C:\Windows\system32> # the data isn't updated until you query again...

PS C:\Windows\system32> $c = dockerpsq -Name temp30 -Full

PS C:\Windows\system32> $c | ft

CONTAINER_ID IMAGE                COMMAND CREATED      STATUS        PORTS NAMES 
------------ -----                ------- -------      ------        ----- ----- 
4e4d98ee2785 microsoft/nanoserver "cmd"   2 months ago Up 52 seconds       temp30



PS C:\Windows\system32> $c.StopContainer($DoIt)
4e4d98ee2785

PS C:\Windows\system32> $c.RmContainer($DoIt)
4e4d98ee2785
```
