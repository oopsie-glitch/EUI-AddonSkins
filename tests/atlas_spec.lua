-- Source-shaped Atlas c847580: three eager UI roots, fixed legend budget,
-- duplicate root map tiles, LibDD controls and borrowed AceConfig widgets.
for _, client in ipairs({'Retail','Forever'}) do
    local created,hooks,reads,fontWrites,colorWrites=0,0,0,0,0
    local looks,events,modules,errors={},{},{},{}
    local enabled,combat=true,false
    local accent={.2,.7,.4};local face='eui-font'
    local function anchors(o)
        function o:SetAllPoints(f) self.all=f end
        function o:SetPoint(...) self.points=self.points or {};self.points[#self.points+1]={...}end
        function o:ClearAllPoints()self.points={}end
        function o:SetSize(w,h)self.w,self.h=w,h end
        function o:GetSize()return self.w or 10,self.h or 10 end
        function o:SetWidth(v)self.w=v end
        function o:SetHeight(v)self.h=v end
        function o:GetWidth()return self.w or 10 end
        function o:GetHeight()return self.h or 10 end
        function o:SetAlpha(v)self.alpha=v end
        function o:GetAlpha()return self.alpha or 0 end
        function o:Show()self.shown=true;if self.scripts and self.scripts.OnShow then self.scripts.OnShow(self)end end
        function o:Hide()self.shown=false;if self.scripts and self.scripts.OnHide then self.scripts.OnHide(self)end end
        function o:IsShown()return self.shown~=false end
        function o:IsVisible()return self:IsShown() and (not self.parent or self.parent:IsVisible())end
    end
    local function region(kind,parent,name,layer)
        created=created+1
        local t={kind=kind,parent=parent,name=name,layer=layer,alpha=1,shown=true,color={.2,.8,.3,1},font={'native',12,''}}
        anchors(t)
        function t:GetObjectType()return self.kind end
        function t:GetName()return self.name end
        function t:GetParent()return self.parent end
        function t:IsForbidden()return false end
        function t:GetTexture()return self.path end
        function t:SetTexture(v)self.path=v end
        function t:SetAtlas(v)self.atlas=v end
        function t:GetDrawLayer()return self.layer end
        function t:SetColorTexture(...)colorWrites=colorWrites+1;self.color={...}end
        function t:SetVertexColor(...)self.color={...}end
        function t:GetVertexColor()return table.unpack(self.color)end
        function t:SetTexCoord(...)self.crop={...}end
        function t:GetFont()return table.unpack(self.font)end
        function t:SetFont(...)fontWrites=fontWrites+1;self.font={...}end
        function t:GetTextColor()return table.unpack(self.color)end
        function t:SetTextColor(...)self.color={...}end
        function t:SetText(v)self.text=v end
        function t:GetText()return self.text end
        function t:SetFontObject()error('Atlas must never mutate borrowed FontObjects')end
        function t:GetFontObject()error('Atlas must never capture borrowed FontObjects')end
        parent.regions[#parent.regions+1]=t;if name then _G[name]=t end;return t
    end
    local function frame(kind,name,parent)
        created=created+1
        local f={kind=kind or 'Frame',name=name,parent=parent,children={},regions={},scripts={},alpha=1,shown=true,w=100,h=25,level=3}
        anchors(f)
        function f:GetObjectType()return self.kind end
        function f:GetName()return self.name end
        function f:GetParent()return self.parent end
        function f:GetFrameLevel()return self.level end
        function f:SetFrameLevel(v)self.level=v end
        function f:EnableMouse(v)self.mouse=v end
        function f:IsForbidden()return self.forbidden end
        function f:IsProtected()return self.protected end
        function f:GetNumChildren()return #self.children end
        function f:GetChildren()reads=reads+1;return table.unpack(self.children)end
        function f:GetNumRegions()return #self.regions end
        function f:GetRegions()reads=reads+1;return table.unpack(self.regions)end
        function f:RegisterEvent(e)self.events=self.events or {};self.events[e]=true end
        function f:SetScript(key,fn)self.scripts[key]=fn end
        function f:HookScript(key,fn)local old=self.scripts[key];self.scripts[key]=function(...)local r=old and table.pack(old(...))or{n=0};fn(...);return table.unpack(r,1,r.n)end end
        function f:CreateTexture(name,layer)return region('Texture',self,name,layer)end
        function f:CreateFontString(name,layer)return region('FontString',self,name,layer)end
        function f:GetFontString()return self.label end
        function f:GetNormalTexture()return self.normal end
        function f:GetPushedTexture()return self.pushed end
        function f:GetHighlightTexture()return self.highlight end
        function f:IsEnabled()return self.enabled~=false end
        function f:SetBackdrop(v)self.backdrop=v end
        function f:GetBackdrop()return self.backdrop end
        function f:GetThumbTexture()return self.thumb end
        function f:GetOrientation()return 'VERTICAL'end
        if parent then parent.children[#parent.children+1]=f end
        if name then _G[name]=f end;return f
    end
    CreateFrame=function(kind,name,parent)local f=frame(kind,name,parent);events[#events+1]=f;return f end
    InCombatLockdown=function()return combat end
    geterrorhandler=function()return function(e)errors[#errors+1]=e end end
    hooksecurefunc=function(obj,key,fn)
        hooks=hooks+1;local original=obj[key]
        obj[key]=function(...)local r=table.pack(original(...));fn(...);return table.unpack(r,1,r.n)end
    end
    C_Timer={After=function()error('Atlas skin added an unexpected timer')end}
    local function text(f,name)local t=f:CreateFontString(name,'ARTWORK');t:SetText('native');return t end
    local function button(name,parent)
        local b=frame('Button',name,parent);b.label=text(b);b.action=function()return 'native',nil,7 end
        b.scripts.OnClick=b.action;return b
    end
    local S={GetAccentColor=function()return table.unpack(accent)end,GetPanelColor=function()return .05,.06,.07,.9 end,
        GetFont=function()return face,''end,OnLooksChanged=function(fn)looks[#looks+1]=fn end}
    local function paint(f,kind,keep)
        if not f["painted"..kind]then f["painted"..kind]=true;local bg=f:CreateTexture(nil,'BACKGROUND');bg:SetColorTexture(.05,.06,.07,.9)end
        f.style=kind;f.keep=keep
    end
    S.Button=function(f,keep)paint(f,'button',keep)end
    S.PageButton=function(f,glyph)paint(f,'page');f.glyph=glyph end
    S.CloseButton=function(f)paint(f,'close')end
    S.Dropdown=function(f)paint(f,'dropdown')end
    S.EditBox=function(f)paint(f,'edit')end
    S.Panel=function(f)error('Atlas must not blanket-strip map roots or borrowed widget trees')end
    S.Shell=S.Panel
    S.StateButtonLabel=function()end
    S.ScrollBar=function(f)paint(f,'scroll')end
    S.Font=function(t,r,g,b)local _,size=t:GetFont();t:SetFont(face,size,'');if r then t:SetTextColor(r,g,b,1)end end
    local ns={IsEnabled=function()return enabled end}
    ns.RegisterModule=function(id,label,available,install)modules[id]={available=available,install=install}end
    local popupOwners={}
    ns.BindPopupOwner=function(_,_,f)popupOwners[f]=true end
    assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins',ns)
    assert(loadfile('EUIAddonSkins/Skins/Atlas.lua'))('EUIAddonSkins',ns)
    Atlas=nil;AtlasLoot={GUI={}};assert(not modules.Atlas.available(),'AtlasLoot wrongly activates Atlas')
    Atlas={LocName='Atlas',optionsFrames={},ScrollBar_Update=function()return 'scroll',nil,4 end,
        RefreshMap=function()return 'map',nil,8 end,ToggleWindowSize=function()return 'size'end,
        ToggleLegendPanel=function()return 'legend'end,OpenOptions=function()return 'options'end,
        SetupOptions=function()end,RegisterModuleOptions=function()end}
    ATLAS_HAS_EJ=client=='Retail';ATLAS_NUM_LINES=2
    local mapRegions={};local chrome={}
    for _,name in ipairs({'AtlasFrame','AtlasFrameSmall','AtlasFrameLarge'})do
        local f=frame('Frame',name);f:SetSize(name=='AtlasFrameSmall' and 534 or 1023,631);f:SetPoint('TOPLEFT',0,-104)
        f.MapFrame=frame('Frame',name..'MapFrame',f)
        local map=f.MapFrame:CreateTexture(nil,'BACKGROUND');map:SetTexture('module/map');mapRegions[#mapRegions+1]=map
        if name=='AtlasFrameLarge'then
            for i=1,12 do local tile=f:CreateTexture('AtlasMapLarge'..i,'BACKGROUND');tile:SetTexture('module/tile'..i);mapRegions[#mapRegions+1]=tile end
        end
        local art=f:CreateTexture(nil,'ARTWORK');art:SetTexture('Interface\\AddOns\\Atlas\\Images\\'..name..'-TopLeft');chrome[#chrome+1]=art
        text(f);button(name..'CloseButton',f);button(name..'OptionsButton',f)
        for _,suffix in ipairs({'PrevMapButton','NextMapButton','SizeUpButton','SizeDownButton','CollapseButton','ExpandButton'})do button(name..suffix,f)end
        for _,suffix in ipairs({'LockButton','LFGButton','AdventureJournalMapButton','AdventureJournalButton','AtlasLootButton'})do
            local b=button(name..suffix,f);b.normal=b:CreateTexture(nil,'ARTWORK');b.normal:SetTexture('meaningful-glyph');b.normal:SetTexCoord(.1,.2,.3,.4)
        end
        for _,suffix in ipairs({'DropDown','DropDownType'})do local d=frame('Frame',name..suffix,f);d.initialize=function()end;d.Label=text(d)end
        f.ZoneName=frame('Button',name..'MapZoneName',f);f.ZoneName.Text=text(f.ZoneName)
        local pin=button(name..'NPC',f.MapFrame);pin.art=pin:CreateTexture(nil,'ARTWORK');pin.art:SetTexture('map-marker');pin.art:SetTexCoord(.2,.3,.4,.5)
    end
    local rootSize,rootPoints=AtlasFrame.w,AtlasFrame.points
    AtlasSearchEditBox=frame('EditBox','AtlasSearchEditBox',AtlasFrame);AtlasSearchEditBox.SetTextInsets=function()end
    AtlasSearchEditBox.action=function(v)AtlasSearchEditBox.value=v;return 'input'end
    for _,n in ipairs({'AtlasSearchButton','AtlasSearchClearButton','AtlasSwitchButton'})do button(n,AtlasFrame)end
    AtlasScrollBarScrollBar=frame('Slider','AtlasScrollBarScrollBar',AtlasFrame)
    AtlasScrollBarScrollBar.thumb=AtlasScrollBarScrollBar:CreateTexture(nil,'ARTWORK')
    for _,suffix in ipairs({'ScrollUpButton','ScrollDownButton'})do button('AtlasScrollBarScrollBar'..suffix,AtlasScrollBarScrollBar)end
    AtlasSwitchDD=frame('Frame','AtlasSwitchDD',AtlasFrame)
    for i=1,2 do local b=button('AtlasEntry'..i,AtlasFrame);b.Text=b.label;b.Highlight=b:CreateTexture(nil,'HIGHLIGHT');b.scripts.OnUpdate=function()return 'native tooltip'end end
    Atlas.WorldMap={Button=button(nil,frame('Frame'))};local world=Atlas.WorldMap.Button
    world.Icon=world:CreateTexture(nil,'ARTWORK');world.Border=world:CreateTexture(nil,'ARTWORK');world.Background=world:CreateTexture(nil,'BACKGROUND')
    AtlasEJLootFrame=nil
    Atlas_EncounterJournal_SetLootButton=function(item)item.icon:SetTexture('native-loot');item.IconBorder:SetVertexColor(.6,.2,.9,1);return 'loot',nil,5 end
    Atlas_EncounterJournal_DisplayLoot=function()return 'display'end
    if ATLAS_HAS_EJ then
        local f=frame('Frame','AtlasEJLootFrame',AtlasFrame);f:CreateTexture('AtlasEJLootFrame_Back','BACKGROUND')
        button('AtlasEJLootFrameCloseButton',f);f.lootScroll=frame('Frame','AtlasEJLootFrameLootScrollFrame',f)
        for _,key in ipairs({'filter','slotFilter','difficulty'})do f.lootScroll[key]=button(nil,f.lootScroll)end
        f.lootScroll.buttons={}
        local row=button(nil,f.lootScroll);row.icon=row:CreateTexture(nil,'ARTWORK');row.IconBorder=row:CreateTexture(nil,'OVERLAY')
        row.bossTexture=row:CreateTexture(nil,'BACKGROUND');row.bosslessTexture=row:CreateTexture(nil,'BACKGROUND')
        row.name=text(row);row.slot=text(row);row.armorType=text(row);row.boss=text(row);f.lootScroll.buttons[1]=row
    end
    local gui={Release=function(_,widget)widget.released=true;return 'release'end}
    local dialog={FeedGroup=function(_,id,_,container)return 'feed',nil,id end,OpenFrames={}}
    LibStub=function(name)if name=='AceGUI-3.0'then return gui elseif name=='AceConfigDialog-3.0'then return dialog end end
    modules.Atlas.install(S,modules.Atlas)
    assert(#errors==0,table.concat(errors,'; '))
    assert(AtlasFrame.w==rootSize and AtlasFrame.points==rootPoints)
    for _,map in ipairs(mapRegions)do assert(map.alpha==1 and map.path:find('module/'),'map tiles stripped')end
    for _,art in ipairs(chrome)do assert(art.alpha==0)end
    assert(AtlasFrameDropDown.style=='dropdown' and popupOwners[AtlasFrameDropDown] and popupOwners.AtlasSwitchDD==nil)
    assert(popupOwners[AtlasSwitchDD] and AtlasFrameNextMapButton.glyph=='>')
    assert(AtlasFrameLockButton.normal.path=='meaningful-glyph' and AtlasFrameLockButton.normal.crop[1]==.1)
    assert(world.Border.alpha==0 and world.Icon.alpha==1)
    local n,r,fw,c=created,reads,fontWrites,hooks
    for _=1,1000 do local a,b,v=Atlas:ScrollBar_Update();assert(a=='scroll'and b==nil and v==4)end
    assert(created==n and reads==r and fontWrites==fw and hooks==c,'warm legend updates do skin discovery')
    assert(AtlasEntry1.scripts.OnUpdate()=='native tooltip' and AtlasEntry1.scripts.OnClick()=='native')
    local newEntry=button('AtlasEntry2',AtlasFrame);newEntry.Text=newEntry.label
    Atlas:ScrollBar_Update();assert(newEntry.Text.font[1]==face,'same-count legend replacement missed')
    if ATLAS_HAS_EJ then
        local item=AtlasEJLootFrame.lootScroll.buttons[1]
        local a,b,v=Atlas_EncounterJournal_SetLootButton(item);assert(a=='loot'and b==nil and v==5)
        assert(item.icon.path=='native-loot'and item.IconBorder.alpha==1 and item.bossTexture.alpha==0)
    end
    local function widget(kind)
        local w={type=kind,frame=frame('Frame'),children={}}
        if kind=='CheckBox'then
            w.checkbg=w.frame:CreateTexture(nil,'ARTWORK');w.check=w.frame:CreateTexture(nil,'ARTWORK');w.checked=true
            w.SetValue=function(self,v)self.checked=v;self.check.shown=v;return 'value'end
            w.SetDisabled=function(self,v)self.disabled=v;return 'disabled'end
        elseif kind=='Dropdown'then
            w.dropdown=frame('Frame',nil,w.frame);w.dropdown:CreateTexture(nil,'ARTWORK')
            w.button=button(nil,w.dropdown);w.button:CreateTexture(nil,'ARTWORK')
            w.pullout={frame=frame('Frame'),items={},Open=function()return 'open'end}
        elseif kind=='Slider'then
            w.slider=frame('Slider',nil,w.frame);w.slider.thumb=w.slider:CreateTexture(nil,'ARTWORK')
            w.slider.range={0,100};w.editbox=frame('EditBox',nil,w.frame)
        elseif kind=='Button'then
            w.frame.highlight=w.frame:CreateTexture(nil,'HIGHLIGHT')
        end
        return w
    end
    local group=widget('BlizOptionsGroup');local check=widget('CheckBox');local dropdown=widget('Dropdown')
    local slider=widget('Slider');local action=widget('Button');local sliderW,sliderH=slider.slider:GetSize()
    group.children={check,dropdown,slider,action};Atlas.optionsFrames.General=group
    modules.Atlas.refresh() -- Bind the owned category's first-show hook.
    local a,b,id=dialog:FeedGroup('Atlas',{},group);assert(a=='feed'and b==nil and id=='Atlas')
    assert(check.check.alpha==0 and check.checkbg.alpha==0 and #check.frame.regions==4)
    local box,mark=check.frame.regions[3],check.frame.regions[4]
    assert(box.w==14 and mark.w==8 and mark.alpha==1)
    assert(slider.slider.thumb.alpha==0 and slider.slider.regions[3].w==6 and slider.slider.range[2]==100)
    assert(slider.slider.w==sliderW and slider.slider.h==sliderH and action.frame.highlight.alpha==1)
    local nn,hh,rr,ff,cc=created,hooks,reads,fontWrites,colorWrites
    for _=1,1000 do check:SetValue(true);check:SetDisabled(false)end
    -- First disabled flag normalisation may repaint once.
    assert(created==nn and hooks==hh and reads==rr and fontWrites==ff and colorWrites<=cc+1)
    check:SetValue(false);assert(mark.alpha==0)
    check:SetValue(true);check:SetDisabled(true);assert(mark.color[1]==.4 and mark.alpha==1)
    local pullItem=widget('CheckBox');dropdown.pullout.items={pullItem}
    assert(dropdown.pullout:Open()=='open' and pullItem.check.alpha==0)
    gui:Release(group)
    assert(check.check.alpha==1 and check.checkbg.alpha==1 and mark.alpha==0 and pullItem.check.alpha==1)
    assert(slider.slider.thumb.alpha==1 and slider.slider.regions[3].alpha==0)
    -- Foreign use after release must not be restyled by the old callbacks.
    check:SetValue(true);assert(check.check.alpha==1 and mark.alpha==0)
    local foreign=widget('BlizOptionsGroup');local before=reads
    dialog:FeedGroup('OtherAddon',{},foreign);assert(reads==before and #foreign.frame.regions==0)
    dialog:FeedGroup('Atlas',{},group);assert(check.check.alpha==0)
    dropdown.pullout:Open();assert(pullItem.check.alpha==0)
    dialog:FeedGroup('OtherAddon',{},group);assert(check.check.alpha==1 and mark.alpha==0 and pullItem.check.alpha==1)
    group.frame:Show();assert(check.check.alpha==1 and mark.alpha==0)
    dialog:FeedGroup('Atlas',{},group)
    enabled=false;gui:Release(check);assert(check.check.alpha==1)
    local late=widget('CheckBox');group.children[1]=late
    dialog:FeedGroup('Atlas',{},group);assert(late.check.alpha==1)
    enabled=true;combat=true;dialog:FeedGroup('Atlas',{},group);assert(late.check.alpha==1)
    combat=false
    for _,e in ipairs(events)do if e.events and e.events.PLAYER_REGEN_ENABLED then e.scripts.OnEvent(e,'PLAYER_REGEN_ENABLED')end end
    -- Open Settings groups are discovered at combat recovery without invoking native data actions.
    assert(late.check.alpha==0)
    face='changed-font';accent={.9,.1,.2}
    for _,fn in ipairs(looks)do fn()end
    assert(AtlasEntry1.Text.font[1]==face and late.frame.regions[4].color[1]==.9)
    assert(late.check.font[1]=='native' and #errors==0,table.concat(errors,'; '))
    Atlas.optionsFrames={};AtlasEJLootFrame=nil;Atlas=nil;AtlasLoot=nil
    print('PASS: Atlas '..client..': main/small/large map tiles/pins/geometry, dropdown ownership, native actions/colours, legend pooling, options release/foreign reuse, combat/theme/toggles and optional EJ handling')
    print('BENCH Atlas '..client..' mock: 1000 warm legend updates: new objects/hooks, hierarchy reads and font writes=0; 1000 stable option state updates: no objects/hooks/scans/fonts and at most one normalisation colour write')
end
