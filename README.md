# cmake

## 🔥 Latest News

- [2026/3] cmake项目首次上线。


## 概述

**cmake** 是 CANN（Compute Architecture for Neural Networks）生态中提供**公共编译脚本、第三方开源软件编译脚本、公共打包与安装框架脚本**的仓库，实现多仓联合编译，统一打包和安装流程。
```
┌─────────────────────────────────────────────────────────────┐
│                    CANN 组件生态                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ runtime  │  │ metadef  │  │  hcomm   │  │   ...    │     │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘     │
│       │             │             │             │           │
│       └─────────────┴──────┬──────┴─────────────┘           │
│                            ▼                                │
│                   ┌─────────────────┐                       │
│                   │      cmake      │                       |
│                   └─────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

## 📂 目录结构

```
cmake/
├── scripts/                        # 脚本目录
│   ├── package/                    # 打包相关脚本
│   └── install/                    # 安装相关脚本
├── third_party/                    # 第三方开源软件编译脚本
├── function/                       # 功能模块目录
├── intf_pub/                       # 公共目录
├── superbuild/                     # 集成工程目录
├── toolchain/                      # 工具链目录
└── README.md                       # 项目说明文档
```


##  快速开始

<span style="font-size:16px;">  **重要说明**：本仓库是 CANN 组件的配套构建脚本，**不能独立使用**，需要与 CANN 下的其它组件（如 runtime、ops-transformer 等）配套使用。
</span>

在CANN其它组件引入本仓库方法如下：

1. **创建cmake/fetch_cann_cmake.cmake文件**

    粘贴以下代码。

    ```cmake
    if(NOT PROJECT_SOURCE_DIR)
        if(CANN_3RD_LIB_PATH AND IS_DIRECTORY "${CANN_3RD_LIB_PATH}/cmake")
            include("${CANN_3RD_LIB_PATH}/cmake/function/prepare.cmake")
        else()
            include(FetchContent)
    
            set(CANN_CMAKE_TAG "1.0.0")
            if(CANN_3RD_LIB_PATH AND EXISTS "${CANN_3RD_LIB_PATH}/cann-cmake-${CANN_CMAKE_TAG}.tar.gz")
                FetchContent_Declare(
                    cann-cmake
                    URL "${CANN_3RD_LIB_PATH}/cann-cmake-${CANN_CMAKE_TAG}.tar.gz"
                )
            else()
                FetchContent_Declare(
                    cann-cmake
                    GIT_REPOSITORY https://gitcode.com/cann/cmake.git
                    GIT_TAG        ${CANN_CMAKE_TAG}
                    GIT_SHALLOW    TRUE
                )
            endif()
            FetchContent_GetProperties(cann-cmake)
            if(NOT cann-cmake_POPULATED)
                FetchContent_Populate(cann-cmake)
            endif()
            include("${cann-cmake_SOURCE_DIR}/function/prepare.cmake")
        endif()
    endif()
    ```

2. **添加include(cmake/fetch_cann_cmake.cmake)命令**

    根目录的CMakeLists.txt中，cmake_minimum_required命令之后，project命令之前，添加``include(cmake/fetch_cann_cmake.cmake)``。

3. **添加init_cann_project()命令**

    初始化cmake工程。init_cann_project中会执行一些初始化操作，设置公共参数等。

    ```cmake
    cmake_minimum_required(VERSION 3.16)
    include(cmake/fetch_cann_cmake.cmake)
    project(runtime)

    init_cann_project()
    ```

## 相关信息

- [贡献指南](./CONTRIBUTING.md)
- [安全声明](./SECURITY.md)
- [许可证](./LICENSE)
