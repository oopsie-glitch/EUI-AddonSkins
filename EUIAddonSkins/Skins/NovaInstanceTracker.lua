local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("NovaInstanceTracker", "NovaInstanceTracker", function()
    return type(_G.NIT) == "table"
end, function(S, module)
    local soft = ns.CreateSoftSkin(S, module)
    local H = ns.CreateSkinHelper(setmetatable({PageButton = soft.SoftPageButton}, {__index = S}), module)
    local unpack = unpack or table.unpack
    local layers, nodes, pooled, owners = {}, {}, {}, {}
    local pooledButtons, dropdownArrows, closeGlyphs, nativeChecks, pooledThumbs = {}, {}, {}, {}, {}
    local fills, skinArt, tracks, arrows, labels, edges = {}, {}, {}, {}, {}, {}
    local lifts, views = {}, {}
    local optionGroups, libraryHooks = {}, {}
    local generation, waiting, applying = 1, false, false
    local Walk, PaintWidget, Refresh, Pullout, Options, BindGroup
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("ADDON_LOADED")
    local function Ready()
        if not ns.IsEnabled(module) then return false end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return false end
        return true
    end
    local function OptionID(id)
        return type(id) == "string" and (id == "NovaInstanceTracker" or id:match("^NovaInstanceTracker "))
    end
    local function Excluded(f)
        local kind = f:GetObjectType()
        return kind == "PlayerModel" or kind == "ModelScene" or kind == "GameTooltip"
    end
    local function LibraryHook(object, key, callback, cleanup)
        if type(object) ~= "table" or type(object[key]) ~= "function" then return end
        local bound = libraryHooks[object]
        if not bound then bound = {}; libraryHooks[object] = bound end
        if bound[key] == object[key] then return end
        hooksecurefunc(object, key, function(...)
            if cleanup or ns.IsEnabled(module) then H.Safe(callback, ...) end
        end)
        bound[key] = object[key]
    end
    local function Font(text, heading)
        if not H.Allowed(text) or not text.GetFont then return end
        local face, size, flags = text:GetFont()
        if not face then return end -- Partially constructed controls have no font yet.
        local target, targetFlags = S.GetFont()
        local parent = text.GetParent and text:GetParent()
        if not owners[text] and not owners[parent] and (face ~= target or (flags or "") ~= (targetFlags or "")) then
            local r, g, b, a = text:GetTextColor()
            S.Font(text); text:SetTextColor(r, g, b, a)
        end
        if not owners[text] and not owners[parent] then
            -- Nova resets owned title/display fonts when reopening its logs.
            -- Repair that exact text synchronously, never rescan the window.
            H.Hook(text, "SetFont", function() if Ready() then Font(text) end end)
        end
        if owners[text] or owners[parent] then
            local r, g, b, a = text:GetTextColor()
            if r > 0.9 and g > 0.65 and b < 0.25 then text:SetTextColor(0.88, 0.88, 0.9, a) end
        end
    end
    local function Strip(f, keep)
        if not H.Allowed(f) then return end
        if f.SetBackdrop then f:SetBackdrop(nil) end
        for _, r in ipairs(H.Regions(f)) do
            if H.Texture(r) and not skinArt[r] and r ~= keep then r:SetAlpha(0) end
        end
    end
    local function Panel(f, keep)
        if not H.Allowed(f) then return end
        local fill = fills[f]
        if not fill then
            -- Same-frame BACKGROUND art cannot be lifted above native text by
            -- AceGUI's recursive frame-level repair when a page is reparented.
            fill = f:CreateTexture(nil, "BACKGROUND", nil, -7)
            fill:SetAllPoints(f); fills[f], skinArt[fill] = fill, true
        end
        if f.SetBackdrop then f:SetBackdrop(nil) end
        for _, r in ipairs(H.Regions(f)) do
            local layer = r.GetDrawLayer and r:GetDrawLayer()
            if H.Texture(r) and r ~= keep and not skinArt[r] and (layer == "BACKGROUND" or layer == "BORDER") then r:SetAlpha(0) end
        end
        local r, g, b = S.GetPanelColor()
        fill:SetColorTexture(r, g, b, 0.98); fill:SetAlpha(1)
    end
    local function Lift(f)
        if not H.Allowed(f) then return end
        local pair = lifts[f]
        if pair and pair.generation == generation then return end
        if not pair then
            pair = {}; lifts[f] = pair
            for i = 1, 2 do
                pair[i] = f:CreateTexture(nil, "BACKGROUND", nil, -6)
                skinArt[pair[i]] = true
            end
            pair[1]:SetPoint("TOPLEFT", f, "TOPLEFT")
            pair[1]:SetPoint("BOTTOMRIGHT", f, "BOTTOM")
            pair[2]:SetPoint("TOPLEFT", f, "TOP")
            pair[2]:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT")
        end
        local r, g, b = S.GetPanelColor()
        r, g, b = math.min(1, r + 0.10), math.min(1, g + 0.10), math.min(1, b + 0.10)
        for i, texture in ipairs(pair) do
            local first, last = i == 1 and 0 or 0.18, i == 1 and 0.18 or 0
            texture:SetColorTexture(1, 1, 1, 1)
            if texture.SetGradient and CreateColor then
                texture:SetGradient("HORIZONTAL", CreateColor(r, g, b, first), CreateColor(r, g, b, last))
            elseif texture.SetGradientAlpha then
                texture:SetGradientAlpha("HORIZONTAL", r, g, b, first, r, g, b, last)
            else texture:SetColorTexture(r, g, b, 0.08) end
        end
        pair.generation = generation
    end
    local function Label(f, text)
        if not H.Allowed(text) then return end
        local state = labels[f]
        if not state then
            state = {}; labels[f] = state
            local painting = false
            state.paint = function()
                local record = owners[f]
                if painting or not record or not record.active or not Ready() then return end
                painting = true
                Font(state.text)
                local disabled = f.IsEnabled and not f:IsEnabled()
                if record.widget.frame == f and record.widget.disabled then disabled = true end
                local shade = disabled and 0.5 or 0.92
                state.text:SetTextColor(shade, shade, disabled and 0.52 or 0.94, 1)
                painting = false
            end
            for _, method in ipairs({"Enable", "Disable", "SetEnabled"}) do H.Hook(f, method, state.paint) end
            for _, event in ipairs({"OnEnable", "OnDisable", "OnEnter", "OnLeave", "OnMouseDown", "OnMouseUp"}) do
                H.Script(f, event, state.paint)
            end
        end
        state.text = text
        -- Native colour writes can follow Enable/hover. Repair
        -- only this active action label, never a page or unrelated pooled widget.
        H.Hook(text, "SetTextColor", state.paint)
        state.paint()
    end
    local function PoolButton(f)
        if not H.Allowed(f) then return end
        Panel(f)
        if not edges[f] then
            edges[f] = {}
            for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
                local edge = f:CreateTexture(nil, "BORDER")
                edge:SetColorTexture(0.25, 0.25, 0.26, 0.7)
                if side == "TOP" or side == "BOTTOM" then
                    edge:SetPoint(side .. "LEFT"); edge:SetPoint(side .. "RIGHT"); edge:SetHeight(1)
                else edge:SetPoint("TOP" .. side); edge:SetPoint("BOTTOM" .. side); edge:SetWidth(1) end
                edges[f][#edges[f] + 1], skinArt[edge] = edge, true
            end
        end
        local hover = pooledButtons[f]
        if not hover then
            hover = f:CreateTexture(nil, "HIGHLIGHT")
            hover:SetAllPoints(f); hover:SetColorTexture(1, 1, 1, 0.08)
            pooledButtons[f], skinArt[hover] = hover, true
        end
        Strip(f)
        Label(f, f.GetFontString and f:GetFontString())
    end
    local function PooledClose(f)
        if not H.Allowed(f) then return end
        -- AceGUI Frame uses a full labelled Close action at the bottom;
        -- only genuine icon close buttons should receive an X glyph.
        if f.GetFontString and H.Allowed(f:GetFontString()) then PoolButton(f); return end
        if not closeGlyphs[f] then
            local layer = CreateFrame("Frame", nil, f)
            closeGlyphs[f], layers[layer] = layer, true
            layer:SetAllPoints(f); layer:EnableMouse(false)
            S.CloseButton(layer)
        end
        for _, r in ipairs(H.Regions(f)) do if H.Texture(r) then r:SetAlpha(0) end end
    end
    local function Arrow(button, direction)
        if not H.Allowed(button) then return end
        Strip(button)
        local glyph = arrows[button]
        if not glyph then
            glyph = button:CreateTexture(nil, "OVERLAY")
            glyph:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png")
            glyph:SetPoint("CENTER", button, "CENTER"); glyph:SetSize(12, 12)
            if direction == "^" and glyph.SetRotation then glyph:SetRotation(math.pi) end
            arrows[button], skinArt[glyph] = glyph, true
        end
        glyph:SetVertexColor(0.85, 0.85, 0.85, 1)
    end
    local function Scroll(f, temporary)
        if f.GetThumbTexture and f:GetThumbTexture() then
            local thumb = f:GetThumbTexture()
            if temporary then
                Strip(f); thumb:SetAlpha(0)
                local horizontal = f.GetOrientation and f:GetOrientation() == "HORIZONTAL"
                local track = tracks[f]
                if not track then
                    track = f:CreateTexture(nil, "BACKGROUND"); tracks[f], skinArt[track] = track, true
                    if horizontal then track:SetPoint("LEFT", f, "LEFT"); track:SetPoint("RIGHT", f, "RIGHT"); track:SetHeight(2)
                    else track:SetPoint("TOP", f, "TOP"); track:SetPoint("BOTTOM", f, "BOTTOM"); track:SetWidth(2) end
                end
                track:SetColorTexture(0.20, 0.20, 0.21, 1)
                local grip = pooledThumbs[thumb]
                if not grip then
                    grip = f:CreateTexture(nil, "ARTWORK"); pooledThumbs[thumb], skinArt[grip] = grip, true
                    grip:SetPoint("CENTER", thumb, "CENTER")
                    if horizontal then grip:SetSize(8, 14)
                    else grip:SetPoint("TOP", thumb, "TOP"); grip:SetPoint("BOTTOM", thumb, "BOTTOM"); grip:SetWidth(5) end
                end
                local r, g, b = S.GetAccentColor(); grip:SetColorTexture(r, g, b, 0.85)
                local name = f.GetName and f:GetName()
                Arrow(f.ScrollUpButton or name and _G[name .. "ScrollUpButton"], "^")
                Arrow(f.ScrollDownButton or name and _G[name .. "ScrollDownButton"], "v")
            else
                H.LegacySlider(f)
                if f.GetOrientation and f:GetOrientation() == "HORIZONTAL" then thumb:SetSize(8, 14)
                else thumb:SetWidth(5) end
            end
        elseif temporary then
            local thumb = f.Track and f.Track.Thumb or f.GetThumb and f:GetThumb()
            if H.Allowed(thumb) then
                Strip(thumb)
                local fill = pooledThumbs[thumb]
                if not fill then
                    fill = thumb:CreateTexture(nil, "ARTWORK"); pooledThumbs[thumb], skinArt[fill] = fill, true
                    fill:SetPoint("TOP", thumb, "TOP"); fill:SetPoint("BOTTOM", thumb, "BOTTOM"); fill:SetWidth(5)
                end
                local r, g, b = S.GetAccentColor(); fill:SetColorTexture(r, g, b, 0.8)
            end
            Arrow(f.Back, "^"); Arrow(f.Forward, "v")
        else
            S.ScrollBar(f, true)
            if H.Allowed(f.Back) then soft.SoftPageButton(f.Back, "^") end
            if H.Allowed(f.Forward) then soft.SoftPageButton(f.Forward, "v") end
        end
    end
    local function Check(f)
        local art = nativeChecks[f]
        if not art then
            local before = {}
            for _, r in ipairs(H.Regions(f)) do before[r] = true end
            for _, child in ipairs(H.Children(f)) do before[child] = true end
            soft.Checkbox(f, {borderInset = 4, hover = 0.06})
            art = {}; nativeChecks[f] = art
            for _, r in ipairs(H.Regions(f)) do if not before[r] then art[#art + 1] = r end end
            for _, child in ipairs(H.Children(f)) do if not before[child] then art[#art + 1] = child end end
        end
        for _, part in ipairs(art) do
            part:ClearAllPoints(); part:SetPoint("CENTER", f, "CENTER"); part:SetSize(14, 14)
        end
        for i, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
            local mark = f[getter] and H.Texture(f[getter](f))
            if mark then
                mark:SetVertexColor(1, 1, 1, 1)
                if i == 1 then local r, g, b = S.GetAccentColor(); mark:SetColorTexture(r, g, b, 1)
                else mark:SetColorTexture(0.4, 0.4, 0.4, 0.8) end
                mark:ClearAllPoints(); mark:SetPoint("CENTER", f, "CENTER"); mark:SetSize(10, 10)
            end
        end
    end
    local function Control(f)
        local kind, widget = f:GetObjectType(), f.obj
        if f.treeline and f.toggle then return end -- sidebar rows keep their native selection/hit area
        local name = f.GetName and f:GetName() or ""
        if not owners[f] and kind == "Button" and (name:find("Close",1,true) or f.nitRemove) then
            S.CloseButton(f)
        elseif kind == "CheckButton" then Check(f)
        elseif kind == "Slider" then Scroll(f, owners[f])
        elseif kind == "EditBox" then
            Font(f)
            if not (f.IsMultiLine and f:IsMultiLine()) then
                if owners[f] then Strip(f); Panel(f) else soft.EditBox(f, {padInput = false}) end
            end
        elseif kind == "DropdownButton" then soft.Dropdown(f)
        elseif kind == "Button" then
            local label = f.GetFontString and f:GetFontString()
            -- Texture-only icon controls retain recognisable artwork.
            if H.Allowed(label) then
                if owners[f] then PoolButton(f)
                else
                    soft.Button(f)
                    if S.StateButtonLabel then S.StateButtonLabel(f) end
                end
            end
        end
        if kind == "StatusBar" then return end -- Native timeout value, alpha and colour.
        if H.Allowed(f.NineSlice) then
            if owners[f] then
                for _, r in ipairs(H.Regions(f.NineSlice)) do if H.Texture(r) then r:SetAlpha(0) end end
            else S.FadeNineSlice(f.NineSlice) end
        end
        if not owners[f] then
            for _, key in ipairs({"close", "closeButton", "removeButton"}) do
                local close = f[key]
                if H.Allowed(close) then S.CloseButton(close); close.nitRemove = true end
            end
        end
        if H.Allowed(f.CloseButton) then
            if owners[f] then PooledClose(f.CloseButton) else S.CloseButton(f.CloseButton) end
        end
        for _, key in ipairs({"ScrollBar", "scrollbar", "scrollBar"}) do if H.Allowed(f[key]) then Scroll(f[key], owners[f]) end end
        if not owners[f] and type(f.initialize) == "function" and ns.BindPopupOwner then
            ns.BindPopupOwner(S, module, f); soft.Dropdown(f)
        end
        -- Ace widgets are handled after their complete page is built, never by a
        -- global AceGUI Create/AddChild callback.
        if widget and widget.frame == f then
            PooledClose(widget.closebutton); PooledClose(widget.closebtn)
        end
    end
    Walk = function(f, force, owner, depth)
        if not H.Allowed(f) or layers[f] == true or Excluded(f) or (depth or 0) > 24 then return end
        local kind = f:GetObjectType()
        if kind == "GameTooltip" or kind == "Texture" or kind == "FontString" then return end
        local state = nodes[f]
        local nc = f.GetNumChildren and f:GetNumChildren()
        local nr = f.GetNumRegions and f:GetNumRegions()
        if not force and state and state.generation == generation and nc ~= nil and nr ~= nil
            and state.children == nc and state.regions == nr then return end
        if not state then
            state = {}; nodes[f] = state
            H.Script(f, "OnShow", function() if (not owner or owner.active) and Ready() then Walk(f, false, owner) end end)
        end
        if owner then owner.nodes[f] = true; owners[f] = owner end
        if not owner and H.Allowed(f.borderFrame) and f.borderFrame.SetBackdrop then f.borderFrame:SetBackdrop(nil) end
        Control(f)
        if not owner and H.Allowed(f.tooltip) then
            Panel(f.tooltip); Walk(f.tooltip, false, nil, (depth or 0) + 1)
        end
        for _, text in ipairs(H.Regions(f)) do Font(text) end
        local children = H.Children(f)
        for _, child in ipairs(children) do
            if not owner or not child.obj or child.obj == owner.widget then
                Walk(child, force, owner, (depth or 0) + 1)
            end
        end
        state.children = f.GetNumChildren and f:GetNumChildren()
        state.regions = f.GetNumRegions and f:GetNumRegions()
        state.generation = generation
    end
    -- Pooled Ace widgets are shared with other addons. Snapshot only native
    -- cosmetics and restore them, then hide our added art, on each release.
    local function RegionState(r)
        local d = {alpha = r:GetAlpha()}
        if r.GetTextColor then d.color = {r:GetTextColor()} end
        if H.Texture(r) then
            d.texture = r:GetTexture()
            if r.GetAtlas then d.atlas = r:GetAtlas() end
            if r.GetVertexColor then d.vertex = {r:GetVertexColor()} end
            if r.GetTexCoord then d.coords = {r:GetTexCoord()} end
            d.width, d.height = r:GetWidth(), r:GetHeight()
        end
        if r.GetNumPoints then
            d.points = {}; for i = 1, r:GetNumPoints() do d.points[i] = {r:GetPoint(i)} end
        end
        return d
    end
    local function RestoreRegion(r, d)
        r:SetAlpha(d.alpha)
        if d.color then r:SetTextColor(unpack(d.color)) end
        if H.Texture(r) then
            if d.atlas and r.SetAtlas then r:SetAtlas(d.atlas) else r:SetTexture(d.texture) end
            if d.vertex then r:SetVertexColor(unpack(d.vertex)) end
            if d.coords then r:SetTexCoord(unpack(d.coords)) end
            r:SetSize(d.width, d.height)
        end
        if d.points then r:ClearAllPoints(); for _, point in ipairs(d.points) do r:SetPoint(unpack(point)) end end
    end
    local function Snapshot(f, record, depth)
        if not H.Allowed(f) or layers[f] == true or (depth or 0) > 24 then return end
        if f:GetObjectType() == "GameTooltip" then return end
        local d = record.saved[f]
        local fresh = not d
        if fresh then d = {regions = {}, children = {}}; record.saved[f] = d end
        if fresh and f.GetBackdrop then
            d.backdrop = f:GetBackdrop()
            if f.GetBackdropColor then d.bg = {f:GetBackdropColor()} end
            if f.GetBackdropBorderColor then d.edge = {f:GetBackdropBorderColor()} end
        end
        if fresh and f.GetTextColor then d.color = {f:GetTextColor()} end
        for _, r in ipairs(H.Regions(f)) do
            if not d.regions[r] and not (record.art and record.art[r]) then d.regions[r] = RegionState(r) end
        end
        for _, child in ipairs(H.Children(f)) do
            d.children[child] = true
            if not (record.art and record.art[child]) and (not child.obj or child.obj == record.widget) then
                Snapshot(child, record, (depth or 0) + 1)
            end
        end
    end
    local function Restore(record)
        if not record.active then return end
        record.active = false
        record.checkGeneration = nil
        for item in pairs(record.menuItems or {}) do
            if pooled[item] then Restore(pooled[item]) end
        end
        record.menuItems = nil
        for f, d in pairs(record.saved) do
            nodes[f], owners[f] = nil, nil
            if f.SetBackdrop then
                f:SetBackdrop(d.backdrop)
                if d.bg then f:SetBackdropColor(unpack(d.bg)) end
                if d.edge then f:SetBackdropBorderColor(unpack(d.edge)) end
            end
            if d.color then f:SetTextColor(unpack(d.color)) end
            for r, saved in pairs(d.regions) do RestoreRegion(r, saved) end
        end
        for text, saved in pairs(record.menuFonts or {}) do RestoreRegion(text, saved) end
        for art in pairs(record.art or {}) do art:SetAlpha(0) end
        record.saved, record.menuFonts = {}, nil
    end
    local function CheckLabel(widget, record)
        if not record.active or not Ready() or not H.Allowed(widget.text) then return end
        local anchor = H.Texture(widget.image) and widget.image:GetTexture() and widget.image or widget.checkbg
        widget.text:SetPoint("LEFT", anchor, "RIGHT", 6, 0)
    end
    local function PaintCheck(widget, record)
        if not record.active or not Ready() or not widget.checkbg or not widget.check then return end
        if record.checkGeneration == generation and record.checkDisabled == not not widget.disabled then return end
        widget.checkbg:SetColorTexture(0.17, 0.17, 0.18, 1)
        widget.checkbg:SetVertexColor(1, 1, 1, 1); widget.checkbg:SetSize(14, 14)
        widget.checkbg:ClearAllPoints(); widget.checkbg:SetPoint("TOPLEFT", widget.frame, "TOPLEFT", 5, -5)
        CheckLabel(widget, record)
        widget.checkbg:SetTexCoord(0, 1, 0, 1)
        if widget.highlight then widget.highlight:SetColorTexture(1, 1, 1, 0.08) end
        local r, g, b = S.GetAccentColor()
        widget.check:SetVertexColor(1, 1, 1, 1)
        widget.check:SetColorTexture(widget.disabled and 0.45 or r, widget.disabled and 0.45 or g, widget.disabled and 0.45 or b, 1)
        widget.check:SetTexCoord(0, 1, 0, 1)
        widget.check:ClearAllPoints(); widget.check:SetPoint("CENTER", widget.checkbg, "CENTER"); widget.check:SetSize(8, 8)
        record.checkGeneration, record.checkDisabled = generation, not not widget.disabled
    end
    PaintWidget = function(widget, force)
        if type(widget) ~= "table" or not H.Allowed(widget.frame) then return end
        local f = widget.frame
        local record = pooled[widget]
        if not record then
            record = {widget = widget, nodes = {}, saved = {}}; pooled[widget] = record
            -- Cleanup is intentionally ungated: disabling a skin cannot leak its
            -- appearance into an unrelated addon's next pool acquisition.
            if type(widget.OnRelease) == "function" then hooksecurefunc(widget, "OnRelease", function() Restore(record) end) end
        end
        if record.active and record.generation == generation and not force then
            for _, child in ipairs(widget.children or {}) do PaintWidget(child) end
            return
        end
        if not record.active then
            record.active, record.saved = true, {}
            for art, alpha in pairs(record.art or {}) do art:SetAlpha(alpha) end
        end
        record.generation = generation
        -- Snapshot newly introduced native subframes before this pass; a
        -- layout rebuild can add children without releasing the outer group.
        Snapshot(f, record)
        local before = {}
        for node in pairs(record.saved) do
            for _, r in ipairs(H.Regions(node)) do before[r] = true end
            for _, child in ipairs(H.Children(node)) do before[child] = true end
        end
        for node in pairs(record.saved) do owners[node] = record end
        if widget.type == "Window" or widget.type == "Frame" or widget.type == "Dropdown-Pullout" then Strip(f); Panel(f); if widget.type == "Frame" then Lift(f) end end
        if widget.type == "InlineGroup" and H.Allowed(widget.content) then
            local border = widget.content:GetParent()
            if H.Allowed(border) and border ~= f then Strip(border); Panel(border) end
            Font(widget.titletext, true)
        end
        if widget.type == "Heading" then Strip(f); Font(widget.label, true) end
        if type(widget.type) == "string" and widget.type:match("^Dropdown%-Item%-") then
            Font(widget.text)
            if H.Texture(widget.check) then
                widget.check:SetColorTexture(S.GetAccentColor())
                widget.check:ClearAllPoints(); widget.check:SetPoint("LEFT", f, "LEFT", 6, -1)
                widget.check:SetSize(8, 8)
            end
            if H.Texture(widget.highlight) then widget.highlight:SetColorTexture(1, 1, 1, 0.1) end
        end
        if widget.type == "BlizOptionsGroup" then Font(widget.label, true) end
        if widget.type == "CheckBox" and widget.checkbg and widget.check then
            PaintCheck(widget, record)
            for _, method in ipairs({"SetValue", "SetDisabled"}) do
                H.Hook(widget, method, function() PaintCheck(widget, record) end)
            end
            H.Hook(widget, "SetType", function() record.checkGeneration = nil; PaintCheck(widget, record) end)
            for _, method in ipairs({"SetLabel", "SetImage"}) do
                H.Hook(widget, method, function() CheckLabel(widget, record) end)
            end
            for _, event in ipairs({"OnMouseDown", "OnMouseUp"}) do
                H.Script(f, event, function() CheckLabel(widget, record) end)
            end
        elseif widget.type == "Dropdown" and H.Allowed(widget.dropdown) then
            -- The cover is a clickable sibling above the native text frame.
            -- Put the fill on the text's frame, but size it to the cover, so it
            -- cannot obscure labels or inherit the template's -15/+17 margins.
            local host = widget.dropdown
            local bounds = H.Allowed(widget.button_cover) and widget.button_cover or host
            Strip(host); PoolButton(host)
            fills[host]:ClearAllPoints(); fills[host]:SetAllPoints(bounds)
            pooledButtons[host]:ClearAllPoints(); pooledButtons[host]:SetAllPoints(bounds)
            for i, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
                local edge = edges[host][i]
                edge:ClearAllPoints()
                if side == "TOP" or side == "BOTTOM" then
                    edge:SetPoint(side .. "LEFT", bounds, side .. "LEFT")
                    edge:SetPoint(side .. "RIGHT", bounds, side .. "RIGHT")
                else
                    edge:SetPoint("TOP" .. side, bounds, "TOP" .. side)
                    edge:SetPoint("BOTTOM" .. side, bounds, "BOTTOM" .. side)
                end
            end
            if not dropdownArrows[host] then
                local arrow = host:CreateTexture(nil, "OVERLAY")
                arrow:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png")
                arrow:SetSize(12, 12)
                if H.Allowed(widget.button) then arrow:SetPoint("CENTER", widget.button, "CENTER")
                else arrow:SetPoint("RIGHT", bounds, "RIGHT", -5, 0) end
                dropdownArrows[host], skinArt[arrow] = arrow, true
            end
            dropdownArrows[host]:SetAlpha(0.8)
            Pullout(widget)
            if H.Allowed(widget.button) then
                for _, r in ipairs(H.Regions(widget.button)) do if H.Texture(r) then r:SetAlpha(0) end end
            end
        elseif widget.type == "TabGroup" then
            for _, tab in pairs(widget.tabs or {}) do
                if H.Allowed(tab) then
                    PoolButton(tab)
                    local text = tab.text or tab.Text or tab.GetFontString and tab:GetFontString()
                    if H.Allowed(text) then
                        Font(text)
                        if tab.selected then text:SetTextColor(S.GetAccentColor()) else text:SetTextColor(0.9, 0.9, 0.9, 1) end
                    end
                end
            end
        end
        for _, key in ipairs({"border", "treeframe"}) do if H.Allowed(widget[key]) then Panel(widget[key]) end end
        if widget.type == "TreeGroup" then
            H.Hook(widget, "RefreshTree", function()
                if record.active and Ready() then PaintWidget(widget, true) end
            end)
            for _, row in ipairs(widget.buttons or {}) do
                Font(row.text)
                if H.Allowed(row.text) then row.text:SetTextColor(row.treeline and row.treeline.disabled and 0.5 or 0.9, row.treeline and row.treeline.disabled and 0.5 or 0.9, row.treeline and row.treeline.disabled and 0.52 or 0.92, 1) end
                local highlight = row.GetHighlightTexture and H.Texture(row:GetHighlightTexture())
                if highlight then
                    if row.selected then local r, g, b = S.GetAccentColor(); highlight:SetColorTexture(r, g, b, 0.16)
                    else highlight:SetColorTexture(1, 1, 1, 0.1) end
                end
                if H.Texture(row.toggle and row.toggle:GetNormalTexture()) then
                    local tex = row.toggle:GetNormalTexture()
                    local expanded = tex:GetTexture() == 130821
                    Strip(row.toggle)
                    local mark = arrows[row.toggle]
                    if not mark then
                        mark = row.toggle:CreateTexture(nil, "OVERLAY")
                        mark:SetSize(10, 10); mark:SetPoint("CENTER", row.toggle, "CENTER")
                        arrows[row.toggle], skinArt[mark] = mark, true
                    end
                    mark:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png")
                    if mark.SetRotation then mark:SetRotation(expanded and 0 or -math.pi / 2) end
                    mark:SetVertexColor(0.85, 0.85, 0.87, 1)
                end
            end
        end
        for _, item in ipairs(widget.items or {}) do
            if item.frame then
                record.menuItems = record.menuItems or {}
                record.menuItems[item] = true
                PaintWidget(item)
            elseif H.Allowed(item.text) then
                -- Widget-backed items snapshot/restore their own fonts. Taking
                -- another snapshot after painting would save the skinned font.
                record.menuFonts = record.menuFonts or {}
                if not record.menuFonts[item.text] then record.menuFonts[item.text] = RegionState(item.text) end
                Font(item.text)
            end
        end
        Walk(f, true, record)
        if widget.type ~= "Heading" and widget.type ~= "BlizOptionsGroup" and H.Allowed(widget.label or f.label) then
            local label = widget.label or f.label
            Font(label); label:SetTextColor(0.86, 0.86, 0.88, 1)
        end
        if widget.type == "Button" then
            Label(f, widget.text or f.GetFontString and f:GetFontString())
            H.Hook(widget, "SetDisabled", function() if labels[f] then labels[f].paint() end end)
        end
        if ns.StyleTextureDialog then
            H.Hook(widget, "Fire", function(_, event)
                if event ~= "OnClick" and event ~= "OnValueChanged" and event ~= "OnEnterPressed" then return end
                local dialog = LibStub and LibStub("AceConfigDialog-3.0", true)
                local popup = dialog and dialog.popup
                if popup and popup:IsShown() then ns.StyleTextureDialog(S, module, popup, record.active) end
            end)
        end
        if widget.slider then Scroll(widget.slider, true) end
        record.art = record.art or {}
        for node in pairs(record.saved) do
            for _, r in ipairs(H.Regions(node)) do if not before[r] then record.art[r] = r:GetAlpha() end end
            for _, child in ipairs(H.Children(node)) do if not before[child] then record.art[child] = child:GetAlpha() end end
        end
        for _, child in ipairs(widget.children or {}) do PaintWidget(child) end
    end
    Pullout = function(widget)
        local popup = widget.pullout
        if type(popup) ~= "table" or not H.Allowed(popup.frame) then return end
        pooled[popup] = pooled[popup] or {widget = popup, nodes = {}, saved = {}}
        local record = pooled[popup]
        if not record.hideHook then
            record.hideHook = true
            popup.frame:HookScript("OnHide", function() Restore(record) end)
        end
        if not record.openHook and type(popup.Open) == "function" then
            record.openHook = true
            hooksecurefunc(popup, "Open", function()
                H.Safe(function()
                    local owner = popup.userdata and popup.userdata.obj
                    if ns.IsEnabled(module) and owner and pooled[owner] and pooled[owner].active and Ready() then PaintWidget(popup)
                    else Restore(record) end
                end)
            end)
        end
        if popup.frame:IsShown() and popup.userdata and popup.userdata.obj == widget and pooled[widget].active and Ready() then
            PaintWidget(popup)
        end
    end
    BindGroup = function(widget)
        if type(widget) ~= "table" or widget.type ~= "BlizOptionsGroup" or not H.Allowed(widget.frame) then return end
        if optionGroups[widget] then return end
        local state = {fed = false}; optionGroups[widget] = state
        -- Native OnShow fires AceConfig synchronously. Our script runs after
        -- construction, even if a later Ace library replaces FeedGroup/Open.
        H.Script(widget.frame, "OnShow", function()
            if not Ready() then return end
            Options(true)
            if not state.fed then PaintWidget(widget) end
            state.fed = false
        end)
        H.Script(widget.frame, "OnHide", function() state.fed = false end)
    end
    local function WatchRelease(gui)
        LibraryHook(gui, "Release", function(_, widget)
            if pooled[widget] then Restore(pooled[widget]) end
        end, true)
    end
    Options = function(bindOnly)
        local gui = LibStub and LibStub("AceGUI-3.0", true)
        WatchRelease(gui)
        local dialog = LibStub and LibStub("AceConfigDialog-3.0", true)
        if not dialog then return end
        LibraryHook(dialog, "FeedGroup", function(_, id, _, container)
            if OptionID(id) and Ready() then
                BindGroup(container)
                PaintWidget(container)
                if optionGroups[container] then optionGroups[container].fed = true end
            end
        end)
        LibraryHook(dialog, "AddToBlizOptions", function(_, id)
            if OptionID(id) then Options(true) end
        end)
        for id, open in pairs(dialog.OpenFrames or {}) do
            if not bindOnly and OptionID(id) then PaintWidget(open) end
        end
        for id, entries in pairs(dialog.BlizOptions or {}) do
            if OptionID(id) then
                for _, widget in pairs(entries) do
                    BindGroup(widget)
                    if not bindOnly and widget.frame and widget.frame:IsShown() then PaintWidget(widget) end
                end
            end
        end
    end
    local app = _G.NIT
    local roots = {}
    local rootNames = {
        "NITInstanceFrame", "NITAltsFrame", "NITTradeLogFrame", "NITTradeCopyFrame",
        "NITInstanceFrameDC", "NITCharsFrameDC", "NITCopyFrame", "NITLevelLogFrame",
        "NRCLockoutsFrame", "NITLootReminderListFrame", "NITRemantsFrame", "NITPostInstanceStatsFrame",
    }
    local Root
    Root = function(f, force)
        if not Ready() or not H.Allowed(f) then return end
        roots[f] = true
        local state = views[f]
        if not state then
            state = {}; views[f] = state
            H.Script(f, "OnShow", function() Root(f) end)
        end
        if state.generation ~= generation then
            Panel(f); Lift(f)
            if H.Allowed(f.NineSlice) then S.FadeNineSlice(f.NineSlice) end
            if H.Allowed(f.topFrame) then Panel(f.topFrame) end
            state.generation = generation
        end
        Walk(f, force)
        -- A Level Log creates its rows through private methods on this frame.
        H.Hook(f, "createSimpleLineFrame", function(count)
            if Ready() then Walk(f.simpleLineFrames and f.simpleLineFrames[count], false) end
        end)
    end
    local function MainWindows()
        if not Ready() then return end
        for _, name in ipairs(rootNames) do Root(_G[name]) end
        local copyHeader = _G.NITCopyFrameTopBar
        if H.Allowed(copyHeader) then
            local state = views[copyHeader]
            if not state or state.generation ~= generation then
                Panel(copyHeader)
                if H.Allowed(copyHeader.NineSlice) then S.FadeNineSlice(copyHeader.NineSlice) end
                views[copyHeader] = {generation = generation}
            end
        end
        -- Reminder text intentionally has no opaque shell or background.
        local reminder = _G.NITLootReminderFrame
        if H.Allowed(reminder) then Walk(reminder, false) end
        for _, key in ipairs({"instanceFrameSelectAltMenu"}) do
            local owner = app[key]
            if H.Allowed(owner) and ns.BindPopupOwner then ns.BindPopupOwner(S, module, owner) end
        end
    end
    local function BindNative()
        for _, key in ipairs({"openInstanceLogFrame", "openAltsFrame", "openTradeLogFrame", "openTradeCopyFrame",
            "openDeleteConfirmFrame", "openDeleteCharConfirmFrame", "openNITCopyFrame", "openLockoutsFrame",
            "createLevelLogFrame", "loadLevelLogFrame", "loadLootReminderListFrame", "loadRemnantsFrame",
            "createInstanceFrameShowsAltsButton", "createInstanceFramePvpButton", "createInstanceFramePveButton",
            "createInstanceFrameSelectAltMenu", "createAltsFrameCheckbox", "createAltsFrameSlider",
            "createAltsFrameLootReminderButton", "createTradeCopyFormatButtons", "loadLootReminderFrame"}) do
            H.Hook(app, key, MainWindows)
        end
        for _, entry in ipairs({{"createInstanceLineFrame", "NITInstanceLine"}, {"createAltsLineFrame", "NITAltsLine"}}) do
            local suffix = entry[2]
            H.Hook(app, entry[1], function(_, id)
                if Ready() and (type(id) == "string" or type(id) == "number") then Walk(_G[tostring(id) .. suffix], false) end
            end)
        end
        for _, key in ipairs({"createSimpleTextFrame", "createSimpleScrollFrame"}) do
            H.Hook(app, key, function(_, name)
                if type(name) == "string" then Root(_G[name]) end
            end)
        end
    end
    local function Discover()
        BindNative(); MainWindows(); Options()
        for f in pairs(roots) do Root(f) end
        soft.RefreshSoftBorders()
    end
    Refresh = function()
        if applying or not Ready() then return end
        applying = true; H.Safe(Discover); applying = false
    end
    module.refresh = function() generation = generation + 1; Refresh() end
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
    events:SetScript("OnEvent", function(_, event, name)
        if event == "ADDON_LOADED" then
            local gui = LibStub and LibStub("AceGUI-3.0", true)
            local gh = gui and libraryHooks[gui]
            if gui and (not gh or gh.Release ~= gui.Release) then WatchRelease(gui) end
            if not ns.IsEnabled(module) then return end
            local dialog = LibStub and LibStub("AceConfigDialog-3.0", true)
            local dh = dialog and libraryHooks[dialog]
            if dialog and (not dh or dh.FeedGroup ~= dialog.FeedGroup) then
                if Ready() then Options(true) end
            end
            if name == "NovaInstanceTracker" then H.Queue(module, Refresh) end
        elseif waiting then
            waiting = false; generation = generation + 1; Refresh()
        end
    end)
    Refresh()
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("NovaInstanceTracker", DefineSkin)
else DefineSkin() end
