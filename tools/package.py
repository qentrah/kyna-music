#!/usr/bin/env python3
"""Stage a checked Kyna app with its complete, relocatable Qt/audio runtime."""
import argparse, json, os, pathlib, plistlib, shutil, subprocess, sys

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--ky',type=pathlib.Path,required=True)
p.add_argument('--native',type=pathlib.Path,required=True)
p.add_argument('--kyna-root',type=pathlib.Path,required=True)
p.add_argument('--qtpaths',default='qtpaths')
p.add_argument('--output',type=pathlib.Path,required=True)
p.add_argument('--launcher',type=pathlib.Path)
a=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[1];out=a.output.resolve();ky=a.ky.resolve();native=a.native.resolve();repo=a.kyna_root.resolve()
if out.exists():raise SystemExit('Choose a fresh output directory')
sys.path.insert(0,str(repo/'build_tools/packaging'))
from portable_runtime import stage,copy_regular_tree,native_file,digest
out.mkdir(parents=True)
subprocess.run([str(ky),'--native-library',str(native),'build','main.ky','--output',str(out/'checked')],cwd=root,check=True)
if sys.platform=='darwin':
 app=out/'Kyna Music.app';contents=app/'Contents';binary=contents/'MacOS';resources=contents/'Resources'
 binary.mkdir(parents=True);resources.mkdir()
 if not a.launcher:raise SystemExit('--launcher is required on macOS')
 shutil.copy2(a.launcher,binary/'KynaMusic')
 (contents/'Info.plist').write_bytes(plistlib.dumps({'CFBundleName':'Kyna Music','CFBundleDisplayName':'Kyna Music','CFBundleIdentifier':'org.kyna.music','CFBundleExecutable':'KynaMusic','CFBundlePackageType':'APPL','CFBundleShortVersionString':'1.0.0','CFBundleVersion':'1','NSHighResolutionCapable':True,'NSHumanReadableCopyright':'Kyna Music contributors. See Resources/licenses.'}))
else:
 app=out/'KynaMusic';binary=app/'bin';resources=app;binary.mkdir(parents=True)
shutil.copy2(ky,binary/ky.name);shutil.copy2(native,binary/native.name)
shutil.copytree(out/'checked/app',resources/'app')
# Copy QML modules used by the app, including their declared runtime dependencies.
queries=dict(line.split(':',1) for line in subprocess.check_output([a.qtpaths,'--query'],text=True).splitlines() if ':' in line)
qml=pathlib.Path(queries['QT_INSTALL_QML']);plugins=pathlib.Path(queries['QT_INSTALL_PLUGINS'])
for name in ('QtQml','QtQuick'):
 copy_regular_tree(qml/name,binary/'qt/qml'/name)
# Include the native audio backend and platform/style/image plugins.
for name in ('platforms','imageformats','multimedia','styles','tls','networkinformation'):
 if (plugins/name).is_dir():copy_regular_tree(plugins/name,binary/'qt/plugins'/name)
searches=[pathlib.Path(queries[k]) for k in ('QT_INSTALL_LIBS','QT_INSTALL_BINS') if k in queries]
if sys.platform=='darwin':
 # Homebrew splits Qt into formulae; official Qt uses the first search directory.
 searches += list(pathlib.Path('/opt/homebrew/opt').glob('qt*/lib'))
 searches += [pathlib.Path('/opt/homebrew/lib')]
inventory=stage(binary,[binary/ky.name,binary/native.name],searches)
inventory['qt_version']=queries['QT_VERSION']
# Developer machine paths are not part of a portable package's public inventory.
for item in inventory['binaries']:item.pop('source',None)
(binary/'runtime-inventory.json').write_text(json.dumps(inventory,indent=2)+'\n')
licenses=resources/'licenses';licenses.mkdir()
shutil.copy2(root/'LICENSE',licenses/'KynaMusic-MIT.txt');shutil.copy2(root/'LICENSE-ASSETS.txt',licenses/'Demo-CC0.txt')
shutil.copytree(repo/'docs/licenses/native',licenses/'native')
(licenses/'QT-SOURCES.txt').write_text('Qt '+queries['QT_VERSION']+' is dynamically linked. You may replace these libraries with ABI-compatible builds.\nCorresponding source: https://download.qt.io/archive/qt/'+'.'.join(queries['QT_VERSION'].split('.')[:2])+'/'+queries['QT_VERSION']+'/single/\nBuild instructions: https://doc.qt.io/qt-6/build-sources.html\nQt Multimedia codecs and platform dependencies vary by target; see runtime-inventory.json.\n')
if sys.platform=='darwin':
 subprocess.run(['codesign','--force','--deep','--sign','-',str(app)],check=True)
 subprocess.run(['codesign','--verify','--deep','--strict',str(app)],check=True)
elif sys.platform=='win32':
 (app/'KynaMusic.cmd').write_text('@echo off\r\ncd /d "%~dp0app"\r\n"%~dp0bin\\ky.exe" --native-library "%~dp0bin\\'+native.name+'" run main.ky\r\n')
else:
 launcher=app/'KynaMusic';launcher.write_text('#!/bin/sh\nset -eu\nAPP_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"\ncd "$APP_DIR/app"\nexec "$APP_DIR/bin/ky" --native-library "$APP_DIR/bin/'+native.name+'" run main.ky\n');launcher.chmod(0o755)
shutil.rmtree(out/'checked')
(out/'BUNDLE-AUDIT.json').write_text(json.dumps({'schema':'kyna.music-bundle/v1','native_abi':2,'qt':queries['QT_VERSION'],'production_signed':False,'binaries':len(inventory['binaries'])},indent=2)+'\n')
(out/'SHA256SUMS').write_text(''.join(digest(f)+'  '+f.relative_to(out).as_posix()+'\n' for f in sorted(app.rglob('*')) if f.is_file()))
print(app)
