#requires -version 2
[CmdletBinding()]
param()

<#
Originally a port of the below Python code to PowerShell. Apparently this is an algorithm for validating Norwegian SSNs.

Later supplemented with algorithms based on information on wikipedia:
https://no.wikipedia.org/wiki/F%C3%B8dselsnummer

Joakim Borger Svendsen, 2021-September

Dot-source (. \Test-Ssn.ps1; Test-Ssn -Ssn '01234567890') and use the function Test-Ssn
to validate Norwegian social security numbers (personnummer/fødselsnummer).

Test fail number that matches the algorithm for numbers: 20140930135

Will return a custom PowerShell object with an SSN property containing the SSN as a string
and whether it is valid as the property "IsValidSsn", the gender and the type of SSN: D, FH, H or P.

def validate_pid(pnr):    
    list = [int(d) for d in str(pnr)]
    if (list[0]*3+list[1]*7+list[2]*6+list[3]*1+list[4]*8+list[5]*9+list[6]*4+list[7]*5+list[8]*2+list[9]) % 11 == 0 and \
        (list[0]*5+list[1]*4+list[2]*3+list[3]*2+list[4]*7+list[5]*6+list[6]*5+list[7]*4+list[8]*3+list[9]*2+list[10]) % 11 == 0:
        return True


#>

function Test-Ssn {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True, HelpMessage = 'Enter SSN(s) to validate')]
        [String[]]
        $Ssn
    )

    begin {

    }
    process {
        foreach ($SingleSsn in $Ssn) {
        
            # Remove non-digits (all non-digit characters are removed).
            $SingleSsn = $SingleSsn -replace '\D+'

            Write-Verbose "Current SSN for processing: '$SingleSsn'."

            $SsnResult = [PSCustomObject]@{
                SSN = $SingleSsn
                IsValidSsn = ''
                SsnType = ''
                Gender = ''
            }

            if ($SingleSsn -match '^\d{11}$') {

                $Birthday = [Int] $SingleSsn.SubString(0, 2)
                $BirthMonth = [Int] $SingleSsn.SubString(2, 2)
                $BirthYear = [Int] $SingleSsn.SubString(4, 2)
                
                
                if ($Birthday -ge 80) {
                    $SsnResult.SsnType = 'FH'
                    $SsnResult.Gender = 'Unknown'
                }
                elseif ($Birthday -gt 40) {
                    $SsnResult.SsnType = 'D'
                    $Birthday -= 40
                }
                elseif ($BirthMonth -gt 40) {
                    $SsnResult.SsnType = 'H'
                    $BirthMonth -= 40
                }
                else {
                    $SsnResult.SsnType = 'P'
                }
                
                # If the third individual digit is even, the gender is female. If it's uneven, the gender is male.
                # If the number is an "FH" number, this is not valid and the gender is unknown.
                if ($SsnResult.Gender -ne 'Unknown') {
                    if ([Int] $SingleSsn.SubString(8, 1) % 2 -eq 0) {
                        $SsnResult.Gender = 'Female'
                    }
                    else {
                        $SsnResult.Gender = 'Male'
                    }
                }
                
                $Digits = [Int[]][String[]][Char[]] $SingleSsn

                $VerificationNumber1 = ($Digits[0]*3 + $Digits[1]*7 + $Digits[2]*6 + $Digits[3]*1 + $Digits[4]*8 + $Digits[5]*9 + $Digits[6]*4 + $Digits[7]*5 + $Digits[8]*2) % 11

                if ($VerificationNumber1 -ne 0) {
                    $VerificationNumber1 = 11 - $VerificationNumber1
                }
                
                # SSNs where the first verification number (kontrollnummer) is 10 are not valid.
                if ($VerificationNumber1 -eq 10) {
                    $SsnResult.IsValidSsn = $False
                    $SsnResult.Gender = ''
                    $SsnResult.SsnType = ''
                    $SsnResult
                    continue
                }

                $VerificationNumber2 = ($Digits[0]*5 + $Digits[1]*4 + $Digits[2]*3 + $Digits[3]*2 + $Digits[4]*7 + $Digits[5]*6 + $Digits[6]*5 + $Digits[7]*4 + $Digits[8]*3 + $VerificationNumber1*2) % 11

                if ($VerificationNumber2 -ne 0) {
                    $VerificationNumber2 = 11 - $VerificationNumber2
                }

                # SSNs where the second verification number (kontrollnummer) is 10 are not valid.
                if ($VerificationNumber2 -eq 10) {
                    $SsnResult.IsValidSsn = $False
                    $SsnResult.Gender = ''
                    $SsnResult.SsnType = ''
                    $SsnResult
                    continue
                }

                # We know the check numbers cannot be 10 here. 11 has become 0. Two if statements in an attempt to optimize
                # for speed by evaluating only the verification numbers first and if they fail return an object immediately.
                # Was unsure how granular I would make the comparisons, in theory you could have 6 if statements here and it
                # would execute faster than two or one.
                if ($VerificationNumber1 -eq $Digits[9] -and $VerificationNumber2 -eq $Digits[10]) {
                    Write-Verbose "Verification number 1 and 2 match number 10 and 11 in the SSN."
                    if ($Birthday -ge 1 -and $Birthday -le 31 -and $BirthMonth -ge 1 -and $BirthMonth -le 12) {
                        
                        $SsnResult.IsValidSsn = $True
                        $SsnResult
                        continue

                    }
                    else {
                        
                        Write-Verbose "Birth date not in range."
                        $SsnResult.IsValidSsn = $False
                        $SsnResult.Gender = ''
                        $SsnResult.SsnType = ''
                        $SsnResult
                        
                        continue
                    }
                }
                else {

                    Write-Verbose "Verification number 1 and 2 do NOT match number 10 and 11 in the SSN."
                    $SsnResult.IsValidSsn = $False
                    $SsnResult.Gender = ''
                    $SsnResult.SsnType = ''
                    $SsnResult
                        
                    continue

                }
            }
            else {
                
                Write-Verbose "SSN is not 11 digits long."
                $SsnResult.IsValidSsn = $False
                $SsnResult.Gender = ''
                $SsnResult.SsnType = ''
                $SsnResult
                
                continue

            }

        }
    }
    end {

    }

}
