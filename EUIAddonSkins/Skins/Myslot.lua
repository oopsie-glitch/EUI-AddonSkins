local ADDON, ns = ...
local function DefineSkin()
local function Public()
    return LibStub and LibStub("Myslot-5.0", true)
end
local canvas
local headings = {Myslot = true, Unsaved = true, [(TALENTS or 'Talents') .. ':'] = true}
local painted, outlines, captionHooks = setmetatable({}, {__mode='k'}), setmetatable({}, {__mode='k'}), setmetatable({}, {__mode='k'})
local function Options()
    if canvas then return canvas end
    if Settings and Settings.GetCategory and SettingsPanel and SettingsPanel.GetLayout then
        local ok, frame = pcall(function()
            local category = Settings.GetCategory('Myslot')
            local layout = category and SettingsPanel:GetLayout(category)
            return layout and layout.GetFrame and layout:GetFrame()
        end)
        if ok and frame then canvas = frame end
    end
    if not canvas then
        for _, frame in ipairs(INTERFACEOPTIONS_ADDONCATEGORIES or {}) do
            if frame.name == 'Myslot' then canvas = frame; break end
        end
    end
    return canvas
end
local function AccentCaption(C, text)
    if not text or not text.GetText or not text.SetTextColor then return end
    local value = text:GetText()
    if type(value) ~= 'string' then return end
    local plain = value:gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', '')
    if not headings[plain] then return end
    local r,g,b = C.S.GetAccentColor()
    if plain ~= value and text.SetText then
        -- Only recognised cosmetic headings lose embedded yellow markup.
        -- Profile/import text, class/status colours and danger text never enter.
        local state = captionHooks[text]
        if state and state.busy then return end
        if state then state.busy = true end
        text:SetText(plain)
        if state then state.busy = false end
    end
    text:SetTextColor(r,g,b)
end
local function Outline(f)
    if outlines[f] or not f.CreateTexture then return end
    outlines[f] = true
    for _, side in ipairs({'TOP','BOTTOM','LEFT','RIGHT'}) do
        local edge=f:CreateTexture(nil,'BORDER');edge:SetColorTexture(.26,.26,.26,1)
        if side=='TOP' or side=='BOTTOM' then
            edge:SetPoint(side..'LEFT',f,side..'LEFT');edge:SetPoint(side..'RIGHT',f,side..'RIGHT');edge:SetHeight(1)
        else
            edge:SetPoint('TOP'..side,f,'TOP'..side);edge:SetPoint('BOTTOM'..side,f,'BOTTOM'..side);edge:SetWidth(1)
        end
    end
end
local function Captions(C, f)
    for _, text in ipairs(C.H.Regions(f)) do
        if text.GetObjectType and text:GetObjectType()=='FontString' and text.GetText then
            local value=text:GetText()
            local plain=type(value)=='string' and value:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')
            -- The Unsaved caption starts empty and is populated only after
            -- export/edit. Observe owned non-action labels before that happens.
            if headings[plain] or not (f.GetFontString and f:GetFontString()==text) then
                if not captionHooks[text] then
                    captionHooks[text]={}
                    C.H.Hook(text,'SetText',function() if not captionHooks[text].busy then AccentCaption(C,text) end end)
                end
                AccentCaption(C,text)
            end
        end
    end
end
local function MenuReady(C)
    local manager=Menu and Menu.GetManager and Menu.GetManager()
    local list=manager and manager.GetOpenMenu and manager:GetOpenMenu()
    local lib=Public();local main=lib and lib.MainFrame
    local owner=list and list.GetOwnerRegion and list:GetOwnerRegion()
    local ancestor=owner
    for _=1,12 do
        if not ancestor then break end
        if ancestor==main and C.H.Allowed(list) and ns.BindPopupList then
            ns.BindPopupList(C.S,C.module,owner,list);return
        end
        ancestor=ancestor.GetParent and ancestor:GetParent()
    end
end
ns.RegisterScopedSkin('Myslot','Myslot',{
    softBorders=true,
    preserveTextColors=true,
    immediateShow=true,
    available=function()local lib=Public();return (lib and lib.MainFrame~=nil)or(C_AddOns and C_AddOns.IsAddOnLoaded('Myslot'))end,
    roots=function(C)
        local roots={};local lib=Public()
        if lib and lib.MainFrame then roots[#roots+1]={frame=lib.MainFrame,options={bottomBar=38,noTopBar=true,noAccent=true}} end
        local panel=Options()
        if C.H.Allowed(panel) then roots[#roots+1]={frame=panel,mode='controls'}end
        return roots
    end,
    -- Static controls already have native state handlers. Clicks only need to
    -- bind a completed popup, not traverse the editor/options tree again.
    controlRefresh=function(C)MenuReady(C)end,
    hooks=function(C)
        C.H.Hook(Settings,'RegisterCanvasLayoutCategory',function(frame,name)
            if name=='Myslot' then canvas=frame;C.module.refresh()end
        end)
        C.H.Hook(SettingsPanel,'DisplayCategory',function(_,category)
            if category and category.GetName and category:GetName()=='Myslot' then
                local panel=Options();if C.H.Allowed(panel)then C.RefreshControlsNow(panel)end
            end
        end)
        local manager=Menu and Menu.GetManager and Menu.GetManager()
        C.H.Hook(manager,'OpenMenu',function()MenuReady(C)end)
    end,
    visit=function(C,f,kind)
        Captions(C,f)
        if kind=='EditBox' and f.IsMultiLine and f:IsMultiLine() then
            -- Keep the encoded profile byte-for-byte, including all editor
            -- geometry, selection/focus handlers and native text callbacks.
            if not painted[f] and f.SetFont and f.GetFont then
                local _,size=f:GetFont();local path,flags=C.S.GetFont()
                f:SetFont(path,size or 12,flags or '');painted[f]=true
            end
            return true
        end
        if kind=='Slider' and f.GetThumbTexture then
            C.H.LegacySlider(f)
            local thumb=f:GetThumbTexture()
            if C.H.Texture(thumb) then
                thumb:SetAlpha(0)
                local grip=painted[f]
                if not grip then
                    grip=f:CreateTexture(nil,'ARTWORK');grip:SetPoint('CENTER',thumb,'CENTER');grip:SetSize(6,18);painted[f]=grip
                    local function Visible()grip:SetAlpha((not thumb.IsShown or thumb:IsShown())and 1 or 0)end
                    for _,method in ipairs({'Show','Hide','SetShown'})do C.H.Hook(thumb,method,Visible)end
                    Visible()
                end
                grip:SetColorTexture(C.S.GetAccentColor())
            end
            return true
        end
        if kind=='CheckButton' then
            if not painted[f]then C.S.Checkbox(f);painted[f]=true end
            if f.text and f.text.SetTextColor then f.text:SetTextColor(.9,.9,.92)end
            return true
        end
        if kind=='Button' then
            C.MenuOwner(f)
            if not painted[f] then
                local arrows,icons,keep={},{},{}
                for _,texture in ipairs(C.H.Regions(f))do
                    local path=texture.GetTexture and texture:GetTexture()
                    if type(path)=='string' then
                        if path:find('ChatFrameExpandArrow',1,true)then arrows[#arrows+1]=texture
                        elseif path:lower():find('interface',1,true) and (path:lower():find('icons',1,true)
                            or path:find('UI-ChatIcon',1,true))then
                            local key='euiMyslotArt'..(#icons+1)
                            f[key]=texture;keep[#keep+1]=key;icons[#icons+1]={texture,texture:GetAlpha()}
                        end
                    end
                end
                local label=f.GetFontString and f:GetFontString()
                if not label and f.GetWidth and f:GetWidth()>150 then
                    C.S.Dropdown(f)
                    for _,texture in ipairs(C.H.Regions(f))do
                        if texture.GetAtlas and texture:GetAtlas()=='Azerite-PointingArrow'then
                            texture:SetTexture('Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png')
                            texture:SetVertexColor(.8,.8,.8,1)
                        end
                    end
                elseif #arrows>0 and (not f.GetWidth or f:GetWidth()<=40) then
                    C.S.PageButton(f,'v')
                else
                    C.S.Button(f,keep)
                    if C.S.StateButtonLabel then C.S.StateButtonLabel(f)end
                    Outline(f)
                end
                for _,icon in ipairs(icons)do icon[1]:SetAlpha(icon[2])end
                painted[f]=true
                C.H.Script(f,'OnClick',function()MenuReady(C)end)
            end
            return true
        end
    end,
    -- Private UIParent-owned import progress has no stable public handle.
    -- Leave its native coroutine/update and all confirmation actions untouched.
})
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition('Myslot',DefineSkin)
else DefineSkin()end
