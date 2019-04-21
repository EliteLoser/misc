[CmdletBinding()]
Param(
        [Switch]
        $WhatIf = $True
    )

$FilesToMoveAndRename = Get-ChildItem -Path "$Env:UserProfile\OneDrive\Pictures\Camera Roll\IMAG????.jpg"

foreach ($File in $FilesToMoveAndRename) {
    $NewName = "$($File.LastWriteTime.ToString('yyyyMMdd'))_Android-$($File.Name)"
    $Year = $File.LastWriteTime.Year
    $Month = $File.LastWriteTime.Month
    $File | Rename-Item -NewName { "$Env:UserProfile\OneDrive\Pictures\Camera Roll\$NewName" } -WhatIf:$WhatIf -Verbose
    Write-Verbose -Verbose "Sleeping for a few milliseconds to let the file get renamed properly..."
    Start-Sleep -Milliseconds 25
    Move-Item -LiteralPath $(if ($WhatIf) {
        $File.FullName
    } else {
        "$Env:UserProfile\OneDrive\Pictures\Camera Roll\$NewName"
    }) -Destination "$Env:UserProfile\OneDrive\Pictures\Camera Roll\$Year\$("{0:D2}" -f $Month)" -WhatIf:$WhatIf -Verbose
}

