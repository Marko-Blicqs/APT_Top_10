<#
   Use this script to create the target database and import all available data into it.

   Before running the script, set the following variables.

     $debug           - Only required for your debugging
     $dbName          - The name of the target database; use a dedicated database
     $sqlServerName   - The name of your MS SQL Server instance
     $importDirectory - The folder in which this script is located
     $dataLocation    - The folder location of your local copy of the MITRE ATT&CK data.
                        
                        The root folder for each year's data uses the year (e.g. 2020). 
                        Each subfolder follows the expected MITRE pattern.

  You may also set the following optional variables.

     $sectionFilter    - A string containing the value of the "section" to filter (e.g. capec, enterprise-attack) or $null for all.
                         The valuse of $sectionFilter is the name of the first-level sub-folder.
     $typeFilter       - A string containing the value of the "section" to filter (e.g. malware) or $null for all. 
                         The value of $typeFilter is the name of the second-level sub-folder.
     $targeYr          - To specify a specific target year for the import

  This script imports the file MitreFunctions.psm1 that contains all the import routines that, in turn, 
   call the import proc usp_Mitre_AddJason
   

#>
Clear-Host

$debug             = $false

$dbName            = 'Mitre_Top10'
$sqlServerName     = 'localhost\SQLEXPRESS'
$importDirectory   = "C:\APT_Project\APT_Top_10\Import"
$dataLocation      = "C:\APT_Project\Mitre Data\Data"

$connectionString  = "Data Source=$sqlServerName;Initial Catalog=$dbName;Integrated Security=SSPI;Application Name=JsonImportExample"

$sectionFilter     = "enterprise-attack"   #"enterprise-attack" # $null -> all, enterprise-attack, capec
$typeFilter        = $null                 #"relationship"      # $null -> all, malware, relationship, intrusion-set
$targeYr           = 1                     #1 -> all years, or {2018,2019,2020,2021}


#Write-Host "importDir: $importDirectory"

Set-Location $importDirectory
$scriptName        = Join-Path $importDirectory '\Create_DB_Objects.sql'


$StartTime = $(get-date)
$st = "{0:dd MMM yyyy @ HH:mm:ss}" -f ([datetime]$StartTime)
Write-Host "Runtime: $st"

Import-Module ".\MitreFunctions.psm1" -Force

CreateDatabaseObjects $sqlServerName $dbName $scriptName $debug

IterateFolders $dataLocation $sectionFilter $typeFilter $targeYr $debug

RunBasicAnalysis $debug

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host ""
Write-Host "Elapsed time:" $totalTime
Write-Host