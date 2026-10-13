#!/usr/bin/env python3
"""Generate six original, deterministic instrumental loops; no downloaded music."""
import array, json, math, pathlib, random, sys, wave
root=pathlib.Path(sys.argv[1]);root.mkdir(parents=True,exist_ok=True)
tracks=[('After the rain','Kyna Sessions','Slow mornings',82,57),('Soft focus','Studio North','In good time',96,60),('Night drive','Kyna Sessions','Blue hour',110,50),('Golden hour','Studio North','Daylight studies',88,62),('Somewhere quiet','Kyna Sessions','Slow mornings',72,55),('Open windows','Studio North','Daylight studies',104,59)]
items=[]
rate=22050;seconds=40
for index,(title,artist,album,bpm,root_note) in enumerate(tracks,1):
 name=f'{index:02d}';path=root/(name+'.wav')
 if not path.exists():
  rng=random.Random(index);samples=array.array('h');beat=60/bpm
  notes=[0,7,3,10,7,3,12,7];chords=[0,-2,3,-5]
  for sample in range(rate*seconds):
   t=sample/rate;within=t%beat;b=int(t/beat);chord=chords[(b//8)%4]
   freq=440*2**((root_note+chord-69)/12)
   pad=sum(math.sin(2*math.pi*freq*2**(n/12)*t) for n in [0,3,7])/3
   envelope=min(t/1.5,1)*min((seconds-t)/2,1)
   pulse=math.sin(2*math.pi*(48*within+35*(1-math.exp(-within*30))/30))*math.exp(-within*16)
   off=(t+beat/2)%beat;hat=(rng.random()*2-1)*math.exp(-off*85)*0.10
   step=t%(beat/2);melody=440*2**((root_note+12+notes[int(t/(beat/2))%8]-69)/12)
   lead=math.sin(2*math.pi*melody*t)*math.exp(-step*7)*0.10
   bass=math.sin(2*math.pi*freq/2*t)*math.exp(-within*3)*0.16
   value=(0.13*pad+0.19*pulse+hat+lead+bass)*envelope
   samples.append(int(max(-.9,min(.9,value))*32767))
  if sys.byteorder!='little':samples.byteswap()
  with wave.open(str(path),'wb') as output:
   output.setnchannels(1);output.setsampwidth(2);output.setframerate(rate);output.writeframes(samples.tobytes())
 items.append(dict(id='demo-'+name,title=title,artist=artist,album=album,path=f'qrc:/music/demo/{name}.wav',art=f'qrc:/music/ui/art/{name}.svg',liked=index in [1,4],duration='0:40'))
(root/'catalog.json').write_text(json.dumps(dict(version=1,tracks=items,playlists=[dict(id='slow',name='Slow mornings',tracks=['demo-01','demo-04','demo-05']),dict(id='focus',name='Deep focus',tracks=['demo-02','demo-06','demo-03'])],volume=.65),indent=2)+'\n')
