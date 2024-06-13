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

*   `dart run build_runner build` to update the json serializable code.

Building the necessary library components for the iOS simulator app.

```bash
cd packages/woolydart/src/llama.cpp
mkdir build-ios
cd build-ios
cmake .. -DBUILD_SHARED_LIBS=ON -DLLAMA_METAL=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_SERVER=OFF -DCMAKE_TOOLCHAIN_FILE=~/Stash/codes/mindmeld/packages/ios-cmake/ios.toolchain.cmake -DPLATFORM=SIMULATORARM64
make build_info
cmake --build . --config Release
cd ~/Stash/codes/mindmeld
#rm -rf ios/Frameworks
#mkdir -p ios/Frameworks
#cp packages/woolydart/src/llama.cpp/build-ios/libllama.dylib ios/Frameworks/libllama.dylib
#dart run build_runner build --delete-conflicting-outputs # maybe needed? still can't load libllama
mkdir -p ios/Frameworks/libllama.framework
lipo -create packages/woolydart/src/llama.cpp/build-ios/libllama.dylib -output ios/Frameworks/libllama.framework/libllama
install_name_tool -id @rpath/libllama.framework/libllama ios/Frameworks/libllama.framework/libllama
```

Actually building for real devices means rebuilding the binary:

```bash
cmake .. -DBUILD_SHARED_LIBS=ON -DLLAMA_METAL=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_SERVER=OFF -DCMAKE_TOOLCHAIN_FILE=~/Stash/codes/mindmeld/packages/ios-cmake/ios.toolchain.cmake -DPLATFORM=OS64
make build_info
```

Steps to get iOS going
* `vtool -show ios/Frameworks/libllama.framework/libllama ios/Frameworks/libllama.framework/libllama` shows minos version needed
* right click 'ios' in vs code, open in Xcode
* Select Runner in project navigator view on the left
* In 'build settings' change minimum deployments to 14.0 (There might have been one more place I changed that.)
* Scroll down to 'Frameworks, Libraries, and Embedded Content and click +
* Hit the 'add other..' button select 'add files...' browse to the 'libllama.framework' folder and click the 'open' button to add the framework.
* Add 'Info.plist' file, edited by hand.

* Upped minimum deployments to iOS 16 with a target of iOS 17.
* Added reference to Accelerate and Metal frameworks.
* -DLLAMA_METAL_EMBED_LIBRARY=ON


#### Models to explore:

https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF   (tinychat)
https://huggingface.co/stabilityai/stablelm-zephyr-3b           (zephyr)
https://huggingface.co/NousResearch/Nous-Capybara-3B-V1.9       (chatml)
https://huggingface.co/tsunemoto/TinyDolphin-2.8-1.1b-GGUF      (chatml probably)
https://huggingface.co/rhysjones/phi-2-orange-v2                (chatml)
https://huggingface.co/cognitivecomputations/dolphin-2_6-phi-2  (chatml)
https://huggingface.co/BeaverAI/Cream-Phi-3-4B-v1.1-GGUF        (phi3?)

Configurations can be consulted from the LM Studio repo:
https://github.com/lmstudio-ai/configs

#### TODO

* Need to break apart the new chat log page to have model setup on it's own page.
* Add avatar pictures to the chat log and to be used in the AppBar for the chat log page
* Low nBatch ruined something in llama_decode somewhere in the bindings. Batch of 8 limited incoming prompt to 166 characters.
* think about how to deal with extra messages getting sent while one is being predicted.
* Provide a text hint as to how to add more models in the onboarding page.
* BUG: make sure chat logs with duplicate names can't be made
* Should have copy icon next to chat log settings to copy scenario/desc and then paste icons in the sections.
  Should confirm the pastes with a bottom sheet so that there's not accidental overrides.
* Main screen should be a main menu where you can:
    - chat
    - manage models
    - [tbd: group chat, games, etc]
* Launch icon
* When app isn't focus, maybe send the user a notification?
* BUG: backing out of log view while generating doesn't stop generation; will eventually show up in log, but feels awkward.
* Sort chat log list by recent use?
* Long press of send button should 'impersonate' the AI instead if there's a message in the text box?
* Have a help icon for ChatLog Configuration to explain settings verbosely.
* Gotta version info the config files and chat logs