local ADDON, ns = ...
-- Standalone skin addons receive their own namespace from WoW.
if ADDON ~= "EUIAddonSkins" then
    ns = EUIAddonSkins and EUIAddonSkins.GetSkinNamespace(ADDON)
    if not ns then return end
    ADDON = "EUIAddonSkins"
end
ns.RegisterScopedSkin("Attune", "Attune", {
    softBorders = true,
    available = function() return _G.Attune ~= nil end,
    roots = function()
        local result = ns.SkinRoots({"Attune_MainFrame", "AttuneBronzeChrome", "Attune_MainRaidFrame", "Attune_SurveyMenuFrame",
            "Attune_SyncProgress_Frame", "AttuneQuestRewardFrame", "AttuneQuestDetail"}, {bottomBar = 24})
        for _, target in ipairs(result) do
            target.exclude = {}
            if target.frame ~= _G.AttuneBronzeChrome and _G.AttuneBronzeChrome then target.exclude[_G.AttuneBronzeChrome] = true end
            -- Traverse named graph controls; never paint the graph canvas or its lines.
            if target.frame.map then target.exclude[target.frame.map] = true end
        end
        return result
    end,
    hooks = function(C, refresh)
        for _, method in ipairs({"Attune_Frame", "Attune_RaidPlannerFrame", "Attune_ShowQuestRewards", "Attune_ShowQuestDetail",
            "Attune_ShowWebsiteURL", "Attune_UpdateTreeGroup", "Attune_ShowResultList", "Attune_ShowProfileList", "Attune_StartSync", "Attune_RaidPlannerRoster",
            "Attune_CreateNode", "Attune_CreateZoomSlider", "Attune_UpdateWindowPortrait"}) do C.H.Hook(_G, method, refresh) end
    end,
    visit = function(C, f, kind, refresh)
        local H, S = C.H, C.S
        local name = f.GetName and f:GetName() or ""
        if f == _G.AttuneBronzeChrome then
            if f.NineSlice then S.FadeNineSlice(f.NineSlice) end
            if f.CloseButton then S.CloseButton(f.CloseButton) end
            H.Portrait(f)
            -- Keep the title's original drag handlers.
        end
        if name:match("^Attune_Node_") then
            H.ThinBackdrop(f)
            for _, r in ipairs(H.Regions(f)) do H.Font(r) end
            return true
        end
        if name:match("^Attune_Icon_") then
            local icon = f.GetNormalTexture and f:GetNormalTexture()
            if icon then S.SquareIcon(icon, f) end
            return true
        end
        local ancestor = f
        while ancestor do
            if ancestor == _G.Attune_GraphRoot then return true end
            ancestor = ancestor.GetParent and ancestor:GetParent()
        end
        if kind == "Slider" then H.LegacySlider(f); return true end
        if f.treeline and f.toggle then
            H.Selection(f, f.selected == true)
            H.Font(f.text)
            local expanded = f.toggle.GetNormalTexture and f.toggle:GetNormalTexture()
            local path = expanded and expanded.GetTexture and expanded:GetTexture()
            H.Toggle(f.toggle, path == 130821 or type(path) == "string" and path:find("MinusButton"))
            if f.obj then H.Hook(f.obj, "RefreshTree", refresh) end
            return true
        end
        local widget = f.obj
        if widget and widget.frame == f then
            local status = widget.statustext and widget.statustext.GetParent and widget.statustext:GetParent()
            if status then C.Panel(status); H.Font(widget.statustext) end
            if widget.sizer_se then
                H.Resize(widget.sizer_se, true)
            end
        end
        H.Resize(f)
    end,
})
