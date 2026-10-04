@echo off

if not exist adb.exe goto nofile
if not exist AdbWinApi.dll goto nofile

adb start-server

call clean.bat

if not exist ROMbkp\nul mkdir ROMbkp
if "%~1"=="n" goto nobyname
:getbyname
adb shell "ls /dev/block/bootdevice/by-name -1" > ROMbkp\by-name.txt
set "gotbyname=1"
if %errorlevel% == 1 goto :errorls

:nobyname

for /f "delims=:" %%a in ( 'type "ROMbkp\by-name.txt"' ) do if "%%a" == "ls" ( if not "%gotbyname%"=="1" ( goto getbyname ) else goto errorls )

for /f "delims=" %%a in ( 'type "ROMbkp\by-name.txt"' ) do getimg.bat %%a %~1
if %errorlevel% == 1 goto error
goto exit


:nofile
echo Error: adb.exe or adbwinapi.dll does not exist.
goto exit

:errorls
echo Error: Cannot read partition list( /dev/block/bootdevice/by-name ) from phone.
echo Note: "error: no devices/emulators found" means adb is unable to detect phone which caused this error.
goto exit

:error
echo .
echo Error occured.
goto exit

:exit
echo Program exited.
pause