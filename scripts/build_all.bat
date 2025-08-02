@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Build all Docker images in sequence
:: Usage: build_all.bat

echo Starting complete build process for ARM64 cross-compilation...

:: Build base image
echo.
echo ================================
echo Building base Debian image...
echo ================================
call build_base.bat
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Base image build failed
    exit /b 1
)

:: Build OCCT image
echo.
echo ================================
echo Building OCCT libraries...
echo ================================
call build_occt.bat
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: OCCT image build failed
    exit /b 1
)

:: Build View3D image
echo.
echo ================================
echo Building View3D application...
echo ================================
call build_view3d.bat
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: View3D image build failed
    exit /b 1
)

echo.
echo ================================
echo BUILD COMPLETE
echo ================================
echo All images built successfully:
echo - pchuan98/debian-builder11
echo - pchuan98/occt
echo - pchuan98/view3d-arm64
echo.
echo Application ready for deployment!

ENDLOCAL