-- Shared options category, saved preferences and modern/legacy registration.
local oldSettings,oldLegacy,oldOpen=Settings,InterfaceOptions_AddCategory,InterfaceOptionsFrame_OpenToCategory
local function environment(modern,db)
    local frames,categories,opened={},0,nil
    EUIAddonSkinsDB=db;RXP=nil;Details=nil;SlashCmdList={}
    UIParent={}
    CreateFrame=function(kind,name,parent)
        local f={kind=kind,name=name,parent=parent,hooks={},events={},texts={}}
        function f:SetPoint(...)self.point={...}end
        function f:RegisterEvent(event)self.events[event]=true end
        function f:SetScript(event,fn)self.hooks[event]=fn end
        function f:HookScript(event,fn)local old=self.hooks[event];self.hooks[event]=function(...)if old then old(...)end;fn(...)end end
        function f:SetChecked(value)self.checked=value end
        function f:GetChecked()return self.checked end
        function f:CreateFontString(_,_,template)
            local t={template=template}
            function t:SetPoint(...)self.point={...}end
            function t:SetText(value)self.text=value end
            self.texts[#self.texts+1]=t;return t
        end
        frames[#frames+1]=f;return f
    end
    local function registered(panel,name)
        assert(panel.name=='EUI AddonSkins' and (not name or name==panel.name),'category still named for Details only')
        categories=categories+1
        return {GetID=function()return 123 end}
    end
    Settings=modern and {RegisterCanvasLayoutCategory=registered,RegisterAddOnCategory=function()end,
        OpenToCategory=function(id)opened=id end} or nil
    InterfaceOptions_AddCategory=modern and nil or registered
    InterfaceOptionsFrame_OpenToCategory=function(panel)opened=panel end
    local ns={}
    assert(loadfile('EUIAddonSkins/DetailsSettings.lua'))('EUIAddonSkins',ns)
    for _,f in ipairs(frames)do if f.events.PLAYER_LOGIN then f.hooks.OnEvent(f,'PLAYER_LOGIN')end end
    local panel=ns.CreateDetailsSettingsPanel()
    ns.CreateDetailsSettingsPanel();SlashCmdList.EUIDETAILS()
    assert(categories==1 and opened==(modern and 123 or panel),'shared panel registered twice or broke existing shortcut')
    assert(panel.menus and panel.meter and panel.tiny and panel.rxpArrow,'existing controls or arrow toggle missing')
    assert(panel.meter.texts[1].text=='Legacy Details! Styling','legacy settings label not renamed')
    local explained=false
    for _,text in ipairs(panel.texts) do if text.text:find('Older automatic styling',1,true) then explained=true end end
    assert(explained,'legacy settings did not distinguish native skin selection')
    return ns,panel
end
for _,modern in ipairs({true,false})do
    local db={details={menus=false,meter=true,tiny=false},unrelated={kept=true}}
    local ns,panel=environment(modern,db)
    assert(ns.RXPSettings().arrow==true,'existing installations lost the current arrow by default')
    panel.rxpArrow.hooks.OnShow(panel.rxpArrow);assert(panel.rxpArrow:GetChecked())
    local calls=0;ns.RXPSettingsChanged=function()calls=calls+1 end
    panel.rxpArrow:SetChecked(false);panel.rxpArrow.hooks.OnClick(panel.rxpArrow)
    assert(db.rxp.arrow==false and calls==1,'arrow checkbox did not save/apply its preference')
    panel.rxpArrow.hooks.OnClick(panel.rxpArrow);assert(calls==1,'unchanged preference re-applied arrow')
    assert(db.details.menus==false and db.details.meter==true and db.details.tiny==false
        and db.unrelated.kept,'arrow setting changed existing saved preferences')
    local detailsCalls=0;ns.DetailsSettingsChanged=function()detailsCalls=detailsCalls+1 end
    panel.menus:SetChecked(true);panel.menus.hooks.OnClick(panel.menus)
    assert(db.details.menus and detailsCalls==1 and calls==1,'Details callback changed or arrow callback cross-fired')
    ns.SetRXPSetting('unknown',true);assert(db.rxp.unknown==nil and calls==1)
    db.rxp.arrow=true;panel.rxpArrow.hooks.OnShow(panel.rxpArrow);assert(panel.rxpArrow:GetChecked(),'checkbox stale after saved preference change')
    ns.SetRXPSetting('arrow',false)
    -- A new load with no target installed preserves off, without activating a skin.
    local reloaded,otherPanel=environment(modern,db)
    assert(reloaded.RXPSettings().arrow==false and db.details.meter==true,'reload reset saved arrow choice or Details settings')
    otherPanel.rxpArrow.hooks.OnShow(otherPanel.rxpArrow);assert(not otherPanel.rxpArrow:GetChecked())
    otherPanel.rxpArrow:SetChecked(true);otherPanel.rxpArrow.hooks.OnClick(otherPanel.rxpArrow)
    assert(db.rxp.arrow==true,'preference could not be set while RestedXP was absent')
end
-- Fresh getters do not bind/write defaults; explicit existing API initialization
-- retains exactly the historical Off / Off / On behavior.
for _,modern in ipairs({true,false}) do
    local ns,panel=environment(modern,nil)
    assert(not ns.ReadDetailsSetting('meter') and not ns.ReadDetailsSetting('tiny') and ns.ReadDetailsSetting('menus'))
    assert(EUIAddonSkinsDB==nil,'label/default read initialized SavedVariables')
    local cfg=ns.DetailsSettings()
    assert(cfg.meter==false and cfg.tiny==false and cfg.menus==true)
    for _,saved in ipairs({
        {meter=true,tiny=false,menus=false},
        {meter=false,tiny=true,menus=true},
        {meter=true,menus=true},
    }) do
        local oldTiny=saved.tiny
        local context=environment(modern,{details=saved})
        assert(context.ReadDetailsSetting('meter')==saved.meter and context.ReadDetailsSetting('menus')==saved.menus)
        assert(context.ReadDetailsSetting('tiny')==(oldTiny~=nil and oldTiny or oldTiny==nil and saved.meter))
        assert(saved.tiny==oldTiny,'reading older saves migrated a preference')
        local persisted=context.DetailsSettings()
        assert(persisted.meter==saved.meter and persisted.menus==saved.menus)
        if oldTiny~=nil then assert(persisted.tiny==oldTiny) end
    end
end
print('PASS: Legacy Details! Styling label, shared meter key, fresh Off/Off/On defaults, explicit saves and historical Tiny Threat inheritance')
Settings,InterfaceOptions_AddCategory,InterfaceOptionsFrame_OpenToCategory=oldSettings,oldLegacy,oldOpen
print('PASS: shared addon options, modern/legacy category, persistent arrow toggle, missing targets, preserved Details settings and shortcut')
