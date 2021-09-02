function Split-CollectionWithParameterSupport {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)] $Collection,
        [Parameter(Mandatory=$true)][ValidateRange(1, 247483647)][int] $Count)
    begin {
        $Ctr = 0
        $Array = @()
        $TempArray = @()
    }
    process {
        foreach ($e in $Collection) {
            if (++$Ctr -eq $Count) {
                $Ctr = 0
                $Array += , @($TempArray + $e)
                $TempArray = @()
                continue
            }
            $TempArray += $e
        }
    }
    end {
        if ($TempArray) { $Array += , $TempArray }
        $Array
    }
}


function Split-Collection {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)] $Collection,
        [Parameter(Mandatory=$true)][ValidateRange(1, 247483647)][int] $Count)
    begin {
        $Ctr = 0
        $Arrays = @()
        $TempArray = @()
    }
    process {
        if (++$Ctr -eq $Count) {
            $Ctr = 0
            $Arrays += , @($TempArray + $_)
            $TempArray = @()
            return
        }
        $TempArray += $_
    }
    end {
        if ($TempArray) { $Arrays += , $TempArray }
        $Arrays
    }
}
