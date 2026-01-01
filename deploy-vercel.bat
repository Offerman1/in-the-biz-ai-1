@echo off
echo ========================================
echo Building Flutter Web App...
echo ========================================
flutter build web --release

if %errorlevel% neq 0 (
    echo Build failed!
    pause
    exit /b %errorlevel%
)

echo.
echo ========================================
echo Deploying to Vercel...
echo ========================================
vercel --prod

echo.
echo ========================================
echo Deployment Complete!
echo ========================================
pause
