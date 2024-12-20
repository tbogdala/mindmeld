#!/bin/sh

# Store the project root for convenience
SCRIPT_DIR=$PWD

# Build the woolydart package for MacOS
cd packages/woolydart/src
rm -rf build-ios-sim
cmake -B build-ios-sim -DWOOLY_TESTS=Off -DBUILD_SHARED_LIBS=Off -DGGML_STATIC=On -DGGML_METAL=OFF -DGGML_METAL_EMBED_LIBRARY=OFF -DCMAKE_TOOLCHAIN_FILE=~/Stash/codes/mindmeld/packages/ios-cmake/ios.toolchain.cmake -DENABLE_VISIBILITY=On -DPLATFORM=SIMULATORARM64 woolycore
cmake --build build-ios-sim --config Release -j 4

# Jump back to our project dir
cd "$SCRIPT_DIR"

# Now make the binary for xcode's framework
mkdir -p ios/Frameworks/libllama.framework
lipo -create packages/woolydart/src/build-ios-sim/libwoolycore.dylib -output ios/Frameworks/libllama.framework/libllama
install_name_tool -id @rpath/libllama.framework/libllama ios/Frameworks/libllama.framework/libllama