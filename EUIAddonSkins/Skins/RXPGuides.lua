local ADDON, ns = ...
local function DefineSkin()
-- AceConfig widgets are shared pools. Only our child layers enter EUI's skin
-- registry; restore native regions/backdrops before a widget is reused elsewhere.
local function OptionsSkin(S, H, module, addon)
    local unpack = unpack or table.unpack
    local states, roots = setmetatable({}, {__mode = 'k'}), setmetatable({}, {__mode = 'k'})
    local Paint, PaintTree
    local function App(name)
        local title = addon.title or 'RestedXP Guides'
        return name == title or type(name) == 'string' and name:sub(1, #title + 1) == title .. '/'
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
    local function Font(d, text, r, g, b)
        if not H.Allowed(text) or not text.GetFont then return end
        local saved = Save(d, text)
        if not saved.font then saved.font, saved.color = {text:GetFont()}, {text:GetTextColor()} end
        local path, _, flags = text:GetFont()
        local target, targetFlags = S.GetFont()
        if path ~= target or flags ~= (targetFlags or '') then S.Font(text) end
        if r then text:SetTextColor(r, g, b, select(4, text:GetTextColor())) end
    end
    local function Layer(d, key, host, method, options)
        if not H.Allowed(host) then return end
        local layer = d.layers[key]
        if not layer then
            layer = CreateFrame(method == 'PageButton' and 'Button' or 'Frame', nil, host)
            layer:SetAllPoints(host); layer:EnableMouse(false)
            layer:SetFrameLevel(math.max(0, host:GetFrameLevel() - 1))
            S[method or 'Panel'](layer, options or {noBorder = true})
            d.layers[key] = layer
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
        layer:SetAlpha(1)
        return layer
    end
    local function Neutral(d, text, disabled)
        Font(d, text, disabled and 0.5 or 0.9, disabled and 0.5 or 0.9, disabled and 0.52 or 0.92)
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
        local r, g, b = S.GetAccentColor(); grip.fill:SetColorTexture(r, g, b, 0.85); grip:SetAlpha(1)
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
        local d = states[widget]
        if not d then
            d = {layers = {}, saved = {}}; states[widget] = d
            frame:HookScript('OnHide', function() roots[widget] = nil; Restore(d) end)
            H.Script(frame, 'OnShow', function() if Owned(widget) then Paint(widget) end end)
        end
        if not ns.IsEnabled(module) or not (popup or Owned(widget)) then Restore(d); return end
        if InCombatLockdown and InCombatLockdown() then module.optionsWaiting = true; return end
        d.active = true
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
            Neutral(d, widget.text or frame.GetFontString and frame:GetFontString(), widget.disabled)
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
                Neutral(d, widget.button:GetFontString(), widget.disabled)
            end
        elseif kind == 'EditBox' then
            Input(d, widget.editbox or frame); Neutral(d, widget.label, widget.disabled)
            if H.Allowed(widget.button) then Fade(d, widget.button); Layer(d, 'accept', widget.button, 'Button') end
        elseif kind == 'ScrollFrame' then
            Slider(d, widget.scrollbar or widget.scrollBar)
        elseif kind == 'Label' then
            Font(d, widget.label)
        elseif kind == 'ColorPicker' then
            Neutral(d, widget.text, widget.disabled)
        elseif kind == 'Frame' then
            Fade(d, frame); Layer(d, 'window', frame)
            if H.Allowed(widget.closebtn) then Fade(d, widget.closebtn); Layer(d, 'close', widget.closebtn, 'CloseButton') end
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
            roots[rootframe or container] = true
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
            if widget then roots[widget] = true; PaintTree(widget) end
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
    local refreshOptions = OptionsSkin(S, H, module, addon)
    local themed = setmetatable({}, {__mode = "k"})
    local targetSeen
    local copies, wrapped = setmetatable({}, {__mode = "k"}), {}
    local unpack = unpack or table.unpack
    local function Pack(...) return {n = select("#", ...), ...} end
    local function Copy(t)
        local out = {}; for k, v in pairs(t or {}) do out[k] = v end; return out
    end
    local function Theme(source)
        if type(source) ~= "table" then return source end
        local out = copies[source]
        if not out then out = Copy(source); copies[source] = out end
        local r, g, b = S.GetAccentColor()
        local pr, pg, pb, pa = S.GetPanelColor()
        out.font = S.GetFont()
        -- Session copies leave registered themes, saved choices and semantic colors intact.
        if source.backgroundColors then
            out.backgroundColors = Copy(source.backgroundColors)
            for _, key in ipairs({"common", "guideName", "guideWindow", "scrollbar", "inactivePartyTab", "activeStepCheckbox"}) do
                out.backgroundColors[key] = {pr, pg, pb, pa}
            end
            out.backgroundColors.activeStepCheckboxChecked = {r, g, b, 1}
            out.borderColors = Copy(source.borderColors)
            for _, key in ipairs({"common", "commonEdge", "inactivePartyTab"}) do
                out.borderColors[key] = {0.055, 0.055, 0.055, 1}
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
            out.bottomFrameBG = {pr, pg, pb, pa}
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
    local function TintBackdrop(f)
        if InCombatLockdown and InCombatLockdown() then return end
        if not f or (f.IsForbidden and f:IsForbidden()) then return end
        if H.Allowed(f) and f:GetObjectType() == "CheckButton" then
            if not guideChecks[f] then
                local before = {}; for _, region in ipairs(H.Regions(f)) do before[region] = true end
                S.Checkbox(f)
                for _, region in ipairs(H.Regions(f)) do
                    if not before[region] and H.Texture(region) and region.GetDrawLayer and region:GetDrawLayer() == "BACKGROUND" then
                        region:ClearAllPoints(); region:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
                        region:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
                    end
                end
                guideChecks[f] = true
            end
            for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture", "GetHighlightTexture"}) do
                if f[getter] then H.Fade(f[getter](f)) end
            end
            local r, g, b = S.GetAccentColor()
            for _, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
                local texture = f[getter] and H.Texture(f[getter](f))
                if texture then
                    texture:SetColorTexture(r, g, b, 1)
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
                if r and g and b and (math.abs(r - g) > 0.04 or math.abs(r - b) > 0.04) then return end
                borderLocks[f] = true
                f:SetBackdropBorderColor(0.055, 0.055, 0.055, 1)
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
    local function CombatLocked()
        return InCombatLockdown and InCombatLockdown()
    end
    local slimThumbs = {}
    local guideChrome = setmetatable({}, {__mode = "k"})
    local function LegacyChrome(f)
        if CombatLocked() or not f then return end
        local header = f.GuideName
        if H.Allowed(header) then
            if not guideChrome[header] and H.Allowed(f.BottomFrame) and header.ClearAllPoints then
                guideChrome[header] = true
                -- Native GuideName overlaps the scrolling content by nine units.
                -- Give its full 35-unit title row a place above that content.
                header:ClearAllPoints()
                header:SetPoint("BOTTOMLEFT", f.BottomFrame, "TOPLEFT", 0, 0)
                header:SetPoint("BOTTOMRIGHT", f.BottomFrame, "TOPRIGHT", 0, 0)
            end
            local icon, class = H.Texture(header.icon), H.Texture(header.classIcon)
            if icon then
                icon:ClearAllPoints(); icon:SetPoint("TOPLEFT", header, "TOPLEFT", 6, -3)
                icon:SetSize(28, 28); S.SquareIcon(icon)
            end
            if class and icon then
                class:ClearAllPoints(); class:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -1)
                class:SetSize(12, 12); S.SquareIcon(class)
            end
            if header.text then
                header.text:ClearAllPoints()
                header.text:SetPoint("LEFT", header, "LEFT", 42, 0)
                header.text:SetPoint("RIGHT", header, "RIGHT", -6, 0)
            end
        end
        local scroll = f.ScrollFrame and f.ScrollFrame.ScrollBar
        if H.Allowed(scroll) then
            local visual = slimThumbs[scroll]
            H.LegacySlider(scroll, visual and visual.fill)
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
                visual.fill:SetColorTexture(r, g, b, 0.8)
            end
        end
        if f.Footer then
            if H.Allowed(f.Footer.icon) then H.Resize(f.Footer.icon, true) end
            local cog = f.Footer.cog
            if H.Allowed(cog) and cog.GetNormalTexture then
                local icon = H.Texture(cog:GetNormalTexture())
                if icon then
                    icon:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\cogs-3.png")
                    icon:SetVertexColor(0.8, 0.8, 0.8, 1)
                end
            end
        end
    end
    SyncShell = function(f, entry)
        if CombatLocked() then return end
        local shown = true
        if f.rxpBackground then
            shown = not f.rxpBackground.IsShown or f.rxpBackground:IsShown()
            f.rxpBackground:SetAlpha(0) -- native border/visibility still belongs to RXP
        elseif f.GetBackdrop then
            local backdrop = f:GetBackdrop()
            shown = backdrop and backdrop.bgFile and true or false
            if shown and f.SetBackdropColor and not entry.lock then
                entry.lock = true
                f:SetBackdropColor(0, 0, 0, 0)
                entry.lock = false
            end
        end
        entry.layer:SetAlpha(shown and entry.opacity or 0)
    end
    local function ThemeShell(f)
        if not f or not f.GetFrameLevel or (not f.GetBackdrop and not f.rxpBackground) or CombatLocked()
            or (f.IsForbidden and f:IsForbidden()) then return end
        local entry = themed[f]
        if not entry then
            -- Own flat background-only child: leave icon and guide regions native.
            local layer = CreateFrame("Frame", nil, f)
            layer:SetAllPoints(f)
            layer:SetFrameLevel(f:GetFrameLevel())
            layer:EnableMouse(false)
            S.Panel(layer, {noBorder = true, inset = false})
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
        SyncShell(f, entry)
    end
    local function TargetFrame()
        return addon.targeting and addon.targeting.activeTargetFrame
    end
    local function ApplyTargets()
        local f = TargetFrame()
        if not f or CombatLocked() or (f.IsForbidden and f:IsForbidden()) then return end
        -- The container has secure action-button children. Only touch its visual
        -- backdrop/title outside combat; never scan or skin those buttons.
        if targetSeen ~= f then
            targetSeen = f
            if f.UpdateVisuals then H.Safe(f.UpdateVisuals, f) end
            H.Hook(f, "UpdateVisuals", refresh)
        end
        TintBackdrop(f)
        TintBackdrop(f.title)
        ThemeShell(f)
        ThemeShell(f.title)
        local r, g, b = S.GetAccentColor()
        H.Font(f.title and f.title.text, r, g, b)
    end
    local itemSeen
    local function ApplyItems()
        local f = addon.activeItemFrame
        if not f or CombatLocked() or (f.IsForbidden and f:IsForbidden()) then return end
        if itemSeen ~= f then
            itemSeen = f
            if f.UpdateVisuals then H.Safe(f.UpdateVisuals, f) end
            H.Hook(f, "UpdateVisuals", function() H.Queue(f, ApplyItems) end)
            H.Hook(f, "UpdateFrame", function() H.Queue(f, ApplyItems) end)
        end
        TintBackdrop(f); TintBackdrop(f.title)
        ThemeShell(f); ThemeShell(f.title)
        local r, g, b = S.GetAccentColor()
        H.Font(f.title and f.title.text, r, g, b)
        -- Secure item-use buttons keep all attributes, dimensions and handlers.
        -- Crop only their existing icon textures, outside combat.
        for _, button in ipairs(f.buttonList or {}) do
            local icon = H.Texture(button.icon)
            if icon then S.SquareIcon(icon) end
        end
    end
    local function QueueItems()
        H.Queue(addon.activeItemFrame or module, function()
            if CombatLocked() then applyWaiting = true; return end
            ApplyItems()
        end)
    end
    for _, name in ipairs({"CreateActiveItemFrame", "UpdateItemFrame"}) do H.Hook(addon, name, QueueItems) end
    local function Apply()
        if CombatLocked() then applyWaiting = true; return end
        applyWaiting = false
        Wrap(addon.v2, "GetTheme")
        local legacy = addon.RXPFrame or _G.RXPFrame
        if legacy then
            LegacyChrome(legacy)
            Scan(legacy)
            -- Secure children may make the guide root implicitly protected. Tint
            -- only the known visual containers, without entering action buttons.
            for _, key in ipairs({"BottomFrame", "GuideName", "Footer"}) do TintBackdrop(legacy[key]) end
            ThemeShell(legacy.BottomFrame)
            ThemeShell(legacy.GuideName)
            ThemeShell(legacy.Footer)
            ns.AttachAccent(S, legacy.GuideName)
            for _, step in pairs(legacy.CurrentStepFrame and legacy.CurrentStepFrame.framePool or {}) do
                TintBackdrop(step)
                TintBackdrop(step.number)
                ThemeShell(step)
                ThemeShell(step.number)
            end
            H.Hook(legacy, "UpdateVisuals", function() LegacyChrome(legacy); refresh() end)
            H.Hook(legacy, "UpdateScrollBar", function() LegacyChrome(legacy) end)
            H.Fade(legacy.GuideName and legacy.GuideName.bg)
            H.Fade(legacy.Footer and legacy.Footer.bg)
        end
        -- Inspect only existing widgets; GetGuideWindow would create one eagerly.
        local window = addon.v2 and addon.v2.state and addon.v2.state.guideWindow or _G.RXPV2GuideWindow
        if window then
            Scan(window.frame)
            for _, key in ipairs({"upperFrame", "guideNameFrame", "guideStepsFrame"}) do ThemeShell(window[key]) end
            ns.AttachAccent(S, window.upperFrame or window.frame)
            H.Fade(window.banner)
            H.Hook(window, "UpdateTheme", refresh)
            H.Hook(window, "UpdateSubTheme", refresh)
            H.Hook(window, "RefreshLayout", refresh)
            local r, g, b = S.GetAccentColor()
            H.Font(window.title, r, g, b)
            if window.closebutton and H.Allowed(window.closebutton) then S.CloseButton(window.closebutton) end
        end
        -- Active V2 steps are widgets kept outside the main guide window.
        local state = addon.v2 and addon.v2.state
        for _, player in pairs(state and state.player or {}) do
            local active = player.activeStepFrame
            for _, child in pairs(active and active.children or {}) do
                ThemeShell(child.card or child.frame)
                ThemeShell(child.title)
            end
        end
        local party = state and state.activePartyStepFrame
        if party then ThemeShell(party.frame) end
        ApplyTargets()
        ApplyItems()
        local importer = addon.guideImporter
        if importer then
            for _, widget in pairs(importer.widgets or {}) do
                if type(widget) == "table" then Scan(widget.frame) end
            end
            H.Hook(importer, "UpdateTheme", refresh)
        end
        S.RefreshSoftBorders()
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
        refresh()
    end
    Wrap(addon, "LoadActiveTheme", true)
    Wrap(addon.v2, "GetTheme")
    for _, name in ipairs({"RenderFrame", "LoadGuide", "SetStep"}) do H.Hook(addon, name, refresh) end
    for _, name in ipairs({"GetGuideWindow", "UpdateGuideWindow", "UpdateActiveStepTheme"}) do H.Hook(addon.v2, name, refresh) end
    if addon.ui and addon.ui.v2 then
        H.Hook(addon.ui.v2, "CreateGuideImporter", refresh)
        H.Hook(addon.ui.v2, "ApplyFrameBackdrop", function(_, f, edge, background)
            local entry = themed[f]
            if entry then entry.opacity = background and background[4] or 1; SyncShell(f, entry) end
            refresh()
        end)
        H.Hook(addon.ui.v2, "SetFrameBackdropShown", function(_, f)
            local entry = themed[f]
            if entry then SyncShell(f, entry) end
        end)
    end
    for _, name in ipairs({"CreateTargetFrame", "RenderTargetFrameBackground", "UpdateTargetFrame"}) do
        H.Hook(addon.targeting, name, refresh)
    end
    local combatEvents = CreateFrame("Frame")
    combatEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatEvents:SetScript("OnEvent", function()
        if themeWaiting then UpdateTheme()
        elseif applyWaiting then refresh() end
        if module.optionsWaiting then refreshOptions() end
    end)
    if ns.BindPopupOwner then
        H.Hook(addon, "ShowMenu", function(_, _, owner)
            ns.BindPopupOwner(S, module, owner or (addon.RXPFrame and addon.RXPFrame.MenuFrame))
        end)
        if addon.RXPFrame then ns.BindPopupOwner(S, module, addon.RXPFrame.MenuFrame) end
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
