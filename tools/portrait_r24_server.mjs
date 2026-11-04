// Isolated test launcher only. No production server changes.
import {registerHooks} from 'node:module';
registerHooks({load(url,context,next){
 const result=next(url,context);
 if(url.endsWith('/server/abyss-save/test/runtime.mjs'))return {...result,source:String(result.source)
  .replace('cf:false,...runtimeExtra','cf:false,unsafeDevRegistryPath:process.env.PORTRAIT_DEV_REGISTRY,...runtimeExtra')
  .replace("new Miniflare(v5?require('miniflare').convertV4MiniflareOptions(options):options)","new Miniflare(v5?{...require('miniflare').convertV4MiniflareOptions(options),enableDevRegistry:false,unsafeEnableSharedStorage:false,resourcePersistencePath:path.join(process.env.PORTRAIT_DEV_REGISTRY,'state'),isolatedResourcePersistencePath:path.join(process.env.PORTRAIT_DEV_REGISTRY,'state')}:options)")
  .replace("const db=await mf.getD1Database('DB');","await mf.ready; const db=await mf.getD1Database('DB');")};
 return result;
}});
