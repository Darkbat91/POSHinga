function Test-IcingaHostValid
{
<#
.Synopsis
   Verifies the Specified Host is in an Icinga configuration
.DESCRIPTION
   Connects to the Icinga API and attempts to validate the provided HostName
.EXAMPLE
    Tests a Valid Host on the server

   Test-IcingaHostValid -servername "MyIcingaServer" -token "ValidAuth" -HostName "Host Im Checking"

    TRUE
.OUTPUT
    Boolean of Valid Host
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
#Host that we are Verifying is present on the system
[string][Parameter(Mandatory=$true)]$HostName = ""
)
#Ignore CA Cert
Ignore-SelfSignedCerts

#Create URL's for everything within system
$baseurl = "https://$($serverName):$IcingaPort"
Write-PLDebug $baseurl
$HostVerificationuri = "$baseurl/v1/objects/hosts"
Write-PLDebug $HostVerificationuri
[int]$count = 1

do
{
    try {
    $validhosts = Invoke-RestMethod -Method Post -Headers @{Authorization=("Basic {0}" -f $token);  'Accept'='application/json'} -Uri $HostVerificationuri -ContentType "application/json" -ErrorAction Stop -ErrorVariable myweberror
    break}
    catch{}

    if($count -ne 1)
    {
    Write-PLInfo "Attempt $($count-1) failed trying again"
    sleep 1
    }
    $count++
} while ($myweberror[0].Message -like 'The underlying connection was closed: A connection that was expected to be kept alive was closed by the server.')

Write-PLDebug $validhosts.results.name
if($validhosts.results.name -notcontains $hostname -and $validhosts -ne $null)
    {

    #Notify that the host name is incorrect
    Write-PLInfo -Sublevel 'ERROR' -Message "Unable to find $hostname in Icinga2"
    return $false
    }
else
    {
    Write-PLInfo "Host Name is valid: $hostname"
    return $true
    }
}