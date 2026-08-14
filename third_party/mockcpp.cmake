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

if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "aarch64")
    set(mockcpp_CXXFLAGS "-fPIC")
else()
    set(mockcpp_CXXFLAGS "-fPIC -std=c++11")
endif()
set(mockcpp_FLAGS "-fPIC")
set(mockcpp_LINKER_FLAGS "")

set(mockcpp_CXXFLAGS "${mockcpp_CXXFLAGS} -D_GLIBCXX_USE_CXX11_ABI=${CANN_CXX11_ABI}")

#依赖蓝区二进制仓mockcpp
set(FILE_NAME mockcpp-2.7.tar.gz)
set(BOOST_INCLUDE_DIR ${CANN_3RD_LIB_PATH}/boost)
set(MOCKCPP_DOWNLOAD_PATH ${CANN_3RD_LIB_PATH}/pkg)
set(MOCKCPP_SOURCE_PATH ${CANN_3RD_LIB_PATH}/mockcpp)
set(MOCK_INSTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/mockcpp)

message(STATUS "[ThirdParty][mockcpp] cmake install prefix ${CMAKE_INSTALL_PREFIX}")
include(ExternalProject)

if(EXISTS ${CANN_3RD_LIB_PATH}/mockcpp-2.7-h5.patch)
    set(PATCH_FILE "${CANN_3RD_LIB_PATH}/mockcpp-2.7-h5.patch")
    message(STATUS "[ThirdParty][mockcpp] patch use cache: ${PATCH_FILE}")
    add_custom_target(mockcpp_patch)
elseif(EXISTS ${MOCKCPP_DOWNLOAD_PATH}/mockcpp-2.7-h5.patch)
    set(PATCH_FILE ${MOCKCPP_DOWNLOAD_PATH}/mockcpp-2.7-h5.patch)
    message(STATUS "[ThirdParty][mockcpp] patch use cache: ${PATCH_FILE}")
    add_custom_target(mockcpp_patch)
else()
    set(PATCH_FILE ${MOCKCPP_DOWNLOAD_PATH}/mockcpp-2.7-h5.patch)
    ExternalProject_Add(mockcpp_patch
        URL "https://gitcode.com/cann-src-third-party/mockcpp/releases/download/v2.7-h5/mockcpp-2.7-h5.patch"
        URL_HASH SHA256=65a2aac5e8ffe1a0eb983e4455972ef70b9850d4283ea7d4cc83e3cb97e98c5e
        DOWNLOAD_DIR ${MOCKCPP_DOWNLOAD_PATH}
        DOWNLOAD_NO_EXTRACT TRUE
        DOWNLOAD_NO_PROGRESS TRUE
        TIMEOUT 60
        UPDATE_COMMAND ""
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        INSTALL_COMMAND ""
        EXCLUDE_FROM_ALL TRUE
    )
    message(STATUS "[ThirdParty][mockcpp] patch need download to: ${PATCH_FILE}")
endif()

message(STATUS "[ThirdParty][mockcpp] CMAKE_COMMAND is ${CMAKE_COMMAND}")
if(EXISTS ${CANN_3RD_LIB_PATH}/mockcpp/${FILE_NAME})
    set(REQ_URL ${CANN_3RD_LIB_PATH}/mockcpp/${FILE_NAME})
    message(STATUS "[ThirdParty][mockcpp] use cache file: ${REQ_URL}")
elseif(EXISTS ${CANN_3RD_LIB_PATH}/${FILE_NAME})
    set(REQ_URL ${CANN_3RD_LIB_PATH}/${FILE_NAME})
    message(STATUS "[ThirdParty][mockcpp] use local tar.gz: ${REQ_URL}")
else()
    set(REQ_URL "https://cann-3rd.obs.cn-north-4.myhuaweicloud.com/mockcpp/mockcpp-2.7.tar.gz")
    message(STATUS "[ThirdParty][mockcpp] not use cache, new url file: ${REQ_URL}")
endif()

ExternalProject_Add(mockcpp_static_build
    URL ${REQ_URL}
    URL_HASH SHA256=73ab0a8b6d1052361c2cebd85e022c0396f928d2e077bf132790ae3be766f603
    TIMEOUT 300
    DEPENDS third_party_boost mockcpp_patch
    DOWNLOAD_DIR ${MOCKCPP_DOWNLOAD_PATH}
    SOURCE_DIR ${MOCKCPP_SOURCE_PATH}
    PATCH_COMMAND patch --forward --batch --quiet -r - -p1 < ${PATCH_FILE}
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -G ${CMAKE_GENERATOR}
        -DCMAKE_CXX_FLAGS=${mockcpp_CXXFLAGS}
        -DCMAKE_C_FLAGS=${mockcpp_FLAGS}
        -DCMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER}
        -DCMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER}
        -DBOOST_INCLUDE_DIRS=${BOOST_INCLUDE_DIR}
        -DCMAKE_SHARED_LINKER_FLAGS=${mockcpp_LINKER_FLAGS}
        -DCMAKE_EXE_LINKER_FLAGS=${mockcpp_LINKER_FLAGS}
        -DBUILD_32_BIT_TARGET_BY_64_BIT_COMPILER=OFF
        -DCMAKE_INSTALL_PREFIX=${MOCK_INSTALL_PATH}
        <SOURCE_DIR>
    EXCLUDE_FROM_ALL TRUE
)

if(NOT EXISTS ${MOCK_INSTALL_PATH}/include)
    file(MAKE_DIRECTORY ${MOCK_INSTALL_PATH}/include)
endif()

# use for asc_devkit service
set(MOCKCPP_INCLUDE_ONE ${MOCK_INSTALL_PATH}/include)
set(MOCKCPP_INCLUDE_TWO ${BOOST_INCLUDE_DIR})
set(MOCKCPP_STATIC_LIBRARY ${MOCK_INSTALL_PATH}/lib/libmockcpp.a)

set(MOCKCPP_INCLUDE_DIR ${MOCKCPP_INCLUDE_ONE} ${MOCKCPP_INCLUDE_TWO})
get_filename_component(MOCKCPP_LIBRARY_DIR ${MOCKCPP_STATIC_LIBRARY} DIRECTORY)

add_library(mockcpp STATIC IMPORTED)
set_target_properties(mockcpp PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${MOCKCPP_INCLUDE_DIR}"
    IMPORTED_LOCATION "${MOCKCPP_STATIC_LIBRARY}"
)
add_dependencies(mockcpp mockcpp_static_build)
