@if not "%DEBUG%"=="1" @echo off
REM Run window as MAX so window starts in top left corner
if not "%1"=="max" if not "%2"=="max" start /MAX cmd /c "%0" %1 max & exit/b
cls
TITLE %~dpf0 (v1.19)
REM set cmd shell window size (was 160 x 60)
mode con: cols=160 lines=83 2> nul
echo.
color 1f

echo %~n0 (using RoboCopy)
echo.
echo.
echo Action: Updates files on an existing Easy2Boot USB drive.
echo.
echo Source: %~dp0
echo.
echo         Old E2B v1.5x files will be replaced.
echo         Your own files will not be deleted.
echo.
echo         Tip: To hide files in the root and delete non-essential readme files, set the \menu.lst file attribute to Hidden first.
echo.
echo.
echo Note: To make a new E2B drive, please use the \Make_E2B_USB_DRIVE (run as admin).cmd file.
echo.

set str=%~dp0
set str=%STR:~-2,2%
::if "%str%"==":\" echo ERROR: Source is a drive! Please run %~nx0 from the download folder & color 4f & pause & goto :EOF
set str=

pushd "%~dp0"

echo.%~pn0 | %WINDIR%\System32\find.exe /I "Desktop\Update_e2b">nul && (set ERR=0) || (set ERR=1)
if "%ERR%"=="0" echo ERROR: Please extract the Easy2Boot files to an EMPTY FOLDER - not the Desktop! & color 4f & pause & goto :EOF
set ERR=

REM WMIC presence/PATH gate removed: queries use PowerShell CIM.

setlocal enableextensions enabledelayedexpansion

powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; [Console]::WriteLine('caption  description  Size  volumename'); foreach($r in (Get-CimInstance -ClassName Win32_LogicalDisk)) { [Console]::WriteLine(([string]$r.caption+'  '+[string]$r.description+'  '+[string]$r.Size+'  '+[string]$r.volumename)) }" | %WINDIR%\System32\find.exe "Disk" | sort /+1
echo.

REM get current version and versions available
call :getCVER
echo.
echo Tip: Please choose "E2B" volume.
echo.
FOR %%D IN (D E F G H I J K L M N O P Q R S T U V W X Y Z) DO (
DIR %%D:\_ISO\e2b\grub\menu.lst > nul 2>&1 && (echo E2B detected on %%D:) && (call set DE2B=%%D)
)
echo.
set ask=%1
if "%1"=="max" set ask=
if "%ask%"=="" set /P ask=USB Drive Letter to update to E2B v%CVER%? (e.g. %DE2B%) : 
if "%ask%"=="" goto :EOF
set USB=%ask:~0,1%

if exist "%USB%:\_ISO\e2b\grub\menu.lst" goto :cc1
echo.
color 4f
echo WARNING: Drive %USB%: does not already contain all E2B files!
echo.
set /P cont=Continue to update? ([N]/Y) : 
if /i not "%cont%"=="Y" goto :eof


:cc1
color 1f
REM get current version on USB drive
call :getUSBVER
set OVER=%USBVER%


REM See if menu.lst is hidden
dir /ah %USB%:\menu.lst >nul 2>nul && set TIDYUP=1
REM See if user has deleted or moved scripts
dir "%USB%:\_ISO\e2b\grub\e2b.cfg" >nul 2>nul || set NEWDRIVE=1
dir "%USB%:\MAKE_E2B_USB_DRIVE (run as admin).cmd" >nul 2>nul || set TIDYMAKE=1
dir "%USB%:\QEMU_MENU_TEST (run as admin).cmd" >nul 2>nul || set TIDYQEMU=1
dir "%USB%:\MAKE_THIS_DRIVE_CONTIGUOUS.cmd" >nul 2>nul || set TIDYCONTIG=1


set DF=ZZA_FASTLOAD_ON_OFF.mnu
call :delzz
set DF=ZZSubMenuAntiVirus.mnu
call :delzz
set DF=ZZSubMenuAuto.mnu
call :delzz
set DF=ZZSubMenuBackup.mnu
call :delzz
set DF=ZZSubMenuDos.mnu
call :delzz
set DF=ZZSubMenuLinux.mnu
call :delzz
set DF=ZZSubMenuUtilities.mnu
call :delzz
set DF=ZZSubMenuWin.mnu
call :delzz
set DF=ZZSubMenuWinPE.mnu
call :delzz
set DF=ZZWindowsInstall.mnu
call :delzz
set DF=ZZZF1SubMenuHelp.mnu
call :delzz
set DF=ZZZF7BootHdd.mnu
call :delzz
set DF=ZZZF8$_SHOW_FASTLOAD.mnu
call :delzz
set DF=ZZZF8ReloadMenu.mnu
call :delzz
set DF="Place *"
call :delzz
set DF="\MNU\Read Me*"
call :delzz
set DF="\MNU\Note Any*.*"
call :delzz
if exist %USB%:\_ISO\FASTLOAD.YES del %USB%:\_ISO\FASTLOAD.YES
if exist %USB%:\_ISO\FASTLOAD_Read_Me.txt del %USB%:\_ISO\FASTLOAD_Read_Me.txt

::tidy up old files
if exist "%USB%:\_ISO\docs\Sample mnu Files\*.mnu" del "%USB%:\_ISO\docs\Sample mnu Files\*.mnu"
if exist "%USB%:\_ISO\docs\Sample mnu Files\Win7*.ini" del "%USB%:\_ISO\docs\Sample mnu Files\Win7*.ini"
if exist "%USB%:\_ISO\docs\Sample mnu Files\POS*.txt" del "%USB%:\_ISO\docs\Sample mnu Files\POS*.txt" 
if exist "%USB%:\_ISO\docs\Sample mnu Files\kali*.txt" del "%USB%:\_ISO\docs\Sample mnu Files\kali*.txt"
if exist "%USB%:\_ISO\docs\Sample mnu Files\crunch*.txt" del "%USB%:\_ISO\docs\Sample mnu Files\crunch*.txt"
if exist "%USB%:\_ISO\docs\Sample mnu Files\E2B Menus\PTN2_Menu.mnu" del "%USB%:\_ISO\docs\Sample mnu Files\E2B Menus\PTN2_Menu.mnu"
if exist "%USB%:\_ISO\docs\Sample mnu Files\E2B Menus\PTN_Log1_Menu.mnu" del "%USB%:\_ISO\docs\Sample mnu Files\E2B Menus\PTN_Log1_Menu.mnu"

if exist "%USB%:\_ISO\docs\E2B Utilities\Make SubMenu.cmd" del "%USB%:\_ISO\docs\E2B Utilities\Make SubMenu.cmd"
REM ZGRUB_USB_046.mnu has moved
if exist %USB%:\_ISO\MAINMENU\ZGRUB_USB_046.mnu del %USB%:\_ISO\MAINMENU\ZGRUB_USB_046.mnu

:: tidy up old Win8 Win10 files
set DF=AutoWipeDisk_Win8.1RetailPro_UK.xml
call :delzz8
set DF=AutoWipeDisk_Win8.1RetailPro_USA_SingleMaxPtn.xml
call :delzz8
set DF=AutoWipeDisk_Win8RetailPro_UK.xml
call :delzz8
set DF=AutoWipe_Win8.1_RetailPro_UK_NoUsers_AdministratorOnly_30GB.xml
call :delzz8
set DF=CHOOSE FROM A LIST.key
call :delzz8
set DF=Sample Win8 Pro (no prompt to repair).xml
call :delzz8
set DF=Sample Win8 Pro.xml
call :delzz8
set DF=Windows 8 Preview Pro.key
call :delzz8
set DF=Windows 8.1 Ent 90 Day Eval.key
call :delzz8

set DF=AutoWipeDisk0_Win10ProUK.xml
call :delzz10
set DF=CHOOSE FROM A LIST.key
call :delzz10
set DF=Sample Win10 Pro (no prompt to repair).xml
call :delzz10
set DF=Sample Win10 Pro.xml
call :delzz10
set DF=Windows 10 Insider Preview.key
call :delzz10
set DF=Windows 10 Tech Preview.key
call :delzz10

REM Check if.mnu files exist (may have been renamed by user)
set MAINDEFAULT=
set MAINMENU=
set UTILMEM=
set UTILGRUB=
if not exist %USB%:\_ISO\MAINMENU\$$$SetDefaultMenu.mnu set MAINDEFAULT=1
if not exist %USB%:\_ISO\MAINMENU\ZZSubMenuAll.mnu set MAINMENU=1
if not exist %USB%:\_ISO\UTILITIES\Utilities_MemTest.mnu set UTILMEM=1
if not exist %USB%:\_ISO\UTILITIES\ZGRUB_USB_046.mnu set UTILGRUB=1

echo.
set NOROBO=
cmd /c robocopy /? | %WINDIR%\System32\find.exe "XF" > nul || set NOROBO=1
if "%NOROBO%"=="1" goto :XCOP
REM Check for MT switch
set MT=
robocopy /? | %WINDIR%\System32\find.exe "MT[" > nul && set MT=/MT:1
echo Updating %USB%: to v%CVER% ...
REM exclude .zip files and this file (must add \ at end if enclosing in quotes)
robocopy "%~dp0\" %USB%:\\ /E /FFT /XX /FP /NP /NDL /NJH /r:2 /w:3 %MT% /XF %~nx0 E2B_ReadMe.txt Update_all_E2B_drives.cmd UPDATE_E2B_DRIVE.CMD Make_E2B.exe CONTIG.ISO
echo ------------------------------------------------------------------------------
    if %ERRORLEVEL% EQU 16 echo ***FATAL ERROR*** & goto end1
    if %ERRORLEVEL% EQU 15 echo COPIED + FAIL + MISMATCHES + EXTRA  (some files not copied!) & goto end1
    if %ERRORLEVEL% EQU 14 echo FAIL + MISMATCHES + EXTRA FILES  (some files not copied!) & goto end1
    if %ERRORLEVEL% EQU 13 echo COPIED + FAIL + MISMATCHES  (some files not copied!) & goto end1
    if %ERRORLEVEL% EQU 12 echo FAILED + MISMATCHES  (some files not copied!) & goto end1
    if %ERRORLEVEL% EQU 11 echo COPY + FAIL + EXTRA (some files not copied!) & goto end1
    if %ERRORLEVEL% EQU 10 echo FAILED + EXTRA  (some files not copied!) & goto end1
    if %ERRORLEVEL% EQU 9 echo COPY OK + FAIL  (some files not copied!) & goto end1
    if %ERRORLEVEL% EQU 8 echo FAILED  (some files not copied!) & goto end1
    if %ERRORLEVEL% EQU 7 echo COPIED OK, SOME MISMATCHES + EXTRA FILES  - POSSIBLE ERRORS? & goto end1
    if %ERRORLEVEL% EQU 6 echo MISMATCH, EXTRA FILES COPIED  - POSSIBLE ERRORS? & goto end1
    if %ERRORLEVEL% EQU 5 echo MISMATCH, COPIED OK  - POSSIBLE ERRORS? & goto end1
    if %ERRORLEVEL% EQU 4 echo MISMATCH - POSSIBLE ERRORS? & goto end1
    if %ERRORLEVEL% EQU 3 echo UPDATED OK & goto end1
    if %ERRORLEVEL% EQU 2 echo ALREADY UP TO DATE (NO CHANGES MADE) & goto end1
    if %ERRORLEVEL% EQU 1 echo FILES UPDATED OK & goto end1
REM if %ERRORLEVEL% EQU 0 echo ALREADY UP TO DATE (NO CHANGES MADE) & goto end1
:end1

REM echo ErrorLevel=%ERRORLEVEL%
REM Robocopy gives errorlevel 0 if access denied!!!
if %ERRORLEVEL%==0 goto skipcfg
REM if %ERRORLEVEL%==2 goto skipcfg
if %ERRORLEVEL% GTR 9000 (set NOROBO=1& goto :XCOP)
if %ERRORLEVEL% GTR 7 goto skipcfg
echo.

:XCOP
if "%NOROBO%"=="1" echo Using XCOPY /d to update - please wait... & echo. & xcopy /cherkyd "%~dp0*.*" %USB%:

REM Make new MyE2B.cfg file
setlocal disabledelayedexpansion
if not exist %USB%:\_ISO\MyE2B.cfg if exist .\_ISO\docs\Make_E2B_USB_Drive\Make_MyE2B.cfg.cmd call .\_ISO\docs\Make_E2B_USB_Drive\Make_MyE2B.cfg.cmd %USB%:
endlocal


:skipcfg

::if exist "%USB%:\MAKE_E2B_USB_DRIVE (run as admin).cmd" del "%USB%:\MAKE_E2B_USB_DRIVE (run as admin).cmd"
if exist %USB%:\E2B_ReadMe.txt del %USB%:\E2B_ReadMe.txt
if exist %USB%:\%~nx0 del %USB%:\%~nx0
:: copy bootmgr for NTBOOT if present
if not exist %USB%:\_ISO\e2b\grub\DPMS\NTBOOT.MOD\bootmgr if exist C:\bootmgr xcopy /h c:\bootmgr %USB%:\_ISO\e2b\grub\DPMS\NTBOOT.MOD > nul
if not exist %USB%:\_ISO\e2b\grub\DPMS\NTBOOT.MOD\bootmgr if exist "%SystemRoot%\Boot\PCAT\bootmgr" xcopy /h "%SystemRoot%\Boot\PCAT\bootmgr" %USB%:\_ISO\e2b\grub\DPMS\NTBOOT.MOD > nul

REM ----- TIDY FILES IF MENU.LST is hidden ---

if "%NEWDRIVE%"=="1" goto :skptidy1

if "%TIDYUP%"=="1" (
attrib +h %USB%:\menu.lst
attrib +h %USB%:\Win7PESE.ini
attrib +h %USB%:\Win8PESE.ini
attrib +h %USB%:\Win10PESE.ini
attrib +h %USB%:\grldr
attrib +h %USB%:\autorun.inf
attrib +h %USB%:\e2b.ico
attrib +h %USB%:\unattend.xml
attrib +h %USB%:\autounattend.xml
attrib +h "%USB%:\_ISO\MAINMENU\NOT FOR WINDOWS*."
@echo.
@echo INFO: %USB%:\menu.lst had Hidden attribute - files in %USB%:\ are now hidden
)

if "%TIDYMAKE%"=="1"   if exist "%USB%:\MAKE_E2B_USB_DRIVE (run as admin).cmd" del "%USB%:\MAKE_E2B_USB_DRIVE (run as admin).cmd"
if "%TIDYQEMU%"=="1"   if exist "%USB%:\QEMU_MENU_TEST (run as admin).cmd"     del "%USB%:\QEMU_MENU_TEST (run as admin).cmd"
if "%TIDYCONTIG%"=="1" if exist "%USB%:\MAKE_THIS_DRIVE_CONTIGUOUS.cmd"        del "%USB%:\MAKE_THIS_DRIVE_CONTIGUOUS.cmd"

REM Check for user renamed files
set DIR=%USB%:\_ISO\MAINMENU
set FILE=$$$SetDefaultMenu.mnu
if exist %DIR%\%FILE% if "%MAINDEFAULT%"=="1" call :delmnu
set FILE=ZZSubMenuAll.mnu
if exist %DIR%\%FILE% if "%MAINMENU%"=="1" call :delmnu

set DIR=%USB%:\_ISO\UTILITIES
set FILE=Utilities_MemTest.mnu
if exist %DIR%\%FILE% if "%UTILMEM%"=="1" call :delmnu
set FILE=ZGRUB_USB_046.mnu
if exist %DIR%\%FILE% if "%UTILGRUB%"=="1" call :delmnu

:skptidy1
REM get latest versions from web
call :getvers
REM get the version we just updated to
call :getUSBVER
set UVER=%USBVER%
color 2f
echo.
echo INFORMATION:
if not "%LVER%"=="" echo              Latest (stable) is  v%LVER%   %LDATE%
if not "%BVER%"=="" if NOT "%BVER%"=="%LVER%" echo              Latest Beta is      v%BVER%  %BDATE%
echo.
if not "%OVER%"=="" echo              E2B drive was       v%OVER%
if not "%UVER%"=="" echo              E2B drive is now    v%UVER%
echo.

REM Check for agFM ptn
REM find drive number of %USB%:
@For /F Tokens^=2Delims^=^" %%A In ('WMIC /LOCALE:MS_409 LogicalDisk Where "DeviceID='%USB%:'"^ Assoc /AssocClass:Win32_LogicalDiskToPartition 2^>Nul^| %WINDIR%\system32\Find.exe "n."')Do @For /F Tokens^=2Delims^=^" %%B In ('WMIC Path^ Win32_DiskDriveToDiskPartition 2^>Nul^| %WINDIR%\system32\Find.exe "%%A"')Do set DD=%%B
set DD=%DD:~17,3%
set /a DD=%DD%+0
if "%DD%"=="" echo ERROR: Cannot determine drive number from drive letter %USB% & pause & goto :EOF
WMIC /LOCALE:MS_409 Path Win32_LogicalDiskToPartition get Dependent, Antecedent | %WINDIR%\system32\find.exe /i "Disk #%DD%, Partition #1" > "%temp%\vol.tmp"
for /f "usebackq tokens=4 delims==," %%j in ("%temp%\vol.tmp") do set LL=%%j
set L=%LL:"=%
set L=%L:~0,1%:
if "%L%"=="" (type "%temp%\vol.tmp" & echo. & echo LL=%LL% & echo ERROR: Cannot determine drive letter of partition 2 & pause & goto :EOF)
echo Partition 2 is %L%
set AGFM=%L%
if NOT "%AGFM%"=="" if exist "%AGFM%\e2b\Update agFM\Download and update agFM_v2.cmd" copy "%USB%:\_ISO\docs\Make_E2B_USB_Drive\Download and update agFM_v2.cmd" "%AGFM%\e2b\Update agFM\Download and update agFM_v2.cmd"
if NOT "%AGFM%"=="" if exist "%AGFM%\e2b\Update agFM\Download and update agFM.cmd" set "AGFMNAME=Download and update agFM.cmd"
if NOT "%AGFM%"=="" if exist "%AGFM%\e2b\Update agFM\Download and update agFM_v2.cmd" set "AGFMNAME=Download and update agFM_v2.cmd"
if NOT "%AGFMNAME%"==""  (
	setlocal disabledelayedexpansion
	pushd "%AGFM%\e2b\Update agFM\"
	call "%AGFM%\e2b\Update agFM\%AGFMNAME%"
    if exist "%AGFM%\e2b\Update agFM\Update_to_latest_Ventoy_version.cmd" call "%AGFM%\e2b\Update agFM\Update_to_latest_Ventoy_version.cmd"
	popd
	goto :EOF
)
echo.
if "%AGFMNAME%"=="" (
	echo ------ %AGFM% ------
	dir %AGFM%\ /b /ad-s /on
	echo      ------
	echo.
	echo Information: agFM files were not found on Partition 2
	echo.
	if exist %AGFM%\ventoy\ventoy_x64.efi echo WARNING: Partition 2 may have been replaced by a VENTOY PARTITION IMAGE^^! 
	if exist %AGFM%\ventoy\ventoy_x64.efi echo Please restore the original agFM files by booting and using the 'Restore agFM Partition 2' menu entry,
	if exist %AGFM%\ventoy\ventoy_x64.efi echo and then run Update E2B Drive again to update Partition 2.
	echo.
)
echo.
REM echo Finished!
pause
goto :EOF

:delzz
if exist "%USB%:\_ISO\MAINMENU\%DF%" del "%USB%:\_ISO\MAINMENU\%DF%"
goto :eof

:delzz8
if exist "%USB%:\_ISO\WINDOWS\WIN8\%DF%" del "%USB%:\_ISO\WINDOWS\WIN8\%DF%"
goto :eof

:delzz10
if exist "%USB%:\_ISO\WINDOWS\WIN10\%DF%" del "%USB%:\_ISO\WINDOWS\WIN10\%DF%"
goto :eof

:delmnu
color 4f
echo.
echo WARNING: A standard .MNU file was missing!
echo ==========================================
echo.
echo %DIR%\%FILE% was missing but has now been added.
echo.
echo The .mnu files in this folder are now:
echo.
dir %DIR%\*.mnu /b
echo.
echo You may have previously renamed %FILE% (perhaps to change its order in the Menu).
echo If there is another version present, you may see duplicate menu entries.
echo.
set ask=
set /p ask=Do you want to delete %FILE% now? (Y/[N]) : 
if /i "%ask%"=="Y" del %DIR%\%FILE%
color 1f
goto :eof

:getvers
:: Check for more recent version
echo.
echo Getting file LatestE2BBeta.txt from easy2boot.xyz- please wait...
if exist LatestE2B.txt del LatestE2B.txt
set wgpath=
if exist ".\_ISO\docs\Make_E2B_USB_Drive\wget.exe" set wgpath=.\_ISO\docs\Make_E2B_USB_Drive\
if not exist %wgpath%wget.exe color 4f & echo CANNOT FIND WGET.EXE & pause & goto :EOF
REM Try multiple sites
set url=https://easy2boot.xyz/wp-content/uploads/downloads/LatestE2BBeta.txt
if not exist LatestE2B.txt %wgpath%wget.exe -q -t 1 -T 3 %url% -O LatestE2B.txt > nul || del LatestE2B.txt
set url=http://easy2boot.xyz/wp-content/uploads/downloads/LatestE2BBeta.txt
if not exist LatestE2B.txt %wgpath%wget.exe -q -t 1 -T 3 %url% -O LatestE2B.txt > nul || del LatestE2B.txt

if not exist LatestE2B.txt goto :eof

%WINDIR%\System32\find.exe LatestE2B.txt "set LVER=" > nul || goto :eof
set LVER=
set LDATE=
set BVER=
set BDATE=

FOR /F "tokens=2 delims=^=" %%K IN (latestE2B.txt) DO (
    if "!LVER!"=="" (SET LVER=%%K) else if "!LDATE!"=="" SET LDATE=%%K
)
FOR /F "tokens=2 skip=2 delims=^=" %%K IN (latestE2B.txt) DO (
    if "!BVER!"=="" (SET BVER=%%K) else if "!BDATE!"=="" SET BDATE=%%K
)
if exist LatestE2B.txt del LatestE2B.txt
goto :EOF


:getCVER
:: get this version of E2B
set CVER=
if exist "%temp%\mdtemp.cmd" del "%temp%\mdtemp.cmd" > nul
if exist ".\_ISO\e2b\grub\E2B.cfg" %WINDIR%\System32\find.exe "set VER=" ".\_ISO\e2b\grub\E2B.cfg" > "%temp%\mdtemp.cmd"
if exist "%temp%\mdtemp.cmd" call "%temp%\mdtemp.cmd" > nul 2> nul
if exist "%temp%\mdtemp.cmd" del "%temp%\mdtemp.cmd" > nul
set VER=X%VER%
if /i "%VER:~1,1%"=="v" set CVER=%VER:~2,99%
if "%VER%"=="X" set CVER=
set VER=
:nover
goto :EOF

:getUSBVER
if "%USB%"=="" goto :EOF
:: get USB version of E2B
set UEBVER=
if exist "%temp%\mdtemp.cmd" del "%temp%\mdtemp.cmd" > nul
if exist "%USB%:\_ISO\e2b\grub\E2B.cfg" %WINDIR%\System32\find.exe "set VER=" "%USB%:\_ISO\e2b\grub\E2B.cfg" > "%temp%\mdtemp.cmd"
if exist "%temp%\mdtemp.cmd" call "%temp%\mdtemp.cmd" > nul 2> nul
if exist "%temp%\mdtemp.cmd" del "%temp%\mdtemp.cmd" > nul
REM We get an error if VER is empty, so must be at least 1 character
set VER=X%VER%
if /i "%VER:~1,1%"=="v" set USBVER=%VER:~2,99%
if "%VER%"=="X" set USBVER=
set VER=
goto :EOF

