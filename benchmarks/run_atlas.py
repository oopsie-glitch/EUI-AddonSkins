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
parser.add_argument('--baseline', help='Git ref containing the baseline Atlas adapter')
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
        for file in ('benchmarks/atlas.lua', 'tests/atlas_spec.lua'):
            rc = lua.luaL_loadfilex(state, file.encode(), None) or lua.lua_pcallk(state, 0, 0, 0, 0, None)
            if rc:
                raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
    finally:
        lua.lua_close(state)
else:
    records = {}
    with tempfile.TemporaryDirectory() as scratch:
        env = os.environ.copy()
        if args.baseline:
            path = Path(scratch) / 'Atlas.lua'
            path.write_bytes(subprocess.check_output(['git', 'show', f'{args.baseline}:EUIAddonSkins/Skins/Atlas.lua']))
            env['ATLAS_SKIN_PATH'] = str(path)
        for _ in range(5):
            output = subprocess.check_output(['python3', __file__, '--trial'], env=env, text=True)
            for line in output.splitlines():
                parts = line.split()
                if parts[0] == 'ATLAS_COLD':
                    _, client, cold, first = parts
                    for name, value in [('install_ms', cold), ('first_show_ms', first)]:
                        records.setdefault(f'{client}.{name}', []).append(float(value))
                elif parts[0] == 'ATLAS_PERF':
                    _, client, name, elapsed, churn, retained, *counters = parts
                    row = {'batch_1000_ms': float(elapsed), 'churn_kib': float(churn), 'retained_kib': float(retained)}
                    for field in counters:
                        key, value = field.split('=', 1)
                        if key != 'top':
                            row[key] = int(value)
                    records.setdefault(f'{client}.{name}', []).append(row)
                    records[f'{client}.{name}.profile'] = counters[-1]
        result = {'adapter': args.baseline or 'working tree', 'trials': 5, 'warmup': 100, 'iterations': 1000,
                  'evidence': 'Mock adapter timings/calls and GC-stopped Lua allocation churn; not client latency, FPS or retained native memory.', 'results': {}}
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
