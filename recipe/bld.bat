@echo on
setlocal enabledelayedexpansion

mkdir builddir

:: check if clang-cl is on path as required
clang-cl.exe --version
if %ERRORLEVEL% neq 0 exit 1

:: see explanation here:
:: https://github.com/conda-forge/scipy-feedstock/pull/253#issuecomment-1732578945
set "MESON_RSP_THRESHOLD=320000"

:: -wnx flags mean: --wheel --no-isolation --skip-dependency-check
%PYTHON% -m build -w -n -x ^
    -Cbuilddir=builddir ^
    -Cinstall-args=--tags=runtime,python-runtime,devel
if %ERRORLEVEL% neq 0 (type builddir\meson-logs\meson-log.txt && exit 1)