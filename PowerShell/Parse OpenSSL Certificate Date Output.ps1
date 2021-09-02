$LinuxServer = "www.svendsentech.no"
$TargetCertDNS = "www.powershelladmin.com"

#$SSHCredentials = Import-Clixml C:\Temp\testcreds.xml # protected by DPAPI...
#$SSHCredentials = Get-Credential root # set earlier

# Assuming SSHSessions module version above 1.9,
# otherwise don't index into the ".Result" property
# and there won't be an ".Error" property...
Import-Module SSHSessions -ErrorAction Stop
New-SshSession -ComputerName $LinuxServer -ErrorAction Stop -Credential $SSHCredentials

$SSHOutput = Invoke-SSHCommand -ComputerName $LinuxServer -Quiet `
    -Command "echo | openssl s_client -connect $($TargetCertDNS):443 -servername $($TargetCertDNS):443 2> /dev/null | openssl x509 -noout -dates"
if ($SSHOutput.Error) {
    # handle error
}
elseif ($SSHOutput[0].Result -match '^(?ms)\s*notBefore\s*=\s*(.+)notAfter\s*=\s*(.+)$') {
    Write-Verbose -Verbose "Regex matched."
    Write-Verbose -Verbose "`$Matches[1] (notBefore) is: $($Matches[1].TrimEnd())"
    Write-Verbose -Verbose "`$Matches[2] (notAfter) is:  $($Matches[2].TrimEnd())"
    $NotAfter, $NotBefore = "Unset", "Unset"
    $ErrorActionPreference = "Stop"
    try {
        $NotAfter = [DateTime]::ParseExact(
            [regex]::Replace(
                ($Matches[2] -replace '\s*GMT\s*$' -replace '(.+)\s+([\d:]+)\s+(\d{4})', '$1 $3 $2'), '(\w+)\s+(\d?\d)\s+(.+)', {
                    $args[0].Groups[1].Value + " " + ("{0:D2}" -f [int] $args[0].Groups[2].Value) + " " + $args[0].Groups[3].Value
                }
            ), 'MMM dd yyyy HH:mm:ss', [CultureInfo]::InvariantCulture)
    }
    catch {
        $NotAfter = "Parse error"
    }
    try {
        $NotBefore = [DateTime]::ParseExact(
            [regex]::Replace(
                ($Matches[1] -replace '\s+GMT\s*' -replace '^(.+)\s+([\d:]+)\s+(\d{4})$', '$1 $3 $2'), '(\w+)\s+(\d?\d)\s+(.+)', {
                    $args[0].Groups[1].Value + " " + ("{0:D2}" -f [int] $args[0].Groups[2].Value) + " " + $args[0].Groups[3].Value
                }
            ), 'MMM dd yyyy HH:mm:ss', [CultureInfo]::InvariantCulture)
    }
    catch {
            $NotBefore = "Parse error"
    }
    $ErrorActionPreference = "Continue"
}
else {
    $NotAfter = "Parse error (no match)"
    $NotBefore = "Parse error (no match)"
}

[PSCustomObject] @{
    ComputerName = $LinuxServer
    TargetCertificateDNS = $TargetCertDNS
    NotAfter = $NotAfter
    NotBefore = $NotBefore
}
