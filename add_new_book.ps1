# Initialize the loop condition
$RunAgain = $true

# Get the directory where the script file is located
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Construct the path to the configuration file relative to the script directory
$ConfigFileName = "config.json"
$ConfigPath = Join-Path -Path $ScriptDirectory -ChildPath $ConfigFileName

# Directory values
$AudiobookDirectory
$EbookDirectory

# Load configuration if available
if (Test-Path -Path $ConfigPath) {
    $Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    if ($Config.AudiobookDirectory) { $AudiobookDirectory = $Config.AudiobookDirectory }
    if ($Config.EbookDirectory) { $EbookDirectory = $Config.EbookDirectory }
}

# Save configuration
function Save-Configuration {
    $Config = @{
        AudiobookDirectory = $AudiobookDirectory
        EbookDirectory = $EbookDirectory
    } | ConvertTo-Json

    $Config | Set-Content -Path $ConfigPath
}

function Confirm-UserChoice {
    param (
        [string]$Prompt
    )
    do {
        $userChoice = Read-Host $Prompt
    } while ($userChoice -notmatch '^[YNyn]$')
    return $userChoice -imatch '[Yy]'
}

do {
    # Prompt the user for input with input validation
    $CreateAudiobook = Confirm-UserChoice "Create an audiobook directory? (Y/N)"
    $CreateEbook = Confirm-UserChoice "Create an ebook directory? (Y/N)"

    # Exit program when the user chooses no for creating either directory
    if (-not ($CreateAudiobook -or $CreateEbook)) {
        exit
    }

    # Prompt the user for Author, Book Title, and Release Year
    $Author = Read-Host "Enter Author"
    $BookTitle = Read-Host "Enter Book Title"
    $ReleaseYear = Read-Host "Enter Release Year"

    # Prompt the user to enter Narrator if creating an audiobook directory
    if ($CreateAudiobook) {
        $Narrator = Read-Host "Enter Narrator"
    }

    # Set directory names based on user choices
    if ($CreateAudiobook) {
        if (-not (Test-Path -Path $ConfigPath) -or -not $AudiobookDirectory) {
            $AudiobookDirectory = Read-Host "Enter the desired directory for audiobooks"
        } else {
            $AudiobookDirectoryCorrect = Confirm-UserChoice "Is this the correct location to store the audiobook in? $AudiobookDirectory (Y/N)"
            if (-not $AudiobookDirectoryCorrect) {
                $AudiobookDirectory = Read-Host "Enter the desired directory for audiobooks"
            }
        }
        $FolderPathAudiobook = Join-Path -Path $AudiobookDirectory -ChildPath "$Author\$BookTitle ($ReleaseYear)\$Narrator"
    }
    
    if ($CreateEbook) {
        if (-not (Test-Path -Path $ConfigPath) -or -not $EbookDirectory) {
            $EbookDirectory = Read-Host "Enter the desired directory for ebooks"
        } else {
            $EbookDirectoryCorrect = Confirm-UserChoice "Is this the correct base location to store the ebook in? $EbookDirectory (Y/N)"
            if (-not $EbookDirectoryCorrect) {
                $EbookDirectory = Read-Host "Enter the desired directory for ebooks"
            }
        }
        $FolderPathEbook = Join-Path -Path $EbookDirectory -ChildPath "$Author\$BookTitle ($ReleaseYear)"
    }

    # Save configuration after both directories have been verified
    Save-Configuration

    # Check if both audiobook and ebook directories are being created in the same location
    if ($CreateAudiobook -and $CreateEbook -and $AudiobookDirectory -eq $EbookDirectory) {
        Write-Host "Both audiobook and ebook directories cannot be created in the same location. Script exiting."
        exit
    }

    if ($CreateAudiobook -and -not (Test-Path -Path $FolderPathAudiobook)) {
        New-Item -Path $FolderPathAudiobook -ItemType Directory -Force | Out-Null
        Write-Host "Audiobook folder structure created."
    }
    
    if ($CreateEbook -and -not (Test-Path -Path $FolderPathEbook)) {
        New-Item -Path $FolderPathEbook -ItemType Directory -Force | Out-Null
        Write-Host "Ebook folder structure created."
    }

    # Prompt the user and ask if they want to add any files to the newly created audiobook directory
    if ($CreateAudiobook) {
        $AddAudiobookFiles = Confirm-UserChoice "Would you like to add any files to the newly created audiobook directory? (Y/N)"
        if ($AddAudiobookFiles) {
            if (-not (Test-Path -Path $FolderPathAudiobook)) { Write-Host "Audiobook directory ($FolderPathAudiobook) not found." }
            do {
                # Ask the user for the destination of the file they want to move
                $FileDestination = Read-Host "Enter the path of the file you want to move"
                if (-not (Test-Path -Path $FileDestination -PathType Leaf)) {
                    Write-Host "Error: The specified file path '$FileDestination' does not exist."
                } else {
                    try {
                        Move-Item -Path $FileDestination -Destination $FolderPathAudiobook -Force
                        Write-Host "File moved successfully."
                    } catch {
                        Write-Host "Error: $_"
                    }
                }
                # Ask if the user wants to add more files
                $AddMoreFiles = Confirm-UserChoice "Do you want to add more files? (Y/N)"
            } while ($AddMoreFiles)
        }
    }

    # Prompt the user and ask if they want to add any files to the newly created ebook directory
    if ($CreateEbook) {
        $AddEbookFiles = Confirm-UserChoice "Would you like to add any files to the newly created ebook directory? (Y/N)"
        if ($AddEbookFiles) {
            if (-not (Test-Path -Path $FolderPathEbook)) { Write-Host "Ebook directory ($FolderPathEbook) not found." }
            do {
                # Ask the user for the destination of the file they want to move
                $FileDestination = Read-Host "Enter the path of the file you want to move"
                if (-not (Test-Path -Path $FileDestination -PathType Leaf)) {
                    Write-Host "Error: The specified file path '$FileDestination' does not exist."
                } else {
                    try {
                        Move-Item -Path $FileDestination -Destination $FolderPathEbook -Force
                        Write-Host "File moved successfully."
                    } catch {
                        Write-Host "Error: $_"
                    }
                }
                # Ask if the user wants to add more files
                $AddMoreFiles = Confirm-UserChoice "Do you want to add more files? (Y/N)"
            } while ($AddMoreFiles)
        }
    }

    # Ask the user if they want to run the script again
    $RunAgain = Confirm-UserChoice "Do you want to run this script again? (Y/N)"

} while ($RunAgain)