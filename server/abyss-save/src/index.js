import {validate,summary,Invalid,rankReasons,percentile} from './validate.js';
const MAX=65536, ALPHABET='0123456789ABCDEFGHJKMNPQRSTVWXYZ';
const json=(value,status=200,headers={})=>new Response(JSON.stringify(value),{status,headers:{'content-type':'application/json; charset=utf-8','cache-control':'no-store','x-content-type-options':'nosniff',...headers}});
class HttpError extends Error {constructor(status,message,extra={}){super(message);this.status=status;this.extra=extra;}}
const reject=(status,message,extra)=>{throw new HttpError(status,message,extra);};
function allowed(origin){try{const u=new URL(origin);return origin==='https://aredsea.github.io'||(['localhost','127.0.0.1','[::1]'].includes(u.hostname)&&u.protocol==='http:');}catch{return false;}}
function codeOf(value){if(typeof value!=='string')reject(400,'invalid_code');const c=value.toUpperCase().replace(/[\s-]/g,'').replace(/O/g,'0').replace(/[IL]/g,'1');if(!/^[0-9A-HJKMNP-TV-Z]{12}$/.test(c))reject(400,'invalid_code');return c.match(/.{4}/g).join('-');}
function random(n){return Array.from(crypto.getRandomValues(new Uint8Array(n)),x=>ALPHABET[x&31]).join('');}
const hex=x=>Array.from(new Uint8Array(x),n=>n.toString(16).padStart(2,'0')).join('');
async function hash(pin,salt){const key=await crypto.subtle.importKey('raw',new TextEncoder().encode(pin),'PBKDF2',false,['deriveBits']);return hex(await crypto.subtle.deriveBits({name:'PBKDF2',hash:'SHA-256',salt:new TextEncoder().encode(salt),iterations:100000},key,256));}
async function authenticate(db,code,pin){
 if(typeof pin!=='string'||!/^[0-9A-HJKMNP-TV-Z]{10}$/.test(pin))reject(403,'invalid_pin');
 const row=await db.prepare('SELECT * FROM accounts WHERE code=?').bind(code).first();
 const digest=await hash(pin,row?.salt??'absent-account-padding');
 let different=row?0:1;const expected=row?.pin_hash??'0'.repeat(64);for(let i=0;i<64;i++)different|=digest.charCodeAt(i)^expected.charCodeAt(i);
 if(different)reject(403,'invalid_pin');return row;
}
async function rate(db,bucket,limit,now){
 const minute=Math.floor(now/60);
 const row=await db.prepare('INSERT INTO counters(bucket,minute,n) VALUES(?,?,1) ON CONFLICT(bucket,minute) DO UPDATE SET n=n+1 RETURNING n').bind(bucket,minute).first();
 if(row.n>limit)reject(429,'rate_limited',{retry_after:60-now%60});
}
async function body(request){
 if(Number(request.headers.get('content-length')??0)>MAX)reject(413,'payload_too_large');
 if(!request.headers.get('content-type')?.toLowerCase().startsWith('application/json'))reject(415,'json_required');
 const reader=request.body?.getReader();if(!reader)reject(400,'invalid_json');let n=0;const chunks=[];
 for(;;){const {done,value}=await reader.read();if(done)break;n+=value.length;if(n>MAX){await reader.cancel();reject(413,'payload_too_large');}chunks.push(value);}
 const bytes=new Uint8Array(n);let pos=0;for(const chunk of chunks){bytes.set(chunk,pos);pos+=chunk.length;}
 try{const value=JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(bytes));if(!value||Array.isArray(value)||typeof value!=='object')reject(400,'invalid_json');return value;}catch(e){if(e instanceof HttpError)throw e;reject(400,'invalid_json');}
}
function fields(v,allowed,required=[]){for(const k of Object.keys(v))if(!allowed.includes(k))reject(400,'unknown_field');for(const k of required)if(!Object.hasOwn(v,k))reject(400,'missing_field');}
async function turnstile(request,env,value){
 if(env.TURNSTILE_ENABLED!=='true')return;
 if(!env.TURNSTILE_SECRET)reject(503,'turnstile_unconfigured');
 const form=new URLSearchParams({secret:env.TURNSTILE_SECRET,response:String(value??''),remoteip:request.headers.get('CF-Connecting-IP')??''});
 const r=await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify',{method:'POST',body:form});
 const data=await r.json();if(!data.success||data.action!=='account'||!['aredsea.github.io','localhost'].includes(data.hostname))reject(403,'turnstile_failed');
}
async function current(db,code,rev=null){
 const row=rev===null?await db.prepare('SELECT s.* FROM saves s JOIN accounts a ON a.code=s.code AND a.rev=s.rev WHERE s.code=?').bind(code).first():await db.prepare('SELECT * FROM saves WHERE code=? AND rev=?').bind(code,rev).first();
 if(!row)reject(404,'save_not_found');return {code,rev:row.rev,save:JSON.parse(row.payload),summary:JSON.parse(row.summary),at:row.created};
}
async function rankSnapshot(db,now){
 const cached=await db.prepare('SELECT payload FROM rank_cache WHERE id=1 AND expires>?').bind(now).first();if(cached)return JSON.parse(cached.payload);
 const histogram=(await db.prepare('SELECT best,COUNT(*) AS n FROM ranks GROUP BY best ORDER BY best DESC').all()).results;
 const out={at:now,expires:now+300,n:histogram.reduce((n,x)=>n+x.n,0),top:histogram[0]?.best??0,histogram};
 await db.prepare('INSERT INTO rank_cache(id,payload,expires) VALUES(1,?,?) ON CONFLICT(id) DO UPDATE SET payload=excluded.payload,expires=excluded.expires').bind(JSON.stringify(out),now+300).run();return out;
}
async function route(request,env){
 const db=env.DB, u=new URL(request.url), now=Math.floor(Date.now()/1000), method=request.method,path=u.pathname;
 const ip=request.headers.get('CF-Connecting-IP')??'local';
 // Store only a one-minute hash of IP. Scheduled cleanup bounds retention.
 const ipHash=hex(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(Math.floor(now/60)+':'+ip)));
 await rate(db,'ip:'+ipHash,60,now);
 if(path==='/v1/account'&&method==='POST'){
  await rate(db,'new:'+ipHash,5,now);const b=await body(request);fields(b,['save','turnstile'],['save']);await turnstile(request,env,b.turnstile);
  const save=validate(b.save), payload=JSON.stringify(save), sum=summary(save);if(new TextEncoder().encode(payload).length>MAX)reject(413,'payload_too_large');
  const code=codeOf(random(12)),pin=random(10),salt=random(26),digest=await hash(pin,salt);
  await db.batch([
   db.prepare('INSERT INTO accounts(code,salt,pin_hash,rev,created,updated) VALUES(?,?,?,1,?,?)').bind(code,salt,digest,now,now),
   db.prepare('INSERT INTO saves(code,rev,payload,summary,created) VALUES(?,1,?,?,?)').bind(code,payload,JSON.stringify(sum),now)
  ]);
  return json({code,pin,rev:1,summary:sum},201);
 }
 if(path==='/v1/account/connect'&&method==='POST'){
  const b=await body(request);fields(b,['code','pin'],['code','pin']);const code=codeOf(b.code);
  await rate(db,'account:'+code,20,now);await authenticate(db,code,b.pin);const saved=await current(db,code);
  return json({code,rev:saved.rev,summary:saved.summary,at:saved.at});
 }
 if(path==='/v1/save'&&method==='PUT'){
  const b=await body(request);fields(b,['code','pin','rev','save'],['code','pin','rev','save']);const code=codeOf(b.code);
  await rate(db,'account:'+code,20,now);await authenticate(db,code,b.pin);
  if(!Number.isSafeInteger(b.rev)||b.rev<1)reject(400,'invalid_rev');
  const save=validate(b.save),payload=JSON.stringify(save),sum=summary(save);if(new TextEncoder().encode(payload).length>MAX)reject(413,'payload_too_large');
  // An atomic CAS plus history insert. changes() refers to the immediately preceding UPDATE.
  const result=await db.batch([
   db.prepare('UPDATE accounts SET rev=rev+1,updated=? WHERE code=? AND rev=?').bind(now,code,b.rev),
   db.prepare('INSERT INTO saves(code,rev,payload,summary,created) SELECT code,rev,?,?,? FROM accounts WHERE code=? AND rev=? AND changes()=1').bind(payload,JSON.stringify(sum),now,code,b.rev+1),
   // An uploaded new save invalidates its previous rank until explicitly re-submitted.
   db.prepare('DELETE FROM ranks WHERE code=? AND EXISTS(SELECT 1 FROM accounts WHERE code=? AND rev=?) AND changes()=1').bind(code,code,b.rev+1)
  ]);
  if(!result[0].meta.changes){const latest=await current(db,code);reject(409,'conflict',{rev:latest.rev,summary:latest.summary,at:latest.at});}
  return json({code,rev:b.rev+1,summary:sum});
 }
 if(path==='/v1/account'&&method==='DELETE'){
  const b=await body(request);fields(b,['code','pin'],['code','pin']);const code=codeOf(b.code);await rate(db,'account:'+code,20,now);await authenticate(db,code,b.pin);
  await db.batch([db.prepare('DELETE FROM accounts WHERE code=?').bind(code),db.prepare('DELETE FROM rank_cache'),db.prepare('DELETE FROM counters WHERE bucket=?').bind('account:'+code)]);
  return json({deleted:true});
 }
 if(path==='/v1/rank'&&method==='POST'){
  const b=await body(request);fields(b,['code','pin'],['code','pin']);const code=codeOf(b.code);await rate(db,'account:'+code,20,now);await authenticate(db,code,b.pin);
  const saved=await current(db,code),save=validate(saved.save),previous=await db.prepare('SELECT summary,created FROM saves WHERE code=? AND rev<? ORDER BY rev DESC LIMIT 1').bind(code,saved.rev).first();
  const reasons=rankReasons(save,previous?JSON.parse(previous.summary):null,previous?now-previous.created:0);
  if(reasons.length)reject(422,'rank_ineligible',{reasons});
  if(save.dungeon_r21.best>0){
   // The SELECT prevents a concurrent save/delete from ranking stale data.
   await db.prepare('INSERT INTO ranks(code,best,updated) SELECT code,?,? FROM accounts WHERE code=? AND rev=? ON CONFLICT(code) DO UPDATE SET best=excluded.best,updated=excluded.updated').bind(save.dungeon_r21.best,now,code,saved.rev).run();
  }
  return json({submitted:true,best:save.dungeon_r21.best,cache_seconds:300});
 }
 if(path==='/v1/rank'&&method==='GET'){
  const snapshot=await rankSnapshot(db,now);let best=null;
  if(u.searchParams.has('code')){const code=codeOf(u.searchParams.get('code'));await rate(db,'read:'+code,60,now);const row=await db.prepare('SELECT best FROM ranks WHERE code=?').bind(code).first();best=row?.best??0;}
  const ahead=best===null?0:snapshot.histogram.filter(x=>x.best>best).reduce((n,x)=>n+x.n,0);
  return json({metric:'deepest_floor',best,pct:best>0?percentile(ahead,snapshot.n):null,n:snapshot.n,top:snapshot.top,at:snapshot.at,expires:snapshot.expires,cache_seconds:300});
 }
 const match=path.match(/^\/v1\/save\/([^/]+)(\/revs)?$/);
 if(match&&method==='GET'){
  const code=codeOf(decodeURIComponent(match[1]));await rate(db,'read:'+code,60,now);
  if(match[2]){const exists=await db.prepare('SELECT code FROM accounts WHERE code=?').bind(code).first();if(!exists)reject(404,'save_not_found');const rows=(await db.prepare('SELECT rev,summary,created AS at FROM saves WHERE code=? ORDER BY rev DESC LIMIT 10').bind(code).all()).results;return json({code,revs:rows.map(r=>({...r,summary:JSON.parse(r.summary)}))});}
  let rev=null;if(u.searchParams.has('rev')){rev=Number(u.searchParams.get('rev'));if(!Number.isSafeInteger(rev)||rev<1)reject(400,'invalid_rev');}
  return json(await current(db,code,rev));
 }
 reject(404,'not_found');
}
export default {
 async fetch(request,env){
  const origin=request.headers.get('Origin');let response;
  try{
   if(origin&&!allowed(origin))reject(403,'origin_denied');
   if(request.method==='OPTIONS')response=new Response(null,{status:204,headers:{'Access-Control-Allow-Methods':'GET, POST, PUT, DELETE, OPTIONS','Access-Control-Allow-Headers':'Content-Type','Access-Control-Max-Age':'600'}});
   else response=await route(request,env);
  }catch(e){
   if(e instanceof Invalid)response=json({error:e.message,field:e.path},422);
   else if(e instanceof HttpError)response=json({error:e.message,...e.extra},e.status,e.status===429?{'Retry-After':String(e.extra.retry_after)}:{});
   else response=json({error:'service_unavailable'},503);
  }
  response.headers.set('Vary','Origin');response.headers.set('Cross-Origin-Resource-Policy','cross-origin');
  if(origin&&allowed(origin))response.headers.set('Access-Control-Allow-Origin',origin);
  return response;
 },
 async scheduled(event,env){await env.DB.prepare('DELETE FROM counters WHERE minute<?').bind(Math.floor(Date.now()/60000)-2).run();}
};
