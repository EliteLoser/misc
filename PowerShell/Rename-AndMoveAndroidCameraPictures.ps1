[CmdletBinding()]
Param(
        [Switch]
        $WhatIf = $True
    )

# To use and not just test: Pass in -WhatIf:$False

# Get Android files as by default naming convention on my phone per 2019-04-21. Easter Sunday. Include "-EFFECTS" in the name.
$FilesToMoveAndRename = Get-ChildItem -Path "$Env:UserProfile\OneDrive\Pictures\Camera Roll\IMAG*.jpe?g$" |
    Where-Object { $_.Name -match '^IMAG\d{4}(?:-EFFECTS)?\.jpg' }

foreach ($File in $FilesToMoveAndRename) {
    
    $NewName = "$($File.LastWriteTime.ToString('yyyyMMdd\-HHmmss'))_Android-$($File.Name)"

    $Year = $File.LastWriteTime.Year
    $Month = $File.LastWriteTime.Month
    
    # I could have handled the renaming in the Move-Item, but ended up with this for now...
    $File | Rename-Item -NewName { "$Env:UserProfile\OneDrive\Pictures\Camera Roll\$NewName" } -WhatIf:$WhatIf -Verbose
    
    Write-Verbose -Verbose "Sleeping for a few milliseconds to let the file get renamed properly..."
    Start-Sleep -Milliseconds 25
    
    # Ensure the destination directory exists by creating it if it's missing.
    if (-not (Test-Path -LiteralPath "$Env:UserProfile\OneDrive\Pictures\Camera Roll\$Year\$("{0:D2}" -f $Month)" -PathType Container)) {
        # Harmless if it exists as well.
        New-Item -Path "$Env:UserProfile\OneDrive\Pictures\Camera Roll\$Year\$("{0:D2}" -f $Month)" -ItemType Directory -Force
    }

    Move-Item -LiteralPath $(if ($WhatIf) {
        $File.FullName
    } else {
        "$Env:UserProfile\OneDrive\Pictures\Camera Roll\$NewName"
    }) -Destination "$Env:UserProfile\OneDrive\Pictures\Camera Roll\$Year\$("{0:D2}" -f $Month)" -WhatIf:$WhatIf -Verbose
    
}

