# Create 'logs' directory if it does not exist
$logDirectory = "logs"
if (!(Test-Path -Path $logDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $logDirectory | Out-Null
}

# Initialize counters
$totalFilesProcessed = 0
$successfulMoves = 0
$failedMoves = 0
$skippedFiles = 0

# Get start time
$startTime = Get-Date -Format "yyyy-MM-dd-HH-mm-ss.fffffff"
$logFileName = Join-Path -Path $logDirectory -ChildPath "log_$startTime.log"

# Start processing PDF files
$startText = "$startTime --- Start processing PDF files ---"
Write-Output $startText
if (!(Test-Path -Path $logFileName)) {
    New-Item -ItemType File -Path $logFileName -Force | Out-Null
}
Write-Output $startText | Out-File -FilePath $logFileName -Append

# Traverse through each PDF file in the current directory only
Get-ChildItem -Path . -Filter *.pdf | ForEach-Object {
    $totalFilesProcessed++
    $sourceFile = $_.FullName
    $processingTime = Get-Date -Format "yyyy-MM-dd-HH-mm-ss.fffffff"
    $processingText = "$processingTime Processing file: $sourceFile"
    Write-Output $processingText
    Write-Output $processingText | Out-File -FilePath $logFileName -Append

    # Get file name without extension
    $fileName = $_.Name
    $nameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($fileName)

    # Check file name format
    if ($nameWithoutExt -match '^DCGPK\d{11}_\d{8}_\d{6}$') {
        $prefix = $nameWithoutExt.Substring(0, 16)  # DCGPKxxxxxxxxxxx
        $datepart = $nameWithoutExt.Substring(17, 8)  # yyyymmdd
        $timepart = $nameWithoutExt.Substring(26, 6)  # hhiiss

        $yyyy = $datepart.Substring(0, 4)
        $mm = $datepart.Substring(4, 2)
        $dd = $datepart.Substring(6, 2)

        $hh = $timepart.Substring(0, 2)
        $ii = $timepart.Substring(2, 2)
        $ss = $timepart.Substring(4, 2)

        $checkFileTime = Get-Date -Format "yyyy-MM-dd-HH-mm-ss.fffffff"
        $checkFileText = "$checkFileTime File name: $fileName with prefix: $prefix in date: $yyyy-$mm-$dd-$hh-$ii-$ss"
        Write-Output $checkFileText
        Write-Output $checkFileText | Out-File -FilePath $logFileName -Append

        # Create directories if they do not exist
        $targetDir = Join-Path -Path $PWD.Path -ChildPath "$yyyy\$mm\$dd"
        if (-not (Test-Path -Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir | Out-Null
            $createFolderTime = Get-Date -Format "yyyy-MM-dd-HH-mm-ss.fffffff"
            $createFolderText = "$createFolderTime Created folder: $targetDir"
            Write-Output $createFolderText
            Write-Output $createFolderText | Out-File -FilePath $logFileName -Append
        }

        # Move file to the new location

		try {
			Move-Item -Path $sourceFile -Destination $targetDir -ErrorAction Stop
			$successfulMoves++
			$moveFileTime = Get-Date -Format "yyyy-MM-dd-HH-mm-ss.fffffff"
			$moveFileText = "$moveFileTime Successfully moved file $fileName."
			Write-Output $moveFileText
			Write-Output $moveFileText | Out-File -FilePath $logFileName -Append
		} catch {
			$failedMoves++
			$errorMoveFileTime = Get-Date -Format "yyyy-MM-dd-HH-mm-ss.fffffff"
			$errorMessage = $_.Exception.Message
			$errorMoveFileText = "$errorMoveFileTime Error moving file $fileName $errorMessage"
			Write-Output $errorMoveFileText
			Write-Output $errorMoveFileText | Out-File -FilePath $logFileName -Append
		}
    } else {
        $skippedFiles++
        $skipMoveFileTime = Get-Date -Format "yyyy-MM-dd-HH-mm-ss.fffffff"
        $skipMoveFileText = "$skipMoveFileTime File $fileName does not match the required format, skipping."
        Write-Output $skipMoveFileText
        Write-Output $skipMoveFileText | Out-File -FilePath $logFileName -Append
    }

    Write-Output ""  # Empty line to separate logs for each file
    Write-Output "" | Out-File -FilePath $logFileName -Append
}

$endTime = Get-Date -Format "yyyy-MM-dd-HH-mm-ss.fffffff"
$endText = "$endTime --- All PDF files processed ---"
Write-Output $endText
Write-Output $endText | Out-File -FilePath $logFileName -Append

# Output summary
Write-Output ""
$summaryText = "Summary:"
Write-Output $summaryText
Write-Output $summaryText | Out-File -FilePath $logFileName -Append

$totalFilesProcessedText = "Total files processed: $totalFilesProcessed"
Write-Output $totalFilesProcessedText
Write-Output $totalFilesProcessedText | Out-File -FilePath $logFileName -Append

$successfulMovesText = "Successful moves: $successfulMoves"
Write-Output $successfulMovesText
Write-Output $successfulMovesText | Out-File -FilePath $logFileName -Append

$failedMovesText = "Failed moves: $failedMoves"
Write-Output $failedMovesText
Write-Output $failedMovesText | Out-File -FilePath $logFileName -Append

$skippedFilesText = "Skipped files: $skippedFiles"
Write-Output $skippedFilesText
Write-Output $skippedFilesText | Out-File -FilePath $logFileName -Append

# To prevent PowerShell from closing immediately
# pause