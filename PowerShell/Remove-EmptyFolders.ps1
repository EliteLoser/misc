function Remove-EmptyFolders {
    <#
    .SYNOPSIS
        Removes empty folders recursively from a root directory.
        The root directory itself is not removed.

        Author: Joakim Borger Svendsen, Svendsen Tech, Copyright 2022.
        MIT License.
        
        Semantic version: v1.0.0        
    .EXAMPLE
        . .\Remove-EmptyFolders.ps1
        Remove-EmptyFolders -Path E:\FileShareFolder
    .EXAMPLE
        Remove-EmptyFolders -Path \\server\share\data
    
    #>
    [CmdletBinding()]
    Param(
        [String] $Path
    )
    Begin {
        [Int32] $Script:Counter = 0
        if (++$Counter -eq 1) {
            $RootPath = $Path
            Write-Verbose -Message "Saved root path as '$RootPath'."
        }
        # Avoid overflow. Overly cautious?
        if ($Counter -eq [Int32]::MaxValue) {
            $Counter = 1
        }
    }
    Process {
        # List directories.
        foreach ($ChildDirectory in Get-ChildItem -LiteralPath $Path -Force |
            Where-Object {$_.PSIsContainer}) {
            # Use .ProviderPath on Windows instead of .FullName in order to support UNC paths (untested).
            # Process each child directory recursively.
            Remove-EmptyFolders -Path $ChildDirectory.FullName
        }
        $CurrentChildren = Get-ChildItem -LiteralPath $Path -Force
        # If it's empty, the condition below evaluates to true. Get-ChildItem 
        # returns $null for empty folders.
        if ($null -eq $CurrentChildren) {
            # Do not delete the root folder itself.
            if ($Path -ne $RootPath) {
                Write-Verbose -Message "Removing empty folder '$Path'."
                Remove-Item -LiteralPath $Path -Force
            }
        }
    }
}

