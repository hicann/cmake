# AGENTS.md

Guidance for OpenCode sessions working in this repo.

## What this repo is

Shared CMake/Python build, packaging, and install framework for the CANN ecosystem. It is **not a standalone buildable project** — it is consumed by sibling CANN component repos (runtime, metadef, ge, etc.) checked out alongside it under a common parent (`CANN_TOP_DIR` = parent of this repo). There is no root `CMakeLists.txt`; the build entry point is `superbuild/CMakeLists.txt`, driven by `build.sh`.

## Build

```bash
# --pkgs is REQUIRED. Comma-separated package names (e.g. runtime,asc-devkit).
sh build.sh --pkgs=<PACKAGES> [-j<N>] [-v] [--pkg-type=run|rpm|deb] [--build-type=Release|Debug] [--build_host_only] [--asan]
```

- Build dir: `build/`. Output (packaged artifacts): `build_out/`.
- `build.sh` runs `cmake -S superbuild -B build` then `cmake --build build --target package`.
- A full build requires the sibling CANN repos present under `CANN_TOP_DIR` and a CANN toolkit install. Without these the superbuild cannot resolve dependencies — do not attempt to "fix" this by making the repo standalone.
- `ASCEND_CANN_PACKAGE_PATH` (toolkit install) resolution order in `build.sh`: `-p/--cann_path` → `ASCEND_HOME_PATH` → `ASCEND_OPP_PATH` → default dirs (`~/Ascend/cann` non-root, `/usr/local/Ascend/cann` root).
- `--build_host_only` skips the device cross-compile step (see host/device split below).

## Tests

```bash
python3 -m pytest scripts/package/tests/          # packaging tests (from repo root)
python3 -m pytest scripts/build_analysis/tests/   # IWYU log parser tests
python3 -m pytest scripts/package/tests/test_package.py::TestClass -v   # single test
```

- No `pytest.ini`/`pyproject.toml`. Each test dir has its own `conftest.py` that prepends its parent to `sys.path` so modules import without install.
- `classify_rule.yaml` sets `llt.ut_check: true` — keep tests green when changing `scripts/package/**`.

## Architecture notes that are not obvious from filenames

- **Two integration modes, gated by `TOPLEVEL_PROJECT`:** When this repo's `superbuild/` is the top-level project (`TOPLEVEL_PROJECT ON`, set in `function/prepare.cmake:15`), functions like `set_cann_cpack_config`, `add_cann_device_project`, and `check_cann_pkg_build_deps` execute. When consumed by a sibling repo (`TOPLEVEL_PROJECT OFF`), they early-return. `ENABLE_UNIFIED_BUILD` re-enables some of them for multi-repo unified builds. Always check both branches when editing `function/prepare.cmake`.
- **`CANN_TOP_DIR`** is resolved as the parent of this repo (`function/function.cmake:31`). Package dependency resolution reads `version.cmake` files from `${CANN_TOP_DIR}/${pkg_dir}` — package→directory mappings live in `superbuild/config.cmake`.
- **Device cross-compile** uses `toolchain/aarch64-hcc-toolchain.cmake` (aarch64 target via hcc). Host and device builds are separate ExternalProject steps; `PRODUCT_SIDE` (`host`/`device`) controls which source dirs are added (`<pkg>` vs `<pkg>/cmake/device`).
- **`__FILE__` macro rewriting:** Both `prepare.cmake` (non-Ninja) and the toolchain file override `CMAKE_C/CXX_COMPILE_OBJECT` to emit only the basename in `__FILE__`, plus `-Wno-builtin-macro-redefined`. Preserve this when touching compile rules.
- **ABI:** Host defaults to `_GLIBCXX_USE_CXX11_ABI=0` (old ABI); device leaves it unset. See `intf_pub/intf_pub_linux.cmake:38`. `USE_CXX11_ABI` overrides this.
- **ccache** is on by default (`ENABLE_CCACHE`).

## Public API consumed by CANN repos

Functions in `function/prepare.cmake` are the framework's public API: `init_cann_project`, `set_cann_package`, `set_cann_build_dependencies`, `set_cann_run_dependencies`, `set_cann_cpack_config`, `add_cann_third_party`, `find_cann_package`, `generate_cann_stub_library`, `cann_pack_targets_and_files`, `gen_cann_version_header`, `add_cann_sign_file`. Consumer repos call these from their own `CMakeLists.txt`; changing signatures or behavior is a cross-repo breaking change.

## Directory map

| Path | Purpose |
|------|---------|
| `function/` | Core framework: `prepare.cmake` (public API), `function.cmake` (superbuild init + dep resolution) |
| `superbuild/` | Superbuild entrypoints (`CMakeLists.txt` host, `device/CMakeLists.txt` device, `config.cmake` package→dir map) |
| `modules/` | `Find<dep>.cmake` modules; added to `CMAKE_MODULE_PATH` via `PREPEND_MODULE_PATH` |
| `third_party/` | `<name>.cmake` scripts for building external deps (abseil, boost, grpc, protobuf, ...), included via `add_cann_third_party(name)` |
| `intf_pub/` | `intf_pub_linux.cmake` — shared compile/link flags (security hardening, sanitizers, ABI) applied via `add_cann_target_options` |
| `toolchain/` | `aarch64-hcc-toolchain.cmake` for device cross-compile |
| `docs/` | Detailed architecture/integration docs (`architecture.md`, `framework/`, `superbuild/`) |
| `scripts/package/` | Python packaging logic + pytest suite; invoked by CMake at `package` time |
| `scripts/version/` | `check_build_dependencies.py`, `generate_version_info.py` — invoked by CMake functions |
| `scripts/sign/` | Code signing scripts invoked by `add_cann_sign_file` |
| `scripts/signtool/` | Python image pack/extract/ESBC-header tools used by the sign flow |
| `scripts/build_analysis/` | IWYU log parser (`iwyu_log_parser.py`) + pytest suite in `tests/` |
| `scripts/install/` | Shell install scripts shipped in the packages |

## Conventions

- **License header required** on every source file (CANN-2.0), enforced by `OAT.xml`. Copy the header block from any existing file when creating new `.cmake`/`.py`/`.sh` files.
- **C++ standard is C++17** (`CMAKE_CXX_STANDARD 17`, no extensions), set in `init_cann_project`.
- Comments throughout the framework are in Chinese — match this when editing existing files.
- Consumer integration pattern (see `README.md`): `fetch_cann_cmake.cmake` → `include(function/prepare.cmake)` → `init_cann_project()` after `project()`.
