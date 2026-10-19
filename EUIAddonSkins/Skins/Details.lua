local ADDON, ns = ...
local function DefineSkin()
local unpack = unpack or table.unpack
local WHITE = "Interface\\Buttons\\WHITE8X8"
local MEDIA_NAME = "EUI AddonSkins Meter"
local function TinyPlugin()
    local D = _G.Details
    return D and D.GetPlugin and D:GetPlugin("DETAILS_PLUGIN_TINY_THREAT")
end
local function TinyWindow(instance)
    if not instance or instance.modo ~= 4 then return false end
    local id = instance.current_raid_plugin or instance.last_raid_plugin
    if id == "DETAILS_PLUGIN_TINY_THREAT" or id == "Details_TinyThreat" then return true end
    local plugin = TinyPlugin()
    return plugin and plugin.GetPluginInstance and plugin:GetPluginInstance() == instance or false
end
local function MeterWanted(instance)
    local eui = _G.EllesmereUIDB
    local cfg = ns.DetailsSettings()
    local wanted
    if instance then
        local key = TinyWindow(instance) and "tiny" or "meter"
        wanted = cfg[key] == true
    else wanted = cfg.meter == true or cfg.tiny == true end
    return wanted and not (EUIAddonSkinsDB and EUIAddonSkinsDB.disabled)
        and not (eui and (eui.thirdPartySkinsOff or eui.thirdPartySkinAddons
            and eui.thirdPartySkinAddons["EUI AddonSkins - Details!"] == false))
end
local function Profile()
    local D = _G.Details
    local name = D and D.GetCurrentProfileName and D:GetCurrentProfileName() or "Default"
    return (GetRealmName and GetRealmName() or "") .. ":" .. (UnitName and UnitName("player") or "") .. ":" .. name
end
local function Backup(instance, create)
    local db = ns.DetailsSettings()
    db.backups = db.backups or {}
    local profile = Profile()
    db.backups[profile] = db.backups[profile] or {}
    local id = instance.meu_id or (instance.GetId and instance:GetId())
    if not id then return end
    local saved = db.backups[profile]
    if create and not saved[id] and instance.row_info and instance.row_info.space then
        local info = instance.row_info
        saved[id] = {height = info.height, spacing = info.space.between, texture = info.texture, texture_file = info.texture_file}
    end
    if create and saved[id] and instance.row_info and not saved[id].format then
        local info = instance.row_info
        local data = info.textR_show_data
        saved[id].format = {multi = instance.use_multi_fontstrings,
            custom = info.textR_enable_custom_text, bracket = info.textR_bracket,
            separator = info.textR_separator, data = data and {data[1], data[2], data[3]}}
    end
    return saved[id], saved, id
end
local function RestoreSettings(instance)
    local old, saved, id = Backup(instance)
    local info = instance.row_info
    if old and info and info.space then
        info.height, info.texture, info.texture_file = old.height, old.texture, old.texture_file
        info.space.between = old.spacing
        instance.row_height = (old.height or 0) + (old.spacing or 0)
        if old.format then
            local format = old.format
            instance.use_multi_fontstrings, info.textR_enable_custom_text = format.multi, format.custom
            info.textR_bracket, info.textR_separator = format.bracket, format.separator
            if format.data then info.textR_show_data = {format.data[1], format.data[2], format.data[3]} end
        end
        saved[id] = nil
        return true
    end
end

-- Recovery is independent of EUI dispatch: a disabled skin must still be able
-- to restore its saved cosmetic settings after a reload or profile switch.
local recovery = CreateFrame("Frame")
recovery:RegisterEvent("PLAYER_LOGIN"); recovery:RegisterEvent("ADDON_LOADED")
local profileRecoveryHooked
local function Recover()
    local D = _G.Details
    if D and type(D.ApplyProfile) == "function" and not profileRecoveryHooked then
        profileRecoveryHooked = true
        hooksecurefunc(D, "ApplyProfile", function() Recover() end)
    end
    if D and D.GetAllInstances then
        for _, instance in pairs(D:GetAllInstances() or {}) do
            if not MeterWanted(instance) and RestoreSettings(instance) and instance.baseframe and instance.ChangeSkin
                and not (InCombatLockdown and InCombatLockdown()) then instance:ChangeSkin() end
        end
    end
end
recovery:SetScript("OnEvent", Recover)

local function Frame(value)
    if type(value) == "table" or type(value) == "userdata" then
        return value.widget or value.frame or value
    end
end

local Look = ns.GetMeterStyle

local function Setup(C, refresh)
    if C.details then return C.details end
    local S, H, D = C.S, C.H, _G.Details
    local state = {meters = {}, owners = {}, roots = {}, sections = {}, designerRows = {}, designers = {}, snapshots = {}, texts = {}, textures = {}, applying = false}
    C.details = state
    local function Busy()
        if InCombatLockdown and InCombatLockdown() then
            if not state.combatPending then state.combatPending = true; refresh() end
            return true
        end
    end
    local function Owned(frame)
        frame = Frame(frame)
        for _ = 1, 24 do
            if not H.Allowed(frame) then return false end
            if state.roots[frame] or state.owners[frame] then return true end
            frame = frame.GetParent and frame:GetParent()
        end
        return false
    end
    -- Options sections are explicitly registered; defer hidden content until
    -- the completed native section-selection callback styles the visible page.
    local visualFrames = setmetatable({}, {__mode = "k"})
    local scan = H.Scan
    H.Scan = function(root, callback, visit, excluded)
        -- New visual layers can be created during this same traversal.
        local exclude = setmetatable({}, {__index = visualFrames})
        for f, value in pairs(excluded or {}) do exclude[f] = value end
        local options = Frame(_G.DetailsOptionsWindow)
        for _, section in pairs(options and options.sectionFramesContainer or {}) do
            local page = Frame(section)
            if H.Allowed(page) and page.IsShown and not page:IsShown() then exclude[page] = true end
        end
        return scan(root, callback, visit, exclude)
    end
    local controls, headingTints = {}, setmetatable({}, {__mode = "k"})
    local function OptionOwned(f)
        for _ = 1, 24 do
            if not H.Allowed(f) then return false end
            if f == _G.DetailsOptionsWindow or f == _G.DetailsPluginContainerWindow then return true end
            f = f.GetParent and f:GetParent()
        end
        return false
    end
    local readableBackground, readableControls = nil, {}
    local function Gradient(texture, direction, r, g, b, first, last)
        texture:SetColorTexture(1, 1, 1, 1)
        if texture.SetGradient and CreateColor then
            texture:SetGradient(direction, CreateColor(r, g, b, first), CreateColor(r, g, b, last))
        elseif texture.SetGradientAlpha then
            texture:SetGradientAlpha(direction, r, g, b, first, r, g, b, last)
        else texture:SetColorTexture(r, g, b, math.max(first, last) * 0.5) end
    end
    state.ReadableBackground = function(f)
        if f ~= Frame(_G.DetailsOptionsWindow) then return end
        if not readableBackground or readableBackground.owner ~= f then
            local layer = CreateFrame("Frame", nil, f)
            visualFrames[layer] = true
            layer:SetAllPoints(f); layer:EnableMouse(false)
            if layer.SetFrameLevel and f.GetFrameLevel then layer:SetFrameLevel(f:GetFrameLevel()) end
            local d = {owner = f, layer = layer}; readableBackground = d
            d.base = layer:CreateTexture(nil, "BACKGROUND", nil, -4); d.base:SetAllPoints(layer)
            d.left = layer:CreateTexture(nil, "BACKGROUND", nil, -3)
            d.left:SetPoint("TOPLEFT", layer, "TOPLEFT"); d.left:SetPoint("BOTTOMRIGHT", layer, "BOTTOM")
            d.right = layer:CreateTexture(nil, "BACKGROUND", nil, -3)
            d.right:SetPoint("TOPLEFT", layer, "TOP"); d.right:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT")
            d.top = layer:CreateTexture(nil, "BACKGROUND", nil, -2)
            d.top:SetPoint("TOPLEFT", layer, "TOPLEFT"); d.top:SetPoint("BOTTOMRIGHT", layer, "RIGHT")
            d.bottom = layer:CreateTexture(nil, "BACKGROUND", nil, -2)
            d.bottom:SetPoint("TOPLEFT", layer, "LEFT"); d.bottom:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT")
        end
        local d = readableBackground
        local r, g, b = 0.055, 0.055, 0.06
        if S.GetPanelColor then r, g, b = S.GetPanelColor() end
        r, g, b = math.max(0.055, r), math.max(0.055, g), math.max(0.06, b)
        if d.r == r and d.g == g and d.b == b then return end
        d.r, d.g, d.b = r, g, b
        d.base:SetColorTexture(r, g, b, 0.82)
        local lr, lg, lb = math.min(1, r + 0.15), math.min(1, g + 0.15), math.min(1, b + 0.15)
        Gradient(d.left, "HORIZONTAL", lr, lg, lb, 0, 0.5)
        Gradient(d.right, "HORIZONTAL", lr, lg, lb, 0.5, 0)
        Gradient(d.top, "VERTICAL", 0, 0, 0, 0, 0.14)
        Gradient(d.bottom, "VERTICAL", 0, 0, 0, 0.14, 0)
    end
    state.ControlContrast = function(f, widget, method)
        if not OptionOwned(f) then return end
        if method == "switch" or method == "dropdown" or method == "input" then
            local d = readableControls[f]
            if not d then
                local layer = CreateFrame("Frame", nil, f)
                visualFrames[layer] = true
                layer:SetAllPoints(f); layer:EnableMouse(false)
                if layer.SetFrameLevel and f.GetFrameLevel then layer:SetFrameLevel(f:GetFrameLevel()) end
                d = {layer = layer}; readableControls[f] = d
                d.fill = layer:CreateTexture(nil, "BACKGROUND", nil, -2); d.fill:SetAllPoints(layer)
                for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
                    local edge = layer:CreateTexture(nil, "BORDER")
                    edge:SetColorTexture(0.28, 0.28, 0.3, 0.45)
                    if side == "TOP" or side == "BOTTOM" then
                        edge:SetPoint(side .. "LEFT", layer, side .. "LEFT"); edge:SetPoint(side .. "RIGHT", layer, side .. "RIGHT"); edge:SetHeight(1)
                    else
                        edge:SetPoint("TOP" .. side, layer, "TOP" .. side); edge:SetPoint("BOTTOM" .. side, layer, "BOTTOM" .. side); edge:SetWidth(1)
                    end
                end
            end
            local shade = method == "switch" and 0.095 or 0.065
            if d.shade ~= shade then d.fill:SetColorTexture(shade, shade, shade + 0.005, 1); d.shade = shade end
        end
        local row = widget and widget.highlightFrame
        if H.Allowed(row) and OptionOwned(row) and H.Texture(row.highlightTexture) then
            -- DF already owns the row bounds, hover visibility and click handlers.
            -- Repaint its plain background only; no new clickable row is introduced.
            for _, region in ipairs(H.Regions(row)) do
                if H.Texture(region) and region ~= row.highlightTexture and region.GetDrawLayer and region:GetDrawLayer() == "ARTWORK" then
                    region:SetVertexColor(1, 1, 1, 1); region:SetColorTexture(0, 0, 0, 0.12)
                end
            end
        end
    end
    local function LabelTone(text, widget, heading)
        text = Frame(text)
        if not H.Allowed(text) or text:GetObjectType() ~= "FontString" then return end
        H.Font(text)
        if widget and (widget.lockdown or widget.widget and widget.widget.IsEnabled and not widget.widget:IsEnabled()) then
            text:SetTextColor(0.5, 0.5, 0.5, 1)
        elseif heading then text:SetTextColor(S.GetAccentColor())
        else text:SetTextColor(0.88, 0.88, 0.9, 1) end
    end
    state.OptionLabels = function(f)
        if not OptionOwned(f) then return end
        for _, key in ipairs({"title", "titulo", "instancetext", "editingGroupLabel"}) do
            LabelTone(f[key], nil, true)
        end
        -- BuildMenu exposes standalone labels separately from paired controls.
        -- Only its gold/orange headings change; descriptions and semantic colours stay native.
        for _, label in ipairs(f.widget_list_by_type and f.widget_list_by_type.label or {}) do
            local text = Frame(label)
            if H.Allowed(text) and text.GetTextColor then
                local r, g, b = text:GetTextColor()
                local old = headingTints[text]
                local heading = r and r > 0.7 and g > 0.4 and b < 0.3
                    or old and r == old[1] and g == old[2] and b == old[3]
                if heading then
                    LabelTone(text, nil, true)
                    headingTints[text] = {S.GetAccentColor()}
                else headingTints[text] = nil end
            end
        end
    end
    state.Control = function(f, kind)
        local widget = f.MyObject
        if type(widget) ~= "table" then return false end
        local method = widget.type
        if kind == "EditBox" and widget.value_box == f then
            S.EditBox(f, {padInput = false}); state.ControlContrast(f, widget, "input"); return true
        end
        local supported = method == "switch" or method == "dropdown" or kind == "Slider" and method == "slider"
            or kind == "Button" and method == "button" and OptionOwned(f) and (f.GetFontString and f:GetFontString() or f.Text or f.text)
        if not supported then return false end
        if ns.DetailsSettings().menus == false or not ns.IsEnabled(C.module) or Busy() then return true end
        local d = controls[f]
        if not d or d.widget ~= widget then
            d = {widget = widget}; controls[f] = d
            d.paint = function()
                if not H.Allowed(f) or f.MyObject ~= widget or not Owned(f) or d.painting then return end
                d.painting = true
                local ok, err = pcall(state.Control, f, kind)
                d.painting = false
                if not ok then error(err) end
            end
            -- Native template/setter bursts touch just this control, not every window.
            for _, name in ipairs({"SetTemplate", "Enable", "Disable"}) do H.Hook(widget, name, d.paint) end
            if method == "switch" then
                H.Hook(widget, "SetCheckedTexture", d.paint)
                H.Hook(widget, "SetAsCheckBox", d.paint)
                H.Hook(widget, "SetValue", d.paint)
            end
            local function PaintCurrent()
                local current = controls[f]
                if current then current.paint() end
            end
            H.Script(f, "OnEnable", PaintCurrent); H.Script(f, "OnDisable", PaintCurrent)
            H.Script(f, "OnShow", PaintCurrent)
            if kind == "Button" then H.Script(f, "OnClick", PaintCurrent) end
        end
        f.euiDetailsOptionVisual = true
        if method == "switch" then
            f.euiDetailsCheck = H.Texture(widget.checked_texture)
            f.euiDetailsToggle = H.Texture(widget.toggle_knob)
            S.Button(f, {"euiDetailsCheck", "euiDetailsToggle", "text", "Text", "label"})
            if f.SetBackdrop then f:SetBackdrop(nil) end
            if f.euiDetailsCheck and not widget.is_toggle then
                local mark = f.euiDetailsCheck
                mark:SetVertexColor(1, 1, 1, 1)
                if widget.lockdown or f.IsEnabled and not f:IsEnabled() then mark:SetColorTexture(0.4, 0.4, 0.4, 0.8)
                else mark:SetColorTexture(S.GetAccentColor()) end
                mark:ClearAllPoints()
                mark:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -4)
                mark:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
                -- Native Show/Hide and alpha continue to reflect value/lockdown.
            end
            LabelTone(widget.hasLabel or widget.label, widget)
        elseif method == "dropdown" then
            local icon = H.Texture(widget.icon); local alpha = icon and icon:GetAlpha()
            if not d.dropdown then
                local before = {}; for _, region in ipairs(H.Regions(f)) do before[region] = true end
                S.Dropdown(f)
                for _, region in ipairs(H.Regions(f)) do
                    if not before[region] and H.Texture(region) and region.GetDrawLayer and region:GetDrawLayer() == "OVERLAY" then d.arrow = region end
                end
                d.dropdown = true
            end
            if icon then icon:SetAlpha(alpha) end
            H.Fade(f.statusbar)
            local native = H.Texture(f.arrowTexture)
            if native and d.arrow then H.Fade(d.arrow) end
            for _, arrow in pairs({base = native or d.arrow, hover = H.Texture(f.arrowTexture2)}) do
                arrow:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png")
                arrow:SetTexCoord(0, 1, 0, 1); arrow:SetSize(10, 7)
                arrow:ClearAllPoints(); arrow:SetPoint("RIGHT", f, "RIGHT", -7, 0)
                arrow:SetVertexColor(0.8, 0.8, 0.8, 1); arrow:SetAlpha(1)
            end
            if H.Allowed(f.dropdownframe) then
                H.Script(f.dropdownframe, "OnShow", function() C.RefreshControlsNow(f.dropdownframe) end)
                C.Panel(f.dropdownframe)
            end
        elseif kind == "Slider" then
            H.LegacySlider(f)
            local thumb = f.GetThumbTexture and H.Texture(f:GetThumbTexture())
            if thumb and f.GetOrientation and f:GetOrientation() == "HORIZONTAL" then
                thumb:SetSize(8, 14)
                -- Newer DF exposes a native numeric editor. Reserve room inside
                -- the original control width, keeping the existing row footprint.
                if type(widget.SetValueBox) == "function" and f.GetWidth then
                    if d.manageValueBox == nil then d.manageValueBox = not widget.value_box_shown end
                    if d.manageValueBox then
                        local width = f:GetWidth()
                        if width ~= d.trackWidth then d.width = width end
                        if d.width and d.width >= 100 then
                            d.trackWidth = d.width - 40
                            if width ~= d.trackWidth then f:SetWidth(d.trackWidth) end
                            if not widget.value_box_shown or widget.value_box_side ~= "right" then widget:SetValueBox(true, "right", 36, 18, 4) end
                        end
                    end
                    -- An existing native value-box layout keeps its own side/size.
                    if H.Allowed(widget.value_box) then
                        H.Script(widget.value_box, "OnShow", d.paint)
                        S.EditBox(widget.value_box, {padInput = false})
                        state.ControlContrast(widget.value_box, widget, "input")
                    end
                end
            end
        else
            f.euiDetailsIcon = H.Texture(widget.icon)
            S.Button(f, {"euiDetailsIcon", "text", "Text", "label"})
            if f.SetBackdrop then f:SetBackdrop(nil) end
            LabelTone((f.GetFontString and f:GetFontString()) or f.Text or f.text, widget)
        end
        state.ControlContrast(f, widget, method)
        return true
    end
    state.Section = function(button)
        local section = state.sections[button]
        if not section then return false end
        if ns.DetailsSettings().menus == false or not ns.IsEnabled(C.module) then return true end
        if Busy() then return true end
        -- SelectOptionsSection resets every native button template, including
        -- the hover/leave colours. Keep navigation out of generic button scans.
        if button.SetBackdrop then button:SetBackdrop(nil) end
        if button.HaveRoundedCorners and button.DisableRoundedCorners then button:DisableRoundedCorners() end
        local widget = button.MyObject
        if widget then H.Fade(H.Texture(widget.icon)) end
        H.Fade(H.Texture(button.icon))
        if H.Tab(button, section:IsShown()) then
            for _, text in ipairs(H.Regions(button)) do
                local native = button.GetFontString and button:GetFontString()
                if text ~= native and text.GetObjectType and text:GetObjectType() == "FontString" then
                    LabelTone(text, widget, section:IsShown())
                end
            end
            -- EUI supplies the visible label; DF templates can recolour the
            -- hidden native label again, so keep it from doubling the text.
            H.Fade(button.GetFontString and button:GetFontString())
        else S.Button(button, {"Text", "text"}) end
        for _, text in ipairs(H.Regions(button)) do H.Font(text) end
        return true
    end
    state.DesignerRow = function(row)
        if not state.designerRows[row] then return false end
        H.Font(row.Label)
        -- These are pooled object selectors, not ordinary action buttons.
        -- Keep the native label, object icon, expand toggle and selection action.
        return true
    end
    state.BindDesigner = function(editor)
        if not H.Allowed(editor) or not Owned(editor) or ns.DetailsSettings().menus == false then return end
        H.Hook(editor, "EditObject", C.RefreshNow)
        local function DisabledOptions()
            if ns.DetailsSettings().menus ~= false then C.RefreshControlsNow(editor) end
        end
        H.Hook(editor, "RefreshDisabledOptions", function() H.Queue(editor, DisabledOptions) end)
        local selector = editor.GetObjectSelector and editor:GetObjectSelector()
        if not H.Allowed(selector) then return end
        local function Rows()
            if ns.DetailsSettings().menus == false or Busy() then return end
            for _, row in pairs(selector.GetLines and selector:GetLines() or {}) do
                if H.Allowed(row) then state.designerRows[row] = true; state.DesignerRow(row) end
            end
        end
        H.Hook(selector, "Refresh", Rows)
        if not state.designers[editor] then
            state.designers[editor] = true
            -- Populate from already registered objects once, using the editor's
            -- native method. Do not force creation or poll for the designer.
            if selector.RefreshMe then H.Safe(selector.RefreshMe, selector) end
        end
        Rows()
    end
    local function Row(row)
        if not MeterWanted() or not H.Allowed(row) or Busy() then return end
        local look = state.look
        if not look then return end
        -- Only appearance: never read actor GUIDs, names, values or combat data.
        if H.Allowed(row.statusbar) and row.statusbar.SetStatusBarTexture then
            local texture = H.Texture(row.textura)
            if texture then
                if not state.textures[texture] then state.textures[texture] = {path = texture:GetTexture(), profile = Profile()} end
                if texture:GetTexture() ~= look.texture then texture:SetTexture(look.texture) end
            else row.statusbar:SetStatusBarTexture(look.texture) end
        end
        for _, key in ipairs({"lineText1", "lineText2", "lineText3", "lineText4",
            "lineText11", "lineText12", "lineText13", "lineText14"}) do
            local text = row[key]
            if H.Allowed(text) and text.SetFont and look.font then
                if not state.texts[text] then state.texts[text] = {font = {text:GetFont()}, profile = Profile()} end
                local size = (key == "lineText1" or key == "lineText11") and look.leftSize or look.rightSize
                local oldFont, oldSize, oldFlags = text:GetFont()
                if oldFont ~= look.font or oldSize ~= size or (oldFlags or "") ~= look.flags then
                    text:SetFont(look.font, size, look.flags)
                end
            end
        end
        -- Details owns class/spec atlas coordinates, highlights and row actions.
        if state.layout then state.layout.Row(row) end
    end
    local function Rows(instance)
        if state.applying or not MeterWanted(instance) or TinyWindow(instance) or not ns.IsEnabled(C.module) or Busy() then return end
        for _, row in pairs(instance.barras or {}) do Row(row) end
    end
    state.Row = Row
    local function Fade(art)
        if not H.Allowed(art) or not art.SetAlpha then return end
        local kind = art:GetObjectType()
        if kind ~= "Texture" and kind ~= "FontString" then return end
        if not state.textures[art] then
            state.textures[art] = {alpha = art:GetAlpha(), profile = Profile(), instance = state.paintInstance}
            local painting = false
            H.Hook(art, "SetAlpha", function()
                local snapshot = state.textures[art]
                if painting or state.restoring or not snapshot or not MeterWanted(snapshot.instance) then return end
                painting = true; art:SetAlpha(0); painting = false
            end)
        end
        art:SetAlpha(0)
    end
    state.layout = ns.CreateDetailsLayout(H, function(instance) return not state.restoring and MeterWanted(instance) and ns.IsEnabled(C.module) end, refresh, Fade)
    state.RestoreMeters = function()
        if Busy() then return end
        state.applying, state.restoring = true, true
        -- Native ChangeSkin can reanchor controls; release our layout first.
        if state.meterActive then state.layout.Restore() end
        for _, instance in pairs(D:GetAllInstances() or {}) do
            local restored = RestoreSettings(instance)
            -- Details retains instances whose windows have not been built or were closed.
            -- Restore their saved settings without asking its renderer to touch a missing frame.
            if restored and H.Allowed(instance.baseframe) and instance.ChangeSkin then
                H.Safe(instance.ChangeSkin, instance)
            end
        end
        if not state.meterActive then state.applying, state.restoring = false, false; return end
        state.meterActive = false
        for _, entry in pairs(state.meters) do
            entry.bg:SetAlpha(0)
            if entry.header then entry.header:SetAlpha(0) end
            if entry.title and entry.height then entry.title:SetHeight(entry.height) end
            for frame, old in pairs(entry.backdrops) do
                frame:SetBackdrop(old.backdrop)
                if frame.SetBackdropColor and old.color[1] then frame:SetBackdropColor(unpack(old.color)) end
                if frame.SetBackdropBorderColor and old.border[1] then frame:SetBackdropBorderColor(unpack(old.border)) end
            end
            entry.title, entry.height, entry.backdrops = nil, nil, {}
        end
        for art, old in pairs(state.textures) do
            if old.alpha ~= nil then art:SetAlpha(old.alpha) end
            if old.path and old.profile == Profile() then art:SetTexture(old.path) end
        end
        for text, old in pairs(state.texts) do
            if old.profile == Profile() and old.font[1] then text:SetFont(unpack(old.font)) end
        end
        state.textures, state.texts = {}, {}
        local plugin = TinyPlugin()
        if plugin and plugin.RefreshRows then H.Safe(plugin.RefreshRows, plugin) end
        state.applying, state.restoring = false, false
    end
    state.Meter = function(instance)
        local f = instance and instance.baseframe
        if not H.Allowed(f) then return end
        state.paintInstance = instance
        state.meterActive = true
        local look = state.look
        local entry = state.meters[f]
        if not entry then
            entry = {backdrops = {}}; state.meters[f] = entry
            local bg = CreateFrame("Frame", nil, f)
            bg:SetAllPoints(f); bg:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1)); bg:EnableMouse(false)
            entry.bg = bg:CreateTexture(nil, "BACKGROUND"); entry.bg:SetAllPoints(bg)
            H.Script(f, "OnShow", refresh)
        end
        Backup(instance, true)
        entry.bg:SetAlpha(1)
        entry.bg:SetColorTexture(unpack(look.bg))
        -- Hide only named native decoration, never the frame, rows or buttons.
        for _, key in ipairs({"barra_esquerda", "barra_direita", "barra_fundo", "wallpaper"}) do Fade(f[key]) end
        local header = f.cabecalho or {}
        for _, key in ipairs({"ball", "ball_r", "emenda", "top_bg"}) do Fade(header[key]) end
        local title = f.titleBar
        if H.Allowed(title) then
            if not entry.title then entry.title, entry.height = title, title:GetHeight() end
            title:SetHeight(look.headerHeight)
            Fade(title.texture)
            if not entry.header then entry.header = title:CreateTexture(nil, "BACKGROUND"); entry.header:SetAllPoints(title) end
            entry.header:SetAlpha(1)
            local c = look.header; entry.header:SetColorTexture(c.r or 0, c.g or 0, c.b or 0, look.headerAlpha)
        end
        for _, frame in pairs({f, instance.bgdisplay}) do
            if H.Allowed(frame) and frame.SetBackdrop then
                if not entry.backdrops[frame] then
                    entry.backdrops[frame] = {backdrop = frame:GetBackdrop(), color = {frame:GetBackdropColor()}, border = {frame:GetBackdropBorderColor()}}
                end
                frame:SetBackdrop(nil)
            end
        end
        -- Native setters maintain Details' row geometry. Do not change window
        -- anchors, size, groups, segment, combat data or click scripts.
        local info = instance.row_info
        if not TinyWindow(instance) and info and type(info.textR_show_data) == "table" and instance.SetBarRightTextSettings then
            local data = info.textR_show_data
            if instance.use_multi_fontstrings ~= false or info.textR_enable_custom_text
                or not data[1] or not data[2] or data[3] or info.textR_bracket ~= "(" or info.textR_separator ~= "NONE" then
                state.applying = true
                instance.use_multi_fontstrings = false; info.textR_enable_custom_text = false
                H.Safe(instance.SetBarRightTextSettings, instance, true, true, false, "(", "NONE")
                state.applying = false
            end
        end
        local media = LibStub and LibStub("LibSharedMedia-3.0", true)
        local textureName
        if media and media.Register then media:Register("statusbar", MEDIA_NAME, look.texture); textureName = MEDIA_NAME end
        if info and instance.SetBarSettings and (info.height ~= look.height
            or not info.space or info.space.between ~= look.spacing
            or textureName and info.texture ~= textureName) then
            state.applying = true
            H.Safe(instance.SetBarSettings, instance, look.height, textureName, nil, nil, nil, nil, nil, nil, nil, nil, look.spacing)
            state.applying = false
            local plugin = TinyWindow(instance) and TinyPlugin()
            if plugin and plugin.RefreshRows then H.Safe(plugin.RefreshRows, plugin) end
        end
        Rows(instance)
        state.layout.Window(instance, look)
        state.paintInstance = nil
    end
    state.TinyRow = function(row)
        local plugin = TinyPlugin()
        local instance = plugin and plugin.GetPluginInstance and plugin:GetPluginInstance()
        if state.restoring or not instance or not TinyWindow(instance) or not MeterWanted(instance)
            or not ns.IsEnabled(C.module) or Busy() then return end
        local bar = Frame(row)
        if not H.Allowed(bar) then return end
        local texture = bar.GetStatusBarTexture and H.Texture(bar:GetStatusBarTexture())
        if texture then
            if not state.textures[texture] then state.textures[texture] = {path = texture:GetTexture(), profile = Profile()} end
            if texture:GetTexture() ~= state.look.texture then texture:SetTexture(state.look.texture) end
        end
        for _, key in ipairs({"lefttext", "righttext"}) do
            local text = bar[key]
            if H.Allowed(text) then
                if not state.texts[text] then state.texts[text] = {font = {text:GetFont()}, profile = Profile()} end
                text:SetFont(state.look.font, key == "lefttext" and state.look.leftSize or state.look.rightSize, state.look.flags)
            end
        end
    end
    state.BindTiny = function()
        local plugin = TinyPlugin()
        H.Hook(plugin, "RefreshRow", function(_, row) if state.look then state.TinyRow(row) end end)
    end
    state.ApplyMeters = function()
        if Busy() then return end
        local wanted, kinds, changed = {}, {}, false
        for _, instance in pairs(D:GetAllInstances() or {}) do
            wanted[instance], kinds[instance] = MeterWanted(instance), TinyWindow(instance)
            if state.wanted and state.wanted[instance] ~= nil and (state.wanted[instance] ~= wanted[instance] or state.kinds[instance] ~= kinds[instance]) then changed = true end
        end
        if changed or not MeterWanted() then state.RestoreMeters() end
        state.wanted, state.kinds = wanted, kinds
        for instance, active in pairs(wanted) do if active then state.Meter(instance) end end
        local plugin = TinyPlugin()
        for _, row in pairs(plugin and plugin.Rows or {}) do state.TinyRow(row) end
    end

    local function MenuTexts(frame, callback)
        for _, line in pairs(frame.Lines or {}) do
            if H.Allowed(line) then
                -- Cooltip fontstrings belong to the line's statusbar child,
                -- but are also exposed through these documented line fields.
                for _, key in ipairs({"leftText", "rightText"}) do
                    local text = line[key]
                    if H.Allowed(text) then callback(text) end
                end
            end
        end
    end
    -- Cooltip is shared with other addons: change its existing native backdrop
    -- only while owned by Details, and restore it on transfer or hiding.
    local function Restore(frame)
        local old = state.snapshots[frame]
        if not old then return end
        state.snapshots[frame] = nil
        frame:SetBackdrop(old.backdrop)
        frame:SetBackdropColor(unpack(old.color)); frame:SetBackdropBorderColor(unpack(old.border))
        for text, data in pairs(old.fonts) do text:SetFont(unpack(data)) end
        for art, data in pairs(old.art) do
            art:SetAlpha(data.alpha)
            if data.changed then
                art:SetTexture(data.texture)
                if data.coords then art:SetTexCoord(unpack(data.coords)) end
                art:SetVertexColor(unpack(data.color))
            end
        end
        if old.rounded ~= nil then
            if old.rounded then frame:EnableRoundedCorners() else frame:DisableRoundedCorners() end
        end
    end
    local function MenuArt(old, art, color)
        if not H.Texture(art) then return end
        if not old.art[art] then
            old.art[art] = {alpha = art:GetAlpha()}
            if color then
                local data = old.art[art]
                data.changed = true
                data.texture, data.color = art:GetTexture(), {art:GetVertexColor()}
                if art.GetTexCoord then data.coords = {art:GetTexCoord()} end
            end
        end
        if color then
            art:SetTexture(WHITE); art:SetTexCoord(0, 1, 0, 1); art:SetVertexColor(unpack(color)); art:SetAlpha(1)
        else art:SetAlpha(0) end
    end
    local function Cooltip()
        local tip = _G.GameCooltip
        if not tip or Busy() then return end
        local owner = tip.GetOwner and tip:GetOwner()
        local owned = ns.IsEnabled(C.module) and ns.DetailsSettings().menus ~= false and Owned(owner)
        for _, f in pairs({tip.frame1, tip.frame2}) do
            if H.Allowed(f) and f.SetBackdrop and f.GetBackdropColor and f.GetBackdropBorderColor then
                if not owned then Restore(f)
                else
                    if not state.snapshots[f] then
                        local old = {backdrop = f:GetBackdrop(), color = {f:GetBackdropColor()}, border = {f:GetBackdropBorderColor()}, fonts = {}, art = {}}
                        if f.HaveRoundedCorners and f.DisableRoundedCorners and f.EnableRoundedCorners then old.rounded = not f.disabled end
                        state.snapshots[f] = old
                        MenuTexts(f, function(text)
                            local font, size, flags = text:GetFont()
                            if font then old.fonts[text] = {font, size, flags or ""} end
                        end)
                    end
                    local old = state.snapshots[f]
                    if old.rounded ~= nil then f:DisableRoundedCorners() end
                    MenuArt(old, f.frameBackgroundTexture)
                    MenuArt(old, f.gradientTexture)
                    f:SetBackdrop({bgFile = WHITE, edgeFile = WHITE, edgeSize = 1})
                    local r, g, b, a = S.GetPanelColor(); f:SetBackdropColor(r, g, b, a)
                    f:SetBackdropBorderColor(0.055, 0.055, 0.055, 1)
                    MenuTexts(f, function(text)
                        -- Pooled submenu lines can appear after the first show.
                        local old = state.snapshots[f]
                        if not old.fonts[text] then
                            local font, size, flags = text:GetFont()
                            if font then old.fonts[text] = {font, size, flags or ""} end
                        end
                        H.Font(text)
                    end)
                    local ar, ag, ab = S.GetAccentColor()
                    for _, line in pairs(f.Lines or {}) do
                        if H.Allowed(line) then
                            -- Only decorative hover/separator textures: leave
                            -- icons, arrows, status values and actions native.
                            MenuArt(old, line.background, {ar, ag, ab, 0.14})
                            MenuArt(old, line.divbar, {0.14, 0.14, 0.14, 1})
                        end
                    end
                    H.Script(f, "OnHide", function() Restore(f) end)
                    H.Script(f, "OnShow", Cooltip)
                end
            end
        end
    end
    state.Cooltip = Cooltip
    state.Restore = Restore
    ns.DetailsSettingsChanged = function(key)
        if key == "meter" or key == "tiny" then C.RefreshNow() end
        state.Cooltip()
        refresh()
    end
    state.QuickMenu = function(_, owner, instance)
        local tip = _G.GameCooltip
        local header = instance and instance.baseframe and instance.baseframe.cabecalho
        local button = header and header.modo_selecao
        button = Frame(button)
        if not tip or not tip.AddLine or not tip.AddMenu or owner ~= button or state.quickAdded then return end
        state.quickAdded = true
        tip:AddLine("EUI AddonSkins")
        tip:AddMenu(1, function() end)
        for _, option in ipairs({{"meter", "Style Details meters"}, {"tiny", "Style Tiny Threat"}, {"menus", "Skin menus and options (reload)"}}) do
            local key, label = option[1], option[2]
            tip:AddLine(label, ns.DetailsSettings()[key] and "On" or "Off", 2)
            tip:AddMenu(2, function()
                ns.SetDetailsSetting(key, not ns.DetailsSettings()[key])
                if tip.Hide then tip:Hide() end
            end)
        end
        tip:AddLine("Open skin settings", nil, 2)
        tip:AddMenu(2, ns.OpenDetailsSettings)
    end
    if D.CreateEventListener then
        state.listener = D:CreateEventListener()
        for _, event in ipairs({"DETAILS_STARTED", "DETAILS_INSTANCE_OPEN", "DETAILS_INSTANCE_SIZECHANGED", "DETAILS_PROFILE_APPLYED"}) do
            state.listener:RegisterEvent(event, function() if ns.IsEnabled(C.module) then refresh() end end)
        end
        state.listener:RegisterEvent("DETAILS_INSTANCE_NEWROW", function(_, instance, row)
            if ns.IsEnabled(C.module) and MeterWanted(instance) and not TinyWindow(instance) then H.Safe(Row, row) end
        end)
    end
    H.Hook(D, "InstanceRefreshRows", Rows)
    for _, method in ipairs({"RefreshTitleBarText", "TitleTextTickTimer", "SetTitleBarText"}) do
        H.Hook(D, method, function(instance, other)
            state.layout.Title(method == "TitleTextTickTimer" and other or instance)
        end)
    end
    H.Hook(D, "RefreshMainWindow", function(_, instance) state.layout.Title(instance) end)
    for _, name in ipairs({"SetMode", "SetDisplay"}) do H.Hook(D, name, C.RefreshNow) end
    H.Hook(D.RaidTables, "EnableRaidMode", C.RefreshNow)
    H.Hook(D, "InstallPlugin", refresh)
    H.Hook(D, "SetMenuOwner", state.QuickMenu)
    -- Native raid-menu callbacks receive Cooltip's Host as self, but the
    -- switch method expects nil (menu dispatch) or the raid-plugin manager.
    -- Adapt only exact callbacks generated by Details' own raid-menu builder.
    H.Hook(D, "MontaRaidOption", function()
        local tip, raid = _G.GameCooltip, D.RaidTables
        local original = raid and raid.switch
        if not tip or type(original) ~= "function" then return end
        if state.raidSwitchOriginal ~= original then
            state.raidSwitchOriginal = original
            state.raidSwitch = function(_, fixed, pluginName, instance, ...)
                local function Finish(...)
                    local header = instance and instance.baseframe and instance.baseframe.cabecalho
                    local button = Frame(header and header.atributo)
                    -- Modern Details buttons use OnEnter rather than legacy
                    -- injected CoolTip metadata. Refresh only the same open menu.
                    if H.Allowed(button) and tip.GetOwner and tip:GetOwner() == button then
                        local enter = button.GetScript and button:GetScript("OnEnter")
                        if enter then enter(button, nil, true, true)
                        elseif tip.Hide then tip:Hide() end
                    end
                    return ...
                end
                -- Supplying the manager avoids switch's obsolete ExecFunc path.
                return Finish(original(raid, fixed, pluginName, instance, ...))
            end
        end
        for index, callback in pairs(tip.FunctionsTableMain or {}) do
            if callback == original then tip.FunctionsTableMain[index] = state.raidSwitch end
        end
    end)
    for _, name in ipairs({"ChangeSkin", "SetBarSettings", "SetBarTextSettings", "ApplyProfile", "CreateInstance"}) do
        H.Hook(D, name, function() if not state.applying then refresh() end end)
    end
    for _, name in ipairs({"OpenOptionsWindow", "InitializeOptionsWindow", "OpenBreakdownWindow", "OpenSpecificBreakdownWindow",
        "FastReportWindow", "SendReportWindow", "SendReportTextWindow", "Reportar"}) do
        H.Hook(D, name, C.RefreshNow)
    end
    return state
end

ns.RegisterScopedSkin("Details", "Details!", {
    available = function() return type(_G.Details) == "table" and type(_G.Details.GetAllInstances) == "function" end,
    softBorders = true, preserveTextColors = true, immediateShow = true,
    borderlessButtons = function(f) return f.euiDetailsOptionVisual == true end,
    hooks = function(C, refresh)
        local state = Setup(C, refresh)
        state.BindTiny()
        local options = _G.Details222 and _G.Details222.OptionsPanel
        C.H.Hook(options, "SelectOptionsSection", C.RefreshNow)
        local tip = _G.GameCooltip
        C.H.Hook(tip, "Reset", function() state.quickAdded = false end)
        for _, name in ipairs({"ShowCooltip", "BuildCooltip", "BuildTooltip", "BuildTooltipSecondFrame", "SetHost", "ShowRoundedCorner", "HideRoundedCorner"}) do
            C.H.Hook(tip, name, state.Cooltip)
        end
    end,
    roots = function(C)
        local state = C.details
        state.combatPending = false; state.look = Look(C.S)
        for _, instance in pairs(_G.Details:GetAllInstances() or {}) do
            for _, key in ipairs({"baseframe", "rowframe", "windowSwitchButton", "bgframe"}) do
                local owner = instance[key]
                if C.H.Allowed(owner) then state.owners[owner] = true end
            end
        end
        state.ApplyMeters()
        local result = {}
        local function Add(value)
            local f = Frame(value)
            if C.H.Allowed(f) then
                state.roots[f] = true
                result[#result + 1] = {frame = f, options = {noTopBar = true,
                    noAccent = f == _G.DetailsOptionsWindow or f == _G.DetailsPluginContainerWindow}}
            end
        end
        local panel = ns.CreateDetailsSettingsPanel()
        if C.H.Allowed(panel) then result[#result + 1] = {frame = panel, mode = "controls"} end
        if ns.DetailsSettings().menus ~= false then
            local options = Frame(_G.DetailsOptionsWindow)
            for _, section in pairs(options and options.sectionFramesContainer or {}) do
                local button = C.H.Allowed(section) and Frame(section.sectionButton)
                if C.H.Allowed(section) and C.H.Allowed(button) then
                    state.sections[button] = section
                    local function Paint() state.Section(button) end
                    C.H.Hook(section.sectionButton, "SetTemplate", Paint)
                    C.H.Hook(section.sectionButton, "SetIcon", Paint)
                    Paint()
                end
            end
            for _, name in ipairs({"DetailsOptionsWindow", "DetailsPluginContainerWindow", "DetailsBreakdownWindow",
                "DetailsReportWindow", "DetailsCopyPasteFrame2"}) do Add(_G[name]) end
            Add(_G.Details.BreakdownWindowFrame); Add(_G.Details.janela_report)
            state.BindDesigner(_G.DetailsOptionsDesignerEditor)
        end
        state.Cooltip()
        return result
    end,
    visit = function(C, f, kind, refresh)
        local H, S = C.H, C.S
        C.details.ReadableBackground(f)
        C.details.OptionLabels(f)
        local options = Frame(_G.DetailsOptionsWindow)
        local name = options and options.GetName and options:GetName()
        if kind == "Button" and name and f == _G[name .. "CloseButton"] then S.CloseButton(f); return true end
        if C.details.Section(f) then return true end
        if C.details.DesignerRow(f) then return true end
        -- Preserve displayed values and semantic colours in breakdown bars.
        if kind == "StatusBar" then
            local texture = C.details.look.texture
            if f.SetStatusBarTexture then f:SetStatusBarTexture(texture) end
            for _, text in ipairs(H.Regions(f)) do H.Font(text) end
            return true
        end
        if C.details.Control(f, kind) then return true end
        local widget = f.MyObject
        if kind == "EditBox" and type(widget) == "table" and widget.type == "textentry"
            and not (f.IsMultiLine and f:IsMultiLine()) then
            -- DF anchors the field just two pixels beyond its description.
            -- Blizzard padding expands the field leftward across that label.
            S.EditBox(f, {padInput = false})
            C.details.ControlContrast(f, widget, "input")
            for _, text in ipairs(H.Regions(f)) do H.Font(text) end
            return true
        end
        if kind == "Slider" then
            H.LegacySlider(f)
            local thumb = f.GetThumbTexture and H.Texture(f:GetThumbTexture())
            if thumb and thumb.SetSize and f.GetOrientation and f:GetOrientation() == "HORIZONTAL" then thumb:SetSize(8, 14) end
            return true
        end
        if f.spellId or f.spellID or f.itemId or f.itemID then
            for _, text in ipairs(H.Regions(f)) do H.Font(text) end
            return true
        end
    end,
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("Details", DefineSkin)
else DefineSkin() end
