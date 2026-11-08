"""RestedXP host-Lua audit. Run from the repository root."""
import argparse
import ctypes
import json
import os
from pathlib import Path
import statistics
import subprocess
import sys
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
mode = parser.add_mutually_exclusive_group()
mode.add_argument('--baseline', help='Git ref containing a baseline RXPGuides adapter')
mode.add_argument('--native', action='store_true', help='Run the same fixture without installing the adapter')
parser.add_argument('--output', type=Path)
parser.add_argument('--trial', action='store_true', help=argparse.SUPPRESS)
args = parser.parse_args()


def trial():
    lua = ctypes.CDLL('liblua5.4.so.0')
    lua.luaL_newstate.restype = ctypes.c_void_p
    lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
    lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
    lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
    lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
    lua.lua_tolstring.restype = ctypes.c_char_p
    lua.lua_close.argtypes = [ctypes.c_void_p]
    state = lua.luaL_newstate()
    try:
        lua.luaL_openlibs(state)
        if lua.luaL_loadfilex(state, b'benchmarks/restedxp.lua', None) or lua.lua_pcallk(state, 0, 0, 0, 0, None):
            raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
    finally:
        lua.lua_close(state)


if args.trial:
    trial()
else:
    trials = []
    with tempfile.TemporaryDirectory() as scratch:
        env = os.environ.copy()
        if args.baseline:
            path = Path(scratch) / 'RXPGuides.lua'
            path.write_bytes(subprocess.check_output(['git', 'show', f'{args.baseline}:EUIAddonSkins/Skins/RXPGuides.lua']))
            env['RXP_ADAPTER'] = str(path)
        if args.native:
            env['RXP_NATIVE'] = '1'
        for _ in range(5):
            results = {}
            for profile in ('0', '1'):
                output = subprocess.check_output([sys.executable, __file__, '--trial'],
                                                 env=dict(env, RXP_COLD_PROFILE=profile), text=True)
                for line in output.splitlines():
                    if line.startswith('RXP '):
                        _, workload, *fields = line.split()
                        results.setdefault(workload, {}).update(
                            (key, float(value)) for key, value in (field.split('=') for field in fields))
            trials.append(results)
    medians = {name: {metric: statistics.median(t[name][metric] for t in trials) for metric in row}
               for name, row in trials[0].items()}
    result = json.dumps({'adapter': args.baseline or ('native model' if args.native else 'working tree'),
                         'trials': trials, 'medians': medians}, indent=2) + '\n'
    if args.output:
        args.output.write_text(result)
    print(result, end='')
