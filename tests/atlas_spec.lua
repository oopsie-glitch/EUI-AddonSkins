-- Source-shaped Atlas c847580: three eager UI roots, fixed legend budget,
-- duplicate root map tiles, LibDD controls and borrowed AceConfig widgets.
for _, client in ipairs({'Retail','Forever'}) do
    local created,hooks,reads,fontWrites,colorWrites=0,0,0,0,0
    local looks,events,modules,errors={},{},{},{}
    local fileIDs,assetReads={},0
    GetFileIDFromPath=function(path)assetReads=assetReads+1;return fileIDs[path:lower():gsub('%.blp$','')]end
    local enabled,combat=true,false
    local accent={.2,.7,.4};local face='eui-font'
    local function anchors(o)
        function o:SetAllPoints(f) self.all=f end
        function o:SetPoint(...) self.points=self.points or {};self.points[#self.points+1]={...}end
        function o:GetPoint()
            local p=self.points and self.points[1]
            if not p then return end
            if type(p[2])=='number' then return p[1],self.parent,p[1],p[2],p[3] end
            return table.unpack(p)
        end
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
        function t:GetTextureFileID()return self.path end
        function t:SetTexture(v)self.path=v end
        function t:SetAtlas(v)self.atlas=v end
        function t:SetDesaturated(v)self.desaturated=v end
        function t:AddMaskTexture(mask)self.mask=mask end
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
        function f:GetFrameStrata()return 'MEDIUM'end
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
        function f:CreateTexture(name,layer,_,sublevel)local r=region('Texture',self,name,layer);r.sublevel=sublevel;return r end
        function f:CreateFontString(name,layer)return region('FontString',self,name,layer)end
        function f:CreateMaskTexture(name,layer)return region('MaskTexture',self,name,layer)end
        function f:GetFontString()return self.label end
        function f:GetNormalTexture()return self.normal end
        function f:GetPushedTexture()return self.pushed end
        function f:GetHighlightTexture()return self.highlight end
        function f:IsEnabled()return self.enabled~=false end
        function f:SetBackdrop(v)self.backdrop=v end
        function f:GetBackdrop()return self.backdrop end
        function f:GetThumbTexture()return self.thumb end
        function f:GetOrientation()return self.orientation or 'VERTICAL'end
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
    S.PageButton=function(f,glyph,size)
        assert(f:GetObjectType()=='Button','EUI PageButton requires Button state methods')
        paint(f,'page');f.glyph=glyph;f.glyphSize=size
        for _,key in ipairs({'normal','pushed','highlight'})do if f[key]then f[key]:SetAlpha(0)end end
    end
    S.CloseButton=function(f)paint(f,'close')end
    S.Dropdown=function()error('Atlas LibDD must not gain a second decorative arrow')end
    S.EditBox=function(f)paint(f,'edit')end
    S.Panel=function(f)error('Atlas must not blanket-strip map roots or borrowed widget trees')end
    S.Shell=S.Panel
    S.StateButtonLabel=function()end
    S.ScrollBar=function(f)paint(f,'scroll')end
    S.Font=function(t,r,g,b)local _,size=t:GetFont();t:SetFont(face,size,'');if r then t:SetTextColor(r,g,b,1)end end
    local ns={IsEnabled=function()return enabled end}
    ns.RegisterModule=function(id,label,available,install)modules[id]={available=available,install=install}end
    local popupOwners={}
    ns.BindPopupOwner=function(_,_,f,options)popupOwners[f]=options or true end
    assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins',ns)
    assert(loadfile('EUIAddonSkins/Skins/Atlas.lua'))('EUIAddonSkins',ns)
    Atlas=nil;AtlasLoot={GUI={}};assert(not modules.Atlas.available(),'AtlasLoot wrongly activates Atlas')
    Atlas={LocName='Atlas',optionsFrames={},ScrollBar_Update=function()return 'scroll',nil,4 end,
        RefreshMap=function()return 'map',nil,8 end,ToggleWindowSize=function()return 'size'end,
        ToggleLegendPanel=function()return 'legend'end,OpenOptions=function()return 'options'end,
        SetupOptions=function()end,RegisterModuleOptions=function()end}
    Atlas.db={profile={options={frames={lock=false}}}}
    Atlas.UpdateLock=function(self)
        for _,name in ipairs({'AtlasFrame','AtlasFrameSmall','AtlasFrameLarge'})do
            _G[name..'LockButton'].normal:SetTexture(self.db.profile.options.frames.lock and 'locked' or 'unlocked')
        end
        return 'lock',nil,6
    end
    ATLAS_HAS_EJ=client=='Retail';ATLAS_NUM_LINES=2
    local mapRegions,chrome,nativeGlobes,rootMetadata={},{},{},{}
    for rootIndex,name in ipairs({'AtlasFrame','AtlasFrameSmall','AtlasFrameLarge'})do
        local f=frame('Frame',name);f:SetSize(name=='AtlasFrameSmall' and 534 or 1023,name=='AtlasFrameLarge' and 790 or 631);f:SetPoint('TOPLEFT',0,-104)
        f.MapFrame=frame('Frame',name..'MapFrame',f)
        local map=f.MapFrame:CreateTexture(nil,'BACKGROUND');map:SetTexture('module/map');mapRegions[#mapRegions+1]=map
        if name=='AtlasFrameLarge'then
            for i=1,12 do local tile=f:CreateTexture('AtlasMapLarge'..i,'BACKGROUND');tile:SetTexture('module/tile'..i);mapRegions[#mapRegions+1]=tile end
        end
        local slots=name=='AtlasFrameLarge' and {{512,512,0,0},{512,512,512,0},{512,256,0,-512},{512,256,512,-512},{512,32,0,-768},{512,32,512,-768}}
            or {{512,128,0,0},{512,512,0,-128},{name=='AtlasFrameSmall' and 32 or 512,128,512,0},{name=='AtlasFrameSmall' and 32 or 512,512,512,-128}}
        local parts=name=='AtlasFrameLarge' and {'TopLeft','TopRight','MidLeft','MidRight','BottomLeft','BottomRight'}
            or {'TopLeft','BottomLeft','TopRight','BottomRight'}
        for i,slot in ipairs(slots)do
            local art=f:CreateTexture(nil,i==#slots and 'BORDER' or 'ARTWORK')
            -- Float sizes and named relative frames model scaled native geometry.
            art:SetSize(slot[1]+.015,slot[2]-.015);art:SetPoint('TOPLEFT',name,'TOPLEFT',slot[3]+.015,slot[4]-.015)
            local path='Interface\\AddOns\\Atlas\\Images\\'..name..'-'..parts[i]
            local id=900000+rootIndex*100+i
            if i~=#slots then fileIDs[path:lower()]=id end -- one opaque ID must use the geometry fallback
            art.pendingPath=client=='Retail' and id or (name..'-'..parts[i]..'.BLP')
            if client=='Forever' then art:SetTexture(art.pendingPath) end
            if i==1 then nativeGlobes[name]=art end
            chrome[#chrome+1]=art
        end
        local semantic=f:CreateTexture(nil,'ARTWORK');semantic:SetTexture('module/annotation');semantic:SetSize(512,128);semantic:SetPoint('TOPLEFT',0,0)
        mapRegions[#mapRegions+1]=semantic
        text(f);button(name..'CloseButton',f);button(name..'OptionsButton',f)
        for _,suffix in ipairs({'PrevMapButton','NextMapButton','SizeUpButton','SizeDownButton','CollapseButton','ExpandButton'})do button(name..suffix,f)end
        for _,suffix in ipairs({'LockButton','LFGButton','AdventureJournalMapButton','AdventureJournalButton','AtlasLootButton'})do
            local b=button(name..suffix,f);b.normal=b:CreateTexture(nil,'ARTWORK');b.normal:SetTexture('meaningful-glyph');b.normal:SetTexCoord(.1,.2,.3,.4)
        end
        for _,suffix in ipairs({'DropDown','DropDownType'})do
            local d=frame('Frame',name..suffix,f);d.initialize=function()end;d.Label=text(d);d.Text=text(d)
            for _,side in ipairs({'Left','Middle','Right'})do d[side]=d:CreateTexture(nil,'ARTWORK')end
            d.Button=button(name..suffix..'Button',d);d.Button:SetSize(24,24);d.Button.normal=d.Button:CreateTexture(nil,'ARTWORK')
            d.favorite=button(name..suffix..'OptionalFavorite',d);d.favorite.icon=d.favorite:CreateTexture(nil,'ARTWORK')
        end
        f.ZoneName=frame('Button',name..'MapZoneName',f);f.ZoneName.Text=text(f.ZoneName)
        local pin=button(name..'NPC',f.MapFrame);pin.art=pin:CreateTexture(nil,'ARTWORK');pin.art:SetTexture('map-marker');pin.art:SetTexCoord(.2,.3,.4,.5)
    end
    local info=frame('Frame','AtlasText_ZoneName',AtlasFrame);info:SetPoint('TOPLEFT',546,-84)
    info.label=text(info);local infoPoints,infoColor=info.points,info.label.color
    local rootSize,rootPoints=AtlasFrame.w,AtlasFrame.points
    for _,name in ipairs({'AtlasFrame','AtlasFrameSmall','AtlasFrameLarge'})do
        local f=_G[name];local artwork=0
        for _,r in ipairs(f.regions)do if r.kind=='Texture' and r.layer=='ARTWORK' then artwork=artwork+1 end end
        rootMetadata[f]={level=f:GetFrameLevel(),strata=f:GetFrameStrata(),artwork=artwork}
    end
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
    -- First observation can precede native texture assignment; never add a second globe.
    for _,name in ipairs({'AtlasFrame','AtlasFrameSmall','AtlasFrameLarge'})do
        local f=_G[name];local artwork=0
        for _,r in ipairs(f.regions)do if r.kind=='Texture' and r.layer=='ARTWORK' then artwork=artwork+1 end end
        assert(artwork==rootMetadata[f].artwork,'skin created duplicate globe artwork')
    end
    if client=='Retail' then
        for _,r in ipairs(chrome)do r:SetTexture(r.pendingPath)end
        for _,name in ipairs({'AtlasFrame','AtlasFrameSmall','AtlasFrameLarge'})do _G[name]:Show() end
    end
    assert(#errors==0,table.concat(errors,'; '))
    assert(info.points==infoPoints and info.label.color[1]==infoColor[1] and info.label.alpha==1)
    assert(AtlasFrame.w==rootSize and AtlasFrame.points==rootPoints)
    for _,map in ipairs(mapRegions)do assert(map.alpha==1 and map.path:find('module/'),'map tiles stripped')end
    for _,art in ipairs(chrome)do assert(art==nativeGlobes[art.parent.name] and art.alpha==1 or art.alpha==0,'native composite survived outside globe')end
    assert(AtlasFrameDropDown.Button.glyph=='v' and AtlasFrameDropDown.Button.glyphSize==10 and AtlasFrameDropDown.Button.normal.alpha==0 and AtlasFrameDropDown.Button.w==24 and AtlasFrameDropDown.Button.h==24)
    assert(AtlasFrameDropDown.Left.alpha==0 and AtlasFrameDropDown.favorite.icon.alpha==1)
    assert(AtlasFrameDropDown.Button.scripts.OnClick()=='native' and AtlasFrameDropDown.favorite.scripts.OnClick()=='native')
    assert(popupOwners[AtlasFrameDropDown].noAccent and popupOwners[AtlasFrameDropDown].chevrons and popupOwners[AtlasFrameDropDown].compactChecks)
    assert(popupOwners.AtlasSwitchDD==nil)
    for _,name in ipairs({'AtlasFrame','AtlasFrameSmall','AtlasFrameLarge'})do
        local f=_G[name];local globes,fills=0,0
        for _,r in ipairs(f.regions)do
            if r.kind=='Texture' and r.path==nil then
                fills=fills+1
                assert(r.layer=='BACKGROUND' and r.sublevel==-8 and r.all==f,'covering info/header/legend rectangle returned')
            end
            if r.w==32 and r.h==32 and r.crop and r.crop[1]==2/512 then
                globes=globes+1
                assert(r==nativeGlobes[name] and r.mask,'globe must reuse original composite')
                assert(r.crop[2]==74/512 and r.points[1][4]==16 and r.points[1][5]==-9)
            end
        end
        assert(fills==1 and globes==1,'one base fill and one original globe expected')
        assert(f:GetFrameLevel()==rootMetadata[f].level and f:GetFrameStrata()==rootMetadata[f].strata)
    end
    Atlas.db.profile.options.frames.lock=true
    local la,lb,lc=Atlas:UpdateLock();assert(la=='lock' and lb==nil and lc==6)
    assert(AtlasFrameLockButton.normal.path=='locked' and AtlasFrameLockButton.normal.desaturated)
    Atlas.db.profile.options.frames.lock=false;Atlas:UpdateLock();assert(AtlasFrameLockButton.normal.path=='unlocked')
    assert(popupOwners[AtlasSwitchDD] and AtlasFrameNextMapButton.glyph=='>')
    assert(AtlasFrameLockButton.normal.crop[1]==.1 and AtlasFrameLFGButton.normal.path=='meaningful-glyph')
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
            w.highlight=w.frame:CreateTexture(nil,'HIGHLIGHT')
            w.SetValue=function(self,v)self.checked=v;self.check.shown=v;return 'value'end
            w.SetDisabled=function(self,v)self.disabled=v;return 'disabled'end
        elseif kind=='Dropdown-Item-Toggle'then
            w.check=w.frame:CreateTexture(nil,'OVERLAY');w.highlight=w.frame:CreateTexture(nil,'OVERLAY');w.useHighlight=true;w.value=true
            w.SetValue=function(self,v)self.value=v;self.check.shown=v end
            w.SetDisabled=function(self,v)self.disabled=v end
            w.frame.scripts.OnClick=function()w.value=not w.value;w.check.shown=w.value;return 'toggle'end
        elseif kind=='Dropdown'then
            w.dropdown=frame('Frame',nil,w.frame);w.dropdown:CreateTexture(nil,'ARTWORK')
            w.button=button(nil,w.dropdown);w.button:CreateTexture(nil,'ARTWORK')
            w.pullout={frame=frame('Frame'),items={},Open=function()return 'open'end}
        elseif kind=='Slider'then
            w.slider=frame('Slider',nil,w.frame);w.slider.orientation='HORIZONTAL';w.slider.thumb=w.slider:CreateTexture(nil,'ARTWORK')
            w.SetDisabled=function(self,v)self.disabled=v;return 'slider disabled'end
            w.slider.range={0,100};w.editbox=frame('EditBox',nil,w.frame)
        elseif kind=='InlineGroup'then
            local border=frame('Frame',nil,w.frame);border.backdrop={edgeFile='heavy-native'}
            w.content=frame('Frame',nil,border)
        elseif kind=='TreeGroup'then
            w.treeframe=frame('Frame',nil,w.frame);w.treeframe.backdrop={edgeFile='heavy-tree'}
            w.border=frame('Frame',nil,w.frame);w.border.backdrop={edgeFile='heavy-content'}
            w.scrollbar=frame('Slider',nil,w.treeframe);w.scrollbar.thumb=w.scrollbar:CreateTexture(nil,'ARTWORK')
            w.scrollbar.ScrollUpButton=button(nil,w.scrollbar);w.scrollbar.ScrollDownButton=button(nil,w.scrollbar)
            w.buttons={button(nil,w.treeframe),button(nil,w.treeframe)}
            for _,b in ipairs(w.buttons)do b.highlight=b:CreateTexture(nil,'HIGHLIGHT');b.icon=b:CreateTexture(nil,'ARTWORK');b.selected=false end
            w.RefreshTree=function(self)self.buttons[1].selected=self.selection==1;self.buttons[2].selected=self.selection==2;return 'tree',nil,3 end
        elseif kind=='Button'then
            w.frame.highlight=w.frame:CreateTexture(nil,'HIGHLIGHT')
        end
        return w
    end
    local group=widget('BlizOptionsGroup');local check=widget('CheckBox');local dropdown=widget('Dropdown')
    local slider=widget('Slider');local action=widget('Button');local sliderW,sliderH=slider.slider:GetSize()
    local inline=widget('InlineGroup');local tree=widget('TreeGroup');tree.selection=1;tree:RefreshTree()
    group.children={check,dropdown,slider,action,inline,tree};Atlas.optionsFrames.General=group
    modules.Atlas.refresh() -- Bind the owned category's first-show hook.
    local a,b,id=dialog:FeedGroup('Atlas',{},group);assert(a=='feed'and b==nil and id=='Atlas')
    assert(check.check.alpha==0 and check.checkbg.alpha==0 and #check.frame.regions==6)
    local box,mark=check.frame.regions[4],check.frame.regions[5]
    assert(box.w==14 and mark.w==8 and mark.alpha==1)
    assert(slider.slider.thumb.alpha==0 and slider.slider.regions[3].w==10 and slider.slider.regions[2].h==2 and slider.slider.range[2]==100)
    assert(slider.slider.w==sliderW and slider.slider.h==sliderH and action.frame.highlight.alpha==0 and check.highlight.alpha==0)
    assert(not inline.content.parent.backdrop and not tree.treeframe.backdrop and not tree.border.backdrop)
    local nav=tree.buttons[1]
    assert(nav.highlight.alpha==0 and nav.icon.alpha==1 and nav.regions[4].color[1]==accent[1] and nav.regions[4].alpha==1)
    tree.selection=2;local ta,tb,tc=tree:RefreshTree();assert(ta=='tree' and tb==nil and tc==3)
    assert(nav.regions[4].alpha==0 and tree.buttons[2].regions[4].alpha==1)
    local nn,hh,rr,ff,cc=created,hooks,reads,fontWrites,colorWrites
    for _=1,1000 do check:SetValue(true);check:SetDisabled(false)end
    -- First disabled flag normalisation may repaint once.
    assert(created==nn and hooks==hh and reads==rr and fontWrites==ff and colorWrites<=cc+1)
    local warmObjects,warmHooks,warmReads,warmFonts,warmAssets=created,hooks,reads,fontWrites,assetReads
    for _=1,1000 do
        AtlasFrame:Show();Atlas:RefreshMap();tree:RefreshTree();dialog:FeedGroup('Atlas',{},group)
    end
    assert(created==warmObjects and hooks==warmHooks and reads==warmReads and fontWrites==warmFonts and assetReads==warmAssets,'warm open/options/navigation scans or allocations')
    slider:SetDisabled(true);assert(slider.slider.regions[3].color[1]==.4)
    check:SetValue(false);assert(mark.alpha==0)
    check:SetValue(true);check:SetDisabled(true);assert(mark.color[1]==.4 and mark.alpha==1)
    local pullItem=widget('Dropdown-Item-Toggle');dropdown.pullout.items={pullItem}
    assert(dropdown.pullout:Open()=='open' and pullItem.check.alpha==0 and pullItem.highlight.alpha==0)
    assert(pullItem.frame.scripts.OnClick()=='toggle' and not pullItem.value)
    pullItem:SetValue(true);assert(pullItem.value and pullItem.check.alpha==0)
    pullItem:SetDisabled(true);assert(pullItem.frame.regions[5].color[1]==.4)
    pullItem:SetDisabled(false)
    gui:Release(group)
    assert(check.check.alpha==1 and check.checkbg.alpha==1 and mark.alpha==0 and pullItem.check.alpha==1)
    assert(slider.slider.thumb.alpha==1 and slider.slider.regions[3].alpha==0 and action.frame.highlight.alpha==1)
    assert(inline.content.parent.backdrop.edgeFile=='heavy-native' and tree.treeframe.backdrop.edgeFile=='heavy-tree')
    assert(nav.highlight.alpha==1 and nav.regions[4].alpha==0)
    tree:RefreshTree();assert(nav.highlight.alpha==1 and nav.regions[4].alpha==0)
    -- Foreign use after release must not be restyled by the old callbacks.
    check:SetValue(true);assert(check.check.alpha==1 and mark.alpha==0)
    local foreign=widget('BlizOptionsGroup');local before=reads
    dialog:FeedGroup('OtherAddon',{},foreign);assert(reads==before and #foreign.frame.regions==0)
    dialog:FeedGroup('Atlas',{},group);assert(check.check.alpha==0)
    dropdown.pullout:Open();assert(pullItem.check.alpha==0)
    dialog:FeedGroup('OtherAddon',{},group);assert(check.check.alpha==1 and mark.alpha==0 and pullItem.check.alpha==1)
    group.frame:Show();assert(check.check.alpha==1 and mark.alpha==0)
    dialog:FeedGroup('Atlas',{},group)
    enabled=false;modules.Atlas.refresh();gui:Release(check);assert(check.check.alpha==1 and nav.highlight.alpha==1)
    local late=widget('CheckBox');group.children[1]=late
    dialog:FeedGroup('Atlas',{},group);assert(late.check.alpha==1)
    enabled=true;combat=true;dialog:FeedGroup('Atlas',{},group);assert(late.check.alpha==1)
    combat=false
    for _,e in ipairs(events)do if e.events and e.events.PLAYER_REGEN_ENABLED then e.scripts.OnEvent(e,'PLAYER_REGEN_ENABLED')end end
    -- Open Settings groups are discovered at combat recovery without invoking native data actions.
    assert(late.check.alpha==0)
    face='changed-font';accent={.9,.1,.2}
    for _,fn in ipairs(looks)do fn()end
    assert(AtlasEntry1.Text.font[1]==face and late.frame.regions[5].color[1]==.9)
    assert(late.check.font[1]=='native' and #errors==0,table.concat(errors,'; '))
    Atlas.optionsFrames={};AtlasEJLootFrame=nil;Atlas=nil;AtlasLoot=nil;GetFileIDFromPath=nil
    print('PASS: Atlas '..client..': main/small/large map tiles/pins/geometry, dropdown ownership, native actions/colours, legend pooling, options release/foreign reuse, combat/theme/toggles and optional EJ handling')
    print('BENCH Atlas '..client..' mock: 1000 legend updates and 1000 warm open/map/options/tree cycles: objects/hooks/hierarchy reads/font writes=0; 1000 stable option state updates: same zero counts, at most one normalisation colour write')
end
