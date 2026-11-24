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
def inspect():
    z=archive()
    toc=z.read('LFGForever/LFGForever.toc').decode('utf-8-sig')
    metadata={}
    for line in toc.splitlines():
        if line.startswith('##') and ':' in line:
            key,value=line[2:].split(':',1)
            if key.strip() in ('Interface','Title','Version','Dependencies','OptionalDeps','SavedVariables','SavedVariablesPerCharacter'):
                metadata[key.strip()]=value.strip()
    print('LFG_METADATA '+json.dumps(metadata))
    print('LFG_LOAD_ORDER '+json.dumps([s.strip() for s in toc.splitlines() if s.strip() and not s.startswith('#')]))
    for path in z.namelist():
        if not path.endswith('.lua'):continue
        s=z.read(path).decode('utf-8-sig')
        functions=[]
        for m in re.finditer(r'(?:local\s+)?function\s+([\w.:]+)\s*\(([^)]*)\)|([\w.:\[\]"\']+)\s*=\s*function\s*\(([^)]*)\)',s):
            name=m.group(1) or m.group(3)
            functions.append({'symbol':name,'line':s.count('\n',0,m.start())+1,'parameters':m.group(2) if m.group(1) else m.group(4)})
        frames=[]
        for m in re.finditer(r'([\w.]+)\s*=\s*CreateFrame\s*\(\s*["\'](\w+)["\']\s*,\s*([^,\n]+)\s*,\s*([^,\n)]+)(?:\s*,\s*([^)\n]+))?',s):
            frames.append({'slot':m.group(1),'type':m.group(2),'name':m.group(3).strip(),'parent':m.group(4).strip(),'template':(m.group(5) or '').strip(),'line':s.count('\n',0,m.start())+1})
        signals=[]
        for m in re.finditer(r'([\w.]+)\s*:\s*(SetScript|HookScript|RegisterEvent)\s*\(\s*["\']([\w_]+)["\'](?:\s*,\s*([\w.:]+))?',s):
            signals.append({'owner':m.group(1),'operation':m.group(2),'signal':m.group(3),'handler':m.group(4),'line':s.count('\n',0,m.start())+1})
        exports=sorted(set(re.findall(r'_G\.([A-Za-z_]\w*)',s)+re.findall(r'_G\s*\[\s*["\']([A-Za-z_]\w*)["\']\s*\]',s)))
        methods=sorted(set(re.findall(r'\b([\w.]+)\s*[:.]\s*(Create\w+|Build\w+|Update\w+|Refresh\w+|Show\w+|Open\w+|Set\w+)\s*\(',s)))
        print('LFG_STRUCTURE '+json.dumps({'path':path,'functions':functions,'frames':frames,'signals':signals,'global_symbols':exports,'calls':[a+'.'+b for a,b in methods]}))
    # Emit only symbols/ownership metadata, never source lines or user-facing text.
    for path in z.namelist():
        if not path.endswith('.lua'):continue
        s=z.read(path).decode('utf-8-sig')
        aliases=re.findall(r'(?:local\s+)?([A-Za-z_]\w*)\s*=\s*([A-Za-z_]\w*)\s*(?:or\s*\{\s*\})?(?:\s*\n|\s*$)',s)
        constants={k:v for k,v in re.findall(r'\b([A-Z][A-Z_0-9]*)\s*=\s*["\']([A-Za-z_][A-Za-z_0-9.-]*)["\']',s)}
        assignments=[]
        for m in re.finditer(r'\b([\w.]+)\s*=\s*([\w.]+)(?:\s*\(|\s*(?:\n|,|;|$))',s):
            lhs,rhs=m.groups()
            if '.' in lhs or rhs.startswith(('Create','LFGF.Create')):assignments.append({'slot':lhs,'symbol':rhs,'line':s.count('\n',0,m.start())+1})
        bindings=[{'slot':m.group(1),'callee':m.group(2),'line':s.count('\n',0,m.start())+1} for m in re.finditer(r'\b([\w.]+)\s*=\s*([\w.]+)\s*\(',s)]
        varargs=re.findall(r'local\s+([\w, ]+)\s*=\s*\.\.\.',s)
        returns=[m.group(1).strip() for m in re.finditer(r'\breturn\s+([\w.]+(?:\s*,\s*[\w.]+)*)(?=\s*(?:\n|end|$))',s)]
        menu_apis=sorted(set(re.findall(r'\b(Menu\w*|Scroll\w*|Settings|LFGForever\w*)[.:]([A-Za-z_]\w*)',s)))
        print('LFG_OWNERSHIP '+json.dumps({'path':path,'aliases':aliases,'bindings':bindings,'varargs':varargs,'constants':constants,'assignments':assignments,'returns':returns,'ui_api_symbols':menu_apis}))
    for path in z.namelist():
        if path.endswith('.xml'):
            root=ET.fromstring(z.read(path))
            print('LFG_XML '+json.dumps({'path':path,'objects':[{k:e.attrib[k] for k in ('name','parent','inherits') if k in e.attrib} for e in root.iter() if any(k in e.attrib for k in ('name','parent','inherits'))]}))
if __name__=='__main__':inspect()
