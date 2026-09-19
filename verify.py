import sys,subprocess,tarfile,io,struct,plistlib
p=sys.argv[1]
def archive(flag):
 return tarfile.open(fileobj=io.BytesIO(subprocess.check_output(['dpkg-deb',flag,p])),mode='r:')
c=archive('--ctrl-tarfile'); names=[m.name.removeprefix('./') for m in c if m.isfile()]
assert names==['control'],names
control=c.extractfile(next(m for m in c if m.isfile())).read().decode()
for text in ['Package: com.zuotian.keyskin','Version: 0.1.0','Architecture: iphoneos-arm64e']: assert text in control
print(control)
d=archive('--fsys-tarfile'); files={m.name.removeprefix('./'):m for m in d if m.isfile()}
assert set(files)=={'Library/MobileSubstrate/DynamicLibraries/KeySkin.dylib','Library/MobileSubstrate/DynamicLibraries/KeySkin.plist'},files
raw=d.extractfile(files['Library/MobileSubstrate/DynamicLibraries/KeySkin.dylib']).read()
magic,cpu,subtype,filetype=struct.unpack_from('<IIII',raw)
assert magic==0xfeedfacf and cpu==0x100000c and subtype&0xffffff==2 and filetype==6
assert len(raw)>4096
print('PASS: control only; no scripts; thin Mach-O MH_DYLIB ARM64E; bytes=',len(raw))
print('CPU subtype=',hex(subtype))
print('Filter:',plistlib.loads(d.extractfile(files['Library/MobileSubstrate/DynamicLibraries/KeySkin.plist']).read()))
