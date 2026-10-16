local ADDON, ns = ...
local function DefineSkin()
local scrollThumbs = setmetatable({}, {__mode = "k"})
local glyphs = {ItemRackOptSetsDropDownButton = "v", ItemRackOptEventEditTypeDropButton = "v",
    ItemRackOptSortMoveTop = "^^", ItemRackOptSortMoveUp = "^", ItemRackOptSortMoveDown = "v",
    ItemRackOptSortMoveBottom = "vv", ItemRackOptSortMoveDelete = "X", ItemRackOptToggleInvAll = "All"}
ns.RegisterScopedSkin("ItemRack", "ItemRack", {
    softBorders = true,
    panels = false,
    preserveTextColors = true,
    immediateShow = true,
    panelOptions = {noBorder = true},
    available = function() return _G.ItemRack ~= nil end,
    roots = function()
        local result = ns.SkinRoots({"ItemRackOptFrame", "ItemRackLogFrame"}, {bottomBar = 24})
        if _G.ItemRackMenuFrame then result[#result + 1] = {frame = _G.ItemRackMenuFrame, mode = "controls"} end
        if _G.ItemRackOpt and _G.ItemRackOpt.QueueIconPicker then result[#result + 1] = {frame = _G.ItemRackOpt.QueueIconPicker} end
        return result
    end,
    hooks = function(C, refresh)
        if not C.Clear then
            local H, S = C.H, C.S
            local cleared, icons = {}, {}
            C.Clear = function(f)
                if not H.Allowed(f) then return end
                if not cleared[f] then
                    cleared[f] = true
                    local regions, foreground = H.Regions(f), false
                    for _, region in ipairs(regions) do
                        if H.Texture(region) then
                            local layer = region:GetDrawLayer()
                            if layer ~= "BACKGROUND" and layer ~= "BORDER" then foreground = true end
                        end
                    end
                    if not foreground and S.Inset then S.Inset(f) end
                    for _, region in ipairs(regions) do
                        if H.Texture(region) then
                            local layer = region:GetDrawLayer()
                            if layer == "BACKGROUND" or layer == "BORDER" then H.Fade(region) end
                        end
                    end
                end
                if f.SetBackdrop then f:SetBackdrop(nil) end
            end
            C.Icon = function(f, icon)
                if not H.Allowed(f) or not H.Texture(icon) then return end
                -- Texture IDs, cooldowns, quality borders and checked states
                -- remain native. Only the baked action-slot bevel is removed.
                if not icons[f] then
                    icons[f] = true
                    local normal = f.GetNormalTexture and H.Texture(f:GetNormalTexture())
                    if normal and normal ~= icon then H.Fade(normal) end
                end
                S.SquareIcon(icon)
            end
            C.Row = function(row)
                if not H.Allowed(row) then return end
                local name = row.GetName and row:GetName() or ""
                local highlight = H.Texture(_G[name .. "Highlight"])
                if highlight then
                    local r, g, b = S.GetAccentColor()
                    highlight:SetColorTexture(r, g, b, 0.13)
                end
                C.Icon(row, _G[name .. "Icon"])
                for _, region in ipairs(H.Regions(row)) do H.Font(region) end
            end
            C.Rows = function()
                for _, prefix in ipairs({"ItemRackOptSortList", "ItemRackOptEventList", "ItemRackOptSetList"}) do
                    for index = 1, 40 do
                        local row = _G[prefix .. index]
                        if not row then break end
                        C.Row(row)
                    end
                end
            end
            C.Menu = function()
                local menu = _G.ItemRackMenuFrame
                if H.Allowed(menu) then C.RefreshControlsNow(menu) end
            end
            C.UpdateRows = function()
                if InCombatLockdown and InCombatLockdown() then refresh(); return end
                C.Rows()
            end
            C.UpdateHighlight = function(row)
                if InCombatLockdown and InCombatLockdown() then refresh(); return end
                if type(row) == "string" then row = _G[row] end
                C.Row(row)
            end
        end
        C.H.Hook(_G.ItemRack, "ToggleOptions", refresh)
        C.H.Hook(_G.ItemRack, "SlashHandler", refresh)
        C.H.Hook(_G.ItemRack, "BuildMenu", C.Menu)
        for _, method in ipairs({"TabOnClick", "ShowPrevSubFrame", "ToggleEventEditor", "OpenQueueIconPicker"}) do C.H.Hook(_G.ItemRackOpt, method, C.RefreshNow) end
        for _, method in ipairs({
            "QueueIconPickerUpdate", "RefreshQueueIconPage", "LayoutQueueControls", "UpdateInv"}) do C.H.Hook(_G.ItemRackOpt, method, refresh) end
        for _, method in ipairs({"SortListScrollFrameUpdate", "EventListScrollFrameUpdate", "SetListScrollFrameUpdate"}) do
            C.H.Hook(_G.ItemRackOpt, method, C.UpdateRows)
        end
        C.H.Hook(_G.ItemRackOpt, "LockHighlight", C.UpdateHighlight)
        C.H.Hook(_G.ItemRackOpt, "UnlockHighlight", C.UpdateHighlight)
    end,
    visit = function(C, f, kind)
        local H, S = C.H, C.S
        -- ItemRack's labels are frequently BACKGROUND regions; keep them above
        -- newly painted button/checkbox fills without moving their anchors.
        for _, region in ipairs({f:GetRegions()}) do
            if region:GetObjectType() == "FontString" then
                if region.SetDrawLayer then region:SetDrawLayer("OVERLAY") end
                C.H.Font(region)
            end
        end
        local name = f.GetName and f:GetName() or ""
        if f == _G.ItemRackMenuFrame then C.Panel(f) end
        if name == "ItemRackOptSubFrame2" then
            for _, side in ipairs({"Left", "Middle", "Right"}) do H.Fade(_G["ItemRackOptSetsDropTexture" .. side]) end
        end
        local picker = _G.ItemRackOpt and _G.ItemRackOpt.QueueIconPicker
        if kind == "Frame" and name:match("^ItemRackOpt") and f ~= _G.ItemRackOptFrame and f ~= picker then
            local point, relative, relativePoint
            if f.GetPoint then point, relative, relativePoint = f:GetPoint(1) end
            if point and relativePoint and point:find("LEFT") and relative == _G.ItemRackOptFrame and relativePoint:find("RIGHT") then C.Panel(f)
            else C.Clear(f) end
        end
        if kind == "ScrollFrame" and name:match("^ItemRackOpt") then
            C.Clear(f)
        end
        -- The public scrollbar primitive targets MinimalScrollBar. ItemRack
        -- still uses classic Slider thumbs; draw a strip on the existing thumb
        -- without changing its range, drag area or OnValueChanged callback.
        if kind == "Slider" and f.GetThumbTexture and f.GetOrientation then
            H.LegacySlider(f, scrollThumbs[f])
            local thumb = f:GetThumbTexture()
            if f:GetOrientation() == "HORIZONTAL" then
                if H.Texture(thumb) then thumb:SetTexCoord(0, 1, 0, 1); thumb:SetSize(10, 16) end
                return true
            end
            if thumb and not scrollThumbs[f] then
                local strip = f:CreateTexture(nil, "ARTWORK")
                strip:SetColorTexture(1, 1, 1, 0.3)
                strip:SetPoint("TOP", thumb, "TOP")
                strip:SetPoint("BOTTOM", thumb, "BOTTOM")
                strip:SetWidth(4)
                C.H.Fade(thumb)
                scrollThumbs[f] = strip
            end
            return true
        end
        if kind == "Button" and (name:match("^ItemRackOptList%d+$") or name:match("^ItemRackOptSoundList%d+$")
            or name:match("^ItemRackOptSoundTestList%d+$")) then
            C.H.Fade(_G[name .. "Underline"])
            return true
        end
        if kind == "Button" and (name:match("^ItemRackOptSortList%d+$") or name:match("^ItemRackOptEventList%d+$")
            or name:match("^ItemRackOptSetList%d+$")) then C.Row(f); return true end
        local icon = _G[name .. "Icon"]
        if (kind == "Button" or kind == "CheckButton") and icon and icon.GetObjectType
            and icon:GetObjectType() == "Texture" then
            C.Icon(f, icon)
            return true
        end
        if (kind == "Button" or kind == "CheckButton") and f.GetName then
            local name = f:GetName() or ""
            if name:match("^ItemRackOptTab%d+$") then return C.H.Tab(f, f.IsEnabled and not f:IsEnabled()) end
            if name == "ItemRackOptClose" or name == "ItemRackOptSetListClose" or name == "ItemRackOptSortListClose" then
                C.S.CloseButton(f); return true
            end
            if glyphs[name] then S.PageButton(f, glyphs[name], 12); return true end
            if name:match("^ItemRackOptEventList%d+Icon$") then C.Icon(f, f:GetNormalTexture()); return true end
            if name:match("^ItemRackOpt.*Icon%d+$") or name:match("^ItemRackOptInv%d+$") then
                local t = _G[name .. "Icon"] or (f.GetNormalTexture and f:GetNormalTexture())
                if t then C.Icon(f, t) end
                return true
            end
        end
        if kind == "CheckButton" then
            S.Checkbox(f, {borderInset = 4, hover = 0.06, stockCheck = name == "ItemRackOptShowHelm" or name == "ItemRackOptShowCloak"})
            return true
        end
        if kind == "Button" and name == "ItemRackOptEventEditTypeDrop" then
            f.Text = f.Text or _G[name .. "Text"]
            S.Dropdown(f); return true
        end
        -- Equipment/action buttons outside options are protected and stay intact.
    end,
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("ItemRack", DefineSkin)
else DefineSkin() end
