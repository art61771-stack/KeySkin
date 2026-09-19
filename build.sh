#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build
clang++ -std=c++17 -Wall -Wextra -Werror tests/geometry.cpp -o build/geometry
build/geometry build/offscreen.ppm
python3 tests/check_prefs.py
xcrun clang++ -std=c++17 -Wall -Wextra -Werror tests/coregraphics.cpp -framework CoreGraphics -framework CoreFoundation -o build/coregraphics
build/coregraphics
xcrun clang++ -std=c++17 -Wall -Wextra -Werror -fobjc-arc tests/runtime.mm -framework Foundation -o build/runtime
build/runtime
SDK=$(xcrun --sdk iphoneos --show-sdk-path)
xcrun --sdk iphoneos clang++ -x objective-c++ -std=c++17 -arch arm64e -isysroot "$SDK" -miphoneos-version-min=16.0 -fobjc-arc -fblocks -Wall -Wextra -Werror -include KSKeyImage.h -dynamiclib Tweak.xm -o build/KeySkin.dylib -Wl,-install_name,@loader_path/.jbroot/Library/MobileSubstrate/DynamicLibraries/KeySkin.dylib -framework UIKit -framework Foundation -framework CoreFoundation -framework CoreGraphics -framework ImageIO -framework QuartzCore
codesign --force --sign - build/KeySkin.dylib
codesign --verify --strict --verbose=4 build/KeySkin.dylib
xcrun lipo -info build/KeySkin.dylib
xcrun otool -hvL build/KeySkin.dylib
xcrun --sdk iphoneos clang++ -x objective-c++ -std=c++17 -arch arm64e -isysroot "$SDK" -miphoneos-version-min=16.0 -fobjc-arc -fblocks -Wall -Wextra -Werror -Icompat -Fcompat -bundle PrefsController.m -o build/KeySkinPrefs -framework Preferences -framework UIKit -framework Foundation -framework CoreFoundation -framework ImageIO -framework CoreGraphics
codesign --force --sign - build/KeySkinPrefs
codesign --verify --strict --verbose=4 build/KeySkinPrefs
xcrun lipo -info build/KeySkinPrefs
xcrun otool -hvL build/KeySkinPrefs
python3 package.py
python3 verify.py build/KeySkin-0.1.3-roothide.deb
shasum -a 256 build/*.deb > build/SHA256SUMS
