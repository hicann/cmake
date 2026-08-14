# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------
include_guard(GLOBAL)
include(ExternalProject)

set(ZLIB_INSTALL_DIR ${CANN_3RD_LIB_PATH}/lib_cache/zlib)
set(ZLIB_INCLUDE_DIR ${ZLIB_INSTALL_DIR}/include)
if(NOT EXISTS ${ZLIB_INCLUDE_DIR})
    file(MAKE_DIRECTORY "${ZLIB_INCLUDE_DIR}")
endif()

set(ZLIB_LIBRARY ${ZLIB_INSTALL_DIR}/lib/libz.a)
add_library(zlib_static STATIC IMPORTED)
set_target_properties(zlib_static PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${ZLIB_INCLUDE_DIR}"
    IMPORTED_LOCATION             "${ZLIB_LIBRARY}"
)

set(MINIZIP_LIBRARY ${ZLIB_INSTALL_DIR}/lib/libminizip.a)
add_library(minizip_static STATIC IMPORTED)
set_target_properties(minizip_static PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${ZLIB_INCLUDE_DIR}"
    IMPORTED_LOCATION             "${MINIZIP_LIBRARY}"
    # 自动添加libminizip.a对libz.a的依赖
    INTERFACE_LINK_LIBRARIES ${ZLIB_LIBRARY}
)

set(ZLIB_GZ_HASH SHA256=1525952a0a567581792613a9723333d7f8cc20b87a81f920fb8bc7e3f2251428)
set(ZLIB_XZ_HASH SHA256=d14c38e313afc35a9a8760dadf26042f51ea0f5d154b0630a31da0540107fb98)

if(EXISTS "${CANN_3RD_LIB_PATH}/zlib/zlib-1.2.13.tar.xz")
    set(REQ_URL "${CANN_3RD_LIB_PATH}/zlib/zlib-1.2.13.tar.xz")
    set(ZLIB_URL_HASH ${ZLIB_XZ_HASH})
    message(STATUS "[ThirdParty][zlib] ${REQ_URL} found.")
elseif(EXISTS "${CANN_3RD_LIB_PATH}/zlib/zlib-1.2.13.tar.gz")
    set(REQ_URL "${CANN_3RD_LIB_PATH}/zlib/zlib-1.2.13.tar.gz")
    set(ZLIB_URL_HASH ${ZLIB_GZ_HASH})
    message(STATUS "[ThirdParty][zlib] ${REQ_URL} found.")
elseif(EXISTS "${CANN_3RD_LIB_PATH}/zlib-1.2.13.tar.gz")
    set(REQ_URL "${CANN_3RD_LIB_PATH}/zlib-1.2.13.tar.gz")
    set(ZLIB_URL_HASH ${ZLIB_GZ_HASH})
    message(STATUS "[ThirdParty][zlib] ${REQ_URL} found.")
else()
    set(REQ_URL "https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/zlib/zlib-1.2.13.tar.gz")
    set(ZLIB_URL_HASH ${ZLIB_GZ_HASH})
    message(STATUS "[ThirdParty][zlib] ${REQ_URL} not found, need download.")
endif()
ExternalProject_Add(zlib_src
    URL ${REQ_URL}
    URL_HASH ${ZLIB_URL_HASH}
    TIMEOUT 300
    PATCH_COMMAND patch --forward --batch --quiet -r - -p1 < ${CMAKE_CURRENT_LIST_DIR}/patch/zlib_add_minizip_static_lib.patch
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    EXCLUDE_FROM_ALL TRUE
)
ExternalProject_Get_Property(zlib_src SOURCE_DIR)
set(ZLIB_SRC_DIR ${SOURCE_DIR})

if(EXISTS ${ZLIB_LIBRARY} AND EXISTS ${MINIZIP_LIBRARY})
    message(STATUS "zlib lib found in ${ZLIB_LIBRARY}.")
else()
    set(ZLIB_C_FLAGS "-fPIC -fexceptions -O2")
    ExternalProject_Add(zlib_bin_build
        DOWNLOAD_COMMAND ""
        UPDATE_COMMAND ""
        SOURCE_DIR ${ZLIB_SRC_DIR}
        CONFIGURE_COMMAND ${CMAKE_COMMAND}
            -DCMAKE_INSTALL_PREFIX=${ZLIB_INSTALL_DIR}
            -DCMAKE_C_FLAGS=${ZLIB_C_FLAGS}
            -DCMAKE_POLICY_VERSION_MINIMUM=3.5
            -DCMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER}
            -DCMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER}
            -DLLVM_PATH=${LLVM_PATH}
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
            <SOURCE_DIR>
        BUILD_COMMAND $(MAKE)
        INSTALL_COMMAND $(MAKE) install
        DEPENDS zlib_src
        EXCLUDE_FROM_ALL TRUE
    )
    add_dependencies(zlib_static zlib_bin_build)
    add_dependencies(minizip_static zlib_bin_build)
endif()
