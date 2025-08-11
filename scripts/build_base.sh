#!/usr/bin/env bash

# Build base Debian builder image
# Usage: ./build_base.sh

DOCKER_IMAGE="pchuan98/debian-builder10"
PLATFORM="linux/arm64"
BUILD_PARALLELISM=$(nproc)
DOCKERFILE_PATH="build/Dockerfile.base"

echo "Building base Debian builder image..."

# Check Docker availability
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker not found. Please install Docker first."
    exit 1
fi

# Setup ARM64 environment
echo "Setting up ARM64 build environment..."
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to setup ARM64 environment"
    exit 1
fi

# Create buildx builder if needed
echo "Creating buildx builder if needed..."
if ! docker buildx inspect arm64-builder &> /dev/null; then
    docker buildx create --name arm64-builder --use
    docker buildx inspect --bootstrap
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create builder"
        exit 1
    fi
fi

# Build base image
echo "Building base image..."
docker buildx build \
    -f "$DOCKERFILE_PATH" \
    --platform "$PLATFORM" \
    -t "$DOCKER_IMAGE" \
    --load \
    --progress=plain \
    --build-arg BUILDKIT_MAX_PARALLELISM="$BUILD_PARALLELISM" \
    --build-arg HTTPS_PROXY="" \
    --build-arg HTTP_PROXY="" \
    .

if [ $? -ne 0 ]; then
    echo "ERROR: Build failed. Check Docker output for details."
    exit 1
fi

echo
echo "SUCCESS: Base image $DOCKER_IMAGE built successfully!"