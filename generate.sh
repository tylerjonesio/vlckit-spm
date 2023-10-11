#!/bin/sh
#
rm -rf .tmp/ || true

TAG_VERSION="v3.6.0.b10"
IOS_URL="https://download.videolan.org/pub/cocoapods/unstable/MobileVLCKit-3.6.0b10-615f96dc-4733d1cc.tar.xz"
MACOS_URL="https://download.videolan.org/pub/cocoapods/unstable/VLCKit-3.6.0b10-615f96dc-4733d1cc.tar.xz"
TVOS_URL="https://download.videolan.org/cocoapods/unstable/TVVLCKit-3.6.0b10-615f96dc-4733d1cc.tar.xz"

mkdir .tmp/

#Download and generate MobileVLCKit
wget -O .tmp/MobileVLCKit.tar.xz $IOS_URL
tar -xf .tmp/MobileVLCKit.tar.xz -C .tmp/

#Download and generate VLCKit
wget -O .tmp/VLCKit.tar.xz $MACOS_URL
tar -xf .tmp/VLCKit.tar.xz -C .tmp/

#Download and generate TVVLCKit
wget -O .tmp/TVVLCKit.tar.xz $TVOS_URL
tar -xf .tmp/TVVLCKit.tar.xz -C .tmp/

IOS_LOCATION=".tmp/MobileVLCKit-binary/MobileVLCKit.xcframework"
TVOS_LOCATION=".tmp/TVVLCKit-binary/TVVLCKit.xcframework"
MACOS_LOCATION=".tmp/VLCKit - binary package/VLCKit.xcframework"

#Merge into one xcframework
xcodebuild -create-xcframework \
    -framework "$MACOS_LOCATION/macos-arm64_x86_64/VLCKit.framework" \
    -debug-symbols "${PWD}/$MACOS_LOCATION/macos-arm64_x86_64/dSYMs/VLCKit.framework.dSYM" \
    -framework "$TVOS_LOCATION/tvos-arm64_x86_64-simulator/TVVLCKit.framework" \
    -debug-symbols "${PWD}/$TVOS_LOCATION/tvos-arm64_x86_64-simulator/dSYMs/TVVLCKit.framework.dSYM" \
    -framework "$TVOS_LOCATION/tvos-arm64/TVVLCKit.framework"  \
    -debug-symbols "${PWD}/$TVOS_LOCATION/tvos-arm64/dSYMs/TVVLCKit.framework.dSYM" \
    -framework "$IOS_LOCATION/ios-arm64_i386_x86_64-simulator/MobileVLCKit.framework" \
    -debug-symbols "${PWD}/$IOS_LOCATION/ios-arm64_i386_x86_64-simulator/dSYMs/MobileVLCKit.framework.dSYM" \
    -framework "$IOS_LOCATION/ios-arm64_armv7_armv7s/MobileVLCKit.framework" \
    -debug-symbols "${PWD}/$IOS_LOCATION/ios-arm64_armv7_armv7s/dSYMs/MobileVLCKit.framework.dSYM" \
    -output .tmp/VLCKit-all.xcframework
    
ditto -c -k --sequesterRsrc --keepParent ".tmp/VLCKit-all.xcframework" ".tmp/VLCKit-all.xcframework.zip"

#Update package file
PACKAGE_HASH=$(sha256sum ".tmp/VLCKit-all.xcframework.zip" | awk '{ print $1 }')
PACKAGE_STRING="Target.binaryTarget(name: \"VLCKit-all\", url: \"https:\/\/github.com\/tylerjonesio\/vlckit-spm\/releases\/download\/$TAG_VERSION\/VLCKit-all.xcframework.zip\", checksum: \"$PACKAGE_HASH\")"
echo "Changing package definition for xcframework with hash $PACKAGE_HASH"
sed -i '' -e "s/let vlcBinary.*/let vlcBinary = $PACKAGE_STRING/" Package.swift

cp -f .tmp/MobileVLCKit-binary/COPYING.txt ./LICENSE
