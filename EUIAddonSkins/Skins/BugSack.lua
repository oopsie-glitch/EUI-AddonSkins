local ADDON, ns = ...
local function DefineSkin()
local selected = {}
local function Owned(tab)
    local name = tab and tab.GetName and tab:GetName()
    return name and (name == "BugSackTabAll" or name == "BugSackTabSession" or name == "BugSackTabLast" or name == "BugSackTabOptions")
end
ns.RegisterScopedSkin("BugSack", "BugSack", {
    softBorders = true,
    available = function() return _G.BugSack ~= nil end,
    roots = function() return ns.SkinRoots({"BugSackFrame"}, {bottomBar = 28}) end,
    hooks = function(C, refresh)
        C.H.Hook(_G, "PanelTemplates_SelectTab", function(tab)
            if not Owned(tab) then return end
            for _, name in ipairs({"BugSackTabAll", "BugSackTabSession", "BugSackTabLast", "BugSackTabOptions"}) do
                selected[name] = _G[name] == tab
            end
            refresh()
        end)
        C.H.Hook(_G, "PanelTemplates_DeselectTab", function(tab)
            if Owned(tab) then selected[tab:GetName()] = false; refresh() end
        end)
        C.H.Hook(_G.BugSack, "OpenSack", refresh)
        C.H.Hook(_G.BugSack, "OpenConfig", refresh)
        C.H.Hook(_G.BugSack, "CreateOptionsTab", refresh)
    end,
    visit = function(C, f, kind)
        local name = f.GetName and f:GetName() or ""
        if kind == "Button" then
            if name:match("^BugSackTab") then return C.H.Tab(f, selected[name]) end
            if name == "BugSackNextButton" then C.S.SoftPageButton(f, ">"); return true end
            if name == "BugSackPrevButton" then C.S.SoftPageButton(f, "<"); return true end
        end
    end,
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("BugSack", DefineSkin)
else DefineSkin() end
