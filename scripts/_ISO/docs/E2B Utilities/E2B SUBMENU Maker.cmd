@echo off
color 1f
TITLE %~n0
:: set cmd shell window size
mode con: cols=120 lines=60
echo E2B SubMenu Maker
echo =================
echo.
echo.
if not "%~1"=="" goto g1

REM WMIC presence/PATH gate removed: queries use PowerShell CIM.

powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; [Console]::WriteLine('caption  description  Size  volumename'); foreach($r in (Get-CimInstance -ClassName Win32_LogicalDisk)) { [Console]::WriteLine(([string]$r.caption+'  '+[string]$r.description+'  '+[string]$r.Size+'  '+[string]$r.volumename)) }" | %WINDIR%\System32\find.exe "Disk" | sort /+1
echo.
echo.
set ask=
set /P ask=E2B USB Drive Letter? (e.g. E) : 
if "%ask%"=="" goto :EOF
echo.
echo CURRENT %ask%:\_ISO FOLDERS
echo =======================
dir /b /ad %ask%:\_ISO\
echo.
set fld=
set /P fld=New folder name (NO SPACES ALLOWED!) e.g. MSDART_RECOVERY : 
if "%fld%"=="" goto :EOF
if exist %ask%:\_ISO\MAINMENU\ZZSubMenu$%fld%.mnu echo ERROR: ZZSubMenu$%fld%.mnu already exists in \_ISO\MAINMENU folder! & pause & goto :EOF
if not exist %ask%:\_ISO\%fld%\nul mkdir %ask%:\_ISO\%fld%
echo
cls
call %0 %ask%:\_ISO\%fld%
goto :EOF

:g1

if "%~1"==""  echo Usage: && echo Create a new folder in the \_ISO folder of the E2B USB drive (e.g. \_ISO\RESCUE) && echo then Drag-and-Drop the new folder onto this file to make a MAIN MENU entry for it. && echo. && pause && goto :EOF
if not "%~x1"=="" echo ERROR: Please drag-and-drop a FOLDER from \_ISO && pause && goto :EOF
if not "%~p1"=="\_ISO\" echo ERROR: Folder must be in \_ISO folder not %~p1  && pause && goto :EOF
call :check_path %~n1
set FILE="%~d1\_ISO\MAINMENU\ZZSubMenu$%~n1.mnu"
if exist %FILE% echo ERROR: %FILE% already exists! & pause & goto :EOF

echo File to be created = %FILE%
echo.
echo   You will be asked to enter 3 things:
echo.
echo 1 Menu Heading    - the Title Heading that will be displayed at the top of the screen
echo 2 Main Menu Entry - the line that will appear in the Main Menu
echo 3 Help Text       - the help text for the Main Menu entry
echo.
echo.
echo ENTER MENU HEADING
echo ==================
echo.
echo Example:
echo             %~n1 Menu
echo.
set /p HDTEXT=Menu Heading Title : 
if "%HDTEXT%"=="" exit

echo.
echo MAIN MENU ENTRY
echo ===============
echo.
echo Hotkey tip: Type ^^^^ where one ^^ is required
echo.

echo Examples:
echo             %~n1 Menu
echo             ^^^^Ctrl+R RESCUE Menu [Ctrl+R]        (sets hotkey of Ctrl+R)
echo             ^^^^G WINDOWS TO GO VHD Menu [G]       (sets hotkey of G)
echo.
echo.
set /p MTEXT=Menu text : 
if "%MTEXT%"=="" exit

echo.
echo.
echo.
echo ENTER HELP TEXT
echo ===============
echo.
echo Examples:
echo             %~n1 Menu
echo             Rescue Menu\nFor Windows OS recovery and repair.
echo.
set /p HTEXT=Help text : 
if "%HTEXT%"=="" set HTEXT=\x20


set "LINE=iftitle [ls (bd)/_ISO/%~n1/ ^> (md)0x9F00+1 ^&^& checkrange 1:-1 read 0x13E0000 ^> nul] %MTEXT%\n%HTEXT%"

echo.
echo.
echo.
echo SAVE THE .MNU FILE?
echo ===================
echo.
echo %FILE% will contain the lines:
echo.
echo.
echo ----------------------------------------------------------------------------------
echo %LINE%
echo set MFOLDER=/_ISO/%~n1
echo set HDG=%HDTEXT%
echo (bd)/%%grub%%/SubMenu.g4b
echo boot
echo ----------------------------------------------------------------------------------
echo.
echo.
echo.
set ask=
echo Press ENTER or Y to confirm...
echo.
set /p ask=OK to write Submenu .mnu file ([Y]/N) : 

if /i "%ask%"=="N" goto :EOF
if "%ask%"=="" goto :SS
if /i not  "%ask%"=="Y" goto :EOF


:SS
if exist %FILE% del %FILE%
REM use UTF-8
CHCP 65001

echo %LINE%> %FILE%
echo set MFOLDER=/_ISO/%~n1>> %FILE%
echo set HDG=%HDTEXT%>> %FILE%
echo (bd)/%%grub%%/SubMenu.g4b>> %FILE%
echo boot>> %FILE%
call "%~d0\_ISO\docs\E2B Utilities\Convert Unicode file to UTF8\UNICODEToUTF8.cmd" %FILE%
goto :EOF

:check_path
if not "%~2"=="" echo ERROR: Folder name must not contain spaces! && pause && exit
goto :EOF


