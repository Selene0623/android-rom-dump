@echo off

if "%~1" == "" goto errornoarg
if not exist ROMbkp\nul mkdir ROMbkp

:ask
set "arg2=%~2"
if "%arg2%"=="s" goto extractnow
if "%arg2%"=="n" goto extractnow
echo .
set /P yn="Do you want to extract %~1 (y/n)?"
if "%yn%"=="y" goto extractnow
if "%yn%"=="n" goto exit
goto ask

:extractnow
adb shell "dd if=dev/block/bootdevice/by-name/%~1" > ROMbkp\%~1.img
for /f "delims=:" %%a in ('type "ROMbkp\%~1.img"') do if "%%a" == "dd" goto errordd
echo .
echo '%~1' successfully written to 'ROMbkp/%~1.img'.
goto exit

:errornoarg
echo Error: No arguments supplied
pause
goto exit

:errordd
ren %~1.img %~1.txt
echo Error: Cannot dump '%~1'
echo Read 'ROMbkp/%~1.txt' for more info.
pause
goto exit


:exit

