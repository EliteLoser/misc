[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | Out-Null

# This function removes text between parentheses
function massageModel {
    
    param([Parameter(Mandatory=$true)][string] $private:model)
    
    $private:model = $private:model -replace '\s*\([^)]+\)\s*$', ''
    $private:model = $private:model -replace '\s+$', ''
    
    return $private:model
    
}

# Create a WSUS object
if (!$wsus) {
    
    $wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer()
    
}

# Create a computer scope object and set the criteria to "All" update installation states
# to target all computers in the WSUS database.
$computerScope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
$computerScope.IncludedInstallationStates = [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::All

# Get all the computer objects
$computers = $wsus.GetComputerTargets($computerScope)

'Found ' + $computers.Count + ' computers'

# Initialize hash
$models = @{}

# Store "massaged" models in a hash (keys are unique)
# and count the number of models.
$computers | Foreach-Object { $model = massageModel $_.Model; $models.$model += 1 }

'Found ' + $models.count + ' unique models'

# Output the data, sorted with the most common models
# first and then alphabetically.
$models.GetEnumerator() |
  Sort-Object -Property @{Expression='Value';Descending=$true},@{Expression='Name';Descending=$false} |
  Format-Table -AutoSize
