// Resolve the existing, read-only tool installation; do not install into server/.
import {registerHooks,createRequire} from 'node:module';import {pathToFileURL} from 'node:url';import path from 'node:path';
const require=createRequire(path.join(process.env.ABYSS_NODE_MODULES,'package.json'));
const wrangler=pathToFileURL(require.resolve('wrangler')).href;
registerHooks({resolve(specifier,context,next){if(specifier==='wrangler')return {url:wrangler,shortCircuit:true};return next(specifier,context)}});
