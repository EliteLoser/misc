#requires -version 2
function ConvertFrom-LinuxDfOutput {
    param([string] $Text)
    [regex] $HeaderRegex = '\s*File\s*system\s+1024-blocks\s+Used\s+Available\s+Capacity\s+Mounted\s*on\s*'
    [regex] $LineRegex = '^\s*(.+?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+\s*%)\s+(.+)\s*$'
    $Lines = @($Text -split '[\r\n]+')
    if ($Lines[0] -match $HeaderRegex) {
        foreach ($Line in ($Lines | Select -Skip 1)) {
            [regex]::Matches($Line, $LineRegex) | foreach {
                New-Object -TypeName PSObject -Property @{
                    Filesystem = $_.Groups[1].Value
                    '1024-blocks' = [decimal] $_.Groups[2].Value
                    Used = [decimal] $_.Groups[3].Value
                    Available = [decimal] $_.Groups[4].Value
                    CapacityPercent = [decimal] ($_.Groups[5].Value -replace '\D')
                    MountedOn = $_.Groups[6].Value
                } | Select Filesystem, 1024-blocks, Used, Available, CapacityPercent, MountedOn
            }
        }
    }
    else {
        Write-Warning -Message "Error in output. Failed to recognize headers from 'df --portability' output."
    }
} 
