# OCCT ARM64 跨平台编译项目

本项目提供模块化的基于Docker的Open CASCADE Technology (OCCT)库和View3D应用程序ARM64架构交叉编译方案，特别针对搭载ARM Cortex-A55处理器和Mali G52 GPU的RK3566设备。

## 概述

- **目标平台**: RK3566 (ARM Cortex-A55) 搭载 Mali G52 GPU
- **操作系统**: Debian 11 ARM64 带XFCE4桌面环境
- **图形支持**: OpenGL ES 3.2, Vulkan 1.1
- **构建方式**: 模块化Docker多阶段交叉编译
- **OCCT版本**: 7.8.1
- **架构**: 三层构建系统 (基础 → OCCT → View3D)

## 前提条件

- Windows 11 并启用WSL2
- 已安装Docker
- 可联网的RK3566目标设备
- Docker多架构支持

## 快速开始

### 选项1: 构建所有组件 (推荐)

```bash
# 按顺序构建所有组件
scripts/build_all.bat     # Windows
./scripts/build_all.sh    # Linux
```

### 选项2: 分别构建各组件

```bash
# 1. 构建基础Debian镜像
scripts/build_base.bat     # Windows
./scripts/build_base.sh    # Linux

# 2. 构建OCCT库
scripts/build_occt.bat     # Windows  
./scripts/build_occt.sh    # Linux

# 3. 构建View3D应用程序
scripts/build_view3d.bat   # Windows
./scripts/build_view3d.sh  # Linux
```

### 生成的Docker镜像

- `pchuan98/debian-builder11` - 带构建工具的基础Debian
- `pchuan98/occt` - OCCT库安装到 `/opt/occt`
- `pchuan98/view3d-arm64` - 带View3D的完整应用程序

### 部署到目标设备

```bash
# 传输View3D应用程序到RK3566
scp -r view3d-arm64 user@rk3566-ip:/home/user/view3d

# 在目标设备上安装
sudo mv /home/user/view3d /opt/view3d
sudo chmod -R 755 /opt/view3d
export LD_LIBRARY_PATH=/opt/occt/lib:/opt/view3d/lib:$LD_LIBRARY_PATH
```

### 测试安装

```bash
# 在RK3566设备上 - 测试OCCT
/opt/occt/bin/draw.sh

# 测试View3D应用程序
/opt/view3d/bin/view3d
```

## 项目结构

```
├── scripts/
│   ├── build_all.bat     # 构建所有组件 (Windows)
│   ├── build_all.sh      # 构建所有组件 (Linux)  
│   ├── build_base.bat    # 构建基础镜像 (Windows)
│   ├── build_base.sh     # 构建基础镜像 (Linux)
│   ├── build_occt.bat    # 构建OCCT镜像 (Windows)
│   ├── build_occt.sh     # 构建OCCT镜像 (Linux)
│   ├── build_view3d.bat  # 构建View3D镜像 (Windows)
│   └── build_view3d.sh   # 构建View3D镜像 (Linux)
├── build/
│   ├── Dockerfile.base   # 带构建工具的基础Debian
│   ├── Dockerfile.occt   # OCCT编译和运行时
│   └── Dockerfile.view3d # View3D应用程序构建
├── src/
│   ├── CMakeLists.txt    # 优化的View3D构建配置
│   └── ...               # View3D源文件
├── CLAUDE.md             # Claude代码开发指南
├── README.md             # 英文文档
├── README_zh.md          # 中文文档
└── occt/                 # OCCT子模块(忽略)
```

## 构建配置

### Docker构建架构

1. **基础阶段** (`Dockerfile.base`): 带构建工具和依赖的Debian 11
2. **OCCT阶段** (`Dockerfile.occt`): OCCT编译和运行时库
3. **View3D阶段** (`Dockerfile.view3d`): 自定义View3D应用程序构建

### 构建依赖

- 基础镜像提供: GCC, CMake, OpenGL ES, X11 和开发库
- OCCT库编译并安装到 `/opt/occt`
- View3D应用程序链接优化的OCCT库

### 构建特性

- **目标平台**: ARM64 (linux/arm64)
- **基础镜像**: 使用USTC中国镜像源优化的Debian 11
- **图形支持**: 启用OpenGL, OpenGL ES 3.2
- **库支持**: FreeImage, FreeType, RapidJSON
- **优化**: 多线程并行构建

### CMake配置

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

## 开发指南

### 命名规范
- 使用驼峰式命名
- 仅使用英文命名

### 内存管理
- 优先使用智能指针和标准容器
- 避免对托管对象使用裸指针

## 故障排除

### Docker构建问题

**证书错误**:
- 构建使用USTC镜像源以加速中国区下载
- 如遇证书问题，请检查`build/Dockerfile`中的镜像配置

**构建失败**:
- 分阶段调试构建:
  ```bash
  docker buildx build --target base -t occt-base .
  docker buildx build --target builder -t occt-builder .
  ```

### RK3566运行时问题

**OpenGL问题**:
```bash
# 安装Mesa驱动
sudo apt install mesa-utils libgl1-mesa-glx:arm64

# 验证OpenGL支持
glxinfo | grep OpenGL
```

**依赖错误**:
```bash
# 检查缺失的库
ldd /opt/occt/bin/draw.sh

# 安装所需的arm64软件包
sudo apt install [缺失的包]:arm64
```

## 验证步骤

1. ✅ 启用多架构支持和buildx
2. ✅ 确认Docker镜像构建无证书错误
3. ✅ 验证所有构建阶段成功完成
4. ✅ 检查从运行时阶段提取OCCT是否正常
5. ✅ 测试RK3566上`draw.sh`能否运行(带OpenGL)
6. ✅ 在目标设备上测试OCCT示例模型

## GPU配置说明

- **Mali G52**: 支持OpenGL ES 3.2和Vulkan 1.1
- **X11桌面**: 使用`-DUSE_OPENGL=ON`
- **Wayland**: 考虑`-DUSE_EGL=ON`

## 构建优化

- 多阶段构建减小最终镜像体积
- USTC镜像源加速中国区下载
- 浅克隆减少下载时间
- 分离阶段便于缓存和调试

## 许可证

本项目遵循Open CASCADE Technology (OCCT)的许可条款。具体许可信息请参考OCCT文档。

## 贡献指南

请仅关注项目特定文件。`occt/`文件夹是子模块，应忽略。自定义功能应在单独的项目目录中实现。