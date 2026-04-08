@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title File Hash Generator

:: Get the directory where this .bat file is placed
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "OUTPUT=%SCRIPT_DIR%\file_hashes.csv"

echo.
echo =============================================
echo   File Hash Generator - SHA256
echo   Output: file_hashes.csv
echo =============================================
echo.

:: Write CSV header
echo FileName,RelativePath,Extension,FileSize,DateCreated,DateModified,SHA256Hash > "%OUTPUT%"

:: Count total files first
set "total=0"
for /r "%SCRIPT_DIR%" %%F in (*) do (
    if /i not "%%~nxF"=="hash_files.bat" (
        if /i not "%%~nxF"=="file_hashes.csv" (
            set /a total+=1
        )
    )
)

echo Found %total% files. Starting hash...
echo.

set "count=0"

for /r "%SCRIPT_DIR%" %%F in (*) do (
    if /i not "%%~nxF"=="hash_files.bat" (
        if /i not "%%~nxF"=="file_hashes.csv" (

            set /a count+=1

            :: Progress
            set /a pct=count*100/total
            echo [!count!/%total% ^| !pct!%%] %%~nxF

            :: File name, extension, relative path
            set "FNAME=%%~nxF"
            set "EXT=%%~xF"
            set "FPATH=%%~fF"
            set "RELPATH=!FPATH:%SCRIPT_DIR%\=!"

            :: File size in MB (4 decimal places)
            set "SIZEB=%%~zF"
            call :calc_mb !SIZEB! SIZEMB

            :: SHA256 Hash via CertUtil
            set "HASHLINE="
            for /f "skip=1 tokens=*" %%H in ('certutil -hashfile "%%~fF" SHA256 2^>nul') do (
                if not defined HASHLINE set "HASHLINE=%%H"
            )
            :: Remove spaces from hash
            set "HASH=!HASHLINE: =!"

            :: Date Created and Modified in IST (UTC+5:30)
            call :get_ist_date "%%~fF" created modified

            :: Escape double quotes in fields
            set "FNAME=!FNAME:"=""!"
            set "RELPATH=!RELPATH:"=""!"

            :: Write CSV row
            echo "!FNAME!","!RELPATH!","!EXT!","!SIZEMB! MB","!created!","!modified!","!HASH!" >> "%OUTPUT%"
        )
    )
)

echo.
echo =============================================
echo  Completed! %count% files processed.
echo  Output saved to: %OUTPUT%
echo =============================================
echo.
pause
exit /b 0


:: -----------------------------------------------
:: Calculate MB from bytes to 4 decimal places
:: Usage: call :calc_mb BYTES RESULT_VAR
:: -----------------------------------------------
:calc_mb
set /a "MB_INT=%~1 / 1048576"
set /a "MB_REM=((%~1 %% 1048576) * 10000) / 1048576"
:: Pad remainder to 4 digits
set "MB_REM=0000!MB_REM!"
set "MB_REM=!MB_REM:~-4!"
set "%~2=!MB_INT!.!MB_REM!"
exit /b


:: -----------------------------------------------
:: Get IST datetime for a file (Created & Modified)
:: Uses PowerShell one-liner for accurate IST conversion
:: Usage: call :get_ist_date "filepath" created_var modified_var
:: -----------------------------------------------
:get_ist_date
set "TMPFILE=%TEMP%\hashtemp_%RANDOM%.txt"

powershell -NoProfile -Command ^
    "$f = Get-Item '%~1'; " ^
    "$ist = [System.TimeZoneInfo]::FindSystemTimeZoneById('India Standard Time'); " ^
    "$c = [System.TimeZoneInfo]::ConvertTimeFromUtc($f.CreationTimeUtc, $ist); " ^
    "$m = [System.TimeZoneInfo]::ConvertTimeFromUtc($f.LastWriteTimeUtc, $ist); " ^
    "Write-Output ($c.ToString('dd-MMM-yyyy hh:mm tt')); " ^
    "Write-Output ($m.ToString('dd-MMM-yyyy hh:mm tt'))" > "%TMPFILE%" 2>nul

set "line1="
set "line2="
set "linecount=0"
for /f "usebackq delims=" %%L in ("%TMPFILE%") do (
    set /a linecount+=1
    if !linecount!==1 set "line1=%%L"
    if !linecount!==2 set "line2=%%L"
)
del "%TMPFILE%" >nul 2>&1

set "%~2=!line1!"
set "%~3=!line2!"
exit /b