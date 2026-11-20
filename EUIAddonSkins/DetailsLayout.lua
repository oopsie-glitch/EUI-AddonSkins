local ADDON, ns = ...
local unpack = unpack or table.unpack
local MEDIA = "Interface\\AddOns\\EllesmereUIDamageMeters\\Media\\"
local buttons = {
    {"modo_selecao", "dm_settings.png"}, {"segmento", "dm_undo.png"},
    {"atributo", "dm_sheet.png"}, {"report", "dm_report.png"},
    {"reset", "dm_reset.png"}, {"novo", "dm_open.png"}, {"fechar", "dm_close.png"},
}
local nativeTextures = {
    {"GetNormalTexture", 0.55}, {"GetHighlightTexture", 1},
    {"GetPushedTexture", 1}, {"GetDisabledTexture", 0.35},
}
local roundedFills = {"CenterBlock", "TopHorizontalEdge", "BottomHorizontalEdge",
    "TopLeft", "TopRight", "BottomLeft", "BottomRight"}
local function Readable(value)
    return not (issecretvalue and issecretvalue(value))
end
local function Same(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do
        if not Readable(a[i]) or not Readable(b[i]) or a[i] ~= b[i] then return false end
    end
    return true
end

-- Own cosmetic regions only. Never capture or restore native geometry, fonts,
-- title text, instance settings or the toolbar's input and visibility state.
function ns.CreateDetailsLayout(H, wanted, defer)
    local L, windows = {}, {}
    local RestoreToolbar
    local function Ready(instance)
        if not H.Allowed(instance and instance.baseframe) then return false end
        if InCombatLockdown and InCombatLockdown() then defer(); return false end
        return true
    end
    local function RestoreArt(saved)
        for art, old in pairs(saved) do
            local current = art:GetTexture()
            if Readable(current) and current == old.applied then
                art:SetTexture(old.path)
                if old.coords then art:SetTexCoord(unpack(old.coords)) end
            end
            if old.color and Same({art:GetVertexColor()}, old.tint) then art:SetVertexColor(unpack(old.color)) end
            saved[art] = nil
        end
    end
    local function RestoreTitle(entry)
        if entry.title and Same({entry.title:GetTextColor()}, entry.titleApplied) then
            entry.tinting = true
            entry.title:SetTextColor(unpack(entry.titleColor))
            entry.tinting = false
        end
        entry.title, entry.titleColor, entry.titleApplied = nil, nil, nil
    end
    local function RestoreSurface(entry)
        entry.surfaceActive = false
        if entry.body then entry.body:SetAlpha(0) end
        for _, art in pairs(entry.headers) do art:SetAlpha(0) end
        for art, alpha in pairs(entry.faded) do
            local current = art:GetAlpha()
            if Readable(current) and current == 0 then art:SetAlpha(alpha) end
            entry.faded[art] = nil
        end
        for frame, old in pairs(entry.backdrops) do
            if old.fill and Same({frame:GetBackdropColor()}, {0, 0, 0, 0}) then frame:SetBackdropColor(unpack(old.fill)) end
            if old.border and Same({frame:GetBackdropBorderColor()}, {0, 0, 0, 0}) then frame:SetBackdropBorderColor(unpack(old.border)) end
            entry.backdrops[frame] = nil
        end
        RestoreTitle(entry)
    end
    local function Entry(instance)
        local f = instance.baseframe
        local entry = windows[instance]
        if not entry or entry.frame ~= f then
            if entry then RestoreSurface(entry); RestoreToolbar(entry) end
            entry = {frame = f, faded = {}, fadeHooks = {}, backdrops = {}, backdropHooks = {},
                toolbarFaded = {}, icons = {}, headers = {}}
            windows[instance] = entry
        end
        return entry
    end
    local function Fade(entry, art, instance, toolbar)
        if not H.Allowed(art) or not art.GetAlpha or not art.SetAlpha then return end
        local saved = toolbar and entry.toolbarFaded or entry.faded
        local Paint = entry.fadeHooks[art]
        if not Paint then
            local writing = false
            Paint = function(_, nativeAlpha)
            if writing or entry.restoring or not wanted(instance, toolbar and "toolbar" or "meter")
                or not toolbar and not entry.surfaceActive or not Ready(instance) then return end
            if nativeAlpha ~= nil and Readable(nativeAlpha) then saved[art] = nativeAlpha end
            local alpha = art:GetAlpha()
            if not Readable(alpha) then return end
            if alpha ~= 0 then
                saved[art] = alpha
                writing = true; art:SetAlpha(0); writing = false
            end
        end
            entry.fadeHooks[art] = Paint
            H.Hook(art, "SetAlpha", Paint)
        end
        Paint()
    end
    local function Backdrop(entry, frame, instance)
        if not H.Allowed(frame) or not frame.GetBackdropColor or not frame.SetBackdropColor
            or not frame.GetBackdropBorderColor or not frame.SetBackdropBorderColor then return end
        local Paint = entry.backdropHooks[frame]
        if not Paint then Paint = function()
            if entry.paintingBackdrop or entry.restoring or not entry.surfaceActive or not wanted(instance, "meter") or not Ready(instance) then return end
            if frame.GetBackdrop and not frame:GetBackdrop() then return end
            entry.paintingBackdrop = true
            local old = entry.backdrops[frame]
            if not old then old = {}; entry.backdrops[frame] = old end
            for _, spec in ipairs({{"fill", "GetBackdropColor", "SetBackdropColor"},
                {"border", "GetBackdropBorderColor", "SetBackdropBorderColor"}}) do
                local color = {frame[spec[2]](frame)}
                local plain = #color == 4
                for _, value in ipairs(color) do if not Readable(value) then plain = false end end
                if plain and not Same(color, {0, 0, 0, 0}) then
                    old[spec[1]] = color
                    frame[spec[3]](frame, 0, 0, 0, 0)
                end
            end
            entry.paintingBackdrop = false
        end
            entry.backdropHooks[frame] = Paint
            -- Tint native material in place: unlike historical SetBackdrop(nil),
            -- these setters never rebuild nine-slice geometry.
            local function NativeColor(key, ...)
                if entry.paintingBackdrop or entry.restoring or not entry.surfaceActive or not wanted(instance, "meter") then return end
                local color = {...}
                local plain = #color == 4
                for _, value in ipairs(color) do if not Readable(value) then plain = false end end
                if plain then
                    local old = entry.backdrops[frame]
                    if not old then old = {}; entry.backdrops[frame] = old end
                    old[key] = color
                end
                Paint()
            end
            H.Hook(frame, "SetBackdropColor", function(_, ...) NativeColor("fill", ...) end)
            H.Hook(frame, "SetBackdropBorderColor", function(_, ...) NativeColor("border", ...) end)
            H.Hook(frame, "SetBackdrop", Paint)
        end
        Paint()
    end
    RestoreToolbar = function(entry)
        RestoreArt(entry.icons)
        entry.restoring = true
        for art, alpha in pairs(entry.toolbarFaded) do
            if Readable(art:GetAlpha()) and art:GetAlpha() == 0 then art:SetAlpha(alpha) end
            entry.toolbarFaded[art] = nil
        end
        entry.restoring = false
    end
    function L.Toolbar(instance)
        if not Ready(instance) then return end
        local entry = Entry(instance)
        local available = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("EllesmereUIDamageMeters")
        if not wanted(instance, "toolbar") or not available then RestoreToolbar(entry); return end
        local header = instance.baseframe.cabecalho or {}
        for _, spec in ipairs(buttons) do
            local obj = header[spec[1]]
            local button = obj and (obj.widget or obj)
            if H.Allowed(button) then
                local primary = button.GetNormalTexture and H.Texture(button:GetNormalTexture())
                    or H.Texture(button.texture) or H.Texture(obj.texture)
                for _, source in ipairs({button, obj}) do
                    for _, key in ipairs({"texture", "icon", "leftTexture", "rightTexture", "centerTexture"}) do
                        local art = H.Texture(source[key])
                        if art then
                            local stateTexture = art == primary
                            for _, getter in ipairs(nativeTextures) do
                                if button[getter[1]] and button[getter[1]](button) == art then stateTexture = true; break end
                            end
                            if not stateTexture then Fade(entry, art, instance, true) end
                        end
                    end
                end
                for _, specTexture in ipairs(nativeTextures) do
                    local getter, shade = specTexture[1], specTexture[2]
                    local art = button[getter] and H.Texture(button[getter](button))
                        or getter == "GetNormalTexture" and primary
                    if art and art.GetTexture then
                        local current = art:GetTexture()
                        if Readable(current) then
                            local old = entry.icons[art]
                            local coords = art.GetTexCoord and {art:GetTexCoord()}
                            if not old or current ~= old.applied then
                                old = {path = current, coords = coords, applied = MEDIA .. spec[2]}
                                entry.icons[art] = old
                            end
                            if current ~= old.applied then art:SetTexture(old.applied) end
                            if coords and not Same(coords, {0, 1, 0, 1}) then art:SetTexCoord(0, 1, 0, 1) end
                            local color = {art:GetVertexColor()}
                            local readable = true
                            for _, value in ipairs(color) do if not Readable(value) then readable = false end end
                            if readable and #color == 4 then
                                if not old.tint or not Same(color, old.tint) then old.color = color end
                                local tint = {shade, shade, shade, color[4]}
                                if not Same(color, tint) then art:SetVertexColor(unpack(tint)) end
                                old.tint = tint
                            end
                        end
                    end
                end
            end
        end
    end
    function L.Title(instance, look)
        if not Ready(instance) then return end
        local entry = windows[instance]
        if not entry then return end
        look = look or entry.look
        local obj = instance.GetTitleBarFontString and instance:GetTitleBarFontString() or instance.menu_attribute_string
        local title = obj and (obj.widget or obj)
        if entry.title and (entry.title ~= title or not wanted(instance, "meter") or not look.titleAccent) then
            RestoreTitle(entry)
        end
        if not wanted(instance, "meter") or not look.titleAccent or not H.Allowed(title) or not title.GetTextColor then return end
        local current = {title:GetTextColor()}
        for _, value in ipairs(current) do if not Readable(value) then return end end
        if not entry.title or not Same(current, entry.titleApplied) then entry.titleColor = current end
        entry.title = title
        local color = look.titleColor
        if not Same(current, color) then
            entry.tinting = true
            title:SetTextColor(unpack(color))
            entry.tinting = false
        end
        entry.titleApplied = color
        -- AttributeMenu also writes this color from its delayed native callback.
        -- Observe only this instance's native title; never read or rewrite its text.
        if entry.hookedTitle ~= title then
            entry.hookedTitle = title
            H.Hook(title, "SetTextColor", function()
                if not entry.tinting and entry.title == title and wanted(instance, "meter") then L.Title(instance) end
            end)
        end
    end
    function L.Window(instance, look)
        if not Ready(instance) then return end
        local entry = Entry(instance)
        entry.look = look
        local f = instance.baseframe
        if wanted(instance, "meter") then
            entry.surfaceActive = true
            if not entry.body then
                -- Preserve the original Meter body's below-window draw order.
                entry.bodyHost = CreateFrame("Frame", nil, f)
                entry.bodyHost:SetAllPoints(f); entry.bodyHost:EnableMouse(false)
                entry.body = entry.bodyHost:CreateTexture(nil, "BACKGROUND")
                entry.body:SetAllPoints(entry.bodyHost)
            end
            local level = f.GetFrameLevel and f:GetFrameLevel()
            if Readable(level) and type(level) == "number" then
                level = math.max(0, level - 1)
                if entry.bodyLevel ~= level then entry.bodyHost:SetFrameLevel(level); entry.bodyLevel = level end
            end
            Backdrop(entry, f, instance)
            Backdrop(entry, instance.bgdisplay, instance)
            local canvas = instance.windowBackgroundDisplay
            if canvas ~= instance.bgdisplay then Backdrop(entry, canvas, instance) end
            Backdrop(entry, f.fullWindowFrame, instance)
            Backdrop(entry, f.titleBar, instance)
            Fade(entry, f.border, instance)
            Fade(entry, f.fullWindowFrame and f.fullWindowFrame.border, instance)
            if not Same(entry.bg or {}, look.bg) then entry.body:SetColorTexture(unpack(look.bg)); entry.bg = look.bg end
            if entry.body:GetAlpha() ~= 1 then entry.body:SetAlpha(1) end
            local custom = f.titleBar
            local header = H.Allowed(custom) and (not custom.IsShown or custom:IsShown()) and custom or f.UPFrame
            if not H.Allowed(header) then header = custom end
            if H.Allowed(header) then
                if entry.headerAnchor ~= header then
                    if entry.header then entry.header:SetAlpha(0) end
                    entry.header = entry.headers[header]
                    if not entry.header then
                        -- Native header decoration can be faded independently of
                        -- its geometry. Paint on the meter without inheriting that fade.
                        entry.header = f:CreateTexture(nil, "BACKGROUND")
                        entry.header:SetAllPoints(header)
                        entry.headers[header] = entry.header
                    end
                    entry.headerAnchor, entry.headerColor = header, nil
                end
                local c = look.header
                local color = {c.r or 0, c.g or 0, c.b or 0, look.headerAlpha}
                if not Same(entry.headerColor or {}, color) then entry.header:SetColorTexture(unpack(color)); entry.headerColor = color end
                if entry.header:GetAlpha() ~= 1 then entry.header:SetAlpha(1) end
            end
            -- Native backdrops remain allocated. Hide only their fill regions so
            -- layered backgrounds cannot obscure or multiply the EUI surface.
            Fade(entry, f.Center, instance)
            local background = instance.windowBackgroundDisplay or instance.bgdisplay
            if H.Allowed(background) then Fade(entry, background.Center, instance) end
            Fade(entry, header and header.Center, instance)
            local rounded = f.fullWindowFrame
            if H.Allowed(rounded) then
                for _, key in ipairs(roundedFills) do Fade(entry, rounded[key], instance) end
            end
            for _, key in ipairs({"barra_esquerda", "barra_direita", "barra_fundo", "wallpaper"}) do Fade(entry, f[key], instance) end
            local native = f.cabecalho or {}
            for _, key in ipairs({"ball", "ball_r", "emenda", "top_bg"}) do Fade(entry, native[key], instance) end
            if custom then Fade(entry, custom.texture, instance) end
            Fade(entry, native.atributo_icon, instance)
            for _, key in ipairs({"resize_direita", "resize_esquerda"}) do
                local grip = f[key]
                if H.Allowed(grip) then Fade(entry, grip.texture, instance) end
            end
            if H.Allowed(f.lock_button) then Fade(entry, f.lock_button.label, instance) end
        else RestoreSurface(entry) end
        L.Title(instance, look)
        L.Toolbar(instance)
    end
    function L.Release(instance)
        if InCombatLockdown and InCombatLockdown() then defer(); return end
        local entry = windows[instance]
        if entry then RestoreSurface(entry); RestoreToolbar(entry) end
    end
    return L
end
