"""Five-trial host Lua timing/allocation/call-count benchmark, not a WoW profile."""
import argparse
import ctypes
import json
import os
from pathlib import Path
import statistics
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--baseline', help='Git ref containing the baseline OneForAll adapter')
parser.add_argument('--source', type=Path, help='External supplied OneForAll directory; enables actual Widgets/MainFrame/Settings/QoL/GearPlanner')
parser.add_argument('--native', action='store_true', help='Same target workload without installing the skin')
parser.add_argument('--index-only', action='store_true', help='Separate actual native data-load/index benchmark; requires --source')
parser.add_argument('--trial', action='store_true', help=argparse.SUPPRESS)
parser.add_argument('--output', type=Path)
args = parser.parse_args()

if args.trial:
    lua = ctypes.CDLL('liblua5.4.so.0')
    lua.luaL_newstate.restype = ctypes.c_void_p
    lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
    lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
    lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
    lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
    lua.lua_tolstring.restype = ctypes.c_char_p
    lua.lua_close.argtypes = [ctypes.c_void_p]
    state = lua.luaL_newstate()
    lua.luaL_openlibs(state)
    try:
        files = ('benchmarks/oneforall_index.lua',) if os.getenv('ONEFORALL_INDEX_ONLY') else ('benchmarks/oneforall.lua', 'tests/oneforall_spec.lua')
        for file in files:
            rc = lua.luaL_loadfilex(state, file.encode(), None) or lua.lua_pcallk(state, 0, 0, 0, 0, None)
            if rc:
                raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
    finally:
        lua.lua_close(state)
else:
    records = {}
    with tempfile.TemporaryDirectory() as scratch:
        env = os.environ.copy()
        if args.index_only:
            assert args.source, '--source is required for --index-only'
            env['ONEFORALL_INDEX_ONLY'] = '1'
            env['ONEFORALL_SOURCE'] = str(args.source.resolve())
            data = args.source.resolve() / 'Data'
            paths = sorted((data / 'Dungeons').glob('*.lua')) + [args.source.resolve() / 'DungeonData.lua']
            paths += [data / name for name in ('Armory.lua', 'ClassQuests.lua', 'QuestRewards.lua')]
            data_list = Path(scratch) / 'source-data-list.txt'
            data_list.write_text('\n'.join(map(str, paths)) + '\n')
            env['ONEFORALL_DATA_LIST'] = str(data_list)
        if args.baseline:
            path = Path(scratch) / 'benchmark-adapter.lua'
            path.write_bytes(subprocess.check_output(['git', 'show', f'{args.baseline}:EUIAddonSkins/Skins/OneForAll.lua']))
            env['ONEFORALL_SKIN_PATH'] = str(path)
        if args.native:
            env['ONEFORALL_NATIVE'] = '1'
        env['ONEFORALL_NUMERIC_TEXTURES'] = '1'
        if args.source:
            for name, file in [('WIDGETS','Widgets'),('MAINFRAME','MainFrame'),('SETTINGS','Settings'),('QOL','QoL'),('GEARPLANNER','GearPlanner')]:
                path = args.source.resolve() / 'UI' / (file + '.lua')
                assert path.is_file(), path
                env['ONEFORALL_' + name] = str(path)
        for _ in range(5):
            output = subprocess.check_output(['python3', __file__, '--trial'], env=env, text=True)
            for line in output.splitlines():
                parts = line.split()
                if parts[0] == 'OFA_LOAD':
                    records.setdefault(parts[1] + '.load_ms', []).append(float(parts[2].split('=')[1]))
                elif parts[0] == 'OFA_PERF':
                    row = {}
                    for field in parts[3:]:
                        key, value = field.split('=', 1)
                        if key == 'top':
                            records[parts[1]+'.'+parts[2]+'.profile'] = value
                        else:
                            row[key] = float(value)
                    records.setdefault(parts[1]+'.'+parts[2], []).append(row)
        result = {'adapter': 'native-index' if args.index_only else ('native-only' if args.native else (args.baseline or 'working tree')), 'trials': 5,
                  'source': str(args.source) if args.source else 'source-shaped fixture',
                  'warmup': 0 if args.index_only else 20, 'iterations': 'per workload n' if args.index_only else 200, 'latency_samples': 0 if args.index_only else 100,
                  'evidence': 'Host Lua 5.4; mocked WoW APIs/EUI. Hook trampolines allocate return tables in mocks. Lua/host-C calls are not native client API C-call measurements. GC-stopped churn is not retained memory. Not in-game CPU/frame latency/FPS.', 'results': {}}
        for key, values in records.items():
            if isinstance(values, str):
                result['results'][key] = values
            elif isinstance(values[0], dict):
                result['results'][key] = {field: statistics.median(row[field] for row in values) for field in values[0]}
            else:
                result['results'][key] = statistics.median(values)
        rendered = json.dumps(result, indent=2) + '\n'
        if args.output:
            args.output.write_text(rendered)
        print(rendered, end='')
