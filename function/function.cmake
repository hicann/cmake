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
endmacro()

# 加载配置
function(load_superbuild_config)
    if(CANN_SUPERBUILD_CONFIG AND EXISTS ${CANN_SUPERBUILD_CONFIG})
        include(${CANN_SUPERBUILD_CONFIG})
    else()
        include(${CANN_CMAKE_DIR}/superbuild/config.cmake)
    endif()
endfunction()

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

# 过滤目标列表
function(filter_targets outvar)
    unset(EXISTS_TARGETS)
    unset(NOT_EXISTS_TARGETS)
    foreach(TGT IN LISTS ARGN)
        # 目标名以maybe::开头，表明该目标可能存在, 不参与目标存在性强校验
        string(REGEX REPLACE "^maybe::" "" NEW_TGT "${TGT}")
        # 如果替换后的串与原串不同, 说明原串以maybe::开头
        if(NOT(TGT STREQUAL NEW_TGT))
            if(TARGET ${NEW_TGT})
                # 存在的目标, 将去除maybe::的目标名加入存在列表
                list(APPEND EXISTS_TARGETS ${NEW_TGT})
            else()
                # 不存在的目标, 将包含maybe::的目标名加入不存在的列表
                list(APPEND NOT_EXISTS_TARGETS ${TGT})
            endif()
        else()
            if(TARGET ${TGT})
                list(APPEND EXISTS_TARGETS ${TGT})
            else()
                list(APPEND NOT_EXISTS_TARGETS ${TGT})
            endif()
        endif()
    endforeach()
    set(${outvar} ${EXISTS_TARGETS} "__SEP__" ${NOT_EXISTS_TARGETS} PARENT_SCOPE)
endfunction(filter_targets)

# 获取存在的目标
function(get_exists_targets outvar)
    unset(RESULT)
    foreach(TGT IN LISTS ARGN)
        if(TGT STREQUAL "__SEP__")
            break()
        endif()
        list(APPEND RESULT ${TGT})
    endforeach()
    set(${outvar} "${RESULT}" PARENT_SCOPE)
endfunction()

# 获取不存在的目标
function(get_not_exists_targets outvar)
    unset(RESULT)
    set(NEED_APPEND FALSE)
    foreach(TGT IN LISTS ARGN)
        if(TGT STREQUAL "__SEP__")
            set(NEED_APPEND TRUE)
            continue()
        endif()
        if(NOT NEED_APPEND)
            continue()
        endif()
        # maybe目标不加入不存在列表
        if(NOT(TGT MATCHES "^maybe::"))
            list(APPEND RESULT ${TGT})
        endif()
    endforeach()
    set(${outvar} "${RESULT}" PARENT_SCOPE)
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
            if(dep_pkg IN_LIST all_pkgs OR dep_pkg IN_LIST pkgs_next)
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
    add_dependencies(cann_all_targets ${build_targets})
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

# 内部调用
function(get_project_deps TARGET_PROJ PROJ_ROOT_DIR OUT_VAR)
    # -------------------------- 初始化变量 --------------------------
    # 1. 初始化返回变量(仅首次调用时清空)
    if(NOT DEFINED ${OUT_VAR})
        set(${OUT_VAR} "" PARENT_SCOPE)
    endif()
    # 2. 初始化已处理项目列表(防循环依赖, 内部传递)
    if(NOT DEFINED PROCESSED_PROJS)
        set(PROCESSED_PROJS "")
    endif()

    # -------------------------- 检查循环依赖 --------------------------
    list(FIND PROCESSED_PROJS "${TARGET_PROJ}" PROJ_INDEX)
    if(NOT PROJ_INDEX EQUAL -1)
        return() # 已处理过该项目, 直接返回
    endif()
    list(APPEND PROCESSED_PROJS "${TARGET_PROJ}")

    # -------------------------- 定位dep.cmake --------------------------
    # 目标项目的目录(绝对路径)
    set(TARGET_PROJ_DIR "${PROJ_ROOT_DIR}/${TARGET_PROJ}")
    # dep.cmake配置文件路径
    set(DEP_CONFIG_FILE "${TARGET_PROJ_DIR}/cmake/deps.cmake")

    # 无dep.cmake -> 无依赖, 直接返回
    if(NOT EXISTS "${DEP_CONFIG_FILE}")
        return()
    endif()

    # -------------------------- 解析dep.cmake --------------------------
    # 临时变量存储当前项目的直接依赖
    unset(CURRENT_DEPENDS)
    unset(BUILD_DEPS)
    # 加载dep.cmake, 读取DEPENDS变量
    include("${DEP_CONFIG_FILE}")
    # 检查DEPENDS是否定义(避免配置文件为空)
    if(DEFINED BUILD_DEPS AND NOT BUILD_DEPS STREQUAL "")
        # 拆分依赖列表(支持空格、分号分隔)
        set(CURRENT_DEPENDS "${BUILD_DEPS}")
    endif()

    # -------------------------- 递归处理依赖 --------------------------
    foreach(DEP_PROJ ${CURRENT_DEPENDS})
        string(STRIP "${DEP_PROJ}" DEP_PROJ) # 去除空格
        if(DEP_PROJ STREQUAL "")
            continue()
        endif()

        if("${PRODUCT_SIDE}" STREQUAL "host")
            set(DEP_PROJ_DIR "${PROJ_ROOT_DIR}/${DEP_PROJ}")
        else()
            set(DEP_PROJ_DIR "${PROJ_ROOT_DIR}/${DEP_PROJ}/cmake/device")
        endif()

        # 检查依赖目录是否存在
        if(NOT IS_DIRECTORY "${DEP_PROJ_DIR}")
            continue()
        endif()

        # 去重：避免重复添加同一目录
        file(RELATIVE_PATH REL_PATH "${PROJ_ROOT_DIR}" "${DEP_PROJ_DIR}")
        list(FIND ${OUT_VAR} "${REL_PATH}" DIR_INDEX)
        if(DIR_INDEX EQUAL -1)
            list(APPEND ${OUT_VAR} "${REL_PATH}")
            set(${OUT_VAR} "${${OUT_VAR}}" PARENT_SCOPE)

            # 递归解析当前依赖的子依赖
            get_project_deps("${DEP_PROJ}" "${PROJ_ROOT_DIR}" "${OUT_VAR}" "${PROCESSED_PROJS}")
        endif()
    endforeach()
endfunction()

function(get_project_dep_dirs TARGET_PROJ PROJ_ROOT_DIR OUT_VAR)
    # 清空返回变量, 避免残留
    set(${OUT_VAR} "" PARENT_SCOPE)
    # 调用核心递归函数
    get_project_deps("${TARGET_PROJ}" "${PROJ_ROOT_DIR}" "PROJECT_DEPS")
    # 结果打印输出
    set(${OUT_VAR} "${PROJECT_DEPS}" PARENT_SCOPE)
endfunction()
