
#ExecuteProc $yr, $section, $fileContent, $type, $json.id
function ExecuteProc ( $year, $section, $type, $id, $fileContent, $debug, $fileCount, $fileName) {

    Write-Host "   ExecuteProc($fileCount) $Tab {YR: $year, SECTION: $section, TYPE: $type, File: $fileName, Debug: $debug}"

    if ($debug -eq $true) {
        return
    }
    else
    {
        $rv = 1

        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $sqlConnection.Open()

        $sqlCommand = new-object System.Data.SqlClient.SqlCommand
        $sqlCommand.CommandTimeout = 120
        $sqlCommand.Connection = $sqlConnection
        $sqlCommand.CommandType=[System.Data.CommandType]'StoredProcedure'
        $sqlCommand.CommandText= 'dbo.usp_Mitre_AddJason'
    
        [void]($sqlCommand.Parameters.Add("@Yr", [System.Data.SqlDbType]::Int).Value = $year)
        [void]($sqlCommand.Parameters.Add("@Section", [System.Data.SqlDbType]::VarChar, 30).Value = $section)
        [void]($sqlCommand.Parameters.Add("@JSON", [System.Data.SqlDbType]::NvarChar, -1).Value = $fileContent)
        [void]($sqlCommand.Parameters.Add("@Type", [System.Data.SqlDbType]::VarChar, 50).Value = $type)

        try{
            $result = $sqlCommand.ExecuteNonQuery()
        }
        catch{
            Write-Host ""
            Write-Host $_.Exception.Message -ForegroundColor DarkYellow
            Write-Host ""
            $rv = -1;
        }
        finally {
            $sqlConnection.Close()
        }

        return $rv
    }
}

function RunBasicAnalysis ($debug)
{ 

    Write-Host "   RunBasicAnalysis() $Tab {Debug: $debug}"

    if ($debug -eq $true) {
        return
    }
    else
    {
        $rv = 1

        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $sqlConnection.Open()

        $sqlCommand = new-object System.Data.SqlClient.SqlCommand
        $sqlCommand.CommandTimeout = 120
        $sqlCommand.Connection = $sqlConnection
        $sqlCommand.CommandType=[System.Data.CommandType]'StoredProcedure'
        $sqlCommand.CommandText= 'dbo.usp_Mitre_RunAnalysis'
    
        [void]($sqlCommand.Parameters.Add("@TopMu", [System.Data.SqlDbType]::Int).Value = 0)

        try{
            $result = $sqlCommand.ExecuteNonQuery()
        }
        catch{
            Write-Host ""
            Write-Host $_.Exception.Message -ForegroundColor DarkYellow
            Write-Host ""
            $rv = -1;
        }
        finally {
            $sqlConnection.Close()
        }

        if ($rv -eq 1)
        {
            Write-Host "   RunBasicAnalysis(): SUCCESSFUL"
        }
    }

}



function CreateDatabaseObjects ($sqlServerName, $dbName, $scriptName, $debug)
{

    $variables = ('dbName={0}' -f $dbName)

    if (1 -eq 1) {        
        Write-Host "   CreateDatabaseObjects() $Tab {ServerName: $sqlServerName, Db: $dbName}"
        Write-Host "   CreateDatabaseObjects() $Tab {Vars: $variables}"
        Write-Host "   CreateDatabaseObjects() $Tab {Script: $scriptName}"
        Write-Host "   CreateDatabaseObjects() $Tab {Debug: $debug}"
    }
    
    if ($debug -eq $true) {
        return
    }
    else
    {

        try{
            invoke-sqlcmd -ServerInstance $sqlServerName -inputFile $scriptName -Variable $variables
        }
        catch{
            Write-Host ""
            Write-Host $_.Exception.Message -ForegroundColor DarkYellow
            Write-Host ""
        }
   }

}


function IterateFolders ($rootFolder, $sectionFilter, $typeFilter, $targetYear, $debug) 
{
    $subdirs      = (Get-ChildItem -Directory -Exclude ".*" -Path $rootFolder | Select-Object)
    $fileCount    = 0
    $Tab          = [char]9
    $rv           = 0

    
    foreach($d in $subdirs)
    {
        $yr= $d.Name 
        $d2s = (Get-ChildItem -Directory -Exclude ".*" -Path $d | Select-Object)

        if ($yr -eq $targetYear -or $targetYear -eq 1)
        {
            Write-Host "IterateFolders() for $Yr :"
            foreach($d2 in $d2s)
            {
                $section = $d2.Name

                if ($sectionFilter -eq $null -or $sectionFilter -eq "" -or $sectionFilter -like $section)
                {

                    $d3s = (Get-ChildItem -Directory -Exclude ".*" -Path $d2 | Select-Object)

                    foreach($d3 in $d3s)
                    {
                        $type = $d3.Name                        
                
                        #if ($debug -eq $true) {Write-Host "IterateFolders(): $section > $type"}

                        if ($typeFilter -eq $null -or $typeFilter -eq "" -or $typeFilter -like $type)
                        {
                            $filePath = $d3.FullName + '\*.json'
                                if ($debug -eq $true) 
                                {
                                    #Write-Host "  PATH: $filePath"
                                    Write-Host ""
                                    Write-Host "IterateFolders() {Year: $yr > Section: $section > Type: $type}"
                                }

                
                            $jsonFiles = Get-ChildItem $filePath
                            $fileCount = 0;

                            foreach($jsonFile in $jsonFiles)
                            {            
                                $fileCount += 1                    
    
                                $fileContent = (Get-Content -Raw $jsonFile)
                                $json        = (Get-Content -Raw $jsonFile | ConvertFrom-Json) 
                                #Write-Host "File name: " $jsonFile.name
                                $rv = 0
                                $rv = ExecuteProc $yr $section $type $json.id $fileContent $debug $fileCount $jsonFile.name

                                if ($rv -ne 1) {
                                   Write-Host '>>>> ERROR: see above <<<<';
                                   return;
                                } 
                            }
                            
                            Write-Host "   IterateFolders($fileCount) {$Yr > $section > $type}"

                        } # typeFilter

                        
                    } 
                } # sectionFilter         
            }
        }
    }
}