function Get-IPv4SubnetMask {
    param([Parameter(ValueFromPipeline=$true)][int[]] $NetworkLength)
    process {
        foreach ($Length in $NetworkLength) {
            $MaskBinary = ('1' * $Length).PadRight(32, '0')
            $DottedMaskBinary = $MaskBinary -replace '(.{8}(?!\z))', '${1}.'
            $SubnetMask = ($DottedMaskBinary.Split('.') | foreach { [Convert]::ToInt32($_, 2) }) -join '.'
            $SubnetMask
        }
    }
}

# 1..32 | Get-IPv4SubnetMask
