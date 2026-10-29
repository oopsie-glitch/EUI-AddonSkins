-- Auctionator on the modern auction house: native tab row, EUI zone seams, results
-- washes, pooled rows/icons, money inputs, labels and warm idempotence.
-- Specs share one Lua state: drop the legacy AuctionFrame and earlier mocks.
for _, name in ipairs({'AuctionFrame', 'AuctionFrameTab1', 'AuctionFrameTab2', 'AuctionFrameTab3', 'LibStub',
    'AuctionatorTabs_Shopping', 'AuctionatorConfigLazyFrame', 'AuctionatorConfigLoadedFrame', 'AuctionatorDialog1',
    'AuctionatorTabContainerMixin', 'AuctionatorExportTextFrameMixin'}) do _G[name] = nil end
local timers, modules, events, created, looks, hookCount = {}, {}, {}, 0, {}, 0
local hierarchyReads, geometryWrites, colorWrites = 0, 0, 0
local enabled, combat, fontFace = true, false, 'eui-font'
local ns = {IsEnabled = function() return enabled end, AttachAccent = function() end}
function ns.RegisterModule(id, _, available, install) modules[id] = {available = available, install = install} end
C_Timer = {After = function(_, fn) timers[#timers + 1] = fn end}
InCombatLockdown = function() return combat end
geterrorhandler = function() return function(e) error(e) end end
NORMAL_FONT_COLOR = {GetRGB = function() return 1, 0.82, 0 end}
PixelUtil = {GetNearestPixelSize = function() return 0.5 end}
C_Texture = {GetAtlasInfo = function(atlas) return (atlas == 'UI-RefreshButton' or atlas == 'auctionhouse-itemicon-empty') and {} or nil end}
hooksecurefunc = function(obj, key, callback)
    hookCount = hookCount + 1
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
local function anchors(o)
    function o:ClearAllPoints() geometryWrites=geometryWrites+1;self.points = {} end
    function o:SetPoint(...) geometryWrites=geometryWrites+1;self.points = self.points or {}; self.points[#self.points + 1] = {...} end
    function o:GetNumPoints() return #(self.points or {}) end
    function o:GetPoint(i) return table.unpack(self.points[i]) end
    function o:SetAllPoints(rel) self.all = rel or true end
end
local function texture(layer, w, h)
    created = created + 1
    local t = {kind = 'Texture', layer = layer, alpha = 1, w = w or 16, h = h or 16, masks = {}}
    anchors(t)
    function t:GetPoint(i)
        if self.all then return 'TOPLEFT',self.all,'TOPLEFT',0,0 end
        local point=self.points and self.points[i]
        if not point then return end
        if type(point[2])=='number' then return point[1],self.parent,point[1],point[2],point[3] end
        return table.unpack(point)
    end
    function t:ClearAllPoints() geometryWrites=geometryWrites+1;self.points={};self.all=nil end
    function t:GetObjectType() return self.kind end
    function t:GetDrawLayer() return self.layer end
    function t:IsShown() return self.shown ~= false end
    function t:SetDrawLayer(layer) self.layer = layer end
    function t:GetTexture() return self.path end
    function t:SetTexture(p) self.path = p end
    function t:GetAtlas() return self.atlas end
    function t:SetAtlas(a) self.atlas = a end
    function t:SetColorTexture(...) colorWrites=colorWrites+1;self.color = {...} end
    function t:SetVertexColor(...) self.vertex = {...} end
    function t:GetVertexColor() return table.unpack(self.vertex or {1, 1, 1, 1}) end
    function t:SetDesaturated(v) self.desaturated = v end
    function t:SetAlpha(a) self.alpha = a end
    function t:GetAlpha() return self.alpha end
    function t:GetSize() return self.w, self.h end
    function t:SetSize(w, h) self.w, self.h = w, h end
    function t:GetHeight() return self.h end
    function t:SetHeight(h) self.h = h end
    function t:SetWidth(w) self.w = w end
    function t:SetShown(v) self.shown = v end
    function t:Hide() self.shown = false end
    function t:Show() self.shown = true end
    function t:SetTexCoord(...) self.crop = {...}; self.texCoordWrites=(self.texCoordWrites or 0)+1 end
    function t:GetNumMaskTextures() return #self.masks end
    function t:GetMaskTexture(i) return self.masks[i] end
    function t:AddMaskTexture(m) self.masks[#self.masks + 1] = m end
    function t:RemoveMaskTexture(m) for i, v in ipairs(self.masks) do if v == m then table.remove(self.masks, i) end end end
    return t
end
local function fontString(text, r, g, b)
    local fs = {text = text, color = {r or 1, g or 1, b or 1}}
    function fs:GetObjectType() return 'FontString' end
    function fs:GetText() return self.text end
    function fs:GetTextColor() return table.unpack(self.color) end
    function fs:SetTextColor(...) self.color = {...} end
    function fs:SetJustifyH(v) self.justifyH = v end
    function fs:SetJustifyV(v) self.justifyV = v end
    return fs
end
local function frame(kind, parent, name)
    created = created + 1
    local f = {kind = kind or 'Frame', children = {}, regions = {}, scripts = {}, shown = true, alpha = 1, w = 100, h = 24, name = name}
    anchors(f)
    function f:GetObjectType() return self.kind end
    function f:GetName() return self.name end
    function f:IsForbidden() return self.forbidden end
    function f:IsProtected() return self.protected end
    function f:GetParent() return self.parent end
    function f:GetChildren() hierarchyReads=hierarchyReads+1;return table.unpack(self.children) end
    function f:GetRegions() hierarchyReads=hierarchyReads+1;return table.unpack(self.regions) end
    function f:GetNumChildren() return #self.children end
    function f:GetNumRegions() return #self.regions end
    function f:GetFrameLevel() return 4 end
    function f:SetFrameLevel(v) self.level = v end
    function f:GetEffectiveScale() return 1 end
    function f:SetSize(w,h) geometryWrites=geometryWrites+1;self.w,self.h=w,h end
    function f:EnableMouse(value) self.mouse=value end
    function f:GetHeight() return self.h end
    function f:SetHeight(h) self.h = h end
    function f:GetWidth() return self.w end
    function f:SetWidth(w) self.w = w end
    function f:SetAlpha(a) self.alpha = a end
    function f:GetAlpha() return self.alpha end
    function f:IsShown() return self.shown end
    function f:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function f:SetHitRectInsets(...) self.hit = {...} end
    function f:HookScript(key, fn) local old = self.scripts[key]; self.scripts[key] = function(...) local r=old and table.pack(old(...))or{n=0}; fn(...);return table.unpack(r,1,r.n) end end
    function f:SetScript(key, fn) self.scripts[key] = fn end
    function f:RegisterEvent(e) self.events = self.events or {}; self.events[e] = true end
    function f:CreateTexture(_, layer)
        local t = texture(layer); t.parent=self; self.regions[#self.regions + 1] = t; return t
    end
    function f:CreateMaskTexture()
        local t = texture('BORDER'); t.kind='MaskTexture'
        self.regions[#self.regions+1]=t;return t
    end
    function f:GetFontString() return self.label end
    function f:GetNormalTexture() return self.normal end
    function f:SetJustifyH(v) self.justifyH = v end
    function f:SetJustifyV(v) self.justifyV = v end
    function f:SetTextInsets(...) self.insets = {...}; self.insetWrites = (self.insetWrites or 0) + 1 end
    function f:GetID() return self.id end
    function f:GetLeft() return self.l end
    function f:GetRight() return self.r end
    function f:GetTop() return self.t end
    function f:GetBottom() return self.b end
    if parent then f.parent = parent; parent.children[#parent.children + 1] = f end
    return f
end
CreateFrame = function(kind, name, parent)
    local f = frame(kind, parent, name)
    if name then _G[name] = f end
    if not parent then events[#events + 1] = f end
    return f
end
local S = {OnLooksChanged = function(fn) looks[#looks + 1] = fn end}
function S.Shell(f) f.shell = true end
function S.Panel(f, opts) f.panel = true; f.panelOptions = opts end
function S.Inset(f)
    f.inset = true
    for _, region in ipairs(f.regions) do
        if region.kind == 'Texture' then region:SetAlpha(0) end
    end
end
function S.Tab(f, opts)
    if not f.tab then f.plate = f:CreateTexture(nil, 'BACKGROUND') end
    f.tab = true; if opts and opts.darkActive then f.darkActive = true end
end
function S.SetTabSelection(f, v) f.selected = v end
function S.EditBox(f, opts)
    if f.input then return end -- Public primitive is idempotent.
    f.input = (f.input or 0) + 1; f.soft = f.soft or (opts and opts.noBorder)
    -- Like the engine: strip template art, including unnamed coin textures.
    for _, region in ipairs(f.regions) do if region.kind == 'Texture' then region:SetAlpha(0) end end
end
function S.Button(f, keepKeys)
    f.button = true
    -- Model EUI's texture strip and theme registry; item art must be kept.
    local keep = {}; for _, key in ipairs(keepKeys or {}) do keep[f[key] or false] = true end
    f.keepKeys = keepKeys
    for _, region in ipairs(f.regions) do
        if region.kind == 'Texture' and not keep[region] then region:SetAlpha(0) end
    end
end
function S.ScrollBar(f) f.scroll = true end
function S.SquareIcon(icon, owner) icon.square = (icon.square or 0) + 1; icon.owner = owner end
function S.White(fs) fs.color = {1, 1, 1} end
function S.GetAccentColor() return 0.1, 0.8, 0.6 end
function S.Dropdown(f) f.dropdown = true end
function S.GetFont() return fontFace, '' end
function S.Font(f, r, g, b)
    f.fontFace = fontFace; f.fontWrites = (f.fontWrites or 0) + 1
    if r then f:SetTextColor(r, g, b) end
end
for _, key in ipairs({'FadeNineSlice', 'CloseButton', 'Checkbox', 'StateButtonLabel', 'PageButton'}) do S[key] = function() end end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins', ns)
assert(loadfile('EUIAddonSkins/Skins/Auctionator.lua'))('EUIAddonSkins', ns)

-- Blizzard's modern host with its tab row and EUI's zone-seam host.
AuctionHouseFrame = frame()
local host = AuctionHouseFrame
host.SetDisplayMode = function(self, mode) self.mode = mode end
host.Tabs = {frame('Button', host), frame('Button', host), frame('Button', host)}
local zone = frame('Frame', host)
-- Wrong-layer lookalike must never be mistaken for EUI's private seam host.
local lookalike = frame('Frame', host)
lookalike.regions = {texture('BACKGROUND', 900, 1), texture('BACKGROUND', 900, 1)}
frame('Frame', lookalike); frame('Frame', lookalike)
-- Put the lookalike first to exercise the fallback guard.
host.children[#host.children], host.children[4] = host.children[4], host.children[#host.children]
zone.regions = {texture('ARTWORK', 900, 1), texture('ARTWORK', 900, 1)}
frame('Frame', zone); frame('Frame', zone)
-- Auctionator's panels, tabs and controls.
Auctionator = {Tabs = {State = {knownTabs = {{name = 'Shopping', tabFrameName = 'AuctionatorShoppingFrame'},
    {name = 'Selling', tabFrameName = 'AuctionatorSellingFrame'},
    {name = 'Cancelling', tabFrameName = 'AuctionatorCancellingFrame'}}}}}
AuctionatorSellingFrame = frame('Frame', host); local selling = AuctionatorSellingFrame
AuctionatorShoppingFrame = frame('Frame', host); local shopping = AuctionatorShoppingFrame
-- Cancelling's refresh: icon set by file ID (no name to match), Auctionator's own button art.
AuctionatorCancellingFrame = frame('Frame', host); AuctionatorCancellingFrame.shown = false
local cancelRefresh = frame('Button', AuctionatorCancellingFrame)
cancelRefresh.Icon = cancelRefresh:CreateTexture(nil, 'ARTWORK'); cancelRefresh.Icon:SetTexture(1121272)
cancelRefresh.normal = cancelRefresh:CreateTexture(nil, 'BACKGROUND')
-- An icon-only button elsewhere is not a refresh button.
local listIcon = frame('Button', shopping); listIcon.Icon = listIcon:CreateTexture(nil, 'ARTWORK')
AuctionatorAHTabsContainer = {Tabs = {}}
for _, view in ipairs({shopping, selling}) do
    local tab = frame('Button'); tab.frameRef = view; view.shown = false
    table.insert(AuctionatorAHTabsContainer.Tabs, tab)
end
local shoppingTab, sellingTab = table.unpack(AuctionatorAHTabsContainer.Tabs)
selling.BagInset = frame('Frame', selling); selling.HistoricalPriceInset = frame('Frame', selling)
local spinner = selling.HistoricalPriceInset:CreateTexture(nil, 'OVERLAY')
local sale = frame('Frame', selling); selling.SaleItemFrame = sale
sale.regions = {fontString('Quantity'), fontString('24'), fontString('Deposit:', 1, 0.82, 0)}
sale.Quantity = frame('Frame', sale)
local quantity = frame('EditBox', sale.Quantity); sale.Quantity.InputBox = quantity
quantity.insets = {0, 0, 8, 0}; quantity.fontFace = 'native-number-font'
quantity.value = 37
sale.Quantity.GetNumber = function() return quantity.value end
-- Also retain support for the direct EditBox used by older layouts.
local older = frame('Frame', sale); older.Quantity = frame('EditBox', older)
local durationLabels = {}
for _, hours in ipairs({2, 8, 24}) do
    local choice = frame('Frame', sale); choice.isAuctionatorRadio = true
    choice.RadioButton = frame('CheckButton', choice)
    local button = choice.RadioButton
    button.GetChecked = function() return false end
    button.SetChecked = function() end
    button.Label = fontString(tostring(hours)); anchors(button.Label)
    button.regions[#button.regions + 1] = button.Label
    durationLabels[#durationLabels + 1] = button.Label
end
local price = frame('Frame', sale); price.MoneyInput = frame('Frame', price); local moneyInput = price.MoneyInput
local function inputText(box)
    local text = fontString('0'); anchors(text)
    text:SetPoint('LEFT', box, 'LEFT', 6, 5) -- Independently offset template text.
    box.regions[#box.regions + 1] = text
    return text
end
local quantityText = inputText(quantity)
quantity.Label = fontString('Quantity'); anchors(quantity.Label)
quantity.Label:SetPoint('TOPRIGHT', quantity, 'TOPLEFT', -10, -4)
quantity.regions[#quantity.regions + 1] = quantity.Label
for _, key in ipairs({'GoldBox', 'SilverBox', 'CopperBox'}) do
    local box = frame('EditBox', moneyInput); moneyInput[key] = box
    box.insets = {0, 0, 8, 0}; box.fontFace = 'native-number-font'
    box.regions = {texture('BACKGROUND', 8, 20), texture('ARTWORK', 13, 13)}
    box.numericText = inputText(box)
    box.label = fontString('currency'); anchors(box.label)
    box.label:SetPoint('RIGHT', box, 'RIGHT', -4, 0)
    box.regions[#box.regions + 1] = box.label
end
local post = frame('Button', sale); post.label = fontString('Post')
moneyInput.CopperBox.l, moneyInput.CopperBox.r, moneyInput.CopperBox.t, moneyInput.CopperBox.b = 490, 546, 400, 360
post.l, post.t, post.b = 546, 400, 360
local refreshButton = frame('Button', sale); refreshButton.Icon = refreshButton:CreateTexture(nil, 'ARTWORK')
refreshButton.Icon:SetAtlas('UI-RefreshButton')
local bag = frame('Button', selling); bag.Icon = bag:CreateTexture(nil, 'ARTWORK'); bag.IconBorder = bag:CreateTexture(nil, 'OVERLAY')
bag.IconBorder:SetVertexColor(0.12, 1, 0, 1); bag.Icon:AddMaskTexture({})
bag.IconSelectedHighlight=bag:CreateTexture(nil,'BACKGROUND')
bag.IconSelectedHighlight:SetAtlas('bags-glow-artifact')
bag.EmptySlot=bag:CreateTexture(nil,'BACKGROUND')
local plain = frame('Button', selling); plain.Icon = plain:CreateTexture(nil, 'ARTWORK'); plain.IconBorder = plain:CreateTexture(nil, 'OVERLAY')
plain.IconBorder:SetVertexColor(1, 1, 1, 1)
local listing = frame('Frame', selling); listing.HeaderContainer = frame('Frame', listing)
listing.l, listing.r, listing.HeaderContainer.l, listing.HeaderContainer.r = 100, 600, 86, 600
local prices = frame('Frame', selling); prices:SetPoint('BOTTOMLEFT', selling, 'BOTTOMLEFT', 20, 0)
for index, key in ipairs({'CurrentPricesTab', 'PriceHistoryTab', 'YourHistoryTab'}) do
    prices[key] = frame('Button', prices); prices[key].id = index
end
prices.selectedTab = 1; prices.CurrentPricesTab.l = 105
local column = frame('Button', listing.HeaderContainer); column.label = fontString('Buyout Price', 1, 0.82, 0)
column.Middle = column:CreateTexture(nil, 'BACKGROUND')
listing.ScrollArea = frame('Frame', listing); local box = frame('Frame', listing.ScrollArea); listing.ScrollArea.ScrollBox = box
listing.ScrollArea.l, listing.ScrollArea.r = 95, 640; selling.CurrentPricesListing = listing
local scrollbar = frame('EventFrame', listing.ScrollArea); listing.ScrollArea.ScrollBar = scrollbar
scrollbar.Background = frame('Frame', scrollbar)
local cap = scrollbar:CreateTexture(nil, 'ARTWORK')
local trackChrome = scrollbar.Background:CreateTexture(nil, 'BACKGROUND')
scrollbar.nativeScroll = function() return 'native-scroll' end
-- An option widget: dropdown with its own arrow button, and a field reset button.
local widget = frame('Frame', sale); widget.DropDown = frame('Button', widget)
local arrow = frame('Button', widget.DropDown); arrow:CreateTexture(nil, 'ARTWORK')
widget.ResetButton = frame('Button', widget); widget.ResetButton:CreateTexture(nil, 'BACKGROUND')
widget.ResetButton.texture = widget.ResetButton:CreateTexture(nil, 'ARTWORK')
widget.ResetButton.texture.SetDrawLayer = function(self, layer) self.layer = layer end
local pool = {}
box.ForEachFrame = function(_, fn) for _, row in ipairs(pool) do fn(row) end end
box.Update = function() end
local function row()
    local r = frame('Button', box); r.cells = {}
    r.NormalTexture = r:CreateTexture(nil, 'BACKGROUND'); r.HighlightTexture = r:CreateTexture(nil, 'HIGHLIGHT')
    local cell = frame('Frame', r); cell.Icon = cell:CreateTexture(nil, 'BACKGROUND')
    cell.IconBorder = cell:CreateTexture(nil, 'BACKGROUND'); cell.IconBorder:SetAtlas('auctionhouse-itemicon-small-border')
    cell.Populate = function(self, data, index)
        self.rowData, self.index = data, index
        if data and data.iconTexture then self.Icon:SetTexture(data.iconTexture) end
        self.Icon:SetAlpha(data and data.noneAvailable and .5 or 1)
        return 'native-populate', nil, index
    end
    cell:Populate({itemKey={itemID=1}, iconTexture='item'}, 1)
    r.cells[1] = cell
    pool[#pool + 1] = r; return r
end
local qualities = {[1]=2}
ITEM_QUALITY_COLORS = {
    [0]={r=.62,g=.62,b=.62}, [1]={r=1,g=1,b=1}, [2]={r=.12,g=1,b=0},
    [3]={r=0,g=.44,b=.87}, [4]={r=.64,g=.21,b=.93}, [5]={r=1,g=.5,b=0},
    [6]={r=.9,g=.8,b=.5}, [7]={r=0,g=.8,b=1},
}
C_AuctionHouse = {GetItemKeyInfo=function(key)
    local q=qualities[key.itemID]; if q~=nil then return {quality=q} end
end}
C_Item = {GetItemInfo=function(link) return 'link-item', link, link=='known-link' and 4 or nil end}
local first = row()
shopping.ListsContainer = frame('Frame', shopping); shopping.ListsContainer.w = 326
for _, key in ipairs({'NewListButton', 'ImportButton', 'ExportButton'}) do shopping[key] = frame('Button', shopping) end
shopping.ExportButton:SetPoint('LEFT', shopping.ImportButton, 'RIGHT', 0, 0)
shopping.ShoppingResultsInset = frame('Frame', shopping)
-- Extended Search Options popup, with its form on an inset.
AuctionatorShoppingTabItemFrame = frame('Frame', host); AuctionatorShoppingTabItemFrame.Inset = frame('Frame', AuctionatorShoppingTabItemFrame)
shopping.SearchOptions = frame('Frame', shopping); shopping.SearchOptions:SetPoint('TOPLEFT', shopping, 'TOPLEFT', 0, -10)
shopping.SearchOptions.SearchString = frame('EditBox', shopping.SearchOptions); shopping.SearchOptions.SearchString.b = 60
local searchReset = frame('Button', shopping.SearchOptions)
shopping.SearchOptions.ResetSearchStringButton = searchReset
searchReset.texture = searchReset:CreateTexture(nil, 'ARTWORK')
searchReset.texture:SetTexture('Interface/Buttons/UI-Reset')
searchReset.normal = searchReset:CreateTexture(nil, 'BACKGROUND')
searchReset.click = function() return 'native-reset' end
shopping.ContainerTabs = frame('Frame', shopping)
shopping.ContainerTabs.ListsTab = frame('Button', shopping.ContainerTabs); shopping.ContainerTabs.ListsTab.t = 58
shopping.ContainerTabs.RecentsTab = frame('Button', shopping.ContainerTabs)

-- Existing Classic/Forever profession addition: the host and its recipe rows
-- belong to Blizzard/EUI, not this skin. Keep native colors, text and anchors.
local professionHost = frame('Frame')
local nativeRecipe = frame('Button', professionHost)
local function profession(name)
    local f = frame('Frame', professionHost, name); _G[name] = f
    f.Total = fontString('To Craft: |Tcoin:0|t\nProfit: |cffff0000-27|r', 1, 0.82, 0)
    f.regions = {f.Total}
    f.SearchButton = frame('Button', f); f.SearchButton.label = fontString('Search')
    f.SearchButton.scripts.OnClick = function(_, button) return 'native-search', button end
    f:SetPoint('TOPLEFT', professionHost, 'TOPLEFT', 205, -6)
    return f
end
local existingProfession = profession('AuctionatorCraftingInfo')
local existingOrders = profession('AuctionatorCraftingInfoProfessionsOrderFrame')
local originalProfessionPoints = existingProfession.points
Auctionator.CraftingInfo = {
    Initialize = function() return 'already initialized' end,
    InitializeProfessionsFrame = function()
        local f = profession('AuctionatorCraftingInfoProfessionsFrame')
        f.CustomQuantity = frame('Frame', f); f.CustomQuantity.shown = false
        f.CustomQuantity.Quantity = frame('Frame', f.CustomQuantity)
        local input = frame('EditBox', f.CustomQuantity.Quantity)
        f.CustomQuantity.Quantity.InputBox = input
        input.Label = fontString('Quantity'); input.value = 7
        f.CustomQuantity.SearchButton = frame('Button', f.CustomQuantity)
        f.CustomQuantity.SearchButton.scripts.OnClick = function() return input.value end
        return f, 'native-initialized'
    end,
    InitializeCustomerOrdersFrame = function() return profession('AuctionatorTradeSkillSearch') end,
}
Auctionator.EnchantInfo = {Initialize = function() return profession('AuctionatorEnchantInfoFrame') end}

modules.Auctionator.install(S, modules.Auctionator); flush()
assert(existingProfession.SearchButton.button and existingProfession.Total.fontFace == fontFace)
assert(existingOrders.SearchButton.button)
assert(existingProfession.Total.color[1] == 1 and existingProfession.Total.color[2] == 0.82)
assert(existingProfession.Total.text:find('|Tcoin:0|t', 1, true) and existingProfession.Total.text:find('|cffff0000-27|r', 1, true))
assert(existingProfession.points == originalProfessionPoints and not existingProfession.shell)
assert(not professionHost.shell and not nativeRecipe.button, 'walked or shelled the native profession host')
-- Tabs: styled, chained a physical pixel after Blizzard's last tab, Blizzard row left alone.
assert(shoppingTab.tab and sellingTab.tab and shoppingTab.h == 22)
assert(shoppingTab.points[1][2] == host.Tabs[3] and shoppingTab.points[1][4] == 0.5)
assert(sellingTab.points[1][2] == shoppingTab and shoppingTab.hit[1] == 0)
assert(shoppingTab.selected == false and host.Tabs[1].selected == nil and zone.alpha == 1)
-- Opening an Auctionator tab: it reads active, Blizzard's row and EUI's seams step aside.
selling.shown = true; host:SetDisplayMode({}); flush()
assert(sellingTab.selected and not shoppingTab.selected)
assert(host.Tabs[1].selected == false and host.Tabs[3].selected == false and zone.alpha == 0)
assert(lookalike.alpha == 1, 'unrelated host child was faded')
selling.shown = false; host:SetDisplayMode('buy'); flush()
assert(sellingTab.selected == false and zone.alpha == 1, 'Blizzard tab did not restore seams')
-- Panels: tab content is not shelled; results zones washed and edged, side lists clear.
assert(not selling.shell and not shopping.shell)
-- Insets stay clear (artwork kept); each table washes its own row area, edged on top and left.
assert(selling.HistoricalPriceInset.inset and #selling.HistoricalPriceInset.children == 0 and spinner.alpha == 1)
local area = listing.ScrollArea
local wash = area.children[#area.children]
assert(area.inset and wash ~= box and wash.regions[1].color[4] == 0.02 and wash.regions[2].h == 0.5 and wash.regions[3].w == 0.5)
-- Option widgets: dropdown skinned and its arrow button cleared; reset icon kept above the block.
assert(widget.DropDown.dropdown and arrow.regions[1].alpha == 0)
local resetPlate = widget.ResetButton.regions[1] ~= widget.ResetButton.texture and widget.ResetButton.regions[1]
assert(not widget.ResetButton.button and widget.ResetButton.texture.layer == 'OVERLAY' and widget.ResetButton.texture.alpha == 1)
assert(resetPlate and resetPlate.alpha == 0, 'reset button kept its plate')
assert(selling.BagInset.inset and #selling.BagInset.children == 0 and shopping.ShoppingResultsInset.inset)
assert(scrollbar.scroll and cap.alpha == 0 and trackChrome.alpha == 0 and scrollbar.nativeScroll() == 'native-scroll')
cap:SetAlpha(1); trackChrome:SetAlpha(1)
assert(cap.alpha == 0 and trackChrome.alpha == 0, 'scrollbar chrome returned after redraw')
-- Header row: strip spans the table's row area (95..640 against a 86..600 header row).
local strip = listing.HeaderContainer.regions[1]
assert(strip.points[1][4] == 9 and strip.points[2][4] == 40 and strip.color[4] == 0.5)
assert(column.Middle.alpha == 0 and not column.button and column.label.color[2] == 1)
-- Rows: Blizzard art faded, white washes, square cell icons; pooled rows on Update.
assert(first.NormalTexture.alpha == 0 and first.HighlightTexture.color[4] == 0.1 and first.cells[1].Icon.square == 1)
local second = row(); box:Update()
assert(second.HighlightTexture.color[4] == 0.1 and second.cells[1].Icon.square == 1)
-- Money: coins kept, boxes slimmer, copper narrower; quantity centered; labels gold.
local gold = moneyInput.GoldBox
assert(gold.regions[2].alpha == 1 and gold.h == 19 and moneyInput.CopperBox.w == 96, 'copper still touches Post')
assert(moneyInput.GoldBox.w == 100, 'boxes without a flush neighbour were narrowed')
assert(quantity.justifyH == 'CENTER' and quantity.insets[1] == 0)
assert(quantity.justifyV == 'MIDDLE' and quantity.insets[3] == 0 and quantity.insets[4] == 0)
assert(quantity.fontFace == fontFace, 'quantity kept the native number font')
assert(not sale.Quantity.input and sale.Quantity.GetNumber() == 37, 'quantity wrapper/actions were changed')
assert(older.Quantity.justifyH == 'CENTER', 'direct quantity input support was lost')
assert(quantityText.points[1][1] == 'TOPLEFT' and quantityText.points[1][5] == 0
    and quantityText.points[2][1] == 'BOTTOMRIGHT' and quantityText.points[2][5] == 0
    and quantityText.justifyV == 'MIDDLE', 'quantity text retained its independent vertical offset')
assert(quantity.Label.points[1][1] == 'TOPRIGHT' and quantity.Label.points[1][5] == -4,
    'quantity field label was mistaken for its numeric text')
for _, key in ipairs({'GoldBox', 'SilverBox', 'CopperBox'}) do
    local input = moneyInput[key]
    assert(input.justifyH == 'RIGHT' and input.justifyV == 'MIDDLE' and input.fontFace == fontFace)
    assert(input.insets[1] == 6 and input.insets[2] == 20 and input.insets[3] == 0 and input.insets[4] == 0,
        'money text did not clear the native coin or vertical template padding')
    assert(input.numericText.points[1][4] == 6 and input.numericText.points[1][5] == 0
        and input.numericText.points[2][4] == -20 and input.numericText.points[2][5] == 0
        and input.numericText.justifyH == 'RIGHT' and input.numericText.justifyV == 'MIDDLE',
        'money text retained its independent template anchor')
    assert(input.label.points[1][1] == 'RIGHT' and input.label.points[1][4] == -4,
        'native currency-symbol label was moved')
end
for _, label in ipairs(durationLabels) do
    assert(label.fontFace == fontFace and #label.points == 1 and label.points[1][1] == 'LEFT')
    assert(label.points[1][3] == 'RIGHT' and label.points[1][4] == 4 and label.points[1][5] == 0,
        'duration label not centered beside its radio button')
end
assert(sale.regions[1].color[2] == 0.82 and sale.regions[2].color[2] == 1)
-- Refresh: white house glyph, original art faded.
local cancelGlyph = cancelRefresh.regions[#cancelRefresh.regions]
assert(cancelGlyph.atlas == 'UI-RefreshButton' and cancelGlyph.desaturated, 'panel refresh by file ID not glyphed')
assert(cancelRefresh.Icon.alpha == 0 and cancelRefresh.normal.alpha == 0, 'panel refresh kept its button art')
assert(listIcon.Icon.alpha ~= 0 and listIcon.regions[#listIcon.regions] == listIcon.Icon, 'non-refresh icon button glyphed')
assert(refreshButton.Icon.alpha == 0 and refreshButton.regions[2].atlas == 'UI-RefreshButton' and refreshButton.regions[2].desaturated)
-- Bag icons: unmasked, inset, re-squared when the pooled button refills.
assert(#bag.Icon.masks == 1 and bag.Icon.points[1][2] == 2 and bag.IconBorder.alpha == 1 and plain.IconBorder.alpha == 1)
assert(not bag.euiQualityTop and not plain.euiQualityTop, 'redundant rarity overlays created')
bag.Icon:AddMaskTexture({}); bag.Icon:SetAllPoints(bag); bag.Icon:SetTexture('next-item')
assert(#bag.Icon.masks == 1 and bag.Icon.points[1][2] == 2 and bag.Icon.square >= 2, 'pooled icon not repaired')
-- Shopping buttons: three equal widths, 4px apart, inside the lists column.
assert(shopping.NewListButton.w == 106 and shopping.ImportButton.w == 106 and shopping.ExportButton.w == 106)
assert(shopping.NewListButton.points[1][2] == shopping.ListsContainer and #shopping.ExportButton.points == 1)
assert(shopping.ImportButton.points[1][2] == shopping.NewListButton and shopping.ExportButton.points[1][4] == 4)
-- Selling's price tabs are flat and their row lines up with the results zone.
assert(prices.points[1][4] == 10, 'price tabs not aligned with the zone')
-- Search row lifted until 6px clear of the list tabs.
assert(shopping.SearchOptions.points[1][5] == -6, 'search row still on the list tabs')
assert(searchReset.texture.alpha == 1 and searchReset.normal.alpha == 0 and not searchReset.button)
assert(searchReset.click() == 'native-reset', 'search reset action replaced')
-- The popup is shelled; its form inset stays clear, no card of its own.
local popupInset = AuctionatorShoppingTabItemFrame.Inset
assert(AuctionatorShoppingTabItemFrame.shell and popupInset.inset and not popupInset.panel, 'popup form not plain')
-- Bordered EUI controls inside the modern auction house, not the soft variant.
assert(not gold.soft and not quantity.soft, 'soft borderless inputs inside the modern auction house')
assert(prices.CurrentPricesTab.plate.alpha == 0 and not prices.CurrentPricesTab.darkActive)
assert(prices.CurrentPricesTab.selected and prices.PriceHistoryTab.selected == false)
-- Warm refreshes: no new UI objects and no repeated resizing.
local before, hooksBefore = created, hookCount
for _ = 1, 10 do modules.Auctionator.refresh(); flush() end
assert(created == before, 'warm refresh created UI objects')
assert(hookCount == hooksBefore, 'warm refresh duplicated secure hooks')
assert(quantity.insetWrites == 1 and moneyInput.GoldBox.insetWrites == 1, 'warm refresh changed numeric layout repeatedly')
assert(gold.h == 19 and moneyInput.CopperBox.w == 96 and shoppingTab.h == 22 and shopping.ExportButton.w == 106)
assert(prices.points[1][4] == 10 and shopping.SearchOptions.points[1][5] == -6, 'warm refresh shifted again')
-- A theme restrip must not remove loading art from the foreground.
selling.shown = true; spinner:SetAlpha(0)
fontFace = 'new-eui-font'
for _, fn in ipairs(looks) do fn() end; flush()
assert(spinner.alpha == 1, 'theme refresh lost foreground artwork')
assert(quantity.fontFace == fontFace and moneyInput.GoldBox.fontFace == fontFace
    and durationLabels[1].fontFace == fontFace, 'numeric fonts did not follow theme change')
assert(quantityText.fontFace == fontFace and moneyInput.GoldBox.numericText.fontFace == fontFace,
    'numeric text regions did not follow theme change')
selling.shown = false
-- Layout work is deferred in combat; regeneration applies it once.
local combatTab = frame('Button'); combatTab.frameRef = frame('Frame', host); combatTab.frameRef.shown = false
table.insert(AuctionatorAHTabsContainer.Tabs, combatTab)
combat = true; modules.Auctionator.refresh(); flush(); assert(not combatTab.tab)
combat = false
for _, eventFrame in ipairs(events) do
    if eventFrame.events and eventFrame.events.PLAYER_REGEN_ENABLED then eventFrame.scripts.OnEvent(eventFrame, 'PLAYER_REGEN_ENABLED') end
end
flush(); assert(combatTab.tab, 'combat-deferred tab did not skin')
-- Hidden panels are not walked again until shown; showing one skins what changed meanwhile.
local lateButton = frame('Button', shopping); lateButton.label = fontString('Late')
modules.Auctionator.refresh(); flush()
assert(not lateButton.button, 'hidden panel walked on a warm refresh')
shopping.shown = true; shopping.scripts.OnShow(shopping); flush()
assert(lateButton.button, 'shown panel not skinned')
shopping.shown = false; modules.Auctionator.refresh(); flush()
-- EUI's auction house on Blizzard art (off / Blizzard / Classic look): Auctionator stays stock too.
EllesmereUI = {GetBlizzWindowStyle = function(key) assert(key == 'auctionhouse'); return 'off' end}
local lateTab = frame('Button'); lateTab.frameRef = frame('Frame', host); lateTab.frameRef.shown = false; table.insert(AuctionatorAHTabsContainer.Tabs, lateTab)
local lateInset = frame('Frame', selling); selling.ShoppingResultsInset = lateInset
modules.Auctionator.refresh(); flush()
assert(not lateTab.tab and not lateInset.inset, 'skinned inside a stock auction house')
EllesmereUI.GetBlizzWindowStyle = function() return 'blizzard' end; modules.Auctionator.refresh(); flush()
assert(not lateTab.tab, 'skinned under the Blizzard window style')
selling.shown = true
EllesmereUI.GetBlizzWindowStyle = function() return 'modern' end; modules.Auctionator.refresh(); flush()
assert(lateTab.tab and lateInset.inset, 'EUI auction house style did not skin')
selling.shown = false; modules.Auctionator.refresh(); flush()
EllesmereUI = nil
-- Without the refresh atlas on the client, a refresh button keeps its native art.
C_Texture = {GetAtlasInfo = function() return nil end}
local bare = frame('Button', AuctionatorCancellingFrame); bare.Icon = bare:CreateTexture(nil, 'ARTWORK'); bare.Icon:SetTexture(1121272)
AuctionatorCancellingFrame.shown = true; modules.Auctionator.refresh(); flush()
assert(bare.Icon.alpha == 1 and #bare.regions == 1, 'refresh button blanked without its atlas')
AuctionatorCancellingFrame.shown = false; C_Texture = nil; modules.Auctionator.refresh(); flush()
-- Profession windows created after activation are painted by initializer
-- post-hooks synchronously; return values/actions and the hidden popup survive.
local lateProfession, nativeResult = Auctionator.CraftingInfo.InitializeProfessionsFrame()
assert(nativeResult == 'native-initialized' and lateProfession.SearchButton.button)
local popup = lateProfession.CustomQuantity
local quantity = popup.Quantity.InputBox
assert(popup.shell and not popup.shown and quantity.input and quantity.value == 7)
assert(popup.SearchButton.scripts.OnClick() == 7)
local searchResult, mouseButton = lateProfession.SearchButton.scripts.OnClick(nil, 'RightButton')
assert(searchResult == 'native-search' and mouseButton == 'RightButton')
assert(Auctionator.CraftingInfo.Initialize() == 'already initialized')
assert(Auctionator.CraftingInfo.InitializeCustomerOrdersFrame().SearchButton.button)
assert(Auctionator.EnchantInfo.Initialize().SearchButton.button)
-- A newly replaced control is picked up on show, without walking native rows.
lateProfession.SearchButton = frame('Button', lateProfession)
lateProfession.scripts.OnShow(lateProfession)
assert(lateProfession.SearchButton.button and not nativeRecipe.button)
-- Warm refreshes reuse hooks/UI objects and do not write EditBox fonts again.
local objectCount, hooks, writes = created, hookCount, quantity.fontWrites
for _ = 1, 20 do modules.Auctionator.refresh(); flush() end
assert(created == objectCount and hookCount == hooks and quantity.fontWrites == writes)
fontFace = 'profession-theme-font'; for _, fn in ipairs(looks) do fn() end; flush()
assert(quantity.fontFace == fontFace and existingProfession.Total.fontFace == fontFace)
assert(existingProfession.Total.color[2] == 0.82 and quantity.value == 7)
-- Auction-house style settings do not gate independent profession additions.
EllesmereUI = {GetBlizzWindowStyle = function() return 'off' end}
local stockProfession = Auctionator.EnchantInfo.Initialize()
assert(stockProfession.SearchButton.button); EllesmereUI = nil
local savedAH = AuctionHouseFrame; AuctionHouseFrame = nil
assert(Auctionator.EnchantInfo.Initialize().SearchButton.button, 'profession controls require an auction-house frame')
AuctionHouseFrame = savedAH
-- Load-on-demand initializer methods are discovered on ADDON_LOADED.
Auctionator.CraftingInfo.InitializeObjectiveTrackerFrame = function() return profession('AuctionatorCraftingInfoObjectiveTrackerFrame') end
for _, f in ipairs(events) do if f.events and f.events.ADDON_LOADED then f.scripts.OnEvent(f, 'ADDON_LOADED') end end
flush()
local orders = Auctionator.CraftingInfo.InitializeObjectiveTrackerFrame()
assert(orders.SearchButton.button)
combat = true
local combatProfession = Auctionator.EnchantInfo.Initialize()
assert(not combatProfession.SearchButton.button)
combat = false
for _, f in ipairs(events) do if f.events and f.events.PLAYER_REGEN_ENABLED then f.scripts.OnEvent(f, 'PLAYER_REGEN_ENABLED') end end
flush(); assert(combatProfession.SearchButton.button)
-- Disabled: no further work.
enabled = false; selling.shown = true; host:SetDisplayMode({}); flush()
assert(zone.alpha == 1 and sellingTab.selected == false, 'disabled skin repainted')
local disabledProfession = Auctionator.EnchantInfo.Initialize()
assert(not disabledProfession.SearchButton.button, 'disabled profession skin repainted')
for _, name in ipairs({'AuctionatorCraftingInfo', 'AuctionatorCraftingInfoProfessionsFrame', 'AuctionatorEnchantInfoFrame',
    'AuctionatorTradeSkillSearch', 'AuctionatorCraftingInfoObjectiveTrackerFrame', 'AuctionatorCraftingInfoProfessionsOrderFrame'}) do _G[name] = nil end
print('PASS: Auctionator modern tabs/zones/rows/icons/form alignment, owned profession additions and quantity popup, native actions/colors/placement, late initialization, warm reuse, theme/combat/toggle guards and visible-only rescans')

-- Auctionator Options > AddOns: fixed visual sizes independent of the native
-- CheckButton's large template rectangle. Native hit/label/click geometry stays.
enabled=true
local page=CreateFrame('Frame','AuctionatorConfigTooltipsFrame')
local function Checkbox(parent)
 local f=frame('CheckButton',parent);f:SetSize(32,32)
 f.checked=true;f.enabled=true
 f.GetChecked=function(self)return self.checked end
 f.SetChecked=function(self,v)self.checked=v;return 'native-set'end
 f.IsEnabled=function(self)return self.enabled end
 f.Enable=function(self)self.enabled=true;return 'native-enable'end
 f.Disable=function(self)self.enabled=false;return 'native-disable'end
 f.normal=f:CreateTexture(nil,'BACKGROUND');f.normal:SetTexture('native-box')
 f.tick=f:CreateTexture(nil,'ARTWORK');f.tick:SetTexture('native-yellow-tick')
 f.label=fontString('Show auction house value of items in tooltips');anchors(f.label)
 f.label:SetPoint('LEFT',f,'RIGHT',20,0);f.regions[#f.regions+1]=f.label
 f.scripts.OnClick=function(self)self.checked=not self.checked;return 'native-click'end
 return f
end
local option=Checkbox(page);local labelPoints=option.label.points
local foreign=Checkbox(frame('Frame'))
local secret=Checkbox(page);secret.protected=true
for _,eventFrame in ipairs(events)do
 if eventFrame.events and eventFrame.events.ADDON_LOADED then eventFrame.scripts.OnEvent(eventFrame,'ADDON_LOADED','Auctionator')end
end
flush()
assert(#option.children==1 and #foreign.children==0 and #secret.children==0)
local visual=option.children[1]
assert(visual.w==22 and visual.h==22 and visual.mouse==false and option.w==32 and option.h==32)
assert(option.normal.alpha==0 and option.tick.alpha==0 and option.label.points==labelPoints)
local mark
for _,art in ipairs(visual.regions)do if art.w==8 and art.h==8 then mark=art end end
assert(mark and mark.shown and mark.color[1]==.1 and mark.color[2]==.8)
assert(option.scripts.OnClick(option)=='native-click'and not mark.shown)
assert(option:SetChecked(true)=='native-set'and mark.shown)
assert(option:Disable()=='native-disable'and mark.color[1]==.4)
assert(option:Enable()=='native-enable'and mark.color[1]==.1)
local c,h,reads,geo,colors=created,hookCount,hierarchyReads,geometryWrites,colorWrites
for _=1,1000 do option:SetChecked(true);option:Enable();option.scripts.OnShow(option)end
assert(created==c and hookCount==h and hierarchyReads==reads and geometryWrites==geo and colorWrites==colors)
assert(#timers==0,'checkbox state callbacks queued full integration refreshes')
for _=1,50 do option.scripts.OnClick(option)end
assert(mark.shown==option.checked and #timers==0)
combat=true;option:SetChecked(false);assert(mark.shown)
combat=false
for _,eventFrame in ipairs(events)do
 if eventFrame.events and eventFrame.events.PLAYER_REGEN_ENABLED then eventFrame.scripts.OnEvent(eventFrame,'PLAYER_REGEN_ENABLED')end
end
flush();assert(not mark.shown)
S.GetAccentColor=function()return .7,.2,.9 end
for _,fn in ipairs(looks)do fn()end;flush();assert(mark.color[1]==.7)
enabled=false;option:SetChecked(true);assert(not mark.shown and #timers==0)
enabled=true;option.scripts.OnShow(option);assert(mark.shown)
print('PASS: Auctionator settings compact square indicators, unchanged native hit/label/action/state, protected/foreign exclusions, theme/combat/disabled guards')
print('BENCH Auctionator settings mock: 1000 warm check/enable/show cycles: new UI objects/hooks, hierarchy reads, geometry/colour writes and queued full refreshes=0')


-- Auctionator 341: Groups/ViewItem, ItemKeyCell:Populate and BuyIconName:SetItem.
do
    selling.shown, shopping.shown = true, true
    local cell = first.cells[1]
    local function matches(border, quality)
        local r,g,b,a=border:GetVertexColor(); local c=ITEM_QUALITY_COLORS[quality]
        return r==c.r and g==c.g and b==c.b and a==1 and border:IsShown() and border.alpha==1
    end
    -- Native selling path owns selected/empty visibility and count/tier overlays.
    bag.ProfessionQualityOverlay = bag:CreateTexture(nil,'OVERLAY')
    bag.Text = fontString('17'); bag.regions[#bag.regions+1]=bag.Text
    bag.SetItemInfo = function(self, info)
        self.itemInfo=info
        if info then
            self.Icon:SetTexture(info.iconTexture)
            self.Icon:SetAlpha(info.selected and .8 or 1)
            local c=ITEM_QUALITY_COLORS[info.quality]
            self.IconBorder:SetVertexColor(c.r,c.g,c.b,1)
            self.IconBorder:SetShown(not info.selected)
            self.IconSelectedHighlight:SetShown(info.selected)
            self.Text.text=tostring(info.count)
        else
            self.IconBorder:Hide(); self.Icon:Hide(); self.Text.text=''
        end
        return 'native-item'
    end
    -- Both purchase forms and their dialogs use this same native header.
    local purchase=frame('Frame',shopping)
    purchase.Icon=purchase:CreateTexture(nil,'ARTWORK')
    purchase.QualityBorder=purchase:CreateTexture(nil,'ARTWORK')
    purchase.QualityBorder:SetTexture('Interface/Common/WhiteIconFrame')
    purchase.SetItem=function(self, quality)
        self.Icon:SetTexture('purchase-icon')
        local c=ITEM_QUALITY_COLORS[quality]
        self.QualityBorder:SetVertexColor(c.r,c.g,c.b,1)
        return 'native-purchase'
    end
    modules.Auctionator.refresh();flush()
    assert(matches(cell.IconBorder,2),'first populated result lost its native border')
    assert(cell.IconBorder.atlas=='auctionhouse-itemicon-small-border' and cell.IconBorder.layer=='OVERLAY')
    local atlas, points, width, height=cell.IconBorder.atlas,cell.Icon.points,cell.w,cell.h
    for quality=0,7 do
        qualities[1]=quality
        local a,b,index=cell:Populate({itemKey={itemID=1},iconTexture='q'..quality,noneAvailable=true},quality)
        assert(a=='native-populate' and b==nil and index==quality)
        assert(matches(cell.IconBorder,quality),'result rarity missing: '..quality)
        assert(cell.Icon.alpha==.5,'native unavailable fade changed')
        assert(bag:SetItemInfo({quality=quality,iconTexture='bag',count=17})=='native-item')
        assert(matches(bag.IconBorder,quality),'selling rarity missing: '..quality)
        assert(purchase:SetItem(quality)=='native-purchase' and matches(purchase.QualityBorder,quality))
    end
    assert(cell.Icon.points==points and cell.w==width and cell.h==height and cell.IconBorder.atlas==atlas)
    bag:SetItemInfo({quality=4,iconTexture='selected',selected=true,count=12})
    modules.Auctionator.refresh();flush()
    assert(not bag.IconBorder:IsShown() and bag.IconSelectedHighlight:IsShown() and bag.Icon.alpha==.8)
    assert(bag.Text.text=='12' and bag.ProfessionQualityOverlay.alpha==1)
    bag:SetItemInfo(nil);assert(not bag.IconBorder:IsShown() and bag.Text.text=='')
    cell:Populate({itemKey={itemID=999}},1);assert(not cell.IconBorder:IsShown(),'stale rarity on uncached item')
    qualities[999]=3
    cell:Populate({itemKey={itemID=999}},1);assert(matches(cell.IconBorder,3),'late native data not reflected')
    cell:Populate({itemLink='known-link'},1);assert(matches(cell.IconBorder,4),'item-link fallback failed')
    cell:Populate({},1);assert(not cell.IconBorder:IsShown())
    cell:Populate(nil,1);assert(not cell.IconBorder:IsShown())
    local api=C_AuctionHouse;C_AuctionHouse=nil
    cell:Populate({itemKey={itemID=1},itemLink='known-link'},1);assert(matches(cell.IconBorder,4))
    C_AuctionHouse=api
    -- New pooled cells, same-count replacement, shrink/reopen and native resets.
    local replacement=row();pool[1]=replacement;pool[2]=nil;pool[3]=nil
    box:Update();local reused=replacement.cells[1]
    assert(matches(reused.IconBorder,7) and not reused.euiQualityTop)
    reused.IconBorder:SetVertexColor(1,0,0,1)
    reused:Populate({itemKey={itemID=1}},1);assert(matches(reused.IconBorder,7))
    -- Warm population is local: no objects, hooks, scans, geometry writes or timers.
    local c,h,reads,geo=created,hookCount,hierarchyReads,geometryWrites
    for i=1,1000 do
        qualities[1]=i%8;reused:Populate({itemKey={itemID=1}},i)
        assert(matches(reused.IconBorder,i%8))
    end
    assert(created==c and hookCount==h and hierarchyReads==reads and geometryWrites==geo and #timers==0)
    enabled=false;qualities[1]=4;reused:Populate({itemKey={itemID=1}},1)
    assert(matches(reused.IconBorder,0),'disabled skin still updated rarity')
    enabled=true;combat=true;reused:Populate({itemKey={itemID=1}},1)
    assert(matches(reused.IconBorder,0),'combat paint was not deferred')
    combat=false
    for _,eventFrame in ipairs(events)do
        if eventFrame.events and eventFrame.events.PLAYER_REGEN_ENABLED then
            eventFrame.scripts.OnEvent(eventFrame,'PLAYER_REGEN_ENABLED')
        end
    end
    flush();assert(matches(reused.IconBorder,4))
    EllesmereUI={GetBlizzWindowStyle=function()return 'blizzard'end}
    qualities[1]=3;reused:Populate({itemKey={itemID=1}},1);assert(matches(reused.IconBorder,4))
    EllesmereUI.GetBlizzWindowStyle=function()return 'modern'end
    bag:SetItemInfo({quality=0,iconTexture='poor',count=1})
    purchase:SetItem(1)
    for _,fn in ipairs(looks)do fn()end;flush()
    -- Simulate EUI reapplying its recorded Button keep list during a theme pass.
    assert(not bag.button, 'selling item registered as an EUI text button')
    assert(matches(bag.IconBorder,0) and matches(purchase.QualityBorder,1) and matches(reused.IconBorder,3))
    assert(not bag.euiQualityTop and bag.Text.text=='1' and bag.ProfessionQualityOverlay.alpha==1)
    print('PASS: Auctionator native rarity borders: all eight qualities, selling/purchase native state, pooled/late/missing result data, native returns, theme, combat/disabled/stock guards')
    print('BENCH Auctionator rarity mock: 1000 populated result cells: new UI objects/hooks, hierarchy reads, geometry writes and queued refreshes=0')
end


-- EUI 9.7 Skin_AuctionHouse keeps GiantItemButton's socket and inset ring.
do
    local previousTextureAPI=C_Texture
    C_Texture={GetAtlasInfo=function(atlas)return atlas=='auctionhouse-itemicon-empty' and {} or nil end}
    local function item(parent, size)
        local f=frame('Button',parent);f:SetSize(size,size)
        f.Icon=f:CreateTexture(nil,'BACKGROUND');f.IconBorder=f:CreateTexture(nil,'OVERLAY')
        f.EmptySlot=f:CreateTexture(nil,'BACKGROUND');f.EmptySlot:SetTexture('old-empty-slot')
        -- Source/Groups/ViewItem.xml crops the old 64px sprite sheet.
        f.EmptySlot:SetTexCoord(0,.640625,0,.640625)
        f.IconSelectedHighlight=f:CreateTexture(nil,'BACKGROUND')
        f.IconSelectedHighlight:SetAtlas('bags-glow-artifact');f.IconSelectedHighlight:SetVertexColor(.977,.592,.086,1)
        f.ProfessionQualityOverlay=f:CreateTexture(nil,'OVERLAY')
        f.Text=fontString('5');f.regions[#f.regions+1]=f.Text
        f:SetPoint('TOPLEFT',parent,'TOPLEFT',15,-20)
        f.SetItemInfo=function(self,info)
            self.itemInfo=info
            if info then
                self.Icon:SetTexture(info.iconTexture);self.Icon:Show()
                local c=ITEM_QUALITY_COLORS[info.quality]
                self.IconBorder:SetVertexColor(c.r,c.g,c.b,1)
                self.IconBorder:SetShown(not info.selected)
                self.IconSelectedHighlight:SetShown(info.selected)
                self.Icon:SetAlpha(info.selected and .8 or 1)
                self.Text.text=tostring(info.count)
            else
                self.Icon:Hide();self.IconBorder:Hide();self.IconSelectedHighlight:Hide();self.Text.text=''
            end
            return 'native-item',nil,9
        end
        f.scripts.OnClick=function()return 'native-click'end
        f.scripts.OnReceiveDrag=function()return 'native-drag'end
        return f
    end
    local large=item(sale,60)
    sale.Icon=large -- Actual SaleItemFrame.Icon identity, not every selling slot.
    -- Selected-sale subclass has native special handling after base SetItemInfo.
    local baseSet=large.SetItemInfo
    large.SetItemInfo=function(self,info)
        local a,b,c=baseSet(self,info)
        self.IconSelectedHighlight:Hide();self.IconBorder:SetShown(info~=nil);self.Icon:SetAlpha(1)
        return a,b,c
    end
    large:SetItemInfo(nil)
    local inventory=item(selling,40)
    local foreign=item(frame('Frame',shopping),40)
    local position=large.points
    modules.Auctionator.refresh();flush()
    assert(not large.button and not inventory.button and foreign.button)
    assert(large.EmptySlot.atlas=='auctionhouse-itemicon-empty' and large.EmptySlot.all==large and large.EmptySlot.alpha==1)
    assert(large.IconBorder.all==large.Icon and large.IconBorder.layer=='OVERLAY')
    assert(large.Icon.owner==nil and inventory.Icon.owner==nil,'extra EUI BorderRegion requested')
    assert(large.Icon.points[1][2]==2 and large.Icon.points[2][2]==-2 and large.w==60 and large.h==60 and large.points==position)
    assert(#large.Icon.masks==1 and large.Icon.masks[1].path=='Interface\\Common\\common-iconmask')
    assert(large.Icon.masks[1].all==large.Icon)
    assert(inventory.IconSelectedHighlight.path=='Interface\\Common\\WhiteIconFrame')
    local function fullPreview()
        local uv=large.EmptySlot.crop
        assert(uv and uv[1]==0 and uv[2]==1 and uv[3]==0 and uv[4]==1,
            'preview retained the legacy crop instead of the full AH atlas region')
    end
    fullPreview()
    assert(not large.Icon:IsShown() and large.EmptySlot:IsShown() and not large.IconBorder:IsShown())
    assert(large.EmptySlot.texCoordWrites==2, 'preview crop should be corrected once at setup')
    assert(inventory.EmptySlot.crop[2]==.640625 and foreign.EmptySlot.crop[2]==.640625,
        'preview correction changed inventory/foreign texture coordinates')
    assert(large.EmptySlot.layer=='BACKGROUND' and large.IconBorder.all==large.Icon)
    local socket=large.EmptySlot
    local mask=large.Icon.masks[1]
    local c,h,reads,geo=created,hookCount,hierarchyReads,geometryWrites
    for i=1,1000 do
        local a,b,index=large:SetItemInfo({quality=i%8,iconTexture='updated',selected=true,count=i})
        inventory:SetItemInfo({quality=i%8,iconTexture='inventory',selected=i%2==0,count=i})
        assert(a=='native-item' and b==nil and index==9)
        assert(large.IconBorder:IsShown() and not large.IconSelectedHighlight:IsShown())
        fullPreview();assert(large.EmptySlot==socket)
        assert(inventory.IconSelectedHighlight:IsShown()==(i%2==0))
    end
    assert(created==c and hookCount==h and hierarchyReads==reads and geometryWrites==geo and #timers==0)
    assert(large.Icon.masks[1]==mask and #large.Icon.masks==1 and large.Text.text=='1000')
    assert(socket.texCoordWrites==2, 'item updates repeated the preview UV correction')
    assert(large.scripts.OnClick()=='native-click' and large.scripts.OnReceiveDrag()=='native-drag')
    assert(large.ProfessionQualityOverlay.alpha==1)
    large:SetItemInfo(nil);assert(not large.IconBorder:IsShown() and large.Text.text=='' and not large.Icon:IsShown() and socket:IsShown());fullPreview()
    large:SetItemInfo({quality=3,iconTexture='new-item',count=2});assert(large.IconBorder:GetVertexColor()==0);fullPreview()
    -- Native geometry/mask resets are repaired locally with one retained mask.
    large.Icon:SetAllPoints(large);large.Icon:AddMaskTexture({})
    assert(large.Icon.points[1][2]==2 and #large.Icon.masks==1 and large.Icon.masks[1]==mask)
    for _,fn in ipairs(looks)do fn()end;flush()
    assert(large.EmptySlot.alpha==1 and large.IconBorder.all==large.Icon and not large.button);fullPreview()
    -- Geometry changed while disabled or in combat is repaired at recovery.
    enabled=false;large.Icon:SetAllPoints(large);enabled=true
    modules.Auctionator.refresh();flush();assert(large.Icon.points[1][2]==2 and large.Icon.all==nil)
    combat=true;large.Icon:SetAllPoints(large)
    assert(large.Icon.all==large)
    combat=false
    for _,eventFrame in ipairs(events)do
        if eventFrame.events and eventFrame.events.PLAYER_REGEN_ENABLED then eventFrame.scripts.OnEvent(eventFrame,'PLAYER_REGEN_ENABLED') end
    end
    flush();assert(large.Icon.all==nil and large.Icon.points[1][2]==2)
    -- No new style is applied to protected or disabled late slots.
    local secret=item(selling,40);secret.protected=true
    enabled=false;local disabled=item(selling,40)
    modules.Auctionator.refresh();flush();assert(not disabled.button and disabled.EmptySlot.atlas==nil)
    enabled=true;modules.Auctionator.refresh();flush()
    assert(secret.EmptySlot.atlas==nil and not secret.button and disabled.EmptySlot.atlas=='auctionhouse-itemicon-empty')
    -- Missing atlas/mask APIs retain a usable native border fallback.
    local noMask=item(selling,40);noMask.CreateMaskTexture=false
    modules.Auctionator.refresh();flush()
    assert(not noMask.button and noMask.EmptySlot.atlas=='auctionhouse-itemicon-empty' and noMask.Icon.owner==nil)
    C_Texture=nil
    local fallback=item(selling,40);fallback.CreateMaskTexture=false
    modules.Auctionator.refresh();flush();assert(fallback.button and fallback.IconBorder.alpha==1)
    C_Texture=previousTextureAPI
    print('PASS: Auctionator selling matches EUI retained GiantItemButton socket/inset ring: large and pooled inventory slots, local reset repair, selection/count/tier/actions, theme and protected/disabled/API fallbacks')
    print('BENCH Auctionator selling mock: 1000 large plus 1000 inventory updates: new UI objects/hooks, hierarchy reads, geometry writes and queued refreshes=0')
    print('PASS: Auctionator preview-only legacy UV crop reset: full atlas region on first empty display, selected/cleared states and theme refresh; inventory coordinates and rarity/layout unchanged')
end
