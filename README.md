# OCCT ARM64 Cross-Compilation Project

This project provides a Docker-based cross-compilation setup for building Open CASCADE Technology (OCCT) libraries and View3D applications for ARM64 architecture, specifically targeting RK3566 devices with ARM Cortex-A55 processors and Mali G52 GPUs.

## Overview

- **Target Platform**: RK3566 (ARM Cortex-A55) with Mali G52 GPU
- **Operating System**: Debian 11 ARM64 with XFCE4 desktop environment
- **Graphics**: OpenGL ES 3.2, Vulkan 1.1 support
- **Build Method**: Docker multi-stage cross-compilation
- **OCCT Version**: 7.9.1
- **Architecture**: Three-tier build system (Base → OCCT → View3D)

## Prerequisites

- Docker installed with buildx support
- Multi-architecture Docker support (QEMU)
- RK3566 target device with network access (for deployment)

## Quick Start

### Docker-based Cross-compilation

```bash
# Windows
scripts\build_occt.bat

# Linux
./scripts/build_occt.sh
```

This builds the OCCT ARM64 Docker image using `build/Dockerfile`.

### Available Build Scripts

```bash
# Individual component builds
scripts/build_base.bat/.sh     # Base Debian 11 with build tools
scripts/build_occt.bat/.sh     # OCCT libraries compilation
scripts/build_view3d.bat/.sh   # View3D application build
scripts/build_all.bat/.sh      # Build all components in sequence

# Local build using pre-compiled OCCT image
scripts/local_build.bat        # Build src files using saved OCCT image
```

### Local Build with Pre-compiled OCCT

Use the `scripts/local_build.bat` script to build your src files using a pre-compiled OCCT image:

```batch
# Build mode: Compile src files
scripts\local_build.bat

# Export mode: Export OCCT library to current directory
scripts\local_build.bat --export
```

**Prerequisites for local build:**
- Docker Desktop running with WSL2 support
- OCCT image tar file at `temp/occt-image.tar`
- Source files in `src/` directory (for build mode)

**Features:**
- Uses persistent container for faster subsequent builds
- Parallel compilation with configurable build parallelism
- Exports compiled results to `build-output/` directory
- Can export OCCT library as `occt-arm64.tar.gz` archive

## Project Structure

```
├── .github/
│   └── workflows/
│       └── build-occt.yml     # GitHub Actions CI/CD workflow
├── scripts/
│   ├── build_*.bat/.sh        # Build scripts for different platforms
├── build/
│   ├── Dockerfile             # Main multi-stage build
│   ├── Dockerfile.base        # Base Debian with build tools
│   ├── Dockerfile.occt        # OCCT compilation stage
│   └── Dockerfile.view3d      # View3D application stage
├── src/                       # View3D application source code
├── occt/                      # OCCT submodule (v7.9.1)
├── .gitattributes            # Git line ending configuration
├── CLAUDE.md                 # Development guidance for Claude Code
└── README.md                 # This file
```

## Docker Images

The build process creates these Docker images:

- `pchuan98/debian-builder11` - Base Debian 11 with build tools
- `pchuan98/occt:v7.9.1` - OCCT libraries installed to `/opt/occt`
- `pchuan98/view3d-arm64` - Complete View3D application

### Saving Docker Images

To save the OCCT image to a tar file for offline use:

```bash
# Save OCCT image to tar file
docker save pchuan98/occt:v7.9.1 -o temp/occt-image.tar

# Load image from tar file
docker load -i temp/occt-image.tar
```

## GitHub Actions CI/CD

This repository includes automated Docker image building via GitHub Actions:

### Workflow Features
- **Automatic builds** on push to master branch
- **Multi-architecture support** (ARM64 target)
- **GitHub Container Registry** integration (`ghcr.io`)
- **Build caching** for faster subsequent builds
- **Pull request validation**

### Triggered When
- Changes to `build/Dockerfile`, `occt/**`, or workflow files
- Pull requests to master branch
- Manual workflow dispatch

### Image Registry
Built images are pushed to: `ghcr.io/[your-username]/[repository-name]/occt`

## Build Configuration

### CMake Options
```cmake
-DCMAKE_BUILD_TYPE=Release
-DUSE_FREETYPE=ON
-DUSE_FREEIMAGE=ON
-DUSE_OPENGL=ON
-DUSE_GLES2=ON
-DCMAKE_INSTALL_PREFIX=/opt/occt
```

### Target Specifications
- **Platform**: linux/arm64
- **Base OS**: Debian 11 with USTC mirrors
- **Graphics**: OpenGL, OpenGL ES 3.2 enabled
- **Libraries**: FreeImage, FreeType, RapidJSON support

## Deployment to RK3566

### Extract from Docker Container
```bash
# Create temporary container and extract built files
docker run --rm -v $(pwd):/host pchuan98/occt bash -c "cp -r /opt/occt /host/occt-arm64"
```

### Transfer to Target Device
```bash
# Transfer to RK3566
scp -r occt-arm64 user@rk3566-ip:/home/user/occt

# Install on target device
sudo mv /home/user/occt /opt/occt
sudo chmod -R 755 /opt/occt
export LD_LIBRARY_PATH=/opt/occt/lib:$LD_LIBRARY_PATH
```

### Test Installation
```bash
# Test OCCT on RK3566
/opt/occt/bin/draw.sh

# Test View3D application (if built)
/opt/view3d/bin/view3d
```

## Troubleshooting

### Docker Build Issues
**Multi-architecture setup**:
```bash
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker buildx create --name arm64-builder --use
docker buildx inspect --bootstrap
```

**Build specific stages**:
```bash
docker buildx build --target debian11 -t occt-base .
docker buildx build --target builder -t occt-builder .
docker buildx build --target occt -t occt-runtime .
```

### Runtime Issues on RK3566
**OpenGL verification**:
```bash
# Install Mesa drivers
sudo apt install mesa-utils libgl1-mesa-glx:arm64

# Verify OpenGL support
glxinfo | grep OpenGL
```

**Dependency checking**:
```bash
# Check missing libraries
ldd /opt/occt/bin/draw.sh

# Install required packages
sudo apt install [missing-package]:arm64
```

## Build Optimization Features

- **Multi-stage Docker build** reduces final image size
- **USTC mirror** provides faster package downloads in China
- **Build caching** via GitHub Actions cache
- **Parallel compilation** using all available CPU cores
- **Optimized dependencies** with minimal package installation

## Language Versions

This documentation is available in:
- [English](README.md)
- [中文](README_zh.md)

## License

This project follows the licensing terms of Open CASCADE Technology (OCCT). Please refer to the OCCT documentation for specific licensing information.