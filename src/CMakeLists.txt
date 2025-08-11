cmake_minimum_required(VERSION 3.13)
project(View3DHandlerA VERSION 1.0.0 LANGUAGES CXX)

# Find required packages
find_package(OpenCASCADE REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(X11 REQUIRED x11)

# ARM64 OpenGL ES support
if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64")
    pkg_check_modules(EGL REQUIRED egl)
    pkg_check_modules(GLES2 REQUIRED glesv2)
endif()

# Source files
file(GLOB_RECURSE SOURCES "*.cpp")
file(GLOB_RECURSE HEADERS "*.h")

# Create shared library
add_library(View3DHandler SHARED ${SOURCES} ${HEADERS})

# Include directories
target_include_directories(View3DHandler PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${OpenCASCADE_INCLUDE_DIR}
    ${X11_INCLUDE_DIRS}
)

# Complete OCCT libraries (matching vcxproj configuration)
set(OCCT_CORE_LIBS TKernel TKMath TKBO TKBRep TKFeat TKXSBase TKService TKV3d TKOffset TKPrim TKFillet TKBool TKTopAlgo TKGeomBase TKGeomAlgo TKG2d TKG3d TKShHealing)
set(OCCT_IO_LIBS TKDEIGES TKDESTEP TKDESTL TKDEVRML)
set(OCCT_CAF_LIBS TKLCAF TKCAF)

# Link libraries
target_link_libraries(View3DHandler PRIVATE
    ${OCCT_CORE_LIBS}
    ${OCCT_IO_LIBS}
    ${OCCT_CAF_LIBS}
    ${X11_LIBRARIES}
)

# ARM64 specific libraries and includes
if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64")
    target_link_libraries(View3DHandler PRIVATE
        TKOpenGles
        ${EGL_LIBRARIES}
        ${GLES2_LIBRARIES}
    )
    target_include_directories(View3DHandler PRIVATE
        ${EGL_INCLUDE_DIRS}
        ${GLES2_INCLUDE_DIRS}
    )
else()
    target_link_libraries(View3DHandler PRIVATE TKOpenGl)
endif()

# Target properties and compiler flags
set_target_properties(View3DHandler PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
    POSITION_INDEPENDENT_CODE ON
    INSTALL_RPATH "/opt/occt/lib"
    BUILD_WITH_INSTALL_RPATH TRUE
    OUTPUT_NAME "View3DHandler"
    PREFIX ""
)

target_compile_options(View3DHandler PRIVATE
    -Wall -Wextra
    $<$<CONFIG:Release>:-O3 -DNDEBUG>
    $<$<CONFIG:Debug>:-g -O0>

    # ignore warn
    $<$<CXX_COMPILER_ID:GNU>:-w>
    $<$<CXX_COMPILER_ID:Clang>:-w>
    $<$<CXX_COMPILER_ID:MSVC>:/w>
)

# Install targets
install(TARGETS View3DHandler
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

install(FILES ${HEADERS}
    DESTINATION include/View3DHandler
)
