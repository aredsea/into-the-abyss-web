/* Raster comps are preserved. Semantic button layers connect the review flow only. */
"use strict";
const $ = (id) => document.getElementById(id);
const icons = {
  town:'<path d="M3 11 12 3l9 8v10h-6v-7H9v7H3Z"/>',
  roster:'<circle cx="8" cy="7" r="3"/><circle cx="17" cy="8" r="2.5"/><path d="M2 21v-5c0-6 12-6 12 0v5zm13 0v-6c0-2-1-3-1-3 5-2 8 1 8 4v5z"/>',
  depart:'<circle cx="12" cy="12" r="9" fill="none" stroke-width="2"/><path d="m16 7-2 8-7 2 3-8z"/>',
  bag:'<path d="M5 7h14l2 14H3Z"/><path d="M9 7V5a3 3 0 0 1 6 0v2" fill="none" stroke-width="2"/>',
  journal:'<path d="M5 2h11l4 4v16H5Z"/><path d="M8 9h9M8 13h9M8 17h9" stroke="#f3efe2" fill="none" stroke-width="1.5"/>'
};
const navEntries=[["town","마을"],["roster","동료"],["depart","원정"],["bag","가방"],["journal","기록"]];
const familyNames={town:"마을과 기록",companions:"동료와 장비",preparation:"원정 준비",facilities:"마을 시설",expedition:"탐색",combat:"전투와 결과"};
let screens=[], byId={}, current=null, trail=[], choices={}, pendingAction=null, toastTimer=null, renderToken=0;

function notify(message) {
  if (!message) return;
  clearTimeout(toastTimer);
  $("toast").textContent=message;
  $("toast").classList.add("show");
  toastTimer=setTimeout(()=>$("toast").classList.remove("show"),2800);
}
function route(id,options={}) {
  if(!byId[id]) id="town";
  if(current && current.id!==id && !options.back) trail.push(current.id);
  if(location.hash.slice(1)!==id) history.pushState({scene:id},"","#"+id);
  render(id);
}
function goBack() {
  route(trail.pop() || current.back || "town",{back:true});
}
function closeDialog(id){if($(id).open) $(id).close();}
function run(h) {
  if(h.disabled) return;
  if(h.selectGroup){
    choices[h.selectGroup]=h.value;
    document.querySelectorAll(".hotspot[data-group]").forEach(b=>{
      if(b.dataset.group===h.selectGroup) {
        const selected=b.dataset.value===h.value;
        b.classList.toggle("selected",selected);
        b.setAttribute("aria-pressed",String(selected));
      }
    });
  }
  if(h.effect){
    $("screen").classList.remove("flash");
    requestAnimationFrame(()=>$("screen").classList.add("flash"));
  }
  if(h.confirm){
    pendingAction=h;
    $("action-title").textContent=h.label;
    $("action-description").textContent=h.label+" 동작을 확인할까요?";
    $("action-dialog").showModal();
    return;
  }
  if(h.to) route(h.to);
  else if(h.after) route(h.after);
  notify(h.message);
}
function makeHotspot(h,index) {
  const b=document.createElement("button");
  b.className="hotspot"+(h.visible?" visible-control":"");
  b.style.cssText="left:"+h.x+"%;top:"+h.y+"%;width:"+h.w+"%;height:"+h.h+"%";
  b.setAttribute("aria-label",h.label);
  b.dataset.hotspot=String(index);
  b.title=h.label;
  if(h.visible) b.textContent=h.label;
  if(h.disabled)b.disabled=true;
  if(h.selectGroup){
    b.dataset.group=h.selectGroup;
    b.dataset.value=h.value;
    const selected=choices[h.selectGroup]===h.value;
    b.classList.toggle("selected",selected);
    b.setAttribute("aria-pressed",String(selected));
  }
  b.addEventListener("click",()=>run(h));
  return b;
}
function render(id) {
  const s=byId[id];
  if(!s)return;
  current=s;
  const token=++renderToken;
  document.title=s.title+" · B 클릭 시안";
  $("scene-title").textContent=s.title;
  $("screen").setAttribute("aria-label",s.title+" 클릭 시안");
  $("screen").classList.toggle("is-home",!!s.home);
  $("screen").classList.remove("flash");
  $("screen").style.setProperty("--ratio",s.home?853/1844:1448/3/1086);
  $("image-loading").hidden=false;
  const img=$("scene-art");
  img.onload=()=>{if(token===renderToken)$("image-loading").hidden=true;};
  img.onerror=()=>{if(token===renderToken){$("image-loading").textContent="이미지를 불러오지 못했습니다. 화면 목록에서 다시 선택해 주세요.";$("image-loading").hidden=false;}};
  img.style.left=String(-100*s.panel)+"%";
  img.src=s.image;
  if(img.complete&&img.naturalWidth)$("image-loading").hidden=true;
  const fragment=document.createDocumentFragment();
  if(s.back){
    fragment.append(makeHotspot({label:"뒤로",x:0,y:0,w:16,h:6,to:s.back},-1));
  }
  s.hotspots.forEach((h,i)=>fragment.append(makeHotspot(h,i)));
  $("hotspots").replaceChildren(fragment);
  const nav=$("game-nav");
  nav.hidden=!s.nav;
  nav.style.height=s.home?"6.7%":"8%";
  nav.replaceChildren();
  if(s.nav) navEntries.forEach(([target,label])=>{
    const button=document.createElement("button");
    button.className="nav-button";
    button.setAttribute("aria-label",label);
    if(s.nav===target)button.setAttribute("aria-current","page");
    button.innerHTML='<svg viewBox="0 0 24 24" aria-hidden="true">'+icons[target]+'</svg><span>'+label+'</span>';
    button.addEventListener("click",()=>route(target));
    nav.append(button);
  });
  document.querySelectorAll(".scene-link").forEach(b=>{
    if(b.dataset.scene===s.id)b.setAttribute("aria-current","page");else b.removeAttribute("aria-current");
  });
  $("history-back").disabled=s.id==="town"&&!trail.length;
  closeDialog("scene-index");
  window.scrollTo(0,0);
}
function buildIndex() {
  const container=$("scene-links");
  for(const family of Object.keys(familyNames)){
    const group=screens.filter(s=>s.family===family);
    const heading=document.createElement("h2");
    heading.textContent=familyNames[family];
    container.append(heading);
    const links=document.createElement("div");
    links.className="group";
    group.forEach(s=>{
      const b=document.createElement("button");
      b.className="scene-link";
      b.dataset.scene=s.id;
      b.textContent=s.title;
      b.addEventListener("click",()=>route(s.id));
      links.append(b);
    });
    container.append(links);
  }
}
$("open-index").addEventListener("click",()=>$("scene-index").showModal());
$("history-back").addEventListener("click",goBack);
$("toggle-hints").addEventListener("click",()=>{
  const active=!document.body.classList.contains("show-hints");
  document.body.classList.toggle("show-hints",active);
  $("toggle-hints").setAttribute("aria-pressed",String(active));
});
document.querySelectorAll("[data-close]").forEach(b=>b.addEventListener("click",()=>closeDialog(b.dataset.close)));
$("restart").addEventListener("click",()=>{trail=[];choices={};closeDialog("scene-index");route("town",{back:true});notify("처음 화면으로 돌아왔습니다.");});
$("action-cancel").addEventListener("click",()=>closeDialog("action-dialog"));
$("action-confirm").addEventListener("click",()=>{
  const h=pendingAction;
  closeDialog("action-dialog");
  pendingAction=null;
  if(h){if(h.after)route(h.after);notify(h.message||"버튼 동작을 확인했습니다.");}
});
window.addEventListener("popstate",()=>{if(screens.length)render(byId[location.hash.slice(1)]?location.hash.slice(1):"town");});
window.addEventListener("hashchange",()=>{const id=location.hash.slice(1);if(byId[id]&&current?.id!==id)render(id);});
window.addEventListener("keydown",event=>{
  if(event.key==="Escape"&&!document.querySelector("dialog[open]")&&current?.id!=="town")goBack();
});
fetch("screens.json").then(r=>{if(!r.ok)throw Error("screens");return r.json();}).then(data=>{
  screens=data;byId=Object.fromEntries(screens.map(s=>[s.id,s]));
  buildIndex();
  render(byId[location.hash.slice(1)]?location.hash.slice(1):"town");
  notify("시안 속 버튼을 눌러 보세요. ‘영역’으로 누를 곳을 확인할 수 있습니다.");
}).catch(()=>{
  $("image-loading").textContent="시안을 열지 못했습니다. 새로고침해 주세요.";
});
