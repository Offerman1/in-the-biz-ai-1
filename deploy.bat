@echo off
echo.
echo ========================================
echo   IN THE BIZ - WEB DEPLOYMENT
echo ========================================
echo.

echo Step 1: Building Flutter web app...
call flutter build web --release --base-href=/
if errorlevel 1 (
    echo BUILD FAILED!
    pause
    exit /b 1
)

echo.
echo Step 2: Copying build files to root...
xcopy /E /Y "build\web\*" "." >nul

echo.
echo Step 3: Committing changes...
git add .
git commit -m "Deploy: %date% %time%"

echo.
echo Step 4: Pushing to GitHub...
git push origin gh-pages

echo.
echo ========================================
echo   DEPLOYMENT COMPLETE!
echo   Website: https://inthebiz.app
echo ========================================
echo.
pause
