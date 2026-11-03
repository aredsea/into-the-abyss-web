// Keep serve.mjs and the Worker/D1 code unchanged on disk; allocate a private port.
import './ui_r23_server_shutdown.mjs';
import {registerHooks} from 'node:module';
import {pathToFileURL} from 'node:url';
import path from 'node:path';
const root=path.resolve(import.meta.dirname,'..');
const entry=pathToFileURL(path.join(root,'server/abyss-save/test/serve.mjs')).href;
registerHooks({load(url,context,next){
 const result=next(url,context);if(url!==entry)return result;
 const before=String(result.source);
 if(!before.includes('runtime(8787)'))throw Error('Unexpected serve.mjs launcher');
 return {...result,source:before.replace('runtime(8787)','runtime()')};
}});
