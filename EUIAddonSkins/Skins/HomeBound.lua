local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule('HomeBound','Home Bound',function() return _G.HB_MainFrame ~= nil end,function(S,module)
    local H=ns.CreateSkinHelper(S,module)
    local soft=ns.CreateSoftSkin(S,module)
    local generation,waiting,painting=1,false,false
    local nodes,art,roots,lists,dirty={}, {}, {}, {}, {}
    local flushKey={}
    local Walk,Discover,Flush,MenuReady
    local windows={'HB_MainFrame','HB_VendorPopup','HB_WowheadLinkFrame','HB_RewardFrame',
        'HB_SmallPreviewFrame','HB_SupportFrame','HB_UploadFrame','HB_NoteTooltip','HB_CostTooltip'}
    local function Ready()
        if not ns.IsEnabled(module) then return false end
        if InCombatLockdown and InCombatLockdown() then waiting=true;return false end
        return true
    end
    local function State(f)
        if not nodes[f] then nodes[f]={} end
        return nodes[f]
    end
    local function Text(text,neutral)
        if not H.Allowed(text) or text:GetObjectType()~='FontString' or not text.GetFont then return end
        local face,_,flags=text:GetFont();if not face then return end
        local path,style=S.GetFont()
        local r,g,b,a=text:GetTextColor()
        if face~=path or (flags or '')~=(style or '') then S.Font(text,r,g,b);text:SetTextColor(r,g,b,a) end
        -- Only nonsemantic control labels lose the native yellow. Collection,
        -- buildability, rarity and missing-material colours remain native.
        if neutral and r>.8 and g>.6 and b<.3 then text:SetTextColor(.9,.9,.92,a) end
    end
    local function Backdrop(f)
        if f.SetBackdrop then f:SetBackdrop(nil) end
    end
    local function Fill(f,lift)
        local d=State(f)
        if not d.fill then
            d.fill=f:CreateTexture(nil,'BACKGROUND',nil,-7);art[d.fill]=true;d.fill:SetAllPoints(f)
        end
        local r,g,b=S.GetPanelColor();local offset=lift or 0
        d.fill:SetColorTexture(math.min(1,r+offset),math.min(1,g+offset),math.min(1,b+offset),.96)
        Backdrop(f)
    end
    local function Selection(f,selected)
        local d=State(f);d.selected=selected
        if not d.edge then
            d.edge=f:CreateTexture(nil,'OVERLAY');art[d.edge]=true
            d.edge:SetPoint('BOTTOMLEFT',f,'BOTTOMLEFT',1,1)
            d.edge:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',-1,1);d.edge:SetHeight(2)
        end
        if selected then d.edge:SetColorTexture(S.GetAccentColor())
        else d.edge:SetColorTexture(.22,.22,.24,.6) end
        for _,text in ipairs(H.Regions(f)) do
            if text.GetObjectType and text:GetObjectType()=='FontString' then
                Text(text,not (f.bp and text==f.score))
                if f.id then
                    if selected then text:SetTextColor(S.GetAccentColor()) else text:SetTextColor(.85,.85,.87) end
                end
            end
        end
    end
    local function SelectionHook(f)
        local d=State(f)
        if d.selectionBound then return end
        d.selectionBound=true
        if f.GetBackdropBorderColor then
            local r,g,b=f:GetBackdropBorderColor()
            d.selected=r>.9 and g>.6 and b<.25
        end
        H.Hook(f,'SetBackdropBorderColor',function(_,r,g,b)
            if Ready() then Selection(f,r>.9 and g>.6 and b<.25) end
        end)
    end
    local function Shell(f)
        local d=State(f)
        if d.shell then return end
        d.shell=true
        local keep={}
        for _,t in ipairs(H.Regions(f)) do
            if H.Texture(t) and t.GetDrawLayer and t:GetDrawLayer()~='BACKGROUND' and t:GetDrawLayer()~='BORDER' then keep[t]=t:GetAlpha() end
        end
        S.Shell(f,{noTopBar=true,noBorder=true})
        for t,a in pairs(keep) do t:SetAlpha(a) end
        Backdrop(f)
    end
    local function Scroll(bar)
        if not H.Allowed(bar) then return end
        if bar.GetThumbTexture and H.Texture(bar:GetThumbTexture()) then H.LegacySlider(bar)
        else
            S.ScrollBar(bar,true)
            if H.Allowed(bar.Back) then soft.SoftPageButton(bar.Back,'^') end
            if H.Allowed(bar.Forward) then soft.SoftPageButton(bar.Forward,'v') end
        end
    end
    local function Check(f)
        local d=State(f)
        if not d.check then S.Checkbox(f,{borderInset=4,hover=.08});d.check=true end
        for i,key in ipairs({'GetCheckedTexture','GetDisabledCheckedTexture'}) do
            local t=f[key] and H.Texture(f[key](f))
            if t then
                t:SetVertexColor(1,1,1,1)
                if i==1 then t:SetColorTexture(S.GetAccentColor()) else t:SetColorTexture(.4,.4,.4,.8) end
                t:ClearAllPoints();t:SetPoint('CENTER',f,'CENTER');t:SetSize(8,8)
            end
        end
        local label=f.Text or f.text
        Text(label,true)
        if H.Allowed(label) then
            if f.IsEnabled and not f:IsEnabled() then label:SetTextColor(.5,.5,.52)
            else label:SetTextColor(.9,.9,.92) end
        end
    end
    local function Dropdown(f)
        local d=State(f)
        if not d.dropdown then
            d.dropdown=true
            soft.Dropdown(f)
            if f.EnableRegenerateOnResponse then f:EnableRegenerateOnResponse() end
            if ns.BindPopupOwner then ns.BindPopupOwner(S,module,f) end
            H.Hook(f,'OnMenuOpened',function(_,list) MenuReady(list) end)
        end
    end
    local function Arrow(f,texture)
        local path=texture and texture.GetTexture and texture:GetTexture()
        if type(path)~='string' then return false end
        path=path:lower()
        local glyph=path:find('prevpage',1,true) and '<' or path:find('nextpage',1,true) and '>'
        if glyph then soft.SoftPageButton(f,glyph);return true end
        return false
    end
    local function Paint(f)
        local d,kind=State(f),f:GetObjectType()
        if d.generation==generation then return end
        local name=f.GetName and f:GetName() or ''
        local neutral=not(f.isLine or f.isHeader or f.qtyText or f.bp or f.borderFrame)
        if roots[f]=='shell' then Shell(f)
        elseif f.id and name:match('^HB_Tab_') then
            SelectionHook(f);Fill(f,.04);Selection(f,d.selected)
        elseif f.bp and H.Texture(f.thumb) and f.title then
            SelectionHook(f);Fill(f,.055);Selection(f,d.selected)
        elseif kind=='Frame' then
            local parent=f.GetParent and f:GetParent()
            if parent==_G.HB_BlueprintsFrame and f.GetBackdrop and f:GetBackdrop() then Fill(f,.02)
            else
                -- Anonymous raised frames include item-quality borders and
                -- preview overlays. Never add a background to these frames.
                local backdrop=f.GetBackdrop and f:GetBackdrop()
                if backdrop and backdrop.edgeFile and not f.btn and not (parent and parent.borderFrame==f) then
                    local r,g,b,a=f:GetBackdropColor()
                    local copy={};for k,v in pairs(backdrop) do if k~='edgeFile' and k~='edgeSize' then copy[k]=v end end
                    f:SetBackdrop(copy);f:SetBackdropColor(r,g,b,a)
                end
            end
        end
        if H.Allowed(f.NineSlice) and (roots[f] or kind=='EditBox') then S.FadeNineSlice(f.NineSlice) end
        if H.Allowed(f.ScrollBar) then Scroll(f.ScrollBar) end
        if kind=='ScrollFrame' and f.GetScrollChild then
            local child=f:GetScrollChild()
            if H.Allowed(child) then
                lists[child]=true
                H.Hook(child,'SetHeight',function()
                    if not Ready() then return end
                    dirty[child]=true
                    -- SetHeight is the completed manifest/gallery/list boundary.
                    -- Repaint only this list, never all addon windows.
                    if not painting then Flush() end
                end)
            end
        end
        if kind=='EditBox' then
            soft.EditBox(f);Text(f.Instructions,true)
            -- Keep search text, focus, input padding and import codes native.
        elseif kind=='CheckButton' then
            Check(f)
            for _,method in ipairs({'SetChecked','Enable','Disable','SetEnabled'}) do H.Hook(f,method,function() if Ready() then Check(f) end end) end
        elseif type(f.SetupMenu)=='function' then Dropdown(f)
        elseif kind=='Slider' then
            if H.Texture(f.GetThumbTexture and f:GetThumbTexture()) then H.LegacySlider(f) end
            if H.Allowed(f.Slider) then H.LegacySlider(f.Slider) end
            if H.Allowed(f.Back) then soft.SoftPageButton(f.Back,'<') end
            if H.Allowed(f.Forward) then soft.SoftPageButton(f.Forward,'>') end
        elseif kind=='Button' and not f.isLine and not f.isHeader and not f.qtyText and not f.bp then
            local normal=f.GetNormalTexture and H.Texture(f:GetNormalTexture())
            local label=f.GetFontString and f:GetFontString() or f.Text
            local close=false
            if normal then
                local path=normal:GetTexture()
                close=type(path)=='string' and path:lower():find('close',1,true)
            end
            if not close and f.GetPoint and f:GetWidth()<=36 and f:GetHeight()<=36 then
                local point,_,relativePoint,x,y=f:GetPoint(1)
                local parent=f.GetParent and f:GetParent()
                close=roots[parent]=='shell' and point=='TOPRIGHT' and (not relativePoint or relativePoint=='TOPRIGHT')
                    and x and y and math.abs(x)<=8 and math.abs(y)<=8
            end
            if close then S.CloseButton(f)
            elseif not Arrow(f,normal) then
                if not H.Allowed(label) then
                    for _,r in ipairs(H.Regions(f)) do
                        if r.GetObjectType and r:GetObjectType()=='FontString' and r.GetText and r:GetText()~='' then label=r;break end
                    end
                end
                if H.Allowed(label) and f:GetHeight()<=40 and f:GetWidth()<=260 then
                    soft.Button(f,{'Text','text'})
                    if S.StateButtonLabel and f.GetFontString and f:GetFontString() then S.StateButtonLabel(f) end
                end
            end
        end
        for _,t in ipairs(H.Regions(f)) do Text(t,neutral) end
        if f.isLine then
            local t=f.GetHighlightTexture and H.Texture(f:GetHighlightTexture())
            if t then t:SetColorTexture(1,1,1,.1) end
        end
        d.generation=generation
    end
    local function Excluded(f)
        local kind=f:GetObjectType()
        return kind=='PlayerModel' or kind=='ModelScene' or kind=='GameTooltip' or kind=='Texture'
            or kind=='Line' or kind=='FontString'
    end
    Walk=function(f,deep)
        if not H.Allowed(f) or art[f] or Excluded(f) then return end
        local d=State(f)
        local n=f.GetNumChildren and f:GetNumChildren() or -1
        local nr=f.GetNumRegions and f:GetNumRegions() or -1
        Paint(f)
        if not d.bound then
            d.bound=true
            H.Script(f,'OnShow',function()
                if Ready() then dirty[f]=true;H.Queue(flushKey,Flush) end
            end)
            -- Click callbacks run after native tab/card selection, so newly
            -- constructed detail controls can be styled in the same UI turn.
            if f:GetObjectType()=='Button' and not f.isLine and not f.qtyText and not f.isHeader then
                H.Script(f,'OnClick',function()
                    if not Ready() then return end
                    dirty[f]=true
                    if f.bp then
                        local blueprint=_G.HB_BlueprintsFrame
                        if blueprint then for _,panel in ipairs(H.Children(blueprint)) do if panel~=f:GetParent() then dirty[panel]=true end end end
                    end
                    Flush()
                end)
            end
        end
        if not deep and d.children==n and d.regions==nr and d.walkGeneration==generation then return end
        for _,child in ipairs(H.Children(f)) do Walk(child,false) end
        -- Native first-show callbacks may append FontStrings after construction.
        for _,text in ipairs(H.Regions(f)) do Text(text,not(f.isLine or f.isHeader or f.qtyText or f.bp)) end
        d.children=f.GetNumChildren and f:GetNumChildren() or n
        d.regions=f.GetNumRegions and f:GetNumRegions() or nr
        d.walkGeneration=generation
    end
    Flush=function()
        if not Ready() or painting then return end
        painting=true
        local pending=dirty;dirty={}
        for f in pairs(pending) do Walk(f,false) end
        painting=false
    end
    local function Bind(f,mode)
        if not H.Allowed(f) then return end
        if mode then roots[f]=mode end
        Walk(f,false)
    end
    local menuDescriptions=setmetatable({}, {__mode='k'})
    local function Marker(row,description)
        if not Ready() or not row or not description then return end
        local selected=description.IsCheckbox and description:IsCheckbox() or description.IsRadio and description:IsRadio()
        if selected and row.leftTexture1 then
            row.leftTexture1:SetColorTexture(.18,.18,.2,1)
            if row.leftTexture2 then row.leftTexture2:SetColorTexture(S.GetAccentColor()) end
        end
    end
    MenuReady=function(list)
        if not Ready() then return end
        local manager=Menu and Menu.GetManager and Menu.GetManager()
        list=list or manager and manager.GetOpenMenu and manager:GetOpenMenu()
        local owner=list and list.GetOwnerRegion and list:GetOwnerRegion()
        -- Owner chains on submenus eventually resolve to the filter button.
        local parent=owner;local own=false
        for _=1,10 do
            if parent==_G.HB_FilterButton then own=true;break end
            parent=parent and (parent.GetOwnerRegion and parent:GetOwnerRegion() or parent.GetParent and parent:GetParent())
        end
        if not own or not H.Allowed(list) then return end
        if ns.BindPopupList then ns.BindPopupList(S,module,owner,list) end
        if list.EnumerateElementDescriptions then list:EnumerateElementDescriptions(function(_,description)
            if description.AddInitializer and not menuDescriptions[description] then
                menuDescriptions[description]=true
                description:AddInitializer(function(row,desc,menu)
                    if menu==list and list:IsShown() and list:GetOwnerRegion()==owner then Marker(row,desc) end
                end)
            end
        end) end
        for _,row in ipairs(H.Children(list)) do if row.GetElementDescription then Marker(row,row:GetElementDescription()) end end
    end
    Discover=function()
        if not Ready() then return end
        for _,name in ipairs(windows) do Bind(_G[name],'shell') end
        Bind(_G.HB_ConfigFrame,'controls');Bind(_G.HB_BlueprintsFrame,'controls')
        -- Fullscreen image/dimmer, hero thumbnails, models and item quality
        -- frames keep native textures and geometry. Only their controls change.
        Bind(_G.HB_BlueprintFullscreenFrame,'controls')
        MenuReady()
    end
    module.refresh=function()
        if not Ready() then return end
        generation=generation+1;Discover()
    end
    -- BuildUI is HomeBound's only exported completed list builder. Its hook
    -- does not calculate collection state, query item APIs or change results.
    H.Hook(_G,'BuildUI',function()
        if not Ready() then return end
        local main=_G.HB_MainFrame
        if H.Allowed(main) then Walk(main,false) end
        Flush()
    end)
    local manager=Menu and Menu.GetManager and Menu.GetManager()
    H.Hook(manager,'OpenMenu',function()MenuReady()end)
    H.Hook(Settings,'RegisterCanvasLayoutCategory',function(frame,name)
        if name=='Home Bound' then Bind(frame,'controls') end
    end)
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
    local events=CreateFrame('Frame');events:RegisterEvent('ADDON_LOADED');events:RegisterEvent('PLAYER_ENTERING_WORLD');events:RegisterEvent('PLAYER_REGEN_ENABLED')
    events:SetScript('OnEvent',function(_,event,name)
        if event=='PLAYER_REGEN_ENABLED' then if waiting then waiting=false;module.refresh() end
        elseif event=='PLAYER_ENTERING_WORLD' or name=='HomeBound' or name=='HomeBound_Blueprints' then
            H.Queue(module,Discover)
        end
    end)
    Discover()
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition('HomeBound',DefineSkin)
else DefineSkin() end
