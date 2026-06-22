message(STATUS "Running pre-build script: extracting archive...")
if(CPACK_GENERATOR STREQUAL "External")
    message(STATUS "run skip")
    return()
endif()
get_filename_component(CANN_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}" DIRECTORY)
# 使用 CMake 内置的解压命令
set(DEB_DELIVERY ${CPACK_CMAKE_BINARY_DIR}/_CPack_Packages/${CPACK_SYSTEM_NAME}/${CPACK_GENERATOR}/${CPACK_PACKAGE_FILE_NAME}${CPACK_RPM_DIRECTORY_PREFIX}/${CPACK_CANN_INSTALL_COMPONENT}/usr/local/Ascend/cann-${CPACK_PACKAGE_VERSION}/)
if(CPACK_ENABLE_DEVICE)
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xzf "${CPACK_CMAKE_BINARY_DIR}/device_build/device-${CPACK_CANN_INSTALL_COMPONENT}.tar.gz"
        WORKING_DIRECTORY "${DEB_DELIVERY}"
    )
endif()
execute_process(
    COMMAND python3 ${CANN_CMAKE_DIR}/package/package.py --pkg_name ${CPACK_PACKAGE_PARAM_NAME} --chip_name ${CPACK_SOC} --os_arch linux-${CMAKE_SYSTEM_PROCESSOR} --version_dir ${CPACK_PACKAGE_VERSION} --delivery_dir ${DEB_DELIVERY} --source_dir ${CPACK_CMAKE_SOURCE_DIR} --suffix ${CPACK_GENERATOR}
    WORKING_DIRECTORY ${CPACK_CMAKE_BINARY_DIR}
    OUTPUT_VARIABLE result
    ERROR_VARIABLE error
    RESULT_VARIABLE code
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
if (NOT code EQUAL 0)
    message(FATAL_ERROR "Filelist generation failed: ${result} ${error}")
else ()
    message(STATUS "Filelist generated successfully: ${result}")
endif ()