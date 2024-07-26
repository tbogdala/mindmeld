# MindMeld

A simple-to-use GUI for local AI chat.

Supported platforms: iOS, Android
In-Development platforms: MacOS


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

Each platform is a little bit different with Flutter. For MacOS and iOS, the native binaries
for the upstream [woolycore](https://github.com/tbogdala/woolycore) library must be built, while
for Android they're built automatically.

In both iOS and Android cases, you must have an existing [Flutter](https://flutter.dev/) development
setup operational. That should take care of a lot of pain points. Make sure `flutter doctor` runs clean.


### iOS Build Instructions

Before running the app in the simulator or on device, you will need to build binaries manually
for either the simulator or the on-device version. They build to separate directories, but ultimately
*one* binary gets copied to the iOS framework folder, so these scripts will have to be re-run
whenever changing from simulator to device or vice versa.

To build simulator binaries: `./make_ios_simulator_deps.sh`

To build the on-device binaries: `./make_ios_deps.sh`


### MacOS Build Instructions

Much like the iOS Build Instructions above, the MacOS framework binary has to be built manually.
This can be done by running `./make_macos_deps.sh`.


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

*   iOS builds need to have the binaries built manually first.

*   JSON serialization code gets updated with: `dart run build_runner build`.

*   Launcher icons get updated with: `flutter pub run flutter_launcher_icons`.
    Docs: https://pub.dev/packages/flutter_launcher_icons

*   Splash screen gets updated with: `dart run flutter_native_splash:create`.
    Docs: https://github.com/jonbhanson/flutter_native_splash

*   Think downloading a single file would be easy with a framework like Flutter?
    Nope! This package got the job done for me: https://github.com/781flyingdutchman/background_downloader

*   MacOS: Hardened Runtime setting needs 'Disable Library Validation' enabled so that `path_provider` can not crash at app start.

*   iOS: To get over 4GB of memory, I had to add the `com.apple.developer.kernel.increased-memory-limit` entitlement.


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

* Can verify what's exported with `nm -gU ios/Frameworks/libllama.framework/libllama`.


#### Models to explore for mobile devices:

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
* Provide a text hint as to how to add more models in the onboarding page.
* BUG: make sure chat logs with duplicate names can't be made
* Should have copy icon next to chat log settings to copy scenario/desc and then paste icons in the sections.
  Should confirm the pastes with a bottom sheet so that there's not accidental overrides.
* Main screen should be a main menu where you can:
    - chat
    - manage models
    - [tbd: group chat, games, etc]
* When app isn't focus, maybe send the user a notification?
* Long press of send button should 'impersonate' the AI instead if there's a message in the text box?
* Have a help icon for ChatLog Configuration to explain settings verbosely.
* Gotta version info the config files and chat logs
* BUG: changing model in chat log settings wont change the loaded model
* Confirm that not supplying a ConfigModelSetting context size uses -1 or auto for default.
* BUG: ConfigModelSettings that are nullable might not be picking good defaults. 
    ThreadCount to -1 causes crash for example so 1 is hardcoded in as a default if not supplied.
* BUG: Crashes if existing logs have a model name that isn't imported
* BUG?: switching between logs might crash the app?
* Show overall T/s or TG & PP T/s?