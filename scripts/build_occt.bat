@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Build OCCT libraries image
:: Usage: build_occt.bat

SET DOCKER_IMAGE=pchuan98/occt
SET PLATFORM=linux/arm64
SET BUILD_PARALLELISM=12
SET DOCKERFILE_PATH=build/Dockerfile.occt

echo Building OCCT libraries image...

:: Check Docker availability
docker --version >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Docker not found. Please install Docker Desktop with WSL2 support.
    exit /b 1
)

:: Check if base image exists
docker image inspect pchuan98/debian-builder11 >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Base image pchuan98/debian-builder11 not found.
    echo Please run build_base.bat first.
    exit /b 1
)

:: Build OCCT image
echo Building OCCT image...
docker buildx build ^
    -f %DOCKERFILE_PATH% ^
    --platform %PLATFORM% ^
    -t %DOCKER_IMAGE% ^
    --load ^
    --progress=plain ^
    --build-arg BUILDKIT_MAX_PARALLELISM=%BUILD_PARALLELISM% ^
    --build-arg HTTPS_PROXY="" ^
    --build-arg HTTP_PROXY="" ^
    .

IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed. Check Docker output for details.
    exit /b 1
)

echo.
echo SUCCESS: OCCT image %DOCKER_IMAGE% built successfully!

ENDLOCAL