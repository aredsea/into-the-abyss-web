"""Exercise the real Wrangler --local migration path, including a seeded P9 DB."""
from pathlib import Path
import os, json, subprocess, shutil, hashlib
root=Path(__file__).resolve().parents[1];out=root/'verification/cloud-r22/p9b/migration';out.mkdir(parents=True,exist_ok=True)
modules=Path(os.environ.get('ABYSS_NODE_MODULES','C:/Users/asone/AppData/Local/npm-cache/_npx/c943b712072b77c4/node_modules'))
cli=modules/'wrangler/bin/wrangler.js';env=os.environ.copy()
for k in ['CLOUDFLARE_API_TOKEN','CLOUDFLARE_API_KEY','CF_API_TOKEN','CF_API_KEY']:env.pop(k,None)
env.update(WRANGLER_SEND_METRICS='false',WRANGLER_LOG_PATH=str(out/'wrangler.log'))
results=[]
def run(name,args,config=None):
    command=['node',str(cli),'d1',*args,'--local','--persist-to',str(out/'d1'),'--config',str(config or root/'server/abyss-save/wrangler.toml')]
    p=subprocess.run(command,cwd=root,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=120)
    text=p.stdout.decode('utf-8',errors='replace');(out/(name+'.log')).write_text(text,encoding='utf-8')
    assert p.returncode==0,(name,p.returncode,text)
    results.append({'name':name,'exit':p.returncode})
    return text
def sql(name,query):
    text=run(name,['execute','abyss-web-save','--command',query,'--json'])
    return json.loads(text)
legacy=out/'legacy';legacy.mkdir(exist_ok=True)
shutil.copyfile(root/'server/abyss-save/migrations/0001.sql',legacy/'0001.sql')
config=out/'legacy.toml'
config.write_text('name="abyss-web-save-local-upgrade"\ncompatibility_date="2025-07-18"\n[[d1_databases]]\nbinding="DB"\ndatabase_name="abyss-web-save"\ndatabase_id="00000000-0000-0000-0000-000000000000"\nmigrations_dir="'+legacy.as_posix()+'"\n',encoding='utf-8')
run('01-legacy-schema',['migrations','apply','abyss-web-save'],config)
payload=json.dumps(json.loads((root/'verification/cloud-r22/fixtures.json').read_text(encoding='utf-8'))['town'],ensure_ascii=False,separators=(',',':'))
escape=lambda v:"'"+v.replace("'","''")+"'"
digest=hashlib.pbkdf2_hmac('sha256',b'23456789AB',b'local-upgrade-fixture',100000).hex()
sql('02-seed-legacy',"INSERT INTO accounts(code,salt,pin_hash,rev,created,updated) VALUES('ABCD-EFGH-JKMP','local-upgrade-fixture','"+digest+"',1,100,200); INSERT INTO saves(code,rev,payload,summary,created) VALUES('ABCD-EFGH-JKMP',1,"+escape(payload)+",'{}',200);")
run('03-production-migrations',['migrations','apply','abyss-web-save'])
state=sql('04-foreign-keys-and-preservation',"PRAGMA foreign_keys; PRAGMA foreign_key_check; SELECT a.code,a.pin_hash,a.pin_iterations,a.rank_at,s.payload FROM accounts a JOIN saves s USING(code) WHERE a.code='ABCD-EFGH-JKMP';")
assert state[0]['results']==[{'foreign_keys':1}],state
assert state[1]['results']==[],state
row=state[2]['results'][0];assert row['pin_hash']==digest and row['pin_iterations']==100000 and row['rank_at']==100 and row['payload']==payload
deleted=sql('05-cascade',"DELETE FROM accounts WHERE code='ABCD-EFGH-JKMP'; SELECT COUNT(*) AS n FROM saves WHERE code='ABCD-EFGH-JKMP';")
assert deleted[-1]['results']==[{'n':0}],deleted
run('06-idempotent',['migrations','apply','abyss-web-save'])
(out/'results.json').write_text(json.dumps({'checks':6,'failures':0,'commands':results,'foreign_keys':1,'old_pin_iterations':100000,'legacy_payload_unchanged':True},indent=2),encoding='utf-8')
print('WRANGLER MIGRATION CHECKS 6 FAILURES 0')
