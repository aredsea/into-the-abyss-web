'use strict';
const $=id=>document.getElementById(id), canvas=$('stage'),ctx=canvas.getContext('2d'),images=new Map();
const reduced=matchMedia('(prefers-reduced-motion: reduce)').matches;
let manifest,clip,elapsed=0,playing=false,last=0,request=0;
const load=async path=>{if(images.has(path))return images.get(path);const im=new Image();im.src=path;await im.decode();images.set(path,im);return im};
function timing(){const hold=$('impact').checked&&clip.contact!==null&&!reduced?.05:0,contact=clip.contact===null?Infinity:clip.duration*clip.contact/(clip.frames-1);return{hold,contact,body:elapsed<contact?elapsed:Math.max(contact,elapsed-hold)}}
async function choose(id){const token=++request;playing=false;clip=null;$('play').disabled=$('pause').disabled=true;const next=manifest.clips.find(c=>c.id===id);await load(next.sheet);if(token!==request)return;clip=next;elapsed=0;$('quality').textContent=next.review;$('contact').href=next.contact_sheet;
 for(const b of $('variants').children)b.setAttribute('aria-pressed',String(b.dataset.id===id));$('play').disabled=$('pause').disabled=false;$('pause').textContent='계속 재생';draw()}
function sprite(im,n,x,y,scale=1.7){ctx.drawImage(im,(n%5)*256,Math.floor(n/5)*256,256,256,Math.round(x),Math.round(y),Math.round(256*scale),Math.round(256*scale))}
function draw(){ctx.imageSmoothingEnabled=false;ctx.fillStyle='#111c21';ctx.fillRect(0,0,640,480);const bg=images.get('../assets/academy.png');if(bg){ctx.globalAlpha=.24;ctx.drawImage(bg,0,0,640,480);ctx.globalAlpha=1}if(!clip)return;
 const tm=timing(),frame=Math.min(clip.frames-1,Math.floor(Math.min(1,tm.body/clip.duration)*(clip.frames-1)+.0001)),age=elapsed-tm.contact,active=$('impact').checked&&clip.contact!==null&&!$('compare').checked,hit=active&&age>=0&&age<.18;
 ctx.save();if(hit&&!reduced)ctx.translate(Math.round(Math.sin(age*170)*2*(1-age/.18)),0);
 const base=images.get('../assets/hildegard-seed.png'),sheet=images.get(clip.sheet);
 if($('compare').checked){ctx.drawImage(base,-20,79,384,384);sprite(sheet,frame,280,79,1.5);ctx.fillStyle='#e8e3d7';ctx.font='18px Malgun Gothic,sans-serif';ctx.fillText('원본 자세',90,457);ctx.fillText('생성 프레임',400,457)}
 else{const enemy=images.get('../assets/executor.png'),dx=hit&&!reduced?5*(1-age/.18):0;ctx.drawImage(enemy,435+dx,210,150,190);sprite(sheet,frame,0,30,1.7);
 if(hit){ctx.strokeStyle='#f7e5bd';ctx.lineWidth=3;ctx.globalAlpha=1-age/.18;for(let i=0;i<6;i++){const a=i*Math.PI/3+.4,r=12+age*115;ctx.beginPath();ctx.moveTo(496+Math.cos(a)*r*.4,290+Math.sin(a)*r*.4);ctx.lineTo(496+Math.cos(a)*r,290+Math.sin(a)*r);ctx.stroke()}ctx.globalAlpha=1}}
 ctx.restore();$('frame').value=`${frame} / ${clip.frames-1}`;$('timeline').value=Math.round(Math.min(1,tm.body/clip.duration)*1000);$('phase').textContent=clip.contact===null?(elapsed>=clip.duration?'종료':'자세 연결'):tm.body<tm.contact?'준비':age<tm.hold?'타격 순간 멈춤':tm.body<clip.duration*.75?'베기 · 후속 자세':'회수';
 window.__motionR6={id:clip.id,frame,playing,body:tm.body,elapsed,hold:tm.hold,reduced,impact:$('impact').checked,compare:$('compare').checked,loaded:true};
}
function tick(now){const dt=last?Math.min(.1,(now-last)/1000):0;last=now;if(clip&&playing){elapsed+=dt*Number($('speed').value);if(elapsed>=clip.duration+timing().hold+.35){if($('loop').checked)elapsed=0;else{playing=false;$('pause').textContent='계속 재생'}}}draw();requestAnimationFrame(tick)}
$('play').onclick=()=>{if(!clip)return;elapsed=0;playing=true;$('pause').textContent='일시 정지'};
$('pause').onclick=()=>{if(!clip)return;if(elapsed>=clip.duration+timing().hold)elapsed=0;playing=!playing;$('pause').textContent=playing?'일시 정지':'계속 재생'};
$('timeline').oninput=()=>{if(!clip)return;playing=false;const b=Number($('timeline').value)/1000*clip.duration;elapsed=b+(b>=timing().contact?timing().hold:0);$('pause').textContent='계속 재생';draw()};
for(const id of ['impact','compare'])$(id).onchange=draw;
(async()=>{manifest=await(await fetch('manifest.json')).json();await Promise.all(['academy.png','executor.png','hildegard-seed.png'].map(n=>load('../assets/'+n)));for(const c of manifest.clips){const b=document.createElement('button');b.textContent=c.label;b.dataset.id=c.id;b.onclick=()=>choose(c.id).catch(error);$('variants').append(b)}await choose(manifest.clips[0].id);requestAnimationFrame(tick)})().catch(error);
function error(e){playing=false;$('quality').textContent='모션을 불러오지 못했습니다. 새로고침해 주세요.';console.error(e)}
