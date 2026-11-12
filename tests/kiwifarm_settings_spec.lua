-- Exercise the actual KiwiFarm adapter with native-shaped font writes and menu callbacks.
do
local keys = {"KiwiFarm", "EUIAddonSkinsDB", "InCombatLockdown", "LibStub"}
local original = {}
for _, key in ipairs(keys) do original[key] = _G[key] end

local ns, config, looks, combat = {}, nil, nil, false
ns.IsEnabled = function() return true end
ns.RegisterScopedSkin = function(id, _, definition)
    assert(id == "KiwiFarm")
    config = definition
end
assert(loadfile("EUIAddonSkins/Widgets.lua"))("EUIAddonSkins", ns)
assert(loadfile("EUIAddonSkins/Skins/KiwiFarm.lua"))("EUIAddonSkins", ns)

local writes, hooks, face = 0, 0, "eui-first"
local text = {path="native", size=14, flags="OUTLINE", color={0.1, 0.4, 0.8}}
function text:GetObjectType() return "FontString" end
function text:GetFont() return self.path, self.size, self.flags end
function text:SetFont(path, size, flags)
    writes = writes + 1
    self.path, self.size, self.flags = path, size, flags
    return true
end
KiwiFarm = {
    GetBackdropColor=function() return 1, 1, 1, .6 end,
    GetRegions=function() return text end,
}
EUIAddonSkinsDB = {other={preserved=true}}
InCombatLockdown = function() return combat end
LibStub = nil
local nativeMenuHook
local context = {module={}, MenuOwner=function() end, S={
    GetFont=function() return face end,
    OnLooksChanged=function(fn) looks=fn end,
}, H={
    Allowed=function(value) return value~=nil end,
    Hook=function(owner, key, fn)
        if owner==_G then nativeMenuHook=fn; return end
        if owner~=text then return end
        local native=owner[key]
        owner[key]=function(self,...)
            local result=native(self,...)
            fn()
            return result
        end
        hooks=hooks+1
    end,
}}
local notified
ns.SettingsPreferenceChanged = function(id, key) assert(id=="KiwiFarm"); notified=key end
config.hooks(context)
local settings=context.module.settingsAppearance
assert(settings.get("useEUIFont")==true and EUIAddonSkinsDB.kiwiFarm==nil)
assert(text.path=="eui-first" and text.size==14 and text.flags=="" and hooks==1)
local settled=writes
for _=1,100 do looks() end
assert(writes==settled and hooks==1, "unchanged looks rewrote fonts")
face="eui-second"; looks()
assert(text.path=="eui-second" and text.size==14)
settings.set("useEUIFont",false)
assert(text.path=="native" and text.size==14 and text.flags=="OUTLINE")
assert(notified=="useEUIFont" and EUIAddonSkinsDB.kiwiFarm.useEUIFont==false)
text:SetFont("native-new",13,"THICKOUTLINE")
face="eui-third"; looks()
assert(text.path=="native-new" and text.flags=="THICKOUTLINE" and text.color[3]==0.8)
settings.set("useEUIFont",true)
assert(text.path=="eui-third" and text.size==13)
text:SetFont("native-layout",12,"OUTLINE")
assert(text.path=="eui-third" and text.size==12, "native layout size was lost")
settings.set("useEUIFont",false)
assert(text.path=="native-layout" and text.flags=="OUTLINE")
combat=true; settings.set("useEUIFont",true)
assert(text.path=="native-layout", "font changed during combat")
combat=false; looks()
assert(text.path=="eui-third" and hooks==1)

local menu={{text="Appearance",menuList={}}}
nativeMenuHook({GetName=function() return "KiwiFarmPopupMenu" end},nil,nil,nil,menu)
local options=menu[1].menuList[1].menuList
local font=options[#options-1]
assert(font.checked()); font.func()
assert(not settings.get("useEUIFont") and text.path=="native-layout")
settings.set("opacitySource","native")
assert(settings.get("backgroundOpacity")==60 and EUIAddonSkinsDB.kiwiFarm.backgroundOpacity=="native")
settings.set("opacitySource","custom")
assert(settings.get("backgroundOpacity")==90)
for _, percent in ipairs({0,75,100}) do
    settings.set("backgroundOpacity",percent); settings.set("menuOpacity",percent)
    assert(settings.get("backgroundOpacity")==percent and settings.get("menuOpacity")==percent)
end
options[#options].func()
assert(EUIAddonSkinsDB.kiwiFarm==nil and EUIAddonSkinsDB.other.preserved)
assert(settings.get("useEUIFont") and text.path=="eui-third")
for _, key in ipairs(keys) do _G[key]=original[key] end
print("PASS: KiwiFarm native and centralized settings, font ownership, no repeated writes, and reset")
end
