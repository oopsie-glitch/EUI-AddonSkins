-- Optional actual upstream dropdown exercise. GPL target source is supplied at
-- test time; no target implementation/assets are copied into this repository.
return function(ctx)
    local oldCreate, oldWipe = CreateFrame, table.wipe
    local function noop() end
    local function region(t)
        t.SetJustifyH,t.SetJustifyV,t.SetNonSpaceWrap=noop,noop,noop
        function t:Hide()self.shown=false end
        function t:Show()self.shown=true end
        function t:GetWidth()return self.width or #(self.text or '')*7 end
        function t:GetHeight()return self.height or 12 end
        return t
    end
    CreateFrame=function(...)
        local f=oldCreate(...)
        function f:SetHeight(n)self.height=n end
        f.RegisterForClicks,f.SetFrameStrata=noop,noop
        function f:SetFrameLevel(n)self.level=n end
        function f:GetFrameLevel()return self.level or 1 end
        function f:GetWidth()return self.width or 24 end
        function f:GetHeight()return self.height or 24 end
        function f:SetParent(p)
            if self.parent==p then return end
            if self.parent then for i=#self.parent.children,1,-1 do if self.parent.children[i]==self then table.remove(self.parent.children,i)end end end
            self.parent=p;if p then p.children[#p.children+1]=self end
        end
        local ct,cf=f.CreateTexture,f.CreateFontString
        function f:CreateTexture(...)return region(ct(self,...))end
        function f:CreateFontString(...)return region(cf(self,...))end
        for _,name in ipairs({'Normal','Pushed','Highlight','Disabled'})do
            f['Set'..name..'Texture']=function(self,path)local t=self:CreateTexture();t:SetTexture(path);self[name:lower()]=t end
            f['Get'..name..'Texture']=function(self)return self[name:lower()]end
        end
        return f
    end
    table.wipe=function(t)for k in pairs(t)do t[k]=nil end;return t end
    ctx.gui.Temp_SetParPoint=function(self,parent)self.frame:SetParent(parent)end
    assert(loadfile(ctx.source..'/GUI/Template_DropDown.lua'))('AtlasLoot', {BOX_BORDER_BACKDROP={bgFile='native'}})
    local dd=ctx.gui.CreateDropDown();dd.frame:SetParent(ctx.root)
    local selected
    dd:SetButtonOnClick(function(_,id,arg,user)selected={id,arg,user}end)
    local data={{info={name='Loot',bgColor={.1,.1,.1,1}},
        {id='epic',name='Epic',color={.6,.2,.9},arg=42},
        {id='common',name='Common',color={1,1,1},arg=1}}}
    dd:SetData(data,'epic');ctx.module.refresh();ctx.flush()
    assert(dd.frame.dropdown and dd.frame.button.glyph=='v')
    dd:Toggle()
    local cat
    for _,child in ipairs(dd.frame.children)do if child.buttons then cat=child end end
    assert(cat and cat.panel and cat.buttons[1].button,'native popup not synchronously skinned')
    assert(cat.buttons[1].label.textColor[3]==.9,'native quality label recoloured')
    cat.buttons[1].hooks.OnClick(cat.buttons[1]);ctx.flush()
    assert(selected[1]=='epic' and selected[2]==42 and selected[3]==true,'native click payload changed')
    dd:SetData({{info={name='Small'},data[1][2]}},'common');dd:Toggle();ctx.flush()
    assert(#cat.buttons==1 and cat.buttons[1].id=='common','native pool did not shrink/reuse')
    local toggle=dd.Toggle
    for i=1,20 do dd:Toggle();ctx.flush()end
    assert(dd.Toggle==toggle,'reused native dropdown accumulated hooks')
    dd:Clear();ctx.flush()
    CreateFrame,table.wipe=oldCreate,oldWipe
    print('PASS: '..ctx.variant..' actual Template_DropDown: constructor, synchronous popup, semantic text, click args, pool shrink/reopen, hook reuse')
end
