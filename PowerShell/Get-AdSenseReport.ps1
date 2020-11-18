

$CsvDataFormatted = Import-Csv -Path './adsense report.csv' |
    ForEach-Object {
        Add-Member -InputObject $_ -MemberType NoteProperty -Name Dato -Value ([DateTime]$_.Dato) -Force
        Add-Member -InputObject $_ -MemberType NoteProperty -Name Year -Value $_.Dato.Year
        Add-Member -InputObject $_ -MemberType NoteProperty -Name YearAndMonth -Value ([String]$_.Dato.Year + "-" + ("{0:D2}" -f $_.Dato.Month))
        Add-Member -InputObject $_ -MemberType NoteProperty -Name Income -Value ([Decimal]$_."Anslåtte inntekter (NOK)" -replace ',', '.') -PassThru
    } |
    Sort-Object -Property Dato -Descending

#$Data = @{}

# Monthly

$CsvDataFormatted |
    Group-Object -Property YearAndMonth |
    ForEach-Object {
        [PSCustomObject] @{
            YearAndMonth = $_.Name
            MonthlyIncome = ($_.Group | Measure-Object -Property Income -Sum).Sum
        } | Select-Object -Property YearAndMonth, MonthlyIncome, Year, YearlyIncome
    }

<#
$CsvDataFormatted |
    ForEach-Object { 
        if (++$Counter -eq 1) { 
            $LastMonth = "{0:D2}" -f $_.Dato.Month
        }
        if ($LastMonth -eq $_.Dato.Month) {
            $Data.([String]$_.Dato.Year + "-" + $LastMonth) += $_.Income
        }
        else {
            $LastMonth = "{0:D2}" -f $_.Dato.Month
            $Data.([String]$_.Dato.Year + "-" + $LastMonth) += $_.Income
        }
    }

$Data.GetEnumerator() | Sort-Object -Property Name | Format-Table -AutoSize

$Data = @{}
#>
# Yearly

$CsvDataFormatted |
    Group-Object -Property Year |
    ForEach-Object {
        [PSCustomObject] @{
            Year = $_.Name
            YearlyIncome = ($_.Group | Measure-Object -Property Income -Sum).Sum
        } 
    }
    
