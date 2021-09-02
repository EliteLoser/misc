[CmdletBinding()]
param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)][Alias('Cn')][string[]] $ComputerName
)

process {
    foreach ($Computer in $ComputerName) {
        Write-Verbose "Processing $Computer"
        $Output = @(.\PsLoggedon.exe -l "\\$Computer" 2> $env:TEMP\psloggedon.tmp)
        if ($Output -imatch 'Error') {
            New-Object PSObject -Property @{
                ComputerName = $Computer
                Date         = $null
                Domain       = $null
                User         = $null
                Error        = ($Output | Where-Object { $_ -match '\S' }) -join ' ; '
            } | Select-Object -Property ComputerName, Date, Domain, User, Error
        }
        $Output | ForEach-Object {
            if ($_ -match '\s+(?<DateTime>(?:.?unknown time.?|\d{1,2}/\d{1,2}/\d{4}\s+\d{1,2}:\d{1,2}:\d{1,2}\s+[ap]m))\s+(?<DomainUser>\S+)') {
                $DomainUser = $Matches.DomainUser
                if ($Matches.DateTime -imatch 'unknown time') {
                    $Date = $null
                }
                else {
                    $Date = $Matches.DateTime
                }
                if ($Date) {
                    $Date = [datetime] $Date
                }
                New-Object PSObject -Property @{
                    ComputerName = $Computer
                    Date         = $Date
                    Domain       = $DomainUser.Split('\')[0]
                    User         = $DomainUser.Split('\')[1]
                    Error        = $null
                }
            }
        } | Select-Object -Property ComputerName, Date, Domain, User, Error
    }
}
