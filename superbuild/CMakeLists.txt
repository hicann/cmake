# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

cmake_minimum_required(VERSION 3.16.3)
project(cann_superbuild)

option(ENABLE_CCACHE "Enable ccache capability" ON)
option(ENABLE_PACKAGE "Enable packing operation" OFF)

set(HOST_TOOLCHAIN "native-toolchain.cmake" CACHE STRING "host toolchain")
set(DEVICE_TOOLCHAIN "aarch64-hcc-toolchain.cmake" CACHE STRING "device toolchain")

get_filename_component(TOP_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
get_filename_component(CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)

include(ExternalProject)
include(CMakePrintHelpers)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type (default Release)" FORCE)
endif()

if(CMAKE_INSTALL_PREFIX STREQUAL /usr/local)
    set(CMAKE_INSTALL_PREFIX ${TOP_DIR}/output CACHE STRING "path for install()" FORCE)
endif()

foreach(FEATURE ${FEATURE_LIST})
    string(REPLACE "=" ";" TEMP ${FEATURE})
    set(${TEMP} CACHE STRING "feature" FORCE)
endforeach()

add_custom_target(all_compile ALL)

execute_process(COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_DIR}/superbuild/sub_project.cmake ${TOP_DIR}/CMakeLists.txt)


set(BUILD_WRAPPER "${CMAKE_DIR}/superbuild/build_ext.sh")
if(CMAKE_GENERATOR MATCHES "Unix Makefiles")
    set(USING_MAKE TRUE)
else()
    set(USING_MAKE FALSE)
endif()

if(IS_ABSOLUTE ${HOST_TOOLCHAIN})
    set(HOST_TOOLCHAIN_FILE ${HOST_TOOLCHAIN})
else()
    set(HOST_TOOLCHAIN_FILE ${CMAKE_DIR}/toolchain/${HOST_TOOLCHAIN})
endif()

if(IS_ABSOLUTE ${DEVICE_TOOLCHAIN})
    set(DEVICE_TOOLCHAIN_FILE ${DEVICE_TOOLCHAIN})
else()
    set(DEVICE_TOOLCHAIN_FILE ${CMAKE_DIR}/toolchain/${DEVICE_TOOLCHAIN})
endif()

if(DEFINED ENV{TOOLCHAIN_HOME})
    set(TOOLCHAIN_DIR $ENV{TOOLCHAIN_HOME}/tools/hcc)
else()
    message(WARNING "Environment variable TOOLCHAIN_DIR is not set.")
endif()

include(${CMAKE_DIR}/superbuild/host.cmake)
include(${CMAKE_DIR}/superbuild/device.cmake)