-- BtWQuests 2.65.0: source-shaped owned UI, pooled nodes and private menus.
local enabled, combat, accent, created = true, false, 0.2, 0
local timers, events, errors, looks, modules = {}, {}, {}, {}, {}
local factory, hookCount = nil, 0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'BtWQuests'); factory = fn end
ns.RegisterModule = function(id, _, available, install) modules[id] = {available = available, install = install} end
C_Timer = {After = function(_, fn) timers[#timers + 1] = fn end}
InCombatLockdown = function() return combat end
geterrorhandler = function() return function(e) errors[#errors + 1] = e end end
hooksecurefunc = function(obj, key, fn)
    hookCount = hookCount + 1
    local original = obj[key]
    obj[key] = function(...)
        local result = table.pack(original(...)); fn(...); return table.unpack(result, 1, result.n)
    end
end
local function flush()
    local rounds = 0
    while #timers > 0 do
        local batch = timers; timers = {}
        for _, fn in ipairs(batch) do fn() end
        rounds = rounds + 1; assert(rounds < 20, 'refresh loop')
    end
    assert(#errors == 0, table.concat(errors, '\n'))
end
local function texture(kind)
    created = created + 1
    local t = {kind = kind or 'Texture', alpha = 1, path = 'native', color = {0.1, 0.7, 0.2}}
    function t:GetObjectType() return self.kind end
    function t:IsForbidden() return false end
    function t:GetAlpha() return self.alpha end
    function t:SetAlpha(v) self.alpha = v end
    function t:GetTexture() return self.path end
    function t:SetTexture(v) self.path = v end
    function t:GetDrawLayer() return 'ARTWORK' end
    function t:SetColorTexture(...) self.color = {...} end
    function t:SetVertexColor(...) self.color = {...} end
    function t:SetWidth(v) self.width = v end
    function t:GetWidth() return self.width or 18 end
    function t:GetHeight() return 18 end
    function t:SetAllPoints(f) self.anchor = f end
    return t
end
local function frame(kind, parent)
    created = created + 1
    local f = {kind = kind or 'Frame', children = {}, regions = {}, hooks = {}, shown = true, width = 100, height = 24, parent = parent}
    function f:GetObjectType() return self.kind end
    function f:IsForbidden() return self.forbidden end
    function f:IsProtected() return self.protected end
    function f:GetChildren() return table.unpack(self.children) end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:GetParent() return self.parent end
    function f:HookScript(key, fn) local old = self.hooks[key]; self.hooks[key] = function(...) if old then old(...) end; fn(...) end end
    function f:SetScript(key, fn) self.hooks[key] = fn end
    function f:RegisterEvent(e) self.events = self.events or {}; self.events[e] = true end
    function f:SetBackdrop(v) assert(not combat); self.backdrop = v end
    function f:SetSize(w, h) self.width, self.height = w, h end
    function f:SetHeight(h) self.height = h end
    function f:GetWidth() return self.width end
    function f:GetHeight() return self.height end
    function f:ClearAllPoints() self.points = {} end
    function f:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = {...} end
    function f:GetNormalTexture() return self.normal end
    function f:GetFontString() return self.text end
    function f:IsShown() return self.shown end
    function f:CreateTexture() local t = texture(); self.regions[#self.regions + 1] = t; return t end
    function f:GetThumbTexture() return self.thumb end
    if kind ~= 'Slider' then f.GetThumbTexture = nil end
    if parent then parent.children[#parent.children + 1] = f end
    return f
end
CreateFrame = function(kind) local f = frame(kind); events[#events + 1] = f; return f end
local function region(f, key, kind)
    local t = texture(kind); f[key] = t; f.regions[#f.regions + 1] = t; return t
end
local function fade(f, keys)
    local keep = {}; for _, key in ipairs(keys or {}) do if f[key] then keep[f[key]] = true end end
    for _, r in ipairs(f.regions) do if r.kind == 'Texture' and not keep[r] then r:SetAlpha(0) end end
end
local S = {GetAccentColor = function() return accent, 0.5, 0.6 end, OnLooksChanged = function(fn) looks[#looks + 1] = fn end}
function S.Shell(f, opts) f.shell = opts; fade(f) end
function S.Panel(f, opts) f.panel = opts; fade(f) end
function S.Inset(f) f.inset = true; fade(f) end
function S.FadeNineSlice(f) f.faded = true end
function S.Button(f, keep) f.button = true; fade(f, keep) end
function S.Font(f, r, g, b) f.font = 'eui'; if r then f.color = {r, g, b} end end
function S.StateButtonLabel(f) f.stateLabel = true end
function S.Checkbox(f) f.checkbox = true end
function S.EditBox(f) f.edit = true end
function S.Dropdown(f) f.dropdown = true; fade(f) end
function S.ScrollBar(f) f.scroll = true end
function S.CloseButton(f) f.close = true end
function S.PageButton(f, glyph) f.glyph = glyph end
function S.SquareIcon(f) f.square = true end
function S.ApplyBarFill(f) f.fill = true end
BtWQuests, BtWQuestsFrame = nil, nil
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins', ns)
assert(loadfile('EUIAddonSkins/Skins/BtWQuests.lua'))('EUIAddonSkins', ns)
assert(factory and created == 0 and not modules.BtWQuests, 'definition did runtime work before activation')
factory(); assert(not modules.BtWQuests.available(), 'missing target not optional')
BtWQuests = {}
BtWQuestsFrame = frame(); local root = BtWQuestsFrame
root.CloseButton = frame('Button', root)
for _, key in ipairs({'NavBack', 'NavForward', 'NavHere', 'OptionsButton'}) do root[key] = frame('Button', root) end
root.OptionsButton.normal = region(root.OptionsButton, 'nativeIcon')
root.Inset = frame('Frame', root); region(root.Inset, 'Bg')
root.SearchBox = frame('EditBox', root)
root.ExpansionList = frame('Frame', root)
root.ExpansionList.Left = frame('Button', root.ExpansionList); root.ExpansionList.Right = frame('Button', root.ExpansionList)
local expansion = frame('Frame', root.ExpansionList)
region(expansion, 'Background'); region(expansion, 'Base'); region(expansion, 'Name', 'FontString')
expansion.AutoLoad = frame('CheckButton', expansion)
local expansionButton = frame('Button', expansion)
region(expansionButton, 'Active'); region(expansionButton, 'Subtext', 'FontString')
region(expansionButton, 'text', 'FontString')
root.Category = frame('Frame', root); root.Category.Scroll = frame('ScrollFrame', root.Category)
root.Category.Scroll.Child = frame('Frame', root.Category.Scroll)
root.Category.Scroll.ScrollBar = frame('Slider', root.Category.Scroll)
local bar = root.Category.Scroll.ScrollBar
bar.thumb = region(bar, 'thumb'); bar.thumb.height = 80; region(bar, 'trackBG')
root.Chain = frame('Frame', root); root.Chain.Scroll = frame('ScrollFrame', root.Chain)
root.Chain.Scroll.Child = frame('Frame', root.Chain.Scroll)
local canvas = root.Chain.Scroll.Child
local line = frame('Frame', canvas); local connector = region(line, 'line')
line.GetChildren = function() error('walked graph connector hierarchy') end
local function node()
    local f = frame('Button', canvas)
    for _, key in ipairs({'Icon', 'Cover', 'Tick', 'TagTexture', 'HeroicTexture', 'MythicTexture', 'ActiveTexture', 'IsNext'}) do region(f, key) end
    region(f, 'Name', 'FontString'); f.Name:SetAlpha(0.5)
    f.geometry = 'native-chain-position'; f.action = function() return 'quest-native' end
    f.Set = function(self) self.Icon:SetAlpha(1); return 'set-result', nil, 3 end
    f.Update = function(self) self.Name:SetAlpha(0.5); return 'update-result' end
    return f
end
local first = node()
root.Chain.Scroll.SetChain = function() node(); return 'chain-result' end
root.Chain.Scroll.Update = function() return 'graph-update' end
root.UpdateCurrentChain = function() return 'status-update' end
local function category()
    local f = frame('Button', root.Category.Scroll.Child)
    for _, key in ipairs({'Background', 'Tick', 'Major', 'Acive'}) do region(f, key) end
    region(f, 'Name', 'FontString'); region(f, 'Subtext', 'FontString')
    f.Set = function() return 'category-set' end
    f.action = function() return 'category-native' end
    return f
end
local card = category()
root.DisplayItemList = function() category(); return 'display-result' end
root.DisplayExpansionList = function() return 'expansion-result' end
root.DisplayCurrentChain = function() return 'current-chain' end
root.SearchPreview = frame('Frame', root); region(root.SearchPreview, 'bottomBorder')
root.SearchResults = frame('Frame', root); root.SearchResults.CloseButton = frame('Button', root.SearchResults)
local function result()
    local f = frame('Button', root.SearchPreview); f.link = 'chain:1'
    region(f, 'Name', 'FontString'); f.action = function() return 'search-native' end
    return f
end
root.SearchPreview.UpdateResults = function() result(); return 'results-native' end
root.SearchResults.UpdateSearch = function() return 'scroll-native' end
local menuCalls = 0
local function dropdown(parent)
    local f = frame('Frame', parent); region(f, 'Text', 'FontString'); region(f, 'Icon')
    f.Button = frame('Button', f); region(f.Button, 'normal')
    f.GetListFrame = function(self)
        menuCalls = menuCalls + 1
        if not self.list then
            self.list = frame('Button')
            self.list.Backdrop = frame('Frame', self.list); self.list.MenuBackdrop = frame('Frame', self.list)
            self.list.Backdrop.backdrop = {bgFile = 'native'}
        end
        return self.list
    end
    f.Open = function(self)
        local list = self:GetListFrame(); local row = frame('Button', list)
        for _, key in ipairs({'Check', 'UnCheck', 'Icon', 'Highlight'}) do region(row, key) end
        region(row, 'NormalText', 'FontString'); row.NormalText.color = {0.2, 0.6, 1}
        row.action = function() return 'menu-native' end
        return 'open-native'
    end
    return f
end
root.CharacterDropDown = dropdown(root)
BtWQuestsOptionsMenu = dropdown(); BtWQuestsOptionsMenu.displayMode = 'MENU'
local denied = frame('Button', root); denied.protected = true; region(denied, 'Name', 'FontString')
modules.BtWQuests.install(S, modules.BtWQuests); flush()
assert(root.shell.noBorder and root.Inset.inset and root.Inset.Bg.alpha == 0)
assert(root.NavBack.glyph == '<' and root.NavHere.glyph == '^' and root.NavBack.width == 22)
assert(root.CharacterDropDown.dropdown and root.CharacterDropDown.height == 22 and root.CharacterDropDown.Icon.alpha == 1)
assert(menuCalls == 0 and not BtWQuestsOptionsMenu.list, 'skin forced lazy menus to load')
assert(root.SearchBox.edit and root.SearchPreview.panel.noBorder and root.SearchResults.CloseButton.close)
assert(expansion.Base.alpha == 0 and expansion.Background.alpha == 1 and expansion.AutoLoad.checkbox)
assert(expansionButton.Active.alpha == 1 and expansionButton.Active.color[4] == 0.12
    and expansionButton.Active.anchor == expansionButton, 'expansion activity state was removed')
assert(root.ExpansionList.Left.height == 22, 'full-height page button became an opaque bar')
assert(bar.thumb.width == 4 and bar.thumb.height == 80 and bar.trackBG.alpha == 0)
assert(first.Icon.alpha == 0 and first.Cover.alpha == 0 and first.Tick.alpha == 1 and first.ActiveTexture.alpha == 1)
assert(first.Name.alpha == 0.5 and first.geometry == 'native-chain-position' and connector.alpha == 1)
assert(card.Background.alpha == 0 and card.Tick.alpha == 1 and card.Name.color[1] == 0.92)
assert(not denied.button and not denied.Name.font, 'protected control was changed')
local a, b, c = first:Set(); assert(a == 'set-result' and b == nil and c == 3 and first.Icon.alpha == 0)
assert(first:Update() == 'update-result' and first.Name.alpha == 0.5 and first.action() == 'quest-native')
assert(root:DisplayItemList() == 'display-result' and root.Category.Scroll.Child.children[2].button)
assert(root.Chain.Scroll:SetChain() == 'chain-result' and canvas.children[#canvas.children].button)
assert(root.SearchPreview:UpdateResults() == 'results-native')
local searchRow = root.SearchPreview.children[#root.SearchPreview.children]
assert(searchRow.button and searchRow.Name.color[1] == 0.92 and searchRow.action() == 'search-native')
assert(BtWQuestsOptionsMenu:Open() == 'open-native')
local list = BtWQuestsOptionsMenu.list; local row = list.children[#list.children]
assert(list.panel.noBorder and list.Backdrop.backdrop == nil and row.Highlight.color[4] == 0.08)
assert(row.Check.color[1] == accent and row.NormalText.color[3] == 1 and row.action() == 'menu-native')
local before, hooksBefore = created, hookCount
for _ = 1, 20 do modules.BtWQuests.refresh(); flush() end
assert(created == before and hookCount == hooksBefore, 'warm refresh allocated objects/hooks')
accent = 0.7; for _, fn in ipairs(looks) do fn() end; flush()
assert(row.Check.color[1] == accent, 'popup check did not track the accent')
combat = true; root:DisplayItemList()
local pending = root.Category.Scroll.Child.children[#root.Category.Scroll.Child.children]
assert(not pending.button, 'new combat control was modified')
combat = false; for _, event in ipairs(events) do if event.events and event.events.PLAYER_REGEN_ENABLED then event.hooks.OnEvent() end end; flush()
assert(pending.button, 'combat-deferred skin was lost')
enabled = false; root:DisplayItemList(); local off = root.Category.Scroll.Child.children[#root.Category.Scroll.Child.children]
modules.BtWQuests.refresh(); flush(); assert(not off.button, 'disabled skin processed new content')
assert(#errors == 0, table.concat(errors, '\n'))
-- Retail activation through the actual Core + Loader, not a direct installer.
-- Model the EUI callback, core completion and BtWQuests load boundaries.
for _, scenario in ipairs({'early', 'late', 'undispatched'}) do
    local live, callbacks, start = {}, {}, #events + 1
    local ownLoaded, targetLoaded = false, scenario ~= 'late'
    EUIAddonSkinsDB = {}; SlashCmdList = {}; DEFAULT_CHAT_FRAME = {AddMessage = function() end}
    UnitName = function() return 'RetailTester' end
    UnitGUID = function() return 'Player-Retail-Tester' end
    local clientInterface = scenario == 'undispatched' and 120007 or 120105
    GetBuildInfo = function() return 'test-retail', '12345', 'test', clientInterface end
    EUI_CLIENT_BLOCKED = scenario == 'undispatched' or nil
    C_AddOns = {
        GetAddOnInfo = function(name) if name == 'BtWQuests' then return name, 'BtWQuests', '', true end end,
        GetAddOnEnableState = function(name, character)
            assert(name == 'BtWQuests' and character == 'Player-Retail-Tester')
            return 2
        end,
        IsAddOnLoaded = function(name)
            return name == 'EUIAddonSkins' and ownLoaded or name == 'BtWQuests' and targetLoaded or false
        end,
        GetAddOnMetadata = function(name) return name == 'EllesmereUI' and '9.5.5' or '1.3.0' end,
        LoadAddOn = function() error('skin forced target to load') end,
    }
    EllesmereUI = {RegisterSkin = function(name, fn) assert(not callbacks[name]); callbacks[name] = fn end}
    BtWQuestsOptionsMenu = nil
    BtWQuestsFrame = targetLoaded and frame() or nil
    assert(loadfile('EUIAddonSkins/Core.lua'))('EUIAddonSkins', live)
    assert(loadfile('EUIAddonSkins/Loader.lua'))('EUIAddonSkins', live)
    assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins', live)
    assert(loadfile('EUIAddonSkins/Skins/BtWQuests.lua'))('EUIAddonSkins', live)
    local entry = live.skinCatalogByID.BtWQuests
    assert(callbacks['EUI AddonSkins - BtWQuests'] and not entry.loaded)
    if scenario ~= 'undispatched' then callbacks['EUI AddonSkins - BtWQuests'](S) end
    assert(not entry.loaded, 'activated before the core finished loading')
    local function fire(name, addon)
        for i = start, #events do
            local f = events[i]
            if f.events and f.events[name] then f.hooks.OnEvent(f, name, addon) end
        end
    end
    ownLoaded = true; fire('ADDON_LOADED', 'EUIAddonSkins'); fire('PLAYER_LOGIN')
    if scenario == 'late' then
        assert(not entry.loaded, 'unloaded BtWQuests activated')
        BtWQuestsFrame = frame(); targetLoaded = true; fire('ADDON_LOADED', 'BtWQuests')
    end
    local report = live.LoaderDiagnostics()
    assert(report:find('Client interface: ' .. clientInterface, 1, true) and report:find('EUI callback received', 1, true))
    if scenario == 'undispatched' then
        assert(not entry.loaded and not BtWQuestsFrame.shell and #live.modules == 0)
        assert(report:find('EUI client blocked: true', 1, true), 'upstream client gate was hidden')
    else
        assert(entry.loaded and entry.skin == S and live.modules[1].active and BtWQuestsFrame.shell,
            'Retail loader did not install the BtWQuests skin: ' .. scenario .. ' | ' .. report .. ' | ' .. table.concat(errors, '; '))
    end
end
EUI_CLIENT_BLOCKED = nil
assert(#errors == 0, table.concat(errors, '\n'))
print('PASS: BtWQuests UI/semantics/pooling/menu guards plus actual Retail core/loader activation in both load orders and unavailable EUI callback diagnostics')
