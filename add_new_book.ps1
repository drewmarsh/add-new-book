# Initialize the loop condition
$RunAgain = $true

# Get the directory where the script file is located
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Construct the path to the configuration file relative to the script directory
$ConfigFileName = "config.json"
$ConfigPath = Join-Path -Path $ScriptDirectory -ChildPath $ConfigFileName

# Set default directory values
$AudiobookDirectory = "C:\Audiobooks"
$EbookDirectory = "C:\Ebooks"

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

function Validate-Input {
    param (
        [string]$Prompt
    )
    do {
        $input = Read-Host $Prompt
    } while ($input -notmatch '^[YNyn]$')
    return $input -imatch '[Yy]'
}

do {
    # Prompt the user for input with input validation
    $CreateAudiobook = Validate-Input "Create an audiobook directory? (Y/N)"
    $CreateEbook = Validate-Input "Create an ebook directory? (Y/N)"

    if (-not ($CreateAudiobook -or $CreateEbook)) {
        Write-Host "No directory selected. Script exiting."
        exit
    }

    # Prompt the user for Author, Book Title, and Release Year
    $Author = Read-Host "Enter Author"
    $BookTitle = Read-Host "Enter Book Title"
    $ReleaseYear = Read-Host "Enter Release Year"

    # Set directory names based on user choices
    if ($CreateAudiobook) {
        # Ask user to enter a Narrator only if an audiobook directory is being created
        $Narrator = Read-Host "Enter Narrator"
    }

    # Verify audiobook directory
    if ($CreateAudiobook) {
        $AudiobookDirectoryCorrect = Validate-Input "Is this the correct location to store the audiobook in? $AudiobookDirectory (Y/N)"
        if (-not $AudiobookDirectoryCorrect) {
            $AudiobookDirectory = Read-Host "Enter the desired directory for audiobooks"
        }
        $FolderPathAudiobook = Join-Path -Path $AudiobookDirectory -ChildPath "$Author\$BookTitle ($ReleaseYear)\$Narrator"
        Save-Configuration
    }

    # Verify ebook directory
    if ($CreateEbook) {
        $EbookDirectoryCorrect = Validate-Input "Is this the correct base location to store the ebook in? $EbookDirectory (Y/N)"
        if (-not $EbookDirectoryCorrect) {
            $EbookDirectory = Read-Host "Enter the desired directory for ebooks"
        }
        $FolderPathEbook = Join-Path -Path $EbookDirectory -ChildPath "$Author\$BookTitle ($ReleaseYear)"
        Save-Configuration
    }

    # Check if both audiobook and ebook directories are being created in the same location
    if ($CreateAudiobook -and $CreateEbook -and $AudiobookDirectory -eq $EbookDirectory) {
        Write-Host "Both audiobook and ebook directories cannot be created in the same location. Script exiting."
        exit
    }

    # Check if the folder(s) already exist, and if not, create them
    if ($CreateAudiobook -and -not (Test-Path -Path $FolderPathAudiobook)) {
        New-Item -Path $FolderPathAudiobook -ItemType Directory -Force
        Write-Host "Audiobook folder structure created:"
    }

    if ($CreateEbook -and -not (Test-Path -Path $FolderPathEbook)) {
        New-Item -Path $FolderPathEbook -ItemType Directory -Force
        Write-Host "Ebook folder structure created:"
    }

    # Ask the user if they want to run the script again
    $RunAgain = Validate-Input "Do you want to run this script again? (Y/N)"

} while ($RunAgain)
