@echo off
echo.
echo ========================================
echo   BRAANDINS Website Update Script
echo ========================================
echo.
echo This will:
echo 1. Build the latest web version
echo 2. Push updates to GitHub Pages
echo.
pause

echo.
echo [1/2] Building web version (Mobile Optimized)...
echo.
call dart pub global run peanut --extra-args "--base-href=/braand_app/"

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Build failed!
    echo.
    pause
    exit /b 1
)

echo.
echo [2/2] Pushing to GitHub Pages...
echo.
git push origin gh-pages --force

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Push failed!
    echo Make sure you're connected to the internet.
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   SUCCESS! Website Updated!
echo ========================================
echo.
echo Your changes will be live in 1-2 minutes at:
echo https://OXeroSevyn.github.io/braand_app/
echo.
echo (GitHub Pages takes a moment to rebuild)
echo.
pause
