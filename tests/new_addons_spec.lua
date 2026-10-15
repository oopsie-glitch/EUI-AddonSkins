-- Integration safety: lazy AH controls, callbacks, secure Spy rows and combat.
local timers, errors, modules, looks, events = {}, {}, {}, {}, {}
local enabled, combat = true, false
local ns = {IsEnabled = function() return enabled end,
    AttachAccent = function(_, f) f.accent = true end}
function ns.RegisterModule(id, _, available, install) modules[id] = {available = available, install = install} end
C_Timer.After = function(_, fn) timers[#timers + 1] = fn end
InCombatLockdown = function() return combat end
geterrorhandler = function() return function(e) errors[#errors + 1] = e end end
hooksecurefunc = function(obj, key, callback)
    local original = obj[key]
    obj[key] = function(...)
        local result = table.pack(original(...)); callback(...); return table.unpack(result, 1, result.n)
    end
end
local function flush()
    local rounds = 0
    while #timers > 0 do
        local batch = timers; timers = {}; for _, fn in ipairs(batch) do fn() end
        rounds = rounds + 1; assert(rounds < 20, 'refresh loop')
    end
end
local function frame(kind, parent)
    local f = {kind = kind or 'Frame', children = {}, regions = {}, hooks = {}, scripts = {}, shown = true}
    function f:GetObjectType() return self.kind end
    function f:IsForbidden() return self.forbidden end
    function f:IsProtected() return self.protected end
    function f:GetChildren() return table.unpack(self.children) end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:GetFrameLevel() return 4 end
    function f:SetFrameLevel(v) self.level = v end
    function f:SetAllPoints() end
    function f:EnableMouse(v) self.mouse = v end
    function f:SetBackdrop(v) assert(not combat); self.backdrop = v end
    function f:HookScript(key, fn) self.hooks[key] = fn end
    function f:SetScript(key, fn) self.scripts[key] = fn end
    function f:RegisterEvent(e) self.events = self.events or {}; self.events[e] = true end
    function f:IsShown() return self.shown end
    if parent then parent.children[#parent.children + 1] = f end
    return f
end
CreateFrame = function(kind, name, parent)
    local f = frame(kind, parent)
    if name then _G[name] = f end
    if not parent then events[#events + 1] = f end
    return f
end
local config = {OpenFrames = {}, FeedGroup = function() end}
LibStub = function() return config end
local S = {OnLooksChanged = function(fn) looks[#looks + 1] = fn end}
function S.Shell(f, opts) assert(not combat); f.shell = true; f.shellOptions = opts end
function S.Panel(f) assert(not f.protected); f.panel = true end
function S.Tab(f) assert(not f.protected); f.tab = true end
function S.SetTabSelection(f, v) f.selected = v end
function S.CloseButton(f) f.close = true end
function S.PageButton(f, glyph) f.glyph = glyph end
function S.EditBox(f, opts) assert(not f.protected); f.padded = opts.padInput; f.inputOptions = opts end
function S.Button(f) f.button = true end
function S.ScrollBar(f) f.scroll = true end
function S.Font() end
function S.FadeNineSlice() end
function S.ApplyBarFill(f) error('Spy secure row bar must retain semantic colors') end
function S.Checkbox() end
function S.StateButtonLabel() end
function S.Dropdown() end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins', ns)
for _, name in ipairs({'Auctionator', 'Spy'}) do
    _G[name] = nil
    assert(loadfile('EUIAddonSkins/Skins/' .. name .. '.lua'))('EUIAddonSkins', ns)
    assert(not modules[name].available())
end
Auctionator = {Tabs = {State = {knownTabs = {{name = 'Shopping', tabFrameName = 'AuctionatorShoppingFrame'}}}},
    Dialogs = {}, Config = {InternalInitializeFrames = function() end}}
AuctionatorTabContainerMixin = {OnLoad = function() return 'constructor-result' end}
AuctionatorExportTextFrameMixin = {OnLoad = function() end}
Auctionator.Dialogs.ShowConfirm = function()
    AuctionatorDialog1 = frame(); AuctionatorDialog1.children = {frame('EditBox')}
    AuctionatorDialog1.callback = function() return 'purchase-original' end
    return 17
end
modules.Auctionator.install(S, modules.Auctionator); flush()
assert(AuctionatorShoppingFrame == nil, 'skin must not open the AH')
AuctionatorShoppingFrame = frame()
AuctionatorShoppingFrame.ScrollBar = frame('EventFrame')
local input = frame('EditBox', AuctionatorShoppingFrame)
AuctionatorTabs_Shopping = frame('Button')
AuctionatorTabs_Shopping.Selected = function() return 19 end
AuctionatorTabs_Shopping.DeselectTab = function() AuctionatorShoppingFrame.shown = false end
assert(AuctionatorTabContainerMixin.OnLoad(frame()) == 'constructor-result'); flush()
assert(AuctionatorShoppingFrame.shell and input.padded and AuctionatorShoppingFrame.ScrollBar.scroll)
assert(AuctionatorTabs_Shopping.tab and AuctionatorTabs_Shopping.selected)
assert(AuctionatorTabs_Shopping:Selected() == 19)
AuctionatorTabs_Shopping:DeselectTab(); flush(); assert(not AuctionatorTabs_Shopping.selected)
assert(Auctionator.Dialogs.ShowConfirm() == 17); flush()
assert(AuctionatorDialog1.shell and AuctionatorDialog1.callback() == 'purchase-original')
local export = frame(); AuctionatorExportTextFrameMixin.OnLoad(export); flush(); assert(export.shell)
combat = true
local late = frame(); AuctionatorExportTextFrameMixin.OnLoad(late); flush(); assert(not late.shell)
combat = false
for _, f in ipairs(events) do if f.events and f.events.PLAYER_REGEN_ENABLED then f.scripts.OnEvent(f, 'PLAYER_REGEN_ENABLED') end end
flush(); assert(late.shell)
-- Global discovery runs at initialization/load boundaries, not each repaint.
local nativePairs, globalWalks = pairs, 0
pairs = function(t)
    if t == _G then globalWalks = globalWalks + 1 end
    return nativePairs(t)
end
for _ = 1, 25 do modules.Auctionator.refresh(); flush() end
assert(globalWalks == 0, 'warm refresh searched all globals')
AuctionatorConfigLazyFrame = frame(); local lazyInput = frame('EditBox', AuctionatorConfigLazyFrame)
Auctionator.Config:InternalInitializeFrames(); flush()
assert(globalWalks == 1 and lazyInput.padded, 'late config discovery lost')
AuctionatorConfigLoadedFrame = frame(); local loadedInput = frame('EditBox', AuctionatorConfigLoadedFrame)
for _, f in ipairs(events) do
    if f.events and f.events.ADDON_LOADED then f.scripts.OnEvent(f, 'ADDON_LOADED') end
end
flush(); assert(globalWalks == 2 and loadedInput.padded, 'addon-load discovery lost')
pairs = nativePairs
-- Spy's root is protected through its target rows. Never modify those rows.
Spy = {CreateMainWindow = function() end, CreateFrame = function(_, name) _G[name] = frame(); return _G[name], 'extra' end,
    Colors = {UpdateColor = function() end}}
Spy.MainWindow = frame(); Spy.MainWindow.protected = true
local row = frame('Button', Spy.MainWindow); row.protected = true
row.attributes = {macrotext = '/target Enemy'}
row.click = function() return 'target-original' end
local bar = frame('StatusBar', row); bar.color = {1, 0, 0}
Spy.MainWindow.Rows = {row}
Spy.MainWindow.CloseButton = frame('Button', Spy.MainWindow)
Spy.MainWindow.LeftButton = frame('Button', Spy.MainWindow)
Spy.AlertWindow = frame(); Spy.AlertWindow.Icon = frame('Frame', Spy.AlertWindow)
Spy.AlertWindow.Icon.backdrop = {bgFile = 'alert-icon'}
SpyStatsFrame = frame(); SpyStatsFrameTopCloseButton = frame('Button', SpyStatsFrame)
local filter = frame('EditBox', SpyStatsFrame)
local optionsRoot = frame(); local optionInput = frame('EditBox', optionsRoot)
Spy.optionsFrames = {General = optionsRoot}
modules.Spy.install(S, modules.Spy); flush()
assert(optionInput.padded)
local standalone = frame(); local newOption = frame('EditBox', standalone)
config.OpenFrames.Spy = {frame = standalone}
config:FeedGroup('Spy', {}, {}, {frame = standalone}); flush()
assert(standalone.children[#standalone.children].shell and newOption.padded)
assert(filter.padded and SpyStatsFrameTopCloseButton.close)
assert(Spy.MainWindow.CloseButton.close and Spy.MainWindow.LeftButton.glyph == '<')
assert(row.attributes.macrotext == '/target Enemy' and row.click() == 'target-original' and bar.color[1] == 1)
assert(Spy.AlertWindow.Icon.backdrop.bgFile == 'alert-icon')
local bg = Spy.MainWindow.children[#Spy.MainWindow.children]
assert(bg.shellOptions.noBorder and bg.shellOptions.noTopBar and filter.inputOptions.noBorder, 'Spy soft shell/input missing')
assert(bg.shell and bg.accent and bg.mouse == false and bg.level < Spy.MainWindow:GetFrameLevel())
local dialog, extra = Spy:CreateFrame('SpyExtraWindow'); assert(extra == 'extra'); flush()
assert(dialog.children[1].shell)
combat = true
local pending = Spy:CreateFrame('SpyLateWindow'); flush(); assert(#pending.children == 0)
combat = false
for _, f in ipairs(events) do if f.events and f.events.PLAYER_REGEN_ENABLED then f.scripts.OnEvent(f, 'PLAYER_REGEN_ENABLED') end end
flush(); assert(pending.children[1].shell)
enabled = false
local disabled = Spy:CreateFrame('SpyDisabledWindow'); flush(); assert(#disabled.children == 0)
for _, fn in ipairs(looks) do fn() end; flush(); assert(#disabled.children == 0)
assert(#errors == 0, table.concat(errors, '\n'))
print('PASS: Auctionator lazy tabs/dialogs/scrollbars, preserved constructors/actions, Spy secure rows/icons, combat deferral, disabled refresh')
