@echo off
REM ================================
REM Threat Removal Script
REM File: C:\Program Files\ClamAV\scripts\remove_threat.bat
REM Args: %1 = quarantined file path, %2 = virus name, %3 = timestamp
REM ================================

setlocal enabledelayedexpansion

set "QUARANTINED_FILE=%~1"
set "VIRUS_NAME=%~2"
set "TIMESTAMP=%~3"

set "LOG_DIR=C:\Program Files\ClamAV\logs"
set "REMOVAL_LOG=%LOG_DIR%\removals.log"
set "BACKUP_DIR=%LOG_DIR%\removal_backups"

REM Create backup directory if it doesn't exist
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo ================================
echo CONFIRMED THREAT REMOVAL
echo File: %QUARANTINED_FILE%
echo Virus: %VIRUS_NAME%
echo ================================

REM ================================
REM Create forensic backup before deletion
REM ================================
if exist "%QUARANTINED_FILE%" (
    set "BACKUP_NAME=%TIMESTAMP%_%VIRUS_NAME%_%~nx1"
    set "BACKUP_NAME=!BACKUP_NAME::=!"
    set "BACKUP_NAME=!BACKUP_NAME:/=!"
    set "BACKUP_NAME=!BACKUP_NAME:\=!"
    set "BACKUP_NAME=!BACKUP_NAME: =_!"
    set "BACKUP_PATH=%BACKUP_DIR%\!BACKUP_NAME!.backup"
    
    echo Creating forensic backup...
    copy "%QUARANTINED_FILE%" "!BACKUP_PATH!" >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        echo [%TIMESTAMP%] BACKUP: Created forensic backup at !BACKUP_PATH! >> "%REMOVAL_LOG%"
        echo Forensic backup created successfully
    ) else (
        echo [%TIMESTAMP%] WARNING: Failed to create backup for %QUARANTINED_FILE% >> "%REMOVAL_LOG%"
        echo WARNING: Backup creation failed
    )
    
    REM ================================
    REM Secure deletion
    REM ================================
    echo Performing secure deletion...
    
    REM First, try to remove read-only attribute
    attrib -r "%QUARANTINED_FILE%" >nul 2>&1
    
    REM Delete the file
    del /f /q "%QUARANTINED_FILE%" >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        echo [%TIMESTAMP%] REMOVED: Successfully deleted %QUARANTINED_FILE% (%VIRUS_NAME%) >> "%REMOVAL_LOG%"
        echo ✓ Threat removed successfully
        
        REM Optional: Use sdelete for more secure deletion if available
        where sdelete >nul 2>&1
        if !ERRORLEVEL! EQU 0 (
            echo Running secure delete on free space...
            sdelete -p 1 -z -q "C:\Program Files\ClamAV\quarantine" >nul 2>&1
        )
        
    ) else (
        echo [%TIMESTAMP%] ERROR: Failed to delete %QUARANTINED_FILE% (%VIRUS_NAME%) >> "%REMOVAL_LOG%"
        echo ✗ ERROR: Failed to remove threat
        
        REM Try alternative removal methods
        echo Attempting alternative removal...
        takeown /f "%QUARANTINED_FILE%" >nul 2>&1
        icacls "%QUARANTINED_FILE%" /grant administrators:F >nul 2>&1
        del /f /q "%QUARANTINED_FILE%" >nul 2>&1
        
        if !ERRORLEVEL! EQU 0 (
            echo [%TIMESTAMP%] REMOVED: Alternative method succeeded for %QUARANTINED_FILE% >> "%REMOVAL_LOG%"
            echo ✓ Threat removed with alternative method
        ) else (
            echo [%TIMESTAMP%] CRITICAL: All removal attempts failed for %QUARANTINED_FILE% >> "%REMOVAL_LOG%"
            echo ✗ CRITICAL: Manual intervention required
        )
    )
    
) else (
    echo [%TIMESTAMP%] ERROR: Quarantined file not found: %QUARANTINED_FILE% >> "%REMOVAL_LOG%"
    echo ERROR: Quarantined file not found
)

REM ================================
REM Clean up any remaining traces
REM ================================
echo Cleaning up traces...

REM Clear Windows thumbnail cache if it might contain traces
if exist "%USERPROFILE%\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*.db" (
    echo Clearing thumbnail cache...
    taskkill /f /im explorer.exe >nul 2>&1
    del /f /q "%USERPROFILE%\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
    start explorer.exe
)

REM Clear recent documents that might reference the file
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs" /va /f >nul 2>&1

echo [%TIMESTAMP%] CLEANUP: System cleanup completed for %VIRUS_NAME% >> "%REMOVAL_LOG%"

echo ================================
echo Threat removal process completed
echo Check %REMOVAL_LOG% for details
echo Forensic backup available in %BACKUP_DIR%
echo ================================

endlocal