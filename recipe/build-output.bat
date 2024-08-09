@echo on
setlocal enabledelayedexpansion

REM Set a few environment variables that are not set due to
REM https://github.com/conda/conda-build/issues/3993
set PIP_NO_BUILD_ISOLATION=True
set PIP_NO_DEPENDENCIES=True
set PIP_IGNORE_INSTALLED=True
set PIP_NO_INDEX=True
set PYTHONDONTWRITEBYTECODE=True

REM delete tests from baseline output "cherab-inversion"
if "%PKG_NAME%"=="cherab-inversion" (
    REM `pip install dist\numpy*.whl` does not work on windows,
    REM so use a loop; there's only one wheel in dist/ anyway
    for /f %%f in ('dir /b /S .\dist') do (
        pip install %%f
        if %ERRORLEVEL% neq 0 exit 1
    )

    REM clean up dist folder for building tests
    rmdir /s /q dist
) else (
    REM copy of build.sh, except different build tags and fortran setup;
    REM instead of using the same script (lightly templated on tags) per output,
    REM we keep the global build to reuse the cache when building the tests.

    REM need to rename project as well; for more details see
    REM https://scipy.github.io/devdocs/building/redistributable_binaries.html
    sed -i "s:name = \"cherab-inversion\":name = \"cherab-inversion-tests\":g" pyproject.toml

    :: see explanation here:
    :: https://github.com/conda-forge/scipy-feedstock/pull/253#issuecomment-1732578945
    set "MESON_RSP_THRESHOLD=320000"

    :: -wnx flags mean: --wheel --no-isolation --skip-dependency-check
    %PYTHON% -m build -w -n -x ^
        -Cbuilddir=builddir ^
        -Cinstall-args=--tags=runtime,python-runtime,test
    if %ERRORLEVEL% neq 0 (type builddir\meson-logs\meson-log.txt && exit 1)

    for /f %%f in ('dir /b /S .\dist') do (
        pip install %%f
        if %ERRORLEVEL% neq 0 exit 1
    )
)