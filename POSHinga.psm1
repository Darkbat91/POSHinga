
#Get Module Root
$moduleRoot = Split-path -Path $MyInvocation.MyCommand.Path
#Import Functions
"$moduleRoot\Functions\*.ps1" | Resolve-Path | ForEach-Object{ . $_.path}