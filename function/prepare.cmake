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

# 包装 find_package，在联编/统一构建模式下跳过
macro(find_cann_package)
    if(TOPLEVEL_PROJECT)
        find_package(${ARGN})
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

    if(ENABLE_UNIFIED_BUILD)
        if(NOT component IN_LIST CANN_PACKAGES)
            return()
        endif()
        set(CPACK_COMPONENTS_ALL "${CANN_PACKAGES}")
    endif()

    cmake_parse_arguments(CANN "NO_COMPONENT_INSTALL;NO_CLEAN" "ENABLE_DEVICE;COMPUTE_UNIT;SHARE_INFO_NAME;OUTPUT" "" ${ARGN})

    if(ENABLE_UNIFIED_BUILD)
        if(component IN_LIST DEVICE_CANN_PACKAGES)
            set(CANN_ENABLE_DEVICE TRUE)
        endif()
    endif()

    add_cann_third_party(makeself-fetch)

    if(CANN_COMPUTE_UNIT)
        set(CPACK_SOC "${CANN_COMPUTE_UNIT}")
    endif()

    if(CANN_SHARE_INFO_NAME)
        set(CPACK_PACKAGE_PARAM_NAME "${CANN_SHARE_INFO_NAME}")
    else()
        set(CPACK_PACKAGE_PARAM_NAME "${component}")
    endif()

    if(CANN_OUTPUT)
        if(ENABLE_UNIFIED_BUILD)
            set(CPACK_CMAKE_INSTALL_PREFIX "${CANN_CMAKE_DIR}/build_out")
        else()
            set(CPACK_CMAKE_INSTALL_PREFIX "${CANN_OUTPUT}")
        endif()
    else()
        set(CPACK_CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")
    endif()

    set(CPACK_PACKAGE_NAME "${component}")
    set(CPACK_PACKAGE_VERSION "${CANN_VERSION_${component}_VERSION}")
    set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CMAKE_SYSTEM_NAME}")

    if(NOT CANN_NO_COMPONENT_INSTALL)
        set(CPACK_CANN_INSTALL_COMPONENT "${component}")
    endif()
    if(CANN_NO_CLEAN)
        set(CPACK_CANN_NO_CLEAN True)
    endif()
    set(CPACK_CMAKE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    set(CPACK_CMAKE_BINARY_DIR "${CMAKE_BINARY_DIR}")
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

function(cann_pack_targets_and_files)
    cmake_parse_arguments(ARG
        ""
        "OUTPUT;MANIFEST;OUTPUT_TARGET"
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
    set(staging_dir "${CMAKE_CURRENT_BINARY_DIR}/_${safe_name}_stage")

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

    add_custom_command(
        OUTPUT "${ARG_OUTPUT}"
        COMMAND ${CMAKE_COMMAND}
            -D _STAGING_DIR=${staging_dir}
            ${manifest_arg}
            -D "_ITEMS=$<JOIN:${src_items},;>"
            -P "${CANN_CMAKE_DIR}/function/_pack_stage.cmake"
        COMMAND tar "czf" "${ARG_OUTPUT}" .
                "--mode=750"
        WORKING_DIRECTORY ${staging_dir}
        DEPENDS ${ARG_TARGETS} ${staging_dir}
        COMMENT "Packing with ${ARG_OUTPUT}"
        VERBATIM
    )

    add_custom_target(${ARG_OUTPUT_TARGET} ALL DEPENDS "${ARG_OUTPUT}")
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