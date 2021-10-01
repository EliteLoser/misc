$Servers | Sort-Object @{ Expression = { $_ -replace '^[^.]+\.' } },
    @{ Expression = { [regex]::Replace($_.Split('.')[0], '(\d+)', { '{0:D16}' -f [int] $args[0].Value }) } },
    @{ Expression = { $_ } }
    
# This will sort correctly with numbers in strings (when not zero-padded), by domain first, then host name.
# All in a single pipeline for delicious consumption.
