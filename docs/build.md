# Building Mindmeld From Source

## Requirements

In general, you'll need a [Flutter](https://flutter.dev/) development environment to build **Mindmeld**. 
In addition to this, you'll want to have any platform specific development tools such as XCode or
Android Studio - `flutter doctor` should run 'clean' for whatever platform you're targeting
with the build.

Besides Flutter, [CMake](https://cmake.org/) will need to be installed as well as a C/C++ compiler in
order to compile [llama.cpp](https://github.com/ggerganov/llama.cpp) and 
[woolycore](https://github.com/tbogdala/woolycore).


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
