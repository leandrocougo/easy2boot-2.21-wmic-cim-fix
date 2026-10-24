@if not "%DEBUG%"=="1" @echo off
REM Version 4.2 2015-03-12 - run from .\_ISO\docs\Make_E2B_USB_Drive folder (Uses LockDisMount), check for grubinst_new and new version of grubinst with silent-boot option, remove touchdrv.exe command, check 4K drives
REM Version 4.3 2015-04-07 - change method of detection of admin privileges
REM Version 4.4 2015-05-03 - Use RMPartUSB and grubinst in same folder if present.
REM version 4.5 2015-06-03 - copy bootmgr to NTBOOT.MOD folder if possible
REM version 4.6 2015-09-28 - default NTFS, add UEFI help text
REM version 4.7 2016-01-18 - bugfix for removable drive detection
REM version 4.8 2016-02-04 - ignore errors on xcopy (in case \autorun.inf is WP), tidy up .tmp file
REM version 4.9 2016-02-12 - if XP don't use wmic
REM version 4.10 2016-03-22 - versions displayed using wget.exe
REM version 4.11 2016-05-24 - new admin permissions test
REM version 4.12 2016-07-08 - only copy compatible bootmgr
REM version 4.13 2016-07-12 - bugfix for bootmgr copy causing exit if no \bootmgr found
REM version 4.14 2016-08-15 - extra bootmgr versions added
REM version 4.15 2016-10-10 - check latest version using LatestE2B.txt file
REM version 4.16 2016-10-29 - help on where to put files added
REM version 4.17 2017-01-12 - allow user to run this from a source E2B USB drive, check target drive <> source drive
REM version 4.18 2017-01-13 - bugfix for bootmgr overwrite when cloning E2B driive
REM version 4.19 2017-01-30 - modify to work with Make_E2B.exe, test for larger than 137GB
REM version 4.20 2017-04-13 - add check for FIND.exe
REM version 4.21 2017-04-29 - show first copy files (in case picks wrong partition)
REM version 4.22 2017-11-30 - Prompt for CONTIG.ISO size at end
REM version 4.23 2018-05-02 - exclude CONTIG.ISO from copy to USB
REM version 4.24 2018-07-04 - use %WINDIR%\System32\find.exe instead of find in case user Path variable is bad
REM version 4.25 2018-12-15 - bugfix for USB drive 10 and 11
REM version 4.26 2019-03-14 - create 2nd partition using diskpart if drive over 128GB (if Removable drive then need Win10 1703+)
REM version 4.27 2019-04-24 - bugfix for Autosize on <32GB drives
REM version 4.28 2019-05-11 - use bitsadmin for download if no wget
REM version 4.29 2019-10-04 - add EXPAND2 support
REM version 4.30 2020-01-23 - reduce ptn1 size to allow for 2nd 500MB FAT32 or NTFS partition or larger if large drive.
REM version 4.31 2020-02-05 - If Win10 or USB HDD ask user for ptn sizes, suppress HWDetection pop-ups, download agFM for ptn2
REM version 4.32 2020-02-17 - bugfixes and improvements for 4.31
REM version 4.33 2020-02-20 - added extra E2B_PTN2 checks, fix ">128GB" typo bug, fix CONTIG.ISO size bug
REM version 4.34 2020-03-21 - format Ptn2 as FAT32 if under 32GB for auto
REM version 4.35 2020-03-24 - if AUTO and large drive ask for partition sizes anyway, Italian diskpart fix
REM version 4.36 2020-04-06 - Use GiB, fix for French and Italian Diskpart
REM version 4.37 2020-04-16 - bugfix for 32GB FAT ptn
REM version 4.38 2020-09-21 - bugfix - if more than one E2B drive connected, agFM ptn2 may be mis-identified
REM version 4.29 2020-10-01 - download and add Ventoy, URL for agFM changed!
REM v4.40 2020-11-12 - fix typo in latestversion.txt URL (_ instead of -)
REM v4.41 2020-11-23 -
REM v4.42 2020-12-23 - add E2B Launcher message
REM v4.43 2021-01-21 - fix for tasklist not in XP Home
REM v4.44 2021-03-10 - add test for wbem in path
REM v4.45 2021-04-05 - bugfix for wbem test
REM v4.46/47 2021-05-06 - multiple download sources and retries added, fix %temp% used without "%temp%" for paths with spaces
REM v4.48 2021-07-08 - DisplayAV status if error
REM v4.49 2021-10-01 - add :getfree subroutine in case user has assigned any network drive letters (Windows bug as assigns same drive letter as network drive to removable drives - e.g. E:)
REM v4.50 2021-11-13 - test for old Win10 builds
REM v4.51 2021-12-30 - add OVERRIDE to DEL PART commands
REM v4.55 2024-08-11 - add WMIC warning for WIN 11 (26/1/2025 modified)


cls
set E2BVER=4.56
TITLE %~n0 %E2BVER%
:: set the cmd shell window size
mode con: cols=130 lines=56 2> nul
color 1f
echo Make an Easy2Boot USB drive (using RMPartUSB)
echo =============================================
echo.

:: ensure ShellHWDetection is enabled to start with
call :getOS
if "%NOPSHELL%"=="" call powershell Start-Service -Name ShellHWDetection > nul
set SRCDL=%~d0
::set str=%~dp0
::set str=%str:~1,6%
::if /i "%str%"==":\_ISO" echo ERROR: This drive is an E2B drive! Please run from a folder on your hard disk. & goto :exitbad
::set str=

:: Check that the Windows FIND command works
echo FRED123FRED | %WINDIR%\system32\find.exe "D123F" > nul || (echo ERROR: Windows FIND.EXE is not working correctly - please check %windir%\system32\find.exe exists and is correct! & echo. & %WINDIR%\System32\find.exe /? & echo. & goto :exitbad)

call :checkperms
::call :check_Permissions
if "%ADMIN%"=="FAIL" goto :exitbad

REM tasklist is not in XP Home - check for Acronis Active Protection
if exist %WINDIR%\system32\tasklist.exe %WINDIR%\system32\tasklist.exe /SVC | %WINDIR%\system32\find.exe /i "AcronisActiveProt" > nul && (echo *** WARNING: Acronis Active Protection Service detected! *** & echo. & echo This will block write access to the USB drive. & echo. & echo Please disable it or 'Trust' all E2B apps and try again [CTRL+ALT+DEL - Task Manager - Stop service - End task]. & echo. & color 4f & pause)

pushd "%~dp0"

REM Check for internet connection
set internet=
ping.exe www.google.com -n 1 -w 1000 > nul && set internet=1
if "%internet%"=="" ping.exe www.microsoft.com -n 1 -w 1000 > nul && set internet=1
if "%internet%"=="" ping.exe bbc.com -n 1 -w 1000 > nul && set internet=1
if "%internet%"=="" ping.exe 8.8.8.8 -n 1 -w 1000 > nul && set internet=1
if "%internet%"=="" ping.exe www.google.com -4 -n 1 -w 1000 > nul && set internet=1
if "%internet%"=="" ping.exe www.google.com -6 -n 1 -w 1000 > nul && set internet=1
if "%internet%"=="" ping.exe www.google.com -n 1 -w 1000
if "%internet%"=="" tracert.exe -w 500 www.google.com
if "%internet%"=="" echo. & echo ***** WARNING: NO (OR BLOCKED) INTERNET ACCESS - PLEASE CHECK ANTIVIRUS, PROXY, POLICIES AND FIREWALL SETTINGS & timeout 5 > nul 2> nul

if "%1"=="AUTO" (set AUTODRV=%2) & (set AUTOLANG=%3) & (set AUTOKBD=%4) & (set AUTOSIZE=%5)
if "%1"=="AUTO" set AUTO=1

::echo AUTODRV="%AUTODRV%" AUTOLANG="%AUTOLANG%" AUTOKBD="%AUTOKBD%"
::pause

echo.%~pn0 | %WINDIR%\system32\find.exe /I "Desktop\_ISO\docs\Make_e2b">nul && (set ERR=0) || (set ERR=1)
if "%ERR%"=="0" echo ERROR: Please extract the Easy2Boot files to an EMPTY FOLDER - not the Desktop! & goto :exitbad
set ERR=

set str=%~dp0
set str=%STR:~-2,2%
if "%str%"==":\" echo ERROR: Source is a drive! Please run %~nx0 from the download folder & goto :exitbad
set str=

if not exist ..\..\..\menu.lst echo ERROR: Cannot find Easy2Boot files in %~dp0 & goto :exitbad
if not exist ..\..\e2b\grub\menu.lst echo ERROR: Cannot find Easy2Boot files in %~dp0 & goto :exitbad
if not exist ..\..\e2b\grub\E2B_GRUB.txt echo ERROR: Cannot find Easy2Boot files in %~dp0 & goto :exitbad

REM WMIC presence/PATH gate removed: queries use PowerShell CIM.

REM change to our working folder
set WF=%~dp0
if exist "%WF%\rmpartusb.exe" goto :gotwf
set WF=%ProgramFiles(x86)%\RMPrepUSB
if exist "%WF%\rmpartusb.exe" goto :gotwf
set WF=%ProgramFiles%\RMPrepUSB
if exist "%WF%\rmpartusb.exe" goto :gotwf


:NF
echo.
echo Sorry - I cannot find RMPartUSB!
echo Please install RMPrepUSB to your default Program Files folder
echo OR
echo Specify the folder where RMPartUSB.exe is located.
echo.
set /p WF=RMPartUSB folder is at (e.g. D:\temp\RMPrepUSB) ? : 
if exist "%WF%\rmpartusb.exe" goto :gotwf
set /p ask=Sorry - couldn't find it - press R to Retry or any other key to exit (Retry\Abort) : 
if /i "%ask%"=="R" goto :NF
exit
:gotwf

:: Check for more recent version
if exist LatestE2B.txt del LatestE2B.txt
echo.
if "%internet%"=="" goto :wget_end
echo Getting current release version from easy2boot website...
if not exist LatestE2B.txt wget.exe --no-check-certificate -q -t 1 -T 3 https://easy2boot.xyz/wp-content/uploads/downloads/LatestE2B.txt -O LatestE2B.txt > nul || del LatestE2B.txt
if not exist LatestE2B.txt wget.exe --no-check-certificate -q -t 1 -T 3 http://easy2boot.xyz/wp-content/uploads/downloads/LatestE2B.txt -O LatestE2B.txt > nul || del LatestE2B.txt
if not exist LatestE2B.txt goto :wget_end

%WINDIR%\System32\find.exe LatestE2B.txt "set LVER=" > nul || goto :wget_end
set LVER=
set VER=
set LDATE=
setlocal enableextensions enabledelayedexpansion
FOR /F "tokens=2 delims=^=" %%K IN (latestE2B.txt) DO (
    if "!LVER!"=="" (SET LVER=%%K) else if "!LDATE!"=="" SET LDATE=%%K
)
setlocal disabledelayedexpansion
if exist LatestE2B.txt del LatestE2B.txt
:: get current version of E2B
if exist "%temp%\mdtemp.cmd" del "%temp%\mdtemp.cmd" > nul
%WINDIR%\System32\find.exe "set VER=" "%~dp0..\..\e2b\grub\E2B.cfg" > "%temp%\mdtemp.cmd"
call "%temp%\mdtemp.cmd" > nul 2> nul
echo.
if not "%VER%"==""  echo INFORMATION: E2B version = %VER%
if not "%LVER%"=="" echo              Latest E2B  = v%LVER%  %LDATE%  (www.easy2boot.xyz/download)


:wget_end
echo.

set ALL=
set A=
pushd "%WF%"
RMPARTUSB FIND > "%temp%\mdtemp.cmd"
call "%temp%\mdtemp.cmd" > nul
if exist "%temp%\mdtemp.cmd" del "%temp%\mdtemp.cmd" > nul
if not "%DRIVESIZE%"=="0" goto :skipa
echo.
echo.
set /P A=WARNING: NO USB DRIVES DETECTED - DO YOU WANT TO LIST ALL THE DRIVES (Y/[N]) : 
if /I not "%A:~0,1%"=="Y" goto :exit
set ALL=ALLDRIVES
RMPARTUSB FIND %ALL% > "%temp%\mdtemp.cmd"
call "%temp%\mdtemp.cmd" 2> nul
if exist "%temp%\mdtemp.cmd" del "%temp%\mdtemp.cmd" > nul

:skipa
if "%DRIVESIZE%"=="0" echo. & echo NO USB DRIVES FOUND! & goto :exitbad
echo.
echo ERASE AND FORMAT USB DRIVE
echo ==========================
echo.
REM list all USB drives so user can see them and their drive number
RMPARTUSB LIST  %ALL% | %WINDIR%\System32\find.exe "DRIVE"
echo.
REM Ask user for a drive number
if "%DRIVE%"=="0" set DRIVE=1
set DD=
if "%AUTODRV%"=="" set /P DD=TARGET USB DRIVE NUMBER (e.g. %DRIVE%) : 
if not "%AUTODRV%"=="" set DD=%AUTODRV%
if "%DD%"=="" echo. & echo Please enter a number! & pause & cls & goto :skipa
set /A DD=%DD%+0
if "%DD%"=="0" echo. & echo Please enter a number above 0! & pause & cls & goto :skipa

:: Check user did not select this drive as the drive to format!
set TGTERR=ERROR: YOU ARE TRYING TO FORMAT THE SOURCE DRIVE (Drive %SRCDL%)!
if "%DD%"=="1" if /i "%DRIVE1LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="2" if /i "%DRIVE2LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="3" if /i "%DRIVE3LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="4" if /i "%DRIVE4LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="5" if /i "%DRIVE5LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="6" if /i "%DRIVE6LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="7" if /i "%DRIVE7LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="8" if /i "%DRIVE8LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="9" if /i "%DRIVE9LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="10" if /i "%DRIVE10LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="11" if /i "%DRIVE11LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="12" if /i "%DRIVE12LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="13" if /i "%DRIVE13LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="14" if /i "%DRIVE14LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="15" if /i "%DRIVE15LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="16" if /i "%DRIVE16LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="17" if /i "%DRIVE17LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="18" if /i "%DRIVE18LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa
if "%DD%"=="19" if /i "%DRIVE19LETTER%"=="%SRCDL%" cls & echo. & echo %TGTERR% & echo. & set AUTODRV=& goto :skipa

cls
echo.
REM execute RMPARTUSB (add SURE if you don't want the user prompt)
RMPARTUSB DRIVE=%DD% GETDRV %ALL% > "%temp%\mdtemp.cmd"
call "%temp%\mdtemp.cmd" > nul
if exist "%temp%\mdtemp.cmd" del "%temp%\mdtemp.cmd" > nul
if "%USBDRIVESIZE%"=="0" echo ERROR: NO DRIVE SIZE! & goto :exitbad
if "%USBDRIVESIZE%"=="" echo ERROR: NO DRIVE SIZE! & goto :exitbad

ver | %WINDIR%\System32\find.exe /i " XP " > nul && goto :skp4k
:: check if 4K sector drive
powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; [Console]::WriteLine('bytespersector  caption  description  Deviceid'); foreach($r in (Get-CimInstance -ClassName Win32_DiskDrive)) { [Console]::WriteLine(([string]$r.bytespersector+'  '+[string]$r.caption+'  '+[string]$r.description+'  '+[string]$r.Deviceid)) }" | %WINDIR%\System32\find.exe /i "DRIVE%DD%" > "%temp%\DD.tmp"
%WINDIR%\System32\find.exe "4096" "%temp%\DD.tmp" > nul
if not errorlevel 1 echo. & echo. & type "%temp%\DD.tmp" & echo. & echo SORRY: THIS DRIVE HAS 4K SECTORS AND IS NOT MBR BOOTABLE! & echo. & del "%temp%\DD.tmp" & goto :exitbad
if exist "%temp%\DD.tmp" del "%temp%\DD.tmp"
:skp4k

cls
echo.
echo.
RMPARTUSB LIST  %ALL% | %WINDIR%\System32\find.exe "DRIVE"
echo.
if "%DD%"=="0" echo WARNING: DRIVE 0 IS YOUR SYSTEM DRIVE!!! & goto :exitbad

if exist r.tmp del r.tmp
ver | %WINDIR%\System32\find.exe " XP " > nul && goto :skprem
powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; [Console]::WriteLine('deviceid  MediaType'); foreach($r in (Get-CimInstance -ClassName Win32_DiskDrive)) { [Console]::WriteLine(([string]$r.deviceid+'  '+[string]$r.MediaType)) }" | %WINDIR%\System32\find.exe "DRIVE%DD%" > r.tmp 2>nul
set DTYPE=UNKNOWN DISK TYPE (may be Fixed or Removable)!
set dt=
%WINDIR%\System32\find.exe /i "Removable" r.tmp > nul && set DTYPE=REMOVABLE DISK
%WINDIR%\System32\find.exe /i "hard" r.tmp > nul && set  DTYPE=FIXED DISK && set dt=1
%WINDIR%\System32\find.exe /i "Fixed" r.tmp > nul && set DTYPE=FIXED DISK && set dt=1
::type r.tmp
echo.
echo INFORMATION: Drive %DD% is a %DTYPE%
if exist r.tmp del r.tmp
:: make sure user sees message
:: if not "%1"=="AUTO" if "%dt%"=="1" pause
echo.

:skprem
echo.
echo WARNING: ALL PARTITIONS ON DRIVE %dd% WILL BE DESTROYED
echo.
echo Ignore any 'Format' pop-up forms - they will be automatically cancelled.
echo.
if not "%AUTODRV%"=="" set FMT=NTFS
if not "%AUTODRV%"=="" goto :cc1
:skprem1
set ask=x
set /p ask=Are you sure it is OK to format DRIVE %DD% (Y/[N]) : 
if /i "%ask:~0,1%"=="Y" goto :lpf
if /i not "%ask:~0,1%"=="N" goto :skprem1
goto :exit

:lpf
if "%DD%"=="0" goto :exit	
set FMT=NTFS
:cc1

:: get drive size
FOR /F "tokens=*" %%A IN ('RMPARTUSB DRIVE^=%dd% GETDRV %ALL%') DO %%A
:: reduce number to units of 100MB
if "%USBDRIVESIZE%"=="" goto :skpsz
set /a USBDSIZE=%USBDRIVESIZE:~0,-8%
if "%USBDSIZE%"=="0" goto :skpsz
echo %OSVERSION%
:: if fixed disk then we can have more than 1 partition
if "%dt%"=="1" goto :emode
:: if Win10 then we can have more than 1 partition
if not "%OSVERSION%"=="10.0" goto :noaske
:: if old WIN10 then we cannot have multiple partitions
set Build=
for /f "tokens=2 delims== " %%A in ('powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; foreach($r in (Get-CimInstance -ClassName Win32_OperatingSystem)) { [Console]::WriteLine(('BuildNumber='+[string]$r.BuildNumber)) }" ^| %WINDIR%\system32\find.exe "="') do set /A Build=%%A
if "%Build%"=="" goto :noaske
if "%Build%"=="0" goto :noaske
if %Build% LSS 15063 echo WARNING: WINDOWS 10 IS TOO OLD - IT DOES NOT SUPPORT MULTIPLE PARTITIONS ON USB FLASH DRIVES (Win 10 - Build %Build%) & pause & goto :noaske

:emode
cls
echo.
echo INFORMATION: Drive %DD% is a %DTYPE%
echo.
:: EXPERT MODE

echo SPECIFY PARTITION SIZES
echo =======================
echo.
set /a DSIZEGB=%USBDRIVESIZE:~0,-6%
:: DSIZEGB is actually in MiB/1000
:: Deliberately reduce size so user does not exceed total size of partitions
set /a DSIZEGB=%DSIZEGB% / 1074
::echo USB DRIVE IS %DSIZEGB%GB (approx.)
:: e.g. USBDRIVESIZE=64009128960  DSIZE=64  USBDSIZE=640 DSIZEGB=61  (size\1000\1024=62579  size\1024\1024=61103MiB  size\1024=‭62,570,018)
::echo USBDRIVESIZE=%USBDRIVESIZE% (units Bytes)
::echo DSIZEGB=%DSIZEGB%   (units 1000MiB)
::echo USBDSIZE=%USBDSIZE% (units 100MB)

if "%AUTO%"=="1" if %USBDSIZE% LSS 1374 goto :noaske

if %USBDSIZE% GEQ 1374 echo For best compatibility, maximum size of Partition 1 should be 128GiB
echo.
echo IMPORTANT: For UEFI booting, Partition 2 must be FAT32
echo.
echo Maximum partition size for FAT32 is 32GiB under Windows
echo Always create Partition 2 for best compatibility (even if very small)
echo.
if %USBDSIZE% LSS 1374 echo Note: Use Size=0 to set default partition sizes
echo.
echo USB drive is %DSIZEGB%GiB (approx.) - Partition 1 maximum 127GiB for best compatibility
echo.
set P1TYPE=NTFS
set P2SIZE=0
set P2TYPE=NTFS
set P3SIZE=0
set P3TYPE=NTFS
set ask=
echo PARTITION 1 NTFS
set /p       ask=Size                      (GiB) : 
if "%ask%"=="" goto :emode
set /a ask=%ask%+0
if "%ask%"=="0" if %USBDSIZE% LSS 1374 goto :noaske
if "%ask%"=="0" if %USBDSIZE% GEQ 1374 goto :emode
set /a P1SIZE=%ask%
echo %P1TYPE% %P1SIZE% (GiB)
if  %DSIZEGB% LSS %P1SIZE% echo *** ERROR: %P1SIZE% EXCEEDS DRIVE SIZE && echo.

echo.
set ask=1
echo PARTITION 2       (Recommend: 1-32GiB FAT32 - for use with agFM UEFI File Manager)
set /p       ask=Size (GiB) [0=none, 999=max, default=1] : 
set /a P2SIZE=%ask%+0
if "%P2SIZE%"=="" set P2SIZE=0
if "%P2SIZE%"=="0" goto :confirm
if not "%P2SIZE%"=="999" if %P2SIZE% LSS 33 echo Tip: Must use FAT32 for UEFI boot support (UEFI agFM/Ventoy)
if not "%P2SIZE%"=="999" if %P2SIZE% GEQ 33 set P2TYPE=NTFS& goto :skpp2
set P2TYPE=FAT32
set /p    P2TYPE=Type       [NTFS/FAT32] (N/[F]) : 
if /i "%P2TYPE:~0,1%"=="N" set P2TYPE=NTFS
if not "%P2TYPE%"=="NTFS" set P2TYPE=FAT32
:skpp2
echo %P2TYPE% %P2SIZE% (GiB)
if not "%P2SIZE%"=="999" if "%P2TYPE%"=="FAT32" if 32 LSS %P2SIZE% echo ERROR: FAT32 MAXIMUM IS 32GiB & pause & goto :emode
if "%P2SIZE%"=="999" if "%P2TYPE%"=="FAT32" echo WARNING: Formatting will fail if FAT32 partition exceeds 32GiB.
echo.
if "%P2SIZE%"=="999" goto :confirm
set /a P12=%P1SIZE% + %P2SIZE%
if  %DSIZEGB% EQU %P12% goto :confirm
if  %DSIZEGB% LSS %P12% echo *** ERROR: TOTAL EXCEEDS DRIVE SIZE? && echo.

set ask=0
echo PARTITION 3
set /p       ask=Use all remaining space ([Y]/N) : 
set P3SIZE=0
if /i "%ask:~0,1%"=="Y" set P3SIZE=MAX
if /i "%ask%"=="0" set P3SIZE=MAX
if "%P3SIZE%"=="0" goto :confirm
echo Tip: NTFS is recommended for Ptn3
set P3TYPE=NTFS
set /p    P3TYPE=Type       (NTFS/FAT32) ([N]/F) : 
if /i "%P3TYPE:~0,1%"=="F" set P3TYPE=FAT32
if not "%P3TYPE%"=="FAT32" set P3TYPE=NTFS
echo %P3TYPE% %P3SIZE% (GiB)
if not "%P3SIZE%"=="MAX" if "%P3TYPE%"=="FAT32" if 32 LSS %P3SIZE% echo ERROR: FAT32 MAXIMUM IS 32GiB & pause & goto :emode
if "%P3SIZE%"=="MAX" if "%P3TYPE%"=="FAT32" echo WARNING: Formatting will fail if FAT32 partition exceeds 32GiB.
echo.
:confirm
if /i "%P2SIZE%"=="999" set P2SIZE=MAX
echo.
echo Please confirm:
echo ===============
echo.
echo DISK %dd%   Size=%DSIZEGB%GiB (approx.)
echo.
echo Partition 1 = %P1TYPE% %P1SIZE% (GiB)
if not "%P2SIZE%"=="0" echo Partition 2 = %P2TYPE% %P2SIZE% (GiB)
if not "%P3SIZE%"=="0" echo Partition 3 = %P3TYPE% %P3SIZE% (GiB)
echo.
if "%P2SIZE%"=="0" echo WARNING: For best compatibility, you should create a Partition 2 or use Default option! & echo.
set ask=N
if "%P2SIZE%"=="0" set /p ask=Make partitions? [Yes/No/Default] [Y/[N]/D) : 
if not "%P2SIZE%"=="0" set /p ask=Make partitions? (Y/[N]) : 
if /i "%ask:~0,1%"=="D" goto :noaske
if /i not "%ask:~0,1%"=="Y" goto :emode

if "%dd%"=="0" echo ERROR! DISK 0 & goto :exitbad

if "%NOPSHELL%"=="" call powershell Stop-Service -Name ShellHWDetection > nul
echo.
echo ERASING AND FORMATTING DRIVE %DD% as %FMT%...
RMPARTUSB DRIVE=%dd% CLEAN %ALL% > nul
if errorlevel 1 (echo. & echo RMPARTUSB CLEAN COMMAND FAILED OR ABORTED BY USER OR PROTECTED BY ANTIVIRUS S/W & goto :exitbadAV)
REM delay to allow Windows to see empty drive
RMPARTUSB DRIVE=%DD% GETDRV %ALL% > nul
set /A PS1=%P1SIZE% * 1025
RMPARTUSB DRIVE=%dd% SIZE=%PS1% WINPE %FMT% 2PTN %ALL% SURE VOLUME=E2B> nul
if errorlevel 1 (echo NTFS FORMAT FAILED! Format as FAT32 first, close all other applications and ensure Windows has given it a drive letter. & goto :exitbadAV)
set USBDRIVELETTER=
REM get the drive letter of the newly formatted drive
FOR /F "tokens=*" %%A IN ('RMPARTUSB DRIVE^=%dd% GETDRV %ALL%') DO %%A
If "%USBDRIVELETTER%"=="" (echo FAILED! No drive letter was given by Windows!& goto :exitbad)
echo RMPartUSB Format completed OK (%USBDRIVELETTER%)
:: Check we will select correct disk - new USB drive should have a 31K partition
(echo sel disk %DD% & echo list part) | diskpart > "%temp%\diskpart.scr"
%WINDIR%\system32\find.exe /i " 31 " "%temp%\diskpart.scr" > nul || (echo Error: E2B Partition 2 not found! & pause & goto :skipe2)

:: delete small 2nd partition that was made by RMPartUSB
echo SELECT DISK %DD% > "%temp%\diskpart.scr"
echo SELECT DISK %DD% >> "%temp%\diskpart.scr"
echo LIST DISK >> "%temp%\diskpart.scr"
echo SEL PART 2 >> "%temp%\diskpart.scr"
echo DEL PART OVERRIDE >> "%temp%\diskpart.scr"
echo EXIT >> "%temp%\diskpart.scr"
:: check script selects correct disk
%WINDIR%\system32\find.exe /i  "SELECT DISK %DD%" "%temp%\diskpart.scr" > nul || goto :skip_p2
echo Creating and formatting extra partitions...
diskpart /s "%temp%\diskpart.scr" > nul

:: get free drive letters
call :getfree

:: create Ptn2 (and Ptn3 if requested)
echo SELECT DISK %DD% > "%temp%\diskpart.scr"
echo SELECT DISK %DD% >> "%temp%\diskpart.scr"
echo LIST DISK >> "%temp%\diskpart.scr"
if not "%P2SIZE%"=="0" if not "%P2SIZE%"=="MAX" set /A PS2=%P2SIZE% * 1024
if not "%P2SIZE%"=="0" if not "%P2SIZE%"=="MAX" echo CREATE PART PRI SIZE=%PS2% >> "%temp%\diskpart.scr"
if "%P2SIZE%"=="MAX" echo CREATE PART PRI >> "%temp%\diskpart.scr"
if not "%P2SIZE%"=="0" echo SEL PART 2 >> "%temp%\diskpart.scr"
if not "%P2SIZE%"=="0" echo FORMAT FS=%P2TYPE% LABEL="E2B_PTN2" QUICK >> "%temp%\diskpart.scr"
if not "%P2SIZE%"=="0" echo ASSIGN %FREE2% >> "%temp%\diskpart.scr"
if "%P3SIZE%"=="MAX" echo CREATE PART PRI >> "%temp%\diskpart.scr"
if "%P3SIZE%"=="MAX" echo SEL PART 3 >> "%temp%\diskpart.scr"
if "%P3SIZE%"=="MAX" echo FORMAT FS=%P3TYPE% LABEL="E2B_PTN3" QUICK >> "%temp%\diskpart.scr"
if "%P3SIZE%"=="MAX" echo ASSIGN %FREE3% >> "%temp%\diskpart.scr"
echo LIST VOL >> "%temp%\diskpart.scr"
echo EXIT >> "%temp%\diskpart.scr"

:: check script selects correct disk
%WINDIR%\system32\find.exe /i  "SELECT DISK %DD%" "%temp%\diskpart.scr" > nul || goto :skip_p2
diskpart /s "%temp%\diskpart.scr" > nul

:skipe2
if exist "%temp%\diskpart.scr" del "%temp%\diskpart.scr" > nul
:: show new partitions (even if not in English)
echo.
(echo sel disk %DD% & echo list part) | diskpart
popd

goto :copy_files










:: NON-EXPERT MODE

:noaske
cls
echo.
echo INFORMATION: Drive %DD% is a %DTYPE%
echo.
:: test for 137.4 GB
if %USBDSIZE% LSS 1374 goto :skpsz
if not "%AUTOSIZE%"=="" goto :skpsz
echo.
echo WARNING: USB Drive is larger than 128GiB
echo For best compatibility, maximum size of Partition 1 should be 128GiB
echo.
set /p ask=Reduce partition 1 size to 128GiB and create large 2nd partition ([Y]/N) : 
if /i not "%ask:~0,1%"=="N" set AUTOSIZE=131000
echo Partition 1 = 128GiB

:skpsz
:: Allow at least 500MB for FAT32 UEFI partition if user wants to make new partition
:: Must reduce number to 32-bit signed integer - convert to MB
if "%USBDSIZE%"=="0" echo BAD DRIVE SIZE & goto :exitbad
set /a DSIZEMB=%USBDRIVESIZE:~0,-4%/105
if "%DSIZEMB%"=="0" echo BAD DRIVE SIZE & goto :exitbad
:: echo AUTOSIZE=%AUTOSIZE% USBDRIVESIZE=%USBDRIVESIZE% USBDSIZE=%USBDSIZE% DSIZEMB=%DSIZEMB%
if "%AUTOSIZE%"=="" set AUTOSIZE=%DSIZEMB%
if /i "%AUTOSIZE%"=="MAX" set AUTOSIZE=%DSIZEMB%
set /a AUTOSIZE=%AUTOSIZE%-500
echo PTN1: %AUTOSIZE%MB
echo.
echo ERASING AND FORMATTING DRIVE %DD% as %FMT%...
if "%NOPSHELL%"=="" call powershell Stop-Service -Name ShellHWDetection > nul
RMPARTUSB DRIVE=%dd% CLEAN %ALL% > nul
if errorlevel 1 (echo. & echo RMPARTUSB CLEAN COMMAND FAILED OR ABORTED BY USER - IF ERROR TRY AGAIN! & goto :exitbad)
REM delay to allow Windows to see empty drive
RMPARTUSB DRIVE=%DD% GETDRV %ALL% > nul

if "%AUTOSIZE%"==""     RMPARTUSB DRIVE=%dd% WINPE %FMT% 2PTN %ALL% SURE VOLUME=E2B> nul
if not "%AUTOSIZE%"=="" RMPARTUSB DRIVE=%dd% SIZE=%AUTOSIZE% WINPE %FMT% 2PTN %ALL% SURE VOLUME=E2B> nul

if "%FMT%"=="NTFS" if errorlevel 1 (echo NTFS FORMAT FAILED! Format as FAT32 first, close all other applications and ensure Windows has given it a drive letter. & goto :exitbad)
if errorlevel 1 (echo RMPARTUSB COMMAND FAILED! Ensure Windows has given it a drive letter. & goto :exitbad)
set USBDRIVELETTER=
REM get the drive letter of the newly formatted drive
FOR /F "tokens=*" %%A IN ('RMPARTUSB DRIVE^=%dd% GETDRV %ALL%') DO %%A
If "%USBDRIVELETTER%"=="" (echo FAILED! No drive letter was given by Windows!& goto :exitbad)
echo Format completed OK (%USBDRIVELETTER%)

REM EXPAND2 can be set by calling cmd file
::if "%EXPAND2%"=="EXPAND2" goto :expand
::if "%AUTOSIZE%"=="" goto :skip_p2
::if "%USBDSIZE%"=="" goto :skip_p2
::if %USBDSIZE% LSS 1374 goto :skip_p2

:expand
:: Now delete ptn2 and create max ptn2 and format remainder if large drive
:: Check we will select correct disk - new USB drive should have a 31K partition
(echo sel disk %DD% & echo list part) | diskpart > "%temp%\diskpart.scr"
%WINDIR%\system32\find.exe /i  " 31 " "%temp%\diskpart.scr" > nul || goto :skip_p2

if exist "%temp%\diskpart.scr" del "%temp%\diskpart.scr" > nul
echo SELECT DISK %DD% > "%temp%\diskpart.scr"
echo SELECT DISK %DD% >> "%temp%\diskpart.scr"
echo LIST DISK >> "%temp%\diskpart.scr"
echo SEL PART 2 >> "%temp%\diskpart.scr"
echo DEL PART OVERRIDE >> "%temp%\diskpart.scr"
echo EXIT >> "%temp%\diskpart.scr"
:: check script selects correct disk
%WINDIR%\system32\find.exe /i  "SELECT DISK %DD%"  "%temp%\diskpart.scr" > nul || goto :skip_p2
diskpart /s "%temp%\diskpart.scr" > nul
if exist "%temp%\diskpart.scr" del "%temp%\diskpart.scr" > nul

:: get free drive letters
call :getfree

::echo AUTOSIZE=%AUTOSIZE% USBDRIVESIZE=%USBDRIVESIZE% USBDSIZE=%USBDSIZE% DSIZEMB=%DSIZEMB%
set /A FREE=%DSIZEMB%-%AUTOSIZE%
set FS=
if %FREE% LSS 32000 set FS=FS=FAT32
if exist "%temp%\diskpart.scr" del "%temp%\diskpart.scr" > nul
echo SELECT DISK %DD% > "%temp%\diskpart.scr"
echo SELECT DISK %DD% >> "%temp%\diskpart.scr"
echo LIST DISK >> "%temp%\diskpart.scr"
::echo SEL PART 2 >> "%temp%\diskpart.scr"
::echo DEL PART OVERRIDE >> "%temp%\diskpart.scr"
echo CREATE PART PRI >> "%temp%\diskpart.scr"
echo SEL PART 2 >> "%temp%\diskpart.scr"
echo FORMAT %FS% LABEL="E2B_PTN2" QUICK >> "%temp%\diskpart.scr"
echo ASSIGN %FREE2% >> "%temp%\diskpart.scr"
echo LIST VOL >> "%temp%\diskpart.scr"
echo EXIT >> "%temp%\diskpart.scr"
:: check script selects correct disk
%WINDIR%\system32\find.exe /i  "SELECT DISK %DD%"  "%temp%\diskpart.scr" > nul || goto :skip_p2
if %FREE% LSS 32000 echo Formatting Partition 2 as FAT32... || echo Formatting Partition 2...
:: type "%temp%\diskpart.scr"
diskpart /s "%temp%\diskpart.scr" > nul && echo Partition 2 "E2B_PTN2" created
if exist "%temp%\diskpart.scr" del "%temp%\diskpart.scr" > nul

:skip_p2

:: show new partitions (even if not in English)
echo.
(echo sel disk %DD% & echo list part) | diskpart

popd

:copy_files
color 1f
:: ensure ShellHWDetection is enabled
if "%NOPSHELL%"=="" call powershell Start-Service -Name ShellHWDetection > nul
REM ===== COPY FILES ===========
if not exist ..\..\..\menu.lst exit
echo.
echo INFORMATION: Some Anti-Virus programs (e.g. Trend Micro AV, MalwareBytes) may cause this copy phase to fail!
echo.
echo Copying Easy2Boot files in \     to %USBDRIVELETTER% ...
REM Only copy files in root, no subdirs; System Volume Information & $RECYCLE.BIN case problems with /herky
xcopy /chrky ..\..\..\*.* %USBDRIVELETTER%\*.*
if errorlevel 1 echo ERROR IN COPYING FILES! Possibly blocked by AntiVirus? & goto :exitbadAV

REM Copy _ISO subdir
echo Copying files to %USBDRIVELETTER%\_ISO\ folder - please wait...
::goto :skpcopy
xcopy /herky ..\..\..\_ISO\*.* %USBDRIVELETTER%\_ISO\*.* /EXCLUDE:exclude_ISO.txt > nul
echo.
if errorlevel 1 echo ERROR IN COPYING FILES. Possibly blocked by AntiVirus? & goto :exitbadAV
:skpcopy

REM ==== END OF COPY FILES ===


:: copy correct bootmgr for NTBOOT if present (doesn't seem to work if do it later!)
:: Windows 10 bootmgr gives BCD error so don't use it if possible!
if not exist %USBDRIVELETTER%\_ISO\e2b\grub\DPMS\NTBOOT.MOD\bootmgr call :copybmgr C:\bootmgr
if "%GD%"=="" call :copybmgr %SystemRoot%\Panther\Rollback\bootmgr
if "%GD%"=="" call :copybmgr %SystemRoot%\Boot\PCAT\bootmgr

pushd "%WF%"
if "%dd%"=="0" exit

REM install grub4dos - use new grubinst to install to PBR
echo Installing grub4dos to PBR of %USBDRIVELETTER%...
set GR=grubinst.exe
REM check if silent-boot supported
if exist gr.txt del gr.txt
if exist gr1.txt del gr1.txt
%GR% -h 2> gr.txt
set SILENT=
%WINDIR%\System32\find.exe "--silent-boot" gr.txt > nul
if not errorlevel 1 set SILENT=--silent-boot
if "%SILENT%"=="" set GR=grubinst_new.exe

if not exist %GR% echo ERROR: %GR% not found or is an old version! & goto :exitbad

REM Dismount the drive, run grubinst, remount the drive
"%~dp0LockDismount.exe" -force %dd% %GR% -t=0 %SILENT% --install-partition=0 (hd%dd%) >> gr1.txt
if errorlevel 1 goto :exitbad

REM also install to MBR
echo.
echo Installing grub4dos to MBR of %USBDRIVELETTER%...
::set GR=grubinst.exe
"%~dp0LockDismount.exe" -force %dd% %GR% -t=0 %SILENT% --skip-mbr-test (hd%dd%) >> gr1.txt
if errorlevel 1 goto :exitbadAV

if exist gr.txt del gr.txt
if exist gr1.txt del gr1.txt

popd

REM if it is not FAT32 then no point in having EFI folder for UEFI booting
if not "%FMT%"=="FAT32" if exist %USBDRIVELETTER%\EFI\nul rd /s /q %USBDRIVELETTER%\EFI > nul

REM delete this batch file from the USB drive
::echo Deleting %USBDRIVELETTER%\_ISO\docs\%~n0%~x0
::if exist %USBDRIVELETTER%\_ISO\docs\%~n0%~x0 del %USBDRIVELETTER%\_ISO\docs\%~n0%~x0

if exist %USBDRIVELETTER%\UPDATE_E2B_DRIVE.CMD del %USBDRIVELETTER%\UPDATE_E2B_DRIVE.CMD
::if exist "%USBDRIVELETTER%\MAKE_E2B_USB_DRIVE (run as admin).cmd" del "%USBDRIVELETTER%\MAKE_E2B_USB_DRIVE (run as admin).cmd"
if exist %USBDRIVELETTER%\E2B_ReadMe.txt del %USBDRIVELETTER%\E2B_ReadMe.txt
if exist "%USBDRIVELETTER%\MAKE_E2B.exe" del "%USBDRIVELETTER%\MAKE_E2B.exe"

REM Make new user MyE2B.cfg file
if not exist %USBDRIVELETTER%\_ISO\MyE2B.cfg call "%~dp0Make_MyE2B.cfg.cmd" %USBDRIVELETTER%

TITLE %~n0 %E2BVER%
echo.
echo Now add your ISOs and other payload files
echo =========================================
echo.
echo \_ISO\MAINMENU      - copy ISOs here for Main Menu (except Windows Install ISOs)
echo \_ISO\LINUX         - copy linux ISOs here
echo \_ISO\WINDOWS\WIN8  - copy Windows 8  Install ISOs here
echo \_ISO\WINDOWS\WIN10 - copy Windows 10 Install ISOs here
echo.
echo Hirens HBCD ISO     - use .isoHW (DLC), .isowinvh (HBCD) or .isofira01 (Strelec) file extension
echo For information on over 300 payloads files, see www.easy2boot.xyz - 'List of tested ISOs' page.
echo.
echo UEFI
echo ====
echo For UEFI bootable payloads, you can first convert each ISO to a .imgPTN file,
echo using the MPI Tool Pack, and then copy the .imgPTN file to the E2B USB drive.
echo.
echo An alternative is to add the a1ive grub2 File Manager (agFM) EFI files to the FAT32 partition 2.
echo Using E2B+agFM you can directly boot from .ISO, .WIM, .VHD, and .IMG files.
echo See www.easy2boot.xyz/agfm/  for more details about agFM.
echo.

:: if not correct bootmgr and we have internet connection, download bootmgr
if not exist %USBDRIVELETTER%\_ISO\e2b\grub\DPMS\NTBOOT.MOD\bootmgr (
if "%internet%"=="1" GWT -range:8808448-9236127 -out:"%USBDRIVELETTER%\_ISO\e2b\grub\DPMS\NTBOOT.MOD\bootmgr" -title:"Downloadinf Win8.1 Bootmgr" -link:/download/B/9/9/B999286E-0A47-406D-8B3D-5B5AD7373A4A/9600.16384.WINBLUE_RTM.130821-1623_X86FRE_ENTERPRISE_EVAL_EN-US-IRM_CENA_X86FREE_EN-US_DV5.ISO -silent
)


if not exist %USBDRIVELETTER%\_ISO\e2b\grub\DPMS\NTBOOT.MOD\bootmgr (
	echo.
	echo WARNING: Compatible version of bootmgr for booting .VHD\.WIM files was not found.
	echo Download and run Add_Bootmgr_to_E2B.exe to add the correct version of Bootmgr to your E2B drive.
	echo.
)

if not "%AUTODRV%"=="" goto :KK

echo.
setlocal enableextensions enabledelayedexpansion

if exist %USBDRIVELETTER%\_ISO\CONTIG.ISO (
echo \_ISO\CONTIG.ISO
echo ================
echo.
dir  %USBDRIVELETTER%\_ISO\CONTIG.iso | %WINDIR%\System32\find.exe /i "CONTIG.ISO"
echo.
echo \_ISO\CONTIG.ISO is a large empty file which is only used
echo                  if your linux ISOs are not contiguous.
echo.
echo nnnn  = Size in MB
echo 0     = Delete CONTIG.ISO
echo ENTER = Keep   CONTIG.ISO *Recommended
echo.
set ask=K
if exist %USBDRIVELETTER%\_ISO\CONTIG.ISO  set /p ask="CONTIG.ISO size (0=Delete, Size or ENTER=Keep) (MB) [e.g. 800] : "
if "!ask!"=="K" goto :KK
if exist %USBDRIVELETTER%\_ISO\CONTIG.ISO del %USBDRIVELETTER%\_ISO\CONTIG.ISO /q
set /a ask=!ask!+0
if !ask! GEQ 1 fsutil file createnew %USBDRIVELETTER%\_ISO\CONTIG.ISO !ask!000000
) else (
echo Make \_ISO\CONTIG.ISO file?
echo ===========================
echo.
echo \_ISO\CONTIG.ISO is a large empty file which is only used
echo                    when your linux ISO is not contiguous.
echo.
echo nnnn  = Size in MB
echo 0     = No CONTIG.ISO
echo.
set ask=K
set /p ask="Set CONTIG.ISO size ([0]=None) (MB) [e.g. 500] : "
if "!ask!"=="K" goto :KK
if "!ask:~0,1!"=="0" goto :KK
set /a ask=!ask!+0
if !ask! GEQ 1 fsutil file createnew %USBDRIVELETTER%\_ISO\CONTIG.ISO !ask!000000
)

:KK
echo.
if exist %USBDRIVELETTER%\_ISO\CONTIG.ISO dir  %USBDRIVELETTER%\_ISO\CONTIG.iso | %WINDIR%\System32\find.exe /i "CONTIG.ISO"
if not exist %USBDRIVELETTER%\_ISO\CONTIG.ISO echo CONTIG.ISO is not present.
echo.

:JJ

:: ===== Add agFM and Ventoy ======
echo.
echo =================== agFM and Ventoy - DOWNLOAD AND COPY UEFI BOOT FILES TO PARTITION 2 =====================
echo.
echo Checking for agFM and Ventoy compatibility (requires PTN2=FAT and 60MB+, Windows 10 or USB HDD, internet connectivity)
if "%internet%"=="" echo ERROR: No Internet connection detected!&&goto :JJ1
echo Internet OK
if exist agFM_download_files.zip del agFM_download_files.zip
set PTN2=
set PTN2FREE=0
set PTN2FS=

:: get partition 2 of this disk using diskpart
(echo sel disk %DD% & echo sel part 2 & echo list vol & echo exit) | diskpart | %WINDIR%\system32\find.exe /i "*" > "%temp%\diskpart.scr"
for /f "tokens=4" %%d in (%temp%\diskpart.scr) do set DLP2=%%d:
for /f "tokens=2 delims==" %%d in ('powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; foreach($r in (Get-CimInstance -ClassName Win32_LogicalDisk -Filter ('Name='+[char]39+'%DLP2%'+[char]39))) { [Console]::WriteLine(('name='+[string]$r.name)) }"') do set PTN2=%%d
if /i not "%DLP2%"=="%PTN2%" echo ERROR: Cannot determine drive letter of Partition 2, Drive %DD% [%PTN2% or %DLP2%?] & echo Please use Windows 10 or a USB Fixed disk - Windows %OSVERSION% detected & pause & goto :JJ1
echo Partition 2 is %PTN2%
if not "%PTN2:~1,2%"==":" goto :JJ1
set DLP2=

for /f "tokens=2 delims==" %%d in ('powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; foreach($r in (Get-CimInstance -ClassName Win32_LogicalDisk -Filter ('Name='+[char]39+'%PTN2%'+[char]39))) { [Console]::WriteLine(('filesystem='+[string]$r.filesystem)) }"') do set PTN2FS=%%d
:: check if running Win7/8/XP and cannot access 2nd ptn on flash drive...
if "%PTN2FS%"=="" goto :JJ1
echo Partition 2 (%PTN2%) is %PTN2FS%
if /i not "%PTN2FS:~0,3%"=="FAT" goto :JJ1
for /f "tokens=2 delims==" %%d in ('powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; foreach($r in (Get-CimInstance -ClassName Win32_LogicalDisk -Filter ('Name='+[char]39+'%PTN2%'+[char]39))) { [Console]::WriteLine(('freespace='+[string]$r.freespace)) }"') do set PTN2FREE=%%d
:: next line is fix for extra invisible character appended to string by wmic!!! DO NOT DELETE!!!
set PTN2FREE=%PTN2FREE%
set PTN2FREE=%PTN2FREE:~0,-6%
set /a PTN2FREE=%PTN2FREE%+0
echo Partition 2 has %PTN2FREE%MB free (must have over 60MB free)
:: must be over 60MB free
if %PTN2FREE% LSS 60 goto :JJ1

echo Note: Some UEFI systems may not MBR-boot to the E2B Menu system if you add these UEFI boot files.
echo Ventoy requires agFM to be installed first.
echo.
set ask=Y
set /p ask=Add a1ive grub2 File Manager UEFI boot files to Partition 2? ([Y]/N) : 
if /i not "%ask:~0,1%"=="Y" goto :JJ1

:: agFM_download_files.zip
echo.
echo Downloading current agFM zip file - please wait...
set outfile=agFM_download_files.zip
set approx_size=29

set url=https://easy2boot.xyz/wp-content/uploads/downloads/agFM_download_files.zip
call :download
if "%ERR%"=="3" call :download
if "%ERR%"=="" goto gotfile

set url=http://easy2boot.xyz/wp-content/uploads/downloads/agFM_download_files.zip
call :download
if "%ERR%"=="3" call :download
if "%ERR%"=="" goto gotfile


if NOT "%ERR%"=="" echo ERROR: Failed to download agFM files & color 4f & pause & goto :eof

:gotfile

if not exist agFM_download_files.zip echo WARNING: Failed to download agFM files from E2B website. & goto :exitbad
echo File obtained from %url%
echo Extracting a1ive grub2 UEFI boot files to %PTN2%...
7z.exe  x -y agFM_download_files.zip -o%PTN2%\  > nul
if exist agFM_download_files.zip del agFM_download_files.zip


:AG1
echo.
if not exist %PTN2%\EFI echo ERROR: UEFI file copy to Partition 2 failed! & goto :exitbad
if exist %PTN2%\EFI\BOOT\BOOTX64.EFI echo E2B USB Drive is now MBR and UEFI-bootable.

if not exist "%PTN2%\e2b\Update agFM\Update_to_latest_Ventoy_version.cmd" goto :JJ2
echo.
echo VENTOY - the new Legacy\UEFI multiboot menu system (www.ventoy.net)
echo ===================================================================
echo.
echo Tip: I strongly recommend that you add Ventoy as an alternative menu system
echo.
set ask=Y
set /p ask=Download and add 'Ventoy for E2B'? ([Y]/N) : 
if /i "%ask:~0,1%"=="Y" call "%PTN2%\e2b\Update agFM\Update_to_latest_Ventoy_version.cmd"
goto :JJ2

:JJ1
@echo off
echo.
echo ****************************************************************
echo *     UEFI BOOT FILES NOT ADDED (Windows 10 is required)       *
echo *                                                              *
echo * To add the UEFI boot files, please visit:                    *
echo * www.easy2boot.xyz/agfm/                                      *
echo *                                                              *
echo ****************************************************************

:JJ2
@echo off
echo.
color 2f
echo FINISHED
echo Please use "\E2B Launcher.exe" on the USB drive to configure your USB drive.
echo.
echo Press W + [ENTER] for instructions on agfm and UEFI booting.
set ask=
set /p ask=Press ENTER to continue... 
if /i "%ask%"=="W" start /B https://www.easy2boot.xyz/agfm/ 
goto :exit

:: --------------------- SUBROUTINES -------------


:check_Permissions
   :: net session >nul 2>&1
   :: sfc 2>&1 | %WINDIR%\System32\find.exe /i "/SCANNOW"
    setlocal enabledelayedexpansion
    fsutil dirty query %systemdrive% >nul
    if not errorLevel 1 (
        echo Administrative permissions confirmed.
    ) else (
        echo Sorry - you need to run as Administrator [use right-click - Run as administrator].
		echo.
		echo If you ran as Administrator, please check your PATH environment variable includes the Windows\system32 folder.
		echo.
		echo PATH VARIABLE = "!PATH!"
	echo.
	color cf
	pause
	Set ADMIN=FAIL
    )
	endlocal
goto :eof


:checkperms
set randname=%random%%random%%random%%random%%random%
md "%windir%\%randname%" 2>nul
if %errorlevel%==0 (echo Administrative permissions confirmed.
goto end)
if %errorlevel%==1 (
    echo Sorry - you need to run as Administrator [use right-click - Run as administrator].
	echo.
	color cf
	pause
	Set ADMIN=FAIL
	goto end)
goto checkperms
:end
rd "%windir%\%randname%" 2>nul
goto :eof


:copybmgr
:: %1 has file spec
set GD=
if "%~z1"=="" goto :EOF
if %~z1==389720 set GD=1
if %~z1==398144 set GD=1
if %~z1==398156 set GD=1
if %~z1==398356 set GD=1
if %~z1==400517 set GD=1
if %~z1==403390 set GD=1
if %~z1==404250 set GD=1
if %~z1==409154 set GD=1
if %~z1==427680 set GD=1
if "%GD%"=="1" xcopy /yh %~1 %USBDRIVELETTER%\_ISO\e2b\grub\DPMS\NTBOOT.MOD > nul
if "%GD%"=="1" attrib -s -h -r %USBDRIVELETTER%\_ISO\e2b\grub\DPMS\NTBOOT.MOD\bootmgr
goto :EOF

:getOS
setlocal
for /f "tokens=2 delims=[]" %%i in ('ver') do set OSVERSION=%%i
for /f "tokens=2-3 delims=. " %%i in ("%OSVERSION%") do set OSVERSION=%%i.%%j
set NOPSHELL=
if "%OSVERSION%" == "5.00" echo Windows 2000 detected & set NOPSHELL=1
if "%OSVERSION%" == "5.0" echo Windows 2000 detected & set NOPSHELL=1
if "%OSVERSION%" == "5.1" echo Windows XP detected & set NOPSHELL=1
if "%OSVERSION%" == "5.2" echo Windows Server 2003 detected & set NOPSHELL=1
if "%OSVERSION%" == "6.0" echo Windows Vista detected & set NOPSHELL=1
if "%OSVERSION%" == "6.1" echo Windows 7 detected
if "%OSVERSION%" == "6.2" echo Windows 8 detected
if "%OSVERSION%" == "6.3" echo Windows 8.1 detected
if "%OSVERSION%" == "6.4" echo Windows 10 detected
if "%OSVERSION%" == "10.0" echo Windows 10 detected
endlocal & set OSVERSION=%OSVERSION%& set NOPSHELL=%NOPSHELL%
:: powershell.exe should be in environment path...
for %%i in (powershell.exe) do if "%%~$path:i"=="" set NOPSHELL=1
goto :eof

:getsize
REM Get size of file on MB
set size=%~z1
set size=%size:~,-6%
if "%size%"=="" set size=0
goto :EOF

:download
echo Trying %url%
set ERR=
if exist %outfile% del %outfile%
if not exist %outfile% wget.exe --no-check-certificate -q --show-progress -t 1 -T 3 %url% -O%outfile% || del %outfile% && set ERR=1&& goto :EOF
if not exist %outfile% set ERR=2&& goto :EOF
call :getsize %outfile%
if %size% LSS %approx_size% echo ERROR: Incomplete file (%size%MB) && set ERR=3&& goto :EOF
goto :EOF

:exitbadAV
echo.
call :DisplayAV

:exitbad
if "%NOPSHELL%"=="" call powershell Start-Service -Name ShellHWDetection > nul
color 4f
pause
exit

:exit
if "%NOPSHELL%"=="" call powershell Start-Service -Name ShellHWDetection > nul
exit


:DisplayAV
REM CheckAv by SSi 2021-07-09
echo.
SETLOCAL EnableDelayedExpansion
powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; foreach($r in (Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct)) { foreach($p in @('displayName','productState','pathToSignedReportingExe')) { [Console]::WriteLine(($p+'='+[string]$r.$p)) } }" 2> nul|findstr "displayName productState pathToSignedReportingExe" > t.txt 2> nul
powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; foreach($r in (Get-CimInstance -Namespace root/SecurityCenter2 -ClassName FirewallProduct)) { foreach($p in @('displayName','productState','pathToSignedReportingExe')) { [Console]::WriteLine(($p+'='+[string]$r.$p)) } }" 2> nul|findstr "displayName productState pathToSignedReportingExe" >> t.txt 2> nul
powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; foreach($r in (Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiSpywareProduct)) { foreach($p in @('displayName','productState','pathToSignedReportingExe')) { [Console]::WriteLine(($p+'='+[string]$r.$p)) } }" 2> nul|findstr "displayName productState pathToSignedReportingExe" >> t.txt 2> nul

if exist t1.txt del t1.txt
for /f "tokens=2 delims=^=" %%G in (t.txt) do echo %%G>> t1.txt
set count=0
set File2Read=t1.txt
for /f "tokens=* delims=;#" %%a in ('Type "%File2Read%"') do (
    set /a count+=1
	set "Line[!count!]=%%a"
)
if exist t.txt del t.txt
if exist t1.txt del t1.txt
REM  Line[1] is name, Line[2] is state number

For /L %%i in (1,3,%count%) do (
	set L=!Line[%%i]!
REM Remove cr at end of string
	echo                  --- !L:~,-1! --- 
	if "%%i"=="1"  call :PrintStat !Line[3]! "!Line[2]!"
	if "%%i"=="4"  call :PrintStat !Line[6]! "!Line[5]!"
	if "%%i"=="7"  call :PrintStat !Line[9]! "!Line[8]!"
	if "%%i"=="10" call :PrintStat !Line[12]! "!Line[11]!"
	if "%%i"=="13" call :PrintStat !Line[15]! "!Line[14]!"
	if "%%i"=="16" call :PrintStat !Line[18]! "!Line[17]!"
	if "%%i"=="19" call :PrintStat !Line[21]! "!Line[20]!"
	if "%%i"=="22" call :PrintStat !Line[24]! "!Line[23]!"
	if "%%i"=="25" call :PrintStat !Line[27]! "!Line[26]!"
	echo.
)
ENDLOCAL
goto :EOF

:PrintStat
set L=%~2 & echo !L:~,-1!
REM set /p dec=Enter productState decimal value to detect state:
call cmd /c exit /b %1
set "hex=%=exitcode%"
set "hex=%hex:~2%"
set "byte1=%hex:~0,2%"&set "byte2=%hex:~2,2%"&set "byte3=%hex:~4,2%"
echo State=%1 (dec) : %byte1%-%byte2%-%byte3% (hex)
:: Check byte1
:: bit 1 = firewall, 2=autoupdate, 4=AV, 8=antispyware, 10=internet settings, 20=user access control, 40=provider service
    set "status1="
    if "%byte1%"=="00" set "status1=NONE"
	set /A "A = 0x%byte1% & 0x01
    if %A% EQU 1 set "status1= FIREWALL"
	set /A "A = 0x%byte1% & 0x04
    if %A% EQU 4 set "status1=%status1% ANTIVIRUS"
	set /A "A = 0x%byte1% & 0x08
    if %A% EQU 8 set "status1=%status1% ANTISPYWARE"
	set /A "A = 0x%byte1% & 0x10
    if %A% EQU 0x10 set "status1=%status1% INTERNET"
	set /A "A = 0x%byte1% & 0x20
    if %A% EQU 0x20 set "status1=%status1% USER_ACCNT_CTRL"
	set /A "A = 0x%byte1% & 0x40
    if %A% EQU 0x40 set "status1=%status1% SERVICE"
	set /A "A = 0x%byte1% & 0x02
    if %A% EQU 2 set "status1=%status1%, AUTOUPDATED"

    set "status2=UNKNOWN"
    set /A "A = 0x%byte2% & 0x18
    if %A% EQU 0 set "status2=***disabled***"
    if %A% EQU 8 set "status2=***expired***"
    if %A% EQU 0x10 set "status2=ENABLED"
    if %A% EQU 0x18 set "status2=***snoozed***"

:: Check byte3 - bit 10h = outdated
    set "status3=UP-TO-DATE"
    set /A "A = 0x%byte3% & 0x10
    if %A% EQU 0x10 set "status3=OUT-OF-DATE"

echo Type of antivirus  :%status1%
echo Scanning status    : %status2%
echo Virus definitions  : %status3%
goto :EOF

:getfree
REM get next two free drive letters - set FREE2 and FREE3 for use in DISKPART ASSIGN command
setlocal enableDelayedExpansion
set FREE2=
set FREE3=
set "drives=DEFGHIJKLMNOPQRSTUVWXYZ"
for /f "delims=:" %%A in ('powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; [Console]::WriteLine('caption'); foreach($r in (Get-CimInstance -ClassName Win32_LogicalDisk)) { [Console]::WriteLine(([string]$r.caption)) }"') do set "drives=!drives:%%A=!"
::echo all unused letters = "%drives%"
::echo first unused letter = "%drives:~0,1%"
::echo 2nd unused letter =   "%drives:~1,1%"
if not "%drives:~0,1%"=="" set "FREE2=LETTER %drives:~0,1%"
if not "%drives:~2,1%"=="" set "FREE3=LETTER %drives:~1,1%"
::set FREE
ENDLOCAL & set FREE2=%FREE2% & set FREE3=%FREE3%
goto :EOF

