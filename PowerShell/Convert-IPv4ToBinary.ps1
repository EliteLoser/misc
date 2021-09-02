function Convert-IPToBinary {
    param([string] $IP)
    $IP = $IP -replace '\s+' # remove whitespace for fun/flexibility
    try
    {
        return ($IP.Split('.') | ForEach-Object { [System.Convert]::ToString([byte] $_, 2).PadLeft(8, '0') }) -join ''
    }
    catch
    {
        Write-Warning -Message "Error converting '$IP' to a binary string: $_"
        return $null
    }
}
