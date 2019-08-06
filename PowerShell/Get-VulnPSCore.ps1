# Author: Joakim Borger Svendsen. "Quick and dirty, but ok done, hopefully."
# Find vulnerable PowerShell versions as per:
<#

Security vulnerability in PowerShell Core
----------------------------------------------
Microsoft have released an advisory concerning a high severity security vulnerability in PowerShell Core version 6.1 and 6.2. The vulnerability has been given the CVE designation CVE-2019-1167 and has been patched in version 6.1.5 and 6.2.2.
https://github.com/PowerShell/PowerShell/security/advisories/GHSA-5frh-8cmj-gc59
https://www.us-cert.gov/ncas/current-activity/2019/07/16/microsoft-releases-security-updates-powershell-core
#>

Import-Module -Name ActiveDirectory
$Global:STServers = Get-ADComputer -Filter { OperatingSystem -like "*Windows*Server*" }
$Global:STResults = Invoke-Command -ComputerName $Global:STServers.Name -ErrorAction SilentlyContinue -ScriptBlock {
    # Look for powershell.exe (early alpha/beta/etc. of PSCore had this executable name).
    $PSInstances = @(Get-Command -Name powershell |
        Select-Object -ExpandProperty Path)

    # Look for pwsh.exe
    $PSInstances += Get-Command -Name pwsh -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue

   

    $TempObject = New-Object -TypeName PSObject -Property @{
        ComputerName = $Env:ComputerName
        Domain = Get-WmiObject -Class ComputerSystem -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty Domain -ErrorAction SilentlyContinue
        PSInstanceCount = $PSInstances.Count
        pwshCount = @($PSInstances |
            Where-Object { $_ -match 'pwsh\.exe' }).Count
        VulnPwshCount = @($PSInstances |
            Where-Object { $_ -match '\\6\.1|\\6\.2' }).Count
    }

    foreach ($PSInstance in $PSInstances) {
        ++$Counter
        Add-Member -InputObject $TempObject -MemberType NoteProperty -Name "PSInstance$('{0:D3}' -f $Counter)" -Value $PSInstance
    }

    $TempObject

}

$Global:STResults
Write-Verbose "Results are in `$Global:STResults" -Verbose

