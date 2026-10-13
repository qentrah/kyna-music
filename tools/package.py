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
# Stage only the authored Kyna project, excluding compiler checkouts and build fixtures.
project=out/'source';project.mkdir()
for name in ('main.ky','kyna.toml'):shutil.copy2(root/name,project/name)
for name in ('src','tests'):shutil.copytree(root/name,project/name)
subprocess.run([str(ky),'--native-library',str(native),'build','main.ky','--output',str(out/'checked')],cwd=project,check=True)
if sys.platform=='darwin':
 app=out/'Kyna Music.app';contents=app/'Contents';resources=contents/'Resources';binary=resources/'runtime'
 binary.mkdir(parents=True);(contents/'MacOS').mkdir()
 if not a.launcher:raise SystemExit('--launcher is required on macOS')
 shutil.copy2(a.launcher,contents/'MacOS/KynaMusic')
 (contents/'Info.plist').write_bytes(plistlib.dumps({'CFBundleName':'Kyna Music','CFBundleDisplayName':'Kyna Music','CFBundleIdentifier':'org.kyna.music','CFBundleExecutable':'KynaMusic','CFBundlePackageType':'APPL','CFBundleShortVersionString':'1.0.0','CFBundleVersion':'1','CFBundleIconFile':'KynaMusic.icns','NSHighResolutionCapable':True,'NSHumanReadableCopyright':'Kyna Music contributors. See Resources/licenses.'}))
else:
 app=out/'KynaMusic';binary=app/'bin';resources=app;binary.mkdir(parents=True)
renderer=a.launcher.resolve().parent/('music_icon_renderer.exe' if os.name=='nt' else 'music_icon_renderer')
subprocess.run([str(renderer),str(root/'ui/icons/app.svg'),str(resources/'app-icon.png'),'512'],check=True)
if sys.platform=='darwin':
 iconset=out/'KynaMusic.iconset';iconset.mkdir()
 for size in (16,32,128,256,512):
  for scale in (1,2):
   name='icon_'+str(size)+'x'+str(size)+('@2x' if scale==2 else '')+'.png'
   subprocess.run([str(renderer),str(root/'ui/icons/app.svg'),str(iconset/name),str(size*scale)],check=True)
 subprocess.run(['iconutil','-c','icns',str(iconset),'-o',str(resources/'KynaMusic.icns')],check=True)
 shutil.rmtree(iconset)
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
# Official Windows Qt SDKs contain both debug and release plugins. Ship the
# release peer only; debug plugins require non-redistributable debug CRT DLLs.
if os.name=='nt':
 for dll in (binary/'qt').rglob('*.dll'):
  if dll.stem.endswith('d') and dll.with_name(dll.stem[:-1]+dll.suffix).is_file():dll.unlink()
searches=[ky.parent]+[pathlib.Path(queries[k]) for k in ('QT_INSTALL_LIBS','QT_INSTALL_BINS') if k in queries]
if os.name=='nt':searches+=list((repo/'build/vcpkg_installed').glob('*/bin'))
if sys.platform=='darwin':
 # Homebrew splits Qt into formulae; official Qt uses the first search directory.
 searches += list(pathlib.Path('/opt/homebrew/opt').glob('qt*/lib'))
 searches += [pathlib.Path('/opt/homebrew/lib')]
inventory=stage(binary,[binary/ky.name,binary/native.name],searches)
inventory['qt_version']=queries['QT_VERSION']
# Preserve the dependency provenance for release audit before removing host paths.
(out/'build-provenance.json').write_text(json.dumps(inventory,indent=2)+'\n')
# Developer machine paths are not part of a portable package's public inventory.
for item in inventory['binaries']:item.pop('source',None)
(binary/'runtime-inventory.json').write_text(json.dumps(inventory,indent=2)+'\n')
licenses=resources/'licenses';licenses.mkdir()
shutil.copy2(root/'LICENSE',licenses/'KynaMusic-MIT.txt');shutil.copy2(root/'LICENSE-ASSETS.txt',licenses/'Demo-CC0.txt')
shutil.copytree(repo/'docs/licenses/native',licenses/'native')
(licenses/'QT-SOURCES.txt').write_text('Qt '+queries['QT_VERSION']+' is dynamically linked. You may replace these libraries with ABI-compatible builds.\nCorresponding source: https://download.qt.io/archive/qt/'+'.'.join(queries['QT_VERSION'].split('.')[:2])+'/'+queries['QT_VERSION']+'/single/\nBuild instructions: https://doc.qt.io/qt-6/build-sources.html\nQt Multimedia codecs and platform dependencies vary by target; see runtime-inventory.json.\n')
from collect_notices import collect
collect(repo,resources,queries['QT_VERSION'],out)
if sys.platform=='darwin':
 # Restore the versioned framework structure expected by Apple's bundle signer.
 for framework in sorted(app.rglob('*.framework')):
  versions=framework/'Versions';version=next(p for p in versions.iterdir() if p.is_dir() and p.name!='Current')
  (versions/'Current').symlink_to(version.name)
  (framework/framework.stem).symlink_to('Versions/Current/'+framework.stem)
  if (framework/'Resources').exists():shutil.rmtree(framework/'Resources')
  (framework/'Resources').symlink_to('Versions/Current/Resources')
 for path in app.rglob('*'):
  if path.is_file():path.chmod(path.stat().st_mode | 0o200)
 for framework in sorted(app.rglob('*.framework')):
  subprocess.run(['codesign','--force','--sign','-',str(framework)],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 # Framework signing changes binary signatures. Refresh hashes before sealing the app.
 for record in inventory['binaries']:record['sha256']=digest(binary/record['path'])
 (binary/'runtime-inventory.json').write_text(json.dumps(inventory,indent=2)+'\n')
 subprocess.run(['codesign','--force','--sign','-',str(app)],check=True)
 subprocess.run(['codesign','--verify','--deep','--strict',str(app)],check=True)
else:
 if not a.launcher:raise SystemExit('--launcher is required for desktop packaging')
 shutil.copy2(a.launcher,app/('KynaMusic.exe' if os.name=='nt' else 'KynaMusic'))
shutil.rmtree(out/'checked');shutil.rmtree(project)
(out/'BUNDLE-AUDIT.json').write_text(json.dumps({'schema':'kyna.music-bundle/v1','native_abi':2,'qt':queries['QT_VERSION'],'production_signed':False,'binaries':len(inventory['binaries'])},indent=2)+'\n')
(out/'SHA256SUMS').write_text(''.join(digest(f)+'  '+f.relative_to(out).as_posix()+'\n' for f in sorted(app.rglob('*')) if f.is_file()))
# Archive first: preserve executable permissions and framework symlinks across CI downloads.
archive=out/('kyna-music-'+('macos' if sys.platform=='darwin' else 'windows' if sys.platform=='win32' else 'linux'))
if sys.platform=='darwin':
 subprocess.run(['ditto','-c','-k','--sequesterRsrc','--keepParent',str(app),str(archive)+'.zip'],check=True)
 archive=pathlib.Path(str(archive)+'.zip')
elif sys.platform=='win32':
 archive=pathlib.Path(shutil.make_archive(str(archive),'zip',out,app.name))
else:
 archive=pathlib.Path(shutil.make_archive(str(archive),'gztar',out,app.name))
(out/'ARCHIVE-SHA256SUMS').write_text(digest(archive)+'  '+archive.name+'\n')
print(app)
