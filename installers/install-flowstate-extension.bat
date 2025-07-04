@echo off
echo ===================================
echo FlowState Browser Extension Installer
echo ===================================
echo.

:: Check if running as admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This installer needs to run as Administrator.
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

:: Set extension directory
set EXTENSION_DIR=%LOCALAPPDATA%\FlowState\browser-extension

:: Create directory
echo Creating extension directory...
if not exist "%EXTENSION_DIR%" mkdir "%EXTENSION_DIR%"

:: Extract extension files (they'll be embedded in the installer)
echo Extracting extension files...
call :ExtractFiles

:: Open Chrome to extensions page
echo.
echo ===================================
echo INSTALLATION INSTRUCTIONS:
echo ===================================
echo 1. Chrome will open to the extensions page
echo 2. Enable "Developer mode" (toggle in top right)
echo 3. Click "Load unpacked"
echo 4. Navigate to: %EXTENSION_DIR%
echo 5. Click "Select Folder"
echo.
echo After installation:
echo - Click the FlowState icon in toolbar
echo - Enter your service key
echo - Enable tracking
echo ===================================
echo.
echo Press any key to open Chrome...
pause >nul

:: Open Chrome extensions page
start chrome://extensions/

:: Also try Edge
start msedge://extensions/ 2>nul

echo.
echo Extension files installed to: %EXTENSION_DIR%
echo.
pause
exit /b 0

:ExtractFiles
:: This section will be replaced by the packager script
:: with the actual base64 encoded files
exit /b