-- Instrumentation contract only. Deliberately inject visibility loss; this is
-- not evidence that the actual client regression or its cause is reproduced.
local ns, hooks, writes, reads, timers = {},0,0,0,0
local objects={}
local function obj(kind,parent,name)
    local o={kind=kind,parent=parent,name=name,alpha=1,shown=true,layer='BACKGROUND',sub=0,rgba={1,1,1,1},scripts={},w=38,h=38}
    objects[#objects+1]=o;if name then _G[name]=o end
    function o:GetObjectType()return self.kind end
    function o:GetParent()return self.parent end
    function o:GetAlpha()reads=reads+1;return self.alpha end
    function o:GetEffectiveAlpha()return self.alpha*(self.parent and self.parent:GetEffectiveAlpha()or 1)end
    function o:IsShown()return self.shown end
    function o:IsVisible()return self.shown and(not self.parent or self.parent:IsVisible())end
    function o:GetDrawLayer()return self.layer,self.sub end
    function o:GetTexture()return self.texture end
    function o:GetTextureFilePath()return self.texture end
    function o:GetVertexColor()return table.unpack(self.rgba)end
    function o:GetWidth()return self.w end
    function o:GetHeight()return self.h end
    function o:GetSize()return self.w,self.h end
    function o:GetNumPoints()return 0 end
    function o:GetTexCoord()return 0,1,0,1 end
    function o:GetFrameLevel()return 3 end
    function o:GetFrameStrata()return 'MEDIUM'end
    function o:SetAlpha(a)writes=writes+1;self.alpha=a end
    function o:SetVertexColor(...)writes=writes+1;self.rgba={...}end
    function o:SetTexture(t)writes=writes+1;self.texture=t end
    function o:SetColorTexture(...)writes=writes+1;self.texture=nil;self.base={...}end
    function o:SetDrawLayer(l,s)writes=writes+1;self.layer,self.sub=l,s end
    function o:Hide()writes=writes+1;self.shown=false end
    function o:Show()writes=writes+1;self.shown=true;if self.scripts.OnShow then self.scripts.OnShow(self)end end
    function o:SetShown(on)if on then self:Show()else self:Hide()end end
    function o:SetSize(w,h)writes=writes+1;self.w,self.h=w,h end
    function o:SetPoint()writes=writes+1 end
    function o:SetFrameStrata()writes=writes+1 end
    function o:SetMultiLine()end
    function o:SetAutoFocus()end
    function o:SetFont()end
    function o:SetWidth(w)writes=writes+1;self.w=w end
    function o:SetMaxLetters()end
    function o:SetScript(k,f)self.scripts[k]=f end
    function o:SetScrollChild(f)self.child=f end
    function o:SetText(t)self.text=t end
    function o:HighlightText()end
    function o:SetFocus()end
    function o:HookScript(k,f)
        hooks=hooks+1;local old=self.scripts[k]
        self.scripts[k]=function(...)if old then old(...)end;f(...)end
    end
    return o
end
UIParent=obj('Frame')
CreateFrame=function(k,n,p,template)
    local o=obj(k,p,n)
    if template=='BasicFrameTemplateWithInset'then o.TitleText=obj('FontString',o)end
    return o
end
hooksecurefunc=function(o,k,fn)
    hooks=hooks+1;local old=o[k]
    o[k]=function(...)local r=table.pack(old(...));fn(...);return table.unpack(r,1,r.n)end
end
debugstack=function()return 'native-delay-redraw.lua:42 -> refreshSlots -> paintSlots'end
GetTime=function()return 1.234 end
GetBuildInfo=function()return 'test','build','date',16001 end
GetAddOnMetadata=function()return '6.0.1'end
C_AddOns=nil
InCombatLockdown=function()return false end
C_Timer={After=function()timers=timers+1 end}
local forwarded
SlashCmdList={EUIADDONSKINS=function(m)forwarded=m;return 'native',nil,3 end}
assert(loadfile('diagnostics/OneForAllTrace.lua'))('EUIAddonSkins',ns)
local D=ns.OneForAllTrace
local f=obj('Frame',UIParent)
function f:Refresh()self.paintSlots()end
local slot=obj('Button',f);local edge=obj('Texture',slot)
local card={border={pieces={edge}},fill={pieces={obj('Texture',slot)}}}
D.Card(card,slot);slot.card=card;slot.slot=1;slot.slotName='HeadSlot';slot.q=2
slot.icon=obj('Texture',slot)
ITEM_QUALITY_COLORS={[2]={r=.12,g=1,b=0}}
function f.paintSlots()edge:SetVertexColor(.12,1,0,1)end
D.Planner(f)
assert(hooks==0 and timers==0 and writes==0 and reads==0,'disabled trace performed observation work')
local a,b,c=SlashCmdList.EUIADDONSKINS('refresh')
assert(a=='native'and b==nil and c==3 and forwarded=='refresh','existing command changed')
D.Command('start');assert(D.active and hooks>0)
local bound=hooks;D.Planner(f);assert(hooks==bound,'duplicate bindings')
f:Refresh();f:Show()
-- Represent a later native callback replacing art/layer/alpha and hiding a
-- parent; no diagnostic must repair it or issue extra writes.
local before=writes
edge:SetTexture('replacement');edge:SetDrawLayer('BACKGROUND',-1);edge:SetAlpha(.2);f:SetAlpha(.5);edge:Hide()
edge:SetColorTexture(1,1,1,0);edge:SetColorTexture(1,1,1,1)
assert(writes==before+7 and not edge:IsShown(),'diagnostic changed native texture state')
D.Command('before')
edge:Show();edge:SetAlpha(1);f.paintSlots()
D.Command('after');D.Command('compare')
assert(not D.active,'export must stop capture')
local export=EUIAddonSkinsOFATraceExport
local text
for _,o in ipairs(objects)do if o.kind=='EditBox'then text=o.text end end
assert(export and text:find('SNAPSHOT before',1,true)and text:find('SNAPSHOT after',1,true))
for _,s in ipairs({'COMPARE before -> after','slot1.border1','SetTexture args=replacement','SetColorTexture args=1,1,1,0','SetColorTexture args=1,1,1,1','native-delay-redraw.lua:42','parentAlpha=0.5','layer=BACKGROUND,-1','quality=2','expected=0.12,1,0'})do
    assert(text:find(s,1,true),'missing trace evidence '..s)
end
local stoppedReads=reads
for i=1,1000 do edge:SetAlpha(i%2);f:Refresh()end
assert(reads==stoppedReads and hooks==bound and timers==0,'stopped trace still observes or schedules')
D.Command('start')
for i=1,2000 do edge:SetAlpha(i%2)end
for i=1,25 do D.Command('snapshot')end
D.Command('export')
for _,o in ipairs(objects)do if o.kind=='EditBox'then text=o.text end end
assert(text:find('events=1024',1,true)and text:find('snapshots=12',1,true),'log bounds failed')
assert(not text:find('dropped=0 ',1,true),'overflow not reported')
print('PASS: OneForAll development trace: opt-in, bounded changes/stacks, before/after export, native state/returns, no polling or disabled observer reads')
