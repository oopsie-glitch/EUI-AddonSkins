local ADDON, ns = ...

-- Each adapter supplies owned roots and explicit refresh hooks. No UIParent scan
-- or global frame-creation/AceGUI replacement is used.
function ns.RegisterScopedSkin(id, label, config)
    ns.RegisterModule(id, label, config.available, function(S, module)
        if config.softBorders then S = ns.CreateSoftSkin(S, module, config.borderlessButtons) end
        if config.preserveTextColors or config.font then
            local font, original = S.Font, S
            S = setmetatable({Font = function(text, r, g, b)
                if config.font then return config.font(original, text, r, g, b) end
                if r == nil and text.GetTextColor then
                    local cr, cg, cb, ca = text:GetTextColor()
                    font(text, cr, cg, cb)
                    text:SetTextColor(cr, cg, cb, ca)
                else font(text, r, g, b) end
            end}, {__index = S})
        end
        local H = ns.CreateSkinHelper(S, module)
        local styled, panels, checks, scanned = {}, {}, {}, {}
        local refresh, waiting, applying
        local events = CreateFrame("Frame")
        events:RegisterEvent("ADDON_LOADED")
        events:RegisterEvent("PLAYER_LOGIN")
        events:RegisterEvent("PLAYER_ENTERING_WORLD")
        events:RegisterEvent("PLAYER_REGEN_ENABLED")
        local C = {S = S, H = H, module = module}
        function C.MenuOwner(owner)
            if ns.BindPopupOwner then ns.BindPopupOwner(S, module, owner) end
        end
        local function PaintPanel(f)
            if not H.Allowed(f) then return end
            if panels[f] then
                if f.SetBackdrop then f:SetBackdrop(nil) end
                return
            end
            panels[f] = true
            -- Keep foreground artwork and icons when replacing panel backgrounds.
            local keep = {}
            for _, r in ipairs({f:GetRegions()}) do
                if r.GetTexture and r.GetDrawLayer and r:GetDrawLayer() ~= "BACKGROUND" and r:GetDrawLayer() ~= "BORDER" then
                    keep[r] = r:GetAlpha()
                end
            end
            S.Panel(f, config.panelOptions)
            for r, a in pairs(keep) do r:SetAlpha(a) end
            if f.SetBackdrop then
                f:SetBackdrop(nil)
                H.Hook(f, "SetBackdrop", function(_, value) if value then refresh() end end)
            end
        end
        C.Panel = PaintPanel
        local function Visit(f, kind)
            if kind == "Frame" and type(f.initialize) == "function" then C.MenuOwner(f) end
            if config.visit and config.visit(C, f, kind, refresh) then return true end
            if kind == "Button" and f.GetParent and styled[f:GetParent()] and f.GetPoint
                and not (f.GetFontString and f:GetFontString()) then
                local point, _, _, x, y = f:GetPoint(1)
                local w, h = f:GetWidth(), f:GetHeight()
                if point == "TOPRIGHT" and x and y and math.abs(x) <= 8 and math.abs(y) <= 8
                    and w >= 18 and w <= 36 and h >= 18 and h <= 36 then
                    S.CloseButton(f); return true
                end
            end
            for _, key in ipairs({"CloseButton", "closeButton"}) do
                if H.Allowed(f[key]) then S.CloseButton(f[key]) end
            end
            if H.Allowed(f.NineSlice) then
                S.FadeNineSlice(f.NineSlice)
                if f.Bg then H.Fade(f.Bg) end
            end
            if H.Allowed(f.ScrollBar) then S.ScrollBar(f.ScrollBar) end
            if H.Allowed(f.scrollbar) then S.ScrollBar(f.scrollbar) end
            if f.Inset and H.Allowed(f.Inset) then PaintPanel(f.Inset) end
            if kind == "Frame" and config.panels ~= false and not f.icon and not f.Icon
                and f.GetBackdrop and not styled[f] then
                local backdrop = f:GetBackdrop()
                if backdrop and backdrop.bgFile and not backdrop.bgFile:lower():find("icons") then PaintPanel(f) end
            end
            for _, r in ipairs({f:GetRegions()}) do H.Font(r) end
            -- Output text panes keep their existing scrolling/selection geometry.
            if kind == "EditBox" and f.IsMultiLine and f:IsMultiLine() then
                if f.SetFont and S.GetFont then
                    local _, size = f:GetFont()
                    local font, flags = S.GetFont()
                    f:SetFont(font, size or 12, flags or "")
                end
                H.Script(f, "OnShow", refresh)
                return true
            end
            if kind == "Button" and not f.icon and not f.Icon and not f.itemId and not f.itemID and not f.spellId then
                local text = (f.GetFontString and f:GetFontString()) or f.Text or f.text
                if text and text.GetObjectType and text:GetObjectType() == "FontString" then
                    S.Button(f, {"Text", "text"})
                    if S.StateButtonLabel then S.StateButtonLabel(f) end
                    if f.SetBackdrop then f:SetBackdrop(nil) end
                end
            end
            if kind == "Button" and (f.icon or f.Icon) and f.GetWidth and f:GetWidth() == f:GetHeight() then
                S.Button(f, {"icon", "Icon", "Count", "IconBorder", "Cooldown"})
            end
            -- AceGUI dropdowns and checkboxes wrap their actual control.
            local widget = f.obj
            if widget and widget.frame == f then
                if widget.type == "Dropdown" and H.Allowed(widget.dropdown) then
                    S.Dropdown(widget.dropdown)
                    if widget.button then
                        for _, r in ipairs({widget.button:GetRegions()}) do
                            if r.GetTexture then H.Fade(r) end
                        end
                    end
                end
                if widget.type == "CheckBox" and widget.checkbg and widget.check then
                    widget.checkbg:SetColorTexture(0.02, 0.02, 0.02, 1)
                    local r, g, b = S.GetAccentColor()
                    if widget.disabled then widget.check:SetVertexColor(0.5, 0.5, 0.5, 1)
                    else widget.check:SetVertexColor(r, g, b, 1) end
                    if not checks[f] then
                        checks[f] = true
                        -- AceGUI's checkbox is texture-based. Flat borders do
                        -- not replace its value, callbacks or show/hide logic.
                        for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
                            local edge = f:CreateTexture(nil, "ARTWORK")
                            edge:SetColorTexture(0.25, 0.25, 0.25, 1)
                            if side == "TOP" or side == "BOTTOM" then
                                edge:SetPoint(side .. "LEFT", widget.checkbg, side .. "LEFT")
                                edge:SetPoint(side .. "RIGHT", widget.checkbg, side .. "RIGHT")
                                edge:SetHeight(1)
                            else
                                edge:SetPoint("TOP" .. side, widget.checkbg, "TOP" .. side)
                                edge:SetPoint("BOTTOM" .. side, widget.checkbg, "BOTTOM" .. side)
                                edge:SetWidth(1)
                            end
                        end
                        H.Hook(widget, "SetType", refresh)
                        H.Hook(widget, "SetDisabled", refresh)
                    end
                    H.Font(widget.text)
                end
            end
        end
        local function Apply()
            if InCombatLockdown and InCombatLockdown() then waiting = true; return end
            waiting = false
            if config.hooks then config.hooks(C, refresh) end
            for _, target in ipairs(config.roots(C) or {}) do
                local f = target.frame or target
                if H.Allowed(f) then
                    if target.mode ~= "controls" and not styled[f] then
                        styled[f] = true
                        H.Shell(f, config.immediateShow and C.RefreshNow or refresh, target.options)
                        -- Some addons redraw their original window backdrop.
                        H.Hook(f, "SetBackdrop", function(_, value)
                            if value then refresh() end
                        end)
                    end
                    if styled[f] and f.SetBackdrop then f:SetBackdrop(nil) end
                    H.Script(f, "OnShow", config.immediateShow and C.RefreshNow or refresh)
                    -- A hidden root is walked once, which hooks its controls' OnShow;
                    -- after that only visible roots are walked. Hidden roots cannot
                    -- change the look, and showing one queues its own refresh.
                    if not scanned[f] or not f.IsVisible or f:IsVisible() then
                        scanned[f] = true
                        H.Scan(f, refresh, Visit, target.exclude)
                    end
                end
            end
            if S.RefreshSoftBorders then S.RefreshSoftBorders() end
        end
        -- Setter/data callbacks can repaint only their owned subtree instead
        -- of rediscovering and scanning every integration window.
        function C.RefreshControlsNow(root)
            if applying or not ns.IsEnabled(module) or not H.Allowed(root) then return end
            if InCombatLockdown and InCombatLockdown() then waiting = true; return end
            applying = true
            H.Safe(H.Scan, root, refresh, Visit)
            applying = false
        end
        local controlsPending = {}
        local function PaintControls()
            for root in pairs(controlsPending) do
                controlsPending[root] = nil
                C.RefreshControlsNow(root)
            end
        end
        function C.RefreshControls(root)
            if not ns.IsEnabled(module) or not H.Allowed(root) then return end
            controlsPending[root] = true
            H.Queue(controlsPending, PaintControls)
        end
        function C.RefreshNow()
            if applying or not ns.IsEnabled(module) then return end
            applying = true
            H.Safe(Apply)
            applying = false
        end
        refresh = function() H.Queue(module, Apply) end
        events:SetScript("OnEvent", function(_, event)
            if ns.IsEnabled(module) and (event ~= "PLAYER_REGEN_ENABLED" or waiting) then refresh() end
        end)
        module.refresh = refresh
        if S.OnLooksChanged then S.OnLooksChanged(refresh) end
        refresh()
    end)
end

function ns.SkinRoots(names, options)
    local result = {}
    for _, name in ipairs(names) do
        if _G[name] then result[#result + 1] = {frame = _G[name], options = options} end
    end
    return result
end
