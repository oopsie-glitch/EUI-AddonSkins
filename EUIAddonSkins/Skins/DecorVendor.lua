local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule('DecorVendor','Decor Vendor',function()
    return type(_G.DVD)=='table' and _G.DVD.ADDON_NAME=='DecorVendor'
end,function(S,module)
    local app=_G.DVD
    local H=ns.CreateSkinHelper(S,module)
    local soft=ns.CreateSoftSkin(S,module)
    local nodes=setmetatable({}, {__mode='k'})
    local art=setmetatable({}, {__mode='k'})
    local panels,canvases,categories={}, {}, {}
    local generation,waiting=1,false
    local Walk,Discover,Options,ListReady,GalleryReady,Tabs
    local function Ready()
        if not ns.IsEnabled(module) then return false end
        if InCombatLockdown and InCombatLockdown() then waiting=true;return false end
        return true
    end
    local function State(f)
        if not nodes[f] then nodes[f]={} end
        return nodes[f]
    end
    local function Font(text,neutral)
        if not H.Allowed(text) or text:GetObjectType()~='FontString' or not text.GetFont then return end
        local current,_,flags=text:GetFont();if not current then return end
        local face,style=S.GetFont();local r,g,b,a=text:GetTextColor()
        if current~=face or (flags or '')~=(style or '') then S.Font(text,r,g,b);text:SetTextColor(r,g,b,a) end
        if neutral then
            -- Strip only a single, purely decorative gold wrapper. Embedded
            -- status colours, links, author credits and item text stay intact.
            local value=text.GetText and text:GetText()
            local plain=type(value)=='string'and value:match('^|cffffd100([^|]*)|r$')
            if plain then text:SetText(plain)end
            if r>.8 and g>.6 and b<.3 then text:SetTextColor(.9,.9,.92,a)end
        end
    end
    local function Strip(f)
        if f.SetBackdrop then f:SetBackdrop(nil) end
        for _,t in ipairs(H.Regions(f)) do
            local layer=t.GetDrawLayer and t:GetDrawLayer()
            if H.Texture(t) and not art[t] and (layer=='BACKGROUND' or layer=='BORDER') then H.Fade(t) end
        end
    end
    local function Surface(f,shell)
        local d=State(f)
        if not d.surface then
            Strip(f)
            if shell then
                -- A shell may fade all regions. Preserve foreground pictures,
                -- text-independent status artwork and logos exactly as supplied.
                local keep={}
                for _,t in ipairs(H.Regions(f)) do if H.Texture(t) and t:GetDrawLayer()~='BACKGROUND' and t:GetDrawLayer()~='BORDER' then keep[t]=t:GetAlpha() end end
                S.Shell(f,{noTopBar=true,noBorder=true})
                for t,a in pairs(keep)do t:SetAlpha(a)end
            else
                d.fill=f:CreateTexture(nil,'BACKGROUND',nil,-7);art[d.fill]=true;d.fill:SetAllPoints(f)
                d.left=f:CreateTexture(nil,'BACKGROUND',nil,-6);art[d.left]=true
                d.right=f:CreateTexture(nil,'BACKGROUND',nil,-6);art[d.right]=true
                d.left:SetPoint('TOPLEFT',f,'TOPLEFT');d.left:SetPoint('BOTTOMRIGHT',f,'BOTTOM')
                d.right:SetPoint('TOPLEFT',f,'TOP');d.right:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT')
            end
            d.surface=true
        end
        if d.surfaceGeneration==generation then return end
        if d.fill then
            local r,g,b=S.GetPanelColor()
            d.fill:SetColorTexture(r+.015,g+.015,b+.015,.97)
            for i,t in ipairs({d.left,d.right}) do
                t:SetColorTexture(1,1,1,1)
                local first,last=i==1 and 0 or .12,i==1 and .12 or 0
                if t.SetGradient and CreateColor then t:SetGradient('HORIZONTAL',CreateColor(r+.12,g+.12,b+.12,first),CreateColor(r+.12,g+.12,b+.12,last))
                elseif t.SetGradientAlpha then t:SetGradientAlpha('HORIZONTAL',r+.12,g+.12,b+.12,first,r+.12,g+.12,b+.12,last)
                else t:SetColorTexture(r+.06,g+.06,b+.06,.08) end
            end
        end
        d.surfaceGeneration=generation
    end
    local function Check(f)
        local d=State(f)
        if not d.check then
            for _,t in ipairs(H.Regions(f)) do if H.Texture(t) then H.Fade(t) end end
            if H.Allowed(f.customBg) then f.customBg:Hide();art[f.customBg]=true end
            local host=CreateFrame('Frame',nil,f);art[host]=true
            host:SetSize(22,22);host:SetPoint('CENTER',f,'CENTER');host:EnableMouse(false)
            S.Checkbox(host,{borderInset=4})
            host.mark=host:CreateTexture(nil,'OVERLAY',nil,2);host.mark:SetPoint('CENTER',host,'CENTER');host.mark:SetSize(8,8)
            host.hover=host:CreateTexture(nil,'OVERLAY',nil,1);host.hover:SetPoint('CENTER',host,'CENTER');host.hover:SetSize(14,14)
            host.hover:SetColorTexture(1,1,1,.08);host.hover:SetAlpha(0)
            d.check=host
            H.Script(f,'OnEnter',function()if Ready() and(not f.IsEnabled or f:IsEnabled())then host.hover:SetAlpha(1)end end)
            for _,event in ipairs({'OnLeave','OnHide'})do H.Script(f,event,function()host.hover:SetAlpha(0)end)end
            for _,method in ipairs({'SetChecked','Enable','Disable','SetEnabled'})do H.Hook(f,method,function()if Ready()then Check(f)end end)end
            H.Script(f,'OnClick',function()if Ready()then Check(f)end end)
        end
        local enabled=not f.IsEnabled or f:IsEnabled()
        local value=f.GetChecked and not not f:GetChecked() or false
        if d.check.mark:IsShown()~=value then d.check.mark:SetShown(value)end
        if d.checkGeneration~=generation or d.enabled~=enabled then
            if enabled then d.check.mark:SetColorTexture(S.GetAccentColor())
            else d.check.mark:SetColorTexture(.4,.4,.4,.8);d.check.hover:SetAlpha(0)end
            -- Sidebar custom labels encode useful faction/profession colours.
            -- Generic Settings labels are neutral; native custom label colours stay.
            Font(f.label,false);Font(f.Text,true);Font(f.text,true)
            d.checkGeneration,d.enabled=generation,enabled
        end
    end
    local function Slider(f)
        local thumb=f.GetThumbTexture and H.Texture(f:GetThumbTexture());if not thumb then return end
        local d=State(f)
        if not d.grip then
            for _,t in ipairs(H.Regions(f))do if H.Texture(t)then H.Fade(t)end end
            if f.SetBackdrop then f:SetBackdrop(nil)end
            d.track=f:CreateTexture(nil,'BACKGROUND');art[d.track]=true
            d.track:SetPoint('LEFT',f,'LEFT');d.track:SetPoint('RIGHT',f,'RIGHT');d.track:SetHeight(2);d.track:SetColorTexture(.2,.2,.22,1)
            d.grip=f:CreateTexture(nil,'ARTWORK');art[d.grip]=true
            d.grip:SetPoint('CENTER',thumb,'CENTER');d.grip:SetSize(6,14)
            local function Show()if Ready()then d.grip:SetShown(thumb:IsShown())end end
            for _,method in ipairs({'Show','Hide','SetShown'})do H.Hook(thumb,method,Show)end
            Show()
        end
        if d.gripGeneration~=generation then d.grip:SetColorTexture(S.GetAccentColor());d.gripGeneration=generation end
    end
    local function Scroll(f)
        if not H.Allowed(f)then return end
        if f.GetThumbTexture and H.Texture(f:GetThumbTexture())then H.LegacySlider(f)
        else
            S.ScrollBar(f,true)
            if H.Allowed(f.Back)then soft.SoftPageButton(f.Back,'^')end
            if H.Allowed(f.Forward)then soft.SoftPageButton(f.Forward,'v')end
        end
    end
    Tabs=function()
        if not Ready()then return end
        for _,tab in ipairs(app.bottomTabs or {})do
            if H.Allowed(tab)then
                local d=State(tab);local selected=tab.id==app.currentTab
                if not d.tab then
                    d.tab=true
                    if tab.SetBackdrop then tab:SetBackdrop(nil)end
                    if H.Texture(tab.bg)then tab.bg:SetColorTexture(.075,.075,.085,.95)end
                    if H.Texture(tab.accent)then tab.accent:ClearAllPoints();tab.accent:SetPoint('BOTTOMLEFT',tab,'BOTTOMLEFT',1,1);tab.accent:SetPoint('BOTTOMRIGHT',tab,'BOTTOMRIGHT',-1,1);tab.accent:SetHeight(2)end
                end
                if H.Texture(tab.bg)then tab.bg:SetColorTexture(selected and .115 or .065,selected and .115 or .065,selected and .125 or .075,.96)end
                if H.Texture(tab.accent)then tab.accent:SetColorTexture(S.GetAccentColor());tab.accent:SetAlpha(selected and 1 or 0)end
                Font(tab.text,true)
                if tab.text then if selected then tab.text:SetTextColor(S.GetAccentColor())else tab.text:SetTextColor(.85,.85,.87)end end
                if H.Texture(tab.icon)then tab.icon:SetVertexColor(1,1,1,1)end
            end
        end
    end
    local function Tile(f)
        local d=State(f)
        if d.tileGeneration==generation then return end
        local r,g,b=S.GetPanelColor()
        f.slotBg:SetColorTexture(r+.035,g+.035,b+.035,.96)
        if H.Texture(f.hoverBg)then f.hoverBg:SetColorTexture(1,1,1,.1)end
        d.tileGeneration=generation
    end
    local function Paint(f)
        local d=State(f);if d.generation==generation then return end
        local kind=f:GetObjectType()
        local semantic=f.isUniversalHeader or f.isUniversalCard or f.nameText or f.topIndicator or f.slotBg
        if panels[f]then Surface(f,panels[f]=='shell')end
        if H.Texture(f.slotBg)then Tile(f)end
        if f.isUniversalHeader then
            if H.Texture(f.bg)then f.bg:SetColorTexture(.105,.105,.12,.9)end
            if H.Texture(f.accent)then f.accent:SetColorTexture(.25,.25,.28,.5)end
            if not d.headerHook then
                d.headerHook=true
                for _,event in ipairs({'OnEnter','OnLeave'})do
                    H.Script(f,event,function()
                        if not Ready()then return end
                        if H.Texture(f.bg)then f.bg:SetColorTexture(event=='OnEnter'and .15 or .105,event=='OnEnter'and .15 or .105,event=='OnEnter'and .17 or .12,.9)end
                        if H.Texture(f.accent)then f.accent:SetColorTexture(S.GetAccentColor());f.accent:SetAlpha(event=='OnEnter'and .8 or .3)end
                    end)
                end
            end
        elseif f.isUniversalCard then
            -- Only the row surface changes; split status strips, text and rarity
            -- border retain their native data-dependent colours and hit areas.
            if f.SetBackdropColor then f:SetBackdropColor(.075,.075,.085,.94)end
            if f.SetBackdropBorderColor then f:SetBackdropBorderColor(.15,.15,.17,.7)end
        end
        if kind=='Frame'and f.GetParent then
            local parent=f:GetParent()
            if H.Allowed(parent)and parent:GetObjectType()=='EditBox'and f.SetBackdropBorderColor then
                f:SetBackdropBorderColor(.22,.22,.24,1)
            end
        end
        if kind=='CheckButton'then Check(f)
        elseif kind=='EditBox'then soft.EditBox(f);Font(f.Instructions,true)
        elseif kind=='Slider'and f.GetThumbTexture then
            if f.GetOrientation and f:GetOrientation()=='HORIZONTAL'then Slider(f)else Scroll(f)end
        elseif kind=='Button'and not semantic and not f.id then
            local label=f.GetFontString and f:GetFontString()or f.Text
            local normal=f.GetNormalTexture and H.Texture(f:GetNormalTexture())
            local path=normal and normal:GetTexture()
            local close=type(path)=='string'and path:lower():find('close',1,true)
            if not close and f.GetPoint and f:GetWidth()<=36 and f:GetHeight()<=36 then
                local point,_,rp,x,y=f:GetPoint(1)
                close=point=='TOPRIGHT'and(not rp or rp=='TOPRIGHT')and x and y and math.abs(x)<=8 and math.abs(y)<=8
            end
            if close then S.CloseButton(f)
            elseif H.Allowed(label)then
                soft.Button(f,{'Text','text','Icon','icon'})
                if S.StateButtonLabel and f.GetFontString and f:GetFontString()then S.StateButtonLabel(f)end
            end
        end
        if H.Allowed(f.Slider)then
            Slider(f.Slider)
            if H.Allowed(f.Back)then soft.SoftPageButton(f.Back,'<')end
            if H.Allowed(f.Forward)then soft.SoftPageButton(f.Forward,'>')end
        end
        if H.Allowed(f.ScrollBar)then Scroll(f.ScrollBar)end
        for _,text in ipairs(H.Regions(f))do Font(text,not semantic and kind~='CheckButton')end
        d.generation=generation
    end
    local function Excluded(f)
        local kind=f:GetObjectType()
        local gallery=app.Gallery
        local preview=gallery and gallery.frame and gallery.frame.preview
        if preview and f==preview.controls then return true end
        return kind=='PlayerModel'or kind=='ModelScene'or kind=='GameTooltip'or kind=='Texture'or kind=='Line'or kind=='FontString'
            or f==app.modelControls or f==app.modelScene
    end
    Walk=function(f,force)
        if not Ready()or not H.Allowed(f)or art[f]or Excluded(f)then return end
        local d=State(f)
        local n=f.GetNumChildren and f:GetNumChildren()or -1
        local nr=f.GetNumRegions and f:GetNumRegions()or -1
        Paint(f)
        if not force and d.walkGeneration==generation and d.children==n and d.regions==nr then return end
        for _,child in ipairs(H.Children(f))do
            if not child.IsShown or child:IsShown()or not nodes[child]then Walk(child,false)end
        end
        d.children=f.GetNumChildren and f:GetNumChildren()or n
        d.regions=f.GetNumRegions and f:GetNumRegions()or nr
        d.walkGeneration=generation
    end
    local function Root(f,mode)
        if not H.Allowed(f)then return end
        local d=State(f)
        if mode and panels[f]~=mode then panels[f]=mode;d.generation=nil end
        if not d.root then
            d.root=true
            H.Script(f,'OnShow',function()Walk(f,true)end)
        end
        Walk(f,false)
    end
    local function Preview()
        if not Ready()then return end
        for _,key in ipairs({'itemContainer','vendorPopup','reagentsPopup','vendorNotes','profNotes'})do Root(app[key],key=='itemContainer'and'panel'or nil)end
        if H.Allowed(app.vendorPrevBtn)then soft.SoftPageButton(app.vendorPrevBtn,'<')end
        if H.Allowed(app.vendorNextBtn)then soft.SoftPageButton(app.vendorNextBtn,'>')end
        local gallery=app.Gallery
        local frame=gallery and gallery.frame
        local preview=frame and frame.preview
        if H.Allowed(preview)then
            if H.Allowed(preview.controls)then art[preview.controls]=true end
            Root(preview,'panel')
            Root(preview.modelBox,'panel')
            if H.Texture(preview.corbelLeft)then H.Fade(preview.corbelLeft)end
            if H.Texture(preview.corbelRight)then H.Fade(preview.corbelRight)end
            -- Native camera controls and the rendered model remain independent.
            if H.Allowed(preview.controls)then art[preview.controls]=true end
        end
    end
    ListReady=function()
        if not Ready()then return end
        for _,f in ipairs(app.activeWidgets or {})do Walk(f,false)end
        -- Empty-state text is owned by this one scroll child; no recursive list
        -- walk is needed when the target exposes its completed active widgets.
        if H.Allowed(app.scrollChild)then for _,t in ipairs(H.Regions(app.scrollChild))do Font(t,false)end end
    end
    GalleryReady=function()
        if not Ready()then return end
        local gallery=app.Gallery;if not gallery then return end
        for _,card in ipairs(gallery.cards or {})do Walk(card,false)end
    end
    local function Canvas(frame)
        if not H.Allowed(frame)then return end
        canvases[frame]=true;Root(frame)
    end
    Options=function()
        if not Ready()then return end
        Canvas(_G.DV_ConfigFrame)
        local root=app.optionsCategory
        if not root then return end
        categories[root]=true
        local function Category(category)
            categories[category]=true
            if SettingsPanel and SettingsPanel.GetLayout then
                local ok,layout=pcall(SettingsPanel.GetLayout,SettingsPanel,category)
                if ok and layout and layout.GetFrame then local ok,f=pcall(layout.GetFrame,layout);if ok then Canvas(f)end end
            end
        end
        Category(root)
        if root.GetSubcategories then for _,category in ipairs(root:GetSubcategories()or {})do Category(category)end end
    end
    local function Hooks()
        H.Hook(app,'RefreshTabVisuals',Tabs)
        H.Hook(app,'BuildVendorUI',ListReady)
        for _,key in ipairs({'BuildVendorFilters','BuildQuestFilters','BuildProfessionFilters','BuildAchievementFilters','BuildBossDropFilters','BuildShopFilters'})do
            H.Hook(app,key,function()Root(app.sidebarFilters);Walk(app.sidebarFilters,true)end)
        end
        H.Hook(app,'CreateOptionsPanel',Options)
        H.Hook(app,'CreateMainHomePanel',Discover)
        H.Hook(app,'ShowMainHomePanel',Discover)
        H.Hook(app,'ShowWowheadBox',function(parent,box)if Ready()then Root(box)end end)
        H.Hook(app,'ApplyFontSettings',function()module.refresh()end)
        for _,key in ipairs({'ShowVendorPopup','ShowReagentsPopup','UpdateProfessionPreview','EnsureVendorNotes','ShowWowheadLinkPopup'})do H.Hook(app,key,Preview)end
        local gallery=app.Gallery
        if gallery then
            H.Hook(gallery,'CreateFrame',Discover)
            H.Hook(gallery,'RefreshGrid',GalleryReady)
            H.Hook(gallery,'BuildSidebarContent',function(parent)Root(parent);Walk(parent,true)end)
            H.Hook(gallery,'ShowItem',Preview)
            H.Hook(gallery,'UpdateActionButton',Preview)
        end
        H.Hook(Settings,'RegisterCanvasLayoutCategory',function(frame,name)if name=='Decor Vendor'then Canvas(frame)end end)
        H.Hook(Settings,'RegisterCanvasLayoutSubcategory',function(parent,frame)if parent==app.optionsCategory or categories[parent]then Canvas(frame)end end)
        H.Hook(SettingsPanel,'DisplayCategory',function()Options()end)
    end
    Discover=function()
        if not Ready()then return end
        Hooks()
        Root(app.frame or _G.DV_MainFrame,'shell')
        Root(app.standaloneHomePanel or _G.DVD_StandaloneHomePanel,'shell')
        for _,key in ipairs({'sidebar','listPanel','previewPanel','modelBox','itemContainer','contentArea','tabBar'})do Root(app[key],'panel')end
        for _,name in ipairs({'DV_TitleBar','DV_VendorPopup','DV_ReagentsPopup'})do Root(_G[name],'panel')end
        local gallery=app.Gallery
        if gallery and H.Allowed(gallery.frame)then
            local f=gallery.frame;Root(f,'shell')
            Root(f.titleBar,'panel')
            if H.Allowed(f.closeBtn)then S.CloseButton(f.closeBtn)end
            Root(f.sidebar,'panel');Root(f.preview,'panel');Root(f.bottom,'panel')
            if f.sidebar then Root(f.sidebar.filterContent)end
        end
        Options();Tabs();ListReady();GalleryReady();Preview()
    end
    module.refresh=function()
        if not Ready()then return end
        generation=generation+1
        -- Repaint bounded, current roots. Native data/model/collection update
        -- loops are never hooked or called by the skin.
        Discover()
    end
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh)end
    local events=CreateFrame('Frame');events:RegisterEvent('ADDON_LOADED');events:RegisterEvent('PLAYER_REGEN_ENABLED')
    events:SetScript('OnEvent',function(_,event,name)
        if event=='PLAYER_REGEN_ENABLED'then if waiting then waiting=false;module.refresh()end
        elseif name=='DecorVendor' or name=='Blizzard_Settings'then H.Queue(module,Discover)end
    end)
    Discover()
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition('DecorVendor',DefineSkin)
else DefineSkin()end
