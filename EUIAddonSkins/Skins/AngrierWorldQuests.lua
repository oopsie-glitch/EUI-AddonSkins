local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule('AngrierWorldQuests', 'Angrier World Quests', function()
    return type(_G.AngrierWorldQuests) == 'table'
end, function(S, module)
    local H = ns.CreateSkinHelper(S, module)
    local canvas, tab, generation = nil, nil, 0
    local controls, layers = setmetatable({}, {__mode='k'}), setmetatable({}, {__mode='k'})
    local pooled, groups = setmetatable({}, {__mode='k'}), setmetatable({}, {__mode='k'})
    local fontGeneration = setmetatable({}, {__mode='k'})
    local Refresh, Profiles, PaintWidget
    local function Ready()
        return ns.IsEnabled(module) and not (InCombatLockdown and InCombatLockdown())
    end
    local function Library(name) return LibStub and LibStub(name, true) end
    local function TargetModule(name)
        local app = _G.AngrierWorldQuests
        return app and app.GetModule and app:GetModule(name, true)
    end
    local function Text(text, owner)
        if not H.Allowed(text) or text:GetObjectType() ~= 'FontString' then return end
        local path, flags = S.GetFont()
        local current, _, currentFlags = text:GetFont()
        if fontGeneration[text] ~= generation or current ~= path or (currentFlags or '') ~= (flags or '') then
            H.Font(text); fontGeneration[text] = generation
        end
        if owner and owner.IsEnabled and not owner:IsEnabled() then text:SetTextColor(.5,.5,.52)
        else text:SetTextColor(.89,.89,.91) end
    end
    -- Visual children never receive mouse input. Native controls, hit rectangles,
    -- action scripts, anchors, text insets and enabled state remain untouched.
    local function Layer(frame)
        local layer = layers[frame]
        if not layer then
            layer = CreateFrame('Frame', nil, frame)
            layer:SetAllPoints(frame); layer:EnableMouse(false)
            layer:SetFrameLevel(math.max(0, frame:GetFrameLevel()-1))
            S.Panel(layer, {noBorder=true, inset=false})
            layer.hover = frame:CreateTexture(nil, 'HIGHLIGHT')
            layer.hover:SetAllPoints(frame); layer.hover:SetColorTexture(1,1,1,.1)
            layers[frame] = layer
        end
        layer:Show(); layer.hover:SetAlpha(1)
        return layer
    end
    local function Arrow(frame)
        local layer = Layer(frame)
        if not layer.arrow then
            layer.arrow = frame:CreateTexture(nil, 'OVERLAY')
            layer.arrow:SetTexture('Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png')
            layer.arrow:SetSize(12,8); layer.arrow:SetPoint('RIGHT',frame,'RIGHT',-7,0)
        end
        layer.arrow:SetVertexColor(.8,.8,.82); layer.arrow:SetAlpha(1)
    end
    local function FadeArt(frame, save)
        for _, r in ipairs(H.Regions(frame)) do
            if H.Texture(r) and r ~= (layers[frame] and layers[frame].hover)
                and r ~= (layers[frame] and layers[frame].arrow) then
                if save and save[r] == nil then save[r] = r:GetAlpha() end
                r:SetAlpha(0)
            end
        end
    end
    local function Check(frame)
        S.Checkbox(frame, {borderInset=4, hover=.05})
        for i, getter in ipairs({'GetCheckedTexture','GetDisabledCheckedTexture'}) do
            local mark = frame[getter] and H.Texture(frame[getter](frame))
            if mark then
                mark:SetVertexColor(1,1,1,1)
                if i == 1 then mark:SetColorTexture(S.GetAccentColor())
                else mark:SetColorTexture(.4,.4,.4,.8) end
                mark:ClearAllPoints(); mark:SetPoint('TOPLEFT',frame,'TOPLEFT',6,-6)
                mark:SetPoint('BOTTOMRIGHT',frame,'BOTTOMRIGHT',-6,6)
            end
        end
        Text(frame.Text, frame)
    end
    local function NativeControl(frame)
        local state = controls[frame]
        if state and state.generation == generation then return end
        state = state or {}; controls[frame] = state
        local kind = frame:GetObjectType()
        if kind == 'CheckButton' and (frame.configKey or frame.filterMask) then
            Check(frame)
        elseif kind == 'DropdownButton' and frame.configKey then
            if not state.bound then S.Dropdown(frame) end
            Text(frame.Text, frame); Text(frame.Label)
            if not state.bound and ns.BindPopupOwner then ns.BindPopupOwner(S,module,frame) end
        else return end
        if not state.bound then
            state.bound = true
            local function Repaint()
                if not Ready() then return end
                if kind == 'CheckButton' then Check(frame)
                else Text(frame.Text,frame) end
            end
            for _, key in ipairs({'Enable','Disable','SetEnabled'}) do H.Hook(frame,key,Repaint) end
        end
        state.generation = generation
    end
    local function PaintCanvas()
        if not Ready() or not H.Allowed(canvas) then return end
        -- AWQ owns a fixed, flat settings canvas. Never traverse QuestMapFrame
        -- or its dynamically refreshed quest rows/checkboxes.
        local count = canvas:GetNumChildren()
        local state = controls[canvas]
        if state and state.count == count and state.generation == generation then return end
        for _, text in ipairs(H.Regions(canvas)) do Text(text) end
        for _, child in ipairs(H.Children(canvas)) do
            if H.Allowed(child) then NativeControl(child) end
        end
        controls[canvas] = {count=count, generation=generation}
    end
    local function BindCanvas(frame)
        if not H.Allowed(frame) then return end
        canvas = frame
        H.Hook(frame, 'OnRefresh', PaintCanvas)
        H.Script(frame, 'OnShow', PaintCanvas)
        PaintCanvas()
    end
    local function FindCanvas()
        local dropdown = _G.AngrierWorldQuestsConfigDropDown1
        if H.Allowed(dropdown) then BindCanvas(dropdown:GetParent()); return end
        if Settings and Settings.GetCategory and SettingsPanel and SettingsPanel.GetLayout then
            local ok, frame = pcall(function()
                local category = Settings.GetCategory('AngrierWorldQuests')
                local layout = category and SettingsPanel:GetLayout(category)
                return layout and layout.GetFrame and layout:GetFrame()
            end)
            if ok then BindCanvas(frame) end
        end
    end
    local function PaintTab()
        if not Ready() or not H.Allowed(tab) then return end
        -- This LargeSideTabButtonTemplate is a Frame, not a Button. Keep its
        -- trophy Icon and custom mouse-up handler; never use Button-only APIs.
        local state = controls[tab]
        if not state then
            S.Button(tab, {'Icon'}); state = {}; controls[tab] = state
            H.Hook(tab, 'SetChecked', function(_, checked)
                state.checked = checked; PaintTab()
            end)
            H.Script(tab, 'OnShow', PaintTab)
        end
        if H.Texture(tab.SelectedTexture) then tab.SelectedTexture:SetAlpha(0) end
        if H.Texture(tab.Icon) then
            tab.Icon:SetAlpha(1)
            local selected = state.checked
            if selected == nil then selected = QuestMapFrame and QuestMapFrame.displayMode == tab.displayMode end
            if selected then tab.Icon:SetVertexColor(S.GetAccentColor())
            else tab.Icon:SetVertexColor(.75,.75,.77) end
        end
    end
    local function FindTab()
        local quest = TargetModule('QuestFrameModule')
        local mode = quest and quest.awqDisplayMode
        if not mode then return end
        for _, candidate in ipairs(QuestMapFrame and QuestMapFrame.TabButtons or {}) do
            if candidate.displayMode == mode then tab = candidate; PaintTab(); break end
        end
    end
    -- Profiles are pooled AceGUI widgets. Snapshot only cosmetic properties;
    -- release restores them even if the integration has since been disabled.
    local function Restore(widget)
        local state = pooled[widget]
        if not state then return end
        for region, alpha in pairs(state.art) do region:SetAlpha(alpha) end
        for text, value in pairs(state.text) do
            if value.object and text.SetFontObject then text:SetFontObject(value.object) end
            if value.font[1] then text:SetFont(unpack(value.font)) end
            fontGeneration[text] = nil
            text:SetTextColor(unpack(value.color))
        end
        for frame in pairs(state.layers) do
            local layer = layers[frame]
            layer:Hide(); layer.hover:SetAlpha(0)
            if layer.arrow then layer.arrow:SetAlpha(0) end
        end
        pooled[widget] = nil
    end
    PaintWidget = function(widget)
        if type(widget) ~= 'table' or not H.Allowed(widget.frame) then return end
        local state = pooled[widget]
        if not state then
            state = {art={},text={},layers={}}; pooled[widget] = state
        end
        local function Font(text, owner)
            if H.Allowed(text) and text:GetObjectType() == 'FontString' then
                if not state.text[text] then
                    state.text[text] = {font={text:GetFont()},color={text:GetTextColor()},
                        object=text.GetFontObject and text:GetFontObject()}
                end
                Text(text, owner)
            end
        end
        Font(widget.text,widget.frame); Font(widget.label); Font(widget.titletext)
        local function StateChanged()
            if pooled[widget] and Ready() then Text(widget.text,widget.frame) end
        end
        for _, key in ipairs({'Enable','Disable','SetEnabled'}) do H.Hook(widget.frame,key,StateChanged) end
        local frame = widget.type == 'EditBox' and widget.editbox
            or widget.type == 'Dropdown' and widget.dropdown
            or widget.type == 'Button' and widget.frame
        if H.Allowed(frame) then
            FadeArt(frame,state.art); Layer(frame); state.layers[frame] = true
            if widget.type == 'Dropdown' then
                if H.Allowed(widget.button) then FadeArt(widget.button,state.art) end
                Arrow(frame)
                -- Existing arrow button and cover keep their native click paths.
                if ns.BindPopupOwner then ns.BindPopupOwner(S,module,frame) end
            end
            Font(frame.GetFontString and frame:GetFontString(),frame)
        end
        for _, child in ipairs(widget.children or {}) do PaintWidget(child) end
        if widget.type == 'Dropdown' and widget.pullout then
            local pullout = widget.pullout
            local function PaintPullout()
                local current = pooled[widget]
                if not current or not Ready() or not H.Allowed(pullout.frame) then return end
                FadeArt(pullout.frame,current.art); Layer(pullout.frame)
                current.layers[pullout.frame] = true
                for _, item in ipairs(pullout.items or {}) do
                    PaintWidget(item)
                end
            end
            H.Hook(pullout,'Open',PaintPullout)
            if pullout.frame and pullout.frame:IsShown() then PaintPullout() end
        end
    end
    Profiles = function()
        local dialog = Library('AceConfigDialog-3.0')
        if not dialog then return end
        H.Hook(dialog, 'FeedGroup', function(_, id, _, container)
            if id == 'AWQ-Profiles' and Ready() then PaintWidget(container) end
        end)
        local gui = Library('AceGUI-3.0')
        if gui and not groups.release then
            groups.release = true
            hooksecurefunc(gui, 'Release', function(_, widget) Restore(widget) end)
        end
        for _, widget in pairs(dialog.BlizOptions and dialog.BlizOptions['AWQ-Profiles'] or {}) do
            if type(widget) == 'table' and H.Allowed(widget.frame) then
                if not groups[widget] then
                    groups[widget] = true
                    H.Script(widget.frame, 'OnShow', function() if Ready() then PaintWidget(widget) end end)
                end
                if widget.frame:IsShown() then PaintWidget(widget) end
            end
        end
    end
    Refresh = function()
        if not Ready() then return end
        generation = generation + 1
        FindTab(); FindCanvas(); Profiles()
        local config, quest = TargetModule('ConfigModule'), TargetModule('QuestFrameModule')
        H.Hook(config,'OnEnable',function() FindCanvas(); Profiles() end)
        H.Hook(quest,'InitQuestLogTab',FindTab)
        H.Hook(quest,'InitQuestLogFrames',FindTab)
    end
    module.refresh = Refresh
    H.Hook(Settings,'RegisterCanvasLayoutCategory',function(frame,name)
        if name == 'AngrierWorldQuests' then BindCanvas(frame) end
    end)
    H.Hook(SettingsPanel,'DisplayLayout',FindCanvas)
    H.Hook(SettingsPanel,'DisplayCategory',FindCanvas)
    local manager = Menu and Menu.GetManager and Menu.GetManager()
    H.Hook(manager,'OpenMenu',function()
        if not Ready() then return end
        local list = manager.GetOpenMenu and manager:GetOpenMenu()
        local owner = list and list.GetOwnerRegion and list:GetOwnerRegion()
        -- Modern compositor menus are bound as texture-only lists by the
        -- shared helper. Do not SetFont on their restricted virtual rows.
        if owner and owner.configKey and owner.GetParent and owner:GetParent() == canvas
            and ns.BindPopupList then ns.BindPopupList(S,module,owner,list) end
    end)
    if S.OnLooksChanged then S.OnLooksChanged(Refresh) end
    local events = CreateFrame('Frame')
    events:RegisterEvent('ADDON_LOADED'); events:RegisterEvent('PLAYER_REGEN_ENABLED')
    events:SetScript('OnEvent',function() if ns.IsEnabled(module) then H.Queue(module,Refresh) end end)
    Refresh()
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition('AngrierWorldQuests', DefineSkin)
else DefineSkin() end
