local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule('TalentLoadoutManager', 'Talent Loadout Manager', function()
    return type(_G.TalentLoadoutManager) == 'table'
end, function(S, module)
    local app = _G.TalentLoadoutManager
    local soft = ns.CreateSoftSkin(S, module)
    local H = ns.CreateSkinHelper(S, module)
    local unpack = unpack or table.unpack
    local generation, waiting = 1, false
    local sides, dialogs, controls, layers, pooled, groups = {}, {}, {}, {}, {}, {}
    local ownedMenus = setmetatable({}, {__mode='k'})
    local Refresh, Discover, Options, PaintWidget
    local function Library(name) return LibStub and LibStub(name, true) end
    local function Ready()
        if not ns.IsEnabled(module) then return false end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return false end
        return true
    end
    local function Text(text, heading, semantic)
        if not H.Allowed(text) or text:GetObjectType() ~= 'FontString' or not text:GetFont() then return end
        local r,g,b,a = text:GetTextColor()
        local path,flags=S.GetFont()
        local current,_,currentFlags=text:GetFont()
        if current~=path or (currentFlags or '')~=(flags or '') then
            S.Font(text,r,g,b); text:SetTextColor(r,g,b,a)
        end
        if heading then text:SetTextColor(S.GetAccentColor())
        elseif not semantic and r>.8 and g>.6 and b<.3 then text:SetTextColor(.9,.9,.92,a) end
    end
    local function Scroll(bar)
        if not H.Allowed(bar) then return end
        if bar.GetThumbTexture and H.Texture(bar:GetThumbTexture()) then H.LegacySlider(bar)
        else
            S.ScrollBar(bar, true)
            if H.Allowed(bar.Back) then soft.SoftPageButton(bar.Back, '^') end
            if H.Allowed(bar.Forward) then soft.SoftPageButton(bar.Forward, 'v') end
        end
    end
    local function Button(f)
        if not H.Allowed(f) then return end
        if not controls[f] then
            soft.Button(f, {'Text','text'})
            if S.StateButtonLabel then S.StateButtonLabel(f) end
            controls[f] = true
        end
    end
    local function Check(f)
        if not H.Allowed(f) then return end
        if not controls[f] then
            S.Checkbox(f,{borderInset=4,hover=.08}); controls[f]=true
        end
        for i,key in ipairs({'GetCheckedTexture','GetDisabledCheckedTexture'}) do
            local t=f[key] and H.Texture(f[key](f))
            if t then
                t:SetVertexColor(1,1,1,1)
                if i==1 then t:SetColorTexture(S.GetAccentColor()) else t:SetColorTexture(.4,.4,.4,.8) end
                t:ClearAllPoints(); t:SetPoint('CENTER',f,'CENTER'); t:SetSize(8,8)
            end
        end
        Text(f.text or f.Text)
    end
    local function Row(side, row)
        if not Ready() or not H.Allowed(row) then return end
        local state = sides[side]
        if not state then return end
        ownedMenus[row]=true
        local previous = state.rows[row]
        if previous == generation and row.Text and row.Text.GetFont and row.Text:GetFont()==S.GetFont() then return end
        -- Native selection, locks, character colours and custom sidebar colours
        -- remain authoritative. Never replace the row or its action scripts.
        Text(row.Text,false,true)
        state.rows[row] = generation
        if ns.BindPopupOwner then ns.BindPopupOwner(S,module,row) end
    end
    local function Import(side)
        if not Ready() then return end
        local f=side.importDialog
        if not H.Allowed(f) then return end
        local state=dialogs[f]
        if not state then
            state={}; dialogs[f]=state
            H.Shell(f,function() Import(side) end,{noTopBar=true,noAccent=true})
            H.Script(f,'OnShow',function() Import(side) end)
        end
        if state.generation==generation then return end
        Text(f.Title or f.title, true)
        if f.NineSlice then S.FadeNineSlice(f.NineSlice) end
        if f.Border then S.FadeNineSlice(f.Border) end
        local input=f.ImportControl and f.ImportControl.InputContainer
        if H.Allowed(input) then
            soft.EditBox(input)
            if input.NineSlice then S.FadeNineSlice(input.NineSlice) end
            Text(input.Instructions); Scroll(input.ScrollBar)
        end
        local name=f.NameControl
        if name then
            Text(name.Label)
            if H.Allowed(name.EditBox) then soft.EditBox(name.EditBox) end
        end
        Text(f.ImportControl and f.ImportControl.Label)
        Button(f.AcceptButton); Button(f.CancelButton)
        Check(f.AutoApplyCheckbox); Check(f.ImportIntoCurrentLoadoutCheckbox)
        if H.Allowed(f.CloseButton) then S.CloseButton(f.CloseButton) end
        state.generation=generation
    end
    local function Side(side)
        if not Ready() then return end
        local f=side.SideBar
        if not H.Allowed(f) then return end
        local state=sides[side]
        if not state then
            state={rows=setmetatable({}, {__mode='k'})}; sides[side]=state
            -- The native sidebar colour/opacity controls remain functional.
            -- It is not an independent window shell; do not lay an opaque
            -- backdrop underneath its user-configured translucent background.
            H.Script(f,'OnShow',function() Side(side) end)
            H.Hook(side,'OnListElementInitialized',function(_,row) Row(side,row) end)
            H.Hook(side,'SetupHook',function() Side(side); Import(side) end)
        end
        if state.generation~=generation then
            Text(f.Title,true)
            for _,key in ipairs({'CreateButton','ImportButton','SaveButton','ConfigButton'}) do Button(f[key]) end
            local toggle=f.ToggleSideBarButton
            if H.Allowed(toggle) then
                Button(toggle)
                if not state.arrow then
                    for _,key in ipairs({'GetNormalTexture','GetHighlightTexture','GetPushedTexture','GetDisabledTexture'}) do
                        if toggle[key] then H.Fade(toggle[key](toggle)) end
                    end
                    state.arrow=toggle:CreateTexture(nil,'OVERLAY')
                    state.arrow:SetTexture('Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-right.png')
                    state.arrow:SetSize(12,12);state.arrow:SetPoint('CENTER',toggle,'CENTER')
                    local function Direction()
                        if not Ready() then return end
                        local location=side.GetAnchorLocation and side:GetAnchorLocation() or 0
                        local collapsed=side.GetCollapsed and side:GetCollapsed()
                        local right=(not collapsed and (location==0 or location==3)) or (collapsed and (location==1 or location==2))
                        state.arrow:SetRotation(right and 0 or math.pi)
                    end
                    H.Hook(side,'SetCollapsed',Direction);H.Hook(side,'UpdatePointsForAnchorLocation',Direction)
                    state.direction=Direction
                end
                state.direction()
            end
            local container=f.ScrollBoxContainer
            if container then Scroll(container.ScrollBar) end
            state.generation=generation
        end
        local box=f.ScrollBoxContainer and f.ScrollBoxContainer.ScrollBox
        if box and box.EnumerateFrames then for row in box:EnumerateFrames() do Row(side,row) end end
        Import(side)
    end
    -- AceGUI options and static popups are borrowed. Only texture/background
    -- cosmetics and label colours change. Never capture/assign FontObjects or
    -- font faces, and restore before the widget is reused by another addon.
    local function Record(owner)
        local state=pooled[owner]
        if not state then state={art={},colors={},backdrops={},layers={}}; pooled[owner]=state end
        return state
    end
    local function Restore(owner)
        local state=pooled[owner]
        if not state then return end
        for t,a in pairs(state.art) do t:SetAlpha(a) end
        for t,c in pairs(state.colors) do t:SetTextColor(unpack(c)) end
        for f,b in pairs(state.backdrops) do
            f:SetBackdrop(b.value)
            if b.color and f.SetBackdropColor then f:SetBackdropColor(unpack(b.color)) end
            if b.border and f.SetBackdropBorderColor then f:SetBackdropBorderColor(unpack(b.border)) end
        end
        for layer in pairs(state.layers) do layer.active=false;layer:Hide() end
        pooled[owner]=nil
    end
    local function Tint(state,text,disabled)
        if not H.Allowed(text) or text:GetObjectType()~='FontString' then return end
        if not state.colors[text] then state.colors[text]={text:GetTextColor()} end
        if disabled then text:SetTextColor(.5,.5,.52) else text:SetTextColor(.9,.9,.92) end
    end
    local function Surface(state,f,quiet)
        if not H.Allowed(f) then return end
        local layer=layers[f]
        if not layer then
            layer=CreateFrame('Frame',nil,f);layer:SetAllPoints(f);layer:EnableMouse(false)
            layer:SetFrameLevel(math.max(0,f:GetFrameLevel()-1))
            if quiet then S.Shell(layer,{noTopBar=true,noBorder=true})
            else S.Panel(layer,{noBorder=false,inset=false}) end
            if f:GetObjectType()=='Button' then
                layer.hover=layer:CreateTexture(nil,'OVERLAY');layer.hover:SetAllPoints(layer)
                layer.hover:SetColorTexture(1,1,1,.12);layer.hover:SetAlpha(0)
                f:HookScript('OnEnter',function()
                    if layer.active and Ready() and (not f.IsEnabled or f:IsEnabled()) then layer.hover:SetAlpha(1) end
                end)
                f:HookScript('OnLeave',function() layer.hover:SetAlpha(0) end)
                f:HookScript('OnHide',function() layer.hover:SetAlpha(0) end)
            end
            layers[f]=layer
        end
        -- Save only native textures, never the skin's child layer textures.
        for _,t in ipairs(H.Regions(f)) do
            if H.Texture(t) then
                if state.art[t]==nil then state.art[t]=t:GetAlpha() end
                t:SetAlpha(0)
            end
        end
        if f.SetBackdrop and not state.backdrops[f] then
            state.backdrops[f]={value=f:GetBackdrop(),color=f.GetBackdropColor and {f:GetBackdropColor()},
                border=f.GetBackdropBorderColor and {f:GetBackdropBorderColor()}}
        end
        if f.SetBackdrop then f:SetBackdrop(nil) end
        if H.Allowed(f.NineSlice) then
            for _,t in ipairs(H.Regions(f.NineSlice)) do
                if H.Texture(t) then if state.art[t]==nil then state.art[t]=t:GetAlpha() end; t:SetAlpha(0) end
            end
        end
        layer:SetFrameLevel(math.max(0,f:GetFrameLevel()-1));layer.active=true;layer:Show();state.layers[layer]=true
        return layer
    end
    local widgetHooks={}
    PaintWidget=function(widget)
        if not Ready() or type(widget)~='table' or not H.Allowed(widget.frame) then return end
        local state=Record(widget)
        local f=widget.frame
        Tint(state,widget.text,widget.disabled);Tint(state,widget.label);Tint(state,widget.titletext);Tint(state,widget.desc,widget.disabled)
        if widget.type=='Button' then
            Surface(state,f,false);Tint(state,f.GetFontString and f:GetFontString(),widget.disabled)
        elseif widget.type=='CheckBox' and H.Texture(widget.checkbg) and H.Texture(widget.check) then
            -- Preserve native check visibility and label/click geometry.
            local bg,mark=widget.checkbg,widget.check
            if not state.art[bg] then state.art[bg]=bg:GetAlpha() end
            bg:SetAlpha(0)
            local layer=layers[bg]
            if not layer then
                layer=CreateFrame('Frame',nil,f);layer:EnableMouse(false)
                layer:SetPoint('CENTER',bg,'CENTER');layer:SetSize(22,22)
                S.Checkbox(layer,{borderInset=4,hover=.06})
                layer.mark=layer:CreateTexture(nil,'OVERLAY');layer.mark:SetSize(8,8);layer.mark:SetPoint('CENTER')
                layers[bg]=layer
            end
            -- Native mark remains the visibility source, including tri-state.
            if state.art[mark]==nil then state.art[mark]=mark:GetAlpha() end
            mark:SetAlpha(0);layer:Show();state.layers[layer]=true
            layer.mark:SetShown(mark:IsShown())
            if widget.disabled then layer.mark:SetColorTexture(.4,.4,.4,.8)
            else layer.mark:SetColorTexture(S.GetAccentColor()) end
        elseif widget.type=='EditBox' and H.Allowed(widget.editbox) then Surface(state,widget.editbox,false)
        elseif widget.type=='ScrollFrame' and H.Allowed(widget.scrollbar) then
            local bar=widget.scrollbar
            local thumb=bar.GetThumbTexture and bar:GetThumbTexture()
            if H.Texture(thumb) then
                if state.art[thumb]==nil then state.art[thumb]=thumb:GetAlpha() end
                thumb:SetAlpha(0)
                local grip=layers[thumb]
                if not grip then
                    grip=CreateFrame('Frame',nil,bar);grip:EnableMouse(false)
                    grip:SetPoint('TOP',thumb,'TOP');grip:SetPoint('BOTTOM',thumb,'BOTTOM');grip:SetWidth(4)
                    local texture=grip:CreateTexture(nil,'ARTWORK');texture:SetAllPoints(grip);texture:SetColorTexture(1,1,1,.3)
                    layers[thumb]=grip
                end
                grip:Show();state.layers[grip]=true
            end
        elseif widget.type=='Frame' then
            Surface(state,f,true)
            for _,key in ipairs({'titlebg','sizer_se','sizer_s','sizer_e'}) do
                local t=widget[key]
                if H.Texture(t) then if state.art[t]==nil then state.art[t]=t:GetAlpha() end;t:SetAlpha(0) end
            end
            if H.Allowed(widget.closebutton) then
                Surface(state,widget.closebutton,false)
                Tint(state,widget.closebutton.GetFontString and widget.closebutton:GetFontString())
            end
            -- AceGUI's border is a decorative Frame child, not an options
            -- widget. Strip only its backdrop artwork; never add a fill above
            -- the content frame or walk arbitrary grandchildren.
            for _,child in ipairs(H.Children(f)) do
                local backdrop=H.Allowed(child) and child.GetBackdrop and child:GetBackdrop()
                if child~=widget.content and not child.obj and backdrop and backdrop.edgeFile then
                    if not state.backdrops[child] then
                        state.backdrops[child]={value=backdrop,color=child.GetBackdropColor and {child:GetBackdropColor()},
                            border=child.GetBackdropBorderColor and {child:GetBackdropBorderColor()}}
                    end
                    child:SetBackdrop(nil)
                end
            end
        end
        if not widgetHooks[widget] then
            widgetHooks[widget]=true
            for _,key in ipairs({'SetDisabled','SetValue','SetTriState','SetType'}) do
                H.Hook(widget,key,function() if pooled[widget] and Ready() then PaintWidget(widget) end end)
            end
        end
        for _,child in ipairs(widget.children or {}) do PaintWidget(child) end
    end
    Options=function()
        if not Ready() then return end
        local dialog=Library('AceConfigDialog-3.0')
        if not dialog then return end
        H.Hook(dialog,'FeedGroup',function(_,id,_,container)
            if id=='TalentLoadoutManager' then PaintWidget(container) end
        end)
        H.Hook(dialog,'Open',function(_,id) if id=='TalentLoadoutManager' then Options() end end)
        local gui=Library('AceGUI-3.0')
        if gui and not groups.release then
            groups.release=true
            -- Cleanup must run even with the skin disabled.
            hooksecurefunc(gui,'Release',function(_,widget) Restore(widget) end)
        end
        local window=dialog.OpenFrames and dialog.OpenFrames.TalentLoadoutManager
        if window then PaintWidget(window) end
        for _,widget in pairs(dialog.BlizOptions and dialog.BlizOptions.TalentLoadoutManager or {}) do
            if type(widget)=='table' and H.Allowed(widget.frame) then
                if not groups[widget] then
                    groups[widget]=true
                    H.Script(widget.frame,'OnShow',function() PaintWidget(widget) end)
                end
                if widget.frame:IsShown() then PaintWidget(widget) end
            end
        end
    end
    local popupNames={}
    local function Popups()
        if not Ready() then return end
        for i=1,STATICPOPUP_NUMDIALOGS or 4 do
            local f=_G['StaticPopup'..i]
            if H.Allowed(f) then
                -- Always release old cosmetics before inspecting a pooled popup.
                Restore(f)
                if f:IsShown() and popupNames[f.which] then
                    local state=Record(f);Surface(state,f,true)
                    local buttons=f.GetButtons and f:GetButtons() or {f.button1,f.button2,f.button3}
                    for _,button in ipairs(buttons) do if H.Allowed(button) then Surface(state,button,false) end end
                    local edit=f.GetEditBox and f:GetEditBox() or f.editBox
                    if H.Allowed(edit) then Surface(state,edit,false) end
                    if not groups[f] then
                        groups[f]=true
                        f:HookScript('OnHide',function() Restore(f) end)
                        hooksecurefunc(f,'Show',function() Restore(f) end)
                    end
                end
            end
        end
    end
    local function Menus()
        if not Ready() then return end
        local manager=Menu and Menu.GetManager and Menu.GetManager()
        local list=manager and manager.GetOpenMenu and manager:GetOpenMenu()
        local owner=list and list.GetOwnerRegion and list:GetOwnerRegion()
        if ownedMenus[owner] and H.Allowed(list) and ns.BindPopupList then ns.BindPopupList(S,module,owner,list) end
    end
    Discover=function()
        if not Ready() then return end
        for _,side in pairs(app.sideBars or {}) do
            if type(side)=='table' then
                -- Bind before construction as well as after SideBarLoaded.
                H.Hook(side,'SetupHook',function() Side(side);Import(side) end)
                H.Hook(side,'OnListElementInitialized',function(_,row)
                    ownedMenus[row]=true;Row(side,row)
                end)
                for _,key in ipairs({'renameDialogName','createDialogName','deleteDialogName','copyDialogName','genericPopupDialogName','removeFromListDialogName','removeFromListBulkDialogName'}) do
                    if side[key] then popupNames[side[key]]=true end
                end
                Side(side);Import(side)
            end
        end
        Options();Popups()
    end
    Refresh=function()
        if not Ready() then return end
        generation=generation+1;Discover()
    end
    module.refresh=Refresh
    H.Hook(_G,'StaticPopup_Show',Popups)
    local manager=Menu and Menu.GetManager and Menu.GetManager()
    H.Hook(manager,'OpenMenu',Menus)
    if app.RegisterCallback and app.Event and app.Event.SideBarLoaded then
        app:RegisterCallback(app.Event.SideBarLoaded,function() Discover() end,module)
    end
    if S.OnLooksChanged then S.OnLooksChanged(Refresh) end
    local events=CreateFrame('Frame')
    events:RegisterEvent('ADDON_LOADED');events:RegisterEvent('PLAYER_REGEN_ENABLED')
    events:SetScript('OnEvent',function(_,event)
        if event=='PLAYER_REGEN_ENABLED' then if waiting then waiting=false;Refresh() end
        else H.Queue(module,Discover) end
    end)
    Discover()
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition('TalentLoadoutManager',DefineSkin)
else DefineSkin() end
