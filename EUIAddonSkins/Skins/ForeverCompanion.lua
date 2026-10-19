-- Standalone integration. No Forever Companion files or gameplay handlers are replaced.
local ADDON, ns = ...
local function DefineSkin()
local API
local S, H, menuSkin, installed, moduleOwner
local unpack = unpack or table.unpack
local roots = setmetatable({}, { __mode = "k" })
local seen = setmetatable({}, { __mode = "k" })
local hooked = setmetatable({}, { __mode = "k" })
local paints = setmetatable({}, { __mode = "k" })
local paintReverse = setmetatable({}, {__mode = "k"})
local tabs = setmetatable({}, { __mode = "k" })
local sideTabs = setmetatable({}, { __mode = "k" })
local pending, queued = {}, false
local Scan, Queue, Completed
local function Weak() return setmetatable({}, {__mode = "k"}) end
local visuals, canvases, fontCache, textGuards, checkSeen, checkMarks = Weak(), Weak(), Weak(), Weak(), Weak(), Weak()
local waitingWindows, combatWork, headers = Weak(), {}, Weak()
local generation = 0
local fontApplying = {}
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
    local kind = type(f)
    return (kind == "table" or kind == "userdata") and type(f.GetObjectType) == "function" and not (f.IsForbidden and f:IsForbidden())
        and not (f.IsProtected and f:IsProtected())
end

local function Paint(t, kind, reverse)
    if not t or not t.SetColorTexture then return end
    local r, g, b = S.GetAccentColor()
    if kind == "accent" then t:SetColorTexture(r, g, b, 0.9)
    elseif kind == "selection" then t:SetColorTexture(r, g, b, 0.18)
    elseif kind == "light" or kind == "dark" or kind == "header" then
        -- Keep the native two-half row geometry, with a neutral centre glow.
        if reverse == nil then reverse = paintReverse[t] end
        local colors = API.COLORS and API.COLORS[kind]
        if colors then
            local first, last = reverse and colors.center or colors.edge, reverse and colors.edge or colors.center
            t:SetColorTexture(1, 1, 1, 1)
            if t.SetGradient and CreateColor then
                t:SetGradient("HORIZONTAL", CreateColor(first[1], first[2], first[3], 1), CreateColor(last[1], last[2], last[3], 1))
            elseif t.SetGradientAlpha then
                t:SetGradientAlpha("HORIZONTAL", first[1], first[2], first[3], 1, last[1], last[2], last[3], 1)
            else t:SetColorTexture(colors.center[1], colors.center[2], colors.center[3], 1) end
        end
        paintReverse[t] = reverse
    elseif kind == "pane" then t:SetColorTexture(0.055, 0.055, 0.06, 0.96)
    else t:SetColorTexture(0, 0, 0, 0.12) end
    paints[t] = kind
end

-- Change the existing color table in place: FC caches it in several files.
local function Palette()
    local c = API.COLORS
    if not c then return end
    c.pane = { 0.055, 0.055, 0.06 }
    c.border = { 0.055, 0.055, 0.055 }
    c.bar = { 0.065, 0.065, 0.075 }
    c.light = { center = { 0.13, 0.13, 0.14 }, edge = { 0.075, 0.075, 0.085 } }
    c.dark = { center = { 0.085, 0.085, 0.095 }, edge = { 0.05, 0.05, 0.06 } }
    c.header = { center = { 0.16, 0.16, 0.17 }, edge = { 0.09, 0.09, 0.10 } }
    c.sep = { 0.20, 0.20, 0.22, 0.35 }
end

local function HookMethod(f, name, callback)
    if type(f[name]) ~= "function" then return end
    local h = hooked[f]
    if not h then h = {}; hooked[f] = h end
    if h[name] then return end
    h[name] = true
    hooksecurefunc(f, name, function(...) if Enabled() then Safe(callback, ...) end end)
end

local function Busy()
    if InCombatLockdown and InCombatLockdown() then chromeWaiting = true; return true end
end

-- Font output is cached, but a native font reset still invalidates the entry.
local function Font(text)
    if not Allowed(text) or text:GetObjectType() ~= "FontString" or fontApplying[text] then return end
    local path, size, flags
    if text.GetFont then path, size, flags = text:GetFont() end
    local old = fontCache[text]
    if not old or old.generation ~= generation or old.path ~= path or old.size ~= size or old.flags ~= flags then
        fontApplying[text] = true
        local ok, err = pcall(S.Font, text)
        fontApplying[text] = nil
        if not ok then error(err) end
        if text.GetFont then path, size, flags = text:GetFont() end
        fontCache[text] = {path = path, size = size, flags = flags, generation = generation}
    end
end

local function Text(text, role, semantic)
    if not Allowed(text) or text:GetObjectType() ~= "FontString" then return end
    Font(text)
    if semantic or not text.GetTextColor or not text.SetTextColor then return end
    local d = textGuards[text]
    if not d then
        d = {}; textGuards[text] = d
        d.paint = function()
            if d.painting or not Enabled() or Busy() or not Allowed(text) then return end
            d.painting = true
            Font(text)
            local r, g, b, a = text:GetTextColor()
            local nr, ng, nb
            if d.role == "accent" then nr, ng, nb = S.GetAccentColor()
            elseif d.role == "tab" then nr, ng, nb = 0.91, 0.91, 0.93
            elseif r and r >= 0.8 and g >= 0.7 and g <= 0.9 and b <= 0.2 then nr, ng, nb = 0.91, 0.91, 0.93 end
            if nr and (r ~= nr or g ~= ng or b ~= nb) then text:SetTextColor(nr, ng, nb, a or 1) end
            d.painting = false
        end
        for _, name in ipairs({"SetTextColor", "SetFontObject", "SetFont"}) do HookMethod(text, name, d.paint) end
    end
    if role ~= nil then d.role = role end
    d.paint()
end

local function Gradient(t, a, b)
    t:SetColorTexture(1, 1, 1, 1)
    if t.SetGradient and CreateColor then
        t:SetGradient("HORIZONTAL", CreateColor(0.19, 0.19, 0.20, a), CreateColor(0.19, 0.19, 0.20, b))
    elseif t.SetGradientAlpha then t:SetGradientAlpha("HORIZONTAL", 0.19, 0.19, 0.20, a, 0.19, 0.19, 0.20, b)
    else t:SetColorTexture(0.12, 0.12, 0.13, 0.3) end
end
local function Canvas(owner, anchor)
    anchor = anchor or owner
    if not Allowed(owner) or not owner.CreateTexture or canvases[anchor] then return end
    local layer = CreateFrame("Frame", nil, owner); visuals[layer] = true
    layer:EnableMouse(false)
    if anchor == owner then
        layer:SetPoint("TOPLEFT", owner, "TOPLEFT", 8, -30)
        layer:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", -8, 8)
    else layer:SetAllPoints(anchor) end
    if layer.SetFrameLevel and owner.GetFrameLevel then layer:SetFrameLevel(owner:GetFrameLevel()) end
    local base = layer:CreateTexture(nil, "BACKGROUND", nil, 1); base:SetAllPoints(layer)
    base:SetColorTexture(0.055, 0.055, 0.06, 0.96)
    local left = layer:CreateTexture(nil, "BACKGROUND", nil, 2)
    left:SetPoint("TOPLEFT", layer, "TOPLEFT"); left:SetPoint("BOTTOMRIGHT", layer, "BOTTOM")
    local right = layer:CreateTexture(nil, "BACKGROUND", nil, 2)
    right:SetPoint("TOPLEFT", layer, "TOP"); right:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT")
    Gradient(left, 0, 0.48); Gradient(right, 0.48, 0)
    canvases[anchor] = layer
end

local function Check(f)
    if not checkSeen[f] then
        checkSeen[f] = true
        S.Checkbox(f, {borderInset = 4, hover = 0.08})
        for _, name in ipairs({"SetCheckedTexture", "SetDisabledCheckedTexture", "Enable", "Disable"}) do
            HookMethod(f, name, function() if Enabled() and not Busy() then Check(f) end end)
        end
    end
    for _, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
        local mark = f[getter] and f[getter](f)
        if mark and mark.SetColorTexture and checkMarks[mark] ~= generation then
            checkMarks[mark] = generation
            local r, g, b = S.GetAccentColor()
            mark:SetColorTexture(r, g, b, 1)
            mark:ClearAllPoints(); mark:SetPoint("TOPLEFT", f, "TOPLEFT", 7, -7); mark:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -7, 7)
        end
    end
end

local function Dropdown(f)
    S.Dropdown(f)
    if ns.BindPopupOwner then ns.BindPopupOwner(menuSkin, moduleOwner, f) end
    local button = f.Button or f
    local arrow = button.Arrow or button.arrow or f.Arrow
    if arrow and arrow.SetTexture and arrow.SetSize then
        arrow:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png")
        arrow:SetSize(10, 7)
        if arrow.SetVertexColor then arrow:SetVertexColor(0.8, 0.8, 0.82, 1) end
    end
end

local function Talent(f)
    -- Exact native talent-button shape, distinct from item and action buttons.
    if not (f.tex and f.rankFS and f.outerTex) then return false end
    S.SquareIcon(f.tex)
    H.Fade(f.outerTex); H.Fade(f.rankBg)
    for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture"}) do if f[getter] then H.Fade(f[getter](f)) end end
    local edges = f.fcSkinEdges
    if not edges then
        edges = {}; f.fcSkinEdges = edges
        for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
            local t = f:CreateTexture(nil, "OVERLAY")
            if side == "TOP" or side == "BOTTOM" then
                t:SetPoint(side .. "LEFT", f, side .. "LEFT"); t:SetPoint(side .. "RIGHT", f, side .. "RIGHT"); t:SetHeight(1)
            else
                t:SetPoint("TOP" .. side, f, "TOP" .. side); t:SetPoint("BOTTOM" .. side, f, "BOTTOM" .. side); t:SetWidth(1)
            end
            edges[#edges + 1] = t
        end
    end
    local r, g, b = 0.3, 0.3, 0.32
    if f.outerTex.GetVertexColor then r, g, b = f.outerTex:GetVertexColor() end
    for _, edge in ipairs(edges) do edge:SetColorTexture(r, g, b, 1) end
    HookMethod(f.outerTex, "SetVertexColor", function() if Enabled() and not Busy() then Talent(f) end end)
    return true
end

local function Mode(button, selected)
    if not Allowed(button) then return end
    if not button.fcSkinActive then
        button.fcSkinActive = button:CreateTexture(nil, "OVERLAY")
        button.fcSkinActive:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT")
        button.fcSkinActive:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT")
        button.fcSkinActive:SetHeight(1)
    end
    if button.GetHighlightTexture then H.Fade(button:GetHighlightTexture()) end
    local r, g, b = S.GetAccentColor()
    button.fcSkinActive:SetColorTexture(r, g, b, selected and 1 or 0)
    Text((button.GetFontString and button:GetFontString()) or button.Text or button.text, selected and "accent" or "tab")
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
    if not Allowed(f) or visuals[f] or Busy() then return end
    HeaderChrome(f)
    SideIcon(f)
    local talent = Talent(f)
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
        elseif kind == "CheckButton" then Check(f)
        elseif kind == "EditBox" then S.EditBox(f, {padInput = true})
        elseif kind == "Slider" or kind == "EventFrame" then
            -- MinimalScrollBar is an EventFrame; normal option sliders stay intact.
            if f.ThumbTexture or f.GetThumbTexture or f.Track then S.ScrollBar(f) end
        elseif kind == "DropdownButton" then Dropdown(f)
        elseif kind == "Button" and not talent and not f.itemId and not f.spellId then
            local label = (f.GetFontString and f:GetFontString()) or f.Text or f.text
            if label and not f.icon then
                S.Button(f, { "Icon", "sel", "selL", "selR", "accent" })
                if S.StateButtonLabel then S.StateButtonLabel(f) end
            end
        end
    end
    for _, region in ipairs({ f:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            Text(region, nil, region == f.rankFS or region == f.skill or region == f.tag or (region == f.name and (f.itemId or f.itemID or f.link or f.out)))
        end
    end
    if f:GetObjectType() == "CheckButton" and not fresh then Check(f) end
    Text(f.headTitle, "accent")
    if headers[f] then Text(f.text, "accent") end
    if f.pages and f.current then
        for id, button in pairs(f.tabBtns or {}) do Mode(button, id == f.current) end
    end
    if f.modeBtns then
        for id, button in pairs(f.modeBtns) do Mode(button, id == (f.mode == "guide" and "guide" or f.gatherView or "recipes")) end
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
            HookMethod(f, method, function()
                if not Enabled() then return end
                if method == "ShowPage" or method == "Render" then Completed(f) else Queue(f) end
            end)
        end
    end
end

Scan = function(f, depth)
    if not Enabled() or not Allowed(f) or visuals[f] or Busy() or (depth or 0) > 16 then return end
    if seen[f] and f.IsVisible and not f:IsVisible() then return end
    if f:GetObjectType() == "GameTooltip" then return end
    pending[f] = nil
    SkinNode(f)
    if not f.GetNumChildren or f:GetNumChildren() > 0 then
        for _, child in ipairs({ f:GetChildren() }) do Scan(child, (depth or 0) + 1) end
    end
end

Completed = function(f)
    if not Enabled() or not Allowed(f) or Busy() then return end
    local page = f.pages and f.pages[f.current]
    if page then SkinNode(f); Scan(page.sf or page) else Scan(f) end
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
        for frame in pairs(batch) do
            local parent = frame.GetParent and frame:GetParent()
            local covered = false
            for _ = 1, 32 do
                if not Allowed(parent) then break end
                if batch[parent] then covered = true; break end
                parent = parent.GetParent and parent:GetParent()
            end
            if not covered then Safe(Scan, frame) end
        end
        if S.RefreshSoftBorders then Safe(S.RefreshSoftBorders) end
    end)
end

local function Window(f)
    if not Allowed(f) or roots[f] then return end
    if Busy() then waitingWindows[f] = true; return end
    roots[f] = true
    -- Only call Shell on initial construction: a later call would fade content icons.
    -- Already-built options windows carry a content icon directly on the root.
    local headAlpha = f.headIcon and f.headIcon:GetAlpha()
    local footer = f.GetName and (f:GetName() == "ForeverCompanionRecipeExport" or f:GetName() == "ForeverCompanionPawnFrame")
    S.Shell(f, {bottomBar = footer and 36 or nil, noAccent = true})
    local name = f.GetName and f:GetName()
    if name ~= "ForeverCompanionTalentFrame" then Canvas(f) end
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
    f:HookScript("OnShow", function() if Enabled() then Safe(Completed, f) end end)
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
        if Enabled() then
            if Busy() then combatWork[#combatWork + 1] = {after = after, result = result, args = Pack(...)}
            else Safe(after, result, ...) end
        end
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
    H = ns.CreateSkinHelper(S, moduleOwner)
    menuSkin = setmetatable({GetPanelColor = function() return 0.065, 0.065, 0.07, 0.98 end}, {__index = S})
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
            local work = combatWork; combatWork = {}
            if Enabled() then
                for _, entry in ipairs(work) do Safe(entry.after, entry.result, unpack(entry.args, 1, entry.args.n)) end
                for f in pairs(waitingWindows) do Safe(Window, f) end
            end
            waitingWindows = Weak()
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
            Dropdown(v[1].frame); Queue(v[1].frame)
        end
    end)
    Wrap("CreateScrollFrame", function(v)
        local sf, bar = v[1], v[2]
        bar = bar or (sf and sf.ScrollBar)
        if bar then S.ScrollBar(bar) end
        if sf then sf:HookScript("OnShow", function() Queue(sf) end); Queue(sf) end
    end)
    Wrap("AddInset", function(v, owner)
        Paint(v[1], "pane"); if v[2] then S.Inset(v[2]) end
        if Allowed(owner) and v[1] and v[1].SetPoint then Canvas(owner, v[1]) end
    end)
    Wrap("StripedBackground", function(v, owner, style)
        style = style or "dark"
        Paint(v[1], style, false); Paint(v[2], style, true)
        if style == "header" and Allowed(owner) and owner:GetObjectType() == "Frame" then headers[owner] = true end
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
        local function Rows()
            if not Enabled() or Busy() then return end
            if v[1].active then
                for _, row in pairs(v[1].active) do Safe(Scan, row) end
            else Queue(sc) end
        end
        HookMethod(v[1], "Layout", Rows)
        HookMethod(v[1], "Refresh", Rows)
        Queue(sc)
    end)
    local FC = _G.ForeverCompanion
    if type(FC) == "table" then
        local windows = {
            OpenOptions = "OptionsFrame", OpenMarket = "MarketFrame", OpenProfessionsFrame = "ProfessionsFrame",
            OpenLootFrame = "LootFrame", OpenConsumeFrame = "ConsumeFrame", ToggleBislist = "Frame",
            RefreshBislist = "Frame", OpenBislistForSpec = "Frame", OpenBisTalentFrame = "TalentFrame",
            OpenBisTalentFrameForSpec = "TalentFrame", RefreshTalentBuild = "TalentFrame",
            OpenRotationFrame = "RotationFrame", OpenRotationFrameForSpec = "RotationFrame", RefreshRotationBuild = "RotationFrame",
        }
        for method, suffix in pairs(windows) do
            HookMethod(FC, method, function()
                local f = _G["ForeverCompanion" .. suffix]
                if Enabled() and Allowed(f) then Safe(Completed, f) end
            end)
        end
    end
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
        generation = generation + 1
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

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("ForeverCompanion", DefineSkin)
else DefineSkin() end
