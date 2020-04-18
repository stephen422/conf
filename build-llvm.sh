#!/bin/bash -eux

### CMAKE OPTIONS
# Ref: http://lists.llvm.org/pipermail/llvm-dev/2016-March/096734.html
# NOTE #3: How to check available cmake-options?
# EXAMPLE #3: cd $BUILD_DIR ; cmake ../llvm -LA | egrep $CMAKE_OPTS
#
# NOTE-1: cmake/ninja: Use LLVM_PARALLEL_COMPILE_JOBS and
# LLVM_PARALLEL_LINK_JOBS options
# NOTE-2: For fast builds use available (online) CPUs +1 or set values
# explicitly
# NOTE-3: For fast and safe linking use bintils-gold and LINK_JOBS="1"
# COMPILE_JOBS="2"

# Some useful docs.
# Purpose of LLVM_ENABLE_LIBCXX: http://lists.llvm.org/pipermail/llvm-dev/2015-July/088689.html

if [ "$#" -ge 1 ]; then
    REV=${1}
else
    REV=master
fi

export CC=${CC:-/usr/bin/clang}
export CXX=${CXX:-/usr/bin/clang++}
timestamp=$(date +'%y%m%d-%H%M%S')
prefix=${HOME}/build/llvm-${REV}-${timestamp}
workdir=${PWD}/build-llvm-${REV}-${timestamp}
srcdir=${workdir}/llvm-project
builddir=${workdir}/build

mkdir ${workdir}
cd ${workdir}

echo ">>> Fetching LLVM."
if [[ ! -d ${srcdir} ]]; then
    echo "REV: ${REV}"
    git clone https://github.com/llvm/llvm-project ${srcdir}
else
    echo "Skipping clone."
fi
pushd ${srcdir}
git checkout ${REV}
# git pull --depth 1 origin ${REV}
# git gc --prune=all
popd

echo ""
echo ">>> Configuring LLVM."
mkdir ${builddir}
cd ${builddir}

cmake_args=(
-DCMAKE_BUILD_TYPE=Release
-DCMAKE_INSTALL_PREFIX=${prefix}
-DCMAKE_C_FLAGS=-march=native
-DCMAKE_CXX_FLAGS=-march=native
-DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt;libcxx;libcxxabi;libunwind;lld;lldb;openmp;polly"
-DLLVM_INSTALL_UTILS=On
-DLLDB_ENABLE_LIBEDIT=On
-DLLVM_ENABLE_ASSERTIONS=Off
-DLIBCXXABI_ENABLE_ASSERTIONS=Off
-DLIBUNWIND_ENABLE_ASSERTIONS=Off
)
# -DLIBCXX_USE_COMPILER_RT=On
# -DLIBCXXABI_USE_COMPILER_RT=On
# -DLIBCXXABI_USE_LLVM_UNWINDER=On
# -DLIBUNWIND_USE_COMPILER_RT=On
#
# This option is recommended against in the official libc++ documentation
# (https://libcxx.llvm.org/docs/BuildingLibcxx.html), unless libc++abi is
# already installed on the system:
# -DLIBCXX_CXX_ABI=libcxxabi
#
# Cause the Clang/LLVM binaries to be linked against a system-installed libc++:
# -DLLVM_ENABLE_LIBCXX=On
#
# To link libunwind statically into everything add follows:
# -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=On
# -DLIBCXXABI_ENABLE_STATIC_UNWINDER=On
# -DSANITIZER_USE_STATIC_LLVM_UNWINDER=On

if [ "$(uname)" == "Darwin" ]; then
    cmake_args+=( -DLLVM_CREATE_XCODE_TOOLCHAIN=ON)
    cmake_args+=( -DCOMPILER_RT_ENABLE_IOS=Off)
    cmake_args+=( -DLLVM_BUILD_EXTERNAL_COMPILER_RT=ON)
    cmake_args+=( -DLLVM_ENABLE_LIBCXX=ON)
    cmake_args+=( -DDEFAULT_SYSROOT=$(xcrun --sdk macosx --show-sdk-path))
else
    # These args set the Clang's default behavior when building other programs,
    # tend to wreck LLVM tests because there's usually no existing libc++ in
    # the system at the time of the test.
    # cmake_args+=( -DCLANG_DEFAULT_CXX_STDLIB=libc++)
    # cmake_args+=( -DCLANG_DEFAULT_LINKER=lld)
    # cmake_args+=( -DCLANG_DEFAULT_RTLIB=compiler-rt)
    # compiler-rt can replace libgcc_s except that it doesn't incluce an
    # unwinder; that's why we need to specify libunwind as the default
    # unwindlib.
    # See https://github.com/rust-lang/rust/issues/65051#issuecomment-537862559.
    # cmake_args+=( -DCLANG_DEFAULT_UNWINDLIB=libunwind)

    # cmake_args+=( -DCOMPILER_RT_USE_BUILTINS_LIBRARY=On)
    # cmake_args+=( -DCOMPILER_RT_USE_LIBCXX=On)

    cmake_args+=( -DLLVM_USE_LINKER=gold)
    cmake_args+=( -DLLVM_PARALLEL_LINK_JOBS=2)

    # not really needed for Void linux
    # cmake_args+=( -DLLVM_LIBDIR_SUFFIX=64)
fi

echo ">>> Configured arguments:"
echo ${cmake_args[*]}

cmake ${srcdir}/llvm -G Ninja ${cmake_args[@]}

echo ""
echo ">>> Building."
cmake --build . -- -v

echo ""
echo ">>> Checking."
# check-lldb fails
cmake --build . --target check-llvm check-clang check-cxx check-cxxabi check-lld

echo ""
echo ">>> Installing."
cmake --build . --target install

echo ""
echo ">>> Creating symbolic link."
rm -f $HOME/build/llvm
ln -s $prefix $HOME/build/llvm
echo ""
echo ">>> Finished!"
