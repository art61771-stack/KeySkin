ARCHS = arm64e
TARGET = iphone:clang:latest:16.0
THEOS_PACKAGE_SCHEME = roothide
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = KeySkin
KeySkin_FILES = Tweak.xm
KeySkin_CFLAGS = -fobjc-arc
KeySkin_CCFLAGS = -std=c++17
KeySkin_FRAMEWORKS = UIKit Foundation CoreFoundation
include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = KeySkinPrefs
KeySkinPrefs_FILES = PrefsController.m
KeySkinPrefs_CFLAGS = -fobjc-arc -x objective-c++ -std=c++17 -Icompat
KeySkinPrefs_FRAMEWORKS = UIKit Foundation CoreFoundation ImageIO
KeySkinPrefs_PRIVATE_FRAMEWORKS = Preferences
KeySkinPrefs_INSTALL_PATH = /Library/PreferenceBundles
KeySkinPrefs_RESOURCE_FILES = Root.plist
KeySkinPrefs_RESOURCE_DIRS = prefs/Resources
include $(THEOS_MAKE_PATH)/bundle.mk
