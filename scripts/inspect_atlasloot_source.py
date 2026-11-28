"""Inspect the supplied source in cloud memory; do not redistribute addon files."""
import hashlib, io, json, re, urllib.request, zipfile
URL = "https://github.com/user-attachments/files/35548736/AtlasLootContinued-Forever_13014.zip"
with urllib.request.urlopen(URL, timeout=60) as r:
    data = r.read()
print("ARCHIVE_SHA256", hashlib.sha256(data).hexdigest())
with zipfile.ZipFile(io.BytesIO(data)) as z:
    assert z.testzip() is None
    names = z.namelist()
    print("SOURCE_FILES", json.dumps([n for n in names if re.search(r'(skin|nav|gui|option|init|toc)', n, re.I) and not '/Libs/' in n]))
    for n in names:
        if n.endswith('.toc') and 'AtlasLootContinued/' in n.replace('\\\\','/'):
            text=z.read(n).decode('utf-8-sig')
            print("TOC_METADATA",n,json.dumps([l for l in text.splitlines() if l.startswith('##')]))
    # Output only mode/lifecycle-related excerpts, not whole source files.
    for n in names:
        if not n.endswith('.lua') or '/Libs/' in n: continue
        text=z.read(n).decode('utf-8-sig')
        lines=text.splitlines()
        selected=set()
        for i,l in enumerate(lines):
            if re.search(r'legacy|[Ss]kin[Mm]ode|[Aa]ctive[Ss]kin|[Uu][Ii][Mm]ode|[Aa]tlas[Nn]av|[Nn]av[Ss]kin|[Ff]orever[Ss]kin',l):
                if re.search(r'(GUI/|Options/|Init|Skin)',n):
                    selected.update(range(max(0,i-2),min(len(lines),i+3)))
        if selected:
            print("LIFECYCLE_EXCERPTS",n)
            for i in sorted(selected): print(str(i+1)+": "+lines[i])
