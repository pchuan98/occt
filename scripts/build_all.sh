#!/usr/bin/env bash

# Build all Docker images in sequence
# Usage: ./build_all.sh

echo "Starting complete build process for ARM64 cross-compilation..."

# Build base image
echo
echo "================================"
echo "Building base Debian image..."
echo "================================"
./scripts/build_base.sh
if [ $? -ne 0 ]; then
    echo "ERROR: Base image build failed"
    exit 1
fi

# Build OCCT image
echo
echo "================================"
echo "Building OCCT libraries..."
echo "================================"
./scripts/build_occt.sh
if [ $? -ne 0 ]; then
    echo "ERROR: OCCT image build failed"
    exit 1
fi

# Build View3D image
echo
echo "================================"
echo "Building View3D application..."
echo "================================"
./scripts/build_view3d.sh
if [ $? -ne 0 ]; then
    echo "ERROR: View3D image build failed"
    exit 1
fi

echo
echo "================================"
echo "BUILD COMPLETE"
echo "================================"
echo "All images built successfully:"
echo "- pchuan98/debian-builder11"
echo "- pchuan98/occt"
echo "- pchuan98/view3d-arm64"
echo
echo "Application ready for deployment!"