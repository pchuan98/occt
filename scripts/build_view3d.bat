@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Build View3D application image
:: Usage: build_view3d.bat

SET DOCKER_IMAGE=pchuan98/view3d-arm64
SET PLATFORM=linux/arm64
SET BUILD_PARALLELISM=12
SET DOCKERFILE_PATH=build/Dockerfile.view3d

echo Building View3D application image...

:: Check Docker availability
docker --version >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Docker not found. Please install Docker Desktop with WSL2 support.
    exit /b 1
)

:: Check if OCCT image exists
docker image inspect pchuan98/occt >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: OCCT image pchuan98/occt not found.
    echo Please run build_occt.bat first.
    exit /b 1
)

:: Build View3D image
echo Building View3D image...
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

:: Extract View3D artifacts
echo Extracting View3D application...
IF NOT EXIST view3d-arm64 mkdir view3d-arm64
docker run --rm -v "%cd%":/host %DOCKER_IMAGE% bash -c "cp -r /opt/view3d /host/view3d-arm64"
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to extract artifacts from container.
    exit /b 1
)

echo.
echo SUCCESS: View3D image %DOCKER_IMAGE% built successfully!
echo Application files extracted to: %cd%\view3d-arm64

ENDLOCAL