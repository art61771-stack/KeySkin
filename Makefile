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
