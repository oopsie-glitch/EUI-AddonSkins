local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule('WorldQuestTracker', 'World Quest Tracker', function()
    return type(_G.WorldQuestTrackerAddon) == 'table'
        and type(_G.WorldQuestTrackerAddon.OpenOptionsPanel) == 'function'
end, function(API, module)
    local S = ns.CreateSoftSkin(API, module)
    local H = ns.CreateSkinHelper(S, module)
    local W = _G.WorldQuestTrackerAddon
    local states, fonts, roots, visual, pins, rows = {}, {}, {}, {}, {}, {}
    local epoch, waiting = 1, false
    local Scan, Apply, Options, Menus
    local events = CreateFrame('Frame')
    events:RegisterEvent('PLAYER_REGEN_ENABLED')
    local function Ready()
        if not ns.IsEnabled(module) then return false end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return false end
        return true
    end
    local function Frame(value)
        if type(value) ~= 'table' and type(value) ~= 'userdata' then return end
        return value.widget or value
    end
    local function Font(value, neutral, disabled)
        local text = Frame(value)
        if not H.Allowed(text) or text:GetObjectType() ~= 'FontString' then return end
        local path, size, flags = text:GetFont()
        local old = fonts[text]
        if not old or old.epoch ~= epoch or old.path ~= path or old.size ~= size or old.flags ~= flags then
            local r,g,b,a = text:GetTextColor()
            S.Font(text, r,g,b); text:SetTextColor(r,g,b,a)
            path,size,flags = text:GetFont()
            fonts[text] = {epoch=epoch,path=path,size=size,flags=flags}
        end
        if neutral then
            if disabled then text:SetTextColor(.5,.5,.52,1)
            else text:SetTextColor(.9,.9,.92,1) end
        end
    end
    local function Label(f)
        return (f.GetFontString and f:GetFontString()) or f.Text or f.text
    end
    local function Owned(f)
        for _=1,24 do
            if not H.Allowed(f) then return false end
            if roots[f] or rows[f] or pins[f] then return true end
            f=f.GetParent and f:GetParent()
        end
        return false
    end
    local function Art(f)
        if not H.Allowed(f) then return end
        if f.DisableRoundedCorners then f:DisableRoundedCorners() end
        if f.SetBackdrop then f:SetBackdrop(nil) end
        H.Fade(f.__flatBackground)
        if f.NineSlice and H.Allowed(f.NineSlice) then S.FadeNineSlice(f.NineSlice) end
    end
    local function Surface(f, shell)
        local d=states[f] or {};states[f]=d
        if not d.surface then
            d.surface=true
            Art(f)
            if shell then S.Shell(f,{noTopBar=true,noAccent=true})
            else S.Panel(f,{inset=false}) end
            H.Hook(f,'SetBackdrop',function(_,value)if value and Ready()then f:SetBackdrop(nil)end end)
        end
        return d
    end
    local function Readable(f)
        local d=Surface(f,true)
        if not d.light then
            local layer=CreateFrame('Frame',nil,f);visual[layer]=true
            layer:SetAllPoints(f);layer:EnableMouse(false);layer:SetFrameLevel(f:GetFrameLevel())
            d.light={}
            for i=1,2 do
                local t=layer:CreateTexture(nil,'BACKGROUND',nil,-2);d.light[i]=t
                if i==1 then t:SetPoint('TOPLEFT',layer,'TOPLEFT');t:SetPoint('BOTTOMRIGHT',layer,'BOTTOM')
                else t:SetPoint('TOPLEFT',layer,'TOP');t:SetPoint('BOTTOMRIGHT',layer,'BOTTOMRIGHT')end
            end
        end
        if d.lightEpoch~=epoch then
            d.lightEpoch=epoch
            for i,t in ipairs(d.light)do
                t:SetColorTexture(1,1,1,1)
                if t.SetGradientAlpha then
                    t:SetGradientAlpha('HORIZONTAL',.22,.22,.24,i==1 and 0 or .35,.22,.22,.24,i==1 and .35 or 0)
                elseif t.SetGradient and CreateColor then
                    t:SetGradient('HORIZONTAL',CreateColor(.22,.22,.24,i==1 and 0 or .35),CreateColor(.22,.22,.24,i==1 and .35 or 0))
                else t:SetColorTexture(.16,.16,.18,.18)end
            end
        end
    end
    local function Control(f,kind,force)
        local d=states[f]or{};states[f]=d
        local widget=type(f.MyObject)=='table' and f.MyObject or nil
        local method=widget and widget.type
        local disabled=(widget and widget.lockdown)or(f.IsEnabled and not f:IsEnabled())or false
        if not d.control then
            d.control=true
            local function Paint()if Ready()and Owned(f)then Control(f,kind,true)end end
            for _,name in ipairs({'OnEnable','OnDisable','OnShow','OnClick'})do H.Script(f,name,Paint)end
            for _,name in ipairs({'SetTemplate','Enable','Disable','SetEnabled','SetAsCheckBox','SetCheckedTexture'})do H.Hook(widget,name,Paint)end
        end
        if not force and d.controlEpoch==epoch then return end
        d.controlEpoch=epoch
        if method=='switch' then
            f.euiWQTMark=H.Texture(widget.checked_texture)
            f.euiWQTKnob=H.Texture(widget.toggle_knob)
            if not d.base then S.Button(f,{'euiWQTMark','euiWQTKnob','Text','text','label'});d.base=true end
            Art(f)
            if f.euiWQTMark and not widget.is_toggle then
                local t=f.euiWQTMark;t:SetVertexColor(1,1,1,1)
                if disabled then t:SetColorTexture(.4,.4,.4,.8)else t:SetColorTexture(S.GetAccentColor())end
                t:ClearAllPoints();t:SetPoint('TOPLEFT',f,'TOPLEFT',4,-4);t:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',-4,4)
            end
            Font(widget.hasLabel or widget.label,true,disabled)
        elseif method=='dropdown' or kind=='DropdownButton' then
            if not d.base then
                local before={};for _,t in ipairs(H.Regions(f))do before[t]=true end
                local icon=widget and H.Texture(widget.icon);local alpha=icon and icon:GetAlpha()
                S.Dropdown(f)
                if icon then icon:SetAlpha(alpha)end
                for _,t in ipairs(H.Regions(f))do if not before[t]and H.Texture(t)and t.GetDrawLayer and t:GetDrawLayer()=='OVERLAY'then d.arrow=t end end
                d.base=true
            end
            H.Fade(f.statusbar)
            local native=H.Texture(f.arrowTexture)
            if native and d.arrow then H.Fade(d.arrow)end
            for _,t in pairs({base=native or d.arrow,hover=H.Texture(f.arrowTexture2)})do
                t:SetTexture('Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png')
                t:SetTexCoord(0,1,0,1);t:SetSize(10,7);t:ClearAllPoints();t:SetPoint('RIGHT',f,'RIGHT',-7,0)
                t:SetVertexColor(.8,.8,.82,1);t:SetAlpha(1)
            end
            if H.Allowed(f.dropdownframe)then
                roots[f.dropdownframe]=true
                Surface(f.dropdownframe)
                H.Script(f.dropdownframe,'OnShow',function()if Ready()then Scan(f.dropdownframe,true)end end)
            end
        elseif kind=='Slider' then
            H.LegacySlider(f)
            local thumb=f.GetThumbTexture and H.Texture(f:GetThumbTexture())
            if thumb and f.GetOrientation and f:GetOrientation()=='HORIZONTAL'then thumb:SetSize(8,14)end
        elseif kind=='CheckButton' then
            S.Checkbox(f,{borderInset=4,hover=.05})
            for i,getter in ipairs({'GetCheckedTexture','GetDisabledCheckedTexture'})do
                local t=f[getter]and H.Texture(f[getter](f))
                if t then
                    t:SetVertexColor(1,1,1,1)
                    if i==2 or disabled then t:SetColorTexture(.4,.4,.4,.8)else t:SetColorTexture(S.GetAccentColor())end
                    t:ClearAllPoints();t:SetPoint('TOPLEFT',f,'TOPLEFT',6,-6);t:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',-6,6)
                end
            end
        elseif kind=='EditBox' then
            if not d.base then S.EditBox(f,{padInput=false});d.base=true end
        elseif kind=='Button' and Label(f) then
            f.euiWQTIcon=widget and H.Texture(widget.icon)
            if not d.base then S.Button(f,{'euiWQTIcon','Text','text','label'});d.base=true end
            Art(f);Font(Label(f),true,disabled)
        end
        if widget then Font(widget.hasLabel or widget.label,true,disabled)end
    end
    Scan=function(f,force,depth)
        depth=depth or 0
        if depth>16 or not Ready()or not H.Allowed(f)or visual[f]or pins[f]or rows[f]then return end
        local kind=f:GetObjectType()
        if kind=='GameTooltip'or kind=='PlayerModel'or kind=='ModelScene'then return end
        local d=states[f]or{};states[f]=d
        local count=f.GetNumChildren and f:GetNumChildren()or 0
        if not force and d.scanEpoch==epoch and d.count==count then return end
        if kind=='Button'or kind=='CheckButton'or kind=='Slider'or kind=='EditBox'or kind=='DropdownButton'then Control(f,kind,force)end
        for _,text in ipairs(H.Regions(f))do Font(text)end
        if H.Allowed(f.CloseButton)then S.CloseButton(f.CloseButton)end
        if H.Allowed(f.closeButton)then S.CloseButton(f.closeButton)end
        for _,child in ipairs(H.Children(f))do Scan(child,force,depth+1)end
        d.scanEpoch=epoch;d.count=f.GetNumChildren and f:GetNumChildren()or 0
    end
    local function Tabs()
        local container=_G.WQTOptionsPanelContainer
        for i,button in ipairs(container and container.AllButtons or{})do
            local f=Frame(button);local page=Frame(container.AllFrames and container.AllFrames[i])
            if H.Allowed(f)then
                local active=page and page.IsShown and page:IsShown()
                local indicator=H.Texture(button.leftSelectionIndicator)
                if indicator then
                    if active then indicator:SetColorTexture(S.GetAccentColor())else indicator:SetColorTexture(.22,.22,.24,1)end
                end
                Font(Label(f),true,false)
                H.Fade(button.selectedUnderlineGlow)
            end
        end
    end
    Options=function()
        if not Ready()then return end
        local root=_G.WorldQuestTrackerOptionsPanel
        if not H.Allowed(root)then return end
        roots[root]=true;Readable(root)
        local d=states[root]
        if not d.bound then
            d.bound=true;H.Script(root,'OnShow',Options)
            H.Hook(_G.WQTOptionsPanelContainer,'SelectTabByIndex',Tabs)
            for _,button in ipairs(_G.WQTOptionsPanelContainer and WQTOptionsPanelContainer.AllButtons or{})do
                H.Script(Frame(button),'OnClick',Tabs)
            end
        end
        -- All pages are built before OpenOptionsPanel returns. Prepare once,
        -- including hidden tabs, without calling native builders/refresh setters.
        local container=_G.WQTOptionsPanelContainer
        for _,page in ipairs(container and container.AllFrames or{})do
            local name=page.GetName and page:GetName()
            if name then H.Fade(_G[name..'BackgroundTexture']);H.Fade(_G[name..'BackgroundTextureTopLine'])end
            for _,key in ipairs({'gradientBelowTheLine','gradientAboveTheLine'})do
                local texture=Frame(page[key]);if H.Texture(texture)then H.Fade(texture)end
            end
        end
        Scan(root);Tabs()
    end
    local function Pin(f)
        if not H.Allowed(f)then return end
        if not pins[f]then pins[f]={}end
        if not Ready()then return end
        local d=pins[f]
        if d.epoch==epoch then return end
        d.epoch=epoch
        -- Keep rarity, faction, tracking and timed objective overlays native.
        local icon=H.Texture(f.texture)or H.Texture(f.Texture)
        if icon and S.SquareIcon then S.SquareIcon(icon)end
        Font(f.amountText);Font(f.timeLeftText)
    end
    local function Row(f)
        if not H.Allowed(f)then return end
        local d=rows[f]
        if not Ready()then rows[f]=d or {};return end
        if not d or not d.fill then
            d=d or {};rows[f]=d
            for _,key in ipairs({'RightBackground','roundedBackgroundTexture','BackgroupTexture','Circle','Shadow'})do H.Fade(f[key])end
            d.fill=f:CreateTexture(nil,'BACKGROUND',nil,-7);d.fill:SetAllPoints(f)
            d.hover=f:CreateTexture(nil,'HIGHLIGHT');d.hover:SetAllPoints(f);d.hover:SetColorTexture(1,1,1,.1)
        end
        if d.epoch==epoch then return end
        d.epoch=epoch;d.fill:SetColorTexture(.07,.07,.08,.65)
        if H.Texture(f.Icon)and S.SquareIcon then S.SquareIcon(f.Icon)end
        for _,key in ipairs({'Title','Zone','QuestInfomation','YardsDistance','TimeLeft','RewardAmount'})do Font(f[key])end
    end
    local function Window(f)
        if not H.Allowed(f)then return end
        roots[f]=true;Surface(f,true)
        H.Script(f,'OnShow',function()if Ready()then Scan(f,true)end end)
        Scan(f)
    end
    local function MenuOwned(host)
        return Owned(Frame(host))
    end
    Menus=function()
        if not Ready()then return end
        local tip=_G.GameCooltip
        if not tip or not MenuOwned(tip.Host)then return end
        for _,f in pairs({main=tip.frame1,sub=tip.frame2})do
            if H.Allowed(f)then roots[f]=true;Surface(f);Scan(f,true)end
        end
    end
    Apply=function()
        if not Ready()then return end
        waiting=false
        Options()
        for _,name in ipairs({'WorldQuestTrackerFinderFrame','WorldQuestTrackerRareFrame','WorldQuestTrackerSharePanel','WorldQuestTrackerBanPanel','WorldQuestTrackerSummaryPanel','WorldQuestTrackerOribosFlyMasterFrame','WorldQuestTrackerNewsFrame'})do Window(_G[name])end
        for _,name in ipairs({'WorldQuestTrackerParentTapFrame','WorldQuestTrackerDoubleTapFrame'})do
            local f=_G[name];if H.Allowed(f)then roots[f]=true;Scan(f)end
        end
        if H.Allowed(W.WorldSummary)then
            roots[W.WorldSummary]=true
            for _,anchor in pairs(W.WorldSummary.Anchors or{})do Font(anchor.Title)end
        end
        local holder=_G.WorldQuestTrackerScreenPanel_QuestHolder
        if H.Allowed(holder)then
            for _,f in ipairs(H.Children(holder))do if f.worldQuest then Row(f)end end
        end
        for _,pool in pairs({world=W.WorldMapWidgets,zone=W.ZoneWidgetPool,summary=W.WorldSummary and W.WorldSummary.Widgets})do
            for _,f in pairs(pool)do Pin(f)end
        end
        for f in pairs(rows)do Row(f)end
        for f in pairs(pins)do Pin(f)end
        Font(_G.WorldQuestTrackerQuestsHeader and WorldQuestTrackerQuestsHeader.Text)
        S.RefreshSoftBorders();Menus()
    end
    local function Refresh()H.Queue(module,Apply)end
    H.Hook(W,'OpenOptionsPanel',Options)
    for _,name in ipairs({'OpenSharePanel','OpenQuestBanPanel','OpenNewsWindow','RegisterGroupFinderFrameOnLibWindow'})do H.Hook(W,name,Apply)end
    H.Hook(W,'GetOrCreateTrackerWidget',function(index)Row(_G['WorldQuestTracker_Tracker'..index])end)
    H.Hook(W,'CreateWorldMapSquareButton',function(name,index)Pin(_G['WorldQuestTrackerWorldMapPOI'..name..'POI'..index])end)
    H.Hook(W,'CreateZoneWidget',function(index,name)Pin(_G[name..index])end)
    local tip=_G.GameCooltip
    for _,name in ipairs({'ShowCooltip','Show','BuildTooltip','BuildTooltipSecondFrame'})do H.Hook(tip,name,Menus)end
    -- Discover existing pins once; subsequent factories style only their result.
    local parent=_G.WorldQuestTrackerWorldMapPOI
    if H.Allowed(parent)and Ready()then
        for _,f in ipairs(H.Children(parent))do if f.IsWorldQuestButton or f.Texture and f.TextureCustom then Pin(f)end end
    end
    module.refresh=function()epoch=epoch+1;Refresh()end
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh)end
    events:SetScript('OnEvent',function()if waiting then Refresh()end end)
    Refresh()
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition('WorldQuestTracker',DefineSkin)else DefineSkin()end
