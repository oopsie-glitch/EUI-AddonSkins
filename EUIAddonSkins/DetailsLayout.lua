local ADDON, ns = ...
local unpack = unpack or table.unpack
local MEDIA = "Interface\\AddOns\\EllesmereUIDamageMeters\\Media\\"
local buttons = {
    {"modo_selecao", "dm_settings.png"}, {"segmento", "dm_undo.png"},
    {"atributo", "dm_sheet.png"}, {"report", "dm_report.png"},
    {"reset", "dm_reset.png"}, {"novo", "dm_open.png"}, {"fechar", "dm_close.png"},
}
local nativeTextures = {"GetNormalTexture", "GetHighlightTexture", "GetPushedTexture", "GetDisabledTexture"}
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
            saved[art] = nil
        end
    end
    local function RestoreSurface(entry)
        if entry.body then entry.body:SetAlpha(0) end
        for _, art in pairs(entry.headers) do art:SetAlpha(0) end
        for art, alpha in pairs(entry.faded) do
            local current = art:GetAlpha()
            if Readable(current) and current == 0 then art:SetAlpha(alpha) end
            entry.faded[art] = nil
        end
        if entry.title then
            local current = {entry.title:GetTextColor()}
            if Same(current, entry.titleApplied) then entry.title:SetTextColor(unpack(entry.titleColor)) end
            entry.title, entry.titleColor, entry.titleApplied = nil, nil, nil
        end
    end
    local function Entry(instance)
        local f = instance.baseframe
        local entry = windows[instance]
        if not entry or entry.frame ~= f then
            if entry then RestoreSurface(entry); RestoreArt(entry.icons) end
            entry = {frame = f, faded = {}, icons = {}, headers = {}}
            windows[instance] = entry
        end
        return entry
    end
    local function Fade(entry, art)
        if not H.Allowed(art) or not art.GetAlpha or not art.SetAlpha then return end
        local alpha = art:GetAlpha()
        if not Readable(alpha) then return end
        if alpha ~= 0 then entry.faded[art] = alpha; art:SetAlpha(0) end
    end
    function L.Toolbar(instance)
        if not Ready(instance) then return end
        local entry = Entry(instance)
        local available = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("EllesmereUIDamageMeters")
        if not wanted(instance, "toolbar") or not available then RestoreArt(entry.icons); return end
        local header = instance.baseframe.cabecalho or {}
        for _, spec in ipairs(buttons) do
            local obj = header[spec[1]]
            local button = obj and (obj.widget or obj)
            if H.Allowed(button) then
                for _, getter in ipairs(nativeTextures) do
                    local art = button[getter] and H.Texture(button[getter](button))
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
        local obj = instance.GetTitleBarFontString and instance:GetTitleBarFontString()
        local title = obj and (obj.widget or obj)
        if entry.title and (entry.title ~= title or not wanted(instance, "meter") or not look.titleAccent) then
            if Same({entry.title:GetTextColor()}, entry.titleApplied) then entry.title:SetTextColor(unpack(entry.titleColor)) end
            entry.title, entry.titleColor, entry.titleApplied = nil, nil, nil
        end
        if not wanted(instance, "meter") or not look.titleAccent or not H.Allowed(title) or not title.GetTextColor then return end
        local current = {title:GetTextColor()}
        for _, value in ipairs(current) do if not Readable(value) then return end end
        if not entry.title or not Same(current, entry.titleApplied) then entry.titleColor = current end
        entry.title = title
        local color = look.titleColor
        if not Same(current, color) then title:SetTextColor(unpack(color)) end
        entry.titleApplied = color
    end
    function L.Window(instance, look)
        if not Ready(instance) then return end
        local entry = Entry(instance)
        entry.look = look
        local f = instance.baseframe
        if wanted(instance, "meter") then
            if not entry.body then
                entry.body = f:CreateTexture(nil, "BACKGROUND")
                entry.body:SetAllPoints(f)
            end
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
                        entry.header = header:CreateTexture(nil, "BACKGROUND")
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
            Fade(entry, f.Center)
            local background = instance.windowBackgroundDisplay or instance.bgdisplay
            if H.Allowed(background) then Fade(entry, background.Center) end
            Fade(entry, header and header.Center)
            for _, key in ipairs({"barra_esquerda", "barra_direita", "barra_fundo", "wallpaper"}) do Fade(entry, f[key]) end
            local native = f.cabecalho or {}
            for _, key in ipairs({"ball", "ball_r", "emenda", "top_bg"}) do Fade(entry, native[key]) end
            if custom then Fade(entry, custom.texture) end
        else RestoreSurface(entry) end
        L.Title(instance, look)
        L.Toolbar(instance)
    end
    function L.Release(instance)
        if InCombatLockdown and InCombatLockdown() then defer(); return end
        local entry = windows[instance]
        if entry then RestoreSurface(entry); RestoreArt(entry.icons) end
    end
    return L
end
