-- Cosmetic properties and native ownership, using the 13014 field layout.
return function(ctx)
    local frame,S,flush,m=ctx.frame,ctx.S,ctx.flush,ctx.module
    local old=AtlasLoot
    local root=frame('Frame','AtlasLoot_GUI-Frame')
    root:SetBackdrop({bgFile='native-fill',edgeFile='native-border',edgeSize=16})
    root.titleFrame=frame('Frame',nil,root)
    root.titleFrame:SetBackdrop({bgFile='native-fill',edgeFile='native-border',edgeSize=16})
    root.contentFrame=frame('Frame',nil,root)
    local c=root.contentFrame
    for _,key in ipairs({'topBG','itemBG','downBG'}) do
        c[key]=c:CreateTexture()
        c[key].layer='BACKGROUND'
        c[key]:SetColorTexture(0,0,.4,1)
        local original=c[key].SetColorTexture
        c[key].SetColorTexture=function(self,...)self.writes=(self.writes or 0)+1;original(self,...)end
    end
    c.map=c:CreateTexture();c.map.path='native-dungeon-map'
    local title=c:CreateFontString(nil,'ARTWORK','GameFontNormal')
    title:SetTextColor(.1,.7,.2,1)
    local search=frame('EditBox','AtlasLoot_GUI-ItemFrame-SearchBox',c)
    local next=frame('Button','AtlasLoot_GUI-ItemFrame-nextPageButton',c)
    root.width,root.height=920,600
    local db={
        mainFrame={bgColor={a=.77},title={bgColor={a=.88}}},
        contentTopBar={bgColor={a=.65}},contentBottomBar={bgColor={a=.55}},
        content={bgColor={a=.45},showBgImage=false},
    }
    local function native()
        c.topBG:SetColorTexture(0,0,.4,db.contentTopBar.bgColor.a)
        c.downBG:SetColorTexture(0,0,.4,db.contentBottomBar.bgColor.a)
        if db.content.showBgImage then c.itemBG:SetTexture('native-lore-image')
        else c.itemBG:SetColorTexture(0,0,0,db.content.bgColor.a) end
    end
    local gui={frame=root,RefreshContentBackGround=native,RefreshMainFrame=function()end,curBgInfo={{0,0,.4},'native-lore-image'}}
    if ATLAS_SOURCE_SURFACE then ATLAS_SOURCE_SURFACE(gui,db) end
    AtlasLoot={GUI=gui,db={GUI=db}}
    local owner={}
    m.install(S,owner);flush()
    assert(c.topBG.color[1]==.02 and c.itemBG.color[4]==.45 and c.downBG.color[4]==.55,
        'Classic matte surfaces must use EUI RGB and preserve separate native opacity')
    assert(root.color[4]==.77 and root.titleFrame.color[4]==.88)
    assert(root.backdrop.bgFile=='Interface/Buttons/WHITE8X8' and root.backdrop.edgeSize==1)
    assert(c.map.path=='native-dungeon-map' and title.textColor[2]==.7)
    assert(search.input and next.glyph=='>' and root.width==920 and root.height==600)
    local hooks,regions,writes=ctx.hooks(),#c.regions,c.topBG.writes+c.itemBG.writes+c.downBG.writes
    for _=1,100 do owner.refresh();flush()end
    assert(ctx.hooks()==hooks and #c.regions==regions)
    assert(c.topBG.writes+c.itemBG.writes+c.downBG.writes==writes,'Warm refresh rewrote unchanged surfaces')
    db.content.bgColor.a=0
    gui.RefreshContentBackGround();flush();assert(c.itemBG.color[4]==0,'Zero opacity must remain valid')
    db.content.showBgImage=true
    gui.RefreshContentBackGround();flush()
    assert(c.itemBG.path=='native-lore-image','Optional native artwork must survive')
    db.content.showBgImage=false
    gui.RefreshContentBackGround();flush();assert(c.itemBG.path=='solid')
    local oldColor=S.GetPanelColor
    S.GetPanelColor=function()return .09,.1,.11,.93 end
    owner.refresh();flush()
    assert(c.topBG.color[1]==.09 and c.itemBG.color[4]==0)
    S.GetPanelColor=oldColor
    ctx.combat(true)
    c.topBG:SetColorTexture(.7,.2,.3,.65)
    c.topBG.curColor=nil -- force native content-color invalidation in the exact source case
    gui.RefreshContentBackGround()
    assert(c.topBG.color[1]==0,'Native callback must run in combat')
    ctx.combat(false);owner.refresh();flush()
    assert(c.topBG.color[1]==.02)
    -- Existing hooks and queued paint are inert after a runtime navigation switch.
    gui.Nav={active=true}
    gui.RefreshContentBackGround();owner.refresh();flush()
    assert(c.topBG.color[1]==0 and c.topBG.color[3]==.4)
    AtlasLoot=old
    print('PASS: Classic matte colors, native opacity/art, footer geometry, warm writes, combat and navigation isolation')
end
