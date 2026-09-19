from pathlib import Path
import shutil,subprocess
root=Path('build/package')
if root.exists(): shutil.rmtree(root)
dest=root/'Library/MobileSubstrate/DynamicLibraries'
dest.mkdir(parents=True)
for name in ['KeySkin.dylib','KeySkin.plist']:
 shutil.copyfile('build/'+name if name.endswith('dylib') else name,dest/name)
(dest/'KeySkin.dylib').chmod(0o755)
(root/'DEBIAN').mkdir()
shutil.copyfile('control',root/'DEBIAN/control')
subprocess.run(['dpkg-deb','--root-owner-group','-Zxz','-b',str(root),'build/KeySkin-0.1.0-roothide.deb'],check=True)
