# Define the directories to search
$searchDirectories = @("C:\Users", "D:\")

# Define the destination folder for found photos
$destinationFolder = "C:\test"

# Define the file extensions for the image files you want to search for
$imageExtensions = @("*.jpg", "*.jpeg", "*.heif", "*.heic", "*.png")

# Load the System.Drawing assembly for reading image properties
Add-Type -AssemblyName System.Drawing

# Function to check if a photo was taken with a camera or cell phone
function Is-TakenWithCameraOrPhone {
    param (
        [System.Drawing.Image]$image
    )

    try {
        # Get the property items (EXIF data)
        $exifProperties = $image.PropertyItems

        # Check for "Make" (camera brand) or "Model" (camera model)
        foreach ($property in $exifProperties) {
            if ($property.Id -eq 0x010F -or $property.Id -eq 0x0110) {
                return $true
            }
        }
    } catch {
        # If an error occurs (e.g., no EXIF data), return false
        return $false
    }

    return $false
}

# Function to search for photos taken with a camera or cell phone
function Search-Photos {
    foreach ($directory in $searchDirectories) {
        # Search for image files
        $files = Get-ChildItem -Path $directory -Recurse -Include $imageExtensions -ErrorAction SilentlyContinue

        foreach ($file in $files) {
            try {
                # Load the image to check its metadata
                $image = [System.Drawing.Image]::FromFile($file.FullName)

                # Check if the image was taken with a camera or cell phone
                if (Is-TakenWithCameraOrPhone -image $image) {
                    # Define the destination path for the copied photo
                    $destinationPath = Join-Path $destinationFolder $file.Name

                    # Ensure the destination folder exists
                    if (!(Test-Path $destinationFolder)) {
                        New-Item -Path $destinationFolder -ItemType Directory | Out-Null
                    }

                    # Copy the photo to the destination folder
                    Copy-Item -Path $file.FullName -Destination $destinationPath -Force
                }

                # Dispose of the image object to free resources
                $image.Dispose()
            } catch {
                # Silently continue if there's an error
                continue
            }
        }
    }
}

# Execute the search function
Search-Photos

Write-Host "Search complete. Photos taken with a camera or cell phone have been copied to $destinationFolder."
