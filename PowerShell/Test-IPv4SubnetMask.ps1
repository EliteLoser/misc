function Test-IPv4SubnetMask {
    [CmdletBinding()]
    param(
        [string] $SubnetMaskBinary,
        [string] $SubnetMaskDottedDecimal)
    if ($SubnetMaskBinary) {
        if ($SubnetmaskBinary -match '01') {
            Write-Verbose -Message "Invalid binary IPv4 subnet mask: '$SubnetMaskBinary'. Matched pattern '01'."
            $false
        } elseif ($SubnetMaskBinary.Length -ne 32) {
            Write-Verbose -Message "Invalid binary IPv4 subnet mask: '$SubnetMaskBinary'. Length was different from 32."
            $false
        } elseif ($SubnetMaskBinary -match '[^01]') {
            Write-Verbose -Message "Invalid binary IPv4 subnet mask: '$SubnetMaskBinary'. Was not all ones and zeroes."
            $false
        } else {
            $true
        }
    }
    if ($SubnetMaskDottedDecimal) {
        function Convert-IPToBinary {
            param([string] $IP)
            $IP = $IP -replace '\s+' # remove whitespace for fun
            try {
                return ($IP.Split('.') | ForEach-Object { [System.Convert]::ToString([byte] $_, 2).PadLeft(8, '0') }) -join ''
            }
            catch {
                Write-Warning -Message "Error converting '$IP' to a binary string: $_"
                return $Null
            }
        }
        $Binary = Convert-IPToBinary -IP $SubnetMaskDottedDecimal
        if ($Binary) {
            Test-IPv4SubnetMask -SubnetMaskBinary $Binary
        } else {
            $false
        }
    }
}
