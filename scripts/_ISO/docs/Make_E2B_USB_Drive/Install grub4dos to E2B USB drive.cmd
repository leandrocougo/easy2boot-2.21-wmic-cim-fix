@echo off
if not "%1"=="am_admin" call powershell -h | %WINDIR%\System32\find.exe /i "powershell" > nul && if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin > nul & exit)
pushd "%~dp0"

echo Looking for drives which contain \grldr and \_ISO\e2b\grub\e2b.cfg...
echo.
:; Find E2B USB drive
FOR %%D IN (A B D E F G H I J K L M N O P Q R S T U V W X Y Z) DO (
DIR %%D:\grldr > nul 2>&1 && DIR %%D:\_ISO\e2b\grub\e2b.cfg > nul 2>&1 && (echo E2B found on drive %%D:)
)
echo.
echo INSTALL GRUB4DOS
echo.
:gl
set ask=
set /p ask=E2B drive letter : 
if "%ask%"=="" goto :gl
if /i "%ask:~0,1%"=="C" goto :gl
if /i "%ask:~0,1%:"=="%~d0" echo ERROR: Cannot install grub4dos to this drive. This script must be run from a different drive & goto :gl

set USB=%ask:~0,1%:
if not exist %USB%\grldr echo ERROR: %USB% drive does not contain \grldr - please extract E2B download files first & goto :exitbad
if not exist %USB%\_ISO\e2b\grub\e2b.cfg echo ERROR: %USB% drive does not contain the e2b.cfg file - please extract E2B download files first & goto :exitbad
FOR /F "tokens=2 delims=#," %%? IN ('powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; foreach($r in (Get-CimInstance -ClassName Win32_LogicalDiskToPartition)) { [Console]::WriteLine(([string]$r.Antecedent.DeviceID+'  '+[string]$r.Dependent.DeviceID)) }" ^|FIND /i "%USB%"') DO (set /A dd=%%? && GOTO :done)
ECHO ERROR: Drive letter %USB% is NOT assigned to a partition on a disk.
goto :exitbad
:done
if "%dd%"=="" goto :EOF
:: do not allow drive 0
if "%dd%"=="0" goto :EOF

cls
:: get drive number
(echo Rescan
echo List Disk
echo exit
) | diskpart

echo.
set ask=
set /p ask=OK to install grub4dos to drive %dd% (Y/N) : 
if /i not "%ask%"=="Y" goto :EOF
set ask=
echo.
set /p ask=Are you really sure you want to install grub4dos to Drive %dd% (Y/N) : 
if /i not "%ask%"=="Y" goto :EOF

cls
echo.
REM install grub4dos - use new grubinst to install to PBR
echo Installing grub4dos to PBR of %USB%...
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
echo Installing grub4dos to MBR of %USB%...
"%~dp0LockDismount.exe" -force %dd% %GR% -t=0 %SILENT% --skip-mbr-test (hd%dd%) >> gr1.txt
if errorlevel 1 goto :exitbad
goto :exitgud

:exitbad
color 4f
echo.
echo ERROR! You may need to dissble all AntiVirus software first.
if exist gr1.txt type gr1.txt
if exist gr.txt del gr.txt
if exist gr1.txt del gr1.txt
echo.
pause
popd
goto :EOF

:exitgud
if exist gr.txt del gr.txt
if exist gr1.txt del gr1.txt
color 2f
echo.
echo grub4dos installed to drive %dd% OK
echo.
pause
popd
