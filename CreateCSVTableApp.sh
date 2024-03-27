#!/bin/sh
# 
# Deda, August 2023
# Mostly for myself, but read on if you want to understand
# Should build the CSVTable.app, signed/notarized for gatekeepr for macOS 13+
#

DIR_NAME=`dirName $0`
cd ${DIR_NAME}

XCODE="/Applications/Xcode.app"
WORKSPACE="$DIR_NAME/IDDList.xcworkspace"
BUILD_FOLDER=$HOME/Developer/build
APP_NAME="CSVTable"

# bah, avoid being pestered by this ask
# https://forums.swift.org/t/ignore-macro-validation-using-xcodebuild-command/68125
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
# defaults delete com.apple.dt.Xcode IDESkipMacroFingerprintValidation

mkdir -p $BUILD_FOLDER

log() {
    COMMAND="$@"
    echo "*** running:"
    echo "$COMMAND"
    echo "------------------------------------"
    echo
}

# build the release version
# for some reason i had to tell it to ONLY_ACTIVE_ARCH=NO
# weird
echo "build the release version"
log $XCODE/Contents/Developer/usr/bin/xcodebuild -workspace $WORKSPACE -scheme $APP_NAME -configuration Release ONLY_ACTIVE_ARCH=NO DSTROOT=$BUILD_FOLDER DWARF_DSYM_FOLDER_PATH=$BUILD_FOLDER/$APP_NAME INSTALL_PATH=Release clean install
$XCODE/Contents/Developer/usr/bin/xcodebuild -workspace $WORKSPACE -scheme $APP_NAME -configuration Release ONLY_ACTIVE_ARCH=NO DSTROOT=$BUILD_FOLDER DWARF_DSYM_FOLDER_PATH=$BUILD_FOLDER/$APP_NAME INSTALL_PATH=Release clean install


# Manually check the fat binaries
echo "Manually check the fat binaries"
log lipo -info $BUILD_FOLDER/Release/$APP_NAME.app/Contents/MacOS/$APP_NAME
lipo -info $BUILD_FOLDER/Release/$APP_NAME.app/Contents/MacOS/$APP_NAME


# Manually sign it (remove xattributes as this breaks sign)
echo "Manually sign it (remove xattributes as this breaks sign)"
log /usr/bin/codesign --verbose --force --timestamp --deep --options=runtime --strict --sign "Developer ID Application: ID-DESIGN INC. (ME637H7ZM9)" $BUILD_FOLDER/Release/$APP_NAME.app
/usr/bin/codesign --verbose --force --timestamp --deep --options=runtime --strict --sign "Developer ID Application: ID-DESIGN INC. (ME637H7ZM9)" $BUILD_FOLDER/Release/$APP_NAME.app


# Manually test it
echo "Manually test it"
log spctl -vvv -a $BUILD_FOLDER/Release/$APP_NAME.app
spctl -vvv -a $BUILD_FOLDER/Release/$APP_NAME.app


# Zip it
echo "Zip it"
log /usr/bin/ditto -c -k --sequesterRsrc --keepParent $BUILD_FOLDER/Release/$APP_NAME.app $BUILD_FOLDER/Release/$APP_NAME.zip
/usr/bin/ditto -c -k --sequesterRsrc --keepParent $BUILD_FOLDER/Release/$APP_NAME.app $BUILD_FOLDER/Release/$APP_NAME.zip


# Notarize the zip
# make sure you do the dance
# https://scriptingosx.com/2021/07/notarize-a-command-line-tool-with-notarytool/
echo "Notarize the zip"
log $XCODE/Contents/Developer/usr/bin/notarytool submit $BUILD_FOLDER/Release/$APP_NAME.zip --keychain-profile WhatSizeAppPassword --wait
$XCODE/Contents/Developer/usr/bin/notarytool submit $BUILD_FOLDER/Release/$APP_NAME.zip --keychain-profile WhatSizeAppPassword --wait


# Staple the app (we are using the results of the above)
echo "Staple the app (we are using the results of the above)"
log /usr/bin/xcrun stapler staple -v $BUILD_FOLDER/Release/$APP_NAME.app
/usr/bin/xcrun stapler staple -v $BUILD_FOLDER/Release/$APP_NAME.app


# Zip it again, now a properly signed, notarized, stapled app is inside the zip
echo "Zip it again, now a properly signed, notarized, stapled app is inside the zip"
log /usr/bin/ditto -c -k --sequesterRsrc --keepParent $BUILD_FOLDER/Release/$APP_NAME.app $BUILD_FOLDER/Release/$APP_NAME.zip
/usr/bin/ditto -c -k --sequesterRsrc --keepParent $BUILD_FOLDER/Release/$APP_NAME.app $BUILD_FOLDER/Release/$APP_NAME.zip
