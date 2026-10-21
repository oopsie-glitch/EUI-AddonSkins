"""Run the RCLootCouncil mocked operation-count benchmark through the installed system Lua library."""
import ctypes
from pathlib import Path
import os
import subprocess
import sys
import tempfile

baseline = None
if '--baseline' in sys.argv:
    build = Path('build')
    build.mkdir(exist_ok=True)
    baseline = tempfile.TemporaryDirectory(dir=build)
    path = Path(baseline.name) / 'RCLootCouncil.lua'
    path.write_bytes(subprocess.check_output(['git', 'show', '8df070b33ce0c0a93a37facf8a6f75cecccea952:EUIAddonSkins/Skins/RCLootCouncil.lua']))
    os.environ['RC_SKIN_PATH'] = str(path)
    os.environ['RC_PERF_BASELINE'] = '1'

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
    rc = lua.luaL_loadfilex(state, b'tests/rclootcouncil_spec.lua', None)
    if not rc:
        rc = lua.lua_pcallk(state, 0, 0, 0, 0, None)
    if rc:
        raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
finally:
    lua.lua_close(state)
    if baseline:
        baseline.cleanup()
