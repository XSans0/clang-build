#!/usr/bin/env bash
# Copyright ©2022-2024 XSans0

# Function to show an informational message
msg(){
    echo -e "\e[1;32m$*\e[0m"
}
err(){
    echo -e "\e[1;41$*\e[0m"
}

# Get home directory
HOME_DIR="$(pwd)"

# Building LLVM's
msg "Building LLVM's ..."
./build-llvm.py \
    --defines "LLVM_PARALLEL_COMPILE_JOBS=$(nproc) LLVM_PARALLEL_LINK_JOBS=$(nproc) CMAKE_C_FLAGS=-O3 CMAKE_CXX_FLAGS=-O3" \
    --install-folder "$HOME_DIR/install" \
    --no-update \
    --no-ccache \
    --quiet-cmake \
    --targets "AArch64 ARM X86" \
    --use-good-revision \
    --vendor-string "WeebX"

# Check if the final clang binary exists or not
for file in install/bin/clang-1*; do
    if [ -e "$file" ]; then
        msg "LLVM's build successful"
    else
        err "LLVM's build failed!"
        exit
    fi
done

# Build binutils
msg "Build binutils ..."
./build-binutils.py \
    --install-folder "$HOME_DIR/install" \
    --targets arm aarch64 x86_64

# Remove unused products
rm -fr install/include
rm -f install/lib/*.a install/lib/*.la

# Strips remaining products
for f in $(find install -type f -exec file {} \; | grep 'not stripped' | awk '{print $1}'); do
    strip -s "${f::-1}"
done

# Set executable rpaths so setting LD_LIBRARY_PATH isn't necessary
for bin in $(find install -mindepth 2 -maxdepth 3 -type f -exec file {} \; | grep 'ELF .* interpreter' | awk '{print $1}'); do
    # Remove last character from file output (':')
    bin="${bin::-1}"

    echo "$bin"
    patchelf --set-rpath "$DIR/../lib" "$bin"
done