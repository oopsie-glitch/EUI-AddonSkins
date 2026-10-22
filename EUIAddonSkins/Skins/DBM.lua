local ADDON, ns = ...
local function DefineSkin()

local function Window() return _G.DBM_GUI_OptionsFrame end
local Control, PanelColor
-- HUD work is independent of the load-on-demand options window. Hooks follow
-- DBT's object lifecycle, never its countdown Update/OnUpdate hot path.
local function HUD(C)
    if C.dbmHUD then return C.dbmHUD end
    local H, S = C.H, C.S
    local WHITE = "Interface\\Buttons\\WHITE8X8"
    local bars, icons = {}, {}
    local active, pending = false, false
    local defaults = {smallEnabled = true, hugeEnabled = true, smallLayout = "strip", hugeLayout = "fill",
        smallOpacity = 0.65, hugeOpacity = 0.65, smallColour = "category", hugeColour = "category",
        smallBorder = true, hugeBorder = true, hugeGlyphs = true,
        hugeIconScale = 1, hugeIconAccent = true, hugeIconR = 1, hugeIconG = 1, hugeIconB = 1,
        rangeOpacity = 0.85, radarOpacity = 0.85, infoOpacity = 0.85}
    local normalized
    local function Settings()
        EUIAddonSkinsDB = EUIAddonSkinsDB or {}
        local db = EUIAddonSkinsDB
        if type(db.dbm) ~= "table" then db.dbm = {} end
        local settings = db.dbm
        if settings == normalized then return settings end
        if settings.iconScaleVersion ~= 2 then
            local scale = settings.hugeIconScale
            if type(scale) == "number" and scale == scale then settings.hugeIconScale = math.max(0.5, math.min(2.5, scale / 1.25)) end
            settings.iconScaleVersion = 2
        end
        for key, value in pairs(defaults) do
            local current = settings[key]
            local valid = type(current) == type(value)
            if key:match("Layout$") then valid = current == "strip" or current == "fill"
            elseif key:match("Colour$") then valid = current == "category" or current == "accent"
            elseif key == "hugeIconScale" then valid = valid and current == current and current >= 0.5 and current <= 2.5
            elseif type(value) == "number" then valid = valid and current == current and current >= 0 and current <= 1 end
            if not valid then settings[key] = value end
        end
        normalized = settings
        return settings
    end
    -- Saved choices may change in combat; native callbacks must keep using the
    -- last applied choices until the deferred refresh can commit them safely.
    local applied
    local function ApplySettings()
        applied = applied or {}
        local db = Settings()
        for key in pairs(defaults) do applied[key] = db[key] end
    end
    local function AppliedSettings()
        if not applied then ApplySettings() end
        return applied
    end
    local function Allowed(f)
        return H.Allowed(f) and not (f.IsProtected and f:IsProtected())
    end
    local function Styled(obj)
        return AppliedSettings()[obj.enlarged and "hugeEnabled" or "smallEnabled"]
    end
    local function BorderShown(obj)
        return ns.AccentBarShown() and AppliedSettings()[obj.enlarged and "hugeBorder" or "smallBorder"]
    end
    -- Native ApplyStyle restores current profile values. These snapshots supply
    -- the XML anchors, crops and text properties that DBT does not reset.
    local properties = {
        -- Restore concrete font/shadow properties, never a borrowed FontObject.
        {"GetFont", "SetFont"}, {"GetTextColor", "SetTextColor"},
        {"GetShadowColor", "SetShadowColor"}, {"GetShadowOffset", "SetShadowOffset"},
        {"GetJustifyH", "SetJustifyH"}, {"GetJustifyV", "SetJustifyV"},
        {"CanWordWrap", "SetWordWrap"}, {"CanNonSpaceWrap", "SetNonSpaceWrap"},
        {"GetTexCoord", "SetTexCoord"}, {"GetVertexColor", "SetVertexColor"},
        {"GetBlendMode", "SetBlendMode"}, {"GetAlpha", "SetAlpha"},
    }
    local unpack = unpack or table.unpack
    local function Capture(region)
        if not Allowed(region) then return end
        local state = {region = region, width = region:GetWidth(), height = region:GetHeight(), points = {}}
        if region.GetNumPoints then
            for i = 1, region:GetNumPoints() do state.points[i] = {region:GetPoint(i)} end
        end
        for i, property in ipairs(properties) do
            if region[property[1]] and region[property[2]]
                and not (property[1] == "GetTexCoord" and region.GetNumMaskTextures and region:GetNumMaskTextures() > 0) then
                local values = {region[property[1]](region)}
                local public = true
                if issecretvalue then for _, value in ipairs(values) do if issecretvalue(value) then public = false; break end end end
                if public then state[i] = values end
            end
        end
        return state
    end
    local function RestoreRegion(state)
        local region = state.region
        if not Allowed(region) then return end
        region:ClearAllPoints()
        for _, point in ipairs(state.points) do region:SetPoint(unpack(point)) end
        region:SetSize(state.width, state.height)
        for i, property in ipairs(properties) do
            if state[i] and state[i][1] ~= nil then region[property[2]](region, unpack(state[i])) end
        end
    end
    local function NativeGlyph(icon, d)
        local old = d.mechanicGlyphs and d.mechanicGlyphs[icon]
        if old and icon:GetTexture() == old.texture then
            icon:SetTexture(old.nativeTexture)
            icon:SetTexCoord(unpack(old.nativeCrop))
            icon:SetVertexColor(old[1], old[2], old[3], old[4])
        end
        if old then d.mechanicGlyphs[icon] = nil end
    end
    local function RestoreBar(obj, d, name, bar)
        if not d.styled then return end
        d.styled = false
        for _, state in ipairs(d.native) do RestoreRegion(state) end
        -- SetIcon can change custom mechanic sizes/crops during pooled reuse.
        -- Prefer that latest native geometry over the session's first snapshot.
        for icon, size in pairs(d.nativeIconSizes or {}) do
            if H.Texture(icon) then
                icon:SetSize(size.width, size.height)
                if size.crop and not (icon.GetNumMaskTextures and icon:GetNumMaskTextures() > 0) then icon:SetTexCoord(unpack(size.crop)) end
            end
        end
        for texture, alpha in pairs(d.hidden or {}) do if H.Texture(texture) then texture:SetAlpha(alpha) end end
        for i = 1, 4 do
            local icon = _G[name .. "BarIJIcons" .. (i == 1 and "" or i)]
            if H.Texture(icon) then NativeGlyph(icon, d) end
        end
        if d.inlineSource and _G[name .. "BarName"]:GetText() == d.inlineOutput then
            _G[name .. "BarName"]:SetText(d.inlineSource)
        end
        d.inlineSource, d.inlineOutput, d.inlineLastSource, d.inlineSize, d.labelSize = nil, nil, nil, nil, nil
        for _, texture in ipairs({d.panel, d.tint}) do if texture then texture:Hide() end end
        for _, edge in ipairs(d.edges or {}) do edge:Hide() end
        for i = 1, 2 do
            local icon = _G[name .. "BarIcon" .. i]
            if icons[icon] then icons[icon].layer:Hide() end
        end
        bar:SetStatusBarTexture(d.nativeFill)
        local variance = _G[name .. "BarVariance"]
        if H.Texture(variance) then variance:SetTexture(d.nativeVariance) end
        d.native, d.mechanicAlpha, d.nativeIconSizes = nil, nil, nil
        if type(obj.ApplyStyle) == "function" then obj:ApplyStyle() end
    end
    local function RememberBar(obj, d, name, bar)
        if d.styled then return end
        d.native, d.hidden, d.nativeFill = {}, {}, bar:GetStatusBarTexture():GetTexture()
        local suffixes = {"Bar", "BarName", "BarTimer", "BarIcon1", "BarIcon2", "BarBackground", "BarSpark",
            "BarVariance", "BarVarianceBorder", "BarBorderTop", "BarBorderBottom", "BarBorderLeft", "BarBorderRight",
            "BarIJIcons", "BarIJIcons2", "BarIJIcons3", "BarIJIcons4"}
        for _, suffix in ipairs(suffixes) do
            local state = Capture(_G[name .. suffix])
            if state then d.native[#d.native + 1] = state end
        end
        local variance = _G[name .. "BarVariance"]
        d.nativeVariance = H.Texture(variance) and variance:GetTexture() or nil
        d.styled = true
    end
    local function HideNative(texture, d)
        if not H.Texture(texture) then return end
        if not d.hidden then d.hidden = {} end
        if d.hidden[texture] == nil then
            d.hidden[texture] = texture:GetAlpha()
            H.Hook(texture, "SetAlpha", function(_, alpha)
                if d.styled and alpha ~= 0 then texture:SetAlpha(0) end
            end)
        end
        texture:SetAlpha(0)
    end
    local function Font(text)
        if Allowed(text) and text.GetFont then S.Font(text) end
    end
    local function Shadow(text)
        if text.SetShadowColor then text:SetShadowColor(0, 0, 0, 0.9) end
        if text.SetShadowOffset then text:SetShadowOffset(1, -1) end
    end
    local function Edges(parent, icon)
        local d = icons[icon]
        if d then return d end
        -- A sibling layer follows the icon's current size without changing its
        -- native anchor, cooldown or click target. It accepts no mouse input.
        local layer = CreateFrame("Frame", nil, parent)
        layer:SetPoint("TOPLEFT", icon, "TOPLEFT")
        layer:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
        if layer.EnableMouse then layer:EnableMouse(false) end
        local edge = {}
        for i, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
            local t = layer:CreateTexture(nil, "OVERLAY")
            if i <= 2 then
                t:SetPoint(side .. "LEFT"); t:SetPoint(side .. "RIGHT"); t:SetHeight(1)
            else
                t:SetPoint("TOP" .. side); t:SetPoint("BOTTOM" .. side); t:SetWidth(1)
            end
            edge[i] = t
        end
        d = {layer = layer, edge = edge}; icons[icon] = d
        return d
    end
    local function Icon(parent, icon, border, r, g, b, neutral)
        if not Allowed(parent) or not H.Texture(icon) then return end
        -- Do not modify masked/private icons or guess the meaning of a border.
        if icon.GetNumMaskTextures and icon:GetNumMaskTextures() > 0 then return end
        S.SquareIcon(icon)
        local d = Edges(parent, icon)
        local visible = not icon.IsShown or icon:IsShown()
        if border and border.IsShown and border:IsShown() and not r then visible = false end
        d.layer:SetShown(visible)
        if r then
            if H.Texture(border) then
                if d.nativeBorderAlpha == nil then d.nativeBorderAlpha = border:GetAlpha() end
                border:SetAlpha(0)
            end
        elseif H.Texture(border) and d.nativeBorderAlpha ~= nil then
            border:SetAlpha(d.nativeBorderAlpha)
            d.nativeBorderAlpha = nil
        end
        if not r then
            if neutral then r, g, b = 0.16, 0.16, 0.18
            else r, g, b = S.GetAccentColor() end
        end
        for _, edge in ipairs(d.edge) do edge:SetColorTexture(r, g, b, 0.85) end
        return d
    end
    local function PaintVariance(obj)
        if type(obj) ~= "table" or obj.isSecret or not Allowed(obj.frame) or not Styled(obj) then return end
        local name = obj.frame:GetName()
        if not name then return end
        local variance, boundary = _G[name .. "BarVariance"], _G[name .. "BarVarianceBorder"]
        -- This region conveys timing uncertainty. Keep DBT's native width,
        -- anchors and visibility; only replace its additive gradient artwork.
        if H.Texture(variance) then
            variance:SetTexture(WHITE)
            variance:SetBlendMode("BLEND")
            variance:SetVertexColor(0.14, 0.14, 0.16, 0.65)
            -- DBT calculates this width from the full row. The inset layout
            -- uses a narrower progress strip; retain the same time proportion.
            local bar = _G[name .. "Bar"]
            if Allowed(bar) and type(obj.varianceDuration) == "number" and type(obj.totalTime) == "number" and obj.totalTime > 0 then
                variance:SetWidth(bar:GetWidth() * obj.varianceDuration / obj.totalTime)
            end
        end
        if H.Texture(boundary) then boundary:SetVertexColor(0.25, 0.25, 0.27, 0.65) end
    end
    local function Panel(parent, d)
        if d.panel then return end
        d.panel = parent:CreateTexture(nil, "BACKGROUND")
        -- The background slider owns its final opacity. DBT's row alpha still
        -- applies to native text/fill/icons; visibility continues to inherit.
        if d.panel.SetIgnoreParentAlpha then d.panel:SetIgnoreParentAlpha(true) end
        d.edges = {}
        for i, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
            local edge = parent:CreateTexture(nil, "BORDER")
            if i <= 2 then
                edge:SetPoint(side .. "LEFT", d.panel, side .. "LEFT"); edge:SetPoint(side .. "RIGHT", d.panel, side .. "RIGHT")
            else
                edge:SetPoint("TOP" .. side, d.panel, "TOP" .. side); edge:SetPoint("BOTTOM" .. side, d.panel, "BOTTOM" .. side)
            end
            d.edges[i] = edge
        end
    end
    local function Snap(value, pixel) return math.floor(value / pixel + 0.5) * pixel end
    local GLYPHS = "Interface\\AddOns\\EUIAddonSkins\\Media\\DBMMechanics.tga"
    local glyphNames = {"TANK_ICON", "DAMAGE_ICON", "HEALER_ICON", "INTERRUPT_ICON", "IMPORTANT_ICON", "MAGIC_ICON", "BLEED_ICON", "DEADLY_ICON"}
    -- Reference installed EUI artwork; never bundle optional module assets.
    -- Its plain role variants keep every indicator a clean monochrome glyph.
    local euiGlyphs = {
        [1] = {"EllesmereUIRaidFrames", "tank.png"},
        [2] = {"EllesmereUIRaidFrames", "dps.png"},
        [3] = {"EllesmereUIRaidFrames", "healer.png"},
        [4] = {"EllesmereUIDamageMeters", "dm_home_interrupt.png"},
        [8] = {"EllesmereUIDamageMeters", "dm_home_deaths.png"},
    }
    local function GlyphTexture(index)
        local asset = euiGlyphs[index]
        local loaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
        if asset and loaded and loaded(asset[1]) then
            return "Interface\\AddOns\\" .. asset[1] .. "\\Media\\" .. asset[2], 0, 1
        end
        return GLYPHS, (index - 1) / 8, index / 8
    end
    local glyphSource, glyphKeys
    local function GlyphKey(path, left, right, top, bottom)
        if (issecretvalue and (issecretvalue(path) or issecretvalue(left) or issecretvalue(right) or issecretvalue(top) or issecretvalue(bottom))) then return end
        if (type(path) ~= "string" and type(path) ~= "number") or type(left) ~= "number" or type(right) ~= "number" or type(top) ~= "number" or type(bottom) ~= "number" then return end
        path = tostring(path):lower():gsub("/", "\\"):gsub("%.blp$", ""):gsub("%.tga$", "")
        return path .. ":" .. math.floor(left * 4096 + 0.5) .. ":" .. math.floor(right * 4096 + 0.5) .. ":" .. math.floor(top * 4096 + 0.5) .. ":" .. math.floor(bottom * 4096 + 0.5)
    end
    local function ParseGlyphTag(tag)
        if type(tag) ~= "string" or issecretvalue and issecretvalue(tag) then return end
        local p, w, h, l, r, t, b = tag:match("|T([^:|]+):%d+:%d+:[^|]-:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)|t")
        w, h = tonumber(w), tonumber(h)
        if p and w and h and w > 0 and h > 0 then
            return p, tonumber(l) / w, tonumber(r) / w, tonumber(t) / h, tonumber(b) / h
        end
    end
    local function GlyphMap()
        local source = _G.DBM_COMMON_L
        if type(source) ~= "table" then return end
        if source ~= glyphSource then
            glyphSource, glyphKeys = source, {}
            for index, field in ipairs(glyphNames) do
                local p, left, right, top, bottom = ParseGlyphTag(source[field])
                if p then
                    glyphKeys[GlyphKey(p, left, right, top, bottom)] = index
                    if type(GetFileIDFromPath) == "function" then
                        local id = GetFileIDFromPath(p)
                        if not (issecretvalue and issecretvalue(id)) and type(id) == "number" and id > 0 then
                            glyphKeys[GlyphKey(id, left, right, top, bottom)] = index
                        end
                    end
                end
            end
        end
        return glyphKeys
    end
    local function IconKey(icon, path)
        local ulX, ulY, llX, llY, urX, urY, lrX, lrY = icon:GetTexCoord()
        if issecretvalue and (issecretvalue(ulX) or issecretvalue(ulY) or issecretvalue(llX) or issecretvalue(llY) or issecretvalue(urX) or issecretvalue(urY) or issecretvalue(lrX) or issecretvalue(lrY)) then return end
        if urX ~= nil then
            if llX == ulX and urY == ulY and lrX == urX and lrY == llY then return GlyphKey(path, ulX, urX, ulY, llY) end
        else return GlyphKey(path, ulX, ulY, llX, llY) end
    end
    local function RememberMechanics(obj, d, custom)
        if not d then return end
        d.mechanicHints = nil
        if type(custom) ~= "string" or issecretvalue and issecretvalue(custom) then return end
        local keys, name = GlyphMap(), obj.frame:GetName()
        if not keys or not name then return end
        local slot = 0
        for tag in custom:gmatch("|T[^|]+|t") do
            local p, left, right, top, bottom = ParseGlyphTag(tag)
            if p then
                slot = slot + 1
                if slot > 4 then break end
                local index = keys[GlyphKey(p, left, right, top, bottom)]
                local icon = _G[name .. "BarIJIcons" .. (slot == 1 and "" or slot)]
                if index and H.Texture(icon) and not (icon.GetNumMaskTextures and icon:GetNumMaskTextures() > 0) then
                    local key = IconKey(icon, icon:GetTexture())
                    if key then
                        d.mechanicHints = d.mechanicHints or {}
                        -- Match the actual rendered texture/crop to DBM's explicit
                        -- tag. Numeric file IDs then need no path-resolution API.
                        d.mechanicHints[icon] = {key = key, index = index}
                    end
                end
            end
        end
    end
    local function MechanicGlyph(icon, d)
        if not H.Texture(icon) or not Allowed(icon) or not icon.GetTexCoord then return end
        if icon.GetNumMaskTextures and icon:GetNumMaskTextures() > 0 then return end
        local rawPath = icon:GetTexture()
        local path = icon.GetTextureFilePath and icon:GetTextureFilePath() or rawPath
        if (issecretvalue and (issecretvalue(path) or issecretvalue(rawPath))) or path == nil then return end
        if not AppliedSettings().hugeGlyphs then NativeGlyph(icon, d); return end
        d.mechanicGlyphs = d.mechanicGlyphs or {}
        local old = d.mechanicGlyphs[icon]
        -- Reuse identity only while our exact texture remains assigned. Native
        -- SetIcon resets it on pooling; late EUI modules can upgrade our fallback.
        local styled = old and rawPath == old.texture
        local keys = GlyphMap()
        if not keys then return end
        local key, rawKey = IconKey(icon, path), IconKey(icon, rawPath)
        local hint = d.mechanicHints and d.mechanicHints[icon]
        local index = styled and old.index or key and (keys[key] or keys[rawKey])
            or hint and rawKey == hint.key and hint.index
        if index then
            if not old then
                local r, g, b, alpha = icon:GetVertexColor()
                if issecretvalue and (issecretvalue(r) or issecretvalue(g) or issecretvalue(b) or issecretvalue(alpha)) then return end
                old = {r, g, b, alpha}; d.mechanicGlyphs[icon] = old
            end
            if not styled then
                old.nativeTexture, old.nativeCrop = rawPath, {icon:GetTexCoord()}
            end
            local target, left, right = GlyphTexture(index)
            if not styled or target ~= old.path then
                old.index, old.path = index, target
                icon:SetTexture(target)
                old.texture = icon:GetTexture()
                icon:SetTexCoord(left, right, 0, 1)
            end
            local settings = AppliedSettings()
            local r, g, b = settings.hugeIconR, settings.hugeIconG, settings.hugeIconB
            if settings.hugeIconAccent then r, g, b = ns.AccentBarColor(S) end
            icon:SetVertexColor(r, g, b, 1)
        elseif old then
            icon:SetVertexColor(old[1], old[2], old[3], old[4]); d.mechanicGlyphs[icon] = nil
        end
    end
    local function BarLayout(obj, bar, d, name)
        local frame, options = obj.frame, _G.DBT and _G.DBT.Options or {}
        local prefix = obj.enlarged and "Huge" or ""
        local width = frame:GetWidth()
        local height = math.max(8, options[prefix .. "Height"] or frame:GetHeight())
        local scale = frame.GetEffectiveScale and frame:GetEffectiveScale() or 1
        local factor = PixelUtil and PixelUtil.GetPixelToUIUnitFactor and PixelUtil.GetPixelToUIUnitFactor()
        if not factor and GetPhysicalScreenSize then
            local _, physicalHeight = GetPhysicalScreenSize()
            if physicalHeight and physicalHeight > 0 then factor = 768 / physicalHeight end
        end
        local pixel = (factor or 1) / math.max(scale, 0.01)
        local pad = math.max(pixel, Snap(2, pixel))
        local gap = math.max(pixel, Snap(2, pixel))
        local iconPad = obj.enlarged and pad or 0
        local iconSize = math.max(pixel, Snap(obj.enlarged and math.min(height - pad * 2, width * 0.14) or height, pixel))
        local left, right = _G[name .. "BarIcon1"], _G[name .. "BarIcon2"]
        local leftSpace = H.Texture(left) and left:IsShown() and iconSize + gap or 0
        local rightSpace = H.Texture(right) and right:IsShown() and iconSize + gap or 0
        for i = 1, 2 do
            local icon = i == 1 and left or right
            if H.Texture(icon) then
                icon:SetSize(iconSize, iconSize); icon:ClearAllPoints()
                icon:SetPoint(i == 1 and "LEFT" or "RIGHT", frame, i == 1 and "LEFT" or "RIGHT", i == 1 and iconPad or -iconPad, 0)
            end
        end
        -- Huge Bar indicators live outside the left edge, before the spell icon.
        -- Their presence never changes track length, text or countdown anchors.
        d.mechanicAlpha = d.mechanicAlpha or {}
        local count = 0
        for i = 1, 4 do
            local icon = _G[name .. "BarIJIcons" .. (i == 1 and "" or i)]
            if H.Texture(icon) then
                if d.mechanicAlpha[icon] == nil then d.mechanicAlpha[icon] = icon:GetAlpha() end
                icon:SetAlpha(obj.enlarged and d.mechanicAlpha[icon] or 0)
                if obj.enlarged and icon:IsShown() and icon:GetTexture() ~= nil then count = count + 1 end
            end
        end
        local columns, rows = count > 1 and 2 or 1, count > 2 and 2 or 1
        local symbolSize = math.max(pixel, Snap(math.min(height * (rows == 2 and 0.4 or 0.6), width * 0.1) * 1.25 * AppliedSettings().hugeIconScale, pixel))
        local slot = 0
        for i = 1, 4 do
            local icon = _G[name .. "BarIJIcons" .. (i == 1 and "" or i)]
            if H.Texture(icon) and obj.enlarged and icon:IsShown() and icon:GetTexture() ~= nil then
                local column, row = slot % columns, math.floor(slot / columns)
                icon:SetSize(symbolSize, symbolSize); icon:ClearAllPoints()
                icon:SetPoint("CENTER", frame, "LEFT", -gap - symbolSize / 2 - column * (symbolSize + pixel),
                    ((rows - 1) / 2 - row) * (symbolSize + pixel))
                MechanicGlyph(icon, d)
                slot = slot + 1
            end
        end
        local contentX = leftSpace > 0 and iconPad + leftSpace or pad
        local contentRight = rightSpace > 0 and iconPad + rightSpace or pad
        Panel(frame, d)
        d.panel:ClearAllPoints()
        d.panel:SetPoint("TOPLEFT", frame, "LEFT", 0, Snap(height / 2, pixel))
        d.panel:SetPoint("BOTTOMRIGHT", frame, "RIGHT", 0, Snap(-height / 2, pixel))
        d.panel:SetColorTexture(0.13, 0.135, 0.14, AppliedSettings()[obj.enlarged and "hugeOpacity" or "smallOpacity"])
        d.panel:SetShown(true)
        d.borderPixel = pixel
        local r, g, b = ns.AccentBarColor(S)
        for i, edge in ipairs(d.edges) do
            if i <= 2 then edge:SetHeight(pixel) else edge:SetWidth(pixel) end
            edge:SetColorTexture(r, g, b, 0.35)
            edge:SetShown(BorderShown(obj))
        end
        local label, timer = _G[name .. "BarName"], _G[name .. "BarTimer"]
        local path, flags = S.GetFont()
        local nativeSize = options.FontSize or 10
        local layout = AppliedSettings()[obj.enlarged and "hugeLayout" or "smallLayout"]
        -- Extremely short/narrow rows keep the single-line fallback even when
        -- the saved preference is a name-above-strip layout.
        local twoRow = layout == "strip" and height >= 18 and width >= 150
        local fillHeight = twoRow and math.max(pixel, Snap(height * 0.25, pixel)) or math.max(pixel, Snap(height - pad * 2, pixel))
        local labelHeight = twoRow and math.max(pixel, height - pad * 2 - fillHeight - pixel) or height - pad * 2
        d.labelSize = math.max(6, math.min(nativeSize * (obj.enlarged and 1.1 or 1), twoRow and labelHeight * 0.9 or height * 0.55))
        local timerSize = math.max(6, math.min(nativeSize * (obj.enlarged and 1.1 or 1), height * 0.6))
        -- Limit reservations at DBT's narrowest sizes; never resize its stack frame.
        local available = math.max(pixel, width - contentX - contentRight)
        local timerSpace = math.min(available * 0.4, math.max(20, timerSize * 3.0))
        local trackX = contentX + (twoRow and gap or 0)
        -- Countdown reserves text space, never progress width. The strip/fill
        -- reaches the row's right inset (or the configured right spell icon).
        local trackRight = contentRight
        local trackTop = twoRow and -height / 2 + pad + fillHeight or height / 2 - pad
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", frame, "LEFT", trackX, Snap(trackTop, pixel))
        bar:SetPoint("TOPRIGHT", frame, "RIGHT", -trackRight, Snap(trackTop, pixel))
        bar:SetHeight(fillHeight)
        local x, y = options[prefix .. "TextXOffset"] or 0, options[prefix .. "TextYOffset"] or 0
        local labelY = twoRow and height / 2 - pad - labelHeight / 2 or 0
        if Allowed(timer) then
            timer:SetFont(path, math.min(timerSize, twoRow and labelHeight * 0.9 or timerSize), flags or ""); timer:SetWidth(timerSpace)
            timer:SetHeight(twoRow and labelHeight or height - pad * 2); timer:ClearAllPoints()
            timer:SetPoint("RIGHT", frame, "RIGHT", -contentRight - gap + x, labelY + y)
            if timer.SetJustifyH then timer:SetJustifyH("RIGHT") end
            if timer.SetJustifyV then timer:SetJustifyV("MIDDLE") end
            Shadow(timer)
        end
        if Allowed(label) then
            label:SetFont(path, d.labelSize, flags or ""); label:ClearAllPoints()
            label:SetPoint("LEFT", frame, "LEFT", contentX + gap + x, labelY + y)
            label:SetPoint("RIGHT", frame, "RIGHT", -contentRight - timerSpace - gap * 2 + x, labelY + y)
            label:SetHeight(labelHeight)
            if label.SetJustifyH then label:SetJustifyH("LEFT") end
            if label.SetJustifyV then label:SetJustifyV("MIDDLE") end
            if label.SetWordWrap then label:SetWordWrap(false) end
            if label.SetNonSpaceWrap then label:SetNonSpaceWrap(false) end
            Shadow(label)
        end
    end
    local function FitInlineIcons(obj)
        if type(obj) ~= "table" or obj.isSecret or not Allowed(obj.frame) then return end
        local d = bars[obj]
        local name = obj.frame:GetName()
        local label = name and _G[name .. "BarName"]
        if not d or not d.styled or not Styled(obj) or d.inlineBusy or not d.labelSize or not Allowed(label) or not label.GetText then return end
        local text = label:GetText()
        if (issecretvalue and issecretvalue(text)) or type(text) ~= "string" then return end
        if text ~= d.inlineOutput then d.inlineSource = text end
        if d.inlineSource == d.inlineLastSource and d.inlineSize == d.labelSize and text == d.inlineOutput then return end
        d.inlineLastSource, d.inlineSize = d.inlineSource, d.labelSize
        local limit = math.max(1, math.floor(d.labelSize * 1.15 + 0.5))
        -- Preserve path, crop coordinates, offsets, words and color tags. Only
        -- explicitly sized oversized texture tags need resizing; auto-sized and
        -- atlas tags retain native behavior. Never write this back to DBM data.
        local output = d.inlineSource:gsub("|T([^:|]+):(%d+):(%d+)([^|]*)|t", function(path, h, w, rest)
            local height, width = tonumber(h), tonumber(w)
            if height <= 0 or width <= 0 or math.max(height, width) <= limit then
                return "|T" .. path .. ":" .. h .. ":" .. w .. rest .. "|t"
            end
            local ratio = limit / math.max(height, width)
            return "|T" .. path .. ":" .. math.max(1, math.floor(height * ratio + 0.5)) .. ":" .. math.max(1, math.floor(width * ratio + 0.5)) .. rest .. "|t"
        end)
        d.inlineOutput = output
        if output ~= text then
            d.inlineBusy = true
            label:SetText(output)
            d.inlineBusy = false
        end
    end
    local function FillAlpha(obj, d, alpha)
        if not d.styled or obj.isSecret or not d.tint then return end
        if issecretvalue and issecretvalue(alpha) then return end
        alpha = alpha or 1
        if type(alpha) ~= "number" or d.fillAlpha == alpha then return end
        if not Allowed(obj.frame) or not Allowed(d.tint) then return end
        d.fillAlpha = alpha
        d.tint:SetAlpha(alpha)
    end
    local function BindFillAlpha(obj, bar, fill, d)
        d.fill = fill
        -- DBT flashes via SetStatusBarColor and also accepts direct vertex
        -- colours. Follow only alpha changes; never recolour native data or
        -- add a countdown/OnUpdate hook, scan or allocation to these callbacks.
        if not d.alphaBar then
            d.alphaBar = bar
            H.Hook(bar, "SetStatusBarColor", function(_, _, _, _, alpha) FillAlpha(obj, d, alpha) end)
        end
        if d.alphaFill ~= fill then
            d.alphaFill = fill
            H.Hook(fill, "SetVertexColor", function(_, _, _, _, alpha)
                if d.fill == fill then FillAlpha(obj, d, alpha) end
            end)
        end
        local _, _, _, alpha = fill:GetVertexColor()
        FillAlpha(obj, d, alpha)
    end
    local function PaintBar(obj)
        if not ns.IsEnabled(C.module) or active then return end
        -- Ordinary DBT timer frames are insecure and need styling when created
        -- during a fight. Protected/secret timers are excluded below.
        if type(obj) ~= "table" or obj.isSecret or not Allowed(obj.frame) then return end
        local name = obj.frame:GetName()
        if not name then return end
        local bar = _G[name .. "Bar"]
        if not Allowed(bar) or not bar.GetStatusBarTexture then return end
        active = true
        H.Safe(function()
            local d = bars[obj]
            if not Styled(obj) then RestoreBar(obj, d, name, bar); return end
            RememberBar(obj, d, name, bar)
            -- ApplyBarFill registers a permanent accent recolor in EUI; DBM
            -- fills instead retain native mechanic colors and urgency changes.
            local fill = bar:GetStatusBarTexture()
            if H.Texture(fill) and fill:GetTexture() ~= WHITE then
                local r, g, b, a = fill:GetVertexColor()
                if not (issecretvalue and (issecretvalue(r) or issecretvalue(g) or issecretvalue(b) or issecretvalue(a))) then
                    bar:SetStatusBarTexture(WHITE)
                    bar:GetStatusBarTexture():SetVertexColor(r, g, b, a)
                end
            end
            local bg = _G[name .. "BarBackground"]
            HideNative(bg, d)
            local spark = _G[name .. "BarSpark"]
            HideNative(spark, d)
            for _, side in ipairs({"Top", "Bottom", "Left", "Right"}) do
                local border = _G[name .. "BarBorder" .. side]
                HideNative(border, d)
            end
            Font(_G[name .. "BarName"]); Font(_G[name .. "BarTimer"])
            BarLayout(obj, bar, d, name)
            FitInlineIcons(obj)
            PaintVariance(obj)
            local r, g, b = ns.AccentBarColor(S)
            for i = 1, 2 do
                local icon = _G[name .. "BarIcon" .. i]
                if H.Texture(icon) then
                    local border = Icon(obj.frame, icon, nil, r, g, b)
                    if border then
                        for j, edge in ipairs(border.edge) do
                            if j <= 2 then edge:SetHeight(d.borderPixel) else edge:SetWidth(d.borderPixel) end
                            edge:SetShown(BorderShown(obj))
                        end
                    end
                end
            end
            -- The matte tint follows the native fill and its flash alpha.
            -- Full-width tracks need no fixed or moving end ticks.
            fill = bar:GetStatusBarTexture()
            if H.Texture(fill) then
                if not d.tint then d.tint = bar:CreateTexture(nil, "ARTWORK", nil, 2) end
                d.tint:SetAllPoints(fill)
                if AppliedSettings()[obj.enlarged and "hugeColour" or "smallColour"] == "accent" then
                    local ar, ag, ab = ns.AccentBarColor(S)
                    d.tint:SetColorTexture(ar, ag, ab, 1)
                else
                    d.tint:SetColorTexture(obj.enlarged and 0.08 or 0.14, obj.enlarged and 0.08 or 0.14, obj.enlarged and 0.08 or 0.14, obj.enlarged and 0.4 or 0.2)
                end
                d.tint:SetShown(true)
                BindFillAlpha(obj, bar, fill, d)
            end
        end)
        active = false
    end
    local function NativeIconChanged(obj, _, eventID, custom)
        if type(obj) ~= "table" or obj.isSecret or not Allowed(obj.frame) then return end
        local d = bars[obj]
        RememberMechanics(obj, d, custom)
        if d and d.styled and not (issecretvalue and (issecretvalue(eventID) or issecretvalue(custom))) and not eventID and type(custom) == "string" then
            d.nativeIconSizes = d.nativeIconSizes or {}
            local name = obj.frame:GetName()
            for i = 1, 4 do
                local icon = name and _G[name .. "BarIJIcons" .. (i == 1 and "" or i)]
                -- Native SetIcon clears old textures, then sizes only the
                -- populated custom slots. Do not capture our size on empty slots.
                if H.Texture(icon) and icon:GetTexture() ~= nil then
                    local width, height = icon:GetWidth(), icon:GetHeight()
                    if not (issecretvalue and (issecretvalue(width) or issecretvalue(height))) and type(width) == "number" and type(height) == "number" then
                        local size = d.nativeIconSizes[icon] or {}
                        d.nativeIconSizes[icon] = size
                        size.width, size.height = width, height
                        if not (icon.GetNumMaskTextures and icon:GetNumMaskTextures() > 0) then
                            local crop, public = {icon:GetTexCoord()}, true
                            if issecretvalue then for _, value in ipairs(crop) do if issecretvalue(value) then public = false; break end end end
                            if public then size.crop = crop end
                        end
                    end
                end
            end
        end
        PaintBar(obj)
    end
    local function BindBar(obj)
        if type(obj) ~= "table" or obj.isSecret or not Allowed(obj.frame) then return end
        if not bars[obj] then
            bars[obj] = {}
            RememberMechanics(obj, bars[obj], obj.inlineIcon)
            H.Hook(obj, "ApplyStyle", PaintBar)
            H.Hook(obj, "SetIcon", NativeIconChanged)
            H.Hook(obj, "SetVariance", PaintVariance)
            H.Hook(obj, "SetText", FitInlineIcons)
        end
        PaintBar(obj)
    end
    local TYPES = {"Magic", "Curse", "Disease", "Poison", "Bleed"}
    local selectionBackdrop = {edgeFile = WHITE, edgeSize = 1}
    local function Preview(f)
        if not Allowed(f) then return end
        for i, icon in ipairs(f.Textures or {}) do
            local border = f.BorderTextures and f.BorderTextures[i]
            local dispelType = TYPES[(i - 1) % #TYPES + 1]
            -- Retail removed the legacy DebuffTypeColor global. Resolve the
            -- preview's known demo type through AuraUtil, never live aura data.
            local color
            if border and border.IsShown and border:IsShown() then
                color = AuraUtil and AuraUtil.GetAuraBorderColor and AuraUtil.GetAuraBorderColor(dispelType)
                    or DebuffTypeColor and DebuffTypeColor[dispelType]
            end
            local d = Icon(f.OverlayFrames and f.OverlayFrames[i] or f, icon, border,
                color and color.r, color and color.g, color and color.b)
            if d then
                -- The large protruding glyph is part of Blizzard's border
                -- atlas. Replace it with the matching standalone native atlas.
                if color and AuraUtil and AuraUtil.SetAuraDispelTypeIcon then
                    if not d.symbol then d.symbol = d.layer:CreateTexture(nil, "OVERLAY") end
                    local size = math.max(10, math.min(18, icon:GetWidth() * 0.24))
                    AuraUtil.SetAuraDispelTypeIcon(d.symbol, dispelType)
                    d.symbol:SetSize(size, size)
                    d.symbol:ClearAllPoints(); d.symbol:SetPoint("TOPRIGHT", icon, "TOPRIGHT", -2, -2)
                    d.symbol:SetShown(not icon.IsShown or icon:IsShown())
                elseif d.symbol then d.symbol:Hide() end
            end
            local duration, stack = f.DurationTexts and f.DurationTexts[i], f.StackTexts and f.StackTexts[i]
            Font(duration); Font(stack)
            local durationSize = Allowed(duration) and select(2, duration:GetFont()) or 20
            if Allowed(duration) then
                duration:ClearAllPoints(); duration:SetPoint("CENTER", icon, "CENTER", 0, 1)
                Shadow(duration)
            end
            if Allowed(stack) then
                local path, size, flags = stack:GetFont()
                stack:SetFont(path, math.min(size or 12, math.max(8, (durationSize or 20) * 0.55)), flags)
                stack:ClearAllPoints(); stack:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -3, 3)
                Shadow(stack)
            end
            -- Keep native colorblind abbreviations; do not replace their text.
            local symbol = f.Symbols and f.Symbols[i]
            if Allowed(symbol) then
                Font(symbol)
                symbol:ClearAllPoints(); symbol:SetPoint("TOPLEFT", icon, "TOPLEFT", 2, -2)
                Shadow(symbol)
            end
        end
        if Allowed(f.Border) and f.Border.SetBackdropBorderColor then
            if f.Border.SetBackdrop then f.Border:SetBackdrop(selectionBackdrop) end
            f.Border:ClearAllPoints()
            f.Border:SetPoint("TOPLEFT", f, "TOPLEFT", -1, 1)
            f.Border:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, -1)
            local r, g, b = S.GetAccentColor(); f.Border:SetBackdropBorderColor(r, g, b, 0.8)
        end
        Font(f.NameLabel)
    end
    local function PaintAuras()
        if not ns.IsEnabled(C.module) then return end
        if InCombatLockdown and InCombatLockdown() then pending = true; return end
        local auras = _G.DBM and _G.DBM.Auras
        if type(auras) ~= "table" then return end
        Preview(auras.PlayerPreview); Preview(auras.CoTankPreview); Preview(auras.CoTankPreview2)
        -- Restricted live aura containers are Blizzard-managed. Do not read or
        -- hook their buttons, bindings or secret duration/dispel data.
        if C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() then return end
        for _, state in pairs(auras.AuraTrackingState or {}) do
            for button, regions in pairs(state.buttonRegions or {}) do
                if Allowed(button) then
                    -- Preserve the live dispel artwork/symbol rather than infer
                    -- a dispel type from inaccessible aura information.
                    Icon(button, regions.icon, regions.dispelBorder)
                    Font(regions.durationText); Font(regions.countText)
                end
            end
        end
    end
    local warnings = {}
    local function BindWarning(text)
        if not Allowed(text) or not text.GetFont then return end
        local state = warnings[text]
        if not state then
            state = {}; warnings[text] = state
            state.font = function()
                if state.painting or not ns.IsEnabled(C.module) or not Allowed(text) then return end
                state.painting = true
                H.Safe(function()
                    local _, size = text:GetFont()
                    local path, flags = S.GetFont()
                    if path and size then text:SetFont(path, size, flags or ""); Shadow(text) end
                end)
                state.painting = false
            end
            state.icons = function()
                if state.painting or not ns.IsEnabled(C.module) or not Allowed(text) then return end
                local value = text:GetText()
                if issecretvalue and issecretvalue(value) then return end
                if type(value) ~= "string" or not value:find("|T", 1, true) then return end
                -- DBM's own warning icons use exactly :12:12. Leave other
                -- inline art (raid markers, timeline glyphs, custom crops) intact.
                local cropped = value:gsub("|T([^:|]+):12:12|t", "|T%1:12:12:0:0:64:64:5:59:5:59|t")
                if cropped == value then return end
                state.painting = true
                H.Safe(text.SetText, text, cropped)
                state.painting = false
            end
            H.Hook(text, "SetFont", state.font)
            H.Hook(text, "SetFontObject", state.font)
            H.Hook(text, "SetText", state.icons)
        end
        state.font(); state.icons()
    end
    local function PaintWarnings()
        for i = 1, 3 do BindWarning(_G["DBMWarning" .. i]) end
        for i = 1, 2 do BindWarning(_G["DBMSpecialWarning" .. i]) end
    end
    local function RefreshBars()
        if not ns.IsEnabled(C.module) then return end
        if InCombatLockdown and InCombatLockdown() then pending = true; return end
        ApplySettings()
        local dbt = _G.DBT
        if type(dbt) == "table" and dbt.GetBarIterator then
            for obj in dbt:GetBarIterator() do BindBar(obj) end
        end
    end
    local function PreviewState(state)
        if not state.preview then return end
        local dbm = _G.DBM
        local inCombat = InCombatLockdown and InCombatLockdown()
        local available = ns.IsEnabled(C.module) and type(dbm) == "table" and type(dbm.DemoMode) == "function"
        if state.preview.SetEnabled then state.preview:SetEnabled(available and not inCombat) end
        if state.button then state.button:SetEnabled(ns.IsEnabled(C.module) and (not inCombat or state.frame ~= nil)) end
        if not state.notice then return end
        if inCombat then state.notice:SetText("Styling changes apply after combat. Preview is unavailable during combat.")
        elseif state.selected == "frames" then state.notice:SetText("Changes apply immediately.\nFrame position and size remain controlled by DBM.")
        elseif not available then state.notice:SetText("Bar preview is unavailable in this DBM version.")
        else state.notice:SetText("Changes apply immediately.\nSize, position and spacing remain controlled by DBM.") end
    end
    local function RunPreview()
        if not ns.IsEnabled(C.module) or InCombatLockdown and InCombatLockdown() then return end
        local dbm, gui = _G.DBM, _G.DBM_GUI
        if type(dbm) ~= "table" or type(dbm.DemoMode) ~= "function" then return end
        local duration = dbm:DemoMode(true)
        if type(gui) == "table" and type(gui.CollapseForPreview) == "function" and type(duration) == "number" and duration > 0 then
            gui:CollapseForPreview(duration)
        end
    end
    local UpdateSide, OpenSide, RefreshAux
    local function SideAccent()
        local state = C.dbmPreview
        if not state then return end
        local r, g, b = ns.AccentBarColor(S)
        if state.title then state.title:SetTextColor(r, g, b, 1) end
        local label = state.button:GetFontString()
        if label then label:SetTextColor(r, g, b, 1) end
    end
    local function PositionSide(state)
        local panel, position = state.frame, state.position
        panel:ClearAllPoints()
        if type(position) == "table" and type(position.x) == "number" and type(position.y) == "number"
            and position.x == position.x and position.y == position.y and math.abs(position.x) < 100000 and math.abs(position.y) < 100000 then
            panel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", position.x, position.y)
        else panel:SetPoint("TOPLEFT", state.button, "BOTTOMLEFT", 0, -6) end
    end
    local function SaveSidePosition(state)
        local panel = state.frame
        panel:StopMovingOrSizing()
        if not state.dragging then return end
        state.dragging = nil
        local x, y = panel:GetLeft(), panel:GetTop()
        local px, py = UIParent:GetLeft(), UIParent:GetTop()
        local scale = panel:GetEffectiveScale() / UIParent:GetEffectiveScale()
        if not x or not y or not px or not py then PositionSide(state); return end
        state.position = {x = x * scale - px, y = y * scale - py}
        PositionSide(state)
    end
    local function SyncLayoutControls()
        local page, db = C.dbmSettings, Settings()
        if not page then return end
        for _, entry in ipairs({{page.small, "smallLayout"}, {page.huge, "hugeLayout"}}) do
            if entry[1].SetSelectedValue and entry[1].value ~= db[entry[2]] then entry[1]:SetSelectedValue(db[entry[2]]) end
        end
    end
    local function ChangeSetting(key, value, coalesce)
        local db = Settings()
        if db[key] == value then return end
        db[key] = value
        local refresh = key == "rangeOpacity" or key == "radarOpacity" or key == "infoOpacity"
        refresh = refresh and RefreshAux or RefreshBars
        if coalesce then H.Queue(C.dbmPreview, refresh) else refresh() end
        if UpdateSide then UpdateSide() end
        SyncLayoutControls()
    end
    UpdateSide = function()
        local state = C.dbmPreview
        if not state or not state.frame then return end
        local db, prefix = Settings(), state.selected
        local frames = prefix == "frames"
        for _, control in ipairs({state.enabled, state.layout, state.colour, state.opacity, state.opacityText, state.border}) do control:SetShown(not frames) end
        for _, entry in ipairs(state.frameSliders) do
            entry.slider:SetShown(frames); entry.label:SetShown(frames)
            entry.slider:SetEnabled(ns.IsEnabled(C.module))
        end
        state.preview:SetShown(not frames)
        state.updating = true
        for _, entry in ipairs(state.frameSliders) do
            entry.slider:SetValue(db[entry.key] * 100)
            entry.label:SetText(entry.text .. ": " .. math.floor(db[entry.key] * 100 + 0.5) .. "%")
        end
        if not frames then
            state.enabled:SetChecked(db[prefix .. "Enabled"])
            state.border:SetChecked(db[prefix .. "Border"])
            state.glyphs:SetChecked(db.hugeGlyphs)
            state.glyphs:SetShown(prefix == "huge")
            state.iconScale:SetValue(db.hugeIconScale * 100)
            state.iconScaleText:SetText("Mechanic icon size: " .. math.floor(db.hugeIconScale * 100 + 0.5) .. "%")
            state.iconAccent:SetChecked(db.hugeIconAccent)
            for _, control in ipairs({state.iconScale, state.iconScaleText, state.iconAccent, state.iconCustom}) do control:SetShown(prefix == "huge") end
            state.iconSwatch:SetColorTexture(db.hugeIconR, db.hugeIconG, db.hugeIconB, 1)
            state.frame:SetHeight(prefix == "huge" and 580 or 438)
            state.preview:ClearAllPoints(); state.preview:SetPoint("TOPLEFT", state.frame, "TOPLEFT", 14, prefix == "huge" and -439 or -310)
            state.reset:ClearAllPoints(); state.reset:SetPoint("TOPLEFT", state.frame, "TOPLEFT", 169, prefix == "huge" and -439 or -310)
            state.notice:ClearAllPoints(); state.notice:SetPoint("TOPLEFT", state.frame, "TOPLEFT", 14, prefix == "huge" and -483 or -348)
            state.notice:SetPoint("BOTTOMRIGHT", state.frame, "BOTTOMRIGHT", -14, 14)
            state.notice:SetTextColor(0.9, 0.9, 0.9, 1)
            SideAccent()
            state.layout:SetText("Layout: " .. (db[prefix .. "Layout"] == "strip" and "Name above progress" or "Name over progress"))
            state.colour:SetText("Progress: " .. (db[prefix .. "Colour"] == "accent" and "Accent colour" or "DBM category colours"))
            state.opacity:SetValue(db[prefix .. "Opacity"] * 100)
            state.opacityText:SetText("Background opacity: " .. math.floor(db[prefix .. "Opacity"] * 100 + 0.5) .. "%")
            local available = ns.IsEnabled(C.module) and db[prefix .. "Enabled"]
            for _, control in ipairs({state.layout, state.colour, state.opacity, state.border, state.glyphs}) do control:SetEnabled(available) end
            state.enabled:SetEnabled(ns.IsEnabled(C.module))
            state.reset:SetEnabled(ns.IsEnabled(C.module))
            state.iconScale:SetEnabled(available)
            state.iconAccent:SetEnabled(available and db.hugeGlyphs)
            local picker = _G.ColorPickerFrame
            state.iconCustom:SetEnabled(available and db.hugeGlyphs and not db.hugeIconAccent and picker ~= nil
                and type(picker.SetupColorPickerAndShow) == "function" and type(picker.GetColorRGB) == "function")
        end
        if frames then
            for _, control in ipairs({state.glyphs, state.iconScale, state.iconScaleText, state.iconAccent, state.iconCustom}) do control:Hide() end
            state.frame:SetHeight(438)
            state.reset:ClearAllPoints(); state.reset:SetPoint("TOPLEFT", state.frame, "TOPLEFT", 14, -310)
            state.reset:SetWidth(302)
            state.notice:ClearAllPoints(); state.notice:SetPoint("TOPLEFT", state.frame, "TOPLEFT", 14, -348)
            state.notice:SetPoint("BOTTOMRIGHT", state.frame, "BOTTOMRIGHT", -14, 14)
            state.reset:SetEnabled(ns.IsEnabled(C.module))
            SideAccent()
        else state.reset:SetWidth(147) end
        local r, g, b = ns.AccentBarColor(S)
        for key, button in pairs(state.tabs) do
            local label = button:GetFontString()
            if label then
                if key == prefix then label:SetTextColor(r, g, b, 1) else label:SetTextColor(0.8, 0.8, 0.8, 1) end
            end
        end
        state.updating = false
        PreviewState(state)
    end
    OpenSide = function()
        local state = C.dbmPreview
        if not state or not ns.IsEnabled(C.module) then return end
        if not state.frame then
            if InCombatLockdown and InCombatLockdown() then return end
            -- Created on first use, independent of DBM's timer-category APIs.
            local panel = CreateFrame("Frame", nil, UIParent)
            panel:SetSize(330, 438)
            panel:SetMovable(true)
            if panel.SetClampedToScreen then panel:SetClampedToScreen(true) end
            if panel.SetFrameStrata then panel:SetFrameStrata("DIALOG") end
            panel:EnableMouse(true)
            state.frame, state.selected, state.controls, state.labels = panel, "small", {}, {}
            local function Text(value, y, size)
                local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                label:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, y)
                label:SetWidth(302); label:SetJustifyH("LEFT"); label:SetText(value)
                if size then local path, flags = S.GetFont(); label:SetFont(path, size, flags or "") end
                state.labels[#state.labels + 1] = label
                return label
            end
            local function Button(text, x, y, width, click)
                local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
                button:SetSize(width, 26); button:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
                button:SetText(text); button:SetScript("OnClick", click)
                state.controls[#state.controls + 1] = {button, "Button"}
                return button
            end
            local function Check(text, key, y)
                local button = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
                button:SetSize(26, 26); button:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, y)
                button.Text = button.Text or button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                button.Text:ClearAllPoints(); button.Text:SetPoint("LEFT", button, "RIGHT", 4, 0)
                button.Text:SetWidth(270); button.Text:SetJustifyH("LEFT"); button.Text:SetText(text)
                button:SetScript("OnClick", function(self)
                    ChangeSetting(defaults[key] ~= nil and key or state.selected .. key, not not self:GetChecked())
                end)
                state.controls[#state.controls + 1] = {button, "Checkbox"}
                return button
            end
            state.title = Text("Options", -14, 14)
            local drag = CreateFrame("Frame", nil, panel)
            drag:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0); drag:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -40, 0); drag:SetHeight(36)
            drag:EnableMouse(true); drag:RegisterForDrag("LeftButton")
            drag:SetScript("OnDragStart", function()
                if not ns.IsEnabled(C.module) then return end
                state.dragging = true; panel:StartMoving()
            end)
            drag:SetScript("OnDragStop", function() SaveSidePosition(state) end)
            panel:SetScript("OnHide", function() if state.dragging then SaveSidePosition(state) end end)
            state.drag = drag
            PositionSide(state)
            state.close = Button("X", 292, -8, 26, function() panel:Hide() end)
            state.tabs = {
                small = Button("Small Bars", 14, -44, 96, function() state.selected = "small"; UpdateSide() end),
                huge = Button("Big Bars", 117, -44, 96, function() state.selected = "huge"; UpdateSide() end),
            }
            state.tabs.frames = Button("Frames", 220, -44, 96, function() state.selected = "frames"; UpdateSide() end)
            state.frameSliders = {}
            for i, entry in ipairs({{"rangeOpacity", "Text range background"}, {"radarOpacity", "Radar background"}, {"infoOpacity", "Info background"}}) do
                local key, text = entry[1], entry[2]
                local label = Text("", -100 - (i - 1) * 68)
                local slider = CreateFrame("Slider", nil, panel)
                slider:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -124 - (i - 1) * 68); slider:SetSize(294, 18)
                slider:EnableMouse(true); slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(0, 100); slider:SetValueStep(1)
                if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
                slider:SetThumbTexture(WHITE)
                slider:SetScript("OnValueChanged", function(_, value)
                    if state.updating or not ns.IsEnabled(C.module) then return end
                    ChangeSetting(key, math.floor(math.max(0, math.min(100, value)) + 0.5) / 100, true)
                end)
                state.frameSliders[#state.frameSliders + 1] = {slider = slider, label = label, key = key, text = text}
            end
            state.enabled = Check("Style bars", "Enabled", -80)
            state.layout = Button("", 14, -116, 302, function()
                local key = state.selected .. "Layout"
                ChangeSetting(key, Settings()[key] == "strip" and "fill" or "strip")
            end)
            state.colour = Button("", 14, -150, 302, function()
                local key = state.selected .. "Colour"
                ChangeSetting(key, Settings()[key] == "category" and "accent" or "category")
            end)
            state.opacityText = Text("", -190)
            state.opacity = CreateFrame("Slider", nil, panel)
            state.opacity:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -211); state.opacity:SetSize(294, 18)
            state.opacity:EnableMouse(true)
            state.opacity:SetOrientation("HORIZONTAL"); state.opacity:SetMinMaxValues(0, 100)
            state.opacity:SetValueStep(1)
            if state.opacity.SetObeyStepOnDrag then state.opacity:SetObeyStepOnDrag(true) end
            state.opacity:SetThumbTexture(WHITE)
            state.opacity:SetScript("OnValueChanged", function(_, value)
                if state.updating or not ns.IsEnabled(C.module) then return end
                ChangeSetting(state.selected .. "Opacity", math.floor(math.max(0, math.min(100, value)) + 0.5) / 100, true)
            end)
            state.border = Check("Accent border", "Border", -239)
            state.glyphs = Check("Use custom mechanic icons", "hugeGlyphs", -271)
            state.iconScaleText = Text("", -309)
            state.iconScale = CreateFrame("Slider", nil, panel)
            state.iconScale:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -330); state.iconScale:SetSize(294, 18)
            state.iconScale:EnableMouse(true); state.iconScale:SetOrientation("HORIZONTAL")
            state.iconScale:SetMinMaxValues(50, 250); state.iconScale:SetValueStep(5)
            if state.iconScale.SetObeyStepOnDrag then state.iconScale:SetObeyStepOnDrag(true) end
            state.iconScale:SetThumbTexture(WHITE)
            state.iconScale:SetScript("OnValueChanged", function(_, value)
                if state.updating or not ns.IsEnabled(C.module) then return end
                ChangeSetting("hugeIconScale", math.floor(math.max(50, math.min(250, value)) / 5 + 0.5) * 0.05, true)
            end)
            state.iconAccent = Check("Use accent colour", "hugeIconAccent", -359)
            state.iconCustom = Button("Choose icon colour", 14, -397, 302, function()
                local picker, db = _G.ColorPickerFrame, Settings()
                if not ns.IsEnabled(C.module) or db.hugeIconAccent or not db.hugeGlyphs or not db.hugeEnabled
                    or not picker or type(picker.SetupColorPickerAndShow) ~= "function" or type(picker.GetColorRGB) ~= "function" then return end
                local r, g, b = db.hugeIconR, db.hugeIconG, db.hugeIconB
                local session = {}; state.colourSession = session
                local function Save(red, green, blue)
                    if state.colourSession ~= session or not ns.IsEnabled(C.module) then return end
                    if type(red) ~= "number" or type(green) ~= "number" or type(blue) ~= "number" then return end
                    db.hugeIconR, db.hugeIconG, db.hugeIconB = math.max(0, math.min(1, red)), math.max(0, math.min(1, green)), math.max(0, math.min(1, blue))
                    H.Queue(state, RefreshBars); UpdateSide()
                end
                picker:SetupColorPickerAndShow({r = r, g = g, b = b, hasOpacity = false,
                    swatchFunc = function() Save(picker:GetColorRGB()) end,
                    cancelFunc = function() Save(r, g, b) end})
            end)
            local swatch = CreateFrame("Frame", nil, state.iconCustom)
            swatch:SetSize(16, 12); swatch:SetPoint("RIGHT", state.iconCustom, "RIGHT", -8, 0); swatch:EnableMouse(false)
            state.iconSwatch = swatch:CreateTexture(nil, "OVERLAY"); state.iconSwatch:SetAllPoints(swatch)

            state.preview = Button("Preview DBM bars", 14, -310, 147, RunPreview)
            state.preview:SetScript("OnShow", function() PreviewState(state) end)
            state.reset = Button("Reset styling", 169, -310, 147, function()
                if not ns.IsEnabled(C.module) then return end
                local db = Settings()
                state.colourSession = nil
                for key, value in pairs(defaults) do db[key] = value end
                RefreshBars(); RefreshAux(); UpdateSide(); SyncLayoutControls()
            end)
            state.notice = Text("", -348, 14)
            state.notice:SetHeight(72); state.notice:SetWordWrap(true); state.notice:SetJustifyV("TOP")
            if state.notice.SetSpacing then state.notice:SetSpacing(2) end
            panel:SetScript("OnShow", UpdateSide)
            S.Shell(panel, {noAccent = true, noTopBar = true})
        else state.frame:SetShown(not state.frame:IsShown()) end
        UpdateSide()
        -- Style owned controls explicitly; the generic scanner never enters here.
        for _, entry in ipairs(state.controls) do Control(C, entry[1], entry[2]); Font(entry[1].Text or entry[1]:GetFontString()) end
        for _, label in ipairs(state.labels) do Font(label) end
        for _, entry in ipairs(state.frameSliders) do
            H.LegacySlider(entry.slider)
            local thumb = entry.slider:GetThumbTexture(); if thumb then thumb:SetSize(10, 14) end
        end
        for _, slider in ipairs({state.opacity, state.iconScale}) do
            H.LegacySlider(slider)
            local thumb = slider:GetThumbTexture()
            if thumb then thumb:SetSize(10, 14) end
        end
        UpdateSide()
    end
    local function PreviewButton()
        local frame = Window()
        if not Allowed(frame) then return end
        local state = C.dbmPreview
        if not state then
            local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
            button:SetSize(160, 26)
            button:SetPoint("TOPLEFT", frame, "TOPRIGHT", 8, 0)
            button:SetText("Skin Options")
            button:SetScript("OnClick", OpenSide)
            state = {button = button}; C.dbmPreview = state
            button:SetScript("OnShow", function() button:SetEnabled(ns.IsEnabled(C.module)); UpdateSide(); SideAccent() end)
            S.Button(button)
            H.Script(button, "OnEnter", SideAccent); H.Script(button, "OnLeave", SideAccent); H.Script(button, "OnEnable", SideAccent)
            -- Detached positions last only until the main DBM window reopens.
            -- Use a separate hook: the scoped skin already owns its OnShow callback.
            Settings().optionsPosition = nil
            frame:HookScript("OnShow", function()
                state.position, state.dragging = nil, nil
                if state.frame then
                    state.frame:StopMovingOrSizing()
                    PositionSide(state)
                end
            end)
        end
        state.button:SetEnabled(ns.IsEnabled(C.module))
        Font(state.button:GetFontString())
        SideAccent()
        if state.frame then
            for _, entry in ipairs(state.frameSliders) do
                H.LegacySlider(entry.slider)
                local thumb = entry.slider:GetThumbTexture(); if thumb then thumb:SetSize(10, 14) end
            end
            for _, entry in ipairs(state.controls) do Control(C, entry[1], entry[2]); Font(entry[1].Text or entry[1]:GetFontString()) end
            for _, label in ipairs(state.labels) do Font(label) end
            for _, slider in ipairs({state.opacity, state.iconScale}) do
                H.LegacySlider(slider)
                local thumb = slider:GetThumbTexture()
                if thumb then thumb:SetSize(10, 14) end
            end
            UpdateSide()
        end
    end
    local function SettingsPanel()
        local gui = _G.DBM_GUI
        local category = type(gui) == "table" and gui.Cat_Timers
        if not category or type(category.CreateNewPanel) ~= "function" or type(category.CreateArea) ~= "function"
            or type(category.CreateDropdown) ~= "function" or type(category.CreateButton) ~= "function" or type(category.CreateText) ~= "function" then return end
        local state = C.dbmSettings
        if not state then
            local page = category:CreateNewPanel("AddonSkins", "option")
            if not page or not Allowed(page.frame) then return end
            state = {page = page, frame = page.frame, controls = {}, menuDirty = true}
            C.dbmSettings = state
            local area = page:CreateArea("Timer layouts")
            state.area = area.frame
            local values = {{text = "Name above progress", value = "strip"}, {text = "Name over progress", value = "fill"}}
            local binding = {Options = Settings()}
            local function Dropdown(title, key, y)
                local control = area:CreateDropdown(title, values, binding, key, function(value)
                    if value ~= "strip" and value ~= "fill" then return end
                    local db = Settings()
                    if db[key] == value then return end
                    db[key] = value
                    RefreshBars()
                    PreviewState(state)
                    UpdateSide()
                end, 220)
                control:SetPoint("TOPLEFT", area.frame, "TOPLEFT", 20, y)
                control.myheight = 78
                state.controls[#state.controls + 1] = control
                return control
            end
            state.small = Dropdown("Small Bars", "smallLayout", -40)
            state.huge = Dropdown("Big Bars", "hugeLayout", -108)
            state.preview = area:CreateButton("Preview DBM bars", 180, 24, RunPreview)
            state.preview:SetPoint("TOPLEFT", area.frame, "TOPLEFT", 20, -166)
            state.preview.myheight = 40
            state.controls[#state.controls + 1] = state.preview
            state.notice = area:CreateText("", 440, false, GameFontHighlightSmall, "LEFT", 62)
            state.notice:SetPoint("TOPLEFT", area.frame, "TOPLEFT", 20, -206)
            H.Script(page.frame, "OnShow", function() PreviewState(state) end)
        end
        if not state.styled then
            C.Panel(state.area)
            state.styled = true
        end
        Control(C, state.small, "Dropdown"); Control(C, state.huge, "Dropdown"); Control(C, state.preview, "Button")
        -- Owned controls are excluded from the generic GUI scanner. Updating a
        -- selector repaints bars directly, without an extra window traversal.
        for _, frame in ipairs(state.controls) do
            for _, region in ipairs(H.Regions(frame)) do if region:GetObjectType() == "FontString" then Font(region) end end
        end
        for _, region in ipairs(H.Regions(state.area)) do if region:GetObjectType() == "FontString" then Font(region) end end
        Font(state.notice)
        PreviewState(state)
        if state.menuDirty then
            -- The GUI can already be open when its ADDON_LOADED callback runs.
            -- Refresh its category list once, after control construction ends.
            H.Queue(state, function()
                if InCombatLockdown and InCombatLockdown() then pending = true; return end
                state.menuDirty = false
                local frame = Window()
                if frame and type(frame.UpdateMenuFrame) == "function" and (not frame.IsShown or frame:IsShown()) then frame:UpdateMenuFrame() end
            end)
        end
    end
    -- Small encounter windows have their own lifecycle. Never scan their
    -- children or attach work to radar/encounter Update or OnUpdate paths.
    local auxiliary, InfoSpacing = {}, nil
    local function PublicWidth(text)
        if not Allowed(text) or not text.GetStringWidth then return 0 end
        local ok, width = pcall(text.GetStringWidth, text)
        if not ok or issecretvalue and issecretvalue(width) or type(width) ~= "number" then return 0 end
        return width
    end
    local function AuxGeometry(f, d)
        if not d.styled or not Allowed(f) then return end
        local width, top = f:GetWidth() + 16, 24
        for text in pairs(d.headers) do
            width = math.max(width, PublicWidth(text) + 16)
            if text.GetHeight then top = math.max(top, text:GetHeight() + 16) end
        end
        local bottom = 8
        local footer = f.inRangeText
        if d.kind ~= "info" and Allowed(footer) and footer:IsShown() then bottom = footer:GetHeight() + 8 end
        if d.kind == "info" then bottom = bottom + (d.extraHeight or 0) end
        local left = d.kind == "radar" and -(width - f:GetWidth()) / 2 or -8
        if d.width ~= width or d.top ~= top or d.bottom ~= bottom or d.left ~= left then
            d.width, d.top, d.bottom, d.left = width, top, bottom, left
            d.layer:ClearAllPoints()
            d.layer:SetPoint("TOPLEFT", f, "TOPLEFT", left, top)
            d.layer:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", left, -bottom)
            d.layer:SetWidth(width)
        end
    end
    local function RangeHeader(text, d)
        if d.formatting or not d.styled or not Allowed(d.frame) or not Allowed(text) or not ns.IsEnabled(C.module) then return end
        local value = text:GetText()
        if issecretvalue and issecretvalue(value) or type(value) ~= "string" then return end
        -- Leave localized/reverse headers and unknown formats verbatim.
        local range, players = value:match("^Range:%s*(%d+)%s+Players:%s*(%d+)$")
        if range then
            d.nativeHeader, d.formattedHeader = value, "Range: " .. range .. " · Players: " .. players
            d.formatting = true; text:SetText(d.formattedHeader); d.formatting = false
        elseif value ~= d.formattedHeader then d.nativeHeader, d.formattedHeader = nil, nil end
        AuxGeometry(d.frame, d)
    end
    local function PublicColour(r, g, b, a)
        if issecretvalue and (issecretvalue(r) or issecretvalue(g) or issecretvalue(b) or issecretvalue(a)) then return false end
        return type(r) == "number" and type(g) == "number" and type(b) == "number" and (a == nil or type(a) == "number")
    end
    local function HeadingColour(text, d)
        if d.paintingHeading or d.paintingFont or not d.styled or not Allowed(d.frame) or not Allowed(text) or not ns.IsEnabled(C.module) then return end
        if InCombatLockdown and InCombatLockdown() then pending = true; return end
        local colour = d.headingColours[text]
        if not colour then
            local r, g, b, a = text:GetTextColor()
            if not PublicColour(r, g, b, a) then return end
            colour = {r, g, b, a or 1}; d.headingColours[text] = colour
        end
        local r, g, b, a = colour[1], colour[2], colour[3], colour[4]
        local value = text:GetText()
        local secretText = issecretvalue and issecretvalue(value)
        -- Accent only neutral white. Native warning colours and embedded colour
        -- codes win; never inspect or rewrite a secret encounter title.
        if not secretText and type(value) == "string" and not value:find("|c", 1, true) and not value:find("|r", 1, true)
            and r == 1 and g == 1 and b == 1 then r, g, b = ns.AccentBarColor(S) end
        local cr, cg, cb, ca = text:GetTextColor()
        if not PublicColour(cr, cg, cb, ca) then return end
        if cr ~= r or cg ~= g or cb ~= b or ca ~= a then
            d.paintingHeading = true; text:SetTextColor(r, g, b, a); d.paintingHeading = false
        end
    end
    local function Header(text, d)
        if d.headers[text] then HeadingColour(text, d); return end
        if not text.GetNumPoints or text:GetNumPoints() == 0 then return end
        local point, relative, relativePoint = text:GetPoint(1)
        if point ~= "BOTTOMLEFT" or relative ~= d.frame or relativePoint ~= "TOPLEFT" then return end
        d.headers[text] = {text:GetPoint(1)}
        text:ClearAllPoints(); text:SetPoint("TOPLEFT", d.layer, "TOPLEFT", 8, -8)
        H.Hook(text, "SetText", function()
            if not Allowed(d.frame) or not Allowed(text) or not ns.IsEnabled(C.module) then return end
            if InCombatLockdown and InCombatLockdown() then pending = true; return end
            if d.kind == "info" then AuxGeometry(d.frame, d) else RangeHeader(text, d) end
            HeadingColour(text, d)
        end)
        H.Hook(text, "SetTextColor", function(_, r, g, b, a)
            if d.paintingHeading or d.paintingFont or not d.headers[text] then return end
            if not PublicColour(r, g, b, a) then d.headingColours[text] = nil; return end
            d.headingColours[text] = {r, g, b, a or 1}
            HeadingColour(text, d)
        end)
        if d.kind ~= "info" then RangeHeader(text, d) end
        HeadingColour(text, d)
    end
    local function AuxEnabled()
        if not ns.IsEnabled(C.module) then return false end
        if InCombatLockdown and InCombatLockdown() then pending = true; return false end
        return true
    end
    local function AuxFont(text, d)
        if not Allowed(d.frame) or not Allowed(text) or not text.GetFont then return end
        local state = d.fonts[text]
        if not state then
            state = {font = {text:GetFont()},
                shadowColor = text.GetShadowColor and {text:GetShadowColor()},
                shadowOffset = text.GetShadowOffset and {text:GetShadowOffset()}}
            d.fonts[text] = state
        end
        local function PaintFont()
            if d.paintingFont or not d.styled or not Allowed(d.frame) or not Allowed(text) or not AuxEnabled() then return end
            d.paintingFont = true
            local ok, err = pcall(S.Font, text)
            d.paintingFont = false
            if not ok then error(err) end
        end
        if not d.fontHooks[text] then
            d.fontHooks[text] = true
            H.Hook(text, "SetFont", function(_, path, size, flags)
                if d.paintingFont then return end
                local native = d.fonts[text]
                if native then native.font[1], native.font[2], native.font[3] = path, size, flags end
                PaintFont()
            end)
            H.Hook(text, "SetFontObject", function(_, object)
                if d.paintingFont then return end
                local native = d.fonts[text]
                if native then
                    native.font[1], native.font[2], native.font[3] = text:GetFont()
                    native.shadowColor = text.GetShadowColor and {text:GetShadowColor()}
                    native.shadowOffset = text.GetShadowOffset and {text:GetShadowOffset()}
                end
                PaintFont()
            end)
        end
        PaintFont() -- Keep native sizes and semantic colours.
        Header(text, d)
    end
    local function DiscoverAux(f, d, force)
        local count = f.GetNumRegions and f:GetNumRegions()
        if not force and count and d.regionCount == count then return end
        d.regionCount = count
        for _, region in ipairs(H.Regions(f)) do
            if region:GetObjectType() == "FontString" then AuxFont(region, d) end
        end
    end
    local function AuxMouse(f, layer, d)
        if not f.GetScript then return end
        -- The backdrop extends beyond DBM's original hit rectangle. Let those
        -- margins forward input to the native owner; the higher-level native
        -- frame still handles its original body and any controls normally.
        layer:EnableMouse(true)
        layer:RegisterForDrag("LeftButton")
        local function Forward(script, ...)
            if not d.styled or not ns.IsEnabled(C.module) or not Allowed(f) or not layer:IsShown() then return end
            local handler = f:GetScript(script)
            if handler then return handler(f, ...) end
        end
        local function StopDrag(...)
            if not d.dragging then return end
            d.dragging = nil
            if not Allowed(f) then return end
            local handler = f:GetScript("OnDragStop")
            if handler then return handler(f, ...) end
            if f.StopMovingOrSizing then f:StopMovingOrSizing() end
        end
        layer:SetScript("OnMouseDown", function(_, ...) return Forward("OnMouseDown", ...) end)
        layer:SetScript("OnMouseUp", function(_, ...) return Forward("OnMouseUp", ...) end)
        layer:SetScript("OnDragStart", function(_, ...)
            if not d.styled or not ns.IsEnabled(C.module) or not Allowed(f) or not layer:IsShown() then return end
            if f:GetScript("OnDragStart") then d.dragging = true; return Forward("OnDragStart", ...) end
        end)
        layer:SetScript("OnDragStop", function(_, ...) return StopDrag(...) end)
        -- Closing/disabling during a drag must still run native stop/save logic.
        layer:SetScript("OnHide", function() StopDrag() end)
    end
    local function PaintAux(f, kind, force)
        if not Allowed(f) or not AuxEnabled() or not S.Panel then return end
        local d = auxiliary[f]
        if not d then
            d = {fonts = {}, fontHooks = {}, headers = {}, headingColours = {}, rowPoints = {}, frame = f, kind = kind}; auxiliary[f] = d
            local layer = CreateFrame("Frame", nil, f)
            layer:EnableMouse(false)
            if layer.SetFrameLevel and f.GetFrameLevel then layer:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1)) end
            -- Strip-only EUI panel: opacity must not reveal an opaque Shell
            -- atlas/gradient beneath our independently controlled matte fill.
            S.Panel(layer, {noBg = true, noBorder = true})
            d.layer = layer
            AuxMouse(f, layer, d)
            d.fill = layer:CreateTexture(nil, "BACKGROUND", nil, 7); d.fill:SetAllPoints(layer)
            if d.fill.SetIgnoreParentAlpha then d.fill:SetIgnoreParentAlpha(true) end
            d.edges = {}
            for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
                local edge = layer:CreateTexture(nil, "BORDER")
                if side == "TOP" or side == "BOTTOM" then
                    edge:SetPoint(side .. "LEFT", layer, side .. "LEFT"); edge:SetPoint(side .. "RIGHT", layer, side .. "RIGHT"); edge:SetHeight(1)
                else
                    edge:SetPoint("TOP" .. side, layer, "TOP" .. side); edge:SetPoint("BOTTOM" .. side, layer, "BOTTOM" .. side); edge:SetWidth(1)
                end
                d.edges[#d.edges + 1] = edge
            end
            if kind == "radar" and H.Texture(f.circle) then
                d.circle = {region = f.circle, texture = f.circle:GetTexture(), blend = f.circle:GetBlendMode()}
                for _, texture in ipairs(H.Regions(f)) do
                    if H.Texture(texture) and (texture:GetTexture() == 136431 or texture:GetTexture() == "Interface\\Minimap\\MinimapArrow.blp") then
                        d.arrow = {region = texture, width = texture:GetWidth(), height = texture:GetHeight(), blend = texture:GetBlendMode()}
                        break
                    end
                end
            end
            if f.GetBackdrop then d.backdrop = f:GetBackdrop() end
            if kind == "radar" and H.Texture(f.background) then
                d.background = f.background; d.backgroundAlpha = f.background:GetAlpha()
            end
            H.Hook(f, "SetSize", function() if AuxEnabled() then AuxGeometry(f, d) end end)
            H.Script(f, "OnShow", function() PaintAux(f, kind, true) end)
            H.Hook(f, "SetBackdrop", function(_, value)
                if d.settingBackdrop then return end
                d.backdrop = value
                if Allowed(f) and AuxEnabled() then
                    d.settingBackdrop = true; f:SetBackdrop(nil); d.settingBackdrop = nil
                end
            end)
            if ns.BindPopupOwner then ns.BindPopupOwner(S, C.module, f) end
        end
        if Allowed(f.inRangeText) and d.footer ~= f.inRangeText then
            d.footer = f.inRangeText
            for _, method in ipairs({"Show", "Hide"}) do H.Hook(f.inRangeText, method, function()
                if AuxEnabled() then AuxGeometry(f, d) end
            end) end
        end
        local wasStyled = d.styled
        d.styled = true
        if f.SetBackdrop then
            d.settingBackdrop = true; f:SetBackdrop(nil); d.settingBackdrop = nil
        end
        if d.background then d.background:SetAlpha(0) end
        if d.circle then
            d.circle.region:SetTexture("Interface\\AddOns\\EUIAddonSkins\\Media\\DBMRadar.tga")
            d.circle.region:SetBlendMode("BLEND")
        end
        if d.arrow then
            d.arrow.region:SetBlendMode("BLEND"); d.arrow.region:SetSize(18, 18)
        end
        local r, g, b = PanelColor(S)
        local alpha = Settings()[kind == "radar" and "radarOpacity" or kind == "info" and "infoOpacity" or "rangeOpacity"]
        d.fill:SetColorTexture(r, g, b, alpha)
        for _, edge in ipairs(d.edges) do edge:SetColorTexture(0, 0, 0, alpha * 0.35) end
        d.layer:Show()
        DiscoverAux(f, d, force)
        if not wasStyled and not d.direct then
            for index, perColumn in pairs(d.spacing or {}) do InfoSpacing(nil, index, perColumn) end
        end
        AuxGeometry(f, d)
    end
    local function RestoreAux()
        for f, d in pairs(auxiliary) do
            if d.styled and Allowed(f) then
                d.styled = false; d.layer:Hide()
                if f.SetBackdrop then
                    d.settingBackdrop = true; f:SetBackdrop(d.backdrop); d.settingBackdrop = nil
                end
                if d.background then d.background:SetAlpha(d.backgroundAlpha) end
                if d.circle then d.circle.region:SetTexture(d.circle.texture); d.circle.region:SetBlendMode(d.circle.blend) end
                if d.arrow then d.arrow.region:SetSize(d.arrow.width, d.arrow.height); d.arrow.region:SetBlendMode(d.arrow.blend) end
                for text, point in pairs(d.headers) do
                    local colour = d.headingColours[text]
                    if colour then text:SetTextColor(unpack(colour)) end
                    text:ClearAllPoints(); text:SetPoint(unpack(point))
                    if d.formattedHeader then
                        local value = text:GetText()
                        if not (issecretvalue and issecretvalue(value)) and value == d.formattedHeader then text:SetText(d.nativeHeader) end
                    end
                end
                for text, point in pairs(d.rowPoints) do text:ClearAllPoints(); text:SetPoint(unpack(point)) end
                d.headers, d.headingColours, d.rowPoints, d.width = {}, {}, {}, nil
                -- Restore fonts only: DBM may have resized/reanchored rows or
                -- changed semantic colours since their first appearance.
                for text, state in pairs(d.fonts) do
                    if Allowed(text) then
                        local r, g, b, a = text:GetTextColor()
                        if state.font[1] then text:SetFont(unpack(state.font)) end
                        if state.shadowColor then text:SetShadowColor(unpack(state.shadowColor)) end
                        if state.shadowOffset then text:SetShadowOffset(unpack(state.shadowOffset)) end
                        text:SetTextColor(r, g, b, a)
                    end
                end
                d.fonts, d.regionCount = {}, nil
            end
        end
    end
    RefreshAux = function(force)
        if not ns.IsEnabled(C.module) then RestoreAux(); return end
        PaintAux(_G.DBMRangeCheck, "range", force == true)
        PaintAux(_G.DBMRangeCheckRadar, "radar", force == true)
        PaintAux(_G.DBMInfoFrame, "info", force == true)
    end
    local function NewInfoRegions()
        local f = _G.DBMInfoFrame
        if not Allowed(f) or not AuxEnabled() then return end
        local d = auxiliary[f]
        if not d then PaintAux(f, "info", true)
        else DiscoverAux(f, d, false) end
    end
    InfoSpacing = function(_, index, perColumn)
        local f = _G.DBMInfoFrame
        local d = auxiliary[f]
        if issecretvalue and (issecretvalue(index) or issecretvalue(perColumn)) then return end
        if not d or not Allowed(f) or not AuxEnabled() or type(index) ~= "number" or type(perColumn) ~= "number"
            or perColumn < 2 or not f.lines then return end
        local text = f.lines[index]
        if not Allowed(text) or text.IsShown and not text:IsShown() then return end
        d.spacing = d.spacing or {}; d.spacing[index] = perColumn; d.direct = false
        local point = {text:GetPoint(1)}
        if not point[1] then return end
        d.rowPoints[text] = point
        local x, y = point[4] or 0, point[5] or 0
        if index == 1 then x, y = 0, -8
        elseif index % 2 == 0 then x = math.max(12, x + 4)
        elseif index % perColumn ~= 1 then y = y - 2 end
        text:ClearAllPoints(); text:SetPoint(point[1], point[2], point[3], x, y)
        d.extraHeight = math.max(0, math.min(#f.lines / 2, perColumn / 2) - 1) * 2 + 2
        AuxGeometry(f, d)
    end
    local function BindAux()
        local dbm = _G.DBM
        H.Hook(dbm and dbm.RangeCheck, "Show", RefreshAux)
        local info = dbm and dbm.InfoFrame
        H.Hook(info, "AlignLine", InfoSpacing)
        H.Hook(info, "ShowDirect", function()
            local d = auxiliary[_G.DBMInfoFrame]
            if d then d.extraHeight, d.direct = 0, true end -- Direct layouts keep their own row geometry.
            RefreshAux()
        end)
        for _, method in ipairs({"Show", "UpdateStyle"}) do H.Hook(info, method, RefreshAux) end
        -- These setters can allocate new row/header FontStrings. A region-count
        -- guard makes ordinary value updates constant work without text reads.
        for _, method in ipairs({"SetLine", "SetHeader", "SetDirectLine", "UpdateDirect", "SetDirectHeader"}) do
            H.Hook(info, method, NewInfoRegions)
        end
        RefreshAux(true)
    end
    local function Refresh()
        if not ns.IsEnabled(C.module) then RestoreAux(); return end
        if InCombatLockdown and InCombatLockdown() then pending = true; return end
        pending = false
        BindAux()
        local dbt = _G.DBT
        if type(dbt) == "table" then
            H.Hook(dbt, "CreateBar", function(self, _, id)
                if self.GetBar then BindBar(self:GetBar(id)) end
            end)
        end
        RefreshBars()
        PreviewButton()
        SettingsPanel()
        local auras = _G.DBM and _G.DBM.Auras
        for _, method in ipairs({"PreviewToggle", "OnSettingsChange", "UpdateAuraAnchors", "RegisterAllUnits"}) do
            H.Hook(auras, method, PaintAuras)
        end
        H.Hook(_G.DBM, "UpdateWarningOptions", PaintWarnings)
        H.Hook(_G.DBM, "UpdateSpecialWarningOptions", PaintWarnings)
        PaintWarnings()
        PaintAuras()
    end
    local events = CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED"); events:RegisterEvent("PLAYER_REGEN_ENABLED"); events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            if C.dbmSettings then PreviewState(C.dbmSettings) end
            if C.dbmPreview then PreviewState(C.dbmPreview) end
        elseif event == "ADDON_LOADED" or pending or event == "PLAYER_REGEN_ENABLED" and (C.dbmSettings or C.dbmPreview) then H.Queue(events, Refresh) end
    end)
    if S.OnLooksChanged then S.OnLooksChanged(Refresh) end
    C.dbmHUD = Refresh
    return Refresh
end
local nativeTabs = setmetatable({}, {__mode = "k"})
local fontPaints = setmetatable({}, {__mode = "k"})
local fontStates = setmetatable({}, {__mode = "k"})
local fontGeneration = 0
local function ApplyFont(S, text, r, g, b)
    local state = fontStates[text]
    if not state then state = {}; fontStates[text] = state end
    if state.painting then return end
    local path, size, flags = text:GetFont()
    if issecretvalue and (issecretvalue(path) or issecretvalue(size) or issecretvalue(flags)) then return end
    local target, targetFlags
    if S.GetFont then target, targetFlags = S.GetFont() end
    if not fontPaints[text] or state.generation ~= fontGeneration or state.path ~= path or state.size ~= size or state.flags ~= flags
        or state.target ~= target or state.targetFlags ~= targetFlags then
        -- EUI primes a FontObject shadow before SetFont. Guard that entire
        -- primitive, so our native-font hooks cannot re-enter it halfway through.
        state.painting = true
        local cr, cg, cb, ca
        if r == nil and text.GetTextColor then cr, cg, cb, ca = text:GetTextColor() end
        local ok, err = pcall(S.Font, text, r, g, b)
        state.painting = false
        if not ok then error(err) end
        if cr ~= nil and not (issecretvalue and (issecretvalue(cr) or issecretvalue(cg) or issecretvalue(cb) or issecretvalue(ca))) then
            text:SetTextColor(cr, cg, cb, ca)
        end
        state.path, state.size, state.flags = text:GetFont()
        state.target, state.targetFlags, state.generation = target, targetFlags, fontGeneration
    elseif r ~= nil and text.SetTextColor then text:SetTextColor(r, g, b or r) end
end
local textTones = setmetatable({}, {__mode = "k"})
local function TextTone(C, text, role, owner)
    if C.H.Allowed(text) then
        local tone = textTones[text]
        if not tone then tone = {}; textTones[text] = tone end
        tone.role, tone.owner = role, owner
    end
end
local function PaintTone(text, html)
    local tone = textTones[text]
    if not tone or not text.SetTextColor then return end
    local role, owner = tone.role, tone.owner
    local value = role == "muted" and 0.6 or role == "heading" and 0.95 or 0.88
    if owner and owner.IsEnabled and not owner:IsEnabled() then value = 0.5 end
    local r, g, b, a
    if text.GetTextColor then
        if html then r, g, b, a = text:GetTextColor("p") else r, g, b, a = text:GetTextColor() end
    end
    if issecretvalue and (issecretvalue(r) or issecretvalue(g) or issecretvalue(b) or issecretvalue(a)) then return end
    if r ~= value or g ~= value or b ~= value or a ~= 1 then
        if html then text:SetTextColor("p", value, value, value, 1) else text:SetTextColor(value, value, value, 1) end
    end
end
PanelColor = function(S)
    if S.GetPanelColor then return S.GetPanelColor() end
    return 0.055, 0.055, 0.06, 0.98
end
Control = function(C, f, method)
    C.dbmControls = C.dbmControls or setmetatable({}, {__mode = "k"})
    local d = C.dbmControls[f]
    if not d then
        d = {}; C.dbmControls[f] = d
        local before = {}
        for _, region in ipairs(C.H.Regions(f)) do before[region] = true end
        if method == "EditBox" then C.S.EditBox(f, {padInput = not (f:GetParent() and f:GetParent().mytype == "slider")})
        else C.S[method](f, method == "Checkbox" and {borderInset = 4, hover = 0.05} or nil) end
        if method == "Button" and C.S.StateButtonLabel then C.S.StateButtonLabel(f) end
        for _, region in ipairs(C.H.Regions(f)) do
            if not before[region] and C.H.Texture(region) then
                if region.GetDrawLayer and region:GetDrawLayer() == "BACKGROUND" then d.fill = region end
                if method == "Dropdown" and region.GetAtlas and region:GetAtlas() == "Azerite-PointingArrow" then d.arrow = region end
            end
        end
        if method == "Dropdown" then
            if C.H.Texture(f.Arrow) then C.H.Fade(f.Arrow) end
            local name = f.GetName and f:GetName()
            local button = f.Button or f.button or name and _G[name .. "Button"]
            if C.H.Allowed(button) then
                for _, region in ipairs(C.H.Regions(button)) do if C.H.Texture(region) then C.H.Fade(region) end end
            end
            C.MenuOwner(f)
            if not d.arrow then d.arrow = f:CreateTexture(nil, "OVERLAY") end
            d.arrow:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png")
            d.arrow:SetSize(12, 8); d.arrow:ClearAllPoints(); d.arrow:SetPoint("RIGHT", f, "RIGHT", -8, 0)
            d.arrow:SetVertexColor(0.8, 0.8, 0.8, 1)
        end
    end
    if d.fill and method ~= "Checkbox" then
        local r, g, b = PanelColor(C.S)
        if d.r ~= r or d.g ~= g or d.b ~= b or d.generation ~= fontGeneration then
            d.fill:SetColorTexture(math.min(1, r + 0.025), math.min(1, g + 0.025), math.min(1, b + 0.025), 1)
            d.r, d.g, d.b, d.generation = r, g, b, fontGeneration
        end
    end
    if method == "Checkbox" then
        local r, g, b = C.S.GetAccentColor()
        for i, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
            local mark = f[getter] and f[getter](f)
            if C.H.Texture(mark) and (d[getter] ~= mark or d.r ~= r or d.g ~= g or d.b ~= b or d.generation ~= fontGeneration) then
                -- EUI's own option checkboxes use an inset solid accent square.
                -- Reuse the native checked regions so checked/disabled visibility
                -- remains controlled entirely by WoW and DBM.
                mark:SetVertexColor(1, 1, 1, 1)
                if i == 1 then mark:SetColorTexture(r, g, b, 1) else mark:SetColorTexture(0.4, 0.4, 0.4, 0.8) end
                mark:ClearAllPoints(); mark:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -6); mark:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 6)
                d[getter] = mark
            end
        end
        d.r, d.g, d.b, d.generation = r, g, b, fontGeneration
        TextTone(C, f.textObj, "label", f)
    end
    local label = f.Text or (f.GetFontString and f:GetFontString())
    TextTone(C, label, "label", f)
    PaintTone(label)
    local name = f.GetName and f:GetName()
    if method == "Dropdown" and name then
        TextTone(C, _G[name .. "TitleText"], "label"); PaintTone(_G[name .. "TitleText"])
    end
    return d
end
local function Slider(C, f)
    local H, S = C.H, C.S
    local vertical = f.GetOrientation and f:GetOrientation() == "VERTICAL"
    if vertical then
        C.dbmArrows = C.dbmArrows or {}
        local name = f.GetName and f:GetName()
        for i, button in ipairs({f.ScrollUpButton or name and _G[name .. "ScrollUpButton"], f.ScrollDownButton or name and _G[name .. "ScrollDownButton"]}) do
            if H.Allowed(button) and not C.dbmArrows[button] then
                (S.SoftPageButton or S.PageButton)(button, i == 1 and "^" or "v")
                for _, region in ipairs(H.Regions(button)) do if region:GetObjectType() == "FontString" then H.Fade(region) end end
                local arrow = button:CreateTexture(nil, "OVERLAY")
                arrow:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-" .. (i == 1 and "up3.png" or "down3.png"))
                arrow:SetSize(10, 7); arrow:SetPoint("CENTER"); arrow:SetVertexColor(0.8, 0.8, 0.8, 1)
                C.dbmArrows[button] = arrow
            end
        end
    end
    H.LegacySlider(f)
    local thumb = f.GetThumbTexture and f:GetThumbTexture()
    if H.Texture(thumb) then thumb:SetSize(vertical and 5 or 10, vertical and 22 or 14) end
    TextTone(C, f.textFrame, "label")
end
local function Fonts(C, f, kind)
    local H, S = C.H, C.S
    local function Bind(text, html)
        if fontPaints[text] then fontPaints[text](); return end
        local painting, generation = false, nil
        local function Paint()
            if painting or fontStates[text] and fontStates[text].painting then return end
            if InCombatLockdown and InCombatLockdown() then C.module.refresh(); return end
            painting = true
            H.Safe(function()
                if html and S.GetFont then
                    local path, size, flags = text:GetFont("p")
                    if issecretvalue and (issecretvalue(path) or issecretvalue(size) or issecretvalue(flags)) then return end
                    local target, targetFlags = S.GetFont()
                    if generation ~= fontGeneration or path ~= target or (flags or "") ~= (targetFlags or "") then
                        text:SetFont("p", target, size or 12, targetFlags or "")
                        generation = fontGeneration
                    end
                elseif not html then H.Font(text) end
                PaintTone(text, html)
            end)
            painting = false
        end
        fontPaints[text] = Paint
        Paint()
        H.Hook(text, "SetFontObject", function()
            if painting or fontStates[text] and fontStates[text].painting then return end
            if fontStates[text] then fontStates[text].generation = nil end
            generation = nil; Paint()
        end)
        H.Hook(text, "SetFont", Paint)
        H.Hook(text, "SetTextColor", Paint)
    end
    if kind == "SimpleHTML" then Bind(f, true); return true end
    for _, text in ipairs(H.Regions(f)) do
        if H.Allowed(text) and text:GetObjectType() == "FontString" then
            local name = text.GetName and text:GetName()
            if name and name:match("HeaderText$") then TextTone(C, text, "heading") end
            Bind(text, false)
        end
    end
end
local function GUIExclude(C)
    if not C.dbmExclude then
        C.dbmExclude = setmetatable({}, {__index = function(_, child)
            return child:GetObjectType() == "ScrollingMessageFrame" or child.mytype == "modelframe"
                or child.mytype == "panel" and child.IsShown and not child:IsShown()
        end})
        C.dbmChromeExclude = setmetatable({}, {__index = function(_, child)
            return child.mytype == "panel" or C.dbmExclude[child]
        end})
    end
    local f = Window()
    if f and f.searchHighlightFrame then C.dbmExclude[f.searchHighlightFrame] = true end
    if C.dbmSettings then C.dbmExclude[C.dbmSettings.frame] = true end
    if C.dbmPreview then
        C.dbmExclude[C.dbmPreview.button] = true
        if C.dbmPreview.frame then C.dbmExclude[C.dbmPreview.frame] = true end
    end
    if C.dbmMatte then C.dbmExclude[C.dbmMatte] = true end
    return C.dbmExclude
end
local function Chrome(C)
    local f, H = Window(), C.H
    local exclude = GUIExclude(C)
    if H.Allowed(f) then
        if not C.dbmMatte then
            local layer = CreateFrame("Frame", nil, f); layer:SetAllPoints(f)
            if layer.SetFrameLevel and f.GetFrameLevel then layer:SetFrameLevel(f:GetFrameLevel()) end
            layer:EnableMouse(false)
            C.dbmMatte = layer; exclude[layer] = true
            C.dbmMatteFill = layer:CreateTexture(nil, "BACKGROUND"); C.dbmMatteFill:SetAllPoints(layer)
        end
        local r, g, b, a = PanelColor(C.S)
        if C.dbmMatteR ~= r or C.dbmMatteG ~= g or C.dbmMatteB ~= b or C.dbmMatteA ~= a then
            C.dbmMatteFill:SetColorTexture(r, g, b, a)
            C.dbmMatteR, C.dbmMatteG, C.dbmMatteB, C.dbmMatteA = r, g, b, a
        end
        TextTone(C, _G.DBM_GUI_OptionsFrameHeaderText, "heading")
        TextTone(C, _G.DBM_GUI_OptionsFrameWebsite, "muted")
    end
    for i in ipairs(f and f.tabs or {}) do
        local tab = _G["DBM_GUI_OptionsFrameTab" .. i]
        if H.Allowed(tab) then
            local art = nativeTabs[tab]
            if not art then
                art = {}; nativeTabs[tab] = art
                local function Strip(child, depth)
                    if depth > 4 or not H.Allowed(child) then return end
                    for _, region in ipairs(H.Regions(child)) do if H.Texture(region) then H.Fade(region) end end
                    for _, nested in ipairs(H.Children(child)) do Strip(nested, depth + 1) end
                end
                for _, region in ipairs(H.Regions(tab)) do if H.Texture(region) then H.Fade(region) end end
                for _, child in ipairs(H.Children(tab)) do Strip(child, 0); art[#art + 1] = child end
            end
            for _, child in ipairs(art) do exclude[child] = true end
            H.Tab(tab, f.tab == i)
        end
    end
    local list = _G.DBM_GUI_OptionsFrameList
    local wrapper = H.Allowed(list) and list:GetParent()
    if H.Allowed(wrapper) and wrapper ~= f and C.dbmWrapper ~= wrapper then
        C.Panel(wrapper)
        wrapper:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -72)
        C.dbmWrapper = wrapper
    end
end
local function Navigation(C)
    if C.dbmNavigation then return end
    C.dbmNavigation = true
    local H, dirty = C.H, {}
    local function Paint(root, chrome)
        if not ns.IsEnabled(C.module) or not H.Allowed(root) then return end
        if InCombatLockdown and InCombatLockdown() then C.module.refresh(); return end
        dirty[root] = nil -- A synchronous completed-page paint consumes OnShow work.
        GUIExclude(C)
        if C.dbmExclude[root] then return end
        if chrome then
            Chrome(C)
            root = C.dbmWrapper or _G.DBM_GUI_OptionsFrameList
            if not H.Allowed(root) then return end
        end
        C.RefreshControlsNow(root, chrome and C.dbmChromeExclude or C.dbmExclude)
    end
    local function Queue(root, chrome)
        if not H.Allowed(root) or dirty[root] then return end
        dirty[root] = true
        H.Queue(root, function() if dirty[root] then Paint(root, chrome) end end)
    end
    C.dbmPaintChrome = function() Paint(Window(), true) end
    C.dbmPaintPage = function(_, page) Paint(page, false); C.dbmPaintChrome() end
    C.dbmQueueVisible = function()
        Queue(_G.DBM_GUI and _G.DBM_GUI.currentViewing, false)
        Queue(Window(), true)
    end
    C.dbmControlRefresh = function(root, source)
        local node = H.Allowed(source) and source or root
        for _ = 1, 20 do
            if not H.Allowed(node) then break end
            if node.mytype == "panel" then Queue(node, false); return end
            if node == _G.DBM_GUI_DropDown then Queue(node, false); return end
            if node == _G.DBM_GUI_OptionsFrameList or node == C.dbmWrapper then Queue(Window(), true); return end
            node = node.GetParent and node:GetParent()
        end
        -- Scroll containers and window-level controls can affect the selected
        -- page. Refresh it once without entering unrelated hidden panels/HUD.
        C.dbmQueueVisible()
    end
    C.dbmConsumePending = function() for root in pairs(dirty) do dirty[root] = nil end end
end

ns.RegisterScopedSkin("DBM", "Deadly Boss Mods", {
    softBorders = true,
    -- DBM-GUI is load-on-demand. Never force it to load just to apply a skin.
    available = function() return type(_G.DBM) == "table" or type(_G.DBM_GUI) == "table" and Window() ~= nil end,
    preserveTextColors = true,
    immediateShow = true,
    panelOptions = {noBorder = true, noBg = true},
    font = ApplyFont,
    controlRefresh = function(C, root, source)
        if C.dbmControlRefresh then C.dbmControlRefresh(root, source) end
    end,
    roots = function(C)
        Chrome(C)
        local f, exclude = Window(), GUIExclude(C)
        local roots = {}
        if C.H.Allowed(f) then roots[1] = {frame = f, options = {noAccent = true, noTopBar = true}, exclude = exclude} end
        local popup = _G.DBM_GUI_DropDown
        if C.H.Allowed(popup) then roots[#roots + 1] = {frame = popup, exclude = exclude} end
        return roots
    end,
    hooks = function(C)
        Navigation(C)
        C.dbmConsumePending()
        fontGeneration = fontGeneration + 1
        -- Full/manual/theme/load refreshes retain HUD discovery. Ordinary
        -- navigation and control callbacks below never enter this path.
        HUD(C)()
        for _, name in ipairs({"CreateNewPanel", "CreateBossModPanel", "CreateDropdown"}) do
            C.H.Hook(_G.DBM_GUI, name, C.dbmQueueVisible)
        end
        for _, name in ipairs({"ShowTab", "UpdateMenuFrame", "ClearSelection"}) do
            C.H.Hook(Window(), name, C.dbmPaintChrome)
        end
        C.H.Hook(Window(), "DisplayFrame", C.dbmPaintPage)
        local f = Window()
        C.H.Hook(f and f.tabsGroup, "SelectAtIndex", C.dbmPaintChrome)
    end,
    visit = function(C, f, kind)
        local H, S = C.H, C.S
        if kind == "SimpleHTML" and f:GetParent() and f:GetParent().mytype == "checkbutton" then TextTone(C, f, "label", f:GetParent()) end
        if kind == "CheckButton" and not (f.GetName and (f:GetName() or ""):match("^DBM_GUI_OptionsFrameTab%d+$")) then Control(C, f, "Checkbox") end
        if kind == "DropdownButton" or f.mytype == "dropdown" or f.mytype == "dropdown2" then Control(C, f, "Dropdown") end
        if kind == "EditBox" then Control(C, f, "EditBox") end
        if Fonts(C, f, kind) then return true end
        local name = f.GetName and f:GetName() or ""
        local tab = tonumber(name:match("^DBM_GUI_OptionsFrameTab(%d+)$"))
        if tab then H.Tab(f, Window().tab == tab); return true end
        if kind == "Slider" then Slider(C, f); return true end
        if kind == "CheckButton" or kind == "DropdownButton" or kind == "EditBox" then return true end
        if C.dbmArrows and C.dbmArrows[f] then return true end
        if kind == "Button" then
            if name == "DBM_GUI_OptionsFrameClosePanelButton" then S.CloseButton(f); return true end
            -- Do not fade or recolour DBM's colour-picker swatch textures.
            if type(f.SetColorRGB) == "function" then
                for _, region in ipairs(H.Regions(f)) do H.Font(region) end
                return true
            end
            -- Pooled sidebar rows exist before they receive an element. Claim
            -- them immediately so generic discovery never creates row boxes.
            if H.Allowed(f.toggle) and (f.element or f:GetParent() == _G.DBM_GUI_OptionsFrameList) then
                local window = Window()
                local page = window.tabs and window.tabs[window.tab]
                local selected = window.searchQuery and window.searchQuery ~= ""
                    and _G.DBM_GUI.currentViewing or page and page.selection
                if not f.euiSelection then
                    f.euiSelection = f:CreateTexture(nil, "BACKGROUND")
                    f.euiSelection:SetAllPoints(f)
                end
                local r, g, b = S.GetAccentColor()
                f.euiSelection:SetColorTexture(r, g, b, f.element and selected == f.element and 0.12 or 0)
                local highlight = f.GetHighlightTexture and H.Texture(f:GetHighlightTexture())
                if highlight then
                    highlight:SetColorTexture(r, g, b, 0.08)
                    highlight:SetVertexColor(1, 1, 1, 1)
                    if highlight.SetBlendMode then highlight:SetBlendMode("BLEND") end
                end
                TextTone(C, f.text, f.element and selected == f.element and "heading" or "label")
                H.Font(f.text); PaintTone(f.text)
                H.Toggle(f.toggle, f.element and f.element.showSub)
                return true
            end
            if f:GetParent() and f:GetParent().toggle == f then
                for _, region in ipairs(H.Regions(f)) do if H.Texture(region) and region.GetDrawLayer and region:GetDrawLayer() == "BACKGROUND" then region:SetColorTexture(0, 0, 0, 0) end end
                return true
            end
            H.Resize(f)
            if f.GetFontString and H.Allowed(f:GetFontString()) then Control(C, f, "Button"); return true end
        end
        if f.mytype == "dropdown" or f.mytype == "dropdown2" then
            Control(C, f, "Dropdown")
            return true
        end
        if f.mytype == "area" then C.Panel(f) end
    end,
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("DBM", DefineSkin)
else DefineSkin() end
