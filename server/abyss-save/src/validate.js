import K from './known.json' with {type:'json'};
export class Invalid extends Error { constructor(path){super('invalid_save');this.path=path;} }
const fail=p=>{throw new Invalid(p);};
const obj=(v,p)=>{if(!v||Array.isArray(v)||typeof v!=='object')fail(p);return v;};
const keys=(v,allowed,p,required=[])=>{obj(v,p);for(const k of Object.keys(v))if(!allowed.includes(k))fail(p+'.'+k);for(const k of required)if(!Object.hasOwn(v,k))fail(p+'.'+k);};
const num=(v,lo,hi,p,integer=true)=>{if(typeof v!=='number'||!Number.isFinite(v)||v<lo||v>hi||(integer&&!Number.isInteger(v)))fail(p);};
const text=(v,p,max=300)=>{if(typeof v!=='string'||v.length>max)fail(p);};
const bool=(v,p)=>{if(typeof v!=='boolean')fail(p);};
const list=(v,p,max=100)=>{if(!Array.isArray(v)||v.length>max)fail(p);return v;};
const ids=K.world.companions.map(c=>c.id), owners=[...ids,'persona'];
const items=K.world.items.map(c=>c.id), gear=new Map(K.gear.items.map(e=>[e.id,e]));
// expansion_world builds action keys from active class skills, plus the signature skill.
const battleSkills=new Set(['personal',...K.world.classes.flatMap(c=>c.skills.filter(s=>['기본','능동'].includes(s.kind)).map(s=>s.id==='atk'?'attack':s.id))]);
const stats=['hp','mp','str','agi','int','def','spd'];
export const need=l=>Math.floor((60*l+10*l*l)*(l<10?.4:l<30?.6+.4*(l-10)/20:1)+.5);
function xp(p,l,e){num(l,1,40,p+'.level');num(e,0,l===40?0:need(l)-1,p+'.xp');}
function settle(m,level,exp){if(typeof m[level]!=='number'||typeof m[exp]!=='number')return;while(m[level]<40&&m[exp]>=need(m[level])){m[exp]-=need(m[level]);m[level]++;}if(m[level]===40)m[exp]=0;}
export function migrate(input){
 obj(input,'save');const s=structuredClone(input);
 if(![1,2,3].includes(s.schema))fail('schema');
 if(s.schema===3){
  if(s.persona)xp('persona',s.persona.lv,s.persona.exp);
  for(const[id,m]of Object.entries(obj(s.members,'members')))xp('members.'+id,m?.level,m?.xp);
 }
 // Validate required original shape before adding defaults; malformed legacy is not repaired.
 for(const key of ['day','gold','party','members','items','hand','acts','run','summary','log','runs'])if(!Object.hasOwn(s,key))fail(key);
 if(s.schema<3){
  if(s.schema===1){
   if(Object.keys(obj(s.members,'members')).length!==4||list(s.party,'party',4).length!==4)fail('legacy.party');
   const base=structuredClone(K.defaults);for(const [k,v] of Object.entries(base))if(!Object.hasOwn(s,k))s[k]=v;
   s.owned=[...base.owned];s.rng=20261027;
   for(const id of ids)if(!s.members[id])s.members[id]=base.members[id];
   const highest=Math.max(...s.owned.map(id=>s.members[id].level));
   for(const q of s.board)q.level=q.lv=Math.min(40,Math.max(1,highest+K.questDifficulty[q.difficulty].delta));
  }
  s.schema=3;
  s.persona??={name:'',race:'',lineage:'',nation:'',cls:'',stats:{},bonus:{},fight:0,lv:1,exp:0,bonus_total:5,bonus_custom:0,skill:{prefix:'',suffix:'',prefix_lv:{},suffix_lv:{}}};
  s.creation_r22??={complete:true,legacy:true};s.scene??='town';s.ui??={page:1,sel:'',msg:''};s.scenario??='';s.xp_r22??={};
  const defaults=K.defaults;
  for(const k of ['town_r21','commerce_r21','research_editor_r21','dialogue_r21','npc_aff_r21','persona_progress_r21','dungeon_r21'])s[k]??=structuredClone(defaults[k]);
  if(!input.town_r21){const qn=Math.max(0,...s.board.filter(q=>q.source_id?.startsWith('q')).map(q=>q.id));s.town_r21={seed:s.rng,counter:qn,qn};}
  if(!input.commerce_r21)s.commerce_r21={process_n:0,sold_day:s.day,bought:{}};
 }
 // Existing P1 normalizes XP and archives exact previous values.
 const changed=[];
 for(const id of s.owned??[]) {const m=s.members[id];if(m){num(m.level,1,40,id+'.level');num(m.xp,0,1000000,id+'.xp');}if(m&&m.level<40&&m.xp>=need(m.level)){changed.push({id,level:m.level,xp:m.xp});settle(m,'level','xp');}}
 if(s.persona?.lv<40&&s.persona.exp>=need(s.persona.lv)){changed.push({id:'persona',level:s.persona.lv,xp:s.persona.exp});settle(s.persona,'lv','exp');}
 if(changed.length){let key='experience_before_r22';while(Object.hasOwn(s,key))key+='_';s[key]=changed;}
 for(const id of items)s.items[id]??=0;
 s.members.persona??={level:s.persona.lv,xp:s.persona.exp,aff:0,hp:1,mp:0};
 s.equipment.persona??={};s.research.persona??=structuredClone(s.persona.skill);
 return s;
}
function research(v,p){
 keys(v,['prefix','suffix','prefix_lv','suffix_lv'],p,['prefix','suffix','prefix_lv','suffix_lv']);
 for(const kind of ['prefix','suffix']){
  const allowed=K.research[kind==='prefix'?'prefixes':'suffixes'].map(x=>x.id);
  if(!['',...allowed].includes(v[kind]))fail(p+'.'+kind);
  keys(v[kind+'_lv'],allowed,p+'.'+kind+'_lv');for(const [k,n]of Object.entries(v[kind+'_lv']))num(n,0,10,p+'.'+k);
 }
}
function countMap(v,p,max=1e6,keyTest=()=>true){obj(v,p);if(Object.keys(v).length>2048)fail(p);for(const[k,n]of Object.entries(v)){if(k.length>160||!keyTest(k))fail(p+'.key');num(n,0,max,p+'.'+k);}}
function quest(v,p){
 keys(v,['cmp','d','difficulty','elite','gold','id','kind','level','lv','name','reward_v','rift','source_id','stars','strength','title','migration_from','town_seed'],p);
 if(!Object.keys(v).length)return;
 for(const k of ['gold','id','level'])num(v[k],k==='gold'?0:1,k==='level'?40:1e6,p+'.'+k);
 for(const k of ['lv','stars','reward_v','town_seed'])if(k in v)num(v[k],1,k==='lv'?40:k==='stars'?10:2147483646,p+'.'+k);
 for(const k of ['d','name','kind','rift','difficulty','source_id','title','migration_from'])if(k in v)text(v[k],p+'.'+k);
 if('strength'in v)num(v.strength,1.5,2,p+'.strength',false);
 for(const k of ['cmp','elite'])if(k in v)bool(v[k],p+'.'+k);
}
function gearCode(v,p){
 text(v,p,80);const m=v.match(/^([a-z0-9_]+)\.([a-z0-9]+)\.(\d+)$/);
 if(!m||!gear.has(m[1])||Number(m[3])!==K.gear.version)fail(p);
 const seed=parseInt(m[2],36);num(seed,1,1099511627776,p+'.seed');
 if(v!==gear.get(m[1]).id+'.'+seed.toString(36)+'.'+K.gear.version)fail(p);
}
function boundedTree(v,p,depth=0){
 if(depth>24)fail(p);if(v===null)return;
 if(typeof v==='number'){num(v,-Number.MAX_SAFE_INTEGER,Number.MAX_SAFE_INTEGER,p,false);return;}
 if(typeof v==='string'){text(v,p,1000);return;}
 if(typeof v==='boolean')return;
 if(Array.isArray(v)){list(v,p,4096).forEach((x,i)=>boundedTree(x,p+'.'+i,depth+1));return;}
 obj(v,p);for(const[k,x]of Object.entries(v)){if(k.length>160||['__proto__','constructor','prototype'].includes(k))fail(p);boundedTree(x,p+'.'+k,depth+1);}
}
function battle(v,p,party=[]){
 const base=['schema_version','build','units','current_id','last_ally','selected_enemy','selected_action','result','rng','turn_count','history','events'];
 keys(v,[...base,'extra_state','selected_ally','inventory','r21_roster','ctb','depletions','last_kill'],p);if(!Object.keys(v).length)return;
 keys(v,[...base,'extra_state','selected_ally','inventory','r21_roster','ctb','depletions','last_kill'],p,base);
 // Canonical 10-data MAX_ACTIONS=400; at most 28 roster entries can break
 // once per action (30-engine abyss ignores dr=1 until its lost turn).
 if('depletions'in v){if(v.schema_version!==3)fail(p+'.depletions');num(v.depletions,0,400*28,p+'.depletions');}
 if('last_kill'in v){if(v.schema_version!==3)fail(p+'.last_kill');text(v.last_kill,p+'.last_kill',40);if(v.last_kill!==''&&!owners.includes(v.last_kill))fail(p+'.last_kill');}
 if(![2,3].includes(v.schema_version))fail(p+'.schema_version');if(v.schema_version!==3)for(const k of ['extra_state','inventory','selected_ally'])if(Object.hasOwn(v,k))fail(p+'.'+k);text(v.build,p+'.build',100);
 const unitId=id=>owners.includes(id)||K.battleIds.includes(id)||/^enemy_[0-9]{1,2}$/.test(id);
 const unitText=(id,path,empty=false)=>{if(!(empty&&id==='')&&!unitId(id))fail(path);};
 const savedUnit=(id,path,empty=false)=>{unitText(id,path,empty);if(!(empty&&id==='')&&!Object.hasOwn(v.units,id))fail(path);};
 if('ctb'in v){if(v.schema_version!==3||!('r21_roster'in v))fail(p+'.ctb');keys(v.ctb,['tick','round'],p+'.ctb',['tick','round']);num(v.ctb.tick,0,1e8,p+'.ctb.tick');num(v.ctb.round,0,1e6,p+'.ctb.round');if(v.ctb.round!==Math.floor(v.ctb.tick/100))fail(p+'.ctb.round');}
 for(const k of ['current_id','last_ally','selected_enemy'])unitText(v[k],p+'.'+k);
 text(v.selected_action,p+'.selected_action',80);if(!/^([a-z_]+|item:[a-z_]+)$/.test(v.selected_action))fail(p+'.selected_action');
 if(!['','victory','defeat'].includes(v.result))fail(p+'.result');num(v.rng,1,2147483646,p+'.rng');num(v.turn_count,0,1e6,p+'.turn_count');
 for(const k of ['history','events'])lines(v[k],p+'.'+k,32,300);
 obj(v.units,p+'.units');if(Object.keys(v.units).length>32)fail(p+'.units');
 const flags=['ward_used','once','charging','broken','charged','redirected'];
 for(const[id,u]of Object.entries(v.units)){
  unitText(id,p+'.unit');keys(u,['hp','remaining','effects','mp','shield','actions','gauge','act_index',...flags],p+'.unit',['hp','remaining','effects']);
  for(const[k,x]of Object.entries(u)){
   if(k==='effects'){
    obj(x,p+'.effects');
    for(const key of Object.keys(x))if(!K.battleEffects.includes(key)&&!/^enemy_dot_[0-3]$/.test(key))fail(p+'.effect.id');
    for(const [effect,e] of Object.entries(x)){
     keys(e,['turns','amount','r21','source','by','fresh','doubled','order','heals','stacks','lifetimes','owners','bursts','initial_turns','orders'],p+'.effect',['turns','amount']);num(e.turns,1,100,p+'.turns');num(e.amount,/^enemy_dot_/.test(effect)?-1e12:-100000,/^enemy_dot_/.test(effect)?1e12:100000,p+'.amount',false);
     if(v.schema_version!==3)for(const k of ['stacks','heals','lifetimes','owners','bursts','initial_turns','orders','fresh','order'])if(Object.hasOwn(e,k))fail(p+'.effect.'+k);
     for(const k of ['r21','fresh','doubled'])if(k in e)bool(e[k],p+'.'+k);
     for(const k of ['source','by'])if(k in e)savedUnit(e[k],p+'.effect.'+k);
     if('order'in e)num(e.order,0,1e7,p+'.effect.order');
     if('heals'in e){if(effect!=='regen'||!list(e.heals,p+'.heals',400).length)fail(p+'.heals');for(const h of e.heals){keys(h,['amount','turns','action'],p+'.heal',['amount','turns','action']);num(h.amount,0,1e5,p+'.heal.amount',false);num(h.turns,1,100,p+'.heal.turns');num(h.action,1,400,p+'.heal.action');}}
     const metadata=['lifetimes','owners','bursts','initial_turns','orders'];
     if(metadata.some(k=>k in e)&&!('stacks'in e))fail(p+'.stacks');
     if('stacks'in e){if(effect!=='dot'||!list(e.stacks,p+'.stacks',6).length)fail(p+'.stacks');for(const n of e.stacks)num(n,0,1e5,p+'.stack',false);if(Math.abs(e.stacks.reduce((a,b)=>a+b,0)-e.amount)>1e-7*Math.max(1,Math.abs(e.amount)))fail(p+'.stack.sum');
      for(const k of metadata)if(k in e){list(e[k],p+'.'+k,6);if(e[k].length!==e.stacks.length)fail(p+'.'+k);for(const n of e[k])if(k==='owners')savedUnit(n,p+'.owner',true);else num(n,['lifetimes','initial_turns'].includes(k)?1:0,k==='orders'?1e7:['lifetimes','initial_turns'].includes(k)?100:1e4,p+'.'+k,k!=='bursts');}
     }
    }
   }else if(flags.includes(k))bool(x,p+'.'+k);else num(x,k==='remaining'&&'ctb'in v?-1e6:0,1e6,p+'.'+k,!['remaining','gauge'].includes(k));
  }
 }
 if(v.schema_version===3){
  for(const k of ['extra_state','selected_ally','inventory'])if(!Object.hasOwn(v,k))fail(p+'.'+k);
  unitText(v.selected_ally,p+'.selected_ally');keys(v.inventory,items,p+'.inventory');for(const n of Object.values(v.inventory))num(n,0,Number.MAX_SAFE_INTEGER,p+'.inventory');
  obj(v.extra_state,p+'.extra_state');if(Object.keys(v.extra_state).length>32)fail(p+'.extra_state');
  const booleanKeys=['reviving','haste_done','wall_saved','saved','revive','stood','counter_busy','hidden','echo','echoing','penetrating','decl','inch','jm','double_turn'];
  const stringKeys=['dot_owner','target','last_target','last_attacker','cover','protect','silenced_id'];
  const numberKeys=['prevented','streak','scar','charge_damage','overheal','pull','dot_stacks','bleed_stacks','hunts','king','free','refresh','rescue','foe_turns','cycle_a','cycle_b','source_rng','judith_sp0','judith_until','death_tick','first_attack_action','streak_action','frenzy_action','echo_action','personal_pull','enc','dset','mamp','cover_turns','seal_until','jd','cor','hg_index','karashin_kills','dot_order','scr','sws','lsd','lsn','wlu','wwn','blc','blk','blu','hh','sgs','fzx','fzn','fzr','kg','adv','lmc','f1','ch','chk','chu','huc','hbk','hbu'];
  const globals=['gear_gw','gear_gk','gear_gb','gear_gt'];
  const allies=party.length?party.filter(id=>Object.hasOwn(v.units,id)):Object.keys(v.units).filter(id=>owners.includes(id));const enemies=Object.keys(v.units).filter(id=>!owners.includes(id));
  const slot=(n,path,ally=false)=>{num(n,1,4+enemies.length,path);if(n<=4?n>allies.length:ally)fail(path);};
  for(const[id,x]of Object.entries(v.extra_state)){
   savedUnit(id,p+'.extra.id');keys(x,[...booleanKeys,...stringKeys,...numberKeys,...globals],p+'.extra');
   for(const[k,n]of Object.entries(x))if(globals.includes(k)){
    if(id!==allies[0])fail(p+'.gear.owner');
    if(k==='gear_gk'){keys(n,['pa_echo','gl_king'],p+'.gear_gk');for(const b of Object.values(n))bool(b,p+'.gear_gk');continue;}
    const fields={gear_gw:['n','p','who'],gear_gb:['t','d'],gear_gt:['t','e','d','x','n']}[k];keys(n,fields,p+'.'+k,fields);for(const z of Object.values(n))num(z,0,1e7,p+'.'+k,false);
    for(const f of ['who','t','e'])if(f in n)slot(n[f],p+'.'+k+'.'+f,f==='who');
    if(k==='gear_gw'){num(n.n,1,100,p+'.gear_gw.n');num(n.p,0,100,p+'.gear_gw.p',false);}
   }else if(booleanKeys.includes(k))bool(n,p+'.extra.'+k);else if(stringKeys.includes(k)){text(n,p+'.extra.'+k,80);if(k==='silenced_id'){if(!/^[a-z_]{1,40}$/.test(n)||!battleSkills.has(n))fail(p+'.extra.'+k);}else savedUnit(n,p+'.extra.'+k,true);}else num(n,k==='source_rng'||k==='judith_sp0'?1:0,k==='source_rng'?2147483646:1e7,p+'.extra.'+k,['source_rng','judith_until','death_tick'].includes(k));
  }
 }
 if('r21_roster'in v)list(v.r21_roster,p+'.roster',28).forEach(e=>{keys(e,['foe_id','phase','target_id'],p+'.roster',['foe_id','phase','target_id']);if(e.foe_id!==''&&!K.battleIds.includes(e.foe_id))fail(p+'.foe_id');num(e.phase,1,2,p+'.phase');unitText(e.target_id,p+'.target',true);});
}
function lines(v,p,max=32,width=1000){list(v,p,max).forEach(x=>text(x,p+'.line',width));}
function archiveXP(v,p){list(v,p,31).forEach(e=>{keys(e,['id','level','xp'],p,['id','level','xp']);if(!owners.includes(e.id))fail(p+'.id');num(e.level,1,40,p+'.level');num(e.xp,0,1000000,p+'.xp');});}
function transition(v,p,owned){
 keys(v,['from','to','situation','lines','who','kind','id','direction'],p);if(!Object.keys(v).length)return;
 for(const k of ['from','to'])if(!K.dialogueStages.includes(v[k]))fail(p+'.'+k);
 text(v.situation,p+'.situation',300);lines(v.lines,p+'.lines');
 if('who'in v&&!owned.includes(v.who))fail(p+'.who');if('kind'in v&&v.kind!=='transition')fail(p+'.kind');
 if('direction'in v&&!['up','down'].includes(v.direction))fail(p+'.direction');
 if('id'in v){if(typeof v.id!=='string'||!Object.hasOwn(K.dialogueTransitions,v.id))fail(p+'.id');const t=K.dialogueTransitions[v.id];if(t.from!==v.from||t.to!==v.to||t.direction!==v.direction||('who'in v&&t.who!==v.who))fail(p+'.transition');}
}
function progress(v,p){keys(v,['level','xp'],p,['level','xp']);num(v.level,1,40,p+'.level');num(v.xp,0,v.level===40?0:1000000,p+'.xp');}
function archivedPersona(v,p){
 keys(v,['name','race','lineage','nation','cls','stats','bonus','fight','lv','exp','bonus_total','bonus_custom','skill'],p);
 for(const[k,x]of Object.entries(v)){
  if(['name','race','lineage','nation','cls'].includes(k))text(x,p+'.'+k,200);
  else if(['stats','bonus'].includes(k)){keys(x,stats,p+'.'+k);for(const n of Object.values(x))num(n,0,1000,p+'.'+k);}
  else if(k==='skill')research(x,p+'.skill');
  else num(x,k==='lv'?1:0,k==='lv'?40:k==='exp'?1000000:k==='fight'||k==='bonus_custom'?1:99,p+'.'+k);
 }
}
function extensions(s){
 if('equipment_vitals_before_r14'in s){const a=s.equipment_vitals_before_r14;keys(a,['hp','mp','battle_hp','battle_mp','maxima_hp','maxima_mp'],'equipment_vitals_before_r14');if(!Object.keys(a).length)fail('equipment_vitals_before_r14');for(const n of Object.values(a))num(n,0,1e6,'equipment_vitals_before_r14.value');}
 for(const[k,a]of Object.entries(s))if(/^persona_migration_r21_*$/.test(k)){
  keys(a,['schema','progress','persona','authority'],k,['schema','progress','persona','authority']);num(a.schema,1,3,k+'.schema');progress(a.progress,k+'.progress');archivedPersona(a.persona,k+'.persona');
  if(a.authority!==(a.schema<3?'r21-progress':'p1-persona'))fail(k+'.authority');
 }
 if('settings'in s){keys(s.settings,['lang','diff','chron'],'settings');if('lang'in s.settings&&!['ko','en'].includes(s.settings.lang))fail('settings.lang');if('diff'in s.settings)num(s.settings.diff,1,3,'settings.diff');if('chron'in s.settings)num(s.settings.chron,0,1,'settings.chron');}
 if('place'in s&&!['','town','guild','shop','inn','smithy','archive','gate','alley','shelter','lamp'].includes(s.place))fail('place');
 if('favs'in s){list(s.favs,'favs',3);if(new Set(s.favs).size!==s.favs.length||s.favs.some(id=>!s.owned.includes(id)))fail('favs');}
 if('chronicle_r22'in s){keys(s.chronicle_r22,['list','queue'],'chronicle',['list','queue']);lines(s.chronicle_r22.list,'chronicle.list',60,120);lines(s.chronicle_r22.queue,'chronicle.queue',4096,120);}
 if('panels_r22'in s){
  const p=s.panels_r22;keys(p,['tab','sel','page','msg','panel','bg'],'panels');
  for(const k of ['tab','sel','msg','panel'])if(k in p)text(p[k],'panels.'+k,k==='msg'?1000:100);
  if('page'in p)num(p.page,1,1000000,'panels.page');
  if('panel'in p&&!['codex','status','inventory'].includes(p.panel))fail('panels.panel');
  if('sel'in p&&!['',...owners].includes(p.sel))fail('panels.sel');
  if('tab'in p&&!/^(|all|rec|bag|me|el(?:_[a-z]+)?|cls(?:_[a-z]+)?)$/.test(p.tab))fail('panels.tab');
  if('bg'in p){const b=p.bg;keys(b,['pg','cls','slot','rar','sel','cmp','conf'],'panels.bg');if('pg'in b)num(b.pg,1,1000000,'bg.pg');
   for(const k of ['cls','slot','rar','sel','cmp','conf'])if(k in b)text(b[k],'bg.'+k,80);
   if(b.cls&&!K.world.classes.some(c=>c.id===b.cls))fail('bg.cls');if(b.slot&&!['weapon','armor','acc'].includes(b.slot))fail('bg.slot');if(b.rar&&!['common','fine','rare','epic','legend'].includes(b.rar))fail('bg.rar');
   for(const k of ['sel','conf'])if(b[k])gearCode(b[k],'bg.'+k);if(b.cmp&&!owners.includes(b.cmp))fail('bg.cmp');
  }
 }
}
function itemCounts(v,p){keys(v,[...items,'sh_s','sh_m','sh_l'],p);for(const n of Object.values(v))num(n,0,Number.MAX_SAFE_INTEGER,p);}
function settlement(v,p,s){
 const base=['result','gold','xp','wins','lost','gains','floor','penalty'];
 const extra=['expedition_version','steps','kept_gold','lost_items','gear_lost','lost_gear','first','aff','fell','items','gear','title'];
 keys(v,[...base,...extra],p);if(!Object.keys(v).length)return;
 if(!Object.hasOwn(v,'expedition_version'))for(const k of ['steps','first','aff','fell'])if(Object.hasOwn(v,k))fail(p+'.'+k);
 keys(v,[...base,...extra],p,['result','gold','xp','wins','lost','gains']);
 if(!['clear','retreat','defeat'].includes(v.result))fail(p+'.result');
 for(const k of ['gold','xp','wins','lost','penalty','kept_gold','gear_lost','lost_gear'])if(k in v)num(v[k],0,k==='wins'?6:Number.MAX_SAFE_INTEGER,p+'.'+k);
 if('floor'in v)num(v.floor,1,10000,p+'.floor');
 list(v.gains,p+'.gains',31).forEach(g=>{keys(g,['id','before','level','xp'],p+'.gain',['id','before','level','xp']);if(!owners.includes(g.id))fail(p+'.gain.id');num(g.before,1,40,p+'.gain.before');xp(p+'.gain',g.level,g.xp);});
 if('title'in v)text(v.title,p+'.title');if('gear'in v)list(v.gear,p+'.gear',2000).forEach(c=>gearCode(c,p+'.gear.code'));
 if('items'in v)itemCounts(v.items,p+'.items');if('lost_items'in v)itemCounts(v.lost_items,p+'.lost_items');
 if('expedition_version'in v){num(v.expedition_version,22,22,p+'.version');keys(v,[...base,...extra],p,['steps','kept_gold','lost_items','gear_lost','lost_gear','first','aff','fell','items','gear']);num(v.steps,0,5,p+'.steps');for(const k of ['first','fell'])bool(v[k],p+'.'+k);keys(v.aff,s.owned,p+'.aff');for(const n of Object.values(v.aff))num(n,0,300,p+'.aff',false);}
}
function expedition(s){
 const r=s.run;if('chronicle_choice'in r&&r.chronicle_choice!=='home')fail('run.chronicle_choice');
 if('settings_battle_r22'in r){keys(r.settings_battle_r22,['key','multiplier'],'settings_battle',['key','multiplier']);if(!/^\d+:\d+:(true|false)$/.test(r.settings_battle_r22.key)||![.8,1,1.25].includes(r.settings_battle_r22.multiplier))fail('settings_battle');}
 if(!('expedition_version'in r)){for(const k of ['log','fell','ask','next_available','maxima'])if(k in r)fail('run.'+k);return;}
 num(r.expedition_version,22,22,'run.version');if(r.rift_id!==''||r.data_version!==21)fail('run.expedition');
 lines(r.log,'run.log',8,1000);for(const k of ['fell','ask','next_available'])bool(r[k],'run.'+k);
 keys(r.maxima,r.persona_party,'run.maxima',r.persona_party);
 for(const v of Object.values(r.maxima)){keys(v,['hp','mp'],'maximum',['hp','mp']);num(v.hp,1,1000000,'maximum.hp');num(v.mp,0,1000000,'maximum.mp');}
 if(r.next_available&&(r.phase!=='done'||s.summary.result!=='clear'))fail('run.next_available');
}
export function validate(input){try{return validateUnchecked(input);}catch(e){if(e instanceof Invalid)throw e;throw new Invalid('save.shape');}}
function validateUnchecked(input){
 boundedTree(input,'save');const s=migrate(input);
 const top=[...Object.keys(K.defaults).filter(k=>k!=='lv'),'persona','persona_research_r22','equipment_vitals_before_r14','creation_r22','scene','ui','scenario','xp_r22','settings','favs','panels_r22','chronicle_r22','place'];
 for(const k of Object.keys(s))if(!top.includes(k)&&!/^experience_before_r22_*$/.test(k)&&!/^persona_migration_r21_*$/.test(k))fail(k);
 for(const[k,v]of Object.entries(s))if(/^experience_before_r22_*$/.test(k))archiveXP(v,k);
 extensions(s);
 for(const k of ['day','gold','runs','schema','serial','recruits','refreshes','quest_wins','rng'])num(s[k],['day','rng'].includes(k)?1:0,k==='rng'?2147483646:k==='gold'?Number.MAX_SAFE_INTEGER:1e6,k);
 for(const k of ['owned','party']){list(s[k],k,k==='owned'?30:4);if(new Set(s[k]).size!==s[k].length||s[k].some(id=>!ids.includes(id)))fail(k);}
 if(s.party.some(id=>!s.owned.includes(id)))fail('party.owned');
 keys(s.creation_r22,['complete','legacy'],'creation_r22',['complete','legacy']);bool(s.creation_r22.complete,'complete');bool(s.creation_r22.legacy,'legacy');
 const p=s.persona;
 keys(p,['name','race','lineage','nation','cls','stats','bonus','fight','lv','exp','bonus_total','bonus_custom','skill'],'persona',['name','race','lineage','nation','cls','stats','fight','lv','exp','bonus_total','bonus_custom','skill']);
 for(const k of ['name','race','lineage','nation','cls'])text(p[k],'persona.'+k,200);
 xp('persona',p.lv,p.exp);num(p.fight,0,1,'fight');num(p.bonus_total,0,99,'bonus_total');num(p.bonus_custom,0,1,'bonus_custom');
 if(s.party.length>(p.fight===1?3:4))fail('party.capacity');
 research(p.skill,'persona.skill');keys(p.stats,stats,'persona.stats');for(const[k,n]of Object.entries(p.stats))num(n,0,1000,'persona.stats.'+k);
 keys(p.bonus??{},stats.slice(2),'persona.bonus');let spent=0;for(const[k,n]of Object.entries(p.bonus??{})){num(n,0,Math.max(3,Math.floor((p.bonus_total*3+4)/5)),'bonus.'+k);spent+=n;}if(spent>p.bonus_total)fail('bonus.total');
 if(!s.creation_r22.legacy){
  for(const[field,data]of [['race','races'],['lineage','lineages'],['nation','nations'],['cls','classes']])if(p[field]!==''&&!K.persona[data].some(x=>x.name===p[field]))fail('persona.'+field);
  const cls=K.persona.classes.find(c=>c.name===p.cls);
  if(s.creation_r22.complete){
   if(!cls||!p.race||!p.nation||spent!==p.bonus_total||(p.race==='수인'&&!p.lineage))fail('persona.creation');
   const race=K.persona.races.find(r=>r.name===p.race)?.id,nation=K.persona.nations.find(n=>n.name===p.nation)?.id;
   if(K.persona.blocked[nation]?.[race])fail('persona.blocked');
   for(const k of stats){const expected=cls[k]+(p.bonus?.[k]??0)*(k==='spd'?2:1);if(p.stats[k]!==expected)fail('persona.stats.'+k);}
  }
 }
 if(!['create','scenario','town'].includes(s.scene)||s.creation_r22.complete!==(s.scene==='town'))fail('scene');
 keys(s.ui,['page','sel','msg','tab'],'ui',['page','sel','msg']);num(s.ui.page,1,5,'ui.page');text(s.ui.sel,'ui.sel');text(s.ui.msg,'ui.msg',1000);if('tab'in s.ui&&!['','front','back'].includes(s.ui.tab))fail('ui.tab');text(s.scenario,'scenario');
 keys(s.members,owners,'members',owners);keys(s.equipment,owners,'equipment');keys(s.research,owners,'research');
 for(const[id,m]of Object.entries(s.members)){
  keys(m,['level','xp','aff','hp','mp'],'members.'+id,['level','xp','aff','hp','mp']);xp(id,m.level,m.xp);num(m.aff,-100,200,id+'.aff',false);num(m.hp,0,1e6,id+'.hp');num(m.mp,0,1e6,id+'.mp');
 }
 if(s.members.persona.level!==p.lv||s.members.persona.xp!==p.exp)fail('persona.member');
 // 71-shop's fixed, non-sale bonus is optional in older saves (cap 99).
 keys(s.items,[...items,'charm_potion'],'items',items);for(const[k,n]of Object.entries(s.items))num(n,0,k==='charm_potion'?99:Number.MAX_SAFE_INTEGER,'items.'+k);
 const uids=new Map();for(const e of list(s.gear,'gear',2124)){
  keys(e,['id','uid','seed','forge','tries','source_r21','code'],'gear',['id','uid','seed','forge','tries']);if(!gear.has(e.id)||uids.has(e.uid))fail('gear.id');
  num(e.seed,0,1099511627776,'gear.seed');
  if('code'in e){gearCode(e.code,'gear.code');if(e.source_r21!==true||e.code!==e.id+'.'+e.seed.toString(36)+'.'+K.gear.version)fail('gear.code.identity');}
  num(e.uid,1,s.serial,'gear.uid');num(e.forge,0,10,'gear.forge');num(e.tries,e.forge,1e6,'gear.tries');if('source_r21'in e)bool(e.source_r21,'gear.source');uids.set(e.uid,e);
 }
 const used=new Set();for(const[id,v]of Object.entries(s.equipment)){
  if(Object.keys(v).length&&id!=='persona'&&!s.owned.includes(id))fail('equipment.owner');
  keys(v,['weapon','armor','acc'],'equipment.'+id);for(const[slot,uid]of Object.entries(v)){
   const entry=uids.get(uid),g=entry&&gear.get(entry.id);if(!g||g.slot!==slot||used.has(uid))fail('equipment.uid');used.add(uid);
   const c=id==='persona'?K.world.classes.find(c=>c.name===p.cls):K.world.classes.find(c=>c.name===K.world.companions.find(x=>x.id===id)?.class);
   if(g.cls&&g.cls!=='all'&&g.cls!==c?.id)fail('equipment.class');
   if(s.members[id].level<K.gearRules.equip_lv[g.rarity])fail('equipment.level');
  }
 }
 for(const[id,v]of Object.entries(s.research))research(v,'research.'+id);
 if(s.gear.length-used.size>2000)fail('gear.capacity');
 // HP/MP may retain an earlier party's human synergy. Use the maximum legal party
 // bonus and the actual equipped pieces' maximum rolls, rather than a magic HP cap.
 for(const[id,m]of Object.entries(s.members)){
  const companion=K.world.companions.find(c=>c.id===id),cls=K.world.classes.find(c=>c.name===(id==='persona'?p.cls:companion?.class));
  if(!cls){if(id==='persona'&&(m.hp>1||m.mp>0))fail('persona.resources');continue;}
  const level=m.level-1;
  for(const k of ['hp','mp']){
   const curve=K.world.curves[k];let maximum=Math.floor(cls.base[k]*(1+(companion?.mod?.[k]??0)/100)*(1+(cls.grow[k]??1)*(curve.a*level+curve.b*level*level))+.5);
   if(id==='persona')maximum=Math.floor(maximum*(p.stats[k]??cls.base[k])/cls.base[k]+.5);
   {
    if(k==='mp'&&(id==='persona'?p.race:companion.race)==='엘프')maximum+=6;
    if(k==='hp')maximum=Math.floor(maximum*1.07+.5);
    let bonus=0;
    for(const uid of Object.values(s.equipment[id]??{})){
     const e=uids.get(uid),it=gear.get(e.id),pool=K.gear.pools[it.cls][it.slot];
     const raw=(it.base[k]??0)+(pool.includes(k)&&K.gearRules.rarity[it.rarity].affix>0?K.gear.affix_range[k][1]:0);
     bonus+=raw*(.4+.6*m.level/40)/(.4+.6*it.lv/40)*(1+e.forge*K.gearRules.forge.bonus_per_level)+.1;
    }
    maximum=Math.floor(maximum*(1+bonus/100)+.5);
   }
   if(m[k]>maximum)fail('members.'+id+'.'+k);
  }
 }
 keys(s.research_editor_r21,ids,'research_editor');for(const[id,e]of Object.entries(s.research_editor_r21)){if(!s.owned.includes(id))fail('editor.owner');keys(e,['draft','spent'],'editor',['draft','spent']);research(e.draft,'draft');num(e.spent,0,1e8,'spent');}
 if('persona_research_r22'in s){const e=s.persona_research_r22;keys(e,['draft','spent'],'persona_research');if(Object.keys(e).length){keys(e,['draft','spent'],'persona_research',['draft','spent']);research(e.draft,'persona_research.draft');num(e.spent,0,1e8,'persona_research.spent');}}
 for(const k of ['quest','board'])if(k==='quest')quest(s[k],k);else list(s.board,k,4).forEach((q,i)=>quest(q,'board.'+i));
 const d=s.dungeon_r21;keys(d,['best','cleared_bosses','runs','sel','pg','last'],'dungeon',['best','cleared_bosses','runs','sel']);num(d.best,0,9999,'best');num(d.runs,0,1e6,'dungeon.runs');num(d.sel,1,Math.max(d.best+1,1,...d.cleared_bosses.map(z=>3*(K.zones.indexOf(z)+1)+1)),'dungeon.sel');
 if('pg'in d)num(d.pg,1,Math.ceil((Math.max(d.best+1,1,...d.cleared_bosses.map(z=>3*(K.zones.indexOf(z)+1)+1))+1)/6),'dungeon.pg');if('last'in d)settlement(d.last,'dungeon.last',s);
 list(d.cleared_bosses,'bosses',K.zones.length);if(d.cleared_bosses.some(z=>!K.zones.includes(z))||new Set(d.cleared_bosses).size!==d.cleared_bosses.length)fail('bosses');
 countMap(s.acts,'acts',s.day,k=>owners.some(id=>k.startsWith(id+'_')&&/^[a-z][a-z0-9_]{0,31}$/.test(k.slice(id.length+1))));keys(s.npc_aff_r21,K.npcs,'npc_aff');for(const v of Object.values(s.npc_aff_r21))num(v,0,200,'npc_aff',false);
 for(const card of list(s.hand,'hand',10000))if(!K.world.cards.some(c=>c.id===card))fail('hand.id');
 list(s.log,'log',40).forEach(x=>text(x,'log.line',300));
 keys(s.town_r21,['seed','counter','qn','meet'],'town',['seed','counter','qn']);num(s.town_r21.seed,1,2147483646,'town.seed');for(const k of ['counter','qn'])num(s.town_r21[k],0,1e6,'town.'+k);if('meet'in s.town_r21&&!ids.includes(s.town_r21.meet))fail('town.meet');
 keys(s.commerce_r21,['bought','process_n','sold_day','forge_codes_r22','legacy_persona_progress_r22','pietro_buys'],'commerce',['bought','process_n','sold_day']);num(s.commerce_r21.process_n,0,1e6,'process_n');num(s.commerce_r21.sold_day,1,s.day,'sold_day');obj(s.commerce_r21.bought,'bought');for(const[k,v]of Object.entries(s.commerce_r21.bought)){gearCode(k,'bought.code');bool(v,'bought');}
 if('pietro_buys'in s.commerce_r21)num(s.commerce_r21.pietro_buys,0,Number.MAX_SAFE_INTEGER,'commerce.pietro_buys');
 if(s.commerce_r21.forge_codes_r22!==undefined){obj(s.commerce_r21.forge_codes_r22,'forge_codes');for(const[code,f]of Object.entries(s.commerce_r21.forge_codes_r22)){gearCode(code,'forge_code');keys(f,['forge','tries'],'forge',['forge','tries']);num(f.forge,0,10,'forge');num(f.tries,f.forge,Number.MAX_SAFE_INTEGER,'tries');}}
 if('legacy_persona_progress_r22'in s.commerce_r21)progress(s.commerce_r21.legacy_persona_progress_r22,'legacy_progress');
 if('persona_progress_r21'in s)keys(s.persona_progress_r21,['level','xp'],'persona_progress',['level','xp']);if('persona_progress_r21'in s)xp('persona_progress',s.persona_progress_r21.level,s.persona_progress_r21.xp);
 keys(s.xp_r22,['xp_bn'],'xp_r22');if('xp_bn'in s.xp_r22)num(s.xp_r22.xp_bn,0,1e8,'xp_bn');
 const r=s.run;keys(r,['phase','step','gold','xp','wins','event','resolved','final','battle','rested','id','rules_version','data_version','floor','seed','rift_id','stars','elites','kind','loot_items','loot_gear','last','persona_party','persona_pm','persona_xp_paid','source_quest','quest_level','quest_seed','dialogue_marks','route_version','route_seed','node','path','expedition_version','log','fell','ask','next_available','maxima','settings_battle_r22','chronicle_choice'],'run');
 if(Object.keys(r).length){
  if(!['explore','battle','rest','done'].includes(r.phase)||r.id!==s.runs)fail('run.phase');num(r.step,0,5,'run.step');num(r.gold,0,1e6,'run.gold');num(r.xp,0,1e6,'run.xp');num(r.wins,0,6,'run.wins');for(const k of ['resolved','final','rested'])bool(r[k],'run.'+k);battle(r.battle,'run.battle',r.persona_party??s.party);
  if('floor'in r)num(r.floor,1,10000,'run.floor');if('seed'in r)num(r.seed,1,2147483646,'run.seed');if('elites'in r)num(r.elites,0,2,'run.elites');if('kind'in r&&!['battle','elite','boss'].includes(r.kind))fail('run.kind');
  if('source_quest'in r)quest(r.source_quest,'run.quest');
  if('rift_id'in r&&r.rift_id!==''&&!K.rifts.some(x=>x.id===r.rift_id))fail('run.rift_id');
  if('stars'in r)num(r.stars,1,10,'run.stars');
  if('loot_gear'in r)list(r.loot_gear,'loot_gear',2000).forEach(c=>gearCode(c,'loot_gear.code'));
  for(const k of ['event','last','node'])if(k in r)text(r[k],'run.'+k,300);
  for(const k of ['rules_version','data_version','route_version','route_seed'])if(k in r)num(r[k],1,2147483646,'run.'+k);
  if('path'in r)lines(r.path,'run.path',32,80);
  if('persona_xp_paid'in r)num(r.persona_xp_paid,0,r.xp,'persona_xp_paid');
  if('quest_level'in r)num(r.quest_level,1,40,'quest_level');
  if('quest_seed'in r)num(r.quest_seed,1,2147483646,'quest_seed');
  if('dialogue_marks'in r){obj(r.dialogue_marks,'dialogue_marks');for(const[k,v]of Object.entries(r.dialogue_marks)){if(!/^\d+:(true|false):[a-z_]+:(down|low)$/.test(k))fail('dialogue_marks.key');bool(v,'dialogue_marks.value');}}
  if('persona_party'in r){list(r.persona_party,'persona_party',4);if(new Set(r.persona_party).size!==r.persona_party.length||r.persona_party.some(id=>!['persona',...s.owned].includes(id)))fail('persona_party');}
  if('persona_pm'in r){list(r.persona_pm,'persona_pm',4);for(const e of r.persona_pm){keys(e,['id','cls','L','race','lin','nat','ps','skill'],'pm',['id','cls','L']);if(!['',...owners].includes(e.id)||!['',...K.world.classes.map(c=>c.id)].includes(e.cls))fail('pm.id');num(e.L,1,40,'pm.L');for(const k of ['race','lin','nat'])if(k in e)text(e[k],'pm.'+k,100);if('ps'in e){keys(e.ps,stats,'pm.ps');for(const n of Object.values(e.ps))num(n,0,1000,'pm.ps',false);}if('skill'in e)research(e.skill,'pm.skill');}}
  if('loot_items'in r){keys(r.loot_items,[...items,'sh_s','sh_m','sh_l'],'loot_items');for(const n of Object.values(r.loot_items))num(n,0,10000,'loot.item');}
 }
 settlement(s.summary,'summary',s);
 expedition(s);
 const dialog=s.dialogue_r21;keys(dialog,['seen','pending','response','queue','bark_counts'],'dialogue',['seen','pending','response','queue','bark_counts']);countMap(dialog.seen,'seen',1e6,k=>Object.hasOwn(K.dialogueScenes,k));countMap(dialog.bark_counts,'bark_counts',1e6,k=>K.dialogueEvents.includes(k));
 for(const part of ['pending','response']){
  const v=dialog[part],fields=part==='pending'?['who','scene','day']:['who','scene','choice','text','lines','gained','before','after','transition'];keys(v,fields,'dialogue.'+part);
  if(!Object.keys(v).length)continue;keys(v,fields,'dialogue.'+part,fields);
  if(!s.owned.includes(v.who)||K.dialogueScenes[v.scene]?.who!==v.who)fail('dialogue.owner');
  if(part==='pending')num(v.day,s.day,s.day,'dialogue.day');else{
   if(!K.dialogueScenes[v.scene].choices.includes(v.choice))fail('dialogue.choice');text(v.text,'dialogue.text',1000);lines(v.lines,'dialogue.lines');
   for(const k of ['gained','before','after'])num(v[k],k==='gained'?-300:-100,k==='gained'?300:200,'dialogue.'+k,false);
   transition(v.transition,'dialogue.transition',s.owned);
  }
 }
 list(dialog.queue,'dialogue.queue',32).forEach(v=>{keys(v,['who','kind','lines','from','to','situation','event','id','direction'],'queue',['who','kind','lines']);if(!s.owned.includes(v.who)||!['bark','transition'].includes(v.kind))fail('queue.owner');lines(v.lines,'queue.lines');if(v.kind==='bark'){keys(v,['who','kind','lines','event'],'queue',['event']);if(!K.dialogueEvents.includes(v.event))fail('queue.event');}else transition(v,'queue',s.owned);});
 return s;
}
export function summary(s){return {day:s.day,gold:s.gold,level:s.persona.lv,best:s.dungeon_r21.best,runs:s.runs,companions:s.owned.length};}
export function rankReasons(s,previous=null,elapsed=0){
 const best=s.dungeon_r21.best,lv=s.persona.lv,reasons=[];
 if(!s.creation_r22.complete)reasons.push('만들기 미완료');
 const minimum=K.rankLevels[Math.min(Math.floor(Math.max(0,best-1)/3),K.rankLevels.length-1)];
 if(lv<minimum)reasons.push('층 대비 레벨');if(s.dungeon_r21.runs<best)reasons.push('도전 횟수 대비 층');if(s.gold>10000000)reasons.push('금화 상한');
 elapsed=Math.min(86400,Math.max(0,Number.isFinite(elapsed)?elapsed:0));
 if(previous){if(best>previous.best+2+Math.floor(elapsed/600))reasons.push('최고 층 급증');if(lv>previous.level+2+Math.floor(elapsed/300))reasons.push('레벨 급증');}
 return reasons;
}
export const percentile=(ahead,n)=>n>0?Math.max(1,Math.ceil(100*ahead/n)):null;
