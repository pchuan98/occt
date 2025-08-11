@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
:: Local build using pre-compiled OCCT image
:: Usage: local_build.bat [--export] [--rm]
::   --export: Export OCCT library to current directory
::   --rm: Use disposable container (remove after use)
SET OCCT_IMAGE=pchuan98/occt10:v7.8.1
SET TAR_FILE=occt10-image.tar
SET CONTAINER_NAME=builder
SET PLATFORM=linux/arm64
SET BUILD_PARALLELISM=12

:: Check for parameters
SET EXPORT_MODE=0
SET DISPOSABLE_MODE=0

:: Parse all arguments
:parse_args
IF "%1"=="" GOTO :done_parsing
IF "%1"=="--export" (
   SET EXPORT_MODE=1
)
IF "%1"=="--rm" (
   SET DISPOSABLE_MODE=1
)
SHIFT
GOTO :parse_args
:done_parsing

IF %EXPORT_MODE%==1 (
   echo Export mode: Will export OCCT library to current directory
) ELSE (
   echo Build mode: Will compile src files
)

IF %DISPOSABLE_MODE%==1 (
   echo Container mode: Disposable (will be removed after use)
) ELSE (
   echo Container mode: Persistent (will be reused)
)

:: Check Docker availability
docker --version >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
   echo ERROR: Docker not found. Please install Docker Desktop with WSL2 support.
   exit /b 1
)

:: Check if Docker Desktop is running
docker info >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
   echo ERROR: Docker Desktop is not running. Please start Docker Desktop and try again.
   exit /b 1
)

:: Check if image exists locally
docker images %OCCT_IMAGE% --format "{{.Repository}}:{{.Tag}}" | findstr /c:"%OCCT_IMAGE%" >nul 2>&1
IF !ERRORLEVEL! NEQ 0 (
   echo OCCT image not found locally. Loading from tar file...
   :: Check if tar file exists
   IF NOT EXIST %TAR_FILE% (
       echo ERROR: OCCT image tar file not found at %TAR_FILE%
       echo Please ensure the compiled image tar file is available.
       exit /b 1
   )

   :: Load OCCT image from tar file
   echo Loading OCCT image from %TAR_FILE%...
   docker load -i %TAR_FILE%
   IF !ERRORLEVEL! NEQ 0 (
       echo ERROR: Failed to load OCCT image from tar file.
       exit /b 1
   )
   echo OCCT image loaded successfully.
) ELSE (
   echo OCCT image found locally, skipping load.
)

:: Check if src directory exists (only in build mode)
IF %EXPORT_MODE%==0 (
   IF NOT EXIST src (
       echo ERROR: src directory not found. Please ensure source files are available.
       exit /b 1
   )
)

IF %DISPOSABLE_MODE%==1 (
   :: Use disposable container (--rm mode)
   echo Using disposable container mode...
   IF NOT EXIST build-output mkdir build-output
   SET CONTAINER_RUN_MODE=--rm
   SET CONTAINER_NAME=src-builder-temp-%RANDOM%
) ELSE (
   :: Use persistent container (default mode)
   :: Check if container already exists
   docker ps -a --filter "name=^/%CONTAINER_NAME%$" --format "{{.Names}}" | findstr /c:"%CONTAINER_NAME%" >nul 2>&1
   IF !ERRORLEVEL! EQU 0 (
       echo Reusing existing container %CONTAINER_NAME%...
       docker start %CONTAINER_NAME% >nul 2>&1
   ) ELSE (
       echo Creating new persistent container %CONTAINER_NAME%...
       IF NOT EXIST build-output mkdir build-output
       docker create ^
           -v "%cd%/src":/workspace/src ^
           -v "%cd%/build-output":/workspace/build ^
           --platform %PLATFORM% ^
           --name %CONTAINER_NAME% ^
           %OCCT_IMAGE% ^
           tail -f /dev/null >nul
       IF !ERRORLEVEL! NEQ 0 (
           echo ERROR: Failed to create container.
           exit /b 1
       )
       docker start %CONTAINER_NAME%
   )
)

IF %EXPORT_MODE%==1 (
   :: Export OCCT library mode
   echo Exporting OCCT library from container...
   
   IF %DISPOSABLE_MODE%==1 (
       :: Use disposable container for export
       docker run %CONTAINER_RUN_MODE% ^
           -v "%cd%/build-output":/workspace/build ^
           --platform %PLATFORM% ^
           --name %CONTAINER_NAME% ^
           %OCCT_IMAGE% ^
           bash -c "cd /opt && tar -czf /workspace/occt-arm64.tar.gz occt/"
       IF !ERRORLEVEL! NEQ 0 (
           echo ERROR: Failed to export OCCT library.
           exit /b 1
       )
   ) ELSE (
       :: Use persistent container for export
       :: Create tar.gz archive inside container
       echo Creating tar.gz archive of OCCT library...
       docker exec %CONTAINER_NAME% bash -c "cd /opt && tar -czf /workspace/occt-arm64.tar.gz occt/"
       IF !ERRORLEVEL! NEQ 0 (
           echo ERROR: Failed to create tar archive.
           exit /b 1
       )
       
       :: Copy from /workspace/occt-arm64.tar.gz
       docker cp %CONTAINER_NAME%:/workspace/occt-arm64.tar.gz build-output/occt-arm64.tar.gz
   )

   echo.
   echo SUCCESS: OCCT library exported successfully!
) ELSE (
   :: Build mode
   echo Using container %CONTAINER_NAME% for compilation...
   
   IF %DISPOSABLE_MODE%==1 (
       :: Use disposable container for compilation
       docker run %CONTAINER_RUN_MODE% ^
           -v "%cd%/src":/workspace/src ^
           -v "%cd%/build-output":/workspace/build ^
           --platform %PLATFORM% ^
           --name %CONTAINER_NAME% ^
           %OCCT_IMAGE% ^
           bash -c "cd /workspace && cmake src -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/workspace/build/install -DOpenCASCADE_DIR=/opt/occt/lib/cmake/opencascade && cmake --build build -j %BUILD_PARALLELISM% && cmake --install build"
       IF !ERRORLEVEL! NEQ 0 (
           echo ERROR: Compilation failed. Check Docker output for details.
           exit /b 1
       )
   ) ELSE (
       :: Use persistent container for compilation
       docker exec %CONTAINER_NAME% bash -c "cd /workspace && cmake src -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/workspace/build/install -DOpenCASCADE_DIR=/opt/occt/lib/cmake/opencascade && cmake --build build -j %BUILD_PARALLELISM% && cmake --install build"
       IF !ERRORLEVEL! NEQ 0 (
           echo ERROR: Compilation failed. Check Docker output for details.
           exit /b 1
       )
   )
   
   echo.
   echo SUCCESS: Local build completed successfully!
   echo Build results available in: %cd%\build-output
)

ENDLOCAL