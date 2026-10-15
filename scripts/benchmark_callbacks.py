"""Compare identical mock callback bursts against an unmodified baseline checkout."""
from pathlib import Path
import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--baseline',required=True,type=Path,help='Checkout containing the pre-audit Scoped.lua and skins')
args=parser.parse_args()
runtime=['EUIAddonSkins/Scoped.lua']+[f'EUIAddonSkins/Skins/{name}.lua' for name in ['DBM','Details','Gargul','ThreatClassic2']]
assert all((args.baseline/p).is_file() for p in runtime)
def run(folder,baseline=False):
    env=dict(os.environ);env.pop('EUI_AUDIT_BASELINE',None)
    if baseline:env['EUI_AUDIT_BASELINE']='1'
    process=subprocess.run([sys.executable,'tests/run_lua.py'],cwd=folder,env=env,text=True,capture_output=True)
    if process.returncode:raise RuntimeError(process.stdout+'\n'+process.stderr)
    result={}
    for line in process.stdout.splitlines():
        if line.startswith('BENCH '):
            _,name,*fields=line.split()
            result[name]={key:int(value) for key,value in (field.split('=') for field in fields)}
    assert len(result)==5
    return result
with tempfile.TemporaryDirectory(prefix='callback-baseline-',dir=root.parent) as temporary:
    folder=Path(temporary)
    for name in ['EUIAddonSkins','tests']:
        shutil.copytree(root/name,folder/name)
    for rel in runtime:shutil.copyfile(args.baseline/rel,folder/rel)
    results={'environment':'Mock WoW frames; H.Scan invocations by root, not FPS/CPU or recursive frame counts.',
             'before':run(folder,True),'after':run(root)}
(root/'docs/acegui-callback-results.json').write_text(json.dumps(results,indent=2)+'\n')
print(json.dumps(results,indent=2))
