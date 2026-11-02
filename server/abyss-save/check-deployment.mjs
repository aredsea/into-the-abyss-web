// This gate reads local Wrangler configuration only. No deployment or token use.
import {unstable_readConfig} from 'wrangler';
import {fileURLToPath} from 'node:url';
const config=unstable_readConfig({config:process.argv[2]??fileURLToPath(new URL('./wrangler.toml',import.meta.url))});
if(config.vars?.TURNSTILE_ENABLED!=='true'){
 console.error('Deployment refused: production TURNSTILE_ENABLED must be true.');
 process.exitCode=1;
}else console.log('Production Turnstile enabled. Local configuration check passed; no deployment performed.');
