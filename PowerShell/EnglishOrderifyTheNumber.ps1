#requires -version 2



function Format-WithEnglishNumericalOrderLetters {
    <#
        .SYNOPSIS
            Turn
                Numbers ending with "0" into "0th"
                Numbers ending with "1" into "1st"
                Numbers ending with "2" into "2nd"
                Numbers ending with "3" into "3rd"
                Numbers ending with "4" into "4th"
                Numbers ending with "5" into "5th"
                Numbers ending with "6" into "6th"
                Numbers ending with "7" into "7th"
                Numbers ending with "8" into "8th"
                Numbers ending with "9" into "9th"

                Exceptions from the above are:
                    11-19 - all get appended "th"

            What determines the letter form is the last two digits or the last
            digit if there is only one.

            Only integers are supported.

            This is something we humans need from time to time in IT.
            Now it's handled for PowerShell. Hope I did humankind justice.

        .PARAMETER Number
            Number to append numerical order letters in English to.
        
        .EXAMPLE
            1, 10, 4, 202, 43 | Format-WithEnglishNumericalOrderLetters

            1st
            10th
            4th
            202nd
            43rd

        .EXAMPLE
            PS /home/joakim/Documents> $TestStrings                                                                                                                   
            This is the 1 time it has been done
            This is the 2 time we did it
            This is the 3 word
            This is the 4 way
            PS /home/joakim/Documents> $TestStrings | %{ [Regex]::Replace($_, '(\d+)', { Format-WithEnglishNumericalOrderLetters -Number $args[0].Groups[0].Value }) }

            This is the 1st time it has been done
            This is the 2nd time we did it
            This is the 3rd word
            This is the 4th way

        .EXAMPLE
            0..200 | Format-WithEnglishNumericalOrderLetters

            1st
            2nd
            3rd
            4th
            5th
            6th
            7th
            8th
            9th
            10th
            11th
            12th
            13th
            14th
            15th
            16th
            17th
            18th
            19th
            20th
            21st
            22nd
            23rd
            24th
            25th
            26th
            27th
            28th
            29th
            30th
            31st
            32nd
            33rd
            34th
            35th
            36th
            37th
            38th
            39th
            40th
            41st
            42nd
            43rd
            44th
            45th
            46th
            47th
            48th
            49th
            50th
            51st
            52nd
            53rd
            54th
            55th
            56th
            57th
            58th
            59th
            60th
            61st
            62nd
            63rd
            64th
            65th
            66th
            67th
            68th
            69th
            70th
            71st
            72nd
            73rd
            74th
            75th
            76th
            77th
            78th
            79th
            80th
            81st
            82nd
            83rd
            84th
            85th
            86th
            87th
            88th
            89th
            90th
            91st
            92nd
            93rd
            94th
            95th
            96th
            97th
            98th
            99th
            100th
            101st
            102nd
            103rd
            104th
            105th
            106th
            107th
            108th
            109th
            110th
            111th
            112th
            113th
            114th
            115th
            116th
            117th
            118th
            119th
            120th
            121st
            122nd
            123rd
            124th
            125th
            126th
            127th
            128th
            129th
            130th
            131st
            132nd
            133rd
            134th
            135th
            136th
            137th
            138th
            139th
            140th
            141st
            142nd
            143rd
            144th
            145th
            146th
            147th
            148th
            149th
            150th
            151st
            152nd
            153rd
            154th
            155th
            156th
            157th
            158th
            159th
            160th
            161st
            162nd
            163rd
            164th
            165th
            166th
            167th
            168th
            169th
            170th
            171st
            172nd
            173rd
            174th
            175th
            176th
            177th
            178th
            179th
            180th
            181st
            182nd
            183rd
            184th
            185th
            186th
            187th
            188th
            189th
            190th
            191st
            192nd
            193rd
            194th
            195th
            196th
            197th
            198th
            199th
            200th
    #>

    [CmdletBinding()]
    param(
        
        [Parameter(
            Mandatory = $True,
            ValueFromPipeline = $True,
            HelpMessage='Example: ''1, 24, 42 | Format-WithEnglishNumericalOrderLetters'' gives ''1st 24th 42nd'' on three lines (three objects).'
        )]
        [Int[]]
        $Number
    )
    begin {

    }
    process {
        
        foreach ($Num in $Number) {
            
            $NumberString = [String]$Num
            
            if ($NumberString.Length -gt 1) {
                
                $RelevantDigitsString = -join $NumberString[-2,-1]

            }
            else {

                $RelevantDigitsString = $NumberString[-1]

            }
            switch -Regex ($RelevantDigitsString) {
                
                '\A(?:4|5|6|7|8|9|10|1[1-9]|[2-9]0|[2-9]4|[2-9]5|[2-9]6|[2-9]7|[2-9]8|[2-9]9|00|0[4-9])\z' {$NumberString + 'th'}
                '\A(?:[2-9]?1|01)\z' {$NumberString + 'st'}
                '\A(?:[2-9]?2|02)\z' {$NumberString + 'nd'}
                '\A(?:[2-9]?3|03)\z' {$NumberString + 'rd'}
                
            }
            
        }

    }
    end {

    }

}
