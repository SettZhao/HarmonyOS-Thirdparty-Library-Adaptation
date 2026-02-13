# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(libmp4)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

# Include directories for libmp4 headers
include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include
                    ${NATIVERENDER_ROOT_PATH}/libmp4)

# Add compile definition for OpenHarmony logging
add_definitions(-DBUILD_OPENHARMONY)

# Collect all libmp4 C source files
file(GLOB LIBMP4_SOURCES
    ${NATIVERENDER_ROOT_PATH}/libmp4/*.c
)

# Build shared library with NAPI wrapper and libmp4 sources
# Note: Use 'mp4' (not 'libmp4') as the library name
# CMake will automatically add 'lib' prefix to generate 'libmp4.so'
add_library(mp4 SHARED 
    napi_init.cpp
    ${LIBMP4_SOURCES}
)

# Link required libraries
target_link_libraries(mp4 PUBLIC 
    libace_napi.z.so
    libhilog_ndk.z.so
)

