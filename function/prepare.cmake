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

# 添加target公共编译和链接选项
macro(add_cann_target_options)
    include(${CANN_CMAKE_DIR}/intf_pub/intf_pub_linux.cmake)
endmacro()

# 生成 DEB 和 RPM 依赖字符串
# 辅助函数：规范化版本比较符，确保操作符与版本号之间有空格
function(normalize_version_cond input_str output_var)
    # 将 ">=8.5" 变成 ">= 8.5"
    string(REGEX REPLACE "([><=]+)([0-9])" "\\1 \\2" normalized "${input_str}")
    set(${output_var} "${normalized}" PARENT_SCOPE)
endfunction()

function(convert_dependencies_to_package_formats DEP_LIST OUT_DEB OUT_RPM)
    # 获取依赖列表的值
    set(dependencies ${${DEP_LIST}})

    set(DEB_DEPENDS "")
    set(RPM_REQUIRES "")

    foreach(dep_entry ${dependencies})
        # dep_entry 格式: "pkg >=8.5" 或 "pkg >= 8.5"（由 set_cann_run_dependencies 组合为单个字符串）
        string(REGEX MATCH "^([^ ]+) +(.*)" _ ${dep_entry})
        if(CMAKE_MATCH_COUNT GREATER 1)
            set(pkg_name "${CMAKE_MATCH_1}")
            set(raw_cond "${CMAKE_MATCH_2}")
        else()
            message(WARNING "Invalid dependency entry: ${dep_entry}")
            continue()
        endif()

        # 规范化版本条件，确保操作符后有空格
        normalize_version_cond("${raw_cond}" cond_normalized)

        # ---- DEB 格式: "pkg (op version)" ----
        set(deb_entry "${pkg_name} (${cond_normalized})")
        if(DEB_DEPENDS)
            set(DEB_DEPENDS "${DEB_DEPENDS}, ${deb_entry}")
        else()
            set(DEB_DEPENDS "${deb_entry}")
        endif()

        # ---- RPM 格式: "pkg op version" ----
        set(rpm_entry "${pkg_name} ${cond_normalized}")
        if(RPM_REQUIRES)
            set(RPM_REQUIRES "${RPM_REQUIRES}, ${rpm_entry}")
        else()
            set(RPM_REQUIRES "${rpm_entry}")
        endif()
    endforeach()

    # 将结果返回给父作用域
    set(${OUT_DEB} "${DEB_DEPENDS}" PARENT_SCOPE)
    set(${OUT_RPM} "${RPM_REQUIRES}" PARENT_SCOPE)
endfunction()

# 设置cann工程公共参数
macro(init_cann_project)
    # 联合构建时，init函数可能被调用多次，保证第一次调用时生效，忽略后续调用
    if(NOT CANN_PROJECT_INITED)
        cmake_parse_arguments(CANN "PREPEND_MODULE_PATH" "PRODUCT_SIDE" "" ${ARGN})

        if(CANN_PRODUCT_SIDE)
            set(PRODUCT_SIDE "${CANN_PRODUCT_SIDE}")
        endif()

        if(POLICY CMP0135)
            cmake_policy(SET CMP0135 NEW)
        endif()

        include(CMakePrintHelpers)

        set(CANN_BINARY_COMPONENTS)
        set(CANN_BINARY_COMPONENTS_ALL FALSE)

        set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
        set(CMAKE_CXX_STANDARD 17)
        set(CMAKE_CXX_STANDARD_REQUIRED ON)
        set(CMAKE_CXX_EXTENSIONS OFF)

        if(NOT CMAKE_GENERATOR STREQUAL "Ninja")
                set(CMAKE_CXX_COMPILE_OBJECT
                    "<CMAKE_CXX_COMPILER> <DEFINES> -D__FILE__='\"$(notdir $(abspath <SOURCE>))\"' -Wno-builtin-macro-redefined <INCLUDES> <FLAGS> -o <OBJECT> -c <SOURCE>"
                )
                set(CMAKE_C_COMPILE_OBJECT
                    "<CMAKE_C_COMPILER> <DEFINES> -D__FILE__='\"$(notdir $(abspath <SOURCE>))\"' -Wno-builtin-macro-redefined <INCLUDES> <FLAGS> -o <OBJECT> -c <SOURCE>"
                )
        endif()

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

        # Init third_party default path witch not set in services.
        if(NOT CANN_3RD_LIB_PATH)
            set(CANN_3RD_LIB_PATH ${CMAKE_SOURCE_DIR}/third_party)
            message("set third_party default path: ${CANN_3RD_LIB_PATH}.")
        endif()

        __cann_get_target_arch()

        if(CANN_PREPEND_MODULE_PATH)
            list(PREPEND CMAKE_MODULE_PATH "${CANN_CMAKE_DIR}/modules")
            list(PREPEND CMAKE_PREFIX_PATH "${ASCEND_INSTALL_PATH}")
        endif()

        __cann_print_summary()
        set(CANN_PROJECT_INITED TRUE)

        unset(CANN_PREPEND_MODULE_PATH)
        unset(CANN_PRODUCT_SIDE)
    endif()
endmacro()

# 添加device侧工程
function(add_cann_device_project component)
    # 多仓联编时跳过device工程（superbuild 由 ExternalProject_Add 统一处理）
    if(NOT TOPLEVEL_PROJECT)
        return()
    endif()

    # ENABLE_BUILD_DEVICE为FALSE时跳过device工程
    # 注意：superbuild 模式下 ENABLE_BUILD_DEVICE 被置为 FALSE（见 superbuild/CMakeLists.txt），
    # 以避免子包各自启动 device 编译与 superbuild 的 ExternalProject_Add 冲突。
    if(DEFINED ENABLE_BUILD_DEVICE AND NOT ENABLE_BUILD_DEVICE)
        return()
    endif()

    set(EP_CMAKE_ARGS)
    if(ASCEND_CANN_PACKAGE_PATH)
        list(APPEND EP_CMAKE_ARGS "-D" "ASCEND_CANN_PACKAGE_PATH=${ASCEND_CANN_PACKAGE_PATH}")
    else()
        list(APPEND EP_CMAKE_ARGS "-D" "ASCEND_INSTALL_PATH=${ASCEND_INSTALL_PATH}")
    endif()
    if(HI_PYTHON)
        list(APPEND EP_CMAKE_ARGS "-D" "HI_PYTHON=${HI_PYTHON}")
    endif()

    include(ExternalProject)
    ExternalProject_Add(cann_device
        SOURCE_DIR ${CMAKE_SOURCE_DIR}/cmake/device
        BINARY_DIR ${CMAKE_BINARY_DIR}/device_build
        CMAKE_ARGS
            ${EP_CMAKE_ARGS}
            -D TOOLCHAIN_DIR=${ASCEND_INSTALL_PATH}/toolkit/toolchain/hcc
            -D CMAKE_TOOLCHAIN_FILE=${CANN_CMAKE_DIR}/toolchain/aarch64-hcc-toolchain.cmake
            -D CANN_3RD_LIB_PATH=${CANN_3RD_LIB_PATH}
            -D CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -D ENABLE_SIGN=${ENABLE_SIGN}
            -D CUSTOM_SIGN_SCRIPT=${CUSTOM_SIGN_SCRIPT}
            -D VERSION_INFO=${VERSION_INFO}
            -D ENABLE_OPEN_SRC=TRUE
            -D BUILD_OPEN_PROJECT=TRUE
        INSTALL_COMMAND ${CMAKE_CPACK_COMMAND}
        BUILD_ALWAYS TRUE
    )
    install(FILES
        ${CMAKE_BINARY_DIR}/device_build/device-${component}.tar.gz
        DESTINATION .
        COMPONENT ${component}
    )
endfunction()

# 包装 find_package，在联编/统一构建模式下跳过
macro(find_cann_package)
    if(TOPLEVEL_PROJECT OR "${ARGV0}" IN_LIST CANN_BINARY_COMPONENTS OR CANN_BINARY_COMPONENTS_ALL)
        find_package(${ARGN})
    elseif(ENABLE_UNIFIED_BUILD AND "${ARGV0}" STREQUAL "ASC")
        include(${CANN_TOP_DIR}/${CANN_PACKAGE_DIR_asc-devkit}/cmake/asc/asc_modules/FindASC.cmake)
        list(APPEND CMAKE_MODULE_PATH "${CANN_TOP_DIR}/${CANN_PACKAGE_DIR_asc-devkit}/cmake/asc/asc_modules")
    endif()
endmacro()

# 添加三方库
macro(add_cann_third_party name)
    if(TOPLEVEL_PROJECT OR ENABLE_UNIFIED_BUILD)
        include(${CANN_CMAKE_DIR}/third_party/${name}.cmake)
    endif()
endmacro()

# 通过相对父目录方式添加子目录
function(add_cann_subdirectories_relative base_dir)
    foreach(source_dir ${ARGN})
        file(RELATIVE_PATH relative_dir "${base_dir}" "${source_dir}")
        add_subdirectory("${source_dir}" "${relative_dir}")
    endforeach()
endfunction()

# 模拟全局列表变量
macro(__cann_append_global_property name value)
    set_property(GLOBAL APPEND
        PROPERTY ${name} "${value}"
    )
    get_property(${name}
        GLOBAL
        PROPERTY ${name}
    )
endmacro()

# 设置打包配置，支持多次调用打多个包
# component: 组件名
# NO_COMPONENT_INSTALL: 不带--component参数安装
# ENABLE_DEVICE: 是否解压device-${component}.tar.gz
# COMPUTE_UNIT: 芯片型号
# SHARE_INFO_NAME: 如果子包在share/info目录下的名字与component不一致，则需要设置
function(set_cann_cpack_config component)
    if(NOT TOPLEVEL_PROJECT AND NOT ENABLE_UNIFIED_BUILD)
        return()
    endif()

    if(ENABLE_UNIFIED_BUILD)
        if(NOT component IN_LIST CANN_PACKAGES)
            return()
        endif()
    endif()

    cmake_parse_arguments(CANN
        "NO_COMPONENT_INSTALL;NO_CLEAN;TGZ"
        "ENABLE_DEVICE;PACKAGE_TYPE;COMPUTE_UNIT;SHARE_INFO_NAME;OUTPUT;ARCHIVE_FILE_NAME"
        ""
        ${ARGN}
    )

    __cann_append_global_property(CPACK_COMPONENTS_ALL "${component}")

    if(CANN_OUTPUT)
        if(ENABLE_UNIFIED_BUILD)
            set(CPACK_CMAKE_INSTALL_PREFIX "${CANN_CMAKE_DIR}/build_out")
        else()
            set(CPACK_CMAKE_INSTALL_PREFIX "${CANN_OUTPUT}")
        endif()
    else()
        set(CPACK_CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")
    endif()

    if(CANN_TGZ)
        string(TOUPPER "${component}" UPPER_COMPONENT)

        set(CPACK_GENERATOR TGZ)
        set(CPACK_ARCHIVE_COMPONENT_INSTALL ON)

        if(CANN_ARCHIVE_FILE_NAME)
            set(CPACK_ARCHIVE_${UPPER_COMPONENT}_FILE_NAME "${CANN_ARCHIVE_FILE_NAME}")
        endif()
        set(CPACK_POST_BUILD_SCRIPTS "${CANN_CMAKE_DIR}/scripts/package/post_package.cmake")  # 需要使用CPACK_CMAKE_INSTALL_PREFIX
        include(CPack)  # 需要使用CPACK_COMPONENTS_ALL
        return()
    endif()

    if(ENABLE_UNIFIED_BUILD)
        if(component IN_LIST DEVICE_CANN_PACKAGES AND SUPERBUILD_ENABLE_DEVICE)
            set(CANN_ENABLE_DEVICE TRUE)
        else()
            set(CANN_ENABLE_DEVICE FALSE)
        endif()
    endif()

    add_cann_third_party(makeself-fetch)

    if(CANN_COMPUTE_UNIT)
        set(CPACK_SOC "${CANN_COMPUTE_UNIT}")
    endif()

    if(CANN_SHARE_INFO_NAME)
        __cann_append_global_property(CPACK_PACKAGE_PARAM_NAME "${CANN_SHARE_INFO_NAME}")
    else()
        __cann_append_global_property(CPACK_PACKAGE_PARAM_NAME "${component}")
    endif()

    # RUN_DEPENDENCIES_LIST 由 set_cann_run_dependencies 积累，格式为 "pkg >=version" 组合字符串。
    # 此处不能 set(RUN_DEPENDENCIES_LIST "") 清空，否则会创建局部变量遮蔽调用方作用域的值。
    list(REMOVE_DUPLICATES RUN_DEPENDENCIES_LIST)
    set(DEB_DEPENDS "")
    set(RPM_REQUIRES "")
    message(STATUS "RUN_DEPENDENCIES_LIST: ${RUN_DEPENDENCIES_LIST}")
    convert_dependencies_to_package_formats(RUN_DEPENDENCIES_LIST DEB_DEPENDS RPM_REQUIRES)

    # 将生成的依赖字符串传递给 Cpack
    set(CPACK_DEBIAN_PACKAGE_DEPENDS "${DEB_DEPENDS}")
    set(CPACK_RPM_PACKAGE_REQUIRES "${RPM_REQUIRES}")
    message(STATUS "DEB depends: ${CPACK_DEBIAN_PACKAGE_DEPENDS}")
    message(STATUS "RPM requires: ${CPACK_RPM_PACKAGE_REQUIRES}")
    set(CPACK_PACKAGE_NAME "cann-${component}")
    string(TOLOWER "${CMAKE_SYSTEM_NAME}" CPACK_SYSTEM_NAME)
    set(CPACK_ARCHITECTURE "${CMAKE_SYSTEM_PROCESSOR}")
    set(CPACK_PACKAGE_VERSION "${CANN_VERSION_${component}_VERSION}")
    set(PACKAGE_FILE_NAME_TEMPLATE "${CPACK_PACKAGE_NAME}_${CPACK_PACKAGE_VERSION}_${CPACK_SYSTEM_NAME}-${CPACK_ARCHITECTURE}")
    set(CPACK_PACKAGE_FILE_NAME "${PACKAGE_FILE_NAME_TEMPLATE}")

    if(NOT CANN_NO_COMPONENT_INSTALL)
        set(CPACK_CANN_INSTALL_COMPONENT "${component}")
    endif()
    if(CANN_NO_CLEAN)
        set(CPACK_CANN_NO_CLEAN True)
    endif()
    __cann_append_global_property(CPACK_CMAKE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    set(CPACK_CMAKE_BINARY_DIR "${CMAKE_BINARY_DIR}")
    __cann_append_global_property(CPACK_ENABLE_DEVICE "${CANN_ENABLE_DEVICE}")
    set(CPACK_SET_DESTDIR OFF)
    set(CPACK_PACKAGING_INSTALL_PREFIX "/usr/local/Ascend/cann-${CPACK_PACKAGE_VERSION}")
    if(CANN_PACKAGE_TYPE STREQUAL "rpm")
        set(CPACK_GENERATOR "RPM")
    elseif(CANN_PACKAGE_TYPE STREQUAL "deb")
        set(CPACK_GENERATOR "DEB")
    elseif(CANN_PACKAGE_TYPE STREQUAL "deb,rpm")
        set(CPACK_GENERATOR "DEB;RPM")
    elseif(CANN_PACKAGE_TYPE STREQUAL "all")
        set(CPACK_GENERATOR "DEB;RPM;External")
    else()
        set(CPACK_GENERATOR External)
    endif()
    set(CPACK_RPM_COMPONENT_INSTALL ON)
    set(CPACK_DEB_COMPONENT_INSTALL ON)
    set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA 
        "${CMAKE_BINARY_DIR}/postinst"
        "${CMAKE_BINARY_DIR}/prerm")
    set(CPACK_RPM_POST_INSTALL_SCRIPT_FILE 
        "${CMAKE_BINARY_DIR}/postinst"
    )
    set(CPACK_RPM_PRE_UNINSTALL_SCRIPT_FILE 
        "${CMAKE_BINARY_DIR}/prerm"
    )
    set(CPACK_DEBIAN_PACKAGE_MAINTAINER "huawei")
    set(CPACK_EXTERNAL_PACKAGE_SCRIPT "${CANN_CMAKE_DIR}/scripts/package/makeself.cmake")
    set(CPACK_EXTERNAL_ENABLE_STAGING TRUE)
    set(CPACK_PACKAGE_DIRECTORY "${CMAKE_BINARY_DIR}")
    set(CPACK_MAKESELF_PATH "${CANN_3RD_LIB_PATH}/makeself")
    set(CPACK_BUILD_MODE "RUN_COPY")
    set(CPACK_TARGET_ARCH "${TARGET_ARCH}")
    set(CPACK_PRE_BUILD_SCRIPTS "${CANN_CMAKE_DIR}/scripts/package/pre_package.cmake")
    set(CPACK_POST_BUILD_SCRIPTS "${CANN_CMAKE_DIR}/scripts/package/post_package.cmake") 
    # 每次include(CPack)都会重新生成CPackConfig.cmake
    include(CPack)
endfunction()

# 设置子工程打包
function(set_cann_subprj_package)
    cmake_parse_arguments(CANN "SUPERBUILD" "" "" ${ARGN})

    if(NOT TOPLEVEL_PROJECT AND NOT CANN_SUPERBUILD)
        return()
    endif()

    if(CANN_SUPERBUILD)
        set(CPACK_COMPONENTS_ALL "${CANN_PACKAGES}")
    else()
        get_cmake_property(CPACK_COMPONENTS_ALL COMPONENTS)
        list(REMOVE_ITEM CPACK_COMPONENTS_ALL "Unspecified")
    endif()
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
# pkg_name 和 depend 以配对形式追加到 CANN_VERSION_*_BUILD_DEPS 列表，
# 格式为 pkg1;version1;pkg2;version2;...
# 消费者 get_build_pkg_deps 以步长 2 遍历取包名，修改此处参数格式需同步修改该函数。
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
    # CANN_VERSION_*_RUN_DEPS 存储为 pkg;version 配对列表，供 generate_version_info.py 按对解析
    list(APPEND CANN_VERSION_${CANN_VERSION_CURRENT_PACKAGE}_RUN_DEPS "${pkg_name}" "${depend}")
    set(CANN_VERSION_${CANN_VERSION_CURRENT_PACKAGE}_RUN_DEPS "${CANN_VERSION_${CANN_VERSION_CURRENT_PACKAGE}_RUN_DEPS}" PARENT_SCOPE)
    # RUN_DEPENDENCIES_LIST 存储为 "pkg version" 组合字符串，供 convert_dependencies_to_package_formats 按 regex 解析
    list(APPEND RUN_DEPENDENCIES_LIST "${pkg_name} ${depend}")
    set(RUN_DEPENDENCIES_LIST "${RUN_DEPENDENCIES_LIST}" PARENT_SCOPE)
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

# 将 cc 源文件的相对路径，转换为绝对路径
function(__cann_to_absolute_path origin_sources origin_source_dir output_sources)
    set(sources_list)
    foreach(source_file ${${origin_sources}})
        if(NOT IS_ABSOLUTE ${source_file} AND ${source_file} MATCHES "\\.(c|cc|cpp)$")
            list(APPEND sources_list ${${origin_source_dir}}/${source_file})
        else()
            list(APPEND sources_list ${source_file})
        endif()
    endforeach()
    set(${output_sources} ${sources_list} PARENT_SCOPE)
endfunction()

# 克隆 target 的属性到新 target，IGNORE_PROP 为需要跳过的属性名列表
#
# Usage:
#   clone_cann_target(ORIGIN ccl_kernel OUTPUT aicpu_custom)
#   clone_cann_target(ORIGIN ccl_kernel OUTPUT aicpu_custom IGNORE_PROP LINK_LIBRARIES)
#   clone_cann_target(ORIGIN ccl_kernel OUTPUT aicpu_custom IGNORE_PROP SOURCES LINK_LIBRARIES)
function(clone_cann_target)
    cmake_parse_arguments(ARG
        ""
        "ORIGIN;OUTPUT"
        "IGNORE_PROP"
        ${ARGN}
    )

    if(NOT ARG_ORIGIN OR NOT ARG_OUTPUT)
        message(FATAL_ERROR "clone_cann_target: ORIGIN or OUTPUT is required")
    endif()

    # 克隆源文件，同时将相对路径转换为绝对路径
    if(NOT "SOURCES" IN_LIST ARG_IGNORE_PROP)
        get_target_property(sourceFiles ${ARG_ORIGIN} SOURCES)
        get_target_property(sourceDir ${ARG_ORIGIN} SOURCE_DIR)
        __cann_to_absolute_path(sourceFiles sourceDir absolute_sources_files)
        target_sources(${ARG_OUTPUT} PRIVATE
            ${absolute_sources_files}
        )
    endif()

    # 克隆头文件搜索路径
    if(NOT "INCLUDE_DIRECTORIES" IN_LIST ARG_IGNORE_PROP)
        get_target_property(includeDirs ${ARG_ORIGIN} INCLUDE_DIRECTORIES)
        target_include_directories(${ARG_OUTPUT} PRIVATE
            ${includeDirs}
        )
    endif()

    # 克隆链接库
    if(NOT "LINK_LIBRARIES" IN_LIST ARG_IGNORE_PROP)
        get_target_property(linkLibs ${ARG_ORIGIN} LINK_LIBRARIES)
        target_link_libraries(${ARG_OUTPUT} PRIVATE
            ${linkLibs}
        )
    endif()

    # 克隆链接目录
    if(NOT "LINK_DIRECTORIES" IN_LIST ARG_IGNORE_PROP)
        get_target_property(linkDirs ${ARG_ORIGIN} LINK_DIRECTORIES)
        if(linkDirs)
            target_link_directories(${ARG_OUTPUT} PRIVATE
                ${linkDirs}
            )
        endif()
    endif()

    # 克隆宏定义
    if(NOT "COMPILE_DEFINITIONS" IN_LIST ARG_IGNORE_PROP)
        get_target_property(compileDefs ${ARG_ORIGIN} COMPILE_DEFINITIONS)
        if(compileDefs)
            target_compile_definitions(${ARG_OUTPUT} PRIVATE
                ${compileDefs}
            )
        endif()
    endif()

    # 克隆编译选项
    if(NOT "COMPILE_OPTIONS" IN_LIST ARG_IGNORE_PROP)
        get_target_property(compileOptions ${ARG_ORIGIN} COMPILE_OPTIONS)
        if(compileOptions)
            target_compile_options(${ARG_OUTPUT} PRIVATE
                ${compileOptions}
            )
        endif()
    endif()

    # 克隆链接选项
    if(NOT "LINK_OPTIONS" IN_LIST ARG_IGNORE_PROP)
        get_target_property(linkOpts ${ARG_ORIGIN} LINK_OPTIONS)
        if(linkOpts)
            target_link_options(${ARG_OUTPUT} PRIVATE
                ${linkOpts}
            )
        endif()
    endif()
endfunction()

# 打包目标文件和普通文件
# OUTPUT - 输出文件路径
# MANIFEST - 可选，manifest文件名
# OUTPUT_TARGET - 输出目标名
# TAR_ROOT_DIR - 可选，打包根目录
# SIZE_LIMIT - 可选，大小限制（单位KB），超出则报错
# TARGETS - 目标列表
# FILES - 文件列表
# GEN_INI - 可选标志，传入且设置了 CANN_VERSION_CURRENT_PACKAGE 时生成 .ini 文件并打包
function(cann_pack_targets_and_files)
    cmake_parse_arguments(ARG
        "GEN_INI"
        "OUTPUT;MANIFEST;OUTPUT_TARGET;TAR_ROOT_DIR;SIZE_LIMIT"
        "TARGETS;FILES"
        ${ARGN}
    )

    # --- Validation ---
    if(NOT ARG_OUTPUT)
        message(FATAL_ERROR "[pack_targets_and_files] OUTPUT is required")
    endif()

    if(NOT IS_ABSOLUTE "${ARG_OUTPUT}")
        set(ARG_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${ARG_OUTPUT}")
    endif()

    if(NOT ARG_OUTPUT_TARGET)
        message(FATAL_ERROR "[pack_targets_and_files] OUTPUT_TARGET is required")
    endif()

    # Generate safe target name
    get_filename_component(tar_basename "${ARG_OUTPUT}" NAME_WE)
    string(MAKE_C_IDENTIFIER "pack_${tar_basename}" safe_name)
    set(staging_root_dir "${CMAKE_CURRENT_BINARY_DIR}/_${safe_name}_stage")

    if(ARG_TAR_ROOT_DIR)
        set(staging_dir "${staging_root_dir}/${ARG_TAR_ROOT_DIR}")
        set(tar_src ${ARG_TAR_ROOT_DIR})
    else()
        set(staging_dir "${staging_root_dir}")
        set(tar_src ".")
    endif()
    
    # 仅当调用方传入 GEN_INI 选项时才生成 .ini 文件；同时需要
    # CANN_VERSION_CURRENT_PACKAGE 以解析版本号
    set(ini_file "")
    set(ini_version "")
    if(ARG_GEN_INI AND CANN_VERSION_CURRENT_PACKAGE)
        set(pkg_version "${CANN_VERSION_${CANN_VERSION_CURRENT_PACKAGE}_VERSION}")
        if(pkg_version)
            get_filename_component(output_dir "${ARG_OUTPUT}" DIRECTORY)
            get_filename_component(output_name "${ARG_OUTPUT}" NAME)
            if(output_name MATCHES "(.+)\\.tar\\.gz$")
                set(ini_basename "${CMAKE_MATCH_1}")
            elseif(output_name MATCHES "(.+)\\.tgz$")
                set(ini_basename "${CMAKE_MATCH_1}")
            else()
                get_filename_component(ini_basename "${output_name}" NAME_WE)
            endif()
            set(ini_file "${staging_dir}/${ini_basename}.ini")
            set(ini_version "${pkg_version}")
        endif()
    endif()

    # --- Collect all source items (as generator expressions) ---
    set(src_items "")
    foreach(tgt IN LISTS ARG_TARGETS)
        if(NOT TARGET ${tgt})
            message(FATAL_ERROR "[pack_targets_and_files] Target '${tgt}' does not exist")
        endif()

        get_target_property(type ${tgt} TYPE)
        if(type MATCHES "^(EXECUTABLE|SHARED_LIBRARY|STATIC_LIBRARY)$")
            list(APPEND src_items "$<TARGET_FILE:${tgt}>")
        endif()
    endforeach()
    list(APPEND src_items ${ARG_FILES})

    if(NOT src_items)
        message(FATAL_ERROR "[pack_targets_and_files] No targets or files specified to pack")
    endif()

    set(manifest_arg "")
    if(ARG_MANIFEST)
        if("${ARG_MANIFEST}" STREQUAL "")
            message(FATAL_ERROR "[pack] MANIFEST filename cannot be empty")
        endif()
        if(IS_ABSOLUTE "${ARG_MANIFEST}")
            message(FATAL_ERROR "[pack] MANIFEST must be relative (e.g., 'sha256sums.cfg')")
        endif()
        set(manifest_arg -D_MANIFEST_FILE=${staging_dir}/${ARG_MANIFEST})
    endif()

    add_custom_command(
        OUTPUT ${staging_dir}
        COMMAND ${CMAKE_COMMAND} -E make_directory "${staging_dir}"
        VERBATIM
    )

    set(ini_output "")
    set(ini_command "")
    set(ini_depends "")
    set(ini_copy_command "")
    if(ini_file)
        get_filename_component(output_dir "${ARG_OUTPUT}" DIRECTORY)
        set(ini_output "${ini_file}")
        set(ini_output_dir "${output_dir}/${ini_basename}.ini")
        set(ini_command COMMAND python3 ${CANN_CMAKE_DIR}/scripts/version/generate_package_ini.py
            "${ini_version}" --output "${ini_file}")
        set(ini_copy_command COMMAND ${CMAKE_COMMAND} -E copy "${ini_file}" "${ini_output_dir}")
        set(ini_depends ${CANN_CMAKE_DIR}/scripts/version/generate_package_ini.py)
    endif()

    set(size_check_command "")
    if(ARG_SIZE_LIMIT AND CMAKE_BUILD_TYPE STREQUAL "Release")
        set(size_check_command COMMAND ${CMAKE_COMMAND} -D_OUTPUT_FILE=${ARG_OUTPUT} -D_SIZE_LIMIT_KB=${ARG_SIZE_LIMIT} -P ${CANN_CMAKE_DIR}/function/_check_size_limit.cmake)
    endif()

    add_custom_command(
        OUTPUT "${ARG_OUTPUT}" ${ini_output}
        ${ini_command}
        ${ini_copy_command}
        COMMAND ${CMAKE_COMMAND}
            -D _STAGING_DIR=${staging_dir}
            ${manifest_arg}
            -D "_ITEMS=$<JOIN:${src_items},;>"
            -P "${CANN_CMAKE_DIR}/function/_pack_stage.cmake"
        COMMAND tar "czf" "${ARG_OUTPUT}" ${tar_src}
                "--mode=750"
        ${size_check_command}
        WORKING_DIRECTORY ${staging_root_dir}
        DEPENDS ${ARG_TARGETS} ${staging_dir} ${ini_depends}
        COMMENT "Packing with ${ARG_OUTPUT}"
        VERBATIM
    )

    add_custom_target(${ARG_OUTPUT_TARGET} ALL DEPENDS "${ARG_OUTPUT}")
    set_target_properties(${ARG_OUTPUT_TARGET} PROPERTIES
        TARGET_FILE "${ARG_OUTPUT}"
    )
endfunction()

function(add_cann_sign_file)
    cmake_parse_arguments(
        ARG
        ""
        "OUTPUT_TARGET;INPUT;CONFIG;RESULT_VAR"
        "SCRIPT_ARGS;DEPENDS"
        ${ARGN}
    )

    # --- Validation ---
    if(DEFINED CUSTOM_SIGN_SCRIPT AND NOT CUSTOM_SIGN_SCRIPT STREQUAL "")
        set(SIGN_SCRIPT ${CUSTOM_SIGN_SCRIPT})
    else()
        set(SIGN_SCRIPT)
    endif()

    if(ENABLE_SIGN)
        set(sign_flag "true")
    else()
        set(sign_flag "false")
    endif()

    foreach(var INPUT CONFIG RESULT_VAR)
        if(NOT ARG_${var})
            message(FATAL_ERROR "[sign_file] Missing required: ${var}")
        endif()
    endforeach()

    if(NOT EXISTS "${ARG_CONFIG}")
        message(FATAL_ERROR "[sign_file] Sign config not found: ${ARG_CONFIG}")
    endif()

    # Normalize input
    if(NOT IS_ABSOLUTE "${ARG_INPUT}")
        set(ARG_INPUT "${CMAKE_CURRENT_BINARY_DIR}/${ARG_INPUT}")
    endif()

    # Auto output path: ${CMAKE_CURRENT_BINARY_DIR}/signatures
    set(signatures_dir "${CMAKE_CURRENT_BINARY_DIR}/signatures")
    get_filename_component(input_name "${ARG_INPUT}" NAME)
    set(output_sig "${signatures_dir}/${input_name}")

    if(EXISTS "${SIGN_SCRIPT}")
        get_filename_component(EXT ${SIGN_SCRIPT} EXT) # 获取文件扩展名

        if (${EXT} STREQUAL ".sh")
            set(sign_cmd bash ${SIGN_SCRIPT} ${output_sig} ${ARG_CONFIG} ${sign_flag})
        elseif(${EXT} STREQUAL ".py")
            set(add_header ${CANN_CMAKE_DIR}/scripts/sign/add_header_sign.py)
            set(sign_builder ${CANN_CMAKE_DIR}/scripts/sign/community_sign_build.py)
            message(STATUS "Detected +++VERSION_INFO:${VERSION_INFO}, CANN_CMAKE_DIR:${CANN_CMAKE_DIR}")
            set(sign_cmd python3 ${add_header} ${signatures_dir} ${sign_flag} --bios_check_cfg=${ARG_CONFIG} --sign_script=${sign_builder} --version=${VERSION_INFO})
        endif()
    else()
        set(sign_cmd )
    endif()

    # Ensure dir exists
    file(MAKE_DIRECTORY "${signatures_dir}")

    # Target name
    get_filename_component(sign_basename "${ARG_INPUT}" NAME_WE)
    string(MAKE_C_IDENTIFIER "${sign_basename}" safe_name)

    if(ARG_OUTPUT_TARGET)
        set(sign_target "${ARG_OUTPUT_TARGET}")
    else()
        set(sign_target "sign_${safe_name}")
    endif()

    add_custom_command(
        OUTPUT "${output_sig}"
        COMMAND ${CMAKE_COMMAND} -E make_directory ${signatures_dir}
        COMMAND ${CMAKE_COMMAND} -E copy ${ARG_INPUT} ${output_sig}
        COMMAND ${sign_cmd}
        DEPENDS "${ARG_INPUT}" "${SIGN_SCRIPT}" ${ARG_DEPENDS} ${ARG_CONFIG}
        COMMENT "Signing: ${ARG_INPUT} → ${output_sig}"
        VERBATIM
    )

    add_custom_target(${sign_target} ALL DEPENDS "${output_sig}")

    # Return path via RESULT_VAR
    if(ARG_RESULT_VAR)
        set(${ARG_RESULT_VAR} "${output_sig}" PARENT_SCOPE)
    endif()
endfunction()

function(__cann_generate_stub_with_output_name name output_name)
    string(FIND ${output_name} "::" temp)
    if(temp EQUAL "-1")
        set(target_plain_name ${output_name})
    else()
        string(REPLACE "::" ";" temp_list ${output_name})
        list(GET temp_list 1 target_plain_name)
    endif()

    # 多个name可以对应一个output_name
    if(NOT TARGET ${target_plain_name}_stub_tmp)
        add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/stub/${target_plain_name}.c
            COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/stub
            COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_CURRENT_BINARY_DIR}/stub/${target_plain_name}.c)
        add_library(${target_plain_name}_stub_tmp SHARED ${CMAKE_CURRENT_BINARY_DIR}/stub/${target_plain_name}.c)
        set_target_properties(${target_plain_name}_stub_tmp PROPERTIES
            WINDOWS_EXPORT_ALL_SYMBOLS TRUE
            LIBRARY_OUTPUT_NAME ${target_plain_name} 
            RUNTIME_OUTPUT_NAME ${target_plain_name}
            LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/stub
            RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/stub)
    endif()

    add_library(${name} SHARED IMPORTED GLOBAL)
    if(UNIX)
        set_target_properties(${name} PROPERTIES
            IMPORTED_LOCATION "${CMAKE_CURRENT_BINARY_DIR}/stub/lib${target_plain_name}.so")
    endif()
    if(WIN32)
        set_target_properties(${name} PROPERTIES
            IMPORTED_LOCATION "${CMAKE_CURRENT_BINARY_DIR}/stub/${target_plain_name}.dll"
            IMPORTED_IMPLIB "${CMAKE_CURRENT_BINARY_DIR}/stub/${target_plain_name}.lib")
    endif()
    add_dependencies(${name} ${target_plain_name}_stub_tmp)
endfunction()

# 生成打桩库
function(generate_cann_stub_library name)
    cmake_parse_arguments(CANN "" "OUTPUT_NAME" "" ${ARGN})

    if(NOT CANN_OUTPUT_NAME)
        set(CANN_OUTPUT_NAME ${name})
    endif()

    __cann_generate_stub_with_output_name(${name} ${CANN_OUTPUT_NAME})
endfunction()

# 创建导入库头文件搜索目录
function(create_imported_interface_include_directories)
    foreach(target IN LISTS ARGN)
        get_property(DIRS TARGET ${target} PROPERTY INTERFACE_INCLUDE_DIRECTORIES)
        foreach(DIR IN LISTS DIRS)
            if(NOT EXISTS "${DIR}")
                file(MAKE_DIRECTORY "${DIR}")
            endif()
        endforeach()
    endforeach()
endfunction()

# 生成版本号头文件
function(gen_cann_version_header pkg_name)
    cmake_parse_arguments(CANN "" "VERSION" "" ${ARGN})
    if(CANN_UNPARSED_ARGUMENTS)
        # 如果有2个位置参数，将第2个位置参数作为component
        list(GET CANN_UNPARSED_ARGUMENTS 0 component)
    else()
        set(component "${pkg_name}")
    endif()
    if(NOT CANN_VERSION)
        set(CANN_VERSION "${CANN_VERSION_${component}_VERSION}")
    endif()
    set(OUTPUT_PATH "${CMAKE_BINARY_DIR}/include/version/${pkg_name}_version.h")
    add_custom_command(OUTPUT ${OUTPUT_PATH}
        COMMAND bash ${CANN_CMAKE_DIR}/scripts/package/generate_version_header.sh "${pkg_name}" "${CANN_VERSION}" --output ${OUTPUT_PATH}
    )
    add_custom_target(gen_${pkg_name}_version_header ALL DEPENDS ${OUTPUT_PATH})
    if(NOT PRODUCT_SIDE STREQUAL "device")
        install(FILES ${OUTPUT_PATH}
            DESTINATION ${TARGET_ARCH}-linux/include/version
            PERMISSIONS OWNER_READ GROUP_READ
            COMPONENT ${component}
            ${INSTALL_OPTIONAL}
        )
    endif()
    if(NOT TARGET cann_version_headers)
        add_library(cann_version_headers INTERFACE)
        target_include_directories(cann_version_headers INTERFACE
            $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/include>
        )
    endif()
    add_dependencies(cann_version_headers gen_${pkg_name}_version_header)
endfunction()
