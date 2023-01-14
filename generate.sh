#!/bin/sh

rm -rf .tmp/ || true

TAG_VERSION="v0.0.1"
IOS_URL="https://download.videolan.org/pub/cocoapods/prod/MobileVLCKit-3.5.1-34408b84-e9eceaed.tar.xz"
MACOS_URL="https://download.videolan.org/pub/cocoapods/prod/VLCKit-3.5.1-34408b84-e9eceaed.tar.xz"
TVOS_URL="https://download.videolan.org/cocoapods/prod/TVVLCKit-3.5.1-34408b84-e9eceaed.tar.xz"

function adjustPackageFile() {
    PACKAGE_HASH=$(sha256sum ".tmp/output/$2-binary.xcframework.zip" | awk '{ print $1 }')
    PACKAGE_STRING="Target.binaryTarget(name: \"$2-binary\", url: \"https:\/\/github.com\/tylerjonesio\/vlckit-spm\/releases\/download\/$TAG_VERSION\/$2.xcframework.zip\", checksum: \"$PACKAGE_HASH\")"
    echo "Changing package definition for $1,$2 with hash $PACKAGE_HASH"
    sed -i '' -e "s/let $1.*/let $1 = $PACKAGE_STRING/" Package.swift
}

mkdir .tmp/
mkdir .tmp/output/

#Download and generate MobileVLCKit
wget -O .tmp/MobileVLCKit.tar.xz $IOS_URL
tar -xf .tmp/MobileVLCKit.tar.xz -C .tmp/
ditto -c -k --sequesterRsrc --keepParent ".tmp/MobileVLCKit-binary/MobileVLCKit.xcframework" ".tmp/MobileVLCKit-binary.xcframework.zip"
cp .tmp/MobileVLCKit-binary.xcframework.zip .tmp/output/
adjustPackageFile "iOSPackage" "MobileVLCKit"


#Download and generate VLCKit
wget -O .tmp/VLCKit.tar.xz $MACOS_URL
tar -xf .tmp/VLCKit.tar.xz -C .tmp/
#Special case to include missing header file
cp ".tmp/MobileVLCKit-binary/MobileVLCKit.xcframework/ios-arm64_i386_x86_64-simulator/MobileVLCKit.framework/Headers/VLCDialogProvider.h" ".tmp/VLCKit - binary package/VLCKit.xcframework/macos-arm64_x86_64/VLCKit.framework/Headers/VLCDialogProvider.h"
ditto -c -k --sequesterRsrc --keepParent ".tmp/VLCKit - binary package/VLCKit.xcframework" ".tmp/VLCKit-binary.xcframework.zip"
cp .tmp/VLCKit-binary.xcframework.zip .tmp/output/
adjustPackageFile "macPackage" "VLCKit"

#Download and generate TVVLCKit
wget -O .tmp/TVVLCKit.tar.xz $TVOS_URL
tar -xf .tmp/TVVLCKit.tar.xz -C .tmp/
ditto -c -k --sequesterRsrc --keepParent ".tmp/TVVLCKit-binary/TVVLCKit.xcframework" ".tmp/TVVLCKit-binary.xcframework.zip"
cp .tmp/TVVLCKit-binary.xcframework.zip .tmp/output/
adjustPackageFile "tvPackage" "TVVLCKit"

cp -f .tmp/MobileVLCKit-binary/COPYING.txt ./LICENSE
