-- Standalone integration. No Forever Companion files or gameplay handlers are replaced.
local ADDON, ns = ...
-- Standalone skin addons receive their own namespace from WoW.
if ADDON ~= "EUIAddonSkins" then
    ns = EUIAddonSkins and EUIAddonSkins.GetSkinNamespace(ADDON)
    if not ns then return end
    ADDON = "EUIAddonSkins"
end
local API
local S, installed, moduleOwner
local unpack = unpack or table.unpack
local roots = setmetatable({}, { __mode = "k" })
local seen = setmetatable({}, { __mode = "k" })
local hooked = setmetatable({}, { __mode = "k" })
local paints = setmetatable({}, { __mode = "k" })
local tabs = setmetatable({}, { __mode = "k" })
local sideTabs = setmetatable({}, { __mode = "k" })
local pending, queued = {}, false
local Scan, Queue
local chromeWaiting
local failures = {}
local refreshMethods = { "ShowPage", "Render", "RenderList", "Update", "RefreshAll" }

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff0cd29fEUI AddonSkins:|r " .. msg)
end

local function Enabled()
    return S and not (EUIAddonSkinsDB and EUIAddonSkinsDB.disabled)
        and (not S.IsEnabled or S.IsEnabled())
end

local function Safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok and not failures[tostring(err)] then
        failures[tostring(err)] = true
        geterrorhandler()(ADDON .. ": " .. tostring(err))
    end
end

local function Allowed(f)
    return f and f.GetObjectType and not (f.IsForbidden and f:IsForbidden())
        and not (f.IsProtected and f:IsProtected())
end

local function Paint(t, kind)
    if not t or not t.SetColorTexture then return end
    local r, g, b = S.GetAccentColor()
    if kind == "accent" then t:SetColorTexture(r, g, b, 0.9)
    elseif kind == "selection" then t:SetColorTexture(r, g, b, 0.18)
    elseif kind == "light" then t:SetColorTexture(1, 1, 1, 0.045)
    elseif kind == "header" then t:SetColorTexture(r, g, b, 0.09)
    elseif kind == "pane" then t:SetColorTexture(0.025, 0.025, 0.03, 0.85)
    else t:SetColorTexture(0, 0, 0, 0.12) end
    paints[t] = kind
end

-- Change the existing color table in place: FC caches it in several files.
local function Palette()
    local c = API.COLORS
    if not c then return end
    local r, g, b = S.GetAccentColor()
    c.pane = { 0.025, 0.025, 0.03 }
    c.border = { 0.055, 0.055, 0.055 }
    c.bar = { 0.065, 0.065, 0.075 }
    c.light = { center = { 0.085, 0.085, 0.095 }, edge = { 0.055, 0.055, 0.065 } }
    c.dark = { center = { 0.05, 0.05, 0.06 }, edge = { 0.025, 0.025, 0.035 } }
    c.header = { center = { r * 0.18, g * 0.18, b * 0.18 }, edge = { 0.025, 0.025, 0.035 } }
    c.sep = { r, g, b, 0.22 }
end

local function HookMethod(f, name, callback)
    if type(f[name]) ~= "function" then return end
    local h = hooked[f]
    if not h then h = {}; hooked[f] = h end
    if h[name] then return end
    h[name] = true
    hooksecurefunc(f, name, callback)
end

local function HeaderChrome(f)
    if f ~= _G.ForeverCompanionFrame then return end
    if InCombatLockdown and InCombatLockdown() then chromeWaiting = true; return end
    local close, options, help = f.CloseButton, f.optionsBtn, f.helpBtn
    if Allowed(close) then
        close:ClearAllPoints(); close:SetSize(20, 20)
        close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)
    end
    local previous = close
    for _, button in ipairs({options or false, help or false}) do
        if Allowed(button) and Allowed(previous) then
            button:ClearAllPoints(); button:SetSize(20, 20)
            button:SetPoint("RIGHT", previous, "LEFT", -4, 0)
            previous = button
        end
    end
    -- Some FC versions add a small title-row toggle beside the tour button.
    -- Match only direct header controls, leaving content checkboxes untouched.
    if Allowed(help) and f.GetChildren then
        for _, button in ipairs({f:GetChildren()}) do
            if Allowed(button) and button ~= close and button ~= options and button ~= help
                and button.GetPoint and button.GetWidth and button.GetHeight then
                local kind = button:GetObjectType()
                local point, relative, _, x, y = button:GetPoint(1)
                local width, height = button:GetWidth(), button:GetHeight()
                if (kind == "Button" or kind == "CheckButton") and point == "TOPRIGHT" and relative == f
                    and x and x >= -120 and x <= -28 and y and y >= -14 and y <= 4
                    and width >= 12 and width <= 32 and height >= 12 and height <= 32 then
                    button:ClearAllPoints(); button:SetSize(20, 20)
                    button:SetPoint("RIGHT", help, "LEFT", -4, 0)
                end
            end
        end
    end
end

local function SideIcon(tab)
    if not Allowed(tab) or not sideTabs[tab] or not tab.icon then return end
    if InCombatLockdown and InCombatLockdown() then chromeWaiting = true; return end
    -- Native side-tab masks offset the icon left; square tabs need equal insets.
    tab.icon:ClearAllPoints()
    tab.icon:SetPoint("TOPLEFT", tab, "TOPLEFT", 3, -3)
    tab.icon:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -3, 3)
    local parent = tab.GetParent and tab:GetParent()
    if parent and tab.SetFrameLevel and parent.GetFrameLevel then
        tab:SetFrameLevel(parent:GetFrameLevel() + 8)
    end
    if parent and tab.GetPoint then
        local point, relative, relativePoint, x, y = tab:GetPoint(1)
        if point == "TOPLEFT" and relative == parent and relativePoint == "TOPRIGHT" and x and x < 6 then
            tab:SetPoint(point, relative, relativePoint, 6, y)
        end
    end
end

local function SkinNode(f)
    if not Allowed(f) then return end
    HeaderChrome(f)
    SideIcon(f)
    local fresh = not seen[f]
    if fresh then
        seen[f] = true
        local kind = f:GetObjectType()
        if kind == "StatusBar" and S.ApplyBarFill then
            S.ApplyBarFill(f)
            local painting = false
            HookMethod(f, "SetStatusBarColor", function()
                if not Enabled() or painting then return end
                painting = true; S.ApplyBarFill(f); painting = false
            end)
        elseif kind == "CheckButton" then S.Checkbox(f)
        elseif kind == "EditBox" then S.EditBox(f, {padInput = true})
        elseif kind == "Slider" or kind == "EventFrame" then
            -- MinimalScrollBar is an EventFrame; normal option sliders stay intact.
            if f.ThumbTexture or f.GetThumbTexture or f.Track then S.ScrollBar(f) end
        elseif kind == "DropdownButton" then S.Dropdown(f)
        elseif kind == "Button" and not f.itemId and not f.spellId then
            local label = (f.GetFontString and f:GetFontString()) or f.Text or f.text
            if label and not f.icon then
                S.Button(f, { "Icon", "sel", "selL", "selR", "accent" })
                if S.StateButtonLabel then S.StateButtonLabel(f) end
            end
        end
        if f:GetObjectType() ~= "GameTooltip" then
            for _, region in ipairs({ f:GetRegions() }) do
                if region:GetObjectType() == "FontString" then S.Font(region) end
            end
        end
    end
    if S.SortHeaderBar and f.HeaderContainer and f.HeaderContainer.GetChildren then S.SortHeaderBar(f) end
    -- FC selection hooks must retain their original behavior.
    if f.accent then
        Paint(f.accent, "accent")
        if f.text then f.text:SetTextColor(1, 1, 1) end
    end
    if f.selL then Paint(f.selL, "selection") end
    if f.selR then Paint(f.selR, "selection") end
    if f.icon and f.sel and not tabs[f] then Paint(f.sel, "selection") end
    local h = hooked[f]
    if type(f.SetSelected) == "function" and not (h and h.SetSelected) then
        HookMethod(f, "SetSelected", function() if Enabled() then Safe(SkinNode, f) end end)
    end
    for _, method in ipairs(refreshMethods) do
        if type(f[method]) == "function" and not (h and h[method]) then
            HookMethod(f, method, function() Queue(f) end)
        end
    end
end

Scan = function(f, depth)
    if not Enabled() or not Allowed(f) or (depth or 0) > 16 then return end
    if f:GetObjectType() == "GameTooltip" then return end
    SkinNode(f)
    if not f.GetNumChildren or f:GetNumChildren() > 0 then
        for _, child in ipairs({ f:GetChildren() }) do Scan(child, (depth or 0) + 1) end
    end
end

-- One deferred pass coalesces construction/refresh bursts. No polling/OnUpdate.
Queue = function(f)
    if not Enabled() or not Allowed(f) then return end
    pending[f] = true
    if queued then return end
    queued = true
    C_Timer.After(0, function()
        queued = false
        local batch = pending
        pending = {}
        if not Enabled() then return end
        for frame in pairs(batch) do Safe(Scan, frame) end
        if S.RefreshSoftBorders then Safe(S.RefreshSoftBorders) end
    end)
end

local function Window(f)
    if not Allowed(f) or roots[f] then return end
    roots[f] = true
    -- Only call Shell on initial construction: a later call would fade content icons.
    -- Already-built options windows carry a content icon directly on the root.
    local headAlpha = f.headIcon and f.headIcon:GetAlpha()
    local footer = f.GetName and (f:GetName() == "ForeverCompanionRecipeExport" or f:GetName() == "ForeverCompanionPawnFrame")
    S.Shell(f, footer and {bottomBar = 36} or nil)
    ns.AttachAccent(S, f)
    if headAlpha then f.headIcon:SetAlpha(headAlpha) end
    if f.NineSlice then S.FadeNineSlice(f.NineSlice) end
    if f.Bg then f.Bg:SetAlpha(0) end
    if f.Inset then S.Inset(f.Inset) end
    if f.TitleBg then f.TitleBg:SetAlpha(0) end
    if f.TitleContainer then
        S.FadeRegions(f.TitleContainer)
        if f.TitleContainer.TitleText then S.Font(f.TitleContainer.TitleText, 1, 1, 1) end
    elseif f.TitleText then S.Font(f.TitleText, 1, 1, 1) end
    if f.CloseButton then S.CloseButton(f.CloseButton) end
    f:HookScript("OnShow", function() Queue(f) end)
    Queue(f)
end

local function Pack(...) return { n = select("#", ...), ... } end

-- Factories return frames which post-hooks cannot see. Wrap only FC's public factories,
-- preserving all return values (including nils) and propagating original errors.
local function Wrap(name, after)
    local original = API[name]
    if type(original) ~= "function" then return end
    API[name] = function(...)
        local result = Pack(original(...))
        if Enabled() then Safe(after, result, ...) end
        return unpack(result, 1, result.n)
    end
end

local externalWaiting
local auctionFooters = setmetatable({}, {__mode = "k"})
local function ExternalButtons()
    if not Enabled() then return end
    if InCombatLockdown and InCombatLockdown() then externalWaiting = true; return end
    externalWaiting = false
    -- FC attaches this UIParent-owned launcher to the Blizzard talent/spellbook
    -- window. Only visit the named button, never the Blizzard host's controls.
    local button = _G.ForeverCompanionTalentBtn
    if Allowed(button) then Queue(button) end
    -- The auction scan footer is private to FC. Inspect only the host's direct
    -- children and require its exact owned logo and fields before touching it.
    local host = _G.AuctionHouseFrame or _G.AuctionFrame
    if Allowed(host) and host.GetChildren then
        for _, footer in ipairs({host:GetChildren()}) do
            local icon = footer.icon
            local path = type(icon) == "table" or type(icon) == "userdata"
            path = path and icon.GetTexture and icon:GetTexture()
            if Allowed(footer) and Allowed(footer.btn) and footer.status
                and type(path) == "string" and path:find("ForeverCompanion", 1, true)
                and path:find("LogoAddon", 1, true) then
                if not auctionFooters[footer] then
                    auctionFooters[footer] = true
                    footer:ClearAllPoints(); footer:SetPoint("TOPRIGHT", host, "BOTTOMRIGHT", -4, -30)
                    footer:SetSize(360, 26)
                    footer.status:SetWidth(200)
                    S.Panel(footer); S.Button(footer.btn)
                    if S.StateButtonLabel then S.StateButtonLabel(footer.btn) end
                end
                icon:SetAlpha(1); S.Font(footer.status, 0.9, 0.9, 0.92)
            end
        end
    end
end

local function Install(skin)
    if installed then return end
    S = ns.CreateSoftSkin(skin, moduleOwner)
    if not Enabled() then return end
    installed = true
    Palette()
    -- AttachToFrame is called after the launcher is fully constructed.
    if type(API.AttachToFrame) == "function" then
        hooksecurefunc(API, "AttachToFrame", function(button)
            if button == _G.ForeverCompanionTalentBtn then ExternalButtons() end
        end)
    end
    local externalEvents = CreateFrame("Frame")
    externalEvents:RegisterEvent("PLAYER_LOGIN")
    externalEvents:RegisterEvent("ADDON_LOADED")
    externalEvents:RegisterEvent("AUCTION_HOUSE_SHOW")
    externalEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
    externalEvents:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" and chromeWaiting then
            chromeWaiting = false
            for f in pairs(roots) do Queue(f) end
        end
        if event == "AUCTION_HOUSE_SHOW" then
            -- FC may construct the private footer later in this same event.
            C_Timer.After(0, ExternalButtons)
        elseif event ~= "PLAYER_REGEN_ENABLED" or externalWaiting then ExternalButtons() end
    end)
    ExternalButtons()
    Wrap("CreateWindow", function(v) Window(v[1]) end)
    Wrap("CreateMenuButton", function(v)
        S.Button(v[1]); if S.StateButtonLabel then S.StateButtonLabel(v[1]) end
        Queue(v[1])
    end)
    Wrap("CreateSearchBox", function(v) Queue(v[1]) end)
    Wrap("CreateDropdown", function(v)
        if v[1] and v[1].frame then
            S.Dropdown(v[1].frame); Queue(v[1].frame)
            if ns.BindPopupOwner then ns.BindPopupOwner(S, moduleOwner, v[1].frame) end
        end
    end)
    Wrap("CreateScrollFrame", function(v)
        local sf, bar = v[1], v[2]
        bar = bar or (sf and sf.ScrollBar)
        if bar then S.ScrollBar(bar) end
        if sf then sf:HookScript("OnShow", function() Queue(sf) end); Queue(sf) end
    end)
    Wrap("AddInset", function(v)
        Paint(v[1], "pane"); if v[2] then S.Inset(v[2]) end
    end)
    Wrap("StripedBackground", function(v, _, style)
        Paint(v[1], style); Paint(v[2], style)
    end)
    Wrap("CreateSideTab", function(v)
        local tab = v[1]
        if S.Tab and S.SetTabSelection then
            tabs[tab] = true
            tab.Icon = tab.icon -- public Tab preserves icon tabs through this key
            S.Tab(tab)
            S.SetTabSelection(tab, tab.sel and tab.sel.IsShown and tab.sel:IsShown() or false)
            HookMethod(tab, "SetActive", function(_, selected)
                if Enabled() then S.SetTabSelection(tab, selected) end
            end)
        else S.Button(tab, { "icon", "sel" }) end
        if tab.mask and tab.icon and tab.icon.RemoveMaskTexture then tab.icon:RemoveMaskTexture(tab.mask) end
        if tab.bg then tab.bg:SetAlpha(0) end
        if tab.border then tab.border:SetAlpha(0) end
        if tab.hl then tab.hl:SetAlpha(0) end
        if tab.icon then S.SquareIcon(tab.icon, tab) end
        -- Keep the native order, size and actions; only correct icon/border overlap.
        sideTabs[tab] = true
        SideIcon(tab)
        local placing = false
        HookMethod(tab, "SetPoint", function()
            if not Enabled() or placing then return end
            placing = true; Safe(SideIcon, tab); placing = false
        end)
        if not tabs[tab] then Paint(tab.sel, "selection") end
        Queue(tab)
    end)
    Wrap("CreateOptionsButton", function(v) S.Button(v[1], { "icon" }); Queue(v[1]) end)
    Wrap("VirtualList", function(v, _, sc)
        HookMethod(v[1], "Layout", function() Queue(sc) end)
        HookMethod(v[1], "Refresh", function() Queue(sc) end)
        Queue(sc)
    end)
    -- Windows may already exist when the skin callback is dispatched at login.
    for _, name in ipairs({
        "Frame", "RotationFrame", "TalentFrame", "ConsumeFrame", "OptionsFrame",
        "LootFrame", "ProfessionsFrame", "MarketFrame", "StatsPanel", "SpecChooser",
        "NewsFrame", "TourFrame", "TourHint", "PawnFrame", "ScanFrame", "PickFrame",
        "RecipePicker", "RecipeExport", "ScalePreview",
    }) do
        local f = _G["ForeverCompanion" .. name]
        if f then Safe(Window, f) end
    end
    if S.OnLooksChanged then S.OnLooksChanged(function()
        if not Enabled() then return end
        Palette()
        ExternalButtons()
        for texture, kind in pairs(paints) do Safe(Paint, texture, kind) end
        for f in pairs(roots) do Queue(f) end
    end) end
end

-- The collection loads this module only when its target API is present.
ns.RegisterModule("ForeverCompanion", "Forever Companion", function()
    return _G.ForeverCompanionAPI ~= nil
end, function(skin, module)
    API = _G.ForeverCompanionAPI
    moduleOwner = module
    Install(skin)
    module.refresh = function()
        ExternalButtons()
        for f in pairs(roots) do Queue(f) end
    end
end)
