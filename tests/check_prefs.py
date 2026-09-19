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
assert info['CFBundleVersion'] == info['CFBundleShortVersionString'] == '0.1.5'
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
assert ': UITableViewController' in source
for forbidden in ['PSListController', 'PSSpecifier', 'ksSpecifiers',
                  'loadSpecifiers', 'setSpecifiers', 'reloadSpecifiers',
                  'readPreferenceValue:', 'setPreferenceValue:', 'pathForResource:']:
    assert forbidden not in source, forbidden
for initializer in ['init', 'initWithStyle:', 'initWithNibName:']:
    assert '- (instancetype)' + initializer in source
# Verify exact production enum order, cell labels, and didSelect routing.
rows = ['Enabled', 'Install', 'Preview', 'Export', 'Clear']
enum = re.search(r'typedef NS_ENUM\(NSInteger, KSSettingsRow\) \{(.*?)\};', source, re.S).group(1)
assert re.findall(r'KSSettingsRow(\w+)', enum) == rows + ['Count']
assert 'KSSettingsRowEnabled = 0' in enum
assert 'return section == 0 ? KSSettingsRowCount : 0;' in source
assert re.search(r'numberOfSectionsInTableView:.*?return 1;', source, re.S)
cells = source.split('cellForRowAtIndexPath:')[1].split('titleForFooterInSection:')[0]
selection = source.split('didSelectRowAtIndexPath:')[1].split('- (void)showMessage:')[0]
labels = ['Enabled（实验性图片换肤）', '生成示例', '预览', '导出兼容报告', '清除']
for row, label in zip(rows, labels):
    assert re.search(r'case KSSettingsRow' + row + r':.*?cell.textLabel.text = @"' + re.escape(label) + '";', cells, re.S)
actions = dict(zip(rows[1:], ['installBuiltin', 'previewBuiltin', 'exportCompatibility', 'clearSkin']))
assert re.findall(r'case KSSettingsRow(\w+):', selection) == rows[1:]
for row, action in actions.items():
    assert f'case KSSettingsRow{row}: [self {action}:nil]; break;' in selection
assert 'deselectRowAtIndexPath:indexPath' in selection
assert 'if (indexPath.section != 0) return;' in selection
assert 'toggle.on = [self enabledValue];' in cells
assert '[toggle addTarget:self action:@selector(enabledChanged:) forControlEvents:UIControlEventValueChanged];' in cells
assert 'cell.accessoryView = nil;' in cells  # reused buttons cannot retain a switch
assert 'CFPreferencesSetAppValue' in source and 'CFPreferencesCopyAppValue' in source
assert 'CFBooleanGetTypeID() ? [value boolValue] : NO' in source
toggle = source.split('- (void)enabledChanged:')[1].split('- (void)installBuiltin:')[0]
for statement in ['isKindOfClass:UISwitch.class', 'KSWrite(@"Enabled", @(requested));',
                  'CFPreferencesAppSynchronize(KSDomain)', '[self enabledValue] == requested',
                  '[self.tableView reloadData];', 'if (!saved)']:
    assert statement in toggle
assert re.findall(r'KSWrite\(@"([^"]+)"', toggle) == ['Enabled']
initializers = source.split('@implementation KSSettingsTableController')[1].split('- (BOOL)enabledValue')[0]
assert 'KSWrite(' not in initializers  # opening/reopening never resets stored data
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
assert 'Version: 0.1.5\n' in (root / 'control').read_text()
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
assert '[self.tableView reloadData];' in clear
assert "0.1.1" not in (root / "Root.plist").read_text()
print('PASS: fixed UIKit five-row mapping/actions, strict Enabled default/storage, retained 0.1.5 resources and hook guards (static only; not device validation)')

# Real entry uses the PSViewController contract, not a UITableViewController entry.
assert '@interface KSRootListController : PSViewController' in source
assert '@interface KSSettingsTableController : UITableViewController' in source
entry_source = source.split('@implementation KSRootListController')[1].split('@end')[0]
for forbidden in ['initWith', 'specifier', 'tableView', 'forwardInvocation', 'respondsToSelector', 'KSWrite(']:
    assert forbidden not in entry_source, forbidden
for required in ['[super viewDidLoad]', 'addChildViewController:content', 'addSubview:content.view', 'didMoveToParentViewController:self', 'safeAreaLayoutGuide']:
    assert required in entry_source, required
assert entry_source.index('addChildViewController:') < entry_source.index('addSubview:') < entry_source.index('didMoveToParentViewController:')
assert 'PSViewController : UIViewController' in (root/'compat/Preferences/PSViewController.h').read_text()
assert 'PSListController : PSViewController' in (root/'compat/Preferences/PSListController.h').read_text()
assert 'PSViewController' in (root/'compat/Preferences.framework/Preferences.tbd').read_text()
assert not subprocess.check_output(['git','diff','905808b','--','Tweak.xm','KSRuntime.h'])
print('PASS: PS entry inheritance/containment, independent five-row content, no specifier cache, unchanged production runtime (static only)')
