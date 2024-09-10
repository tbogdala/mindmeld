# MindMeld

A simple-to-use, open source GUI for local AI chat.

Supported platforms: iOS, Android, MacOS, Linux
In-Development platforms: Windows


## Features

* Based on [llama.cpp](https://github.com/ggerganov/llama.cpp) and supports any model supported by that project in GGUF form.
* Graphical user interface, tailored towards chatting with AI, which is mobile compatible.
* Create multiple chat logs, each with their own parameters, story context and characters
* Customizable character portrait images.
* Automatic model downloading from HuggingFace.
* Built-in 'narrator' using the slash-command '/narrator' at the start of a message.
* Lorebook support: customizable lists of 'lore' text that gets added behind the scenes
  to the LLM prompt when a pattern is matched in the chat log context or recent messages.
  Lorebooks are active across all chats and are enabled if a character name from the chat
  log pattern matches.
* Fast regeneration of AI chat replies with prompt caching.


## Getting the source code

Make sure to check out the repository while being mindful of the submodules. The 
initial commit can be done with:

```bash
git clone --recurse-submodules https://github.com/tbogdala/mindmeld.git
```

To update it, remember to recurse the submodules as well:

```bash
git pull --recurse-submodules
```


## Build Instructions

Each platform is a little bit different with Flutter. For MacOS, iOS and Linux, the native binaries
for the upstream [woolycore](https://github.com/tbogdala/woolycore) library must be built, while
for Android they're built automatically.

In both iOS and Android cases, you must have an existing [Flutter](https://flutter.dev/) development
setup operational with the additional components necessary for the chosen mobile ecosystem. 
That should take care of a lot of pain points. Make sure `flutter doctor` runs clean.


### iOS Build Instructions

Before running the app in the simulator or on device, you will need to build binaries manually
for either the simulator or the on-device version. They build to separate directories, but ultimately
*one* binary gets copied to the iOS framework folder, so these scripts will *have to be re-run*
whenever changing from simulator to device or vice versa.

To build simulator binaries: `./make_ios_simulator_deps.sh`

To build the on-device binaries: `./make_ios_deps.sh`

Simulator performance on MacOS is sensitive to thread count; using a Thread Count of 4 in the chat log
configuration helps performance **immensely**, because simulator binaries are not built with
Metal enabled.


### MacOS Build Instructions

Much like the iOS Build Instructions above, the MacOS framework binary has to be built manually.
This can be done by running `./make_macos_deps.sh`.


### Linux Build Instructions

Similar to most other build targets, you have to run a script to compile the
dependencies before running the program. This can be done by running `./make_linux_deps.sh`.

The program can be run with the desktop launcher by running `flutter run --release`.


### Android Build Instructions

The Android system shouldn't need any extra steps once the whole ecosystem for Android support
in flutter is setup. `android/app/build.gradle` has some minimums. It's expecting the compiler
to be SDK 35, and the NDK used is "27.0.12077973". The Android SDK CMake version was pinned
to "3.22.1" as well. You'll want to make sure you have those downloaded in the Android SDK Manager.

When compiling the project it will compile the upstream [woolycore](https://github.com/tbogdala/woolycore)
and [llama.cpp](https://github.com/ggerganov/llama.cpp) code for Android use.

To do a full clean Android build, besides running `flutter clean` you need to `rm -rf android/app/.cxx`.

Note: The Android build of upstream [woolycore](https://github.com/tbogdala/woolycore) is not
hardware accelerated and running anything bigger than say TinyLlama-1.1B at Q4_K_M will be super slow.


## License

This project is licensed under the GPL v3 terms, as specified in the `LICENSE` file.

The project is built around [woolycore](https://github.com/tbogdala/woolycore), 
[woolydart](https://github.com/tbogdala/woolydart) for the language bindings and of course the 
great [llama.cpp](https://github.com/ggerganov/llama.cpp) library. All three of these libraries
are licensed under the MIT license.


#### Dev Notes

*   `android/app/build.gradle references "../../packages/CMakeLists.txt" as the makefile to 
    build the android llama.cpp cross compiled libraries. This is basically a very light cmake
    file that turns on shared library building and then just defers to the upstream CMakeLists.txt
    file for compatibility. Everything else seems to happen automatically and requires no
    direct action.

*   The [aub.ai](https://github.com/BrutalCoding/aub.ai/) repo was a huge help in figuring 
    out the iOS solution. There's also [this Medium blog](https://medium.com/@khaifunglim97/how-to-build-a-flutter-app-with-c-c-libraries-via-ffi-on-android-and-ios-including-opencv-1e2124e85019)
    and [this StackOverflow question](https://stackoverflow.com/questions/69214595/how-to-manually-add-a-xcframework-to-a-flutter-ios-plugin/70210039#70210039)
    that helped too. For UI work [this chat log example blog](https://www.freecodecamp.org/news/build-a-chat-app-ui-with-flutter/) was helpful.


*   JSON serialization code gets updated with: `dart run build_runner build`.

*   Launcher icons get updated with: `flutter pub run flutter_launcher_icons`.
    Docs: https://pub.dev/packages/flutter_launcher_icons

*   Think downloading a single file would be easy with a framework like Flutter?
    Nope! This package got the job done for me: https://github.com/781flyingdutchman/background_downloader

*   MacOS: Hardened Runtime setting needs 'Disable Library Validation' enabled so that `path_provider` 
    can not crash at app start.

*   MacOS: Removed App Sandbox entitlement in order to access GGUF files the user may already have 
    elsewhere on the system, say, for example, in the user's `.cache/huggingface` or `.cache/lm-studio` 
    folders. With the sandbox, the models would need to be duplicated or moved into one of the standard 
    folders, like `~/Documents`.

*   iOS: To get over 4GB of memory, I had to add the `com.apple.developer.kernel.increased-memory-limit` 
    entitlement.


Steps used to get iOS going, initially:
* `vtool -show ios/Frameworks/libllama.framework/libllama ios/Frameworks/libllama.framework/libllama` shows minos version needed
* right click 'ios' in vs code, open in Xcode
* Select Runner in project navigator view on the left
* In 'build settings' change minimum deployments to 14.0 (There might have been one more place I changed that.)
* Scroll down to 'Frameworks, Libraries, and Embedded Content and click +
* Hit the 'add other..' button select 'add files...' browse to the 'libllama.framework' folder and click the 'open' button to add the framework.
* Add 'Info.plist' file, edited by hand.
* Upped minimum deployments to iOS 16 with a target of iOS 17.
* Added reference to Accelerate and Metal frameworks.
* Can verify what's exported with `nm -gU ios/Frameworks/libllama.framework/libllama`.


#### TODO

* BUG: make sure chat logs with duplicate names can't be made
* Should have copy icon next to chat log settings to copy scenario/desc and then paste icons in the sections.
  Should confirm the pastes with a bottom sheet so that there's not accidental overrides.
* Have a help icon for ChatLog Configuration to explain settings verbosely.
* Confirm that not supplying a ConfigModelSetting context size uses -1 or auto for default.
* Show overall T/s or TG & PP T/s?
* BUG: /narrator replies cannot be continued as the narrator, currently.
* BUG: any file can be added as a model, such as `img.png`. :(
* Streaming text generation.
* Hitting esc on edit should cancel edit; or have a cancel button
* Setup quantization for KV cache
* Configurable switch to select between prompt caching for regeneration and prompt caching for continuation
* BUG: long-pressing send button while editing does weird behavior.


### Road to Github release:

1) When creating a first log, fill in some default settings and use Vox for a default character.
2) Ensure first-run experience is satisfactory for a first dev version release.
3) Debug window that shows the prompt and the response data from the llm with a 'copy to clipboard' button.

