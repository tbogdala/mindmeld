#!/bin/sh

# Store the project root for convenience
SCRIPT_DIR=$PWD

# Build the woolydart package for MacOS
cd packages/woolydart/src
rm -rf build
cmake -B build -DLLAMA_METAL=On -DLLAMA_METAL_EMBED_LIBRARY=On 
cmake --build build --config Release

# Jump back to our project dir
cd "$SCRIPT_DIR"

# Now make the binary for xcode's framework
mkdir -p macos/Frameworks/libllama.framework
lipo -create packages/woolydart/src/build/libwoolydart.dylib -output macos/Frameworks/libllama.framework/libllama
install_name_tool -id @rpath/libllama.framework/libllama macos/Frameworks/libllama.framework/libllama