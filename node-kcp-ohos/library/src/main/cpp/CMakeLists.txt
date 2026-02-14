# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(KCP)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include)

# KCP source files
set(KCP_SOURCES
    ${NATIVERENDER_ROOT_PATH}/kcp/ikcp.c
)

# Note: CMake will automatically add 'lib' prefix to generate 'libkcp.so'
add_library(kcp SHARED 
    napi_init.cpp
    ${KCP_SOURCES}
)

target_link_libraries(kcp PUBLIC 
    libace_napi.z.so
    libhilog_ndk.z.so
)

