'use strict';
const $=id=>document.getElementById(id),c=$('stage').getContext('2d');c.imageSmoothingEnabled=false;
const images=new Map();let data,person='hildegard',action='personal',t=0,playing=false,last=0,active,request=0;
const labels={attack:'공격',guard:'방어',taunt:'도발',personal:'고유 스킬'};
async function img(path){if(images.has(path))return images.get(path);const im=new Image();im.src=path;await im.decode();images.set(path,im);return im}
function phase(p){return p<.22?'준비':p<.4?'발동':p<.75?'유지 · 후속':'복귀'}
async function choose(id,a='personal'){
 const token=++request;person=id;action=a;active=null;playing=false;
 $('play').disabled=true;$('pause').disabled=true;$('phase').textContent='불러오는 중';
 for(const b of $('actions').children)b.disabled=true;
 const clip=data.clips.find(x=>x.id===id+'-'+a);if(!clip)throw Error('Missing clip '+id+'-'+a);
 await img(clip.sheet);await img('assets/'+id+'-seed.png');
 if(clip.vfx){for(const name of ['behind','front','whole']){const f=clip.vfx.clips.find(x=>x.name===name);if(f)await img(clip.vfx.path+'/'+f.sheets[0].file)}}
 if(token!==request)return;active=clip;t=0;playing=!matchMedia('(prefers-reduced-motion: reduce)').matches;
 $('character-name').textContent=data.people[id].name+' · '+data.people[id].weapon;
 $('skill-name').textContent=clip.label;$('target').textContent=clip.target;$('rule').textContent=clip.rule;$('quality').textContent=clip.review;
 $('characters').replaceChildren(...Object.entries(data.people).map(([key,p])=>{const b=document.createElement('button');b.textContent=p.name;b.setAttribute('aria-pressed',String(key===id));b.onclick=()=>choose(key);return b}));
 $('actions').replaceChildren(...Object.entries(labels).filter(([key])=>data.clips.some(x=>x.id===id+'-'+key)).map(([key,label])=>{const b=document.createElement('button');b.textContent=label;b.setAttribute('aria-pressed',String(key===a));b.onclick=()=>choose(id,key);return b}));
 $('play').disabled=false;$('pause').disabled=false;$('pause').textContent=playing?'일시 정지':'계속 재생';draw();
}
function imageAt(im,x,y,w,h,alpha=1){c.save();c.globalAlpha=alpha;c.drawImage(im,Math.round(x),Math.round(y),w,h);c.restore()}
function sprite(index,x,y,scale){const im=images.get(active.sheet),n=Math.min(active.frames-1,index);c.drawImage(im,(n%5)*256,Math.floor(n/5)*256,256,256,Math.round(x-128*scale),Math.round(y-230*scale),256*scale,256*scale)}
function fxClip(name,p,x,y,scale=1){const v=active.vfx;if(!v)return;const f=v.clips.find(z=>z.name===name);if(!f)return;const n=Math.floor(p*(v.frames-1))-f.start_frame;if(n<0||n>=f.frames)return;const s=f.sheets[0],im=images.get(v.path+'/'+s.file);c.drawImage(im,(n%s.columns)*f.frame.w,Math.floor(n/s.columns)*f.frame.h,f.frame.w,f.frame.h,Math.round(x+f.offset.x*scale),Math.round(y+f.offset.y*scale),f.frame.w*scale,f.frame.h*scale)}
function draw(){
 c.clearRect(0,0,720,560);const bg=images.get('assets/academy.png');if(bg){const factor=Math.max(720/bg.width,560/bg.height);c.drawImage(bg,(720-bg.width*factor)/2,(560-bg.height*factor)/2,bg.width*factor,bg.height*factor)}
 c.fillStyle='rgba(5,13,18,.55)';c.fillRect(0,0,720,560);const g=c.createLinearGradient(0,380,0,560);g.addColorStop(0,'transparent');g.addColorStop(1,'#081015');c.fillStyle=g;c.fillRect(0,380,720,180);
 if(!active)return;const p=Math.min(1,t/active.duration),n=Math.min(active.frames-1,Math.floor(p*active.frames));let x=245,y=460,scale=1.65;
 const fx=$('fx').checked,compare=$('base').checked,enemy=images.get('assets/executor.png');
 if(compare){x=480;scale=1.45;imageAt(images.get('assets/'+person+'-seed.png'),70,460-230*scale,256*scale,256*scale);c.fillStyle='#d4cbb7';c.font='22px sans-serif';c.fillText('원본 자세',125,510);c.fillText('생성 모션',426,510)}
 else if(enemy){const hit=(action==='attack'||person!=='hildegard')&&p>.35&&p<.55;imageAt(enemy,483+(hit&&!matchMedia('(prefers-reduced-motion: reduce)').matches?Math.sin(p*80)*3:0),252,180,225,.72);if(person==='teiris'){imageAt(images.get('assets/apprentice.png'),437,158,90,133,.72);imageAt(images.get('assets/orb.png'),610,130,88,107,.72)}}
 c.fillStyle='#0008';c.beginPath();c.ellipse(x,y+3,90,14,0,0,Math.PI*2);c.fill();
 if(fx&&person==='hildegard'&&action==='personal')fxClip('behind',p,x,y,scale);
 sprite(n,x,y,scale);
 if(fx&&!compare){
  if(person==='hildegard'&&action==='personal')fxClip('front',p,x,y,scale);
  else if(person==='teiris'){fxClip('whole',p,564,330,1.03);fxClip('whole',Math.max(0,p-.04),482,230,.65);fxClip('whole',Math.max(0,p-.07),650,185,.55)}
  else if(person==='bargut')fxClip('whole',p,510,330,1.35);
  else if(action==='taunt'&&p>.25&&p<.75){c.strokeStyle='#e2b97b';c.lineWidth=3;const r=(p-.25)*270;c.beginPath();c.ellipse(x,y,r,r*.24,0,0,Math.PI*2);c.stroke()}
  else if(action==='guard'&&p>.3&&p<.65){c.strokeStyle='#c6e1e8';c.lineWidth=4;c.beginPath();c.arc(x+83,y-180,60,-1.1,1.1);c.stroke()}
 }
 $('phase').textContent=phase(p);$('frame').value=n+' / '+(active.frames-1);$('timeline').value=Math.round(p*1000);
 window.__motionTest={id:active.id,frame:n,progress:p,playing,effects:fx,compare,loaded:true};
}
function tick(now){const dt=last?Math.min(.1,(now-last)/1000):0;last=now;if(active&&playing){t+=dt*Number($('speed').value);if(t>=active.duration+.45){if($('loop').checked)t=0;else{t=active.duration;playing=false;$('pause').textContent='계속 재생'}}}draw();requestAnimationFrame(tick)}
$('play').onclick=()=>{if(!active)return;t=0;playing=true;$('pause').textContent='일시 정지';draw()};
$('pause').onclick=()=>{if(!active)return;playing=!playing;if(t>=active.duration)t=0;$('pause').textContent=playing?'일시 정지':'계속 재생';draw()};
$('timeline').oninput=()=>{if(!active)return;playing=false;t=Number($('timeline').value)/1000*active.duration;$('pause').textContent='계속 재생';draw()};
for(const id of ['fx','base'])$(id).onchange=draw;
document.addEventListener('visibilitychange',()=>{if(document.hidden){playing=false;$('pause').textContent='계속 재생'}});
(async()=>{const r=await fetch('manifest.json');if(!r.ok)throw Error('manifest '+r.status);data=await r.json();await Promise.all([img('assets/academy.png'),img('assets/executor.png'),img('assets/apprentice.png'),img('assets/orb.png')]);await choose('hildegard');requestAnimationFrame(tick)})().catch(e=>{$('quality').textContent='불러오지 못했습니다: '+e.message;console.error(e)});
