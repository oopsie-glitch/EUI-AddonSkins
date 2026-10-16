local ADDON, ns = ...
local function DefineSkin()
local scrollThumbs = setmetatable({}, {__mode = "k"})
local settingsDrops = {ItemRackOptQuickAccessMenuSide = true, ItemRackOptQuickAccessMenuDir = true,
    ItemRackOptMinimapMenuDir = true, ItemRackOptEventEditTypeDrop = true}
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
        local result = ns.SkinRoots({"ItemRackOptFrame", "ItemRackLogFrame"}, {bottomBar = 24, noAccent = true})
        if _G.ItemRackMenuFrame then result[#result + 1] = {frame = _G.ItemRackMenuFrame, mode = "controls"} end
        if _G.ItemRackOpt and _G.ItemRackOpt.QueueIconPicker then result[#result + 1] = {frame = _G.ItemRackOpt.QueueIconPicker} end
        return result
    end,
    hooks = function(C, refresh)
        if not C.Clear then
            local H, S = C.H, C.S
            local cleared, icons, borders, controls, tabLabels = {}, {}, {}, {}, {}
            C.TabLabel = function(f)
                local data = S.GetFFD and S.GetFFD(f)
                -- EUI tabs have their own visible label; leave the hidden native
                -- label transparent so it cannot render a second copy.
                local text = data and data.label or (f.GetFontString and f:GetFontString()) or f.Text
                if not H.Allowed(text) or not text.SetTextColor then return end
                local entry = tabLabels[f]
                if not entry or entry.text ~= text then
                    local painting = false
                    local function Paint()
                        if painting then return end
                        if InCombatLockdown and InCombatLockdown() then refresh(); return end
                        local r, g, b = S.GetAccentColor()
                        local shade = f.IsEnabled and f:IsEnabled() and 0.65 or 1
                        painting = true; text:SetTextColor(r * shade, g * shade, b * shade, 1); painting = false
                    end
                    entry = {text = text, paint = Paint}; tabLabels[f] = entry
                    H.Hook(text, "SetTextColor", Paint)
                end
                entry.paint()
            end
            C.RemoveArt = function(texture)
                if not H.Texture(texture) then return end
                H.Fade(texture)
                -- These are static, addon-owned decorations. Clear the source
                -- too so a restored alpha cannot expose the native gradient.
                if texture:GetTexture() then texture:SetTexture(nil) end
            end
            C.FlatHighlight = function(texture, r, g, b, a)
                texture:SetColorTexture(r, g, b, a)
                -- A solid texture can still carry the template's vertex gradient.
                if texture.SetGradientAlpha then texture:SetGradientAlpha("VERTICAL", 1, 1, 1, 1, 1, 1, 1, 1)
                elseif texture.SetGradient and CreateColor then
                    C.White = C.White or CreateColor(1, 1, 1, 1)
                    texture:SetGradient("VERTICAL", C.White, C.White)
                end
            end
            C.Check = function(f, stock)
                S.Checkbox(f, {borderInset = 4, hover = 0.06, stockCheck = stock})
                if stock then return end
                local check = f.GetCheckedTexture and H.Texture(f:GetCheckedTexture())
                if check then
                    if check.SetDesaturated then check:SetDesaturated(true) end
                    check:ClearAllPoints(); check:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -4)
                    check:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
                    local r, g, b = S.GetAccentColor()
                    check:SetVertexColor(r, g, b, 1)
                end
            end
            C.SettingsFont = function(text, size, r, g, b)
                if not H.Allowed(text) or not text.GetFont or not text.SetFont then return end
                S.Font(text, r, g, b)
                local font, _, flags = text:GetFont()
                if font then text:SetFont(font, size, flags or "") end
                if text.SetDrawLayer then text:SetDrawLayer("OVERLAY") end
            end
            C.SettingsRow = function(row)
                if not H.Allowed(row) then return end
                local name = row:GetName()
                C.RemoveArt(_G[name .. "Underline"])
                C.SettingsFont(_G[name .. "Label"], 11, 0.78, 0.78, 0.8)
                local label = _G[name .. "CheckText"]
                C.SettingsFont(label, 10)
                if H.Allowed(label) then
                    label:ClearAllPoints(); label:SetPoint("LEFT", row, "LEFT", 22, 0)
                    label:SetWidth(math.max(1, row:GetWidth() - 24))
                end
                C.SettingsFont(_G[name .. "NumberLabel"], 10)
                local check = _G[name .. "CheckButton"]
                if H.Allowed(check) then
                    check:SetSize(20, 20)
                    check:ClearAllPoints(); check:SetPoint("LEFT", row, "LEFT", 0, 0)
                    C.Check(check)
                end
            end
            C.Settings = function()
                if InCombatLockdown and InCombatLockdown() then refresh(); return end
                local offset = FauxScrollFrame_GetOffset and _G.ItemRackOptListScrollFrame
                    and FauxScrollFrame_GetOffset(ItemRackOptListScrollFrame) or 0
                for index = 1, 11 do
                    local row = _G["ItemRackOptList" .. index]
                    if row then
                        C.SettingsRow(row)
                        local opt = _G.ItemRackOpt and ItemRackOpt.OptInfo and ItemRackOpt.OptInfo[offset + index]
                        if opt and H.Allowed(opt.button) then
                            C.RefreshControlsNow(opt.button)
                            if opt.type == "number" then
                                local label = _G[row:GetName() .. "NumberLabel"]
                                if H.Allowed(label) then label:SetWidth(90) end
                                opt.button:ClearAllPoints(); opt.button:SetPoint("RIGHT", row, "RIGHT", -2, 0)
                            end
                        end
                    end
                end
            end
            C.SettingsPickers = function()
                if InCombatLockdown and InCombatLockdown() then refresh(); return end
                for name in pairs(settingsDrops) do
                    C.RefreshControlsNow(_G[name])
                    C.RefreshControlsNow(_G[name .. "Pick"])
                end
            end
            C.GetQualityColor = function(quality)
                if quality == nil or quality == false then return 0.35, 0.35, 0.35 end
                local getter = type(GetItemQualityColor) == "function" and GetItemQualityColor
                    or (_G.C_Item and C_Item.GetItemQualityColor)
                if type(getter) == "function" then
                    local r, g, b = getter(quality)
                    if r ~= nil and g ~= nil and b ~= nil then return r, g, b end
                end
                local color = _G.ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
                if color and color.r ~= nil and color.g ~= nil and color.b ~= nil then return color.r, color.g, color.b end
                return 0.35, 0.35, 0.35
            end
            C.ButtonIcon = function(f, name)
                return _G[name .. "ItemRackIcon"] or _G[name .. "Icon"] or f.icon or f.Icon
            end
            C.InventoryQuality = function(slot)
                if slot >= 20 then return end
                if GetInventoryItemQuality then return GetInventoryItemQuality("player", slot) end
                local rack = _G.ItemRack
                if rack and type(rack.GetID) == "function" then return C.ItemQuality(rack.GetID(slot)) end
            end
            C.ItemQuality = function(id)
                local rack = _G.ItemRack
                if not id or id == 0 or id == "MENU" or (_G.ItemRackUser and ItemRackUser.Sets and ItemRackUser.Sets[id]) then return end
                if rack and type(rack.GetInfoByID) == "function" then
                    local _, _, _, quality = rack.GetInfoByID(id)
                    return quality
                end
            end
            C.QualityBorder = function(f, icon, quality)
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
                local r, g, b = C.GetQualityColor(quality)
                for _, edge in ipairs(entry) do edge:SetColorTexture(r, g, b, 1) end
            end
            C.Detached = function()
                if InCombatLockdown and InCombatLockdown() then refresh(); return end
                -- Exact addon-owned secure buttons only. No attributes, native
                -- scripts, frame anchors, state drivers or visibility changes.
                for slot = 0, 20 do
                    local name = "ItemRackButton" .. slot
                    local f = _G[name]
                    local icon = f and C.ButtonIcon(f, name)
                    if f and icon and not (f.IsForbidden and f:IsForbidden())
                        and not (icon.IsForbidden and icon:IsForbidden()) and type(icon.SetTexCoord) == "function" then
                        S.SquareIcon(icon)
                        local normal = f.GetNormalTexture and f:GetNormalTexture()
                        if normal and normal ~= icon then normal:SetAlpha(0) end
                        C.QualityBorder(f, icon, C.InventoryQuality(slot))
                    end
                end
                local menu = _G.ItemRackMenuFrame
                if menu and not (menu.IsForbidden and menu:IsForbidden()) and not H.Allowed(menu) then
                    S.Panel(menu, {noBorder = true})
                    if menu.SetBackdrop then menu:SetBackdrop(nil) end
                end
                for index, id in ipairs(_G.ItemRack and ItemRack.Menu or {}) do
                    local name = "ItemRackMenu" .. index
                    local f = _G[name]
                    local icon = f and C.ButtonIcon(f, name)
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
                        local r, g, b = S.GetAccentColor()
                        if path and controls[f] ~= true then
                            controls[f]:SetTexture(path); controls[f]:SetVertexColor(r, g, b, 1)
                        else
                            local data = S.GetFFD and S.GetFFD(f)
                            local glyph = data and data.arrow or (f.GetFontString and f:GetFontString())
                            if H.Allowed(glyph) and glyph.SetTextColor then glyph:SetTextColor(r, g, b, 1) end
                        end
                    end
                end
            end
            C.Clear = function(f)
                if not H.Allowed(f) then return end
                if not cleared[f] then
                    local regions, foreground, decorations = H.Regions(f), false, {}
                    for _, region in ipairs(regions) do
                        if H.Texture(region) then
                            local layer = region:GetDrawLayer()
                            if layer ~= "BACKGROUND" and layer ~= "BORDER" then foreground = true end
                        end
                    end
                    for _, region in ipairs(regions) do
                        if H.Texture(region) then
                            local layer = region:GetDrawLayer()
                            if layer == "BACKGROUND" or layer == "BORDER" then decorations[#decorations + 1] = region end
                        end
                    end
                    cleared[f] = decorations
                    if not foreground and S.Inset then S.Inset(f) end
                end
                for _, region in ipairs(cleared[f]) do C.RemoveArt(region) end
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
                    if not data then quality = C.InventoryQuality(slot) end
                    C.QualityBorder(f, icon, quality)
                elseif menuIndex then
                    C.QualityBorder(f, icon, C.ItemQuality(_G.ItemRack and ItemRack.Menu and ItemRack.Menu[menuIndex]))
                end
                if name:match("^ItemRackOptSetsIcon%d+$") then
                    local highlight = f.GetHighlightTexture and H.Texture(f:GetHighlightTexture())
                    if highlight then
                        C.FlatHighlight(highlight, 1, 1, 1, 0.13)
                        if highlight.SetBlendMode then highlight:SetBlendMode("BLEND") end
                        highlight:ClearAllPoints(); highlight:SetAllPoints(icon)
                    end
                elseif name == "ItemRackOptSetsCurrentSet" then f:SetSize(30, 30) end
            end
            C.Row = function(row)
                if not H.Allowed(row) then return end
                local name = row.GetName and row:GetName() or ""
                local highlight = H.Texture(_G[name .. "Highlight"])
                if highlight then
                    local r, g, b = S.GetAccentColor()
                    C.FlatHighlight(highlight, r, g, b, 0.13)
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
        for _, method in ipairs({"InitButtons", "UpdateButtons", "ConstructLayout", "ReflectLock", "AddButton", "ReflectMainScale", "RefreshCustomItemIcons"}) do
            C.H.Hook(_G.ItemRack, method, C.Detached)
        end
        C.Detached()
        for _, method in ipairs({"TabOnClick", "ShowPrevSubFrame", "ToggleEventEditor", "OpenQueueIconPicker"}) do C.H.Hook(_G.ItemRackOpt, method, C.RefreshNow) end
        for _, method in ipairs({
            "QueueIconPickerUpdate", "RefreshQueueIconPage", "LayoutQueueControls", "UpdateInv"}) do C.H.Hook(_G.ItemRackOpt, method, refresh) end
        for _, method in ipairs({"SortListScrollFrameUpdate", "EventListScrollFrameUpdate", "SetListScrollFrameUpdate"}) do
            C.H.Hook(_G.ItemRackOpt, method, C.UpdateRows)
        end
        C.H.Hook(_G.ItemRackOpt, "SetsIconScrollFrameUpdate", function()
            if InCombatLockdown and InCombatLockdown() then refresh(); return end
            C.RefreshControlsNow(_G.ItemRackOptSetsIconFrame)
        end)
        C.H.Hook(_G.ItemRackOpt, "PickSetOnShow", function() C.RefreshControlsNow(_G.ItemRackOptSubFrame5) end)
        C.H.Hook(_G.ItemRackOpt, "LockHighlight", C.UpdateHighlight)
        C.H.Hook(_G.ItemRackOpt, "UnlockHighlight", C.UpdateHighlight)
        C.H.Hook(_G.ItemRackOpt, "ListScrollFrameUpdate", C.Settings)
        for _, method in ipairs({"UpdateQuickAccessMenuSide", "UpdateQuickAccessMenuDir", "UpdateMinimapMenuDir",
            "ToggleQuickAccessMenuSidePick", "ToggleQuickAccessMenuDirPick", "ToggleMinimapMenuDirPick"}) do
            C.H.Hook(_G.ItemRackOpt, method, C.SettingsPickers)
        end
        C.Settings()
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
        if settingsDrops[name] then
            f.Text = f.Text or _G[name .. "Text"]
            S.Dropdown(f)
            C.SettingsFont(f.Text, 10, 0.9, 0.9, 0.92)
            local data = S.GetFFD and S.GetFFD(f)
            if data and H.Texture(data.arrow) then
                data.arrow:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-left.png")
                data.arrow:SetTexCoord(0, 1, 0, 1)
                if data.arrow.SetRotation then data.arrow:SetRotation(math.pi / 2) end
                data.arrow:SetSize(9, 9); data.arrow:SetVertexColor(0.75, 0.75, 0.77, 1)
            end
            if H.Allowed(f.Text) then
                if f.Text.GetStringWidth then f:SetWidth(math.max(f:GetWidth(), f.Text:GetStringWidth() + 30)) end
                f.Text:ClearAllPoints(); f.Text:SetPoint("LEFT", f, "LEFT", 6, 0)
                f.Text:SetPoint("RIGHT", f, "RIGHT", -22, 0)
            end
            return true
        end
        if name:match("Button$") and settingsDrops[name:sub(1, -7)] then
            -- The parent supplies EUI's arrow; keep this native click target.
            for _, region in ipairs(H.Regions(f)) do if H.Texture(region) then H.Fade(region) end end
            return true
        end
        if name:match("Pick$") and settingsDrops[name:sub(1, -5)] then C.Panel(f); return true end
        if f == _G.ItemRackMenuFrame then C.Panel(f) end
        if name == "ItemRackOptSubFrame2" then
            for _, side in ipairs({"Left", "Middle", "Right"}) do H.Fade(_G["ItemRackOptSetsDropTexture" .. side]) end
        end
        local picker = _G.ItemRackOpt and _G.ItemRackOpt.QueueIconPicker
        -- The saved-set list's decorated inner frame has no global name.
        local setRow = _G.ItemRackOptSetList1
        if kind == "Frame" and name == "" and setRow and f == setRow:GetParent() then
            C.Clear(f); C.Panel(f)
        end
        if kind == "Frame" and name:match("^ItemRackOpt") and f ~= _G.ItemRackOptFrame and f ~= picker then
            local point, relative, relativePoint
            if f.GetPoint then point, relative, relativePoint = f:GetPoint(1) end
            if point and relativePoint and point:find("LEFT") and relative == _G.ItemRackOptFrame and relativePoint:find("RIGHT") then C.Panel(f)
            else
                C.Clear(f)
                if name:match("^ItemRackOptSubFrame%d+$") or name == "ItemRackOptSetsIconFrame" then C.Panel(f) end
            end
        end
        if kind == "ScrollFrame" and name:match("^ItemRackOpt") then
            C.Clear(f)
        end
        -- The public scrollbar primitive targets MinimalScrollBar. ItemRack
        -- still uses classic Slider thumbs; draw a strip on the existing thumb
        -- without changing its range, drag area or OnValueChanged callback.
        if kind == "Slider" and f.GetThumbTexture and f.GetOrientation then
            if f:GetOrientation() == "VERTICAL" and S.SoftPageButton then
                local up = f.ScrollUpButton or _G[name .. "ScrollUpButton"]
                local down = f.ScrollDownButton or _G[name .. "ScrollDownButton"]
                if H.Allowed(up) then S.SoftPageButton(up, "^", 9) end
                if H.Allowed(down) then S.SoftPageButton(down, "v", 9) end
            end
            H.LegacySlider(f, scrollThumbs[f])
            local thumb = f:GetThumbTexture()
            if f:GetOrientation() == "HORIZONTAL" then
                if H.Texture(thumb) then thumb:SetTexCoord(0, 1, 0, 1); thumb:SetSize(8, 12) end
                C.SettingsFont(_G[name .. "Min"], 9, 0.6, 0.6, 0.62)
                C.SettingsFont(_G[name .. "Max"], 9, 0.6, 0.6, 0.62)
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
            C.SettingsRow(f)
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
            if name:match("^ItemRackOptTab%d+$") then
                H.Tab(f, f.IsEnabled and not f:IsEnabled()); C.TabLabel(f); return true
            end
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
            C.Check(f, name == "ItemRackOptShowHelm" or name == "ItemRackOptShowCloak")
            return true
        end
        if kind == "EditBox" and name == "ItemRackOptSetsName" then
            S.EditBox(f)
            local data = S.GetFFD and S.GetFFD(f)
            if data and H.Texture(data.bg) then data.bg:SetColorTexture(0.055, 0.055, 0.055, 0.9) end
            C.SettingsFont(f, 11, 0.9, 0.9, 0.92)
            if f.SetTextInsets then f:SetTextInsets(4, 4, 0, 0) end
            return true
        end
        if kind == "EditBox" and name:match("^ItemRackOpt") and _G[name .. "Slider"] then
            -- Popup padding shifts the field's anchors; these numeric controls
            -- have their own right-aligned layout and symmetric text insets.
            S.EditBox(f)
            local data = S.GetFFD and S.GetFFD(f)
            if data and H.Texture(data.bg) then data.bg:SetColorTexture(0.055, 0.055, 0.055, 0.9) end
            C.SettingsFont(f, 10, 0.9, 0.9, 0.92)
            f:SetSize(32, 18)
            if f.SetJustifyH then f:SetJustifyH("CENTER") end
            if f.SetJustifyV then f:SetJustifyV("MIDDLE") end
            if f.SetTextInsets then f:SetTextInsets(2, 2, 0, 0) end
            return true
        end
        -- Equipment/action buttons outside options are protected and stay intact.
    end,
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("ItemRack", DefineSkin)
else DefineSkin() end
