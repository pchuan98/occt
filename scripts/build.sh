#!/usr/bin/env bash

# Enhanced OCCT ARM64 Cross-Compilation Build Script
# Version 3.0 - Supports step-by-step execution via arguments

# Configuration
BUILDX_BUILDER="arm64-builder"
DOCKER_IMAGE="occt-arm64"
PLATFORM="linux/arm64"
BUILD_PARALLELISM=$(nproc)
DOCKERFILE_PATH="build/Dockerfile"

# Argument parsing
STEP="all"
if [ $# -gt 0 ]; then
    STEP="$1"
fi

# Check Docker availability
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker not found. Please install Docker first."
    exit 1
fi

# Step 1: Setup environment
if [ "$STEP" = "all" ] || [ "$STEP" = "1" ]; then
    echo "[1/4] Setting up ARM64 build environment..."
    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to setup ARM64 environment"
        exit 1
    fi
fi

# Step 2: Create builder
if [ "$STEP" = "all" ] || [ "$STEP" = "2" ]; then
    echo "[2/4] Creating buildx builder if needed..."
    if ! docker buildx inspect "$BUILDX_BUILDER" &> /dev/null; then
        docker buildx create --name "$BUILDX_BUILDER" --use
        docker buildx inspect --bootstrap
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to create builder"
            exit 1
        fi
    fi
fi

# Step 3: Build image
if [ "$STEP" = "all" ] || [ "$STEP" = "3" ]; then
    echo "[3/4] Building OCCT for ARM64..."
    docker buildx build \
        -f "$DOCKERFILE_PATH" \
        --platform "$PLATFORM" \
        -t "$DOCKER_IMAGE" \
        --load \
        --build-arg BUILDKIT_MAX_PARALLELISM="$BUILD_PARALLELISM" \
        --build-arg HTTPS_PROXY="" \
        --build-arg HTTP_PROXY="" \
        .
    if [ $? -ne 0 ]; then
        echo "ERROR: Build failed. Check Docker output for details."
        exit 1
    fi
fi

# Step 4: Extract artifacts
if [ "$STEP" = "all" ] || [ "$STEP" = "4" ]; then
    echo "[4/4] Extracting compiled libraries..."
    mkdir -p occt-arm64
    docker run --rm -v "$(pwd)":/host "$DOCKER_IMAGE" bash -c "cp -r /occt/build_dist /host/occt-arm64"
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to extract artifacts from container."
        exit 1
    fi
fi

# Completion message
if [ "$STEP" = "all" ]; then
    echo
    echo "SUCCESS: OCCT ARM64 build completed!"
    echo "Compiled libraries are in: $(pwd)/occt-arm64"
    echo "To deploy to RK3566 device, use the commands from README.md"
else
    echo
    echo "SUCCESS: Step $STEP completed"
fi