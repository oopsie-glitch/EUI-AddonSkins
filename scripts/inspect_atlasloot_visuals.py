"""Verify the exact source ownership used by the Classic visual adapter."""
import hashlib,io,urllib.request,zipfile
with urllib.request.urlopen('https://github.com/user-attachments/files/35548736/AtlasLootContinued-Forever_13014.zip',timeout=60) as r:data=r.read()
assert hashlib.sha256(data).hexdigest()=='f3a7ffc65480a92c7b18961409087d9b2f83b1bf9d942fcd230b3cc28d479a1d'
with zipfile.ZipFile(io.BytesIO(data)) as z:
    def source(path):return z.read(path).decode('utf-8-sig')
    gui=source('AtlasLootContinued/GUI/GUI.lua')
    select=source('AtlasLootContinued/GUI/Template_Select.lua')
    dropdown=source('AtlasLootContinued/GUI/Template_DropDown.lua')
    assert 'db = AtlasLoot.db.GUI' in gui
    for field in ('topBG','downBG','itemBG','map'):
        assert 'frame.contentFrame.'+field+' = frame.contentFrame:CreateTexture' in gui
    for field in ('contentTopBar','contentBottomBar','content'):
        assert 'db.'+field+'.bgColor.a' in gui
    assert 'db.content.showBgImage' in gui and 'GUI.curBgInfo[2]' in gui
    assert 'self.frame:SetBackdropColor(r, g, b, alpha or 1)' in select
    assert 'frame.button:SetScript("OnClick", DropDownButtonOnClick)' in dropdown
    assert 'self.frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])' in dropdown
print('PASS: pinned 13014 cosmetic layer ownership, native opacity/image options, selection and dropdown lifecycle')
