-- Source-shaped AWQ canvas and AceDB Profiles. No configuration action is executed.
local timers,events,errors,modules,looks={},{},{},{},{}
local enabled,combat,accent=true,false,.7
local ns={IsEnabled=function()return enabled end,AttachAccent=function(_,f)f.accent=true end}
function ns.RegisterModule(id,_,available,install)modules[id]={available=available,install=install}end
C_Timer={}
unpack=table.unpack
C_Timer.After=function(_,fn)timers[#timers+1]=fn end
InCombatLockdown=function()return combat end
geterrorhandler=function()return function(err)errors[#errors+1]=err end end
hooksecurefunc=function(obj,key,fn)local old=obj[key];obj[key]=function(...)local r=table.pack(old(...));fn(...);return table.unpack(r,1,r.n)end end
local function flush()local n=0;while #timers>0 do local t=timers;timers={};for _,fn in ipairs(t)do fn()end;n=n+1;assert(n<20,'Myslot refresh loop')end end
local writes,objects,pixelCalls=0,0,0
local effectiveScale=.711111
PixelUtil={GetNearestPixelSize=function(_,scale)pixelCalls=pixelCalls+1;return 1/scale end}
local function region(kind)
 local r={kind=kind or'Texture',alpha=1,font={'native',12,''},color={1,.82,0,1},text=''}
 function r:GetObjectType()return self.kind end
 function r:SetAlpha(v)self.alpha=v end
 function r:GetAlpha()return self.alpha end
 function r:IsShown()return self.shown~=false end
 function r:Show()self.shown=true end
 function r:Hide()self.shown=false end
 function r:SetShown(v)self.shown=v end
 function r:SetColorTexture(...)self.color={...}end
 function r:SetVertexColor(...)self.color={...}end
 function r:GetVertexColor()return table.unpack(self.color)end
 function r:SetSize(w,h)self.w,self.h=w,h end
 function r:GetWidth()return self.w or 16 end
 function r:GetHeight()return self.h or 16 end
 function r:SetHeight(h)self.h=h end
 function r:SetWidth(w)self.w=w end
 function r:SetAllPoints()end
 function r:SetPoint(...)self.point={...}end
 function r:GetPoint()return table.unpack(self.point or{})end
 function r:ClearAllPoints()self.point=nil end
 function r:SetRotation(v)self.rotation=v end
 function r:SetTexture(v)self.path=v;self.atlas=nil end
 function r:GetTexture()return self.path end
 function r:SetAtlas(v)self.atlas=v end
 function r:GetAtlas()return self.atlas end
 function r:GetDrawLayer()return self.layer end
 function r:SetText(v)self.text=v;return 'text-native'end
 function r:GetText()return self.text end
 function r:GetFont()return table.unpack(self.font)end
 function r:SetFont(...)self.font={...};writes=writes+1 end
 function r:SetTextColor(...)self.color={...}end
 function r:GetTextColor()return table.unpack(self.color)end
 return r
end
local function frame(kind,parent)
 objects=objects+1
 local f={kind=kind or'Frame',parent=parent,regions={},children={},hooks={},scripts={},shown=true,enabled=true,points={},w=24,h=24}
 function f:GetObjectType()return self.kind end
 function f:GetParent()return self.parent end
 function f:GetName()return self.name end
 function f:IsProtected()return self.protected end
 function f:IsForbidden()return false end
 function f:GetNumChildren()return #self.children end
 function f:GetChildren()return table.unpack(self.children)end
 function f:GetRegions()return table.unpack(self.regions)end
 function f:CreateTexture(_,layer)local r=region();r.layer=layer;r.parent=self;self.regions[#self.regions+1]=r;return r end
 function f:CreateFontString()local r=region('FontString');r.parent=self;self.regions[#self.regions+1]=r;return r end
 function f:GetFontString()return self.label end
 function f:HookScript(event,fn)local old=self.hooks[event];self.hooks[event]=function(...)if old then old(...)end;fn(...)end end
 function f:SetScript(event,fn)self.scripts[event]=fn end
 function f:GetScript(event)return self.scripts[event]end
 function f:RegisterEvent(event)self.events=self.events or{};self.events[event]=true end
 function f:IsShown()return self.shown end
 function f:IsVisible()return self.shown end
 function f:Show()self.shown=true;if self.scripts.OnShow then self.scripts.OnShow(self)end;if self.hooks.OnShow then self.hooks.OnShow(self)end end
 function f:Hide()self.shown=false;if self.hooks.OnHide then self.hooks.OnHide(self)end end
 function f:SetBackdrop(v)assert(not combat);self.backdrop=v end
 function f:GetBackdrop()return self.backdrop end
 function f:GetEffectiveScale()return effectiveScale end
 function f:GetFrameLevel()return 5 end
 function f:SetFrameLevel(v)self.level=v end
 function f:SetAllPoints()end
 function f:EnableMouse(v)self.mouse=v end
 function f:SetSize(w,h)self.w,self.h=w,h end
 function f:GetWidth()return self.w end
 function f:GetHeight()return self.h end
 function f:SetPoint(...)self.points[#self.points+1]={...}end
 function f:GetPoint()return table.unpack(self.points[1]or{})end
 function f:SetText(v)if self.label then self.label:SetText(v)end end
 function f:IsEnabled()return self.enabled end
 function f:Enable()self.enabled=true end
 function f:Disable()self.enabled=false end
 function f:SetEnabled(v)self.enabled=v end
 function f:IsMultiLine()return self.multiline end
 function f:GetFont()return table.unpack(self.font or{'native',12,''})end
 function f:SetFont(...)self.font={...};writes=writes+1 end
 function f:GetTextColor()return 1,1,1,1 end
 function f:SetText(v)self.content=v;return 'editor-native'end
 function f:GetText()return self.content end
 function f:SetTextInsets(...)self.insets={...}end
 function f:GetThumbTexture()return self.thumb end
 function f:GetOrientation()return'VERTICAL'end
 if parent then parent.children[#parent.children+1]=f end
 return f
end
CreateFrame=function(kind,_,parent)local f=frame(kind,parent);events[#events+1]=f;return f end
local function label(f,value)local t=f:CreateFontString();t:SetText(value);return t end
local function button(parent,text,callback)local f=frame('Button',parent);f.label=label(f,text);f.w=120;f.scripts.OnClick=callback;return f end
local S={GetFont=function()return'eui',''end,GetAccentColor=function()return accent,.5,.3 end,OnLooksChanged=function(fn)looks[#looks+1]=fn end}
S.Font=function(t,r,g,b)if t.SetFont then t:SetFont('eui',12,'')end;if r then t:SetTextColor(r,g,b)end end
S.Shell=function(f,opts)f.shell=opts end
S.Panel=function(f,opts)f.panel=true;f.panelOptions=opts end
S.Button=function(f,keys)f.button=true;f.keep=keys;local keep={};for _,key in ipairs(keys or{})do keep[f[key]]=true end;for _,r in ipairs(f.regions)do if r.kind=='Texture'and not keep[r]then r.alpha=0 end end end
S.Dropdown=function(f)S.Button(f);f.dropdown=true;f.arrow=f:CreateTexture(nil,'OVERLAY');f.arrow:SetAtlas('Azerite-PointingArrow')end
S.Checkbox=function(f,options)f.checkbox=true;f.checkboxOptions=options end
S.PageButton=function(f,glyph)f.glyph=glyph;S.Button(f)end
S.StateButtonLabel=function()end
S.EditBox=function(f,opts)f.input=opts end
S.ScrollBar=function(f)f.scroll=true end
S.FadeNineSlice=function()end
local refreshes,questReads,clicks,hookCount=0,0,0,0
local oldHook=hooksecurefunc
hooksecurefunc=function(...)hookCount=hookCount+1;return oldHook(...)end
local canvas=frame();canvas.shown=false
canvas.OnRefresh=function()refreshes=refreshes+1;return 'refresh-native',nil,8 end
local config={OnEnable=function()end}
local quest={awqDisplayMode=8,InitQuestLogTab=function()end,InitQuestLogFrames=function()end}
AngrierWorldQuests={GetModule=function(_,name)return name=='ConfigModule'and config or name=='QuestFrameModule'and quest end}
local questRoot=frame();local questCheck=frame('CheckButton',questRoot)
questCheck.Text=label(questCheck,'Quest row');questCheck.configKey='do-not-skin'
questRoot.GetChildren=function()questReads=questReads+1;error('quest tree scan')end
local tab,foreignTab=frame(),frame();tab.displayMode=8;foreignTab.displayMode=1
QuestMapFrame={TabButtons={foreignTab,tab},ContentFrames={[8]=questRoot},displayMode=1}
tab.Icon=tab:CreateTexture();tab.Icon:SetTexture('trophy');tab.SelectedTexture=tab:CreateTexture()
tab.SetChecked=function(self,v)self.checked=v;self.Icon:SetVertexColor(.6,.6,.6);return 'checked-native',nil,7 end
tab.scripts.OnMouseUp=function()clicks=clicks+1;return 'click-native'end
Settings={RegisterCanvasLayoutCategory=function()return 'registered-native'end,GetCategory=function()return{}end}
SettingsPanel={GetLayout=function()error('private layout')end,DisplayLayout=function()canvas:OnRefresh()end,DisplayCategory=function()end}
local profiles={type='BlizOptionsGroup',frame=frame(),children={}}
local other={type='BlizOptionsGroup',frame=frame(),children={}}
local function widget(kind,parent,text)
 local f=frame('Button');f.label=label(f,text or kind)
 local w={type=kind,frame=f,text=f.label,children={}}
 if parent then parent.children[#parent.children+1]=w end
 return w
end
local action=widget('Button',profiles,'Reset Profile');local nativeArt=action.frame:CreateTexture()
local foreign=widget('Button',other,'Another addon')
local dropdown=widget('Dropdown',profiles,'Existing');dropdown.dropdown=frame();dropdown.button=frame('Button',dropdown.dropdown)
dropdown.button:CreateTexture()
dropdown.pullout={frame=frame(),items={},Open=function(self)self.frame:Show();return 'pullout-native'end}
dropdown.pullout.frame:CreateTexture()
local item=widget('Dropdown-Item-Toggle',nil,'Default');dropdown.pullout.items={item}
local edit=widget('EditBox',profiles,'New');edit.editbox=frame('EditBox');edit.editbox:CreateTexture()
local gui={Release=function(_,w)w.released=true;return 'release-native',nil,9 end}
local dialog={BlizOptions={['AWQ-Profiles']={profiles}},FeedGroup=function()return 'feed-native',nil,6 end}
LibStub=function(name)return name=='AceGUI-3.0'and gui or name=='AceConfigDialog-3.0'and dialog end
local lists=0
ns.BindPopupOwner=function()end
ns.BindPopupList=function(_,_,owner,list)assert(owner==AngrierWorldQuestsConfigDropDown1 and list);lists=lists+1 end
local manager={OpenMenu=function(self,owner)self.list={GetOwnerRegion=function()return owner end};return 'menu-native'end,
GetOpenMenu=function(self)return self.list end}
Menu={GetManager=function()return manager end}
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins',ns)
assert(loadfile('EUIAddonSkins/Skins/AngrierWorldQuests.lua'))('EUIAddonSkins',ns)
local m=modules.AngrierWorldQuests;assert(m.available());m.install(S,m)
assert(tab.button and not foreignTab.button and not questCheck.checkbox and questReads==0)
local a,b,c=tab:SetChecked(true);assert(a=='checked-native'and b==nil and c==7)
assert(tab.Icon.color[1]==accent and tab.SelectedTexture.alpha==0 and tab.Icon.path=='trophy')
assert(tab.scripts.OnMouseUp()=='click-native'and clicks==1)
assert(action.text.color[1]>.8 and nativeArt.alpha==0 and foreign.text.font[1]=='native')
assert(Settings.RegisterCanvasLayoutCategory(canvas,'AngrierWorldQuests')=='registered-native')
local check=frame('CheckButton',canvas);check.configKey='onlyCurrentZone';check.Text=label(check,'Only current zone')
check.GetCheckedTexture=function()return check.mark end;check.mark=check:CreateTexture()
check.GetChecked=function(self)return self.checked end
check.SetChecked=function(self,v)self.checked=v end
check.scripts.OnClick=function()clicks=clicks+1;return 'setting-native'end
local dd=frame('Button',canvas);dd.SetupMenu=function()end
dd.EnableRegenerateOnResponse=function(self)self.shouldRegenerateOnResponse=true end
dd.GetMenuDescription=function(self)return self.description end
dd.UpdateToMenuSelections=function(self)
 self.Text.font={'native',12,''};self.Text:SetText(self.description and self.description.value or 'Name')
 if self.nativeArt then self.nativeArt:SetAlpha(1)end
 return 'selection-native',nil,17
end
dd.RegisterMenu=function(self,description)
 self.description=description
 if self.menu then self.menu:SetMenuDescription(description)end
 self:UpdateToMenuSelections();return 'register-native',nil,19
end
dd.OnMenuOpened=function()return 'opened-native'end
dd.configKey='sortMethod';dd.Text=label(dd,'Name');dd.Label=label(dd,'Sort order')
dd.nativeArt=dd:CreateTexture()
AngrierWorldQuestsConfigDropDown1=dd
local r,n,num=canvas:OnRefresh();assert(r=='refresh-native'and n==nil and num==8)
assert(check.children[1].checkbox and check.children[1].w==22 and dd.dropdown and check.Text.color[1]>.8)
check:SetChecked(true);assert(check.children[1].regions[#check.children[1].regions].shown)
check:SetChecked(false);assert(not check.children[1].regions[#check.children[1].regions].shown)
assert(check.scripts.OnClick()=='setting-native'and clicks==2)
local objectsBefore,writesBefore,hooksBefore=objects,writes,hookCount
for _=1,100 do canvas:OnRefresh();tab:SetChecked(false)end
assert(objects==objectsBefore and writes==writesBefore and hookCount==hooksBefore,'warm refresh repeated work')
assert(refreshes==101 and questReads==0 and not questCheck.checkbox)
manager:OpenMenu(dd);assert(lists==1)
manager:OpenMenu(foreign.frame);assert(lists==1)
assert(select(3,dialog:FeedGroup('Other',{},other))==6 and foreign.text.font[1]=='native')
assert(gui:Release(action)=='release-native'and nativeArt.alpha==1 and action.text.font[1]=='native')
dialog:FeedGroup('AWQ-Profiles',{},profiles);assert(nativeArt.alpha==0 and action.text.font[1]=='eui')
action.frame:Disable();assert(action.text.color[1]==.5)
action.frame:Enable();assert(action.text.color[1]>.8)
local no,nw=objects,writes
for _=1,100 do dialog:FeedGroup('AWQ-Profiles',{},profiles)end
assert(objects==no and writes==nw,'profiles repeated layers/font writes')
assert(dropdown.pullout:Open()=='pullout-native'and item.text.font[1]=='eui')
enabled=false
local h=hookCount;manager:OpenMenu(dd);canvas:OnRefresh();tab:SetChecked(true)
assert(lists==1 and hookCount==h)
assert(select(3,gui:Release(action))==9 and action.text.font[1]=='native','disabled release did not restore')
enabled=true;combat=true
local o,w=objects,writes;m.refresh();canvas:OnRefresh();assert(objects==o and writes==w)
combat=false;accent=.25;for _,fn in ipairs(looks)do fn()end
tab:SetChecked(true);assert(tab.Icon.color[1]==.25)
assert(#errors==0,table.concat(errors,'; '))
assert(questReads==0 and questCheck.Text.font[1]=='native')
print('PASS: AWQ tab/options/Profiles; native actions/returns, pool restoration, menus, late controls, theme/combat/toggle guards')
print('BENCH AWQ 100 warm canvas refreshes: objects=0 font_writes=0 new_hooks=0 quest_tree_reads=0 (mock)')

-- The second alpha opts into AWQ-owned row checkbox cosmetics only.
local poolRows={}
AngrierWorldQuestsHeader={titleFramePool={EnumerateActive=function()return ipairs(poolRows)end}}
-- FramePool EnumerateActive yields frames as iterator keys.
AngrierWorldQuestsHeader.titleFramePool.EnumerateActive=function()
 local i=0;return function()i=i+1;return poolRows[i]end
end
quest.QuestLog_Update=function()return 'quests-native',nil,12 end
m.refresh() -- bind late method
local function questRow(tracked)
 local row=frame('Button');row.Checkbox=frame('Frame',row)
 row.Checkbox.CheckMark=row.Checkbox:CreateTexture();row.Checkbox.CheckMark.shown=tracked
 row.scripts.OnClick=function()return 'track-native'end
 poolRows[#poolRows+1]=row;return row
end
local first=questRow(true);local second=questRow(false)
local qr,qn,qv=quest:QuestLog_Update();assert(qr=='quests-native'and qn==nil and qv==12)
local box=first.Checkbox;local host=box.children[1];local mark=host.regions[#host.regions]
assert(host.checkbox and host.mouse==false and mark.shown and box.CheckMark.alpha==0)
assert(second.Checkbox.children[1].regions[#second.Checkbox.children[1].regions].shown==false)
assert(first.scripts.OnClick()=='track-native'and questCheck.Text.font[1]=='native')
box.CheckMark:Hide();assert(not mark.shown)
box.CheckMark:Show();assert(mark.shown)
local o,w,h=objects,writes,hookCount
for _=1,100 do quest:QuestLog_Update();box.CheckMark:Show()end
assert(objects==o and writes==w and hookCount==h,'warm quest refresh allocated or duplicated hooks')
local third=questRow(true);quest:QuestLog_Update();assert(third.Checkbox.children[1].checkbox)
enabled=false;local skipped=questRow(true);quest:QuestLog_Update();assert(#skipped.Checkbox.children==0)
enabled=true;combat=true;quest:QuestLog_Update();assert(#skipped.Checkbox.children==0)
box.CheckMark:Hide();assert(mark.shown) -- combat postpones cosmetic updates
combat=false;m.refresh();assert(skipped.Checkbox.children[1].checkbox and not mark.shown)
assert(#errors==0,table.concat(errors,'; '))
print('PASS: AWQ-only pooled quest checkboxes, native tracking visibility/actions, late rows, warm reuse, disabled/combat guards')

-- A continuous outer rectangle and inset fill keep every edge inside bounds
-- at fractional UI scales; neither native geometry nor hit areas are resized.
local settingsHost=check.children[1]
local edge,fill=settingsHost.regions[1],settingsHost.regions[2]
assert(edge.point[1]=='BOTTOMRIGHT'and edge.point[4]==-4 and edge.point[5]==4)
assert(fill.point[1]=='BOTTOMRIGHT'and fill.point[4]<0 and fill.point[5]>0)
local function assertScale(scale)
 effectiveScale=scale;m.refresh()
 assert(math.abs(fill.point[5]*scale-1)<.00001,'outline is not one physical pixel')
 assert(settingsHost.w==22 and check.w==24 and check.h==24,'native hit area changed')
end
for _,scale in ipairs({.533333,.64,.711111,.9,1,1.25})do assertScale(scale)end
local t,p=objects,pixelCalls
for _=1,100 do canvas:OnRefresh();quest:QuestLog_Update()end
assert(objects==t and pixelCalls==p,'warm refresh rebuilt outline geometry')
print('PASS: contained checkbox outline at six fractional scales; native geometry and warm layout reuse preserved')
-- Timings/heap are measured in this mock, not in the WoW client.
local function benchmark(name,fn)
 collectgarbage('collect')
 local heap=collectgarbage('count');local o,w,h=objects,writes,hookCount
 collectgarbage('stop');local start=os.clock()
 for _=1,1000 do fn()end
 local elapsed=os.clock()-start;local allocated=collectgarbage('count')-heap
 collectgarbage('restart');collectgarbage('collect')
 assert(objects==o and writes==w and hookCount==h,name..' repeated creation/font/hook work')
 print(string.format('BENCH AWQ %s: 1000 callbacks %.3f ms; temporary Lua heap %.2f KiB; objects=0 font_writes=0 new_hooks=0 (mock)',name,elapsed*1000,allocated))
end
benchmark('warm settings refresh',function()canvas:OnRefresh()end)
benchmark('quest rebuild completion',function()quest:QuestLog_Update()end)
benchmark('Profiles feed',function()dialog:FeedGroup('AWQ-Profiles',{},profiles)end)

-- Startup/load bursts coalesce into one integration refresh, with no polling.
local eventFrame
for _,f in ipairs(events)do
 if f.events and f.events.UI_SCALE_CHANGED then eventFrame=f end
end
assert(eventFrame and #timers==0)
for _=1,1000 do eventFrame.scripts.OnEvent(eventFrame,'ADDON_LOADED','ForeignAddon')end
assert(#timers==1,'load burst queued duplicate full refreshes')
flush();assert(#timers==0)
local so,sh=objects,hookCount
for _=1,100 do
 gui:Release(action);gui:Release(dropdown);gui:Release(edit);gui:Release(item)
 dialog:FeedGroup('AWQ-Profiles',{},profiles)
end
assert(objects==so and hookCount==sh,'Profiles release/reuse grew objects or hooks')
assert(questReads==0 and #errors==0,table.concat(errors,'; '))
print('PASS: 1000 load events coalesce once; 100 Profiles release/reuse cycles add no UI objects or hooks')

-- Blizzard's generated menus capture IsSelected data, then rebuild their
-- compositor regions. Verify styling before display and synchronous selection.
local callbacks,descriptionCount=0,0
MenuUtil={TraverseMenu=function(root,fn)for _,desc in ipairs(root.elements)do fn(desc)end end}
local function description(value,id)
 local desc={initializers={},IsRadio=function()return true end,IsSelected=function()return value==id end}
 function desc:AddInitializer(fn)self.initializers[#self.initializers+1]=fn end
 return desc
end
dd.GenerateMenu=function(self)
 descriptionCount=descriptionCount+1
 local root={value=self.value or 'Tab',elements={description(self.value or 'Tab','Tab'),description(self.value or 'Tab','Window')}}
 return self:RegisterMenu(root)
end
dd.Choose=function(self,value)
 callbacks=callbacks+1;self.value=value
 if self.shouldRegenerateOnResponse then self:GenerateMenu()else self:UpdateToMenuSelections()end
 return 'choice-native',nil,23
end
local list=frame();list.owner=dd;list.GetOwnerRegion=function(self)return self.owner end
local rows={frame('Button',list),frame('Button',list)}
for _,row in ipairs(rows)do
 row.leftTexture1=row:CreateTexture();row.leftTexture2=row:CreateTexture()
 row.label=label(row,'Menu entry');row.label.SetFont=nil
 setmetatable(row.label,{__index=function(_,key)if key=='SetFont'then error('restricted compositor SetFont access')end end})
 row.GetElementDescription=function(self)return self.description end
end
local initializedBeforeOpen=false
list.SetMenuDescription=function(self,root)
 for i,row in ipairs(rows)do
  local desc=root.elements[i];row.description=desc
  row.leftTexture1:SetAtlas('native-ring');row.leftTexture1:SetColorTexture(1,1,1)
  if desc:IsSelected()then row.leftTexture2=row.selected or row.leftTexture2 or row:CreateTexture();row.selected=row.leftTexture2;row.leftTexture2:SetAtlas('native-dot')
  else row.selected=row.leftTexture2 or row.selected;row.leftTexture2=nil end
  for _,fn in ipairs(desc.initializers)do fn(row,desc,self)end
 end
 initializedBeforeOpen=rows[1].leftTexture1.color[1]==.16
end
assert(dd.shouldRegenerateOnResponse,'native response regeneration was not enabled')
assert(select(3,dd:GenerateMenu())==19)
list:SetMenuDescription(dd:GetMenuDescription());assert(initializedBeforeOpen,'native radio flashed before initializers ran')
dd.menu=list;local priorLists=lists
assert(dd:OnMenuOpened(list)=='opened-native'and lists==priorLists+1)
assert(rows[1].leftTexture2.color[1]==accent and rows[1].leftTexture2.w==7)
assert(dd.Text.font[1]=='eui'and dd.nativeArt.alpha==0)
local queued=#timers
assert(select(3,dd:Choose('Window'))==23 and callbacks==1)
assert(dd.Text.text=='Window'and dd.Text.font[1]=='eui'and dd.nativeArt.alpha==0,'selection left stale text/art')
assert(not rows[1].leftTexture2 and rows[2].leftTexture2.color[1]==accent,'selected marker was not styled on native rebuild')
assert(#timers==queued,'selection styling deferred to a later frame')
local initializers=#dd.description.elements[1].initializers
for _=1,100 do dd:OnMenuOpened(list)end
assert(#dd.description.elements[1].initializers==initializers,'duplicate row initializers')
-- Compositor reuse by another owner must retain native textures.
list.owner=foreign.frame;list:SetMenuDescription(dd.description)
assert(rows[1].leftTexture1.color[1]==1,'AWQ initializer leaked into a foreign menu')
list.owner=dd;dd.menu=nil;list:Hide();list:Show();list:SetMenuDescription(dd.description);dd.menu=list
local reopen=lists;dd:OnMenuOpened(list);assert(lists==reopen+1,'reopened menu did not restore its styling')
assert(#errors==0,table.concat(errors,'; '))
print('PASS: pre-display radio initializers, immediate selection/art repair, native response regeneration, restricted fonts, no queued updates, reuse and foreign-owner isolation')
local menuObjects,menuHooks=objects,hookCount
collectgarbage('collect');local menuHeap=collectgarbage('count')
for i=1,1000 do dd:Choose(i%2==0 and 'Tab'or 'Window')end
collectgarbage('collect')
assert(objects==menuObjects and hookCount==menuHooks,'menu response burst created objects or duplicate hooks')
assert(collectgarbage('count')-menuHeap<64,'old generated descriptions were retained')
assert(callbacks==1001 and #timers==queued,'menu repair duplicated setting actions or queued repaint')
enabled=false;dd:Choose('Window');assert(dd.Text.font[1]=='native'and dd.nativeArt.alpha==1)
enabled=true;combat=true;dd:Choose('Tab');assert(dd.Text.font[1]=='native')
combat=false;m.refresh();assert(dd.Text.font[1]=='eui'and dd.nativeArt.alpha==0)
assert(#errors==0,table.concat(errors,'; '))
print('PASS: 1000 native selection responses retain no old descriptions, duplicate no actions/hooks/objects, and respect disabled/combat guards')

-- Late Settings construction installs completion hooks before first display,
-- without waiting for the queued discovery or repainting every known font.
local lateDropdown
SettingsPanel={DisplayLayout=function()
 lateDropdown=frame('Button',canvas);lateDropdown.configKey='timeFilterDuration'
 lateDropdown.SetupMenu=function()end;lateDropdown.Text=label(lateDropdown,'6 Hours')
 return 'late-layout-native',nil,29
end,DisplayCategory=function()end,GetLayout=function()error('private layout')end}
local beforeFonts=writes
eventFrame.scripts.OnEvent(eventFrame,'ADDON_LOADED','Blizzard_Settings')
assert(#timers==1)
assert(select(3,SettingsPanel:DisplayLayout())==29)
assert(lateDropdown.dropdown and lateDropdown.Text.font[1]=='eui','late Settings painted a native frame first')
local preparedFonts=writes
flush();assert(writes==preparedFonts,'queued discovery redundantly reapplied prepared fonts')
print('PASS: late Settings category styled synchronously before display; load discovery does not reapply prepared fonts')
