#!/bin/sh

APP_NAME="mindmeld"
APPDIR="build/mindmeld.AppDir"

# CUDA libraries are pulled from here on my debian system
CUDA_DIR="/usr/lib/x86_64-linux-gnu"

# needs the appimagetool from https://github.com/AppImage/AppImageKit
APPIMAGETOOL="/home/timothy/Applications/appimagetool-x86_64.AppImage"

# ensure everything is current - ccache makes the dep rebuild mostly pain-free
#
# Note: for Linux, AVX512 is not enabled by default. in fact ...
# GGML_FMA, GGML_AVX, GGML_AVX2 nor GGML_AVX512 appear to be enabled by default.
rm -rf $APPDIR
./make_linux_deps.sh

# build the linux runner in release mode
flutter build linux --release

# make the AppDir for our package
mkdir $APPDIR

# copy our build
cp -r build/linux/x64/release/bundle/* $APPDIR
cp packages/woolydart/src/build-linux/libwoolycore.so $APPDIR

# copy some assets
cp assets/app_icon_512.png $APPDIR

# copy over CUDA
mkdir -p $APPDIR/usr/lib
cp $CUDA_DIR/libcudart* $APPDIR/usr/lib
cp $CUDA_DIR/libcublas* $APPDIR/usr/lib

# Define desktop entry content as a multi-line string
desktop_content="[Desktop Entry]
Name=Mindmeld
Exec=mindmeld
Icon=app_icon_512
Type=Application
Categories=Utility;"
echo "$desktop_content" > $APPDIR/mindmeld.desktop

# Create the AppRun script
apprun_content="#!/bin/sh
exec \"\${0%/*}/mindmeld\" \"\$@\"
"
echo "$apprun_content" > $APPDIR/AppRun
chmod +x $APPDIR/AppRun  # make it executable

# Now do the Appimage build
$APPIMAGETOOL $APPDIR