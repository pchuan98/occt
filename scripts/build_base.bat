@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Build base Debian builder image
:: Usage: build_base.bat

SET DOCKER_IMAGE=pchuan98/debian-builder10
SET PLATFORM=linux/arm64
SET BUILD_PARALLELISM=6
SET DOCKERFILE_PATH=build/Dockerfile.base

echo Building base Debian builder image...

:: Check Docker availability
docker --version >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Docker not found. Please install Docker Desktop with WSL2 support.
    exit /b 1
)

:: Setup ARM64 environment
echo Setting up ARM64 build environment...
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to setup ARM64 environment
    exit /b 1
)

:: Create buildx builder if needed
echo Creating buildx builder if needed...
docker buildx inspect arm64-builder >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    docker buildx create --name arm64-builder --use
    docker buildx inspect --bootstrap
    IF %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to create builder
        exit /b 1
    )
)

:: Build base image
echo Building base image...
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
echo SUCCESS: Base image %DOCKER_IMAGE% built successfully!

ENDLOCAL