#!/usr/bin/env python3
"""Exercise the shipped VM, adapter and Kyna modules with SDK paths removed."""
import argparse, hashlib, json, os, pathlib, subprocess, sys, tempfile
p=argparse.ArgumentParser(description=__doc__);p.add_argument('output',type=pathlib.Path);a=p.parse_args();out=a.output.resolve()
if sys.platform=='darwin':
 app=out/'Kyna Music.app/Contents';binary=app/'Resources/runtime';source=app/'Resources/app'
else:
 app=out/'KynaMusic';binary=app/'bin';source=app/'app'
ky=binary/('ky.exe' if os.name=='nt' else 'ky');module=binary/('music_bridge.dll' if os.name=='nt' else 'libmusic_bridge.so')
inventory=json.loads((binary/'runtime-inventory.json').read_text())
for record in inventory['binaries']:
 path=binary/record['path']
 if hashlib.sha256(path.read_bytes()).hexdigest()!=record['sha256']:raise SystemExit('Inventory hash mismatch: '+record['path'])
with tempfile.TemporaryDirectory(prefix='music-shipped-') as directory:
 env=dict(os.environ,KYNA_MUSIC_DATA_DIR=directory,KYNA_MUSIC_VERIFY_AUDIO='1',QT_QUICK_BACKEND='software',QT_PLUGIN_PATH='/missing-sdk',QML2_IMPORT_PATH='/missing-sdk',QML_IMPORT_PATH='/missing-sdk')
 env.pop('LD_LIBRARY_PATH',None);env.pop('DYLD_LIBRARY_PATH',None)
 env['PATH']=os.path.join(os.environ.get('SystemRoot','C:/Windows'),'System32') if os.name=='nt' else '/usr/bin:/bin'
 for script in ('smoke.ky','reload.ky'):
  subprocess.run([str(ky),'--native-library',str(module),'run',str(source/'tests'/script)],cwd=pathlib.Path(__file__).resolve().parents[1],env=env,check=True,timeout=45)
print('PORTABLE_MUSIC_OK')
