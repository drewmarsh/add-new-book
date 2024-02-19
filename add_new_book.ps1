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

# Prompts the user with a yes/no question and validates the input
function Confirm-UserChoice {
    param (
        [string]$Prompt
    )
    do {
        $userChoice = Read-Host $Prompt
    } while ($userChoice -notmatch '^[YNyn]$')
    return $userChoice -imatch '[Yy]'
}

function Get-DirectoryPath {
    param (
        [string]$Type,
        [string]$ConfigPath,
        [string]$CurrentDirectory,
        [string]$Narrator
    )

    $directoryVariableName = "${Type}Directory"
    $folderPathVariableName = "FolderPath${Type}"

    if (-not (Test-Path -Path $ConfigPath) -or -not $CurrentDirectory) {
        do {
            $CurrentDirectory = Read-Host "Enter the desired directory for $Type"
            $CurrentDirectory = Clean-DirectoryPathFromQuotes -DirectoryPath $CurrentDirectory
        } while (-not (Test-Path -Path $CurrentDirectory))
    } else {
        $DirectoryCorrect = Confirm-UserChoice "Is this the correct location to store the $Type in? $CurrentDirectory (Y/N)"
        if (-not $DirectoryCorrect) {
            do {
                $CurrentDirectory = Read-Host "Enter the desired directory for $Type"
                $CurrentDirectory = Clean-DirectoryPathFromQuotes -DirectoryPath $CurrentDirectory
            } while (-not (Test-Path -Path $CurrentDirectory))
        }
    }

    Set-Variable -Name $directoryVariableName -Value $CurrentDirectory -Scope Script

    if ($Type -eq "Audiobook" -and $Narrator) {
        $CurrentDirectory = Join-Path -Path $CurrentDirectory -ChildPath "$Author\$BookTitle ($ReleaseYear)"
        $CurrentDirectory = Join-Path -Path $CurrentDirectory -ChildPath $Narrator
    } else {
        $CurrentDirectory = Join-Path -Path $CurrentDirectory -ChildPath "$Author\$BookTitle ($ReleaseYear)"
    }

    Set-Variable -Name $folderPathVariableName -Value $CurrentDirectory -Scope Script
}

function Clean-DirectoryPathFromQuotes {
    param (
        [string]$DirectoryPath
    )

    # Remove quotation marks from the directory path
    $CleanedPath = $DirectoryPath -replace '"', ''
    
    return $CleanedPath
}

# Moves files to the specified directory after obtaining user confirmation
function MoveFilesToDirectory {
    param (
        [string]$FolderPath
    )

    $MoveFiles = Confirm-UserChoice "Do you want to move any files to this newly created directory? $FolderPath (Y/N)"
    if ($MoveFiles) {
        if (-not (Test-Path -Path $FolderPath)) { Write-Host "Directory ($FolderPath) not found." }
        
        do {
            # Ask the user for the destination of the file that they want to move
            $FileDestination = Read-Host "Enter the path of the file you want to move"
            $FileDestination = Clean-DirectoryPathFromQuotes -DirectoryPath $FileDestination
            
            if (-not (Test-Path -Path $FileDestination -PathType Leaf)) {
                Write-Host "Error: The specified file path '$FileDestination' does not exist."
            } else {
                try {
                    Move-Item -Path $FileDestination -Destination $FolderPath -Force
                    Write-Host "File moved successfully."
                } catch {
                    Write-Host "Error: $_"
                    $FileDestination = Clean-DirectoryPathFromQuotes -DirectoryPath $FileDestination
                    try {
                        Move-Item -Path $FileDestination -Destination $FolderPath -Force
                        Write-Host "File moved successfully after removing quotes."
                    } catch {
                        Write-Host "Error: $_"
                    }
                }
            }
            # Ask if the user wants to move more files
            $MoveMoreFiles = Confirm-UserChoice "Do you want to move more files? (Y/N)"
        } while ($MoveMoreFiles)
    }
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

    # Create directories based on user choices
    if ($CreateAudiobook) {
        Get-DirectoryPath -Type "Audiobook" -ConfigPath $ConfigPath -CurrentDirectory $AudiobookDirectory -Narrator $Narrator
    }
    
    if ($CreateEbook) {
        Get-DirectoryPath -Type "Ebook" -ConfigPath $ConfigPath -CurrentDirectory $EbookDirectory
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
        MoveFilesToDirectory -FolderPath $FolderPathAudiobook
    }
    
    if ($CreateEbook -and -not (Test-Path -Path $FolderPathEbook)) {
        New-Item -Path $FolderPathEbook -ItemType Directory -Force | Out-Null
        Write-Host "Ebook folder structure created."
        MoveFilesToDirectory -FolderPath $FolderPathEbook
    }

    # Ask the user if they want to run the script again
    $RunAgain = Confirm-UserChoice "Do you want to run this script again? (Y/N)"

} while ($RunAgain)