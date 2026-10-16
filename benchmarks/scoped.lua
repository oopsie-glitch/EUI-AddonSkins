-- Synthetic scoped skin (ns.RegisterScopedSkin): 6 option roots, one visible, 10 groups of
-- 30 controls each with font strings. Measures warm refreshes (what any click or
-- enable/disable on a skinned button queues). Lua 5.4 host; SetFont is counted, not timed.
-- BENCH_ROOT points at the addon directory to measure.
local timers, modules, counters = {}, {}, {}
local ns = {AttachAccent = function() end}
function ns.IsEnabled() return true end
function ns.RegisterModule(id, _, available, install) modules[id] = {available = available, install = install} end
C_Timer = {After = function(_, fn) timers[#timers + 1] = fn end}
InCombatLockdown = function() return false end
geterrorhandler = function() return function(e) error(e) end end
hooksecurefunc = function(obj, key, callback)
    local original = obj[key]
    obj[key] = function(...) original(...); callback(...) end
end
local function count(key) counters[key] = (counters[key] or 0) + 1 end
local function flush()
    while #timers > 0 do local batch = timers; timers = {}; for _, fn in ipairs(batch) do fn() end end
end
local FontString = {}
FontString.__index = FontString
function FontString:GetObjectType() return 'FontString' end
function FontString:IsForbidden() return false end
function FontString:IsProtected() return false end
function FontString:GetFont() return self.font, 12, self.flags end
function FontString:SetFont(path, _, flags) count('setfont'); self.font, self.flags = path, flags end
function FontString:GetTextColor() return 1, 1, 1, 1 end
function FontString:SetTextColor() end
function FontString:GetText() return 'Label' end
local Frame = {}
Frame.__index = Frame
function Frame:GetObjectType() return self.kind end
function Frame:IsForbidden() return false end
function Frame:IsProtected() return false end
function Frame:GetParent() return self.parent end
function Frame:GetName() end
function Frame:GetChildren() count('children'); return table.unpack(self.children) end
function Frame:GetRegions() return table.unpack(self.regions) end
function Frame:GetNumChildren() return #self.children end
function Frame:GetNumRegions() return #self.regions end
function Frame:GetWidth() return 100 end
function Frame:GetHeight() return 20 end
function Frame:GetPoint() end
function Frame:IsShown() return self.shown end
function Frame:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function Frame:HookScript(key, fn) self.scripts[key] = fn end
function Frame:SetScript(key, fn) self.scripts[key] = fn end
function Frame:HasScript() return true end
function Frame:RegisterEvent() end
function Frame:GetFontString() return self.label end
function Frame:GetBackdrop() end
function Frame:SetBackdrop() end
function Frame:CreateTexture() return {SetColorTexture = function() end, SetPoint = function() end, SetAllPoints = function() end} end
local function frame(kind, parent)
    local f = setmetatable({kind = kind or 'Frame', children = {}, regions = {}, scripts = {}, shown = true}, Frame)
    if parent then f.parent = parent; parent.children[#parent.children + 1] = f end
    return f
end
local function text(f)
    local fs = setmetatable({font = 'native', flags = ''}, FontString)
    f.regions[#f.regions + 1] = fs
    return fs
end
CreateFrame = function(kind, _, parent) return frame(kind, parent) end
local S = {}
for _, key in ipairs({'Shell', 'Panel', 'Inset', 'EditBox', 'ScrollBar', 'SquareIcon', 'FadeNineSlice',
    'CloseButton', 'Checkbox', 'Dropdown', 'StateButtonLabel', 'PageButton', 'Tab', 'SetTabSelection', 'White'}) do
    S[key] = function() end
end
function S.Button() count('button') end
function S.Font(fs) count('font'); fs:SetFont('eui', 12, '') end
function S.GetFont() return 'eui', '' end
function S.GetAccentColor() return 0.1, 0.8, 0.6 end
assert(loadfile(BENCH_ROOT .. '/Widgets.lua'))('EUIAddonSkins', ns)
assert(loadfile(BENCH_ROOT .. '/Scoped.lua'))('EUIAddonSkins', ns)

local roots = {}
for r = 1, 6 do
    local root = frame(); root.shown = r == 1
    text(root)
    for _ = 1, 10 do
        local group = frame('Frame', root); text(group)
        for index = 1, 30 do
            local c = frame(index % 3 == 0 and 'Button' or 'Frame', group)
            c.label = text(c); text(c)
        end
    end
    roots[r] = root
end
ns.RegisterScopedSkin('Bench', 'Bench', {
    available = function() return true end,
    roots = function() return roots end,
})
local module = {}
modules.Bench.install(S, module); flush()
local function measure(n, fn)
    counters = {}
    collectgarbage('collect'); collectgarbage('stop')
    local heap, started = collectgarbage('count'), os.clock()
    for _ = 1, n do fn() end
    local elapsed, allocated = os.clock() - started, collectgarbage('count') - heap
    collectgarbage('restart')
    return elapsed, allocated, counters
end
local elapsed, allocated, c = measure(200, function() module.refresh(); flush() end)
print(string.format('MEASURE %.6f %.3f %d %d %d', elapsed, allocated, c.font or 0, c.setfont or 0, c.children or 0))
