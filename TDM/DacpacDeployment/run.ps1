param([string]$SqlPackageFilters)

$output = @()

try {

  Write-Host $env:TEMP
  # get-childitem -path $env:TEMP -Recurse  -Filter "TDM_*" | remove-item -Recurse -Force
  # Creating a folder for each execution
  $DateTime = Get-Date -Format "yyyyMMddHHmm"
  $ExecutionDirectory = $env:TEMP
  Write-Host "Base Directory is $ExecutionDirectory"

  #Connect to target database

  $TARGET_CONNECTIONSTRING = "Server=$env:TargetServerName;Initial Catalog=$env:TargetDatabaseName;Persist Security Info=False;User ID=$env:TargetUserId;Password=$env:TargetPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  $sqlConnToTargetDB = New-Object System.Data.SqlClient.SqlConnection
  $sqlConnToTargetDB.ConnectionString = $TARGET_CONNECTIONSTRING
  $sqlcmdToTargetDB = New-Object System.Data.SqlClient.SqlCommand
  $sqlcmdToTargetDB.Connection = $sqlConnToTargetDB
  $sqlcmdToTargetDB.CommandText = $env:CREATE_SCHEMA_QUERY
  $sqlConnToTargetDB.Open()
  #create schema ATHENA_DW
  if ($sqlcmdToTargetDB.ExecuteNonQuery() -ne -1) {
      Write-Host "Failed to Create ATHENA_DW schema on target database";
  }
  else {
      Write-Host "Created ATHENA_DW schema in " $sqlConnToTargetDB.Database " database"
  }
  $sqlConnToTargetDB.Close();

  # https://github.com/NowinskiK/DeploymentContributorFilterer
  # Generate DACPAC
  $ExtractDacpacCommand = $env:DACPAC_EXTRACT_COMMAND
  $DacpacPath = "$ExecutionDirectory\athena_$DateTime.dacpac"

  # Apply connection properties 
  $ExtractDacpacCommand = $ExtractDacpacCommand.replace("[DBNAME]", $env:SourceDatabaseName)
  $ExtractDacpacCommand = $ExtractDacpacCommand.replace("[ServerName]", $env:SourceServerName)
  $ExtractDacpacCommand = $ExtractDacpacCommand.replace("[username]", $env:SourceUserId)
  $ExtractDacpacCommand = $ExtractDacpacCommand.replace("[Password]", $env:SourcePassword)
  $ExtractDacpacCommand = $ExtractDacpacCommand.replace("[FilePath]", $DacpacPath)
  Write-Host "Command to Extract DACPAC -$ExtractDacpacCommand"
  #Write-Host "$env:SQL_PACKAGE_BIN_PATH$ExtractDacpacCommand"
  $extract = Invoke-Expression   "$env:SQL_PACKAGE_BIN_PATH$ExtractDacpacCommand" | Out-String 
  Write-Host $extract
  # Deploy DACPAC
  $PublishDacpacCommand = $env:DACPAC_PUBLISH_COMMAND
  $ReportPath = "$ExecutionDirectory\athena_report_$DateTime.xml"

  # Apply connection properties 
  $PublishDacpacCommand = $PublishDacpacCommand.replace("[DBNAME]", $env:TargetDatabaseName)
  $PublishDacpacCommand = $PublishDacpacCommand.replace("[ServerName]", $env:TargetServerName)
  $PublishDacpacCommand = $PublishDacpacCommand.replace("[username]", $env:TargetUserId)
  $PublishDacpacCommand = $PublishDacpacCommand.replace("[Password]", $env:TargetPassword)
  $PublishDacpacCommand = $PublishDacpacCommand.replace("[FilePath]", $DacpacPath)
  $PublishDacpacCommand = $PublishDacpacCommand.replace("[ReportPath]",$ReportPath)
  $PublishDacpacCommand = $PublishDacpacCommand.replace("[SqlPackageFilters]",$SqlPackageFilters)

  Write-Host "Command to publish DACPAC -$PublishDacpacCommand"
  #Write-Host "$env:SQL_PACKAGE_BIN_PATH$PublishDacpacCommand"
  $publish = Invoke-Expression  "$env:SQL_PACKAGE_BIN_PATH$PublishDacpacCommand" | Out-String 
  Write-Host $publish
  $output = 'Success'
}
catch {
  Write-Host $_.ScriptStackTrace
  $output = 'Failed'
}

return $output










