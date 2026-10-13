#!/usr/bin/env python3
"""Build, check, test, run or package the Kyna desktop app with explicit inputs."""
import argparse, os, pathlib, subprocess, sys, tempfile
ROOT=pathlib.Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('action',choices=['build','check','test','run','package'])
p.add_argument('--kyna-root',type=pathlib.Path,default=ROOT/'.deps/kyna')
p.add_argument('--ky',type=pathlib.Path)
p.add_argument('--qt-prefix',type=pathlib.Path)
p.add_argument('--qtpaths',default='qtpaths')
p.add_argument('--output',type=pathlib.Path,default=ROOT/'build/package')
a=p.parse_args();repo=a.kyna_root.resolve();build=ROOT/'build'
ky=(a.ky or repo/('build/bin/Release/ky.exe' if os.name=='nt' else 'build/bin/ky')).resolve()
if not ky.is_file():raise SystemExit('Kyna executable not found. Pass --ky and --kyna-root; see README.md.')
def run(args,**kw):subprocess.run([str(x) for x in args],cwd=ROOT,check=True,**kw)
if a.action=='build':
 args=['cmake','-S',ROOT/'native','-B',build,'-DCMAKE_BUILD_TYPE=Release','-DKYNA_ROOT='+str(repo)]
 if a.qt_prefix:args+=['-DCMAKE_PREFIX_PATH='+str(a.qt_prefix.resolve())]
 run(args);run(['cmake','--build',build,'--config','Release','--parallel','4'])
module=build/'native'/('Release/music_bridge.dll' if os.name=='nt' else 'libmusic_bridge.so')
if not module.is_file():raise SystemExit('Build the native adapter first: python tools/build.py build ...')
cmd=[ky,'--native-library',module]
if a.action in ('build','check'):run(cmd+['check','main.ky'])
elif a.action=='run':run(cmd+['run','main.ky'])
elif a.action=='test':
 with tempfile.TemporaryDirectory(prefix='kyna-music-tests-') as directory:
  env=dict(os.environ,KYNA_MUSIC_DATA_DIR=directory,KYNA_MUSIC_VERIFY_AUDIO='1',QT_QUICK_BACKEND='software')
  run(cmd+['run','tests/smoke.ky'],env=env,timeout=45)
  run(cmd+['run','tests/reload.ky'],env=env,timeout=15)
elif a.action=='package':
 args=[sys.executable,ROOT/'tools/package.py','--ky',ky,'--native',module,'--kyna-root',repo,'--qtpaths',a.qtpaths,'--output',a.output]
 if sys.platform=='darwin':args+=['--launcher',build/'music_launcher']
 run(args)
