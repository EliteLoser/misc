[CmdletBinding()]
Param()

$Path = './adsense report2.csv'
$CsvData = @(Import-Csv -LiteralPath $Path)

# Add recent data.
$LastDate = [DateTime]($CsvData[-1].Dato)
Write-Verbose "Last date in main report: $LastDate" -Verbose

if (Test-Path -LiteralPath ($Path = './adsense-new.csv')) {
    $CsvData += @(Import-Csv -LiteralPath $Path).Where({([DateTime] $_.Dato) -gt $LastDate}) |
        Sort-Object -Descending
}

$LastDate = [DateTime]($CsvData[-1].Dato)
Write-Verbose "Last date in report after adding potentially new data: $LastDate" -Verbose

# Format the data.
$CsvDataFormatted = $CsvData |
    ForEach-Object {
        Add-Member -InputObject $_ -MemberType NoteProperty -Name Dato -Value ([DateTime]$_.Dato) -Force
        Add-Member -InputObject $_ -MemberType NoteProperty -Name Year -Value $_.Dato.Year -Force
        Add-Member -InputObject $_ -MemberType NoteProperty `
            -Name YearAndMonth -Value ([String]$_.Dato.Year + "-" + ("{0:D2}" -f $_.Dato.Month)) -Force
        Add-Member -InputObject $_ -MemberType NoteProperty `
            -Name Income -Value ([Decimal]$_."Anslåtte inntekter (NOK)" -replace ',', '.') -Force -PassThru
    } |
    Sort-Object -Property Dato -Descending


# Monthly
$CsvDataFormatted |
    Group-Object -Property YearAndMonth |
    ForEach-Object {
        [PSCustomObject] @{
            YearAndMonth = $_.Name
            MonthlyIncome = ($_.Group | Measure-Object -Property Income -Sum).Sum
        } |
            # This is to get all the properties displayed at the end.
            Select-Object -Property YearAndMonth, MonthlyIncome, Year, YearlyIncome
    }

# Yearly
$CsvDataFormatted |
    Group-Object -Property Year |
    ForEach-Object {
        [PSCustomObject] @{
            Year = $_.Name
            YearlyIncome = ($_.Group | Measure-Object -Property Income -Sum).Sum
        } 
    }
