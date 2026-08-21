# ----------------------------------------------------------------------------
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# ----------------------------------------------------------------------------
include_guard(GLOBAL)

unset(pybind11_FOUND CACHE)
unset(PYBIND11_INCLUDE CACHE)

set(PYBIND11_DOWNLOAD_PATH ${CANN_3RD_LIB_PATH}/pkg)
set(PYBIND11_INSTALL_PATH ${CANN_3RD_LIB_PATH}/lib_cache/pybind11)

find_path(PYBIND11_INCLUDE
    NAMES pybind11/pybind11.h
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
    PATHS ${PYBIND11_INSTALL_PATH}/include ${Python3_SITELIB}/pybind11/include
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(pybind11
    FOUND_VAR
        pybind11_FOUND
    REQUIRED_VARS
        PYBIND11_INCLUDE
)
if(pybind11_FOUND AND NOT FORCE_REBUILD_CANN_3RD)
    message(STATUS "[ThirdParty][pybind11] found in ${PYBIND11_INCLUDE}, and not force rebuild cann third_party")
    set(pybind11_INCLUDE_DIR ${PYBIND11_INCLUDE})
else()
    set(REQ_URL "https://gitcode.com/cann-src-third-party/pybind11/releases/download/v2.13.6/pybind11-2.13.6.tar.gz")
    set(PYBIND11_ARCHIVE ${PYBIND11_DOWNLOAD_PATH}/pybind11-2.13.6.tar.gz)

    if(EXISTS ${PYBIND11_ARCHIVE})
        message(STATUS "[ThirdParty][pybind11] found archive at ${PYBIND11_ARCHIVE}")
        set(PYBIND11_URL_ARGS URL ${PYBIND11_ARCHIVE})
    elseif(EXISTS ${CANN_3RD_LIB_PATH}/pybind11-2.13.6.tar.gz)
        message(STATUS "[ThirdParty][pybind11] found archive at ${CANN_3RD_LIB_PATH}/pybind11-2.13.6.tar.gz")
        set(PYBIND11_URL_ARGS URL ${CANN_3RD_LIB_PATH}/pybind11-2.13.6.tar.gz)
    else()
        message(STATUS "[ThirdParty][pybind11] not found, need download from ${REQ_URL}")
        set(PYBIND11_URL_ARGS
            URL ${REQ_URL}
            URL_HASH SHA256=e08cb87f4773da97fa7b5f035de8763abc656d87d5773e62f6da0587d1f0ec20
        )
    endif()

    include(ExternalProject)
    ExternalProject_Add(pybind11_build
        ${PYBIND11_URL_ARGS}
        TIMEOUT 300
        DOWNLOAD_DIR ${PYBIND11_DOWNLOAD_PATH}
        SOURCE_DIR ${PYBIND11_INSTALL_PATH}
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        INSTALL_COMMAND ""
        EXCLUDE_FROM_ALL TRUE
    )

    set(pybind11_INCLUDE_DIR ${PYBIND11_INSTALL_PATH}/include)
endif()

add_library(pybind11 INTERFACE)
target_include_directories(pybind11 SYSTEM INTERFACE "${pybind11_INCLUDE_DIR}")
if(TARGET pybind11_build)
    add_dependencies(pybind11 pybind11_build)
endif()
