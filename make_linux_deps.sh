#!/bin/sh

# Store the project root for convenience
SCRIPT_DIR=$PWD

# Build the woolydart package for Linux
cd packages/woolydart/src
rm -rf build-linux
cmake -B build-linux -DWOOLY_TESTS=Off -DBUILD_SHARED_LIBS=Off -DGGML_CUDA=On woolycore
cmake --build build-linux --config Release -j8

# Jump back to our project dir
cd "$SCRIPT_DIR"
