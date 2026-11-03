import {L,dir} from './ui_r23_phase4_oracle.mjs';import fs from 'node:fs';
const out=await L(`
local out={};local oldload,oldsave=B.bag_load,B.bag_save;local bag={};B.LANG='ko'
B.bag_load=function()return bag end;B.bag_save=function(_,b)bag=b end
local gid
for _,id in ipairs(B.gear().order)do local it=B.gear().items[id];if it.cls=='warrior' and it.slot=='weapon' and it.rarity=='common'then gid=id;break end end
local code=B.gear_code(gid,1235);local old=B.gear_code(gid,4242)
for _,kind in ipairs({'empty_un','full_un','space_un','duplicate_equip','full_equip','stale_equip','duplicate_sell','stale_sell'})do
 local G=B.G_new();G.scene='town';G.persona.cls='전사';G.persona.lv=40;G.persona.name='A & B';G.roster={'haldric'};G.lvl.haldric=40;G.ui.sel='haldric';G.equip.haldric={weapon=old};G.ui.bg={pg=1,cls='',slot='',rar='',sel=code,cmp='',conf=''};bag={code,code}
 if kind=='full_un' or kind=='space_un' or kind=='full_equip'then bag={};for i=1,(kind=='space_un' and 1999 or 2000)do bag[i]=code end end
 if kind=='empty_un'then G.equip.haldric={}end
 if kind=='stale_sell' or kind=='stale_equip'then bag={}end
 local before={G=json.decode(json.encode(G)),bag=json.decode(json.encode(bag))}
 if kind:find('_un')then B.H.cx(G,'un_weapon','ui-phase4')elseif kind:find('_equip')then B.H.bg(G,'eq_haldric','ui-phase4')else B.H.bg(G,'sell','ui-phase4')end
 out[#out+1]={kind=kind,before=before,after={gold=G.gold,bag=bag,equipped=G.equip.haldric.weapon or '',msg=G.ui.msg,sel=G.ui.bg.sel,conf=G.ui.bg.conf}}
end
B.bag_load,B.bag_save=oldload,oldsave;return out
`);
fs.writeFileSync(dir+'/ui-edges-oracle.json',JSON.stringify(out,null,2)+'\n');console.log('edges',out.length);
