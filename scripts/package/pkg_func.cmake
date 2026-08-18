# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------
# 打包公共函数

# 打包前处理
function(pre_package_process component share_info_name source_dir enable_device package_dir suffix)
    set(CANN_PACKAGE_DIR "${package_dir}")

    if(enable_device)
        execute_process(
            COMMAND tar --keep-old-files -zxpf device-${component}.tar.gz
            WORKING_DIRECTORY "${CANN_PACKAGE_DIR}"
            RESULT_VARIABLE RETCODE
        )
        if(RETCODE)
            message(FATAL_ERROR "Extract device-${component}.tar.gz failed, return code is ${RETCODE}.")
        endif()

        file(REMOVE "${CANN_PACKAGE_DIR}/device-${component}.tar.gz")
    endif()

    if(CPACK_CANN_PRE_PKG_${component})
        include(${CPACK_CANN_PRE_PKG_${component}})
    endif()

    execute_process(
        COMMAND python3 ${CMAKE_CURRENT_LIST_DIR}/package.py --pkg_name ${share_info_name} --chip_name ${CPACK_SOC} --os_arch linux-${CMAKE_SYSTEM_PROCESSOR} --version_dir ${CPACK_PACKAGE_VERSION} --delivery_dir ${CANN_PACKAGE_DIR} --source_dir ${source_dir} --suffix ${suffix}
        WORKING_DIRECTORY ${CPACK_CMAKE_BINARY_DIR}
        OUTPUT_VARIABLE result
        ERROR_VARIABLE error
        RESULT_VARIABLE code
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if (NOT code EQUAL 0)
        message(FATAL_ERROR "Filelist generation failed: ${result} ${error}")
    endif()
endfunction()
