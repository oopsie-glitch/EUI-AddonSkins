"""Checksum-pinned source-contract checks; addon source is not logged or packaged."""
from inspect_lfgforever import archive,SHA
import re
def check():
    z=archive()
    contracts={
        'core/window.lua':[r'FRAME_NAME\s*=\s*"LFGForeverFrame"',r'content\.FilterPanel\s*=\s*filter',r'content\.ListPanel\s*=\s*list',r'frame\.Content\s*=\s*content',r'function\s+LFGF\.ToggleWindow',r'function\s+LFGF\.OpenForListing'],
        'core/filterpanel.lua':[r'panel\.TabSystem\s*=\s*tabs',r'panel\.WhisperLog\s*=\s*whispers',r'panel\.PlayerRatings\s*=\s*ratings',r'panel\.SettingsGear\s*=',r'panel\.MyFiltersDropdown\s*=',r':SetTab\s*\('],
        'core/main.lua':[r'function\s+LFGF\.CreateScrollList',r'"WowScrollBoxList"',r'"MinimalScrollBar"'],
        'core/listpanel.lua':[r'panel\.ScrollBox\s*=',r'view:SetElementFactory',r'LFGBrowseSearchEntryTemplate'],
        'core/whisperlog.lua':[r'log\.ScrollBox\s*=',r'view:SetElementInitializer'],
        'core/playerratings.lua':[r'ratings\.ScrollBox\s*=',r'view:SetElementInitializer',r'star\.Unearned\s*=',r'star\.Earned\s*='],
        'core/minimap.lua':[r'function\s+LFGForever_OnAddonCompartmentClick',r'LFGForeverMinimapButton'],
        'core/slash.lua':[r'function\s+LFGForever_ToggleWindow',r'LFGForeverSearchKeyButton',r'LFGFOREVER'],
        'core/blizzardtab.lua':[r'LFGForeverBlizzardTab',r'SetCustomOnMouseUpHandler'],
    }
    for path,patterns in contracts.items():
        text=z.read('LFGForever/'+path).decode('utf-8-sig')
        for index,pattern in enumerate(patterns):
            assert re.search(pattern,text),'Native UI contract changed: '+path+' #'+str(index+1)
    toc=z.read('LFGForever/LFGForever.toc').decode('utf-8-sig')
    assert re.search(r'## Version:\s*2\.6\.0',toc)
    assert re.search(r'## Interface:\s*16001',toc)
    assert not any('/Libs/' in n or '/libs/' in n for n in z.namelist())
    print('PASS: pinned LFG Forever 2.6.0 source contracts: lazy window/launchers, three ScrollBox views, owned controls, semantic rating resources; SHA256 '+SHA)
if __name__=='__main__':check()
