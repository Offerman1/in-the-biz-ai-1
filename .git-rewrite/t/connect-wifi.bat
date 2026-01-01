@echo off
REM All device IP addresses
set TABLET_IP=10.0.0.50
set SEEKER_IP=10.0.0.65
set SN339D_IP=10.0.0.98
set ADB_PATH=C:\Android\Sdk\platform-tools\adb.exe

echo Connecting all devices over Wi-Fi...
echo.
echo Connecting Tablet (SM X210)...
%ADB_PATH% connect %TABLET_IP%:5555
echo.
echo Connecting Seeker Phone...
%ADB_PATH% connect %SEEKER_IP%:5555
echo.
echo Connecting SN339D Phone...
%ADB_PATH% connect %SN339D_IP%:5555

echo.
echo Available devices:
%ADB_PATH% devices

echo.
echo To disconnect all: adb disconnect
pause
