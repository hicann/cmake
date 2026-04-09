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
project(cann LANGUAGES C CXX ASM)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(ENABLE_CCACHE "Enable ccache capability" ON)
option(ENABLE_ASAN "Enable asan capability" OFF)
set(CMAKE_FRAMEWORK "cmake_framework" CACHE STRING "cmake framework dir")

get_filename_component(TOP_DIR "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)
get_filename_component(CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)
get_filename_component(CANN_PROJECT_NAME "${CMAKE_CURRENT_BINARY_DIR}" NAME)

include(${CMAKE_FRAMEWORK}/function/function.cmake)

if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type (Default Release)" FORCE)
    message(STATUS "No build type selected, Default to Release.")
endif()

foreach(FEATURE ${FEATURE_LIST})
    string(REPLACE "=" ";" TEMP ${FEATURE})
    set(${TEMP} CACHE STRING "feature" FORCE)
    message(STATUS "Feature setting : ${TEMP}")
endforeach()

if(ENABLE_CCACHE)
    find_program(CCACHE_PROGRAM ccache)
    if(CCACHE_PROGRAM)
        set(CMAKE_C_COMPILER_LAUNCHER ${CCACHE_PROGRAM} CACHE PATH "Ccache C Compiler")
        set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE_PROGRAM} CACHE PATH "Ccache CXX Compiler")
    endif()
endif()

add_custom_target(all_pkgs ALL)
string(TOUPPER ${PRODUCT_SIDE} UPPERSIDE)
set(DIRS)
foreach(PKG_NAME ${PACKAGE})
    add_custom_target(pkg_${PKG_NAME})
    add_dependencies(all_pkgs pkg_${PKG_NAME})

    set(PKG_CONFIG "${CMAKE_FRAMEWORK}/config/${PKG_NAME}_config.cmake")

    if("${PRODUCT_SIDE}" STREQUAL "host")
        set(PKG_DIR ${PKG_NAME})
    else()
        set(PKG_DIR ${PKG_NAME}/cmake/device)
    endif()

    if(EXISTS "${PKG_CONFIG}")
        include(${PKG_CONFIG})
        string(TOUPPER ${PKG_NAME} UPPERPKG)
        list(APPEND DIRS ${${UPPERSIDE}_${UPPERPKG}_DIRS})
    elseif(EXISTS ${TOP_DIR}/${PKG_DIR})
        list(APPEND DIRS ${PKG_DIR})
        set(${PKG_NAME}_DIR ${PKG_DIR})

        get_project_dep_dirs(${PKG_NAME} ${TOP_DIR} PROJ_DEPS_DIRS)
        if(PROJ_DEPS_DIRS)
            list(APPEND DIRS ${PROJ_DEPS_DIRS})
        endif()
    endif()
endforeach()

list(TRANSFORM DIRS REPLACE "/$" "")
list(REMOVE_DUPLICATES DIRS)
foreach(DIR ${DIRS})
    if(EXISTS ${TOP_DIR}/${DIR}/CMakeLists.txt)
        add_subdirectory(${DIR})
    else()
        message(STATUS "Directory ${DIR} does not contains CMakeLists.txt!")
    endif()
endforeach()

foreach(PKG_NAME ${PACKAGE})
    if(${PKG_NAME}_DIR)
        unset(TARGETS_IN_DIR)
        get_build_targets_in_directory(TARGETS_IN_DIR ${${PKG_NAME}_DIR})
        if(TARGETS_IN_DIR)
            add_dependencies(pkg_${PKG_NAME} ${TARGETS_IN_DIR})
        endif()
    endif()

    unset(TARGETS_NAME)
    string(TOUPPER ${PKG_NAME} UPPERPKG)
    if(DEFINED ${UPPERSIDE}_${UPPERPKG}_TARGETS)
        set(TARGETS_NAME ${UPPERSIDE}_${UPPERPKG}_TARGETS)
    endif()

    if(TARGETS_NAME)
        filter_targets(TARGETS ${${TARGETS_NAME}})
        get_exists_targets(EXISTS_TARGETS ${TARGETS})
        if(EXISTS_TARGETS)
            add_dependencies(pkg_${PKG_NAME} ${EXISTS_TARGETS})
        endif()

        get_not_exists_targets(NOT_EXISTS_TARGETS ${TARGETS})
        if(NOT_EXISTS_TARGETS)
            message(WARNING "pkg_${PKG_NAME} depended target ${NOT_EXISTS_TARGETS} not defined in ${CANN_PROJECT_NAME}!")
        endif()
    endif()
endforeach()

get_cmake_property(_INSTALL_RULES INSTALL_RULES)
if(NOT _INSTALL_RULES)
    install(CODE "message(STATUS \"Skipping install for ${PROJECT_NAME} (no files to install)\")")
endif()

