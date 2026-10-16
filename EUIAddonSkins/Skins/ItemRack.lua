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
            local cleared, icons, borders, controls = {}, {}, {}, {}
            C.ItemQuality = function(id)
                local rack = _G.ItemRack
                if not id or id == 0 or id == "MENU" or (_G.ItemRackUser and ItemRackUser.Sets and ItemRackUser.Sets[id]) then return end
                if rack and type(rack.GetInfoByID) == "function" then
                    local _, _, _, quality = rack.GetInfoByID(id)
                    return quality
                end
            end
            C.QualityBorder = function(f, icon, quality, selected)
                if icon.GetNumMaskTextures and icon:GetNumMaskTextures() > 0 then return end
                local entry = borders[f]
                if not entry then
                    entry = {}; borders[f] = entry
                    for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
                        local edge = f:CreateTexture(nil, "OVERLAY", nil, 5)
                        if side == "TOP" or side == "BOTTOM" then
                            edge:SetPoint(side .. "LEFT", icon, side .. "LEFT")
                            edge:SetPoint(side .. "RIGHT", icon, side .. "RIGHT"); edge:SetHeight(1)
                        else
                            edge:SetPoint("TOP" .. side, icon, "TOP" .. side)
                            edge:SetPoint("BOTTOM" .. side, icon, "BOTTOM" .. side); edge:SetWidth(1)
                        end
                        entry[#entry + 1] = edge
                    end
                end
                local r, g, b = 0.35, 0.35, 0.35
                if quality and GetItemQualityColor then r, g, b = GetItemQualityColor(quality) end
                for _, edge in ipairs(entry) do edge:SetColorTexture(r, g, b, 1) end
                if selected ~= nil then
                    if not entry.marker then
                        local marker = f:CreateTexture(nil, "OVERLAY", nil, 6)
                        marker:SetSize(4, 4); marker:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -2, 2)
                        entry.marker = marker
                    end
                    local ar, ag, ab = S.GetAccentColor()
                    entry.marker:SetColorTexture(ar, ag, ab, selected and 0.9 or 0)
                end
            end
            C.Detached = function()
                if InCombatLockdown and InCombatLockdown() then refresh(); return end
                -- Exact addon-owned secure buttons only. No attributes, native
                -- scripts, frame anchors, state drivers or visibility changes.
                for slot = 0, 20 do
                    local f, icon = _G["ItemRackButton" .. slot], _G["ItemRackButton" .. slot .. "Icon"]
                    if f and icon and not (f.IsForbidden and f:IsForbidden())
                        and not (icon.IsForbidden and icon:IsForbidden()) and type(icon.SetTexCoord) == "function" then
                        S.SquareIcon(icon)
                        local normal = f.GetNormalTexture and f:GetNormalTexture()
                        if normal and normal ~= icon then normal:SetAlpha(0) end
                        local quality = slot < 20 and GetInventoryItemQuality and GetInventoryItemQuality("player", slot)
                        C.QualityBorder(f, icon, quality)
                    end
                end
                local menu = _G.ItemRackMenuFrame
                if menu and not (menu.IsForbidden and menu:IsForbidden()) and not H.Allowed(menu) then
                    S.Panel(menu, {noBorder = true})
                    if menu.SetBackdrop then menu:SetBackdrop(nil) end
                end
                for index, id in ipairs(_G.ItemRack and ItemRack.Menu or {}) do
                    local f, icon = _G["ItemRackMenu" .. index], _G["ItemRackMenu" .. index .. "Icon"]
                    if f and icon and not (f.IsForbidden and f:IsForbidden())
                        and not (icon.IsForbidden and icon:IsForbidden()) then
                        S.SquareIcon(icon)
                        local normal = f.GetNormalTexture and f:GetNormalTexture()
                        if normal and normal ~= icon then normal:SetAlpha(0) end
                        C.QualityBorder(f, icon, C.ItemQuality(id))
                    end
                end
                for _, key in ipairs({"Lock", "Queue", "Options", "Close"}) do
                    local f = _G["ItemRackButtonMenu" .. key]
                    if f and not (f.IsForbidden and f:IsForbidden()) then
                        local path
                        if key == "Lock" then
                            local locked = _G.ItemRackUser and ItemRackUser.Locked == "ON"
                            path = "Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-lock-" .. (locked and "locked" or "unlocked") .. ".png"
                        elseif key == "Options" then path = "Interface\\AddOns\\EllesmereUI\\media\\icons\\sidebar\\settings-ig-2.png" end
                        if not controls[f] then
                            S.PageButton(f, path and "" or (key == "Queue" and "Q" or "X"), 10)
                            if path then
                                local icon = f:CreateTexture(nil, "OVERLAY")
                                icon:SetSize(11, 11); icon:SetPoint("CENTER", f, "CENTER")
                                controls[f] = icon
                            else controls[f] = true end
                        end
                        if path and controls[f] ~= true then controls[f]:SetTexture(path) end
                    end
                end
            end
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
                local name = f.GetName and f:GetName() or ""
                local slot = tonumber(name:match("^ItemRackOptInv(%d+)$"))
                local menuIndex = tonumber(name:match("^ItemRackMenu(%d+)$"))
                if slot then
                    local data = _G.ItemRackOpt and ItemRackOpt.Inv and ItemRackOpt.Inv[slot]
                    local quality = data and C.ItemQuality(data.id)
                    if not data and GetInventoryItemQuality then quality = GetInventoryItemQuality("player", slot) end
                    C.QualityBorder(f, icon, quality, data and data.selected and true or false)
                elseif menuIndex then
                    C.QualityBorder(f, icon, C.ItemQuality(_G.ItemRack and ItemRack.Menu and ItemRack.Menu[menuIndex]))
                end
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
                C.Detached()
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
        for _, method in ipairs({"InitButtons", "UpdateButtons", "ConstructLayout", "ReflectLock", "AddButton", "ReflectMainScale"}) do
            C.H.Hook(_G.ItemRack, method, C.Detached)
        end
        C.Detached()
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
