local ADDON, ns = ...
local OPACITY_APP = "EUIAddonSkinsRestedXP"
local function DefineSkin()
-- AceConfig widgets are shared pools. Only our child layers enter EUI's skin
-- registry; restore native regions/backdrops before a widget is reused elsewhere.
local function OptionsSkin(S, H, module, addon, foreverLook)
    local unpack = unpack or table.unpack
    local states, roots = setmetatable({}, {__mode = 'k'}), setmetatable({}, {__mode = 'k'})
    local Paint, PaintTree
    local function App(name)
        local title = addon.title or 'RestedXP Guides'
        return name == OPACITY_APP or name == title or type(name) == 'string' and name:sub(1, #title + 1) == title .. '/'
    end
    local function Owned(widget)
        for _ = 1, 24 do
            if type(widget) ~= 'table' then return false end
            if widget.userdata and widget.userdata.appName then return App(widget.userdata.appName) end
            if roots[widget] then return true end
            widget = widget.parent
        end
        return false
    end
    local function Restore(d)
        if not d.active then return end
        d.active = false
        for _, layer in pairs(d.layers) do layer:SetAlpha(0) end
        for region, saved in pairs(d.saved) do
            if saved.alpha then region:SetAlpha(saved.alpha) end
            if saved.font and saved.font[1] then region:SetFont(unpack(saved.font)) end
            if saved.color then region:SetTextColor(unpack(saved.color)) end
            if saved.tint then region:SetVertexColor(unpack(saved.tint)) end
            if saved.insets then region:SetTextInsets(unpack(saved.insets)) end
            if saved.justify then region:SetJustifyV(saved.justify) end
            if saved.hasBackdrop then
                region:SetBackdrop(saved.backdrop)
                if saved.bg then region:SetBackdropColor(unpack(saved.bg)) end
                if saved.edge then region:SetBackdropBorderColor(unpack(saved.edge)) end
            end
        end
        d.saved = {}
    end
    local function Save(d, region)
        local saved = d.saved[region]
        if not saved then saved = {}; d.saved[region] = saved end
        return saved
    end
    local function Fade(d, frame, keep)
        if not H.Allowed(frame) then return end
        for _, region in ipairs(H.Regions(frame)) do
            if H.Texture(region) and not (keep and keep[region]) then
                local saved = Save(d, region)
                if saved.alpha == nil then saved.alpha = region:GetAlpha() end
                region:SetAlpha(0)
            end
        end
        if frame.GetBackdrop and frame.SetBackdrop then
            local saved = Save(d, frame)
            if not saved.hasBackdrop then
                saved.hasBackdrop, saved.backdrop = true, frame:GetBackdrop()
                if frame.GetBackdropColor then saved.bg = {frame:GetBackdropColor()} end
                if frame.GetBackdropBorderColor then saved.edge = {frame:GetBackdropBorderColor()} end
            end
            frame:SetBackdrop(nil)
        end
    end
    local function Font(d, text, r, g, b, alpha)
        if not H.Allowed(text) or not text.GetFont then return end
        local saved = Save(d, text)
        if not saved.font then saved.font, saved.color = {text:GetFont()}, {text:GetTextColor()} end
        local path, _, flags = text:GetFont()
        local target, targetFlags = S.GetFont()
        if path ~= target or (flags or '') ~= (targetFlags or '') then S.Font(text) end
        if r then
            local cr, cg, cb, ca = text:GetTextColor()
            alpha = alpha or ca
            if cr ~= r or cg ~= g or cb ~= b or ca ~= alpha then text:SetTextColor(r, g, b, alpha) end
        end
    end
    local function LayerLevel(d, layer, host)
        if not d.active or not ns.IsEnabled(module) then return end
        if InCombatLockdown and InCombatLockdown() then module.optionsWaiting = true; return end
        local level = math.max(0, host:GetFrameLevel() - 1)
        if layer:GetFrameLevel() ~= level then layer:SetFrameLevel(level) end
    end
    local function Layer(d, key, host, method, options)
        if not H.Allowed(host) then return end
        local layer = d.layers[key]
        if not layer then
            layer = CreateFrame(method == 'PageButton' and 'Button' or 'Frame', nil, host)
            layer:SetAllPoints(host); layer:EnableMouse(false)
            if layer.SetMouseMotionEnabled then layer:SetMouseMotionEnabled(false) end
            S[method or 'Panel'](layer, options or {noBorder = true})
            if method == 'Button' then
                -- Options actions need a quiet outline against the page fill,
                -- like EUI's Escape-menu buttons. Keep it on our disposable
                -- visual layer so pooled native buttons remain untouched.
                layer.rxpActionEdges = {}
                for _, side in ipairs({'TOP', 'BOTTOM', 'LEFT', 'RIGHT'}) do
                    local edge = layer:CreateTexture(nil, 'BORDER')
                    edge:SetColorTexture(0.26, 0.26, 0.26, 1)
                    if side == 'TOP' or side == 'BOTTOM' then
                        edge:SetPoint(side .. 'LEFT', layer, side .. 'LEFT')
                        edge:SetPoint(side .. 'RIGHT', layer, side .. 'RIGHT'); edge:SetHeight(1)
                    else
                        edge:SetPoint('TOP' .. side, layer, 'TOP' .. side)
                        edge:SetPoint('BOTTOM' .. side, layer, 'BOTTOM' .. side); edge:SetWidth(1)
                    end
                    layer.rxpActionEdges[#layer.rxpActionEdges + 1] = edge
                end
            end
            d.layers[key] = layer
            -- AceGUI reparents pooled controls during Open/confirmation rebuilds.
            -- Keep the owned background below native text after hierarchy changes.
            local function SyncLevel() LayerLevel(d, layer, host) end
            H.Hook(host, 'SetParent', SyncLevel)
            H.Hook(host, 'SetFrameLevel', SyncLevel)
            if method == 'Dropdown' then
                for _, region in ipairs(H.Regions(layer)) do
                    if region.GetAtlas and region:GetAtlas() == 'Azerite-PointingArrow' then
                        region:SetTexture('Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png')
                        region:SetVertexColor(0.8, 0.8, 0.8, 1)
                    end
                end
            end
            if method == 'Button' or method == 'Dropdown' then
                for _, region in ipairs(H.Regions(layer)) do
                    if region.GetDrawLayer and region:GetDrawLayer() == 'HIGHLIGHT' then
                        region:SetAlpha(0)
                        H.Script(host, 'OnEnter', function() if d.active then region:SetAlpha(1) end end)
                        H.Script(host, 'OnLeave', function() region:SetAlpha(0) end)
                    end
                end
            end
        end
        local forever = d.opacityDialog and foreverLook()
        local EUI = _G.EllesmereUI
        if forever and key ~= host and not layer.rxpRim and EUI and EUI.ForeverBorder and EUI.ForeverBorderSeat and EUI.ForeverBorderShown then
            -- Never register this artwork host with the panel skin.
            local art = CreateFrame('Frame', nil, layer)
            art:SetAllPoints(layer); art:EnableMouse(false)
            if art.SetMouseMotionEnabled then art:SetMouseMotionEnabled(false) end
            local rim = EUI.ForeverBorder(art, 'ARTWORK', 1, nil, 'textured')
            if rim then
                EUI.ForeverBorderSeat(rim, art, 'TOPLEFT', 0, 0, 0, 0)
                layer.rxpRim = rim
            end
        end
        if layer.rxpRim and EUI and EUI.ForeverBorderShown then
            EUI.ForeverBorderShown(layer.rxpRim, not not forever)
        end
        LayerLevel(d, layer, host)
        layer:SetAlpha(1)
        return layer
    end
    local function Neutral(d, text, disabled)
        Font(d, text, disabled and 0.5 or 0.9, disabled and 0.5 or 0.9, disabled and 0.52 or 0.92, 1)
    end
    local function ButtonLabel(d, widget, button, text)
        if not H.Allowed(button) or not H.Allowed(text) then return end
        d.buttons = d.buttons or {}
        local state = d.buttons[button]
        if not state then
            state = {}; d.buttons[button] = state
            state.reflect = function()
                if not d.active or not ns.IsEnabled(module) or not Owned(widget) then return end
                if InCombatLockdown and InCombatLockdown() then module.optionsWaiting = true; return end
                local disabled = widget.disabled
                if button.IsEnabled then disabled = not button:IsEnabled() end
                Neutral(d, state.text, disabled)
            end
            -- Native button font objects can replace our label after a page
            -- refresh, hover or press. Repair only this label, never rescan.
            local function Reflect() H.Safe(state.reflect) end
            for _, event in ipairs({'OnEnable', 'OnDisable', 'OnEnter', 'OnLeave', 'OnMouseDown', 'OnMouseUp'}) do
                -- Layer already owns H.Script's hover slot; add this separate
                -- callback once so the hover visual and label both update.
                if button.HookScript and (not button.HasScript or button:HasScript(event)) then
                    button:HookScript(event, Reflect)
                end
            end
            -- AceGUI may call Enable again without an OnEnable transition.
            H.Hook(widget, 'SetDisabled', state.reflect)
        end
        state.text = text
        state.reflect()
    end
    local function Slider(d, slider)
        if not H.Allowed(slider) then return end
        local thumb = slider.GetThumbTexture and H.Texture(slider:GetThumbTexture())
        Fade(d, slider, thumb and {[thumb] = true})
        if not thumb then return end
        local saved = Save(d, thumb)
        if not saved.alpha then saved.alpha = thumb:GetAlpha() end
        thumb:SetAlpha(0) -- retain the native grip dimensions and drag hit area
        local track = Layer(d, slider, slider)
        -- The public panel supplies the matte track; our compact visual grip
        -- follows the native thumb without resizing its interaction rectangle.
        local grip = d.layers[thumb]
        if not grip then
            grip = CreateFrame('Frame', nil, slider)
            grip:EnableMouse(false); S.Panel(grip, {noBorder = true})
            d.layers[thumb] = grip
        end
        grip:ClearAllPoints(); grip:SetPoint('CENTER', thumb, 'CENTER')
        if slider.GetOrientation and slider:GetOrientation() == 'HORIZONTAL' then
            track:ClearAllPoints(); track:SetPoint('LEFT', slider, 'LEFT'); track:SetPoint('RIGHT', slider, 'RIGHT'); track:SetHeight(2)
            grip:SetSize(8, 12)
        else
            track:ClearAllPoints(); track:SetPoint('TOP', slider, 'TOP'); track:SetPoint('BOTTOM', slider, 'BOTTOM'); track:SetWidth(2)
            grip:SetPoint('TOP', thumb, 'TOP'); grip:SetPoint('BOTTOM', thumb, 'BOTTOM'); grip:SetWidth(5)
        end
        if not grip.fill then grip.fill = grip:CreateTexture(nil, 'OVERLAY'); grip.fill:SetAllPoints(grip) end
        local r, g, b = S.GetAccentColor()
        local forever = d.opacityDialog and foreverLook()
        if forever then
            r, g, b = 0.77, 0.58, 0.35
            if not track.rxpBronze then
                -- WindowEngine owns the matte track. Keep the tint on an
                -- unregistered, mouse-inert child so refresh cannot strip it.
                local art = CreateFrame('Frame', nil, track)
                art:SetAllPoints(track); art:EnableMouse(false)
                if art.SetMouseMotionEnabled then art:SetMouseMotionEnabled(false) end
                local line = art:CreateTexture(nil, 'ARTWORK')
                line:SetAllPoints(art)
                line:SetColorTexture(0.49, 0.33, 0.18, 0.85)
                track.rxpBronze = art
            end
        end
        if track.rxpBronze then track.rxpBronze:SetShown(not not forever) end
        grip.fill:SetColorTexture(r, g, b, 0.85); grip:SetAlpha(1)
        local name = slider.GetName and slider:GetName()
        local up = slider.ScrollUpButton or (name and _G[name .. 'ScrollUpButton'])
        local down = slider.ScrollDownButton or (name and _G[name .. 'ScrollDownButton'])
        for index, button in pairs({up, down}) do
            if H.Allowed(button) then
                Fade(d, button); Layer(d, button, button, 'PageButton', index == 1 and '^' or 'v')
            end
        end
    end
    local function Input(d, input)
        if not H.Allowed(input) then return end
        Fade(d, input); Layer(d, input, input, 'EditBox', {noBorder = true, padInput = false})
        Font(d, input)
        local saved = Save(d, input)
        if input.GetTextInsets and input.SetTextInsets then
            if not saved.insets then saved.insets = {input:GetTextInsets()} end
            input:SetTextInsets(6, 6, 0, 0)
        end
        if input.GetJustifyV and input.SetJustifyV then
            saved.justify = saved.justify or input:GetJustifyV(); input:SetJustifyV('MIDDLE')
        end
    end
    local function Pullout(widget)
        local popup = widget.pullout
        if type(popup) ~= 'table' or not H.Allowed(popup.frame) then return end
        local function Repaint()
            local owner = popup.userdata and popup.userdata.obj
            if owner and Owned(owner) then Paint(popup, true)
            elseif states[popup] then Restore(states[popup]) end
        end
        H.Hook(popup, 'Open', Repaint)
        if not states[popup] then
            -- Register cleanup now, even if the pooled pullout is not open yet.
            states[popup] = {layers = {}, saved = {}}
            popup.frame:HookScript('OnHide', function() Restore(states[popup]) end)
        end
        if popup.OnRelease and not states[popup].releaseHook then
            states[popup].releaseHook = true
            hooksecurefunc(popup, 'OnRelease', function() Restore(states[popup]) end)
        end
    end
    Paint = function(widget, popup)
        local frame = type(widget) == 'table' and widget.frame
        if not H.Allowed(frame) then return end
        -- AceConfig's confirmation/validation popup is not an AceGUI child.
        -- Fire returns after its native action has built the complete popup.
        -- Recheck ownership because AceGUI widgets are pooled across addons.
        if ns.StyleTextureDialog then
            H.Hook(widget, 'Fire', function(_, event)
                if event ~= 'OnClick' and event ~= 'OnValueChanged' and event ~= 'OnEnterPressed' then return end
                local dialog = LibStub and LibStub('AceConfigDialog-3.0', true)
                local confirmation = dialog and dialog.popup
                if confirmation and confirmation:IsShown() then
                    ns.StyleTextureDialog(S, module, confirmation, Owned(widget))
                end
            end)
        end
        local d = states[widget]
        if not d then
            d = {layers = {}, saved = {}}; states[widget] = d
            frame:HookScript('OnHide', function() roots[widget] = nil; Restore(d) end)
            H.Script(frame, 'OnShow', function() if Owned(widget) then Paint(widget) end end)
        end
        if not ns.IsEnabled(module) or not (popup or Owned(widget)) then Restore(d); return end
        if InCombatLockdown and InCombatLockdown() then module.optionsWaiting = true; return end
        d.active = true
        d.opacityDialog = false
        local owner = widget
        for _ = 1, 24 do
            if type(owner) ~= 'table' then break end
            if (owner.userdata and owner.userdata.appName == OPACITY_APP)
                or roots[owner] == OPACITY_APP then
                d.opacityDialog = true
                break
            end
            owner = owner.parent
        end
        local kind = widget.type
        if popup then
            Fade(d, frame); Layer(d, 'panel', frame)
            for _, item in ipairs(widget.items or {}) do
                Font(d, item.text) -- native disabled/title colours stay intact
                if H.Texture(item.check) then
                    local saved = Save(d, item.check)
                    if not saved.tint then saved.tint = {item.check:GetVertexColor()} end
                    local r, g, b = S.GetAccentColor(); item.check:SetVertexColor(r, g, b, 1)
                end
            end
            Slider(d, widget.slider)
            return
        end
        if kind == 'BlizOptionsGroup' then
            local r, g, b = S.GetAccentColor(); Font(d, widget.label, r, g, b)
        elseif kind == 'TabGroup' then
            Fade(d, widget.border or frame)
            for _, tab in pairs(widget.tabs or {}) do
                if H.Allowed(tab) then
                    Fade(d, tab)
                    local layer = Layer(d, tab, tab)
                    if not layer.marker then
                        layer.marker = layer:CreateTexture(nil, 'OVERLAY')
                        layer.marker:SetPoint('BOTTOMLEFT', tab, 'BOTTOMLEFT', 1, 0)
                        layer.marker:SetPoint('BOTTOMRIGHT', tab, 'BOTTOMRIGHT', -1, 0); layer.marker:SetHeight(2)
                    end
                    local r, g, b = S.GetAccentColor()
                    layer.marker:SetColorTexture(r, g, b, tab.selected and 1 or 0)
                    local text = tab.text or tab.Text or tab.GetFontString and tab:GetFontString()
                    if tab.selected then Font(d, text, r, g, b) else Neutral(d, text, tab.disabled) end
                end
            end
            H.Hook(widget, 'BuildTabs', function() if d.active then Paint(widget) end end)
        elseif kind == 'InlineGroup' then
            Fade(d, widget.content and widget.content:GetParent() or frame)
            local r, g, b = S.GetAccentColor(); Font(d, widget.titletext, r, g, b)
        elseif kind == 'Heading' then
            Fade(d, frame)
            local r, g, b = S.GetAccentColor(); Font(d, widget.label, r, g, b)
        elseif kind == 'Button' then
            Fade(d, frame); Layer(d, 'button', frame, 'Button')
            ButtonLabel(d, widget, frame, widget.text or frame.GetFontString and frame:GetFontString())
        elseif kind == 'CheckBox' and widget.checkbg and widget.check then
            Fade(d, frame, {[widget.checkbg] = true, [widget.check] = true})
            -- Keep native checked/tristate visibility and hit rectangles.
            local r, g, b = S.GetAccentColor()
            for _, texture in ipairs({widget.checkbg, widget.check}) do
                local saved = Save(d, texture)
                if not saved.tint then saved.tint = {texture:GetVertexColor()} end
                if not saved.alpha then saved.alpha = texture:GetAlpha() end
                texture:SetAlpha(0)
            end
            local bg = Layer(d, 'check', frame)
            bg:ClearAllPoints(); bg:SetPoint('CENTER', widget.checkbg, 'CENTER'); bg:SetSize(14, 14)
            if not bg.mark then bg.mark = bg:CreateTexture(nil, 'OVERLAY'); bg.mark:SetPoint('CENTER'); bg.mark:SetSize(8, 8) end
            bg.mark:SetColorTexture(widget.disabled and 0.5 or r, widget.disabled and 0.5 or g, widget.disabled and 0.5 or b, 1)
            bg.mark:SetShown(widget.check:IsShown())
            Neutral(d, widget.text, widget.disabled)
            for _, method in ipairs({'SetValue', 'SetType', 'SetDisabled'}) do
                H.Hook(widget, method, function() if d.active then Paint(widget) end end)
            end
        elseif kind == 'Dropdown' then
            Fade(d, widget.dropdown); Fade(d, widget.button)
            local cover = H.Allowed(widget.button_cover) and widget.button_cover or widget.frame
            local layer = Layer(d, 'dropdown', cover, 'Dropdown')
            if cover == frame then
                layer:ClearAllPoints(); layer:SetPoint('TOPLEFT', frame, 'BOTTOMLEFT', 0, 25)
                layer:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT')
            end
            Neutral(d, widget.text, widget.disabled); Neutral(d, widget.label, widget.disabled)
            Pullout(widget)
        elseif kind == 'Slider' then
            Slider(d, widget.slider); Input(d, widget.editbox)
            Neutral(d, widget.label, widget.disabled); Neutral(d, widget.lowtext, widget.disabled); Neutral(d, widget.hightext, widget.disabled)
        elseif kind == 'Keybinding' then
            Neutral(d, widget.label, widget.disabled)
            if H.Allowed(widget.button) then
                Fade(d, widget.button); Layer(d, 'key', widget.button, 'Button')
                ButtonLabel(d, widget, widget.button, widget.button:GetFontString())
            end
        elseif kind == 'EditBox' then
            Input(d, widget.editbox or frame); Neutral(d, widget.label, widget.disabled)
            if H.Allowed(widget.button) then
                Fade(d, widget.button); Layer(d, 'accept', widget.button, 'Button')
                ButtonLabel(d, widget, widget.button, widget.button:GetFontString())
            end
        elseif kind == 'ScrollFrame' then
            Slider(d, widget.scrollbar or widget.scrollBar)
        elseif kind == 'Label' then
            Font(d, widget.label)
        elseif kind == 'ColorPicker' then
            Neutral(d, widget.text, widget.disabled)
        elseif kind == 'Frame' then
            Fade(d, frame); Layer(d, 'window', frame)
            local close = widget.closebtn
            if d.opacityDialog then
                local status = widget.statustext and widget.statustext:GetParent()
                Fade(d, status) -- blank status field chrome; retain status text and tooltips
                if not close then
                    -- Older AceGUI Frame widgets keep Close as a local button.
                    for _, child in ipairs(H.Children(frame)) do
                        if child ~= status and child.obj == widget and child.GetScript and child:GetScript('OnClick') then
                            close = child
                            break
                        end
                    end
                end
            end
            if H.Allowed(close) then
                Fade(d, close)
                if d.opacityDialog then
                    Layer(d, 'close', close, 'Button')
                    ButtonLabel(d, widget, close, close:GetFontString())
                else Layer(d, 'close', close, 'CloseButton') end
            end
        end
        -- Colour-picker swatches, description colours and the RXP logo remain native.
        Font(d, widget.titletext)
    end
    PaintTree = function(widget)
        if type(widget) ~= 'table' then return end
        Paint(widget)
        for _, child in ipairs(widget.children or {}) do PaintTree(child) end
    end
    local dialog
    local function Refresh()
        if InCombatLockdown and InCombatLockdown() then module.optionsWaiting = true; return end
        module.optionsWaiting = false
        for widget in pairs(roots) do
            if widget.frame and widget.frame.IsShown and widget.frame:IsShown() then PaintTree(widget) end
        end
        for widget, d in pairs(states) do
            if d.active then
                if not ns.IsEnabled(module) then Restore(d)
                elseif widget.userdata and widget.userdata.obj then Paint(widget, Owned(widget.userdata.obj)) end
            end
        end
    end
    local function Bind()
        dialog = LibStub and LibStub('AceConfigDialog-3.0', true)
        if not dialog then return end
        H.Hook(dialog, 'FeedGroup', function(_, app, _, container, rootframe)
            if not App(app) then return end
            -- FeedGroup returns after constructing the selected page. Visit its
            -- widgets synchronously, never the guide or unrelated options apps.
            roots[rootframe or container] = app
            PaintTree(container)
            local parent = container.parent
            for _ = 1, 12 do
                if not parent or not Owned(parent) then break end
                Paint(parent); parent = parent.parent
            end
        end)
        H.Hook(dialog, 'Open', function(_, app, container)
            if not App(app) then return end
            local widget = container or dialog.OpenFrames and dialog.OpenFrames[app]
            if widget then
                roots[widget] = app
                if not states[widget] or not states[widget].active then PaintTree(widget) end
            end
        end)
        for app, groups in pairs(dialog.BlizOptions or {}) do
            if App(app) then
                for _, widget in pairs(groups) do roots[widget] = true end
            end
        end
        for app, widget in pairs(dialog.OpenFrames or {}) do if App(app) then roots[widget] = true end end
    end
    Bind()
    return function() Bind(); Refresh() end
end

ns.RegisterModule("RXPGuides", "RestedXP Guides", function()
    return _G.RXP and type(_G.RXP.LoadActiveTheme) == "function"
end, function(S, module)
    S = ns.CreateSoftSkin(S, module, function() return true end)
    S.PageButton = S.SoftPageButton or S.PageButton
    local addon = _G.RXP
    local H = ns.CreateSkinHelper(S, module)
    local refresh, applyWaiting, themeWaiting
    local ForeverLook
    local refreshOptions = OptionsSkin(S, H, module, addon, function() return ForeverLook and ForeverLook() end)
    local themed = setmetatable({}, {__mode = "k"})
    local targetSeen
    local function Font(text, r, g, b)
        if not text or not text.GetFont or not H.Allowed(text) then return end
        local path, _, flags = text:GetFont()
        local target, targetFlags = S.GetFont()
        if path ~= target or (flags or "") ~= (targetFlags or "") then H.Font(text) end
        if r and text.GetTextColor then
            local cr, cg, cb, ca = text:GetTextColor()
            if cr ~= r or cg ~= g or cb ~= b then text:SetTextColor(r, g, b, ca) end
        end
    end
    local function SkinPreferences()
        return EUIAddonSkinsDB and EUIAddonSkinsDB.restedXP
    end
    local function BackgroundOverride()
        local settings = SkinPreferences()
        local value = settings and settings.opacity
        if type(value) == "number" and value == value then return math.max(0, math.min(1, value)) end
    end
    local function SavePreference(key, value)
        EUIAddonSkinsDB = EUIAddonSkinsDB or {}
        EUIAddonSkinsDB.restedXP = EUIAddonSkinsDB.restedXP or {}
        EUIAddonSkinsDB.restedXP[key] = value
    end
    local auxTitlePoints = setmetatable({}, {__mode = "k"})
    local auxTitleInset = 5
    local function SeatAuxiliaryTitle(f, title, text)
        if not title.GetPoint or not title.SetHeight then return end
        local saved = auxTitlePoints[title]
        if ForeverLook() then
            local point, relative, anchor, x, y = title:GetPoint(1)
            if not saved and point then
                saved = {height = title:GetHeight(), size = select(2, text:GetFont()), points = {}}
                for i = 1, title:GetNumPoints() do saved.points[i] = {title:GetPoint(i)} end
                auxTitlePoints[title] = saved
            end
            if point ~= "TOPLEFT" or relative ~= f or anchor ~= "TOPLEFT" or x ~= auxTitleInset or y ~= -1 then
                title:ClearAllPoints()
                title:SetPoint("TOPLEFT", f, "TOPLEFT", auxTitleInset, -1)
            end
            if title:GetHeight() ~= 11 then title:SetHeight(11) end
            local path, size, flags = text:GetFont()
            if size and size > 10 then text:SetFont(path, 10, flags) end
        elseif saved then
            title:ClearAllPoints()
            for _, point in ipairs(saved.points) do title:SetPoint((unpack or table.unpack)(point)) end
            title:SetHeight(saved.height)
            local path, size, flags = text:GetFont()
            if saved.size and saved.size ~= size then text:SetFont(path, saved.size, flags) end
            auxTitlePoints[title] = nil
        end
    end
    local WarmTitle
    local titleMetrics = setmetatable({}, {__mode = "k"})
    local function AuxiliaryTitle(f)
        if InCombatLockdown and InCombatLockdown() then applyWaiting = true; return end
        local title, text = f and f.title, f and f.title and f.title.text
        if not title or not text or not text.GetFont then return end
        local r, g, b = WarmTitle()
        Font(text, r, g, b)
        SeatAuxiliaryTitle(f, title, text)
        -- RXP measured with its previous font. Clear a stale FontString width
        -- before measuring the new face, retaining the native localized text.
        if not text.GetStringWidth or not title.SetWidth then return end
        local path, size, flags = text:GetFont()
        local value = text.GetText and text:GetText()
        local saved, width = titleMetrics[text]
        if saved and value and saved.value == value and saved.path == path and saved.size == size and saved.flags == flags then
            width = saved.width
        else
            if text.SetWidth then text:SetWidth(0) end
            width = text.GetUnboundedStringWidth and text:GetUnboundedStringWidth() or text:GetStringWidth()
            if not width or width <= 0 then return end
            width = math.ceil(width) + 12
            titleMetrics[text] = {path = path, size = size, flags = flags, value = value, width = width}
        end
        if not title.GetWidth or title:GetWidth() ~= width then title:SetWidth(width) end
        if f.GetWidth and f.SetWidth and f:GetWidth() < width + 10 then f:SetWidth(width + 10) end
    end
    local copies, wrapped = setmetatable({}, {__mode = "k"}), {}
    local unpack = unpack or table.unpack
    local function Pack(...) return {n = select("#", ...), ...} end
    local function Copy(t)
        local out = {}; for k, v in pairs(t or {}) do out[k] = v end; return out
    end
    -- The public skin palette resolves only eui/modern. The whole-UI
    -- profile resolver also handles Forever profiles imported on Retail.
    ForeverLook = function()
        local EUI = _G.EllesmereUI
        local settings = SkinPreferences()
        if settings and settings.style == "standard" then return false end
        if settings and settings.style == "forever" then return EUI and EUI.IS_FOREVER == true or false end
        if not (EUI and EUI.ProfileWindowSkinLook and EUI.GetActiveProfileData) then return false end
        local db = _G.EllesmereUIDB
        return EUI.ProfileWindowSkinLook(EUI.GetActiveProfileData(), db and db.fonts) == "forever"
    end
    -- Concept A's chrome palette. Semantic quest and status colours stay native.
    local bronzeR, bronzeG, bronzeB = 0.49, 0.33, 0.18
    local copperR, copperG, copperB = 0.91, 0.71, 0.43
    local function ForeverPanel(header)
        if header then return 0.115, 0.082, 0.052 end
        return 0.062, 0.052, 0.043
    end
    -- EUI can re-strip the direct regions of its registered panels/buttons.
    -- Keep Forever art on an unregistered child at the same drawing level.
    local function ForeverArtHost(parent)
        local host = CreateFrame("Frame", nil, parent)
        host:SetAllPoints(parent)
        host:SetFrameLevel(parent:GetFrameLevel())
        host:EnableMouse(false)
        if host.SetMouseMotionEnabled then host:SetMouseMotionEnabled(false) end
        return host
    end
    local function ForeverRim(host, parent, inset)
        local EUI = _G.EllesmereUI
        if not (EUI.ForeverBorder and EUI.ForeverBorderSeat and EUI.ForeverBorderShown) then return end
        local ring = EUI.ForeverBorder(host, "ARTWORK", 1, nil, "textured")
        inset = inset or 0
        if ring then EUI.ForeverBorderSeat(ring, parent or host, "TOPLEFT", inset, -inset, -inset, inset) end
        return ring
    end
    local function SeatFill(texture, frame, x, top, bottom)
        texture:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -top)
        texture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -x, bottom)
    end
    local function MaskFill(art, edge, first, second, third, step, bottomInset)
        local mode = Enum and Enum.UITextureSliceMode and Enum.UITextureSliceMode.Stretched
        if mode and art.CreateMaskTexture and first.AddMaskTexture then
            local mask = art:CreateMaskTexture()
            mask:SetTexture("Interface\\AddOns\\EUIAddonSkins\\Media\\RestedXPFill.tga",
                "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            -- Fixed corners track the slim rim while the center stretches.
            mask:SetTextureSliceMargins(8, 8, 8, 8)
            mask:SetTextureSliceMode(mode)
            mask:SetAllPoints(edge)
            first:AddMaskTexture(mask)
            second:AddMaskTexture(mask)
            if third then third:AddMaskTexture(mask) end
            return mask
        else
            -- Older clients without sliced masks retain a conservative inset.
            first:ClearAllPoints()
            second:ClearAllPoints()
            SeatFill(first, art, 2, 9, bottomInset or 9)
            SeatFill(second, art, 2, 9, bottomInset or 9)
            if third then
                third:ClearAllPoints()
                SeatFill(third, step, 0, 3, 0)
            end
        end
    end
    local function MeterHeaderArt(texture, bandOnly)
        local atlas = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("ui-questtracker-primary-objective-header")
        local file = atlas and (atlas.file or atlas.filename)
        if not file then return false end
        local l, t = atlas.leftTexCoord, atlas.topTexCoord
        local w, h = atlas.rightTexCoord - l, atlas.bottomTexCoord - t
        -- The meter reserves extra height for the last six rows (rail and
        -- shadow). Compact titles use just the 24-row band.
        local bottom = bandOnly and 33 or 39
        texture:SetTexture(file)
        texture:SetTexCoord(l + w * 64 / 300, l + w * 176 / 300, t + h * 9 / 40, t + h * bottom / 40)
        return true
    end
    local surfacePaint = setmetatable({}, {__mode = "k"})
    local function SetPaintAlpha(texture, alpha, shown)
        local paint = surfacePaint[texture]
        if paint.alpha ~= alpha or paint.gradientDirty then
            paint.alpha, paint.gradientDirty = alpha, nil
            if paint.low then
                local lo, hi = paint.from or paint.shade, paint.to or 1
                paint.low:SetRGBA(paint.r * lo, paint.g * lo, paint.b * lo, alpha)
                paint.high:SetRGBA(paint.r * hi, paint.g * hi, paint.b * hi, alpha)
                texture:SetGradient("VERTICAL", paint.low, paint.high)
            else
                texture:SetVertexColor(paint.r or 1, paint.g or 1, paint.b or 1, alpha)
            end
        end
        shown = alpha > 0 and shown ~= false
        if paint.shown ~= shown then
            paint.shown = shown
            texture:SetShown(shown)
        end
    end
    local function ForeverSurface(art, band, titleBody, guideHeader, legacyHeader)
        local plate = art:CreateTexture(nil, "BACKGROUND", nil, 1)
        local grain = art:CreateTexture(nil, "BACKGROUND", nil, 2)
        if titleBody then
            for _, texture in ipairs({plate, grain}) do
                texture:SetPoint("TOPLEFT", titleBody, "TOPLEFT", 8, -3)
                texture:SetPoint("TOPRIGHT", titleBody, "TOPRIGHT", -8, -3)
                texture:SetPoint("BOTTOM", art, "BOTTOM", 0, 0)
            end
        else
            plate:SetAllPoints(art)
            grain:SetAllPoints(art)
        end
        local r, g, b = 0.165, 0.115, 0.075
        if band then r, g, b = 0.185, 0.126, 0.080 end
        plate:SetColorTexture(r, g, b, 1)
        local paint = {r = r, g = g, b = b}
        surfacePaint[plate] = paint
        local meterArt = (guideHeader or titleBody) and MeterHeaderArt(plate, legacyHeader or titleBody ~= nil)
        if not meterArt and plate.SetGradient and CreateColor then
            paint.shade = band and (guideHeader and 0.73 or 0.65) or 0.73
            paint.low = CreateColor(r * paint.shade, g * paint.shade, b * paint.shade, 1)
            paint.high = CreateColor(r, g, b, 1)
        end
        grain:SetTexture("Interface/Tooltips/UI-Tooltip-Background", "REPEAT", "REPEAT")
        plate:SetBlendMode("BLEND")
        grain:SetBlendMode("BLEND")
        grain:SetHorizTile(true); grain:SetVertTile(true)
        grain:SetVertexColor(0.56, 0.44, 0.32, 1)
        surfacePaint[grain] = {r = 0.56, g = 0.44, b = 0.32}
        if meterArt then
            -- Tame the atlas's bright lower ramp. Tint RGB only so coverage
            -- still follows the slider.
            paint.r, paint.g, paint.b = 0.62, 0.64, 0.68
        elseif not paint.low then
            paint.r, paint.g, paint.b = nil, nil, nil
        end
        return grain, plate, meterArt
    end

    local function ForeverOpacity()
        -- Use the public house-panel alpha; normalize against EUI's 92% default.
        local override = BackgroundOverride()
        return override and override / 0.70 or (select(4, S.GetPanelColor()) or 0.92) / 0.92
    end
    local function SharedAlpha(opacity, scale)
        local override = BackgroundOverride()
        if override then
            return override
        end
        return math.min(opacity, 0.66 * scale)
    end
    local function SectionAlpha(default, scale)
        return BackgroundOverride() or math.min(1, default * scale)
    end
    local function OverlayAlpha(target, base)
        return base < 1 and math.max(0, math.min(1, target) - base) / (1 - base) or 0
    end
    local function TextureAlpha(texture, alpha)
        local current = texture:GetAlpha()
        if alpha == 0 and current ~= 0 or math.abs(current - alpha) > 0.002 then
            texture:SetAlpha(alpha)
        end
    end
    local function SurfaceAlpha(plate, grain, target, grainWeight, shown)
        -- Keep the opaque material's relative RGB weights. Put opacity in
        -- gradient stops / vertex colours as well as excluding zero-alpha draws.
        local grainAlpha = target * grainWeight
        SetPaintAlpha(grain, grainAlpha, shown)
        SetPaintAlpha(plate, OverlayAlpha(target, grainAlpha), shown)
    end

    local function CombatLocked()
        return InCombatLockdown and InCombatLockdown()
    end
    local compositions = setmetatable({}, {__mode = "k"})
    local function ComposeGuide(root, header, footer, currentStep, forever)
        local art = root and compositions[root]
        if not art and forever and root and root.GetFrameLevel and header and footer
            and not (root.IsForbidden and root:IsForbidden()) then
            local EUI = _G.EllesmereUI
            if not (EUI.IS_FOREVER and EUI.ForeverBorder and EUI.ForeverBorderSeat and EUI.ForeverBorderShown) then return end
            art = ForeverArtHost(root)
            art.grain, art.plate = ForeverSurface(art, false)
            if currentStep then
                local fill = art:CreateTexture(nil, "BACKGROUND", nil, 3)
                fill:SetAllPoints(currentStep)
                fill:SetColorTexture(0.165, 0.115, 0.075)
                fill:SetBlendMode("BLEND")
                surfacePaint[fill] = {}
                art.stepFill = fill
            end
            art.masked = MaskFill(art, art, art.plate, art.grain, art.stepFill, currentStep)
            art.header, art.footer, art.currentStep = header, footer, currentStep
            local function AnchorTop()
                if not ForeverLook() then return end
                if CombatLocked() then refresh(); return end
                local top = currentStep and currentStep:IsShown() and currentStep:GetHeight() > 0 and currentStep or header
                if art.top == top then return end
                art.top = top
                if art.stepFill then
                    SetPaintAlpha(art.stepFill, surfacePaint[art.stepFill].alpha or 0, top == currentStep)
                end
                if art.headerRule then art.headerRule:SetShown(top ~= header) end
                art:ClearAllPoints()
                art:SetPoint("TOPLEFT", top, "TOPLEFT", -2, top == currentStep and 6 or 2)
                art:SetPoint("BOTTOMRIGHT", footer, "BOTTOMRIGHT", 2, -2)
            end
            AnchorTop()
            H.Script(currentStep, "OnShow", AnchorTop)
            H.Script(currentStep, "OnHide", AnchorTop)
            art.anchorTop = AnchorTop
            art.rim = ForeverRim(art)
            compositions[root] = art
        end
        if art then
            if forever then art.anchorTop() end
            art:SetShown(forever)
            if forever then return art end
        end
    end
    local function MatchGradient(texture, art, lower, upper)
        local paint = surfacePaint[texture]
        if not (paint.low and art.GetBottom and art.GetTop) then return end
        local bottom, top = art:GetBottom(), art:GetTop()
        if not bottom or not top or top <= bottom then return end
        local function Sample(y)
            local fraction = math.max(0, math.min(1, (y - bottom) / (top - bottom)))
            return paint.shade + (1 - paint.shade) * fraction
        end
        local from, to = Sample(lower or bottom), Sample(upper or top)
        if paint.from == from and paint.to == to then return end
        paint.from, paint.to, paint.gradientDirty = from, to, true
        if paint.alpha then SetPaintAlpha(texture, paint.alpha) end
    end
    local function MatchGuideGradient(art)
        if art.split and art.header.GetTop and art.header.GetBottom and art.footer.GetTop then
            MatchGradient(art.plate, art, art.footer:GetTop(), art.header:GetBottom())
            -- The upper strip runs from the title's top to the guide's top.
            MatchGradient(art.upperPlate, art, art.header:GetTop(), nil)
        else
            MatchGradient(art.plate, art, nil, nil)
        end
    end
    local function SeatGuideFill(art, split)
        if (art.split == true) == split then return end
        art.split = split
        if split and not art.upperPlate then
            art.upperGrain, art.upperPlate = ForeverSurface(art, false)
            local mask = art.masked
            art.upperGrain:AddMaskTexture(mask)
            art.upperPlate:AddMaskTexture(mask)
            H.Script(art, "OnSizeChanged", MatchGuideGradient)
            for _, texture in ipairs({art.upperPlate, art.upperGrain}) do
                texture:ClearAllPoints()
                texture:SetPoint("TOPLEFT", art, "TOPLEFT")
                texture:SetPoint("BOTTOMRIGHT", art.header, "TOPRIGHT", 2, 0)
            end
        end
        for _, texture in ipairs({art.plate, art.grain}) do
            texture:ClearAllPoints()
            if split then
                texture:SetPoint("TOPLEFT", art.header, "BOTTOMLEFT", -2, 0)
                texture:SetPoint("BOTTOMRIGHT", art.footer, "TOPRIGHT", 2, 0)
            elseif art.masked then texture:SetAllPoints(art)
            else SeatFill(texture, art, 2, 9, 9) end
        end
        MatchGuideGradient(art)
    end
    local rims = setmetatable({}, {__mode = "k"})
    local function ButtonRim(button, forever)
        if not H.Allowed(button) then return end
        local ring = rims[button]
        if not ring and forever and button.GetFrameLevel then
            local EUI = _G.EllesmereUI
            if not (EUI.ForeverBorder and EUI.ForeverBorderSeat and EUI.ForeverBorderShown) then return end
            ring = ForeverRim(ForeverArtHost(button), button)
            rims[button] = ring
        end
        if ring and ring.on ~= forever then _G.EllesmereUI.ForeverBorderShown(ring, forever) end
    end
    WarmTitle = function()
        if ForeverLook() then return 0.86, 0.73, 0.51 end
        return S.GetAccentColor()
    end
    local function Theme(source)
        if type(source) ~= "table" then return source end
        local out = copies[source]
        if not out then out = Copy(source); copies[source] = out end
        local r, g, b = S.GetAccentColor()
        local pr, pg, pb, pa = S.GetPanelColor()
        local forever = ForeverLook()
        if forever then pr, pg, pb = ForeverPanel(false) end
        out.font = S.GetFont()
        -- Session copies leave registered themes, saved choices and semantic colors intact.
        if source.backgroundColors then
            out.backgroundColors = Copy(source.backgroundColors)
            for _, key in ipairs({"common", "guideName", "guideWindow", "scrollbar", "inactivePartyTab", "activeStepCheckbox"}) do
                out.backgroundColors[key] = {pr, pg, pb, pa}
            end
            if forever then
                local hr, hg, hb = ForeverPanel(true)
                out.backgroundColors.guideName = {hr, hg, hb, pa}
                out.backgroundColors.scrollbar = {0.083, 0.065, 0.05, pa}
            end
            out.backgroundColors.activeStepCheckboxChecked = {r, g, b, 1}
            out.borderColors = Copy(source.borderColors)
            for _, key in ipairs({"common", "commonEdge", "inactivePartyTab"}) do
                out.borderColors[key] = forever and {bronzeR, bronzeG, bronzeB, 1} or {0.055, 0.055, 0.055, 1}
            end
            out.borderColors.activeStepCheckboxChecked = {r, g, b, 1}
            out.textColor = Copy(source.textColor)
            out.textColor.common = {0.9, 0.9, 0.92, 1}
            out.textColor.title = {r, g, b, 1}
            out.textColor.inactivePartyTab = {0.65, 0.65, 0.68, 1}
            out.edge = Copy(source.edge)
            out.edge.edgeFile = "Interface/Buttons/WHITE8X8"
            out.edge.edgeSize = 1
            out.edge.texCoords = {top = {0, 1, 0, 1}, bottom = {0, 1, 0, 1}, left = {0, 1, 0, 1}, right = {0, 1, 0, 1}}
        else
            out.background = {pr, pg, pb, pa}
            -- V1 uses this fill for idle and mouse-leave. Keep the row's
            -- own alpha and hover palette while exposing the shared surface.
            out.bottomFrameBG = {pr, pg, pb, forever and OverlayAlpha(SectionAlpha(0.70, ForeverOpacity()), SharedAlpha(pa or 1, ForeverOpacity())) or BackgroundOverride() or pa}
            out.bottomFrameHighlight = {r, g, b, 1}
            out.textColor = {0.9, 0.9, 0.92}
        end
        return out
    end
    local function Wrap(object, name, legacy)
        if not object or wrapped[object] or type(object[name]) ~= "function" then return end
        wrapped[object] = true
        local original = object[name]
        object[name] = function(...)
            local result = Pack(original(...))
            if ns.IsEnabled(module) and type(result[1]) == "table" then
                result[1] = Theme(result[1])
                object.activeTheme = result[1]
                if legacy then
                    addon.colors, addon.font = result[1], result[1].font
                    local f = addon.RXPFrame or _G.RXPFrame
                    for _, key in ipairs({"edge", "guideName", "bottom"}) do
                        local backdrop = f and f.backdrop and f.backdrop[key]
                        if backdrop then
                            backdrop.bgFile = "Interface/Buttons/WHITE8X8"
                            backdrop.edgeFile = key ~= "bottom" and "Interface/Buttons/WHITE8X8" or nil
                            backdrop.edgeSize = 1
                            -- RXP's original 8px artwork used asymmetric 2-4px
                            -- fill insets. Match the fill to our thin border.
                            local inset = key ~= "bottom" and 1 or 0
                            backdrop.insets = {left = inset, right = inset, top = inset, bottom = inset}
                        end
                    end
                end
            end
            return unpack(result, 1, result.n)
        end
    end
    local SyncShell
    local borderLocks = {}
    local guideChecks = setmetatable({}, {__mode = "k"})
    local stockCheckFolders = {[""] = true, ["darkmode/"] = true, ["goldassistant/"] = true,
        ["green/"] = true, ["hardcore/"] = true}
    local function TintBackdrop(f)
        if InCombatLockdown and InCombatLockdown() then return end
        if not f or (f.IsForbidden and f:IsForbidden()) then return end
        if H.Allowed(f) and f:GetObjectType() == "CheckButton" then
            if not guideChecks[f] then
                local marks = {}
                for _, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
                    local texture = f[getter] and H.Texture(f[getter](f))
                    local path = texture and texture.GetTexture and texture:GetTexture()
                    if path and f.theme then
                        local tint = {texture:GetVertexColor()}
                        local folder = type(path) == "string" and path:lower():gsub("\\", "/"):gsub("%.blp$", "")
                            :match("^interface/addons/rxpguides/textures/(.-)rxp%-checked%-32$")
                        -- These V1 files bake their green tick into the bitmap.
                        -- Leave custom or explicitly status-tinted marks alone.
                        marks[getter] = {path, tint, stockCheckFolders[folder] and tint[1] == 1 and tint[2] == 1 and tint[3] == 1}
                    end
                end
                local before = {}; for _, region in ipairs(H.Regions(f)) do before[region] = true end
                S.Checkbox(f)
                for _, region in ipairs(H.Regions(f)) do
                    if not before[region] and H.Texture(region) and region.GetDrawLayer and region:GetDrawLayer() == "BACKGROUND" then
                        region:ClearAllPoints(); region:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
                        region:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
                    end
                end
                guideChecks[f] = {marks = marks}
            end
            for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture", "GetHighlightTexture"}) do
                if f[getter] then H.Fade(f[getter](f)) end
            end
            local forever = ForeverLook()
            local visual = guideChecks[f]
            if forever and not visual.hover and f.CreateTexture then
                local hover = f:CreateTexture(nil, "HIGHLIGHT")
                SeatFill(hover, f, 1, 1, 1)
                hover:SetColorTexture(0.88, 0.66, 0.39, 0.18)
                visual.hover = hover
            end
            if visual.hover then visual.hover:SetShown(forever) end
            local r, g, b = S.GetAccentColor()
            for _, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
                local texture = f[getter] and H.Texture(f[getter](f))
                if texture then
                    local mark = visual.marks[getter]
                    if forever and mark and not mark[3] then
                        texture:SetTexture(mark[1])
                        texture:SetVertexColor(unpack(mark[2]))
                    elseif forever then
                        texture:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
                        if getter == "GetDisabledCheckedTexture" then texture:SetVertexColor(0.53, 0.48, 0.40, 1)
                        else texture:SetVertexColor(copperR, copperG, copperB, 1) end
                    else
                        texture:SetColorTexture(r, g, b, 1)
                    end
                    texture:ClearAllPoints(); texture:SetPoint("CENTER", f, "CENTER"); texture:SetSize(8, 8)
                end
            end
            return true -- preserve native checked/disabled visibility and skip actions
        end
        -- Legacy scrollbar geometry and its track/arrow chrome stay unchanged.
        if f.GetObjectType and f:GetObjectType() == "Slider" then return end
        local legacy = addon.RXPFrame or _G.RXPFrame
        local bar = legacy and legacy.ScrollFrame and legacy.ScrollFrame.ScrollBar
        if bar and (f == bar.ScrollUpButton or f == bar.ScrollDownButton
            or f.GetParent and f:GetParent() == bar) then return end
        if f.GetBackdrop and f.SetBackdropBorderColor then
            local backdrop = f:GetBackdrop()
            local function PaintBorder(_, r, g, b)
                if borderLocks[f] then return end
                if InCombatLockdown and InCombatLockdown() then if refresh then refresh() end; return end
                if r == nil and f.GetBackdropBorderColor then r, g, b = f:GetBackdropBorderColor() end
                -- Checked/status borders retain their semantic accent colour.
                local wasBronze = r and g and b and math.abs(r - bronzeR) < 0.002
                    and math.abs(g - bronzeG) < 0.002 and math.abs(b - bronzeB) < 0.002
                if not wasBronze and r and g and b and (math.abs(r - g) > 0.04 or math.abs(r - b) > 0.04) then return end
                borderLocks[f] = true
                if ForeverLook() then
                    local entry = themed[f]
                    f:SetBackdropBorderColor(bronzeR, bronzeG, bronzeB, entry and (entry.rim or entry.secondary or entry.joinedBody) and 0 or 1)
                else f:SetBackdropBorderColor(0.055, 0.055, 0.055, 1) end
                borderLocks[f] = false
            end
            if backdrop and backdrop.edgeFile then PaintBorder() end
            H.Hook(f, "SetBackdropBorderColor", PaintBorder)
            -- Native SetBackdrop resets border color to white. Correct it in
            -- the same call stack, before the client can draw another frame.
            H.Hook(f, "SetBackdrop", function()
                if InCombatLockdown and InCombatLockdown() then return end
                local current = f:GetBackdrop()
                if current and current.edgeFile then PaintBorder() end
                local entry = themed[f]
                if entry then
                    SyncShell(f, entry)
                end
            end)
        end
    end
    local function LegacySkipCheck(button, forever)
        if not H.Allowed(button) then return end
        local visual = guideChecks[button]
        if not visual then
            if not forever then return end
            TintBackdrop(button)
            visual = guideChecks[button]
            if not visual then return end
        end
        if forever and not visual.skipBorder then
            local lines = {}
            for _, edge in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
                local line = button:CreateTexture(nil, "BORDER", nil, 2)
                if edge == "TOP" or edge == "BOTTOM" then
                    line:SetPoint(edge .. "LEFT", button, edge .. "LEFT")
                    line:SetPoint(edge .. "RIGHT", button, edge .. "RIGHT")
                    line:SetHeight(1)
                else
                    line:SetPoint("TOP" .. edge, button, "TOP" .. edge, 0, -1)
                    line:SetPoint("BOTTOM" .. edge, button, "BOTTOM" .. edge, 0, 1)
                    line:SetWidth(1)
                end
                line:SetColorTexture(0.65, 0.46, 0.28, 0.85)
                lines[#lines + 1] = line
            end
            visual.skipBorder = lines
            H.Script(button, "OnEnter", function(self)
                if not ForeverLook() then return end
                local tip, screen = _G.GameTooltip, _G.UIParent
                local row = self:GetParent()
                if not (tip and screen and row and row.GetRight and row.GetLeft and row.GetEffectiveScale
                    and not (tip.IsForbidden and tip:IsForbidden()) and tip:GetOwner() == self) then return end
                local right, left, screenRight = row:GetRight(), row:GetLeft(), screen:GetRight()
                if not (right and left and screenRight) then return end
                local rowScale = row:GetEffectiveScale()
                local room = screenRight * screen:GetEffectiveScale() - right * rowScale
                local openRight = room >= (tip:GetWidth() + 8) * tip:GetEffectiveScale() or room >= left * rowScale
                tip:ClearAllPoints()
                tip:SetPoint(openRight and "LEFT" or "RIGHT", row, openRight and "RIGHT" or "LEFT", openRight and 8 or -8, 0)
            end)
        end
        if visual.skipBorder and visual.skipShown ~= forever then
            visual.skipShown = forever
            for _, line in ipairs(visual.skipBorder) do line:SetShown(forever) end
        end
    end
    local scans = setmetatable({}, {__mode = "k"})
    local function Scan(f)
        if not H.Allowed(f) then return end
        local apply = scans[f]
        if not apply then
            local queue
            apply = function()
                if InCombatLockdown and InCombatLockdown() then applyWaiting = true; return end
                H.Scan(f, queue, TintBackdrop)
            end
            queue = function() H.Queue(f, apply) end
            scans[f] = apply
        end
        apply()
    end
    local slimThumbs = {}
    local guideChrome = setmetatable({}, {__mode = "k"})
    local footerTint = setmetatable({}, {__mode = "k"})
    local resizeGrips = setmetatable({}, {__mode = "k"})
    local function LegacyResizeGrip(footer, forever)
        local button = footer.icon
        if not H.Allowed(button) then return end
        local grip = resizeGrips[button]
        if not forever or not grip then H.Resize(button, true) end
        if not grip then
            for _, region in ipairs(H.Regions(button)) do
                if region.GetText and region:GetText() == "+" then
                    grip = {label = region}
                    resizeGrips[button] = grip
                    break
                end
            end
            if not grip then return end
        end
        if forever and not grip.art then
            -- The footer owns the art, so the native resize button and its
            -- hit rectangle stay intact and the Standard helper cannot fade it.
            local art = footer:CreateTexture(nil, "OVERLAY")
            art:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\resize_element.png")
            art:SetSize(10, 10)
            art:SetPoint("CENTER", button, "CENTER", -1, 0)
            art:SetVertexColor(0.79, 0.63, 0.42, 0.90)
            grip.art = art
        end
        if grip.forever ~= forever then
            grip.forever = forever
            grip.label:SetShown(not forever)
            if grip.art then grip.art:SetShown(forever) end
        end
    end
    local scrollArrows = setmetatable({}, {__mode = "k"})
    local function ScrollArrow(button, up, forever, legacy)
        if not H.Allowed(button) then return end
        local state = scrollArrows[button]
        if not state and forever then
            local host = legacy and ForeverArtHost(button)
            local arrow = (host or button):CreateTexture(nil, "OVERLAY")
            arrow:SetTexture(up and "Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-up3.png"
                or "Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png")
            arrow:SetSize(12, 12)
            arrow:SetPoint("CENTER", button, "CENTER")
            arrow:SetVertexColor(0.88, 0.66, 0.39, 1)
            state = {arrow = arrow, alpha = {}, host = host}
            scrollArrows[button] = state
            local fill
            if host then
                ForeverRim(host, nil, 3)
                fill = host:CreateTexture(nil, "BACKGROUND")
                SeatFill(fill, host, 5, 5, 5)
            end
            local function Reflect()
                local enabled = not button.IsEnabled or button:IsEnabled()
                arrow:SetAlpha(enabled and 1 or 0.45)
                if host then
                    host:SetAlpha(enabled and 1 or 0.65)
                    local shade = enabled and (state.pressed and 0.035 or state.hover and 0.12) or 0.06
                    fill:SetColorTexture(shade, shade, shade + 0.005, 0.92)
                end
            end
            H.Script(button, "OnEnable", Reflect)
            H.Script(button, "OnDisable", Reflect)
            if host then
                H.Script(button, "OnEnter", function() state.hover = true; Reflect() end)
                H.Script(button, "OnLeave", function() state.hover, state.pressed = nil, nil; Reflect() end)
                H.Script(button, "OnMouseDown", function() state.pressed = true; Reflect() end)
                H.Script(button, "OnMouseUp", function() state.pressed = nil; Reflect() end)
            end
            Reflect()
        end
        if not state or state.forever == forever then return end
        state.forever = forever
        state.arrow:SetShown(forever)
        if state.host then state.host:SetShown(forever) end
        if forever then
            if legacy then
                for _, region in ipairs(H.Regions(button)) do
                    if state.alpha[region] == nil then state.alpha[region] = region:GetAlpha() end
                end
            else
                for _, texture in pairs({button.Normal, button.Pushed, button.Disabled}) do
                    if texture and texture.GetAlpha then state.alpha[texture] = texture:GetAlpha() end
                end
            end
            for texture in pairs(state.alpha) do texture:SetAlpha(0) end
        else
            for texture, alpha in pairs(state.alpha) do
                if texture:GetAlpha() == 0 then texture:SetAlpha(alpha) end
                state.alpha[texture] = nil
            end
        end
    end
    local legacyTitles = setmetatable({}, {__mode = "k"})
    local function LegacyHeaderTitle(header, forever)
        local text = header.text
        if not (H.Allowed(text) and text.GetText and text.GetFont and text.GetAlpha and header.CreateFontString) then return end
        local title = legacyTitles[header]
        if not title and forever then
            local primary = header:CreateFontString(nil, "OVERLAY")
            local secondary = header:CreateFontString(nil, "OVERLAY")
            for _, label in ipairs({primary, secondary}) do
                label:SetJustifyH("LEFT")
                if label.SetMaxLines then label:SetMaxLines(1) end
            end
            primary:SetPoint("TOPLEFT", header, "TOPLEFT", 7, -7)
            primary:SetPoint("TOPRIGHT", header, "TOPRIGHT", -7, -7)
            secondary:SetPoint("TOPLEFT", primary, "BOTTOMLEFT", 0, -1)
            secondary:SetPoint("TOPRIGHT", primary, "BOTTOMRIGHT", 0, -1)
            primary:SetTextColor(1, 0.82, 0)
            secondary:SetTextColor(0.79, 0.69, 0.55)
            title = {primary = primary, secondary = secondary}
            legacyTitles[header] = title
            H.Hook(text, "SetText", function()
                if not ForeverLook() then return end
                if CombatLocked() then applyWaiting = true; return end
                LegacyHeaderTitle(header, true)
            end)
        end
        if not title then return end
        local value = text:GetText()
        local first, second
        if type(value) == "string" then first, second = value:match("^([^\n]+)\n(.+)$") end
        local split = forever and second ~= nil
        title.primary:SetShown(split)
        title.secondary:SetShown(split)
        if split then
            if title.alpha == nil then title.alpha = text:GetAlpha(); text:SetAlpha(0) end
            local path, size, flags = text:GetFont()
            -- Leave room for the upper bevel, line spacing and lower rule.
            if size then size = math.min(size, math.max(8, math.floor((header:GetHeight() - 7) / 2))) end
            if path and size and (title.path ~= path or title.size ~= size or title.flags ~= flags) then
                title.path, title.size, title.flags = path, size, flags
                title.primary:SetFont(path, size, flags)
                title.secondary:SetFont(path, math.max(8, size - 2), flags)
            end
            if title.value ~= value then
                title.value = value
                title.primary:SetText(first)
                title.secondary:SetText(second)
            end
        elseif title.alpha ~= nil then
            text:SetAlpha(title.alpha)
            title.alpha = nil
        end
    end
    local function LegacyChrome(f)
        if CombatLocked() or not f then return end
        local forever = ForeverLook()
        local header = f.GuideName
        if H.Allowed(header) then
            if forever then Font(header.text, 1, 0.82, 0)
            elseif guideChrome[header.text] and f and addon.colors and addon.colors.textColor
                and header.text.SetTextColor then header.text:SetTextColor(unpack(addon.colors.textColor)) end
            if not guideChrome[header] and H.Allowed(f.BottomFrame) and header.ClearAllPoints then
                guideChrome[header] = true
                -- Native GuideName overlaps the scrolling content by nine units.
                -- Give its full 35-unit title row a place above that content.
                header:ClearAllPoints()
                header:SetPoint("BOTTOMLEFT", f.BottomFrame, "TOPLEFT", 0, 0)
                header:SetPoint("BOTTOMRIGHT", f.BottomFrame, "TOPRIGHT", 0, 0)
            end
            H.Fade(header.icon); H.Fade(header.classIcon)
            if header.text and header.text.ClearAllPoints and not guideChrome[header.text] then
                guideChrome[header.text] = true
                header.text:ClearAllPoints()
                header.text:SetPoint("LEFT", header, "LEFT", 6, 0)
                header.text:SetPoint("RIGHT", header, "RIGHT", -6, 0)
            end
            if header.text and header.text.SetJustifyH then
                header.text:SetJustifyH(forever and "LEFT" or "CENTER")
            end
            LegacyHeaderTitle(header, forever)
        end
        local scroll = f.ScrollFrame and f.ScrollFrame.ScrollBar
        if H.Allowed(scroll) then
            local visual = slimThumbs[scroll]
            H.LegacySlider(scroll, visual and visual.fill)
            local name = scroll.GetName and scroll:GetName()
            ScrollArrow(scroll.ScrollUpButton or (name and _G[name .. "ScrollUpButton"]), true, forever, true)
            ScrollArrow(scroll.ScrollDownButton or (name and _G[name .. "ScrollDownButton"]), false, forever, true)
            local thumb = scroll.GetThumbTexture and H.Texture(scroll:GetThumbTexture())
            if thumb then
                if not visual then
                    visual = {fill = scroll:CreateTexture(nil, "OVERLAY")}
                    slimThumbs[scroll] = visual
                    visual.fill:SetWidth(4)
                end
                if visual.thumb ~= thumb then
                    visual.thumb = thumb
                    visual.fill:ClearAllPoints()
                    visual.fill:SetPoint("TOP", thumb, "TOP")
                    visual.fill:SetPoint("BOTTOM", thumb, "BOTTOM")
                end
                -- Retain the native thumb geometry and drag hit area.
                H.Fade(thumb)
                local r, g, b = S.GetAccentColor()
                if visual.forever ~= forever then
                    visual.fill:SetWidth(forever and 3 or 4)
                    visual.forever = forever
                end
                if forever then r, g, b = 0.56, 0.41, 0.27 end
                visual.fill:SetColorTexture(r, g, b, forever and 0.72 or 0.8)
            end
        end
        if f.Footer then
            LegacyResizeGrip(f.Footer, forever)
            local cog = f.Footer.cog
            local label = f.Footer.text
            if forever then Font(label) end
            if H.Allowed(label) and label.GetTextColor then
                if forever then
                    if not footerTint[label] then footerTint[label] = {label:GetTextColor()} end
                    local r, g, b = WarmTitle()
                    label:SetTextColor(r * 0.88, g * 0.88, b * 0.88, footerTint[label][4])
                elseif footerTint[label] then
                    label:SetTextColor(unpack(footerTint[label]))
                    footerTint[label] = nil
                end
            end
            if H.Allowed(cog) and cog.GetNormalTexture then
                local icon = H.Texture(cog:GetNormalTexture())
                if icon then
                    icon:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\cogs-3.png")
                    if forever then icon:SetVertexColor(0.79, 0.63, 0.42, 1)
                    else icon:SetVertexColor(0.8, 0.8, 0.8, 1) end
                end
            end
        end
    end
    SyncShell = function(f, entry)
        if entry.suspended or CombatLocked() then return end
        local shown = true
        local border = f.rxpBorder
        if (entry.rim or entry.secondary or entry.joinedBody or entry.borderAlpha ~= nil) and border and border.GetAlpha and border.SetAlpha then
            if entry.forever then
                if entry.borderAlpha == nil then entry.borderAlpha = border:GetAlpha() end
                if border:GetAlpha() ~= 0 then border:SetAlpha(0) end
            elseif entry.borderAlpha ~= nil then
                border:SetAlpha(entry.borderAlpha)
                entry.borderAlpha = nil
            end
        end
        if f.rxpBackground then
            shown = not f.rxpBackground.IsShown or f.rxpBackground:IsShown()
            f.rxpBackground:SetAlpha(0)

        elseif f.GetBackdrop then
            local backdrop = f:GetBackdrop()
            shown = backdrop and backdrop.bgFile and true or false
            if shown and f.SetBackdropColor and not entry.lock then
                local r, g, b, a
                if f.GetBackdropColor then r, g, b, a = f:GetBackdropColor() end
                if r ~= 0 or g ~= 0 or b ~= 0 or a ~= 0 then
                    entry.lock = true
                    f:SetBackdropColor(0, 0, 0, 0)
                    entry.lock = false
                end
            end
        end
        local center = f.Center
        if center and center.GetAlpha and center.SetAlpha then
            if entry.forever then
                if entry.centerAlpha == nil then
                    entry.centerAlpha = center:GetAlpha()
                    entry.centerShown = center.IsShown and center:IsShown()
                end
                TextureAlpha(center, 0)
                if center.Hide then center:Hide() end
            elseif entry.centerAlpha ~= nil then
                TextureAlpha(center, entry.centerAlpha)
                if entry.centerShown and center.Show then center:Show() end
                entry.centerAlpha, entry.centerShown = nil, nil
            end
        end
        local opacity = entry.opacity
        local target = addon.targeting and addon.targeting.activeTargetFrame
        if f == addon.activeItemFrame then
            local source = target and themed[target]
            if source then opacity = source.opacity
            elseif addon.colors and addon.colors.background then opacity = addon.colors.background[4] or 1
            else opacity = select(4, S.GetPanelColor()) or 1 end
        end
        if not entry.forever then opacity = BackgroundOverride() or opacity end
        local composition = entry.composition
        if composition then
            local scale = ForeverOpacity()
            local base = SharedAlpha(opacity, scale)
            local override = BackgroundOverride()
            local split = composition.masked ~= nil and override ~= nil and override > 0
            SeatGuideFill(composition, split)
            SurfaceAlpha(composition.plate, composition.grain, base, 0.32)
            if composition.upperPlate then
                SurfaceAlpha(composition.upperPlate, composition.upperGrain, split and base or 0, 0.32)
            end
            if composition.stepFill then
                local extra = OverlayAlpha(SectionAlpha(0.75, scale), base)
                SetPaintAlpha(composition.stepFill, extra, composition.top == composition.currentStep)
            end
        end
        if entry.forever and entry.plate and not entry.joinedBody then
            local scale = ForeverOpacity()
            local override = BackgroundOverride()
            local auxiliary = entry.titleBody and themed[entry.titleBody]
            local titleMask = auxiliary and auxiliary.mask
            local splitAux = titleMask and override and override > 0
            local base = entry.auxTitle and SectionAlpha(0.75, scale)
                or entry.underlay and SharedAlpha(select(4, S.GetPanelColor()) or 1, scale) or 0
            local targetAlpha = SectionAlpha(entry.band and 0.80 or 0.75, scale)
            local split = entry.underlay and entry.underlay.masked and override and override > 0
            if entry.titleMask ~= titleMask then
                if entry.titleMask then
                    entry.plate:RemoveMaskTexture(entry.titleMask)
                    entry.grain:RemoveMaskTexture(entry.titleMask)
                end
                if titleMask then
                    entry.plate:AddMaskTexture(titleMask)
                    entry.grain:AddMaskTexture(titleMask)
                end
                for _, texture in ipairs({entry.plate, entry.grain}) do
                    texture:ClearAllPoints()
                    texture:SetPoint("TOPLEFT", entry.titleBody, "TOPLEFT", titleMask and 0 or 8, titleMask and 0 or -3)
                    texture:SetPoint("TOPRIGHT", entry.titleBody, "TOPRIGHT", titleMask and 0 or -8, titleMask and 0 or -3)
                    texture:SetPoint("BOTTOM", entry.art, "BOTTOM", 0, 0)
                end
                entry.titleMask = titleMask
            end
            if entry.auxBodyTitle and entry.mask then
                local splitBody = override and override > 0
                if entry.splitBody ~= splitBody then
                    for _, texture in ipairs({entry.plate, entry.grain}) do
                        texture:ClearAllPoints()
                        if splitBody then
                            texture:SetPoint("TOPLEFT", entry.auxBodyTitle, "BOTTOMLEFT", -auxTitleInset, 0)
                            texture:SetPoint("BOTTOMRIGHT", entry.art, "BOTTOMRIGHT")
                        else texture:SetAllPoints(entry.art) end
                    end
                    entry.splitBody = splitBody
                end
            end
            local extra = (split or splitAux or base == 1) and targetAlpha or OverlayAlpha(targetAlpha, base)
            SurfaceAlpha(entry.plate, entry.grain, extra, entry.meterArt and 0 or entry.band and 0.28 or 0.32)
            if entry.topRule then
                TextureAlpha(entry.topRule, targetAlpha)
                TextureAlpha(entry.bottomRule, targetAlpha)
            end
            if entry.art:IsShown() ~= shown then entry.art:SetShown(shown) end
        end
        local alpha = shown and not (entry.forever and (entry.joinedBody or entry.plate)) and opacity or 0
        if entry.forever and entry.badge then alpha = 0 end
        local showLayer = not (entry.forever and (entry.joinedBody or entry.plate or entry.badge))
        if entry.layer:IsShown() ~= showLayer then entry.layer:SetShown(showLayer) end
        if not entry.layer.GetAlpha or entry.layer:GetAlpha() ~= alpha then entry.layer:SetAlpha(alpha) end
        local items = addon.activeItemFrame
        if f == target and items and items ~= f and themed[items] then SyncShell(items, themed[items]) end
    end
    local function ThemeShell(f, chrome, composition, underlay, titleBody)
        if not f or not f.GetFrameLevel or (not chrome and not f.GetBackdrop and not f.rxpBackground) or CombatLocked()
            or (f.IsForbidden and f:IsForbidden()) then return end
        local entry = themed[f]
        if not entry then
            if not f.GetBackdrop and not f.rxpBackground and not ForeverLook() then return end
            -- Own flat background-only child: leave icon and guide regions native.
            local layer = CreateFrame("Frame", nil, f)
            layer:SetAllPoints(f)
            layer:SetFrameLevel(f:GetFrameLevel())
            layer:EnableMouse(false)
            if f.GetBackdrop or f.rxpBackground then
                S.Panel(layer, {noBorder = true, inset = false})
            end
            entry = {layer = layer, opacity = 1}
            local fill = f.rxpBackground and f.rxpBackground.textures and f.rxpBackground.textures[1]
            if fill and fill.GetVertexColor then
                local _, _, _, alpha = fill:GetVertexColor()
                entry.opacity = alpha or 1
            elseif f.GetBackdropColor then
                local _, _, _, alpha = f:GetBackdropColor()
                entry.opacity = alpha or 1
            end
            themed[f] = entry
            H.Hook(f, "SetBackdropColor", function(_, r, g, b, a)
                if entry.lock then return end
                entry.opacity = a or 1
                SyncShell(f, entry)
            end)
            H.Hook(f, "ClearBackdrop", function() SyncShell(f, entry) end)
            -- SetBackdrop already has the synchronous tint hook. Its callback
            -- below also handles removing/reinstating the native background.
        end
        entry.suspended = nil
        if chrome then
            local forever = ForeverLook()
            local joinedBody = chrome == "joined"
            local roleChanged = entry.joinedBody ~= joinedBody
            entry.joinedBody = joinedBody
            entry.composition = composition
            entry.underlay = underlay
            entry.badge = chrome == "badge"
            if entry.badge then entry.secondary = true end
            if forever and not entry.art and not joinedBody and not entry.badge then
                local legacyHeader = chrome == "legacyHeader"
                local header = legacyHeader or chrome == "header"
                local band = header or chrome == "footer" or chrome == "auxTitle"
                local art = ForeverArtHost(f)
                entry.art = art
                local title = chrome == "auxTitle"
                local grain, plate, meterArt = ForeverSurface(art, band, titleBody, header, legacyHeader)
                entry.grain, entry.plate, entry.band, entry.auxTitle = grain, plate, band, title
                entry.titleBody = titleBody
                if chrome == "auxBody" then entry.auxBodyTitle = f.title end
                entry.meterArt = meterArt
                entry.secondary = band
                if not entry.secondary then entry.rim = ForeverRim(art) end
                local edge = underlay or (entry.rim and art)
                if edge then entry.mask = MaskFill(art, edge, plate, grain, nil, nil, legacyHeader and 0 or nil) end

                if legacyHeader then
                    -- Use the outer rim's exact edge art, including its fallback.
                    local EUI = _G.EllesmereUI
                    local edgeArt = underlay and underlay.rim and underlay.rim[5]
                    local rule
                    if edgeArt then
                        rule = art:CreateTexture(nil, "BACKGROUND", nil, 3)
                        rule:SetTexture(edgeArt:GetTexture())
                        rule:SetTexCoord(edgeArt:GetTexCoord())
                        rule:SetHeight(edgeArt:GetHeight())
                    elseif EUI.ForeverBorderDivider then
                        rule = EUI.ForeverBorderDivider(art, "BACKGROUND", 3)
                    end
                    if not rule then
                        rule = art:CreateTexture(nil, "BACKGROUND", nil, 3)
                        rule:SetColorTexture(bronzeR, bronzeG, bronzeB, 1)
                        rule:SetHeight(1)
                    end
                    rule:SetPoint("TOPLEFT", art, "TOPLEFT", 0, 2)
                    rule:SetPoint("TOPRIGHT", art, "TOPRIGHT", 0, 2)
                    if entry.mask then rule:AddMaskTexture(entry.mask) end
                    if underlay then
                        underlay.headerRule = rule
                        rule:SetShown(underlay.top ~= f)
                    end
                    entry.topRule = rule
                end
                if band and (legacyHeader or (not title and not meterArt)) then
                    local divider = art:CreateTexture(nil, "BACKGROUND", nil, 3)
                    local edge = chrome == "footer" and "TOP" or "BOTTOM"
                    divider:SetPoint(edge .. "LEFT", art, edge .. "LEFT", 2, 0)
                    divider:SetPoint(edge .. "RIGHT", art, edge .. "RIGHT", -2, 0)
                    divider:SetHeight(1)
                    divider:SetColorTexture(bronzeR, bronzeG, bronzeB, header and 0.55 or 0.34)
                    if legacyHeader then
                        if entry.mask then divider:AddMaskTexture(entry.mask) end
                        entry.bottomRule = divider
                    end
                end
            end
            if entry.forever ~= forever or roleChanged then
                entry.forever = forever
                if entry.art then entry.art:SetShown(forever and not joinedBody) end
                if (entry.art or entry.badge or joinedBody) and f.GetBackdrop and f:GetBackdrop() then TintBackdrop(f) end
            end
        end
        SyncShell(f, entry)
    end
    local function TargetFrame()
        return addon.targeting and addon.targeting.activeTargetFrame
    end
    local QueueTargets, QueueItems
    local targetQueue, itemQueue = {}, {}
    local function ApplyTargets()
        local f = TargetFrame()
        if not f or CombatLocked() or (f.IsForbidden and f:IsForbidden()) then return end
        -- The container has secure action-button children. Only touch its visual
        -- backdrop/title outside combat; never scan or skin those buttons.
        if targetSeen ~= f then
            targetSeen = f
            if f.UpdateVisuals then H.Safe(f.UpdateVisuals, f) end
            H.Hook(f, "UpdateVisuals", function() AuxiliaryTitle(f); QueueTargets() end)
            H.Script(f, "OnShow", function() AuxiliaryTitle(f) end)
        end
        TintBackdrop(f)
        TintBackdrop(f.title)
        ThemeShell(f, "auxBody")
        ThemeShell(f.title, "auxTitle", nil, nil, f)
        AuxiliaryTitle(f)
    end
    QueueTargets = function()
        H.Queue(TargetFrame() or targetQueue, function()
            if CombatLocked() then applyWaiting = true; return end
            ApplyTargets()
        end)
    end
    local itemSeen
    local function ApplyItems()
        local f = addon.activeItemFrame
        if not f or CombatLocked() or (f.IsForbidden and f:IsForbidden()) then return end
        if itemSeen ~= f then
            itemSeen = f
            if f.UpdateVisuals then H.Safe(f.UpdateVisuals, f) end
            H.Hook(f, "UpdateVisuals", function() AuxiliaryTitle(f); QueueItems() end)
            H.Hook(f, "UpdateFrame", QueueItems)
            H.Script(f, "OnShow", function() AuxiliaryTitle(f) end)
        end
        TintBackdrop(f); TintBackdrop(f.title)
        ThemeShell(f, "auxBody"); ThemeShell(f.title, "auxTitle", nil, nil, f)
        AuxiliaryTitle(f)
        -- Secure item-use buttons keep all attributes, dimensions and handlers.
        -- Crop only their existing icon textures, outside combat.
        for _, button in ipairs(f.buttonList or {}) do
            local icon = H.Texture(button.icon)
            if icon then S.SquareIcon(icon) end
        end
    end
    QueueItems = function()
        H.Queue(addon.activeItemFrame or itemQueue, function()
            if CombatLocked() then applyWaiting = true; return end
            ApplyItems()
        end)
    end
    for _, name in ipairs({"CreateActiveItemFrame", "UpdateItemFrame"}) do H.Hook(addon, name, QueueItems) end
    local arrowTextureSeen, arrowWidth, arrowHeight, originalArrow, restoringArrow, arrowWaiting
    local function RestoreArrow()
        local saved = originalArrow
        if not saved then return end
        originalArrow, arrowTextureSeen, arrowWidth, arrowHeight = nil, nil, nil, nil
        local texture, frame = saved.texture, saved.frame
        texture:ClearAllPoints()
        texture:SetSize(saved.width, saved.height)
        if #saved.points > 0 then
            for _, point in ipairs(saved.points) do texture:SetPoint(unpack(point)) end
        else texture:SetAllPoints(frame) end
        texture:SetTexCoord(0, 1, 0, 1)
        texture:SetVertexColor(unpack(saved.tint))
        if saved.font and saved.font[1] then
            local _, size = saved.text:GetFont()
            saved.text:SetFont(saved.font[1], size or saved.font[2], saved.font[3])
        end
        if saved.color then saved.text:SetTextColor(unpack(saved.color)) end
        -- Ask RXP for its current theme artwork, not a stale saved texture path.
        restoringArrow = true
        if type(frame.UpdateVisuals) == "function" then H.Safe(frame.UpdateVisuals, frame)
        else texture:SetTexture(saved.path) end
        restoringArrow = false
        -- Native DrawArrow caches this bearing. Keep it when resetting the UVs,
        -- including the stationary/wrong-continent cases that may not redraw.
        if texture.SetRotation then texture:SetRotation(frame.wrongContinent and 0 or frame.orientation or 0) end
    end
    local function ApplyArrow()
        if restoringArrow then return end
        local frame = addon.arrowFrame
        if not H.Allowed(frame) then return end
        if CombatLocked() then arrowWaiting = true; return end
        arrowWaiting = false
        H.Hook(frame, "UpdateVisuals", ApplyArrow)
        H.Script(frame, "OnSizeChanged", ApplyArrow)
        if not ns.IsEnabled(module) or ns.RXPSettings and ns.RXPSettings().arrow == false then
            RestoreArrow()
            return
        end
        local texture = H.Texture(frame.texture)
        if texture then
            if not originalArrow or originalArrow.texture ~= texture then
                originalArrow = {frame = frame, texture = texture, path = texture:GetTexture(),
                    width = texture:GetWidth(), height = texture:GetHeight(), points = {}, tint = {texture:GetVertexColor()}}
                if texture.GetNumPoints and texture.GetPoint then
                    for i = 1, texture:GetNumPoints() do originalArrow.points[i] = {texture:GetPoint(i)} end
                end
                if H.Allowed(frame.text) and frame.text.GetFont then
                    originalArrow.text = frame.text
                    originalArrow.font, originalArrow.color = {frame.text:GetFont()}, {frame.text:GetTextColor()}
                end
            end
            local path = "Interface\\AddOns\\EUIAddonSkins\\Media\\NavigationChevronSmooth.tga"
            local forever = ForeverLook()
            if texture:GetTexture() ~= path or arrowTextureSeen ~= texture then
                texture:SetTexture(path)
                -- High-resolution shallow chevron; preserve the initial proportions.
                texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                if forever and texture.SetRotation and frame.orientation and frame.orientation ~= 0 then
                    texture:SetRotation(frame.wrongContinent and 0 or frame.orientation)
                end
                arrowTextureSeen = texture
                arrowWidth, arrowHeight = nil, nil
            end
            local width, height = frame:GetWidth(), frame:GetHeight()
            if arrowWidth ~= width or arrowHeight ~= height then
                -- Enlarge artwork only; keep native hit area, label and scale setting.
                texture:ClearAllPoints()
                texture:SetPoint("CENTER", frame, "CENTER", 0, 0)
                texture:SetSize(width * 1.1, height * 1.1)
                arrowWidth, arrowHeight = width, height
            end
            local r, g, b = S.GetAccentColor()
            if forever then r, g, b = copperR, copperG, copperB end
            local cr, cg, cb, ca = texture:GetVertexColor()
            if cr ~= r or cg ~= g or cb ~= b or ca ~= 1 then texture:SetVertexColor(r, g, b, 1) end
        end
        Font(frame.text, 0.9, 0.9, 0.92)
    end
    ns.RXPSettingsChanged = ApplyArrow
    H.Hook(addon, "SetupArrow", ApplyArrow)
    local guideWindowSeen
    local function V2Chrome(window)
        if not window then return end
        if CombatLocked() then applyWaiting = true; return end
        H.Fade(window.iconLogo); H.Fade(window.classIcon)
        local title, header = window.title, window.guideNameFrame
        if title and title.ClearAllPoints and H.Allowed(header) then
            local right = 6
            local forever = ForeverLook()
            if forever and H.Allowed(window.settingsButton) then right = 16 end
            for _, button in pairs({window.settingsButton, window.guideSelectButton}) do
                if H.Allowed(button) then right = right + button:GetWidth() + 7 end
            end
            -- Mirror the native control space on the left to keep the label
            -- centered on the header without covering either native button.
            title:ClearAllPoints()
            title:SetPoint("TOPLEFT", header, "TOPLEFT", forever and 7 or right, -6)
            title:SetPoint("TOPRIGHT", header, "TOPRIGHT", -right, -6)
            if title.SetJustifyH then title:SetJustifyH(forever and "LEFT" or "CENTER") end
            local subtitle = window.subtitle
            if subtitle and subtitle.SetJustifyH then subtitle:SetJustifyH(forever and "LEFT" or "CENTER") end
            if forever and subtitle and subtitle.GetFont and subtitle.SetFont and title.GetFont then
                Font(subtitle, 0.79, 0.69, 0.55)
                local path, _, flags = subtitle:GetFont()
                local _, size = title:GetFont()
                if path and size then
                    local target = math.max(8, size - 2)
                    if select(2, subtitle:GetFont()) ~= target then subtitle:SetFont(path, target, flags) end
                end
            end
        end
    end
    local rowDividers = setmetatable({}, {__mode = "k"})
    local function StepDivider(row, forever)
        local divider = rowDividers[row]
        if forever and not divider and H.Allowed(row) and row:IsShown() then
            divider = row:CreateTexture(nil, "BACKGROUND", nil, 2)
            divider:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 5, 0)
            divider:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -5, 0)
            divider:SetHeight(1)
            divider:SetColorTexture(bronzeR, bronzeG, bronzeB, 0.48)
            rowDividers[row] = divider
        end
        if divider then divider:SetShown(forever) end
    end
    local nativeFillAlpha = setmetatable({}, {__mode = "k"})
    local function NativeFillAlpha(fill, alpha)
        if not H.Allowed(fill) or not fill.GetAlpha or not fill.SetAlpha then return end
        if alpha then
            if nativeFillAlpha[fill] == nil then nativeFillAlpha[fill] = fill:GetAlpha() end
            TextureAlpha(fill, nativeFillAlpha[fill] * alpha)
        elseif nativeFillAlpha[fill] ~= nil then
            TextureAlpha(fill, nativeFillAlpha[fill])
            nativeFillAlpha[fill] = nil
        end
    end
    -- Change only the display labels. RXP's shared icon table also feeds
    -- tooltips, map markers and exported step data.
    local markerFiles = {
        ["interface/gossipframe/availablequesticon"] = "RestedXPQuestAccept",
        ["interface/gossipframe/activequesticon"] = "RestedXPQuestTurnIn",
        ["interface/gossipframe/gossipgossipicon"] = "RestedXPTalk",
        ["interface/worldmap/chatbubble_64grey"] = "RestedXPTalk",
        ["interface/worldstateframe/columnicon-flagcapture2"] = "RestedXPRouteFlag",
        -- Blizzard FileDataIDs for the same assets. These are exact aliases,
        -- never a generic substitution for item or spell FileDataIDs.
        ["132049"] = "RestedXPQuestAccept",
        ["132048"] = "RestedXPQuestTurnIn",
        ["132053"] = "RestedXPTalk",
        ["308474"] = "RestedXPTalk",
        ["137205"] = "RestedXPRouteFlag",
    }
    local function BronzeMarkers(text)
        if type(text) ~= "string" or not text:find("|T", 1, true) then return text end
        return (text:gsub("(|+)T([^:|]+)(:[^|]*)|t", function(pipes, path, geometry)
            -- A paired pipe is literal text. Preserve explicit crops and
            -- authored vertex colours as well as all unknown/atlas tags.
            if #pipes % 2 == 0 or not geometry:match("^:%d+[:%d%.%-]*$") then return end
            local _, fields = geometry:gsub(":", "")
            if fields > 4 then return end
            local key = path:lower():gsub("\\", "/"):gsub("%.blp$", ""):gsub("%.tga$", "")
            local file = markerFiles[key]
            if file then
                return pipes .. "TInterface/AddOns/EUIAddonSkins/Media/" .. file .. geometry .. "|t"
            end
        end))
    end
    local iconLabels = setmetatable({}, {__mode = "k"})
    local function SkinIconLabel(label, forever)
        if not H.Allowed(label) or not label.GetText or not label.SetText then return end
        local state = iconLabels[label]
        if not state then
            if not forever then return end
            state = {}
            iconLabels[label] = state
            H.Hook(label, "SetText", function(_, value)
                if state.writing or not ForeverLook() then return end
                if value ~= state.source then
                    state.source, state.rendered = value, BronzeMarkers(value)
                end
                if state.rendered ~= value then
                    state.writing = true
                    label:SetText(state.rendered)
                    state.writing = false
                end
            end)
        end
        local text = label:GetText()
        if forever then
            if text ~= state.rendered and text ~= state.source then
                state.source, state.rendered = text, BronzeMarkers(text)
            end
            if text == state.source and state.rendered ~= text then label:SetText(text) end
        elseif state.rendered ~= state.source and text == state.rendered then
            label:SetText(state.source)
        end
    end
    local function SkinActiveIcons(item, forever)
        for _, row in ipairs(item.elementRows or {}) do
            SkinIconLabel(row.icon, forever)
            SkinIconLabel(row.text, forever)
        end
    end
    local function V2Dividers(steps)
        if CombatLocked() then applyWaiting = true; return end
        local forever = ForeverLook()
        local window = addon.v2 and addon.v2.state and addon.v2.state.guideWindow or _G.RXPV2GuideWindow
        local shell = forever and window and compositions[window.frame]
        local scale = shell and ForeverOpacity()
        local extra = scale and OverlayAlpha(SectionAlpha(0.70, scale), SharedAlpha(select(4, S.GetPanelColor()) or 1, scale))
            or (not forever and BackgroundOverride())
        for _, item in pairs(steps.items or {}) do
            local row = item.frame
            SkinIconLabel(item.text, forever)
            StepDivider(row, forever)
            NativeFillAlpha(row and row.rxpShadow, forever and 0 or nil)
            NativeFillAlpha(item.numberFrame and item.numberFrame.rxpBackground, forever and 0 or nil)
            local fill = row and row.rxpBackground
            local texture = fill and fill.textures and fill.textures[1]
            if texture and texture.GetVertexColor and extra then
                local _, _, _, alpha = texture:GetVertexColor()
                NativeFillAlpha(fill, alpha and alpha > 0 and math.min(1, extra / alpha) or nil)
            else
                NativeFillAlpha(fill, nil)
            end
        end
    end
    local function V2FooterFill(window, forever)
        local alpha = BackgroundOverride()
        local native = select(4, S.GetPanelColor()) or 1
        NativeFillAlpha(window.footerBackground, forever and 0 or (alpha and native > 0 and math.min(1, alpha / native) or nil))
    end
    local function HideLegacyGuideArt(legacy)
        if not legacy then return end
        -- RXP keeps this root shown to drive V2 visibility, and the legacy
        -- cog is parented to the root even though it anchors to the footer.
        ComposeGuide(legacy, nil, nil, nil, false)
        ButtonRim(legacy.Footer and legacy.Footer.cog, false)
    end
    local function HideV2GuideArt(window)
        if not window then return end
        ComposeGuide(window.frame, nil, nil, nil, false)
        ButtonRim(window.settingsButton, false)
        ButtonRim(window.guideSelectButton, false)
        ButtonRim(window.closebutton, false)
        for _, panel in pairs({window.upperFrame, window.guideNameFrame, window.guideStepsFrame, window.footer}) do
            local entry = themed[panel]
            if entry and not entry.suspended then
                entry.suspended = true
                entry.layer:SetShown(false)
                if entry.art then entry.art:SetShown(false) end
            end
        end
    end
    local function Apply()
        if CombatLocked() then applyWaiting = true; return end
        applyWaiting = false
        Wrap(addon.v2, "GetTheme")
        local forever = ForeverLook()
        local legacy = addon.RXPFrame or _G.RXPFrame
        local hasMode = addon.v2 and type(addon.v2.IsGuideWindowEnabled) == "function"
        local v2Enabled = hasMode and addon.v2:IsGuideWindowEnabled()
        if v2Enabled then
            HideLegacyGuideArt(legacy)
        elseif legacy then
            LegacyChrome(legacy)
            for _, row in ipairs(legacy.ScrollChild and legacy.ScrollChild.framePool or {}) do
                if forever then Font(row.text); Font(row.number and row.number.text) end
                SkinIconLabel(row.text, forever)
                StepDivider(row, forever)
            end
            Scan(legacy)
            -- Secure children may make the guide root implicitly protected. Tint
            -- only the known visual containers, without entering action buttons.
            for _, key in ipairs({"BottomFrame", "GuideName", "Footer"}) do TintBackdrop(legacy[key]) end
            local shell = ComposeGuide(legacy, legacy.GuideName, legacy.Footer, legacy.CurrentStepFrame, forever)
            ThemeShell(legacy.BottomFrame, shell and "joined" or "body", shell)
            ButtonRim(legacy.Footer and legacy.Footer.cog, shell ~= nil)
            ThemeShell(legacy.GuideName, "legacyHeader", nil, shell)
            ThemeShell(legacy.Footer, "footer", nil, shell)
            ns.AttachAccent(S, legacy.GuideName)
            for _, step in pairs(legacy.CurrentStepFrame and legacy.CurrentStepFrame.framePool or {}) do
                TintBackdrop(step)
                TintBackdrop(step.number)
                if forever then
                    Font(step.number and step.number.text)
                end
                for _, element in pairs(step.elements or {}) do
                    LegacySkipCheck(element.button, forever)
                    if forever then Font(element.text) end
                    SkinIconLabel(element.icon, forever)
                    SkinIconLabel(element.text, forever)
                end
                -- The V1 pool also supplies independently positioned tip windows.
                local detached = step.GetFrameStrata and step:GetFrameStrata() ~= legacy:GetFrameStrata()
                ThemeShell(step, shell and not detached and "joined" or "body")
                ThemeShell(step.number, "badge")
            end
            H.Hook(legacy, "UpdateVisuals", function() LegacyChrome(legacy); refresh() end)
            H.Hook(legacy, "UpdateScrollBar", function() LegacyChrome(legacy) end)
            H.Fade(legacy.GuideName and legacy.GuideName.bg)
            H.Fade(legacy.Footer and legacy.Footer.bg)
        end
        -- Inspect only existing widgets; GetGuideWindow would create one eagerly.
        local window = addon.v2 and addon.v2.state and addon.v2.state.guideWindow or _G.RXPV2GuideWindow
        if guideWindowSeen ~= window then HideV2GuideArt(guideWindowSeen) end
        guideWindowSeen = window
        if hasMode and not v2Enabled then
            HideV2GuideArt(window)
        elseif window then
            Scan(window.frame)
            local shell = ComposeGuide(window.frame, window.upperFrame or window.guideNameFrame, window.footer, nil, forever)
            ThemeShell(window.upperFrame, shell and "joined" or "body")
            ThemeShell(window.guideNameFrame, "header", nil, shell)
            ThemeShell(window.guideStepsFrame, shell and "joined" or "body", shell)
            ThemeShell(window.footer, "footer", nil, shell)
            V2FooterFill(window, forever)
            for _, panel in pairs({window.upperFrame, window.guideStepsFrame}) do
                NativeFillAlpha(panel.rxpShadow, forever and 0 or nil)
            end
            ButtonRim(window.settingsButton, forever)
            ButtonRim(window.guideSelectButton, forever)
            ButtonRim(window.closebutton, forever)
            local steps = window.guideSteps
            if steps then
                local bar = steps.scroll and steps.scroll.scrollbar
                if bar then
                    ScrollArrow(bar.ScrollUpButton, true, forever)
                    ScrollArrow(bar.ScrollDownButton, false, forever)
                end
                H.Hook(steps, "SetRows", V2Dividers)
                V2Dividers(steps)
            end
            ns.AttachAccent(S, window.upperFrame or window.frame)
            H.Fade(window.banner)
            V2Chrome(window)
            H.Hook(window, "UpdateFrameLayout", function() V2Chrome(window) end)
            H.Hook(window, "UpdateTheme", refresh)
            H.Hook(window, "UpdateSubTheme", refresh)
            H.Hook(window, "RefreshLayout", function()
                H.Queue(window.frame, function() V2Chrome(window); Scan(window.frame) end)
            end)
            local r, g, b = WarmTitle()
            if forever then r, g, b = 1, 0.82, 0 end
            Font(window.title, r, g, b)
            if forever then Font(window.subtitle); Font(window.footerText) end
            if window.closebutton and H.Allowed(window.closebutton) then S.CloseButton(window.closebutton) end
        end
        -- Active V2 steps are widgets kept outside the main guide window.
        local state = addon.v2 and addon.v2.state
        for _, player in pairs(state and state.player or {}) do
            local active = player.activeStepFrame
            for _, child in pairs(active and active.children or {}) do
                ThemeShell(child.card or child.frame, "step")
                ThemeShell(child.title, "badge")
                SkinActiveIcons(child, forever)
            end
        end
        local party = state and state.activePartyStepFrame
        if party then ThemeShell(party.frame) end
        ApplyTargets()
        ApplyItems()
        ApplyArrow()
        local importer = addon.guideImporter
        if importer then
            for _, widget in pairs(importer.widgets or {}) do
                if type(widget) == "table" then Scan(widget.frame) end
            end
            H.Hook(importer, "UpdateTheme", refresh)
        end
    end
    refresh = function() H.Queue(module, Apply) end
    local function UpdateTheme()
        if not ns.IsEnabled(module) then return end
        if CombatLocked() then themeWaiting = true; return end
        themeWaiting = false
        if addon.settings and addon.settings.profile and addon.RXPFrame then
            H.Safe(addon.LoadActiveTheme, addon)
            -- Refresh visuals directly; RenderFrame also reloads the current guide.
            if addon.RXPFrame.UpdateVisuals then H.Safe(addon.RXPFrame.UpdateVisuals, addon.RXPFrame, true) end
        end
        local window = addon.v2 and addon.v2.state and addon.v2.state.guideWindow or _G.RXPV2GuideWindow
        if window and window.UpdateTheme then H.Safe(window.UpdateTheme, window, {updateChildren = true}) end
        if addon.v2 and addon.v2.UpdateActiveStepTheme and addon.v2.state and addon.v2.state.player and addon.player then
            H.Safe(addon.v2.UpdateActiveStepTheme, addon.v2)
        end
        if addon.guideImporter and addon.guideImporter.UpdateTheme then H.Safe(addon.guideImporter.UpdateTheme, addon.guideImporter) end
        local target = TargetFrame()
        if target and not CombatLocked() and target.UpdateVisuals then H.Safe(target.UpdateVisuals, target) end
        S.RefreshSoftBorders()
        refresh()
    end
    Wrap(addon, "LoadActiveTheme", true)
    Wrap(addon.v2, "GetTheme")
    for _, name in ipairs({"RenderFrame", "LoadGuide", "SetStep"}) do H.Hook(addon, name, refresh) end
    H.Hook(addon.v2, "GetGuideWindow", function()
        local window = addon.v2.state and addon.v2.state.guideWindow or _G.RXPV2GuideWindow
        if window and window ~= guideWindowSeen then refresh() end
    end)
    H.Hook(addon.v2, "DisableLegacyGuideWindow", function()
        if not CombatLocked() then HideLegacyGuideArt(addon.RXPFrame or _G.RXPFrame) end
        refresh()
    end)
    H.Hook(addon.v2, "UpdatePlayerActiveStepItem", function(_, item)
        if not CombatLocked() and ForeverLook() then SkinActiveIcons(item, true) end
    end)
    for _, name in ipairs({"UpdateGuideWindow", "UpdateActiveStepTheme"}) do H.Hook(addon.v2, name, refresh) end
    if addon.ui and addon.ui.v2 then
        H.Hook(addon.ui.v2, "CreateGuideImporter", refresh)
        H.Hook(addon.ui.v2, "ApplyFrameBackdrop", function(_, f, edge, background)
            local entry = themed[f]
            if entry then entry.opacity = background and background[4] or 1; SyncShell(f, entry)
            else refresh() end -- one coalesced discovery for newly constructed controls
        end)
        H.Hook(addon.ui.v2, "SetFrameBackdropShown", function(_, f)
            local entry = themed[f]
            if entry then SyncShell(f, entry) end
        end)
    end
    for _, name in ipairs({"CreateTargetFrame", "RenderTargetFrameBackground"}) do
        H.Hook(addon.targeting, name, QueueTargets)
    end
    -- Native target updates may reset the title dimensions; never walk its secure rows.
    H.Hook(addon.targeting, "UpdateTargetFrame", function() AuxiliaryTitle(TargetFrame()) end)
    local combatEvents = CreateFrame("Frame")
    combatEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatEvents:SetScript("OnEvent", function()
        if themeWaiting then UpdateTheme()
        elseif applyWaiting then refresh() end
        if module.optionsWaiting then refreshOptions() end
        if arrowWaiting then ApplyArrow() end
    end)
    local settingsRegistered
    local settingsKey = OPACITY_APP
    local function SettingsChanged()
        UpdateTheme()
        if ns.RefreshPopupMenusNow then ns.RefreshPopupMenusNow() end
    end
    local function ResetSkinSettings()
        if EUIAddonSkinsDB then EUIAddonSkinsDB.restedXP = nil end
        SettingsChanged()
        refreshOptions()
        local registry = LibStub and LibStub("AceConfigRegistry-3.0", true)
        if settingsRegistered and registry and registry.NotifyChange then registry:NotifyChange(settingsKey) end
    end
    local function ApplyOpacity()
        if CombatLocked() then themeWaiting = true; return end
        if not ns.IsEnabled(module) then return end
        for frame, entry in pairs(themed) do
            if not frame.IsForbidden or not frame:IsForbidden() then SyncShell(frame, entry) end
        end
        local forever = ForeverLook()
        local colors = addon.colors
        local fill = colors and colors.bottomFrameBG
        if fill then
            local old = fill[4]
            local scale = ForeverOpacity()
            fill[4] = ForeverLook() and OverlayAlpha(SectionAlpha(0.70, scale), SharedAlpha(colors.background[4] or 1, scale))
                or BackgroundOverride() or select(4, S.GetPanelColor())
            local root = addon.RXPFrame or _G.RXPFrame
            for _, row in ipairs(root and root.ScrollChild and root.ScrollChild.framePool or {}) do
                if H.Allowed(row) and row.GetBackdropColor then
                    local r, g, b, a = row:GetBackdropColor()
                    local highlight = colors.bottomFrameHighlight
                    local hovering = highlight and r == highlight[1] and g == highlight[2]
                        and b == highlight[3] and a == highlight[4]
                    if forever and a and not hovering and a ~= fill[4]
                        or old and a and math.abs(a - old) < 0.004 and math.abs(a - fill[4]) >= 0.004
                        and math.abs(r - fill[1]) < 0.004 and math.abs(g - fill[2]) < 0.004
                        and math.abs(b - fill[3]) < 0.004 then
                        if forever then row:SetBackdropColor(fill[1], fill[2], fill[3], fill[4])
                        else row:SetBackdropColor(r, g, b, fill[4]) end
                    end
                end
            end
        end
        local window = addon.v2 and addon.v2.state and addon.v2.state.guideWindow or _G.RXPV2GuideWindow
        if window then
            if window.guideSteps then V2Dividers(window.guideSteps) end
            V2FooterFill(window, ForeverLook())
        end
    end
    local function OpenOpacitySettings()
        if CombatLocked() then return end
        local registry = LibStub and LibStub("AceConfigRegistry-3.0", true)
        local dialog = LibStub and LibStub("AceConfigDialog-3.0", true)
        if not registry or not dialog then return end
        if not settingsRegistered then
            registry:RegisterOptionsTable(settingsKey, {
                type = "group", name = "RestedXP — EUI AddonSkins", args = {
                    opacity = {
                        type = "range", name = "Background Opacity", order = 1,
                        width = "full", min = 0, max = 100, step = 1, bigStep = 5,
                        get = function()
                            local alpha = BackgroundOverride()
                            if alpha == nil then
                                alpha = select(4, S.GetPanelColor()) or 0.92
                                if ForeverLook() then alpha = alpha * 0.70 / 0.92 end
                            end
                            return math.floor(alpha * 100 + 0.5)
                        end,
                        set = function(_, value)
                            if type(value) ~= "number" or value ~= value then return end
                            SavePreference("opacity", math.max(0, math.min(100, value)) / 100)
                            -- Coalesce slider changes and use the existing combat-safe refresh.
                            H.Queue(settingsKey, ApplyOpacity)
                        end,
                    },
                    reset = {type = "execute", name = "Reset Skin Settings", order = 2, func = ResetSkinSettings},
                },
            })
            dialog:SetDefaultSize(settingsKey, 350, 150)
            settingsRegistered = true
        end
        refreshOptions()
        dialog:Open(settingsKey)
    end
    local function StyleChoice(label, value)
        return {text = label, isNotRadio = false, checked = function()
            local preferences = SkinPreferences()
            return (preferences and preferences.style or "auto") == value
        end, func = function()
            SavePreference("style", value)
            SettingsChanged()
            refreshOptions()
        end}
    end
    local settingsMenu = {
        text = "EUI AddonSkins", notCheckable = true, hasArrow = true, padding = 28,
        menuList = {
            {text = "Style", notCheckable = true, isTitle = true},
            StyleChoice("Automatic", "auto"),
            StyleChoice("EUI Standard", "standard"),
            StyleChoice("EUI Forever", "forever"),
            {text = "Background Opacity…", notCheckable = true, func = OpenOpacitySettings},
            {text = "Reset Skin Settings", notCheckable = true, func = ResetSkinSettings},
        },
    }
    settingsMenu.menuList[4].disabled = not (_G.EllesmereUI and _G.EllesmereUI.IS_FOREVER)
    local function PadMenu(menu, settingsIndex, pad)
        local result
        for i, item in ipairs(menu) do
            local needsPadding = pad and item.hasArrow
            if not result and (i == settingsIndex or needsPadding) then
                result = {}
                for j = 1, i - 1 do result[j] = menu[j] end
            end
            if result then
                if i == settingsIndex then result[#result + 1] = settingsMenu end
                if needsPadding then
                    local copy = Copy(item)
                    copy.padding = (item.padding or 0) + 28
                    if type(item.menuList) == "table" then copy.menuList = PadMenu(item.menuList, nil, true) end
                    item = copy
                end
                result[#result + 1] = item
            end
        end
        return result or menu
    end
    if type(addon.ShowMenu) == "function" then
        local showMenu = addon.ShowMenu
        addon.ShowMenu = function(self, menu, ...)
            if not CombatLocked() and ns.IsEnabled(module) and type(menu) == "table" then
                local optionsText = _G.GAMEOPTIONS_MENU
                local settingsIndex
                if optionsText then
                    for i, item in ipairs(menu) do
                        if item.text == optionsText .. "..." then settingsIndex = i; break end
                    end
                end
                local pad = ForeverLook()
                if settingsIndex or pad then menu = PadMenu(menu, settingsIndex, pad) end
            end
            return showMenu(self, menu, ...)
        end
    end
    if ns.BindPopupOwner then
        local menuLook = {
            noAccent = true, chevrons = true, hoverAlpha = 0.38,
            chevronColor = {0.88, 0.66, 0.39},
            hoverColor = {0.80, 0.56, 0.32},
            legacyShell = function(layer)
                local grain, plate = ForeverSurface(layer, true)
                -- Menus share a fixed, opaque dark material at every depth.
                -- Initialize the gradient and grain independently of the guide.
                SurfaceAlpha(plate, grain, 1, 0.28)
                MaskFill(layer, layer, plate, grain)
                ForeverRim(layer)
            end,
        }
        local options = {legacyLook = function()
            local EUI = _G.EllesmereUI
            if ForeverLook() and EUI.IS_FOREVER and EUI.ForeverBorder and EUI.ForeverBorderSeat and EUI.ForeverBorderShown then
                return menuLook
            end
        end}
        H.Hook(addon, "ShowMenu", function(_, _, owner)
            ns.BindPopupOwner(S, module, owner or (addon.RXPFrame and addon.RXPFrame.MenuFrame), options)
        end)
        H.Hook(addon.v2, "UpdateMenuTheme", function()
            if ForeverLook() then ns.RefreshPopupMenusNow() end
        end)
        if addon.RXPFrame then ns.BindPopupOwner(S, module, addon.RXPFrame.MenuFrame, options) end
        if S.OnLooksChanged then S.OnLooksChanged(ns.RefreshPopupMenus) end
    end
    module.refresh = function() refreshOptions(); UpdateTheme() end
    if S.OnLooksChanged then S.OnLooksChanged(UpdateTheme); S.OnLooksChanged(refreshOptions) end
    refreshOptions()
    UpdateTheme()
end)

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("RXPGuides", DefineSkin)
else DefineSkin() end
