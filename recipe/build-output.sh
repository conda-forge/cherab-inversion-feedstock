#!/bin/bash
set -ex

# Set a few environment variables that are not set due to
# https://github.com/conda/conda-build/issues/3993
export PIP_NO_BUILD_ISOLATION=True
export PIP_NO_DEPENDENCIES=True
export PIP_IGNORE_INSTALLED=True
export PIP_NO_INDEX=True
export PYTHONDONTWRITEBYTECODE=True

if [[ "$PKG_NAME" == "cherab-inversion" ]]; then
    # install wheel from build.sh
    pip install $PREFIX/dist/cherab*.whl

    # clean up dist folder for building tests
    rm -rf $PREFIX/dist
else
    # copy of build.sh, except different build tags; instead of using the
    # same script (lightly templated on tags) per output, we keep the
    # global build to reuse the cache when building the tests

    # need to rename project as well; for more details see
    # https://scipy.github.io/devdocs/building/redistributable_binaries.html
    sed -i "s:name = \"cherab-inversion\":name = \"cherab-inversion-tests\":g" pyproject.toml

    # HACK: extend $CONDA_PREFIX/meson_cross_file that's created in
    # https://github.com/conda-forge/ctng-compiler-activation-feedstock/blob/main/recipe/activate-gcc.sh
    # https://github.com/conda-forge/clang-compiler-activation-feedstock/blob/main/recipe/activate-clang.sh
    # to use host python; requires that [binaries] section is last in meson_cross_file
    echo "python = '${PREFIX}/bin/python'" >> ${CONDA_PREFIX}/meson_cross_file.txt

    # meson-python already sets up a -Dbuildtype=release argument to meson, so
    # we need to strip --buildtype out of MESON_ARGS or fail due to redundancy
    MESON_ARGS_REDUCED="$(echo $MESON_ARGS | sed 's/--buildtype release //g')"

    # -wnx flags mean: --wheel --no-isolation --skip-dependency-check
    $PYTHON -m build -w -n -x \
        -Cbuilddir=builddir \
        -Cinstall-args=--tags=runtime,python-runtime,tests \
        || (cat builddir/meson-logs/meson-log.txt && exit 1)

    pip install dist/cherab*.whl
fi