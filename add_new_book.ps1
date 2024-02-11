# Initialize the loop condition
$RunAgain = $true

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

    # Initialize directory names
    $AudiobookDirectoryName = ""
    $EbookDirectoryName = ""

    # Set directory names based on user choices
    if ($CreateAudiobook) {
        # Ask user to enter a Narrator only if an audiobook directory is being created
        $Narrator = Read-Host "Enter Narrator"
    }

    # Define the base directory where the folder structure for the new audiobook will be created
    $AudiobookDirectory = "C:\Users\drew\Desktop\Audiobooks"

    # Define the base directory where the folder structure for the new ebook will be created
    $EbookDirectory = "C:\Users\drew\Desktop\Ebooks"

    # Verify audiobook directory
    if ($CreateAudiobook) {
        $AudiobookDirectoryCorrect = Validate-Input "Is this the correct location to store the audiobook in? $AudiobookDirectory (Y/N)"
        if (-not $AudiobookDirectoryCorrect) {
            $AudiobookDirectory = Read-Host "Enter the desired directory for audiobooks:"
        }
        $FolderPathAudiobook = Join-Path -Path $AudiobookDirectory -ChildPath "$Author\$BookTitle ($ReleaseYear)\$Narrator"
    }

    # Verify ebook directory
    if ($CreateEbook) {
        $EbookDirectoryCorrect = Validate-Input "Is this the correct base location to store the ebook in? $EbookDirectory (Y/N)"
        if (-not $EbookDirectoryCorrect) {
            $EbookDirectory = Read-Host "Enter the desired directory for ebooks:"
        }
        $FolderPathEbook = Join-Path -Path $EbookDirectory -ChildPath "$Author\$BookTitle ($ReleaseYear)"
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
