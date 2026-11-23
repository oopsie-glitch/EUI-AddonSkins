local ADDON, ns = ...
local unpack = unpack or table.unpack
local NAME = "Addonskins EUI"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local MEDIA = "Interface\\AddOns\\EUIAddonSkins\\Media\\DetailsNative\\"
local ownDefinition
local registrationStatus = "waiting for the Details integration to activate"
-- GetSkin is overwritten by class_instance.lua with an instance-only getter.
-- The native selector and InstallSkin share this authoritative named registry.
local function FindSkin(name)
    local D = _G.Details
    return D and type(D.skins) == "table" and D.skins[name]
end
function ns.NativeDetailsRegistrationStatus()
    local D = _G.Details
    local metadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    local version = metadata and metadata("Details", "Version") or "unknown"
    return registrationStatus .. " | Details: " .. tostring(version)
        .. " | IsLoaded: " .. tostring(D and type(D.IsLoaded) == "function" and D.IsLoaded() or false)
        .. " | combat: " .. tostring(InCombatLockdown and InCombatLockdown() or false)
end
if SlashCmdList then
    SLASH_EUIDETAILSNATIVE1 = "/euidetailsnative"
    SlashCmdList.EUIDETAILSNATIVE = function()
        if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Addonskins EUI: " .. ns.NativeDetailsRegistrationStatus()) end
    end
end
function ns.IsNativeDetailsInstance(instance)
    local D = _G.Details
    return instance and instance.skin == NAME and ownDefinition ~= nil
        and D and FindSkin(NAME) == ownDefinition or false
end

-- Experimental adapter: native selection owns every profile/default write.
-- Register only when the existing Details integration is eligible and initialized.
function ns.CreateNativeDetailsPrototype(C, releaseLegacy)
    local D, H, S = _G.Details, C.H, C.S
    local P, entries, painting = {}, setmetatable({}, {__mode = "k"}), false
    local buttons = {
        {"modo_selecao", "settings.tga"}, {"segmento", "undo.tga"},
        {"atributo", "sheet.tga"}, {"report", "report.tga"},
        {"reset", "reset.tga"}, {"novo", "open.tga"}, {"fechar", "close.tga"},
    }
    local textureStates = {{"GetNormalTexture",0.65},{"GetHighlightTexture",1},{"GetPushedTexture",1},{"GetDisabledTexture",0.25}}
    local function Plain(v) return not (issecretvalue and issecretvalue(v)) end
    local function Number(v) return Plain(v) and type(v) == "number" end
    local function SafeUI()
        return not (InCombatLockdown and InCombatLockdown()) and ns.IsEnabled(C.module)
    end
    local function Frame(v)
        if type(v) == "table" or type(v) == "userdata" then return v.widget or v end
    end
    local function Color(f)
        local r,g,b,a = f:GetBackdropColor()
        if Plain(r) and Plain(g) and Plain(b) and Plain(a) then return {r,g,b,a} end
    end
    local reported = {}
    local function Status(code, message, warn)
        P.status, P.reason = code, message
        registrationStatus = message .. " | install attempts: " .. tostring(P.installAttempts or 0)
        if warn and not reported[code] then
            reported[code] = true
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("EUI AddonSkins: Addonskins EUI unavailable: " .. message .. ". /euidetailsnative")
            end
        end
    end
    -- Only the native definition follows the live accent. Details deep-copies
    -- this value on selection; already applied profiles remain entirely native.
    local function TitleAccentDefault(definition)
        if type(S.GetAccentColor) ~= "function" then
            Status("accent", "EUI accent source is unavailable", true); return false
        end
        local r,g,b = S.GetAccentColor()
        if not Plain(r) or not Plain(g) or not Plain(b)
            or type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
            Status("accent", "EUI accent is not ready", true); return false
        end
        local title = definition.instance_cprops.attribute_text
        local color = title.text_color
        if type(color) ~= "table" then color = {}; title.text_color = color end
        if color[1] ~= r or color[2] ~= g or color[3] ~= b or color[4] ~= 1 then
            color[1],color[2],color[3],color[4] = r,g,b,1
        end
        return true
    end
    function P.Register(look)
        if not SafeUI() then Status("deferred", "waiting for enabled, out-of-combat refresh"); return end
        if ownDefinition and FindSkin(NAME) == ownDefinition then
            if not TitleAccentDefault(ownDefinition) then return end
            if P.status ~= "registered" then
                Status("registered", "registered in Details.skins; native GetSkin is instance-dependent")
            end
            return
        end
        if type(D.IsLoaded) ~= "function" then Status("unsupported", "missing Details.IsLoaded", true); return end
        if not D.IsLoaded() then Status("initializing", "waiting for Details initialization / DETAILS_STARTED"); return end
        if type(D.InstallSkin) ~= "function" or type(D.CopyTable) ~= "function"
            or type(D.skins) ~= "table" or type(D.instance_defaults) ~= "table" then
            Status("unsupported", "missing native InstallSkin, CopyTable, skins registry or instance defaults", true); return
        end
        -- Foreign definitions, including differently implemented cached skins, win.
        if FindSkin(NAME) then
            P.collision = true; Status("collision", "another definition owns Addonskins EUI", true); return
        end
        ownDefinition = nil
        local base = FindSkin("Minimalistic")
        if not base or type(base.file) ~= "string" or not base.icon_anchor_main or not base.icon_anchor_plugins then
            Status("schema", "Minimalistic lacks the required native file/anchor schema", true); return
        end
        local definition = D.CopyTable(base)
        local props = D.CopyTable(D.instance_defaults)
        local row = props.row_info
        if not row or not row.space or not props.attribute_text then
            Status("defaults", "native row/space/title defaults are unavailable", true); return
        end
        -- Do not inherit Minimalistic's numerous unrelated presentation defaults.
        -- Use the approved fallback defaults, independent of the optional EUI meter.
        definition.instance_cprops = props
        -- Atlas anchors and native menu/title defaults form one layout contract.
        -- Copy the working skin's initial layout, not generic disabled-title defaults.
        local nativeLayout = base.instance_cprops or {}
        for _, key in ipairs({"menu_anchor", "menu_anchor_down", "toolbar_side", "plugins_grow_direction", "toolbar_icon_file"}) do
            if nativeLayout[key] ~= nil then props[key] = D.CopyTable(nativeLayout[key]) end
        end
        local nativeTitle = nativeLayout.attribute_text
        if nativeTitle then
            if nativeTitle.anchor then props.attribute_text.anchor = D.CopyTable(nativeTitle.anchor) end
            if nativeTitle.side then props.attribute_text.side = nativeTitle.side end
        end
        definition.micro_frames = nil
        definition.no_cache, definition.is_cached_skin = true, nil
        definition.author, definition.version = "EUI AddonSkins community", "experimental"
        definition.site = "https://github.com/oopsie-glitch/EUI-AddonSkins"
        definition.desc = "Experimental community skin. Selecting a different native skin resets appearance settings. Back up your Details profile first. No official EllesmereUI affiliation."
        local media = LibStub and LibStub("LibSharedMedia-3.0", true)
        if not media or type(media.Register) ~= "function" then
            Status("media", "LibSharedMedia-3.0 is not ready", true); return
        end
        local font = type(S.GetFont) == "function" and S.GetFont()
        if not Plain(font) or type(font) ~= "string" then
            Status("font", "EUI font source is unavailable", true); return
        end
        media:Register("statusbar", NAME .. " Bar", WHITE)
        media:Register("statusbar", NAME .. " Flat", WHITE)
        media:Register("background", NAME .. " Background", WHITE)
        media:Register("font", NAME .. " Font", font)
        props.bg_r, props.bg_g, props.bg_b, props.bg_alpha = 0, 0, 0, 0.75
        props.backdrop_texture = NAME .. " Background"
        props.titlebar_shown, props.titlebar_height = true, 22
        props.titlebar_texture = NAME .. " Flat"
        props.titlebar_texture_color = {27/255, 27/255, 27/255, 1}
        props.attribute_text.enabled = true
        props.attribute_text.show_timer = false -- initial native selection only
        props.attribute_text.text_face, props.attribute_text.text_size = NAME .. " Font", 11
        -- Initial native offsets only. MenuAnchor uses a 16-unit top offset
        -- and 1x1 menu points on 128-unit corner textures; the native title
        -- region is text_size + 2 high. Keep initial controls inside the band.
        -- Do not repaint/migrate saved instances or enforce later user geometry.
        local left, right = definition.left_corner_anchor, definition.right_corner_anchor
        local menu, title = props.menu_anchor, props.attribute_text
        if props.toolbar_side == 1 and title.side == 1 and type(title.anchor) == "table"
            and type(left) == "table" and type(right) == "table" and type(menu) == "table"
            and Number(left[1]) and Number(left[2]) and Number(right[1]) and Number(right[2])
            and Number(props.menu_icons_size) then
            local center = props.titlebar_height / 2
            local buttonHeight = 16 * props.menu_icons_size
            local padding = math.max(0, (props.titlebar_height - buttonHeight) / 2)
            title.anchor[2] = center - (title.text_size + 2) / 2 - left[2]
            if menu.side == 2 then
                menu[1] = 128 - right[1] - buttonHeight - padding
                menu[2] = center + buttonHeight / 2 - 16 + 1 - right[2]
            elseif menu.side == 1 then
                menu[1] = padding - left[1] - 128 - 1
                menu[2] = center - buttonHeight / 2 - left[2]
            end
        end
        if not TitleAccentDefault(definition) then return end
        -- Native title/timer settings and text are never maintained by this adapter.
        props.fullborder_shown, props.fullborder_size = true, 0.5
        props.fullborder_color = {0.055, 0.055, 0.055, 1}
        props.show_sidebars, props.show_statusbar = false, false
        props.rounded_corner_enabled = false
        props.hide_icon = true
        props.menu_icons_color, props.menu_icons_alpha = {0.65, 0.65, 0.65}, 1
        row.height, row.space.between = 18, 2
        row.font_face, row.font_face_file, row.font_size = NAME .. " Font", font, 11
        row.texture, row.texture_file, row.texture_custom = NAME .. " Bar", WHITE, ""
        row.textR_show_data, row.textR_bracket, row.textR_separator = {true, true, false}, "(", "NONE"
        row.textR_enable_custom_text = false
        props.use_multi_fontstrings = false
        -- Older and modern Details layouts both retain their own row-text renderer.
        for i, text in ipairs(row.texts or {}) do
            if text.font then
                text.font.face = font
                text.font.size = 11
            end
        end
        -- Details loads profiles before IsLoaded becomes true. WaitForSkin
        -- temporarily changes the skin identity, causing ChangeSkin to reset
        -- appearance to the fallback before this provider can register.
        -- Recover only that pending selection, from Details' own saved profile,
        -- through its native preset importer. No shadow preferences or hooks.
        local waiting, pending, recovery = D.waitingForSkins, {}, {}
        if type(waiting) == "table" then
            local profile
            for id, name in pairs(waiting) do
                if name == NAME then
                    local instance = D:GetInstance(id)
                    if instance and instance.skin == NAME then
                        if not profile and type(D.GetProfile) == "function"
                            and type(D.GetCurrentProfileName) == "function" then
                            profile = D:GetProfile(D:GetCurrentProfileName())
                        end
                        local saved = profile and profile.instances and profile.instances[id]
                        if type(saved) ~= "table" or saved.skin ~= NAME
                            or type(instance.ApplySavedSkin) ~= "function"
                            or not Number(saved.version) or not Number(D.preset_version)
                            or saved.version < D.preset_version then
                            Status("profile", "cannot safely recover the waiting native saved window " .. tostring(id), true)
                            return
                        end
                        recovery[#recovery + 1] = {instance = instance, saved = D.CopyTable(saved)}
                    end
                    pending[id] = name
                end
            end
        end
        ownDefinition = definition
        -- Consume only our waiting entries. Native InstallSkin would otherwise
        -- reselect stale windows which the user already switched away from.
        for id in pairs(pending) do waiting[id] = nil end
        P.installAttempts = (P.installAttempts or 0) + 1
        D:InstallSkin(NAME, definition)
        if FindSkin(NAME) ~= definition then
            ownDefinition = nil
            for id, name in pairs(pending) do if waiting[id] == nil then waiting[id] = name end end
            Status("rejected", "InstallSkin did not retain the submitted definition", true)
            return
        end
        for _, item in ipairs(recovery) do
            if item.instance.skin == NAME then item.instance:ApplySavedSkin(item.saved) end
        end
        P.recoveredWindows = #recovery
        Status("registered", "registered in Details.skins; native GetSkin is instance-dependent")
    end
    local function SaveArt(entry, art, path, tint)
        if not H.Allowed(art) or not art.GetTexture or not art.SetTexture then return end
        local current = art:GetTexture()
        if not Plain(current) then return end
        local old = entry.art[art]
        if not old then
            local coords = art.GetTexCoord and {art:GetTexCoord()}
            local color = art.GetVertexColor and {art:GetVertexColor()}
            for _, value in ipairs(coords or {}) do if not Plain(value) then return end end
            for _, value in ipairs(color or {}) do if not Plain(value) then return end end
            old = {path = current, coords = coords, color = color}
            entry.art[art] = old
        end
        old.applied = path
        if current ~= path then art:SetTexture(path) end
        if art.GetTexCoord and art.SetTexCoord then
            local x1,y1,x2,y2,x3,y3,x4,y4 = art:GetTexCoord()
            if Plain(x1) and Plain(y1) and Plain(x2) and Plain(y2)
                and Plain(x3) and Plain(y3) and Plain(x4) and Plain(y4) then
                -- WoW returns eight corner coordinates; the four-value form
                -- remains accepted for older wrappers and source fixtures.
                local full
                if x3 ~= nil then
                    full = x1 == 0 and y1 == 0 and x2 == 0 and y2 == 1
                        and x3 == 1 and y3 == 0 and x4 == 1 and y4 == 1
                else full = x1 == 0 and y1 == 1 and x2 == 0 and y2 == 1 end
                if not full then art:SetTexCoord(0,1,0,1) end
            end
        end
        if art.GetVertexColor and art.SetVertexColor then
            local r,g,b,a = art:GetVertexColor()
            if Plain(r) and Plain(g) and Plain(b) and Plain(a) and (r ~= tint or g ~= tint or b ~= tint or a ~= 1) then art:SetVertexColor(tint,tint,tint,1) end
        end
    end
    function P.Toolbar(instance)
        if not SafeUI() or not ns.IsNativeDetailsInstance(instance) then return end
        local entry = entries[instance]
        if not entry then return end
        local header = instance.baseframe and instance.baseframe.cabecalho or {}
        for _, spec in ipairs(buttons) do
            local button = Frame(header[spec[1]])
            if H.Allowed(button) then
                for _, state in ipairs(textureStates) do
                    if button[state[1]] then SaveArt(entry, button[state[1]](button), MEDIA .. spec[2], state[2]) end
                end
                SaveArt(entry, button.texture, MEDIA .. spec[2], 0.65)
            end
        end
    end
    function P.Background(instance)
        if painting or not SafeUI() or not ns.IsNativeDetailsInstance(instance) then return end
        local entry, base, f = entries[instance], instance.baseframe, instance.bgdisplay
        if not entry or not H.Allowed(f) or not f.GetBackdropColor or not f.SetBackdropColor then return end
        local c = Color(f)
        if not c then return end
        local alpha = instance.bg_alpha
        if not Plain(alpha) or type(alpha) ~= "number" then return end
        -- A rounded/native redraw may remove the base backdrop. Suppress only
        -- a verified equivalent fill, never the sole surviving body surface.
        local duplicate = false
        if H.Allowed(base) and base.GetBackdrop and f.GetBackdrop then
            local a, b = base:GetBackdrop(), f:GetBackdrop()
            if Plain(a) and Plain(b) and type(a) == "table" and type(b) == "table" then
                local ap, bp = a.bgFile, b.bgFile
                local bc = base.GetBackdropColor and Color(base)
                if Plain(ap) and Plain(bp) and ap and ap == bp and bc then
                    local desired = c[4] ~= 0 and c[4] or alpha
                    duplicate = bc[1] == c[1] and bc[2] == c[2] and bc[3] == c[3] and bc[4] == desired
                end
            end
        end
        if duplicate and c[4] ~= 0 then
            entry.background = {frame = f, color = c}
            painting = true
            f:SetBackdropColor(c[1],c[2],c[3],0)
            painting = false
        elseif not duplicate and entry.background then
            -- Current native opacity wins over the former suppression snapshot,
            -- including an explicit zero. Never write an instance/profile value.
            entry.background = nil
            if c[4] == 0 and alpha ~= 0 then f:SetBackdropColor(c[1],c[2],c[3],alpha) end
        end
    end
    -- Native RefreshAttributeTextSize subtracts a button count, but never moves
    -- the left-anchored title past a left-side toolbar. Fit the existing title
    -- to actual occupied bounds; never move or resize a button.
    local function Points(f)
        local result = {}
        for i = 1, f:GetNumPoints() do
            local p,r,rp,x,y = f:GetPoint(i)
            if not Plain(p) or not Plain(r) or not Plain(rp) or not Number(x) or not Number(y) then return end
            result[i] = {p,r,rp,x,y}
        end
        return result
    end
    local function OwnPoint(title, state, f)
        if not state or title:GetNumPoints() ~= 1 then return false end
        local p,r,rp,x,y = title:GetPoint(1)
        return Plain(p) and Plain(r) and Plain(rp) and Plain(x) and Plain(y)
            and p == "BOTTOMLEFT" and r == f and rp == "TOPLEFT" and x == state.x and y == state.y
    end
    function P.Title(instance)
        if not SafeUI() or not ns.IsNativeDetailsInstance(instance) then return end
        local entry, f = entries[instance], instance.baseframe
        local title = instance.GetTitleBarFontString and Frame(instance:GetTitleBarFontString())
        if not entry or not H.Allowed(f) or not H.Allowed(title)
            or not f.GetEffectiveScale or not title.GetEffectiveScale or not title.GetNumPoints
            or not title.GetLeft or not title.GetBottom or not title.GetTop
            or not f.GetLeft or not f.GetTop or not f.GetWidth then return end
        local scale, ts = f:GetEffectiveScale(), title:GetEffectiveScale()
        local fl, ft, fw = f:GetLeft(), f:GetTop(), f:GetWidth()
        local tl, tb, tt = title:GetLeft(), title:GetBottom(), title:GetTop()
        if not Number(scale) or not Number(ts) or scale <= 0 or ts <= 0
            or not Number(fl) or not Number(ft) or not Number(fw)
            or not Number(tl) or not Number(tb) or not Number(tt) then return end
        local state = entry.title
        if not OwnPoint(title, state, f) then
            local points = Points(title)
            if not points then return end
            state = {points = points, left = tl * ts / scale - fl,
                bottom = tb * ts / scale - ft, height = (tt - tb) * ts / scale}
            entry.title = state
        end
        local left, right = math.max(0, state.left), fw
        local bottom, top = ft + state.bottom, ft + state.bottom + state.height
        local function Reserve(value)
            local button = Frame(value)
            if not H.Allowed(button) or button.IsShown and not button:IsShown()
                or not button.GetLeft or not button.GetRight or not button.GetTop or not button.GetBottom
                or not button.GetEffectiveScale then return end
            local bs = button:GetEffectiveScale()
            local bl,br,bt,bb = button:GetLeft(),button:GetRight(),button:GetTop(),button:GetBottom()
            if not Number(bs) or bs <= 0 or not Number(bl) or not Number(br) or not Number(bt) or not Number(bb) then return end
            bl,br,bt,bb = bl*bs/scale-fl,br*bs/scale-fl,bt*bs/scale,bb*bs/scale
            if bt > bottom and bb < top then
                if instance.menu_anchor and instance.menu_anchor.side == 1 then left = math.max(left, br)
                else right = math.min(right, bl) end
            end
        end
        local header = f.cabecalho or {}
        for _, spec in ipairs(buttons) do Reserve(header[spec[1]]) end
        for _, button in ipairs(D.ToolBar and D.ToolBar.Shown or {}) do
            local raw = Frame(button)
            if raw and raw.GetParent and raw:GetParent() == f then Reserve(raw) end
        end
        left = math.min(fw, left)
        local width = math.max(0, right - left)
        -- A zero FontString width can mean auto-size in the client. Keep its
        -- native visibility/content, but paint no title when controls use all space.
        local alpha = title.GetAlpha and title:GetAlpha()
        if Number(alpha) and title.SetAlpha then
            if width == 0 then
                if entry.titleAlpha == nil or alpha ~= 0 then entry.titleAlpha = alpha end
                if alpha ~= 0 then title:SetAlpha(0) end
            elseif entry.titleAlpha ~= nil then
                if alpha == 0 then title:SetAlpha(entry.titleAlpha) end
                entry.titleAlpha = nil
            end
        end
        if not OwnPoint(title, state, f) or state.x ~= left or state.y ~= state.bottom then
            title:ClearAllPoints()
            title:SetPoint("BOTTOMLEFT", f, "TOPLEFT", left, state.bottom)
            state.x, state.y = left, state.bottom
        end
        local current = title:GetWidth()
        if Number(current) and current ~= width then title:SetWidth(width) end
    end
    function P.Release(instance)
        local entry = entries[instance]
        if not entry then return end
        local title = instance.GetTitleBarFontString and Frame(instance:GetTitleBarFontString())
        if H.Allowed(title) and entry.titleAlpha ~= nil and title.GetAlpha and title.SetAlpha then
            local alpha = title:GetAlpha()
            if Number(alpha) and alpha == 0 then title:SetAlpha(entry.titleAlpha) end
        end
        if H.Allowed(title) and entry.title and OwnPoint(title, entry.title, instance.baseframe) then
            title:ClearAllPoints()
            for _, point in ipairs(entry.title.points) do title:SetPoint(unpack(point)) end
        end
        for art, old in pairs(entry.art) do
            local path = art:GetTexture()
            -- Native ChangeSkin normally replaced these first; don't overwrite it.
            if Plain(path) and path == old.applied then
                art:SetTexture(old.path)
                if old.coords and art.SetTexCoord then art:SetTexCoord(unpack(old.coords)) end
                if old.color and art.SetVertexColor then art:SetVertexColor(unpack(old.color)) end
            end
        end
        for art, alpha in pairs(entry.faded) do
            local current = art:GetAlpha()
            if Plain(current) and current == 0 then art:SetAlpha(alpha) end
        end
        local bg = entry.background
        if bg then
            local c = Color(bg.frame)
            if c and c[4] == 0 and c[1] == bg.color[1] and c[2] == bg.color[2] and c[3] == bg.color[3] then
                local alpha = instance.bg_alpha
                if Plain(alpha) and type(alpha) == "number" and alpha ~= 0 then
                    bg.frame:SetBackdropColor(c[1],c[2],c[3],alpha)
                end
            end
        end
        entries[instance] = nil
    end
    function P.Apply(instance)
        if not SafeUI() then return end
        if not ns.IsNativeDetailsInstance(instance) then P.Release(instance); return end
        if not H.Allowed(instance.baseframe) then return end
        releaseLegacy(instance)
        local entry = entries[instance]
        if not entry then entry = {art = {}, faded = {}}; entries[instance] = entry end
        local f, header = instance.baseframe, instance.baseframe.cabecalho or {}
        -- Preserve native geometry. The native titleBar supplies the flat band;
        -- suppress only the decorative atlas pieces behind it.
        for _, art in pairs({header.ball, header.ball_r, header.emenda, header.top_bg}) do
            if H.Allowed(art) and art.GetAlpha and art.SetAlpha then
                local a = art:GetAlpha()
                if Plain(a) then
                    if entry.faded[art] == nil then entry.faded[art] = a end
                    if a ~= 0 then art:SetAlpha(0) end
                end
            end
        end
        P.Background(instance)
        P.Toolbar(instance)
        P.Title(instance)
    end
    function P.Refresh(look)
        if not SafeUI() then return end
        P.Register(look)
        for _, instance in pairs(D:GetAllInstances() or {}) do P.Apply(instance) end
    end
    -- No row, combat-data, timer, font or geometry hooks.
    H.Hook(D, "SetBackgroundColor", P.Background)
    H.Hook(D, "SetBackgroundAlpha", P.Background)
    H.Hook(D, "RefreshAttributeTextSize", P.Title)
    P.entries = entries -- bounded diagnostics/tests, not a second preference store
    return P
end
