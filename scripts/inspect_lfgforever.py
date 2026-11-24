"""Inspect the supplied archive without executing or reproducing addon source."""
from urllib.request import urlopen
from zipfile import ZipFile
from io import BytesIO
from hashlib import sha256
from pathlib import PurePosixPath
import json,re,xml.etree.ElementTree as ET
URL='https://github.com/user-attachments/files/35335139/LFGForever.zip'
SHA='68529acce2de99476226522242daacd9d277ffecd5b1a8b2d9c12c99febe6a6e'
def archive():
    with urlopen(URL,timeout=60) as r:data=r.read(20*1024*1024+1)
    assert len(data)<=20*1024*1024 and sha256(data).hexdigest()==SHA
    z=ZipFile(BytesIO(data))
    assert z.testzip() is None and sum(i.file_size for i in z.infolist())<100*1024*1024
    for i in z.infolist():
        p=PurePosixPath(i.filename)
        assert not p.is_absolute() and '..' not in p.parts and p.parts[0]=='LFGForever'
    return z
