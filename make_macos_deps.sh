#!/bin/sh

# Store the project root for convenience
SCRIPT_DIR=$PWD

# Build the woolydart package for MacOS
cd packages/woolydart/src
rm -rf build
cmake -B build -DWOOLY_TESTS=Off -DBUILD_SHARED_LIBS=Off -DGGML_METAL=On -DGGML_METAL_EMBED_LIBRARY=On woolycore
cmake --build build --config Release -j 4

# Jump back to our project dir
cd "$SCRIPT_DIR"

# Now make the binary for xcode's framework
mkdir -p macos/Frameworks/libllama.framework
lipo -create packages/woolydart/src/build/libwoolycore.dylib -output macos/Frameworks/libllama.framework/libllama
install_name_tool -id @rpath/libllama.framework/libllama macos/Frameworks/libllama.framework/libllama