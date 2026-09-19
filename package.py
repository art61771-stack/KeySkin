from pathlib import Path
import shutil,subprocess
assert 'Version: 0.1.5\n' in Path('control').read_text()
root=Path('build/package')
if root.exists(): shutil.rmtree(root)
dest=root/'Library/MobileSubstrate/DynamicLibraries'
dest.mkdir(parents=True)
for name in ['KeySkin.dylib','KeySkin.plist']:
 shutil.copyfile('build/'+name if name.endswith('dylib') else name,dest/name)
(dest/'KeySkin.dylib').chmod(0o755)
bundle=root/'Library/PreferenceBundles/KeySkinPrefs.bundle'
bundle.mkdir(parents=True)
shutil.copyfile('build/KeySkinPrefs',bundle/'KeySkinPrefs')
(bundle/'KeySkinPrefs').chmod(0o755)
shutil.copyfile('Root.plist',bundle/'Root.plist')
shutil.copyfile('prefs/Resources/Info.plist',bundle/'Info.plist')
shutil.copytree('layout',root,dirs_exist_ok=True)
(root/'DEBIAN').mkdir()
shutil.copyfile('control',root/'DEBIAN/control')
subprocess.run(['dpkg-deb','--root-owner-group','-Zxz','-b',str(root),'build/KeySkin-0.1.5-roothide.deb'],check=True)
