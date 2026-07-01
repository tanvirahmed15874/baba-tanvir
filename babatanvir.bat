@echo off
:: =====================================================
::  PC DEEP CLEAN & HEALTH CHECK
::  Made by Baba Tanvir
:: =====================================================
:: Run AS ADMINISTRATOR for full effect
:: (Right-click -> Run as administrator)
::
:: HONEST NOTE: No script can hold CPU/GPU/RAM at a
:: permanent 0%. The moment a program runs, usage goes
:: back up - that's normal PC behavior, not a bug.
:: This script does two real things instead:
::   1) DEEP CLEAN  - clears junk/cache and trims memory
::                     every single time you run it.
::   2) STAY LOW    - optional mode that keeps repeating
::                     the memory trim every few minutes
::                     for as long as you leave it running,
::                     so usage is pushed back down instead
::                     of slowly climbing.
:: =====================================================

title PC Deep Clean - by Baba Tanvir
color 0A
setlocal enabledelayedexpansion

:MENU
set STAYLOW=
set LBU=
cls
echo ============================================
echo    PC DEEP CLEAN ^& HEALTH CHECK
echo    Made by Baba Tanvir
echo ============================================
echo.
echo   [1] Deep Clean Now (one-time, full clean + health check)
echo   [2] Deep Clean + Stay Low Mode
echo       (repeats memory trim every 5 min until closed)
echo   [3] Health Check Only (no cleaning)
echo   [4] Exit
echo.
set /p CHOICE=Choose an option (1/2/3/4): 

if "%CHOICE%"=="1" goto DEEPCLEAN
if "%CHOICE%"=="2" goto DEEPCLEAN_LOOP
if "%CHOICE%"=="3" goto HEALTHCHECK
if "%CHOICE%"=="4" exit
goto MENU

:DEEPCLEAN_LOOP
set STAYLOW=1
goto DEEPCLEAN

:DEEPCLEAN
echo.
echo Starting deep clean... please wait.
timeout /t 1 >nul

:: ---------------------------------------------------
:: RAM - BEFORE
:: ---------------------------------------------------
for /f "tokens=2 delims==" %%A in ('wmic OS get FreePhysicalMemory /value ^| findstr "="') do set FREE_BEFORE=%%A
for /f "tokens=2 delims==" %%A in ('wmic OS get TotalVisibleMemorySize /value ^| findstr "="') do set TOTAL_MEM=%%A
echo [1/9] Free RAM before: !FREE_BEFORE! KB of !TOTAL_MEM! KB total
echo.

:: ---------------------------------------------------
:: TEMP FILES + WINDOWS TEMP
:: ---------------------------------------------------
echo [2/9] Clearing temp files, cache, and junk...
del /q /f /s "%TEMP%\*" >nul 2>&1
del /q /f /s "C:\Windows\Temp\*" >nul 2>&1
del /q /f /s "C:\Windows\Prefetch\ReadyBoot\*" >nul 2>&1
del /q /f /s "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
del /q /f /s "%LOCALAPPDATA%\Microsoft\Windows\INetCache\*" >nul 2>&1
del /q /f /s "%LOCALAPPDATA%\Microsoft\Windows\WER\*" >nul 2>&1
echo       Done.
echo.

:: ---------------------------------------------------
:: RECYCLE BIN
:: ---------------------------------------------------
echo [3/9] Emptying Recycle Bin...
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1
echo       Done.
echo.

:: ---------------------------------------------------
:: DNS + NETWORK
:: ---------------------------------------------------
echo [4/9] Flushing DNS cache...
ipconfig /flushdns >nul 2>&1
echo       Done.
echo.

:: ---------------------------------------------------
:: GPU / SHADER CACHE
:: ---------------------------------------------------
echo [5/9] Clearing GPU shader cache...
del /q /f /s "%LOCALAPPDATA%\D3DSCache\*" >nul 2>&1
del /q /f /s "%LOCALAPPDATA%\NVIDIA\DXCache\*" >nul 2>&1
del /q /f /s "%LOCALAPPDATA%\NVIDIA\GLCache\*" >nul 2>&1
del /q /f /s "%LOCALAPPDATA%\AMD\DxCache\*" >nul 2>&1
echo       Done.
echo.

:: ---------------------------------------------------
:: EXPLORER RESTART (release held memory/handles)
:: ---------------------------------------------------
echo [6/9] Restarting Explorer to release held memory...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 >nul
start explorer.exe
echo       Done.
echo.

:: ---------------------------------------------------
:: TRIM WORKING SET OF EVERY RUNNING PROCESS
:: Forces every open app to release RAM it's holding
:: but not actively using right now.
:: ---------------------------------------------------
echo [7/9] Trimming memory of all running programs...
powershell -NoProfile -Command ^
  "$sig = '[DllImport(\"psapi.dll\")] public static extern bool EmptyWorkingSet(IntPtr hProcess);'; " ^
  "$t = Add-Type -MemberDefinition $sig -Name W -Namespace P -PassThru; " ^
  "Get-Process | ForEach-Object { try { $t::EmptyWorkingSet($_.Handle) | Out-Null } catch {} }" >nul 2>&1
echo       Done.
echo.

:: ---------------------------------------------------
:: DISK CLEANUP
:: ---------------------------------------------------
echo [8/9] Running Windows Disk Cleanup...
cleanmgr /sagerun:1 >nul 2>&1
echo       Done.
echo.

:: ---------------------------------------------------
:: RAM - AFTER
:: ---------------------------------------------------
for /f "tokens=2 delims==" %%A in ('wmic OS get FreePhysicalMemory /value ^| findstr "="') do set FREE_AFTER=%%A
echo [9/9] Free RAM after:  !FREE_AFTER! KB of !TOTAL_MEM! KB total
set /a FREED=!FREE_AFTER!-!FREE_BEFORE!
echo       RAM freed this run: approximately !FREED! KB
echo.

:: If in loop mode, skip the full health report to keep loop fast
if "%STAYLOW%"=="1" goto AFTERCLEAN

:: ---------------------------------------------------
:: PC HEALTH CHECK (one-time mode only)
:: ---------------------------------------------------
echo ------------------------------------------------
echo  SYSTEM INFO
echo ------------------------------------------------
systeminfo | findstr /C:"OS Name" /C:"OS Version" /C:"System Boot Time" /C:"Total Physical Memory" /C:"Available Physical Memory"

echo.
echo ------------------------------------------------
echo  CPU USAGE (current snapshot)
echo ------------------------------------------------
wmic cpu get loadpercentage /value | findstr "="

echo.
echo ------------------------------------------------
echo  DISK HEALTH (SMART status)
echo ------------------------------------------------
wmic diskdrive get model,status

echo.
echo ------------------------------------------------
echo  DISK SPACE
echo ------------------------------------------------
wmic logicaldisk get deviceid,volumename,freespace,size

echo.
echo ------------------------------------------------
echo  BATTERY REPORT (laptops only)
echo ------------------------------------------------
powercfg /batteryreport /output "%USERPROFILE%\Desktop\battery-report.html" >nul 2>&1
if exist "%USERPROFILE%\Desktop\battery-report.html" (
    echo Battery report saved to Desktop as battery-report.html
) else (
    echo No battery detected or report unavailable.
)

echo.
echo ============================================
echo   DEEP CLEAN COMPLETE - Made by Baba Tanvir
echo ============================================
echo.
echo NOTE: CPU/GPU/RAM usage will rise again as soon as
echo you open apps - that's normal. Run this anytime
echo things feel sluggish, or pick option 2 to keep it
echo trimmed automatically in the background.
echo.
pause
goto MENU

:AFTERCLEAN
echo Stay Low Mode active. Next trim in 5 minutes...
echo (Close this window anytime to stop.)
echo.
timeout /t 300
goto DEEPCLEAN_LOOP

:HEALTHCHECK
cls
echo ============================================
echo    PC HEALTH CHECK
echo    Made by Baba Tanvir
echo ============================================
echo.
echo Gathering system health info... please wait.
echo.

echo ------------------------------------------------
echo  SYSTEM INFO
echo ------------------------------------------------
systeminfo | findstr /C:"OS Name" /C:"OS Version" /C:"System Boot Time" /C:"Total Physical Memory" /C:"Available Physical Memory"

echo.
echo ------------------------------------------------
echo  RAM STATUS
echo ------------------------------------------------
for /f "tokens=2 delims==" %%A in ('wmic OS get FreePhysicalMemory /value ^| findstr "="') do set FREE_NOW=%%A
for /f "tokens=2 delims==" %%A in ('wmic OS get TotalVisibleMemorySize /value ^| findstr "="') do set TOTAL_NOW=%%A
echo Free RAM: !FREE_NOW! KB of !TOTAL_NOW! KB total

echo.
echo ------------------------------------------------
echo  CPU
echo ------------------------------------------------
wmic cpu get name /value | findstr "="
wmic cpu get loadpercentage /value | findstr "="
wmic cpu get currenttemperature /value 2>nul | findstr "="

echo.
echo ------------------------------------------------
echo  GPU
echo ------------------------------------------------
wmic path win32_videocontroller get name,adapterram,driverversion /value | findstr "="

echo.
echo ------------------------------------------------
echo  DISK HEALTH (SMART status)
echo ------------------------------------------------
wmic diskdrive get model,status,size

echo.
echo ------------------------------------------------
echo  DISK SPACE
echo ------------------------------------------------
wmic logicaldisk get deviceid,volumename,freespace,size

echo.
echo ------------------------------------------------
echo  UPTIME
echo ------------------------------------------------
for /f "skip=1" %%A in ('wmic os get lastbootuptime') do if not defined LBU set LBU=%%A
echo Last boot (raw): !LBU!

echo.
echo ------------------------------------------------
echo  BATTERY REPORT (laptops only)
echo ------------------------------------------------
powercfg /batteryreport /output "%USERPROFILE%\Desktop\battery-report.html" >nul 2>&1
if exist "%USERPROFILE%\Desktop\battery-report.html" (
    echo Battery report saved to Desktop as battery-report.html
) else (
    echo No battery detected or report unavailable.
)

echo.
echo ============================================
echo   HEALTH CHECK COMPLETE - Made by Baba Tanvir
echo ============================================
echo.
pause
goto MENU
