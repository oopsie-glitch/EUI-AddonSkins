local timers, modules, shells, looks, errors = {}, {}, {}, {}, {}
local combat, style = false, 'eui'
local ns = {IsEnabled = function() return true end, AttachAccent = function() end,
    RegisterModule = function(id, _, available, install) modules[id] = {available = available, install = install} end}
C_Timer.After = function(_, fn) timers[#timers + 1] = fn end
InCombatLockdown = function() return combat end
geterrorhandler = function() return function(e) errors[#errors + 1] = e end end
hooksecurefunc = function(obj, key, fn)
    local orig = obj[key]
    obj[key] = function(...)
        local out = table.pack(orig(...)); fn(...); return table.unpack(out, 1, out.n)
    end
end
local function flush()
    local rounds = 0
    while #timers > 0 do
        local batch = timers; timers = {}; for _, fn in ipairs(batch) do fn() end
        rounds = rounds + 1; assert(rounds < 20, 'theme refresh loop')
    end
end
local function frame(kind, parent)
    local f = {kind = kind or 'Frame', regions = {}, children = {}, scripts = {}, alpha = 1, color = {0, 0, 0, 0.7}, visible = true}
    function f:GetObjectType() return self.kind end
    function f:IsProtected() return self.protected end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:GetChildren() return table.unpack(self.children) end
    function f:GetFrameLevel() return 4 end
    function f:SetFrameLevel() end
    function f:SetAllPoints() end
    function f:EnableMouse() end
    function f:SetAlpha(v) self.alpha = v end
    function f:IsShown() return self.visible end
    function f:SetShown(v) self.visible = v end
    function f:HookScript(key, fn) self.scripts[key] = fn end
    function f:SetScript(key, fn) self.scripts[key] = fn end
    function f:RegisterEvent() end
    function f:GetBackdrop() return self.backdrop end
    function f:SetBackdrop(v) self.backdrop = v; self.border = {1, 1, 1, 1} end
    function f:ClearBackdrop() self.backdrop = nil end
    function f:SetBackdropColor(...) self.color = {...} end
    function f:GetBackdropColor() return table.unpack(self.color) end
    function f:SetBackdropBorderColor(...) self.border = {...} end
    if parent then parent.children[#parent.children + 1] = f end
    return f
end
CreateFrame = function(kind, _, parent) return frame(kind, parent) end
local S = {GetAccentColor = function() return 0.1, 0.8, 0.6 end,
    GetPanelColor = function() return 0.03, 0.03, 0.03, 0.9 end,
    GetFont = function() return 'eui-font' end, GetStyle = function() return style end,
    OnLooksChanged = function(fn) looks[#looks + 1] = fn end}
function S.Shell(f, opts)
    shells[#shells + 1] = f; f.shellOptions = opts; f.style = style
    looks[#looks + 1] = function() f.style = style end
end
function S.Tab(f) assert(not f.buttonSkinned, 'tab was styled as a button first'); f.tabSkinned = true end
function S.SetTabSelection(f, selected) f.selected = selected end
function S.Button(f) f.buttonSkinned = true end
function S.EditBox(f, opts) f.inputOptions = opts end
function S.SquareIcon(t, f) t.borderParent = f end
function S.ApplyBarFill(f) f.fillSkinned = true end
function S.SortHeaderBar(f) f.headersSkinned = true end
for _, key in ipairs({'Font', 'Checkbox', 'Dropdown', 'ScrollBar', 'StateButtonLabel', 'CloseButton'}) do S[key] = function() end end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins', ns)
-- Shared control capabilities and custom tab selection.
local H = ns.CreateSkinHelper(S, {})
local root, tab, input, progress, list, iconButton = frame(), frame('Button'), frame('EditBox'), frame('StatusBar'), frame(), frame('Button')
list.HeaderContainer = frame()
iconButton.icon = {GetObjectType = function() return "Texture" end}
iconButton.GetWidth = function() return 25 end; iconButton.GetHeight = function() return 25 end
root.children = {tab, input, progress, list, iconButton}
local selected = true
local function visit(f) if f == tab then return H.Tab(f, selected) end end
H.Scan(root, function() end, visit)
assert(tab.tabSkinned and tab.selected and not tab.buttonSkinned)
selected = false; H.Scan(root, function() end, visit); assert(not tab.selected)
assert(input.inputOptions.padInput and progress.fillSkinned and list.headersSkinned and iconButton.icon.borderParent == iconButton)
-- RXP background-only shells on both existing window versions.
assert(loadfile('EUIAddonSkins/Skins/RXPGuides.lua'))('EUIAddonSkins', ns)
local legacy = frame(); legacy.backdrop = {edge = {}, guideName = {}, bottom = {}}
legacy.BottomFrame = frame(); legacy.BottomFrame:SetBackdrop({bgFile = 'white', edgeFile = 'border'})
local step = frame(); step:SetBackdrop({bgFile = 'white', edgeFile = 'border'})
legacy.CurrentStepFrame = {framePool = {step}}
local upper = frame(); upper.rxpBackground = frame(); upper.rxpBackground.textures = {{GetVertexColor = function() return 1, 1, 1, 0.6 end}}
local icon = {alpha = 1}; upper.regions = {} -- guide artwork never passed to Shell
local source = {font = 'original', background = {1, 1, 1}, textColor = {1, 1, 1}}
RXP = {RXPFrame = legacy, settings = {profile = {activeTheme = 'Custom'}}, LoadActiveTheme = function() return source end,
    v2 = {state = {guideWindow = {frame = frame(), upperFrame = upper}}, GetTheme = function() return {} end},
    ui = {v2 = {ApplyFrameBackdrop = function(_, f, _, bg)
        f.rxpBackground:SetAlpha(1); f.rxpBackground:SetShown(true)
    end, SetFrameBackdropShown = function(_, f, shown) f.rxpBackground:SetShown(shown) end}}}
modules.RXPGuides.install(S, modules.RXPGuides); flush()
assert(#shells == 3 and legacy.BottomFrame.color[4] == 0 and step.color[4] == 0 and upper.rxpBackground.alpha == 0)
assert(shells[1] ~= legacy.BottomFrame and shells[1].shellOptions.noBorder and shells[1].shellOptions.noTopBar)
local upperLayer = shells[3]; assert(upperLayer.alpha == 0.6, 'V2 opacity not preserved')
legacy.BottomFrame:SetBackdropColor(0.2, 0.2, 0.2, 0.4)
assert(shells[1].alpha == 0.4 and legacy.BottomFrame.color[4] == 0)
legacy.BottomFrame:ClearBackdrop(); assert(shells[1].alpha == 0, 'hidden legacy background restored')
legacy.BottomFrame:SetBackdrop({bgFile = 'white', edgeFile = 'border'}); legacy.BottomFrame:SetBackdropColor(0, 0, 0, 0.8)
assert(shells[1].alpha == 0.8 and legacy.BottomFrame.border[1] == 0.055)
RXP.ui.v2:SetFrameBackdropShown(upper, false); assert(upperLayer.alpha == 0, 'hidden V2 background restored')
RXP.ui.v2:ApplyFrameBackdrop(upper, {}, {0, 0, 0, 0.3}); flush()
assert(upperLayer.alpha == 0.3 and upper.rxpBackground.alpha == 0)
style = 'modern'; for _, fn in ipairs(looks) do fn() end; flush()
for _, shell in ipairs(shells) do assert(shell.style == 'modern') end
assert(RXP.settings.profile.activeTheme == 'Custom' and source.font == 'original' and icon.alpha == 1)
assert(#errors == 0, table.concat(errors, '\n'))
print('PASS: native tab selection, input padding, statusbar fills, icon borders, sortable headers, RXP shells/live styles/opacity/hidden backgrounds')
