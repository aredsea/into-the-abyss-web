// Run the unchanged test/serve.mjs on an isolated port when 8787 is occupied.
const Module=require('node:module'),load=Module._load;
Module._load=function(name,parent,isMain){
 const result=load.apply(this,arguments);
 if(name==='miniflare')return {...result,Miniflare:class extends result.Miniflare{
  constructor(options){super({...options,port:options.port===8787?18787:options.port});}
 }};
 return result;
};
