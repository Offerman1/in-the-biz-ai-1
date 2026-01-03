@echo off
echo ========================================
echo Google Play Store Graphics Generator
echo ========================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python is not installed. Please install Python first.
    echo Or create graphics manually using Canva: https://www.canva.com/
    pause
    exit /b
)

REM Check if PIL/Pillow is installed
python -c "from PIL import Image" >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Pillow library...
    pip install Pillow
)

echo Generating feature graphic...
python scripts/generate-feature-graphic.py

echo.
echo ========================================
echo NEXT STEPS:
echo ========================================
echo.
echo 1. Feature graphic created in: store-assets/feature-graphic.png
echo.
echo 2. Take screenshots of your app:
echo    - Run: flutter run -d 10.0.0.65:5555
echo    - Take 4-8 screenshots showing:
echo      * Dashboard with earnings
echo      * Add Shift screen
echo      * Calendar view
echo      * Analytics/Stats
echo      * Shift detail
echo      * AI Chat
echo.
echo 3. Find your app icon at:
echo    android/app/src/main/res/mipmap-xxxhdpi/launcher_icon.png
echo.
echo 4. Upload all to Google Play Console!
echo.
pause
