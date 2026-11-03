local out={rows={},counts={}}
local function cp(v)return json.decode(json.encode(v))end
local function core(G)return {saved=cp(G.persona.skill),draft=cp(G.ui.psd or {}),spent=G.ui.psd_gold or 0,gold=G.gold,message=G.ui.msg or ''}end
local specimens={{}}
for _,p in ipairs(B.PERSONA.prefixes)do for _,s in ipairs(B.PERSONA.suffixes)do if B.ps_compatible(p,s)then
 specimens[#specimens+1]={prefix=p.id,suffix=s.id,prefix_lv={},suffix_lv={}}
end end end
local args={'','ps','ps_','PS_up_pre','ps_up_pre_x','ps_up_missing','ps_pre_missing','ps_suf_missing','ps_up_pre','ps_up_suf','ps_save'}
for _,p in ipairs(B.PERSONA.prefixes)do args[#args+1]='ps_pre_'..p.id end
for _,s in ipairs(B.PERSONA.suffixes)do args[#args+1]='ps_suf_'..s.id end
local original_busy=B.pend_busy;local original_hard=B.pend_hard
for _,lang in ipairs({'ko','en'})do B.LANG=lang
for _,saved in ipairs(specimens)do for _,level in ipairs({0,9,10})do for _,gold in ipairs({0,200,99999})do for _,arg in ipairs(args)do
 local draft=B.ps_clean(saved)
 for _,p in ipairs(B.PERSONA.prefixes)do draft.prefix_lv[p.id]=level end
 for _,s in ipairs(B.PERSONA.suffixes)do draft.suffix_lv[s.id]=level end
 local G={persona={skill=cp(saved)},ui={psd=draft,psd_gold=7,msg='before'},gold=gold,pending=''}
 local busy=(gold==200);B.pend_busy=function()return busy end
 -- The host's pending/chat transport is observed separately, never equated
 -- with native dialogue or excluded from the remaining-work statement.
 B.pend_hard=function(g,text,id,line)g.pending=text;g.pending_line=line end
 local input={saved=cp(saved),draft=cp(draft),spent=7,gold=gold,arg=arg,busy=busy,lang=lang,message='before'}
 B.ps_guild_action(G,arg,'fixture')
 local op='research_action';out.rows[#out.rows+1]={op=op,input=input,expected=core(G),host_pending=G.pending,host_line=G.pending_line};out.counts[op]=(out.counts[op]or 0)+1
end end end end end
B.pend_busy=original_busy;B.pend_hard=original_hard;B.LANG='ko';return out
