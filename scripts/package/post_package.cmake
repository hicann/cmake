# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

# CPack DEB generator 生成的 control 文件末尾会多一个空行，影响后续解析处理
if(CPACK_GENERATOR STREQUAL "DEB")
    get_filename_component(_script_dir "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)
    set(_fixed_package_files)
    foreach(_pkg_file IN LISTS CPACK_PACKAGE_FILES)
        execute_process(
            COMMAND bash "${_script_dir}/fix_deb_control.sh" "${_pkg_file}"
            RESULT_VARIABLE _ret
        )
        if(_ret EQUAL 0)
            message(STATUS "fix_deb_control.sh succeeded for: ${_pkg_file}")
            list(APPEND _fixed_package_files "${_pkg_file}")
        else()
            message(WARNING "fix_deb_control.sh failed for: ${_pkg_file}, using original package")
            list(APPEND _fixed_package_files "${_pkg_file}")
        endif()
    endforeach()
    set(CPACK_PACKAGE_FILES ${_fixed_package_files})
endif()

file(MAKE_DIRECTORY "${CPACK_CMAKE_INSTALL_PREFIX}")
file(COPY ${CPACK_PACKAGE_FILES} DESTINATION "${CPACK_CMAKE_INSTALL_PREFIX}")
