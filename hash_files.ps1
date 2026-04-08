# hash_files.ps1
# Drop this file in your folder and run it.
# Right-click -> Run with PowerShell
# OR: powershell -ExecutionPolicy Bypass -File .\hash_files.ps1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutputCSV = Join-Path $ScriptDir "file_hashes.csv"
$ErrorActionPreference = "Continue"

# IST = UTC+5:30
$IST = [System.TimeZoneInfo]::CreateCustomTimeZone(
    "IST", [TimeSpan]::FromHours(5.5), "India Standard Time", "India Standard Time"
)

function To-IST($dt) {
    $utc = [System.TimeZoneInfo]::ConvertTimeToUtc($dt)
    $ist = [System.TimeZoneInfo]::ConvertTimeFromUtc($utc, $IST)
    return $ist.ToString("dd-MMM-yyyy hh:mm tt")
}

# Write header
"FileName,RelativePath,Extension,FileSize,DateCreated,DateModified,SHA256Hash" |
    Out-File -FilePath $OutputCSV -Encoding UTF8

# Collect all files except this script and the output CSV
$files = Get-ChildItem -Path $ScriptDir -Recurse -File |
         Where-Object { $_.FullName -ne $OutputCSV -and $_.Name -ne "hash_files.ps1" }

$total = $files.Count
$count = 0

Write-Host "Found $total files. Starting hash..." -ForegroundColor Cyan

foreach ($file in $files) {
    $count++
    $pct = [math]::Round(($count / $total) * 100, 1)

    Write-Progress -Activity "Hashing files ($pct%)" `
                   -Status "$count / $total  |  $($file.Name)" `
                   -PercentComplete $pct

    try {
        $hash     = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
        $sizeMB   = [math]::Round($file.Length / 1MB, 4).ToString("F4") + " MB"
        $created  = To-IST $file.CreationTime
        $modified = To-IST $file.LastWriteTime
        $relPath  = $file.FullName.Substring($ScriptDir.Length).TrimStart('\')
        $ext      = $file.Extension

        $row = @(
            ('"' + ($file.Name -replace '"','""') + '"'),
            ('"' + ($relPath   -replace '"','""') + '"'),
            ('"' + $ext + '"'),
            ('"' + $sizeMB  + '"'),
            ('"' + $created  + '"'),
            ('"' + $modified + '"'),
            ('"' + $hash     + '"')
        ) -join ","

        $row | Out-File -FilePath $OutputCSV -Encoding UTF8 -Append

    } catch {
        Write-Warning "SKIPPED: $($file.FullName) --- $_"
    }
}

Write-Progress -Activity "Done" -Completed
Write-Host "Completed! $count files processed." -ForegroundColor Green
Write-Host "Output saved to: $OutputCSV" -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")