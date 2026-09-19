import sys,subprocess,tarfile,io,struct,plistlib
p=sys.argv[1]
def archive(flag):
 return tarfile.open(fileobj=io.BytesIO(subprocess.check_output(['dpkg-deb',flag,p])),mode='r:')
c=archive('--ctrl-tarfile'); names=[m.name.removeprefix('./') for m in c if m.isfile()]
assert names==['control'],names
control=c.extractfile(next(m for m in c if m.isfile())).read().decode()
for text in ['Package: com.zuotian.keyskin','Version: 0.1.1','Architecture: iphoneos-arm64e']: assert text in control
print(control)
d=archive('--fsys-tarfile'); files={m.name.removeprefix('./'):m for m in d if m.isfile()}
bundle='Library/PreferenceBundles/KeySkinPrefs.bundle/'
entry='Library/PreferenceLoader/Preferences/KeySkin.plist'
assert set(files)=={'Library/MobileSubstrate/DynamicLibraries/KeySkin.dylib','Library/MobileSubstrate/DynamicLibraries/KeySkin.plist',bundle+'KeySkinPrefs',bundle+'Info.plist',bundle+'Root.plist',entry},files
info=plistlib.loads(d.extractfile(files[bundle+'Info.plist']).read())
assert info['CFBundleExecutable']=='KeySkinPrefs' and info['NSPrincipalClass']=='KSRootListController'
assert info['CFBundleVersion']=='0.1.1'
assert plistlib.loads(d.extractfile(files[entry]).read())['entry']['detail']==info['NSPrincipalClass']
items=plistlib.loads(d.extractfile(files[bundle+'Root.plist']).read())['items']
assert len([x for x in items if x['cell']=='PSButtonCell'])==4
prefs=d.extractfile(files[bundle+'KeySkinPrefs']).read()
magic,cpu,subtype,kind=struct.unpack_from('<IIII',prefs)
assert magic==0xfeedfacf and cpu==0x100000c and subtype&0xffffff==2 and kind==8
assert b'KSRootListController' in prefs and b'exportCompatibility:' in prefs
print('PASS: PreferenceLoader entry, Root/Info/controller, arm64e MH_BUNDLE:',len(prefs))
raw=d.extractfile(files['Library/MobileSubstrate/DynamicLibraries/KeySkin.dylib']).read()
magic,cpu,subtype,filetype=struct.unpack_from('<IIII',raw)
assert magic==0xfeedfacf and cpu==0x100000c and subtype&0xffffff==2 and filetype==6
assert len(raw)>4096
print('PASS: control only; no scripts; thin Mach-O MH_DYLIB ARM64E; bytes=',len(raw))
print('CPU subtype=',hex(subtype))
print('Filter:',plistlib.loads(d.extractfile(files['Library/MobileSubstrate/DynamicLibraries/KeySkin.plist']).read()))
