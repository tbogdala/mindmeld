# MindMeld


#### Dev Notes

*   Added the `woolydart` Dart wrapper under `./packages` so that it can be built by the android
    toolchain in this example.

    This library must have the `llama.cpp` sources patched and built per the README of that project!

    Currently needs to be downloaded and moved into the folder manually, but it will be added as
    a submodule eventually, once uploaded to github.

*   `android/app/build.gradle references "../../packages/CMakeLists.txt" as the makefile to 
    build the android llama.cpp cross compiled libraries. This is basically a very light cmake
    file that turns on shared library building and then just defers to the upstream CMakeLists.txt
    file for compatibility. Everything else seems to happen automatically and requires no
    direct action.

*   The [aub.ai](https://github.com/BrutalCoding/aub.ai/) repo was a huge help in figuring 
    out the iOS solution. There's also [this Medium blog](https://medium.com/@khaifunglim97/how-to-build-a-flutter-app-with-c-c-libraries-via-ffi-on-android-and-ios-including-opencv-1e2124e85019)
    and [this StackOverflow question](https://stackoverflow.com/questions/69214595/how-to-manually-add-a-xcframework-to-a-flutter-ios-plugin/70210039#70210039)
    that helped too. For UI work [this chat log example blog](https://www.freecodecamp.org/news/build-a-chat-app-ui-with-flutter/) was helpful.

*   iOS builds need to have the binaries built manually first.

```bash
cd packages/woolydart/src/llama.cpp
mkdir build-ios
cd build-ios
cmake .. -DBUILD_SHARED_LIBS=ON -DLLAMA_METAL=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_SERVER=OFF -DCMAKE_TOOLCHAIN_FILE=../../../../ios-cmake/ios.toolchain.cmake -DPLATFORM=OS64
cmake --build . --config Release
cd ../../../../..
mkdir -p ios/Frameworks/libllama.framework
lipo -create packages/woolydart/src/llama.cpp/build-ios/libllama.dylib -output ios/Frameworks/libllama.framework/libllama
install_name_tool -id @rpath/libllama.framework/libllama ios/Frameworks/libllama.framework/libllama
```

    Looks like ios-cmake will be needed, but I've removed it from the `packages` folder for now.

* Need to break apart the new chat log page to have model setup on it's own page.
* Model setup should be how models are copied over ('installed') with the file picker
  and the formatting set. Then in the new chat log page, the configured model can just be
  chosen from a drop down.
* Add avatar pictures to the chat log and to be used in the AppBar for the chat log page