-- Runtime ownership cases; optional exact 13014 selectors are injected by the cloud source runner.
return function(ctx)
    local oldAtlas, oldLooks = AtlasLoot, ctx.S.OnLooksChanged
    local function Native(gui, nav, db)
        function nav.GetStyle() return db.style or 'nav' end
        function nav.GetLook() return nav.GetStyle() == 'legacy' and 'legacy' or db.theme end
        function nav.SetStyle(style)
            nav.sessionLook = nav.sessionLook or nav.GetLook()
            db.style = style
        end
        function nav.SetLook(key)
            if key == 'legacy' then return nav.SetStyle(key) end
            nav.sessionLook = nav.sessionLook or nav.GetLook()
            db.style, db.theme = 'nav', key
        end
        function nav:Revert() self.active = false; gui.RefreshStyle() end
    end
    local function state(look, noFrame)
        local gui, db = {}, {style = look == 'legacy' and 'legacy' or 'nav', theme = look}
        local nav = {active = look ~= 'legacy'}
        gui.Nav = nav
        local root = ctx.frame('Frame', 'AtlasLoot_GUI-Frame')
        root:SetBackdrop({bgFile='native', edgeFile='native-border', edgeSize=16})
        root:SetBackdropColor(.2,.3,.4,.8)
        root.CloseButton = ctx.frame('Button', nil, root)
        root.titleFrame = ctx.frame('Frame', nil, root)
        root.titleFrame.infoButton = ctx.frame('Button', nil, root.titleFrame)
        root.moduleSelect, root.subCatSelect, root.difficulty, root.boss, root.extra =
            {frame=ctx.frame()}, {frame=ctx.frame()}, {frame=ctx.frame()}, {frame=ctx.frame()}, {frame=ctx.frame()}
        root.contentFrame = {topBG={}, downBG={}}
        local label = root:CreateFontString(nil,'ARTWORK','GameFontNormal')
        gui.frame = noFrame and nil or root
        gui.Create = function() gui.frame = root; return 'native-create',nil,6 end
        gui.RefreshStyle = function() return 'native-style' end
        gui.RefreshFonts = function() return 'native-fonts' end
        gui.RefreshVersionUpdate = function() end
        gui.Toggle = function() return 'native-toggle',nil,8 end
        gui.ItemFrame = {Refresh=function() return 'native-item' end}
        local favGUI = {frame=ctx.frame(), NavStyle={applied=false}, Create=function()end, Toggle=function()end}
        AtlasLoot = {GUI=gui, db={GUI=db}, Favourites={GUI=favGUI}}
        if ATLAS_SOURCE_LIFECYCLE then ATLAS_SOURCE_LIFECYCLE(AtlasLoot,gui,nav,db) else Native(gui,nav,db) end
        local looks={}
        ctx.S.OnLooksChanged = function(fn) looks[#looks+1]=fn end
        local m={}
        ctx.install(ctx.S,m)
        ctx.flush()
        return {gui=gui,nav=nav,db=db,root=root,label=label,fav=favGUI,module=m,looks=looks}
    end
    local function untouched(st)
        assert(not st.root.accent and st.root.backdrop.edgeSize == 16 and st.label.font == 'GameFontNormal',
            'AtlasLoot navigation mode was styled')
    end
    -- Fresh sessions are how 13014 applies a selected look after reload.
    for _, look in ipairs({'foreverbronze','atlasnav','legacy'}) do
        local st=state(look)
        if look ~= 'legacy' then
            untouched(st)
            st.nav.SetLook('legacy') -- pending/cancelled reload: navigation is still displayed
            assert(st.db.style=='legacy' and st.nav.active)
            if st.nav.TestCancelReload then st.nav.TestCancelReload() end
            local originalColor, hooks = st.root.color, st.gui.Create
            for _, fn in ipairs(st.looks) do fn() end
            for _=1,1000 do st.gui.Toggle();st.gui.RefreshFonts();st.gui.ItemFrame:Refresh();st.module.refresh() end
            ctx.flush();untouched(st)
            assert(st.root.color==originalColor and st.gui.Create==hooks)
            assert(#st.fav.frame.regions==0, 'navigation favourites was discovered')
        else
            assert(st.root.accent and st.root.backdrop.edgeSize==1 and st.label.font=='eui')
            st.nav.SetLook('foreverbronze')
            assert(st.db.style=='nav' and not st.nav.active)
            st.gui.RefreshFonts();ctx.flush()
            assert(st.label.font=='eui', 'pending navigation choice stopped Classic styling')
            -- Favourites may use the pending choice at its own first creation.
            st.fav.NavStyle.applied=true
            local n=ctx.frame('CheckButton',nil,st.fav.frame)
            st.module.refresh();ctx.flush();assert(not n.checkbox,'navigation favourites was styled')
            local objects=#st.root.regions
            for _=1,100 do st.module.refresh();ctx.flush() end
            assert(#st.root.regions==objects,'Classic warm refresh grew artwork')
            -- Existing hooks and queued jobs must re-check the displayed state.
            st.module.refresh()
            st.nav.active=true
            local color, fonts=st.root.color,st.label.fontWrites
            st.root:SetBackdropBorderColor(.9,.8,.7,1)
            st.gui.RefreshFonts();for _,fn in ipairs(st.looks)do fn()end;ctx.flush()
            assert(st.root.border[1]==.9 and st.root.color==color and st.label.fontWrites==fonts,
                'stale queued callback or installed hook modified navigation UI')
        end
    end
    -- Runtime fallback is Classic even if the saved preference remains nav.
    local st=state('foreverbronze')
    st.nav:Revert();ctx.flush()
    assert(st.db.style=='nav' and not st.nav.active and st.root.accent,
        'native fallback failed to activate Classic cosmetics')
    -- Constructor is observed while unbuilt; intermediate callbacks never discover it.
    st=state('atlasnav',true)
    local a,b,c=st.gui:Create();ctx.flush()
    assert(a=='native-create' and b==nil and c==6);untouched(st)
    st=state('legacy',true)
    st.gui:Create();ctx.flush()
    assert(st.root.accent,'late Classic constructor did not activate')
    -- Combat recovery evaluates the final runtime state, not a saved selection.
    ctx.combat(true);st.module.refresh();ctx.flush()
    st.nav.active=true
    ctx.combat(false)
    ctx.event('PLAYER_REGEN_ENABLED');ctx.flush()
    local fonts=st.label.fontWrites
    st.gui.RefreshFonts();ctx.flush();assert(st.label.fontWrites==fonts)
    AtlasLoot,ctx.S.OnLooksChanged=oldAtlas,oldLooks
    print('PASS: AtlasLoot 13014 displayed-mode isolation; pending/cancelled switches, reload sessions, fallback, queues, hooks, menus, favourites, theme and combat')
end
