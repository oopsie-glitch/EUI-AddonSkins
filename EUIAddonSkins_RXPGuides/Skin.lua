local ADDON, ns = ...
-- Standalone skin addons receive their own namespace from WoW.
if ADDON ~= "EUIAddonSkins" then
    ns = EUIAddonSkins and EUIAddonSkins.GetSkinNamespace(ADDON)
    if not ns then return end
    ADDON = "EUIAddonSkins"
end
ns.RegisterModule("RXPGuides", "RestedXP Guides", function()
    return _G.RXP and type(_G.RXP.LoadActiveTheme) == "function"
end, function(S, module)
    S = ns.CreateSoftSkin(S, module)
    local addon = _G.RXP
    local H = ns.CreateSkinHelper(S, module)
    local refresh, applyWaiting, themeWaiting
    local themed = setmetatable({}, {__mode = "k"})
    local targetSeen
    local copies, wrapped = setmetatable({}, {__mode = "k"}), {}
    local unpack = unpack or table.unpack
    local function Pack(...) return {n = select("#", ...), ...} end
    local function Copy(t)
        local out = {}; for k, v in pairs(t or {}) do out[k] = v end; return out
    end
    local function Theme(source)
        if type(source) ~= "table" then return source end
        local out = copies[source]
        if not out then out = Copy(source); copies[source] = out end
        local r, g, b = S.GetAccentColor()
        local pr, pg, pb, pa = S.GetPanelColor()
        out.font = S.GetFont()
        -- Session copies leave registered themes, saved choices and semantic colors intact.
        if source.backgroundColors then
            out.backgroundColors = Copy(source.backgroundColors)
            for _, key in ipairs({"common", "guideName", "guideWindow", "scrollbar", "inactivePartyTab", "activeStepCheckbox"}) do
                out.backgroundColors[key] = {pr, pg, pb, pa}
            end
            out.backgroundColors.activeStepCheckboxChecked = {r, g, b, 1}
            out.borderColors = Copy(source.borderColors)
            for _, key in ipairs({"common", "commonEdge", "inactivePartyTab"}) do
                out.borderColors[key] = {0.055, 0.055, 0.055, 1}
            end
            out.borderColors.activeStepCheckboxChecked = {r, g, b, 1}
            out.textColor = Copy(source.textColor)
            out.textColor.common = {0.9, 0.9, 0.92, 1}
            out.textColor.title = {r, g, b, 1}
            out.textColor.inactivePartyTab = {0.65, 0.65, 0.68, 1}
            out.edge = Copy(source.edge)
            out.edge.edgeFile = "Interface/Buttons/WHITE8X8"
            out.edge.edgeSize = 1
            out.edge.texCoords = {top = {0, 1, 0, 1}, bottom = {0, 1, 0, 1}, left = {0, 1, 0, 1}, right = {0, 1, 0, 1}}
        else
            out.background = {pr, pg, pb, pa}
            out.bottomFrameBG = {pr, pg, pb, pa}
            out.bottomFrameHighlight = {r, g, b, 1}
            out.textColor = {0.9, 0.9, 0.92}
        end
        return out
    end
    local function Wrap(object, name, legacy)
        if not object or wrapped[object] or type(object[name]) ~= "function" then return end
        wrapped[object] = true
        local original = object[name]
        object[name] = function(...)
            local result = Pack(original(...))
            if ns.IsEnabled(module) and type(result[1]) == "table" then
                result[1] = Theme(result[1])
                object.activeTheme = result[1]
                if legacy then
                    addon.colors, addon.font = result[1], result[1].font
                    local f = addon.RXPFrame or _G.RXPFrame
                    for _, key in ipairs({"edge", "guideName", "bottom"}) do
                        local backdrop = f and f.backdrop and f.backdrop[key]
                        if backdrop then
                            backdrop.bgFile = "Interface/Buttons/WHITE8X8"
                            backdrop.edgeFile = key ~= "bottom" and "Interface/Buttons/WHITE8X8" or nil
                            backdrop.edgeSize = 1
                            -- RXP's original 8px artwork used asymmetric 2-4px
                            -- fill insets. Match the fill to our thin border.
                            local inset = key ~= "bottom" and 1 or 0
                            backdrop.insets = {left = inset, right = inset, top = inset, bottom = inset}
                        end
                    end
                end
            end
            return unpack(result, 1, result.n)
        end
    end
    local SyncShell
    local borderLocks = {}
    local function TintBackdrop(f)
        if InCombatLockdown and InCombatLockdown() then return end
        if not f or (f.IsForbidden and f:IsForbidden()) then return end
        -- Legacy scrollbar geometry and its track/arrow chrome stay unchanged.
        if f.GetObjectType and f:GetObjectType() == "Slider" then return end
        local legacy = addon.RXPFrame or _G.RXPFrame
        local bar = legacy and legacy.ScrollFrame and legacy.ScrollFrame.ScrollBar
        if bar and (f == bar.ScrollUpButton or f == bar.ScrollDownButton
            or f.GetParent and f:GetParent() == bar) then return end
        if f.GetBackdrop and f.SetBackdropBorderColor then
            local backdrop = f:GetBackdrop()
            local function PaintBorder(_, r, g, b)
                if borderLocks[f] then return end
                if InCombatLockdown and InCombatLockdown() then if refresh then refresh() end; return end
                if r == nil and f.GetBackdropBorderColor then r, g, b = f:GetBackdropBorderColor() end
                -- Checked/status borders retain their semantic accent colour.
                if r and g and b and (math.abs(r - g) > 0.04 or math.abs(r - b) > 0.04) then return end
                borderLocks[f] = true
                f:SetBackdropBorderColor(0.055, 0.055, 0.055, 1)
                borderLocks[f] = false
            end
            if backdrop and backdrop.edgeFile then PaintBorder() end
            H.Hook(f, "SetBackdropBorderColor", PaintBorder)
            -- Native SetBackdrop resets border color to white. Correct it in
            -- the same call stack, before the client can draw another frame.
            H.Hook(f, "SetBackdrop", function()
                if InCombatLockdown and InCombatLockdown() then return end
                local current = f:GetBackdrop()
                if current and current.edgeFile then PaintBorder() end
                local entry = themed[f]
                if entry then
                    SyncShell(f, entry)
                end
            end)
        end
    end
    local function Scan(f)
        if H.Allowed(f) then H.Scan(f, refresh, TintBackdrop) end
    end
    local function CombatLocked()
        return InCombatLockdown and InCombatLockdown()
    end
    local slimThumbs = {}
    local function LegacyChrome(f)
        if CombatLocked() or not f then return end
        local header = f.GuideName
        if H.Allowed(header) then
            local icon, class = H.Texture(header.icon), H.Texture(header.classIcon)
            if icon then
                icon:ClearAllPoints(); icon:SetPoint("TOPLEFT", header, "TOPLEFT", 6, -3)
                icon:SetSize(28, 28); S.SquareIcon(icon)
            end
            if class and icon then
                class:ClearAllPoints(); class:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -1)
                class:SetSize(12, 12); S.SquareIcon(class)
            end
            if header.text then
                header.text:ClearAllPoints()
                header.text:SetPoint("LEFT", header, "LEFT", 42, 0)
                header.text:SetPoint("RIGHT", header, "RIGHT", -6, 0)
            end
        end
        local scroll = f.ScrollFrame and f.ScrollFrame.ScrollBar
        if H.Allowed(scroll) then
            local visual = slimThumbs[scroll]
            H.LegacySlider(scroll, visual and visual.fill)
            local thumb = scroll.GetThumbTexture and H.Texture(scroll:GetThumbTexture())
            if thumb then
                if not visual then
                    visual = {fill = scroll:CreateTexture(nil, "OVERLAY")}
                    slimThumbs[scroll] = visual
                    visual.fill:SetWidth(4)
                end
                if visual.thumb ~= thumb then
                    visual.thumb = thumb
                    visual.fill:ClearAllPoints()
                    visual.fill:SetPoint("TOP", thumb, "TOP")
                    visual.fill:SetPoint("BOTTOM", thumb, "BOTTOM")
                end
                -- Retain the native thumb geometry and drag hit area.
                H.Fade(thumb)
                local r, g, b = S.GetAccentColor()
                visual.fill:SetColorTexture(r, g, b, 0.8)
            end
        end
        if f.Footer and H.Allowed(f.Footer.icon) then H.Resize(f.Footer.icon, true) end
    end
    SyncShell = function(f, entry)
        if CombatLocked() then return end
        local shown = true
        if f.rxpBackground then
            shown = not f.rxpBackground.IsShown or f.rxpBackground:IsShown()
            f.rxpBackground:SetAlpha(0) -- native border/visibility still belongs to RXP
        elseif f.GetBackdrop then
            local backdrop = f:GetBackdrop()
            shown = backdrop and backdrop.bgFile and true or false
            if shown and f.SetBackdropColor and not entry.lock then
                entry.lock = true
                f:SetBackdropColor(0, 0, 0, 0)
                entry.lock = false
            end
        end
        entry.layer:SetAlpha(shown and entry.opacity or 0)
    end
    local function ThemeShell(f, footer)
        if not f or not f.GetFrameLevel or (not f.GetBackdrop and not f.rxpBackground) or CombatLocked()
            or (f.IsForbidden and f:IsForbidden()) then return end
        local entry = themed[f]
        if not entry then
            -- Own background-only child: never feed icon/guide regions to Shell.
            local layer = CreateFrame("Frame", nil, f)
            layer:SetAllPoints(f)
            layer:SetFrameLevel(f:GetFrameLevel())
            layer:EnableMouse(false)
            S.Shell(layer, {noBorder = true, noTopBar = true, bottomBar = footer})
            entry = {layer = layer, opacity = 1}
            local fill = f.rxpBackground and f.rxpBackground.textures and f.rxpBackground.textures[1]
            if fill and fill.GetVertexColor then
                local _, _, _, alpha = fill:GetVertexColor()
                entry.opacity = alpha or 1
            elseif f.GetBackdropColor then
                local _, _, _, alpha = f:GetBackdropColor()
                entry.opacity = alpha or 1
            end
            themed[f] = entry
            H.Hook(f, "SetBackdropColor", function(_, r, g, b, a)
                if entry.lock then return end
                entry.opacity = a or 1
                SyncShell(f, entry)
            end)
            H.Hook(f, "ClearBackdrop", function() SyncShell(f, entry) end)
            -- SetBackdrop already has the synchronous tint hook. Its callback
            -- below also handles removing/reinstating the native background.
        end
        SyncShell(f, entry)
    end
    local function TargetFrame()
        return addon.targeting and addon.targeting.activeTargetFrame
    end
    local function ApplyTargets()
        local f = TargetFrame()
        if not f or CombatLocked() or (f.IsForbidden and f:IsForbidden()) then return end
        -- The container has secure action-button children. Only touch its visual
        -- backdrop/title outside combat; never scan or skin those buttons.
        if targetSeen ~= f then
            targetSeen = f
            if f.UpdateVisuals then H.Safe(f.UpdateVisuals, f) end
            H.Hook(f, "UpdateVisuals", refresh)
        end
        TintBackdrop(f)
        TintBackdrop(f.title)
        ThemeShell(f)
        ThemeShell(f.title)
        ns.AttachAccent(S, f)
        local r, g, b = S.GetAccentColor()
        H.Font(f.title and f.title.text, r, g, b)
    end
    local function Apply()
        if CombatLocked() then applyWaiting = true; return end
        applyWaiting = false
        Wrap(addon.v2, "GetTheme")
        local legacy = addon.RXPFrame or _G.RXPFrame
        if legacy then
            LegacyChrome(legacy)
            Scan(legacy)
            -- Secure children may make the guide root implicitly protected. Tint
            -- only the known visual containers, without entering action buttons.
            for _, key in ipairs({"BottomFrame", "GuideName", "Footer"}) do TintBackdrop(legacy[key]) end
            ThemeShell(legacy.BottomFrame)
            ThemeShell(legacy.GuideName)
            ThemeShell(legacy.Footer, 20)
            ns.AttachAccent(S, legacy.GuideName)
            for _, step in pairs(legacy.CurrentStepFrame and legacy.CurrentStepFrame.framePool or {}) do
                TintBackdrop(step)
                TintBackdrop(step.number)
                ThemeShell(step)
                ThemeShell(step.number)
                ns.AttachAccent(S, step)
            end
            H.Hook(legacy, "UpdateVisuals", function() LegacyChrome(legacy); refresh() end)
            H.Hook(legacy, "UpdateScrollBar", function() LegacyChrome(legacy) end)
            H.Fade(legacy.GuideName and legacy.GuideName.bg)
            H.Fade(legacy.Footer and legacy.Footer.bg)
        end
        -- Inspect only existing widgets; GetGuideWindow would create one eagerly.
        local window = addon.v2 and addon.v2.state and addon.v2.state.guideWindow or _G.RXPV2GuideWindow
        if window then
            Scan(window.frame)
            for _, key in ipairs({"upperFrame", "guideNameFrame", "guideStepsFrame"}) do ThemeShell(window[key]) end
            ns.AttachAccent(S, window.upperFrame or window.frame)
            H.Fade(window.banner)
            H.Hook(window, "UpdateTheme", refresh)
            H.Hook(window, "UpdateSubTheme", refresh)
            H.Hook(window, "RefreshLayout", refresh)
            local r, g, b = S.GetAccentColor()
            H.Font(window.title, r, g, b)
            if window.closebutton and H.Allowed(window.closebutton) then S.CloseButton(window.closebutton) end
        end
        -- Active V2 steps are widgets kept outside the main guide window.
        local state = addon.v2 and addon.v2.state
        for _, player in pairs(state and state.player or {}) do
            local active = player.activeStepFrame
            for _, child in pairs(active and active.children or {}) do
                ThemeShell(child.card or child.frame)
                ThemeShell(child.title)
                ns.AttachAccent(S, child.card or child.frame)
            end
        end
        local party = state and state.activePartyStepFrame
        if party then ThemeShell(party.frame, 18); ns.AttachAccent(S, party.frame) end
        ApplyTargets()
        local importer = addon.guideImporter
        if importer then
            for _, widget in pairs(importer.widgets or {}) do
                if type(widget) == "table" then Scan(widget.frame) end
            end
            H.Hook(importer, "UpdateTheme", refresh)
        end
        S.RefreshSoftBorders()
    end
    refresh = function() H.Queue(module, Apply) end
    local function UpdateTheme()
        if not ns.IsEnabled(module) then return end
        if CombatLocked() then themeWaiting = true; return end
        themeWaiting = false
        if addon.settings and addon.settings.profile and addon.RXPFrame then
            H.Safe(addon.LoadActiveTheme, addon)
            -- Refresh visuals directly; RenderFrame also reloads the current guide.
            if addon.RXPFrame.UpdateVisuals then H.Safe(addon.RXPFrame.UpdateVisuals, addon.RXPFrame, true) end
        end
        local window = addon.v2 and addon.v2.state and addon.v2.state.guideWindow or _G.RXPV2GuideWindow
        if window and window.UpdateTheme then H.Safe(window.UpdateTheme, window, {updateChildren = true}) end
        if addon.v2 and addon.v2.UpdateActiveStepTheme and addon.v2.state and addon.v2.state.player and addon.player then
            H.Safe(addon.v2.UpdateActiveStepTheme, addon.v2)
        end
        if addon.guideImporter and addon.guideImporter.UpdateTheme then H.Safe(addon.guideImporter.UpdateTheme, addon.guideImporter) end
        local target = TargetFrame()
        if target and not CombatLocked() and target.UpdateVisuals then H.Safe(target.UpdateVisuals, target) end
        refresh()
    end
    Wrap(addon, "LoadActiveTheme", true)
    Wrap(addon.v2, "GetTheme")
    for _, name in ipairs({"RenderFrame", "LoadGuide", "SetStep"}) do H.Hook(addon, name, refresh) end
    for _, name in ipairs({"GetGuideWindow", "UpdateGuideWindow", "UpdateActiveStepTheme"}) do H.Hook(addon.v2, name, refresh) end
    if addon.ui and addon.ui.v2 then
        H.Hook(addon.ui.v2, "CreateGuideImporter", refresh)
        H.Hook(addon.ui.v2, "ApplyFrameBackdrop", function(_, f, edge, background)
            local entry = themed[f]
            if entry then entry.opacity = background and background[4] or 1; SyncShell(f, entry) end
            refresh()
        end)
        H.Hook(addon.ui.v2, "SetFrameBackdropShown", function(_, f)
            local entry = themed[f]
            if entry then SyncShell(f, entry) end
        end)
    end
    for _, name in ipairs({"CreateTargetFrame", "RenderTargetFrameBackground", "UpdateTargetFrame"}) do
        H.Hook(addon.targeting, name, refresh)
    end
    local combatEvents = CreateFrame("Frame")
    combatEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatEvents:SetScript("OnEvent", function()
        if themeWaiting then UpdateTheme()
        elseif applyWaiting then refresh() end
    end)
    if ns.BindPopupOwner then
        H.Hook(addon, "ShowMenu", function(_, _, owner)
            ns.BindPopupOwner(S, module, owner or (addon.RXPFrame and addon.RXPFrame.MenuFrame))
        end)
        if addon.RXPFrame then ns.BindPopupOwner(S, module, addon.RXPFrame.MenuFrame) end
        if S.OnLooksChanged then S.OnLooksChanged(ns.RefreshPopupMenus) end
    end
    module.refresh = UpdateTheme
    if S.OnLooksChanged then S.OnLooksChanged(UpdateTheme) end
    UpdateTheme()
end)
