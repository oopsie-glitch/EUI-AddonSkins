local ADDON, ns = ...
-- Standalone skin addons receive their own namespace from WoW.
if ADDON ~= "EUIAddonSkins" then
    ns = EUIAddonSkins and EUIAddonSkins.GetSkinNamespace(ADDON)
    if not ns then return end
    ADDON = "EUIAddonSkins"
end
ns.RegisterModule("Spy", "Spy", function()
    return _G.Spy and type(_G.Spy.CreateMainWindow) == "function"
end, function(S, module)
    S = ns.CreateSoftSkin(S, module)
    local spy = _G.Spy
    local H = ns.CreateSkinHelper(S, module)
    local windows, styled, layers, options = {}, {}, {}, {}
    local config = LibStub and LibStub("AceConfigDialog-3.0", true)
    local refresh, waiting
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")

    local function Window(f, alert)
        if not f or not f.GetObjectType or (f.IsForbidden and f:IsForbidden()) then return end
        -- Secure targeting rows can make the parent protected. Create only a
        -- noninteractive visual child, outside combat, without changing actions.
        if not layers[f] then
            local bg = CreateFrame("Frame", nil, f)
            bg:SetAllPoints(f)
            bg:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
            bg:EnableMouse(false)
            S.Shell(bg, {noTopBar = alert or f == spy.MainWindow})
            ns.AttachAccent(S, bg)
            layers[f] = bg
            if f.HookScript then
                f:HookScript("OnShow", function() if ns.IsEnabled(module) then refresh() end end)
            end
        end
        if f.SetBackdrop then f:SetBackdrop(nil) end
        if f.TitleBar and f.TitleBar.SetBackdrop and not (f.TitleBar.IsForbidden and f.TitleBar:IsForbidden()) then
            f.TitleBar:SetBackdrop(nil)
        end
        if not styled[f] then
            styled[f] = true
            -- Remove only window decoration, not alert icons or player rows.
            for _, region in ipairs({f:GetRegions()}) do
                local path = region.GetTexture and region:GetTexture()
                if type(path) == "string" and (path:find("UI%-DialogBox") or path:find("UI%-Tooltip")) then H.Fade(region) end
            end
            if H.Allowed(f.CloseButton) then S.CloseButton(f.CloseButton) end
            if H.Allowed(f.LeftButton) and S.SoftPageButton then S.SoftPageButton(f.LeftButton, "<") end
            if H.Allowed(f.RightButton) and S.SoftPageButton then S.SoftPageButton(f.RightButton, ">") end
        end
        H.Font(f.Title)
        -- Scan individual unprotected children; secure rows and their bars keep
        -- Spy's class/KOS colors, macro attributes and click handlers intact.
        local exclude = {}
        if f.Icon then exclude[f.Icon] = true end
        for _, row in pairs(f.Rows or {}) do exclude[row] = true end
        exclude[layers[f]] = true
        for _, child in ipairs({f:GetChildren()}) do H.Scan(child, refresh, nil, exclude) end
    end
    local function Apply()
        if InCombatLockdown() then waiting = true; return end
        waiting = false
        for _, name in ipairs({"Spy_MainWindow", "SpyStatsFrame"}) do
            if _G[name] then windows[_G[name]] = true end
        end
        if spy.MainWindow then windows[spy.MainWindow] = true end
        for f in pairs(windows) do Window(f) end
        Window(spy.AlertWindow, true)
        if H.Allowed(_G.SpyStatsFrameTopCloseButton) then S.CloseButton(_G.SpyStatsFrameTopCloseButton) end
        H.Fade(_G.SpyStatsFrame_Header)
        if config and config.OpenFrames and config.OpenFrames.Spy then
            Window(config.OpenFrames.Spy.frame)
        end
        for _, f in pairs(spy.optionsFrames or {}) do
            if H.Allowed(f) then H.Script(f, "OnShow", refresh); H.Scan(f, refresh) end
        end
        for f in pairs(options) do H.Scan(f, refresh) end
        S.RefreshSoftBorders()
    end
    refresh = function() H.Queue(module, Apply) end
    H.Hook(config, "FeedGroup", function(_, appName, _, root)
        if appName == "Spy" then
            if root and root.frame then options[root.frame] = true end
            refresh()
        end
    end)
    H.Hook(spy, "CreateFrame", function(_, name)
        if type(name) == "string" and _G[name] then windows[_G[name]] = true end
        refresh()
    end)
    for _, method in ipairs({"CreateMainWindow", "UpdateMainWindow", "UpdateAlertWindow", "HandleProfileChanges",
        "SetupMainWindowButtons", "SetCurrentList", "SetFont", "ShowConfig", "SetupOptions"}) do H.Hook(spy, method, refresh) end
    H.Hook(spy.Colors, "UpdateColor", refresh)
    if _G.SpyStats then H.Hook(_G.SpyStats, "Show", refresh) end
    events:SetScript("OnEvent", function() if waiting and ns.IsEnabled(module) then refresh() end end)
    module.refresh = refresh
    if S.OnLooksChanged then S.OnLooksChanged(refresh) end
    refresh()
end)
