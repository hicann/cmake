# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------
# makeself.cmake - 自定义 makeself 打包脚本

include(${CMAKE_CURRENT_LIST_DIR}/pkg_func.cmake)

include(CMakePrintHelpers)

set(CMAKE_SYSTEM_PROCESSOR ${CPACK_TARGET_ARCH})
# 设置 makeself 路径
set(MAKESELF_EXE ${CPACK_MAKESELF_PATH}/makeself.sh)
set(MAKESELF_HEADER_EXE ${CPACK_MAKESELF_PATH}/makeself-header.sh)
if(NOT MAKESELF_EXE)
    message(FATAL_ERROR "makeself not found!")
endif()

function(pack_run_package component share_info_name source_dir enable_device)
    # 创建临时安装目录
    set(STAGING_DIR "${CPACK_CMAKE_BINARY_DIR}/_CPack_Packages/makeself_staging")
    file(REMOVE_RECURSE "${STAGING_DIR}")
    file(MAKE_DIRECTORY "${STAGING_DIR}")

    # 执行安装到临时目录
    execute_process(
        COMMAND "${CMAKE_COMMAND}" --install "${CPACK_CMAKE_BINARY_DIR}" --prefix "${STAGING_DIR}" --component "${component}"
        RESULT_VARIABLE INSTALL_RESULT
    )

    if(NOT INSTALL_RESULT EQUAL 0)
        message(FATAL_ERROR "Installation to staging directory failed: ${INSTALL_RESULT}")
    endif()

    pre_package_process("${component}" "${share_info_name}" "${source_dir}" "${enable_device}" "${STAGING_DIR}" "run")

    # makeself打包
    file(STRINGS ${CPACK_CMAKE_BINARY_DIR}/makeself.txt script_output)
    string(REPLACE " " ";" makeself_param_string "${script_output}")
    string(REGEX MATCH "cann.*\\.run" package_name "${makeself_param_string}")

    list(LENGTH makeself_param_string LIST_LENGTH)
    math(EXPR INSERT_INDEX "${LIST_LENGTH} - 2")
    list(INSERT makeself_param_string ${INSERT_INDEX} "${STAGING_DIR}")

    message(STATUS "script output: ${script_output}")
    message(STATUS "makeself: ${makeself_param_string}")
    message(STATUS "package: ${package_name}")

    if(NOT DEFINED CPACK_HELP_HEADER_PATH)
        set(CPACK_HELP_HEADER_PATH "share/info/${share_info_name}/script/help.info")
    endif()

    if(NOT DEFINED CPACK_INSTALL_PATH)
        set(CPACK_INSTALL_PATH "share/info/${share_info_name}/script/install.sh")
    endif()

    execute_process(COMMAND bash ${MAKESELF_EXE}
            --header ${MAKESELF_HEADER_EXE}
            --help-header ${CPACK_HELP_HEADER_PATH}
            ${makeself_param_string} ${CPACK_INSTALL_PATH}
            WORKING_DIRECTORY ${STAGING_DIR}
            RESULT_VARIABLE EXEC_RESULT
            ERROR_VARIABLE  EXEC_ERROR
    )

    if(NOT EXEC_RESULT EQUAL 0)
        message(FATAL_ERROR "makeself packaging failed: ${EXEC_ERROR}")
    endif()

    execute_process(
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CPACK_CMAKE_INSTALL_PREFIX}
        RESULT_VARIABLE MKDIR_INSTALL_PREFIX
    )

    if(MKDIR_INSTALL_PREFIX EQUAL 0)
        execute_process(
            COMMAND find . -name "cann-*.run"
            COMMAND xargs -I {} cp {} ${CPACK_CMAKE_INSTALL_PREFIX}/
            WORKING_DIRECTORY ${STAGING_DIR}
            RESULT_VARIABLE EXEC_RESULT
            ERROR_VARIABLE  EXEC_ERROR
        )

        if(NOT "${EXEC_RESULT}" STREQUAL "0")
            message(FATAL_ERROR "Failed to copy run files: ${EXEC_ERROR}")
        else()
            message(STATUS "Build pkg success: ${CPACK_CMAKE_INSTALL_PREFIX}/${package_name}")
        endif()
    else()
        message(FATAL_ERROR "Failed to mkdir new directory: ${CPACK_CMAKE_INSTALL_PREFIX}")
    endif()
endfunction()

list(LENGTH CPACK_COMPONENTS_ALL len_components)
list(LENGTH CPACK_PACKAGE_PARAM_NAME len_share_info_names)
if(NOT len_components EQUAL len_share_info_names)
    message(FATAL_ERROR "CPACK_COMPONENTS_ALL and CPACK_PACKAGE_PARAM_NAME is not one-to-one mapping.")
endif()

math(EXPR len_components "${len_components} - 1")
foreach(index RANGE ${len_components})
    list(GET CPACK_COMPONENTS_ALL ${index} component)
    list(GET CPACK_PACKAGE_PARAM_NAME ${index} share_info_name)
    list(GET CPACK_CMAKE_SOURCE_DIR ${index} source_dir)
    list(GET CPACK_ENABLE_DEVICE ${index} enable_device)
    pack_run_package("${component}" "${share_info_name}" "${source_dir}" "${enable_device}")
endforeach()
