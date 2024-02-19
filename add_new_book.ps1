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
            $CurrentDirectory = Remove-QuotesFromDirectoryPath -DirectoryPath $CurrentDirectory
        } while (-not (Test-Path -Path $CurrentDirectory))
    } else {
        $HighlightedDirectory = Format-Directory -DirectoryPath $CurrentDirectory
        $DirectoryCorrect = Confirm-UserChoice ("Is this the correct location to store the $Type in? $HighlightedDirectory" + (Write-ChoicePrompt))
        if (-not $DirectoryCorrect) {
            do {
                $CurrentDirectory = Read-Host "Enter the desired directory for the $Type"
                $CurrentDirectory = Remove-QuotesFromDirectoryPath -DirectoryPath $CurrentDirectory
            } while (-not (Test-Path -Path $CurrentDirectory))
        }
        Write-Host
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

function Remove-QuotesFromDirectoryPath {
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

    $HighlightedDirectory = Format-Directory -DirectoryPath $FolderPath
    $MoveFiles = Confirm-UserChoice ("Do you want to move any files to this newly created directory? $HighlightedDirectory" + (Write-ChoicePrompt))
    if ($MoveFiles) {
        if (-not (Test-Path -Path $FolderPath)) { Write-Host "Directory ($FolderPath) not found." }
        
        do {
            # Ask the user for the destination of the file that they want to move
            Write-Host
            $FileDestination = Read-Host "`tEnter the path of the file you want to move"
            $FileDestination = Remove-QuotesFromDirectoryPath -DirectoryPath $FileDestination
            Write-Host "`t" -NoNewline
        
            if (-not (Test-Path -Path $FileDestination -PathType Leaf)) {
                # Handle the case where the specified file path does not exist
                Format-Error -ErrorMessage "Error: The specified file path '$FileDestination' does not exist." | Write-Host
            } else {
                try {
                    Move-Item -Path $FileDestination -Destination $FolderPath -Force
                    Format-Success -SuccessMessage "File moved successfully." | Write-Host
                } catch {
                    Format-Error -ErrorMessage "Error: $_" | Write-Host
                }
            }
        
            # Ask if the user wants to move more files
            Write-Host
            $MoveMoreFiles = Confirm-UserChoice ("Do you want to move another file?" + (Write-ChoicePrompt))
        } while ($MoveMoreFiles)
    }
}

# Producing colored text
$Colors = @{
    'Reset' = [char]27 + '[0m'
    'Red' = [char]27 + '[31m'
    'Green' = [char]27 + '[32m'
    'Yellow' = [char]27 + '[33m'
}

function Format-Color {
    param ([string]$Message, [string]$Color)

    $Reset = $Colors['Reset']
    return "$Color$Message$Reset"
}

function Format-Success {
    param ([string]$SuccessMessage)

    return Format-Color -Message $SuccessMessage -Color $Colors['Green']
}

function Format-Error {
    param ([string]$ErrorMessage)

    return Format-Color -Message $ErrorMessage -Color $Colors['Red']
}

function Format-Directory {
    param ([string]$DirectoryPath)

    return Format-Color -Message "$DirectoryPath" -Color $Colors['Yellow']
}

function Write-ChoicePrompt {
    $Reset = $Colors['Reset']
    $Green = $Colors['Green']
    $Red = $Colors['Red']
    Write-Output " (${Green}Y${Reset}/${Red}N${Reset})"
}

do {
    # Prompt the user for input with input validation
    $CreateAudiobook = Confirm-UserChoice ("Create an Audiobook directory?" + (Write-ChoicePrompt))
    $CreateEbook = Confirm-UserChoice ("Create an Ebook directory?" + (Write-ChoicePrompt))
    Write-Host

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
    Write-Host

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
        Write-Host "`tError: Both Audiobook and Ebook directories cannot be created in the same location. Script exiting."
        exit
    }

    if ($CreateAudiobook -and -not (Test-Path -Path $FolderPathAudiobook)) {
        New-Item -Path $FolderPathAudiobook -ItemType Directory -Force | Out-Null
        MoveFilesToDirectory -FolderPath $FolderPathAudiobook
    }
    
    if ($CreateEbook -and -not (Test-Path -Path $FolderPathEbook)) {
        New-Item -Path $FolderPathEbook -ItemType Directory -Force | Out-Null
        MoveFilesToDirectory -FolderPath $FolderPathEbook
    }

    # Ask the user if they want to run the script again
    Write-Host
    $RunAgain = Confirm-UserChoice ("Do you want to run this script again?" + (Write-ChoicePrompt))

} while ($RunAgain)