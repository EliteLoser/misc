#requires -version 2
[CmdletBinding()]
Param()

<#
Port of this Python code to PowerShell. Apparently this is an algorithm for validating Norwegian SSNs.

Joakim Borger Svendsen, 2021-August

Dot-source (. \Test-SSN.ps1; Test-SSN -SSN '01234567890') and use the function Test-SSN
to validate Norwegian social security numbers (personnummer/fødselsnummer).

Will return a custom PowerShell object with an SSN property containing the SSN as a string
and whether it is valid as the property "IsValidSsn".

def validate_pid(pnr):    
    list = [int(d) for d in str(pnr)]
    if (list[0]*3+list[1]*7+list[2]*6+list[3]*1+list[4]*8+list[5]*9+list[6]*4+list[7]*5+list[8]*2+list[9]) % 11 == 0 and \
        (list[0]*5+list[1]*4+list[2]*3+list[3]*2+list[4]*7+list[5]*6+list[6]*5+list[7]*4+list[8]*3+list[9]*2+list[10]) % 11 == 0:
        return True
#>

function Test-SSN {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, HelpMessage='Enter SSN(s) to validate')]
        [String[]]
        $SSN
    )

    Begin {

    }
    Process {
        foreach ($SingleSSN in $SSN) {
        
            # Remove non-digits (all non-digit characters are removed).
            $SingleSSN = $SingleSSN -replace '\D+'

            Write-Verbose "Current SSN for processing: '$SingleSSN'."
            if ($SingleSSN -match '^\d{11}$') {
        
                $List = [Int[]][String[]][Char[]] $SingleSSN
                if (($List[0]*3+$List[1]*7+$List[2]*6+$List[3]*1+$List[4]*8+$List[5]*9+$List[6]*4+$List[7]*5+$List[8]*2+$List[9]) % 11 -eq 0 -and `
                    ($List[0]*5+$List[1]*4+$List[2]*3+$List[3]*2+$List[4]*7+$List[5]*6+$List[6]*5+$List[7]*4+$List[8]*3+$List[9]*2+$List[10]) % 11 -eq 0) {
                    [PSCustomObject]@{
                        SSN = $SingleSSN
                        IsValidSsn = $True
                    }
                }
                else {
                    [PSCustomObject]@{
                        SSN = $SingleSSN
                        IsValidSsn = $False
                    }
                }
            }
            else {
                [PSCustomObject]@{
                    SSN = $SingleSSN
                    IsValidSsn = $False
                }
            }

        }
    }
    End {

    }

}
