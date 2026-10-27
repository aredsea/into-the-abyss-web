const fs=require('fs'),path=require('path'),crypto=require('crypto');
const {createCanvas,loadImage}=require('C:/Users/asone/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@napi-rs/canvas');
const root=path.resolve(__dirname,'../../outputs/github-publication'),out=__dirname;fs.mkdirSync(out,{recursive:true});
const art=JSON.parse(fs.readFileSync(root+'/project/data/character-art-r4.json','utf8'));
(async()=>{const records=[];for(const id of ['hildegard','teiris','bargut','berenga']){
 const a=art[id],source=root+'/project/'+a.path.replace('res://',''),im=await loadImage(source),f=a.frames[0],b=f.bounds;
 const canvas=createCanvas(256,256),c=canvas.getContext('2d');c.imageSmoothingEnabled=false;
 const scale=Math.min(204/b[3],204/b[2]);const ox=128-b[2]*scale/2-b[0]*scale,oy=230-(b[1]+b[3])*scale;
 c.save();c.translate(ox,oy);c.scale(scale,scale);c.beginPath();f.polygon.forEach((p,i)=>i?c.lineTo(...p):c.moveTo(...p));c.closePath();c.clip();c.drawImage(im,0,0);c.restore();
 fs.writeFileSync(out+'/'+id+'-seed.png',canvas.toBuffer('image/png'));
 records.push({id,source_sha256:crypto.createHash('sha256').update(fs.readFileSync(source)).digest('hex'),seed_size:[256,256],source_bounds:b,scale,foot_y:230,original_modified:false});
}fs.writeFileSync(out+'/seed-provenance.json',JSON.stringify(records,null,2));console.log(JSON.stringify(records));})();
