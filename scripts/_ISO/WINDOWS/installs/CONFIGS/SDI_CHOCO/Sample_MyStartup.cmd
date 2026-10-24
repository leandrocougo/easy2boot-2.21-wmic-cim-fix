:: Environment variables that are already available:
:: %USB% is the USB drive - e.g. D:  NOTE: IT MAY BE DISCONNECTED BY NOW!
:: %BIT% will either be X86 or AMD64
:: %WINVER% will be 7 or 8 or 10 or 11
:: %log% will be the log file
:: %errlog% will be a log file to record errors
:: %systemdrive%\DRIVERS folder will hold all files that were in %USB%\_ISO\WINDOWS\INSTALLS\CONFIGS\SDI_CHOCO

ECHO %0 RUNNING >> %LOG%

echo WINVER: [%WINVER%]
echo BIT: [%BIT%]
:: use loganddisplay to show the console text output of any command and then append to log file (e.g. dir C:\  %loganddisplay%)
set loganddisplay= ^> %~n0_temp.txt 2^>^&1 ^& type %~n0_temp.txt ^>^> %log% ^& type %~n0_temp.txt ^& del /Q /F %~n0_temp.txt

REM Display Build Number and version - e.g. 10.1.19044   Microsoft Windows 10 Pro
for /f "tokens=2 delims==" %%G in ('powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; foreach($r in (Get-CimInstance -ClassName Win32_OperatingSystem)) { [Console]::WriteLine(('Caption='+[string]$r.Caption)) }"') do set _edition=%%G
for /f "tokens=2 delims==" %%G in ('powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; foreach($r in (Get-CimInstance -ClassName Win32_OperatingSystem)) { [Console]::WriteLine(('Version='+[string]$r.Version)) }"') do set _version=%%G
echo Edition=[%_edition%]
echo Version=[%_version%]
for /f "tokens=4,5,6 delims=[]. " %%G in ('ver') Do (set _major=%%G& set _minor=%%H& set _build=%%I) 
Echo Major Version: [%_major%]
Echo Minor Version: [%_minor%]
Echo Build: [%_build%]
Echo Architecture: [%PROCESSOR_ARCHITECTURE%]

:: Stop automatic updates (uncomment to enable)
:: reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t REG_DWORD /d 1 /f

:: configure choco to allow non-checksummed packages and not prompt user for 'Yes' (-y is not needed)
choco feature enable -n allowEmptyChecksums > nul
choco feature enable -n allowGlobalConfirmation > nul

if exist %systemdrive%\DRIVERS\OfflineChoco.TAG start /wait %systemdrive%\DRIVERS\nircmd speak text "Offline Choco is enabled - tag exists"

choco -v || start /wait %systemdrive%\DRIVERS\nircmd speak text "WARNING: Chocolatey is not installed - choco installs will not work"

if "%BIT%"=="" echo ERROR: The BIT environment variable is not set - you must run Startup.cmd first. %loganddisplay%

:: ---- OFFLINE INSTALL OF CHOCO PACKAGES ----
:: Install any offline packages that were in USB:\_ISO\WINDOWS\INSTALLS\APPS\CHOCBOX folder - each one must be named by name
if exist %systemdrive%\DRIVERS\OfflineChoco.TAG start /wait %systemdrive%\DRIVERS\nircmd speak text "Installing Fox it reader, win merge, prod u key and notepad plus plus"
if exist %systemdrive%\DRIVERS\OfflineChoco.TAG echo Installing Offline Choco packages...
:: Some packages require chocolatey-core.extension, so always install this first
if exist %systemdrive%\DRIVERS\OfflineChoco.TAG choco install chocolatey-core.extension  -source C:\DRIVERS\CHOCBOX -yr >> %log%
:: Now install choco packages - must use xxxxxx.install if they are .install packages
if exist %systemdrive%\DRIVERS\OfflineChoco.TAG choco install FoxitReader        -source C:\DRIVERS\CHOCBOX -yr >> %log%
if exist %systemdrive%\DRIVERS\OfflineChoco.TAG choco install WinMerge           -source C:\DRIVERS\CHOCBOX -yr >> %log%
if exist %systemdrive%\DRIVERS\OfflineChoco.TAG choco install ProduKey.install        -source C:\DRIVERS\CHOCBOX -yr >> %log%
if exist %systemdrive%\DRIVERS\OfflineChoco.TAG choco install notepadplusplus.install -source C:\DRIVERS\CHOCBOX -yr >> %log%
if exist %systemdrive%\DRIVERS\OfflineChoco.TAG start /wait %systemdrive%\DRIVERS\nircmd speak text "off line install finished"
::Example for offline SKYPE --- see e2b website
if exist %systemdrive%\DRIVERS\OfflineChoco.TAG choco install skype        -source C:\DRIVERS\CHOCBOX -yr
:: must install vc for DLLs for Skype
if exist %systemdrive%\DRIVERS\OfflineChoco.TAG %systemdrive%\DRIVERS\CHOCBOX\vc_redist.x86.exe /q /norestart
if exist %systemdrive%\DRIVERS\OfflineChoco.TAG echo Finished Offline Choco packages


:: ----- ONLINE INSTALLS - INTERNET ACCESS REQUIRED ----
echo Installing Classic shell...
%systemdrive%\DRIVERS\nircmd.exe speak text "Downloading and installing Classic Shell"
choco install classic-shell -yr --no-progress >> %log%
:: Install Google Chrome (internet connection required) - automatic install
echo Installing Google Chrome...
%systemdrive%\DRIVERS\nircmd.exe speak text "Downloading and installing Google Chrome"
choco install googlechrome -yr --no-progress >> %log%
echo Installing WinRar...
%systemdrive%\DRIVERS\nircmd.exe speak text "Downloading and installing WinRar"
choco install winrar -yr --no-progress >> %log%

::More online install examples:

:: This example show the output as well as logging it
::choco install malwarebytes -yr --no-progress %loganddisplay%

::choco install 7zip.install -yr --no-progress >> %log%
::choco install vlc -yr --no-progress >> %log%
::choco install sysinternals -yr --no-progress >> %log%
::choco install keepass.install -yr --no-progress >> %log%
::choco install virtualbox -yr --no-progress >> %log%
::choco install ccleaner -yr --no-progress >> %log%
::choco install 7zip.install -yr --no-progress >> %log%
::choco install notepadplusplus.install -yr --no-progress >> %log%
::choco install jre8 -yr --no-progress >> %log%
::choco install vlc -yr --no-progress >> %log%
::choco install filezilla -yr --no-progress >> %log%
::choco install winrar -yr --no-progress >> %log%
::choco install winmerge -yr --no-progress >> %log%
::choco install irfanview -yr --no-progress >> %log%
::choco install audacity -yr --no-progress >> %log%
::choco install qbittorrent -yr --no-progress >> %log%
::choco install cpu-z -yr --no-progress >> %log%
::choco install everything -yr --no-progress >> %log%
::choco install firefox -packageParameters "l=en-GB"  -yr --no-progress >> %log%
::choco install googledrive -yr --no-progress >> %log%
::choco install dropbox -yr --no-progress >> %log%
::choco install adobereader -yr --no-progress >> %log%
::choco install libreoffice -yr --no-progress >> %log%
::choco install classic-shell -yr --no-progress >> %log%

:: Change computername (e.g. based on serial number and notebook\PC type)
:: call :CHNGCNAME

ECHO %0 FINISHED >> %LOG%
goto :EOF

REM --------------------- END ---------------------------



:CHNGCNAME
REM -----  CHANGE COMPUTERNAME ------

REM get serial numbers, etc.
for /F "skip=2 tokens=2 delims=," %%A in ('wmic bios get serialnumber /FORMAT:csv') do (set "zzbiosserial=%%A")
echo biosserial="%zzbiosserial%"
for /F "skip=2 tokens=2 delims=," %%A in ('wmic systemenclosure get serialnumber /FORMAT:csv') do (set "zzserial=%%A")
echo serial="%zzserial%"
for /F "skip=2 tokens=2 delims=," %%A in ('wmic csproduct get name /FORMAT:csv') do (set "zzprodname=%%A")
echo prodname="%zzprodname%"
for /F "skip=2 tokens=2 delims=," %%A in ('wmic csproduct get vendor /FORMAT:csv') do (set "zzprodvendor=%%A")
echo prodvendor="%zzprodvendor%"
for /F "skip=2 tokens=2 delims=," %%A in ('wmic baseboard get product /FORMAT:csv') do (set "zzboardprod=%%A")
echo boardprod="%zzboardprod%"
for /F "skip=2 tokens=2 delims=," %%A in ('wmic baseboard get version /FORMAT:csv') do (set "zzboardver=%%A")
echo boardver="%zzboardver%"
for /F "skip=2 tokens=2 delims=," %%A in ('wmic baseboard get SerialNumber /FORMAT:csv') do (set "zzboardserial=%%A")
echo boardserial="%zzboardserial%"
for /F "skip=2 tokens=2 delims=," %%A in ('wmic systemenclosure get ChassisTypes /FORMAT:csv') do (set "zztyperaw=%%A")
set zztype=PC
if "%zztyperaw:~1,1%"=="9"  set zztype=NB
if "%zztyperaw:~1,2%"=="10" set zztype=NB
if "%zztyperaw:~1,2%"=="14" set zztype=NB
if "%zztyperaw:~1,2%"=="25" set zztype=NB
echo zztype="%zztype%"
REM Get Mainboard UUID - e.g. 25168B60-D7FE-11DD-9D38-BCEE7B876D92  - the last part is often (but not always) the mainboard MAC address
for /F "skip=2 tokens=2 delims=," %%A in ('wmic csproduct get UUID /FORMAT:csv') do (set "zzuuid=%%A")
set zzmbmac=%zzuuid:-12%
echo UUID="%zzuuid%"  MAC="%zzmbmac%" (??)

REM Get Ethernet MAC address - e.g. zzMAC=BCEE7B876D33  (12 characters)
set zzMAC=
if "%zzMAC%"=="" for /f "usebackq tokens=3 delims=," %%a in (`getmac /fo csv /v ^| find """Ethernet"""`) do set zzMAC=%%~a
if "%zzMAC%"=="" for /f "usebackq tokens=3 delims=," %%a in (`getmac /fo csv /v ^| find "Ethernet 1"`) do set zzMAC=%%~a
if "%zzMAC%"=="" for /f "usebackq tokens=3 delims=," %%a in (`getmac /fo csv /v ^| find "Ethernet 2"`) do set zzMAC=%%~a
REM Remove all hyphens from string
set zzMAC=%zzMAC:-=%
echo MAC=%zzMAC%
setlocal EnableDelayedExpansion
set zzmac1=
set N=0
for /F %%A in ('wmic NIC get Macaddress ^| find ":"') do (
  set /a N += 1
  set "zzmac!N!=%%A"
)
endlocal & set zzmac1=%zzmac1%& set zzmac2=%zzmac2%& set zzmac3=%zzmac3%& set zzmac4=%zzmac4%
REM remove :  from BC:EE:7B:87:6D:74
set zzmac1=%zzmac1::=%
set zzmac2=%zzmac2::=%
set zzmac3=%zzmac3::=%
set zzmac4=%zzmac4::=%
echo MAC1="%zzmac1%"
echo MAC2="%zzmac2%"
echo MAC3="%zzmac3%"
echo MAC4="%zzmac4%"


REM set the new computername as NEWPC   -  *** CHANGE THIS NEXT LINE AS REQUIRED ***
set "NEWPC=%zzbiosserial%"

REM Remove illegal characters / \ , . " @  (cannot easily remove *)
set NEWPC=%NEWPC:/=%
set NEWPC=%NEWPC:\=%
set NEWPC=%NEWPC:,=%
set NEWPC=%NEWPC:.=%
set NEWPC=%NEWPC:"=%
set NEWPC=%NEWPC:@=%
set NEWPC=%NEWPC: =%
REM Remove * from NEWPC
setlocal EnableDelayedExpansion
:loop
For /F "tokens=1,2* delims=*" %%x In ("%NEWPC%") Do (
   Set "str=!str!%%x%%y"
   Set "NEWPC=%%z"
)
If not "%NEWPC%"=="" GoTo:loop
endlocal & set NEWPC=%str%


REM check we have a value
if "%NEWPC%"=="" echo no serial number! & pause
if "%NEWPC%"=="""" echo no serial number! & pause

REM Convert to uppercase
::call :ToUpper %NEWPC% NEWPC

REM pre-fix with 'PC-' or 'NB-'
set NEWPC=%zztype%-%NEWPC%

REM uncomment line below if you want to use a prefix + serial number
::set "NEWPC=NEW-%zzbiosserial%"
REM uncomment line below if you want to use the *last* 15 characters only
::set "NEWPC=%NEWPC:~-15%"

REM Use first 15 chars max - otherwise we will get an error!
set NEWPC=%NEWPC:~0,15%

start /wait %systemdrive%\DRIVERS\nircmd speak text "Changing computer name - reboot is required"
REM Record system info variables
if "%log%"=="" set log=C:\temp\%~n0.log
set zz >> %log%
set NEWPC >> %log%
set CN=
WMIC computersystem where caption='%COMPUTERNAME%' rename "%NEWPC%" || echo ERROR: COMPUTERNAME WAS NOT CHANGED! && set CN=1&& pause
if "%CN%"=="" echo COMPUTERNAME %COMPUTERNAME% will be changed to "%NEWPC%" on reboot & echo COMPUTERNAME %COMPUTERNAME% will be changed to "%NEWPC%" on reboot >> %log%

REM ----------- END OF COMPUTERNAME CHANGE --------
goto :EOF

REM --------- Convert variable to uppercase --------

:ToUpper
REM Returns variable %1 as UpCase in variable %2
REM Usage: call :ToUpper %myvar% myvar
FOR /F "tokens=2 delims=-" %%A IN ('FIND "" "%~1" 2^>^&1') DO SET UpCase=%%A
set %2=%UpCase:~1,99%
goto :EOF



