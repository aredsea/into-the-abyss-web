// Test environment only: reuse installed dependencies read-only, keep the real
// Worker/D1/validation and disable only the cross-worktree development registry.
import './look_r24_cloud_launcher.mjs';
import {registerHooks,createRequire} from 'node:module';
import {pathToFileURL} from 'node:url';
import path from 'node:path';
if(process.env.ABYSS_NODE_MODULES){
 const installed=createRequire(path.join(process.env.ABYSS_NODE_MODULES,'package.json'));
 const wrangler=pathToFileURL(installed.resolve('wrangler')).href;
 registerHooks({resolve(specifier,context,next){
  if(specifier==='wrangler')return next(wrangler,context);
  return next(specifier,context);
 }});
}
