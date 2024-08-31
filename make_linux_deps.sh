#!/bin/sh

# Store the project root for convenience
SCRIPT_DIR=$PWD

# Build the woolydart package for MacOS
cd packages/woolydart/src
rm -rf build-linux
cmake -B build-linux -DGGML_CUDA=On woolycore
cmake --build build-linux --config Release -j 4

# Jump back to our project dir
cd "$SCRIPT_DIR"