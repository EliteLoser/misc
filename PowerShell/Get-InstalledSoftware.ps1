$Installed = @(Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate)
$Installed += Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
$Installed = $Installed |
    Where-Object {$null -ne $_.DisplayName} |
    Sort-Object -Property DisplayName -Unique |
    ConvertTo-Csv -NoTypeInformation
$Installed += choco list -lo -r -y | ForEach-Object {'"' + $_.Replace("|", '","') + '","Chocolatey",""'}
$InstalledString = $Installed -join "`n"
Write-Verbose -Verbose $InstalledString
