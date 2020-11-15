using namespace System.Net

param($Request, $TriggerMetadata)

$OrchestratorInput = $Request.Body.SqlPackageFilters
$InstanceId = Start-NewOrchestration -FunctionName 'DurableFunctionsOrchestrator' -InputObject $OrchestratorInput
Write-Host "Started orchestration with ID = '$InstanceId'"

$Response = New-OrchestrationCheckStatusResponse -Request $Request -InstanceId $InstanceId
Push-OutputBinding -Name Response -Value $Response 
