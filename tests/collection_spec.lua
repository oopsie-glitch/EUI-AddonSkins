-- Integration regressions for optional, lazy targets and session-only RXP themes.
local timers, errors, modules, looks = {}, {}, {}, {}
local enabled = true
local ns = {IsEnabled = function() return enabled end}
function ns.RegisterModule(id, label, available, install)
    modules[id] = {available = available, install = install}
end
geterrorhandler = function() return function(e) errors[#errors + 1] = e end end
C_Timer.After = function(_, fn) timers[#timers + 1] = fn end
hooksecurefunc = function(object, key, fn)
    local original = object[key]
    object[key] = function(...)
        local result = table.pack(original(...)); fn(...); return table.unpack(result, 1, result.n)
    end
end
local function flush()
    local rounds = 0
    while #timers > 0 do
        local batch = timers; timers = {}
        for _, fn in ipairs(batch) do fn() end
        rounds = rounds + 1; assert(rounds < 15, 'refresh loop')
    end
end
local function region(path, layer)
    return {alpha = 0.8, GetObjectType = function() return 'Texture' end,
        GetTexture = function() return path end, GetDrawLayer = function() return layer end,
        GetAlpha = function(self) return self.alpha end, SetAlpha = function(self, a) self.alpha = a end}
end
local function frame(kind)
    local f = {kind = kind or 'Frame', children = {}, regions = {}, hooks = {}}
    function f:CreateTexture()
        self.created = self.created or {}
        local t = {SetPoint = function(self, ...) self.points = self.points or {}; self.points[#self.points + 1] = {...} end, ClearAllPoints = function(self) self.points = {} end, SetHeight = function() end, SetWidth = function(self, w) self.width = w end,
            SetColorTexture = function(self, ...) self.color = {...} end,
            SetAlpha = function(self, a) self.alpha = a end}
        self.created[#self.created + 1] = t
        return t
    end
    function f:GetObjectType() return self.kind end
    function f:IsProtected() return self.protected end
    function f:GetChildren() return table.unpack(self.children) end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:HookScript(key, fn) self.hooks[key] = fn end
    function f:SetBackdrop(v) self.backdropValue = v; self.borderColor = {1, 1, 1, 1} end
    function f:GetBackdrop() return self.backdropValue end
    function f:SetBackdropColor() end
    function f:SetBackdropBorderColor(...) self.borderColor = {...} end
    function f:GetBackdropBorderColor() return table.unpack(self.borderColor or {1, 1, 1, 1}) end
    return f
end
local combat, combatEvents = false
InCombatLockdown = function() return combat end
CreateFrame = function()
    local f = frame()
    function f:RegisterEvent(event) self.event = event end
    function f:SetScript(event, fn) self.hooks[event] = fn end
    combatEvents = f; return f
end
local S = {GetAccentColor = function() return 0.1, 0.8, 0.6 end,
    GetPanelColor = function() return 0.03, 0.03, 0.04, 0.95 end,
    GetFont = function() return 'EUI-font', 'OUTLINE' end,
    OnLooksChanged = function(fn) looks[#looks + 1] = fn end}
local shells, edits = 0, 0
function S.Shell(f, options) f.shellOptions = options; shells = shells + 1; for _, r in ipairs(f.regions) do r:SetAlpha(0) end end
function S.Panel(f) for _, r in ipairs(f.regions) do r:SetAlpha(0) end end
function S.EditBox(f) edits = edits + 1; assert(not f.protected) end
for _, key in ipairs({'Font', 'Button', 'StateButtonLabel', 'Checkbox', 'Dropdown', 'ScrollBar', 'CloseButton', 'FadeNineSlice', 'PageButton'}) do S[key] = function(f) if key == 'CloseButton' then f.euiClose = true end end end
for _, file in ipairs({'EUIAddonSkins/Accent.lua', 'EUIAddonSkins/Widgets.lua', 'EUIAddonSkins_ForeverDungeonJournal/Skin.lua', 'EUIAddonSkins_RXPGuides/Skin.lua'}) do
    assert(loadfile(file))('EUIAddonSkins', ns)
end
RXP = nil; ForeverDungeonJournal_NS = nil
assert(not modules.RXPGuides.available() and not modules.ForeverDungeonJournal.available(), 'targets must be optional')
local source = {font = 'original-font', background = {1, 1, 1, 1}, textColor = {1, 0, 0}, mapPins = {1, 0, 0}, tooltip = {1, 1, 0}}
local source2 = {font = 'original-v2', backgroundColors = {common = {1, 1, 1}}, borderColors = {common = {1, 1, 1}}, textColor = {title = {1, 1, 0}}, edge = {}, mapPins = {0, 1, 1}, navigationArrow = 'arrow'}
local guide = frame()
guide.backdrop = {
    edge = {edgeSize = 8, insets = {left = 4, right = 2, top = 2, bottom = 4}},
    guideName = {edgeSize = 8, insets = {left = 4, right = 2, top = 2, bottom = 4}},
    bottom = {insets = {left = 4, right = 2, top = 2, bottom = 4}},
}
guide.GuideName = {bg = region('banner', 'BACKGROUND'), icon = region('logo', 'ARTWORK')}
guide.BottomFrame = frame(); guide.BottomFrame:SetBackdrop({edgeFile = 'old'})
local step = frame(); step.number = frame(); step:SetBackdrop({edgeFile = 'old'}); step.number:SetBackdrop({edgeFile = 'old'})
guide.CurrentStepFrame = {framePool = {step}}
guide.Footer = {bg = region('footer', 'BACKGROUND')}
local secret, input = frame('EditBox'), frame('EditBox'); secret.protected = true
guide.children = {secret, input}
local guideCreates, originalCalls, renders = 0, 0, 0
local lazyTarget
RXP = {targeting = {CreateTargetFrame = function(self) self.activeTargetFrame = lazyTarget end}, RXPFrame = guide, settings = {profile = {activeTheme = 'Custom', guideFontSize = 12}},
    LoadActiveTheme = function() originalCalls = originalCalls + 1; return source, nil, 'tail' end,
    RenderFrame = function() renders = renders + 1; return nil, 'render-tail' end,
    v2 = {state = {}, GetTheme = function() return source2 end,
        GetGuideWindow = function(self)
            guideCreates = guideCreates + 1
            local window = {frame = frame(), banner = region('v2-banner', 'ARTWORK'), UpdateTheme = function() end}
            self.state.guideWindow = window; return window
        end}}
assert(modules.RXPGuides.available())
modules.RXPGuides.install(S, modules.RXPGuides); flush()
assert(guide.BottomFrame.borderColor[1] == 0.055 and step.borderColor[1] == 0.055 and step.number.borderColor[1] == 0.055, 'legacy border tint missing')
guide.protected = true
step:SetBackdrop({edgeFile = 'old'}); assert(step.borderColor[1] == 0.055, 'white border visible before queued refresh'); flush()
assert(step.borderColor[1] == 0.055, 'reused step backdrop became white on a protected guide root')
step:SetBackdropBorderColor(0.1, 0.8, 0.6, 1); assert(step.borderColor[2] == 0.8, 'semantic status border changed')
step:SetBackdropBorderColor(0.2, 0.2, 0.22, 1); assert(step.borderColor[1] == 0.055, 'neutral border must stay subdued')
guide.protected = false
assert(guideCreates == 0, 'skin must not create lazy guide windows')
assert(edits == 1 and guide.GuideName.icon.alpha == 0.8, 'restricted controls and icons must survive')
assert(guide.GuideName.bg.alpha == 0, 'legacy banner remains visible')
local theme, empty, tail = RXP:LoadActiveTheme()
assert(theme ~= source and empty == nil and tail == 'tail', 'theme wrapper lost returns')
assert(theme.font == 'EUI-font' and source.font == 'original-font' and source.background[1] == 1)
assert(theme.mapPins == source.mapPins and theme.tooltip == source.tooltip, 'semantic colors changed')
assert(RXP.settings.profile.activeTheme == 'Custom' and RXP.settings.profile.guideFontSize == 12)
assert(RXP.colors == theme and RXP.RXPFrame.backdrop.edge.edgeSize == 1)
-- The native renderer applies these shared backdrops to guide panels, pooled
-- active steps, step-number badges and the Active Targets title/body.
for _, key in ipairs({'edge', 'guideName', 'bottom'}) do
    local backdrop = guide.backdrop[key]
    local expected = key == 'bottom' and 0 or backdrop.edgeSize
    for _, side in ipairs({'left', 'right', 'top', 'bottom'}) do
        assert(backdrop.insets[side] == expected, 'fill detached from border: ' .. key .. '/' .. side)
    end
end
step:SetBackdrop(guide.backdrop.edge); step.number:SetBackdrop(guide.backdrop.edge); flush()
assert(step:GetBackdrop().insets.left == 1 and step.number:GetBackdrop().insets.bottom == 1)

local v2 = RXP.v2:GetTheme()
assert(v2 ~= source2 and v2.backgroundColors ~= source2.backgroundColors)
assert(source2.backgroundColors.common[1] == 1 and v2.mapPins == source2.mapPins and v2.navigationArrow == 'arrow')
local window = RXP.v2:GetGuideWindow(); flush()
assert(window.banner.alpha == 0 and guideCreates == 1)
window.banner:SetAlpha(1); assert(window.banner.alpha == 0, 'banner alpha lock missing')
local target = frame(); target.protected = true; target.title = frame()
target.title.text = {GetObjectType = function() return 'FontString' end}
local action = frame('Button'); action.protected = true
function action:SetAttribute() error('secure target attributes changed') end
target.children = {action}
local targetUpdates = 0
function target:UpdateVisuals()
    assert(not combat, 'target visuals changed in combat')
    targetUpdates = targetUpdates + 1
    self:SetBackdrop({edgeFile = 'old'})
    self.title:SetBackdrop({edgeFile = 'old'})
end
lazyTarget = target
combat = true
RXP.targeting:CreateTargetFrame(); flush()
assert(targetUpdates == 0, 'target updates must wait until combat ends')
combat = false
combatEvents.hooks.OnEvent(); flush()
assert(targetUpdates > 0 and target.borderColor[1] == 0.055 and target.title.borderColor[1] == 0.055)
target:UpdateVisuals(); assert(target.borderColor[1] == 0.055, 'target border flashed before deferred refresh'); flush(); assert(target.borderColor[1] == 0.055, 'target tint lost after native redraw')
RXP.settings.profile.hideActiveTargetsBackground = true
function target:UpdateVisuals() targetUpdates = targetUpdates + 1; self:SetBackdrop(nil) end
modules.RXPGuides.refresh(); flush()
assert(target:GetBackdrop() == nil, 'skin restored a hidden target background')
-- Routine combat endings must not rerender native themes; dirty changes do.
local callsBeforeIdle = originalCalls
combatEvents.hooks.OnEvent(); flush()
assert(originalCalls == callsBeforeIdle, 'idle combat end refreshed RXP theme')
combat = true
modules.RXPGuides.refresh(); flush()
assert(originalCalls == callsBeforeIdle, 'theme updated during combat')
combat = false
combatEvents.hooks.OnEvent(); flush()
assert(originalCalls == callsBeforeIdle + 1, 'combat-deferred theme lost')
local originalTheme = {frame = {1, 0, 0}}
ForeverDungeonJournal_NS = {THEMES = {dungeon = originalTheme}, ToggleJournal = function()
    local root = frame(); root.rightPanel = frame()
    local portrait = region(12345, 'ARTWORK'); root.rightPanel.regions = {portrait}
    root.portrait = portrait
    local close = frame('Button')
    function close:GetParent() return root end
    function close:GetPoint() return 'TOPRIGHT', root, 'TOPRIGHT', -3, -3 end
    function close:GetNormalTexture() return region(123456, 'ARTWORK') end
    local closeClicks = 0
    close.onClick = function() closeClicks = closeClicks + 1 end
    root.close, root.closeClicks = close, function() return closeClicks end
    root.children = {root.rightPanel, close}
    root.dungeonMapArtHolder = frame(); root.dungeonMapArtHolder.children = {frame('EditBox')}
    root.children[#root.children + 1] = root.dungeonMapArtHolder
    ForeverDungeonJournalFrame = root
    return nil, 'journal-tail'
end}
modules.ForeverDungeonJournal.install(S, modules.ForeverDungeonJournal); flush()
assert(shells == 0, 'journal skin created a window eagerly')
local missing, result = ForeverDungeonJournal_NS.ToggleJournal(); flush()
assert(missing == nil and result == 'journal-tail')
assert(ForeverDungeonJournalFrame.shellOptions.noTopBar, 'journal header must keep a continuous background')
assert(ForeverDungeonJournalFrame.portrait.alpha == 0.8, 'boss portrait faded')
assert(ForeverDungeonJournalFrame.close.euiClose, 'numeric-texture close button missed')
ForeverDungeonJournalFrame.close.onClick(); assert(ForeverDungeonJournalFrame.closeClicks() == 1, 'close action lost')
assert(edits == 1, 'map contents must not be scanned')
local icon = region('Interface\\Icons\\INV_Misc_Book_09', 'ARTWORK')
ForeverDungeonJournalSettings = frame(); ForeverDungeonJournalSettings.regions = {icon}
modules.ForeverDungeonJournal.refresh(); flush()
assert(icon.alpha == 0.8, 'settings icon faded')
local previous = shells
modules.ForeverDungeonJournal.refresh(); flush(); assert(shells == previous, 'shell faded twice')
for _, fn in ipairs(looks) do fn() end; flush()
assert(RXP.settings.profile.activeTheme == 'Custom' and source2.font == 'original-v2')
enabled = false
local passthrough = RXP:LoadActiveTheme(); assert(passthrough == source, 'disabled theme wrapper still active')
assert(renders == 0, 'skin refresh must not reload guide content')
local r1, r2 = RXP.RenderFrame(); assert(r1 == nil and r2 == 'render-tail')
assert(originalCalls >= 2 and renders == 1)
-- Legacy chrome must also work when the guide root is implicitly protected.
local header = frame(); guide.GuideName = header
local function icon()
    local t = region('native-logo', 'ARTWORK')
    function t:ClearAllPoints() self.points = {} end
    function t:SetPoint(...) self.points = {...} end
    function t:SetSize(w, h) self.width, self.height = w, h end
    return t
end
header.icon, header.classIcon = icon(), icon()
S.SquareIcon = function(t) t.square = true end
local scrollbar = frame('Slider'); local thumb = icon()
function thumb:SetColorTexture(...) self.color = {...} end
scrollbar.GetThumbTexture = function() return thumb end
scrollbar.GetOrientation = function() return 'VERTICAL' end
guide.ScrollFrame = {ScrollBar = scrollbar}
guide.UpdateScrollBar = function() thumb.color = {1, 1, 1}; return 'scroll-native' end
guide.protected = true
enabled = true; modules.RXPGuides.refresh(); flush()
assert(header.icon.width == 28 and header.classIcon.width == 12 and header.icon.points[1] == 'TOPLEFT')
assert(header.icon.square and header.classIcon.square and thumb.color[1] == 0.1)
local scrollbarReturn = guide.UpdateScrollBar()
assert(scrollbarReturn == 'scroll-native' and thumb.color[1] == 0.1,
    'RXP scrollbar must skin before the callback returns: ' .. tostring(scrollbarReturn) .. '/' .. tostring(thumb.color[1]) .. '/' .. table.concat(errors, '\n'))
local thin = scrollbar.created[2]
assert(thin.width == 4 and thin.points[1][2] == thumb and thin.color[1] == 0.1)
thin.GetTexture = function() return "white" end
scrollbar.regions = {thin}
local created = #scrollbar.created
for _ = 1, 5 do guide.UpdateScrollBar() end
assert(#scrollbar.created == created and thin.color[1] == 0.1 and thin.alpha ~= 0, 'warm slider styling must retain the slim visual')
assert(thumb.alpha == 0 and not thumb.width, 'native thumb hit geometry must be preserved')
assert(#errors == 0, table.concat(errors, '\n'))
print('PASS: optional/lazy targets, legacy border/fill alignment and tint after redraw, Active Targets/combat/hidden backgrounds, numeric close texture and clicks, source/profile immutability, portraits/icons/maps, disable')
