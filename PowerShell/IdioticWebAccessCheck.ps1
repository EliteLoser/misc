if ($PSVersionTable.Version.Major -gt 5 -and -not $IsWindows) {
    Write-Error "Only works on Windows." -ErrorAction Stop
}

# You need to populate this with remote IPs or host names
# $Servers = @('server1', 'server2')

Invoke-Command -ComputerName $Servers -ScriptBlock {
    $CanReachWeb = try {
        if (((Invoke-WebRequest -UseBasicParsing -Uri 'http://microsoft.com' -ErrorAction Stop |
            Select-Object -ExpandProperty Links |
            Select-Object -ExpandProperty href) -match 'https://choice\.microsoft\.com')) { 
                $True
            }
        else { 
            $False
        }
    }
    catch {
        $False
    }
    [PSCustomObject]@{
        ComputerName = $Env:ComputerName
        Domain = Get-WmiObject -Class Win32_ComputerSystem -Property Domain |
            Select-Object -ExpandProperty Domain -ErrorAction SilentlyContinue
        CanReachWeb = $CanReachWeb
    }
}
