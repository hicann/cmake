if(CPACK_GENERATOR STREQUAL "External")
    return()
endif()

message(STATUS "Running pre-build script: extracting archive...")

include(${CMAKE_CURRENT_LIST_DIR}/pkg_func.cmake)

list(LENGTH CPACK_COMPONENTS_ALL len_components)
list(LENGTH CPACK_PACKAGE_PARAM_NAME len_share_info_names)
if(NOT len_components EQUAL len_share_info_names)
    message(FATAL_ERROR "CPACK_COMPONENTS_ALL and CPACK_PACKAGE_PARAM_NAME is not one-to-one mapping.")
endif()

math(EXPR len_components "${len_components} - 1")
foreach(index RANGE ${len_components})
    list(GET CPACK_COMPONENTS_ALL ${index} component)
    list(GET CPACK_PACKAGE_PARAM_NAME ${index} share_info_name)
    list(GET CPACK_CMAKE_SOURCE_DIR ${index} source_dir)
    list(GET CPACK_ENABLE_DEVICE ${index} enable_device)

    set(DEB_DELIVERY ${CPACK_CMAKE_BINARY_DIR}/_CPack_Packages/${CPACK_SYSTEM_NAME}/${CPACK_GENERATOR}/${CPACK_PACKAGE_FILE_NAME}/${component}/usr/local/Ascend/cann-${CPACK_PACKAGE_VERSION})
    pre_package_process("${component}" "${share_info_name}" "${source_dir}" "${enable_device}" "${DEB_DELIVERY}" "${CPACK_GENERATOR}")
endforeach()
