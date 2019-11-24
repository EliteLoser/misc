#requires -version 3



function Show-AppleUpdates {
    [CmdletBinding()]
    Param([System.String] $CacheFile = "$PSScriptRoot\previous-apple-check.txt",
        [System.String] $AppleSupportSecurityFixesUri = "https://support.apple.com/en-us/HT201222")
    Begin {
        
        $ErrorActionPreference = "Stop"
        
    }
    Process {
        
        # I really wonder why I (thought I?) had to do it the way I did it.        
        # Author: Joakim Borger Svendsen. 2019-11-24.

        $WebContent = Invoke-WebRequest -UseBasicParsing -Uri $AppleSupportSecurityFixesUri

        #$WebContent
        $UpdateText = [Regex]::Matches($WebContent.RawContent,
            "(?<Text><ul>\s*^<li>\s*The latest version of .{1,15}?OS\s+is.+?</li>\s*</ul>)",
            @([System.Text.RegularExpressions.RegexOptions]::Multiline, [System.Text.RegularExpressions.RegexOptions]::Singleline)
            )

        $UpdateMatches = [Regex]::Matches($UpdateText, "<li>\s*(?<Name>The latest version of .{1,23}?OS is \S+)(?!>&)\.\s*.+?</li>\s*") | 
            Select-Object -ExpandProperty Groups # ).Groups.Name # why didn't this work?
    
        # This is just sad. :(
        [String[]] $Updates = @(foreach ($MatchObject in $UpdateMatches) {
            if ($MatchObject | Get-Member -Name Groups -ErrorAction SilentlyContinue) {
                continue
            }
            $MatchObject.Value
        })

        # Just a crude caching mechanism and comparison.
        if (Test-Path -LiteralPath $CacheFile) {
            if ((@(Get-Content -LiteralPath $CacheFile) -join "`n").Trim() -ne ($Updates -join "`n").Trim()) {
                Write-Warning "A new update is out for at least one product since the last check on $(
                    (Get-Item -LiteralPath $CacheFile).LastWriteTimeUtc.ToString('yyyy\-MM\-dd HH\:mm\:ss'))!"
            }
        }
        
        $Updates

    }
    End {
        
        # Part of the (simple) caching mechanism.
        $Updates | Set-Content -LiteralPath $CacheFile

    }

}
