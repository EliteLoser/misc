[CmdletBinding()]
Param(
        [Switch]
        $WhatIf = $True
    )

# To use and not just test: Pass in -WhatIf:$False

# Get Android files as by default naming convention on my HTC U11+ phone per 2019-04-21. Include "-EFFECTS" in the name
# to support Picasa/Google AI manipulated images. 2019-05-21: Got a Nokia 7.1 with a different naming convention, so I'm
# adding support for names like "{IMG,VID}_<DATE>_<TIME>.{jpe?g,mp4}" as well.
$FilesToMoveAndRename = Get-ChildItem -Path "$Env:UserProfile\OneDrive\Pictures\Camera Roll\*.*" |
    Where-Object { $_.Name -match '^(?:(?:VID|IMG)_\d+_\d*|Screenshot_\d+[\-_]\d+|VIDEO|IMAG)\d{4}(?:-EFFECTS)?\.(?:png|jpe?g|mp4)$' }

foreach ($File in $FilesToMoveAndRename) {
    
    if ($File.Name -like 'Screenshot_[0-9]*') {
        $NewName = $File.Name -replace '^Screenshot_', 'Screenshot_Android_'
    }
    elseif ($File.Name -match '^(?:IMG|VID)_') {
        $NewName = $File.Name -replace '^(IMG|VID)_(\d+)(.+)', '${2}_${1}_Android${3}'
    }
    else {
        $NewName = "$($File.LastWriteTime.ToString('yyyyMMdd\_HHmmss'))_Android-$($File.Name)"
    }

    $Year = $File.LastWriteTime.Year
    $Month = $File.LastWriteTime.Month
    
    # I could have handled the renaming in the Move-Item, but ended up with this for now...
    $File | Rename-Item -NewName { "$Env:UserProfile\OneDrive\Pictures\Camera Roll\$NewName" } -WhatIf:$WhatIf -Verbose
    
    Write-Verbose -Verbose "Sleeping for a few milliseconds to let the file get renamed properly..."
    Start-Sleep -Milliseconds 25
    
    $DestinationPath = "$Env:UserProfile\OneDrive\Pictures\Camera Roll\$Year\$("{0:D2}" -f $Month)"

    # Ensure the destination directory exists by creating it if it's missing.
    if (-not (Test-Path -LiteralPath $DestinationPath -PathType Container)) {
        # Harmless if it exists as well.
        New-Item -Path $DestinationPath -ItemType Directory -Force
    }

    Move-Item -LiteralPath $(if ($WhatIf) {
        $File.FullName
    } else {
        "$Env:UserProfile\OneDrive\Pictures\Camera Roll\$NewName"
    }) -Destination $DestinationPath -WhatIf:$WhatIf -Verbose
    
}

