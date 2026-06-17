# Veeam-AzureBlob-Sync.ps1
$azcopy = "C:\Tools\azcopy.exe"
$source = "C:\BackUp-Folder\"
$destination = "YOUR_BLOB_SAS_URL_HERE"

Write-Host "Starting backup sync to Azure Blob..." -ForegroundColor Cyan
& $azcopy copy $source $destination --recursive
Write-Host "Backup completed: $(Get-Date)" -ForegroundColor Green