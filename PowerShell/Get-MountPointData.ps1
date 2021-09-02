### Copyright (c) 2012-2014, Svendsen Tech
### Author: Joakim Svendsen
### Get-MountPointData v1.2

# "Change history": 1.0 -> 1.1 = -Credential, -PromptForCredentials and -NoFormat (the latter allows math operations)
# --- " ---:        1.1 -> 1.2 = -IncludeDiskInfo to show physical disk index number (this was not trivial).

# Convert from one device ID format to another.
function Get-DeviceIDFromMP {
    
    param([Parameter(Mandatory=$true)][string] $VolumeString,
          [Parameter(Mandatory=$true)][string] $Directory)
    
    if ($VolumeString -imatch '^\s*Win32_Volume\.DeviceID="([^"]+)"\s*$') {
        # Return it in the wanted format.
        $Matches[1] -replace '\\{2}', '\'
    }
    else {
        # Return a presumably unique hashtable key if there's no match.
        "Unknown device ID for " + $Directory
    }
    
}

# Thanks to Justin Rich (jrich523) for this C# snippet.
# https://jrich523.wordpress.com/2015/02/27/powershell-getting-the-disk-drive-from-a-volume-or-mount-point/
$STGetDiskClass = @"
using System;
using Microsoft.Win32.SafeHandles;
using System.IO;
using System.Runtime.InteropServices;

public class STGetDisk
{
    private const uint IoctlVolumeGetVolumeDiskExtents = 0x560000;

    [StructLayout(LayoutKind.Sequential)]
    public struct DiskExtent
    {
        public int DiskNumber;
        public Int64 StartingOffset;
        public Int64 ExtentLength;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DiskExtents
    {
        public int numberOfExtents;
        public DiskExtent first;
    }

    [DllImport("Kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern SafeFileHandle CreateFile(
    string lpFileName,
    [MarshalAs(UnmanagedType.U4)] FileAccess dwDesiredAccess,
    [MarshalAs(UnmanagedType.U4)] FileShare dwShareMode,
    IntPtr lpSecurityAttributes,
    [MarshalAs(UnmanagedType.U4)] FileMode dwCreationDisposition,
    [MarshalAs(UnmanagedType.U4)] FileAttributes dwFlagsAndAttributes,
    IntPtr hTemplateFile);

    [DllImport("Kernel32.dll", SetLastError = false, CharSet = CharSet.Auto)]
    private static extern bool DeviceIoControl(
    SafeFileHandle hDevice,
    uint IoControlCode,
    [MarshalAs(UnmanagedType.AsAny)] [In] object InBuffer,
    uint nInBufferSize,
    ref DiskExtents OutBuffer,
    int nOutBufferSize,
    ref uint pBytesReturned,
    IntPtr Overlapped
    );

    public static string GetPhysicalDriveString(string path)
    {
        //clean path up
        path = path.TrimEnd('\\');
        if (!path.StartsWith(@"\\.\"))
            path = @"\\.\" + path;

        SafeFileHandle shwnd = CreateFile(path, FileAccess.Read, FileShare.Read | FileShare.Write, IntPtr.Zero, FileMode.Open, 0, IntPtr.Zero);
        if (shwnd.IsInvalid)
        {
            //Marshal.ThrowExceptionForHR(Marshal.GetLastWin32Error());
            Exception e = Marshal.GetExceptionForHR(Marshal.GetLastWin32Error());
        }

        uint bytesReturned = new uint();
        DiskExtents de1 = new DiskExtents();
        bool result = DeviceIoControl(shwnd, IoctlVolumeGetVolumeDiskExtents, IntPtr.Zero, 0, ref de1, Marshal.SizeOf(de1), ref bytesReturned, IntPtr.Zero);
        shwnd.Close();

        if (result)
            return @"\\.\PhysicalDrive" + de1.first.DiskNumber;
        return null;
    }
}
"@
try {
    Add-Type -TypeDefinition $STGetDiskClass -ErrorAction Stop
}
catch {
    if (-not $Error[0].Exception -like '*The type name * already exists*') {
        Write-Warning -Message "Error adding [STGetDisk] class locally."
    }
}

function Get-MountPointData {
    
    [CmdletBinding(
        DefaultParameterSetName='NoPrompt'
    )]
    param(
        [Parameter(Mandatory=$true)][string[]] $ComputerName,
        [Parameter(ParameterSetName='Prompt')][switch] $PromptForCredentials,
        [Parameter(ParameterSetName='NoPrompt')][System.Management.Automation.Credential()] $Credential = [System.Management.Automation.PSCredential]::Empty,
        [switch] $IncludeRootDrives,
        [switch] $NoFormat,
        [switch] $IncludeDiskInfo
    )
    
    foreach ($Computer in $ComputerName) {
        
        $WmiHash = @{
            ComputerName = $Computer
            ErrorAction  = 'Stop'
        }
        #if ($PromptForCredentials -and $Credential.Username) {
        #    Write-Warning "You specified both -PromptForCredentials and -Credential. Prompting overrides."
        #}
        if ($PSCmdlet.ParameterSetName -eq 'Prompt') {
            $WmiHash.Credential = Get-Credential
        }
        elseif ($Credential.Username) {
            $WmiHash.Credential = $Credential
        }
        try {
            # Collect mount point device IDs and populate a hashtable with IDs as keys
            $MountPointData = @{}
            Get-WmiObject @WmiHash -Class Win32_MountPoint | 
                Where-Object {
                    if ($IncludeRootDrives) {
                        $true
                    }
                    else {
                        $_.Directory -NotMatch '^\s*Win32_Directory\.Name="[a-z]:\\{2}"\s*$'
                    }
                } |
                ForEach-Object {
                    $MountPointData.(Get-DeviceIDFromMP -VolumeString $_.Volume -Directory $_.Directory) = $_.Directory
            }
            $Volumes = @(Get-WmiObject @WmiHash -Class Win32_Volume | Where-Object {
                    if ($IncludeRootDrives) { $true } else { -not $_.DriveLetter }
                } | 
                Select-Object Label, Caption, Capacity, FreeSpace, FileSystem, DeviceID, @{n='Computer';e={$Computer}} )
        }
        catch {
            Write-Error "${Computer}: Terminating WMI error (skipping): $_"
            continue
        }
        if (-not $Volumes.Count) {
            Write-Error "${Computer}: No mount points found. Skipping."
            continue
        }
        if ($PSBoundParameters['IncludeDiskInfo']) {
            $DiskDriveWmiInfo = Get-WmiObject @WmiHash -Class Win32_DiskDrive
        }
        $Volumes | ForEach-Object {
            if ($MountPointData.ContainsKey($_.DeviceID)) {
                # Let's avoid dividing by zero, it's so disruptive.
                if ($_.Capacity) {
                    $PercentFree = $_.FreeSpace*100/$_.Capacity
                }
                else {
                    $PercentFree = 0
                }
                $_ | Select-Object -Property DeviceID, Computer, Label, Caption, FileSystem, @{n='Size (GB)';e={$_.Capacity/1GB}},
                    @{n='Free space';e={$_.FreeSpace/1GB}}, @{n='Percent free';e={$PercentFree}}
            }
        } | Sort-Object -Property 'Percent free', @{Descending=$true;e={$_.'Size (GB)'}}, Label, Caption |
            Select-Object -Property $(if ($NoFormat) {
                @{n='ComputerName'; e={$_.Computer}},
                @{n='Label';        e={$_.Label}},
                @{n='Caption';      e={$_.Caption}},
                @{n='FileSystem';   e={$_.FileSystem}},
                @{n='Size (GB)';    e={$_.'Size (GB)'}},
                @{n='Free space';   e={$_.'Free space'}},
                @{n='Percent free'; e={$_.'Percent free'}},
                $(if ($PSBoundParameters['IncludeDiskInfo']) {
                    @{n='Disk Index'; e={
                        try {
                            $ScriptBlock = {
                                param($GetDiskClass, $DriveString)
                                try {
                                    Add-Type -TypeDefinition $GetDiskClass -ErrorAction Stop
                                }
                                catch {
                                    #Write-Error -Message "${Computer}: Error creating class [STGetDisk]"
                                    return "Error creating [STGetDisk] class: $_"
                                }
                                return [STGetDisk]::GetPhysicalDriveString($DriveString)
                            }
                            if ($Credential.Username) {
                                $PhysicalDisk = Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock $ScriptBlock -ArgumentList $STGetDiskClass, $(if ($_.Caption -imatch '\A[a-z]:\\\z') { $_.Caption } else { $_.DeviceID.TrimStart('\?') })
                            }
                            else {
                                $PhysicalDisk = Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock -ArgumentList $STGetDiskClass, $(if ($_.Caption -imatch '\A[a-z]:\\\z') { $_.Caption } else { $_.DeviceID.TrimStart('\?') })
                            }
                            if ($PhysicalDisk -like 'Error*') {
                                "Error: $PhysicalDisk"
                            }
                            else {
                                ($DiskDriveWmiInfo | Where-Object { $PhysicalDisk } | Where-Object { $PhysicalDisk.Trim() -eq $_.Name } | Select-Object -ExpandProperty Index) -join '; '
                            }
                        }
                        catch {
                            "Error: $_"
                        }
                    } # end of disk index expression
                    } # end of if disk index hashtable 
                }) # end of if includediskinfo parameter subexpression and if
            }
            else {
                @{n='ComputerName'; e={$_.Computer}},
                @{n='Label';        e={$_.Label}},
                @{n='Caption';      e={$_.Caption}},
                @{n='FileSystem';   e={$_.FileSystem}},
                @{n='Size (GB)';    e={$_.'Size (GB)'.ToString('N')}},
                @{n='Free space';   e={$_.'Free space'.ToString('N')}},
                @{n='Percent free'; e={$_.'Percent free'.ToString('N')}},
                $(if ($PSBoundParameters['IncludeDiskInfo']) {
                    @{n='Disk Index'; e={
                        try {
                            $ScriptBlock = {
                                param($GetDiskClass, $DriveString)
                                try {
                                    Add-Type -TypeDefinition $GetDiskClass -ErrorAction Stop
                                }
                                catch {
                                    #Write-Error -Message "${Computer}: Error creating class [STGetDisk]"
                                    return "Error creating [STGetDisk] class: $_"
                                }
                                return [STGetDisk]::GetPhysicalDriveString($DriveString)
                            }
                            if ($Credential.Username) {
                                $PhysicalDisk = Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock $ScriptBlock -ArgumentList $STGetDiskClass, $(if ($_.Caption -imatch '\A[a-z]:\\\z') { $_.Caption } else { $_.DeviceID.TrimStart('\?') })
                            }
                            else {
                                $PhysicalDisk = Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock -ArgumentList $STGetDiskClass, $(if ($_.Caption -imatch '\A[a-z]:\\\z') { $_.Caption } else { $_.DeviceID.TrimStart('\?') })
                            }
                            if ($PhysicalDisk -like 'Error*') {
                                "Error: $PhysicalDisk"
                            }
                            else {
                                ($DiskDriveWmiInfo | Where-Object { $PhysicalDisk } | Where-Object { $PhysicalDisk.Trim() -eq $_.Name } | Select-Object -ExpandProperty Index) -join '; '
                            }
                        }
                        catch {
                            "Error: $_"
                        }
                    } # end of disk index expression
                    } # end of if disk index hashtable 
                }) # end of if includediskinfo parameter subexpression and if
            }) # end of if $NoFormat
    }
}
