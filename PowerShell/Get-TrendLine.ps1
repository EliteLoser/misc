function Get-TrendLine {
    <#
    .SYNOPSIS   
        Calculate the linear trend line from a series of numbers
    .DESCRIPTION
        Assume you have an array of numbers
    
        $inarr = @(15, 16, 12, 11, 14, 8, 10)
    
        and the trendline is represented as
    
        y = a + bx
    
        where y is the element in the array
            x is the index of y in the array
            a is the intercept of trendline at y axis
            b is the slope of the trendline
        Calling the function with
    
        PS> Get-Trendline -Data $inarr
    
        will return a custom PowerShell object of a,  b,
        and the sum of the last data set member and the
        slope value (b), meaning the "next predicted value".
    
    .PARAMETER Data
        A one-dimensional array containing the series of numbers.
    .EXAMPLE  
        Get-Trendline -Data @(15, 16, 12, 11, 14, 8, 10)
    #>
    Param ([System.Object[]] $Data)
    
    [Decimal] $n = $Data.Count
    [Decimal] $SumX = 0
    [Decimal] $SumX2 = 0
    [Decimal] $SumXY = 0
    [Decimal] $SumY = 0
    
    foreach ($i in 1..$n) { #$i=1; $i -le $n; $i++) 
    
        $SumX += $i
        $SumX2 += [Math]::Pow($i, 2)
        $SumXY += $i * $Data[$i - 1]
        $SumY += $Data[$i-1]
    
    }
    
    $b = ($SumXY - $SumX * $SumY / $n) / ($SumX2 - $SumX * $SumX / $n)
    $a = $SumY / $n - $b * ($SumX / $n)
    
    [PSCustomObject]@{
        InterceptWithYAxis = $a
        Slope = $b
        LastSetMemberPlusSlope = $Data[-1] + $b
    }

}
