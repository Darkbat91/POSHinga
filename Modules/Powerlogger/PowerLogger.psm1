<#
.SYNOPSIS
	Logging Utility
.DESCRIPTION
	Creates Logs to be used within other scripts
.NOTES	
    Author: Micah
    Creation Date: 20150112
    Last Modified: 20160511
    Version: 1.8.2

-----------------------------------------------------------------------------------------------------------------
CHANGELOG
-----------------------------------------------------------------------------------------------------------------
    1.0 Initial Release
	1.1 Addition of terminal logging with seperate log level
    1.2 Added Ability to Remove previous log if exists
    1.4 Added Ability to set color of text outputting to console besides the Default
    1.5 Added Master override of colloring for terminal Output
    1.6 Added Sub Sections to script to allow grouping of messages
    1.7 Added CSV Formatting of the Log
        1.7.1 Added ForceCSV to Indivdual Logging Commands
    1.8 Added Email functionlity send-PLLog as well as -emailline logic to include specific line items in email.
        1.8.2 Added ability to remote send Log as well as Added Internal send-pllogging function

-----------------------------------------------------------------------------------------------------------------
TODO
-----------------------------------------------------------------------------------------------------------------
1. Add functionality to only email last log from start
	#>

function Verify-CSVHeaders
{
param(
[string][Parameter(Mandatory=$true)]$Fullpath,
[boolean][Parameter(Mandatory=$false)]$Overwrote
)
    if($Overwrote -or !(Test-Path $Fullpath))
        {
        Add-Content -path $Fullpath -Value "Time,LogLevel,SubLevel,Message "
        }
}



function Start-Logging()
{
[CmdletBinding()]
param(
	[Parameter(Mandatory=$false)]$ScriptName=$null,
    [Parameter(Mandatory=$false)]$LogPath=$null,
    [validateset("INFO", "DEBUG", "Verbose", "None")]
    [Parameter(Mandatory=$false)]$LoggingLevel="INFO",
    [Parameter(Mandatory=$false)]$ScriptVersion,
    [boolean][Parameter(Mandatory=$false)]$OutputTerminal,
    [validateset("INFO", "DEBUG", "Verbose", "None")]
    [Parameter(Mandatory=$false)]$TerminalLevel="None",
    [switch][Parameter(Mandatory=$false)]$OverWriteLog,
    [validateset("Black","Blue","Cyan","DarkBlue","DarkCyan","DarkGray","DarkGreen","DarkMagenta","DarkRed","DarkYellow","Gray","Green","Magenta","Red","White","Yellow")]
    [Parameter(Mandatory=$false)]$OverRideInfoColor="White",
    [validateset("Black","Blue","Cyan","DarkBlue","DarkCyan","DarkGray","DarkGreen","DarkMagenta","DarkRed","DarkYellow","Gray","Green","Magenta","Red","White","Yellow")]
    [Parameter(Mandatory=$false)]$OverRideVerboseColor="Cyan",
    [validateset("Black","Blue","Cyan","DarkBlue","DarkCyan","DarkGray","DarkGreen","DarkMagenta","DarkRed","DarkYellow","Gray","Green","Magenta","Red","White","Yellow")]
    [Parameter(Mandatory=$false)]$OverRideDEBUGColor="Red",
    [Parameter(Mandatory=$false)][Switch]$WriteCSV
    )

Process{



if ($ScriptName -eq $null) # If script name was not set pull from Script
{
try{
$ScriptNameOrigin = $MyInvocation.ScriptName
$Scriptname = Split-Path $ScriptNameOrigin -Leaf

$ScriptName = $ScriptName.Substring(0,$ScriptName.IndexOf("."))
}
catch{
$ScriptName = Get-Date -Format "yyyymmddhhmm"
$ScriptNameOrigin = $env:TEMP
Write-Host "Unable to find script path... Logging at $ScriptNameOrigin" -ForegroundColor Red
sleep -Seconds 2
}

}

if ($LogPath -eq $null -and $ScriptNameOrigin -eq $env:TEMP)
{
$LogPath = $ScriptNameOrigin
}
else
{
$LogPath = split-path $ScriptNameOrigin -Parent
}


# If requested to write csv make extension CSV
if ($WriteCSV.IsPresent)
    {
    $SCRIPT:Fullpath = $LogPath + "\" + $ScriptName + ".csv"
    }
else
    {
    $SCRIPT:Fullpath = $LogPath + "\" + $ScriptName + ".log"
    }

$Overwrote = $false
$Script:Emailbody = @()
$SCRIPT:ScriptName = $ScriptName
$SCRIPT:LoggingLevel = $LoggingLevel
$SCRIPT:TerminalLogging = $OutputTerminal
$SCRIPT:TerminalLevel = $TerminalLevel
$SCRIPT:InfoColor = $OverRideInfoColor
$SCRIPT:VerboseColor = $OverRideVerboseColor
$SCRIPT:DebugColor = $OverRideDEBUGColor
$SCRIPT:WriteCSV = $WriteCSV.IsPresent

if ($OverWriteLog.IsPresent -and (Test-Path $LogPath))
    {
    Remove-Item $Fullpath
    $Overwrote = $true
    }





IF ($SCRIPT:LoggingLevel -ne "None"){
    # Change format of Header if Write CSV is present
    if ($WriteCSV.IsPresent)
        {
        Verify-CSVHeaders -Fullpath $Fullpath -Overwrote $Overwrote
        Add-Content -Path $Fullpath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),INFO,LOGSTART,`"Started $LoggingLevel for $ScriptName`""
        If ($ScriptVersion -ne $null){Add-Content -Path $Fullpath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),INFO,LOGSTART,`"Script Version: $ScriptVersion`""}
        if ($Overwrote -eq $true){Add-Content -Path $Fullpath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),INFO,LOGSTART,`"Log file has been overwritten`""}
        }
    else
        {
        #Show Logging start time
        Add-content -path $Fullpath -value "____________________________________________________________________________________________________________________"
        Add-Content -Path $Fullpath -Value "Started $LoggingLevel Logging for $ScriptName at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        If ($ScriptVersion -ne $null){Add-Content -Path $Fullpath -Value "Script Version: $ScriptVersion"}
        if ($Overwrote -eq $true){Add-Content -Path $Fullpath -Value "Log file has been overwritten"}
        Add-content -path $Fullpath -value "____________________________________________________________________________________________________________________"
        }
}
if ($SCRIPT:TerminalLogging -and $SCRIPT:TerminalLevel -ne "None")
    {
    Write-Host "Started $LoggingLevel Logging for $ScriptName at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
    If ($ScriptVersion -ne $null){Write-Host -Path $Fullpath -Value "Script Version: $ScriptVersion" -ForegroundColor Green}
    Write-Host "____________________________________________________________________________________________________________________" -ForegroundColor Green
    }
}
}

export-modulemember -function Start-Logging



function Write-PLInfo()
{
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]$Message,
    [Parameter(Mandatory=$false)]$LogFile=$SCRIPT:Fullpath,
    [Parameter(Mandatory=$false)]$Sublevel = $null,
    [Parameter(Mandatory=$false)][switch]$ForceTerminal,
    [validateset("Black","Blue","Cyan","DarkBlue","DarkCyan","DarkGray","DarkGreen","DarkMagenta","DarkRed","DarkYellow","Gray","Green","Magenta","Red","White","Yellow")]
    [Parameter(Mandatory=$false)]$ForegroundColor = $SCRIPT:InfoColor,
    [Parameter(Mandatory=$false)][switch]$ForceCSV,
    [Parameter(Mandatory=$false)][switch]$emailLine
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $originalMessage = $Message
    if ($Sublevel -ne $null)
        {
        $Message = "[$Sublevel]`t`t$Message"
        }
    $output = "$timestamp`t`[INFO]:`t`t$message"

if (($SCRIPT:LoggingLevel -eq "INFO" -or $SCRIPT:LoggingLevel -eq "Debug" -or $SCRIPT:LoggingLevel -eq "Verbose") -and !($SCRIPT:writecsv -or $ForceCSV.IsPresent))
    {
    if($emailLine.IsPresent)
        {
        $script:emailbody += "$output <br>"
        }
    Add-Content -Path $LogFile -Value $output
    }
if (($SCRIPT:TerminalLogging -and $SCRIPT:TerminalLevel -ne "None") -or $ForceTerminal.IsPresent)
    {
    Write-Host $output -ForegroundColor $ForegroundColor
    }
if(($SCRIPT:LoggingLevel -eq "INFO" -or $SCRIPT:LoggingLevel -eq "Debug" -or $SCRIPT:LoggingLevel -eq "Verbose") -and ($SCRIPT:writecsv -or $ForceCSV.IsPresent))
    {
    if($emailLine.IsPresent)
        {
        $script:emailbody += "$output <br>"
        }
    if ($LogFile -like "*.log")
        {
        $LogFile = $LogFile.Replace('.log','.csv')
        }
    Verify-CSVHeaders -Fullpath $LogFile 
    # "Time,LogLevel,SubLevel,Message "
    Add-Content -Path $LogFile -Value "$timestamp,INFO,`"$Sublevel`",`"$originalMessage`""
    }
}

export-modulemember -function Write-PLInfo

function Write-PLDebug()
{
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]$Message,
    [Parameter(Mandatory=$false)]$LogFile=$SCRIPT:Fullpath,
    [Parameter(Mandatory=$false)]$Sublevel = $null,
    [Parameter(Mandatory=$false)][switch]$ForceTerminal,
    [validateset("Black","Blue","Cyan","DarkBlue","DarkCyan","DarkGray","DarkGreen","DarkMagenta","DarkRed","DarkYellow","Gray","Green","Magenta","Red","White","Yellow")]
    [Parameter(Mandatory=$false)]$ForegroundColor = $SCRIPT:DEBUGColor,
    [Parameter(Mandatory=$false)][switch]$ForceCSV,
    [Parameter(Mandatory=$false)][switch]$emailLine
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $originalMessage = $Message
    if ($Sublevel -ne $null)
        {
        $Message = "[$Sublevel]`t`t$Message"
        }
    $output = "$timestamp`t`[DEBUG]:`t$message"
if ($SCRIPT:LoggingLevel -eq "Debug"  -and !($SCRIPT:writecsv -or $ForceCSV.IsPresent))
    {
    if($emailLine.IsPresent)
        {
        $script:emailbody += "$output <br>"
        }
    Add-Content -Path $LogFile -Value $output
    }
if (($SCRIPT:TerminalLogging -and $SCRIPT:TerminalLevel -eq "debug") -or $ForceTerminal.IsPresent)
    {
    Write-Host $output -ForegroundColor $ForegroundColor
    }
if ($SCRIPT:LoggingLevel -eq "Debug"  -and ($SCRIPT:writecsv  -or $ForceCSV.IsPresent))
    {
    if($emailLine.IsPresent)
        {
        $script:emailbody += "$output <br>"
        }
    if ($LogFile -like "*.log")
        {
        $LogFile = $LogFile.Replace('.log','.csv')
        }
    Verify-CSVHeaders -Fullpath $LogFile 
    # "Time,LogLevel,SubLevel,Message "
    Add-Content -Path $LogFile -Value "$timestamp,DEBUG,`"$Sublevel`",`"$originalMessage`""
    }
}

export-modulemember -function Write-PLDebug

function Write-PLVerbose()
{
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]$Message,
    [Parameter(Mandatory=$false)]$LogFile=$SCRIPT:Fullpath,
    [Parameter(Mandatory=$false)]$Sublevel = $null,
    [Parameter(Mandatory=$false)][switch]$ForceTerminal,
    [validateset("Black","Blue","Cyan","DarkBlue","DarkCyan","DarkGray","DarkGreen","DarkMagenta","DarkRed","DarkYellow","Gray","Green","Magenta","Red","White","Yellow")]
    [Parameter(Mandatory=$false)]$ForegroundColor = $SCRIPT:VerboseColor,
    [Parameter(Mandatory=$false)][switch]$ForceCSV,
    [Parameter(Mandatory=$false)][switch]$emailLine
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $originalMessage = $Message
    if ($Sublevel -ne $null)
        {
        $Message = "[$Sublevel]`t`t$Message"
        }
    $output = "$timestamp`t`[Verbose]:`t$message"
if ($SCRIPT:LoggingLevel -eq "Debug" -or $SCRIPT:LoggingLevel -eq "Verbose" -and !($SCRIPT:writecsv -or $ForceCSV.IsPresent))
    {
    if($emailLine.IsPresent)
        {
        $script:emailbody += "$output <br>" 
        }
    Add-Content -Path $LogFile -Value $output
    }
if (($SCRIPT:TerminalLogging -and ($SCRIPT:TerminalLevel -eq "Debug" -or $SCRIPT:TerminalLevel -eq "Verbose")) -or $ForceTerminal.IsPresent)
    {
    Write-Host $output -ForegroundColor $ForegroundColor
    }
if (($SCRIPT:LoggingLevel -eq "Debug" -or $SCRIPT:LoggingLevel -eq "Verbose")  -and ($SCRIPT:writecsv -or $ForceCSV.IsPresent))
    {
    if($emailLine.IsPresent)
        {
        $script:emailbody += "$output <br>" 
        }
    if ($LogFile -like "*.log")
        {
        $LogFile = $LogFile.Replace('.log','.csv')
        }
    Verify-CSVHeaders -Fullpath $LogFile 
    # "Time,LogLevel,SubLevel,Message "
    Add-Content -Path $LogFile -Value "$timestamp,VERBOSE,`"$Sublevel`",`"$originalMessage`""
    }
}

export-modulemember -function Write-PLVerbose

Function Send-PLLog()
{
    param($From = "PowerLogger<mog.helpdesk@jacobs.com>",
          $To = "Micah.Joiner@Jacobs.com",
          $Subject = "Log File",
          $HTMLMessage = "$null",
          $SMTPServer = "",
          [switch]$dontincludeLog,
          [switch]$Onlyoncondition,
          $condition = 'ERROR',
          $remoteSender = $null)

    if($dontincludeLog.IsPresent) # Dont include the log if we were asked not to
        {
        $logcontents = $null
        }
    else
        {
        $logcontents = Get-Content -Path $SCRIPT:Fullpath
        }

    

    if($script:emailbody[0] -ne $null)
        {
        $HTMLMessage += $script:emailbody
        }
    elseif($Onlyoncondition.IsPresent -and ([string]($logcontents)  -notlike "*$condition*"))
        {
        return
        }

    if ($remoteSender -eq $null)
    {
        Send-pllogging -From $From -To $To -Subject $Subject -HTMLMessage $HTMLMessage -SMTPServer $SMTPServer -LogContents $logcontents -scriptName $SCRIPT:ScriptName
    }
    else
    {
        if(Test-Connection -ComputerName $remoteSender -Quiet -Count 1)
            {
            Invoke-Command -ComputerName $remoteSender -ScriptBlock ${Function:send-pllogging} -ArgumentList $from, $to, $Subject, $HTMLMessage, $SMTPServer, $logcontents, $SCRIPT:ScriptName
            }
    }
    
}

export-modulemember -function send-PLLog

Function Send-pllogging
{
    param($From,
          $To,
          $Subject,
          $HTMLMessage,
          $SMTPServer,
          $LogContents,
          $ScriptName)


              
    # Initialize email
    $MailMessage = New-Object System.Net.Mail.MailMessage
    $SMTPClient = New-Object System.Net.Mail.SMTPClient
    
    
    #Start building message
    $MailMessage.To.Add("$To")
    $MailMessage.From = "$From"
    $MailMessage.Subject = "$Subject"
    $MailMessage.Body = $HTMLMessage
    $MailMessage.IsBodyHTML = $true

    $FileName = "C:\Windows\Temp\$ScriptName.log"
    Add-Content -Value $LogContents -Path $FileName

    #Only add atachment if available
    If($LogContents -ne $null)
    {
        $Attachment = New-Object System.Net.Mail.Attachment($FileName)
        $MailMessage.Attachments.Add($Attachment)
    }

    # Section to send email by pickup directory
    #$SMTPClient.PickupDirectoryLocation = $PickupDirectory
    #$SMTPClient.DeliveryMethod = "SpecifiedPickupDirectory"

    $SMTPClient.Host = $SMTPServer
    $SMTPClient.Send($MailMessage)


    Remove-Item -Path $FileName -Force

}