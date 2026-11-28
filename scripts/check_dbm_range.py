"""Run pinned upstream RangeCheck methods in isolated hosted Lua, never in WoW."""
import ctypes
import hashlib
import urllib.request
from pathlib import Path

DBM_PIN = "fc433f76eba067f6704aa81340f40aeb61a6c58b"
STABLE_PIN = "b12b88d06e7812a9f2f26658400443ba48cbd57d"  # 12.1.26
WOW_PIN = "ab5cb850a3f65e742959e379c4689353a2f4549f"
def fetch(repo, pin, path):
    with urllib.request.urlopen(f"https://raw.githubusercontent.com/{repo}/{pin}/{path}", timeout=60) as r:
        data = r.read()
    print("SOURCE", repo, pin, path, "sha256=" + hashlib.sha256(data).hexdigest())
    return data.decode()

range_path = "DBM-Core/DBM-RangeCheck.lua"
source = fetch("DeadlyBossMods/DeadlyBossMods", DBM_PIN, range_path)
stable = fetch("DeadlyBossMods/DeadlyBossMods", STABLE_PIN, range_path)
gui = fetch("DeadlyBossMods/DeadlyBossMods", DBM_PIN, "DBM-GUI/modules/options/general/Core_GUI.lua")
docs = fetch("Gethe/wow-ui-source", WOW_PIN, "Interface/AddOns/Blizzard_APIDocumentationGenerated/RaidMarkersDocumentation.lua")
api = docs.split('Name = "GetRaidTargetIndex"', 1)[1].split('Name = "IsRaidMarkerActive"', 1)[0]
assert "SecretReturns = true" in api
assert source == stable, "Latest verified stable and development RangeCheck differ; reassess findings"
update = source[source.index("\tfunction updateIcon()"):source.index("\tfunction updateRangeFrame()")]
show = source[source.index("function rangeCheck:Show("):source.index("function rangeCheck:Hide(")]
click = gui[gui.index('bmrange:SetScript("OnClick"'):gui.index("\nlocal bminfo")]
assert "local icon = GetRaidTargetIndex(unitList[i])" in update
assert "unitIcons[i] = icon and icon < 9 and icon or nil" in update
assert "updateIcon()" in show and "DBM.RangeCheck:Show(nil, nil, true)" in click
assert "GetRaidTargetIndex" not in Path("EUIAddonSkins/Skins/DBM.lua").read_text()

# Only the three exact upstream function bodies are compiled. Other native
# services/frames are deterministic mocks. No DBM file is modified or bundled.
prefix = """
DBM_RANGE_FACTORY = function(iconValue, makeFrame, flags)
    local state = {reads = 0, played = false}
    local textFrame = makeFrame()
    textFrame:Hide()
    local radarFrame
    local mainFrame = {}
    local unitList, unitClasses, unitIcons = {}, {}, {}
    local activeDots, max = 0, math.max
    local GetNumGroupMembers = function() return 1 end
    local IsInRaid = function() return flags.raid end
    local UnitClass = function() return 'Warrior', 'WARRIOR' end
    local GetRaidTargetIndex = function(unit)
        state.reads = state.reads + 1; state.unit = unit
        return iconValue
    end
    local InCombatLockdown = function() return flags.combat end
    local DBM = {Options = {RangeFrameFrames = 'text'}}
    function DBM:GetNumRealGroupMembers() return 2 end
    function DBM:UpdateMapRestrictions() end
    function DBM:HasMapRestrictions() return flags.restricted end
    local rangeCheck = {}
    DBM.RangeCheck = rangeCheck
    function rangeCheck:IsShown() return textFrame:IsShown() end
    function rangeCheck:Hide() textFrame:Hide() end
    local controller = {RegisterEvent = function() end}
    local createController = function() return controller end
    local updater = {SetScript = function() end, Play = function() state.played = true end}
    local setCompatibleRestrictedRange = function(range) return range end
    local createTextFrame = function() error('unexpected native text construction') end
    local createRadarFrame = function() error('unexpected native radar construction') end
    local updateIcon
    local updateRangeFrame = function() end
    local restoreRange, restoreFilter, restoreThreshold, restoreReverse
    local click
    local bmrange = {SetScript = function(_, name, fn) assert(name == 'OnClick'); click = fn end}
"""
factory = prefix + update + show + click + """
    return {range = rangeCheck, click = click, icons = unitIcons, state = state}
end
"""
cases = Path("tests/dbm_range_upstream_spec.lua").read_text()
standalone = """
local function frame()
    return {shown = false,
        Show = function(self) self.shown = true end,
        Hide = function(self) self.shown = false end,
        IsShown = function(self) return self.shown end}
end
DBM_RANGE_CASES(frame, nil, 'without EUI AddonSkins loaded')
"""
injection = """
do
    local previous = DBM.RangeCheck
    local function attach(range)
        DBM.RangeCheck = range
        enabled = true
        modules.DBM.refresh(); flush() -- install the actual adapter's Show hook
    end
    DBM_RANGE_CASES(function() return CreateFrame('Frame') end,
        function(range) attach(range); enabled = false end, 'DBM skin disabled')
    DBM_RANGE_CASES(function() return CreateFrame('Frame') end,
        attach, 'DBM skin enabled')
    DBM.RangeCheck = previous
    enabled = true
end
"""
fixture = Path("tests/dbm_hud_spec.lua").read_text()
marker = "-- Disabled skins can save preferences without repainting anything."
assert fixture.count(marker) == 1
fixture = fixture.replace(marker, injection + marker)

lua = ctypes.CDLL("liblua5.4.so.0")
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadbufferx.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_size_t, ctypes.c_char_p, ctypes.c_char_p]
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_close.argtypes = [ctypes.c_void_p]
for label, test in (("standalone", standalone), ("adapter", fixture)):
    state = lua.luaL_newstate()
    lua.luaL_openlibs(state)
    try:
        encoded = (factory + cases + test).encode()
        rc = lua.luaL_loadbufferx(state, encoded, len(encoded), b"@tests/dbm_range_upstream_spec.lua", None)
        if not rc:
            rc = lua.lua_pcallk(state, 0, 0, 0, 0, None)
        if rc:
            raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
        print("PASS:", label, "source-extracted comparison/control flow; not a live WoW secret-value test")
    finally:
        lua.lua_close(state)
