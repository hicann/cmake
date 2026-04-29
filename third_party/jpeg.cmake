# ----------------------------------------------------------------------------
# This program is free software, you can redistribute it and/or modify it.
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This file is a part of the CANN Open Software.
# Licensed under CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING
# BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. See LICENSE in the root of
# the software repository for the full text of the License.
# ----------------------------------------------------------------------------
include_guard(GLOBAL)

set(JPEG_TAR_PKG_PATH ${CANN_3RD_LIB_PATH}/libjpeg-turbo/libjpeg-turbo-3.0.1.tar.gz)
if(EXISTS "${JPEG_TAR_PKG_PATH}")
    set(REQ_URL "${JPEG_TAR_PKG_PATH}")
else()
    set(REQ_URL "https://gitcode.com/cann-src-third-party/libjpeg-turbo/releases/download/v3.0.1/libjpeg-turbo-3.0.1.tar.gz")
endif()

set(JPEG_C_FLAGS "-fPIC -fexceptions -D_FORTIFY_SOURCE=2 -O2 -fvisibility=hidden -DCONFIG_MASK_JWARN")
set(JPEG_INSTALL_PATH ${CMAKE_CURRENT_BINARY_DIR}/libjpeg-turbo)


include(ExternalProject)
ExternalProject_Add(third_party_jpeg
    URL ${REQ_URL}
    TLS_VERIFY OFF
    DOWNLOAD_EXTRACT_TIMESTAMP true
    CONFIGURE_COMMAND ${CMAKE_COMMAND}
        -DCMAKE_C_COMPILER_LAUNCHER=${CCACHE_PROGRAM}
        -DTOOLCHAIN_DIR=${TOOLCHAIN_DIR}
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
        -DCMAKE_C_FLAGS=${JPEG_C_FLAGS}
        -DCMAKE_INSTALL_PREFIX=${JPEG_INSTALL_PATH}
        -DCMAKE_INSTALL_DEFAULT_LIBDIR=lib
        -DENABLE_SHARED=FALSE
        -DWITH_JPEG8=ON
        -DWITH_SIMD=ON
    <SOURCE_DIR>
    BUILD_COMMAND $(MAKE)
    INSTALL_COMMAND $(MAKE) install
    EXCLUDE_FROM_ALL TRUE
)

file(MAKE_DIRECTORY ${JPEG_INSTALL_PATH}/include)

add_library(jpeg STATIC IMPORTED)
set_target_properties(jpeg PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${JPEG_INSTALL_PATH}/include"
    IMPORTED_LOCATION             "${JPEG_INSTALL_PATH}/lib/libjpeg.a"
)
add_dependencies(jpeg third_party_jpeg)

add_library(jpeg_headers INTERFACE)
target_include_directories(jpeg_headers INTERFACE ${JPEG_INSTALL_PATH}/include)
add_dependencies(jpeg_headers third_party_jpeg)

add_library(static_turbojpeg STATIC IMPORTED)
set_target_properties(static_turbojpeg PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${JPEG_INSTALL_PATH}/include"
    IMPORTED_LOCATION             "${JPEG_INSTALL_PATH}/lib/libturbojpeg.a"
)
add_dependencies(static_turbojpeg third_party_jpeg)
