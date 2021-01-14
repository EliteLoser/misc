PS /> function testfunc {param([Parameter(ValueFromPipeline)][object[]] $InputObject) Process {Write-Output "InputObject is: $($InputObject -join ',')" }}

PS /> @(@(1,2),@(3,4)) | testfunc                                                                                                                         
InputObject is: 1,2
InputObject is: 3,4
PS /> @(1,2),@(3,4) | testfunc   

InputObject is: 1,2
InputObject is: 3,4
