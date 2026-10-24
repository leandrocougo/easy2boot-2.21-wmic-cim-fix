@echo off
@color 1f
mode con: cols=120 lines=20
title %~f0
echo Checking - please wait...

REM WMIC presence/PATH gate removed: queries use PowerShell CIM.

if not exist "%~d0\_ISO\e2b\grub\menu.lst" echo ERROR: This utility must be run from an E2B USB drive. && goto :BADEND
if not exist "%~d0\_ISO\docs\E2B Utilities\Launcher\%~nx0" echo ERROR: No %~d0\_ISO\docs\E2B Utilities\Launcher\%~nx0 found.
:: get agFM volume letter and myphysdrive number
SETLOCAL ENABLEDELAYEDEXPANSION
call :get_agFM
ENDLOCAL & set agfm=%agfm%
echo.

::set agfm=dd

if "%agfm%"=="" echo agFM FILES ARE NOT PRESENT ON PARTITION 2 && set LIM=1
echo.
if "%agfm%"=="" echo agFM WARNING: \boot\grubfm\config not found on partition 2 of this drive
if NOT "%agfm%"=="" if not exist "%agfm%\ventoy\ventoy_x64.efi" echo WARNING: 'Ventoy for Easy2Boot' UEFI was not found on partition 2 of this drive && set LIM=2
if NOT "%agfm%"=="" if not exist "%agfm%\ventoy\ventoy.cpio" echo WARNING: 'Ventoy for Easy2Boot' Legacy was not found on partition 2 of this drive && set LIM=2
echo.
if "%LIM%"=="1" echo Some agFM and Ventoy options may not work until you add agFM to Partition 2
if "%LIM%"=="2" echo Some Ventoy options may not work until you add 'Ventoy for Easy2Boot' to Partition 2
echo.
::if NOT "%LIM%"=="" color 5f & PING -n 10 127.0.0.1>nul & goto :EOF
if NOT "%LIM%"=="" color 5f & echo. & echo Press any key to continue... & TIMEOUT 10>nul & goto :EOF

if "%LIM%"=="" cls & color 2f 
if "%LIM%"=="" echo Easy2Boot + agFM + Ventoy detected...
::if "%LIM%"=="" PING -n 3 127.0.0.1>nul

goto :EOF

:BADEND
color 4f
echo.
echo STARTUP CHECK FAILED!
echo.
pause
goto :EOF


REM =====================

:get_agFM
REM get physical drive number of drive that has this file
FOR /F "tokens=2 delims=#," %%? IN ('powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; foreach($r in (Get-CimInstance -ClassName Win32_LogicalDiskToPartition)) { [Console]::WriteLine(([string]$r.Antecedent.DeviceID+'  '+[string]$r.Dependent.DeviceID)) }"  ^| %WINDIR%\system32\FIND.exe "%~d0"') DO (set myphysdrive=%%?)
REM echo Physical Drive=%myphysdrive%

FOR %%D IN (D E F G H I J K L M N O P Q R S T U V W X Y Z) DO (
DIR %%D:\boot\grubfm\config> nul 2>&1  && set agfm=%%D:
if not "!agfm!"=="" call :getdno !agfm!
if "!physdrive!"=="!myphysdrive!" goto :dexit
)
:dexit
REM echo agFM drive is %agfm%
goto :EOF


:getdno
REM get physical drive number of drive that has this file
set physdrive=
REM echo Checking %~1
if "%~1"=="" goto :EOF
FOR /F "tokens=2 delims=#," %%? IN ('powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; foreach($r in (Get-CimInstance -ClassName Win32_LogicalDiskToPartition)) { [Console]::WriteLine(([string]$r.Antecedent.DeviceID+'  '+[string]$r.Dependent.DeviceID)) }"  ^| %WINDIR%\system32\FIND.exe "%~1"') DO (set physdrive=%%?)
goto :EOF

REM =================

