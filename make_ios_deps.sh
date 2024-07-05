#!/bin/sh

# Store the project root for convenience
SCRIPT_DIR=$PWD

# Build the woolydart package for MacOS
cd packages/woolydart/src
rm -rf build-ios
cmake -B build-ios -DLLAMA_METAL=On -DLLAMA_METAL_EMBED_LIBRARY=On -DCMAKE_TOOLCHAIN_FILE=~/Stash/codes/mindmeld/packages/ios-cmake/ios.toolchain.cmake -DENABLE_VISIBILITY=On -DPLATFORM=OS64
cmake --build build-ios --config Release

# Jump back to our project dir
cd "$SCRIPT_DIR"

# Now make the binary for xcode's framework
mkdir -p ios/Frameworks/libllama.framework
lipo -create packages/woolydart/src/build-ios/libwoolydart.dylib -output ios/Frameworks/libllama.framework/libllama
install_name_tool -id @rpath/libllama.framework/libllama ios/Frameworks/libllama.framework/libllama