param($Context)

$SqlPackageFilters = $Context.Input
$output = Invoke-ActivityFunction -FunctionName 'DacpacDeployment' -Input $SqlPackageFilters
$output




