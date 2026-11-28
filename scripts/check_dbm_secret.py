"""Secret-free cloud reproduction and five-trial hosted DBM measurements."""
import argparse, ctypes, json, statistics, urllib.request
from pathlib import Path
BASE = "0e388c8fc9fd635d5ec50d2a78d83a843005b7fd"
RAW = "https://raw.githubusercontent.com/oopsie-glitch/EUI-AddonSkins/"
TARGET = Path("EUIAddonSkins/Skins/DBM.lua")
def fetch(path):
    with urllib.request.urlopen(RAW + BASE + "/" + path, timeout=60) as response:
        return response.read().decode()
lua = ctypes.CDLL("liblua5.4.so.0")
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_getglobal.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
lua.lua_close.argtypes = [ctypes.c_void_p]
def run(source, result=False):
    state = lua.luaL_newstate()
    lua.luaL_openlibs(state)
    try:
        code = lua.luaL_loadstring(state, source.encode())
        if not code: code = lua.lua_pcallk(state, 0, 0, 0, 0, None)
        if code: raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
        if result:
            lua.lua_getglobal(state, b"DBM_BENCH")
            return json.loads(lua.lua_tolstring(state, -1, None).decode())
    finally: lua.lua_close(state)
parser = argparse.ArgumentParser()
parser.add_argument("--baseline", action="store_true")
parser.add_argument("--benchmark", action="store_true")
args = parser.parse_args()
candidate, baseline = TARGET.read_text(), fetch(str(TARGET))
try:
    if args.baseline:
        TARGET.write_text(baseline)
        try: run(Path("tests/dbm_hud_spec.lua").read_text())
        except RuntimeError as exc:
            assert "secret border visibility reached cosmetic mutation" in str(exc), str(exc)
            print("CONFIRMED baseline fails restricted border mutation regression:", str(exc))
        else: raise AssertionError("Regression did not reject released implementation")
    if args.benchmark:
        fixture = fetch("tests/dbm_hud_spec.lua")
        fixture = fixture.replace("local function object(kind, name, parent)", "local kinds = {}\nlocal function object(kind, name, parent)\n    kinds[kind] = (kinds[kind] or 0) + 1")
        marker = "DBM, DBT, C_Secrets, DebuffTypeColor, AuraUtil = nil, nil, nil, nil, nil"
        workload = """
enabled = true; modules.DBM.refresh(); flush()
local output = {}
local function measure(name, count, fn)
    fn(); collectgarbage('collect')
    local memory, objects, hookCount = collectgarbage('count'), created, hooks
    local start = os.clock()
    for _ = 1, count do fn() end
    local elapsed = (os.clock() - start) * 1000
    collectgarbage('collect')
    output[#output+1] = string.format('"%s":{"ms":%.6f,"retained_kib":%.6f,"objects":%d,"hooks":%d}',
        name, elapsed, collectgarbage('count') - memory, created - objects, hooks - hookCount)
    assert(created == objects and hooks == hookCount, 'warm workload allocated objects/hooks')
end
measure('aura_settings_1000', 1000, function() DBM.Auras:OnSettingsChange() end)
measure('countdown_1000', 1000, function() first:Update() end)
measure('theme_100', 100, function() for _, fn in ipairs(looks) do fn() end; flush() end)
measure('combat_aura_1000', 1000, function() combat = true; DBM.Auras:OnSettingsChange(); combat = false end)
measure('disabled_aura_1000', 1000, function() enabled = false; DBM.Auras:OnSettingsChange(); enabled = true end)
local eventsCount = 0
for _, frame in ipairs(frames) do for _ in pairs(frame.events) do eventsCount = eventsCount + 1 end end
output[#output+1] = string.format('"inventory":{"objects":%d,"frames":%d,"textures":%d,"fontstrings":%d,"hooks":%d,"event_registrations":%d}',
    created, #frames, kinds.Texture or 0, kinds.FontString or 0, hooks, eventsCount)
DBM_BENCH = '{' .. table.concat(output, ',') .. '}'
"""
        assert marker in fixture
        fixture = fixture.replace(marker, workload + "\n" + marker)
        results = {}
        for label, source in (("v1.6.8", baseline), ("candidate", candidate)):
            TARGET.write_text(source)
            trials = [run("print = function() end\n" + fixture, True) for _ in range(5)]
            results[label] = {work: {key: statistics.median(trial[work][key] for trial in trials)
                for key in trials[0][work]} for work in trials[0]}
        print("HOSTED_LUA_MEDIANS " + json.dumps(results, sort_keys=True))
finally:
    TARGET.write_text(candidate)
