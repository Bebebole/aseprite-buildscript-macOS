#This script requires wget, cmake, ninja, git and xcode installed
#(i really recommend you the "homebrew" package manager for this)

SCRIPT_PATH="${BASH_SOURCE[0]%/*}"
ARCH="$(uname -m)"

if [ $ARCH = "x86_64" ]; then
	SKIA_ARCH="x64"
	OSX_DEPLOYMENT_TARGET=10.9
elif [ $ARCH = "arm64" ]; then
	SKIA_ARCH="arm64"
	OSX_DEPLOYMENT_TARGET=11.0
fi

#Download Skia
cd $SCRIPT_PATH
wget https://github.com/aseprite/skia/releases/latest/download/Skia-macOS-Release-$SKIA_ARCH.zip
unzip Skia-macOS-Release-$SKIA_ARCH.zip -d skia
rm Skia-macOS-Release-$SKIA_ARCH.zip

#Download aseprite source
git clone https://github.com/aseprite/aseprite
cd aseprite
git submodule update --init --recursive

#Compile aseprite
mkdir build
cd build
cmake \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_OSX_ARCHITECTURES=$ARCH \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=$OSX_DEPLOYMENT_TARGET \
  -DCMAKE_OSX_SYSROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
  -DLAF_BACKEND=skia \
  -DSKIA_DIR=$SCRIPT_PATH/skia \
  -DSKIA_LIBRARY_DIR=$SCRIPT_PATH/skia/out/Release-$SKIA_ARCH \
  -DSKIA_LIBRARY=$SCRIPT_PATH/skia/out/Release-$SKIA_ARCH/libskia.a \
  -G Ninja \
  ..
ninja aseprite

#Create aseprite.app package
cd $SCRIPT_PATH
mkdir -p aseprite.app/Contents/Resources
cp -R aseprite/build/bin aseprite.app/Contents/MacOS

INFO_PLIST_FILE='<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
	<string>aseprite</string>
	<key>CFBundleIdentifier</key>
	<string>com.aseprite</string>
	<key>CFBundleName</key>
	<string>aseprite</string>
    <key>CFBundleIconFile</key>
    <string>aseprite_icon</string>
	<key>CFBundlePackageType</key>
	<string>BNDL</string>
</dict>
</plist>'

echo $INFO_PLIST_FILE > aseprite.app/Contents/Info.plist
cp aseprite_icon.icns aseprite.app/Contents/Resources/

#Remove deps and source
rm -rf aseprite/
rm -rf skia/