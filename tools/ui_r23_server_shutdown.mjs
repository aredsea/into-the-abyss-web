// Preload only for serve.mjs: dispose Miniflare through its existing SIGINT handler.
// Windows process-tree enumeration can be denied in restricted test environments.
import {isMainThread} from 'node:worker_threads';
if (isMainThread && (process.argv[1] || '').replaceAll('\\','/').endsWith('server/abyss-save/test/serve.mjs')) {
  let pending='',stopping=false;
  const stop=()=>{if(stopping)return;stopping=true;process.emit('SIGINT');};
  process.stdin.setEncoding('utf8');
  process.stdin.on('data',chunk=>{pending+=chunk;if(pending.includes('ABYSS_R23_STOP\n'))stop();});
  process.stdin.on('end',stop);
}
