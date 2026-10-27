'use strict';
const $=id=>document.getElementById(id),ctx=$('stage').getContext('2d');
let clip,body,weapon,old,bg,frame=0,time=0,playing=false,last=0,mode='new';
const img=async src=>{const a=new Image();a.src=src;await a.decode();return a};
function lengths(){return mode==='new'?clip.durations_ms:Array(13).fill(720/13)}
function startOf(n){return lengths().slice(0,n).reduce((a,b)=>a+b,0)}
function frameAt(ms){let sum=0;const d=lengths();for(let n=0;n<d.length;n++){sum+=d[n];if(ms<sum)return n}return d.length-1}
function draw(){
 ctx.imageSmoothingEnabled=false;ctx.fillStyle='#111c21';ctx.fillRect(0,0,640,500);
 if(bg){ctx.globalAlpha=.17;ctx.drawImage(bg,0,0,640,500);ctx.globalAlpha=1}
 ctx.strokeStyle='#70796a80';ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(66,465);ctx.lineTo(564,465);ctx.stroke();
 if(!clip)return;ctx.save();ctx.translate(88,96);ctx.scale(1.6,1.6);
 const sx=(frame%5)*256,sy=Math.floor(frame/5)*256,im=mode==='new'?body:old;
 ctx.drawImage(im,sx,sy,256,256,0,0,256,256);
 if(mode==='new'&&!$('body').checked){
  const w=clip.weapon,[x,y,angle]=w.anchors[frame],patch=w.hand_patch;
  ctx.save();ctx.translate(x,y);ctx.rotate((angle-w.base_angle)*Math.PI/180);ctx.drawImage(weapon,-w.pivot[0],-w.pivot[1]);ctx.restore();
  ctx.drawImage(body,sx+x+patch[0],sy+y+patch[1],patch[2],patch[3],x+patch[0],y+patch[1],patch[2],patch[3]);
 }
 ctx.restore();$('frame').value=`${frame} / ${lengths().length-1}`;$('timeline').value=frame;
 $('phase').textContent=mode==='old'?'이전 생성 결과':frame<4?'준비 · 중심 모으기':frame===4?'발 디딤 · 가속':frame===5?'접촉':frame<9?'베기 후 자세':'회수';
 window.__motionR7={mode,frame,time,playing,bodyOnly:$('body').checked,duration:startOf(lengths().length),loaded:true};
}
function changeMode(next){mode=next;playing=false;time=0;frame=0;$('timeline').max=lengths().length-1;$('new').setAttribute('aria-pressed',String(mode==='new'));$('old').setAttribute('aria-pressed',String(mode==='old'));$('body').disabled=mode==='old';$('body').checked=false;$('pause').textContent='계속 재생';$('method').textContent=mode==='new'?'몸 12프레임 + 고정된 장검':'이전 A · 칼과 몸을 한 번에 생성';$('body-note').textContent=mode==='new'?'같은 검 이미지를 손 위치에 붙입니다. 프레임마다 검을 새로 그리지 않습니다.':'이전 시안은 칼과 흰 검기가 이미지에 합쳐져 있어 몸만 분리해서 볼 수 없습니다.';draw()}
function seek(n){playing=false;frame=Math.max(0,Math.min(lengths().length-1,n));time=startOf(frame);$('pause').textContent='계속 재생';draw()}
function tick(now){const dt=last?Math.min(now-last,100):0;last=now;if(clip&&playing){time+=dt*Number($('speed').value);const duration=startOf(lengths().length);frame=frameAt(time);if(time>=duration+400){if($('loop').checked){time=0;frame=0}else{playing=false;$('pause').textContent='계속 재생'}}}draw();requestAnimationFrame(tick)}
$('play').onclick=()=>{if(!clip)return;frame=0;time=0;playing=true;$('pause').textContent='일시 정지'};
$('pause').onclick=()=>{if(!clip)return;if(time>=startOf(lengths().length))time=0;playing=!playing;$('pause').textContent=playing?'일시 정지':'계속 재생'};
$('timeline').oninput=()=>seek(Number($('timeline').value));$('prev').onclick=()=>seek(frame-1);$('next').onclick=()=>seek(frame+1);
$('new').onclick=()=>changeMode('new');$('old').onclick=()=>changeMode('old');$('body').onchange=draw;
(async()=>{clip=await(await fetch('manifest.json')).json();[body,weapon,old,bg]=await Promise.all([img(clip.path),img(clip.weapon.path),img('../r6/assets/hildegard-attack-a/sheet.png'),img('../assets/academy.png')]);draw();requestAnimationFrame(tick)})().catch(e=>{$('description').textContent='모션을 불러오지 못했습니다. 새로고침해 주세요.';console.error(e)});
