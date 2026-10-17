"""Build and verify the one-folder, target-aware skin collection."""
from pathlib import Path
import json
import re
import shutil
import subprocess
import sys
from zipfile import ZipFile, ZIP_DEFLATED
root=Path(__file__).resolve().parents[1]
addon=root/'EUIAddonSkins'
catalog=json.loads((root/'scripts/skin_catalog.json').read_text())
toc=addon/'EUIAddonSkins.toc';text=toc.read_text()
version=re.search(r'^## Version: (\S+)$',text,re.M).group(1)
assert f'ns.VERSION = "{version}"' in (addon/'Core.lua').read_text()
assert not list(root.glob('EUIAddonSkins_*')), 'Obsolete sibling modules remain'
runtime=[line.strip().replace('\\','/') for line in text.splitlines() if line.strip() and not line.startswith('#')]
assert all((addon/p).is_file() for p in runtime)
assert {p.relative_to(addon).as_posix() for p in addon.rglob('*.lua')}==set(runtime), 'Unloaded runtime files'
assert set(p for p in runtime if p.startswith('Skins/'))=={f'Skins/{skin}.lua' for skin,_,_ in catalog}
assert runtime.index('Loader.lua') < min(runtime.index(f'Skins/{skin}.lua') for skin,_,_ in catalog)
# Runtime icon atlas is original RGBA art, not a development fixture.
glyph_header=(addon/'Media/DBMMechanics.tga').read_bytes()[:18]
assert glyph_header[2]==2 and int.from_bytes(glyph_header[12:14],'little')==256
assert int.from_bytes(glyph_header[14:16],'little')==32 and glyph_header[16]==32
files=[toc]+[addon/p for p in runtime]+[addon/'LICENSE',addon/'Media/Icon.tga',addon/'Media/DBMMechanics.tga']
for flavor in ['Camelot','Mainline']:
    alias=addon/f'EUIAddonSkins_{flavor}.toc'
    assert alias.read_bytes()==toc.read_bytes(),f'Stale client manifest: {alias}'
    files.append(alias)
subprocess.run([sys.executable,'tests/run_lua.py'],cwd=root,check=True)
archive=root/f'EUIAddonSkins-{version}.zip'
with ZipFile(archive,'w',ZIP_DEFLATED) as z:
    for p in sorted(files):z.write(p,p.relative_to(root).as_posix())
with ZipFile(archive) as z:
    assert z.testzip() is None and len(z.namelist())==len(files)
    assert {p.split('/')[0] for p in z.namelist()}=={'EUIAddonSkins'}
    assert z.read('EUIAddonSkins/LICENSE')==(root/'LICENSE').read_bytes()
    for p in files:assert z.read(p.relative_to(root).as_posix())==p.read_bytes()
shutil.copyfile(archive,root/'EUIAddonSkins.zip')
print(f'Verified {archive.name}: {len(files)} files, one addon folder, {len(catalog)} deferred skin factories')
