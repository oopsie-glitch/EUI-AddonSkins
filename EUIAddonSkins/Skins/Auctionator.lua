local ADDON, ns = ...
-- Modern auction-house styling adapted from AngelosNaoumis's contribution (PR #1).
local function DefineSkin()
ns.RegisterModule("Auctionator", "Auctionator", function()
    return _G.Auctionator and _G.Auctionator.Tabs and _G.Auctionator.Tabs.State
end, function(S, module)
    -- Inside the modern auction house the controls keep EUI's bordered look, as
    -- the pack's own buttons and inputs do; AuctionFrame keeps the softer one.
    local raw, soft = S, ns.CreateSoftSkin(S, module)
    -- Auctionator's header rows are shorter than EUI's fixed sort strip, which
    -- would hang into the first result row; the strip follows the row instead.
    local headers, Headers = {}, nil
    S = setmetatable({SortHeaderBar = function(list) Headers(list) end, RefreshSoftBorders = soft.RefreshSoftBorders},
        {__index = function(_, key) if _G.AuctionHouseFrame then return raw[key] end return soft[key] end})
    local A = _G.Auctionator
    local H = ns.CreateSkinHelper(S, module)
    local roots, shells, panels = {}, {}, {}
    local scrollChrome, qualityCells, radioMarks, layouts = {}, {}, {}, {}
    local itemBorders, sellingItems = {}, {}
    -- The shared first-visit crop also supplies an owner. Selling tiles use
    -- the native socket instead; suppress only that redundant border request.
    S.SquareIcon = function(icon, owner, quality)
        if owner and sellingItems[owner] then return end
        local api = _G.AuctionHouseFrame and raw or soft
        if api.SquareIcon then return api.SquareIcon(icon, owner, quality) end
    end
    local rows, squares, squaring, zones, money, centered, glyphs, labels, darkTabs, chained = {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
    local coppers, cleared, rowWidths, aligned, widgets, refreshes, stripAt = {}, {}, {}, {}, {}, {}, {}
    local scanned, refreshHosts, radioLabels = {}, {}, {}
    local zoneHost, zoneAlpha
    local refresh, waiting
    local discoveryDirty = true
    local events = CreateFrame("Frame")
    events:RegisterEvent("AUCTION_HOUSE_SHOW")
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")

    -- The modern auction house follows EUI's own auction house pack: flat tab
    -- row, washed results zones, gold form labels. AuctionFrame keeps 1.2.0 styling.
    local function Modern() return H.Allowed(_G.AuctionHouseFrame) end
    -- Auctionator lives inside the auction house window, so it follows that
    -- window's EUI style: when EUI leaves it on Blizzard art ("off", or the
    -- Blizzard / Classic UI look), Auctionator stays stock as well.
    local function Stock()
        local EUI = _G.EllesmereUI
        if not (_G.AuctionHouseFrame and EUI and EUI.GetBlizzWindowStyle) then return false end
        local style = EUI.GetBlizzWindowStyle("auctionhouse")
        return style == "off" or style == "blizzard"
    end
    local function Pixel(f)
        if PixelUtil and f.GetEffectiveScale then return PixelUtil.GetNearestPixelSize(1, f:GetEffectiveScale(), 1) end
        return 1
    end
    local function Remember(f, shell)
        if not f or not f.GetObjectType then return end
        roots[f] = shell or roots[f] or "controls"
        refresh()
    end
    -- Foreground art (spinners, icons) survives the panel fade.
    local function Artwork(f)
        local artwork = {}
        for _, region in ipairs(H.Regions(f)) do
            if region.GetTexture and region.GetDrawLayer then
                local layer = region:GetDrawLayer()
                if layer == "ARTWORK" or layer == "OVERLAY" then artwork[region] = region:GetAlpha() end
            end
        end
        return artwork
    end
    local function Panel(f)
        if H.Allowed(f) and not panels[f] then
            local artwork = Artwork(f)
            S.Panel(f)
            panels[f] = artwork
            if f.SetBackdrop then f:SetBackdrop(nil) end
        end
        if type(panels[f]) == "table" then
            for region, alpha in pairs(panels[f]) do region:SetAlpha(alpha) end
        end
    end
    -- EUI's pack leaves its lists unfilled and washes only the results region,
    -- edged on the top and left by 1px seams. Side lists stay clear.
    local function Zone(f, wash)
        if not H.Allowed(f) then return end
        if zones[f] then
            -- EUI restrips registered insets on a theme change. Keep native
            -- foreground art (including the loading spinner) at its own alpha.
            for region, alpha in pairs(zones[f]) do region:SetAlpha(alpha) end
            return
        end
        local artwork = Artwork(f)
        zones[f] = artwork
        S.Inset(f)
        for region, alpha in pairs(artwork) do region:SetAlpha(alpha) end
        if f.SetBackdrop then f:SetBackdrop(nil) end
        if not wash then return end
        -- A child layer: EUI restrips the inset's own textures on theme passes.
        local layer = CreateFrame("Frame", nil, f)
        layer:SetAllPoints(f); layer:SetFrameLevel(f:GetFrameLevel())
        local fill = layer:CreateTexture(nil, "BACKGROUND")
        fill:SetColorTexture(1, 1, 1, 0.02); fill:SetAllPoints(layer)
        local px = Pixel(f)
        local top = layer:CreateTexture(nil, "ARTWORK")
        top:SetColorTexture(0.15, 0.15, 0.15, 1); top:SetHeight(px)
        top:SetPoint("TOPLEFT", f, "TOPLEFT", -px, 0); top:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
        local side = layer:CreateTexture(nil, "ARTWORK")
        side:SetColorTexture(0.15, 0.15, 0.15, 1); side:SetWidth(px)
        side:SetPoint("TOPRIGHT", f, "TOPLEFT", 0, 0); side:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", 0, 0)
    end
    local function Scroll(bar)
        if not H.Allowed(bar) then return end
        if bar.GetThumbTexture then H.LegacySlider(bar); return end
        -- WowTrimScrollBar's end caps live directly on the bar, outside Track,
        -- and its track art on a Background child.
        if not scrollChrome[bar] then
            scrollChrome[bar] = true
            for _, region in ipairs(H.Regions(bar)) do if region.GetTexture then H.Fade(region) end end
            if H.Allowed(bar.Background) then
                for _, region in ipairs(H.Regions(bar.Background)) do if region.GetTexture then H.Fade(region) end end
            end
        end
        S.ScrollBar(bar)
    end
    local function Radio(button)
        if not H.Allowed(button) then return end
        S.Checkbox(button)
        local label = button.Label
        if Modern() and H.Allowed(label) then
            H.Font(label)
            if radioLabels[button] ~= label then
                radioLabels[button] = label
                label:ClearAllPoints()
                label:SetPoint("LEFT", button, "RIGHT", 4, 0)
            end
        end
        if not button.CreateTexture or not button.GetChecked then return end
        if not radioMarks[button] then
            local mark = button:CreateTexture(nil, "OVERLAY", nil, 7)
            mark:SetSize(6, 6); mark:SetPoint("CENTER"); radioMarks[button] = mark
            if button.GetCheckedTexture then H.Fade(button:GetCheckedTexture()) end
            if button.GetDisabledCheckedTexture then H.Fade(button:GetDisabledCheckedTexture()) end
            H.Hook(button, "SetChecked", function() Radio(button) end)
            H.Script(button, "OnClick", function() Radio(button) end)
        end
        local r, g, b = S.GetAccentColor()
        radioMarks[button]:SetColorTexture(r, g, b, 1)
        radioMarks[button]:SetShown(button:GetChecked() and true or false)
    end
    -- Settings use large native CheckButtons. Keep their hit/label geometry,
    -- but draw the compact square on a mouse-disabled child instead.
    local configChecks, checkArt = {}, {}
    local function ConfigCheckbox(f)
        if not configChecks[f] then
            local parent = f
            local owned = false
            for _ = 1, 16 do
                if not H.Allowed(parent) then break end
                local name = parent.GetName and parent:GetName()
                if type(name) == "string" and name:match("^AuctionatorConfig.*Frame$") then owned = true; break end
                parent = parent.GetParent and parent:GetParent()
            end
            if not owned then return false end
            local host = CreateFrame("Frame", nil, f)
            host:SetSize(22, 22); host:SetPoint("CENTER", f, "CENTER"); host:EnableMouse(false)
            raw.Checkbox(host, {borderInset = 4, hover = 0.05})
            local mark = host:CreateTexture(nil, "OVERLAY", nil, 2)
            mark:SetSize(8, 8); mark:SetPoint("CENTER", host, "CENTER")
            local hover = host:CreateTexture(nil, "OVERLAY", nil, 1)
            hover:SetSize(14, 14); hover:SetPoint("CENTER", host, "CENTER")
            hover:SetColorTexture(1, 1, 1, 0.08); hover:SetAlpha(0)
            local state = {host = host, mark = mark, hover = hover}
            configChecks[f], checkArt[host] = state, true
            for _, region in ipairs(H.Regions(f)) do if H.Texture(region) then H.Fade(region) end end
            local function Paint()
                if not ns.IsEnabled(module) then return end
                if InCombatLockdown() then waiting = true; return end
                local enabled = not f.IsEnabled or f:IsEnabled()
                local checked = f.GetChecked and not not f:GetChecked() or false
                if state.checked ~= checked then mark:SetShown(checked); state.checked = checked end
                local r, g, b = raw.GetAccentColor()
                if not enabled then r, g, b = 0.4, 0.4, 0.4; hover:SetAlpha(0) end
                if state.r ~= r or state.g ~= g or state.b ~= b or state.enabled ~= enabled then
                    mark:SetColorTexture(r, g, b, enabled and 1 or 0.8)
                    state.r, state.g, state.b, state.enabled = r, g, b, enabled
                end
            end
            state.paint = Paint
            for _, method in ipairs({"SetChecked", "Enable", "Disable", "SetEnabled"}) do H.Hook(f, method, Paint) end
            H.Script(f, "OnClick", Paint)
            H.Script(f, "OnEnable", Paint); H.Script(f, "OnDisable", Paint)
            H.Script(f, "OnShow", Paint)
            H.Script(f, "OnEnter", function()
                if not InCombatLockdown() and (not f.IsEnabled or f:IsEnabled()) then hover:SetAlpha(1) end
            end)
            H.Script(f, "OnLeave", function() hover:SetAlpha(0) end)
            H.Script(f, "OnHide", function() hover:SetAlpha(0) end)
            Paint()
        else configChecks[f].paint() end
        return true
    end
    -- Pooled bag buttons re-mask and re-crop their icon on every fill, so the
    -- square inset icon is restored from the icon's own setters.
    local function Square(f, icon)
        if squaring[f] then return end
        squaring[f] = true
        if icon.GetNumMaskTextures then
            for index = icon:GetNumMaskTextures(), 1, -1 do icon:RemoveMaskTexture(icon:GetMaskTexture(index)) end
        end
        if f.IconMask and f.IconMask.Hide then f.IconMask:Hide() end
        local state = sellingItems[f]
        if state and state.geometry then
            state.geometry = icon:GetNumPoints() == 2
            if state.geometry then
                local p1, r1, rp1, x1, y1 = icon:GetPoint(1)
                local p2, r2, rp2, x2, y2 = icon:GetPoint(2)
                state.geometry = p1 == "TOPLEFT" and r1 == f and rp1 == "TOPLEFT" and x1 == 2 and y1 == -2
                    and p2 == "BOTTOMRIGHT" and r2 == f and rp2 == "BOTTOMRIGHT" and x2 == -2 and y2 == 2
            end
        end
        if not state or not state.geometry then
            icon:ClearAllPoints(); icon:SetPoint("TOPLEFT", 2, -2); icon:SetPoint("BOTTOMRIGHT", -2, 2)
            if state then state.geometry = true end
        end
        if state then S.SquareIcon(icon) else S.SquareIcon(icon, f) end
        if state and state.mask then icon:AddMaskTexture(state.mask) end
        squaring[f] = nil
    end
    -- Keep the accepted legacy AuctionFrame treatment unchanged.
    local function LegacyItem(f, icon)
        local border = H.Texture(f.IconBorder)
        if border and not itemBorders[f] and f.CreateTexture then
            local lines = {}
            for _, side in ipairs({"Top", "Bottom", "Left", "Right"}) do
                local line = f:CreateTexture(nil, "OVERLAY", nil, 6)
                f["euiQuality" .. side] = line; lines[#lines + 1] = line
                if side == "Top" or side == "Bottom" then
                    local edge = side:upper(); line:SetPoint(edge .. "LEFT"); line:SetPoint(edge .. "RIGHT"); line:SetHeight(1)
                else
                    local edge = side:upper(); line:SetPoint("TOP" .. edge); line:SetPoint("BOTTOM" .. edge); line:SetWidth(1)
                end
            end
            itemBorders[f] = lines
            H.Hook(border, "SetVertexColor", function() LegacyItem(f, icon) end)
        end
        H.Action(f, {"Icon", "icon", "IconSelectedHighlight", "Highlight",
            "euiQualityTop", "euiQualityBottom", "euiQualityLeft", "euiQualityRight"})
        icon:SetAlpha(1)
        S.SquareIcon(icon, f)
        if H.Texture(f.EmptySlot) then H.Fade(f.EmptySlot) end
        H.Fade(border)
        if itemBorders[f] and border.GetVertexColor then
            local r, g, b, a = border:GetVertexColor()
            for _, line in ipairs(itemBorders[f]) do line:SetColorTexture(r, g, b, a or 1); line:SetAlpha(1) end
        end
    end
    -- EllesmereUI's AH ItemDisplay deliberately retains GiantItemButton art.
    -- Reuse that client socket and native rarity texture, without Button's plate
    -- or SquareIcon's extra black edge. Auctionator still owns actions/state.
    local function SellingItem(f, icon)
        local state = sellingItems[f]
        if not state then
            local parent, owned = f, false
            for _ = 1, 16 do
                if parent == _G.AuctionatorSellingFrame then owned = true; break end
                if not H.Allowed(parent) or not parent.GetParent then break end
                parent = parent:GetParent()
            end
            if not owned then return false end
            -- Older clients without this atlas keep the existing native path.
            if not (C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("auctionhouse-itemicon-empty")) then return false end
            state = {}; sellingItems[f] = state
            local socket = H.Texture(f.EmptySlot)
            if not socket then socket = f:CreateTexture(nil, "BACKGROUND", nil, 1); f.EmptySlot = socket end
            socket:SetAtlas("auctionhouse-itemicon-empty", false)
            local selling = _G.AuctionatorSellingFrame
            state.preview = selling and selling.SaleItemFrame and selling.SaleItemFrame.Icon == f
            if state.preview then
                -- The reused preview EmptySlot inherits the old sheet's 0.640625
                -- crop. The AH atlas needs its full region, in every item state.
                socket:SetTexCoord(0, 1, 0, 1)
            end
            socket:ClearAllPoints(); socket:SetAllPoints(f)
            -- Only the large preview needs a socket. On inventory tiles this
            -- decorative background protrudes outside the inset rarity ring.
            if state.preview then socket:SetAlpha(1) else H.Fade(socket) end
            state.socket = socket
            local border = H.Texture(f.IconBorder)
            if border then
                border:ClearAllPoints(); border:SetAllPoints(icon)
                border:SetDrawLayer("OVERLAY", 0)
            end
            local selected = H.Texture(f.IconSelectedHighlight)
            if selected then
                -- Keep the native selection colour/visibility; use a restrained
                -- outer ring rather than the broad artifact glow.
                selected:SetTexture("Interface\\Common\\WhiteIconFrame")
            end
            if f.CreateMaskTexture and icon.AddMaskTexture then
                local mask = f:CreateMaskTexture()
                mask:SetTexture("Interface\\Common\\common-iconmask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                mask:SetAllPoints(icon); state.mask = mask
            end
            for _, method in ipairs({"SetTexture", "SetAtlas", "AddMaskTexture", "SetTexCoord", "SetAllPoints"}) do
                H.Hook(icon, method, function()
                    if InCombatLockdown() then waiting = true; return end
                    if not Stock() then Square(f, icon) end
                end)
            end
        end
        local alpha = state.preview and 1 or 0
        if state.socket:GetAlpha() ~= alpha then
            if state.preview then state.socket:SetAlpha(1) else H.Fade(state.socket) end
        end
        Square(f, icon)
        for _, region in ipairs(H.Regions(f)) do H.Font(region) end
        return true
    end
    local function Item(f, icon)
        if not Modern() then LegacyItem(f, icon); return end
        if SellingItem(f, icon) then return end
        -- Auctionator owns rarity colour and selected/empty visibility. Keep its
        -- texture in EUI's theme registry instead of replacing it with four lines.
        H.Action(f, {"Icon", "icon", "IconBorder", "IconSelectedHighlight", "Highlight",
            "ProfessionQualityOverlay"})
        local border = H.Texture(f.IconBorder)
        if border then border:SetDrawLayer("OVERLAY", 6) end
        if not squares[f] then
            squares[f] = true
            if f.GetNormalTexture and f:GetNormalTexture() then H.Fade(f:GetNormalTexture()) end
            for _, method in ipairs({"SetTexture", "SetAtlas", "AddMaskTexture", "SetTexCoord", "SetAllPoints"}) do
                H.Hook(icon, method, function() Square(f, icon) end)
            end
        end
        Square(f, icon)
        if H.Texture(f.EmptySlot) then H.Fade(f.EmptySlot) end
    end
    -- Retail result cells have native border art but Populate never colours it.
    -- Read the current entry at completed Populate; never cache rarity by row.
    local function ResultQuality(cell)
        if not H.Allowed(cell) or Stock() then return end
        if InCombatLockdown() then waiting = true; return end
        local border = H.Texture(cell.IconBorder)
        if not border then return end
        local data = cell.rowData
        local quality
        if data then
            if data.itemKey and C_AuctionHouse and C_AuctionHouse.GetItemKeyInfo then
                local info = C_AuctionHouse.GetItemKeyInfo(data.itemKey)
                quality = info and info.quality
            end
            if quality == nil and data.itemLink and C_Item and C_Item.GetItemInfo then
                quality = select(3, C_Item.GetItemInfo(data.itemLink))
            end
        end
        local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
        -- A recycled cell with missing data must not show the previous rarity.
        local shown = color ~= nil
        if not border.IsShown or border:IsShown() ~= shown then border:SetShown(shown) end
        if color then
            local r, g, b, a = border:GetVertexColor()
            if r ~= color.r or g ~= color.g or b ~= color.b or a ~= 1 then
                border:SetVertexColor(color.r, color.g, color.b, 1)
            end
        end
    end
    local function Row(row)
        if not rows[row] then
            rows[row] = true
            if row.NormalTexture then H.Fade(row.NormalTexture) end
            if H.Texture(row.HighlightTexture) then row.HighlightTexture:SetColorTexture(1, 1, 1, 0.1) end
            if H.Texture(row.SelectedHighlight) then row.SelectedHighlight:SetColorTexture(1, 1, 1, 0.15) end
        end
        for _, cell in pairs(row.cells) do
            local icon = type(cell) == "table" and H.Texture(cell.Icon)
            if icon and not squares[cell] then
                squares[cell] = true
                S.SquareIcon(icon)
            end
            if icon and H.Texture(cell.IconBorder) then
                if not qualityCells[cell] then
                    qualityCells[cell] = true
                    cell.IconBorder:SetDrawLayer("OVERLAY", 6)
                    H.Hook(cell, "Populate", function() ResultQuality(cell) end)
                end
                ResultQuality(cell)
            end
        end
    end
    local function RowIfCells(row) if row.cells then Row(row) end end
    Headers = function(list)
        local container = list.HeaderContainer
        if not H.Allowed(container) or not container.CreateTexture then return end
        if not headers[container] then
            local strip = container:CreateTexture(nil, "BACKGROUND", nil, 1)
            strip:SetColorTexture(0.02, 0.02, 0.02, 0.5); strip:SetAllPoints(container)
            headers[container] = strip
        end
        -- The strip spans the listing's row area (washed below), so header and
        -- table share their corners; the header row itself can start outside the
        -- list and the window.
        local area = H.Allowed(list.ScrollArea) and list.ScrollArea or list
        local left, right, rowLeft, rowRight
        if area.GetLeft and container.GetLeft then
            left, right, rowLeft, rowRight = area:GetLeft(), area:GetRight(), container:GetLeft(), container:GetRight()
        end
        local at = stripAt[container]
        if left and right and rowLeft and rowRight
            and not (at and at[1] == left - rowLeft and at[2] == right - rowRight) then
            if not at then at = {}; stripAt[container] = at end
            at[1], at[2] = left - rowLeft, right - rowRight
            local strip = headers[container]
            strip:ClearAllPoints()
            strip:SetPoint("TOPLEFT", container, "TOPLEFT", at[1], 0)
            strip:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", at[2], 0)
        end
        for _, column in ipairs(H.Children(container)) do
            if H.Allowed(column) and column:GetObjectType() == "Button" then
                if not headers[column] and column.CreateTexture then
                    for _, key in ipairs({"Left", "Middle", "Right"}) do H.Fade(column[key]) end
                    for _, region in ipairs(H.Regions(column)) do if H.Texture(region) then H.Fade(region) end end
                    local hover = column:CreateTexture(nil, "HIGHLIGHT")
                    hover:SetColorTexture(1, 1, 1, 0.1); hover:SetAllPoints(column)
                    headers[column] = hover
                end
                local label = column.GetFontString and column:GetFontString()
                if label and S.White then S.White(label) end
            end
        end
        local box = list.ScrollArea and list.ScrollArea.ScrollBox
        if H.Allowed(box) and box.ForEachFrame then
            -- Rows pool on data changes; restyle just this box, not a full refresh.
            H.Hook(box, "Update", function() box:ForEachFrame(RowIfCells) end)
        end
    end
    -- Numeric edit boxes retain their own font and template text insets; the
    -- generic frame walk only visits FontStrings. Align the input text itself.
    local function Number(box, justify, rightInset)
        if not H.Allowed(box) or box:GetObjectType() ~= "EditBox" then return end
        if S.Font then S.Font(box) end
        local texts = centered[box]
        if not texts then
            texts = {}; centered[box] = texts
            local left, right = justify == "CENTER" and 0 or 6, rightInset or 0
            box:SetJustifyH(justify)
            if box.SetJustifyV then box:SetJustifyV("MIDDLE") end
            box:SetTextInsets(left, right, 0, 0)
            -- LargeInputBox templates can anchor the internal text separately
            -- from the edit box. Center its rectangle too; leave field labels
            -- and the money template's currency-symbol label in native place.
            for _, region in ipairs(H.Regions(box)) do
                if H.Allowed(region) and region:GetObjectType() == "FontString"
                    and region ~= box.Label and region ~= box.label then
                    region:ClearAllPoints()
                    region:SetPoint("TOPLEFT", box, "TOPLEFT", left, 0)
                    region:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -right, 0)
                    region:SetJustifyH(justify)
                    region:SetJustifyV("MIDDLE")
                    texts[#texts + 1] = region
                end
            end
        end
        if S.Font then for _, text in ipairs(texts) do S.Font(text) end end
    end
    -- Coin icons are small square textures on each box; edge art is tall and thin.
    local function Money(f)
        for _, key in ipairs({"GoldBox", "SilverBox", "CopperBox"}) do
            local box = f[key]
            if H.Allowed(box) and not money[box] then
                local coins = {}
                for _, region in ipairs(H.Regions(box)) do
                    local w, h
                    if region.GetSize then w, h = region:GetSize() end
                    if H.Texture(region) and w and h and w > 0 and w <= 18 and math.abs(w - h) < 2 then coins[#coins + 1] = region end
                end
                S.EditBox(box)
                local name = box.GetName and box:GetName()
                if name then for _, suffix in ipairs({"Left", "Middle", "Right"}) do H.Fade(_G[name .. suffix]) end end
                for _, coin in ipairs(coins) do coin:SetAlpha(1) end
                -- EUI's sell inputs run 5px shorter than Blizzard's.
                local height = box.GetHeight and box:GetHeight()
                if height and height > 5 then box:SetHeight(height - 5) end
                money[box] = #coins > 0 and 20 or 6
            end
            if H.Allowed(box) and money[box] then Number(box, "RIGHT", money[box]) end
        end
        if H.Allowed(f.CopperBox) and not money[f] then money[f] = true; coppers[#coppers + 1] = f.CopperBox end
    end
    -- Keep 4px between a box and the button seated right of it (copper and Post),
    -- measured once the layout exists: the anchoring differs between Auctionator builds.
    local function Clear(box, scope)
        if not H.Allowed(box) or cleared[box] or not box.GetRight then return end
        local left, right, top, bottom = box:GetLeft(), box:GetRight(), box:GetTop(), box:GetBottom()
        if not (left and right and top and bottom) then return end
        cleared[box] = true
        local gap
        local function find(f, depth)
            for _, child in ipairs(H.Children(f)) do
                if H.Allowed(child) and child ~= box and child:GetObjectType() == "Button" and child.GetLeft then
                    local l, t, b = child:GetLeft(), child:GetTop(), child:GetBottom()
                    if l and t and b and l > left and l < right + 4 and t > bottom and b < top and (not gap or l - right < gap) then gap = l - right end
                end
                if depth < 3 and H.Allowed(child) then find(child, depth + 1) end
            end
        end
        find(scope, 0)
        if not gap or gap >= 4 then return end
        local shrink, points, moved = 4 - gap, {}, false
        for index = 1, box:GetNumPoints() do points[index] = {box:GetPoint(index)} end
        for _, p in ipairs(points) do
            if p[1]:find("RIGHT") then p[4] = (p[4] or 0) - shrink; moved = true end
        end
        if moved then
            box:ClearAllPoints()
            for _, p in ipairs(points) do box:SetPoint(p[1], p[2], p[3], p[4] or 0, p[5] or 0) end
        else box:SetWidth(box:GetWidth() - shrink) end
    end
    local function Center(box)
        -- Auctionator 341 uses a Quantity wrapper; older layouts expose the
        -- EditBox directly. Resolve the child without changing the wrapper.
        if H.Allowed(box) and box:GetObjectType() ~= "EditBox" then box = box.InputBox end
        if not H.Allowed(box) or box:GetObjectType() ~= "EditBox" then return end
        S.EditBox(box)
        Number(box, "CENTER")
    end
    -- Option widgets (search options, config) wrap their dropdown, whose arrow is a
    -- child button of its own, and a per-field reset button showing an icon texture.
    local function Dropdown(dropdown)
        if widgets[dropdown] then return end
        widgets[dropdown] = true
        S.Dropdown(dropdown)
        for _, child in ipairs(H.Children(dropdown)) do
            if H.Allowed(child) and child:GetObjectType() == "Button" then
                for _, region in ipairs(H.Regions(child)) do if H.Texture(region) then H.Fade(region) end end
            end
        end
    end
    -- Reset buttons stay a bare icon with a hover wash: a block around each one read
    -- as stray empty boxes wherever Auctionator hides the icon.
    local function Reset(button)
        if widgets[button] or not button.CreateTexture then return end
        widgets[button] = true
        local icon = H.Texture(button.texture) or H.Texture(button.Icon)
            or H.Texture(button.GetNormalTexture and button:GetNormalTexture())
        for _, region in ipairs(H.Regions(button)) do
            if H.Texture(region) and region ~= icon then H.Fade(region) end
        end
        if icon then icon:SetDrawLayer("OVERLAY") end
        local hover = button:CreateTexture(nil, "HIGHLIGHT")
        hover:SetColorTexture(1, 1, 1, 0.1); hover:SetAllPoints(button)
    end
    local function Shift(f, dx, dy)
        local points = {}
        for index = 1, f:GetNumPoints() do points[index] = {f:GetPoint(index)} end
        f:ClearAllPoints()
        for _, p in ipairs(points) do f:SetPoint(p[1], p[2], p[3], (p[4] or 0) + dx, (p[5] or 0) + dy) end
    end
    -- Selling's price tabs start a few pixels in from the results zone; line the row up with it.
    local function AlignTabs(row, first, zone)
        if not (H.Allowed(row) and H.Allowed(first) and H.Allowed(zone)) or aligned[row] or not first.GetLeft then return end
        local from, to = first:GetLeft(), zone:GetLeft()
        if not (from and to) then return end
        aligned[row] = true
        if math.abs(to - from) > 0.5 then Shift(row, to - from, 0) end
    end
    -- Shopping's search row sits on the list tabs; lift it until 6px clear.
    local function SearchGap(f)
        local options, tabs = f.SearchOptions, f.ContainerTabs
        if not (H.Allowed(options) and H.Allowed(options.SearchString) and tabs and H.Allowed(tabs.ListsTab))
            or aligned[options] or not options.SearchString.GetBottom then return end
        local bottom, top = options.SearchString:GetBottom(), tabs.ListsTab:GetTop()
        if not (bottom and top) then return end
        aligned[options] = true
        if bottom - top < 6 then Shift(options, 0, 6 - (bottom - top)) end
    end
    -- New List / Import / Export: equal widths and 4px gaps, kept inside the lists
    -- column so none of them sits over the results wash.
    local function ListButtons(f)
        local lists, buttons = f.ListsContainer, {f.NewListButton, f.ImportButton, f.ExportButton}
        if not (H.Allowed(lists) and lists.GetWidth) then return end
        for index = 1, 3 do if not H.Allowed(buttons[index]) then return end end
        local width = lists:GetWidth()
        if not width or width <= 8 or rowWidths[lists] == width then return end
        rowWidths[lists] = width
        local previous
        for _, button in ipairs(buttons) do
            button:ClearAllPoints(); button:SetWidth((width - 8) / 3)
            if previous then button:SetPoint("LEFT", previous, "RIGHT", 4, 0)
            else button:SetPoint("TOPLEFT", lists, "BOTTOMLEFT", 0, -6) end
            previous = button
        end
    end
    -- Refresh buttons sit directly on Auctionator's panels as icon-only buttons; their
    -- icon can be set by file ID, which carries no name to match, so the panel says it.
    local function PanelRefresh(button)
        if not (H.Allowed(button) and button:GetObjectType() == "Button" and H.Texture(button.Icon)) then return false end
        return not button.IconBorder and not button.EmptySlot and not (button.GetFontString and button:GetFontString())
    end
    -- Checked once per button: Visit reaches every button on every pass.
    local function Named(texture)
        if not H.Texture(texture) then return false end
        local atlas = texture.GetAtlas and texture:GetAtlas()
        local path = texture.GetTexture and texture:GetTexture()
        return type(atlas) == "string" and atlas:find("[Rr]efresh") ~= nil
            or type(path) == "string" and path:find("[Rr]efresh") ~= nil
    end
    local function IsRefresh(button)
        local known = refreshes[button]
        if known == nil then
            local parent = button.GetParent and button:GetParent()
            known = Named(button.Icon) or (button.GetNormalTexture and Named(button:GetNormalTexture()))
                or (parent and refreshHosts[parent] and PanelRefresh(button)) or false
            refreshes[button] = known
        end
        return known
    end
    -- EUI's pack draws refresh as its white house glyph, without a button block.
    local function Glyph(button)
        if glyphs[button] or not button.CreateTexture then return end
        -- As the pack does: without the atlas the native button stays rather than going blank.
        if not (C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("UI-RefreshButton")) then return end
        for _, region in ipairs(H.Regions(button)) do if H.Texture(region) then H.Fade(region) end end
        local glyph = button:CreateTexture(nil, "OVERLAY")
        glyph:SetAtlas("UI-RefreshButton", false); glyph:SetSize(16, 16); glyph:SetPoint("CENTER")
        glyph:SetDesaturated(true); glyph:SetVertexColor(1, 1, 1, 0.9)
        glyphs[button] = glyph
        H.Script(button, "OnEnter", function() glyph:SetVertexColor(1, 1, 1, 1) end)
        H.Script(button, "OnLeave", function() glyph:SetVertexColor(1, 1, 1, 0.9) end)
    end
    -- Blizzard's sell form labels are gold; Auctionator draws its own white. Labels
    -- carry letters and no digits; values (deposit, coins, hours) keep their color.
    local function Gold(f, depth)
        if not H.Allowed(f) or depth > 6 then return end
        local kind = f:GetObjectType()
        if kind == "Button" or kind == "EditBox" or kind == "CheckButton" then return end
        local r, g, b = NORMAL_FONT_COLOR:GetRGB()
        for _, region in ipairs(H.Regions(f)) do
            if region:GetObjectType() == "FontString" then
                local text = region:GetText()
                local cr, cg, cb = region:GetTextColor()
                if type(text) == "string" and text:find("%a") and not text:find("%d") and cr > 0.95 and cg > 0.95 and cb > 0.95 then
                    region:SetTextColor(r, g, b)
                end
            end
        end
        for _, child in ipairs(H.Children(f)) do Gold(child, depth + 1) end
    end
    -- Flat inner tabs (Selling's price views sit right above the main tab row):
    -- no plate, so only the label and the accent underline mark the active view.
    local function InnerTab(tab, selected, flat)
        if Modern() and S.Tab and not darkTabs[tab] and H.Allowed(tab) then
            darkTabs[tab] = true
            if flat then
                S.Tab(tab)
                for _, region in ipairs(H.Regions(tab)) do
                    if H.Texture(region) and region:GetDrawLayer() == "BACKGROUND" then H.Fade(region) end
                end
            else S.Tab(tab, {darkActive = true}) end
        end
        H.Tab(tab, selected or false)
        if tab.ActiveMarker then H.Fade(tab.ActiveMarker) end
        H.Script(tab, "OnClick", refresh)
    end
    -- EUI's pack draws its zone seams on an unnamed full-window child (two 1px
    -- lines, rail and sell sub-hosts) placed for Blizzard's views. The pack only
    -- toggles its sub-hosts, so its alpha is ours to lower over Auctionator.
    local function Zones(host, hidden)
        if not zoneHost then
            for _, child in ipairs(H.Children(host)) do
                if H.Allowed(child) and child.GetName and not child:GetName() and child.GetNumRegions and child:GetNumRegions() == 2
                    and child.GetNumChildren and child:GetNumChildren() == 2 then
                    local seams = true
                    for _, region in ipairs(H.Regions(child)) do
                        local height = region.GetHeight and region:GetHeight()
                        if not H.Texture(region) or not height or height <= 0 or height > 2
                            or not region.GetDrawLayer or region:GetDrawLayer() ~= "ARTWORK" then seams = false end
                    end
                    if seams then zoneHost, zoneAlpha = child, child:GetAlpha(); break end
                end
            end
        end
        local alpha = hidden and 0 or zoneAlpha
        if zoneHost and zoneHost:GetAlpha() ~= alpha then zoneHost:SetAlpha(alpha) end
    end
    local function ModernTabs()
        local host, container = _G.AuctionHouseFrame, _G.AuctionatorAHTabsContainer
        if not (Modern() and container and type(container.Tabs) == "table") then return end
        H.Hook(host, "SetDisplayMode", refresh)
        local previous = host.Tabs and host.Tabs[#host.Tabs]
        local active = false
        for _, tab in ipairs(container.Tabs) do
            if H.Allowed(tab) then
                local view = tab.frameRef
                local visible = view and view.IsShown and view:IsShown() or false
                active = active or visible
                H.Tab(tab, visible)
                if not chained[tab] and previous then
                    chained[tab] = true
                    -- One physical pixel apart and 2px shorter, as EUI's own tab rows.
                    if tab.SetHitRectInsets then tab:SetHitRectInsets(0, 0, 0, 0) end
                    local height = tab:GetHeight(); if height and height > 2 then tab:SetHeight(height - 2) end
                    tab:ClearAllPoints(); tab:SetPoint("LEFT", previous, "RIGHT", Pixel(tab), 0)
                end
                previous = tab
                H.Script(tab, "OnClick", refresh)
                if view then H.Script(view, "OnShow", refresh); H.Script(view, "OnHide", refresh) end
            end
        end
        -- Auctionator clears the display mode, which the pack's own sync skips.
        if active and S.SetTabSelection then
            for _, tab in ipairs(host.Tabs or {}) do if H.Allowed(tab) then S.SetTabSelection(tab, false) end end
        end
        Zones(host, active)
    end
    local function SearchLayout(f)
        local options = f.SearchOptions
        if layouts[f] or not _G.AuctionFrame or not options or not options.SearchLabel
            or not options.SearchString or not options.SearchButton or not options.SearchLabel.ClearAllPoints then return end
        layouts[f] = true
        options.SearchLabel:ClearAllPoints(); options.SearchLabel:SetPoint("TOPLEFT", options, "TOPLEFT", 12, -10)
        options.SearchString:ClearAllPoints(); options.SearchString:SetPoint("LEFT", options.SearchLabel, "RIGHT", 12, 0)
        local previous = options.SearchString
        for _, key in ipairs({"ResetSearchStringButton", "SearchButton", "MoreButton", "AddToListButton", "FullScanButton"}) do
            local button = options[key]
            if H.Allowed(button) and button.ClearAllPoints then
                button:ClearAllPoints(); button:SetPoint("LEFT", previous, "RIGHT", 6, 0); previous = button
            end
        end
        for _, key in ipairs({"ListsContainer", "RecentsContainer"}) do
            local list = f[key]
            if H.Allowed(list) and list.ClearAllPoints then
                list:ClearAllPoints(); list:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -84)
                list:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, key == "ListsContainer" and 35 or 10)
            end
        end
        if H.Allowed(f.ContainerTabs) and f.ListsContainer then
            f.ContainerTabs:ClearAllPoints(); f.ContainerTabs:SetPoint("BOTTOMLEFT", f.ListsContainer, "TOPLEFT", 0, 4)
        end
    end
    -- Visit runs for every frame on every pass: its key lists are built once.
    local PRICE_TABS = {"CurrentPricesTab", "PriceHistoryTab", "YourHistoryTab"}
    local LEGACY_TABS = {"HistoryButton", "CurrentPricesButton", "YourHistoryButton"}
    local ICON_BUTTONS = {"RefreshButton", "ResetSearchStringButton"}
    local CLEAR_INSETS = {"ShoppingResultsInset", "HistoricalPriceInset", "BagInset", "ListsContainer", "RecentsContainer"}
    local LEGACY_PANELS = {"ShoppingResultsInset", "BagInset", "HistoricalPriceInset", "ListsContainer", "RecentsContainer", "ScrollArea"}
    local MODERN_FONTS = {"Title", "NoResultsText", "ResultsText"}
    local LEGACY_FONTS = {"Title", "SearchLabel", "Deposit", "Total", "NoResultsText", "ResultsText"}
    local function Visit(f, kind)
        if checkArt[f] then return true end
        local modern = Modern()
        if kind == "CheckButton" and ConfigCheckbox(f) then return true end
        if kind == "Slider" then Scroll(f); return true end
        if headers[f] then return true end
        if modern and f.cells then Row(f); return true end
        if f.isAuctionatorRadio and H.Allowed(f.RadioButton) then Radio(f.RadioButton) end
        local dropdown = H.Allowed(f.DropDown) and f.DropDown:GetObjectType()
        if dropdown == "Button" or dropdown == "DropdownButton" then Dropdown(f.DropDown) end
        if H.Allowed(f.ResetButton) and f.ResetButton:GetObjectType() == "Button" then Reset(f.ResetButton) end
        if kind == "CheckButton" and f.GetParent then
            local parent = f:GetParent()
            if parent and parent.isAuctionatorRadio then Radio(f); return true end
        end
        if kind == "Button" then
            if modern and widgets[f] then return true end
            if modern and IsRefresh(f) then Glyph(f); return true end
            local icon = H.Icon(f)
            if icon and (f.IconBorder or f.EmptySlot or f.IconSelectedHighlight) then Item(f, icon); return true end
        end
        if modern then
            if f.GoldBox and f.SilverBox then Money(f) end
            Center(f.Quantity)
            ListButtons(f)
            SearchGap(f)
        end
        if f.ListsTab and f.RecentsTab then
            for _, tab in ipairs({f.ListsTab, f.RecentsTab}) do
                InnerTab(tab, f.selectedTab and tab.GetID and f.selectedTab == tab:GetID())
            end
            H.Hook(f, "SetView", refresh)
        end
        if f.CurrentPricesTab and f.PriceHistoryTab then
            for _, key in ipairs(PRICE_TABS) do
                local tab = f[key]
                if H.Allowed(tab) then InnerTab(tab, f.selectedTab and tab.GetID and f.selectedTab == tab:GetID(), true) end
            end
            local panel = f.GetParent and f:GetParent()
            local listing = panel and panel.CurrentPricesListing
            if modern and listing then AlignTabs(f, f.CurrentPricesTab, listing.ScrollArea) end
        end
        for _, key in ipairs(LEGACY_TABS) do
            local button = f[key]
            if H.Allowed(button) then
                local view = key == "HistoryButton" and f.HistoryPrices or key == "CurrentPricesButton" and f.CurrentPrices or f.YourHistory
                H.Tab(button, view and view.IsShown and view:IsShown() or false)
                if view then H.Script(view, "OnShow", refresh); H.Script(view, "OnHide", refresh) end
            end
        end
        for _, key in ipairs(ICON_BUTTONS) do
            local button = f[key]
            if H.Allowed(button) and button:GetObjectType() == "Button" then
                if modern and key == "RefreshButton" then Glyph(button)
                elseif modern and key == "ResetSearchStringButton" then Reset(button)
                else
                    local icon = H.Texture(button.GetNormalTexture and button:GetNormalTexture())
                    if icon then
                        button.euiRefreshIcon = icon
                        H.Action(button, {"euiRefreshIcon"}); icon:SetAlpha(1); S.SquareIcon(icon)
                        local r, g, b = S.GetAccentColor(); if icon.SetVertexColor then icon:SetVertexColor(r, g, b) end
                    end
                end
            end
        end
        SearchLayout(f)
        if modern then
            -- Insets stay clear; each results table washes its own row area, so the
            -- wash, its seams and the header strip share one rect.
            for _, key in ipairs(CLEAR_INSETS) do Zone(f[key]) end
            Zone(f.ScrollArea, f.HeaderContainer ~= nil)
        else
            for _, key in ipairs(LEGACY_PANELS) do Panel(f[key]) end
        end
        -- Search, deposit and total labels stay Blizzard gold beside the native sell form.
        for _, key in ipairs(modern and MODERN_FONTS or LEGACY_FONTS) do
            H.Font(f[key], 0.9, 0.9, 0.92)
        end
        if H.Allowed(f.NineSlice) then S.FadeNineSlice(f.NineSlice) end
        -- Auctionator's simple panels expose their decorative rock background.
        if f.Bg then H.Fade(f.Bg) end
        if H.Allowed(f.Border) then
            S.FadeNineSlice(f.Border)
            for _, region in ipairs({f.Border:GetRegions()}) do
                if region.GetTexture then H.Fade(region) end
            end
        end
        -- Insets stay clear on the modern auction house, popups included: their form
        -- sits plainly on the window, like Auctionator's own Info tab.
        if modern and H.Allowed(f.Inset) then Zone(f.Inset)
        elseif f.Inset and H.Allowed(f.Inset) and not panels[f.Inset] then
            panels[f.Inset] = true
            S.Panel(f.Inset)
            if f.Inset.SetBackdrop then f.Inset:SetBackdrop(nil) end
        end
        if H.Allowed(f.CloseButton) then S.CloseButton(f.CloseButton) end
        -- WowTrimScrollBar is an EventFrame rather than a Slider.
        if H.Allowed(f.ScrollBar) then Scroll(f.ScrollBar) end
    end
    local REFRESH_HOSTS = {"AuctionatorCancellingFrame", "AuctionatorBuyItemFrame", "AuctionatorBuyCommodityFrame"}
    local function RefreshHost(host)
        if not H.Allowed(host) or refreshHosts[host] then return end
        refreshHosts[host] = true
        -- Forget answers given before this panel was known.
        for _, child in ipairs(H.Children(host)) do refreshes[child] = nil end
    end
    local TAB_METHODS = {"Selected", "DeselectTab"}
    local DIALOGS = {"AuctionatorShoppingTabItemFrame", "AuctionatorExportListFrame", "AuctionatorImportListFrame", "AuctionatorItemHistoryFrame"}
    -- Auctionator's profession additions sit on Blizzard's already themed form.
    -- Style only their owned controls, never the host, reagents or recipe list.
    -- Frame names/initializers follow the remaining coverage from PR #1.
    local PROFESSION_ROOTS = {"AuctionatorCraftingInfo", "AuctionatorEnchantInfoFrame",
        "AuctionatorCraftingInfoProfessionsFrame", "AuctionatorCraftingInfoProfessionsOrderFrame",
        "AuctionatorTradeSkillSearch", "AuctionatorCraftingInfoObjectiveTrackerFrame"}
    local PROFESSION_INITIALIZERS = {"Initialize", "InitializeProfessionsFrame",
        "InitializeCustomerOrdersFrame", "InitializeObjectiveTrackerFrame"}
    local professionPaint, professionInputs = {}, {}
    local function ProfessionText(text)
        if not H.Allowed(text) or text:GetObjectType() ~= "FontString" then return end
        -- Keep gold labels, inline profit/warning colors and money textures.
        local r, g, b = text:GetTextColor()
        raw.Font(text, r, g, b)
    end
    local function ProfessionButton(button)
        if not H.Allowed(button) then return end
        raw.Button(button)
        if raw.StateButtonLabel then raw.StateButtonLabel(button) end
    end
    local function PaintProfession(f)
        if not ns.IsEnabled(module) or not H.Allowed(f) then return end
        if InCombatLockdown() then waiting = true; return end
        ProfessionText(f.Total)
        ProfessionButton(f.SearchButton)
        local popup = f.CustomQuantity
        if H.Allowed(popup) then
            if not shells[popup] then
                shells[popup] = true
                raw.Shell(popup, {noAccent = true})
                if popup.SetBackdrop then popup:SetBackdrop(nil) end
                if H.Allowed(popup.NineSlice) then raw.FadeNineSlice(popup.NineSlice) end
                if H.Allowed(popup.CloseButton) then raw.CloseButton(popup.CloseButton) end
            end
            local quantity = popup.Quantity
            local input = H.Allowed(quantity) and (quantity.InputBox or quantity)
            if H.Allowed(input) and input:GetObjectType() == "EditBox" then
                local state = professionInputs[input]
                if not state then
                    state = {}; professionInputs[input] = state
                    raw.EditBox(input)
                end
                local font, flags
                if raw.GetFont then font, flags = raw.GetFont() end
                -- EditBox font writes can fire native OnTextChanged handlers.
                if not state.painted or state.font ~= font or state.flags ~= flags then
                    raw.Font(input)
                    state.painted, state.font, state.flags = true, font, flags
                end
                ProfessionText(input.Label)
            end
            ProfessionButton(popup.SearchButton)
            ProfessionText(popup.TitleText)
        end
    end
    local function RefreshProfessions()
        for _, name in ipairs(PROFESSION_ROOTS) do
            local f = _G[name]
            if H.Allowed(f) then
                if not professionPaint[f] then
                    local paint = function() PaintProfession(f) end
                    professionPaint[f] = paint
                    H.Script(f, "OnShow", paint)
                end
                local popup = f.CustomQuantity
                if H.Allowed(popup) then H.Script(popup, "OnShow", professionPaint[f]) end
                PaintProfession(f)
            end
        end
    end
    local function Apply()
        if InCombatLockdown() then waiting = true; return end
        waiting = false
        -- Initializers may arrive with a load-on-demand profession addon.
        -- Post-hooks paint completed controls before the next rendered frame.
        for _, method in ipairs(PROFESSION_INITIALIZERS) do H.Hook(A.CraftingInfo, method, RefreshProfessions) end
        H.Hook(A.EnchantInfo, "Initialize", RefreshProfessions)
        RefreshProfessions()
        if Stock() then
            if zoneHost then zoneHost:SetAlpha(zoneAlpha) end
            return
        end
        local active = false
        for _, details in ipairs(A.Tabs.State.knownTabs or {}) do
            local f = _G[details.tabFrameName]
            if f then roots[f] = "content" end
            local tab = _G["AuctionatorTabs_" .. details.name]
            if H.Allowed(tab) then
                local visible = f and f.IsShown and f:IsShown()
                    and (not tab.wrapperFrame or not tab.wrapperFrame.IsShown or tab.wrapperFrame:IsShown()) or false
                active = active or visible
                H.Tab(tab, visible)
                for _, method in ipairs(TAB_METHODS) do H.Hook(tab, method, refresh) end
                H.Script(tab, "OnClick", refresh)
                if tab.wrapperFrame then roots[tab.wrapperFrame] = "content" end
                if f then H.Script(f, "OnHide", refresh); H.Script(f, "OnShow", refresh) end
            end
        end
        -- Visual overrides only: Auctionator's wrapper does not always update
        -- the Blizzard host's selectedTab value when it opens an extension tab.
        if _G.AuctionFrame then
            for index = 1, 3 do
                local tab = _G["AuctionFrameTab" .. index]
                if H.Allowed(tab) and S.SetTabSelection then
                    if active then S.SetTabSelection(tab, false) else S.SetTabSelection(tab, nil) end
                end
            end
        end
        ModernTabs()
        -- Panels with icon-only refresh buttons.
        local selling = _G.AuctionatorSellingFrame
        for _, name in ipairs(REFRESH_HOSTS) do RefreshHost(_G[name]) end
        RefreshHost(selling and selling.SaleItemFrame)
        -- Only addon-owned globals, never a scan of the Blizzard auction house.
        if discoveryDirty then
            discoveryDirty = false
            for name, f in pairs(_G) do
                if type(name) == "string" and name:match("^AuctionatorConfig.*Frame$") and (type(f) == "table" or type(f) == "userdata") then
                    if f.GetObjectType then roots[f] = roots[f] or "controls" end
                end
            end
        end
        for _, name in ipairs(DIALOGS) do
            if _G[name] then roots[_G[name]] = "dialog" end
        end
        -- Modern tab panels sit inside the already skinned auction house window;
        -- a shell of their own would darken them against Blizzard's panels.
        local modern = Modern()
        for f, mode in pairs(roots) do
            if H.Allowed(f) then
                if mode ~= "controls" and not (modern and mode == "content") and not shells[f] then
                    shells[f] = true
                    H.Shell(f, refresh, {noTopBar = mode == "content", bottomBar = mode == "dialog" and 32 or nil})
                end
                -- A hidden root is scanned once, which hooks its OnShow; after that
                -- only visible roots are walked, as hidden ones cannot change the look.
                if not scanned[f] or not f.IsVisible or f:IsVisible() then
                    scanned[f] = true
                    H.Scan(f, refresh, Visit)
                end
            end
        end
        local sale = selling and selling.SaleItemFrame
        if modern and H.Allowed(sale) and not labels[sale] then labels[sale] = true; Gold(sale, 0) end
        for _, box in ipairs(coppers) do Clear(box, H.Allowed(sale) and sale or box:GetParent()) end
        -- Standard confirmation dialogs are private, but have numbered owned globals.
        local index = 1
        while _G["AuctionatorDialog" .. index] do
            local f = _G["AuctionatorDialog" .. index]
            if H.Allowed(f) then H.Shell(f, refresh); H.Scan(f, refresh, Visit) end
            index = index + 1
        end
        S.RefreshSoftBorders()
    end
    refresh = function() H.Queue(module, Apply) end
    -- Post-hooks see complete controls without replacing constructors or callbacks.
    for _, entry in ipairs({
        {"AuctionatorTabContainerMixin", "OnLoad", "controls"},
        {"AuctionatorConfigFrameMixin", "OnLoad", "controls"},
        {"AuctionatorShoppingTabFrameMixin", "OnLoad", "content"},
        {"AuctionatorListExportFrameMixin", "OnLoad", "dialog"},
        {"AuctionatorListImportFrameMixin", "OnLoad", "dialog"},
        {"AuctionatorExportTextFrameMixin", "OnLoad", "dialog"},
    }) do
        H.Hook(_G[entry[1]], entry[2], function(f) Remember(f, entry[3]) end)
    end
    if A.Dialogs then
        for _, method in ipairs({"ShowEditBox", "ShowConfirm", "ShowConfirmAlt", "ShowMoney"}) do
            H.Hook(A.Dialogs, method, refresh)
        end
    end
    -- Auctionator's modern tabs can be built after the auction house opens.
    H.Hook(LibStub and LibStub("LibAHTab-1-0", true), "CreateTab", refresh)
    local function Discover() discoveryDirty = true; refresh() end
    H.Hook(A.Config, "InternalInitializeFrames", Discover)
    -- OnLoad already ran for frames created before this skin was enabled.
    local shopping = _G.AuctionatorShoppingFrame
    if shopping then
        for _, key in ipairs({"exportCSVDialog", "exportDialog", "importDialog", "itemDialog", "itemHistoryDialog"}) do
            if shopping[key] then roots[shopping[key]] = "dialog" end
        end
        if shopping.exportDialog and shopping.exportDialog.copyTextDialog then roots[shopping.exportDialog.copyTextDialog] = "dialog" end
    end
    events:SetScript("OnEvent", function(_, event)
        if event == "ADDON_LOADED" then discoveryDirty = true end
        if ns.IsEnabled(module) and (event ~= "PLAYER_REGEN_ENABLED" or waiting) then refresh() end
    end)
    module.refresh = refresh
    if S.OnLooksChanged then S.OnLooksChanged(refresh) end
    refresh()
end)

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("Auctionator", DefineSkin)
else DefineSkin() end
