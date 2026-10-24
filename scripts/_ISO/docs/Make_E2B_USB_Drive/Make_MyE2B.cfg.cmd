@if not "%DEBUG%"=="1" @echo off
color 1f
TITLE %~n0

::echo %0 "%AUTODRV%" "%AUTOLANG%" "%AUTOKBD%"
::pause

:: set cmd shell window size
if "%1"=="" mode con: cols=120 lines=60 2> nul
IF "%Comspec%"=="!Comspec!" ECHO ERROR: Delayed Expansion is enabled! && pause && setlocal disabledelayedexpansion
if not "%~d1"=="" set DRIVE=%~d1& goto :cc1

echo.
echo Create MyE2B.cfg configuration file
echo ===================================
echo.

powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; [Console]::WriteLine('caption  description  Size  volumename'); foreach($r in (Get-CimInstance -ClassName Win32_LogicalDisk)) { [Console]::WriteLine(([string]$r.caption+'  '+[string]$r.description+'  '+[string]$r.Size+'  '+[string]$r.volumename)) }" | %WINDIR%\System32\find.exe "Disk" | sort /+1
echo.
echo.

set ask=%1
if "%ask%"=="" set /P ask=E2B USB Drive Letter? (e.g. E) : 
if "%ask%"=="" goto :EOF

set DRIVE=%ask%:

if exist "%ask%:\_ISO\e2b\grub\menu.lst" goto :cc1
echo.
echo WARNING: Drive %ask%: does not contain E2B (or cannot be accessed)!
echo.
set /P cont=Continue to update? ([N]/Y) : 
if /i not "%cont%"=="Y" goto :eof


:cc1
echo.
echo Create MyE2B.cfg configuration file
echo ===================================
echo.
echo %DRIVE%\_ISO\MyE2B.cfg
echo.
set ask=
if exist %DRIVE%\_ISO\MyE2B.cfg set /p ask=WARNING: A MyE2B.cfg configuration file already exists on %DRIVE% (D=Delete, E=Edit, [ENTER]=Skip) : 
if /i "%ask%"=="E" notepad %DRIVE%\_ISO\MyE2B.cfg
if /i "%ask%"=="D" del %DRIVE%\_ISO\MyE2B.cfg
if exist %DRIVE%\_ISO\MyE2B.cfg goto :EOF
echo.
echo Tip: Press ENTER for default (ENG US) settings.
echo.
echo The %DRIVE%\_ISO\MyE2B.cfg file can contain many configuration settings for Easy2Boot.
echo Please read the \_ISO\Sample_MyE2B.cfg file for details of all possible configuration settings.
echo.

:: -- ASK FOR OPTIONS --

:getlang
if "%DD%"=="" goto :skipr
if exist r.tmp del r.tmp
powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; [Console]::WriteLine('deviceid  MediaType'); foreach($r in (Get-CimInstance -ClassName Win32_DiskDrive)) { [Console]::WriteLine(([string]$r.deviceid+'  '+[string]$r.MediaType)) }" | %WINDIR%\System32\find.exe "DRIVE%DD%" > r.tmp 2>nul
%WINDIR%\System32\find.exe /i "Removable" r.tmp > nul && set DTYPE=REMOVABLE DISK
if not "%DTYPE%"=="" echo INFORMATION: Drive %DRIVE% is of the "%DTYPE%" type
if exist r.tmp del r.tmp
:skipr

echo.
echo.

REM -- LANGUAGES
set KBD=
echo SET LANGUAGE
echo ============
echo.
echo 0  = Default US (choose Keyboard)
echo 1  = Chinese (Traditional)
echo 2  = Chinese (Simplified)
echo 3  = English (UK + UK Keyboard)
echo 4  = English (US + US Keyboard)
echo 5  = French
echo 6  = German
echo 7  = Italian
echo 8  = Polish
echo 9  = Portuguese (Brazilian)
echo 10 = Romanian
echo 11 = Spanish
echo 12 = Swedish
echo 13 = Arabic
echo 14 = Dutch (NL)
echo 15 = Russian
echo 16 = Ukranian
echo 17 = Vietnamese
echo 18 = Czech
echo 19 = Greek
echo 20 = Hungarian
echo 21 = Turkish
echo 22 = Slovenian
echo 23 = Danish
echo 24 = Indonesian
echo.
echo       S = Skip (do not create a MyE2B.cfg file)
echo.
echo [ENTER] = Default (use 'ENG US' settings)
echo.
set ask=0
if "%AUTOLANG%"=="" set /p ask=Please choose a Language (e.g. 4 or S=Skip) : 
if not "%AUTOLANG%"=="" set ask=%AUTOLANG%
if /i "%ask%"=="S" goto :EOF

if %ask% GTR 24 goto :getlang
:: *** CHECK ANSWER NOT TOO BIG

set LANG=ENG
if "%ask%"=="" set LANG=ENG
if "%ask%"=="1" set LANG=TRAD_CHINESE
if "%ask%"=="2" set LANG=SIMP_CHINESE
if "%ask%"=="3" set LANG=ENG
if "%ask%"=="4" set LANG=ENG
if "%ask%"=="5" set LANG=FRENCH
if "%ask%"=="6" set LANG=GERMAN
if "%ask%"=="7" set LANG=ITALIAN
if "%ask%"=="8" set LANG=POLISH
if "%ask%"=="9" set LANG=PORTU_BRAZIL
if "%ask%"=="10" set LANG=ROMANIAN
if "%ask%"=="11" set LANG=SPANISH
if "%ask%"=="12" set LANG=SWEDISH
if "%ask%"=="13" set LANG=ARABIC
if "%ask%"=="14" set LANG=DUTCH
if "%ask%"=="15" set LANG=RUSSIAN
if "%ask%"=="16" set LANG=UKRAINIAN
if "%ask%"=="17" set LANG=VIETNAMESE
if "%ask%"=="18" set LANG=CZECH
if "%ask%"=="19" set LANG=GREEK
if "%ask%"=="20" set LANG=HUNGARIAN
if "%ask%"=="21" set LANG=TURKISH
if "%ask%"=="22" set LANG=SLOVENIAN
if "%ask%"=="23" set LANG=DANISH
if "%ask%"=="24" set LANG=INDONESIAN

if "%AUTOKBD%"=="" if "%ask%"=="3" set KBD=KBD_QWERTY_UK.g4b& goto :skipkbd
if "%AUTOKBD%"=="" if "%ask%"=="4" set KBD=& goto :skipkbd

REM -- KBD ---
:getkbd
echo.
echo SET KEYBOARD TYPE
echo =================
echo.
echo  0 = Default   (English USA)
echo  1 = AZERTY
echo  2 = QWERTZ
echo  3 = English   (UK)
echo  4 = English   (USA)
echo  5 = French    (France)
echo  6 = German    (Germany)
echo  7 = Italian   (Italy)
echo  8 = Japanese  (Nipon)
echo  9 = Spanish   (Espanol)
echo 10 = Hungarian (QWERTZ,0-9)
echo 11 = Latin USA (Spanish\Latin USA)
echo 12 = Swedish   (Finish\Norwegian)
echo 13 = Vietnamese
echo 14 = Brazil    (Portuguese)
echo 15 = Czech     (QWERTY)
echo 16 = Czech     (QWERTZ)
echo 17 = Turkish   (QWERTY)
echo 18 = Croatian\Slovenian (QWERTZ)
echo 19 = Danish
echo.
set ask=0
if "%AUTOKBD%"=="" set /p ask=Choose a Keyboard type (e.g. 4) : 
if not "%AUTOKBD%"=="" set ask=%AUTOKBD%

if %ask% GTR 19 goto :getkbd
:: *** CHECK ANSWER NOT TOO BIG

set KBD=
if "%ask%"=="1" set KBD=KBD_AZERTY.g4b
if "%ask%"=="2" set KBD=KBD_QWERTZ.g4b
if "%ask%"=="3" set KBD=KBD_QWERTY_UK.g4b
if "%ask%"=="4" set KBD=
if "%ask%"=="5" set KBD=KBD_FRENCH.g4b
if "%ask%"=="6" set KBD=KBD_GERMAN.g4b
if "%ask%"=="7" set KBD=KBD_ITALIANO.g4b
if "%ask%"=="8" set KBD=KBD_JAPAN_106.g4b
if "%ask%"=="9" set KBD=KBD_SPANISH.g4b
if "%ask%"=="10" set KBD=KBD_QWERTZ_HUN.g4b
if "%ask%"=="11" set KBD=KBD_LATIN_USA.g4b
if "%ask%"=="12" set KBD=KBD_SWEDISH.g4b
if "%ask%"=="13" set KBD=KBD_VIETNAMESE.g4b
if "%ask%"=="14" set KBD=KBD_PORTU_BRAZIL.g4b
if "%ask%"=="15" set KBD=KBD_CZECH_QWERTY.g4b
if "%ask%"=="16" set KBD=KBD_CZECH_QWERTZ.g4b
if "%ask%"=="17" set KBD=KBD_TURKISH_Q.g4b
if "%ask%"=="18" set KBD=KBD_QWERTZ_SLOV_CROAT.g4b
if "%ask%"=="19" set KBD=KBD_DANISH.g4b

:skipkbd
REM -- SHOW FILE EXTENSIONS --
echo.
echo SHOW FILENAME EXTENSIONS IN MENU ENTRIES
echo ========================================
echo.
set ask=
if "%AUTOKBD%"=="" set /p ask=Show filename extensions in menu (Y/[N]) : 
if not "%AUTOKBD%"=="" set ask=N
set EXTOFF=1
if /i "%ask%"=="Y" set EXTOFF=
echo.
echo.

:anim
REM -- ADD ANIMATED GIF --
echo.
echo DISPLAY ANIMATED E2B ICON?
echo ==========================
echo.
echo I = E2B icon only 
echo Y = E2B icon + E2B Boiler Plate stamp
echo Q = E2B icon + QR code stamp (Easy2Boot website URL - tested payloads page)
echo N = No rotating icon or stamp
echo.
set ask=Y
if "%AUTOKBD%"=="" set /p ask=Display rotating E2B icon on menu (I/[Y]/Q/N) : 
if not "%AUTOKBD%"=="" set ask=Y
set ANIM=
if /i "%ask%"=="Y" set ANIM=1
if /i "%ask%"=="I" set ANIM=0
if /i "%ask%"=="Q" set ANIM=Q
echo.
echo.
echo.

if not "%AUTOLANG%"=="" cls
 
echo SUMMARY
echo =======
echo LANGUAGE=%LANG%
if not "%KBD%"=="" echo KEYBOARD=%KBD%
if "%KBD%"=="" echo KEYBOARD=ENG US
if "%EXTOFF%"=="" echo Show filename extensions in menus
if "%EXTOFF%"=="1" echo Do NOT show filename extensions in menus
if /i "%DTYPE%"=="REMOVABLE DISK"  echo Do NOT look for WINHELPER USB Flash drive
if "%LANG%"=="ARABIC" echo ARABIC Right-to-Left (RTL=1)
if "%ANIM%"=="1" echo Show animated E2B icon + Boiler Plate
if "%ANIM%"=="Q" echo Show animated E2B icon + QR code
if "%ANIM%"=="0" echo Show animated E2B icon

echo.
echo.
echo MyE2B.cfg
echo =========
echo !BAT
echo debug 1 ;; vbeprobe ^> (md)0x220+5 ;; debug 0
echo # if 800x600 is not supported, use 1024 resolution
echo cat --locate="800 x 600" (md)0x220+5 ^> nul ^|^| set GMODE=1024
echo cat --locate="800 x 600" (md)0x220+5 ^> nul ^|^| set MYWBMP=/_ISO/e2b/grub/background1024.jpg
REM set pc variable to avoid shell converting %GMODE% to variable value!
set pc="%%GMODE%%"
echo if %pc%=="1024" set noitems=30 ^&^& set tophelp=32 ^&^& set rstart=3 ^&^& set menuw=62 ^&^& set HBTM=4601

if NOT "%LANG%"=="ARABIC" echo if "%%LANG%%"=="" set LANG=%LANG%
if "%LANG%"=="ARABIC" (echo if "%%LANG%%"=="" set LANG=%LANG% ^&^& set RTL=1)
echo set KBD=%KBD%
echo set EXTOFF=%EXTOFF%
if /i "%DTYPE%"=="REMOVABLE DISK"  echo set NOHELPER=1
if "%ANIM%"=="1" echo set ANIMFD3=/_ISO/docs/Templates/Animate/E2B_GIF.ima
if "%ANIM%"=="1" echo set ANIMATE=0x90=3=9=615=160 (fd3)/frame_0001.bmp
if "%ANIM%"=="1" echo set STAMP1=0x80=570=23 /_ISO/e2b/grub/E2BPlate.bmp
if "%ANIM%"=="Q" echo set ANIMFD3=/_ISO/docs/Templates/Animate/E2B_GIF.ima
if "%ANIM%"=="Q" echo set ANIMATE=0x90=3=9=615=225 (fd3)/frame_0001.bmp
if "%ANIM%"=="Q" echo set STAMP1=0x00=570=23 /_ISO/e2b/grub/QR.bmp
if "%ANIM%"=="0" echo set ANIMFD3=/_ISO/docs/Templates/Animate/E2B_GIF.ima
if "%ANIM%"=="0" echo set ANIMATE=0x90=3=9=615=25 (fd3)/frame_0001.bmp
:: add date and time
echo setmenu --string=i5=74=0=0xffffff="date&time=yyyy-MM-dd  HH:mm:ss"

echo.
set ask=
if "%AUTOKBD%"=="" set /p ask=Write %DRIVE%\_ISO\MyE2B.cfg file? ([Y]/N) : 
if /i "%ask%"=="N" goto :EOF

echo.
echo !BAT>> %DRIVE%\_ISO\MyE2B.cfg
echo # See \_ISO\Sample_MyE2B.cfg for many more settings>> %DRIVE%\_ISO\MyE2B.cfg

echo debug 1 ;; vbeprobe ^> (md)0x220+5 ;; debug 0 >> %DRIVE%\_ISO\MyE2B.cfg
echo # if 800x600 is not supported, use 1024 resolution>> %DRIVE%\_ISO\MyE2B.cfg
echo cat --locate="800 x 600" (md)0x220+5 ^> nul ^|^| set GMODE=1024>> %DRIVE%\_ISO\MyE2B.cfg
echo cat --locate="800 x 600" (md)0x220+5 ^> nul ^|^| set MYWBMP=/_ISO/e2b/grub/background1024.jpg>> %DRIVE%\_ISO\MyE2B.cfg
echo if %pc%=="1024" set noitems=30 ^&^& set tophelp=32 ^&^& set rstart=3 ^&^& set menuw=62 ^&^& set HBTM=4601>> %DRIVE%\_ISO\MyE2B.cfg

if NOT "%LANG%"=="ARABIC" echo if "%%LANG%%"=="" set LANG=%LANG%>> %DRIVE%\_ISO\MyE2B.cfg
if "%LANG%"=="ARABIC" (echo if "%%LANG%%"=="" set LANG=%LANG% ^&^& set RTL=1)>> %DRIVE%\_ISO\MyE2B.cfg
echo set KBD=%KBD%>> %DRIVE%\_ISO\MyE2B.cfg
echo # ---- ADVANCED MENU SETTINGS ----- >> %DRIVE%\_ISO\MyE2B.cfg
(echo set EXTOFF=%EXTOFF%)>> %DRIVE%\_ISO\MyE2B.cfg
if /i "%DTYPE%"=="REMOVABLE DISK"  echo # This drive is the removable type - so don't look for a WINHELPER USB Flash drive>> %DRIVE%\_ISO\MyE2B.cfg
if /i "%DTYPE%"=="REMOVABLE DISK"  (echo set NOHELPER=1)>> %DRIVE%\_ISO\MyE2B.cfg

:: Add animated logo
if "%ANIM%"=="1" echo set ANIMFD3=/_ISO/docs/Templates/Animate/E2B_GIF.ima>> %DRIVE%\_ISO\MyE2B.cfg
if "%ANIM%"=="1" echo set ANIMATE=0x90=3=9=615=160 (fd3)/frame_0001.bmp>> %DRIVE%\_ISO\MyE2B.cfg
if "%ANIM%"=="1" echo set STAMP1=0x80=570=23 /_ISO/e2b/grub/E2BPlate.bmp>> %DRIVE%\_ISO\MyE2B.cfg
if "%ANIM%"=="Q" echo set ANIMFD3=/_ISO/docs/Templates/Animate/E2B_GIF.ima>> %DRIVE%\_ISO\MyE2B.cfg
if "%ANIM%"=="Q" echo set ANIMATE=0x90=3=9=615=225 (fd3)/frame_0001.bmp>> %DRIVE%\_ISO\MyE2B.cfg
if "%ANIM%"=="Q" echo set STAMP1=0x00=570=23 /_ISO/e2b/grub/QR.bmp>> %DRIVE%\_ISO\MyE2B.cfg
if "%ANIM%"=="0" echo set ANIMFD3=/_ISO/docs/Templates/Animate/E2B_GIF.ima>> %DRIVE%\_ISO\MyE2B.cfg
if "%ANIM%"=="0" echo set ANIMATE=0x90=3=9=615=25 (fd3)/frame_0001.bmp>> %DRIVE%\_ISO\MyE2B.cfg
echo setmenu --string=i5=74=0=0xffffff="date&time=yyyy-MM-dd  HH:mm:ss">> %DRIVE%\_ISO\MyE2B.cfg

REM Notepad %DRIVE%\_ISO\MyE2B.cfg
echo %DRIVE%\_ISO\MyE2B.cfg written OK
