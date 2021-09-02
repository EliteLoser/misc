@(foreach ($Computer in $ComputerName) {
    Write-Host -ForegroundColor Green "Processing $Computer ..."
    $ErrorActionPreference = 'SilentlyContinue'
    $TaskText = schtasks.exe /query /s $Computer /fo list /v
    if (-not $?) {
        Write-Warning -Message "$Computer`: schtasks.exe failed"
        continue
    }
    $ErrorActionPreference = 'Continue'
    $TaskText = $TaskText -join "`n"
    @(
    foreach ($m in @([regex]::Matches($TaskText, '(?ms)^Folder:[\t ]*([^\n]+)\n(.+)'))) {
        $Folder = $m.Groups[1].Value
        foreach ($FolderEntries in @($m.Groups[2].Value -split "\n\n")) {
            foreach ($Inner in $FolderEntries) {
                [regex]::Matches([string] $Inner, '(?m)^((?:Repeat:\s)?(?:Until:\s)?[^:]+):[\t ]+(.*)') |
                    ForEach-Object -Begin { $h = @{}; $h.'Folder' = [string] $Folder  } -Process {
                        $h.($_.Groups[1].Value) = $_.Groups[2].Value
                    } -End { New-Object -TypeName PSObject -Property $h }
            }
        }
    }) | Where-Object { $_.Folder -notlike '\Microsoft*' -and `
        $_.'Run As User' -notmatch '^(?:SYSTEM|LOCAL SERVICE|Everyone|Users|Administrators|INTERACTIVE)$' -and `
        $_.'Task To Run' -notmatch 'COM handler' } #|
        #Select HostName, Folder, 'Run As User', 'Task To Run', 'Schedule Type', 'Logon Mode' #, * #| ft -AutoSize
}) # | Export-Csv -NoTypeInformation -Encoding UTF8 -Path oracleservertasks.csv
