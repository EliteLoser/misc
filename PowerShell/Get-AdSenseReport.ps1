$CsvDataFormatted = Import-Csv -Path './adsense report.csv' |
    ForEach-Object { Add-Member -InputObject $_ -MemberType NoteProperty -Name Dato -Value ([DateTime]$_.Dato) -Force -PassThru } |
    Sort-Object -Property Dato -Descending

$Data = @{}

$CsvDataFormatted |
    ForEach-Object { if (++$Counter -eq 1) { $LastMonth = "{0:D2}" -f $_.Dato.Month }
        if ($LastMonth -eq $_.Dato.Month) { $Data.([String]$_.Dato.Year + "-" + $LastMonth) += [Decimal]($_."Anslåtte inntekter (NOK)" -replace ',', '.') }
        else {
            $LastMonth = "{0:D2}" -f $_.Dato.Month
            $Data.([String]$_.Dato.Year + "-" + $LastMonth) += [Decimal]($_."Anslåtte inntekter (NOK)" -replace ',', '.')
        }
    }

$Data.GetEnumerator() | Sort-Object -Property Name | Format-Table -AutoSize

