local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("RareScanner", "RareScanner", function()
    return _G.RARESCANNER_BUTTON ~= nil or _G.RSExplorerFrame ~= nil
end, function(S, module)
    local soft = ns.CreateSoftSkin(S, module)
    local H = ns.CreateSkinHelper(setmetatable({PageButton = soft.SoftPageButton}, {__index = S}), module)
    local unpack = unpack or table.unpack
    local icons, layers, nodes, pooled, owners = {}, {}, {}, {}, {}
    local pooledButtons, dropdownArrows, closeGlyphs, nativeChecks, pooledThumbs = {}, {}, {}, {}, {}
    local fills, skinArt, tracks, arrows, labels = {}, {}, {}, {}, {}
    local lifts, views = {}, {}
    local optionGroups, libraryHooks, mediaRecords = {}, {}, {}
    local generation, waiting, applying = 1, false, false
    local Walk, PaintWidget, Refresh, Pullout, Options, BindGroup, MediaPopup
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("ADDON_LOADED")
    local function Ready()
        if not ns.IsEnabled(module) then return false end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return false end
        return true
    end
    local function OptionID(id)
        return type(id) == "string" and (id == "RareScanner" or id:match("^RareScanner "))
    end
    local function Excluded(f)
        local root = _G.RSExplorerFrame
        local kind = f:GetObjectType()
        return kind == "PlayerModel" or kind == "ModelScene" or kind == "GameTooltip"
            or root and root.RareInfo and f == root.RareInfo.Map
            or type(f.GetView) == "function" -- virtualized rows use initialization callbacks
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
        if face ~= target or (flags or "") ~= (targetFlags or "") then
            local r, g, b, a = text:GetTextColor()
            S.Font(text); text:SetTextColor(r, g, b, a)
        end
        if heading then text:SetTextColor(S.GetAccentColor()) end
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
        -- SetFontObject and native colour writes can follow Enable/hover. Repair
        -- only this active action label, never a page or unrelated pooled widget.
        H.Hook(text, "SetTextColor", state.paint)
        H.Hook(text, "SetFontObject", state.paint)
        state.paint()
    end
    local function PoolButton(f)
        Panel(f)
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
        if not closeGlyphs[f] then
            local layer = CreateFrame("Frame", nil, f)
            closeGlyphs[f], layers[layer] = layer, true
            layer:SetAllPoints(f); layer:EnableMouse(false)
            S.CloseButton(layer)
        end
        for _, r in ipairs(H.Regions(f)) do if H.Texture(r) then r:SetAlpha(0) end end
    end
    local function Icon(f)
        if not H.Allowed(f) then return end
        icons[f] = true
        local texture = f.GetNormalTexture and H.Texture(f:GetNormalTexture())
        if texture then S.SquareIcon(texture) end
        -- Native SetBorderColor also conveys selection/awarded/corruption state.
        -- Retain its colour, desaturation, texture and visibility logic.
        if f.GetBackdrop and f:GetBackdrop() then H.ThinBackdrop(f) end
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
                track:SetColorTexture(0.23, 0.23, 0.18, 1)
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
        if not owners[f] and (f.BaseFrameBackground or f.Background1) then
            Panel(f, f.Texture)
            if H.Texture(f.Header) then H.Fade(f.Header) end
            if H.Allowed(f.Border) and f.Border:GetObjectType() == "Frame" then Strip(f.Border) end
        end
        if icons[f] or type(f.SetBorderColor) == "function" then Icon(f); return end
        if kind == "CheckButton" then Check(f)
        elseif kind == "Slider" then Scroll(f, owners[f])
        elseif kind == "EditBox" then
            Font(f)
            if not (f.IsMultiLine and f:IsMultiLine()) then
                if owners[f] then Strip(f); Panel(f) else soft.EditBox(f, {padInput = false}) end
            end
        elseif kind == "DropdownButton" then soft.Dropdown(f)
        elseif kind == "Button" then
            local label = f.GetFontString and f:GetFontString()
            -- Texture-only dice/pass/note/class controls retain recognisable artwork.
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
        Control(f)
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
        if r.GetFont and r:GetFont() then d.font = {r:GetFont()}; d.color = {r:GetTextColor()} end
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
        if d.font then r:SetFont(unpack(d.font)); r:SetTextColor(unpack(d.color)) end
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
        if fresh and f.GetFont and f:GetFont() then d.font = {f:GetFont()}; d.color = {f:GetTextColor()} end
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
        for f, d in pairs(record.saved) do
            nodes[f], owners[f] = nil, nil
            if f.SetBackdrop then
                f:SetBackdrop(d.backdrop)
                if d.bg then f:SetBackdropColor(unpack(d.bg)) end
                if d.edge then f:SetBackdropBorderColor(unpack(d.edge)) end
            end
            if d.font then f:SetFont(unpack(d.font)); f:SetTextColor(unpack(d.color)) end
            for r, saved in pairs(d.regions) do RestoreRegion(r, saved) end
        end
        for text, saved in pairs(record.menuFonts or {}) do RestoreRegion(text, saved) end
        for art in pairs(record.art or {}) do art:SetAlpha(0) end
        record.saved, record.menuFonts = {}, nil
    end
    local function PaintCheck(widget, record)
        if not record.active or not Ready() or not widget.checkbg or not widget.check then return end
        widget.checkbg:SetColorTexture(0.17, 0.17, 0.18, 1);
        widget.checkbg:SetVertexColor(1, 1, 1, 1); widget.checkbg:SetSize(14, 14)
        -- Keep the compact square centred in AceGUI's original 24px control
        -- slot. Its transparent native artwork supplied padding we must replace.
        widget.checkbg:ClearAllPoints(); widget.checkbg:SetPoint("TOPLEFT", widget.frame, "TOPLEFT", 5, -5)
        if H.Allowed(widget.text) then
            local anchor = H.Texture(widget.image) and widget.image:GetTexture() and widget.image or widget.checkbg
            widget.text:SetPoint("LEFT", anchor, "RIGHT", 6, 0)
        end
        widget.checkbg:SetTexCoord(0, 1, 0, 1)
        if widget.highlight then widget.highlight:SetColorTexture(1, 1, 1, 0.08) end
        local r, g, b = S.GetAccentColor()
        widget.check:SetVertexColor(1, 1, 1, 1)
        widget.check:SetColorTexture(widget.disabled and 0.45 or r, widget.disabled and 0.45 or g, widget.disabled and 0.45 or b, 1)
        widget.check:SetTexCoord(0, 1, 0, 1)
        widget.check:ClearAllPoints(); widget.check:SetPoint("CENTER", widget.checkbg, "CENTER"); widget.check:SetSize(8, 8)
    end
    PaintWidget = function(widget)
        if type(widget) ~= "table" or not H.Allowed(widget.frame) then return end
        local f = widget.frame
        local record = pooled[widget]
        if not record then
            record = {widget = widget, nodes = {}, saved = {}}; pooled[widget] = record
            -- Cleanup is intentionally ungated: disabling a skin cannot leak its
            -- appearance into an unrelated addon's next pool acquisition.
            if type(widget.OnRelease) == "function" then hooksecurefunc(widget, "OnRelease", function() Restore(record) end) end
        end
        if not record.active then
            record.active, record.saved = true, {}
            Snapshot(f, record)
            for art, alpha in pairs(record.art or {}) do art:SetAlpha(alpha) end
        end
        -- Snapshot newly introduced native subframes before this pass; a
        -- layout rebuild can add children without releasing the outer group.
        Snapshot(f, record)
        local before = {}
        for node in pairs(record.saved) do
            for _, r in ipairs(H.Regions(node)) do before[r] = true end
            for _, child in ipairs(H.Children(node)) do before[child] = true end
        end
        for node in pairs(record.saved) do owners[node] = record end
        if widget.type == "Window" or widget.type == "Frame" or widget.type == "Dropdown-Pullout" then Strip(f); Panel(f) end
        if widget.type == "InlineGroup" and H.Allowed(widget.content) then
            local border = widget.content:GetParent()
            if H.Allowed(border) and border ~= f then Strip(border); Panel(border) end
            Font(widget.titletext, true)
        end
        if widget.type == "Heading" then Strip(f); Font(widget.label, true) end
        if widget.type == "BlizOptionsGroup" then Font(widget.label, true) end
        if widget.type == "CheckBox" and widget.checkbg and widget.check then
            PaintCheck(widget, record)
            for _, method in ipairs({"SetValue", "SetType", "SetDisabled", "SetLabel", "SetImage"}) do
                H.Hook(widget, method, function() PaintCheck(widget, record) end)
            end
            for _, event in ipairs({"OnMouseDown", "OnMouseUp"}) do
                H.Script(f, event, function() PaintCheck(widget, record) end)
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
        elseif type(widget.type) == "string" and widget.type:match("^LSM30_") and H.Allowed(f.dropButton) then
            for _, key in ipairs({"DLeft", "DMiddle", "DRight"}) do if H.Texture(f[key]) then f[key]:SetAlpha(0) end end
            Panel(f)
            fills[f]:ClearAllPoints()
            fills[f]:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -18)
            fills[f]:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT")
            Arrow(f.dropButton, "v")
            if H.Allowed(f.text) then Label(f, f.text) end
            H.Script(f.dropButton, "OnClick", function() MediaPopup(widget) end)
            H.Hook(widget, "ToggleDrop", function() MediaPopup(widget) end)
            MediaPopup(widget)
        elseif widget.type == "Keybinding" then
            if H.Allowed(widget.button) then PoolButton(widget.button) end
            H.Script(widget.button, "OnClick", function()
                if record.active and Ready() and widget.msgframe and widget.msgframe:IsShown() and ns.StyleTextureDialog then
                    ns.StyleTextureDialog(S, module, widget.msgframe, true)
                end
            end)
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
        for _, item in ipairs(widget.items or {}) do
            if H.Allowed(item.text) then
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
    MediaPopup = function(widget)
        local own = pooled[widget]
        local frame = widget.dropdown
        if not Ready() or not own or not own.active or not H.Allowed(frame) or not frame:IsShown() then return end
        local record = mediaRecords[frame]
        if not record then
            record = {nodes = {}, saved = {}}; mediaRecords[frame] = record
            -- ReturnDropDownFrame clears its rows before hiding. Restore these
            -- native rows as well, before their next foreign acquisition.
            frame:HookScript("OnHide", function() H.Safe(Restore, record) end)
        end
        if record.active and record.widget ~= widget then Restore(record) end
        record.widget = widget
        if not record.active then
            record.active, record.saved = true, {}
            for art, alpha in pairs(record.art or {}) do art:SetAlpha(alpha) end
        end
        Snapshot(frame, record)
        local before = {}
        for node in pairs(record.saved) do
            owners[node] = record
            for _, r in ipairs(H.Regions(node)) do before[r] = true end
            for _, child in ipairs(H.Children(node)) do before[child] = true end
        end
        Strip(frame, frame.bgTex); Panel(frame)
        if H.Allowed(frame.slider) then Scroll(frame.slider, true) end
        for _, row in ipairs(frame.contentRepo or {}) do
            Font(row.text)
            local highlight = row.GetHighlightTexture and H.Texture(row:GetHighlightTexture())
            if highlight then highlight:SetColorTexture(1, 1, 1, 0.09) end
            if H.Texture(row.check) then row.check:SetVertexColor(S.GetAccentColor()) end
        end
        record.art = record.art or {}
        for node in pairs(record.saved) do
            for _, r in ipairs(H.Regions(node)) do if not before[r] then record.art[r] = r:GetAlpha() end end
            for _, child in ipairs(H.Children(node)) do if not before[child] then record.art[child] = child:GetAlpha() end end
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
        local ace = LibStub and LibStub("AceAddon-3.0", true)
        local target = ace and ace.GetAddon and ace:GetAddon("RareScanner", true)
        H.Hook(target, "SetupOptions", function() Options(true) end)
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
    local alertGeneration, explorerGeneration
    local function Visual(f)
        -- This exception is limited to known alert cosmetics. Never walk the
        -- secure action button or alter attributes, scripts, anchors or scale.
        return (type(f) == "table" or type(f) == "userdata") and f.GetObjectType
            and not (f.IsForbidden and f:IsForbidden())
    end
    local function Alert()
        if not Ready() then return end
        local f = _G.RARESCANNER_BUTTON
        if not Visual(f) or alertGeneration == generation then return end
        S.Panel(f, {noBorder = true})
        if f.SetBackdrop then f:SetBackdrop(nil) end
        for _, text in ipairs(H.Regions(f)) do Font(text) end
        if Visual(f.CloseButton) then S.CloseButton(f.CloseButton) end
        for _, key in ipairs({"FilterEntityButton", "UnFilterEntityButton"}) do
            local button = f[key]
            if Visual(button) then
                button._addonSkinIcon = button.GetNormalTexture and button:GetNormalTexture()
                S.Button(button, {"_addonSkinIcon"})
            end
        end
        for i, key in ipairs({"PreviousButton", "NextButton"}) do
            local button = f[key]
            if Visual(button) and H.Texture(button.Texture) then
                S.Button(button, {"Texture"})
                button.Texture:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png")
                button.Texture:SetSize(16, 16)
                if button.Texture.SetRotation then button.Texture:SetRotation(i == 1 and -math.pi / 2 or math.pi / 2) end
                button.Texture:SetVertexColor(S.GetAccentColor())
            end
        end
        alertGeneration = generation
    end
    local function Loot(pool)
        if not Ready() or not pool or not pool.EnumerateActive then return end
        for item in pool:EnumerateActive() do
            if H.Allowed(item) and H.Texture(item.Icon) then S.SquareIcon(item.Icon) end
        end
    end
    local function ExplorerRow(row)
        if not Ready() or not H.Allowed(row) then return end
        -- Preserve collection, rarity, dead/filtered and selected visibility.
        if H.Texture(row.BG) then row.BG:SetColorTexture(0.055, 0.055, 0.065, 0.94) end
        if H.Texture(row.Highlight) then row.Highlight:SetColorTexture(1, 1, 1, 0.09) end
        if H.Texture(row.NameBG) then row.NameBG:SetColorTexture(0.08, 0.08, 0.09, 0.92) end
        if H.Texture(row.Selected) then local r, g, b = S.GetAccentColor(); row.Selected:SetColorTexture(r, g, b, 0.16) end
        for _, key in ipairs({"Name", "Text"}) do Font(row[key]) end
        -- Portrait masks, collectible symbols and item overlays remain native.
    end
    local function List(list)
        if not H.Allowed(list) then return end
        local box = list.scrollBox or list.ScrollBox
        local view = box and box.GetView and box:GetView()
        if view and view.RegisterCallback and not views[view] then
            views[view] = true
            view:RegisterCallback("OnInitializedFrame", function(_, row)
                if Ready() then H.Safe(ExplorerRow, row) end
            end, module)
        end
        if box and box.ForEachFrame then box:ForEachFrame(ExplorerRow) end
    end
    local function Explorer()
        if not Ready() then return end
        local root = _G.RSExplorerFrame
        if not H.Allowed(root) then return end
        if explorerGeneration ~= generation then
            Panel(root); Lift(root)
            if root.Border then Strip(root.Border) end
            for _, f in ipairs({root.RareInfo, root.RareNPCList, root.CustomLoot}) do
                if H.Allowed(f) then
                    Panel(f)
                    if f.Border then Strip(f.Border) end
                    if f.BaseFrameBackground then H.Fade(f.BaseFrameBackground) end
                    if f.BoardDropShadow then H.Fade(f.BoardDropShadow) end
                    if f.background then H.Fade(f.background) end
                end
            end
            Walk(root, false)
            explorerGeneration = generation
        end
        List(root.RareNPCList)
        List(root.CustomLoot and root.CustomLoot.GroupList)
        Loot(root.lootItemsPool)
        Loot(root.CustomLoot and root.CustomLoot.GroupInfo and root.CustomLoot.GroupInfo.lootItemsPool)
    end
    local function Dialogs()
        local library = LibStub and LibStub("LibDialog-1.0RS", true)
        if not library or not ns.StyleTextureDialog then return end
        H.Hook(library, "Spawn", function(_, reference, data)
            if Ready() and type(reference) == "string" and reference:match("^RARESCANNER_") and library.ActiveDialog then
                local frame = library:ActiveDialog(reference, data)
                if H.Allowed(frame) then ns.StyleTextureDialog(S, module, frame, true) end
            end
        end)
    end
    local function Discover()
        Alert(); Explorer(); Options(); Dialogs()
        soft.RefreshSoftBorders()
    end
    Refresh = function()
        if applying or not Ready() then return end
        applying = true; H.Safe(Discover); applying = false
    end
    local scanner, root = _G.RARESCANNER_BUTTON, _G.RSExplorerFrame
    H.Hook(scanner, "ShowButton", Alert)
    H.Hook(_G.RSLootMixin, "AddItem", function(item) if Ready() and H.Allowed(item) and H.Texture(item.Icon) then S.SquareIcon(item.Icon) end end)
    H.Script(root, "OnShow", Refresh)
    H.Hook(root, "Initialize", Explorer)
    local rareList = root and root.RareNPCList
    H.Hook(rareList, "Initialize", Explorer)
    H.Hook(rareList, "OnElementInitialize", function(_, row) ExplorerRow(row) end)
    H.Hook(rareList, "OnElementSelectionChanged", function()
        if root then Loot(root.lootItemsPool) end
    end)
    local custom = root and root.CustomLoot
    H.Hook(custom, "Initialize", Explorer)
    H.Hook(custom, "OnElementInitialize", function(_, row) ExplorerRow(row) end)
    H.Hook(custom, "OnElementSelectionChanged", function()
        Loot(custom and custom.GroupInfo and custom.GroupInfo.lootItemsPool)
    end)
    module.refresh = function() generation = generation + 1; Refresh() end
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
    events:SetScript("OnEvent", function(_, event)
        if event == "ADDON_LOADED" then
            local gui = LibStub and LibStub("AceGUI-3.0", true)
            local gh = gui and libraryHooks[gui]
            -- Pool cleanup stays active after disabling the skin.
            if gui and (not gh or gh.Release ~= gui.Release) then WatchRelease(gui) end
            if not ns.IsEnabled(module) then return end
            local dialog = LibStub and LibStub("AceConfigDialog-3.0", true)
            local dh = dialog and libraryHooks[dialog]
            -- Constant-time identity checks. Bind only when a library method
            -- changes; never traverse options on unrelated addon-load events.
            if dialog and (not dh or dh.FeedGroup ~= dialog.FeedGroup) then
                if Ready() then Options(true) end
            end
        elseif waiting then
            waiting = false; generation = generation + 1; Refresh()
        end
    end)
    Refresh()
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("RareScanner", DefineSkin)
else DefineSkin() end
