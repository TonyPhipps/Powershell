# Define the directories to search
$searchDirectories = @("C:\Users", "D:\")

# Define the destination folder for found videos
$destinationFolder = "C:\VideosFromCamera"

# Define the file extensions for the video files you want to search for
$videoExtensions = @("*.mp4", "*.mov", "*.avi", "*.mkv", "*.3gp", "*.wmv", "*.flv", "*.m4v")

# Load the Windows.Media.Ocr assembly for reading video properties
Add-Type -AssemblyName System.Windows.Forms

# Function to check if a video was taken with a camera or cell phone (basic metadata check)
function Is-TakenWithCameraOrPhone {
    param (
        [string]$filePath
    )

    try {
        # Get the file metadata
        $shell = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace((Get-Item $filePath).Directory.FullName)
        $file = $folder.ParseName((Get-Item $filePath).Name)

        # Check for common tags like "Date Taken" or "Camera Model"
        $cameraTags = @("System.Video.FrameHeight", "System.Video.FrameWidth", "System.Media.Duration", "System.ItemNameDisplay")
        foreach ($tag in $cameraTags) {
            if ($folder.GetDetailsOf($file, [int]$tag) -ne "") {
                return $true
            }
        }
    } catch {
        # If an error occurs (e.g., no metadata), return false
        return $false
    }

    return $false
}

# Function to search for videos taken with a camera or cell phone
function Search-Videos {
    foreach ($directory in $searchDirectories) {
        # Search for video files
        $files = Get-ChildItem -Path $directory -Recurse -Include $videoExtensions -ErrorAction SilentlyContinue

        foreach ($file in $files) {
            try {
                # Check if the video file likely came from a camera or cell phone
                if (Is-TakenWithCameraOrPhone -filePath $file.FullName) {
                    # Define the destination path for the copied video
                    $destinationPath = Join-Path $destinationFolder $file.Name

                    # Ensure the destination folder exists
                    if (!(Test-Path $destinationFolder)) {
                        New-Item -Path $destinationFolder -ItemType Directory | Out-Null
                    }

                    # Copy the video to the destination folder
                    Copy-Item -Path $file.FullName -Destination $destinationPath -Force
                }
            } catch {
                # Silently continue if there's an error
                continue
            }
        }
    }
}

# Execute the search function
Search-Videos

Write-Host "Search complete. Videos taken with a camera or cell phone have been copied to $destinationFolder."
