// Observe the protected validator without stripping fields from a user's save.
import fs from 'node:fs';
import {validate} from '../server/abyss-save/src/validate.js';
const root=new URL('../',import.meta.url);
const save=JSON.parse(fs.readFileSync(new URL('verification/parity-r23/shop-save.json',root),'utf8'));
const samples={shop_bonus:save};
const noBonus=structuredClone(save);delete noBonus.items.charm_potion;samples.bonus_removed_diagnostic_only=noBonus;
const noCounter=structuredClone(save);delete noCounter.commerce_r21.pietro_buys;samples.counter_removed_diagnostic_only=noCounter;
const oldShape=structuredClone(noCounter);delete oldShape.items.charm_potion;samples.both_removed_diagnostic_only=oldShape;
const rows=Object.entries(samples).map(([name,s])=>{try{validate(s);return {name,accepted:true}}catch(e){return {name,accepted:false,path:e.path,message:e.message}}});
fs.writeFileSync(new URL('verification/parity-r23/cloud-boundary.json',root),JSON.stringify({server_modified:false,user_save_modified:false,rows},null,2));
console.log(rows);
