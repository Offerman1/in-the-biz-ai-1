@echo off
echo ========================================
echo   Deploying to GitHub Pages...
echo ========================================
echo.

REM Step 1: Build the Flutter web app
echo [1/3] Building Flutter web app...
flutter build web --release --base-href=/
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo   ERROR: Flutter build failed!
    echo ========================================
    pause
    exit /b 1
)

echo.
echo [2/3] Preparing deployment...
cd build\web

REM Remove old git repository if it exists
if exist .git (
    rmdir /s /q .git
)

REM Initialize new git repo and commit
git init
git add .
git commit -m "Deploy: %DATE% %TIME%"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo   ERROR: Git commit failed!
    echo ========================================
    cd ..\..
    pause
    exit /b 1
)

git branch -M gh-pages

echo.
echo [3/3] Pushing to GitHub Pages...
git remote add origin https://github.com/munzer221/in-the-biz-ai.git 2>nul
git push origin gh-pages --force
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo   ERROR: Git push failed!
    echo   Check your GitHub credentials
    echo ========================================
    cd ..\..
    pause
    exit /b 1
)

echo.
echo ========================================
echo   SUCCESS! Deployment Complete! 
echo   Your website will update in ~1 minute
echo   Visit: https://munzer221.github.io/in-the-biz-ai/
echo ========================================
echo.

REM Go back to project root
cd ..\..

echo.
echo PRESS ANY KEY TO CLOSE THIS WINDOW...
pause >nul
echo.
echo Press ANY KEY again to confirm...
pause >nul
