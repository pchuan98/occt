#!/usr/bin/env bash

# Build OCCT libraries image
# Usage: ./build_occt.sh

DOCKER_IMAGE="pchuan98/occt10:latest"
PLATFORM="linux/arm64"
BUILD_PARALLELISM=$(nproc)
DOCKERFILE_PATH="build/Dockerfile.occt"

echo "Building OCCT libraries image..."

# Check Docker availability
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker not found. Please install Docker first."
    exit 1
fi

# Check if base image exists
if ! docker image inspect pchuan98/debian-builder10 &> /dev/null; then
    echo "ERROR: Base image pchuan98/debian-builder10 not found."
    echo "Please run build_base.sh first."
    exit 1
fi

# Build OCCT image
echo "Building OCCT image..."
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

echo
echo "SUCCESS: OCCT image $DOCKER_IMAGE built successfully!"