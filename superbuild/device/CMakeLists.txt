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

include(../../function/prepare.cmake)
init_cann_project()

include(../../function/function.cmake)
set(PRODUCT_SIDE "device")

get_filename_component(CANN_TOP_DIR "../../.." REALPATH)

foreach(CANN_DEPEND_PACKAGE_DIR IN LISTS CANN_DEPEND_PACKAGE_DIRS)
    add_subdirectory(${CANN_TOP_DIR}/${CANN_DEPEND_PACKAGE_DIR} ${CANN_DEPEND_PACKAGE_DIR})
endforeach()

set_cann_all_targets()
set_cann_subprj_package(SUPERBUILD)
