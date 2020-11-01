param([string]$InputData)

$output = @()

try {

  Write-Host "Dacpac scripting started"
  get-childitem -path $env:TEMP -Recurse  -Filter "TDM_*" | remove-item -Recurse -Force
  # Creating a folder for each execution
  $DateTime = Get-Date -Format "yyyyMMddHHmm"
  $ExecutionId = 'TDM_'+ $DateTime

  $ExecutionDirectory = New-Item -Path $env:TEMP -Name $ExecutionId -ItemType "directory"
  Write-Host "Base Directory is $ExecutionDirectory"

  #Connect to target database

  $TARGET_CONNECTIONSTRING = "Server=$env:Target_ServerName;Initial Catalog=$env:Target_DatabaseName;Persist Security Info=False;User ID=$env:Target_UserId;Password=$env:Target_Password;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
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

  #Connect to source database
  $SOURCE_CONNECTIONSTRING = "Server=$env:Source_ServerName;Initial Catalog=$env:Source_DatabaseName;Persist Security Info=False;User ID=$env:Source_UserId;Password=$env:Source_Password;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

  $sqlConnToSourceDB = New-Object System.Data.SqlClient.SqlConnection
  $sqlConnToSourceDB.ConnectionString = $SOURCE_CONNECTIONSTRING
  $sqlcmdToSourceDB = New-Object System.Data.SqlClient.SqlCommand
  $sqlcmdToSourceDB.Connection = $sqlConnToSourceDB
  $sqlcmdToSourceDB.CommandText = $env:DDL_SCHEMA_QUERY
  $sqlConnToSourceDB.Open()
  $adp = New-Object System.Data.SqlClient.SqlDataAdapter $sqlcmdToSourceDB

  # Get all the tables from Source tables from Athena_Dw schema
  $dataset = New-Object System.Data.DataSet
  $adp.Fill($dataset) | Out-Null
  $sqlConnToSourceDB.Close();

  # Loop through each table and add the table name to the SQLPackage Command
  $ExtractTablesList = ""
  foreach ($Row in $dataset.Tables[0])
  { 
    $ExtractTablesList += " /p:TableData=" + $Row.TABLE_NAME
  }

  $ExtractDacpacCommand = $env:DACPAC_EXTRACT_COMMAND
  $DacpacPath = "$ExecutionDirectory\athena_$DateTime.dacpac"

  # #Apply connection properties 
  $ExtractDacpacCommand = $ExtractDacpacCommand.replace("[DBNAME]", $env:Source_DatabaseName)
  $ExtractDacpacCommand = $ExtractDacpacCommand.replace("[ServerName]", $env:Source_ServerName)
  $ExtractDacpacCommand = $ExtractDacpacCommand.replace("[username]", $env:Source_UserId)
  $ExtractDacpacCommand = $ExtractDacpacCommand.replace("[Password]", $env:Source_Password)
  $ExtractDacpacCommand = $ExtractDacpacCommand.replace("[Tables]", $ExtractTablesList)
  $ExtractDacpacCommand = $ExtractDacpacCommand.replace("[FilePath]", $DacpacPath)
  Write-Host "Command to Extract DACPAC -$ExtractDacpacCommand"

  # Generate DACPAC
  Set-Location -Path $env:SQL_PACKAGE_BIN_PATH
  Invoke-Expression  $ExtractDacpacCommand #| Out-Null

  # Deploy DACPAC
  $PublishDacpacCommand = $env:DACPAC_PUBLISH_COMMAND
  $ReportPath = "$ExecutionDirectory\athena_report_$DateTime.xml"

  # #Apply connection properties 
  $PublishDacpacCommand = $PublishDacpacCommand.replace("[DBNAME]", $env:Target_DatabaseName)
  $PublishDacpacCommand = $PublishDacpacCommand.replace("[ServerName]", $env:Target_ServerName)
  $PublishDacpacCommand = $PublishDacpacCommand.replace("[username]", $env:Target_UserId)
  $PublishDacpacCommand = $PublishDacpacCommand.replace("[Password]", $env:Target_Password)
  $PublishDacpacCommand = $PublishDacpacCommand.replace("[FilePath]", $DacpacPath)
  $PublishDacpacCommand = $PublishDacpacCommand.replace("[ReportPath]",$ReportPath)

  Write-Host "Command to publish DACPAC -$PublishDacpacCommand"

  # Generate DACPAC
  Set-Location -Path $env:SQL_PACKAGE_BIN_PATH
  Invoke-Expression  $PublishDacpacCommand #| Out-Null

  $output = 'Success'
}
catch {
  Write-Host $_.ScriptStackTrace
  $output = 'Failed'
}

return $output










