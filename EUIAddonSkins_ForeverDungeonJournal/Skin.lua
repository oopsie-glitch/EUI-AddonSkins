local ADDON, ns = ...
-- Standalone skin addons receive their own namespace from WoW.
if ADDON ~= "EUIAddonSkins" then
    ns = EUIAddonSkins and EUIAddonSkins.GetSkinNamespace(ADDON)
    if not ns then return end
    ADDON = "EUIAddonSkins"
end
ns.RegisterModule("ForeverDungeonJournal", "Forever Dungeon Journal", function()
    local journal = _G.ForeverDungeonJournal_NS
    return journal and type(journal.ToggleJournal) == "function"
end, function(S, module)
    S = ns.CreateSoftSkin(S, module)
    local journal = _G.ForeverDungeonJournal_NS
    local H = ns.CreateSkinHelper(S, module)
    local refresh
    local panels, watched = {}, {}
    local borderLocks = {}
    local unpack = unpack or table.unpack

    local function Palette()
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
        if kind == "Slider" then H.LegacySlider(f); return true end
        H.Resize(f, root and f == root.resizeGrip)
        if kind == "Button" and f.art and f.dungeonName then
            -- Keep every artwork/status region and its native opacity, not just the image.
            H.ThinBackdrop(f)
            local function Border(_, r, g, b)
                if borderLocks[f] then return end
                if InCombatLockdown and InCombatLockdown() then refresh(); return end
                if r == nil and f.GetBackdropBorderColor then r, g, b = f:GetBackdropBorderColor() end
                if r and g and b and (math.abs(r - g) > 0.04 or math.abs(r - b) > 0.04) then return end
                if f.SetBackdropBorderColor then
                    borderLocks[f] = true
                    f:SetBackdropBorderColor(0.055, 0.055, 0.055, 1)
                    borderLocks[f] = false
                end
            end
            Border(); H.Hook(f, "SetBackdropBorderColor", Border)
            local r, g, b = S.GetAccentColor()
            H.Font(f.title, r, g, b)
            if f.innerGlow then f.innerGlow:SetColorTexture(r, g, b, 0.3) end
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
        if not watched[f] then
            watched[f] = true
            -- Private page renderers change panel colors; schedule after the whole render.
            H.Hook(f, "SetBackdropColor", refresh)
            H.Hook(f, "SetBackdropBorderColor", refresh)
        end
        H.Scan(f, refresh, Visit, f.dungeonMapArtHolder and {[f.dungeonMapArtHolder] = true})
    end

    local function Apply()
        local f = _G.ForeverDungeonJournalFrame
        if f then
            Watch(f)
            for _, key in ipairs({"mapTab", "bossesTab", "questsTab", "dungeonRouteButton"}) do ModeTab(f[key]) end
            for _, key in ipairs({"contentPanel", "headerPanel", "homePanel", "leftPanel", "rightPanel",
                "questLeftPanel", "questRightPanel", "questTextInset", "routePanel"}) do Panel(f[key]) end
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
            if f.languageSelectorButton then
                H.Action(f.languageSelectorButton)
                local button = f.languageSelectorButton
                if not button.euiCaret and button.CreateFontString then
                    local caret = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    caret:SetPoint("RIGHT", button, "RIGHT", -7, -3)
                    H.Font(caret, 1, 1, 1); caret:SetText("v")
                    button.euiCaret = caret
                end
                H.Font(button.euiCaret, 1, 1, 1)
                H.Font(f.languageSelectorText, 1, 1, 1)
            end
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
    end
    refresh = function() H.Queue(module, Apply) end
    for _, name in ipairs({"ToggleJournal", "ShowUpdateNotice", "ToggleSettingsPanel", "ToggleLootFilterWindow",
        "ToggleFavouritesWindow", "ToggleBugReportWindow", "RefreshHomeCards", "GoBackPage",
        "RefreshLootFilterResults", "RebuildLootFilterPage", "RefreshFavouritesWindow",
        "ShowItemFavouriteMenu", "ShowLootFilterResults", "RelocalizeLootFilter"}) do H.Hook(journal, name, refresh) end
    -- Quest events schedule a private renderer for the next frame; hook its completion.
    if journal.questRefreshWorker then H.Script(journal.questRefreshWorker, "OnUpdate", refresh) end
    Palette()
    refresh()
    module.refresh = refresh
    if S.OnLooksChanged then S.OnLooksChanged(function()
        if ns.IsEnabled(module) then Palette(); refresh() end
    end) end
end)
