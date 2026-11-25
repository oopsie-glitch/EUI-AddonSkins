-- Shared font-height ownership tests; engine validation is strict, not swallowed.
do
local saved={};for _,k in ipairs({"CreateFrame","C_Timer","InCombatLockdown","hooksecurefunc","geterrorhandler","issecretvalue","EllesmereUI","EUI_CLIENT_BLOCKED"})do saved[k]=_G[k]end
local timers,errors,context={}, {}, nil
local enabled,combat=true,false
local writes,shadows,reads,frames,hooks=0,0,0,0,0
local secret=setmetatable({secret=true},{__lt=function()error("secret comparison")end,__le=function()error("secret comparison")end})
issecretvalue=function(v)return type(v)=="table" and v.secret==true end
local function valid(v)return not (issecretvalue and issecretvalue(v)) and type(v)=="number" and v>0 and v<math.huge end
local function text(size)
    local f={height=size,path="native.ttf",flags="OUTLINE",color={.2,.4,.6,.8},object={size=size}}
    function f:GetObjectType()return "FontString"end
    function f:GetFont()reads=reads+1;return self.path,self.height,self.flags end
    function f:GetFontObject()return self.object end
    function f:SetFontObject(obj)shadows=shadows+1;self.object=obj;self.height=obj.size end
    function f:SetFont(path,height,flags)
        assert(valid(height),"FontString:SetFont(): Invalid font height (0.000000): height must be > 0")
        writes=writes+1;self.path,self.height,self.flags=path,height,flags
    end
    function f:GetTextColor()return table.unpack(self.color)end
    function f:SetTextColor(...)self.color={...}end
    function f:IsProtected()return false end
    function f:IsForbidden()return false end
    return f
end
local function frame()
    frames=frames+1
    local f={regions={},children={},scripts={}}
    function f:GetObjectType()return "Frame"end
    function f:GetNumChildren()return #self.children end
    function f:GetNumRegions()return #self.regions end
    function f:GetChildren()return table.unpack(self.children)end
    function f:GetRegions()return table.unpack(self.regions)end
    function f:IsVisible()return true end
    function f:IsProtected()return false end
    function f:IsForbidden()return false end
    function f:HookScript(k,fn)hooks=hooks+1;self.scripts[k]=fn end
    function f:SetScript(k,fn)self.scripts[k]=fn end
    function f:RegisterEvent()end
    return f
end
CreateFrame=frame
C_Timer={After=function(_,fn)timers[#timers+1]=fn end}
InCombatLockdown=function()return combat end
geterrorhandler=function()return function(e)errors[#errors+1]=e end end
hooksecurefunc=function(o,key,fn)
    hooks=hooks+1;local original=o[key]
    o[key]=function(...)local r=table.pack(original(...));fn(...);return table.unpack(r,1,r.n)end
end
local function flush()
    local cycles=0
    while #timers>0 do
        cycles=cycles+1;assert(cycles<10,"unexpected refresh loop")
        local q=timers;timers={};for _,fn in ipairs(q)do fn()end
    end
end
EUI_CLIENT_BLOCKED=nil
local engine={}
local publicFont
local source=os.getenv("EUI_FONT_SOURCE")
if source then
    local function read(file)local f=assert(io.open(source.."/"..file));local s=f:read("*a");f:close();return (s:gsub("\r",""))end
    local fonts=read("EllesmereUI_Fonts.lua")
    local prime=assert(fonts:match("(function EllesmereUI.PrimeFontShadow.-)\n    end"))
    EllesmereUI={_fontFamilySet={}}
    assert(load("local EllesmereUI,shadowObj,noShadowObj=...;"..prime.."\nend"))(EllesmereUI,{size=12},{size=12})
    local window=read("EllesmereUIBlizzardSkin_WindowEngine.lua")
    local first=assert(window:find("function WSkin.Font(fs, r, g, b, size)",1,true))
    local last=assert(window:find("\nend",first,true))
    assert(load("local WSkin,EUI,Theme=...;"..window:sub(first,last+3)))(engine,EllesmereUI,{fontPath="eui.ttf",fontFlag=""})
    local api=read("EllesmereUIBlizzardSkin_SkinAPI.lua")
    local stop=assert(api:find("-- Resolved third-party theme:",1,true))
    publicFont=assert(load(api:sub(1,stop-1).."\nreturn base"))("EllesmereUIBlizzardSkin",{WSkin=engine}).Font
else
    -- Same size selection as the supported engine, with strict SetFont.
    publicFont=function(f,r,g,b)
        local _,height=f:GetFont()
        if height and issecretvalue(height)then return end
        f:SetFont("eui.ttf",height or 12,"")
        if r then f:SetTextColor(r,g,b or r)end
    end
end
local ns={IsEnabled=function()return enabled end,AttachAccent=function()end}
assert(loadfile("EUIAddonSkins/Widgets.lua"))("EUIAddonSkins",ns)
assert(loadfile("EUIAddonSkins/Scoped.lua"))("EUIAddonSkins",ns)
local root,label=frame(),text(14)
root.regions={label}
local S={Font=publicFont,GetFont=function()return "eui.ttf",""end}
ns.RegisterModule=function(_,_,_,install)install(S,{})end
ns.RegisterScopedSkin("FontFixture","Font fixture",{
    panels=false,preserveTextColors=true,
    hooks=function(C)context=C end,
    roots=function()return {{frame=root,mode="controls"}}end,
})
flush();assert(#errors==0 and label.height==14 and label.path=="eui.ttf")
if os.getenv("FONT_HEIGHT_BENCH")then
    local samples={}
    local firstWrites,firstShadows=writes,shadows
    collectgarbage("collect");local heap=collectgarbage("count")
    for trial=1,5 do local started=os.clock();for _=1,1000 do context.RefreshControlsNow(root)end;samples[trial]=(os.clock()-started)*1000 end
    table.sort(samples);collectgarbage("collect")
    print(("FONT_HEIGHT_VALID_BENCH trials=5 refreshes=1000 median_ms=%.3f writes_per_trial=%d shadow_primes_per_trial=%d retained_KiB=%.3f frames=%d hooks=%d"):format(samples[3],(writes-firstWrites)/5,(shadows-firstShadows)/5,collectgarbage("count")-heap,frames,hooks))
    for _,k in ipairs({"CreateFrame","C_Timer","InCombatLockdown","hooksecurefunc","geterrorhandler","issecretvalue","EllesmereUI","EUI_CLIENT_BLOCKED"})do _G[k]=saved[k]end
    return
end
local originalObject=label.object
label.height=0
context.RefreshControlsNow(root)
assert(#errors==0,"REPRO: shared RefreshControlsNow forwarded zero font height: "..table.concat(errors,"\n"))
if os.getenv("FONT_HEIGHT_REPRO")then
    for k,v in pairs(saved)do _G[k]=v end
    return
end
local cases={{"zero",0},{"negative",-2},{"nan",0/0},{"infinity",math.huge},{"negative infinity",-math.huge},{"string","12"},{"false",false},{"nil",nil},{"secret",secret}}
for _,case in ipairs(cases)do
    label.height=case[2]
    local w,p,obj=writes,shadows,label.object
    context.RefreshControlsNow(root)
    assert(writes==w and shadows==p and label.object==obj,"invalid native height was mutated: "..case[1])
    assert(#errors==0,"invalid height reached error handler: "..case[1])
end
-- Inherited font metrics can become valid after construction. No timers or new
-- hooks are needed: the existing normal refresh uses the now-valid size.
label.height=17.5
context.RefreshControlsNow(root)
assert(label.height==17.5 and label.path=="eui.ttf" and label.color[4]==.8)
for _,size in ipairs({.5,9,12,23.25,64})do
    label.height=size;context.RefreshControlsNow(root)
    assert(label.height==size,"native point size changed")
end
local helper=ns.CreateSkinHelper(S,{})
local fresh=frame();local zero=text(0);fresh.regions={zero}
local w,p=writes,shadows
helper.Scan(fresh,function()end)
assert(writes==w and shadows==p,"initial generic scan bypassed height validation")
-- The custom font callback must not get invalid native sizes either.
local routed=0
ns.RegisterScopedSkin("CustomFontFixture","Custom font fixture",{
    panels=false,font=function(api,f)routed=routed+1;api.Font(f)end,
    hooks=function(C)context=C end,
    roots=function()return {{frame=root,mode="controls"}}end,
})
flush();label.height=0;local before=routed;context.S.Font(label)
assert(routed==before,"invalid height entered adapter-specific font callback")
-- Multiline EditBoxes have a direct native SetFont path in Visit.
local box=frame();box.height=0;box.path="native-edit.ttf";box.flags=""
box.GetObjectType=function()return "EditBox"end
box.IsMultiLine=function()return true end
box.GetFont=text(1).GetFont;box.SetFont=text(1).SetFont
root.children={box};w=writes
context.RefreshControlsNow(root)
assert(writes==w,"multiline editor used a fallback/zero height")
box.height=19;context.RefreshControlsNow(root)
assert(box.height==19 and box.path=="eui.ttf")
root.children={}
-- Concrete override/restoration must never capture an invalid restore tuple.
local apply,states=ns.CreateFontOverride()
local overridden=text(13)
apply(overridden,"override.ttf","")
assert(overridden.height==13 and states[overridden].nativeSize==13)
overridden.height=0;w=writes;apply(overridden,nil)
assert(writes==w and states[overridden].nativeSize==13,"invalid tuple replaced restore state")
overridden:SetFont("user.ttf",21,"THICKOUTLINE")
apply(overridden,"override.ttf","");apply(overridden,nil)
assert(overridden.path=="user.ttf" and overridden.height==21 and overridden.flags=="THICKOUTLINE")
for _,case in ipairs(cases)do
    local f=text(case[2]);w=writes;apply(f,"override.ttf","")
    assert(writes==w and states[f]==nil,"invalid override tuple was captured: "..case[1])
end
local plain=text(10);local checker=issecretvalue;issecretvalue=nil
apply(plain,"override.ttf","");apply(plain,nil)
assert(plain.path=="native.ttf" and plain.height==10,"client without secret API changed")
issecretvalue=checker
-- Disabled/combat routes still own their existing deferral, no font writes.
label.height=15;combat=true;w=writes;context.RefreshControlsNow(root);assert(writes==w)
combat=false;enabled=false;context.RefreshControlsNow(root);assert(writes==w);enabled=true
local count,hcount=frames,hooks
label.height=0;collectgarbage("collect");local heap=collectgarbage("count")
for _=1,1000 do context.RefreshControlsNow(root)end
collectgarbage("collect")
assert(frames==count and hooks==hcount and #errors==0,"warm invalid refresh grew resources or errors")
print(("FONT_HEIGHT_RESOURCES refreshes=1000 extra_frames=%d extra_hooks=%d retained_KiB=%.3f"):format(frames-count,hooks-hcount,collectgarbage("count")-heap))
local samples={}
label.height=15
for trial=1,5 do local t=os.clock();for _=1,1000 do context.RefreshControlsNow(root)end;samples[trial]=(os.clock()-t)*1000 end
table.sort(samples)
print(("FONT_HEIGHT_BENCH trials=5 valid_refreshes=1000 median_ms=%.3f"):format(samples[3]))
print("PASS: shared font scanner, actual public font source, zero/invalid/secret heights, inherited metrics, custom callbacks, multiline fields, override restoration, combat/disabled and warm reuse")
for _,k in ipairs({"CreateFrame","C_Timer","InCombatLockdown","hooksecurefunc","geterrorhandler","issecretvalue","EllesmereUI","EUI_CLIENT_BLOCKED"})do _G[k]=saved[k]end
end
