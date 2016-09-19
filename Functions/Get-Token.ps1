function Get-Token
{
#Returns the Base 64 Authintication token for Icinga
param(
[string]$Username,
[string]$Password)

return [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Username,$Password)))
}
