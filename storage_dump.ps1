# Prompt user for target size in TB
$targetSizeTB = [int](Read-Host -Prompt "Enter the target total size in TB to fill")

# Prompt user for the folder path
$folderPath = Read-Host -Prompt "Enter the folder path where files will be created (e.g., D:\NAS\loadtest)"

# Define other variables
$fileSizeTB = 1     # Size of each file in TB
$fileSizeBytes = 1TB  # Size of each file in bytes (1 TB)

# Ensure the folder exists
New-Item -Path $folderPath -ItemType Directory -Force

# Calculate the target size in bytes
$targetSizeBytes = $targetSizeTB * 1TB

# Initialize a counter for file creation and track the current filled size
$currentSizeBytes = 0
$fileCount = 1

# Loop to create files until the target size is reached
while ($currentSizeBytes -lt $targetSizeBytes) {
    $filePath = [System.IO.Path]::Combine($folderPath, "dummyfile$fileCount.tmp")
    
    # Create a 1 TB file
    Write-Output "Creating $filePath with size 1 TB..."
    fsutil file createnew $filePath $fileSizeBytes

    # Update the current filled size and increment the file counter
    $currentSizeBytes += $fileSizeBytes
    $fileCount++

    # Display the current filled size
    Write-Output "Current total filled size: $([math]::Round($currentSizeBytes / 1TB, 2)) TB"
}

Write-Output "Completed filling $folderPath with $targetSizeTB TB of data."
