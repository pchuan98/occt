@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Enhanced OCCT ARM64 Cross-Compilation Build Script
:: Version 3.0 - Supports step-by-step execution via arguments

:: Configuration Section
SET BUILDX_BUILDER=arm64-builder
SET DOCKER_IMAGE=occt-arm64
SET PLATFORM=linux/arm64
SET BUILD_PARALLELISM=12
SET DOCKERFILE_PATH=build/Dockerfile

:: Argument Parsing
SET STEP=all
IF NOT "%1"=="" SET STEP=%1

:: Check Docker availability
docker --version >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Docker not found. Please install Docker Desktop with WSL2 support.
    exit /b 1
)

:: Step 1: Setup environment
IF "%STEP%"=="all" OR "%STEP%"=="1" (
    echo [1/4] Setting up ARM64 build environment...
    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    IF %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to setup ARM64 environment
        exit /b 1
    )
)

:: Step 2: Create builder
IF "%STEP%"=="all" OR "%STEP%"=="2" (
    echo [2/4] Creating buildx builder if needed...
    docker buildx inspect %BUILDX_BUILDER% >nul 2>&1
    IF %ERRORLEVEL% NEQ 0 (
        docker buildx create --name %BUILDX_BUILDER% --use
        docker buildx inspect --bootstrap
        IF %ERRORLEVEL% NEQ 0 (
            echo ERROR: Failed to create builder
            exit /b 1
        )
    )
)

:: Step 3: Build image
IF "%STEP%"=="all" OR "%STEP%"=="3" (
    echo [3/4] Building OCCT for ARM64...
    docker buildx build \
        -f %DOCKERFILE_PATH% \
        --platform %PLATFORM% \
        -t %DOCKER_IMAGE% \
        --load \
        --build-arg BUILDKIT_MAX_PARALLELISM=%BUILD_PARALLELISM% \
        --build-arg HTTPS_PROXY="" \
        --build-arg HTTP_PROXY="" \
        .
    IF %ERRORLEVEL% NEQ 0 (
        echo ERROR: Build failed. Check Docker output for details.
        exit /b 1
    )
)

:: Completion message
IF "%STEP%"=="all" (
    echo.
    echo SUCCESS: OCCT ARM64 build completed!
) ELSE (
    echo.
    echo SUCCESS: Step %STEP% completed
)

ENDLOCAL