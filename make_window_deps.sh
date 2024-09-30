#!/bin/sh

# Store the project root for convenience
SCRIPT_DIR=$PWD

# Build the woolydart package for Windows
cd packages/woolydart/src
cmake -B build-windows -DGGML_CUDA=On -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=TRUE -DBUILD_SHARED_LIBS=TRUE woolycore
cmake --build build-windows --config Release -j 4

# Jump back to our project dir
cd "$SCRIPT_DIR"

# make sure the build folders exist and then copy the files over
# manually ... 
#
# this is some low-iq hackjob revolving around not actually making a 'plugin'
# for flutter that should do all of this automatically...
mkdir -p build/windows/x64/runner/Release
mkdir -p build/windows/x64/runner/Debug
cp packages/woolydart/src/build-windows/bin/Release/ggml.dll build/windows/x64/runner/Release
cp packages/woolydart/src/build-windows/bin/Release/llama.dll build/windows/x64/runner/Release
cp packages/woolydart/src/build-windows/Release/woolycore.dll build/windows/x64/runner/Release
cp packages/woolydart/src/build-windows/bin/Release/ggml.dll build/windows/x64/runner/Debug
cp packages/woolydart/src/build-windows/bin/Release/llama.dll build/windows/x64/runner/Debug
cp packages/woolydart/src/build-windows/Release/woolycore.dll build/windows/x64/runner/Debug

