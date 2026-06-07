<#
$params = @(
"sync",
"F:\GoogleDrive\Tony",
"googledrive:/Tony",
"--drive-skip-shortcuts",
"--drive-acknowledge-abuse",
"--drive-skip-gdocs",
"--drive-skip-dangling-shortcuts",
"--fast-list",
"--suffix-keep-extension",
"--track-renames",
#"--dry-run",
"--verbose"
)

X:\Users\Tony\Downloads\rclone-v1.70.2-windows-amd64\rclone.exe $params
#>


$params = @(
"bisync",
"F:\GoogleDrive\Tony",
"googledrive:/Tony",
"--conflict-resolve", "newer",
"--conflict-loser", "delete",
"--conflict-suffix", "sync-conflict-{DateOnly}-",
"--compare", "size,modtime,checksum",
"--create-empty-src-dirs",
"--drive-skip-shortcuts",
"--drive-acknowledge-abuse",
"--drive-skip-gdocs",
"--drive-skip-dangling-shortcuts",
"--fast-list",
"--fix-case",
"--no-slow-hash",
"--suffix-keep-extension",
"--resilient",
"--recover",
#"--resync",
#"--resync-mode path1",
#"--dry-run",
"--verbose"
)

cd "F:\Program Files\rclone-v1.74.3-windows-amd64"
.\rclone.exe $params