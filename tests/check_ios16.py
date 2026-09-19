"""Synthetic selector tests only; never boot a simulator."""
import json, subprocess, tempfile
from pathlib import Path
script = Path(__file__).with_name('select_ios16.py')
with tempfile.TemporaryDirectory() as tmp:
    inp, out = Path(tmp)/'list.json', Path(tmp)/'selection.txt'
    def run(runtimes):
        inp.write_text(json.dumps({'runtimes': runtimes, 'devices': {}, 'devicetypes': [{'identifier':'iphone', 'productFamily':'iPhone'}]}))
        subprocess.run(['python3', str(script), str(inp), str(out)], check=True)
        return out.read_text()
    def runtime(version, available=True):
        return {'identifier':'com.apple.CoreSimulator.SimRuntime.iOS-'+version.replace('.','-'), 'name':'iOS '+version, 'version':version, 'isAvailable':available, 'supportedDeviceTypes':[{'identifier':'iphone'}]}
    assert run([runtime('18.2')]) == 'NOT RUN: iOS16 runtime unavailable\n'
    assert run([runtime('16.4', False), runtime('18.2')]).startswith('NOT RUN:')
    chosen = run([runtime('18.2'), runtime('16.4'), runtime('17.0')])
    assert chosen.splitlines()[-1] == '16.4'
print('PASS: synthetic strict-iOS16 selector regression (not simulator execution)')
