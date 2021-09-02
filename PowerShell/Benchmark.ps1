function Measure-These {
    <#
    .SYNOPSIS
        Svendsen Tech's Benchmarking Module for PowerShell.

        Benchmark PowerShell script blocks and (virtually) any "DOS"/cmd.exe command
        using this module built around PowerShell's Measure-Command cmdlet. It is designed
        to give a quick, convenient overview of how code performs when doing for instance
        the same thing in different ways.

        See the comprehensive online documentation at:
        http://www.powershelladmin.com/wiki/PowerShell_benchmarking_module_built_around_Measure-Command

        MIT license.

    .DESCRIPTION
        This is a benchmarking module for PowerShell. Get objects containing data about
        the execution time of script blocks. Pipe to Format-Table -AutoSize
        for a direct report. You can also assign the resulting objects to a variable (do not
        use Format-Table if assigning to a variable).

        See the comprehensive online documentation at:
        http://www.powershelladmin.com/wiki/PowerShell_benchmarking_module_built_around_Measure-Command

        Copyright (c) 2012-2017, Joakim Borger Svendsen.
        All rights reserved.
        Author: Joakim Borger Svendsen

        MIT license.

    .PARAMETER Count
        Number of times to execute the code in each specified script block. Pass in
        multiple counts separated by commas.
    .PARAMETER ScriptBlock
        Script block(s) to time the execution time of and collect data about.
    .PARAMETER Title
        Optional titles for each script block. Title 1 goes with block 1,
        2 with 2, and so on. If you omit titles, you will get numbered
        script blocks (from left to right). If you have fewer titles than
        script blocks, you will get numbers when you "run out of titles".
    .PARAMETER Precision
        Specify number of digits after the decimal separator. Default 5. Maximum 15.
        Trailing zeroes are removed by the [Math]::Round() static function.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [Int32[]] $Count,
        [Parameter(Mandatory = $true)] [ScriptBlock[]] $ScriptBlock,
        [String[]] $Title = @(''),
        [ValidateRange(1, 15)][Byte] $Precision = 5)
    begin {
    }
    process {
        $Times = @()
        $BlockNumber = 0
        foreach ($LoopCount in $Count) {
            $ScriptBlock | ForEach-Object {
                $Block = $_
                $BlockNumber++
                $Times += 1..$LoopCount | ForEach-Object {
                    Measure-Command -Expression $Block | # Process the current block once for each specified $Count.
                        Select-Object -ExpandProperty TotalMilliSeconds # Get only the milliseconds.
                    } | # End of 1..$Count ForEach-Object which will be passed to Measure-Object.
                    Measure-Object -Sum -Maximum -Minimum | # Gather results using Measure-Object.
                    ForEach-Object {
                        # Send results down the pipeline in the form of custom PS objects.
                        New-Object -TypeName PSObject -Property @{
                            'Average (ms)' = $_.Sum / $_.Count
                            'Maximum (ms)' = $_.Maximum
                            'Minimum (ms)' = $_.Minimum
                            'Count' = $_.Count
                            'Sum (ms)' = $_.Sum
                            'BlockNumber' = $BlockNumber
                        }
                    }
            } # End of $ScriptBlock ForEach-Object
        } # End of $Count foreach loop
    }
    end {
        # Since this is a _benchmarking_ module, it seems in the right spirit to
        # cache this for a performance gain. :)
        $NumBlocks = $ScriptBlock.Count
        # This is used to keep track of the relative position in the block count.
        # Had to script scope it or else I think it behaved sort of like a closure
        # inside the Select-Object below.
        $Script:Counter = 0
        $Times |
            Select-Object @{n='Title/no.'; e={
                    ++$script:Counter
                    $Index = $script:Counter - 1
                    if ($script:Counter -ge $NumBlocks) {
                        $script:Counter = 0
                    }
                    if ($Title[$Index]) {
                        $Title[$Index]
                    }
                    else {
                        $_.BlockNumber
                    }
                   }},
                   @{ Name = 'Average (ms)'; Expression = { [Math]::Round($_.'Average (ms)', $Precision)} }, Count,
                   @{ Name = 'Sum (ms)'; Expression = { [Math]::Round($_.'Sum (ms)', $Precision) } },
                   @{ Name = 'Maximum (ms)'; Expression = { [Math]::Round($_.'Maximum (ms)', $Precision) } },
                   @{ Name = 'Minimum (ms)'; Expression = { [Math]::Round($_.'Minimum (ms)', $Precision) } }
        
    }
}
