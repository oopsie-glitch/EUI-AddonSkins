"""Run Lua using the system library; no downloaded test dependencies."""
import ctypes
from pathlib import Path

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
    for path in Path('EUIAddonSkins').rglob('*.lua'):
        rc = lua.luaL_loadfilex(state, str(path).encode(), None)
        if rc:
            raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
    for test in ['tests/package_spec.lua', 'tests/loader_spec.lua', 'tests/loader_modules_spec.lua', 'tests/skin_spec.lua', 'tests/collection_spec.lua', 'tests/toggles_spec.lua', 'tests/accent_spec.lua', 'tests/features_spec.lua', 'tests/new_addons_spec.lua', 'tests/batch_spec.lua', 'tests/menus_spec.lua', 'tests/performance_spec.lua', 'tests/legacy_controls_spec.lua', 'tests/details_spec.lua', 'tests/threat_spec.lua', 'tests/pallypower_spec.lua', 'tests/auctionator_modern_spec.lua', 'tests/btwquests_spec.lua', 'tests/dbm_hud_spec.lua', 'tests/rxp_options_spec.lua', 'tests/settings_spec.lua', 'tests/myslot_spec.lua', 'tests/simulationcraft_spec.lua']:
        rc = lua.luaL_loadfilex(state, test.encode(), None)
        if not rc:
            rc = lua.lua_pcallk(state, 0, 0, 0, 0, None)
        if rc:
            raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
finally:
    lua.lua_close(state)
