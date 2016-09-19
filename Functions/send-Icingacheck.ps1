function Send-Icingacheck 
{
<#
.Synopsis
   Sends a Check result to Icinga to process
.DESCRIPTION
   Connects to the Icinga API and attempts to Process a check result
.EXAMPLE
    Tests a Valid Service on the Host

   Send-Icingacheck -servername "MyIcingaServer" -token "Valid Auth" -HostName "The host on Icinga" -ServiceName "Service I want to check" -State OK -Output "THe check was GOOD!"

    TRUE
.OUTPUT
    Boolean of Valid Service
.NOTES	
    Author: MicahJ
    Creation Date: 20160916
    Last Modified: 20160916
    Version: 1.0.0

-----------------------------------------------------------------------------------------------------------------
CHANGELOG
-----------------------------------------------------------------------------------------------------------------
    1.0 Initial Release

#>
param(
#Server where Icinga is Located
[string][Parameter(Mandatory=$true)]$serverName = "",
#Port that Icinga is listening on - Set to the default of 5665 only need to change if modified
[string][Parameter(Mandatory=$false)]$IcingaPort = "5665",
#Token to Authenticate
[string][Parameter(Mandatory=$true)]$token = "",
#Host that is present on the system
[string][Parameter(Mandatory=$true)]$HostName = "",
#Service we are going to Validate
[string][Parameter(Mandatory=$true)]$ServiceName = "",
#Specific State of the Service
[string][Parameter(Mandatory=$true)]
[validateset("OK", "WARNING", "CRITICAL", "UNKNOWN")]
[string]$state = "",
#Further Explination of state
[string]$output = "",
#Performance Data for graphing if Desired
[string[]]$performance = $null

)
Import-Module PowerLogger
Set-StrictMode -Version 2.0

Start-Logging -LoggingLevel DEBUG

#Create URL's for everything within system
$baseurl = "https://$($serverName):$IcingaPort"
Write-PLDebug $baseurl
$processcheckURI = "$baseurl/v1/actions/process-check-result"
Write-PLDebug $processcheckURI

$result = $null

#Ignore CA Cert
Ignore-SelfSignedCerts

Write-PLInfo -Message "Setting $hostname - $servicename to $state - $output | $performance"

#Get numeric state
switch($state)
{
'OK' {$intstate = 0}
'WARNING' {$intstate = 1}
'CRITICAL' {$intstate = 2}
'UNKNOWN' {$intstate = 3}
}

#Initialize object for JSON
$Body = @{
service = "$hostName!$servicename"
exit_status = $intState
plugin_output = $output
performance_data = $performance
}

Write-PLDebug -Message "Input State was $state providing $intstate"

#Create actual JSON from system
$json = $Body | ConvertTo-Json
Write-PLDebug $json

#Submit the check result
[int]$count = 1
do # Start of do loop for icinga errors
{
try # Attempt to process the check
    {
    $result = Invoke-RestMethod -Method Post -Headers @{Authorization=("Basic {0}" -f $token);  'Accept'='application/json'} -Uri $processcheckURI -ContentType "application/json" -Body $json -ErrorVariable myweberror -ErrorAction Stop
    break
    }
#region Error handling
catch{}
    # if we are here then something went wrong
    
    if($myweberror -ne $null)
    {
    #either server error or bad service name most likely
    if($myweberror[0].Message -like "The remote server returned an error: (404) Not Found.")
        { # 404 Gets returned when the host or Service is not valid
        Write-PLDebug -Message "Server returned an error possibly my fault, checking host and service"    
        #First check host
        if(!(Test-IcingaHostValid -serverName $serverName -token $token -HostName $hostname))
            {
            throw "Host $hostname invalid"
            }
        #then Check Service
        if(!(Test-IcingaServiceValid -serverName $serverName -token $token -HostName $hostname -ServiceName $serviceName))
            {
            throw "Service $serviceName on Host $hostname Invalid"
            }


        #CAnt fiure out the error
        throw "Unable to determine error please check log"

        }
    else # Not sure of error
        {
        Write-PLInfo "Unknown Web Error: $myweberror"
        }
    }
    if($count -ne 1)
    {
    Write-PLInfo "Attempt $($count-1) failed trying again"
    sleep 1
    }
    $count++
} while ($myweberror[0].Message -like 'The underlying connection was closed: A connection that was expected to be kept alive was closed by the server.')
#endregion    

Write-PLDebug -Message "Icinga return: $($result.results.status)"
if($result.results.status -like "Successfully processed check result for object `'$hostName!$serviceName`'.")
    {
        Write-PLInfo -Message "SUCCESS - Check sent"
        return $true
    } 
    else {
        Write-PLInfo -Message "ERROR - Check failed to send - $($result.results.status)"
        return $false
    }
}
