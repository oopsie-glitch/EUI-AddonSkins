local ADDON, ns = ...
-- Standalone skin addons receive their own namespace from WoW.
if ADDON ~= "EUIAddonSkins" then
    ns = EUIAddonSkins and EUIAddonSkins.GetSkinNamespace(ADDON)
    if not ns then return end
    ADDON = "EUIAddonSkins"
end
local scrollThumbs = setmetatable({}, {__mode = "k"})
ns.RegisterScopedSkin("ItemRack", "ItemRack", {
    available = function() return _G.ItemRack ~= nil end,
    roots = function()
        local result = ns.SkinRoots({"ItemRackOptFrame", "ItemRackLogFrame"}, {bottomBar = 24})
        if _G.ItemRackOpt and _G.ItemRackOpt.QueueIconPicker then result[#result + 1] = {frame = _G.ItemRackOpt.QueueIconPicker} end
        return result
    end,
    hooks = function(C, refresh)
        C.H.Hook(_G.ItemRack, "ToggleOptions", refresh)
        C.H.Hook(_G.ItemRack, "SlashHandler", refresh)
        for _, method in ipairs({"TabOnClick", "ShowPrevSubFrame", "ToggleEventEditor", "OpenQueueIconPicker",
            "QueueIconPickerUpdate", "RefreshQueueIconPage", "LayoutQueueControls", "UpdateInv"}) do C.H.Hook(_G.ItemRackOpt, method, refresh) end
    end,
    visit = function(C, f, kind)
        -- ItemRack's labels are frequently BACKGROUND regions; keep them above
        -- newly painted button/checkbox fills without moving their anchors.
        for _, region in ipairs({f:GetRegions()}) do
            if region:GetObjectType() == "FontString" then
                if region.SetDrawLayer then region:SetDrawLayer("OVERLAY") end
                C.H.Font(region)
            end
        end
        local name = f.GetName and f:GetName() or ""
        -- The public scrollbar primitive targets MinimalScrollBar. ItemRack
        -- still uses classic Slider thumbs; draw a strip on the existing thumb
        -- without changing its range, drag area or OnValueChanged callback.
        if kind == "Slider" and f.GetThumbTexture and f.GetOrientation and f:GetOrientation() == "VERTICAL" then
            local thumb = f:GetThumbTexture()
            if thumb and not scrollThumbs[f] then
                local strip = f:CreateTexture(nil, "ARTWORK")
                strip:SetColorTexture(1, 1, 1, 0.3)
                strip:SetPoint("TOP", thumb, "TOP")
                strip:SetPoint("BOTTOM", thumb, "BOTTOM")
                strip:SetWidth(4)
                C.H.Fade(thumb)
                scrollThumbs[f] = strip
            end
        end
        if kind == "Frame" and name:match("^ItemRackOpt") and f.GetBackdrop and f:GetBackdrop() then C.Panel(f) end
        if kind == "Button" and (name:match("^ItemRackOptList%d+$") or name:match("^ItemRackOptSoundList%d+$")
            or name:match("^ItemRackOptSoundTestList%d+$")) then
            C.H.Fade(_G[name .. "Underline"])
            return true
        end
        local icon = _G[name .. "Icon"]
        if (kind == "Button" or kind == "CheckButton") and icon and icon.GetObjectType
            and icon:GetObjectType() == "Texture" then
            C.S.SquareIcon(icon, f)
            return true
        end
        if (kind == "Button" or kind == "CheckButton") and f.GetName then
            local name = f:GetName() or ""
            if name:match("^ItemRackOptTab%d+$") then return C.H.Tab(f, f.IsEnabled and not f:IsEnabled()) end
            if name == "ItemRackOptClose" or name == "ItemRackOptSetListClose" or name == "ItemRackOptSortListClose" then
                C.S.CloseButton(f); return true
            end
            if name:match("^ItemRackOpt.*Icon%d+$") or name:match("^ItemRackOptInv%d+$") then
                local t = _G[name .. "Icon"] or (f.GetNormalTexture and f:GetNormalTexture())
                if t then C.S.SquareIcon(t, f) end
                return true
            end
        end
        -- Equipment/action buttons outside options are protected and stay intact.
    end,
})
