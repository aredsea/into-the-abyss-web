// Execute the unmodified, current source Lua. Inputs use isolated host variables;
// no external request, AI call, source write, or server deployment is possible.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..'),src='C:/Clauede Code/dungeon-bot/bot';
const dir=root+'/verification/parity-r23';fs.mkdirSync(dir,{recursive:true});
const names=['01-game.lua','05-gen.lua','10-data.lua','15-josa.lua','24-stats.lua','29-persona-skill.lua','60-create.lua','65-codex.lua','66-status.lua','67-settings.lua','68-cloud.lua','69-rank.lua','70-town.lua','74-affection.lua','74-level.lua','81-gear.lua','85-portrait.lua','86-portrait-have.lua','88-lore.lua','89-memory.lua'];
const raws=names.map(n=>fs.readFileSync(src+'/src/'+n,'utf8'));
const config={HOST:'fixture.invalid',KEY_X:[22,27,30],KEY_M:[125,126,103],BUILD:'r23-fixture'};
const extra=names.map((n,i)=>(n==='68-cloud.lua'?`B.CLOUD=json.decode(${JSON.stringify(JSON.stringify(config))})\n`:'')+`assert(load(${JSON.stringify(raws[i])},${JSON.stringify('@'+n)},'t',_ENV))()`).join('\n');
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));const {sim,L}=await mkSim({policy:false,extra});
const out=await L(`
B.EN=nil;B.UI={}
local out={prepare={},view={},cx={},bg={},numbers={},first={},slots={},portraits={},places={},memory={},items={},fx={},has={},scenarios={},u={},cloud={},members={},levels={},aff_values={},rank={}}
local core_calls={}
debug.sethook(function()
 local info=debug.getinfo(2,'S');if info and info.source:sub(1,1)=='@' then local k=info.source:sub(2)..':'..info.linedefined;core_calls[k]=(core_calls[k] or 0)+1 end
end,'c')
local function cp(x)return json.decode(json.encode(x))end
local function one(a) return a==nil and json.null or a end
local function up(f,wanted)
 for i=1,100 do local k,v=debug.getupvalue(f,i);if not k then break end;if k==wanted then return v end end
 error('missing source upvalue '..wanted)
end
B.LANG='ko'
for _,p in ipairs({{}, {fight=0,bonus_custom=2,stats='bad',bonus_total='bad'}, {race='수인',lineage='개과',nation='x',cls='전사',fight=false,bonus_total='7.9',bonus_custom=1,bonus={str=2,agi=0,int=0,def=0,spd=1}}, {fight=3,bonus_custom=true,bonus_total=-1,bonus={agi=8}}, {stats={},bonus_total=1000,bonus={str=0,agi=0,int=0,def=0,spd=0}}}) do
 local G={persona=cp(p)};local v=B.CR.view(G);out.view[#out.view+1]={input=cp(p),value=v}
 B.CR.P(G);out.prepare[#out.prepare+1]={input=p,value=G.persona}
end
for _,s in ipairs({'','a','한😀','{{user}}','abc{{x}}','😀','é','\"<&>','나란'}) do out.first[#out.first+1]={input=s,value=B.PX.first(s)} end
for _,v in ipairs({-4.9,-1.5,-.5,-.1,0,.1,.5,1.25,1.35,2.25,2.35,9999.99,'bad','12.6'}) do out.numbers[#out.numbers+1]={input=v,num=B.PX.num(v),fnum=B.PX.fnum(v)} end
for i=-500,500 do for _,offset in ipairs({0,.05,.049999999999,.050000000001}) do local v=i/10+offset;out.numbers[#out.numbers+1]={input=v,input_exact=string.format('%.17g',v),num=B.PX.num(v),fnum=B.PX.fnum(v)} end end
for _,s in ipairs({'','weapon','armor','acc','helm','Weapon'}) do out.slots[#out.slots+1]={input=s,value=B.PX.slot_ok(s)} end
for _,l in ipairs({{}, {'levia'}, {'levia','levia','naran'}, {1,2,3}}) do for _,v in ipairs({'levia','naran','bad',1,3,4}) do out.has[#out.has+1]={list=l,input=v,value=B.has(l,v)} end end
for _,v in ipairs({-101,-.1,0,100.9,201,'bad','4.9',true,false}) do out.aff_values[#out.aff_values+1]={input=v,value=B.PX.aff({aff={levia=v}},'levia')} end
for _,persona in ipairs({{}, {lv=12.9}, {lv='bad'}, {lv='40'}, {lv=99}}) do for _,roster in ipairs({{}, {'levia'}}) do for _,levels in ipairs({{}, {levia=3.9}, {levia='bad'}, {levia='10'}, {levia=-3}}) do
 for _,cid in ipairs({'persona','levia','bad'}) do local G={persona=persona,roster=roster,lvl=levels,lv=20};out.levels[#out.levels+1]={input=G,cid=cid,value=B.PX.lv(G,cid)} end
end end end
local member_fn=up(B.PX.bg_detail,'members')
out.member_classes={}
for _,cls in ipairs({'','전사','사제','bad'}) do for _,cid in ipairs({'persona','levia','naran','bad'}) do local G={persona={cls=cls}};out.member_classes[#out.member_classes+1]={input=G,cid=cid,value=up(member_fn,'mcls')(G,cid) or ''} end end
for _,cls in ipairs({'','전사','사제','bad'}) do for _,roster in ipairs({{}, {'levia','naran','teiris'}, B.CAST_ORDER}) do for _,party in ipairs({{}, {'levia','levia','bad','naran'}, {'teiris','naran'}}) do for _,ic in ipairs({'warrior','priest','bad'}) do
 local G={persona={cls=cls},roster=roster,party=party};local m=member_fn(G,ic);local value={};for _,x in ipairs(m) do value[#value+1]={id=x.cid,same=x.same} end
 out.members[#out.members+1]={input=G,cls=ic,value=value}
end end end end
for _,scene in ipairs({'town','battle','create'}) do
 for _,arg in ipairs({'pg_bad','pg_2.9','pg_-4','pg_','pg_1e2','sel_bad','sel_persona','f_bad','bag','fav','back','open_naran'}) do
  local G=B.G_new();G.scene=scene;G.roster={'levia','naran'};G.ui.sel='levia';G.ui.msg='old';G.favs={'naran'}
  local before=cp(G);B.H.cx(G,arg,'r23');out.cx[#out.cx+1]={before=before,arg=arg,value=G}
 end
end
for _,v in ipairs({{}, {pg='2.9',cls=7,slot=false,rar={},sel=0,cmp=true,conf=false}, {pg=-4,cls='bad',slot='weapon',rar='legend',sel='x',cmp='naran',conf='x'}, {pg='bad'}}) do
 local G=B.G_new();G.ui.bg=cp(v);local before=cp(v);up(B.PX.bg_view,'bgs')(G);out.bg[#out.bg+1]={input=before,value=G.ui.bg}
end
local saved_scen,saved_en=B.SCEN,B.SCEN_EN
for _,lang in ipairs({'ko','en'}) do
 for _,s in ipairs({{},{{id='z'},{id='a'}},{z={id='z'},a={id='a'}}}) do
  B.LANG=lang;B.SCEN=s;B.SCEN_EN=s;out.scenarios[#out.scenarios+1]={lang=lang,input=s,value=B.CR.scens()}
 end
end
B.SCEN,B.SCEN_EN=saved_scen,saved_en
local saved_have,saved_expr,saved_mod=B.PORTRAIT_HAVE,B.PORTRAIT_EXPR,B.mod_on
for _,have in ipairs({{}, {levia_portrait_default=true}, {levia_portrait_default=1,levia_portrait_smile='yes'}, {levia_portrait_default=false,levia_portrait_smile=true}}) do
 for _,enabled in ipairs({false,true}) do for _,hidden in ipairs({false,true}) do
  B.PORTRAIT_HAVE=have;B.PORTRAIT_EXPR={have={levia_portrait_smile=true,levia_portrait_default=false},ns='test'};B.mod_on=function()return enabled end;B.SEX_NOW=hidden
  for _,id in ipairs({'levia','persona','bad-id',''}) do for _,variant in ipairs({'default','smile','Smile','','../x'}) do
   local n=B.portrait_name(id,variant);out.portraits[#out.portraits+1]={id=id,variant=variant,have=have,expr=B.PORTRAIT_EXPR.have,enabled=enabled,hidden=hidden,name=n,has=B.portrait_has(n),value=B.portrait_pick(id,variant) or ''}
  end end
 end end
end
B.PORTRAIT_HAVE,B.PORTRAIT_EXPR,B.mod_on=saved_have,saved_expr,saved_mod;B.SEX_NOW=false
out.place_dictionary={ui={['토르바 {place}']=B.ui_pack('en')['토르바 {place}']},words={}}
out.panel_dictionary={}
for _,s in ipairs({'{name}에게 {item:을를} 장착했습니다. 끼고 있던 장비는 가방으로 돌아갑니다.','{item:을를} 팔아 금화 {gold:을를} 받았습니다.','일반 등급 장비 {n}개를 팔아 금화 {gold:을를} 받았습니다.','나'}) do out.panel_dictionary[s]=B.ui_pack('en')[s] or s end
for _,p in pairs(B.PLACE) do out.place_dictionary.words[p.name]=B.en_dict()[p.name] or p.name end
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,scene in ipairs({'town','smithy','guild','inn','shop','battle','create','scenario','sortie'}) do for _,place in ipairs({'','town','archive','gate','alley','rose','lamp','smithy','shop','bad'}) do
  local G={scene=scene,place=place};out.places[#out.places+1]={input=G,lang=lang,value=B.place_label(G) or ''}
 end end
 for _,vars in ipairs({{n=true,a=false},{n=1.5,a='나란'},{n=0,a='레비아'}, {a='{{user}}'}, {}}) do
  for _,s in ipairs({'{n} / {a}','{a:이가} 왔다','{a:으로} 간다','{a:invalid} {missing}','금화 {n}'}) do out.u[#out.u+1]={input=s,vars=vars,lang=lang,value=B.U(s,vars)} end
 end
end
for _,G in ipairs({{}, {settings={}}, {settings={chron=0}}, {settings={chron='0'}}, {settings={chron=false}}, {settings={chron=1}}, {settings='bad'}}) do
 for _,s in ipairs({'','한😀ab','é🙂','가나다라마바사'}) do for _,n in ipairs({0,1,2,3,99}) do
  out.memory[#out.memory+1]={input=G,text=s,n=n,on=B.mem_on(G,'chron'),cut=B.mem_cut(s,n),len=B.mem_len(s)}
 end end
end
local bag={};for i,gid in ipairs(B.gear().order) do bag[#bag+1]=B.gear_code(gid,200+i) end
for _,seed in ipairs({1,2,35,36,1296}) do bag[#bag+1]=B.gear_code(B.gear().order[1],seed) end
local old_bag=B.bag_load;B.bag_load=function()return bag end;B.VID='r23'
for _,cl in ipairs(B.CLASSES) do for _,lv in ipairs({1,5,9,10,20,40}) do for _,slot in ipairs({'weapon','armor','acc','bad'}) do
 local G=B.G_new();G.persona.cls=cl.name;G.persona.lv=lv;out.items[#out.items+1]={cls=cl.name,lv=lv,slot=slot,cid='persona',bag=bag,value=B.PX.items_for(G,slot,'persona')}
end end end
for _,cid in ipairs({'levia','naran','bad'}) do for _,lv in ipairs({1,40}) do
 local G=B.G_new();G.roster={'levia','naran'};G.lvl={[cid]=lv};out.items[#out.items+1]={cls='',lv=lv,slot='weapon',cid=cid,bag=bag,value=B.PX.items_for(G,'weapon',cid)}
end end
out.memory_bytes={}
for _,s in ipairs({'',string.char(0,97,0),string.char(255),string.char(240,159),string.char(192,128),string.char(237,160,128),string.char(244,144,128,128),'한😀é'}) do for _,n in ipairs({0,1,2,3,120}) do
 out.memory_bytes[#out.memory_bytes+1]={hex=B.cloud_hex(s),n=n,value=B.cloud_hex(B.mem_cut(s,n)),len=B.mem_len(s)}
end end
B.bag_load=old_bag;B.VID=nil
for _,key in ipairs({'stat','dmg','crit','mpreg','bad'}) do for _,cl in ipairs({'warrior','priest','bad',''}) do for _,v in ipairs({-1.25,0,1.25,2.35}) do
 out.fx[#out.fx+1]={key=key,cls=cl,input=v,definition=B.PX.fx_def(key) or {},name=B.PX.fx_name(key,cl),value=B.PX.fx_val(key,v)}
end end end
local key=up(B.cloud_link,'key');local ror=up(B.cloud_sha256,'ror');local copy=up(B.cloud_payload,'copy');local bounded=up(B.cloud_apply,'bounded')
out.cloud.key=B.cloud_hex(key());out.cloud.ror={};out.cloud.bounded={};out.cloud.crypto={};out.cloud.codes={};out.cloud.enabled={};out.cloud.copy={}
for _,x in ipairs({0,1,0x7fffffff,0x80000000,0xffffffff}) do for _,n in ipairs({1,7,16,31}) do out.cloud.ror[#out.cloud.ror+1]={x=x,n=n,value=ror(x,n)} end end
for _,v in ipairs({-99,-.1,0,1.9,99,'bad','7.9','-100','0x10'}) do out.cloud.bounded[#out.cloud.bounded+1]={input=v,value=bounded(v,0,10,2)} end
for _,v in ipairs({'bad',false,7}) do out.cloud.bounded[#out.cloud.bounded+1]={input=v,nil_default=true,value=bounded(v,0,10,nil)} end
for _,s in ipairs({'','a','ab','abc','abcd',string.rep('x',55),string.rep('x',56),string.rep('x',64),string.rep('x',65),'한글😀'}) do
 for _,k in ipairs({'','key',string.rep('k',64),string.rep('k',65)}) do out.cloud.crypto[#out.cloud.crypto+1]={input=s,key=k,sha=B.cloud_hex(B.cloud_sha256(s)),hmac=B.cloud_hex(B.cloud_hmac(k,s)),hex=B.cloud_hex(s),b64=B.cloud_b64(s)} end
end
for _,s in ipairs({'abcd-efgh-jkmn',' abcd eFGh jkmn\\n','OOOO-IIII-LLLL','0123456789AB','UUUU-0000-0000','abcd-efgh-jkmp','ABCD-EFGH-JKMO','','short','0123-4567-89A!','0123-4567-89A😀'}) do out.cloud.codes[#out.cloud.codes+1]={input=s,value=B.cloud_code(s) or ''} end
local C=B.CLOUD
for _,host in ipairs({'','fixture.invalid'}) do for _,keyx in ipairs({{}, {22}}) do C.HOST=host;C.KEY_X=keyx;out.cloud.enabled[#out.cloud.enabled+1]={host=host,key=keyx,value=B.cloud_enabled()} end end
C.HOST='fixture.invalid';C.KEY_X={22,27,30}
local original={x={a=1},list={1,2},flag=false};local clone=copy(original);clone.x.a=99;out.cloud.copy={input=original,value=clone}
local allbytes={};for i=0,255 do allbytes[#allbytes+1]=string.char(i) end;local binary=table.concat(allbytes)
out.cloud.binary={hex=B.cloud_hex(binary),sha=B.cloud_hex(B.cloud_sha256(binary)),hmac=B.cloud_hex(B.cloud_hmac(binary,binary)),b64=B.cloud_b64(binary)}
out.cloud.links={};local old_time=os.time;os.time=function()return 1234567890 end
for _,host in ipairs({'','fixture.invalid'}) do C.HOST=host;local G=B.G_new();G.persona.name='private host name';G.gold=987;local link=B.cloud_link(G,'r23') or '';out.cloud.links[#out.cloud.links+1]={host=host,value=link} end
os.time=old_time;C.HOST='fixture.invalid'
for _,row in ipairs(out.numbers) do if type(row.input)=='number' then row.input_bits=B.cloud_hex(string.pack('<d',row.input)) end end
local old_request,old_async,old_refresh,old_load,old_dn=request,async,B.refresh,B.G_load,B.dn_G
async=function(f)return f end;B.refresh=function()end;B.dn_G=function(G)return G.dungeon end
for _,cache in ipairs({{}, {at=0}, {at=100}, {at=400}, {at=1000}, {at='100'}}) do for _,now in ipairs({0,99,100,399,400,401,1000}) do
 local count=0;request=function()count=count+1;return {await=function()return json.encode({status=200,data=json.encode({best=3,pct=50})})end}end
 os.time=function()return now end;setChatVar('r23',B.RANK_KEY,json.encode(cache));local G={scene='sortie',dungeon={mode=1,best=3}};B.G_load=function()return G end;B.H.rk(G,'refresh','r23')
 out.rank[#out.rank+1]={cache=cache,now=now,requested=count>0}
end end
request,async,B.refresh,B.G_load,B.dn_G=old_request,old_async,old_refresh,old_load,old_dn;os.time=old_time
out.rank_headers={};B.LANG='ko';B.VID='r23'
for _,best in ipairs({0,1,10}) do for _,cache in ipairs({{}, {best=0,pct=50}, {best=1,pct=12.5}, {best=10,pct=100}, {best=10,pct='50'}, {best=true,pct=50}, {best='1',pct=50}}) do
 setChatVar('r23',B.RANK_KEY,json.encode(cache));local html=B.rank_head({dungeon={best=best}});out.rank_headers[#out.rank_headers+1]={best=best,cache=cache,show=html:find('상위',1,true)~=nil}
end end
B.VID=nil
out.message_actions={}
local original_load,original_save=B.bag_load,B.bag_save
for _,lang in ipairs({'ko','en'}) do
 B.LANG=lang;local G=B.G_new();G.persona.cls='전사';G.persona.lv=40;G.scene='town';local bag={};local selected={}
 for _,gid in ipairs(B.gear().order) do local it=B.gear().items[gid];if it.cls=='warrior' and not selected[it.rarity] then selected[it.rarity]=gid end end
 for _,r in ipairs({'common','common','epic','legend'}) do bag[#bag+1]=B.gear_code(selected[r],100+#bag)end
 B.bag_load=function()return cp(bag)end;B.bag_save=function(_,v)bag=cp(v)end
 for _,arg in ipairs({'sel_1e0','sell','sell','pg_1e0','f_rar_common','sel_1','eq_persona','f_rar_all','sel_bad','eq_bad','cmp_bad','back','sellc'}) do
  local before,bb=cp(G),cp(bag);B.H.bg(G,arg,'r23');out.message_actions[#out.message_actions+1]={lang=lang,before=before,bag=bb,arg=arg,value=cp(G),after_bag=cp(bag)}
 end
end
B.bag_load,B.bag_save=original_load,original_save
debug.sethook();out.core_calls=core_calls
return out
`);
// Avoid duplicating 1,030 codes in every row, while retaining the full inputs.
out.item_bag=out.items[0].bag;for(const x of out.items)delete x.bag;
for(const row of out.cloud.links)row.payload=row.value?Buffer.from(row.value.split('#')[1].split('.')[0],'base64url').toString('utf8'):'';
const render=await L(`
local result={cases={},calls={}}
debug.sethook(function()
 local info=debug.getinfo(2,'S')
 if info and info.source:sub(1,1)=='@' then local k=info.source:sub(2)..':'..info.linedefined;result.calls[k]=(result.calls[k] or 0)+1 end
end,'c')
local function game(lang)
 B.LANG=lang;local G=B.G_new();G.scene='town';G.roster=B.CAST_ORDER;G.party={'levia','naran','teiris'};G.persona.cls='전사';G.persona.race='인간';G.persona.nation='경계도시';G.persona.name='{{user}}';G.persona.lv=40;B.CR.P(G);B.H.cr(G,'auto','r23');G.persona.stats=B.CR.calc(G.persona)
 G.favs={'levia','naran','teiris'};for i,cid in ipairs(G.roster) do G.lvl[cid]=40;G.exp[cid]=i;G.aff[cid]=i*6-50 end
 return G
end
local function sample(tag,fn)
 local ok,value=pcall(fn);result.cases[#result.cases+1]={name=tag,ok=ok,value=tostring(value or '')}
end
for _,lang in ipairs({'ko','en'}) do
 for page=1,5 do local G=game(lang);G.scene='create';G.ui.page=page;sample(lang..'/create/'..page,function()return B.SCREENS.create(G,'r23')end) end
 for _,sc in ipairs({'','bad',B.CR.scens()[1].id}) do local G=game(lang);G.scene='scenario';G.ui.sel=sc;sample(lang..'/scenario/'..sc,function()return B.SCREENS.scenario(G,'r23')end) end
 for _,tab in ipairs({'','rec','el','el_fire','el_bad','cls','cls_warrior','cls_bad'}) do local G=game(lang);G.ui.tab=tab;G.ui.page=999;sample(lang..'/codex/'..tab,function()return B.PANELS.codex(G,'r23')end) end
 for _,cid in ipairs(B.CAST_ORDER) do local G=game(lang);G.ui.sel=cid;sample(lang..'/detail/'..cid,function()return B.PANELS.codex(G,'r23')end) end
 for _,panel in ipairs({'status','settings','save'}) do for _,tab in ipairs({'','me','bag','reset'}) do local G=game(lang);G.ui.tab=tab;sample(lang..'/'..panel..'/'..tab,function()return B.PANELS[panel](G,'r23')end) end end
 for _,scene in ipairs({'create','scenario','town','shop','guild','inn'}) do local G=game(lang);G.scene=scene;sample(lang..'/view/'..scene,function()return B.view(G,'r23')end) end
 local G=game(lang);G.scene='create';G.ui.sel='persona';sample(lang..'/persona',function()return B.PANELS.codex(G,'r23')end)
 for _,action in ipairs({'status','status','close','codex','settings','bad'}) do sample(lang..'/hd/'..action,function()B.H.hd(G,action,'r23');return json.encode(G.ui)end) end
 for _,action in ipairs({'t_battle','t_me','t_bag','bad'}) do sample(lang..'/st/'..action,function()B.H.st(G,action,'r23');return json.encode(G.ui)end) end
end
debug.sethook();return result
`);
for(const lang of ['ko','en']){
 const vars={a:null,n:0};const text='{a} / {n} / {missing}';
 const value=await L(`B.LANG=${JSON.stringify(lang)};return B.U(${JSON.stringify(text)},json.decode(${JSON.stringify(JSON.stringify(vars))}))`);
 out.u.push({input:text,vars,lang,value});
}
fs.writeFileSync(dir+'/source-renders.json',JSON.stringify(render)+'\n');
const surrounding=await L(`
local result={cases={},calls={}}
debug.sethook(function()local i=debug.getinfo(2,'S');if i and i.source:sub(1,1)=='@' then local k=i.source:sub(2)..':'..i.linedefined;result.calls[k]=(result.calls[k] or 0)+1 end end,'c')
local function cp(t)return json.decode(json.encode(t))end
local function sample(name,f)local ok,v=pcall(f);result.cases[#result.cases+1]={name=name,ok=ok,value=tostring(v or '')}end
local old_request,old_async,old_alert,old_image,old_reload,old_chat=request,async,alertInput,getPersonaImage,reloadDisplay,addChat
local old_refresh,old_nudge=B.refresh,B.nudge
async=function(f)return f end;B.refresh=function()end;B.nudge=function()end;reloadDisplay=function()end;addChat=function()end;getPersonaImage=function()return '' end
local G=B.G_new();G.persona.cls='전사';G.persona.stats=B.CR.calc(G.persona);G.roster={'levia','naran','teiris'};G.party={'levia'};G.lvl={levia=10,naran=10,teiris=2};G.aff={levia=0,naran=20};G.scene='town'
sample('G_migrate/nil',function()return json.encode(B.G_migrate(nil))end)
sample('G_migrate/partial',function()return json.encode(B.G_migrate({gold=777,persona={name='keep'},unknown='keep'}))end)
sample('G_save/load',function()G._chq={'Day 1: fixture'};B.G_save('r23-surround',G);return json.encode(B.G_load('r23-surround'))end)
sample('mem_jget/invalid',function()setChatVar('r23-surround','fixture','broken');return json.encode(B.mem_jget('r23-surround','fixture'))end)
sample('mem_jget/table',function()setChatVar('r23-surround','fixture','{"x":1}');return json.encode(B.mem_jget('r23-surround','fixture'))end)
sample('new_seed/fixed',function()local t,c,r=os.time,os.clock,math.random;os.time=function()return 100 end;os.clock=function()return .25 end;math.random=function()return 7 end;local seed=B.new_seed();os.time,os.clock,math.random=t,c,r;return seed end)
sample('C1_en',function()return B.C1_en('전사')end)
sample('route/status',function()B.route('r23-surround','hd_status');return true end)
for _,img in ipairs({'','{{inlayed::fixture}}','https://fixture.invalid/image.png'}) do getPersonaImage=function()return img end;sample('pimg_kick/'..img,function()B.pimg_kick('r23-surround',true);return getChatVar('r23-surround',B.PIMG_KEY)end)end
for _,a in ipairs({0,30}) do G.aff.levia=a;sample('cloud_recap/'..a,function()return B.cloud_recap(G)end)end
local payload=cp(G);payload.v=1;payload.bag=B.gear_code(B.gear().order[1],1)..';bad';payload.equip={persona={weapon=B.gear_code(B.gear().order[1],1),acc='bad'}}
sample('cloud_apply/valid',function()local value,bag=B.cloud_apply(B.G_new(),payload);return json.encode({value=value,bag=bag})end)
sample('cloud_apply/version',function()local p=cp(payload);p.v=99;local value,err=B.cloud_apply(B.G_new(),p);return json.encode({value=value,err=err})end)
for _,action in ipairs({'op_cpin','op_cload'}) do for _,mode in ipairs({'cancel','code','pin','404','success','request_error'}) do
 local input=0;alertInput=function()input=input+1;return {await=function()if mode=='cancel' then return '' end;if mode=='code' then return 'bad' end;if input==2 then return mode=='pin' and 'bad' or '234567' end;return 'ABCD-EFGH-JKMP' end}end
 request=function()if mode=='request_error' then error('fixture request failed')end;return {await=function()return json.encode({status=mode=='404' and 404 or 200,data=json.encode({rev=3,save=payload})})end}end
 B.G_save('r23-surround',cp(G));sample(action..'/'..mode,function()B.cloud_button('r23-surround',action);return json.encode(B.G_load('r23-surround'))end)
end end
sample('rank_refresh',function()local r=cp(G);r.scene='town';B.G_save('r23-surround',r);return B.rank_refresh('r23-surround')end)
sample('rank/offline-clears-pct',function()local r=cp(G);r.scene='sortie';r.dungeon.mode=1;r.dungeon.best=3;setChatVar('r23-surround',B.RANK_KEY,json.encode({best=3,pct=50,at=0}));request=function()error('offline fixture')end;B.H.rk(r,'refresh','r23-surround');return json.encode(B.mem_jget('r23-surround',B.RANK_KEY))end)
sample('status_battle',function()return B.PX.st_battle(G,'r23-surround')end)
sample('panel_buttons',function()return B.PX.btn('fixture','label','sm','sub')end)
sample('item_name',function()return B.PX.item_name('bad')end)
sample('scenario/go',function()local s=cp(G);s.scenario='';s.scene='scenario';B.H.sc(s,'pick_'..B.CR.scens()[1].id,'r23-surround');B.H.sc(s,'go','r23-surround');return json.encode(s)end)
sample('settings/actions',function()local s=cp(G);for _,a in ipairs({'diff_1','lang_en','chron_0','chron_1','diff_4','reset','reset_no'}) do B.H.op(s,a,'r23-surround')end;return json.encode(s.settings)end)
local bag_load,bag_save=B.bag_load,B.bag_save;local code=B.gear_code(B.gear().order[1],3);local bag={code};B.bag_load=function()return cp(bag)end;B.bag_save=function(_,v)bag=cp(v)end
sample('gear/card',function()local r=B.gear_roll(code);return B.PX.gear_card(r)..B.PX.gear_tile(r.item,'bg_sel_1','보유')end)
sample('gear/detail',function()return B.PX.bg_detail(G,'r23-surround',{sel=code,cmp='persona',conf=''})end)
sample('bag/actions',function()for _,a in ipairs({'f_cls_all','sel_1','back','sellc'}) do B.H.bg(G,a,'r23-surround')end;return json.encode(G.ui)end)
B.bag_load,B.bag_save=bag_load,bag_save
request,async,alertInput,getPersonaImage,reloadDisplay,addChat=old_request,old_async,old_alert,old_image,old_reload,old_chat;B.refresh,B.nudge=old_refresh,old_nudge
debug.sethook();return result
`);
fs.writeFileSync(dir+'/source-surrounding.json',JSON.stringify(surrounding)+'\n');
fs.writeFileSync(dir+'/source-calls.json',JSON.stringify({core:out.core_calls,render:render.calls,surrounding:surrounding.calls})+'\n');delete out.core_calls;
fs.writeFileSync(dir+'/ui-oracle.json',JSON.stringify(out)+'\n');
fs.writeFileSync(dir+'/ui-provenance.json',JSON.stringify({source_files:names.map((name,i)=>({file:'bot/src/'+name,sha256:crypto.createHash('sha256').update(raws[i]).digest('hex')})),source_read_only:true,network:false,config:'test fixture only; no production host/key',counts:Object.fromEntries(Object.entries(out).map(([k,v])=>[k,Array.isArray(v)?v.length:typeof v]))},null,2)+'\n');
console.log(Object.fromEntries(Object.entries(out).map(([k,v])=>[k,Array.isArray(v)?v.length:typeof v])));sim.close?.();
