# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

cmake_minimum_required(VERSION 3.16.3)
project(cann_superbuild)

include(../function/function.cmake)
init_cann_superbuild_project(PRODUCT_SIDE "host")

get_pkg_dependencies("${CANN_PACKAGES}")
calc_device_packages()
set(ENABLE_BUILD_DEVICE FALSE)

get_package_dirs(CANN_DEPEND_PACKAGE_DIRS "${CANN_DEPEND_PACKAGES}")
foreach(CANN_DEPEND_PACKAGE_DIR IN LISTS CANN_DEPEND_PACKAGE_DIRS)
    # 这里不可以使用EXCLUDE_FROM_ALL，cmake会排除install命令，这不是期望的
    add_subdirectory(${CANN_TOP_DIR}/${CANN_DEPEND_PACKAGE_DIR} ${CANN_DEPEND_PACKAGE_DIR})
endforeach()

get_package_dirs(CANN_PACKAGE_DIRS "${CANN_PACKAGES}")
set_cann_all_targets("${CANN_PACKAGE_DIRS}")

set(TOOLCHAIN_DIR ${ASCEND_INSTALL_PATH}/toolkit/toolchain/hcc)
string(REPLACE ";" "::" EP_DEVICE_CANN_PACKAGES "${DEVICE_CANN_PACKAGES}")
string(REPLACE ";" "::" EP_DEVICE_CANN_DEPEND_PACKAGES "${DEVICE_CANN_DEPEND_PACKAGES}")

if(DEVICE_CANN_PACKAGES)
    include(ExternalProject)
    ExternalProject_Add(cann_device
        SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/device
        BINARY_DIR ${CMAKE_BINARY_DIR}/device_build
        CMAKE_ARGS
            -DENABLE_OPEN_SRC=TRUE
            -DENABLE_UNIFIED_BUILD=TRUE
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCANN_SUPERBUILD_CONFIG=${CANN_SUPERBUILD_CONFIG}
            -DTOOLCHAIN_DIR=${TOOLCHAIN_DIR}
            -DCMAKE_TOOLCHAIN_FILE=${CANN_CMAKE_DIR}/toolchain/aarch64-hcc-toolchain.cmake
            -DASCEND_INSTALL_PATH=${ASCEND_INSTALL_PATH}
            -DCANN_3RD_LIB_PATH=${CANN_3RD_LIB_PATH}
            -DCANN_PACKAGES=${EP_DEVICE_CANN_PACKAGES}
            -DCANN_DEPEND_PACKAGES=${EP_DEVICE_CANN_DEPEND_PACKAGES}
        INSTALL_COMMAND ${CMAKE_CPACK_COMMAND}
        LIST_SEPARATOR ::
        BUILD_ALWAYS TRUE
    )
    foreach(CANN_PACKAGE IN LISTS DEVICE_CANN_PACKAGES)
        install(FILES
            ${CMAKE_BINARY_DIR}/device_build/device-${CANN_PACKAGE}.tar.gz
            DESTINATION .
            COMPONENT ${CANN_PACKAGE}
        )
    endforeach()
endif()
