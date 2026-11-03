// Test environment only: independent loopback port and no cross-worktree registry.
// Worker, D1 schema, auth checks and production sources remain unchanged.
import {registerHooks} from 'node:module';
registerHooks({load(url,context,next){
 const result=next(url,context);
 if(url.endsWith('/server/abyss-save/test/serve.mjs'))return {...result,source:String(result.source).replace('runtime(8787)','runtime()')};
 if(url.endsWith('/server/abyss-save/test/runtime.mjs'))return {...result,source:String(result.source).replace('cf:false,...runtimeExtra','cf:false,unsafeDevRegistry:false,...runtimeExtra')};
 return result;
}});
