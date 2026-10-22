local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule('CraftSim', 'CraftSim', function()
    return _G.CraftSimAPI and type(CraftSimAPI.GetCraftSim) == 'function'
end, function(S, module)
    local CS = CraftSimAPI:GetCraftSim()
    if type(CS) ~= 'table' then return end
    local H = ns.CreateSkinHelper(S, module)
    local soft = ns.CreateSoftSkin(S, module)
    local owned, roots, records, kinds, widgets, art = {}, {}, {}, {}, {}, {}
    local shared, initializers, classHooks = {}, {}, {}
    local generation, waiting, applying = 1, false, false
    local Paint, Walk, Discover, Bind, BindSettings, PaintWidget, MenuList
    local events = CreateFrame('Frame')
    events:RegisterEvent('ADDON_LOADED'); events:RegisterEvent('PLAYER_REGEN_ENABLED')
    local function Ready()
        if not ns.IsEnabled(module) then return false end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return false end
        return true
    end
    local function Raw(value)
        if type(value) ~= 'table' and type(value) ~= 'userdata' then return end
        if H.Allowed(value) then return value end
        return H.Allowed(value.frame) and value.frame or H.Allowed(value.scrollFrame) and value.scrollFrame
    end
    local function Own(f)
        for _ = 1, 32 do
            if not H.Allowed(f) then return false end
            if owned[f] then return true end
            f = f.GetParent and f:GetParent()
        end
        return false
    end
    local function State(f)
        local d = records[f]
        if not d then d = {}; records[f] = d end
        return d
    end
    local function Font(text, action)
        if not H.Allowed(text) or not text.GetFont then return end
        local path, _, flags = text:GetFont()
        if not path then return end
        local r, g, b, a = text:GetTextColor()
        local face, style = S.GetFont()
        if path ~= face or (flags or '') ~= (style or '') then
            S.Font(text); text:SetTextColor(r, g, b, a)
        end
        -- Only ordinary gold labels become neutral. Embedded profit/loss,
        -- class and item-quality colours, and native warning colours, survive.
        if action then text:SetTextColor(action:IsEnabled() and .92 or .5, action:IsEnabled() and .92 or .5, action:IsEnabled() and .94 or .52, 1)
        elseif r > .9 and g > .65 and b < .25 then text:SetTextColor(.88, .88, .9, a) end
    end
    local function Fade(f)
        if not H.Allowed(f) then return end
        for _, t in ipairs(H.Regions(f)) do if H.Texture(t) and not art[t] then t:SetAlpha(0) end end
    end
    local function Fill(f, input)
        local d = State(f)
        if not d.fill then
            d.fill = f:CreateTexture(nil, 'BACKGROUND', nil, -5)
            art[d.fill] = true; d.fill:SetAllPoints(f)
        end
        local r, g, b = S.GetPanelColor()
        d.fill:SetColorTexture(math.max(.025, r + (input and -.02 or .015)), math.max(.025, g + (input and -.02 or .015)), math.max(.025, b + (input and -.02 or .015)), .97)
        d.fill:SetAlpha(1)
        return d
    end
    local function Lift(f)
        local d = State(f)
        if not d.lift then
            d.lift = {}
            for i = 1, 2 do
                local t = f:CreateTexture(nil, 'BACKGROUND', nil, -4)
                art[t] = true; d.lift[i] = t
                if i == 1 then t:SetPoint('TOPLEFT'); t:SetPoint('BOTTOMRIGHT', f, 'BOTTOM')
                else t:SetPoint('TOPLEFT', f, 'TOP'); t:SetPoint('BOTTOMRIGHT') end
            end
            d.shades={}
            for i=1,2 do
                local t=f:CreateTexture(nil,'BACKGROUND',nil,-3);art[t]=true;d.shades[i]=t
                if i==1 then t:SetPoint('TOPLEFT');t:SetPoint('BOTTOMRIGHT',f,'RIGHT')
                else t:SetPoint('TOPLEFT',f,'LEFT');t:SetPoint('BOTTOMRIGHT')end
            end
        end
        local r, g, b = S.GetPanelColor()
        for i, t in ipairs(d.lift) do
            local a, z = i == 1 and 0 or .28, i == 1 and .28 or 0
            t:SetColorTexture(1, 1, 1, 1)
            if t.SetGradient and CreateColor then
                t:SetGradient('HORIZONTAL', CreateColor(r + .13, g + .13, b + .13, a), CreateColor(r + .13, g + .13, b + .13, z))
            elseif t.SetGradientAlpha then t:SetGradientAlpha('HORIZONTAL', r + .13, g + .13, b + .13, a, r + .13, g + .13, b + .13, z)
            else t:SetColorTexture(r + .06, g + .06, b + .06, .12) end
        end
        for i,t in ipairs(d.shades)do
            local a,z=i==1 and 0 or .12,i==1 and .12 or 0
            t:SetColorTexture(0,0,0,.06)
            if t.SetGradient and CreateColor then t:SetGradient('VERTICAL',CreateColor(0,0,0,a),CreateColor(0,0,0,z))
            elseif t.SetGradientAlpha then t:SetGradientAlpha('VERTICAL',0,0,0,a,0,0,0,z)end
        end
    end
    local function Edges(f)
        local d = State(f)
        if d.edges then return end
        d.edges = {}
        for _, side in ipairs({'TOP','BOTTOM','LEFT','RIGHT'}) do
            local t = f:CreateTexture(nil, 'BORDER'); art[t] = true
            t:SetColorTexture(.25, .25, .26, .7)
            if side == 'TOP' or side == 'BOTTOM' then
                t:SetPoint(side .. 'LEFT'); t:SetPoint(side .. 'RIGHT'); t:SetHeight(1)
            else t:SetPoint('TOP' .. side); t:SetPoint('BOTTOM' .. side); t:SetWidth(1) end
            d.edges[#d.edges + 1] = t
        end
    end
    local function Check(f)
        local d = State(f)
        if not d.check then
            local host = CreateFrame('Frame', nil, f); art[host] = true
            host:SetSize(14,14); host:SetPoint('CENTER', f, 'CENTER'); host:EnableMouse(false)
            host.outer = host:CreateTexture(nil, 'BACKGROUND'); host.outer:SetAllPoints(host)
            host.outer:SetColorTexture(.25,.25,.26,1)
            host.fill = host:CreateTexture(nil, 'BORDER')
            host.fill:SetPoint('TOPLEFT',host,'TOPLEFT',1,-1); host.fill:SetPoint('BOTTOMRIGHT',host,'BOTTOMRIGHT',-1,1)
            host.fill:SetColorTexture(.025,.025,.03,1)
            host.mark = host:CreateTexture(nil, 'ARTWORK'); host.mark:SetSize(8,8); host.mark:SetPoint('CENTER',host,'CENTER')
            d.check = host
        end
        Fade(f)
        d.check:Show()
        if f.IsEnabled and not f:IsEnabled() then d.check.mark:SetColorTexture(.4,.4,.42,1)
        else d.check.mark:SetColorTexture(S.GetAccentColor()) end
        d.check.mark:SetShown(f.GetChecked and f:GetChecked() or false)
    end
    local function Slider(f)
        local d = State(f)
        local thumb = f.GetThumbTexture and H.Texture(f:GetThumbTexture())
        if thumb then
            Fade(f)
            if not d.grip then
                d.track = f:CreateTexture(nil,'BACKGROUND'); art[d.track] = true
                d.grip = f:CreateTexture(nil,'ARTWORK'); art[d.grip] = true
                d.grip:SetPoint('CENTER',thumb,'CENTER')
                if f.GetOrientation and f:GetOrientation() == 'HORIZONTAL' then
                    d.track:SetPoint('LEFT');d.track:SetPoint('RIGHT');d.track:SetHeight(2);d.grip:SetSize(8,14)
                else
                    d.track:SetPoint('TOP');d.track:SetPoint('BOTTOM');d.track:SetWidth(2)
                    d.grip:SetPoint('TOP',thumb,'TOP');d.grip:SetPoint('BOTTOM',thumb,'BOTTOM');d.grip:SetWidth(5)
                end
            end
            d.track:SetColorTexture(.2,.2,.21,1);d.grip:SetColorTexture(S.GetAccentColor())
        elseif f.Track and H.Allowed(f.Track.Thumb) then
            local host = f.Track.Thumb
            Fade(host)
            if not d.grip then
                d.grip=host:CreateTexture(nil,'ARTWORK');art[d.grip]=true
                d.grip:SetPoint('TOP');d.grip:SetPoint('BOTTOM');d.grip:SetWidth(5)
            end
            d.grip:SetColorTexture(S.GetAccentColor())
        end
    end
    local function Glyph(f, direction)
        if not H.Allowed(f) then return end
        Fade(f)
        local d=State(f)
        if not d.glyph then
            d.glyph=f:CreateTexture(nil,'OVERLAY');art[d.glyph]=true
            d.glyph:SetTexture('Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png')
            d.glyph:SetPoint('CENTER',f,'CENTER');d.glyph:SetSize(10,10)
        end
        d.glyph:SetRotation(direction=='left'and -math.pi/2 or direction=='right'and math.pi/2 or direction=='up'and math.pi or 0)
        d.glyph:SetVertexColor(.82,.82,.84,1);d.glyph:SetAlpha(1)
    end
    local function LocalPaint(f)
        if not Ready() then return end
        local r = shared[f]
        if r and not r.active then return end
        local d=State(f)
        if d.painting then return end
        d.painting=true;H.Safe(Paint,f);d.painting=false
        if r and f:GetObjectType()=='DropdownButton'and MenuList then
            local manager=Menu and Menu.GetManager and Menu.GetManager()
            local list=manager and manager.GetOpenMenu and manager:GetOpenMenu()
            if list and list.GetOwnerRegion and list:GetOwnerRegion()==f then MenuList(list)end
        end
    end
    Paint = function(f)
        if not H.Allowed(f) or art[f] then return end
        local d, kind = State(f), f:GetObjectType()
        if kind == 'Texture' or kind == 'Line' then return end
        if kind == 'FontString' then Font(f); return end
        local role = kinds[f]
        if not role and kind=='Frame'and f.GetBackdrop then
            local backdrop=f:GetBackdrop()
            if backdrop and backdrop.edgeFile then role='panel';kinds[f]=role end
        end
        if role == 'graph' or kind == 'GameTooltip' or kind == 'ModelScene' or kind == 'PlayerModel' then return end
        if role == 'icon' then
            local t = f.GetNormalTexture and H.Texture(f:GetNormalTexture())
            if t then S.SquareIcon(t) end
            if not d.iconHook then
                d.iconHook=true
                H.Hook(f,'SetNormalTexture',function()if Ready()then Paint(f)end end)
            end
            return
        end
        if role == 'window' then
            if not d.shell then S.Shell(f, {noTopBar=true,noBorder=true}); d.shell=true end
            if f.SetBackdrop then f:SetBackdrop(nil) end
            Lift(f)
        elseif role == 'panel' then
            if f.SetBackdrop then f:SetBackdrop(nil) end
            Fade(f); Fill(f)
        elseif role == 'tab' then
            if not d.tab then S.Tab(f);d.tab=true end
        elseif role == 'close' then
            if not d.close then S.CloseButton(f);d.close=true end
        elseif role == 'collapse' then
            Fade(f)
            if not d.minus then
                d.minus=f:CreateTexture(nil,'OVERLAY');art[d.minus]=true
                d.minus:SetSize(9,2);d.minus:SetPoint('CENTER',f,'CENTER')
            end
            d.minus:SetColorTexture(.85,.85,.87,1)
        elseif kind == 'CheckButton' then Check(f)
        elseif kind == 'Slider' or f.Track and f.Track.Thumb then Slider(f)
        elseif kind == 'EditBox' then
            Fade(f);Fill(f,true);Edges(f);Font(f)
        elseif role ~= 'row' and (kind == 'DropdownButton' or type(f.initialize) == 'function') then
            local r=shared[f]
            if not r then S.Dropdown(f) else Fade(f);Fill(f);Edges(f);Glyph(f,'down') end
            if ns.BindPopupOwner and not r then ns.BindPopupOwner(S,module,f) end
        elseif role ~= 'row' and kind == 'Button' and f.GetFontString and H.Allowed(f:GetFontString())
            and f:GetFontString().GetText and f:GetFontString():GetText() and f:GetFontString():GetText()~='' then
            if not d.button then
                -- Shared Settings controls get only local cosmetic art, never
                -- a permanent registration of a pooled native frame with EUI.
                if shared[f] then Fill(f);Edges(f)
                else soft.Button(f);d.button=true end
            end
            Font(f:GetFontString(), f)
        end
        for key,direction in pairs({Back='left',Forward='right',DecrementButton='left',IncrementButton='right',ScrollUpButton='up',ScrollDownButton='down'})do
            local button=Raw(f[key])
            if button then Glyph(button,direction)end
        end
        if d.fill then d.fill:SetAlpha(1) end
        for _, t in ipairs(H.Regions(f)) do Font(t) end
        if not d.bound then
            d.bound=true
            for _, method in ipairs({'Enable','Disable','SetEnabled','SetChecked'}) do H.Hook(f,method,function()LocalPaint(f)end) end
            H.Script(f,'OnClick',function()LocalPaint(f)end)
            if kind=='Button'then
                for _,event in ipairs({'OnEnter','OnLeave','OnMouseDown','OnMouseUp'})do H.Script(f,event,function()LocalPaint(f)end)end
                local text=f.GetFontString and f:GetFontString()
                if H.Allowed(text)then H.Hook(text,'SetFontObject',function()LocalPaint(f)end)end
            end
            if kind=='DropdownButton'and shared[f]then H.Script(f,'OnMouseDown',function()LocalPaint(f)end)end
        end
    end
    local function Inspect(f)
        -- GGUI stores its wrappers on owned content/column frames. Do not walk
        -- arbitrary recipe/database tables in search of UI objects.
        if type(f) ~= 'table' then return end
        for _, value in pairs(f) do
            if type(value) == 'table' and value.isGGUI then
                local raw = Raw(value)
                if value.content and Raw(value.button)and value.is and CS.GGUI then
                    if CS.GGUI.BlizzardTab and value:is(CS.GGUI.BlizzardTab)or CS.GGUI.Tab and value:is(CS.GGUI.Tab)then
                        local button=Raw(value.button);kinds[button]='tab';widgets[value]=true
                    end
                end
                if raw and raw ~= f then
                    widgets[value] = true
                    if CS.GGUI and CS.GGUI.Icon and value.is and value:is(CS.GGUI.Icon)then kinds[raw]='icon'end
                end
            end
        end
    end
    Walk = function(f, force, depth)
        if not H.Allowed(f) or art[f] or (depth or 0)>24 then return end
        local kind=f:GetObjectType()
        if kind=='Texture'or kind=='Line'or kind=='FontString'or kind=='GameTooltip'or kind=='ModelScene'or kind=='PlayerModel' then return end
        if kinds[f]=='graph' or type(f.AddDataSeries)=='function' then kinds[f]='graph';return end
        owned[f]=true
        local d=State(f)
        local n=f.GetNumChildren and f:GetNumChildren()
        if not force and d.generation==generation and n~=nil and d.children==n then return end
        Inspect(f);Paint(f)
        for _,child in ipairs(H.Children(f))do Walk(child,force,(depth or 0)+1)end
        d.children=f.GetNumChildren and f:GetNumChildren();d.generation=generation
    end
    local function Root(wrapper, window)
        local f=Raw(wrapper)
        if not f then return end
        owned[f]=true;roots[f]=true
        if window then kinds[f]='window' end
        H.Script(f,'OnShow',function()if Ready()then Walk(f)end end)
        Walk(f)
    end
    local function Tag(wrapper, role)
        local f=Raw(wrapper)
        if not f then return end
        owned[f]=true;kinds[f]=role or kinds[f];widgets[wrapper]=true
        Paint(f)
    end
    PaintWidget=function(w, role)
        if type(w)~='table' then return end
        if role=='BlizzardTab'or role=='Tab' then
            local f=Raw(w.button)
            if f then kinds[f]='tab';owned[f]=true;Paint(f)end
            if H.Allowed(w.content)then
                owned[w.content]=true
                if f and S.SetTabSelection then
                    local function Select()if Ready()then S.SetTabSelection(f,w.content:IsShown())end end
                    H.Script(w.content,'OnShow',Select);H.Script(w.content,'OnHide',Select);Select()
                end
            end
        elseif role=='Frame' then
            local f=Raw(w);if not f then return end
            Root(w, true)
            local close=f.closeButton or f.CloseButton
            if close then Tag(close,'close')end
            if f.collapseButton then Tag(f.collapseButton,'collapse')end
        elseif role=='Icon' then Tag(w,'icon')
        elseif role=='FrameList' then
            Tag(w)
            for _,row in ipairs(w.rows or {})do Tag(row,'row');Walk(row.frame)end
            if w.scrollFrame then
                local raw=Raw(w.scrollFrame);if raw then owned[raw]=true;Walk(raw)end
                if w.scrollFrame.scrollBar then owned[w.scrollFrame.scrollBar]=true;Slider(w.scrollFrame.scrollBar)end
            end
        elseif role=='ScrollFrame' then
            Root(w,false)
            if H.Allowed(w.scrollBar)then owned[w.scrollBar]=true;Slider(w.scrollBar)end
        elseif role=='CustomDropdown' then
            Tag(w)
            if w.selectionFrame then Root(w.selectionFrame,true)end
            if w.selectionList then PaintWidget(w.selectionList,'FrameList')end
        else Tag(w);local f=Raw(w);if f and role~='Text'then Walk(f)end end
    end
    -- Snapshot shared Blizzard Settings rows before styling, and restore on
    -- their own initializer's Resetter. No foreign Settings rows are adopted.
    local function Save(f, record)
        if not H.Allowed(f)or art[f] then return end
        shared[f]=record
        local d={regions={}};record.saved[f]=d
        if f.GetBackdrop then d.backdrop=f:GetBackdrop()end
        if f.GetBackdropColor then d.bg={f:GetBackdropColor()}end
        if f.GetBackdropBorderColor then d.edge={f:GetBackdropBorderColor()}end
        local function Text(t)
            if t.GetFont and t:GetFont()then return {font={t:GetFont()},color={t:GetTextColor()},object=t.GetFontObject and t:GetFontObject()}end
        end
        d.font=Text(f)
        for _,t in ipairs(H.Regions(f))do
            if not art[t] then
                local v={alpha=t:GetAlpha(),font=Text(t)}
                if H.Texture(t)then
                    v.path=t:GetTexture();v.atlas=t.GetAtlas and t:GetAtlas();v.color=t.GetVertexColor and {t:GetVertexColor()}
                end
                d.regions[t]=v
            end
        end
        for _,child in ipairs(H.Children(f))do Save(child,record)end
    end
    local function Restore(record)
        if not record or not record.active then return end
        record.active=false
        local unpack=unpack or table.unpack
        local function Text(t,d)
            if not d then return end
            if d.object and t.SetFontObject then t:SetFontObject(d.object)end
            t:SetFont(unpack(d.font));t:SetTextColor(unpack(d.color))
        end
        for f,d in pairs(record.saved)do
            if f.SetBackdrop then f:SetBackdrop(d.backdrop)end
            if d.bg then f:SetBackdropColor(unpack(d.bg))end
            if d.edge then f:SetBackdropBorderColor(unpack(d.edge))end
            Text(f,d.font)
            for t,v in pairs(d.regions)do
                t:SetAlpha(v.alpha);Text(t,v.font)
                if H.Texture(t)then
                    if v.atlas and t.SetAtlas then t:SetAtlas(v.atlas)else t:SetTexture(v.path)end
                    if v.color then t:SetVertexColor(unpack(v.color))end
                end
            end
            local own=records[f]
            if own then
                if own.fill then own.fill:SetAlpha(0)end
                if own.check then own.check:Hide()end
                if own.grip then own.grip:SetAlpha(0)end
                if own.track then own.track:SetAlpha(0)end
                if own.glyph then own.glyph:SetAlpha(0)end
                for _,t in ipairs(own.edges or {})do t:SetAlpha(0)end
            end
        end
    end
    local function SharedRow(f)
        if not Ready()or not H.Allowed(f)then return end
        Restore(shared[f]);local record={active=true,saved={},root=f};Save(f,record)
        for raw in pairs(record.saved)do
            Paint(raw)
            local d=records[raw]
            if d then
                for _,t in ipairs({d.grip,d.track})do if t then t:SetAlpha(1)end end
                for _,t in ipairs(d.edges or {})do t:SetAlpha(1)end
            end
        end
    end
    BindSettings=function()
        local opt=CS.OPTIONS
        local category=opt and opt.category
        local panel=SettingsPanel
        local layout=category and panel and panel.GetLayout and panel:GetLayout(category)
        if not layout or not layout.GetInitializers then return end
        local function Init(i)
            if initializers[i]or type(i.InitFrame)~='function'then return end
            initializers[i]=true
            H.Hook(i,'InitFrame',function(_,f)SharedRow(f)end)
            if type(i.Resetter)=='function'then hooksecurefunc(i,'Resetter',function(_,f)Restore(shared[f])end)end
        end
        for _,i in pairs(layout:GetInitializers())do Init(i)end
        H.Hook(layout,'AddInitializer',function(_,i)Init(i)end)
        if panel.GetCurrentLayout and panel:GetCurrentLayout()==layout and panel.GetSettingsList then
            local list=panel:GetSettingsList();local box=list and list.ScrollBox
            local view=box and box.GetView and box:GetView()
            if view and view.EnumerateFrames then for _,row in view:EnumerateFrames()do
                if row.GetElementData and initializers[row:GetElementData()]and not shared[row]then SharedRow(row)end
            end end
        end
    end
    local menus=setmetatable({}, {__mode='k'})
    local menuDescriptions=setmetatable({}, {__mode='k'})
    MenuList=function(list)
        if not Ready()or not H.Allowed(list)or type(list.AttachTexture)~='function'then return end
        local d=menus[list]
        if not d then
            d={alpha={}};menus[list]=d
            list:HookScript('OnHide',function()
                for t,a in pairs(d.alpha)do t:SetAlpha(a)end
                d.alpha={};d.active=false
                -- Compositor-owned art is released by the compositor itself.
            end)
        end
        if not d.active then
            d.active=true
            d.fill=list:AttachTexture();d.fill:SetDrawLayer('BACKGROUND',-8);d.fill:SetAllPoints(list)
            d.fill:SetColorTexture(S.GetPanelColor())
        end
        for _,key in ipairs({'Backdrop','MenuBackdrop','NineSlice'})do
            local f=list[key]
            if H.Allowed(f)and d.alpha[f]==nil then d.alpha[f]=f:GetAlpha();f:SetAlpha(0)end
        end
        for _,t in ipairs(H.Regions(list))do
            if H.Texture(t)and t~=d.fill and t.GetDrawLayer then
                local layer=t:GetDrawLayer()
                if(layer=='BACKGROUND'or layer=='BORDER')and d.alpha[t]==nil then d.alpha[t]=t:GetAlpha();t:SetAlpha(0)end
            end
        end
        if list.EnumerateElementDescriptions then
            list:EnumerateElementDescriptions(function(_,description)
                if description.AddInitializer and not menuDescriptions[description]then
                    menuDescriptions[description]=true
                    description:AddInitializer(function(_,_,submenu)
                        if d.active and submenu then MenuList(submenu)end
                    end)
                end
            end)
        end
    end
    local function OwnedOptions(options)
        if type(options)~='table'then return false end
        if CS.INIT and options.frameTable==CS.INIT.FRAMES and options.frameTable then return true end
        if options.frameID and CS.CONST and CS.CONST.FRAMES then
            for _,id in pairs(CS.CONST.FRAMES)do if id==options.frameID then return true end end
        end
        return Own(options.parent)or Own(options.anchorParent)
    end
    local classes={'Frame','Button','Text','Checkbox','Dropdown','CustomDropdown','BlizzardTab','Tab','TextInput','NumericInput','Slider','ScrollFrame','FrameList','Icon','ToggleButton'}
    Bind=function()
        local G=CS.GGUI
        if not G then return end
        local context=CS.WIDGETS and CS.WIDGETS.ContextMenu
        H.Hook(context,'Open',function()
            if not Ready()then return end
            local manager=Menu and Menu.GetManager and Menu.GetManager()
            local list=manager and manager.GetOpenMenu and manager:GetOpenMenu()
            MenuList(list)
        end)
        for _,name in ipairs(classes)do
            local role=name
            local class=G[name]
            if type(class)=='table'and type(class.new)=='function'and classHooks[class]~=class.new then
                hooksecurefunc(class,'new',function(w,options)
                    if Ready()and OwnedOptions(options)then H.Safe(PaintWidget,w,role)end
                end)
                classHooks[class]=class.new
            end
        end
        local row=G.FrameList and G.FrameList.Row
        if type(row)=='table'and type(row.new)=='function'and classHooks[row]~=row.new then
            hooksecurefunc(row,'new',function(w,f,_,_,list)
                if Ready()and(Own(f)or list and Own(list.frame))then Tag(w,'row');Walk(f)end
            end)
            classHooks[row]=row.new
        end
        if CS.OPTIONS then
            H.Hook(CS.OPTIONS,'Init',function()if Ready()then Discover()end end)
            H.Hook(CS.OPTIONS,'InitTSMPanelFromTemplate',function(_,f)if Ready()and H.Allowed(f)then SharedRow(f)end end)
        end
        -- Completed UI initialization is infrequent; it covers native controls
        -- appended after a GGUI container's constructor has returned.
        for _,component in pairs(CS)do
            if type(component)=='table'and type(component.UI)=='table'then
                for name,fn in pairs(component.UI)do
                    if type(fn)=='function'and name:match('^Init')then
                        H.Hook(component.UI,name,function()if Ready()then H.Queue(module,Discover)end end)
                    end
                end
            end
        end
    end
    Discover=function()
        if not Ready()then return end
        Bind()
        local init=CS.INIT
        for _,w in pairs(init and init.FRAMES or {})do PaintWidget(w,'Frame')end
        local panel=CS.OPTIONS and CS.OPTIONS.optionsPanel or _G.CraftSimOptionsPanel
        if H.Allowed(panel)then Root(panel,false)end
        -- Native controls on the profession frame are explicit CraftSim-owned
        -- objects; the surrounding Blizzard profession UI is never scanned.
        local queue=CS.CRAFTQ
        for _,key in ipairs({'queueRecipeButton','queueRecipeButtonWO','queueRecipeButtonOptions','queueRecipeButtonOptionsWO'})do
            if queue and queue[key]then Root(queue[key],false)end
        end
        local simulation=CS.SIMULATION_MODE and CS.SIMULATION_MODE.UI
        for _,key in ipairs({'WORKORDER','NO_WORKORDER'})do
            local group=simulation and simulation[key]
            if group and group.toggleButton then Root(group.toggleButton,false)end
        end
        BindSettings()
        -- Inspect only UI wrappers discovered on the owned frame/column fields.
        for w in pairs(widgets)do
            if w.isGGUI and w.is and CS.GGUI then
                for _,name in ipairs(classes)do if CS.GGUI[name]and w:is(CS.GGUI[name])then PaintWidget(w,name);break end end
            end
        end
    end
    local function ChangedLibrary()
        local G=CS.GGUI
        for _,name in ipairs(classes)do
            local c=G and G[name]
            if type(c)=='table'and type(c.new)=='function'and classHooks[c]~=c.new then return true end
        end
        local row=G and G.FrameList and G.FrameList.Row
        return type(row)=='table'and type(row.new)=='function'and classHooks[row]~=row.new
    end
    local function Refresh()
        if applying or not Ready()then return end
        applying=true;H.Safe(Discover)
        for f in pairs(roots)do H.Safe(Walk,f)end
        for f,r in pairs(shared)do
            if r.active and r.root==f then for raw in pairs(r.saved)do H.Safe(Paint,raw)end end
        end
        applying=false
    end
    module.refresh=function()generation=generation+1;Refresh()end
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh)end
    events:SetScript('OnEvent',function(_,event)
        if event=='PLAYER_REGEN_ENABLED'then if waiting then waiting=false;module.refresh()end
        elseif ns.IsEnabled(module)and ChangedLibrary()then Bind()end
    end)
    Refresh()
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition('CraftSim',DefineSkin)
else DefineSkin()end
