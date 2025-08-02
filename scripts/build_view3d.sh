#!/usr/bin/env bash

# Build View3D application image
# Usage: ./build_view3d.sh

DOCKER_IMAGE="pchuan98/view3d-arm64"
PLATFORM="linux/arm64"
BUILD_PARALLELISM=$(nproc)
DOCKERFILE_PATH="build/Dockerfile.view3d"

echo "Building View3D application image..."

# Check Docker availability
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker not found. Please install Docker first."
    exit 1
fi

# Check if OCCT image exists
if ! docker image inspect pchuan98/occt &> /dev/null; then
    echo "ERROR: OCCT image pchuan98/occt not found."
    echo "Please run build_occt.sh first."
    exit 1
fi

# Build View3D image
echo "Building View3D image..."
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

# Extract View3D artifacts
echo "Extracting View3D application..."
mkdir -p view3d-arm64
docker run --rm -v "$(pwd)":/host "$DOCKER_IMAGE" bash -c "cp -r /opt/view3d /host/view3d-arm64"
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to extract artifacts from container."
    exit 1
fi

echo
echo "SUCCESS: View3D image $DOCKER_IMAGE built successfully!"
echo "Application files extracted to: $(pwd)/view3d-arm64"