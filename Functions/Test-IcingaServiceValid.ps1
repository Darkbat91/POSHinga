function Test-IcingaServiceValid
{
<#
.Synopsis
   Verifies the Specified Service is in an Icinga configuration for the Specified Host
.DESCRIPTION
   Connects to the Icinga API and attempts to validate the provided ServiceName
.EXAMPLE
    Tests a Valid Service on the Host

   Test-IcingaServiceValid -servername "MyIcingaServer" -token "Valid Auth" -HostName "The host on Icinga" -ServiceName "Service I want to check"

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
#If we want to check the host when we check the service
[switch]$validateHost
)
#Ignore CA Cert
Ignore-SelfSignedCerts

#Create URL's for everything within system
$baseurl = "https://$($serverName):$IcingaPort"
Write-PLDebug $baseurl
$HostVerificationuri = "$baseurl/v1/objects/hosts"
Write-PLDebug $HostVerificationuri
$ServiceVerificationURI = "$baseurl/v1/objects/services"
Write-PLDebug $ServiceVerificationURI
[int]$count = 1

if($validateHost.IsPresent)
    {
    if(!(Test-IcingaHostValid -serverName $serverName -token $token -HostName $HostName))
        {
        Write-PLInfo "Running Service check $ServiceName - Host not valid $HostName"
        return $false
        }
    }

$servicecheckbody = @{filter = "host.name==`"$hostname`""}
$servicecheckjson = $servicecheckbody | ConvertTo-Json

do
{
    try {
    $Validservices = Invoke-RestMethod -Method Post -Headers @{Authorization=("Basic {0}" -f $cred);  'Accept'='application/json'} -Uri $ServiceVerificationURI -ContentType "application/json" -ErrorVariable myerror -Body $servicecheckjson  -ErrorAction Stop
    break}
    catch{}

    if($count -ne 1)
    {
    Write-PLInfo "Attempt $($count-1) failed trying again"
    sleep 1
    }
    $count++
} while ($myweberror[0].Message -like 'The underlying connection was closed: A connection that was expected to be kept alive was closed by the server.')

if($Validservices.results.name -notcontains "$hostname!$ServiceName" -and $Validservices -ne $null)
            {
            #Notify that the Service name is incorrect
            Write-PLInfo -Sublevel 'ERROR' -Message "Unable to find `"$service`" in Icinga2 for `"$hostname`""
            return $false
            }
        else
            {
            Write-PLInfo "Service Name is Valid: $service"
            return $true
            }


}