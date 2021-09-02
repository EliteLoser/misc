[CmdletBinding()]
param([Parameter(Mandatory=$true)][string] $DnsServer)

# Copyright 2014, Svendsen Tech
# All rights reserved.
# Joakim Borger Svendsen
# 2014-08-28

Import-Module .\DnsShell # this has to exist ( http://dnsshell.codeplex.com/ )

$Zones = Get-DnsZone -Server $DnsServer

$ReverseZones = $Zones | Where-Object { $_.ZoneName -like '*.arpa' } |
    Select-Object -ExpandProperty ZoneName

# Example zone:
# $ReverseZones = @('12.10.in-addr.arpa')

$Dupes = @(foreach ($z in $ReverseZones) {
    
    Write-Verbose -Message "Processing zone: $z"
    
    $Records = Get-DnsRecord -ServerName $DnsServer -ZoneName $z -RecordType PTR
    $Records | ForEach-Object -Begin {
        $IpHash = @{}
        } -Process {
        $TempArray = $_.Name -replace '\.in-addr\.arpa$' -split '\.'
        $Ip = ($TempArray[-1..-($TempArray.Count)]) -join '.'
        if (-not $IpHash.ContainsKey($Ip)) {
            # New PTR. The Name property is the PTR. Create one-element array.
            $IpHash.$Ip = @($_.HostName)
        }
        else {
            # Duplicate/alias PTR, add to array.
            $IpHash.$Ip += $_.HostName
        }
            
    }
    $Duplicates = $IpHash.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
    $Duplicates | ForEach-Object {
        New-Object psobject -Property @{
            IP = $_.Name
            Duplicates = $_.Value -join '; '
        }
    }
})

# Display in console.
$Dupes | Select IP, Duplicates | Format-Table -AutoSize

# Export CSV file (if any dupes found).
if ($Dupes.Count) {
    Write-Host -Fore Green 'Exporting CSV file PTRdupes.csv'
    $Dupes | Select IP, Duplicates | Export-Csv -Encoding UTF8 -NoTypeInformation -Path PTRdupes.csv -Delimiter ';'
}
