function Sort-STNumerical {
    <#
        .SYNOPSIS
            Sort a collection of strings containing numbers, or a mix of this and 
            numerical data types - in a human-friendly way.

            This will sort "anything" you throw at it correctly.

            Author: Joakim Borger Svendsen, Copyright 2019-present, Svendsen Tech.

            MIT License

        .PARAMETER InputObject
            Collection to sort.
        
        .PARAMETER MaximumDigitCount
            Maximum numbers of digits to account for in a row, in order for them to be sorted
            correctly. Default: 100. This is the .NET framework maximum as of 2019-05-09.
            For IPv4 addresses "3" is sufficient, but "overdoing" does no or little harm. It might
            eat some more resources, which can matter on really huge files/data sets.

        .PARAMETER Descending
            Optional switch to sort in descending order rather than the default ascending order.

        .EXAMPLE
            $Strings | Sort-STNumerical

            Sort strings containing numbers in a way that magically makes them sorted human-friendly
            
        .EXAMPLE
            $Result = Sort-STNumerical -InputObject $Numbers
            $Result

            Sort numbers in a human-friendly way.

        .EXAMPLE
            @("1.1.0", "1.1.11", "1.1.2") | Sort-STNumerical -Descending

            1.1.11
            1.1.2
            1.1.0
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True)]
        [System.Object[]]
        $InputObject,
        
        [ValidateRange(2, 100)]
        [Byte]
        $MaximumDigitCount = 100,

        [Switch]$Descending
    )
    
    Begin {
        [System.Object[]] $InnerInputObject = @()
        
        [Bool] $SortDescending = $False
        if ($Descending) {
            $SortDescending = $True
        }
    }
    
    Process {
        $InnerInputObject += $InputObject
    }

    End {
        $InnerInputObject |
            Sort-Object -Property `
                @{ Expression = {
                    [Regex]::Replace($_, '(\d+)', {
                        "{0:D$MaximumDigitCount}" -f [Int64] $Args[0].Value })
                    }
                },
                @{ Expression = { $_ } } -Descending:$SortDescending
    }
}
