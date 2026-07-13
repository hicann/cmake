# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

# 初始化superbuild工程
macro(init_cann_superbuild_project)
    cmake_parse_arguments(CANN "" "PRODUCT_SIDE" "" ${ARGN})
    if(LAUNCH_COMPILE_TOOL)
        set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${LAUNCH_COMPILE_TOOL}")
    endif()
    if(LAUNCH_LINK_TOOL)
        set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK "${LAUNCH_LINK_TOOL}")
    endif()  
    if(CANN_PRODUCT_SIDE)
        set(PRODUCT_SIDE "${CANN_PRODUCT_SIDE}")
    endif()
    if(PRODUCT_SIDE STREQUAL "device")
        get_filename_component(CANN_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}/../.."  ABSOLUTE)
    else()
        get_filename_component(CANN_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}/.."  ABSOLUTE)
    endif()
    include(${CANN_CMAKE_DIR}/function/prepare.cmake)
    init_cann_project(${ARGN})

    get_filename_component(CANN_TOP_DIR "${CANN_CMAKE_DIR}/.." REALPATH)
    load_superbuild_config()
    calc_cann_binary_components()
endmacro()

# 计算二进制组件
function(calc_cann_binary_components)
    set(CANN_BINARY_COMPONENTS)
    set(CANN_BINARY_COMPONENTS_ALL FALSE)
    foreach(PKG IN LISTS CANN_BINARY_PACKAGES)
        string(TOLOWER "${PKG}" PKG_LOWER)
        if(PKG_LOWER STREQUAL "all")
            set(CANN_BINARY_COMPONENTS_ALL TRUE)
        else()
            list(APPEND CANN_BINARY_COMPONENTS ${CANN_PACKAGE_COMPONENTS_${PKG}})
        endif()
    endforeach()
    set(CANN_BINARY_COMPONENTS "${CANN_BINARY_COMPONENTS}" PARENT_SCOPE)
    set(CANN_BINARY_COMPONENTS_ALL "${CANN_BINARY_COMPONENTS_ALL}" PARENT_SCOPE)
endfunction()

# 加载配置
macro(load_superbuild_config)
    include(${CANN_CMAKE_DIR}/superbuild/config.cmake)
    if(CANN_SUPERBUILD_CONFIG AND EXISTS ${CANN_SUPERBUILD_CONFIG})
        include(${CANN_SUPERBUILD_CONFIG})
    endif()
endmacro()

# 获取包对应源码目录
function(get_package_dir_by_package outvar package)
    if(ARGN)
        list(GET ARGN 0 subdirs)
    else()
        set(subdirs)
    endif()
    if(CANN_PACKAGE_DIR_${package})
        set(pkg_dir "${CANN_PACKAGE_DIR_${package}}")
    else()
        set(pkg_dir "${package}")
    endif()
    if(subdirs)
        set(pkg_dir "${pkg_dir}/${subdirs}")
    endif()
    set(${outvar} "${pkg_dir}" PARENT_SCOPE)
endfunction()

# 获取包对应源码目录
function(get_package_dirs outvar pkgs)
    set(pkg_dirs)
    foreach(pkg IN LISTS pkgs)
        get_package_dir_by_package(pkg_dir "${pkg}" ${ARGN})
        list(APPEND pkg_dirs "${pkg_dir}")
    endforeach()
    list(REMOVE_DUPLICATES pkg_dirs)
    set(${outvar} "${pkg_dirs}" PARENT_SCOPE)
endfunction()

function(get_targets_in_directory out_var dirpath)
    get_property(targets DIRECTORY "${dirpath}" PROPERTY "BUILDSYSTEM_TARGETS")
    get_property(subdirs DIRECTORY "${dirpath}" PROPERTY "SUBDIRECTORIES")
    foreach(subdir IN LISTS subdirs)
        get_property(exclude_from_all DIRECTORY "${subdir}" PROPERTY "EXCLUDE_FROM_ALL")
        if(exclude_from_all)
            continue()
        endif()
        get_targets_in_directory(sub_targets "${subdir}")
        list(APPEND targets ${sub_targets})
    endforeach()
    set("${out_var}" "${targets}" PARENT_SCOPE)
endfunction()

function(filter_build_targets out_var targets)
    set(build_targets)
    foreach(target IN LISTS targets)
        get_property(type TARGET "${target}" PROPERTY "TYPE")
        if(type STREQUAL "INTERFACE_LIBRARY")
            continue()
        endif()
        get_property(exclude_from_all TARGET "${target}" PROPERTY "EXCLUDE_FROM_ALL")
        if(exclude_from_all)
            continue()
        endif()
        list(APPEND build_targets ${target})
    endforeach()
    set("${out_var}" "${build_targets}" PARENT_SCOPE)
endfunction()

function(get_build_targets_in_directory out_var dirpath)
    get_targets_in_directory(all_targets "${dirpath}")
    filter_build_targets(filter_targets "${all_targets}")
    set("${out_var}" "${filter_targets}" PARENT_SCOPE)
endfunction()

# 获取依赖包列表
function(get_build_pkg_deps out_var)
    set(build_pkg_deps)
    list(LENGTH ARGN len)
    if(len GREATER 0)
        math(EXPR stop "${len} - 1")
        foreach(idx RANGE 0 ${stop} 2)
            list(GET ARGN ${idx} pkg)
            list(APPEND build_pkg_deps ${pkg})
        endforeach()
    endif()
    set("${out_var}" "${build_pkg_deps}" PARENT_SCOPE)
endfunction()

function(do_get_pkg_dependencies pkgs all_pkgs)
    set(pkgs_next)

    foreach(pkg IN LISTS pkgs)
        get_package_dir_by_package(pkg_dir "${pkg}")

        include(${CANN_TOP_DIR}/${pkg_dir}/version.cmake)

        get_build_pkg_deps(build_pkg_deps ${CANN_VERSION_${pkg}_BUILD_DEPS})
        foreach(dep_pkg IN LISTS build_pkg_deps)
            if(dep_pkg IN_LIST all_pkgs OR dep_pkg IN_LIST pkgs_next OR dep_pkg IN_LIST CANN_BINARY_PACKAGES OR CANN_BINARY_COMPONENTS_ALL)
                continue()
            endif()
            if(dep_pkg STREQUAL "bisheng-compiler")
                continue()
            endif()
            list(APPEND pkgs_next ${dep_pkg})
        endforeach()
    endforeach()
    if(pkgs_next)
        list(APPEND all_pkgs ${pkgs_next})
        do_get_pkg_dependencies("${pkgs_next}" "${all_pkgs}")
    endif()
    set(all_pkgs "${all_pkgs}" PARENT_SCOPE)
endfunction()

# 获取依赖包及目录
function(get_pkg_dependencies pkgs)
    do_get_pkg_dependencies("${pkgs}" "${pkgs}")
    set(CANN_DEPEND_PACKAGES "${all_pkgs}" PARENT_SCOPE)
endfunction()

# 1. 添加cann_all_targets目标
# 2. 将其它目标标识为EXCLUDE_FROM_ALL，防止冗余编译
function(set_cann_all_targets pkg_dirs)
    set(build_targets)
    foreach(pkg_dir IN LISTS pkg_dirs)
        get_build_targets_in_directory(pkg_targets ${CANN_TOP_DIR}/${pkg_dir})
        list(APPEND build_targets ${pkg_targets})
    endforeach()

    get_build_targets_in_directory(all_targets "${CMAKE_SOURCE_DIR}")

    foreach(target IN LISTS all_targets)
        set_target_properties(${target} PROPERTIES EXCLUDE_FROM_ALL TRUE)
    endforeach()

    add_custom_target(cann_all_targets ALL)
    if(build_targets)
        add_dependencies(cann_all_targets ${build_targets})
    endif()
endfunction()

# 计算device编译相关参数
function(calc_device_packages)
    set(DEVICE_CANN_PACKAGES)
    set(DEVICE_CANN_DEPEND_PACKAGES)

    foreach(PKG IN LISTS CANN_DEPEND_PACKAGES)
        get_package_dir_by_package(PKG_DIR "${PKG}" "cmake/device")

        if(IS_DIRECTORY "${CANN_TOP_DIR}/${PKG_DIR}")
            list(APPEND DEVICE_CANN_DEPEND_PACKAGES ${PKG})
            if(PKG IN_LIST CANN_PACKAGES)
                list(APPEND DEVICE_CANN_PACKAGES ${PKG})
            endif()
        endif()
    endforeach()

    set(DEVICE_CANN_PACKAGES "${DEVICE_CANN_PACKAGES}" PARENT_SCOPE)
    set(DEVICE_CANN_DEPEND_PACKAGES "${DEVICE_CANN_DEPEND_PACKAGES}" PARENT_SCOPE)
endfunction()
