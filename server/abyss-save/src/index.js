import {validate,summary,Invalid,rankReasons,percentile} from './validate.js';
import {env as startupEnv} from 'cloudflare:workers';
const MAX=65536, ALPHABET='0123456789ABCDEFGHJKMNPQRSTVWXYZ';
const json=(value,status=200,headers={})=>new Response(JSON.stringify(value),{status,headers:{'content-type':'application/json; charset=utf-8','cache-control':'no-store','x-content-type-options':'nosniff',...headers}});
class HttpError extends Error {constructor(status,message,extra={}){super(message);this.status=status;this.extra=extra;}}
const reject=(status,message,extra)=>{throw new HttpError(status,message,extra);};
function allowed(origin,env){try{
 const u=new URL(origin);
 if(['localhost','127.0.0.1','[::1]'].includes(u.hostname))return env.ALLOW_LOCALHOST==='true'&&u.protocol==='http:';
 return u.protocol==='https:'&&origin===u.origin&&(env.CORS_ORIGINS??'https://aredsea.github.io').split(',').map(x=>x.trim()).includes(origin);
}catch{return false;}}
function codeOf(value){if(typeof value!=='string')reject(400,'invalid_code');const c=value.toUpperCase().replace(/[\s-]/g,'').replace(/O/g,'0').replace(/[IL]/g,'1');if(!/^[0-9A-HJKMNP-TV-Z]{12}$/.test(c))reject(400,'invalid_code');return c.match(/.{4}/g).join('-');}
function random(n){return Array.from(crypto.getRandomValues(new Uint8Array(n)),x=>ALPHABET[x&31]).join('');}
const hex=x=>Array.from(new Uint8Array(x),n=>n.toString(16).padStart(2,'0')).join('');
async function hash(pin,salt,iterations){const key=await crypto.subtle.importKey('raw',new TextEncoder().encode(pin),'PBKDF2',false,['deriveBits']);return hex(await crypto.subtle.deriveBits({name:'PBKDF2',hash:'SHA-256',salt:new TextEncoder().encode(salt),iterations},key,256));}
async function authenticate(db,code,pin,iterations){
 if(typeof pin!=='string'||!/^[0-9A-HJKMNP-TV-Z]{10}$/.test(pin))reject(403,'invalid_pin');
 const row=await db.prepare('SELECT *,0 AS is_archived FROM accounts WHERE code=?').bind(code).first()??await db.prepare('SELECT *,1 AS is_archived FROM inactive_archives WHERE code=? AND expires>?').bind(code,Math.floor(Date.now()/1000)).first();
 const digest=await hash(pin,row?.salt??'absent-account-padding',row?.pin_iterations??iterations);
 let different=row?0:1;const expected=row?.pin_hash??'0'.repeat(64);for(let i=0;i<64;i++)different|=digest.charCodeAt(i)^expected.charCodeAt(i);
 if(different)reject(403,'invalid_pin');return row;
}
function setting(env,key,fallback,min=1,max=Number.MAX_SAFE_INTEGER){
 const n=env[key]===undefined?fallback:Number(env[key]);
 if(!Number.isSafeInteger(n)||n<min||n>max)reject(503,'invalid_configuration');return n;
}
function configured(env){if(typeof env.IP_HASH_PEPPER!=='string'||env.IP_HASH_PEPPER.length<16)reject(503,'ip_pepper_unconfigured');}
// Bindings are available globally; a missing secret prevents the isolate starting.
configured(startupEnv);
// Cloudflare supplies the IP header. Canonicalize IPv6 (including mapped IPv4)
// before HMAC so address spelling and privacy addresses do not split a /64.
function ipNetwork(raw){
 let ip=raw.toLowerCase();
 if(/^\d+\.\d+\.\d+\.\d+$/.test(ip))return ip.split('.').map(Number).join('.');
 if(!ip.includes(':'))return 'local';
 if(ip.includes('.')){const i=ip.lastIndexOf(':');const v=ip.slice(i+1).split('.').map(Number);ip=ip.slice(0,i+1)+((v[0]<<8)|v[1]).toString(16)+':'+((v[2]<<8)|v[3]).toString(16);}
 const halves=ip.split('::');const left=halves[0]?halves[0].split(':'):[],right=halves[1]?halves[1].split(':'):[];
 const words=(halves.length===2?[...left,...Array(Math.max(0,8-left.length-right.length)).fill('0'),...right]:left).map(x=>parseInt(x,16));
 if(words.length!==8||words.some(x=>!Number.isInteger(x)||x<0||x>65535))reject(400,'invalid_ip');
 if(words.slice(0,5).every(x=>x===0)&&words[5]===65535)return [words[6]>>8,words[6]&255,words[7]>>8,words[7]&255].join('.');
 return words.slice(0,4).map(x=>x.toString(16).padStart(4,'0')).join(':')+'::/64';
}
async function privateIP(ip,env,now,period=60){
 const key=await crypto.subtle.importKey('raw',new TextEncoder().encode(env.IP_HASH_PEPPER),{name:'HMAC',hash:'SHA-256'},false,['sign']);
 return hex(await crypto.subtle.sign('HMAC',key,new TextEncoder().encode(Math.floor(now/period)+':'+ipNetwork(ip))));
}
// Check every bucket before inserting any row. The admission is one D1 statement,
// so a concurrent caller cannot overdraw, and rejected requests change no counters.
async function rates(db,buckets,now,checkOnly=false){
 const values=buckets.flatMap(([key,cap,n=1,period=60])=>[key,Math.floor(now/period)*(period/60),n,cap]);
 const proposed='WITH proposed(bucket,minute,n,cap) AS (VALUES '+buckets.map(()=>'(?,?,?,?)').join(',')+') ';
 const over='SELECT 1 FROM proposed p LEFT JOIN counters c ON c.bucket=p.bucket AND c.minute=p.minute WHERE COALESCE(c.n,0)+p.n>p.cap';
 if(checkOnly){if(await db.prepare(proposed+over+' LIMIT 1').bind(...values).first())reject(429,'rate_limited',{retry_after:60-now%60});return;}
 const result=await db.prepare(proposed+'INSERT INTO counters(bucket,minute,n) SELECT bucket,minute,n FROM proposed WHERE NOT EXISTS('+over+') ON CONFLICT(bucket,minute) DO UPDATE SET n=counters.n+excluded.n RETURNING bucket').bind(...values).all();
 if(result.results.length!==buckets.length)reject(429,'rate_limited',{retry_after:60-now%60});
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
function turnstileHosts(env){
 const hosts=(env.TURNSTILE_HOSTNAMES??'aredsea.github.io').split(',').map(x=>x.trim()).filter(Boolean);
 return hosts.filter(h=>env.ALLOW_LOCALHOST==='true'||!['localhost','127.0.0.1','::1','[::1]'].includes(h));
}
async function turnstile(request,env,value){
 if(env.TURNSTILE_ENABLED!=='true')return;
 if(!env.TURNSTILE_SECRET)reject(503,'turnstile_unconfigured');
 if(typeof value!=='string'||!value||value.length>2048)reject(403,'turnstile_failed');
 const form=new URLSearchParams({secret:env.TURNSTILE_SECRET,response:String(value??''),remoteip:request.headers.get('CF-Connecting-IP')??''});
 const r=await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify',{method:'POST',body:form});
 const data=await r.json();if(!data.success||data.action!=='account'||!turnstileHosts(env).includes(data.hostname))reject(403,'turnstile_failed');
}
async function current(db,code,rev=null){
 const row=rev===null?await db.prepare('SELECT s.* FROM saves s JOIN accounts a ON a.code=s.code AND a.rev=s.rev WHERE s.code=?').bind(code).first():await db.prepare('SELECT * FROM saves WHERE code=? AND rev=?').bind(code,rev).first();
 if(!row)reject(404,'save_not_found');return {code,rev:row.rev,save:JSON.parse(row.payload),summary:JSON.parse(row.summary),at:row.created};
}
async function rankSnapshot(db,now){
 for(let attempt=0;attempt<50;attempt++){
  const cached=await db.prepare('SELECT payload FROM rank_cache WHERE id=1 AND expires>?').bind(now).first();if(cached)return JSON.parse(cached.payload);
  const lease=await db.prepare("INSERT INTO rank_cache(id,payload,expires,lock_until,generation) VALUES(1,'{}',0,?,0) ON CONFLICT(id) DO UPDATE SET lock_until=excluded.lock_until WHERE rank_cache.expires<=? AND rank_cache.lock_until<=? RETURNING id").bind(now+10,now,now).first();
  if(lease){
   const histogram=(await db.prepare('SELECT best,COUNT(*) AS n FROM ranks GROUP BY best ORDER BY best DESC').all()).results;
   const out={at:now,expires:now+300,n:histogram.reduce((n,x)=>n+x.n,0),top:histogram[0]?.best??0,histogram};
   await db.prepare('UPDATE rank_cache SET payload=?,expires=?,lock_until=0,generation=generation+1 WHERE id=1 AND lock_until=?').bind(JSON.stringify(out),now+300,now+10).run();return out;
  }
  await new Promise(resolve=>setTimeout(resolve,10));
 }
 reject(503,'rank_busy');
}
async function route(request,env){
 const db=env.DB, u=new URL(request.url), now=Math.floor(Date.now()/1000), method=request.method,path=u.pathname;
 const rawIP=request.headers.get('CF-Connecting-IP')??'local';
 const ipHash=await privateIP(rawIP,env,now),dailyIP=await privateIP(rawIP,env,now,86400);
 const network=ipNetwork(rawIP),v6=network.endsWith('/64');
 const subnet=v6?network.split(':').slice(0,3).join(':')+':0::':null;
 const subnetHash=v6?await privateIP(subnet,env,now):null;
 const dailySubnet=v6?await privateIP(subnet,env,now,86400):null;
 // No global request bucket: a few networks must not spend everyone else's budget.
 const base=[['ip:'+ipHash,60],...(v6?[['net48:'+subnetHash,setting(env,'IPV6_48_REQUESTS_PER_MINUTE',240)]]:[])];
 let admitted=false;
 const admit=async(extra=[])=>{await rates(db,[...base,...extra],now);admitted=true;};
 const auth=async(code,pin,extra=[],allowArchive=false)=>{
  const failure=['authfail:'+code+':'+ipHash,20];
  // Reserve CPU admission atomically before PBKDF2, including successful attempts.
  await admit([failure]);
  const row=await authenticate(db,code,pin,setting(env,'PIN_PBKDF2_ITERATIONS',5000,1000,100000));
  // Failed PINs never consume the owner's account bucket.
  await rates(db,[['account:'+code,setting(env,'ACCOUNT_REQUESTS_PER_MINUTE',20)],...extra],now);
  if(row.is_archived&&!allowArchive)reject(410,'archived');
  return row;
 };
 await rates(db,base,now,true);
 try{
 if(path==='/v1/account'&&method==='POST'){
  const b=await body(request);fields(b,['save','turnstile'],['save']);
  const save=validate(b.save), payload=JSON.stringify(save), sum=summary(save);if(new TextEncoder().encode(payload).length>MAX)reject(413,'payload_too_large');
  if(env.TURNSTILE_ENABLED==='true'&&(typeof b.turnstile!=='string'||!b.turnstile||b.turnstile.length>2048))reject(403,'turnstile_failed');
  const bytes=new TextEncoder().encode(payload).length;
  await admit([['new:'+ipHash,5],['daily:new:'+dailyIP,setting(env,'NEW_PER_IP_PER_DAY',20),1,86400],
   ...(v6?[['new48:'+subnetHash,20],['daily:new48:'+dailySubnet,200,1,86400]]:[]),
   ['global:new',setting(env,'GLOBAL_NEW_PER_MINUTE',6000)],
   ['newbytes:'+ipHash,setting(env,'IP_NEW_BYTES_PER_MINUTE',262144),bytes],
   ['global:newbytes',setting(env,'GLOBAL_NEW_BYTES_PER_MINUTE',67108864),bytes]]);
  // Syntax, save validation and all admission decisions precede one-use verification.
  await turnstile(request,env,b.turnstile);
  const iterations=setting(env,'PIN_PBKDF2_ITERATIONS',5000,1000,100000);
  const code=codeOf(random(12)),pin=random(10),salt=random(26),digest=await hash(pin,salt,iterations);
  await db.batch([
   db.prepare('INSERT INTO accounts(code,salt,pin_hash,rev,created,updated,pin_iterations,rank_at) VALUES(?,?,?,1,?,?,?,?)').bind(code,salt,digest,now,now,iterations,now),
   db.prepare('INSERT INTO saves(code,rev,payload,summary,created) VALUES(?,1,?,?,?)').bind(code,payload,JSON.stringify(sum),now)
  ]);
  return json({code,pin,rev:1,summary:sum},201);
 }
 if(path==='/v1/account/connect'&&method==='POST'){
  const b=await body(request);fields(b,['code','pin'],['code','pin']);const code=codeOf(b.code);
  const account=await auth(code,b.pin);const saved=await current(db,code);
  return json({code,rev:saved.rev,summary:saved.summary,at:saved.at});
 }
 if(path==='/v1/save/read'&&method==='POST'){
  const b=await body(request);fields(b,['code','pin','rev','history'],['code','pin']);const code=codeOf(b.code);
  if('rev'in b&&(!Number.isSafeInteger(b.rev)||b.rev<1))reject(400,'invalid_rev');
  if('history'in b&&typeof b.history!=='boolean')reject(400,'invalid_history');
  await auth(code,b.pin);
  if(b.history){const rows=(await db.prepare('SELECT rev,summary,created AS at FROM saves WHERE code=? ORDER BY rev DESC LIMIT 10').bind(code).all()).results;return json({code,revs:rows.map(r=>({...r,summary:JSON.parse(r.summary)}))});}
  return json(await current(db,code,b.rev??null));
 }
 if(path==='/v1/save'&&method==='PUT'){
  const b=await body(request);fields(b,['code','pin','rev','save'],['code','pin','rev','save']);const code=codeOf(b.code);
  if(!Number.isSafeInteger(b.rev)||b.rev<1)reject(400,'invalid_rev');
  const save=validate(b.save),payload=JSON.stringify(save),sum=summary(save);if(new TextEncoder().encode(payload).length>MAX)reject(413,'payload_too_large');
  const bytes=new TextEncoder().encode(payload).length;
  await auth(code,b.pin,[['bytes:'+ipHash,setting(env,'IP_WRITE_BYTES_PER_MINUTE',262144),bytes],['accountbytes:'+code,setting(env,'ACCOUNT_WRITE_BYTES_PER_MINUTE',262144),bytes],['global:bytes',setting(env,'GLOBAL_WRITE_BYTES_PER_MINUTE',134217728),bytes]]);
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
  const b=await body(request);fields(b,['code','pin'],['code','pin']);const code=codeOf(b.code);const account=await auth(code,b.pin,[],true);
  if(account.is_archived){await db.prepare('DELETE FROM inactive_archives WHERE code=?').bind(code).run();reject(410,'archived',{deleted:true});}
  await db.batch([db.prepare('DELETE FROM accounts WHERE code=?').bind(code),db.prepare('DELETE FROM counters WHERE bucket=?').bind('account:'+code)]);
  return json({deleted:true});
 }
 if(path==='/v1/rank'&&method==='POST'){
  const b=await body(request);fields(b,['code','pin'],['code','pin']);const code=codeOf(b.code);const account=await auth(code,b.pin);
  const saved=await current(db,code),save=validate(saved.save);
  const age=Math.max(0,now-account.created);
  const reasons=rankReasons(save,{best:account.rank_best,level:account.rank_level},Math.max(0,now-account.rank_at));
  if(save.dungeon_r21.best>0&&age<setting(env,'RANK_MIN_AGE_SECONDS',600,600))reasons.push('계정 나이');
  for(const reason of rankReasons(save,{best:0,level:1},age))if(!reasons.includes(reason))reasons.push(reason);
  if(reasons.length)reject(422,'rank_ineligible',{reasons});
  if(save.dungeon_r21.best>0){
   // The SELECT prevents a concurrent save/delete from ranking stale data.
   await db.batch([
    db.prepare('UPDATE accounts SET rank_best=MAX(rank_best,?),rank_level=MAX(rank_level,?),rank_at=? WHERE code=? AND rev=?').bind(save.dungeon_r21.best,save.persona.lv,now,code,saved.rev),
    db.prepare('INSERT INTO ranks(code,best,updated) SELECT code,?,? FROM accounts WHERE code=? AND rev=? AND changes()=1 ON CONFLICT(code) DO UPDATE SET best=excluded.best,updated=excluded.updated').bind(save.dungeon_r21.best,now,code,saved.rev)
   ]);
  }
  return json({submitted:true,best:save.dungeon_r21.best,cache_seconds:300});
 }
 if(path==='/v1/rank'&&method==='GET'){
  let best=null;
  const code=u.searchParams.has('code')?codeOf(u.searchParams.get('code')):null;
  await admit(code?[['read:'+code+':'+ipHash,60]]:[]);
  const snapshot=await rankSnapshot(db,now);
  if(u.searchParams.has('code')){const row=await db.prepare('SELECT best FROM ranks WHERE code=?').bind(code).first();best=row?.best??0;}
  const ahead=best===null?0:snapshot.histogram.filter(x=>x.best>best).reduce((n,x)=>n+x.n,0);
  return json({metric:'deepest_floor',best,pct:best>0?percentile(ahead,snapshot.n):null,n:snapshot.n,top:snapshot.top,at:snapshot.at,expires:snapshot.expires,cache_seconds:300});
 }
 const match=path.match(/^\/v1\/save\/([^/]+)(\/revs)?$/);
 if(match&&method==='GET'){
  let decoded;try{decoded=decodeURIComponent(match[1]);}catch{reject(400,'invalid_encoding');}
  const code=codeOf(decoded);await admit([['read:'+code+':'+ipHash,60]]);
  if(match[2]){const exists=await db.prepare('SELECT code FROM accounts WHERE code=?').bind(code).first();if(!exists)reject(404,'save_not_found');const rows=(await db.prepare('SELECT rev,summary,created AS at FROM saves WHERE code=? ORDER BY rev DESC LIMIT 10').bind(code).all()).results;return json({code,revs:rows.map(r=>({...r,summary:JSON.parse(r.summary)}))});}
  let rev=null;if(u.searchParams.has('rev')){const raw=u.searchParams.get('rev');if(!/^[1-9][0-9]*$/.test(raw))reject(400,'invalid_rev');rev=Number(raw);if(!Number.isSafeInteger(rev)||rev<1)reject(400,'invalid_rev');}
  return json(await current(db,code,rev));
 }
 reject(404,'not_found');
 }catch(e){if(!admitted&&e.status!==429)await admit();throw e;}
}
export default {
 async fetch(request,env){
  const origin=request.headers.get('Origin');let response;
  try{
   configured(env);
   if(origin&&!allowed(origin,env))reject(403,'origin_denied');
   if(request.method==='OPTIONS')response=new Response(null,{status:204,headers:{'Access-Control-Allow-Methods':'GET, POST, PUT, DELETE, OPTIONS','Access-Control-Allow-Headers':'Content-Type','Access-Control-Max-Age':'600'}});
   else response=await route(request,env);
  }catch(e){
   if(e instanceof Invalid)response=json({error:e.message,field:e.path},422);
   else if(e instanceof HttpError)response=json({error:e.message,...e.extra},e.status,e.status===429?{'Retry-After':String(e.extra.retry_after)}:{});
   else response=json({error:'service_unavailable'},503);
  }
  response.headers.set('Vary','Origin');response.headers.set('Cross-Origin-Resource-Policy','cross-origin');
  if(origin&&allowed(origin,env))response.headers.set('Access-Control-Allow-Origin',origin);
  return response;
 },
 async scheduled(event,env){
  configured(env);const db=env.DB,now=Math.floor(Date.now()/1000);
  const cutoff=now-setting(env,'INACTIVE_DAYS',180,1,36500)*86400;
  const expires=now+setting(env,'ARCHIVE_DAYS',30,1,36500)*86400;
  // Archive and cascade are a single transaction; a failed archive rolls back deletion.
  await db.batch([
   db.prepare("DELETE FROM counters WHERE (bucket NOT LIKE 'daily:%' AND minute<?) OR (bucket LIKE 'daily:%' AND minute<?)").bind(Math.floor(now/60)-2,Math.floor(now/86400)*1440),
   db.prepare('DELETE FROM inactive_archives WHERE expires<=?').bind(now),
   db.prepare('INSERT OR IGNORE INTO inactive_archives(code,salt,pin_hash,pin_iterations,rev,payload,summary,saved,archived,expires) SELECT a.code,a.salt,a.pin_hash,a.pin_iterations,a.rev,s.payload,s.summary,s.created,?,? FROM accounts a JOIN saves s ON s.code=a.code AND s.rev=a.rev WHERE a.updated<? ORDER BY a.updated LIMIT 100').bind(now,expires,cutoff),
   db.prepare('DELETE FROM accounts WHERE updated<? AND code IN (SELECT code FROM inactive_archives WHERE archived=? AND expires=?)').bind(cutoff,now,expires)
  ]);
 }

};
