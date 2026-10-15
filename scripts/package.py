"""Build the experimental core + load-on-demand skin bundle."""
from pathlib import Path
import json
import re
import shutil
import subprocess
import sys
from zipfile import ZipFile, ZIP_DEFLATED
root = Path(__file__).resolve().parents[1]
addon = root/'EUIAddonSkins'
catalog = json.loads((root/'scripts/skin_catalog.json').read_text())
version = re.search(r'^## Version: (\S+)$', (addon/'EUIAddonSkins.toc').read_text(), re.M).group(1)
assert f'ns.VERSION = "{version}"' in (addon/'Core.lua').read_text()
folders = [addon] + [root/f'EUIAddonSkins_{skin}' for skin, _, _ in catalog]
assert set(root.glob('EUIAddonSkins_*')) == set(folders[1:]), 'Unexpected/missing module directories'
files = []
for folder in folders:
    toc = folder/f'{folder.name}.toc'
    text = toc.read_text()
    assert f'## Version: {version}\n' in text
    if folder != addon:
        assert '## LoadOnDemand: 1\n' in text and '## Dependencies: EUIAddonSkins\n' in text
    runtime = [line.strip().replace('\\', '/') for line in text.splitlines() if line.strip() and not line.startswith('#')]
    assert all((folder/p).is_file() for p in runtime), f'Missing runtime file: {folder}'
    assert {p.name for p in folder.glob('*.lua')} == set(runtime), f'Unloaded Lua: {folder}'
    files.extend([toc] + [folder/p for p in runtime])
    if folder == addon:
        for flavor in ['Camelot', 'Mainline']:
            alias = folder/f'EUIAddonSkins_{flavor}.toc'
            assert alias.read_bytes() == toc.read_bytes(), f'Stale client manifest: {alias}'
            files.append(alias)
    if folder == addon:
        files += [addon/'LICENSE', addon/'Media/Icon.tga']
subprocess.run([sys.executable, 'tests/run_lua.py'], cwd=root, check=True)
archive = root/f'EUIAddonSkins-{version}.zip'
with ZipFile(archive, 'w', ZIP_DEFLATED) as z:
    for path in sorted(files): z.write(path, path.relative_to(root).as_posix())
with ZipFile(archive) as z:
    assert z.testzip() is None
    assert z.read('EUIAddonSkins/LICENSE') == (root/'LICENSE').read_bytes()
    assert len(z.namelist()) == len(files)
    assert {p.split('/')[0] for p in z.namelist()} == {p.name for p in folders}
    for path in files: assert z.read(path.relative_to(root).as_posix()) == path.read_bytes()
shutil.copyfile(archive, root/'EUIAddonSkins.zip')
print(f'Verified {archive.name}: {len(files)} files, one core + {len(catalog)} load-on-demand skins')
