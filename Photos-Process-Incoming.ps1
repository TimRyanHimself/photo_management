<#

SHORTCUT
--------
"C:\Program Files\PowerShell\7\pwsh.exe" -NoExit -File C:\Stuff\Repos\photo_management\Photos-Process-Incoming.ps1

NOTES
-----
Close Windows Media Player before running it
Script to process JPG, MP4 and AVI only

WORKING
-------
Moves files to new folder based on year and month taken
If file already exists then check if same (so delete) or different (move with rename)
Video files. Copied to year/month folder under Photos. So they are kept with the photos.

TO WORK OUT
-----------
What about WhatsApp and other media on phone not in camera? Maybe ignore unless copied to special folder.
Would be nice to have all photos and videos renamed with consistent naming

#>

Param([switch]$PauseBeforeExit)


Function funDeleteFile($FileFullName) {
    #'Checking for file: ' + $FileFullName
    If (Test-Path -LiteralPath $FileFullName) {
        Try {
            Remove-Item -LiteralPath $FileFullName -Force -ErrorAction Stop
            '      Deleted file: ' + $FileFullName
        }
        Catch {
            $objError = $_
            Write-Warning "Error deleting file $($FileFullName)"
            Write-Warning ($objError.Exception.Message)
        }
    }

}

function Convert-DateString ([String]$Date, [String[]]$Format) {
    $result = New-Object DateTime

    $convertible = [DateTime]::TryParseExact(
        $Date,
        $Format,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::None,
        [ref]$result)

    if ($convertible) { $result }
}


Function funProcessFolder($inpFolder) {
    $myFolder = Get-Item -LiteralPath $inpFolder
    "Folder Object FullName: " + $myFolder.FullName
    funDeleteFile($myFolder.FullName + "\Thumbs.db")
    # funDeleteFile($MyTopFolder.FullName + "\Desktop.ini")   # In Windows Media Player, when click 'Organise' -> 'Apply Media Information Changes' it puts back all the desktop.ini files. So I decided to leave them for now

    # Report files
    $objShell = New-Object -ComObject Shell.Application 
    $objFolder = $objShell.namespace($myFolder.FullName)

    $PhotoCountForthisFolder = 0

    foreach ($strFileName in $objFolder.Items() | Where-Object { $_.Name -Like "*.jpg" -or $_.Name -Like "*.mp4" -or $_.Name -Like "*.avi" } | Sort-Object -Property Name) { 

        $PhotoCountForthisFolder++
        
        <#
        # This code is just for finding the extended attribute reference number for a particular tag
        $a = 0
        for ($a; $a -le 266; $a++)
        {
            $strFileName.Name + "`t" + $a.ToString() + "`t" + $objFolder.getDetailsOf($objFolder.items, $a) + "`t" + "`t" + "`t" + "`t" + $objFolder.getDetailsOf($strFileName, $a).ToString().Trim()
                
        }
        exit
        #>

        # Read the extended attributes    
        [String]$strTags = $objFolder.getDetailsOf($strFileName, 18)
        [String]$strDateTaken = $objFolder.getDetailsOf($strFileName, 12).ToString().Trim()
        $dateTaken = ($strDateTaken -replace [char]8206) -replace [char]8207  #http://stackoverflow.com/questions/25474023/file-date-metadata-not-displaying-properly
        if ($null -eq ($dateTaken -as [DateTime])) {
            # No date taken property. Try to extract year and month from the file name
            if ($strFileName.Name.ToLower().EndsWith(".mp4") -and $strFileName.Name.ToLower().StartsWith("vid_20")) { # Videos from some Android phones/tablets using file names vid_20*
                [String]$strYear = $strFileName.Name.SubString(4, 4)
                [String]$strMonth = $strFileName.Name.SubString(8, 2)
            }
            elseif ($strFileName.Name.ToLower().EndsWith(".mp4") -and $strFileName.Name.ToLower().StartsWith("vid-20")) { # Videos from some Android phones/tablets using file names vid-20*
                [String]$strYear = $strFileName.Name.SubString(4, 4)
                [String]$strMonth = $strFileName.Name.SubString(8, 2)
            }
            elseif ($strFileName.Name.ToLower().EndsWith(".mp4") -and $strFileName.Name.ToLower().StartsWith("20")) { # Videos from some Android phones/tablets using file name 20*
                [String]$strYear = $strFileName.Name.SubString(0, 4)
                [String]$strMonth = $strFileName.Name.SubString(4, 2)
            }
            elseif ($strFileName.Name.ToLower().EndsWith(".jpg") -and $strFileName.Name.ToLower().StartsWith("20")) { # Photos from some Android phones/tablets using file name 20*
                [String]$strYear = $strFileName.Name.SubString(0, 4)
                [String]$strMonth = $strFileName.Name.SubString(4, 2)
            }
            elseif ($strFileName.Name.ToLower().EndsWith(".jpg") -and $strFileName.Name.ToLower().StartsWith("img_20")) { # Photos from some Android phones/tablets using file name img_20*
                [String]$strYear = $strFileName.Name.SubString(4, 4)
                [String]$strMonth = $strFileName.Name.SubString(8, 2)
            }
            elseif ($strFileName.Name.ToLower().EndsWith(".jpg") -and $strFileName.Name.ToLower().StartsWith("img-20")) { # Photos from some Android phones/tablets using file name img-20*
                [String]$strYear = $strFileName.Name.SubString(4, 4)
                [String]$strMonth = $strFileName.Name.SubString(8, 2)
            }
            elseif ($strFileName.Name.ToLower().EndsWith(".avi") -and $strFileName.Name.ToLower().StartsWith("100")) { # Videos from KidiZoom
                $dateTakenFromLastWriteTime = (Get-ChildItem ($myFolder.FullName + "\" + $strFileName.Name)).LastWriteTime
                [String]$strYear = $dateTakenFromLastWriteTime.ToString("yyyy")
                [String]$strMonth = $dateTakenFromLastWriteTime.ToString("MM")

            }
            elseif ($strFileName.Name.ToLower().EndsWith(".avi") -and $strFileName.Name.ToLower().StartsWith("mvi")) { # Videos from Canon IXUS
                $dateTakenFromLastWriteTime = (Get-ChildItem ($myFolder.FullName + "\" + $strFileName.Name)).LastWriteTime
                [String]$strYear = $dateTakenFromLastWriteTime.ToString("yyyy")
                [String]$strMonth = $dateTakenFromLastWriteTime.ToString("MM")    
            }
            else {
                # Failed to work out year and month
                [String]$strYear = ""
                [String]$strMonth = ""
            }
        }
        else {
            $parseDate = [datetime]::ParseExact($dateTaken, "g", $null)
            [String]$strYear = $parseDate.ToString("yyyy")
            [String]$strMonth = $parseDate.ToString("MM")
        }        

        # Output file details
        " .. File Name = " + $strFileName.Name 
        " .. Folder full name = " + $myFolder.FullName
        #" .. Folder name = " + $myFolder.Name
        " .. Date taken = " + $strDateTaken
        " .. Year = " + $strYear
        " .. Month = " + $strMonth 
        " .. Tags = " + $strTags
        

        <#
        # Create year folder if not already present
        $strYearFolder = $strPhotoFolderNew + "\\" + $strYear
        if (-Not (Test-Path $strYearFolder))
        {
            "Creating year folder " + $strYearFolder
            New-Item -Path $strPhotoFolderNew -Name $strYear -type Directory | Out-Null
        }
     

        # Create month folder if not already present
        [String]$strMonthFolder = $strYearFolder + "\\" + $strMonth
        if (-Not (Test-Path $strMonthFolder))
        {
            "Creating month folder " + $strMonthFolder
            New-Item -Path $strYearFolder -Name $strMonth -type Directory | Out-Null
        }
        #>
       

        # Process the file
        if (($strYear.Length -eq 4) -and ($strMonth.Length -eq 2)) {
            # Create year-month folder if not already present
            [String]$strYearMonthFolder = $strPhotoFolderNew + "\\" + $strYear + "-" + $strMonth      
            if (-Not (Test-Path $strYearMonthFolder)) {
                "Creating year-month folder " + $strYearMonthFolder
                New-Item -Path $strPhotoFolderNew -Name ($strYear + "-" + $strMonth) -type Directory | Out-Null
            }

            # Check if file already exists in destination
            if (Test-Path ($strYearMonthFolder + "\\" + $strFileName.Name)) {
                # File already exists in destination, check is same or different
                if ((Get-Item ($strYearMonthFolder + "\\" + $strFileName.Name)).Length -eq $strFileName.Size) {
                    "Deleting file (because same size and name as file in destination) " + $strFileName.Path
                    Remove-Item $strFileName.Path
                }
                else {
                    "Moving and renaming file (because same name file with different size on destination) " + $strFileName.Path
                    Move-Item -Path $strFileName.Path -Destination ($strYearMonthFolder + "\\" + $strFileName.Name + ".DELETE_IF_SAME.jpg")
                }
            }
            else {
                # File does not exist in destination. So just move the file.
                "Moving file " + $strFileName.Path
                Move-Item $strFileName.Path $strYearMonthFolder
            }
        }
        else {
            "Year and month taken could not be read" + $strFileName.Path
        }

    }
    "Folder Photo Count was " + $PhotoCountForthisFolder.ToString()
}

[String]$strPhotoFolder = "\\WYSE1\Family\Photos\Incoming"
[String]$strPhotoFolderNew = "\\WYSE1\Family\Photos\"

"Starting"

Get-Date -Format "yyyy-MM-dd--HH-mm-ss"

funProcessFolder($strPhotoFolder)
            
# Cycle through the folders
foreach ($myFolder in (Get-ChildItem -LiteralPath $strPhotoFolder -Directory | Sort-Object name)) {
    funProcessFolder($myFolder.FullName)
}
    
"All done"
if ($PauseBeforeExit) { Read-Host "Press ENTER to finish" }
exit


