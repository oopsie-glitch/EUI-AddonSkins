"""Execute the pinned native styler in isolation and test source-role alternatives.
No upstream addon is installed, modified, logged, committed or redistributed.
Passing this diagnostic records both proven cases and explicitly expected gaps.
"""
from urllib.request import Request,urlopen
from zipfile import ZipFile
from io import BytesIO
from hashlib import sha256
from pathlib import Path
import ctypes,json,re
data=urlopen(Request("https://edge.forgecdn.net/files/9780/878/HuntersFieldGuide-1.3.0.zip",headers={"User-Agent":"EUIAddonSkins-OwnershipAudit/1"}),timeout=45).read()
assert sha256(data).hexdigest()=="caa507c63478c10140478e231694e9d79883213010dfdd5007dc59244cceb941"
z=ZipFile(BytesIO(data));ui=z.read("HuntersFieldGuide/UI.lua").decode("utf-8-sig")
# Exact native Style implementation, not a mocked successful role callback.
start=ui.index("local function Style(fs, kind)")
end=ui.index("local function SubText",start)
styler=ui[start:end]
assert "skin.styles[kind]" in styler and "fs:SetFontObject(st.font)" in styler
for pattern in (r'b.desc\s*=\s*Style\(Text\(b\),\s*"accent"\)',r'v.tamed.text\s*=\s*Style\(Text\(v.tamed\),\s*"accent"\)',r'f.abInfo\s*=\s*b',r'f.petView\s*=\s*v',r'f.modeChoice\s*=\s*v'):
 assert re.search(pattern,ui),pattern
def section(name):
 m=re.search(r"^(?:local\s+)?function\s+"+re.escape(name)+r"\(",ui,re.M)
 assert m,name
 stop=re.search(r"^(?:local\s+)?function\s+",ui[m.end():],re.M)
 return ui[m.start():m.end()+stop.start()]if stop else ui[m.start():]
for name in ("WriteLines","WriteSide"):
 body=section(name)
 assert "Style(fs, l.style)" in body
 assert not re.search(r"\bfs\.(?:style|kind|role|styleKind|textRole)\s*=",body)
 assert not re.search(r"\b(?:PD|HuntersFieldGuide)\."+name+r"\s*=",ui)
print("SOURCE_BOUNDARY",json.dumps({"version":"1.3.0","staticAccentSlots":["FieldGuideFrame.abInfo.desc","FieldGuideFrame.petView.tamed.text","FieldGuideFrame.modeChoice choice-row names"],"pooledRoleWriters":["WriteLines","WriteSide"],"pooledRoleRetained":False,"supportedRoleCallbackVerified":False}))
lua_source=r"""
local nativeBodyFont={}
local initialAccent={0.4,0.6,0.8}
local skin={styles={accent={font=nativeBodyFont,color=initialAccent},body={font=nativeBodyFont,color={0.8,0.8,0.8}},good={font=nativeBodyFont,color={0.2,0.9,0.2}},bad={font=nativeBodyFont,color={0.9,0.2,0.2}}}}
local function fontString(parent)
 local fs={parent=parent}
 function fs:SetFontObject(font)self.font=font end
 function fs:GetFontObject()return self.font end
 function fs:SetTextColor(r,g,b,a)self.color={r,g,b,a or 1}end
 function fs:GetTextColor()return table.unpack(self.color)end
 function fs:SetShadowColor(...)self.shadowColor={...}end
 function fs:SetShadowOffset(...)self.shadowOffset={...}end
 return fs
end
""" + styler + r"""
local function same(a,b)return a[1]==b[1] and a[2]==b[2] and a[3]==b[3]end
local root={abInfo={},petView={tamed={}},modeChoice={}}
root.abInfo.desc=Style(fontString(root.abInfo),"accent")
root.petView.tamed.text=Style(fontString(root.petView.tamed),"accent")
local semantic=Style(fontString(root.abInfo),"body")
semantic:SetTextColor(table.unpack(initialAccent))
-- Certify only the source's exact static slots, never arbitrary matching colours.
local certified=setmetatable({},{__mode="k"})
local function certify(fs)
 if not certified[fs]then certified[fs]={last=skin.styles.accent.color}end
end
local function discoverStatic()
 if root.abInfo.desc then certify(root.abInfo.desc)end
 if root.petView.tamed.text then certify(root.petView.tamed.text)end
end
local function repaint(accent,combat)
 if combat then return end
 discoverStatic()
 for fs,state in pairs(certified)do
  if not state.revoked then
   if same(fs.color,state.last)then fs:SetTextColor(table.unpack(accent));state.last=accent
   else state.revoked=true end
  end
 end
end
discoverStatic()
local recolored=root.abInfo.desc
recolored:SetTextColor(0.7,0.1,0.9)
collectgarbage("collect");local heap=collectgarbage("count")
for i=1,2000 do
 local c=i%2==0 and {0.1,0.7,0.8}or{0.8,0.3,0.2}
 skin.styles.accent.color=c
 repaint(c,false)
 assert(same(semantic.color,initialAccent),"semantic text adopted by RGB")
 assert(same(recolored.color,{0.7,0.1,0.9}),"explicit recolor overwritten")
end
collectgarbage("collect")
assert(collectgarbage("count")-heap<8,"static certificate memory grew")
assert(same(root.petView.tamed.text.color,skin.styles.accent.color))
-- Late fixed-slot text receives a certificate because of the source-owned field.
root.abInfo.desc=Style(fontString(root.abInfo),"accent")
repaint(skin.styles.accent.color,false)
local late=root.abInfo.desc
local oldColor=late.color
local nextAccent={0.45,0.25,0.65}
repaint(nextAccent,true);assert(same(late.color,oldColor),"combat repaint")
skin.styles.accent.color=nextAccent;repaint(nextAccent,false)
assert(same(late.color,nextAccent))
-- Pool position is not role ownership: the exact native Style can assign any
-- role to the same FontString, while the role is not retained in its fields.
local detail={lines={}}
local pooled=fontString(detail);detail.lines[1]=pooled
Style(pooled,"accent")
local before=pooled.color
local other={0.3,0.8,0.5}
skin.styles.accent.color=other;repaint(other,false)
assert(same(pooled.color,before),"field-only diagnostic must expose the unowned pool gap")
local accentFont=pooled:GetFontObject()
Style(pooled,"good")
assert(pooled:GetFontObject()==accentFont,"native shared-font contract changed")
pooled:SetTextColor(table.unpack(other))
-- The native good/body semantic role and accent role can be observationally
-- equal at the post-draw boundary. Certifying every detail row is unsafe.
local accentPeer=Style(fontString(detail),"accent")
assert(same(accentPeer.color,pooled.color) and accentPeer:GetFontObject()==pooled:GetFontObject())
-- A separate role font can tag FUTURE native Style calls, without RGB matching,
-- but replacing the style font does not retroactively tag pre-existing text.
local unmarked=Style(fontString(detail),"accent")
local roleFont={}
skin.styles.accent.font=roleFont
local tagged=Style(fontString(detail),"accent")
assert(tagged:GetFontObject()==roleFont and unmarked:GetFontObject()~=roleFont)
local roleByFont={[roleFont]="accent"}
assert(roleByFont[tagged:GetFontObject()]=="accent")
assert(roleByFont[semantic:GetFontObject()]==nil)
-- Weak certificates do not keep discarded text alive.
root.abInfo.desc=nil;root.petView.tamed.text=nil;late=nil;recolored=nil
collectgarbage("collect");collectgarbage("collect")
assert(next(certified)==nil,"discarded text retained")
return "PASS: 2000 source-certified static-slot changes; late text/semantic equality/recolor/combat/weak release. EXPECTED BLOCKERS: pooled role not retained; role fonts do not retroactively tag existing text."
"""
lua=ctypes.CDLL("liblua5.4.so.0")
lua.luaL_newstate.restype=ctypes.c_void_p
lua.luaL_openlibs.argtypes=[ctypes.c_void_p]
lua.luaL_loadstring.argtypes=[ctypes.c_void_p,ctypes.c_char_p]
lua.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
lua.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];lua.lua_tolstring.restype=ctypes.c_char_p
lua.lua_close.argtypes=[ctypes.c_void_p]
state=lua.luaL_newstate();lua.luaL_openlibs(state)
try:
 rc=lua.luaL_loadstring(state,lua_source.encode())
 if not rc:rc=lua.lua_pcallk(state,0,1,0,0,None)
 value=lua.lua_tolstring(state,-1,None).decode()
 assert not rc,value
 print("SOURCE_OWNERSHIP_ALTERNATIVES",value)
finally:lua.lua_close(state)
print("No production correction is claimed. The isolated native styler test is not a complete native-addon/client test.")
