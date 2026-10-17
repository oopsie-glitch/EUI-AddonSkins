local ADDON, ns = ...
local function DefineSkin()
local unpack = unpack or table.unpack
local navigationText = setmetatable({}, {__mode = "k"})

local function Frame(item)
    local kind = type(item)
    if kind == "table" or kind == "userdata" then return item.frame or item end
end
local fontPaints = setmetatable({}, {__mode = "k"})
local fontGeneration = 0
local function Font(S, text, r, g, b, alpha)
    if not text or not text.GetFont then return end
    if alpha == nil and text.GetTextColor then alpha = select(4, text:GetTextColor()) end
    local path, size, flags = text:GetFont()
    local target, targetFlags = S.GetFont()
    local state = fontPaints[text]
    if not state or state.path ~= path or state.size ~= size or state.flags ~= flags
        or state.target ~= target or state.targetFlags ~= targetFlags or state.generation ~= fontGeneration then
        -- Gargul overloads SetFont(rem, flags); never pass a file to that wrapper.
        if type(text._SetFont) == "function" then text:_SetFont(target, size or 12, targetFlags or "")
        else S.Font(text) end
        path, size, flags = text:GetFont()
        fontPaints[text] = {path = path, size = size, flags = flags, target = target,
            targetFlags = targetFlags, generation = fontGeneration}
    end
    if r ~= nil then
        local cr, cg, cb, ca = text:GetTextColor()
        if cr ~= r or cg ~= g or cb ~= b or ca ~= alpha then text:SetTextColor(r, g, b, alpha) end
    end
end

-- Discover adapters once, then repaint the completed owned page/window. Ordinary
-- AceGUI construction callbacks never rediscover the entire Interface graph.
local function Routing(C)
    if C.gargul then return end
    local H = C.H
    local G = {windows = setmetatable({}, {__mode = "k"}), scopes = setmetatable({}, {__mode = "k"}),
        registered = setmetatable({}, {__mode = "k"}), scopeWindows = setmetatable({}, {__mode = "k"}), dirty = {}, navigation = setmetatable({}, {__mode = "k"})}
    C.gargul, C.navigation = G, G.navigation
    function G.Settings()
        local overview = _G.Gargul.Interface.Settings and _G.Gargul.Interface.Settings.Overview
        local items = overview and overview.InterfaceItems or {}
        local window = Frame(items.Frame and items.Frame.Window) or _G.GARGUL_SETTING_WINDOW
        local page = Frame(items.ScrollFrame and items.ScrollFrame.ScrollFrame)
            or Frame(items.Frame and items.Frame.SectionWrapper)
        local sections = items.Table and items.Table.Sections
        return window, page, Frame(sections), sections, overview
    end
    function G.Exclude(root)
        local window, page, nav = G.Settings()
        local exclude = {}
        if root == window then
            if H.Allowed(page) and page ~= window then exclude[page] = true end
            if H.Allowed(nav) and nav ~= window then exclude[nav] = true end
        end
        for layer in pairs(G.layers or {}) do exclude[layer] = true end
        return exclude
    end
    function G.Paint(root)
        if not H.Allowed(root) or not ns.IsEnabled(C.module) then return end
        G.dirty[root] = nil
        if InCombatLockdown and InCombatLockdown() then C.module.refresh(); return end
        if G.windows[root] and not G.registered[root] then C.RefreshNow(); return end
        if G.Prepare then G.Prepare(root) end
        C.RefreshControlsNow(root, G.Exclude(root))
        local _, _, nav = G.Settings()
        if root == nav and G.Navigation then G.Navigation() end
    end
    function G.Queue(root)
        if not H.Allowed(root) or G.dirty[root] then return end
        G.dirty[root] = true
        H.Queue(root, function() if G.dirty[root] then G.Paint(root) end end)
    end
    function G.Page()
        local window, page = G.Settings()
        -- Completing showSection consumes the construction/OnShow burst. A
        -- newly opened settings window still needs its one initial shell pass.
        if not G.registered[window] then C.RefreshNow(); return end
        G.dirty[window] = nil
        G.Paint(H.Allowed(page) and page or window)
    end
    function G.Route(root, source)
        local window, page, nav = G.Settings()
        local node = H.Allowed(source) and source or root
        for _ = 1, 24 do
            if not H.Allowed(node) then break end
            if node == page or node == nav then G.Queue(node); return end
            if G.registered[node] then G.Queue(node); return end
            node = node.GetParent and node:GetParent()
        end
        if G.windows[root] or G.registered[root] then G.Queue(root)
        elseif H.Allowed(page) or H.Allowed(window) then G.Queue(H.Allowed(page) and page or window)
        else C.module.refresh() end
    end
    function G.Remember(scope)
        if type(scope) ~= "table" then return end
        local owned = G.scopeWindows[scope]
        if not owned then owned = setmetatable({}, {__mode = "k"}); G.scopeWindows[scope] = owned end
        local seen = {}
        local function Items(t, depth)
            if type(t) ~= "table" or seen[t] or depth > 4 then return end
            seen[t] = true
            for key, item in pairs(t) do
                local f = Frame(item)
                if H.Allowed(f) then
                    if key == "Window" or item.type == "Frame" or f:GetObjectType() == "Frame" and f:GetParent() == UIParent then
                        G.windows[f], owned[f] = true, true
                    end
                elseif type(item) == "table" then Items(item, depth + 1) end
            end
        end
        Items(scope and scope.InterfaceItems, 0)
    end
    function G.Completed(scope)
        G.Remember(scope)
        local owned = G.scopeWindows[scope] or {}
        if H.Allowed(scope and scope.Window) then owned[scope.Window] = true; G.windows[scope.Window] = true end
        for f in pairs(owned) do if not G.registered[f] then C.RefreshNow(); return end end
        for f in pairs(owned) do
            if not f.IsShown or f:IsShown() then G.Paint(f) end
        end
    end
    function G.Scope(scope, settingsPage)
        if type(scope) ~= "table" or H.Allowed(Frame(scope)) or G.scopes[scope] then return end
        G.scopes[scope] = true
        G.Remember(scope)
        local _, _, _, _, overview = G.Settings()
        if scope == overview then
            H.Hook(scope, "showSection", G.Page)
            H.Hook(scope, "draw", function()
                local window = G.Settings()
                if not G.registered[window] then C.RefreshNow() else G.Paint(window) end
            end)
        else
            for _, method in ipairs({"draw", "open", "showSection"}) do
                H.Hook(scope, method, function()
                    if settingsPage then
                        local window, page = G.Settings(); G.Queue(H.Allowed(page) and page or window)
                    else G.Completed(scope) end
                end)
            end
        end
    end
    function G.Discover()
        local seen = {}
        local settings = _G.Gargul.Interface.Settings
        local function Scopes(t, depth, isSettings)
            if type(t) ~= "table" or seen[t] or depth > 6 or H.Allowed(Frame(t)) then return end
            seen[t] = true
            G.Scope(t, isSettings)
            for key, value in pairs(t) do
                -- UI registries contain pooled controls and data, not adapters.
                if key ~= "InterfaceItems" and key ~= "FramePool" and key ~= "Colors" then
                    Scopes(value, depth + 1, isSettings or value == settings)
                end
            end
        end
        Scopes(_G.Gargul.Interface, 0, false)
        G.Scope(_G.Gargul.MasterLooterUI)
        local roller = _G.Gargul.RollerUI
        H.Hook(roller, "draw", function()
            -- Gargul creates a fresh roller frame per roll. Full theme/load
            -- refreshes need only the current one, not every historical frame.
            if G.rollerWindow and G.rollerWindow ~= roller.Window then
                G.windows[G.rollerWindow] = nil
                if G.scopeWindows[roller] then G.scopeWindows[roller][G.rollerWindow] = nil end
            end
            G.rollerWindow = roller.Window
            if H.Allowed(roller.Window) then G.windows[roller.Window] = true end
            G.Completed(roller)
        end)
        for _, method in ipairs({"reopen", "refreshExpandedRows", "refreshRollTracker", "showRollAcceptedNotification"}) do
            H.Hook(roller, method, function() G.Queue(roller.Window) end)
        end
        G.Remember(_G.Gargul.MasterLooterUI)
    end
    G.Discover()
    H.Hook(_G.Gargul.Interface, "set", function(_, scope, identifier, item)
        local f = Frame(item)
        -- Register only the supplied window. Scanning Settings.InterfaceItems
        -- per checkbox would turn a page's construction into quadratic work.
        if H.Allowed(f) and (identifier == "Window" or item.type == "Frame" and f:GetParent() == UIParent) then
            G.windows[f] = true
            G.Scope(scope, false)
        end
        -- Registration happens before AddChild on some Ace widgets. Wait for
        -- completed showSection/draw; the queue is only a standalone fallback.
        local window, page = G.Settings()
        G.Route(H.Allowed(Frame(item)) and Frame(item) or page or window, Frame(item))
    end)
    H.Hook(_G.Gargul.Interface, "createWindow", function(_, details)
        local f = type(details) == "table" and _G[details.name]
        if H.Allowed(f) then G.windows[f] = true; G.Queue(f) end
    end)
    H.Hook(_G.Gargul.Interface, "addMinimizeButton", function(_, window)
        if window and H.Allowed(window.Minimized) then
            G.windows[window.Minimized] = true; G.Queue(window.Minimized)
        end
    end)
    for _, method in ipairs({"createDropdown", "addWindowOptions"}) do
        H.Hook(_G.Gargul.Interface, method, function(_, owner)
            local f = Frame(owner); G.Route(f, f)
        end)
    end
    H.Hook(_G.Gargul.Interface, "AceGUIDefaults", function(_, _, item)
        local f = Frame(item); G.Route(f, f)
    end)
    H.Hook(_G.Gargul.UI, "createFrame", function(_, kind, identifier, parent)
        local f = identifier and _G[identifier]
        if H.Allowed(f) and kind == "Frame" and parent == UIParent then
            G.windows[f] = true; G.Queue(f)
        else G.Route(parent, parent) end
    end)
end

local labelOwners = setmetatable({}, {__mode = "k"})
local function Tone(C, text, owner)
    if not C.H.Allowed(text) or not text.GetFont then return end
    labelOwners[text] = owner or true
    local disabled = owner and owner.IsEnabled and not owner:IsEnabled()
    C.H.Font(text, disabled and 0.5 or 0.9, disabled and 0.5 or 0.9, disabled and 0.52 or 0.92)
end
local function Matte(C, f)
    local G, H = C.gargul, C.H
    G.mattes = G.mattes or setmetatable({}, {__mode = "k"})
    G.layers = G.layers or setmetatable({}, {__mode = "k"})
    if G.mattes[f] then return end
    -- The public shell still owns the window; a public flat Panel on our own
    -- non-interactive child supplies one cohesive fill, without header stripes.
    for _, r in ipairs(H.Regions(f)) do
        local layer = r.GetDrawLayer and r:GetDrawLayer()
        if H.Texture(r) and (layer == "BACKGROUND" or layer == "BORDER") then H.Fade(r) end
    end
    local layer = CreateFrame("Frame", nil, f)
    layer:SetAllPoints(f); layer:EnableMouse(false)
    if layer.SetFrameLevel and f.GetFrameLevel then layer:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1)) end
    C.S.Panel(layer, {noBorder = true})
    G.mattes[f], G.layers[layer] = layer, true
end
local function FlatControl(C, f, method, keep)
    if not C.H.Allowed(f) then return end
    local G = C.gargul
    G.controls = G.controls or setmetatable({}, {__mode = "k"})
    local d = G.controls[f]
    if not d then
        local before = {}
        for _, r in ipairs(C.H.Regions(f)) do before[r] = true end
        C.S[method](f, keep)
        if method == "Button" and C.S.StateButtonLabel then C.S.StateButtonLabel(f) end
        d = {}; G.controls[f] = d
        for _, r in ipairs(C.H.Regions(f)) do
            if not before[r] and C.H.Texture(r) then
                if r.GetDrawLayer and r:GetDrawLayer() == "BACKGROUND" then d.fill = r end
                if r.GetDrawLayer and r:GetDrawLayer() == "HIGHLIGHT" then d.hover = r end
                if method == "Dropdown" and r.GetAtlas and r:GetAtlas() == "Azerite-PointingArrow" then
                    r:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png")
                    r:SetVertexColor(0.8, 0.8, 0.8, 1)
                end
            end
        end
        if f.SetBackdrop then
            f:SetBackdrop(nil)
            C.H.Hook(f, "SetBackdrop", function(_, value) if value then f:SetBackdrop(nil) end end)
        end
    end
    if d.fill and C.S.GetPanelColor then
        local r, g, b = C.S.GetPanelColor()
        d.fill:SetColorTexture(math.min(r + 0.035, 1), math.min(g + 0.035, 1), math.min(b + 0.035, 1), 1)
    end
    if method == "Button" or method == "EditBox" then
        for _, region in pairs({d.fill, d.hover}) do
            region:ClearAllPoints()
            region:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
            region:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
        end
    end
    Tone(C, (f.GetFontString and f:GetFontString()) or f.Text or f.text, f)
end
-- lib-st's narrow/blank columns carry hidden sort data and equipment actions.
-- Their header buttons must remain live, but must not become individual boxes.
local function Organizer(C, root)
    local G, H = C.gargul, C.H
    local ui = _G.Gargul.MasterLooterUI
    local items = ui and ui.InterfaceItems
    local players = items and items.Table and items.Table.Players
    if root and root ~= Frame(items and items.Frame and items.Frame.Window) and root ~= (players and players.head) then return end
    G.headerCells = G.headerCells or setmetatable({}, {__mode = "k"})
    G.headerRows = G.headerRows or setmetatable({}, {__mode = "k"})
    if players and H.Allowed(players.head) then
        G.headerRows[players.head] = true
        for _, cell in ipairs(players.head.cols or {}) do if H.Allowed(cell) then G.headerCells[cell] = true end end
        H.Hook(players, "SetDisplayCols", function()
            Organizer(C)
            G.Queue(players.head)
        end)
    end
    G.cogs = G.cogs or setmetatable({}, {__mode = "k"})
    if ui then
        for _, button in pairs({ui.SettingsButton, ui.RollTrackingSettingsButton}) do
            if H.Allowed(button) then G.cogs[button] = true end
        end
    end
end
local function Utility(C, f)
    local H, G = C.H, C.gargul
    if G.cogs and G.cogs[f] then
        if not f.euiGargulCog then
            local icon = f:CreateTexture(nil, "OVERLAY", nil, 6)
            icon:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\cogs-3.png")
            local size = math.min(12, f:GetWidth(), f:GetHeight())
            icon:SetSize(size, size); icon:SetPoint("CENTER", f, "CENTER")
            icon:SetVertexColor(0.8, 0.8, 0.8, 1); f.euiGargulCog = icon
            H.Fade(f.texture)
        end
        FlatControl(C, f, "Button", {"euiGargulCog"})
        return true
    end
    local normal = f.GetNormalTexture and H.Texture(f:GetNormalTexture())
    local path = normal and normal:GetTexture()
    if type(path) ~= "string" or not path:lower():find("gargul[/\\]assets[/\\]buttons[/\\]") then return false end
    -- Keep the native state textures rather than copying the currently visible
    -- one: enabled, disabled, hover and pressed states continue to work.
    local keys = {}
    for _, state in ipairs({"Normal", "Disabled", "Pushed", "Highlight"}) do
        local getter = f["Get" .. state .. "Texture"]
        local texture = getter and H.Texture(getter(f))
        local asset = texture and texture:GetTexture()
        if type(asset) == "string" and asset:lower():find("gargul[/\\]assets[/\\]buttons[/\\]") then
            local key = "euiGargul" .. state
            f[key] = texture; keys[#keys + 1] = key
        end
    end
    FlatControl(C, f, "Button", keys)
    return true
end
local function CandyBar(C, f)
    local H, S, G = C.H, C.S, C.gargul
    H.Font(f.candyBarLabel); H.Font(f.candyBarDuration)
    local bar, path = f.candyBarBar, "Interface\\Buttons\\WHITE8X8"
    local fill = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if bar.SetStatusBarTexture and (not fill or not fill.GetTexture or fill:GetTexture() ~= path) then
        bar:SetStatusBarTexture(path)
        fill = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    end
    -- A separate texture alpha mutes the rendering without replacing native
    -- SetColor thresholds/alpha or running another callback on every tick.
    if H.Texture(fill) and fill:GetAlpha() ~= 0.65 then fill:SetAlpha(0.65) end
    local background = H.Texture(f.candyBarBackground)
    if background and background:GetTexture() ~= path then background:SetTexture(path) end
    if H.Texture(f.candyBarIconFrame) then S.SquareIcon(f.candyBarIconFrame) end
    G.timers = G.timers or setmetatable({}, {__mode = "k"})
    local d = G.timers[f]
    if not d then
        local separator = f:CreateTexture(nil, "OVERLAY", nil, 5)
        separator:SetPoint("TOPLEFT", f, "TOPLEFT"); separator:SetPoint("TOPRIGHT", f, "TOPRIGHT")
        separator:SetHeight(1); separator:SetColorTexture(1, 1, 1, 0.08)
        d = {separator = separator}; G.timers[f] = d
    end
    local _, size = f.candyBarDuration:GetFont()
    local width = math.max(40, (size or 12) * 4)
    local owner = f.GetParent and f:GetParent()
    if d.width ~= width or d.bar ~= bar or d.owner ~= owner then
        local timer, label = f.candyBarDuration, f.candyBarLabel
        timer:ClearAllPoints()
        timer:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -6, -1)
        timer:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -6, 1)
        timer:SetWidth(width)
        label:ClearAllPoints()
        label:SetPoint("TOPLEFT", bar, "TOPLEFT", 6, -1)
        label:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -(width + 12), 1)
        if label.SetWordWrap then label:SetWordWrap(false) end
        d.width, d.bar, d.owner = width, bar, owner
    end
end

local function Scroll(C, f)
    C.H.LegacySlider(f)
    local thumb = f.GetThumbTexture and f:GetThumbTexture()
    if thumb then
        if f.GetOrientation and f:GetOrientation() == "HORIZONTAL" then thumb:SetSize(8, 12)
        else thumb:SetWidth(5) end -- Retain proportional height, hit area and range.
    end
end
local function Check(C, widget)
    local G, H = C.gargul, C.H
    G.checks = G.checks or setmetatable({}, {__mode = "k"})
    local paint = G.checks[widget]
    if not paint then
        paint = function()
            if InCombatLockdown and InCombatLockdown() then C.module.refresh(); return end
            local r, g, b = C.S.GetAccentColor()
            widget.checkbg:SetColorTexture(0.1, 0.1, 0.11, 1)
            widget.checkbg:SetTexCoord(0, 1, 0, 1); widget.checkbg:SetSize(16, 16)
            widget.check:ClearAllPoints(); widget.check:SetPoint("CENTER", widget.checkbg, "CENTER")
            widget.check:SetSize(8, 8); widget.check:SetTexCoord(0, 1, 0, 1)
            widget.check:SetVertexColor(1, 1, 1, 1)
            if widget.check.SetBlendMode then widget.check:SetBlendMode("BLEND") end
            widget.check:SetColorTexture(widget.disabled and 0.5 or r, widget.disabled and 0.5 or g,
                widget.disabled and 0.5 or b, widget.tristate and widget.checked == nil and 0.45 or 1)
            if widget.highlight then widget.highlight:SetColorTexture(1, 1, 1, 0.06) end
            Tone(C, widget.text, widget.frame)
            if widget.desc then C.H.Font(widget.desc) end
        end
        G.checks[widget] = paint
        H.Hook(widget, "SetType", paint); H.Hook(widget, "SetDisabled", paint)
        H.Hook(widget, "SetValue", paint)
    end
    paint() -- Never change checked/disabled state, callbacks or native visibility.
end
local function Navigation(C)
    local G, H = C.gargul, C.H
    local _, _, nav, sections = G.Settings()
    if not H.Allowed(nav) then return end
    C.Panel(nav)
    -- lib-st normally shares its default highlight table across instances.
    -- Give only this navigation table a private neutral highlight definition.
    G.navHighlight = G.navHighlight or {r = 1, g = 1, b = 1, a = 0.07}
    sections.defaulthighlight = G.navHighlight
    local function Highlight(_, row, color)
        if H.Texture(row and row.highlight) then row.highlight:SetColorTexture(1, 1, 1, color and color.a or 0) end
    end
    H.Hook(sections, "SetHighLightColor", Highlight)
    local selected = sections.GetSelection and sections:GetSelection() or sections.selected
    G.markers = G.markers or setmetatable({}, {__mode = "k"})
    for index, row in ipairs(sections.rows or {}) do
        if H.Allowed(row) then
            local marker = G.markers[row]
            if not marker then
                marker = row:CreateTexture(nil, "OVERLAY", nil, 7)
                marker:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)
                marker:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 1); marker:SetWidth(2)
                G.markers[row] = marker
            end
            local real = sections.filtered and sections.filtered[index + (sections.offset or 0)] or index
            local r, g, b = C.S.GetAccentColor()
            marker:SetColorTexture(r, g, b, 1); marker:SetShown(selected ~= nil and real == selected)
            if H.Texture(row.highlight) then
                row.highlight:SetColorTexture(1, 1, 1, real == selected and 0.07 or 0)
            end
        end
    end
end
-- AceGUI pullouts are shared pools, not Gargul windows. Skin a separate child
-- and restore native backdrop/text/check tint when closed or reused elsewhere.
local function Pullout(C, widget)
    local G, H = C.gargul, C.H
    local popup = widget.pullout
    if type(popup) ~= "table" or not H.Allowed(popup.frame) then return end
    G.popups = G.popups or setmetatable({}, {__mode = "k"})
    local d = G.popups[popup]
    if d then return end
    d = {}; G.popups[popup] = d
    local function Restore()
        if not d.active then return end
        d.active = false
        if d.layer then d.layer:SetAlpha(0) end
        if popup.frame.SetBackdrop then popup.frame:SetBackdrop(d.backdrop) end
        if d.background and popup.frame.SetBackdropColor then popup.frame:SetBackdropColor(unpack(d.background)) end
        if d.border and popup.frame.SetBackdropBorderColor then popup.frame:SetBackdropBorderColor(unpack(d.border)) end
        for text, state in pairs(d.fonts or {}) do
            if state[1] then text:SetFont(state[1], state[2], state[3]) end
            text:SetTextColor(unpack(state.color))
        end
        for texture, state in pairs(d.tints or {}) do
            texture:SetVertexColor(unpack(state))
            if texture.SetDesaturated then texture:SetDesaturated(state.desaturated or false) end
        end
        d.fonts, d.tints = nil, nil
    end
    local function Owned()
        local owner = popup.userdata and popup.userdata.obj
        local f = owner and owner.frame
        for _ = 1, 24 do
            if not H.Allowed(f) then break end
            if G.registered[f] or G.windows[f] then return true end
            f = f.GetParent and f:GetParent()
        end
        return false
    end
    local function Paint()
        if not ns.IsEnabled(C.module) or not Owned() then Restore(); return end
        if InCombatLockdown and InCombatLockdown() then C.module.refresh(); return end
        if not d.active then
            d.active, d.fonts, d.tints = true, {}, {}
            d.backdrop = popup.frame.GetBackdrop and popup.frame:GetBackdrop()
            if popup.frame.GetBackdropColor then d.background = {popup.frame:GetBackdropColor()} end
            if popup.frame.GetBackdropBorderColor then d.border = {popup.frame:GetBackdropBorderColor()} end
        end
        if not d.layer then
            d.layer = CreateFrame("Frame", nil, popup.frame)
            d.layer:SetAllPoints(popup.frame); d.layer:EnableMouse(false)
            if d.layer.SetFrameLevel and popup.frame.GetFrameLevel then d.layer:SetFrameLevel(math.max(0, popup.frame:GetFrameLevel() - 1)) end
            C.S.Panel(d.layer, {noBorder = true})
        end
        d.layer:SetAlpha(1)
        if popup.frame.SetBackdrop then popup.frame:SetBackdrop(nil) end
        local r, g, b = C.S.GetAccentColor()
        for _, item in ipairs(popup.items or {}) do
            local text = item.text
            if H.Allowed(text) then
                if not d.fonts[text] then
                    d.fonts[text] = {text:GetFont()}; d.fonts[text].color = {text:GetTextColor()}
                end
                C.H.Font(text) -- Preserve native disabled/title colours and size.
            end
            for _, pair in ipairs({{item.check, r, g, b}, {item.sub, 0.8, 0.8, 0.8}, {item.highlight, 1, 1, 1}}) do
                local texture = pair[1]
                if H.Texture(texture) then
                    if not d.tints[texture] then
                        d.tints[texture] = {texture:GetVertexColor()}
                        d.tints[texture].desaturated = texture.IsDesaturated and texture:IsDesaturated()
                    end
                    if texture.SetDesaturated then texture:SetDesaturated(true) end
                    texture:SetVertexColor(pair[2], pair[3], pair[4], texture == item.highlight and 0.1 or 1)
                end
            end
        end
    end
    d.Paint, d.Restore = Paint, Restore
    H.Hook(popup, "Open", Paint)
    -- Cleanup deliberately runs even after the skin is disabled.
    popup.frame:HookScript("OnHide", Restore)
    if type(popup.Close) == "function" then hooksecurefunc(popup, "Close", Restore) end
    if type(popup.OnRelease) == "function" then hooksecurefunc(popup, "OnRelease", Restore) end
    if C.S.OnLooksChanged then C.S.OnLooksChanged(function() if d.active then Paint() end end) end
end

ns.RegisterScopedSkin("Gargul", "Gargul", {
    softBorders = true,
    borderlessButtons = function() return true end,
    available = function() return type(_G.Gargul) == "table" and type(_G.Gargul.Interface) == "table" end,
    immediateShow = true,
    font = function(S, text, r, g, b)
        local label = labelOwners[text]
        if label then
            local disabled = type(label) ~= "boolean" and label.IsEnabled and not label:IsEnabled()
            r, g, b = disabled and 0.5 or 0.9, disabled and 0.5 or 0.9, disabled and 0.52 or 0.92
        end
        local owner = navigationText[text]
        if owner and owner.navigation[text:GetParent()] then r, g, b = 0.9, 0.9, 0.92 end
        local cr, cg, cb, ca
        if r == nil and text.GetTextColor then cr, cg, cb, ca = text:GetTextColor() end
        -- LibScrollingTable defaults to dark text on a light native background.
        -- Keep class/status colours, but make its near-black labels readable.
        if cr and math.max(cr, cg, cb) < 0.25 then
            local parent = text:GetParent()
            if parent and parent.IsEnabled and not parent:IsEnabled() then r, g, b = 0.55, 0.55, 0.58
            else r, g, b = 0.9, 0.9, 0.92 end
        end
        if r == nil and cr then r, g, b = cr, cg, cb end
        Font(S, text, r, g, b, ca)
    end,
    panelOptions = {noBorder = true, noBg = true},
    controlRefresh = function(C, root, source) Routing(C); C.gargul.Route(root, source) end,
    roots = function(C)
        Routing(C)
        local G, H = C.gargul, C.H
        local window, page, nav, sections = G.Settings()
        if H.Allowed(nav) then
            C.navigation[nav] = true
            for _, method in ipairs({"Refresh", "SetSelection", "SetData"}) do
                H.Hook(sections, method, function() G.Queue(nav) end)
            end
        end
        for scope in pairs(G.scopes) do G.Remember(scope) end
        local roots, added = {}, {}
        local function Add(f, controls)
            if not H.Allowed(f) or added[f] then return end
            added[f], G.registered[f] = true, true
            -- Scoped window roots refresh on show; control-only settings roots
            -- instead consume their own construction burst at showSection.
            if controls then H.Script(f, "OnShow", function() G.Queue(f) end) end
            roots[#roots + 1] = {frame = f, mode = controls and "controls" or nil,
                options = {noAccent = true, noTopBar = true}, exclude = G.Exclude(f)}
        end
        for _, name in ipairs({"GARGUL_SETTING_WINDOW", "GargulUI_RollerUI_Window", "GARGUL_GDKP_BIDDER_WINDOW"}) do
            if H.Allowed(_G[name]) then G.windows[_G[name]] = true end
        end
        for _, f in pairs(_G.Gargul.UI and _G.Gargul.UI.components or {}) do
            if H.Allowed(f) and f:GetObjectType() == "Frame" and f:GetParent() == UIParent then G.windows[f] = true end
        end
        for f in pairs(G.windows) do Add(f) end
        Add(window); Add(page, true); Add(nav, true)
        for root in pairs(G.dirty) do G.dirty[root] = nil end
        return roots
    end,
    hooks = function(C)
        fontGeneration = fontGeneration + 1
        Routing(C)
        C.gargul.Navigation = function() Navigation(C) end
        C.gargul.Prepare = function(root) Organizer(C, root) end
        Organizer(C)
        C.gargul.Discover() -- Only full load/theme refreshes rediscover adapters.
    end,
    visit = function(C, f, kind, refresh)
        local H, S = C.H, C.S
        if C.gargul.windows[f] then Matte(C, f) end
        if C.navigation[f:GetParent()] then C.navigation[f] = true end
        if C.navigation[f] then
            for _, region in ipairs(H.Regions(f)) do
                local layer = region.GetDrawLayer and region:GetDrawLayer()
                if H.Texture(region) and (layer == "BACKGROUND" or layer == "BORDER") then H.Fade(region) end
            end
            local _, _, nav = C.gargul.Settings()
            if f == nav then Navigation(C) end
            for _, text in ipairs(H.Regions(f)) do
                if text:GetObjectType() == "FontString" then
                    navigationText[text] = C
                    H.Font(text, 0.9, 0.9, 0.92)
                    local painting = false
                    H.Hook(text, "SetTextColor", function(_, r, g, b)
                        if painting or not C.navigation[f] or r == 0.9 and g == 0.9 and b == 0.92 then return end
                        painting = true; text:SetTextColor(0.9, 0.9, 0.92, 1); painting = false
                    end)
                end
            end
            if kind ~= "Slider" then return true end
        end
        for _, text in ipairs(H.Regions(f)) do
            if text:GetObjectType() == "FontString" and type(text._SetFont) == "function" then
                H.Hook(text, "SetFont", function()
                    if InCombatLockdown and InCombatLockdown() then C.module.refresh() else S.Font(text) end
                end)
            end
        end
        if C.gargul.headerCells and C.gargul.headerCells[f] then
            Tone(C, f.GetFontString and f:GetFontString(), f)
            return true
        end
        if C.gargul.headerRows and C.gargul.headerRows[f] then
            FlatControl(C, f, "Panel", {noBorder = true})
            return true
        end
        if f.candyBarBar and f.candyBarLabel then CandyBar(C, f); return true end
        if kind == "StatusBar" then return true end -- Keep native timing/threshold colours.
        if kind == "Slider" then Scroll(C, f); return true end
        if kind == "EditBox" then
            S.Font(f)
            if type(f._SetFont) == "function" then
                H.Hook(f, "SetFont", function()
                    if InCombatLockdown and InCombatLockdown() then C.module.refresh() else S.Font(f) end
                end)
            end
            -- AceGUI already positions these fields inside its layout. EUI's
            -- optional six-pixel widening makes adjacent fields/buttons overlap.
            if not (f.IsMultiLine and f:IsMultiLine()) then FlatControl(C, f, "EditBox", {padInput = false}) end
            return true
        end
        if type(f.initialize) == "function" then C.MenuOwner(f); FlatControl(C, f, "Dropdown") end
        local widget = f.obj
        if widget and widget.frame == f then
            Tone(C, widget.titletext, f)
            if widget.type == "CheckBox" and widget.checkbg and widget.check then Check(C, widget); return true end
            if widget.type == "Dropdown" then
                FlatControl(C, H.Allowed(widget.dropdown) and widget.dropdown or f, "Dropdown")
                if H.Allowed(widget.button) then
                    for _, r in ipairs(H.Regions(widget.button)) do if H.Texture(r) then H.Fade(r) end end
                end
                Tone(C, widget.text, widget.frame); Tone(C, widget.label, widget.frame)
                Pullout(C, widget)
                return true
            end
            if widget.type == "Button" then FlatControl(C, f, "Button"); return true end
            if widget.closebtn and H.Allowed(widget.closebtn) then H.Action(widget.closebtn) end
            if widget.sizer_se then H.Resize(widget.sizer_se, true) end
            if widget.type == "Icon" and H.Texture(widget.image) then S.SquareIcon(widget.image); return true end
            if widget.type == "TabGroup" then
                for _, tab in pairs(widget.tabs or {}) do if H.Allowed(tab) then H.Tab(tab, tab.selected and true or false) end end
                H.Hook(widget, "SelectTab", function() C.gargul.Route(f, f) end)
            end
        end
        if kind == "Button" then
            if Utility(C, f) then return true end
            if H.Allowed(f.MinimizeButton) then H.Toggle(f.MinimizeButton, true) end
            if H.Allowed(f.MaximizeButton) then H.Toggle(f.MaximizeButton, false) end
            H.Resize(f)
            local icon = H.Texture(f.Texture)
            if icon then
                H.Action(f, {"Texture", "Count", "IconBorder", "Cooldown"})
                S.SquareIcon(icon, f:GetWidth() == f:GetHeight() and f or nil)
                return true
            end
            local label = f.GetFontString and f:GetFontString()
            if H.Allowed(label) and not f.icon and not f.Icon then FlatControl(C, f, "Button"); return true end
        end
    end,
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("Gargul", DefineSkin)
else DefineSkin() end
