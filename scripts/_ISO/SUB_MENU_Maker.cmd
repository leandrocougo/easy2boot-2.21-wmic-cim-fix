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
:getfld
set fld=
set /P fld=New folder name (e.g. MSDART_RECOVERY) : 
if "%fld%"=="" goto :EOF
call :UpCase fld
if not "%fld%"=="%fld: =%" echo NO SPACES ALLOWED! & goto :getfld
if exist %ask%:\_ISO\MAINMENU\ZZSubMenu_%fld%.mnu color 4f & echo ERROR: ZZSubMenu_%fld%.mnu already exists in \_ISO\MAINMENU folder! & pause & goto :EOF
if not exist %ask%:\_ISO\%fld%\nul mkdir %ask%:\_ISO\%fld%
echo
cls
call %0 %ask%:\_ISO\%fld%
goto :EOF

:g1

if "%~1"==""  color 4f & echo Usage: && echo Create a new folder in the \_ISO folder of the E2B USB drive (e.g. \_ISO\RESCUE) && echo then Drag-and-Drop the new folder onto this file to make a MAIN MENU entry for it. && echo. && pause && goto :EOF
if not "%~x1"=="" color 4f & echo ERROR: Please drag-and-drop a FOLDER from \_ISO && pause && goto :EOF
if not "%~p1"=="\_ISO\" color 4f & echo ERROR: Folder must be in \_ISO folder not %~p1  && pause && goto :EOF
call :check_path %~n1
set FILE="%~d1\_ISO\MAINMENU\ZZSubMenu_%~n1.mnu"
if exist %FILE% color 4f & echo ERROR: %FILE% already exists! & pause & goto :EOF

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
set /p HDTEXT=Text for Menu Heading : 
if "%HDTEXT%"=="" exit

echo.
echo MAIN MENU ENTRY
echo ===============
echo.
echo Hotkey tip: Type ^^^^ where one ^^ is required
echo.

echo Main Menu entry examples:
echo   1.       %~n1 Menu
echo   2.       ^^^^Ctrl+R RESCUE Menu [Ctrl+R]        (sets hotkey of Ctrl+R)
echo   3.       ^^^^G WINDOWS TO GO VHD Menu [G]       (sets hotkey of G)
echo.
echo.
set /p MTEXT=Text for Menu entry : 
if "%MTEXT%"=="" exit

echo.
echo.
echo ENTER HELP TEXT 
echo ===============
echo.
echo Menu Help text examples:
echo   1. [single line]      This is the %~n1 menu
echo   2. [max. 4 lines]     Use this %~n1 menu.\nLine 2 here.\nLine 3 here.\nLine 4 here.
echo.
set /p HTEXT=Text to appear under Menu : 
if "%HTEXT%"=="" set HTEXT=\x20


set "LINE=iftitle [ls (bd)/_ISO/%~n1/ ^> (md)0x9F00+1 ^&^& checkrange 1:-1 read 0x13E0000 ^> nul] %MTEXT%\n%HTEXT%"

echo.
echo.
echo.
echo SAVE THE .MNU FILE?
echo ===================
echo.
echo %FILE% will contain these lines:
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
set ask=Y
echo Press ENTER or Y to confirm...
echo.
set /p ask=Save .mnu file ([Y]/N) : 
if /i not "%ask%"=="Y" goto :EOF

:SS
if exist %FILE% del %FILE%
REM use UTF-8
CHCP 65001
echo %LINE%> %FILE%
echo set MFOLDER=/_ISO/%~n1>> %FILE%
echo set HDG=%HDTEXT%>> %FILE%
echo (bd)/%%grub%%/SubMenu.g4b>> %FILE%
echo boot>> %FILE%
"%~d0\_ISO\docs\E2B Utilities\Convert Unicode file to UTF8\UNICODEToUTF8.cmd" %FILE%
goto :EOF

:check_path
if not "%~2"=="" echo ERROR: Folder name must not contain spaces! && pause && exit
goto :EOF


:UpCase
:: Subroutine to convert a variable VALUE to all UPPER CASE. Called with name of variable as first parameter
FOR %%i IN ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z") DO CALL SET "%1=%%%1:%%~i%%"
goto :EOF

