-- Source-shaped Myslot 6.2.0 UI. No import/clear operation is executed by skinning.
local timers,events,errors,modules,looks={},{},{},{},{}
local enabled,combat=true,false
local ns={IsEnabled=function()return enabled end,AttachAccent=function(_,f)f.accent=true end}
function ns.RegisterModule(id,_,available,install)modules[id]={available=available,install=install}end
C_Timer.After=function(_,fn)timers[#timers+1]=fn end
InCombatLockdown=function()return combat end
geterrorhandler=function()return function(err)errors[#errors+1]=err end end
hooksecurefunc=function(obj,key,fn)local old=obj[key];obj[key]=function(...)local r=table.pack(old(...));fn(...);return table.unpack(r,1,r.n)end end
local function flush()local n=0;while #timers>0 do local t=timers;timers={};for _,fn in ipairs(t)do fn()end;n=n+1;assert(n<20,'Myslot refresh loop')end end
local writes,objects=0,0
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
local S={GetFont=function()return'eui',''end,GetAccentColor=function()return .7,.5,.3 end,OnLooksChanged=function(fn)looks[#looks+1]=fn end}
S.Font=function(t,r,g,b)if t.SetFont then t:SetFont('eui',12,'')end;if r then t:SetTextColor(r,g,b)end end
S.Shell=function(f,opts)f.shell=opts end
S.Panel=function(f)f.panel=true end
S.Button=function(f,keys)f.button=true;f.keep=keys;local keep={};for _,key in ipairs(keys or{})do keep[f[key]]=true end;for _,r in ipairs(f.regions)do if r.kind=='Texture'and not keep[r]then r.alpha=0 end end end
S.Dropdown=function(f)S.Button(f);f.dropdown=true;f.arrow=f:CreateTexture(nil,'OVERLAY');f.arrow:SetAtlas('Azerite-PointingArrow')end
S.Checkbox=function(f)f.checkbox=true end
S.PageButton=function(f,glyph)f.glyph=glyph;S.Button(f)end
S.StateButtonLabel=function()end
S.EditBox=function(f,opts)f.input=opts end
S.ScrollBar=function(f)f.scroll=true end
S.FadeNineSlice=function()end
local lib={MainFrame=frame()};local main=lib.MainFrame
LibStub=function(name)if name=='Myslot-5.0'then return lib end end
C_AddOns={IsAddOnLoaded=function()return true end}
local panel=frame();panel.name='Myslot';panel.shown=false
local category={GetName=function()return'Myslot'end}
Settings={GetCategory=function(name)if name=='Myslot'then return category end end,RegisterCanvasLayoutCategory=function(f,name)return 'native-category',nil,5 end}
SettingsPanel={GetLayout=function(_,cat)if cat==category then return{GetFrame=function()return panel end}end end,DisplayCategory=function()return'display-native',nil,3 end}
local manager={OpenMenu=function(self,owner,list)list.owner=owner;self.list=list;return'open-native',nil,9 end,GetOpenMenu=function(self)return self.list end}
Menu={GetManager=function()return manager end}
local bindings,owners=0,{}
ns.BindPopupOwner=function(_,_,owner)if owner then owners[owner]=true end end
ns.BindPopupList=function(_,_,owner,list)assert(owner==list.owner);bindings=bindings+1 end
local imports,exports,clears=0,0,0
local export=button(main,'Export',function()exports=exports+1;return'export-native'end)
local import=button(main,'Import',function()imports=imports+1;return'import-native'end)
local split=frame('Button',main);split.label=label(split,'');split.art=split:CreateTexture();split.art:SetTexture('Interface\\ChatFrame\\ChatFrameExpandArrow')
local profile=frame('Button',main);profile.w=240;profile.labelText=label(profile,'Select a profile');profile.art=profile:CreateTexture();profile.art:SetTexture('Interface\\Icons\\inv_scroll_03')
local share=frame('Button',main);share.art=share:CreateTexture();share.art:SetTexture('Interface\\ChatFrame\\UI-ChatIcon-Chat-Up')
share.disabledArt=share:CreateTexture();share.disabledArt:SetTexture('Interface\\ChatFrame\\UI-ChatIcon-Chat-Up');share.disabledArt:SetAlpha(.5)
local title=label(main,'Myslot');local unsaved=label(profile,'');local talents=label(main,'Talents:')
local status=label(main,'|cffff0000Talents differ|r')
local editorPanel=frame('Frame',main);editorPanel.backdrop={bgFile='native'}
local scroll=frame('ScrollFrame',editorPanel)
local editor=frame('EditBox',scroll);editor.multiline=true;editor.content='encoded\nprofile|cffffff00NOT A HEADING|r';editor.maxLetters=99999999
local nativeChange=function()return'changed-native'end;editor.scripts.OnTextChanged=nativeChange;editor.scripts.OnChar=nativeChange
local slider=frame('Slider',editorPanel);slider.thumb=slider:CreateTexture();slider.thumb:SetSize(16,32)
local open=button(panel,'Open Myslot',function()main:Show();return'open-native'end)
local danger=label(panel,'|cffff0000DANGEROUS|r')
local clear=button(panel,'Remove all Macros',function()clears=clears+1;return'confirmation-native'end)
local checkbox=frame('CheckButton',panel);checkbox.text=label(checkbox,'Allow |cffff0000CLEAR|r before Import');checkbox.checked=true
checkbox.scripts.OnClick=function()checkbox.checked=not checkbox.checked;return'check-native'end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins',ns)
local baseHelper=ns.CreateSkinHelper;local scans=0
ns.CreateSkinHelper=function(...)local H=baseHelper(...);local scan=H.Scan;H.Scan=function(...)scans=scans+1;return scan(...)end;return H end
assert(loadfile('EUIAddonSkins/Scoped.lua'))('EUIAddonSkins',ns)
assert(loadfile('EUIAddonSkins/Skins/Myslot.lua'))('EUIAddonSkins',ns)
local m=modules.Myslot;assert(m.available());m.install(S,m);flush()
assert(imports==0 and exports==0 and clears==0,'skinning executed a data/clear operation')
assert(main.shell.noAccent and main.shell.noTopBar and not main.accent)
assert(open.button and clear.button and checkbox.checkbox,'Myslot options canvas missed')
assert(split.glyph=='v'and profile.dropdown and profile.art.alpha==1,'split/profile menu affordances lost')
assert(share.button and share.art.alpha==1 and share.disabledArt.alpha==.5 and #share.keep==2,'sharing icon or disabled appearance lost')
assert(profile.arrow.path:match('eui%-arrow%-down3.png'),'profile dropdown has native arrow')
unsaved:SetText('|cffffff00Unsaved|r')
assert(unsaved.text=='Unsaved'and unsaved.color[1]==.7 and talents.color[1]==.7 and title.color[1]==.7)
assert(status.text=='|cffff0000Talents differ|r'and danger.text=='|cffff0000DANGEROUS|r','semantic warnings changed')
assert(checkbox.text.text:find('|cffff0000CLEAR|r',1,true)and checkbox.checked)
assert(editorPanel.panel and editor.content=='encoded\nprofile|cffffff00NOT A HEADING|r'and not editor.input and editor.maxLetters==99999999)
assert(editor.scripts.OnTextChanged==nativeChange and editor.scripts.OnChar==nativeChange,'native editor callbacks replaced')
assert(slider.thumb.w==16 and slider.thumb.h==32 and slider.thumb.alpha==0,'native scrollbar hit area resized')
local grip=slider.regions[#slider.regions];slider.thumb:Hide();assert(grip.alpha==0,'hidden native thumb left a floating grip')
slider.thumb:Show();assert(grip.alpha==1,'native thumb reappearance lost styled grip')
local na,nb,nc=SettingsPanel:DisplayCategory(category);assert(na=='display-native'and nb==nil and nc==3)
scans=0;local stableObjects=objects
for i=1,100 do
 if export.hooks.OnClick then export.hooks.OnClick(export)end
 assert(editor:SetText('payload '..i)=='editor-native');editor.scripts.OnTextChanged()
end
flush();assert(scans==0 and objects==stableObjects and imports==0 and exports==0 and clears==0,'data/menu activity rescans or mutates profiles')
local list=frame();list.GetOwnerRegion=function(self)return self.owner end
local a,b,c=manager:OpenMenu(split,list);assert(a=='open-native'and b==nil and c==9 and bindings==1)
local foreign=frame();manager:OpenMenu(foreign,list);assert(bindings==1,'foreign menu bound as Myslot')
manager:OpenMenu(profile,list);assert(bindings==2)
for i=1,20 do main:Show();flush()end
assert(objects==stableObjects+2,'reopening allocated skin objects')
local current=objects;local nativeClick=import.scripts.OnClick
m.refresh();flush();assert(objects==current and import.scripts.OnClick==nativeClick)
assert(import.scripts.OnClick()=='import-native'and imports==1)
assert(clear.scripts.OnClick()=='confirmation-native'and clears==1)
local old=checkbox.checked;assert(checkbox.scripts.OnClick()=='check-native'and checkbox.checked~=old)
enabled=false;local saved=bindings;manager:OpenMenu(profile,list);assert(bindings==saved,'disabled Myslot menu processed')
enabled=true;combat=true;scans=0;m.refresh();flush();assert(scans==0,'combat scanned Myslot')
combat=false;for _,event in ipairs(events)do if event.events and event.events.PLAYER_REGEN_ENABLED then event.scripts.OnEvent(event,'PLAYER_REGEN_ENABLED')end end;flush()
assert(scans>0 and #errors==0,table.concat(errors,'\n'))
local latePanel=frame();local lateAction=button(latePanel,'Open Myslot',function()return'late-native'end)
local ra,rb,rc=Settings.RegisterCanvasLayoutCategory(latePanel,'Myslot');flush()
assert(ra=='native-category'and rb==nil and rc==5 and lateAction.button,'late options registration lost styling or native returns')
local oldLib=lib;lib=nil;C_AddOns.IsAddOnLoaded=function()return false end
assert(not m.available(),'missing Myslot reported available');lib=oldLib
print('PASS: Myslot modern canvas, native actions/editor/warnings, split/dropdown glyphs, menus, reuse/toggles/combat')
print('BENCH Myslot 100 simulated button/data callbacks: scans=0; skin objects=0; data operations=0')
