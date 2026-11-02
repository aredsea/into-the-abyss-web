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
 num(parseInt(m[2],36),1,1099511627776,p+'.seed');
}
function boundedTree(v,p,depth=0){
 if(depth>24)fail(p);if(v===null)return;
 if(typeof v==='number'){num(v,-Number.MAX_SAFE_INTEGER,Number.MAX_SAFE_INTEGER,p,false);return;}
 if(typeof v==='string'){text(v,p,1000);return;}
 if(typeof v==='boolean')return;
 if(Array.isArray(v)){list(v,p,4096).forEach((x,i)=>boundedTree(x,p+'.'+i,depth+1));return;}
 obj(v,p);for(const[k,x]of Object.entries(v)){if(k.length>160||['__proto__','constructor','prototype'].includes(k))fail(p);boundedTree(x,p+'.'+k,depth+1);}
}
function battle(v,p){
 const base=['schema_version','build','units','current_id','last_ally','selected_enemy','selected_action','result','rng','turn_count','history','events'];
 keys(v,[...base,'extra_state','selected_ally','inventory','r21_roster'],p);if(!Object.keys(v).length)return;
 keys(v,[...base,'extra_state','selected_ally','inventory','r21_roster'],p,base);
 if(![2,3].includes(v.schema_version))fail(p+'.schema_version');if(v.schema_version!==3)for(const k of ['extra_state','inventory','selected_ally'])if(Object.hasOwn(v,k))fail(p+'.'+k);text(v.build,p+'.build',100);
 const unitId=id=>owners.includes(id)||K.battleIds.includes(id)||/^enemy_[0-9]{1,2}$/.test(id);
 const unitText=(id,path,empty=false)=>{if(!(empty&&id==='')&&!unitId(id))fail(path);};
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
    for(const e of Object.values(x)){keys(e,['turns','amount','r21','source','by'],p+'.effect',['turns','amount']);num(e.turns,1,100,p+'.turns');num(e.amount,-100000,100000,p+'.amount',false);if('r21'in e)bool(e.r21,p+'.r21');for(const k of ['source','by'])if(k in e)unitText(e[k],p+'.effect.'+k);}
   }else if(flags.includes(k))bool(x,p+'.'+k);else num(x,0,1e6,p+'.'+k,!['remaining','gauge'].includes(k));
  }
 }
 if(v.schema_version===3){
  for(const k of ['extra_state','selected_ally','inventory'])if(!Object.hasOwn(v,k))fail(p+'.'+k);
  unitText(v.selected_ally,p+'.selected_ally');keys(v.inventory,items,p+'.inventory');for(const n of Object.values(v.inventory))num(n,0,10000,p+'.inventory');
  obj(v.extra_state,p+'.extra_state');if(Object.keys(v.extra_state).length>32)fail(p+'.extra_state');
  const booleanKeys=['reviving','haste_done','wall_saved','saved','revive','stood','counter_busy','hidden'];
  const stringKeys=['dot_owner','target','last_target','cover','protect','silenced_id'];
  const numberKeys=['prevented','streak','scar','charge_damage','overheal','pull','dot_stacks','bleed_stacks','hunts','king','free','refresh','rescue','foe_turns','cycle_a','cycle_b','source_rng'];
  for(const[id,x]of Object.entries(v.extra_state)){
   unitText(id,p+'.extra.id');keys(x,[...booleanKeys,...stringKeys,...numberKeys],p+'.extra');
   for(const[k,n]of Object.entries(x))if(booleanKeys.includes(k))bool(n,p+'.extra.'+k);else if(stringKeys.includes(k)){text(n,p+'.extra.'+k,80);if(k!=='silenced_id')unitText(n,p+'.extra.'+k,true);}else num(n,0,k==='source_rng'?2147483646:1e8,p+'.extra.'+k,false);
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
export function validate(input){try{return validateUnchecked(input);}catch(e){if(e instanceof Invalid)throw e;throw new Invalid('save.shape');}}
function validateUnchecked(input){
 boundedTree(input,'save');const s=migrate(input);
 const top=[...Object.keys(K.defaults).filter(k=>k!=='lv'),'persona','creation_r22','scene','ui','scenario','xp_r22'];
 for(const k of Object.keys(s))if(!top.includes(k)&&!/^experience_before_r22_*$/.test(k))fail(k);
 for(const[k,v]of Object.entries(s))if(/^experience_before_r22_*$/.test(k))archiveXP(v,k);
 for(const k of ['day','gold','runs','schema','serial','recruits','refreshes','quest_wins','rng'])num(s[k],['day','rng'].includes(k)?1:0,k==='rng'?2147483646:k==='gold'?1e8:1e6,k);
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
 keys(s.ui,['page','sel','msg'],'ui',['page','sel','msg']);num(s.ui.page,1,5,'ui.page');text(s.ui.sel,'ui.sel');text(s.ui.msg,'ui.msg',1000);text(s.scenario,'scenario');
 keys(s.members,owners,'members',owners);keys(s.equipment,owners,'equipment');keys(s.research,owners,'research');
 for(const[id,m]of Object.entries(s.members)){
  keys(m,['level','xp','aff','hp','mp'],'members.'+id,['level','xp','aff','hp','mp']);xp(id,m.level,m.xp);num(m.aff,-100,200,id+'.aff',false);num(m.hp,0,1e6,id+'.hp');num(m.mp,0,1e6,id+'.mp');
 }
 if(s.members.persona.level!==p.lv||s.members.persona.xp!==p.exp)fail('persona.member');
 keys(s.items,items,'items',items);for(const[k,n]of Object.entries(s.items))num(n,0,10000,'items.'+k);
 const uids=new Map();for(const e of list(s.gear,'gear',2000)){
  keys(e,['id','uid','seed','forge','tries','source_r21'],'gear',['id','uid','seed','forge','tries']);if(!gear.has(e.id)||uids.has(e.uid))fail('gear.id');
  num(e.uid,1,s.serial,'gear.uid');num(e.seed,0,1099511627776,'gear.seed');num(e.forge,0,10,'gear.forge');num(e.tries,e.forge,1e6,'gear.tries');if('source_r21'in e)bool(e.source_r21,'gear.source');uids.set(e.uid,e);
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
 // HP/MP may retain an earlier party's human synergy. Use the maximum legal party
 // bonus and the actual equipped pieces' maximum rolls, rather than a magic HP cap.
 for(const[id,m]of Object.entries(s.members)){
  const companion=K.world.companions.find(c=>c.id===id),cls=K.world.classes.find(c=>c.name===(id==='persona'?p.cls:companion?.class));
  if(!cls){if(id==='persona'&&(m.hp>1||m.mp>0))fail('persona.resources');continue;}
  const level=m.level-1;
  for(const k of ['hp','mp']){
   const curve=K.world.curves[k];let maximum=Math.floor(cls.base[k]*(1+(companion?.mod?.[k]??0)/100)*(1+(cls.grow[k]??1)*(curve.a*level+curve.b*level*level))+.5);
   if(id==='persona')maximum=Math.floor(maximum*(p.stats[k]??cls.base[k])/cls.base[k]+.5);
   else {
    if(k==='mp'&&companion.race==='엘프')maximum+=6;
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
 for(const k of ['quest','board'])if(k==='quest')quest(s[k],k);else list(s.board,k,4).forEach((q,i)=>quest(q,'board.'+i));
 const d=s.dungeon_r21;keys(d,['best','cleared_bosses','runs','sel'],'dungeon',['best','cleared_bosses','runs','sel']);num(d.best,0,9999,'best');num(d.runs,0,1e6,'dungeon.runs');num(d.sel,1,Math.max(d.best+1,1,...d.cleared_bosses.map(z=>3*(K.zones.indexOf(z)+1)+1)),'dungeon.sel');
 list(d.cleared_bosses,'bosses',K.zones.length);if(d.cleared_bosses.some(z=>!K.zones.includes(z))||new Set(d.cleared_bosses).size!==d.cleared_bosses.length)fail('bosses');
 countMap(s.acts,'acts',s.day,k=>owners.some(id=>k.startsWith(id+'_')&&/^[a-z][a-z0-9_]{0,31}$/.test(k.slice(id.length+1))));keys(s.npc_aff_r21,K.npcs,'npc_aff');for(const v of Object.values(s.npc_aff_r21))num(v,0,200,'npc_aff',false);
 for(const card of list(s.hand,'hand',10000))if(!K.world.cards.some(c=>c.id===card))fail('hand.id');
 list(s.log,'log',40).forEach(x=>text(x,'log.line',300));
 keys(s.town_r21,['seed','counter','qn','meet'],'town',['seed','counter','qn']);num(s.town_r21.seed,1,2147483646,'town.seed');for(const k of ['counter','qn'])num(s.town_r21[k],0,1e6,'town.'+k);if('meet'in s.town_r21&&!ids.includes(s.town_r21.meet))fail('town.meet');
 keys(s.commerce_r21,['bought','process_n','sold_day'],'commerce',['bought','process_n','sold_day']);num(s.commerce_r21.process_n,0,1e6,'process_n');num(s.commerce_r21.sold_day,1,s.day,'sold_day');obj(s.commerce_r21.bought,'bought');for(const[k,v]of Object.entries(s.commerce_r21.bought)){gearCode(k,'bought.code');bool(v,'bought');}
 keys(s.persona_progress_r21,['level','xp'],'persona_progress',['level','xp']);xp('persona_progress',s.persona_progress_r21.level,s.persona_progress_r21.xp);
 keys(s.xp_r22,['xp_bn'],'xp_r22');if('xp_bn'in s.xp_r22)num(s.xp_r22.xp_bn,0,1e8,'xp_bn');
 const r=s.run;keys(r,['phase','step','gold','xp','wins','event','resolved','final','battle','rested','id','rules_version','data_version','floor','seed','rift_id','stars','elites','kind','loot_items','loot_gear','last','persona_party','persona_pm','persona_xp_paid','source_quest','quest_level','quest_seed','dialogue_marks','route_version','route_seed','node','path'],'run');
 if(Object.keys(r).length){
  if(!['explore','battle','rest','done'].includes(r.phase)||r.id!==s.runs)fail('run.phase');num(r.step,0,5,'run.step');num(r.gold,0,1e6,'run.gold');num(r.xp,0,1e6,'run.xp');num(r.wins,0,6,'run.wins');for(const k of ['resolved','final','rested'])bool(r[k],'run.'+k);battle(r.battle,'run.battle');
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
 keys(s.summary,['result','gold','xp','wins','lost','gains','floor','penalty'],'summary');
 if(Object.keys(s.summary).length){if(!['clear','retreat','defeat'].includes(s.summary.result))fail('summary.result');for(const k of ['gold','xp','wins','lost'])num(s.summary[k],0,1e8,'summary.'+k);list(s.summary.gains,'gains',30).forEach(g=>{keys(g,['id','before','level','xp'],'gain',['id','before','level','xp']);if(!owners.includes(g.id))fail('gain.id');num(g.before,1,40,'gain.before');xp('gain',g.level,g.xp);});}
 if('floor'in s.summary)num(s.summary.floor,1,9999,'summary.floor');if('penalty'in s.summary)num(s.summary.penalty,0,1e8,'summary.penalty');
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
