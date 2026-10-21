local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule('WorldQuestsList','World Quests List',function()
    return _G.WorldQuestList and type(_G.WorldQuestList.UpdateList)=='function'
end,function(API,module)
    local S=ns.CreateSoftSkin(API,module)
    local H=ns.CreateSkinHelper(S,module)
    local W=_G.WorldQuestList
    local styled,fonts,rows,visual={},{},{},{}
    local epoch,lastRow,waiting=1,0,false
    local Walk,Apply,Dialog,Menu
    local events=CreateFrame('Frame');events:RegisterEvent('PLAYER_REGEN_ENABLED')
    local function Ready()
        if not ns.IsEnabled(module)then return false end
        if InCombatLockdown and InCombatLockdown()then waiting=true;return false end
        return true
    end
    local function Font(t)
        if not H.Allowed(t)or t:GetObjectType()~='FontString'then return end
        local path,size,flags=t:GetFont();if not path then return end
        local old=fonts[t]
        if old and old.epoch==epoch and old.path==path and old.size==size and old.flags==flags then return end
        local r,g,b,a=t:GetTextColor();S.Font(t,r,g,b);t:SetTextColor(r,g,b,a)
        path,size,flags=t:GetFont();fonts[t]={epoch=epoch,path=path,size=size,flags=flags}
    end
    local function Borders(f)
        for _,key in ipairs({'BorderTop','BorderBottom','BorderLeft','BorderRight','borderLeft','borderRight'})do H.Fade(f[key])end
        for _,t in ipairs(H.Regions(f))do
            local path=t.GetTexture and t:GetTexture()
            if type(path)=='string'and path:lower():find('worldquestslist[/\\]shadow')then H.Fade(t)end
        end
        if H.Allowed(f.shadow)then H.Fade(f.shadow)end
    end
    local function Surface(f,shell)
        if not H.Allowed(f)then return end
        local d=styled[f]or{};styled[f]=d
        if not d.surface then
            d.surface=true;Borders(f)
            if f.SetBackdrop then f:SetBackdrop(nil)end
            if shell then S.Shell(f,{noTopBar=true,noAccent=true})else S.Panel(f,{inset=false})end
        end
        return d
    end
    local function Hover(t,alpha)
        if H.Texture(t)then t:SetTexture('Interface\\Buttons\\WHITE8X8');t:SetVertexColor(1,1,1,alpha or .15)end
    end
    local function Glyph(t,up)
        if not H.Texture(t)then return end
        t:SetTexture('Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png')
        t:SetTexCoord(0,1,0,1);t:SetSize(10,7);t:SetVertexColor(.8,.8,.82,1)
        if t.SetRotation then t:SetRotation(up and math.pi or 0)end
    end
    local function Check(f)
        local d=styled[f]or{};styled[f]=d
        if not d.check then
            d.check=true;Borders(f)
            S.Checkbox(f,{borderInset=1,hover=.1})
            local function Paint()if Ready()then Check(f)end end
            H.Script(f,'OnEnable',Paint);H.Script(f,'OnDisable',Paint)
        end
        local disabled=f.IsEnabled and not f:IsEnabled()
        -- Custom ELib menu checks are only 12px wide. Fixed inset prevents
        -- the larger default CheckButton geometry from clipping them.
        local inset=(f:GetWidth()<=14)and 3 or 6
        for i,getter in ipairs({'GetCheckedTexture','GetDisabledCheckedTexture','GetPushedTexture'})do
            local t=f[getter]and H.Texture(f[getter](f))
            if t then
                t:SetVertexColor(1,1,1,1)
                if disabled or i==2 then t:SetColorTexture(.4,.4,.4,.8)else t:SetColorTexture(S.GetAccentColor())end
                t:ClearAllPoints();t:SetPoint('TOPLEFT',f,'TOPLEFT',inset,-inset);t:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',-inset,inset)
            end
        end
        Font(f.text)
    end
    local function Slider(f)
        local d=styled[f]or{};styled[f]=d
        if not d.slider then d.slider=true;Borders(f);H.LegacySlider(f)end
        local t=f.GetThumbTexture and H.Texture(f:GetThumbTexture())
        if t then
            if f.GetOrientation and f:GetOrientation()=='HORIZONTAL'then t:SetSize(8,14)else t:SetSize(6,18)end
            t:SetColorTexture(S.GetAccentColor())
        end
        Font(f.text)
    end
    local function Button(f)
        local d=styled[f]or{};styled[f]=d
        if not d.button then
            d.button=true;Borders(f)
            S.Button(f,{'Icon','icon','X','text','Text','NormalText','t'})
            local function Tone()
                if not Ready()then return end
                local t=(f.GetFontString and f:GetFontString())or f.X or f.text or f.Text
                Font(t)
                if H.Allowed(t)and t.SetTextColor then
                    if f.IsEnabled and not f:IsEnabled()then t:SetTextColor(.5,.5,.52,1)else t:SetTextColor(.9,.9,.92,1)end
                end
            end
            H.Script(f,'OnEnable',Tone);H.Script(f,'OnDisable',Tone)
            H.Script(f,'OnEnter',Tone);H.Script(f,'OnLeave',Tone)
            Tone()
        end
        Hover(f.hl,.14)
    end
    Walk=function(f,depth)
        depth=depth or 0
        if depth>12 or not H.Allowed(f)or visual[f]or not Ready()then return end
        local kind=f:GetObjectType()
        if kind=='GameTooltip'or kind=='PlayerModel'or kind=='ModelScene'then return end
        if kind=='CheckButton'then Check(f)
        elseif kind=='Slider'then Slider(f)
        elseif kind=='EditBox'then
            local d=styled[f]or{};styled[f]=d
            if not d.input then d.input=true;S.EditBox(f,{padInput=false})end
        elseif kind=='Button'then
            if (f.GetFontString and f:GetFontString())or f.X then Button(f)end
        end
        Borders(f)
        for _,t in ipairs(H.Regions(f))do Font(t)end
        for _,child in ipairs(H.Children(f))do Walk(child,depth+1)end
    end
    local function Row(f)
        if not H.Allowed(f)then return end
        if rows[f]==epoch then return end
        rows[f]=epoch
        for _,key in ipairs({'name','reward','faction','timeleft','zone'})do Font(f[key])end
        if f.LFGButton then Font(f.LFGButton.text)end
        Hover(f.hl,.16)
        -- New/important quest indicators keep their native colours/visibility.
    end
    local function Discover()
        if not Ready()then return end
        local count=#(W.l or{})
        for i=lastRow+1,count do Row(W.l[i])end
        lastRow=count
    end
    local function Dropdown(f)
        if not H.Allowed(f)then return end
        Surface(f);H.Fade(f.b);H.Fade(f.l);Font(f.t)
        local b=f.Button
        if H.Allowed(b)then Hover(b.hl,.16);Glyph(b.i)end
    end
    Menu=function(f)
        if not Ready()or not H.Allowed(f)then return end
        Surface(f);H.Fade(f.Background)
        for _,button in ipairs(f.Buttons or{})do
            local d=styled[button]or{};styled[button]=d
            if not d.menu then
                d.menu=true
                local function PaintFont()if Ready()then Font(button.NormalText)end end
                -- Reload resets FontObjects after showing the popup. Repair the
                -- owned label synchronously, without replacing private ELib code.
                H.Hook(button,'SetNormalFontObject',PaintFont)
                H.Hook(button,'SetHighlightFontObject',PaintFont)
                H.Script(button,'OnShow',PaintFont)
            end
            Font(button.NormalText);Hover(button.Highlight,.17)
            local arrow=H.Texture(button.Arrow)
            if arrow then
                arrow:SetTexture('Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-right.png')
                arrow:SetTexCoord(0,1,0,1);arrow:SetSize(8,10);arrow:SetVertexColor(.8,.8,.82,1)
            end
            if H.Allowed(button.checkButton)then Check(button.checkButton)end
            if H.Allowed(button.radioButton)then Check(button.radioButton)end
            if H.Allowed(button.slider)then Slider(button.slider)end
        end
    end
    Dialog=function(f)
        if not Ready()or not H.Allowed(f)then return end
        local d=Surface(f,true)
        if d.walkEpoch~=epoch then Walk(f);d.walkEpoch=epoch end
        local function Pool(pool)
            for _,row in pairs(pool or{})do
                if H.Allowed(row)then
                    local r=styled[row]or{};styled[row]=r
                    if r.walkEpoch~=epoch then Walk(row);r.walkEpoch=epoch end
                end
            end
        end
        if f.created and not d.created then
            Walk(f);d.created=true
        end
        Pool(f.L);Pool(f.lines);Pool(f.buttons)
        if H.Allowed(f.Close)and not d.close then d.close=true;H.Fade(f.Close.X);S.CloseButton(f.Close)end
        for _,row in pairs(f.buttons or{})do
            if H.Allowed(row.moveTop)then Glyph(row.moveTop.tex,true)end
            if H.Allowed(row.moveBot)then Glyph(row.moveBot.tex)end
        end
    end
    local light
    local function Background()
        if not H.Allowed(W)or not H.Texture(W.b)then return end
        W.b:SetColorTexture(.065,.065,.072,.97)
        if not light then
            light=CreateFrame('Frame',nil,W);visual[light]=true;light:EnableMouse(false)
            light:SetAllPoints(W);light:SetFrameLevel(W:GetFrameLevel());light.parts={}
            for i=1,2 do
                local t=light:CreateTexture(nil,'BACKGROUND');light.parts[i]=t
                if i==1 then t:SetPoint('TOPLEFT',light,'TOPLEFT');t:SetPoint('BOTTOMRIGHT',light,'BOTTOM')
                else t:SetPoint('TOPLEFT',light,'TOP');t:SetPoint('BOTTOMRIGHT',light,'BOTTOMRIGHT')end
                t:SetColorTexture(.17,.17,.19,.14)
                if t.SetGradient and CreateColor then
                    t:SetColorTexture(1,1,1,1)
                    t:SetGradient('HORIZONTAL',CreateColor(.18,.18,.2,i==1 and 0 or .22),CreateColor(.18,.18,.2,i==1 and .22 or 0))
                elseif t.SetGradientAlpha then
                    t:SetColorTexture(1,1,1,1)
                    t:SetGradientAlpha('HORIZONTAL',.18,.18,.2,i==1 and 0 or .22,.18,.18,.2,i==1 and .22 or 0)
                end
            end
            local function Opacity()if Ready()then light:SetAlpha(W.b:GetAlpha())end end
            H.Hook(W.b,'SetAlpha',Opacity);Opacity()
        end
    end
    Apply=function()
        if not Ready()then return end
        waiting=false;Background()
        if H.Allowed(W.backdrop)then Borders(W.backdrop)end
        H.Fade(W.shadow)
        if H.Allowed(W.Close)then
            local d=styled[W.Close]or{};styled[W.Close]=d
            if not d.close then d.close=true;H.Fade(W.Close.X);S.CloseButton(W.Close)end
        end
        for _,key in ipairs({'header','footer','moveHeader'})do
            local f=W[key]
            if H.Allowed(f)then
                for _,t in ipairs(H.Regions(f))do Font(t)end
                if H.Texture(f.b)then f.b:SetColorTexture(.13,.13,.145,1)end
                Borders(f)
            end
        end
        for _,key in ipairs({'sortDropDown','filterDropDown','optionsDropDown','moveHeader'})do Dropdown(W[key])end
        if H.Allowed(W.modeSwitcherCheck)then Surface(W.modeSwitcherCheck);H.Fade(W.modeSwitcherCheck.b);Slider(W.modeSwitcherCheck.s)end
        if H.Allowed(W.ViewAllButton)then Walk(W.ViewAllButton)end
        if H.Allowed(W.oppositeContinentButton)then Dropdown(W.oppositeContinentButton);Walk(W.oppositeContinentButton)end
        if H.Allowed(W.WorldMapHideWQLCheck)then Check(W.WorldMapHideWQLCheck)end
        Discover();for f in pairs(rows)do Row(f)end
        for _,key in ipairs({'BlackListWindow','SortPriorWindow'})do
            local f=W[key]
            if H.Allowed(f)then
                H.Script(f,'OnShow',function()Dialog(f)end)
                H.Hook(f,'Update',function()Dialog(f)end)
                H.Hook(f,'UpdateMode2',function()Dialog(f)end)
                -- Only an already constructed dialog is walked at startup.
                if f.created or f.IsShown and f:IsShown()then Dialog(f)end
            end
        end
        for i=1,3 do
            local f=_G['WQL_ExRTDropDownListModern'..i]
            if H.Allowed(f)then H.Script(f,'OnShow',function()Menu(f)end);if f:IsShown()then Menu(f)end end
        end
        S.RefreshSoftBorders()
    end
    -- Every native list mode finishes by sizing its content frame, including
    -- private updater calls that bypass the exported UpdateList alias. Only
    -- newly appended rows are visited; warm updates are constant work.
    H.Hook(W.C,'SetHeight',Discover)
    H.Script(W,'OnShow',Discover)
    module.refresh=function()epoch=epoch+1;H.Queue(module,Apply)end
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh)end
    events:SetScript('OnEvent',function()if waiting then H.Queue(module,Apply)end end)
    H.Queue(module,Apply)
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition('WorldQuestsList',DefineSkin)else DefineSkin()end
