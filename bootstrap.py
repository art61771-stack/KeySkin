from pathlib import Path
import plistlib
p=Path(__file__).parent
files={
'Makefile':'''ARCHS = arm64e
TARGET = iphone:clang:latest:16.0
THEOS_PACKAGE_SCHEME = roothide
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = KeySkin
KeySkin_FILES = Tweak.xm
KeySkin_CFLAGS = -fobjc-arc
KeySkin_CCFLAGS = -std=c++17
KeySkin_FRAMEWORKS = UIKit Foundation CoreFoundation
include $(THEOS_MAKE_PATH)/tweak.mk
''',
'control':'''Package: com.zuotian.keyskin
Name: KeySkin
Version: 0.1.0
Architecture: iphoneos-arm64e
Description: Opt-in keyboard metadata probe; background rendering disabled.
Maintainer: zuotian
Author: zuotian
Section: Tweaks
Depends: firmware (>= 16.0), mobilesubstrate
''',
'.gitignore':'''build/
.theos/
packages/
evidence/
__pycache__/
''',
}
for n,s in files.items(): (p/n).write_text(s)
(p/'KeySkin.plist').write_bytes(plistlib.dumps({'Filter':{'Bundles':['com.apple.UIKit']}}))
(p/'config.example.plist').write_bytes(plistlib.dumps({'Enabled':False,'ProbeEnabled':False,'BackgroundReplacementEnabled':False}))
