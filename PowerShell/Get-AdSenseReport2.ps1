[CmdletBinding()]
Param()

$Path = './adsense report2.csv'
$CsvData = @(Import-Csv -LiteralPath $Path)

# Add recent data.
$LastDate = [DateTime]$CsvData[-1].Dato
Write-Verbose "Last date in main report: $LastDate" -Verbose

if (Test-Path -LiteralPath ($Path = './adsense-new.csv')) {
    $CsvData += @(Import-Csv -LiteralPath $Path).Where({[DateTime] $_.Dato -gt $LastDate}) |
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
            -Name "RPM for side (NOK)" -Value ([Decimal]$_."RPM for side (NOK)") -Force
        Add-Member -InputObject $_ -MemberType NoteProperty `
            -Name Visninger -Value ([Int64]$_.Visninger) -Force
        Add-Member -InputObject $_ -MemberType NoteProperty `
            -Name YearAndMonth -Value ([String]$_.Dato.Year + "-" + ("{0:D2}" -f $_.Dato.Month)) -Force
        Add-Member -InputObject $_ -MemberType NoteProperty `
            -Name Income -Value ([Decimal]$_."Anslåtte inntekter (NOK)" -replace ',', '.') -Force -PassThru
    } |
    Sort-Object -Property Dato -Descending


# Monthly
<#
$CsvDataFormatted |
    Group-Object -Property YearAndMonth |
    ForEach-Object {
        "In $($_.Name) the total income was $(
            ($_.Group | Measure-Object -Property Income -Sum).Sum)"
    
    <#    [PSCustomObject] @{
            YearAndMonth = $_.Name
            MonthlyIncome = ($_.Group | Measure-Object -Property Income -Sum).Sum
        } | Format-List#>
            # This is to get all the properties displayed at the end.
            #Select-Object -Property YearAndMonth, MonthlyIncome, Year, YearlyIncome,
                #AverageRPM, AverageAdDisplays
    #}
#>

# Yearly
$CsvDataFormatted |
    Group-Object -Property Year |
    ForEach-Object {
        "In $($_.Name) the total income was $(
            ($_.Group | Measure-Object -Property Income -Sum).Sum)"
    <#[PSCustomObject] @{
            Year = $_.Name
            YearlyIncome = ($_.Group | Measure-Object -Property Income -Sum).Sum
        } | Format-List#>
    }


# Yearly displays and RPM
$CsvDataFormatted |
    Group-Object -Property Year |
    ForEach-Object {
        "In $($_.Name) the average number of page views was $(
            ($_.Group | Measure-Object -Property Visninger -Average).Average)"
        <#[PSCustomObject]@{
            Year = $_.Name
            AverageAdDisplays = ($_.Group | Measure-Object -Property Visninger -Average).Average
        } | Format-List#>
    }

$CsvDataFormatted |
    Group-Object -Property Year |
    ForEach-Object {
        "In $($_.Name) the average income per 1000 views was $(
            ($_.Group | Measure-Object -Property "RPM for side (NOK)" -Average).Average)"
        <#[PSCustomObject]@{
            Year = $_.Name
            AverageRPM = ($_.Group | Measure-Object -Property "RPM for side (NOK)" -Average).Average
        } | Format-List#>
    }

