local ADDON, ns = ...
local function DefineSkin()
local function Public()
    return LibStub and LibStub("Myslot-5.0", true)
end
local canvas
local headings = {Myslot = true, Unsaved = true, [(TALENTS or 'Talents') .. ':'] = true}
local painted, captionHooks = setmetatable({}, {__mode='k'}), setmetatable({}, {__mode='k'})
local layers, menuContexts = setmetatable({}, {__mode='k'}), setmetatable({}, {__mode='k'})
local function SettingsCanvas()
    if SettingsPanel and SettingsPanel.GetSettingsCanvas then
        local ok, frame=pcall(SettingsPanel.GetSettingsCanvas,SettingsPanel)
        if ok and frame then return frame end
    end
    return SettingsPanel and SettingsPanel.Container and SettingsPanel.Container.SettingsCanvas
end
local function Options()
    if canvas then return canvas end
    if Settings and Settings.GetCategory and SettingsPanel and SettingsPanel.GetLayout then
        local ok, frame = pcall(function()
            local category = Settings.GetCategory('Myslot')
            local layout = category and SettingsPanel:GetLayout(category)
            return layout and layout.GetFrame and layout:GetFrame()
        end)
        if ok and (type(frame)=='table'or type(frame)=='userdata')and type(frame.GetObjectType)=='function' then canvas = frame end
    end
    if not canvas then
        for _, holder in pairs({modern=SettingsCanvas(),legacy=InterfaceOptionsFramePanelContainer})do
            if holder.GetChildren then
                for _,frame in ipairs({holder:GetChildren()})do
                    if frame.name=='Myslot' then canvas=frame;break end
                end
            end
        end
    end
    if not canvas then
        for _, frame in ipairs(INTERFACEOPTIONS_ADDONCATEGORIES or {}) do
            if frame.name == 'Myslot' then canvas = frame; break end
        end
    end
    return canvas
end
local function AccentCaption(C, text)
    if not text or not text.GetText or not text.SetTextColor then return end
    local value = text:GetText()
    if type(value) ~= 'string' then return end
    local plain = value:gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', '')
    if not headings[plain] then return end
    local r,g,b = C.S.GetAccentColor()
    if plain ~= value and text.SetText then
        -- Only recognised cosmetic headings lose embedded yellow markup.
        -- Profile/import text, class/status colours and danger text never enter.
        local state = captionHooks[text]
        if state and state.busy then return end
        if state then state.busy = true end
        text:SetText(plain)
        if state then state.busy = false end
    end
    text:SetTextColor(r,g,b)
end
local function Control(C,f,glyph,keep)
    local layer=layers[f]
    if not layer then
        local preserved={}
        for _,entry in ipairs(keep or {})do preserved[entry[1]]=true end
        for _,texture in ipairs(C.H.Regions(f))do
            if C.H.Texture(texture) and not preserved[texture]then C.H.Fade(texture)end
        end
        for _,getter in ipairs({'GetNormalTexture','GetPushedTexture','GetDisabledTexture','GetHighlightTexture'})do
            local texture=f[getter]and f[getter](f)
            if C.H.Texture(texture)and not preserved[texture]then C.H.Fade(texture)end
        end
        if C.H.Allowed(f.NineSlice)then C.S.FadeNineSlice(f.NineSlice)end
        layer=CreateFrame('Frame',nil,f);layer:SetAllPoints(f);layer:EnableMouse(false)
        C.S.Panel(layer,{inset=false,noBorder=true});layers[f]=layer
        layer.hover=layer:CreateTexture(nil,'OVERLAY');layer.hover:SetAllPoints(layer)
        layer.hover:SetColorTexture(1,1,1,.14);layer.hover:SetAlpha(0)
        local function Level()layer:SetFrameLevel(math.max(0,f:GetFrameLevel()-1))end
        C.H.Hook(f,'SetParent',Level);C.H.Hook(f,'SetFrameLevel',Level)
        local function Label()
            local text=f.GetFontString and f:GetFontString()
            if text and text.SetTextColor then
                if not f.IsEnabled or f:IsEnabled()then text:SetTextColor(.92,.92,.94)
                else text:SetTextColor(.5,.5,.52)end
            end
        end
        C.H.Script(f,'OnEnter',function()Label();if not f.IsEnabled or f:IsEnabled()then layer.hover:SetAlpha(1)end end)
        C.H.Script(f,'OnLeave',function()Label();layer.hover:SetAlpha(0)end)
        for _,event in ipairs({'OnEnable','OnDisable','OnMouseDown','OnMouseUp'})do C.H.Script(f,event,Label)end
        C.H.Script(f,'OnHide',function()layer.hover:SetAlpha(0)end)
        if glyph then
            layer.glyph=layer:CreateTexture(nil,'OVERLAY')
            layer.glyph:SetTexture('Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png')
            layer.glyph:SetSize(12,8);layer.glyph:SetPoint('CENTER',f,'CENTER')
            layer.glyph:SetVertexColor(.8,.8,.82,1)
            if glyph=='up'then layer.glyph:SetRotation(math.pi)end
        end
        for _,entry in ipairs(keep or {})do entry[1]:SetAlpha(entry[2])end
        Label()
    end
    layer:SetFrameLevel(math.max(0,f:GetFrameLevel()-1))
    local parent=f.GetParent and f:GetParent()
    local optionsButton=false
    for _=1,12 do
        if not parent then break end
        if parent==canvas then optionsButton=true;break end
        parent=parent.GetParent and parent:GetParent()
    end
    if optionsButton and not layer.optionsEdges then
        layer.optionsEdges={}
        for _,side in ipairs({'TOP','BOTTOM','LEFT','RIGHT'})do
            local edge=layer:CreateTexture(nil,'BORDER');edge:SetColorTexture(.26,.26,.26,1)
            if side=='TOP'or side=='BOTTOM'then
                edge:SetPoint(side..'LEFT',layer,side..'LEFT');edge:SetPoint(side..'RIGHT',layer,side..'RIGHT');edge:SetHeight(1)
            else
                edge:SetPoint('TOP'..side,layer,'TOP'..side);edge:SetPoint('BOTTOM'..side,layer,'BOTTOM'..side);edge:SetWidth(1)
            end
            layer.optionsEdges[#layer.optionsEdges+1]=edge
        end
    end
    for _,edge in ipairs(layer.optionsEdges or {})do edge:SetAlpha(optionsButton and 1 or 0)end
    return layer
end
local function Captions(C, f)
    for _, text in ipairs(C.H.Regions(f)) do
        if text.GetObjectType and text:GetObjectType()=='FontString' and text.GetText then
            local value=text:GetText()
            local plain=type(value)=='string' and value:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')
            -- The Unsaved caption starts empty and is populated only after
            -- export/edit. Observe owned non-action labels before that happens.
            if headings[plain] or not (f.GetFontString and f:GetFontString()==text) then
                if not captionHooks[text] then
                    captionHooks[text]={}
                    C.H.Hook(text,'SetText',function() if not captionHooks[text].busy then AccentCaption(C,text) end end)
                end
                AccentCaption(C,text)
            end
        end
    end
end
local function OwnedMenu(C,owner)
    local lib=Public();local main=lib and lib.MainFrame
    for _=1,12 do
        if not owner then return false end
        if owner==main then return true end
        owner=owner.GetOwnerRegion and owner:GetOwnerRegion()or(owner.GetParent and owner:GetParent())
    end
    return false
end
local function MenuArt(C,row,description)
    if not ns.IsEnabled(C.module)or(InCombatLockdown and InCombatLockdown())then return end
    -- Only native compositor textures are changed; no restricted CreateTexture,
    -- FontString:SetFont, row scripts or selection callbacks are touched.
    if row.arrow and row.arrow.SetTexture then
        row.arrow:SetTexture('Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-right.png')
        row.arrow:SetVertexColor(.75,.75,.78,1)
    end
    local selection=description and ((description.IsCheckbox and description:IsCheckbox())or(description.IsRadio and description:IsRadio()))
    if selection and row.leftTexture1 then
        row.leftTexture1:SetColorTexture(.18,.18,.19,1)
        if row.leftTexture2 then
            row.leftTexture2:SetColorTexture(C.S.GetAccentColor())
            row.leftTexture2:SetSize(7,7);row.leftTexture2:ClearAllPoints()
            row.leftTexture2:SetPoint('CENTER',row.leftTexture1,'CENTER')
        end
    end
end
local function MenuReady(C)
    local manager=Menu and Menu.GetManager and Menu.GetManager()
    local list=manager and manager.GetOpenMenu and manager:GetOpenMenu()
    local owner=list and list.GetOwnerRegion and list:GetOwnerRegion()
    if not C.H.Allowed(list)or not OwnedMenu(C,owner)then return end
    if list.EnumerateElementDescriptions then
        list:EnumerateElementDescriptions(function(_,description)
            if not description.AddInitializer then return end
            local context=menuContexts[description]
            if not context then
                context={};menuContexts[description]=context
                description:AddInitializer(function(row,desc,menu)
                    local target=context.list
                    if target and (not menu or menu==target)and target:IsShown()
                        and target:GetOwnerRegion()==context.owner and OwnedMenu(C,context.owner)then MenuArt(C,row,desc)end
                end)
            end
            context.list,context.owner=list,owner
        end)
    end
    for _,row in ipairs(C.H.Children(list))do
        if C.H.Allowed(row)and row.GetElementDescription then MenuArt(C,row,row:GetElementDescription())end
    end
    if ns.BindPopupList then ns.BindPopupList(C.S,C.module,owner,list)end
end
ns.RegisterScopedSkin('Myslot','Myslot',{
    softBorders=true,
    preserveTextColors=true,
    immediateShow=true,
    available=function()local lib=Public();return (lib and lib.MainFrame~=nil)or(C_AddOns and C_AddOns.IsAddOnLoaded('Myslot'))end,
    roots=function(C)
        local roots={};local lib=Public()
        if lib and lib.MainFrame then roots[#roots+1]={frame=lib.MainFrame,options={noTopBar=true,noAccent=true}} end
        local panel=Options()
        if C.H.Allowed(panel) then roots[#roots+1]={frame=panel,mode='controls'}end
        return roots
    end,
    -- Static controls already have native state handlers. Clicks only need to
    -- bind a completed popup, not traverse the editor/options tree again.
    controlRefresh=function(C)MenuReady(C)end,
    hooks=function(C)
        C.H.Hook(Settings,'RegisterCanvasLayoutCategory',function(frame,name)
            if name=='Myslot' then canvas=frame;C.module.refresh()end
        end)
        C.H.Hook(SettingsPanel,'DisplayCategory',function(_,category)
            if category and category.GetName and category:GetName()=='Myslot' then
                local panel=Options();if C.H.Allowed(panel)then C.RefreshControlsNow(panel)end
            end
        end)
        local function CanvasReady()
            local panel=Options()
            if C.H.Allowed(panel)and(not panel.IsVisible or panel:IsVisible())then C.RefreshControlsNow(panel)end
        end
        C.H.Hook(SettingsPanel,'DisplayLayout',CanvasReady)
        C.H.Hook(SettingsCanvas(),'Show',CanvasReady)
        C.H.Hook(_G.InterfaceOptionsFramePanelContainer,'Show',CanvasReady)
        local manager=Menu and Menu.GetManager and Menu.GetManager()
        C.H.Hook(manager,'OpenMenu',function()MenuReady(C)end)
        MenuReady(C)
    end,
    visit=function(C,f,kind)
        Captions(C,f)
        if kind=='EditBox' and f.IsMultiLine and f:IsMultiLine() then
            -- Keep the encoded profile byte-for-byte, including all editor
            -- geometry, selection/focus handlers and native text callbacks.
            if not painted[f] and f.SetFont and f.GetFont then
                local _,size=f:GetFont();local path,flags=C.S.GetFont()
                f:SetFont(path,size or 12,flags or '');painted[f]=true
            end
            return true
        end
        if kind=='Slider' and f.GetThumbTexture then
            local thumb=f:GetThumbTexture()
            if C.H.Texture(thumb) then
                thumb:SetAlpha(0)
                local grip=painted[f]
                if not grip then
                    for _,texture in ipairs(C.H.Regions(f))do if C.H.Texture(texture)then C.H.Fade(texture)end end
                    if f.SetBackdrop then f:SetBackdrop(nil)end
                    if C.H.Allowed(f.NineSlice)then C.S.FadeNineSlice(f.NineSlice)end
                    local track=f:CreateTexture(nil,'BACKGROUND');track:SetPoint('TOP',f,'TOP');track:SetPoint('BOTTOM',f,'BOTTOM');track:SetWidth(2);track:SetColorTexture(.16,.16,.18,1)
                    grip=f:CreateTexture(nil,'ARTWORK');grip:SetPoint('CENTER',thumb,'CENTER');grip:SetSize(6,18);painted[f]=grip
                    local function Visible()grip:SetAlpha((not thumb.IsShown or thumb:IsShown())and 1 or 0)end
                    for _,method in ipairs({'Show','Hide','SetShown'})do C.H.Hook(thumb,method,Visible)end
                    Visible()
                end
                grip:SetColorTexture(C.S.GetAccentColor())
            end
            return true
        end
        if kind=='CheckButton' then
            if not painted[f]then C.S.Checkbox(f);painted[f]=true end
            if f.text and f.text.SetTextColor then f.text:SetTextColor(.9,.9,.92)end
            return true
        end
        if kind=='Button' then
            C.MenuOwner(f)
            local lib=Public();local main=lib and lib.MainFrame
            if not painted[f]then
                local label=f.GetFontString and f:GetFontString()
                local value=label and label.GetText and label:GetText()
                local hasText=label and(value==nil or value~='')
                local point,relative,relativePoint,x
                if f.GetPoint then point,relative,relativePoint,x=f:GetPoint()end
                local small=f.GetWidth and f:GetWidth()<=40
                local split=small and point=='LEFT'and relativePoint=='RIGHT'and x==0
                    and relative and relative.GetParent and relative:GetParent()==main
                local icons={}
                -- Native texture IDs can be numbers. The share button exposes
                -- normal/pushed/disabled art directly; preserve each one's alpha.
                if not hasText and small and not split and f.GetParent and f:GetParent()==main then
                    for _,getter in ipairs({'GetNormalTexture','GetPushedTexture','GetDisabledTexture'})do
                        local texture=f[getter]and f[getter](f)
                        if C.H.Texture(texture)then icons[#icons+1]={texture,texture:GetAlpha()}end
                    end
                end
                local dropdown=not hasText and f.GetWidth and f:GetWidth()>150
                if dropdown then
                    for _,texture in ipairs(C.H.Regions(f))do
                        local anchor=texture.GetPoint and texture:GetPoint()
                        if C.H.Texture(texture)and anchor and anchor:find('LEFT',1,true)then icons[#icons+1]={texture,texture:GetAlpha()}end
                    end
                end
                local parent=f.GetParent and f:GetParent()
                local parentName=parent and parent.GetName and parent:GetName()
                local up=parent and(parent.ScrollUpButton or(parentName and _G[parentName..'ScrollUpButton']))
                local down=parent and(parent.ScrollDownButton or(parentName and _G[parentName..'ScrollDownButton']))
                local stepper=up==f or down==f
                local glyph=split and'down'or dropdown and'down'or stepper and(up==f and'up'or'down')
                local layer=Control(C,f,glyph,icons)
                if dropdown and layer.glyph then layer.glyph:ClearAllPoints();layer.glyph:SetPoint('RIGHT',f,'RIGHT',-7,0)end
                painted[f]=true
                C.H.Script(f,'OnClick',function()MenuReady(C)end)
            else Control(C,f)end
            return true
        end
        if kind=='Frame'and f~=canvas and f.GetBackdrop and f:GetBackdrop()then
            if not painted[f]then C.S.Panel(f,{noBorder=true,inset=false});painted[f]=true end
            f:SetBackdrop(nil)
            return true
        end
    end,
    -- Private UIParent-owned import progress has no stable public handle.
    -- Leave its native coroutine/update and all confirmation actions untouched.
})
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition('Myslot',DefineSkin)
else DefineSkin()end
