local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("ForeverDungeonJournal", "Forever Dungeon Journal", function()
    local journal = _G.ForeverDungeonJournal_NS
    return journal and type(journal.ToggleJournal) == "function"
end, function(S, module)
    S = ns.CreateSoftSkin(S, module)
    local journal = _G.ForeverDungeonJournal_NS
    local H = ns.CreateSkinHelper(S, module)
    local refresh
    local fullQueued, fullSerial = false, 0
    local fontGeneration, fontCache = 0, setmetatable({}, {__mode = "k"})
    local applyFont = S.Font
    S.Font = function(text, r, g, b)
        if not H.Allowed(text) or not text.GetFont then return applyFont(text, r, g, b) end
        local path, size, flags = text:GetFont()
        if issecretvalue and (issecretvalue(path) or issecretvalue(size) or issecretvalue(flags)) then return applyFont(text, r, g, b) end
        local old = fontCache[text]
        if not old or old.generation ~= fontGeneration or old.path ~= path or old.size ~= size or old.flags ~= flags then
            applyFont(text, r, g, b)
            path, size, flags = text:GetFont()
            if issecretvalue and (issecretvalue(path) or issecretvalue(size) or issecretvalue(flags)) then return end
            fontCache[text] = {path = path, size = size, flags = flags, generation = fontGeneration}
        elseif r then text:SetTextColor(r, g, b or r) end
    end
    local panels, watched = {}, {}
    local borderLocks = {}
    local canvases, checks, arrows, grips = {}, {}, {}, {}
    local visuals = setmetatable({}, {__mode = "k"})
    local scan = H.Scan
    H.Scan = function(root, callback, visit, excluded)
        local exclude = setmetatable({}, {__index = visuals})
        for f, value in pairs(excluded or {}) do exclude[f] = value end
        return scan(root, callback, visit, exclude)
    end
    local function Busy()
        return InCombatLockdown and InCombatLockdown()
    end
    local function Gradient(t, first, last)
        t:SetColorTexture(1, 1, 1, 1)
        if t.SetGradient and CreateColor then
            t:SetGradient("HORIZONTAL", CreateColor(0.19, 0.19, 0.20, first), CreateColor(0.19, 0.19, 0.20, last))
        elseif t.SetGradientAlpha then t:SetGradientAlpha("HORIZONTAL", 0.19, 0.19, 0.20, first, 0.19, 0.19, 0.20, last)
        else t:SetColorTexture(0.12, 0.12, 0.13, 0.3) end
    end
    local function Canvas(f)
        if not H.Allowed(f) or not f.CreateTexture or canvases[f] then return end
        local layer = CreateFrame("Frame", nil, f); visuals[layer] = true
        layer:SetAllPoints(f); layer:EnableMouse(false)
        if layer.SetFrameLevel and f.GetFrameLevel then layer:SetFrameLevel(f:GetFrameLevel()) end
        local base = layer:CreateTexture(nil, "BACKGROUND", nil, 1); base:SetAllPoints(layer)
        base:SetColorTexture(0.055, 0.055, 0.06, 0.96)
        local left = layer:CreateTexture(nil, "BACKGROUND", nil, 2)
        left:SetPoint("TOPLEFT", f, "TOPLEFT"); left:SetPoint("BOTTOMRIGHT", f, "BOTTOM")
        Gradient(left, 0, 0.48)
        local right = layer:CreateTexture(nil, "BACKGROUND", nil, 2)
        right:SetPoint("TOPLEFT", f, "TOP"); right:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT")
        Gradient(right, 0.48, 0)
        canvases[f] = {base, left, right}
    end
    local function Arrow(button, direction)
        if not H.Allowed(button) or not button.CreateTexture then return end
        local icon = arrows[button]
        if not icon then
            icon = button:CreateTexture(nil, "OVERLAY")
            icon:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png")
            icon:SetSize(10, 7); icon:SetPoint("CENTER")
            if icon.SetRotation then icon:SetRotation(direction == "up" and math.pi or 0) end
            arrows[button] = icon
        end
        button.fdjSkinArrow = icon
        H.Action(button, {"fdjSkinArrow"})
        for _, text in ipairs(H.Regions(button)) do
            if text.GetObjectType and text:GetObjectType() == "FontString" then H.Fade(text) end
        end
        icon:SetAlpha(1); icon:SetVertexColor(0.8, 0.8, 0.82, 1)
    end
    local function Check(f)
        if not H.Allowed(f) then return end
        if not checks[f] then
            checks[f] = true
            S.Checkbox(f, {borderInset = 4, hover = 0.08})
            local function Paint() if Busy() then module.combatPending = true else Check(f) end end
            for _, name in ipairs({"SetCheckedTexture", "SetDisabledCheckedTexture", "Enable", "Disable"}) do H.Hook(f, name, Paint) end
            H.Script(f, "OnEnable", Paint); H.Script(f, "OnDisable", Paint)
        end
        for _, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
            local mark = f[getter] and H.Texture(f[getter](f))
            if mark then
                mark:SetVertexColor(1, 1, 1, 1)
                if f.IsEnabled and not f:IsEnabled() then mark:SetColorTexture(0.45, 0.45, 0.45, 0.8)
                else mark:SetColorTexture(S.GetAccentColor()) end
                mark:ClearAllPoints(); mark:SetPoint("TOPLEFT", f, "TOPLEFT", 7, -7)
                mark:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -7, 7)
            end
        end
        H.Font(f.fdjLabel)
    end
    local function Language(button)
        if not H.Allowed(button) then return end
        if not button.euiCaret and button.CreateTexture then
            local caret = button:CreateTexture(nil, "OVERLAY")
            caret:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png")
            caret:SetSize(10, 7); caret:SetPoint("RIGHT", button, "RIGHT", -8, 0)
            button.euiCaret = caret
        end
        H.Action(button, {"euiCaret"})
        if button.euiCaret then button.euiCaret:SetAlpha(1); button.euiCaret:SetVertexColor(0.8, 0.8, 0.82, 1) end
    end
    local function Grip(f)
        if not H.Allowed(f) or not f.CreateTexture then return end
        for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture", "GetHighlightTexture"}) do
            if f[getter] then H.Fade(f[getter](f)) end
        end
        if grips[f] then return end
        local lines = {}
        for i = 1, 2 do
            local t = f:CreateTexture(nil, "OVERLAY"); t:SetColorTexture(0.65, 0.65, 0.68, 0.65)
            t:SetSize(7 - (i-1)*3, 1); t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3 + (i-1)*3)
            if t.SetRotation then t:SetRotation(math.pi / 4) end
            lines[i] = t
        end
        grips[f] = lines
    end
    local unpack = unpack or table.unpack

    local function Palette()
        fontGeneration = fontGeneration + 1
        local r, g, b = S.GetAccentColor()
        -- Journal.lua caches this table; recolor in place without changing saved settings.
        for _, theme in pairs(journal.THEMES or {}) do
            theme.frame = {0.025, 0.025, 0.03, 0.98}
            theme.content = {0.035, 0.035, 0.04, 0.96}
            theme.header = {0.055, 0.055, 0.065, 0.96}
            theme.left = {0.025, 0.025, 0.03, 0.96}
            theme.right = {0.035, 0.035, 0.04, 0.96}
            theme.row = {0.06, 0.06, 0.07, 0.92}
            theme.lootRow = {0.06, 0.06, 0.07, 0.92}
            theme.rowSelected = {r * 0.25, g * 0.25, b * 0.25, 0.95}
            theme.border = {0.055, 0.055, 0.055, 1}
            theme.title = {r, g, b}
            theme.text = {0.9, 0.9, 0.92}
            theme.muted = {0.65, 0.65, 0.68}
        end
    end

    local function Panel(f)
        if not H.Allowed(f) or panels[f] then return end
        panels[f] = true
        -- Preserve foreground portrait/artwork regions while replacing the background.
        local artwork = {}
        for _, region in ipairs({f:GetRegions()}) do
            if region.GetTexture and region.GetDrawLayer then
                local layer = region:GetDrawLayer()
                if layer == "ARTWORK" or layer == "OVERLAY" then artwork[region] = region:GetAlpha() end
            end
        end
        S.Panel(f)
        for region, alpha in pairs(artwork) do region:SetAlpha(alpha) end
        if f.SetBackdrop then f:SetBackdrop(nil) end
    end

    local function ModeTab(tab)
        if not H.Allowed(tab) then return end
        -- Keep the journal's foreground icon; the API only preserves .Icon.
        if H.Texture(tab.fdjIcon) then tab.Icon = tab.fdjIcon end
        H.Tab(tab, tab.IsEnabled and not tab:IsEnabled() or false)
        -- UIPanelButtonTemplate can restore its state textures after Enable().
        -- Suppress only native chrome, never the EUI tab's own regions.
        for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture"}) do
            if tab[getter] then H.Fade(tab[getter](tab)) end
        end
        H.Fade(tab.text or (tab.GetFontString and tab:GetFontString()))
        for _, method in ipairs({"SetNormalTexture", "SetPushedTexture", "SetDisabledTexture", "SetHighlightTexture", "Enable", "Disable"}) do
            H.Hook(tab, method, function() ModeTab(tab) end)
        end
    end

    local function Visit(f, kind)
        local root = _G.ForeverDungeonJournalFrame
        if root and f == root.languageSelectorButton then Language(f); return true end
        if root and (f == root.bossesTab or f == root.questsTab or f == root.mapTab or f == root.dungeonRouteButton) then
            -- FDJ disables the active mode button. Mirror that visual state,
            -- including programmatic switches, without enabling/disabling it.
            ModeTab(f); return true
        end
        -- UIPanelCloseButton textures can be numeric file IDs on this client.
        -- Identify the unnamed journal close control by its exact owned anchor.
        if kind == "Button" and f.GetParent and f.GetPoint then
            local parent = f:GetParent()
            if parent == _G.ForeverDungeonJournalFrame or parent == _G.ForeverDungeonJournalSettings
                or parent == _G.ForeverDungeonJournalLootFilter then
                local point, relative, relativePoint, x, y = f:GetPoint(1)
                if point == "TOPRIGHT" and relative == parent and relativePoint == "TOPRIGHT"
                    and ((x == -3 and y == -3) or (x == -2 and y == -2)) then S.CloseButton(f) end
            end
        end
        if kind == "CheckButton" then Check(f); return true end
        if kind == "Slider" then
            H.LegacySlider(f)
            local thumb = f.GetThumbTexture and H.Texture(f:GetThumbTexture())
            if thumb and f.GetOrientation and f:GetOrientation() == "VERTICAL" then
                thumb:SetWidth(8)
                local name = f.GetName and f:GetName()
                Arrow(f.ScrollUpButton or name and _G[name .. "ScrollUpButton"], "up")
                Arrow(f.ScrollDownButton or name and _G[name .. "ScrollDownButton"], "down")
            end
            return true
        end
        if root and f == root.resizeGrip then Grip(f); return true end
        H.Resize(f)
        if kind == "Button" and f.art and f.dungeonName then
            -- Keep every artwork/status region and its native opacity, not just the image.
            H.ThinBackdrop(f)
            local function Border(_, r, g, b)
                if borderLocks[f] then return end
                if InCombatLockdown and InCombatLockdown() then refresh(); return end
                if r == nil and f.GetBackdropBorderColor then r, g, b = f:GetBackdropBorderColor() end
                local hover = r and g and b and r > 0.8 and g > 0.45 and b < 0.4
                if not hover and r and g and b and (math.abs(r - g) > 0.04 or math.abs(r - b) > 0.04) then return end
                if f.SetBackdropBorderColor then
                    borderLocks[f] = true
                    if hover then local cr, cg, cb = S.GetAccentColor(); f:SetBackdropBorderColor(cr, cg, cb, 1)
                    else f:SetBackdropBorderColor(0.055, 0.055, 0.055, 1) end
                    borderLocks[f] = false
                end
            end
            Border(); H.Hook(f, "SetBackdropBorderColor", Border)
            local r, g, b = S.GetAccentColor()
            H.Font(f.title, 0.93, 0.93, 0.95)
            if f.topShade then f.topShade:SetColorTexture(0, 0, 0, 0.26) end
            if f.innerGlow then f.innerGlow:SetColorTexture(0.2, 0.2, 0.22, 0.35) end
            for _, text in ipairs(H.Regions(f)) do H.Font(text) end
            return true
        end
        if kind == "Button" and f.SetBackdrop and not f.icon and not f.Icon and not f.itemID and not f.itemId then
            local label = (f.GetFontString and f:GetFontString()) or f.text or f.Text
            local parent = f.GetParent and f:GetParent()
            if label or (root and (f == root.languageSelectorButton or f == root.hideDungeonsButton
                or f == root.bugReportButton or f == root.favouritesButton or f == root.lootFilterButton
                or parent == root.homePanel or parent == root.languageMenu)) then
                local keep = {}
                for i, region in ipairs(H.Regions(f)) do
                    if region.GetTexture and region.GetDrawLayer and region:GetDrawLayer() == "ARTWORK" then
                        local key = "euiHeaderArtwork" .. i; f[key] = region; keep[#keep + 1] = key
                    end
                end
                H.Action(f, keep)
                for _, r in ipairs(H.Regions(f)) do H.Font(r, 1, 1, 1) end
                return true
            end
        end
        -- Brown text from the original parchment becomes unreadable on a dark panel.
        -- Keep item names/rarity, quest status indicators and portrait artwork intact.
        for _, key in ipairs({"slot", "meta"}) do H.Font(f[key], 0.65, 0.65, 0.68) end
    end

    local function Watch(f)
        if not H.Allowed(f) then return end
        H.Shell(f, refresh, {noTopBar = true})
        ns.AttachAccent(S, f)
        for _, key in ipairs({"fdjCloseButton", "CloseButton", "closeButton"}) do
            if H.Allowed(f[key]) then S.CloseButton(f[key]) end
        end
        local first = not watched[f]
        if first then
            watched[f] = true
            -- Private page renderers change panel colors; schedule after the whole render.
            H.Hook(f, "SetBackdropColor", refresh)
            H.Hook(f, "SetBackdropBorderColor", refresh)
        end
        local function Controls()
            if fullQueued then return end
            local serial = fullSerial
            H.Queue(f, function()
                if serial ~= fullSerial then return end
                if Busy() then module.combatPending = true; return end
                H.Scan(f, Controls, Visit, f.dungeonMapArtHolder and {[f.dungeonMapArtHolder] = true})
            end)
        end
        if first or not f.IsVisible or f:IsVisible() then
            H.Scan(f, Controls, Visit, f.dungeonMapArtHolder and {[f.dungeonMapArtHolder] = true})
        end
    end

    local function Apply()
        if not ns.IsEnabled(module) then fullQueued = false; return end
        if Busy() then module.combatPending = true; fullQueued = false; return end
        module.combatPending = false
        local f = _G.ForeverDungeonJournalFrame
        if f then
            Watch(f)
            for _, key in ipairs({"mapTab", "bossesTab", "questsTab", "dungeonRouteButton"}) do ModeTab(f[key]) end
            for _, key in ipairs({"contentPanel", "headerPanel", "homePanel", "leftPanel", "rightPanel",
                "questLeftPanel", "questRightPanel", "questTextInset", "routePanel"}) do Panel(f[key]) end
            Canvas(f.homePanel)
            for _, key in ipairs({"homeParchment", "contentParchment", "headerParchment", "leftParchment",
                "rightParchment", "questLeftParchment", "questRightParchment", "questParchment", "atmosphere"}) do H.Fade(f[key]) end
            for _, edge in ipairs(f.questInsetEdges or {}) do
                edge:SetColorTexture(0.055, 0.055, 0.055, 1)
            end
            for _, key in ipairs({"questDetailText", "questTurninText", "questRewardSummary", "selectedQuestMeta",
                "questStartsText", "questNotesText", "noQuestMessage", "selectedBossQuestion",
                "selectedBossDescription", "lootTitle"}) do
                H.Font(f[key], 0.85, 0.85, 0.88)
            end
            local r, g, b = S.GetAccentColor()
            H.Font(f.mainTitle, 1, 1, 1)
            H.Font(f.selectedQuestName, r, g, b)
            H.Font(f.homeTitle, r, g, b)
            H.Font(f.homeSubtitle, 0.65, 0.65, 0.68)
            H.Font(f.dungeonTitle, r, g, b)
            if f.homePanel then
                for _, t in ipairs(H.Regions(f.homePanel)) do
                    if t.GetHeight and t:GetHeight() == 1 and t.SetColorTexture then t:SetColorTexture(r, g, b, 0.7) end
                end
            end
            if f.languageMenu then Panel(f.languageMenu); H.Scan(f.languageMenu, refresh, Visit) end
            if f.languageSelectorButton then Language(f.languageSelectorButton); H.Font(f.languageSelectorText, 1, 1, 1) end
            for _, key in ipairs({"searchEditBox", "languageSelectorButton", "bugReportButton"}) do
                local control = f[key]
                if H.Allowed(control) and control.SetHeight and (not control.GetHeight or control:GetHeight() ~= 24) then control:SetHeight(24) end
            end
            if H.Allowed(f.searchEditBox) and f.searchEditBox.ClearAllPoints and not f.searchEditBox.fdjSkinAligned then
                f.searchEditBox:ClearAllPoints(); f.searchEditBox:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -15)
                f.searchEditBox.fdjSkinAligned = true
            end
            H.Font(f.searchPlaceholder, 0.65, 0.65, 0.68)
            local reportIcon = f.bugReportButton and H.Texture(f.bugReportButton.icon)
            if reportIcon then reportIcon:SetSize(18, 18) end
            H.Font(f.selectedBossName, r, g, b)
            for _, key in ipairs({"backButton"}) do
                if H.Allowed(f[key]) then S.Button(f[key]) end
            end
            if H.Allowed(f.questPrevStepButton) and S.SoftPageButton then S.SoftPageButton(f.questPrevStepButton, "<") end
            if H.Allowed(f.questNextStepButton) and S.SoftPageButton then S.SoftPageButton(f.questNextStepButton, ">") end
            for _, key in ipairs({"bugReportWindow", "lootFilterWindow", "favouritesWindow"}) do
                if f[key] then Watch(f[key]) end
            end
        end
        for _, name in ipairs({"ForeverDungeonJournalSettings", "ForeverDungeonJournalNotice",
            "ForeverDungeonJournalOptionsPanel", "ForeverDungeonJournalLootFilter",
            "ForeverDungeonJournalLootFilterResults", "ForeverDungeonJournalFavourites",
            "ForeverDungeonJournalFavouriteContextMenu"}) do
            local window = _G[name]
            -- The Blizzard Settings category is embedded, so only style its controls.
            if window then
                if name == "ForeverDungeonJournalOptionsPanel" then H.Scan(window, refresh)
                else Watch(window) end
            end
        end
        for _, name in ipairs({"OpenBossPage", "OpenQuestPage", "RefreshLootNow", "OpenSearchResult"}) do
            H.Hook(journal, name, refresh) -- Some exports appear only after first opening.
        end
        S.RefreshSoftBorders()
        fullQueued = false
    end
    refresh = function() fullQueued = true; fullSerial = fullSerial + 1; H.Queue(module, Apply) end
    for _, name in ipairs({"ToggleJournal", "ShowUpdateNotice", "ToggleSettingsPanel", "ToggleLootFilterWindow",
        "ToggleFavouritesWindow", "ToggleBugReportWindow", "RefreshHomeCards", "GoBackPage",
        "RefreshLootFilterResults", "RebuildLootFilterPage", "RefreshFavouritesWindow",
        "ShowItemFavouriteMenu", "ShowLootFilterResults", "RelocalizeLootFilter", "RefreshHomeDungeonCards",
        "RefreshQuestList", "RefreshQuestDetail", "ApplyTheme", "ApplyLocale"}) do H.Hook(journal, name, refresh) end
    -- Current workers finish through exported renderers. Keep the legacy
    -- one-shot worker fallback only when those exports are unavailable.
    if journal.questRefreshWorker and not (type(journal.RefreshQuestList) == "function" and type(journal.RefreshQuestDetail) == "function") then
        H.Script(journal.questRefreshWorker, "OnUpdate", refresh)
    end
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:SetScript("OnEvent", function() if module.combatPending then refresh() end end)
    Palette()
    refresh()
    module.refresh = refresh
    if S.OnLooksChanged then S.OnLooksChanged(function()
        if ns.IsEnabled(module) then Palette(); refresh() end
    end) end
end)

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("ForeverDungeonJournal", DefineSkin)
else DefineSkin() end
