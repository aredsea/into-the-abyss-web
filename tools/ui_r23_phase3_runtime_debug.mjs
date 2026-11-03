// Diagnostics only: expose Miniflare's rejected internal response, no disk patch.
import {registerHooks} from 'node:module';
registerHooks({load(url,context,next){
 const r=next(url,context);
 if(!url.replaceAll('\\','/').endsWith('/miniflare/dist/src/index.js'))return r;
 const source=String(r.source).replace('(0, import_node_assert15.default)(!isClientError(syncRes.status));','if(isClientError(syncRes.status))throw new Error("Internal Miniflare response "+syncRes.status+" "+new TextDecoder().decode(syncRes.body).slice(0,500));');
 return {...r,source};
}});
