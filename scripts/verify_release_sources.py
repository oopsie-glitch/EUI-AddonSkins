"""Run selected approved read-only source/regression steps on the combined tree."""
from pathlib import Path
import os,subprocess,sys
def step(path,name):
 lines=Path(path).read_text().splitlines()
 marker="      - name: "+name
 start=lines.index(marker)+1
 while start<len(lines)and not lines[start].startswith("        run: |"):
  assert not lines[start].startswith("      - "),name
  start+=1
 assert start<len(lines),name
 out=[]
 for line in lines[start+1:]:
  if line and not line.startswith("          "):break
  out.append(line[10:]if line else "")
 assert out,name
 print("APPROVED_SOURCE_STEP",name,flush=True)
 subprocess.run(["bash","-e","-c","\n".join(out)],check=True)
subprocess.run([sys.executable,"scripts/check_lfgforever_source.py"],check=True)
subprocess.run([sys.executable,"scripts/inspect_cheapupgrades.py"],check=True)
step(".github/workflows/font-height-test.yml","Fetch pinned public EUI font implementation")
engine=Path("/tmp/eui-font-source/EllesmereUIBlizzardSkin_WindowEngine.lua")
Path("/tmp/lfg-eui-engine.lua").write_bytes(engine.read_bytes())
os.environ.update(EUI_FONT_SOURCE="/tmp/eui-font-source",LFG_EUI_ENGINE_SOURCE="/tmp/lfg-eui-engine.lua",CHEAP_AHTAB_SOURCE="/tmp/cheap-ahtab.lua")
step(".github/workflows/details-native-test.yml","Pinned official Details source compatibility")
for name in ("Reproduce reload reset against the exact prior head","Verify regression sensitivity against the reported runtime","Reproduce old title overlap and compare identical layout workloads","Reproduce title default failure and measure exact prior baseline","Reproduce optional-meter dependency against the approved prior runtime","Reproduce sole-body suppression and compare the current approved baseline","Reproduce previous native defaults and compare the verified baseline","Five-trial hosted comparison"):
 step(".github/workflows/details-native-test.yml",name)
step(".github/workflows/font-height-test.yml","Prove published runtime fails and compare valid-font workloads")
os.environ["LFG_AUDIT_BASE"]="d91722e0190fa0f365be3553e075affee5d8ff50"
subprocess.run([sys.executable,"benchmarks/run_lfgforever.py"],check=True)
subprocess.run([sys.executable,"scripts/verify_cheapupgrades.py"],check=True)
subprocess.run([sys.executable,"scripts/package.py"],check=True)
subprocess.run([sys.executable,"scripts/check_release_1_6_8.py"],check=True)
print("Combined source, persistence, secret-value, ownership, performance and exact package checks: PASS")
