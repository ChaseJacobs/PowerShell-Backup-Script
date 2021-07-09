########################################################
# Forked from: http://www.techguy.at/tag/backupscript/
# Name: BackupScript.ps1                              
# Creator: Chase Jacobs
# CreationDate: 2020.02.11                              
# LastModified: 2020.02.11                               
# Version: 1
########################################################

#Description: Copies the Bakupdirs to the Destination
#You can configure more than one BackupSourcedir, every Dir
#wil be copied to the Destination. A Progress Bar
#is showing the Status of copied MB to the total MB
#Only Change Variables in Variables Section
#Change LoggingLevel to 3 an get more output in Powershell Windows



param (
[string]$source = "C:\Users\chase\Google Drive\Books",
[string]$destination = "C:\Users\chase\Downloads\Backup"
)

#Variables, only Change here
$Destination=$destination #Copy the Files to this Location
$Versions="5" #How many of the last Backups you want to keep
$BackupSourcedir=$source #What Folders you want to backup

$ErrorActionPreference = "Stop"

#STOP-no changes from here
#Settings - do not change anything from here


#Logging "INFO" "Use orig Backup Dir"
$BackupDestinationdir=$Destination +"\Backup-"+ (Get-Date -format yyyy-MM-dd)+"-"+(Get-Random -Maximum 100000)+"\"


$Items=0
$Count=0
$ErrorCount=0

#FUNCTION
#Logging
Function Logging ($State, $Message) {
    $Datum=Get-Date -format dd.MM.yyyy-HH:mm:ss

    $Text="$Datum - $State"+":"+" $Message"

    if ($LoggingLevel -eq "1" -and $Message -notmatch "was copied") {Write-Host $Text}
    elseif ($LoggingLevel -eq "3") {Write-Host $Text}   
}


#Create BackupDestinationdir
Function Create-BackupDestinationdir {
    New-Item -Path $BackupDestinationdir -ItemType Directory | Out-Null
    sleep -Seconds 5
    Logging "INFO" "Create BackupDestinationdir $BackupDestinationdir"
}

#Check if BackupSourcedir and Destination is available
function Check-Dir {
    Logging "INFO" "Check if BackupSourcedir and Destination exists"
    if (!(Test-Path $BackupSourcedir)) {
        return $false
        Logging "Error" "$BackupSourcedir does not exist"
    }
    if (!(Test-Path $Destination)) {
        return $false
        Logging "Error" "$Destination does not exist"
    }
    if ($UseStaging) {
		if (!(Test-Path $Staging)) {
			return $false
			Logging "Error" "$Staging does not exist"
		}
	}
}

#Save all the Files
Function Make-Backup {
    Logging "INFO" "Started the Backup"	

	robocopy $BackupSourcedir $BackupDestinationdir /mir /R:5 /W:5

	Logging "INFO" "robocopy exit code: $LASTEXITCODE"
	
	if ($LASTEXITCODE -gt 3) {
		Logging "Error" "$Robocopy Error"
		exit 1
	}
	else {
		$LASTEXITCODE = 0
	}
}

#Delete BackupDestinationdir
Function Delete-BackupDestinationdir {
    $Folder=Get-ChildItem $Destination | where {$_.Attributes -eq "Directory"} | Sort-Object -Property CreationTime -Descending:$false | Select-Object -First 1

    Logging "INFO" "Remove Dir: $Folder"
    
    $Folder.FullName | Remove-Item -Recurse -Force 
}

#create Backup Dir
Logging "INFO" "----------------------"
Logging "INFO" "Start the Script"
Create-BackupDestinationdir

#Check if all Dir are existing and do the Backup
$CheckDir=Check-Dir

if ($CheckDir -eq $false) {
    Logging "ERROR" "One of the Directory are not available, Script has stopped"
	exit 1
} else {

	if ($LASTEXITCODE -gt 0) {
		Logging "Error" "$Before backup Error"
		exit 1
	}

    Make-Backup

    $Enddate=Get-Date #-format dd.MM.yyyy-HH:mm:ss
    $span = $EndDate - $StartDate
    $Minutes=$span.Minutes
    $Seconds=$Span.Seconds

    Logging "INFO" "----------------------"
    Logging "INFO" "------Complete--------"
}

#Check if BackupDestinationdir needs to be cleaned
$Count=(Get-ChildItem $Destination | where {$_.Attributes -eq "Directory"}).count
Logging "INFO" "Check if there are more than $Versions Directories in the BackupDestinationdir"

while ($Count -gt ($Versions))
{
	Logging "INFO" "Found $Count Directories in the BackupDestinationdir"
    Delete-BackupDestinationdir
	$Count=(Get-ChildItem $Destination | where {$_.Attributes -eq "Directory"}).count
	Logging "INFO" "Check if there are more than $Versions Directories in the BackupDestinationdir"
}

Write-Host "Done"
$text = "Exit Code: "+$LastExitCode
Write-Host $text
exit 0
