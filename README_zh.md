# OCCT ARM64 跨平台编译项目

本项目提供基于Docker的Open CASCADE Technology (OCCT)库和View3D应用程序ARM64架构交叉编译方案，特别针对搭载ARM Cortex-A55处理器和Mali G52 GPU的RK3566设备。

## 概述

- **目标平台**: RK3566 (ARM Cortex-A55) 搭载 Mali G52 GPU
- **操作系统**: Debian 11 ARM64 带XFCE4桌面环境
- **图形支持**: OpenGL ES 3.2, Vulkan 1.1
- **构建方式**: Docker多阶段交叉编译
- **OCCT版本**: 7.9.1
- **架构**: 三层构建系统 (基础 → OCCT → View3D)

## 前提条件

- 已安装Docker及buildx支持
- 多架构Docker支持 (QEMU)
- 可联网的RK3566目标设备（用于部署）

## 快速开始

### Docker跨平台编译

```bash
# Windows
scripts\build_occt.bat

# Linux
./scripts/build_occt.sh
```

这将使用`build/Dockerfile`构建OCCT ARM64 Docker镜像。

### 可用构建脚本

```bash
# 各组件构建
scripts/build_base.bat/.sh     # 带构建工具的基础Debian 11
scripts/build_occt.bat/.sh     # OCCT库编译
scripts/build_view3d.bat/.sh   # View3D应用程序构建
scripts/build_all.bat/.sh      # 按顺序构建所有组件
```

## 项目结构

```
├── .github/
│   └── workflows/
│       └── build-occt.yml     # GitHub Actions CI/CD工作流
├── scripts/
│   ├── build_*.bat/.sh        # 不同平台的构建脚本
├── build/
│   ├── Dockerfile             # 主要多阶段构建
│   ├── Dockerfile.base        # 带构建工具的基础Debian
│   ├── Dockerfile.occt        # OCCT编译阶段
│   └── Dockerfile.view3d      # View3D应用程序阶段
├── src/                       # View3D应用程序源代码
├── occt/                      # OCCT子模块 (v7.9.1)
├── .gitattributes            # Git换行符配置
├── CLAUDE.md                 # Claude代码开发指南
└── README.md                 # 英文文档
```

## Docker镜像

构建过程创建以下Docker镜像：

- `pchuan98/debian-builder11` - 带构建工具的基础Debian 11
- `pchuan98/occt` - OCCT库安装到 `/opt/occt`
- `pchuan98/view3d-arm64` - 完整View3D应用程序

## GitHub Actions CI/CD

本仓库包含通过GitHub Actions自动化Docker镜像构建：

### 工作流特性
- **自动构建** 当推送到master分支时
- **多架构支持** (ARM64目标)
- **GitHub容器注册表** 集成 (`ghcr.io`)
- **构建缓存** 加速后续构建
- **Pull Request验证**

### 触发条件
- 修改 `build/Dockerfile`、`occt/**` 或工作流文件
- 针对master分支的Pull Request
- 手动工作流调度

### 镜像注册表
构建的镜像推送到: `ghcr.io/[用户名]/[仓库名]/occt`

## 构建配置

### CMake选项
```cmake
-DCMAKE_BUILD_TYPE=Release
-DUSE_FREETYPE=ON
-DUSE_FREEIMAGE=ON
-DUSE_OPENGL=ON
-DUSE_GLES2=ON
-DCMAKE_INSTALL_PREFIX=/opt/occt
```

### 目标规格
- **平台**: linux/arm64
- **基础系统**: 使用USTC镜像源的Debian 11
- **图形支持**: 启用OpenGL, OpenGL ES 3.2
- **库支持**: FreeImage, FreeType, RapidJSON

## 部署到RK3566

### 从Docker容器提取
```bash
# 创建临时容器并提取构建文件
docker run --rm -v $(pwd):/host pchuan98/occt bash -c "cp -r /opt/occt /host/occt-arm64"
```

### 传输到目标设备
```bash
# 传输到RK3566
scp -r occt-arm64 user@rk3566-ip:/home/user/occt

# 在目标设备上安装
sudo mv /home/user/occt /opt/occt
sudo chmod -R 755 /opt/occt
export LD_LIBRARY_PATH=/opt/occt/lib:$LD_LIBRARY_PATH
```

### 测试安装
```bash
# 在RK3566上测试OCCT
/opt/occt/bin/draw.sh

# 测试View3D应用程序（如果已构建）
/opt/view3d/bin/view3d
```

## 故障排除

### Docker构建问题
**多架构设置**：
```bash
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker buildx create --name arm64-builder --use
docker buildx inspect --bootstrap
```

**构建特定阶段**：
```bash
docker buildx build --target debian11 -t occt-base .
docker buildx build --target builder -t occt-builder .
docker buildx build --target occt -t occt-runtime .
```

### RK3566运行时问题
**OpenGL验证**：
```bash
# 安装Mesa驱动
sudo apt install mesa-utils libgl1-mesa-glx:arm64

# 验证OpenGL支持
glxinfo | grep OpenGL
```

**依赖检查**：
```bash
# 检查缺失的库
ldd /opt/occt/bin/draw.sh

# 安装所需软件包
sudo apt install [缺失的包]:arm64
```

## 构建优化特性

- **多阶段Docker构建** 减小最终镜像体积
- **USTC镜像源** 加速中国区下载
- **通过GitHub Actions缓存** 构建缓存
- **并行编译** 使用所有可用CPU核心
- **优化依赖** 最小化软件包安装

## 语言版本

本文档提供以下语言版本：
- [English](README.md)
- [中文](README_zh.md)

## 许可证

本项目遵循Open CASCADE Technology (OCCT)的许可条款。具体许可信息请参考OCCT文档。