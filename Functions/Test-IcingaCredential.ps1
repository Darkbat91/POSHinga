function Test-IcingaCredential
{
<#
.Synopsis
   Verifies the credential is working on the icinga server
.DESCRIPTION
   Connects to the Icinga API and attempts to validate the provided credentials
.EXAMPLE
    Tests a Valid ID and Credential

   Test-IcingaCredential -servername "MyIcingaServer" -token "WhatIProvidedForAuthorization"

    TRUE
.OUTPUT
    Boolean of Valid credential
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
#Token that we are checking works
[string][Parameter(Mandatory=$true)]$token = "",
#Do not try and ping the icinga server first - Useful if the server is behind a firewall or something
[switch][Parameter(Mandatory=$false)]$noPingCheck
)
#Ignore CA Cert
Ignore-SelfSignedCerts

$baseurl = "https://$($serverName):$IcingaPort"
Write-PLDebug $baseurl

if(-not(Test-Connection -ComputerName $serverName -Quiet -Count 1) -and $noPingCheck.IsPresent -eq $false)
{
Write-PLInfo 'Failing due to no connection on root server'
return $false
}

[int]$count = 1
do
{
    try {
    $result = Invoke-RestMethod -Method Get -Headers @{Authorization=("Basic {0}" -f $token)} -Uri "$baseurl/v1" -ContentType "application/json" -ErrorAction SilentlyContinue -ErrorVariable myweberror
    break}
    catch{}

    if($count -ne 1)
    {
    Write-PLInfo "Attempt $($count-1) failed trying again"
    sleep 1
    }
    $count++
} while ($myweberror[0].Message -like 'The underlying connection was closed: A connection that was expected to be kept alive was closed by the server.')
    if($result.html.h1 -eq 'Hello from Icinga 2!')
        {
        Write-PLInfo "Verified Server Credentials"
        return $true
        }
    else
        {
        Write-PLInfo "Failed to connect verify Server Name and Token"
        return $false
        }

}