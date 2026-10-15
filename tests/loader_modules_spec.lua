local ns, entries, errors = {}, {}, {}
EUIAddonSkinsDB={}; SlashCmdList={}; DEFAULT_CHAT_FRAME={AddMessage=function() end}
UnitName=function() return 'Fixture' end; UnitGUID=function() return 'Player-Fixture' end
InCombatLockdown=function() return false end
C_Timer={After=function() end}
geterrorhandler=function() return function(e) errors[#errors+1]=e end end
CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
C_AddOns={GetAddOnInfo=function(name) return name end,GetAddOnEnableState=function() return 2 end,
    IsAddOnLoaded=function() return true end,LoadAddOn=function() error('unexpected module load') end}
EllesmereUI={RegisterSkin=function(name,fn)
    assert(not entries[name]); entries[name]=true; fn({IsEnabled=function() return true end})
end}
for line in io.lines('EUIAddonSkins/EUIAddonSkins.toc') do
    if line:match('%.lua$') then assert(loadfile('EUIAddonSkins/'..line:gsub('\\','/')))('EUIAddonSkins',ns) end
end
assert(#ns.modules==20 and #errors==0,table.concat(errors,'; '))
for _,entry in ipairs(ns.skinCatalog) do
    assert(entry.defined and entry.loaded and not entry.factory and entries['EUI AddonSkins - '..entry.label])
    local found; for _,module in ipairs(ns.modules) do if module.id==entry.id then found=module end end
    assert(found and found.skin==entry.skin and found.registered)
end
UnitName,UnitGUID=nil,nil
print('PASS: actual one-folder TOC defines and activates all twenty stable skins once while preserving shared callbacks and EUI toggle facades')
