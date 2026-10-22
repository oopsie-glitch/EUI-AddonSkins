-- Source-shaped LiteMount UI and Blizzard Settings initializers. No configuration action is executed.
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
 function f:GetID()return self.id end
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
S.GetPanelColor=function()return .08,.08,.08,.92 end
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
-- FontObject-based shadow setup can reset colour during a face change.
S.Font=function(t) t:SetFont('eui',12,'');t:SetTextColor(1,1,1,1)end
local actions,providers,casts,scans=0,0,0,0
local hookCount=0;local oldHook=hooksecurefunc
hooksecurefunc=function(...)hookCount=hookCount+1;return oldHook(...)end
local function view()
 local v={rows={},callbacks={}}
 function v:RegisterCallback(event,fn,owner)assert(not self.callbacks[event]);self.callbacks[event]={fn=fn,owner=owner}end
 function v:EnumerateFrames()return ipairs(self.rows)end
 function v:Initialized(row)local c=self.callbacks.OnInitializedFrame;if c then c.fn(c.owner,row)end end
 return v
end
local function scroll(parent,v)
 local f=frame('ScrollFrame',parent);f.GetView=function()return v end
 f.GetDataProvider=function()providers=providers+1;error('skin accessed data provider')end
 return f
end
local function panel(name)
 local f=frame();_G[name]=f;f.name=name;f.Title=label(f,name);f.shown=false
 f.DefaultsButton=button(f,'Defaults',function()actions=actions+1 end)
 f.RevertButton=button(f,'Revert',function()actions=actions+1 end)
 f.RefreshDisplay=function()return 'refresh-native',nil,4 end
 return f
end
local base=panel('LiteMountBasePanel')
local mounts=panel('LiteMountMountsPanel')
mounts.MountsContainer=frame('Frame',mounts);mounts.MountsContainer.backdrop={bgFile='native'}
local listView,gridView=view(),view();mounts.viewsByTabs={listView,gridView}
mounts.ScrollBox=scroll(mounts,listView)
mounts.SetTab=function(self,id)self.selectedTab=id;self.ScrollBox.GetView=function()return self.viewsByTabs[id]end;return 'tab-native'end
mounts.Tabs={button(mounts,'List View'),button(mounts,'Model View')}
for i,tab in ipairs(mounts.Tabs)do tab.id=i end;mounts.selectedTab=1
PanelTemplates_GetSelectedTab=function(p)return p.selectedTab end
mounts.ScrollBar=frame('Frame',mounts);mounts.ScrollBar.Track=frame('Frame',mounts.ScrollBar)
mounts.ScrollBar.Back=button(mounts.ScrollBar);mounts.ScrollBar.Forward=button(mounts.ScrollBar)
local function check(parent,key)
 local f=frame('CheckButton',parent);f.key=key;f.checked=false
 f.normal=f:CreateTexture();f.checkedArt=f:CreateTexture()
 f.GetCheckedTexture=function(self)return self.checkedArt end
 f.GetChecked=function(self)return self.checked end
 f.SetChecked=function(self,value)self.checked=value;return 'check-native',nil,9 end
 f.scripts.OnClick=function(self)self:SetChecked(not self:GetChecked());actions=actions+1;return 'click-native'end
 return f
end
local function row(v,isModel)
 local f=frame('Button');f.mount={id=#v.rows+1};f.Name=label(f,'Mount Name');f.Types=label(f,'Ground');f.Rarity=label(f,'40%')
 f.backdrop={bgFile='native-row'}
 f.Icon=frame('Button',f);f.Icon.Count=label(f.Icon,'4');f.Icon.SetMount=function()casts=casts+1;error('skin called mount setter')end
 f.Icon.GetNormalTexture=function()return f.Icon.texture end;f.Icon.texture=f.Icon:CreateTexture();f.Icon.texture:SetTexture('mount-icon')
 f.Icon.attributes={spell='native-spell'};f.Icon.scripts.OnClick=function()casts=casts+1 end
 f.Priority=frame('Frame',f);f.Priority.Background=f.Priority:CreateTexture();f.Priority.Background:SetColorTexture(0,.6,0,.33)
 f.Priority.Priority=label(f.Priority,'1');f.Priority.Minus=button(f.Priority);f.Priority.Plus=button(f.Priority)
 f.Bit1=check(f,'RUN');f.Bit1.Modified=f.Bit1:CreateTexture();f.Bit1.Modified.shown=false
 if isModel then f.ModelScene=frame('ModelScene',f);f.ModelScene.SetMount=function()error('model recreated')end end
 f.Initialize=function(self,newName)self.Name:SetText(newName);self.Name.font={'native',12,''};self.Name.color={1,.82,0,1};return 'initialize-native'end
 v.rows[#v.rows+1]=f;return f
end
local first=row(listView);local model=row(gridView,true)
local macros=panel('LiteMountMacroPanel');macros.Macro=frame('Frame',macros);macros.Macro.backdrop={bgFile='native-container'}
macros.Macro.ExplainText=label(macros.Macro,'Description');macros.WarnText=label(macros,'Warning');macros.WarnText.color={1,.25,.25,1}
macros.Macro.EditBox=frame('EditBox',macros.Macro);macros.Macro.EditBox.content='/cast Something';macros.Macro.EditBox.font={'mono',13,''}
macros.Macro.EditBox.insets={5,5,5,5};local originalInsets=macros.Macro.EditBox.insets
macros.Macro.EditBox.scripts.OnTextChanged=function()actions=actions+1 end
macros.Class=frame('Frame',macros);local classView=view();macros.Class.ScrollBox=scroll(macros.Class,classView)
local classRow=button(nil,'|cffff7d0aDruid|r');classRow.SelectedTexture=classRow:CreateTexture();classRow.SelectedTexture.shown=true;classView.rows={classRow}
local falling=panel('LiteMountFallingPanel');local fallingView=view();falling.ScrollBox=scroll(falling,fallingView)
local fallingRow=button(nil);fallingRow.Name=label(fallingRow,'Slow Fall');fallingRow.Icon=fallingRow:CreateTexture();fallingRow.Icon:SetTexture('slow-fall')
fallingRow.DeleteButton=button(fallingRow,'Delete',function()actions=actions+1 end);fallingRow.backdrop={bgFile='row'};fallingView.rows={fallingRow}
local rules=panel('LiteMountRuleEdit');rules.Action=frame('Frame',rules);rules.Action.TypeDropDown=button(rules.Action,'Mount')
rules.Action.TypeDropDown.SetupMenu=function()end;rules.Action.TypeDropDown.RegisterMenu=function(self,d)self.description=d;return 'register-native'end
rules.Action.TypeDropDown.GetMenuDescription=function(self)return self.description end
local import=panel('LiteMountProfileImport');import.ProfileData=frame('EditBox',import);import.ProfileData.content='encoded:ABC123';import.ProfileData.font={'mono',12,''}
local popupCalls={};StaticPopup1=frame();StaticPopup1.which='OTHER_ADDON';StaticPopup_Show=function()return 'popup-native'end
ns.StyleTextureDialog=function(_,_,f,active)popupCalls[#popupCalls+1]={f,active}end
local initializer={InitFrame=function(_,f)f.nativeInitialized=true;return 'init-native',nil,7 end,Resetter=function(_,f)f.nativeReset=true;return 'reset-native'end}
local layout={initializers={initializer},GetInitializers=function(self)return self.initializers end,
AddInitializer=function(self,i)self.initializers[#self.initializers+1]=i;return 'add-native'end}
LiteMountGeneralPanel={layout=layout,Register=function()return 'register-general-native'end}
local bindings=0;ns.BindPopupOwner=function()end;ns.BindPopupList=function()bindings=bindings+1 end
local manager={OpenMenu=function(self,owner,list)self.list=list;list.owner=owner;return 'open-native'end,GetOpenMenu=function(self)return self.list end}
manager.OpenContextMenu=function(self,owner,list)self.list=list;list.owner=owner;return 'context-native'end
Menu={GetManager=function()return manager end}
MenuUtil={TraverseMenu=function(d,fn)for _,desc in ipairs(d.elements or{})do fn(desc)end end}
local modulesBefore=modules
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins',ns)
assert(loadfile('EUIAddonSkins/Skins/LiteMount.lua'))('EUIAddonSkins',ns)
local m=modules.LiteMount;assert(m.available());m.install(S,m)
assert(#errors==0,table.concat(errors,'; '))
assert(base.Title.font[1]=='eui'and base.DefaultsButton.label.color[1]>.8)
assert(providers==0 and casts==0 and actions==0)
assert(first.Icon.attributes.spell=='native-spell'and first.Icon.texture.alpha==1 and first.Icon.Count.text=='4')
assert(first.Priority.Background.color[2]==.6 and first.Priority.Background.alpha==1)
assert(first.Bit1.children[1].checkbox and mounts.ScrollBar.scroll)
assert(macros.WarnText.color[1]==1 and macros.WarnText.color[2]==.25)
assert(macros.Macro.EditBox.content=='/cast Something'and macros.Macro.EditBox.font[1]=='mono'and macros.Macro.EditBox.insets==originalInsets)
assert(import.ProfileData.content=='encoded:ABC123'and import.ProfileData.font[1]=='mono')
local no,nh=objects,hookCount
for _=1,100 do assert(select(3,mounts:RefreshDisplay())==4)end
assert(objects==no and hookCount==nh and providers==0 and actions==0)
assert(mounts:SetTab(2)=='tab-native');assert(mounts.Tabs[2].label.color[1]==accent and mounts.Tabs[1].label.color[1]>.8);gridView:Initialized(model)
assert(model.ModelScene:GetObjectType()=='ModelScene'and model.Icon.texture.alpha==1 and casts==0)
local dynamic=row(listView);dynamic:Initialize('Dynamic Mount');listView:Initialized(dynamic)
assert(dynamic.Name.font[1]=='eui'and dynamic.Name.color[1]>.8)
assert(first.Bit1.scripts.OnClick(first.Bit1)=='click-native')
assert(first.Bit1.children[1].regions[#first.Bit1.children[1].regions].shown and actions==1)
first.Bit1.Modified:Show();assert(first.Bit1.children[1].regions[1].color[1]==.55)
base.DefaultsButton:Disable();assert(base.DefaultsButton.label.color[1]==.5)
base.DefaultsButton:Enable();assert(base.DefaultsButton.label.color[1]>.8,'enabled action stayed grey')
classView:Initialized(classRow);assert(classRow.label.text=='|cffff7d0aDruid|r'and classRow.SelectedTexture.shown)
fallingView:Initialized(fallingRow);assert(fallingRow.Icon.path=='slow-fall'and fallingRow.Icon.alpha==1)
-- A pooled Blizzard Settings row is styled only through LiteMount's initializer.
local general=frame();general.Text=label(general,'Try to copy target mount')
general.Checkbox=check(general,'copy');general.Control=frame('Frame',general)
general.Control.Dropdown=button(general.Control,'Priority');general.Control.Dropdown.SetupMenu=function()end
general.Control.DecrementButton=button(general.Control);general.Control.IncrementButton=button(general.Control)
local original=general.Checkbox.normal.alpha
assert(select(3,initializer:InitFrame(general))==7)
assert(general.Text.font[1]=='eui'and general.Checkbox.normal.alpha==0 and general.Checkbox.children[1].checkbox)
local sharedHost=general.Checkbox.children[1]
enabled=false;assert(initializer:Resetter(general)=='reset-native')
assert(general.Text.font[1]=='native'and general.Checkbox.normal.alpha==original and not sharedHost.shown)
general.Checkbox:SetChecked(true);assert(not sharedHost.shown,'disabled callback restyled released foreign row')
enabled=true;initializer:InitFrame(general);assert(sharedHost.shown)
local so,sh=objects,hookCount
for _=1,100 do initializer:Resetter(general);initializer:InitFrame(general)end
assert(objects==so and hookCount==sh,'shared settings reuse added frames or hooks')
local late={InitFrame=initializer.InitFrame,Resetter=initializer.Resetter};assert(layout:AddInitializer(late)=='add-native')
-- Dialog ownership must not strip another skin's popup.
StaticPopup_Show();assert(#popupCalls==0)
StaticPopup1.which='LM_OPTIONS_NEW_PROFILE';StaticPopup_Show();assert(popupCalls[#popupCalls][2])
StaticPopup1.which='OTHER_ADDON';StaticPopup_Show();assert(not popupCalls[#popupCalls][2])
local desc={IsRadio=function()return true end,AddInitializer=function(self,fn)self.init=fn end}
local d={elements={desc}};rules.Action.TypeDropDown:RegisterMenu(d)
local menu=frame();menu.GetOwnerRegion=function(self)return self.owner end;menu.owner=rules.Action.TypeDropDown
local menuRow=frame('Button',menu);menuRow.leftTexture1=menuRow:CreateTexture();menuRow.leftTexture2=menuRow:CreateTexture()
menuRow.GetElementDescription=function()return desc end
assert(desc.init);desc.init(menuRow,desc,menu);assert(menuRow.leftTexture2.color[1]==accent)
manager:OpenMenu(rules.Action.TypeDropDown,menu);assert(bindings>0)
local foreign=frame();menu.owner=foreign;menuRow.leftTexture1:SetColorTexture(1,1,1);desc.init(menuRow,desc,menu)
assert(menuRow.leftTexture1.color[1]==1,'initializer leaked into foreign menu')
combat=true;local lateRow=row(listView);local before=objects;listView:Initialized(lateRow);assert(objects==before)
combat=false;m.refresh();listView:Initialized(lateRow);assert(lateRow.Name.font[1]=='eui')
enabled=false;local skipped=row(listView);listView:Initialized(skipped);assert(skipped.Name.font[1]=='native')
enabled=true;accent=.3;for _,fn in ipairs(looks)do fn()end
assert(sharedHost.regions[#sharedHost.regions].color[1]==.3)
mounts:SetTab(1);listView:Initialized(first) -- inactive pooled rows repaint when acquired
assert(first.Bit1.children[1].regions[#first.Bit1.children[1].regions].color[1]==.3)
assert(#errors==0,table.concat(errors,'; '))
local o,w,h=objects,writes,hookCount
for _=1,1000 do listView:Initialized(first);mounts:RefreshDisplay()end
assert(objects==o and writes==w and hookCount==h and providers==0 and casts==0,'warm skin repeated expensive work')
print('PASS: LiteMount panels, pooled lists/models, rules/editors, General initializer isolation/restoration, native actions/data/colours, menus, popups, themes and combat/disabled guards')
print('BENCH LiteMount 1000 warm row/refresh callbacks: UI objects=0 font_writes=0 new_hooks=0 mount-provider reads=0 cast operations=0 (mock)')

menu:Hide();menu:Show();menu.owner=rules.Action.TypeDropDown
local oldBindings=bindings
assert(manager:OpenContextMenu(rules.Action.TypeDropDown,menu)=='context-native'and bindings==oldBindings+1)
local cold=frame('Button');cold.protected=true;cold.Name=label(cold,'Protected');listView:Initialized(cold)
assert(cold.Name.font[1]=='native'and #cold.children==0,'protected action UI was modified')
local actualInput=macros.Macro.EditBox.content
for _=1,100 do macros:RefreshDisplay();rules:RefreshDisplay()end
assert(macros.Macro.EditBox.content==actualInput and providers==0 and casts==0)
assert(#errors==0,table.concat(errors,'; '))
print('PASS: context-menu completion, protected action exclusions and repeated editor refresh preserve native data')

-- Submenus have no owner region; accept them only under the matching root.
manager.list=menu;menu.owner=rules.Action.TypeDropDown
local submenu=frame();submenu.GetOwnerRegion=function()return nil end
menuRow.leftTexture1:SetColorTexture(1,1,1);desc.init(menuRow,desc,submenu)
assert(menuRow.leftTexture1.color[1]==.16)
menu.owner=foreign;menuRow.leftTexture1:SetColorTexture(1,1,1);desc.init(menuRow,desc,submenu)
assert(menuRow.leftTexture1.color[1]==1,'submenu initializer leaked through a foreign root')
assert(#errors==0,table.concat(errors,'; '))
print('PASS: ownerless native submenus inherit only the matching LiteMount root ownership')
