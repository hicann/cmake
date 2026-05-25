# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------
if(aicpu_FOUND)
  message(STATUS "aicpu has been found")
  return()
endif()

include(FindPackageHandleStandardArgs)

if(BUILD_WITH_INSTALLED_DEPENDENCY_CANN_PKG)
  set(AICPU_INC_DIRS
    ${ASCEND_DIR}/${SYSTEM_PREFIX}/include/experiment
    ${ASCEND_DIR}/${SYSTEM_PREFIX}/include/experiment/msprof
    ${ASCEND_DIR}/${SYSTEM_PREFIX}/include/aicpu_common/context
    ${ASCEND_DIR}/${SYSTEM_PREFIX}/include/aicpu_common/context/common
    ${ASCEND_DIR}/${SYSTEM_PREFIX}/include/aicpu_common/context/cpu_proto
    ${ASCEND_DIR}/${SYSTEM_PREFIX}/include/aicpu_common/context/utils
    ${ASCEND_DIR}/${SYSTEM_PREFIX}/include/experiment/datagw/aicpu/common
    ${ASCEND_DIR}/${SYSTEM_PREFIX}/pkg_inc/aicpu
  )
else()
  set(AICPU_INC_DIRS
    ${TOP_DIR}/abl/msprof/inc
    ${TOP_DIR}/ace/comop/inc
    ${TOP_DIR}/inc/aicpu/cpu_kernels
    ${TOP_DIR}/inc/external/aicpu
    ${TOP_DIR}/asl/ops/cann/ops/built-in/aicpu/context/inc
    ${TOP_DIR}/asl/ops/cann/ops/built-in/aicpu/impl/utils
    ${TOP_DIR}/asl/ops/cann/ops/built-in/aicpu/impl
    ${TOP_DIR}/ops-base/include/aicpu_common/context/common
    ${TOP_DIR}/open_source/eigen
  )
endif()

message(STATUS "Using AICPU include dirs: ${AICPU_INC_DIRS}")

if(TARGET aicpu_headers)
  return()
endif()

find_path(aicpu_INCLUDE_DIR
    NAMES aicpu_engine_struct.h
    PATH_SUFFIXES pkg_inc/aicpu
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
)

find_package_handle_standard_args(aicpu
    FOUND_VAR
        aicpu_FOUND
    REQUIRED_VARS
        aicpu_INCLUDE_DIR
)

if(aicpu_FOUND)
    if(NOT BUILD_WITH_INSTALLED_DEPENDENCY_CANN_PKG)
      set(AICPU_IMPORTED_INC_DIRS
        ${aicpu_INCLUDE_DIR}/..
        ${aicpu_INCLUDE_DIR}
        ${aicpu_INCLUDE_DIR}/aicpu_schedule
        ${aicpu_INCLUDE_DIR}/common
        ${aicpu_INCLUDE_DIR}/cpu_kernels
        ${aicpu_INCLUDE_DIR}/queue_schedule
        ${aicpu_INCLUDE_DIR}/tsd
      )
      list(APPEND AICPU_INC_DIRS ${AICPU_IMPORTED_INC_DIRS})
    endif()

    if(NOT TARGET aicpu_headers)
      add_library(aicpu_headers INTERFACE IMPORTED)
      if(BUILD_WITH_INSTALLED_DEPENDENCY_CANN_PKG)
        set_target_properties(aicpu_headers PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${AICPU_INC_DIRS}"
        )
      else()
        set_target_properties(aicpu_headers PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${AICPU_IMPORTED_INC_DIRS}"
        )
      endif()
    endif()
endif()
