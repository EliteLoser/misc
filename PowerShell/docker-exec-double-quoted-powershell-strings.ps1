# 2018-07-26.
# Using double-quoted strings in docker exec PowerShell commands.
# You need to escape them with a backslash for some reason.

# These all work:

docker exec $ContainerID powershell -command '[String] \"test\"'

docker exec $ContainerID powershell -command '[String] ''test'''

docker exec $ContainerID powershell -command '\"test\"'

docker exec $ContainerID powershell -command '''test'''

docker exec $ContainerID powershell -command "\`"test\`""

$Var = "SomeString"
docker exec $ContainerID powershell -command "\`"test with a variable: $Var\`""

# if you don't, you will get something like this:
<#

PS C:\temp> docker exec $ContainerID powershell -command '"test"'
docker : test : The term 'test' is not recognized as the name of a cmdlet, function, 
At line:1 char:1
+ docker exec $ContainerID powershell -command '"test"'
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (test : The term...let, function, :String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
script file, or operable program. Check the spelling of the name, or if a path 
was included, verify that the path is correct and try again.
At line:1 char:1
+ test
+ ~~~~
    + CategoryInfo          : ObjectNotFound: (test:String) [], CommandNotFoun 
   dException
    + FullyQualifiedErrorId : CommandNotFoundException
 
#>
