# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of 
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

if (TARGET symengine_build)
    return()
endif ()

add_library(symengine_static STATIC IMPORTED)
if(NOT EXISTS ${CANN_3RD_LIB_PATH}/symengine/include)
    file(MAKE_DIRECTORY "${CANN_3RD_LIB_PATH}/symengine/include")
endif()
set_target_properties(symengine_static PROPERTIES
    IMPORTED_LOCATION "${CANN_3RD_LIB_PATH}/symengine/lib/libsymengine.a"
    INTERFACE_INCLUDE_DIRECTORIES "${CANN_3RD_LIB_PATH}/symengine/include"
)

include(ExternalProject)

set(LIB_FILE "${CANN_3RD_LIB_PATH}/symengine/lib") # 编译之后才会有的文件，用于判断是否已经编译
set(MOD_FILE "${CANN_3RD_LIB_PATH}/symengine/symengine/mod.cpp") # 打上patch之后才会有的文件,用于判断是否打了patch
set(CMAKE_FILE "${CANN_3RD_LIB_PATH}/symengine/CMakeLists.txt") # 用于判断是否已下载并解压
set(REQ_URL "${CANN_3RD_LIB_PATH}/symengine/symengine-0.12.0.tar.gz")
set(SYMENGINE_EXTRA_ARGS "")
if(EXISTS ${LIB_FILE})
    message(STATUS "[ThirdParty][symengine] ${LIB_FILE} found, symengine is ready after compile.")
else()
    if(EXISTS ${MOD_FILE})
        message(STATUS "[ThirdParty][symengine] ${MOD_FILE} found, symengine is ready with patch installed.")
    elseif(EXISTS ${CMAKE_FILE})
        message(STATUS "[ThirdParty][symengine] ${CMAKE_FILE} found, symengine is ready without patch installed.")
        list(APPEND SYMENGINE_EXTRA_ARGS
            PATCH_COMMAND patch -p1 < ${CMAKE_CURRENT_LIST_DIR}/symengine_add_mod.patch
        )
    elseif(EXISTS ${REQ_URL})
        message(STATUS "[ThirdParty][symengine] ${REQ_URL} found.")
        list(APPEND SYMENGINE_EXTRA_ARGS
            URL ${REQ_URL}
            PATCH_COMMAND patch -p1 < ${CMAKE_CURRENT_LIST_DIR}/symengine_add_mod.patch
        )
    else()
        message(STATUS "[ThirdParty][symengine] symengine not found, need download.")
        set(REQ_URL "https://gitcode.com/cann-src-third-party/symengine/releases/download/v0.12.0/symengine-0.12.0.tar.gz")
        list(APPEND SYMENGINE_EXTRA_ARGS
            URL ${REQ_URL}
            DOWNLOAD_DIR ${CANN_3RD_LIB_PATH}/symengine
            PATCH_COMMAND patch -p1 < ${CMAKE_CURRENT_LIST_DIR}/symengine_add_mod.patch
        )
    endif()
    set(SYMENGINE_CXXFLAGS "-fPIC -D_GLIBCXX_USE_CXX11_ABI=0 -std=c++17")
    ExternalProject_Add(symengine_build
            SOURCE_DIR ${CANN_3RD_LIB_PATH}/symengine
            ${SYMENGINE_EXTRA_ARGS}
            TLS_VERIFY OFF
            CONFIGURE_COMMAND ${CMAKE_COMMAND}
                -DINTEGER_CLASS:STRING=boostmp
                -DBUILD_SHARED_LIBS:BOOL=OFF
                -DBOOST_ROOT=${CANN_3RD_LIB_PATH}/boost-1.87.0
                -DBUILD_TESTS=off
                -DCMAKE_POLICY_VERSION_MINIMUM=3.5
                -DCMAKE_CXX_STANDARD=17
                -DWITH_SYMENGINE_THREAD_SAFE:BOOL=ON
                -DCMAKE_CXX_EXTENSIONS=OFF
                -DCMAKE_CXX_FLAGS=${SYMENGINE_CXXFLAGS}
                -DCMAKE_INSTALL_PREFIX=${CANN_3RD_LIB_PATH}/symengine
                -DCMAKE_PREFIX_PATH=${CANN_3RD_LIB_PATH}/boost-1.87.0
                <SOURCE_DIR>
            BUILD_COMMAND $(MAKE)
            INSTALL_COMMAND $(MAKE) install
            EXCLUDE_FROM_ALL TRUE
            )
    include(${CMAKE_CURRENT_LIST_DIR}/boost.cmake)
    add_dependencies(symengine_build third_party_boost)
    add_dependencies(symengine_static symengine_build)
endif()
