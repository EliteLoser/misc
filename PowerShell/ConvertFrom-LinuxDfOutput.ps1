#requires -version 2
function ConvertFrom-LinuxDfOutput {
    <#
    .SYNOPSIS
        Convert output from the Linux utility 'df' with the parameter '--portability'
        into PowerShell objects with numerical types. Optionally add MB and GB properties
        using the '-Add1024DividedDiskDizeProperties' parameter.

        Author: Joakim Borger Svendsen, Svendsen Tech. 2024-09-13.

        MIT License.
    #>
    [CmdletBinding()]
    param(
        [String[]] $Text,
        [Switch] $Add1024DividedDiskSizeProperties
    )
    # Add this in an attempt to support direct output from 'df --portability' natively on Linux.
    $Text = $Text -split '(?:\r?\n)+' -join "`n"
    [regex] $HeaderRegex = '\s*File\s*system\s+1024-blocks\s+Used\s+Available\s+Capacity\s+Mounted\s*on\s*'
    [regex] $LineRegex = '^\s*(.+?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+\s*%)\s+(.+)\s*$'
    $Lines = @($Text -split '(?:\r?\n)+')
    Write-Verbose "Line count: $($Lines.Count)"
    if ($Lines[0] -match $HeaderRegex) {
        $FileSystemObjects = @(foreach ($Line in ($Lines | Select-Object -Skip 1)) {
            [regex]::Matches($Line, $LineRegex) | ForEach-Object {
                New-Object -TypeName PSObject -Property @{
                    Filesystem = $_.Groups[1].Value
                    '1024-blocks' = [Decimal] $_.Groups[2].Value
                    Used = [Decimal] $_.Groups[3].Value
                    Available = [Decimal] $_.Groups[4].Value
                    CapacityUsedPercent = [Decimal] ($_.Groups[5].Value -replace '\D')
                    MountedOn = $_.Groups[6].Value
                } | Select-Object Filesystem, 1024-blocks, Used, Available, CapacityUsedPercent, MountedOn
            }
        })
    }
    else {
        Write-Warning -Message "Error in input. Failed to recognize headers from 'df --portability' output."
        # Exit the function.
        return
    }
    if ($Add1024DividedDiskSizeProperties) {
        foreach ($FileSystemObject in $FileSystemObjects) {
            Add-Member -InputObject $FileSystemObject -MemberType NoteProperty -Name '1024-blocksMB' -Value ($FileSystemObject.Used / (1024))
            Add-Member -InputObject $FileSystemObject -MemberType NoteProperty -Name '1024-blocksGB' -Value ($FileSystemObject.Used / (1024*1024))
            Add-Member -InputObject $FileSystemObject -MemberType NoteProperty -Name MBUsed -Value ($FileSystemObject.Used / (1024))
            Add-Member -InputObject $FileSystemObject -MemberType NoteProperty -Name GBUsed -Value ($FileSystemObject.Used / (1024*1024))
            Add-Member -InputObject $FileSystemObject -MemberType NoteProperty -Name MBAvailable -Value ($FileSystemObject.Available / (1024))
            Add-Member -InputObject $FileSystemObject -MemberType NoteProperty -Name GBAvailable -Value ($FileSystemObject.Available / (1024*1024))
        }
    }
    # Explicitly return the objects.
    return $FileSystemObjects
}
