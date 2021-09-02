REM <#
@echo off
REM This file needs to be ASCII encoded for cmd.exe to understand it.
copy %0 %0.tmp.ps1 > nul
PowerShell.exe -ExecutionPolicy Unrestricted -NoProfile -Command "$ErrorActionPreference = 'SilentlyContinue'; if ('%0' -notmatch '[\\/]') { . .\%0.tmp.ps1 } else { . %0.tmp.ps1 }; Remove-Item %0.tmp.ps1"
goto :EOF
REM #>

$ErrorActionPreference = 'Continue'

# PowerShell code goes here:

$PSVersionTable

#ls | sort length -desc | select -first 5 | ft -a
#ps | sort ws -desc | select -first 5 | ft -a
