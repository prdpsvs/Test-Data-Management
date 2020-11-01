using namespace System.Net

param($Request, $TriggerMetadata)

$InstanceId = Start-NewOrchestration -FunctionName 'DurableFunctionsOrchestrator' -InputObject 'Hello'
Write-Host "Started orchestration with ID = '$InstanceId'"

$Response = New-OrchestrationCheckStatusResponse -Request $Request -InstanceId $InstanceId
Push-OutputBinding -Name Response -Value $Response 
