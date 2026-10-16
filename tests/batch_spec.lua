local timers, errors, modules, looks, events = {}, {}, {}, {}, {}
local enabled, combat, accent = true, false, 0.3
local ns = {IsEnabled = function() return enabled end, AttachAccent = function(_, f) f.accent = true end}
function ns.RegisterModule(id, label, available, install) modules[id] = {available = available, install = install} end
C_Timer.After = function(_, fn) timers[#timers + 1] = fn end
C_AddOns = {IsAddOnLoaded = function() return false end}
InCombatLockdown = function() return combat end
geterrorhandler = function() return function(e) errors[#errors + 1] = e end end
hooksecurefunc = function(obj, key, callback)
    local original = obj[key]
    obj[key] = function(...)
        local values = table.pack(original(...)); callback(...); return table.unpack(values, 1, values.n)
    end
end
local function flush()
    local count = 0
    while #timers > 0 do
        local batch = timers; timers = {}; for _, fn in ipairs(batch) do fn() end
        count = count + 1; assert(count < 25, 'refresh loop')
    end
end
local function texture(kind)
    local t = {kind = kind or 'Texture', alpha = 1, path = 'Interface/Icons/test'}
    function t:GetObjectType() return self.kind end
    function t:GetAlpha() return self.alpha end
    function t:SetAlpha(a) self.alpha = a end
    function t:GetTexture() return self.path end
    function t:GetDrawLayer() return self.layer or 'ARTWORK' end
    function t:SetDrawLayer(layer) self.layer = layer end
    function t:SetColorTexture(...) self.color = {...} end
    function t:SetVertexColor(...) self.color = {...} end
    function t:SetPoint(...) self.points = {...} end
    function t:SetSize(w, h) self.width, self.height = w, h end
    function t:SetTexture(path) self.path = path end
    function t:SetAllPoints() end
    function t:SetHeight() end
    function t:SetWidth() end
    return t
end
local function frame(kind, name, parent)
    local f = {kind = kind or 'Frame', name = name, children = {}, regions = {}, hooks = {}, scripts = {}, shown = true, enabled = true, parent = parent}
    function f:GetObjectType() return self.kind end
    function f:GetName() return self.name end
    function f:GetParent() return self.parent end
    function f:ClearAllPoints() self.layoutPoint = nil end
    function f:SetPoint(...) self.layoutPoint = {...} end
    function f:SetSize(w, h) self.width, self.height = w, h end
    function f:GetFontString() return self.Text end
    function f:GetScript(key) return self.scripts[key] end
    function f:Enable() self.enabled = true end
    function f:Disable() self.enabled = false end
    function f:GetNormalTexture() return self.normal end
    function f:GetPoint() return self.point, self.parent, self.point, self.x, self.y end
    function f:IsProtected() return self.protected end
    function f:IsForbidden() return self.forbidden end
    function f:GetChildren() return table.unpack(self.children) end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:HookScript(k, fn) self.hooks[k] = fn end
    function f:SetScript(k, fn) self.scripts[k] = fn end
    function f:RegisterEvent(k) self.events = self.events or {}; self.events[k] = true end
    function f:GetBackdrop() return self.backdrop end
    function f:SetBackdrop(v) assert(not combat); self.backdrop = v end
    function f:IsShown() return self.shown end
    function f:IsEnabled() return self.enabled end
    function f:GetWidth() return 24 end
    function f:GetHeight() return 24 end
    function f:CreateTexture() local t = texture(); self.regions[#self.regions + 1] = t; return t end
    function f:SetFont(font) self.font = font end
    function f:GetFont() return 'original-font', 12 end
    function f:IsMultiLine() return self.multiline end
    if name then _G[name] = f end
    if parent then parent.children[#parent.children + 1] = f end
    return f
end
CreateFrame = function() local f = frame(); events[#events + 1] = f; return f end
local S = {GetAccentColor = function() return accent, 0.5, 0.6 end, GetFont = function() return 'eui-font', '' end,
    OnLooksChanged = function(fn) looks[#looks + 1] = fn end}
function S.Shell(f, options) f.shellOptions = options; assert(not combat and not f.protected); f.shell = true end
function S.Panel(f) assert(not f.protected); f.panel = true; for _, r in ipairs(f.regions) do if r.kind == 'Texture' then r:SetAlpha(0) end end end
function S.Button(f) assert(not f.protected); f.button = true end
function S.EditBox(f, opts) assert(not f.multiline); f.padded = opts.padInput; f.inputOptions = opts end
function S.Checkbox(f) assert(not f.name or not f.name:match('ItemRackOptInv')); f.checkSkin = true end
function S.Tab(f) f.tab = true end
function S.SetTabSelection(f, v) f.selected = v end
function S.SquareIcon(t, f) t.square = true; t.border = f end
function S.ScrollBar(f) f.scroll = true end
function S.CloseButton(f) f.close = true end
function S.PageButton(f, g) f.glyph = g end
function S.ApplyBarFill(f) f.fill = true end
function S.Font(t, r, g, b) t.fontColor = {r, g, b} end
function S.StateButtonLabel() end
function S.FadeNineSlice(f) f.faded = true end
function S.Dropdown(f) f.drop = true end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins', ns)
assert(loadfile('EUIAddonSkins/Scoped.lua'))('EUIAddonSkins', ns)
local ids = {'WhatsTraining', 'ItemRack', 'KiwiFarm', 'Myslot', 'BugSack', 'Altoholic', 'Attune'}
for _, id in ipairs(ids) do _G[id] = nil end
WhatsTrainingFrame = nil
local lib = nil
LibStub = function(name) if name == 'Myslot-5.0' then return lib end end
for _, id in ipairs(ids) do
    assert(loadfile('EUIAddonSkins/Skins/' .. id .. '.lua'))('EUIAddonSkins', ns)
    assert(not modules[id].available(), 'target must be optional: ' .. id)
end
ItemRack = {ToggleOptions = function() return 'options' end}
ItemRackOpt = {TabOnClick = function() end}
KiwiFarm = frame('Frame', 'KiwiFarm')
PanelTemplates_SelectTab = function() end
PanelTemplates_DeselectTab = function() end
BugSack = {OpenSack = function()
    BugSackFrame = frame('Frame', 'BugSackFrame')
    BugSackFrame.Portrait = BugSackFrame:CreateTexture(); BugSackFrame.Portrait.path = 133642
    BugSackFrame.TitleContainer = frame('Frame', nil, BugSackFrame)
    BugSackFrame.caption = frame('Button', nil, BugSackFrame.TitleContainer)
    BugSackFrame.caption.Text = texture('FontString'); BugSackFrame.caption.regions = {BugSackFrame.caption.Text}
    BugSackFrame.caption.scripts.OnDoubleClick = function() return 'native-search' end
    local tab = frame('Button', 'BugSackTabSession', BugSackFrame)
    PanelTemplates_SelectTab(tab)
    local close = frame('Button', 'BatchNumericClose', BugSackFrame)
    close.point, close.x, close.y = 'TOPRIGHT', -3, -3
    close.scripts.OnClick = function() return 'close-original' end
    return 99
end}
Altoholic = {}
Attune = {}
WhatsTrainingFrame = frame('Frame', 'WhatsTrainingFrame')
local host = frame(); host.children = {WhatsTrainingFrame}
local unrelated = frame('Button', nil, host); unrelated.Text = texture('FontString')
WhatsTrainingFrame.Refresh = function() return 'original-refresh' end
local spellRow = frame('Button', nil, WhatsTrainingFrame)
spellRow.spell = {icon = texture(), label = texture('FontString')}; spellRow.statusColor = {1, 0, 0}
spellRow.scripts.OnClick = function() return 'spell-original' end
lib = {MainFrame = frame()}
local exportText = frame('EditBox', nil, lib.MainFrame); exportText.multiline = true; exportText.content = 'encoded-profile'
local input = frame('EditBox', nil, lib.MainFrame)
ItemRackOptFrame = frame('Frame', 'ItemRackOptFrame')
ItemRackOptTab1 = frame('Button', 'ItemRackOptTab1', ItemRackOptFrame); ItemRackOptTab1.enabled = false
local inv = frame('CheckButton', 'ItemRackOptInv1', ItemRackOptFrame)
ItemRackOptInv1Icon = texture(); inv.regions = {ItemRackOptInv1Icon}
local selectedSet = frame('CheckButton', 'ItemRackOptSetsCurrentSet', ItemRackOptFrame)
ItemRackOptSetsCurrentSetIcon = texture(); selectedSet.regions = {ItemRackOptSetsCurrentSetIcon}
local configRow = frame('Button', 'ItemRackOptList1', ItemRackOptFrame)
local configLabel = texture('FontString'); configLabel.layer = 'BACKGROUND'; configRow.regions = {configLabel}
configRow.GetFontString = function() return configLabel end
local secure = frame('Button', nil, ItemRackOptFrame); secure.protected = true; secure.attributes = {macro = 'equip'}
AltoholicFrame = frame('Frame', 'AltoholicFrame'); AltoholicFrame.Tabs = {frame('Button', nil, AltoholicFrame)}; AltoholicFrame.selectedTab = 1
AltoholicFrame.SwitchToTab = function() return 'tab-original' end
Attune_MainFrame = frame('Frame', 'Attune_MainFrame')
Attune_GraphRoot = frame('Frame', 'Attune_GraphRoot', Attune_MainFrame)
local graphButton = frame('Button', nil, Attune_GraphRoot); graphButton.Text = texture('FontString')
AttuneQuestDetail = frame('Frame', 'AttuneQuestDetail'); AttuneQuestDetail.map = frame('Frame', nil, AttuneQuestDetail)
local pin = frame('Button', nil, AttuneQuestDetail.map); pin.Text = texture('FontString')
local check = frame('Frame', nil, Attune_MainFrame)
check.obj = {frame = check, type = 'CheckBox', checkbg = texture(), check = texture(), text = texture('FontString'), SetType = function() end, SetDisabled = function(self, v) self.disabled = v end}
local progress = frame('StatusBar', nil, Attune_MainFrame)
for _, id in ipairs(ids) do assert(modules[id].available()); modules[id].install(S, modules[id]) end
flush()
assert(WhatsTrainingFrame.shellOptions.noBorder and WhatsTrainingFrame.shellOptions.noTopBar, 'Whats Training soft shell missing')
assert(KiwiFarm.shellOptions.noBorder and KiwiFarm.shellOptions.noTopBar, 'KiwiFarm soft shell missing')
assert(lib.MainFrame.shellOptions.noBorder and lib.MainFrame.shellOptions.bottomBar == 38 and input.inputOptions.noBorder, 'Myslot soft shell/input missing')
assert(input.padded and exportText.font == 'eui-font' and exportText.content == 'encoded-profile' and not exportText.padded)
assert(inv.regions[1].square and not inv.checkSkin and secure.attributes.macro == 'equip')
assert(ItemRackOptTab1.tab and ItemRackOptTab1.selected)
assert(ItemRackOptSetsCurrentSetIcon.square and not selectedSet.checkSkin)
assert(configLabel.layer == 'OVERLAY' and not configRow.button)
assert(AltoholicFrame.Tabs[1].selected)
assert(spellRow.spell.icon.square and spellRow.statusColor[1] == 1 and spellRow.scripts.OnClick() == 'spell-original' and not unrelated.button)
assert(not graphButton.button and not pin.button and progress.fill)
assert(check.obj.check.color[1] == accent)
accent = 0.8; for _, fn in ipairs(looks) do fn() end; flush(); assert(check.obj.check.color[1] == 0.8)
check.obj:SetDisabled(true); flush(); assert(check.obj.check.color[1] == 0.5)
check.obj:SetDisabled(false); flush(); assert(check.obj.check.color[1] == 0.8)
assert(BugSack:OpenSack() == 99); flush(); assert(BugSackFrame.shell and not BugSackFrame.accent and BugSackFrame.shellOptions.noAccent)
assert(BugSackTabSession.selected and BatchNumericClose.close and BatchNumericClose.scripts.OnClick() == 'close-original')
assert(BugSackFrame.shellOptions.noBorder, 'BugSack must use the scoped soft window style')
assert(not BugSackFrame.caption.button and BugSackFrame.caption.scripts.OnDoubleClick() == 'native-search')
assert(BugSackFrame.Portrait.alpha == 0, 'native protruding portrait remained visible')
local contained
for _, region in ipairs(BugSackFrame.regions) do if region ~= BugSackFrame.Portrait and region.path == 133642 then contained = region end end
assert(contained and contained.width == 28 and contained.height == 28 and contained.square)
assert(BugSackTabSession.layoutPoint[1] == 'BOTTOMLEFT' and BugSackTabSession.layoutPoint[5] == 8)
local bugNext = frame('Button', 'BugSackNextButton', BugSackFrame)
bugNext.Text = texture('FontString'); bugNext.Text.text = 'Next >'; bugNext.regions = {bugNext.Text}
bugNext.normal = bugNext:CreateTexture(); bugNext.normal.path = 'native-button-art'
bugNext.NineSlice = frame('Frame', nil, bugNext)
bugNext.scripts.OnClick = function() return 'native-next-shift-aware' end
modules.BugSack.refresh(); flush(); assert(not bugNext.glyph, 'navigation must keep its translated label without an extra arrow')
assert(bugNext.normal.alpha == 0 and bugNext.NineSlice.faded)
assert(bugNext.width == 110 and bugNext.height == 28 and bugNext.layoutPoint[5] == 44)
assert(bugNext.Text.text == 'Next >' and bugNext.scripts.OnClick() == 'native-next-shift-aware')
bugNext:Disable(); assert(bugNext.Text.fontColor[1] == 0.65)
bugNext:Enable(); assert(bugNext.Text.fontColor[1] == 1)
local nativeEnable = bugNext.Enable; local regionCount = #BugSackFrame.regions
for _ = 1, 20 do modules.BugSack.refresh(); flush() end
assert(not BugSackFrame.accent)
assert(bugNext.Enable == nativeEnable and #BugSackFrame.regions == regionCount, 'repeated BugSack refresh duplicated hooks or portraits')
local pooled = frame('EditBox', nil, BugSackFrame); BugSackFrame.hooks.OnShow(); flush(); assert(pooled.padded)
combat = true
ItemRackLogFrame = frame('Frame', 'ItemRackLogFrame'); modules.ItemRack.refresh(); flush(); assert(not ItemRackLogFrame.shell)
combat = false
for _, f in ipairs(events) do if f.events and f.events.PLAYER_REGEN_ENABLED then f.scripts.OnEvent(f, 'PLAYER_REGEN_ENABLED') end end
flush(); assert(ItemRackLogFrame.shell)
-- Scoped roots: a hidden root is not walked again until shown; showing it styles what changed.
function BugSackFrame:IsVisible() return self.shown end
BugSackFrame.shown = false
local hiddenInput = frame('EditBox', nil, BugSackFrame)
modules.BugSack.refresh(); flush(); assert(not hiddenInput.padded, 'hidden scoped root walked again')
BugSackFrame.shown = true; BugSackFrame.hooks.OnShow(); flush(); assert(hiddenInput.padded, 'shown scoped root not styled')
local visibleInput = frame('EditBox', nil, BugSackFrame)
modules.BugSack.refresh(); flush(); assert(visibleInput.padded, 'visible scoped root not walked')
enabled = false
ItemRackLogFrame = frame('Frame', 'ItemRackLogFrame'); modules.ItemRack.refresh(); flush(); assert(not ItemRackLogFrame.shell)
assert(#errors == 0, table.concat(errors, '\n'))
print('PASS: seven optional adapters, lazy/pooled controls, accents/AceGUI checks, multiline output, semantic icons/rows, native tabs, protected gear/map/graph, visible-only scoped roots, combat and disabled skins')
