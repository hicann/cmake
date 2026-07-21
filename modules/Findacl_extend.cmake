# -----------------------------------------------------------------------------------------------------------
# Copyright (c) 2026 Huawei Technologies Co., Ltd.
# This program is free software, you can redistribute it and/or modify it under the terms and conditions of
# CANN Open Software License Agreement Version 2.0 (the "License").
# Please refer to the License for details. You may not use this file except in compliance with the License.
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
# See LICENSE in the root of the software repository for the full text of the License.
# -----------------------------------------------------------------------------------------------------------

if(acl_extend_FOUND)
    return()
endif()

find_path(_CANN_ACL_MEDIA_INCLUDE_DIR
    NAMES hi_media_common.h
    PATH_SUFFIXES include/acl/media
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_FIND_ROOT_PATH
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(acl_extend
    REQUIRED_VARS
        _CANN_ACL_MEDIA_INCLUDE_DIR
)

if(acl_extend_FOUND)
    add_library(acl_extend_headers INTERFACE IMPORTED)
    set_target_properties(acl_extend_headers PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${_CANN_ACL_MEDIA_INCLUDE_DIR}"
    )
endif()
