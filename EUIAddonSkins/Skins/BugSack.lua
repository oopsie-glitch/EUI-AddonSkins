local ADDON, ns = ...
local function DefineSkin()
local selected = {}
local tabNames = {"BugSackTabAll", "BugSackTabSession", "BugSackTabLast", "BugSackTabOptions"}
local function Owned(tab)
    local name = tab and tab.GetName and tab:GetName()
    for _, value in ipairs(tabNames) do if name == value then return true end end
end
local function Label(C, button)
    local text = button.GetFontString and button:GetFontString() or button.Text
    if text then
        local shade = button.IsEnabled and not button:IsEnabled() and 0.65 or 1
        C.H.Font(text, shade, shade, shade)
    end
end
ns.RegisterScopedSkin("BugSack", "BugSack", {
    softBorders = true, immediateShow = true,
    available = function() return _G.BugSack ~= nil end,
    roots = function() return ns.SkinRoots({"BugSackFrame"}, {bottomBar = 76, noAccent = true}) end,
    hooks = function(C, refresh)
        C.H.Hook(_G, "PanelTemplates_SelectTab", function(tab)
            if not Owned(tab) then return end
            for _, name in ipairs(tabNames) do selected[name] = _G[name] == tab end
            refresh()
        end)
        C.H.Hook(_G, "PanelTemplates_DeselectTab", function(tab)
            if Owned(tab) then selected[tab:GetName()] = false; refresh() end
        end)
        C.H.Hook(_G.BugSack, "OpenSack", C.RefreshNow)
        C.H.Hook(_G.BugSack, "OpenConfig", C.RefreshNow)
        C.H.Hook(_G.BugSack, "CreateOptionsTab", refresh)
    end,
    visit = function(C, f, kind)
        local H, S = C.H, C.S
        local name = f.GetName and f:GetName() or ""
        if name == "BugSackFrame" then
            H.Portrait(f, false, true)
            local previous
            for _, tabName in ipairs(tabNames) do
                local tab = _G[tabName]
                if H.Allowed(tab) and tab.ClearAllPoints and tab.SetPoint then
                    tab:ClearAllPoints()
                    if previous then tab:SetPoint("LEFT", previous, "RIGHT", 4, 0)
                    else tab:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 8) end
                    previous = tab
                end
            end
        end
        if kind == "Button" then
            if Owned(f) then return H.Tab(f, selected[name]) end
            if name == "BugSackNextButton" or name == "BugSackPrevButton"
                or name == "BugSackSendButton" or name == "BugSackWipeButton" then
                -- Keep translated labels and native click/shift-click actions.
                H.Action(f, {"Text", "text"})
                if f.NineSlice then S.FadeNineSlice(f.NineSlice) end
                for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture"}) do
                    local texture = f[getter] and f[getter](f)
                    if texture then H.Fade(texture) end
                end
                if f.ClearAllPoints and f.SetPoint and f.SetSize then
                    f:ClearAllPoints()
                    if name == "BugSackPrevButton" then
                        f:SetPoint("BOTTOMLEFT", BugSackFrame, "BOTTOMLEFT", 12, 44); f:SetSize(110, 28)
                    elseif name == "BugSackNextButton" then
                        f:SetPoint("BOTTOMRIGHT", BugSackFrame, "BOTTOMRIGHT", -12, 44); f:SetSize(110, 28)
                    else
                        f:SetPoint("BOTTOM", BugSackFrame, "BOTTOM", 0, 44); f:SetSize(160, 28)
                    end
                end
                Label(C, f)
                for _, method in ipairs({"Enable", "Disable", "SetEnabled"}) do
                    H.Hook(f, method, function() Label(C, f) end)
                end
                return true
            end
            local parent = f.GetParent and f:GetParent()
            local window = _G.BugSackFrame
            -- Keep the caption's native drag, tooltip and search actions.
            if window and ((window.TitleContainer and parent == window.TitleContainer)
                or parent == window and f.GetScript and f:GetScript("OnDoubleClick")) then
                Label(C, f); return true
            end
        end
    end,
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("BugSack", DefineSkin)
else DefineSkin() end
