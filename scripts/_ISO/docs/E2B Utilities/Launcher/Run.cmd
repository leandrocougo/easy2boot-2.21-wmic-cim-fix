<# : GetFile.bat
:: launches a File... Open a file chooser Explorer dialogue
:: https://stackoverflow.com/a/15885133/1683264
:: requires PowerShell

:: If Param 1 is "agfm" then use agFM volume letter (optional) else current drive letter
:: Param1 = Full path without drive letter (e.g. \e2b\xx yy\zz.txt)
:: Param2 = command line parameters or Action (ChooseAndEdit, EXPLORER, NotePad, Start, Startw)

@echo off
echo Parameters=%*
title %~df0
pushd "%~dp0"
set me=%~f0
set VOL=%~d0
set agfm=
if /i not "%~1"=="agfm" goto :skipagfm

:: get agFM volume letter and myphysdrive number
SETLOCAL ENABLEDELAYEDEXPANSION
call :get_agFM
ENDLOCAL & set agfm=%agfm%
SHIFT
set VOL=%agfm%

:skipagfm
set mypath=%~1
set myext=%~x1
set mypath=%VOL%%mypath%

::echo me=%me%
::echo VOL=%VOL%
::echo mypath=%mypath%

if /i "%~2"=="ChooseAndEdit" goto :CHOOSE
if /i "%~2"=="EXPLORER" goto :EXPLORER
if /i "%~2"=="NotePad" goto :EDIT
if /i "%~2"=="Start" (start "" cmd /c "%mypath%" & goto :EOF)
if /i "%~2"=="StartW" (start "" /w "agFM" cmd /c "%mypath%" & goto :EOF)

color 4f
echo.
echo USAGE: [agfm]  "filepath+ext"  ACTION
echo Where ACTION=ChooseAndEdit ^| EXPLORER ^| NOTEPAD ^| Start ^| StartW
echo.
if /i "%~2"==""     echo ERROR: ACTION parameter is missing & echo. & pause
if /i NOT "%~2"=="" echo ERROR: ACTION parameter [%2] is not recognised! & echo. & pause

goto :EOF

REM ====================
:EXPLORER
if exist "%mypath%" explorer "%mypath%"
goto :EOF

REM ====================

:EDIT
REM if user has NotePad++ then use it - else use Notepad
if exist "%ProgramFiles%\Notepad++\Notepad++.exe" start "" "%ProgramFiles%\Notepad++\Notepad++.exe" "%mypath%" & goto :EOF
if exist "%ProgramFiles(x86)%\Notepad++\Notepad++.exe" echo start "" "%ProgramFiles(x86)%\Notepad++\Notepad++.exe" "%mypath%" & goto :EOF
start Notepad.exe "%mypath%"
goto :EOF

REM ====================

:CHOOSE
REM Choose a file in %mypath% folder and open in notepad
for /f "delims=" %%I in ('powershell -noprofile "iex (${%me%} | out-string)"') do (set chosen=%%~I)
echo You chose %chosen%
if "%chosen%"=="" goto :EOF
set mypath=%chosen%
goto :EDIT

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

REM ===================

:getdno
REM get physical drive number of drive that has this file
set physdrive=
REM echo Checking %~1
if "%~1"=="" goto :EOF
FOR /F "tokens=2 delims=#," %%? IN ('powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; foreach($r in (Get-CimInstance -ClassName Win32_LogicalDiskToPartition)) { [Console]::WriteLine(([string]$r.Antecedent.DeviceID+'  '+[string]$r.Dependent.DeviceID)) }"  ^| %WINDIR%\system32\FIND.exe "%~1"') DO (set physdrive=%%?)
goto :EOF

REM =================

: end Batch portion / begin PowerShell hybrid chimera #>

Add-Type -AssemblyName System.Windows.Forms
$f = new-object Windows.Forms.OpenFileDialog
$f.InitialDirectory = $env:mypath
# $f.Filter = "Config Files (*.cfg)|*.cfg"
# $f.Filter = "Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
$f.Filter = "Text Files|*.txt;*.cfg;*.lst;*.mnu;*.lua;*.grubfm|All Files (*.*)|*.*"
$f.ShowHelp = $true
# multiple file selection
$f.Multiselect = $false
[void]$f.ShowDialog()
if ($f.Multiselect) { $f.FileNames } else { $f.FileName }

