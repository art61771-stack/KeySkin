"""Strict runtime selector; never substitute another iOS major version."""
import json, sys
from pathlib import Path
source, output = map(Path, sys.argv[1:])
data = json.loads(source.read_text())
choices = []
for runtime in data['runtimes']:
    if not runtime.get('isAvailable') or '.iOS-' not in runtime['identifier']:
        continue
    if runtime['version'].split('.')[0] != '16':
        continue
    supported = {d['identifier'] for d in runtime.get('supportedDeviceTypes', [])}
    existing = {d.get('deviceTypeIdentifier') for d in data['devices'].get(runtime['identifier'], [])}
    types = [d for d in data['devicetypes'] if d.get('productFamily') == 'iPhone' and d['identifier'] in (supported | existing)]
    if types:
        choices.append((runtime, types[0]))
if not choices:
    output.write_text('NOT RUN: iOS16 runtime unavailable\n')
    print('NOT RUN: iOS16 runtime unavailable')
    sys.exit(0)
runtime, device = sorted(choices, key=lambda x: tuple(map(int, x[0]['version'].split('.'))))[-1]
output.write_text(runtime['identifier'] + '\n' + device['identifier'] + '\n' + runtime['name'] + '\n' + runtime['version'] + '\n')
print('Selected iOS16 runtime:', runtime['name'], runtime['version'], runtime['identifier'])
