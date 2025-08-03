# OCCT ARM64 Cross-Compilation Project

This project provides a modular Docker-based cross-compilation setup for building Open CASCADE Technology (OCCT) libraries and View3D applications for ARM64 architecture, specifically targeting RK3566 devices with ARM Cortex-A55 processors and Mali G52 GPUs.

## Overview

- **Target Platform**: RK3566 (ARM Cortex-A55) with Mali G52 GPU
- **Operating System**: Debian 11 ARM64 with XFCE4 desktop environment
- **Graphics**: OpenGL ES 3.2, Vulkan 1.1 support
- **Build Method**: Modular Docker multi-stage cross-compilation
- **OCCT Version**: 7.8.1
- **Architecture**: Three-tier build system (Base → OCCT → View3D)

## Prerequisites

- Windows 11 with WSL2 enabled
- Docker installed and working
- RK3566 target device with network access
- Multi-architecture Docker support

## Quick Start

### Option 1: Build All Components (Recommended)

```bash
# Build everything in sequence
scripts/build_all.bat     # Windows
./scripts/build_all.sh    # Linux
```

### Option 2: Build Individual Components

```bash
# 1. Build base Debian image
scripts/build_base.bat     # Windows
./scripts/build_base.sh    # Linux

# 2. Build OCCT libraries
scripts/build_occt.bat     # Windows  
./scripts/build_occt.sh    # Linux

# 3. Build View3D application
scripts/build_view3d.bat   # Windows
./scripts/build_view3d.sh  # Linux
```

### Docker Images Created

- `pchuan98/debian-builder11` - Base Debian with build tools
- `pchuan98/occt` - OCCT libraries installed to `/opt/occt`
- `pchuan98/view3d-arm64` - Complete application with View3D

### Deploy to Target Device

```bash
# Transfer View3D application to RK3566
scp -r view3d-arm64 user@rk3566-ip:/home/user/view3d

# Install on target device
sudo mv /home/user/view3d /opt/view3d
sudo chmod -R 755 /opt/view3d
export LD_LIBRARY_PATH=/opt/occt/lib:/opt/view3d/lib:$LD_LIBRARY_PATH
```

### Test Installation

```bash
# On RK3566 device - test OCCT
/opt/occt/bin/draw.sh

# Test View3D application
/opt/view3d/bin/view3d
```

## Project Structure

```
├── scripts/
│   ├── build_all.bat     # Build all components (Windows)
│   ├── build_all.sh      # Build all components (Linux)
│   ├── build_base.bat    # Build base image (Windows)
│   ├── build_base.sh     # Build base image (Linux)
│   ├── build_occt.bat    # Build OCCT image (Windows)
│   ├── build_occt.sh     # Build OCCT image (Linux)
│   ├── build_view3d.bat  # Build View3D image (Windows)
│   └── build_view3d.sh   # Build View3D image (Linux)
├── build/
│   ├── Dockerfile.base   # Base Debian with build tools
│   ├── Dockerfile.occt   # OCCT compilation and runtime
│   └── Dockerfile.view3d # View3D application build
├── src/
│   ├── CMakeLists.txt    # Optimized View3D build configuration
│   └── ...               # View3D source files
├── CLAUDE.md             # Claude Code development guidance
├── README.md             # This file
├── README_zh.md          # Chinese documentation
└── occt/                 # OCCT submodule (ignored)
```

## Build Configuration

### Docker Build Architecture

1. **Base Stage** (`Dockerfile.base`): Debian 11 with build tools and dependencies
2. **OCCT Stage** (`Dockerfile.occt`): OCCT compilation and runtime libraries
3. **View3D Stage** (`Dockerfile.view3d`): Custom View3D application build

### Build Dependencies

- Base image provides: GCC, CMake, OpenGL ES, X11, and development libraries
- OCCT libraries are compiled and installed to `/opt/occt`
- View3D application links against optimized OCCT libraries

### Build Features

- **Target**: ARM64 (linux/arm64 platform)
- **Base**: Debian 11 with optimized Chinese mirrors (USTC)
- **Graphics**: OpenGL, OpenGL ES 3.2 enabled
- **Libraries**: FreeImage, FreeType, RapidJSON support
- **Optimization**: Multi-threaded build with parallel processing

### CMake Configuration

```cmake
-DCMAKE_BUILD_TYPE=Release
-DBUILD_SAMPLES=OFF
-DBUILD_TESTING=OFF
-DBUILD_DOC=OFF
-DUSE_OPENGL=ON
-DUSE_GLES2=ON
-DUSE_FREEIMAGE=ON
-DUSE_FREETYPE=ON
-DUSE_VTK=OFF
-DUSE_QT=OFF
-DUSE_RAPIDJSON=ON
```

## Development Guidelines

### Naming Conventions
- Use CamelCase style
- English names only

### Memory Management
- Prefer smart pointers and standard collections
- Avoid raw pointers for managed objects

## Troubleshooting

### Docker Build Issues

**Certificate Errors**:
- The build uses USTC mirrors for faster downloads in China
- If certificate issues occur, check mirror configuration in `build/Dockerfile`

**Build Failures**:
- Build specific stages for debugging:
  ```bash
  docker buildx build --target base -t occt-base .
  docker buildx build --target builder -t occt-builder .
  ```

### Runtime Issues on RK3566

**OpenGL Issues**:
```bash
# Install Mesa drivers
sudo apt install mesa-utils libgl1-mesa-glx:arm64

# Verify OpenGL support
glxinfo | grep OpenGL
```

**Dependency Errors**:
```bash
# Check missing libraries
ldd /opt/occt/bin/draw.sh

# Install required arm64 packages
sudo apt install [missing-package]:arm64
```

## Verification Steps

1. ✅ Enable multi-architecture support and buildx
2. ✅ Confirm Docker image builds without certificate errors
3. ✅ Verify all build stages complete successfully
4. ✅ Check OCCT extraction from runtime stage works
5. ✅ Test `draw.sh` runs on RK3566 with OpenGL
6. ✅ Test sample OCCT models on target device

## GPU Configuration Notes

- **Mali G52**: Supports OpenGL ES 3.2 and Vulkan 1.1
- **X11 Desktop**: Uses `-DUSE_OPENGL=ON`
- **Wayland**: Consider `-DUSE_EGL=ON`

## Build Optimization

- Multi-stage build reduces final image size
- USTC mirror provides faster package downloads in China
- Shallow git clone reduces download time
- Separate stages allow for better caching and debugging

## Language Versions

This documentation is available in:
- [English](README.md)
- [中文](README_zh.md)

## License

This project follows the licensing terms of Open CASCADE Technology (OCCT). Please refer to the OCCT documentation for specific licensing information.

## Contributing

Focus on project-specific files only. The `occt/` folder is a submodule and should be ignored. Custom functionality should be implemented in separate project directories.
