"""Source/resource checks only; does not emulate UIKit/CFPreferences."""
from pathlib import Path
import plistlib, re, subprocess
root = Path(__file__).resolve().parents[1]
def plist(path):
    return plistlib.loads((root / path).read_bytes())
source = (root / 'PrefsController.m').read_text()
info = plist('KeySkinPrefs.plist')
assert info == plist('prefs/Resources/Info.plist')
assert info['CFBundleExecutable'] == 'KeySkinPrefs'
assert info['NSPrincipalClass'] == 'KSRootListController'
assert info['CFBundleVersion'] == info['CFBundleShortVersionString'] == '0.1.3'
entry = plist('layout/Library/PreferenceLoader/Preferences/KeySkin.plist')['entry']
assert entry['bundle'] == info['CFBundleExecutable']
assert entry['detail'] == info['NSPrincipalClass']
assert entry['cell'] == 'PSLinkCell' and entry['isController'] is True
items = plist('Root.plist')['items']
switches = [x for x in items if x['cell'] == 'PSSwitchCell']
assert {x['key'] for x in switches} == {'Enabled'}
for item in switches:
    assert item['default'] is False
    assert item['defaults'] == 'com.zuotian.keyskin'
    assert item['get'] == 'readPreferenceValue:'
    assert item['set'] == 'setPreferenceValue:specifier:'
buttons = [x for x in items if x['cell'] == 'PSButtonCell']
assert len(buttons) == 4
assert 'KSCreateKeyImage' in source and 'targetABIProven' in source
assert 'UIActivityViewController' in source
for item in buttons:
    assert re.search(r'- \(void\)' + re.escape(item['action']), source), item
assert ': PSListController' in source
assert 'CFPreferencesSetAppValue' in source and 'CFPreferencesCopyAppValue' in source
assert 'KSBooleanKey(key)' in source and 'CFBooleanGetTypeID' in source
assert '512 * 1024' in source and 'CGImageSourceGetCount(source) == 1' in source
clear = source.split('- (void)clearSkin:')[1]
for key in ['NormalImageData', 'FunctionImageData']:
    assert f'KSWrite(@"{key}", nil)' in clear
for key in ['Enabled', 'ProbeEnabled']:
    assert f'KSWrite(@"{key}", @NO)' in clear
install = source.split('- (void)installBuiltin:')[1].split('- (void)previewBuiltin:')[0]
assert 'KSWrite(@"Enabled"' not in install and 'KSWrite(@"ProbeEnabled"' not in install
for forbidden in ['NSURLSession', 'UIDocumentPicker', 'PHPhotoLibrary', 'standardUserDefaults', 'keyWindow']:
    assert forbidden not in source
make = (root / 'Makefile').read_text()
for line in ['BUNDLE_NAME = KeySkinPrefs', 'KeySkinPrefs_RESOURCE_FILES = Root.plist',
             'KeySkinPrefs_RESOURCE_DIRS = prefs/Resources', 'KeySkinPrefs_PRIVATE_FRAMEWORKS = Preferences']:
    assert line in make
assert 'Version: 0.1.3\n' in (root / 'control').read_text()
assert 'preferenceloader' in (root / 'control').read_text()
config = plist('config.example.plist')
assert config['Enabled'] is config['ProbeEnabled'] is False
# Source checks only: actual runtime guards are exercised by runtime.mm on macOS.
tweak = (root / 'Tweak.xm').read_text()
for guard in ['if (!allowed) return;', 'KSApprovedClass', 'KSValidatedVoidMethod',
              'object_getClass(view) != KSKeyClass', 'KSRemoveBackground(view)',
              'background.userInteractionEnabled = NO', 'background.accessibilityElementsHidden = YES',
              'insertSubview:background atIndex:0', 'CFBooleanGetTypeID', 'MSHookMessageEx']:
    assert guard in tweak, guard
for forbidden in ['keyWindow', 'NSURLSession', 'addTarget:', 'sendActionsForControlEvents:', 'textInput']:
    assert forbidden not in tweak
print('PASS: 0.1.3 bundle/resources/defaults/actions/storage; per-key hook source guards (not device validation)')

assert "0.1.1" not in (root / "Root.plist").read_text()
assert "setButtonAction:NSSelectorFromString(action)" in source
assert "[super setSpecifiers:specifiers]" in source
assert "[super loadSpecifiers" not in source
assert "bundleForClass:KSRootListController.class" in source
