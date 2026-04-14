# ----------------------------------------------------------------------------
# Copyright (c) 2025 Huawei Technologies Co., Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------
if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

unset(eigen_FOUND CACHE)
unset(eigen_INCLUDE CACHE)

if(NOT OPEN_PKG_PATH)
  set(OPEN_PKG_PATH ${CANN_3RD_LIB_PATH}/pkg) 
endif() 


set(EIGEN_DOWNLOAD_PATH ${CANN_3RD_LIB_PATH}/pkg)

file(GLOB EIGEN_INSTALL_PATH "${CANN_3RD_LIB_PATH}/eigen*")

if(EIGEN_INSTALL_PATH)
  find_path(EIGEN_INCLUDE 
          NAMES CMakeLists.txt 
          NO_CMAKE_SYSTEM_PATH 
          NO_CMAKE_FIND_ROOT_PATH 
          PATHS ${EIGEN_INSTALL_PATH}) 


    include(FindPackageHandleStandardArgs) 
    find_package_handle_standard_args(eigen 
            FOUND_VAR 
            eigen_FOUND 
            REQUIRED_VARS 
            EIGEN_INCLUDE 
            )
else()
  set(EIGEN_INSTALL_PATH ${CANN_3RD_LIB_PATH}/eigen)
endif()

if(eigen_FOUND AND NOT FORCE_REBUILD_CANN_3RD)
  message("eigen found in ${EIGEN_INSTALL_PATH}, and not force rebuild cann third_party") 
else()
  if (IS_DIRECTORY "${CANN_3RD_LIB_PATH}/eigen")
    set(REQ_URL "${CANN_3RD_LIB_PATH}/eigen")
  else()
    set(REQ_URL "https://gitcode.com/cann-src-third-party/eigen/releases/download/5.0.0-h0.trunk/eigen-5.0.0.tar.gz")
  endif()

  include(ExternalProject)
  ExternalProject_Add(external_eigen
    TLS_VERIFY        OFF
    URL               ${REQ_URL}
    DOWNLOAD_DIR      download/eigen
    SOURCE_DIR        third_party
    CONFIGURE_COMMAND ""
    BUILD_COMMAND     ""
    INSTALL_COMMAND   ""
  )

  ExternalProject_Get_Property(external_eigen SOURCE_DIR)
endif()

add_library(Eigen INTERFACE)
target_compile_options(Eigen INTERFACE -w)

set_target_properties(Eigen PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "${SOURCE_DIR}"
)
add_dependencies(Eigen external_eigen)
add_library(Eigen3::Eigen ALIAS Eigen)
target_include_directories(Eigen INTERFACE ${EIGEN_INSTALL_PATH})