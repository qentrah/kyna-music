"""Collect exact-version Qt sources/notices and installed dependency notices."""
import concurrent.futures, json, pathlib, re, shutil, subprocess

def collect(repo, resources, version, output):
    from source_notices import download_source, extract_notices
    sources=output/'sources';sources.mkdir()
    cache=output.parent/'source-cache';cache.mkdir(exist_ok=True)
    base='https://download.qt.io/archive/qt/'+'.'.join(version.split('.')[:2])+'/'+version+'/submodules/'
    def qt(name):
        filename=name+'-everywhere-src-'+version+'.tar.xz'
        checksum=subprocess.check_output(['curl','--fail','--location','--silent','--show-error','--proto','=https','--proto-redir','=https','--retry','3',base+filename+'.sha256'],text=True).split()
        if len(checksum)!=2 or checksum[1].lstrip('*')!=filename or not re.fullmatch('[a-f0-9]{64}',checksum[0]):raise RuntimeError('Invalid Qt source checksum')
        archive=cache/filename;download_source(base+filename,checksum[0],archive)
        notices=extract_notices(archive,resources,name)
        shutil.copy2(archive,sources/filename)
        return {'name':name,'version':version,'url':base+filename,'sha256':checksum[0],'archive':filename,'notices':notices}
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        records=list(pool.map(qt,('qtbase','qtdeclarative','qtsvg','qtmultimedia')))
    (resources/'licenses/qt-source-inventory.json').write_text(json.dumps(records,indent=2)+'\n')
    # vcpkg's installed share folders retain the licenses for the exact built ports.
    for share in (repo/'build/vcpkg_installed').glob('*/share'):
        for copyright in share.glob('*/copyright'):
            target=resources/'licenses/vcpkg'/copyright.parent.name/'copyright';target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(copyright,target)
