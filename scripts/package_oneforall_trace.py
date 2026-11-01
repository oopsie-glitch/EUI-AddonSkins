"""Build an explicitly marked, untagged OneForAll diagnostic ZIP.

The ordinary package/TOCs contain no trace code or commands. Run package.py
first; this derives and verifies the diagnostic variant without editing them.
"""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import argparse
import hashlib
import subprocess

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
revision = subprocess.check_output(['git', 'rev-parse', '--short=12', 'HEAD'], cwd=root, text=True).strip()
if subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no'], cwd=root, text=True).strip():
    revision += '-worktree'
source = root / 'EUIAddonSkins.zip'
trace = (root / 'diagnostics/OneForAllTrace.lua').read_bytes().replace(b'@TRACE_BUILD@', revision.encode())
with ZipFile(source) as normal:
    entries = {n: normal.read(n) for n in normal.namelist()}
assert 'EUIAddonSkins/OneForAllTrace.lua' not in entries
for name in list(entries):
    if name.endswith('.toc'):
        data = entries[name]
        assert data.count(b'Core.lua\n') == 1
        entries[name] = data.replace(b'Core.lua\n', b'Core.lua\nOneForAllTrace.lua\n').replace(
            b'## Notes: ', b'## X-EUI-Development: OneForAll trace ' + revision.encode() + b'\n## Notes: ', 1)
entries['EUIAddonSkins/OneForAllTrace.lua'] = trace
args.output.parent.mkdir(parents=True, exist_ok=True)
with ZipFile(args.output, 'w', ZIP_DEFLATED) as out:
    for name, data in sorted(entries.items()):
        out.writestr(name, data)
with ZipFile(args.output) as out:
    assert out.testzip() is None
    assert len(out.namelist()) == len(entries)
    assert {n.split('/')[0] for n in out.namelist()} == {'EUIAddonSkins'}
    for name, data in entries.items():
        assert out.read(name) == data
    for name, data in entries.items():
        if name.endswith('.toc'):
            for line in data.decode().splitlines():
                if line and not line.startswith('#'):
                    assert 'EUIAddonSkins/' + line.replace('\\', '/') in entries
print(f'{args.output}: {len(entries)} files, diagnostic build {revision}, SHA256 {hashlib.sha256(args.output.read_bytes()).hexdigest()}')
