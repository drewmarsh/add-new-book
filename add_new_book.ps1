# Initialize the loop condition
$RunAgain = "N"

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
        $AudiobookDirectoryName = "(Audiobook)"
        # Ask for Narrator when creating an audiobook directory
        $Narrator = Read-Host "Enter Narrator"
    }
    if ($CreateEbook) {
        $EbookDirectoryName = "(Ebook)"
    }

    # Define the base directory where the folder structure will be created
    $BaseDirectory = "C:\Users\drew\Desktop"  # Replace with your desired base directory path

    # Construct the full path based on user choices
    if ($AudiobookDirectoryName) {
        $FolderPathAudiobook = Join-Path -Path $BaseDirectory -ChildPath "$Author $AudiobookDirectoryName\$BookTitle ($ReleaseYear)\$Narrator"
    }

    if ($EbookDirectoryName) {
        $FolderPathEbook = Join-Path -Path $BaseDirectory -ChildPath "$Author $EbookDirectoryName\$BookTitle ($ReleaseYear)"
    }

    # Check if the folder(s) already exist, and if not, create them
    if ($FolderPathAudiobook -and -not (Test-Path -Path $FolderPathAudiobook)) {
        New-Item -Path $FolderPathAudiobook -ItemType Directory -Force
        Write-Host "Audiobook folder structure created:"
    }

    if ($FolderPathEbook -and -not (Test-Path -Path $FolderPathEbook)) {
        New-Item -Path $FolderPathEbook -ItemType Directory -Force
        Write-Host "Ebook folder structure created:"
    }

    if (-not ($FolderPathAudiobook -or $FolderPathEbook)) {
        $FolderPath = Join-Path -Path $BaseDirectory -ChildPath "$Author\$BookTitle ($ReleaseYear)\$Narrator"

        if (-not (Test-Path -Path $FolderPath)) {
            Write-Host "Folder structure created:"
        } else {
            Write-Host "Folder(s) already exist(s)."
        }
    }

    # Ask the user if they want to run the script again
    $RunAgain = Validate-Input "Do you want to run this script again? (Y/N)"

} while ($RunAgain)
