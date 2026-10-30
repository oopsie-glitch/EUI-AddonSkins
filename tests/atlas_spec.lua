-- Source-shaped Atlas c847580: three eager UI roots, fixed legend budget,
-- duplicate root map tiles, LibDD controls and borrowed AceConfig widgets.
for _, client in ipairs({'Retail','Forever'}) do
    local created,hooks,reads,fontWrites,colorWrites=0,0,0,0,0
    local geometryWrites,textureWrites=0,0
    local looks,events,modules,errors={},{},{},{}
    local fileIDs,assetReads={},0
    GetFileIDFromPath=function(path)assetReads=assetReads+1;return fileIDs[path:lower():gsub('%.blp$','')]end
    CreateColor=function(r,g,b,a)return {r,g,b,a}end
    local enabled,combat=true,false
    local accent={.2,.7,.4};local face='eui-font';local panel={.05,.06,.07,.9}
    local function anchors(o)
        function o:SetAllPoints(f) geometryWrites=geometryWrites+1;self.all=f end
        function o:SetPoint(...) geometryWrites=geometryWrites+1;self.points=self.points or {};self.points[#self.points+1]={...}end
        function o:GetPoint()
            local p=self.points and self.points[1]
            if not p then return end
            if type(p[2])=='number' then return p[1],self.parent,p[1],p[2],p[3] end
            return table.unpack(p)
        end
        function o:ClearAllPoints()geometryWrites=geometryWrites+1;self.points={}end
        function o:SetSize(w,h)geometryWrites=geometryWrites+1;self.w,self.h=w,h end
        function o:GetSize()return self.w or 10,self.h or 10 end
        function o:SetWidth(v)geometryWrites=geometryWrites+1;self.w=v end
        function o:SetHeight(v)geometryWrites=geometryWrites+1;self.h=v end
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
        function t:SetTexture(v)textureWrites=textureWrites+1;self.path=v end
        function t:SetAtlas(v)self.atlas=v end
        function t:SetDesaturated(v)self.desaturated=v end
        function t:AddMaskTexture(mask)self.mask=mask end
        function t:GetDrawLayer()return self.layer end
        function t:SetColorTexture(...)colorWrites=colorWrites+1;self.color={...}end
        function t:SetVertexColor(...)self.color={...}end
        if client=='Retail' then
            function t:SetGradient(direction,first,last) self.gradient={direction,first,last} end
        else
            function t:SetGradientAlpha(direction,...) self.gradient={direction,{...}} end
        end
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
        function f:GetScript(key)return self.scripts[key]end
        function f:SetHitRectInsets(...)self.hitInsets={...}end
        function f:GetText()return self.value or ''end
        function f:SetText(v)self.value=v;if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self,true)end end
        function f:HasFocus()return self.focused end
        function f:SetFocus()self.focused=true;if self.scripts.OnEditFocusGained then self.scripts.OnEditFocusGained(self)end end
        function f:ClearFocus()self.focused=false;if self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self)end end
        function f:SetTextColor(...)self.inputColor={...}end
        function f:Enable()self.enabled=true;if self.scripts.OnEnable then self.scripts.OnEnable(self)end end
        function f:Disable()self.enabled=false;if self.scripts.OnDisable then self.scripts.OnDisable(self)end end
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
    local S={GetAccentColor=function()return table.unpack(accent)end,GetPanelColor=function()return table.unpack(panel)end,
        GetFont=function()return face,''end,OnLooksChanged=function(fn)looks[#looks+1]=fn end}
    local function paint(f,kind,keep)
        if not f["painted"..kind]then
            f["painted"..kind]=true
            local retained={};for _,key in ipairs(keep or {})do retained[f[key]]=true end
            for _,r in ipairs(f.regions)do if r.kind=='Texture' and not retained[r]then r:SetAlpha(0)end end
            f.apiFill=f:CreateTexture(nil,'BACKGROUND');f.apiFill:SetColorTexture(.05,.06,.07,.9);f.apiFill:SetAllPoints(f)
            if kind~='edit'then
                f.apiHover=f:CreateTexture(nil,'HIGHLIGHT');f.apiHover:SetColorTexture(1,1,1,.1);f.apiHover:SetAllPoints(f)
                f.apiBorder=frame('Frame',nil,f)
                for i=1,4 do local e=f.apiBorder:CreateTexture(nil,'BORDER');e:SetSize(i<3 and 1 or 20,i<3 and 20 or 1)end
            end
        end
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
    S.StateButtonLabel=function(f)
        local function state()f.label:SetTextColor(f:IsEnabled() and 1 or .5,1,1,1)end
        f:HookScript('OnEnable',state);f:HookScript('OnDisable',state);state()
    end
    S.ScrollBar=function(f)paint(f,'scroll')end
    S.Font=function(t,r,g,b)local _,size=t:GetFont();t:SetFont(face,size,'');if r then t:SetTextColor(r,g,b,1)end end
    local ns={IsEnabled=function()return enabled end}
    ns.RegisterModule=function(id,label,available,install)modules[id]={available=available,install=install}end
    local popupOwners={}
    ns.BindPopupOwner=function(_,_,f,options)popupOwners[f]=options or true end
    assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins',ns)
    assert(loadfile(os.getenv('ATLAS_SKIN_PATH') or 'EUIAddonSkins/Skins/Atlas.lua'))('EUIAddonSkins',ns)
    Atlas=nil;AtlasLoot={GUI={}};assert(not modules.Atlas.available(),'AtlasLoot wrongly activates Atlas')
    Atlas={LocName='Atlas',optionsFrames={},ScrollBar_Update=function()return 'scroll',nil,4 end,
        RefreshMap=function(self)self:ScrollBar_Update();return 'map',nil,8 end,ToggleWindowSize=function()return 'size'end,
        ToggleLegendPanel=function()return 'legend'end,OpenOptions=function()return 'options'end,
        SetupOptions=function()end,RegisterModuleOptions=function()end}
    Atlas.db={profile={options={frames={lock=false}}}}
    Atlas.UpdateLock=function(self)
        for _,name in ipairs({'AtlasFrame','AtlasFrameSmall','AtlasFrameLarge'})do
            _G[name..'LockButton'].normal:SetTexture(self.db.profile.options.frames.lock and 'locked' or 'unlocked')
            _G[name..'LockButton'].pushed:SetTexture('native-pressed')
        end
        return 'lock',nil,6
    end
    ATLAS_HAS_EJ=client=='Retail';ATLAS_NUM_LINES=ATLAS_BENCHMARK and 26 or 2
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
        text(f)
        local close=button(name..'CloseButton',f);close:SetSize(20,20);close:SetPoint('TOPRIGHT',f,'TOPRIGHT',-2,-14)
        local options=button(name..'OptionsButton',f);options:SetSize(80,20);options:SetPoint('RIGHT',name..'LockButton','LEFT',6,1)
        for _,suffix in ipairs({'PrevMapButton','NextMapButton','SizeUpButton','SizeDownButton','CollapseButton','ExpandButton'})do button(name..suffix,f)end
        for _,suffix in ipairs({'LockButton','LFGButton','AdventureJournalMapButton','AdventureJournalButton','AtlasLootButton'})do
            local b=button(name..suffix,f);b.normal=b:CreateTexture(nil,'ARTWORK');b.normal:SetTexture('meaningful-glyph');b.normal:SetTexCoord(.1,.2,.3,.4)
            if suffix=='LockButton'then
                b:SetSize(36,36);b:SetPoint('RIGHT',close,'LEFT',6,0)
                b.pushed=b:CreateTexture(nil,'ARTWORK');b.pushed:SetTexture('native-lock-pressed')
                b.highlight=b:CreateTexture(nil,'HIGHLIGHT');b.highlight:SetTexture('native-lock-highlight')
                b.scripts.OnClick=function()Atlas.db.profile.options.frames.lock=not Atlas.db.profile.options.frames.lock;return Atlas:UpdateLock()end
            end
        end
        for _,suffix in ipairs({'DropDown','DropDownType'})do
            local d=frame('Frame',name..suffix,f);d.initialize=function()end;d.Label=text(d);d.Text=text(d)
            for _,side in ipairs({'Left','Middle','Right'})do d[side]=d:CreateTexture(nil,'ARTWORK')end
            d.Button=button(name..suffix..'Button',d);d.Button:SetSize(24,24);d.Button.normal=d.Button:CreateTexture(nil,'ARTWORK')
            d:SetSize(240,32);d.Button:SetPoint('TOPRIGHT',d,'TOPRIGHT',2,-1)
            d.openCount=0;d.Button.scripts.OnMouseDown=function(self,mouse)
                assert(self==d.Button,'native dropdown receiver changed')
                if self:IsEnabled() then d.openCount=d.openCount+1;d.lastMouse=mouse end
                return 'native dropdown',nil,9
            end
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
    AtlasSearchEditBox:SetSize(150,32);AtlasSearchEditBox:SetPoint('BOTTOMRIGHT',AtlasFrame,'BOTTOMRIGHT',-210,0)
    local nativeTextChanges=0
    AtlasSearchEditBox.scripts.OnTextChanged=function()nativeTextChanges=nativeTextChanges+1 end
    AtlasSearchEditBox.scripts.OnEnterPressed=function(self)self.searched=self:GetText();self:ClearFocus();return 'search native'end
    AtlasSearchEditBox.action=function(v)AtlasSearchEditBox.value=v;return 'input'end
    for _,n in ipairs({'AtlasSearchButton','AtlasSearchClearButton','AtlasSwitchButton'})do button(n,AtlasFrame)end
    AtlasScrollBarScrollBar=frame('Slider','AtlasScrollBarScrollBar',AtlasFrame)
    AtlasScrollBarScrollBar.thumb=AtlasScrollBarScrollBar:CreateTexture(nil,'ARTWORK')
    for _,suffix in ipairs({'ScrollUpButton','ScrollDownButton'})do button('AtlasScrollBarScrollBar'..suffix,AtlasScrollBarScrollBar)end
    AtlasSwitchDD=frame('Frame','AtlasSwitchDD',AtlasFrame)
    for i=1,ATLAS_NUM_LINES do local b=button('AtlasEntry'..i,AtlasFrame);b.Text=b.label;b.Highlight=b:CreateTexture(nil,'HIGHLIGHT');b.scripts.OnUpdate=function()return 'native tooltip'end end
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
    if ATLAS_BENCHMARK then
        local context={client=client,A=Atlas,S=S,ns=ns,module=modules.Atlas,events=events,
            root=AtlasFrame,gui=gui,dialog=dialog,errors=errors}
        context.counts=function()return {objects=created,hooks=hooks,hierarchy_reads=reads,
            font_writes=fontWrites,geometry_writes=geometryWrites,texture_writes=textureWrites,color_writes=colorWrites}end
        context.complete=function()
            for _,r in ipairs(chrome)do if r.pendingPath then r:SetTexture(r.pendingPath)end end
        end
        context.install=function()modules.Atlas.install(S,modules.Atlas)end
        ATLAS_BENCHMARK(context)
    else
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
        local f=_G[name];local globes,halves,lines=0,0,0
        for _,r in ipairs(f.regions)do
            if r.kind=='Texture' and r.path==nil then
                assert(r.layer=='BACKGROUND','surface must stay below native art')
                if r.gradient then
                    halves=halves+1
                    assert(r.sublevel==-8 and r.color[4]==1,'background must be opaque')
                    local grad=r.gradient
                    if client=='Retail' then
                        assert(grad[2][4]==1 and grad[3][4]==1)
                        if halves==1 then assert(grad[2][1]<grad[3][1],'centre must be lighter')
                        else assert(grad[2][1]>grad[3][1],'edge must be darker')end
                    else assert(grad[2][4]==1 and grad[2][8]==1)end
                elseif r.h==1 or r.w==1 then
                    lines=lines+1;assert(r.sublevel==-6,'section separators must stay on root')
                else
                    local header=r.sublevel==-7 and r.points[1][1]=='TOPLEFT' and r.points[2][3]=='TOPRIGHT' and r.points[2][5]==-80
                    local footer=r.sublevel==-7 and r.points[1][3]=='BOTTOMLEFT' and r.points[1][5]==35 and r.points[2][3]=='BOTTOMRIGHT'
                    assert(header or footer,
                        'large information-panel overlay returned')
                    assert(r.color[4]==1,'header/footer/logo must remain opaque')
                end
            end
            if r.w==32 and r.h==32 and r.crop and r.crop[1]==2/512 then
                globes=globes+1
                assert(r==nativeGlobes[name] and r.mask,'round globe must reuse original and portrait mask')
                assert(r.crop[2]==74/512 and r.points[1][4]==16 and r.points[1][5]==-9)
            end
        end
        assert(halves==2 and globes==1,'one adjoining background and one original globe expected')
        assert(lines==(name=='AtlasFrame' and 2 or 0),'only main information panel needs separators')
        assert(f:GetFrameLevel()==rootMetadata[f].level and f:GetFrameStrata()==rootMetadata[f].strata)
    end
    Atlas.db.profile.options.frames.lock=true
    local la,lb,lc=Atlas:UpdateLock();assert(la=='lock' and lb==nil and lc==6)
    assert(AtlasFrameLockButton.normal.path:find('eui%-lock%-locked.png') and AtlasFrameLockButton.pushed.path==AtlasFrameLockButton.normal.path)
    Atlas.db.profile.options.frames.lock=false;Atlas:UpdateLock();assert(AtlasFrameLockButton.normal.path:find('eui%-lock%-unlocked.png'))
    assert(popupOwners[AtlasSwitchDD] and AtlasFrameNextMapButton.glyph=='>')
    assert(AtlasFrameLockButton.normal.crop[1]==0 and AtlasFrameLockButton.normal.crop[2]==1 and AtlasFrameLFGButton.normal.path=='meaningful-glyph')
    local lock=AtlasFrameLockButton
    assert(lock.normal.w==12 and lock.normal.h==16 and lock.highlight.alpha==0,'lock must use proportionate EUI art without native glow')
    assert(lock.pushed.points[1][4]==1 and lock.pushed.points[1][5]==-1)
    assert(lock.w==36 and lock.h==36 and lock.hitInsets[1]==6 and lock.hitInsets[2]==6)
    assert(AtlasFrameOptionsButton.hitInsets[2]==6)
    -- Native frames overlap by 6: the painted/hit ranges now remain disjoint.
    local lockLeft=80-6;local closeLeft=lockLeft+36-6
    assert(80-AtlasFrameOptionsButton.hitInsets[2]<=lockLeft+lock.hitInsets[1])
    assert(lockLeft+36-lock.hitInsets[2]<=closeLeft)
    lock.scripts.OnClick();assert(Atlas.db.profile.options.frames.lock and lock.normal.path:find('eui%-lock%-locked.png'))
    lock.scripts.OnClick();assert(not Atlas.db.profile.options.frames.lock and lock.normal.path:find('eui%-lock%-unlocked.png'))
    for _,b in ipairs({AtlasFrameOptionsButton,AtlasFrameNextMapButton,AtlasSearchButton,lock})do
        assert(b.apiFill.color[4]==1 and b.apiFill.color[1]>panel[1],'owned buttons need opaque contrast')
        assert(b.apiFill.points[1][4]>=1 and b.apiFill.points[2][4]<=-1,'button paint protrudes')
        for _,e in ipairs(b.apiBorder.regions)do assert(e.color[4]==0,'owned decorative border should not cross neighbours')end
        b.apiFill:SetColorTexture(.02,.02,.02,.1);b.apiFill:SetAllPoints(b)
        assert(b.apiFill.color[4]==1 and b.apiFill.points[1][4]>=1,'native API repaint lost containment')
        b:Disable();assert(b.apiHover.alpha==0);b:Enable();assert(b.apiHover.alpha==1)
    end
    local dropdown=AtlasFrameDropDown
    assert(dropdown.mouse and dropdown.hitInsets[1]==16 and dropdown.hitInsets[3]==1 and dropdown.hitInsets[4]==7)
    dropdown.scripts.OnMouseDown(dropdown,'LeftButton');assert(dropdown.openCount==1 and dropdown.lastMouse=='LeftButton')
    local a,b,c=dropdown.Button.scripts.OnMouseDown(dropdown.Button,'LeftButton');assert(a=='native dropdown'and b==nil and c==9 and dropdown.openCount==2)
    dropdown.scripts.OnMouseDown(dropdown,'RightButton');assert(dropdown.openCount==2)
    dropdown.scripts.OnEnter(dropdown);dropdown.Button:Disable();assert(dropdown.regions[#dropdown.regions-1].alpha==0);dropdown.scripts.OnMouseDown(dropdown,'LeftButton');assert(dropdown.openCount==2);dropdown.Button:Enable()
    enabled=false;dropdown.scripts.OnMouseDown(dropdown,'LeftButton');assert(dropdown.openCount==2);enabled=true
    combat=true;dropdown.scripts.OnMouseDown(dropdown,'LeftButton');assert(dropdown.openCount==2);combat=false
    assert(dropdown.favorite.scripts.OnClick()=='native' and dropdown.openCount==2,'distinct child action changed')
    local selectorAccent=dropdown.regions[#dropdown.regions]
    assert(selectorAccent.h==1 and selectorAccent.color[1]==accent[1] and selectorAccent.color[4]==.65)
    assert(selectorAccent.points[1][2]==selectorAccent.points[2][2] and selectorAccent.points[1][3]=='BOTTOMLEFT' and selectorAccent.points[2][3]=='BOTTOMRIGHT')
    dropdown.Button:Disable();assert(selectorAccent.color[1]==.4);dropdown.Button:Enable();assert(selectorAccent.color[1]==accent[1])
    local search=AtlasSearchEditBox;local hint,edge
    for _,r in ipairs(search.regions)do
        if r.kind=='FontString' and r.text=='Search' then hint=r end
        if r.layer=='BORDER' then edge=r end
    end
    assert(hint and hint.shown and edge and search.w==150 and search.h==32)
    search:SetFocus();assert(not hint.shown and edge.color[1]==accent[1])
    search:SetText('boss');assert(nativeTextChanges==1 and not hint.shown)
    assert(search.scripts.OnEnterPressed(search)=='search native' and search.searched=='boss' and not search.focused)
    search:SetText('');assert(nativeTextChanges==2 and hint.shown and edge.color[1]==.25)
    local objs,hookCount,walks,fontCount=created,hooks,reads,fontWrites
    for _=1,1000 do search:SetFocus();search:SetText('typed');search:ClearFocus()end
    assert(created==objs and hooks==hookCount and reads==walks and fontWrites==fontCount,'search events must stay local')
    search:SetText('');assert(hint.shown)
    assert(search.inputColor[1]==.92 and search.apiFill.points[1][5]==-4 and search.apiFill.points[2][5]==4)
    assert(world.Border.alpha==0 and world.Icon.alpha==1)
    local function profile(fn)
        local names={}
        debug.sethook(function(event)
            if event=='call' then
                local info=debug.getinfo(2,'Sn')
                if info.source:match('[/\\]Atlas%.lua$')then local key=info.name or '(closure)';names[key]=(names[key]or 0)+1 end
            end
        end,'c')
        fn();debug.sethook();return names
    end
    local visits=profile(function()local a,b,c=Atlas:RefreshMap();assert(a=='map'and b==nil and c==8)end)
    assert(visits.Entry==ATLAS_NUM_LINES,'map completion styled the legend more than once')
    visits=profile(function()AtlasFrame:Hide();AtlasFrame:Show()end)
    assert(not visits.Button and not visits.IconButton and not visits.Lock,'warm reopen revisits completed eager controls')
    local beforeClosed={created,hooks,reads,fontWrites,geometryWrites,colorWrites}
    AtlasFrame:Hide()
    for _=1,1000 do
        for _,event in ipairs(events)do
            if event.events and event.events.ADDON_LOADED then event.scripts.OnEvent(event,'ADDON_LOADED','UnrelatedAddon')end
        end
        Atlas:ScrollBar_Update()
    end
    assert(created==beforeClosed[1] and hooks==beforeClosed[2] and reads==beforeClosed[3] and fontWrites==beforeClosed[4] and geometryWrites==beforeClosed[5] and colorWrites==beforeClosed[6],'closed Atlas performs unrelated cosmetic work')
    visits=profile(function()Atlas:ScrollBar_Update()end);assert(not visits.Entry,'closed legend walked rows')
    AtlasFrame:Show()
    local n,r,fw,c=created,reads,fontWrites,hooks
    for _=1,1000 do local a,b,v=Atlas:ScrollBar_Update();assert(a=='scroll'and b==nil and v==4)end
    assert(created==n and reads==r and fontWrites==fw and hooks==c,'warm legend updates do skin discovery')
    assert(AtlasEntry1.scripts.OnUpdate()=='native tooltip' and AtlasEntry1.scripts.OnClick()=='native')
    local newEntry=button('AtlasEntry2',AtlasFrame);newEntry.Text=newEntry.label
    Atlas:ScrollBar_Update();assert(newEntry.Text.font[1]==face,'same-count legend replacement missed')
    newEntry.Text=text(newEntry);Atlas:ScrollBar_Update();assert(newEntry.Text.font[1]==face,'reused row text replacement missed')
    local lateChrome=AtlasFrame:CreateTexture(nil,'ARTWORK');lateChrome:SetTexture('AtlasFrame-TopRight.blp')
    AtlasFrame:Hide();AtlasFrame:Show();assert(lateChrome.alpha==0,'changed root decoration escaped cached reopening')
    local replacement=button('AtlasFrameOptionsButton',AtlasFrame);modules.Atlas.refresh()
    assert(replacement.apiFill and replacement.hitInsets[2]==6,'explicit refresh must rediscover owned control replacements')
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
    local warmGeometry,warmTextures=geometryWrites,textureWrites
    for _=1,1000 do
        AtlasFrame:Show();Atlas:RefreshMap();tree:RefreshTree();dialog:FeedGroup('Atlas',{},group)
    end
    assert(created==warmObjects and hooks==warmHooks and reads==warmReads and fontWrites==warmFonts and assetReads==warmAssets,'warm open/options/navigation scans or allocations')
    assert(geometryWrites==warmGeometry and textureWrites==warmTextures,'warm controls rewrote geometry or icon textures')
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
    local beforeTheme=created
    search:SetFocus()
    panel={.12,.10,.08,0};face='changed-font';accent={.9,.1,.2}
    for _,fn in ipairs(looks)do fn()end
    assert(created==beforeTheme,'theme change must reuse surface textures')
    assert(edge.color[1]==accent[1] and edge.color[2]==accent[2],'focused search must follow accent')
    assert(selectorAccent.color[1]==accent[1] and selectorAccent.color[2]==accent[2],'selector bars must follow accent')
    assert(AtlasSearchButton.apiFill.color[4]==1 and AtlasSearchButton.apiFill.color[1]>panel[1])
    search:ClearFocus()
    for _,r in ipairs(AtlasFrame.regions)do
        if r.gradient then
            assert(r.color[4]==1,'EUI transparent panel setting must not fade Atlas surface')
            if client=='Retail' then assert(r.gradient[2][1]>=.12 and r.gradient[3][1]>=.12)end
        end
    end
    AtlasFrame:SetAlpha(.4);modules.Atlas.refresh()
    assert(AtlasFrame.alpha==.4,'explicit native whole-window opacity must survive refresh')
    assert(AtlasEntry1.Text.font[1]==face and late.frame.regions[5].color[1]==.9)
    assert(late.check.font[1]=='native' and #errors==0,table.concat(errors,'; '))
    Atlas.optionsFrames={};AtlasEJLootFrame=nil;Atlas=nil;AtlasLoot=nil;GetFileIDFromPath=nil
    print('PASS: Atlas '..client..': main/small/large map tiles/pins/geometry, dropdown ownership, native actions/colours, legend pooling, options release/foreign reuse, combat/theme/toggles and optional EJ handling')
    print('BENCH Atlas '..client..' mock: 1000 legend updates and 1000 warm open/map/options/tree cycles: objects/hooks/hierarchy reads/font/geometry/icon-texture writes=0; 1000 stable option state updates: same zero counts, at most one normalisation colour write')
    end
end
