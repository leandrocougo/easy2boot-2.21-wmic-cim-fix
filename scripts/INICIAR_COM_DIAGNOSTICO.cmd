@echo off
setlocal
set "E2B_ROOT=%~dp0"
cd /d "%E2B_ROOT%"
echo Easy2Boot CIM - diagnostic launcher
echo Run this file as administrator.
echo Errors are appended to Easy2Boot-erro.log in this folder.
echo [%date% %time%] Starting >>"%E2B_ROOT%Easy2Boot-erro.log"
cmd.exe /d /c ""%E2B_ROOT%_ISO\docs\Make_E2B_USB_Drive\MAKE_E2B_USB_DRIVE.cmd"" 2>>"%E2B_ROOT%Easy2Boot-erro.log"
set "E2B_RC=%errorlevel%"
echo.
echo Easy2Boot finished. Exit code: %E2B_RC%
echo [%date% %time%] Exit code: %E2B_RC% >>"%E2B_ROOT%Easy2Boot-erro.log"
echo If it stopped unexpectedly, see Easy2Boot-erro.log.
pause
exit /b %E2B_RC%
