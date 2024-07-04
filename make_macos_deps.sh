#!/bin/sh

# Store the project root for convenience
SCRIPT_DIR=$PWD

# Build the woolydart package for MacOS
cd packages/woolydart/src/llama.cpp
rm -rf build
mkdir build
cd build
cmake .. -DBUILD_SHARED_LIBS=ON -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_SERVER=OFF -DLLAMA_METAL_EMBED_LIBRARY=ON
make build_info
cmake --build . --config Release

# Jump back to our project dir
cd "$SCRIPT_DIR"

# Now make the binary for xcode's framework
mkdir -p macos/Frameworks/libllama.framework
lipo -create packages/woolydart/src/llama.cpp/build/libllama.dylib -output macos/Frameworks/libllama.framework/libllama
install_name_tool -id @rpath/libllama.framework/libllama macos/Frameworks/libllama.framework/libllama