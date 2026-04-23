# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

get_filename_component(CANN_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}" DIRECTORY)

if(NOT PROJECT_SOURCE_DIR)
    # 单仓编译
    set(TOPLEVEL_PROJECT ON)
else()
    # 多仓联编
    set(TOPLEVEL_PROJECT OFF)
endif()

function(__cann_print_summary)
    if(ENABLE_CCACHE)
        if(CCACHE_PROGRAM)
            set(CCACHE_FOUND_MSG "Found ccache, ")
        else()
            set(CCACHE_FOUND_MSG "Ccache not found, ")
        endif()
    else()
        set(CCACHE_FOUND_MSG "")
    endif()

    message(STATUS "Initialization summary: ${CCACHE_FOUND_MSG}TARGET_ARCH: ${TARGET_ARCH}")
endfunction()

function(__cann_get_target_arch)
    string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" ARCH_LOW)
    if (ARCH_LOW MATCHES "x86_64|amd64")
        set(TARGET_ARCH x86_64 PARENT_SCOPE)
    elseif (ARCH_LOW MATCHES "aarch64|arm64|arm")
        set(TARGET_ARCH aarch64 PARENT_SCOPE)
    else ()
        message(WARNING "Unknown architecture: ${CMAKE_SYSTEM_PROCESSOR}")
        set(TARGET_ARCH PARENT_SCOPE)
    endif()
endfunction()

# 设置cann工程公共参数
macro(init_cann_project)
    # 联合构建时，init函数可能被调用多次，保证第一次调用时生效，忽略后续调用
    if(NOT CANN_PROJECT_INITED)
        if(POLICY CMP0135)
            cmake_policy(SET CMP0135 NEW)
        endif()

        set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
        set(CMAKE_CXX_STANDARD 17)
        set(CMAKE_CXX_STANDARD_REQUIRED ON)
        set(CMAKE_CXX_EXTENSIONS OFF)

        set(CMAKE_CXX_COMPILE_OBJECT
            "<CMAKE_CXX_COMPILER> <DEFINES> -D__FILE__='\"$(notdir $(abspath <SOURCE>))\"' -Wno-builtin-macro-redefined <INCLUDES> <FLAGS> -o <OBJECT> -c <SOURCE>"
        )
        set(CMAKE_C_COMPILE_OBJECT
            "<CMAKE_C_COMPILER> <DEFINES> -D__FILE__='\"$(notdir $(abspath <SOURCE>))\"' -Wno-builtin-macro-redefined <INCLUDES> <FLAGS> -o <OBJECT> -c <SOURCE>"
        )

        option(ENABLE_CCACHE "Enable ccache" TRUE)
        if(ENABLE_CCACHE)
            find_program(CCACHE_PROGRAM ccache)
            if (CCACHE_PROGRAM)
                set(CMAKE_C_COMPILER_LAUNCHER ${CCACHE_PROGRAM})
                set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE_PROGRAM})
            endif()
        endif()

        if(TOPLEVEL_PROJECT OR ENABLE_UNIFIED_BUILD)
            # install时不添加OPTIONAL选项，以保证打包产物完整
            set(INSTALL_OPTIONAL)
        endif()

        set(TARGET_SYSTEM_NAME Linux)

        set(INSTALL_LIBRARY_DIR lib)
        set(INSTALL_RUNTIME_DIR bin)
        set(INSTALL_INCLUDE_DIR include)
        set(INSTALL_CONFIG_DIR cmake)

        # 组件使用ASCEND_INSTALL_PATH或ASCEND_CANN_PACKAGE_PATH作为cann包安装路径
        if(NOT ASCEND_INSTALL_PATH AND ASCEND_CANN_PACKAGE_PATH)
            set(ASCEND_INSTALL_PATH "${ASCEND_CANN_PACKAGE_PATH}")
        endif()

        __cann_get_target_arch()

        __cann_print_summary()
        set(CANN_PROJECT_INITED TRUE)
    endif()
endmacro()

# 包装 find_package，在联编/统一构建模式下跳过
macro(find_cann_package)
    if(TOPLEVEL_PROJECT)
        find_package(${ARGN})
    endif()
endmacro()

# 添加三方库
macro(add_cann_third_party name)
    include(${CANN_CMAKE_DIR}/third_party/${name}.cmake)
endmacro()

# 通过相对父目录方式添加子目录
function(add_cann_subdirectories_relative base_dir)
    foreach(source_dir ${ARGN})
        file(RELATIVE_PATH relative_dir "${base_dir}" "${source_dir}")
        add_subdirectory("${source_dir}" "${relative_dir}")
    endforeach()
endfunction()

# 设置打包配置
# component: 组件名
# NO_COMPONENT_INSTALL: 不带--component参数安装
# ENABLE_DEVICE: 是否解压device-${component}.tar.gz
# COMPUTE_UNIT: 芯片型号
# SHARE_INFO_NAME: 如果子包在share/info目录下的名字与component不一致，则需要设置
function(set_cann_cpack_config component)
    if(NOT TOPLEVEL_PROJECT AND NOT ENABLE_UNIFIED_BUILD)
        return()
    endif()

    cmake_parse_arguments(CANN "NO_COMPONENT_INSTALL" "ENABLE_DEVICE;COMPUTE_UNIT;SHARE_INFO_NAME" "" ${ARGN})

    add_cann_third_party(makeself-fetch)

    if(CANN_COMPUTE_UNIT)
        set(CPACK_SOC "${CANN_COMPUTE_UNIT}")
    endif()

    if(CANN_SHARE_INFO_NAME)
        set(CPACK_PACKAGE_PARAM_NAME "${CANN_SHARE_INFO_NAME}")
    else()
        set(CPACK_PACKAGE_PARAM_NAME "${component}")
    endif()

    set(CPACK_PACKAGE_NAME "${component}")
    set(CPACK_PACKAGE_VERSION "${CANN_VERSION_${component}_VERSION}")
    set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CMAKE_SYSTEM_NAME}")

    if(NOT CANN_NO_COMPONENT_INSTALL)
        set(CPACK_CANN_INSTALL_COMPONENT "${component}")
    endif()
    set(CPACK_CMAKE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    set(CPACK_CMAKE_BINARY_DIR "${CMAKE_BINARY_DIR}")
    set(CPACK_CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")
    set(CPACK_ENABLE_DEVICE "${CANN_ENABLE_DEVICE}")
    set(CPACK_GENERATOR External)
    set(CPACK_EXTERNAL_PACKAGE_SCRIPT "${CANN_CMAKE_DIR}/scripts/package/makeself.cmake")
    set(CPACK_EXTERNAL_ENABLE_STAGING TRUE)
    set(CPACK_PACKAGE_DIRECTORY "${CMAKE_BINARY_DIR}")
    set(CPACK_MAKESELF_PATH "${MAKESELF_PATH}")
    set(CPACK_BUILD_MODE "RUN_COPY")
    set(CPACK_TARGET_ARCH "${TARGET_ARCH}")
    include(CPack)
endfunction()

# 设置子工程打包
function(set_cann_subprj_package)
    get_cmake_property(CPACK_COMPONENTS_ALL COMPONENTS)
    list(REMOVE_ITEM CPACK_COMPONENTS_ALL "Unspecified")

    set(CPACK_GENERATOR TGZ)
    set(CPACK_ARCHIVE_COMPONENT_INSTALL ON)
    set(CPACK_ARCHIVE_FILE_NAME "${PRODUCT_SIDE}")
    include(CPack)
endfunction()

macro(__cann_replace_cur_major_minor_ver)
    string(REPLACE CUR_MAJOR_MINOR_VER "${CANN_VERSION_${CANN_VERSION_CURRENT_PACKAGE}_VERSION_MAJOR_MINOR}" depend "${depend}")
endmacro()

# 设置包和版本号
function(set_cann_package name)
    cmake_parse_arguments(VERSION "" "VERSION" "" ${ARGN})
    set(VERSION "${VERSION_VERSION}")
    if(NOT name)
        message(FATAL_ERROR "The name parameter is not set in set_cann_package.")
    endif()
    if(NOT VERSION)
        message(FATAL_ERROR "The VERSION parameter is not set in set_cann_package(${name}).")
    endif()
    string(REGEX MATCH "^([0-9]+\\.[0-9]+)" VERSION_MAJOR_MINOR "${VERSION}")
    list(APPEND CANN_VERSION_PACKAGES "${name}")
    set(CANN_VERSION_PACKAGES "${CANN_VERSION_PACKAGES}" PARENT_SCOPE)
    set(CANN_VERSION_CURRENT_PACKAGE "${name}" PARENT_SCOPE)
    set(CANN_VERSION_${name}_VERSION "${VERSION}" PARENT_SCOPE)
    set(CANN_VERSION_${name}_VERSION_MAJOR_MINOR "${VERSION_MAJOR_MINOR}" PARENT_SCOPE)
    set(CANN_VERSION_${name}_BUILD_DEPS PARENT_SCOPE)
    set(CANN_VERSION_${name}_RUN_DEPS PARENT_SCOPE)
endfunction()

# 设置构建依赖
function(set_cann_build_dependencies pkg_name depend)
    if(NOT CANN_VERSION_CURRENT_PACKAGE)
        message(FATAL_ERROR "The set_cann_package must be invoked first.")
    endif()
    if(NOT pkg_name)
        message(FATAL_ERROR "The pkg_name parameter is not set in set_cann_build_dependencies.")
    endif()
    if(NOT depend)
        message(FATAL_ERROR "The depend parameter is not set in set_cann_build_dependencies.")
    endif()
    __cann_replace_cur_major_minor_ver()
    list(APPEND CANN_VERSION_${CANN_VERSION_CURRENT_PACKAGE}_BUILD_DEPS "${pkg_name}" "${depend}")
    set(CANN_VERSION_${CANN_VERSION_CURRENT_PACKAGE}_BUILD_DEPS "${CANN_VERSION_${CANN_VERSION_CURRENT_PACKAGE}_BUILD_DEPS}" PARENT_SCOPE)
endfunction()

# 设置运行依赖
function(set_cann_run_dependencies pkg_name depend)
    if(NOT CANN_VERSION_CURRENT_PACKAGE)
        message(FATAL_ERROR "The set_cann_package must be invoked first.")
    endif()
    if(NOT pkg_name)
        message(FATAL_ERROR "The pkg_name parameter is not set in set_cann_run_dependencies.")
    endif()
    if(NOT depend)
        message(FATAL_ERROR "The depend parameter is not set in set_cann_run_dependencies.")
    endif()
    __cann_replace_cur_major_minor_ver()
    list(APPEND CANN_VERSION_${CANN_VERSION_CURRENT_PACKAGE}_RUN_DEPS "${pkg_name}" "${depend}")
    set(CANN_VERSION_${CANN_VERSION_CURRENT_PACKAGE}_RUN_DEPS "${CANN_VERSION_${CANN_VERSION_CURRENT_PACKAGE}_RUN_DEPS}" PARENT_SCOPE)
endfunction()

# 检查构建依赖
function(check_cann_pkg_build_deps pkg_name)
    if(NOT TOPLEVEL_PROJECT)
        return()
    endif()
    execute_process(
        COMMAND python3 ${CANN_CMAKE_DIR}/scripts/version/check_build_dependencies.py "${ASCEND_INSTALL_PATH}" ${CANN_VERSION_${pkg_name}_BUILD_DEPS}
        RESULT_VARIABLE result
    )
    if(result)
        message(FATAL_ERROR "Check ${pkg_name} build dependencies failed!")
    endif()
endfunction()

# 添加生成version.info的目标
# 目标名格式为：version_${包名}_info
function(add_cann_version_info_targets)
    foreach(pkg_name ${CANN_VERSION_PACKAGES})
        add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/version.${pkg_name}.info
            COMMAND python3 ${CANN_CMAKE_DIR}/scripts/version/generate_version_info.py --output ${CMAKE_BINARY_DIR}/version.${pkg_name}.info
                    "${CANN_VERSION_${pkg_name}_VERSION}" ${CANN_VERSION_${pkg_name}_RUN_DEPS}
            DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/version.cmake ${CANN_CMAKE_DIR}/scripts/version/generate_version_info.py
            VERBATIM
        )
        add_custom_target(version_${pkg_name}_info ALL DEPENDS ${CMAKE_BINARY_DIR}/version.${pkg_name}.info)
    endforeach()
endfunction()
