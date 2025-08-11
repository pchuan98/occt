# docker buildx build --platform linux/arm64 -f build/Dockerfile --load . --build-arg HTTPS_PROXY="" --build-arg HTTP_PROXY="" --build-arg BUILDKIT_MAX_PARALLELISM=8

##################################################################################
FROM debian:10 AS debian10

ARG MIRROR_URL=http://mirrors.aliyun.com/debian-archive/debian

RUN set -e && \
    echo 'Acquire::http::Timeout "30";' > /etc/apt/apt.conf.d/99timeout && \
    echo 'Acquire::http::Retries "3";' >> /etc/apt/apt.conf.d/99timeout && \
    echo 'Acquire::ForceIPv4 "true";' >> /etc/apt/apt.conf.d/99timeout && \
    sed -i 's|http://deb.debian.org|'"${MIRROR_URL}"'|g' /etc/apt/sources.list && \
    sed -i 's|http://security.debian.org|'"${MIRROR_URL}"'|g' /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian-archive/debian buster main contrib non-free' > /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian-archive/debian-security buster/updates main contrib non-free' >> /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian-archive/debian buster-updates main contrib non-free' >> /etc/apt/sources.list && \
    rm -f /var/lib/dpkg/info/libc-bin.* && \
    apt-get clean && \
    apt-get update && \
    apt-get install -y libc-bin && \
    echo 'Acquire::Queue-Mode "host";' > /etc/apt/apt.conf.d/99parallel && \
    echo 'Acquire::http::Pipeline-Depth "10";' >> /etc/apt/apt.conf.d/99parallel && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential cmake pkg-config libxmu-dev libxi-dev \
        freeglut3-dev libgl1-mesa-dev libtbb-dev libjpeg-dev \
        libpng-dev libtiff-dev libglfw3-dev libx11-dev \
        mesa-common-dev libglu1-mesa-dev libfreetype6-dev \
        tcl-dev tk-dev libgles2-mesa-dev libegl1-mesa-dev \
        libfreeimage-dev rapidjson-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

##################################################################################
FROM debian10 AS builder

WORKDIR /occt
COPY occt/ /occt/

RUN mkdir build && cd build && \
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DUSE_FREETYPE=ON \
        -DUSE_FREEIMAGE=ON \
        -DUSE_OPENGL=ON \
        -DUSE_GLES2=ON \
        -DCMAKE_INSTALL_PREFIX=/occt/build_dist && \
    make -j$(nproc) && \
    make install

# FROM debian10 AS occt

# COPY --from=builder /occt/build_dist /opt/occt

##################################################################################
# FROM occt AS view3d

# WORKDIR /view3d
# COPY src/ ./src/

# WORKDIR /view3d/src
# RUN cmake -B build \
#     -DCMAKE_BUILD_TYPE=Release \
#     -DCMAKE_INSTALL_PREFIX=/opt/view3d \
#     -DOpenCASCADE_DIR=/opt/occt/lib/cmake/opencascade \
#     && cmake --build build -j$(nproc) \
#     && cmake --install build