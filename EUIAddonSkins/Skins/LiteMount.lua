local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule('LiteMount','LiteMount',function() return _G.LiteMountBasePanel ~= nil end,function(S,module)
    local H = ns.CreateSkinHelper(S,module)
    local states,entries,views,initializers = {},{}, {},{}
    local decoration = setmetatable({}, {__mode='k'})
    local shared,menuDescriptions,menus = {},setmetatable({}, {__mode='k'}),setmetatable({}, {__mode='k'})
    local generation = 0
    local Paint,Entry,Prepare,Discover,BindGeneral,MenuReady
    local roots = {'LiteMountBasePanel','LiteMountMountsPanel','LiteMountRulesPanel','LiteMountGroupsPanel',
        'LiteMountMacroPanel','LiteMountFallingPanel','LiteMountAdvancedPanel','LiteMountProfilesPanel',
        'LiteMountReportBugPanel','LiteMountFilter','LiteMountRuleEdit','LiteMountPicker','LiteMountFallingAdd',
        'LiteMountProfileExport','LiteMountProfileImport','LiteMountProfileInspect'}
    local function Ready() return ns.IsEnabled(module) and not (InCombatLockdown and InCombatLockdown()) end
    local function Active(state) return Ready() and (not state.pooled or state.record and state.record.active) end
    local function Remember(record,texture)
        if record and record.alpha[texture] == nil then record.alpha[texture] = texture:GetAlpha() end
    end
    local function Fade(state,texture)
        if not H.Texture(texture) then return end
        Remember(state.record,texture)
        if texture:GetAlpha() ~= 0 then texture:SetAlpha(0) end
    end
    local function Tone(text,owner,record,keep)
        if not H.Allowed(text) or text:GetObjectType() ~= 'FontString' then return end
        if record and not record.fonts[text] then
            record.fonts[text] = {color={text:GetTextColor()}}
        end
        local r,g,b,a = text:GetTextColor()
        local path,flags = S.GetFont()
        local old,_,oldFlags = text:GetFont()
        -- Shared Settings controls keep native font inheritance throughout.
        if not record and(old ~= path or (oldFlags or '') ~= (flags or ''))then H.Font(text) end
        if owner and owner.IsEnabled and not owner:IsEnabled() then r,g,b=.5,.5,.52
        elseif not keep and(owner and owner.GetFontString and owner:GetFontString()==text or r and r>.9 and g>.65 and b<.25)then r,g,b=.9,.9,.92 end
        local cr,cg,cb,ca=text:GetTextColor()
        if cr~=r or cg~=g or cb~=b or ca~=a then text:SetTextColor(r,g,b,a)end
        -- Embedded class/group colours and red/green status text stay native.
    end
    local function Surface(state,kind)
        local f=state.frame
        local layer=state.layer
        if not layer then
            layer=CreateFrame('Frame',nil,f);decoration[layer]=true
            layer:SetAllPoints(f);layer:EnableMouse(false)
            layer:SetFrameLevel(f:GetFrameLevel())
            S.Panel(layer,{noBorder=true,inset=false})
            for _,art in ipairs(H.Regions(layer))do if H.Texture(art)then art:SetAlpha(0)end end
            layer.fill=layer:CreateTexture(nil,'BACKGROUND',nil,1);layer.fill:SetAllPoints(layer)
            state.layer=layer
        end
        layer:Show()
        local r,g,b = S.GetPanelColor()
        local lift = kind=='row' and .025 or kind=='panel' and .015 or kind=='input' and -.015 or .005
        local mountPanel=_G.LiteMountMountsPanel
        local opacity=f.ModelScene and .4 or mountPanel and f==mountPanel.MountsContainer and .45 or .97
        layer.fill:SetColorTexture(math.max(.035,math.min(.2,r+lift)),math.max(.035,math.min(.2,g+lift)),math.max(.035,math.min(.2,b+lift)),opacity)
        if (kind=='input'or kind=='button')and not layer.edges then
            layer.edges={}
            for _,side in ipairs({'TOP','BOTTOM','LEFT','RIGHT'})do
                local t=layer:CreateTexture(nil,'BORDER');t:SetColorTexture(.25,.25,.26,.8)
                if side=='TOP'or side=='BOTTOM'then
                    t:SetPoint(side..'LEFT');t:SetPoint(side..'RIGHT');t:SetHeight(1)
                else t:SetPoint('TOP'..side);t:SetPoint('BOTTOM'..side);t:SetWidth(1)end
                layer.edges[#layer.edges+1]=t
            end
        end
        if (kind=='button'or kind=='row')and not layer.hover then
            layer.hover=layer:CreateTexture(nil,'OVERLAY');layer.hover:SetAllPoints(layer)
            layer.hover:SetColorTexture(1,1,1,.1);layer.hover:SetAlpha(0)
        end
        if state.record then state.record.layers[layer]=true end
        return layer
    end
    local function Art(state)
        if not state.art then
            state.art={}
            for _,r in ipairs(H.Regions(state.frame))do
                if H.Texture(r) and r~=state.frame.Selected and r~=state.frame.SelectedTexture and r~=state.frame.Modified
                    and r~=state.frame.EnabledTexture and r~=state.frame.Icon and r~=state.frame.Error then state.art[#state.art+1]=r end
            end
        end
        for _,r in ipairs(state.art)do Fade(state,r)end
        local nine=state.frame.NineSlice
        if H.Allowed(nine)then
            if state.record then Remember(state.record,nine)end
            nine:SetAlpha(0)
        end
    end
    local function Check(state)
        local f=state.frame
        Art(state)
        local host=state.check
        if not host then
            host=CreateFrame('Frame',nil,f);decoration[host]=true
            host:SetSize(22,22);host:SetPoint('CENTER',f,'CENTER');host:EnableMouse(false)
            S.Checkbox(host,{borderInset=4,hover=.05})
            host.outer=host:CreateTexture(nil,'OVERLAY',nil,0)
            host.outer:SetPoint('TOPLEFT',host,'TOPLEFT',4,-4);host.outer:SetPoint('BOTTOMRIGHT',host,'BOTTOMRIGHT',-4,4)
            host.fill=host:CreateTexture(nil,'OVERLAY',nil,1);host.fill:SetColorTexture(.025,.025,.025,1)
            host.mark=host:CreateTexture(nil,'OVERLAY',nil,2);host.mark:SetSize(8,8);host.mark:SetPoint('CENTER',host,'CENTER')
            state.check=host
        end
        if state.checkGeneration~=generation then
            local px=PixelUtil and PixelUtil.GetNearestPixelSize and PixelUtil.GetNearestPixelSize(1,host:GetEffectiveScale(),1)or 1
            host.fill:ClearAllPoints();host.fill:SetPoint('TOPLEFT',host.outer,'TOPLEFT',px,-px);host.fill:SetPoint('BOTTOMRIGHT',host.outer,'BOTTOMRIGHT',-px,px)
            state.checkGeneration=generation
        end
        if f.Modified and f.Modified:IsShown()then host.outer:SetColorTexture(.55,.18,.18,1)
        else host.outer:SetColorTexture(.27,.27,.28,1)end
        if f.IsEnabled and not f:IsEnabled()then host.mark:SetColorTexture(.4,.4,.42,1)
        elseif f:GetParent()and f:GetParent().Negated==f then host.mark:SetColorTexture(.85,.25,.25,1)
        else host.mark:SetColorTexture(S.GetAccentColor())end
        host.mark:SetShown(f.GetChecked and f:GetChecked()or false);host:Show()
        if state.record then state.record.layers[host]=true end
    end
    local function Glyph(state,direction)
        Art(state)
        local layer=Surface(state,'button')
        if not layer.glyph then
            layer.glyph=layer:CreateTexture(nil,'OVERLAY')
            layer.glyph:SetTexture('Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png')
            layer.glyph:SetSize(10,7);layer.glyph:SetPoint('CENTER',layer,'CENTER')
        end
        layer.glyph:SetRotation(direction=='up'and math.pi or direction=='left'and -math.pi/2 or direction=='right'and math.pi/2 or 0)
        if state.frame.IsEnabled and not state.frame:IsEnabled()then layer.glyph:SetVertexColor(.4,.4,.42,1)
        else layer.glyph:SetVertexColor(.82,.82,.84,1)end
    end
    local function IsTab(f)
        local parent=f.GetParent and f:GetParent()
        for _,tab in ipairs(parent and parent.Tabs or {})do if tab==f then return parent end end
    end
    local function Tab(state,parent)
        Art(state);local layer=Surface(state,'button')
        if not layer.selected then
            layer.selected=layer:CreateTexture(nil,'OVERLAY');layer.selected:SetHeight(2)
            layer.selected:SetPoint('BOTTOMLEFT',layer,'BOTTOMLEFT',1,1);layer.selected:SetPoint('BOTTOMRIGHT',layer,'BOTTOMRIGHT',-1,1)
        end
        local selected=PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(parent)or parent.selectedTab
        local active=selected==(state.frame.GetID and state.frame:GetID())
        layer.selected:SetColorTexture(S.GetAccentColor());layer.selected:SetAlpha(active and 1 or 0)
        local text=state.frame.GetFontString and state.frame:GetFontString()
        if text then if active then text:SetTextColor(S.GetAccentColor())else text:SetTextColor(.9,.9,.92)end end
    end
    local function Owned(owner)
        for _=1,16 do
            if not owner then return false end
            local state=states[owner]
            if state and (not state.pooled or state.record and state.record.active)then return true end
            owner=owner.GetOwnerRegion and owner:GetOwnerRegion()or owner.GetParent and owner:GetParent()
        end
        return false
    end
    local function MenuMarker(row,desc)
        if not Ready()or not desc then return end
        if not(desc.IsRadio and desc:IsRadio()or desc.IsCheckbox and desc:IsCheckbox())then return end
        if row.leftTexture1 then row.leftTexture1:SetColorTexture(.16,.16,.17,1);row.leftTexture1:SetSize(12,12)end
        if row.leftTexture1 and row.leftTexture2 then
            row.leftTexture2:SetColorTexture(S.GetAccentColor());row.leftTexture2:SetSize(7,7)
            row.leftTexture2:ClearAllPoints();row.leftTexture2:SetPoint('CENTER',row.leftTexture1,'CENTER')
        end
    end
    local function MenuOwner(list)
        local owner=list and list.GetOwnerRegion and list:GetOwnerRegion()
        if not owner then
            local manager=Menu and Menu.GetManager and Menu.GetManager()
            local root=manager and manager.GetOpenMenu and manager:GetOpenMenu()
            owner=root and root.GetOwnerRegion and root:GetOwnerRegion()
        end
        return owner
    end
    local function Description(owner,root)
        if not Ready()or not root or not MenuUtil or not MenuUtil.TraverseMenu then return end
        MenuUtil.TraverseMenu(root,function(desc)
            if not desc.AddInitializer or menuDescriptions[desc]then return end
            menuDescriptions[desc]=true
            desc:AddInitializer(function(row,d,list)
                if Ready()and Owned(owner)and MenuOwner(list)==owner then MenuMarker(row,d)end
            end)
        end)
    end
    MenuReady=function(owner,list)
        if not Ready()or not list or not Owned(owner)then return end
        local description=owner.GetMenuDescription and owner:GetMenuDescription()
        local old=menus[list]
        if old and old.owner==owner and old.description==description and old.generation==generation then return end
        menus[list]={owner=owner,description=description,generation=generation}
        H.Script(list,'OnHide',function()menus[list]=nil end)
        if list.EnumerateElementDescriptions then Description(owner,list)end
        if ns.BindPopupList then ns.BindPopupList(S,module,owner,list)end
        if list.GetChildren then for _,row in ipairs(H.Children(list))do
            if row.GetElementDescription then MenuMarker(row,row:GetElementDescription())end
        end end
    end
    local function BindControl(state)
        local f=state.frame
        if state.bound then return end
        state.bound=true
        local function Repair()if Active(state)then H.Safe(Paint,state)end end
        for _,method in ipairs({'Enable','Disable','SetEnabled','SetChecked','UpdateToMenuSelections'})do H.Hook(f,method,Repair)end
        for _,event in ipairs({'OnEnable','OnDisable','OnClick'})do H.Script(f,event,Repair)end
        H.Script(f,'OnEnter',function()
            Repair()
            if Active(state)and state.layer and state.layer.hover and(not f.IsEnabled or f:IsEnabled())then state.layer.hover:SetAlpha(1)end
        end)
        local function Leave()if state.layer and state.layer.hover then state.layer.hover:SetAlpha(0)end end
        H.Script(f,'OnLeave',function()Repair();Leave()end);H.Script(f,'OnHide',Leave)
        H.Hook(f,'SetCollapsedState',function(_,collapsed)
            if not Active(state)or not H.Texture(f.CollapseIcon)then return end
            f.CollapseIcon:SetTexture('Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-right.png')
            f.CollapseIcon:SetSize(10,10);f.CollapseIcon:SetRotation(collapsed and 0 or -math.pi/2)
            if f.CollapseIconAlphaAdd then Fade(state,f.CollapseIconAlphaAdd)end
        end)
        H.Hook(f,'RegisterMenu',function(_,root)
            if not Active(state)then return end
            Description(f,root);Repair();if f.menu then MenuReady(f,f.menu)end
        end)
        H.Hook(f,'OnMenuOpened',function(_,list)MenuReady(f,list)end)
        H.Hook(f,'Generate',function(owner,root)if Active(state)then Description(owner,root)end end)
        if f.GetMenuDescription then Description(f,f:GetMenuDescription())end
        if f.Modified then
            for _,method in ipairs({'Show','Hide','SetShown'})do H.Hook(f.Modified,method,Repair)end
        end
    end
    Paint=function(state)
        if not Active(state)then return end
        local f=state.frame;local kind=f:GetObjectType();local parent=f.GetParent and f:GetParent()
        local tabParent=IsTab(f)
        if kind=='CheckButton'then Check(state)
        elseif state.row then
            if f.SetBackdrop then
                if state.record and not state.record.backdrops[f]then state.record.backdrops[f]={f:GetBackdrop(),f.GetBackdropColor and {f:GetBackdropColor()},f.GetBackdropBorderColor and {f:GetBackdropBorderColor()}}end
                if f:GetBackdrop()then f:SetBackdrop(nil)end
            end
            Surface(state,'row')
        elseif tabParent then
            -- Set the active-tab colour after font normalization below.
        elseif kind=='EditBox'then
            -- Keep macro/rule/profile text, mono fonts, text insets, selection,
            -- validation and OnTextChanged completely native.
            Art(state);if not f.url then Surface(state,'input')end
        elseif kind=='Button'or kind=='DropdownButton'then
            local label=f.GetFontString and f:GetFontString()
            local point=f.GetPoint and f:GetPoint()
            local close=not label and f.GetWidth and f:GetWidth()<=36 and point=='TOPRIGHT'
            if close and not state.pooled then
                if not state.close then S.CloseButton(f);state.close=true end
            elseif parent and(parent.Minus==f or parent.DecrementButton==f) then Glyph(state,'left')
            elseif parent and(parent.Plus==f or parent.IncrementButton==f) then Glyph(state,'right')
            elseif parent and parent.Back==f then Glyph(state,'up')
            elseif parent and parent.Forward==f then Glyph(state,'down')
            elseif label or f.Text or f.SetupMenu or f.GetMenuDescription or f.Generate then
                Art(state);local layer=Surface(state,'button')
                if f.SetupMenu or f.GetMenuDescription or f.Generate then
                    if not layer.arrow then
                        layer.arrow=layer:CreateTexture(nil,'OVERLAY')
                        layer.arrow:SetTexture('Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png')
                        layer.arrow:SetSize(12,8);layer.arrow:SetPoint('RIGHT',layer,'RIGHT',-7,0)
                        layer.arrow:SetVertexColor(.82,.82,.84,1)
                    end
                end
            end
        elseif f.GetBackdrop and f:GetBackdrop()and not f.Background then
            if state.record and not state.record.backdrops[f]then state.record.backdrops[f]={f:GetBackdrop(),f.GetBackdropColor and {f:GetBackdropColor()},f.GetBackdropBorderColor and {f:GetBackdropBorderColor()}}end
            f:SetBackdrop(nil);Surface(state,'panel')
        end
        for _,text in ipairs(state.texts)do Tone(text,f,state.record,state.keepText)end
        if tabParent then Tab(state,tabParent)end
        for _,key in ipairs({'Selected','SelectedTexture'})do
            local selected=H.Texture(f[key])
            if selected then
                if state.record then
                    local rec=state.record
                    rec.colours[selected]=rec.colours[selected]or{selected:GetVertexColor()}
                end
                -- Visibility stays driven by native selected/group state.
                if state.record then selected:SetVertexColor(S.GetAccentColor())
                else local r,g,b=S.GetAccentColor();selected:SetColorTexture(r,g,b,.14)end
            end
        end
    end
    local function Build(root,record,list)
        if not H.Allowed(root)or decoration[root]then return end
        local kind=root:GetObjectType()
        if kind=='ModelScene'or kind=='PlayerModel'or kind=='GameTooltip'then return end
        -- Cast/drag action icons retain their action attributes, scripts,
        -- texture state, desaturation, overlays and complete native hit areas.
        if root.SetMount and root.GetNormalTexture and root.Count then return end
        local state=states[root]
        if not state then
            state={frame=root,texts={}};states[root]=state
            for _,r in ipairs(H.Regions(root))do if r:GetObjectType()=='FontString'then state.texts[#state.texts+1]=r end end
        end
        state.record=record;state.pooled=state.pooled or record~=nil
        state.row=root.mount~=nil and root.Name~=nil or root.rule~=nil or root.Condition~=nil or root.CollapseIcon~=nil
        list[#list+1]=state
        if root.GetView then
            local view=root:GetView()
            if view and view.RegisterCallback and not views[view]then
                views[view]=true
                view:RegisterCallback('OnInitializedFrame',function(_,row)if Ready()then H.Safe(Entry,row)end end,module)
            end
            return
        end
        if not record and root.Track and(root.Back or root.Forward)then
            if not state.scroll then S.ScrollBar(root);state.scroll=true end
        end
        BindControl(state)
        for _,child in ipairs(H.Children(root))do
            if child~=root.NineSlice and child~=root.Disable and not decoration[child]then Build(child,record,list)end
        end
    end
    local function Restore(root)
        local record=shared[root]
        if not record then return end
        record.active=false
        for r,a in pairs(record.alpha)do r:SetAlpha(a)end
        for text,v in pairs(record.fonts)do
            text:SetTextColor(unpack(v.color))
        end
        for f,value in pairs(record.backdrops)do
            f:SetBackdrop(value[1])
            if value[2]and f.SetBackdropColor then f:SetBackdropColor(unpack(value[2]))end
            if value[3]and f.SetBackdropBorderColor then f:SetBackdropBorderColor(unpack(value[3]))end
        end
        for r,c in pairs(record.colours)do r:SetVertexColor(unpack(c))end
        for layer in pairs(record.layers)do layer:Hide();if layer.hover then layer.hover:SetAlpha(0)end end
        shared[root]=nil
    end
    Entry=function(root,record)
        if not Ready()or not H.Allowed(root)then return end
        local entry=entries[root]
        local count=root.GetNumChildren and root:GetNumChildren()or 0
        if not entry or entry.count~=count or record then
            local list={};Build(root,record,list)
            entry={nodes=list,count=root.GetNumChildren and root:GetNumChildren()or count};entries[root]=entry
        end
        for _,state in ipairs(entry.nodes)do Paint(state)end
        entry.count=root.GetNumChildren and root:GetNumChildren()or count
    end
    Prepare=function(root)
        if not Ready()or not H.Allowed(root)then return end
        local state=entries[root]
        local count=root.GetNumChildren and root:GetNumChildren()or 0
        if state and state.generation==generation and state.count==count then return end
        Entry(root);entries[root].generation=generation
    end
    local function SharedEntry(root)
        if not Ready()then return end
        Restore(root)
        local record={active=true,alpha={},fonts={},backdrops={},colours={},layers={}}
        shared[root]=record;Entry(root,record)
    end
    BindGeneral=function()
        local panel=_G.LiteMountGeneralPanel
        local layout=panel and panel.layout
        if not layout or not layout.GetInitializers then return end
        local function Bind(initializer)
            if initializers[initializer]or type(initializer.InitFrame)~='function'then return end
            initializers[initializer]=true
            H.Hook(initializer,'InitFrame',function(_,root)SharedEntry(root)end)
            if type(initializer.Resetter)=='function'then
                -- Cleanup must run even after the integration was disabled.
                hooksecurefunc(initializer,'Resetter',function(_,root)Restore(root)end)
            end
        end
        for _,initializer in pairs(layout:GetInitializers())do Bind(initializer)end
        H.Hook(layout,'AddInitializer',function(_,initializer)Bind(initializer)end)
        H.Hook(panel,'Register',BindGeneral)
        local settings=SettingsPanel
        if settings and settings.GetCurrentLayout and settings:GetCurrentLayout()==layout and settings.GetSettingsList then
            local list=settings:GetSettingsList()
            local view=list and list.ScrollBox and list.ScrollBox.GetView and list.ScrollBox:GetView()
            if view and view.EnumerateFrames then for _,row in view:EnumerateFrames()do
                local initializer=row.GetElementData and row:GetElementData()
                if initializers[initializer]and not shared[row]then SharedEntry(row)end
            end end
        end
    end
    local dialogOwned=setmetatable({}, {__mode='k'})
    local function Dialogs()
        if not ns.StyleTextureDialog then return end
        for i=1,4 do local f=_G['StaticPopup'..i]
            if f then
                local ours=f.which and f.which:match('^LM_OPTIONS_')
                if ours or dialogOwned[f]then
                    ns.StyleTextureDialog(S,module,f,Ready()and ours and f:IsShown()and true or false)
                    dialogOwned[f]=ours and true or nil
                end
            end
        end
    end
    Discover=function()
        if not Ready()then return end
        BindGeneral()
        for _,name in ipairs(roots)do
            local f=_G[name]
            if H.Allowed(f)then
                H.Script(f,'OnShow',function()Prepare(f)end)
                H.Hook(f,'RefreshDisplay',function()Prepare(f)end)
                H.Hook(f,'SetTab',function()
                    for _,tab in ipairs(f.Tabs or {})do local state=states[tab];if state then Paint(state)end end
                end)
                Prepare(f)
                if f.viewsByTabs then
                    for _,view in pairs(f.viewsByTabs)do
                        if view.RegisterCallback and not views[view]then
                            views[view]=true;view:RegisterCallback('OnInitializedFrame',function(_,row)if Ready()then H.Safe(Entry,row)end end,module)
                        end
                    end
                end
                -- Only realised entries, never a mount/data provider/database.
                local entry=entries[f]
                if entry then for _,node in ipairs(entry.nodes)do
                    local box=node.frame
                    if box.GetView then local view=box:GetView()
                        if view and view.EnumerateFrames then for _,row in view:EnumerateFrames()do Entry(row)end end
                    end
                end end
            end
        end
        local manager=Menu and Menu.GetManager and Menu.GetManager()
        local function MenuOpened()
            local list=manager.GetOpenMenu and manager:GetOpenMenu()
            MenuReady(list and list.GetOwnerRegion and list:GetOwnerRegion(),list)
        end
        H.Hook(manager,'OpenMenu',MenuOpened);H.Hook(manager,'OpenContextMenu',MenuOpened)
    end
    module.refresh=function()
        if not Ready()then return end
        generation=generation+1;Discover()
        for root,record in pairs(shared)do if record.active then Entry(root,record)end end
    end
    H.Hook(_G,'StaticPopup_Show',Dialogs)
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh)end
    local events=CreateFrame('Frame');events:RegisterEvent('ADDON_LOADED');events:RegisterEvent('PLAYER_REGEN_ENABLED');events:RegisterEvent('UI_SCALE_CHANGED')
    events:SetScript('OnEvent',function(_,event)
        if not ns.IsEnabled(module)then return end
        if event=='ADDON_LOADED'then H.Queue(module,Discover)else H.Queue(module,module.refresh)end
    end)
    Discover()
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition('LiteMount',DefineSkin)else DefineSkin()end
