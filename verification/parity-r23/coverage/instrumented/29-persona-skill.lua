-- ===== 로레다나: 페르소나 고유 스킬 조합 =====
-- 데이터 정본 design/persona_skill.json. 조각별 단계는 조합을 바꿔도 남는다.
do B.__r23_cov.branches["29-persona-skill.lua:3:93"]=true; 
  B.PERSONA = json.decode(B.PERSONA_RAW)
  local C = B.PERSONA
  local function part(kind, id) B.__r23_cov.calls["29-persona-skill.lua:6"]=true; 
    if type(id) ~= "string" then B.__r23_cov.branches["29-persona-skill.lua:7:219"]=true;  return nil end
    for _, x in ipairs(C[kind]) do B.__r23_cov.branches["29-persona-skill.lua:8:271"]=true;  if x.id == id then B.__r23_cov.branches["29-persona-skill.lua:8:288"]=true;  return x end end
    return nil
  end
  local function attack(p) B.__r23_cov.calls["29-persona-skill.lua:11"]=true;  return p and (p.kind == "attack" or p.kind == "volley") end
  local SUPPORT = { regen = true, guard = true, crit = true }
  function B.ps_compatible(p, s) B.__r23_cov.calls["29-persona-skill.lua:13"]=true;  return p and s and (attack(p) ~= (not not SUPPORT[s.kind])) end
  local function lvl(t, id) B.__r23_cov.calls["29-persona-skill.lua:14"]=true; 
    local n = type(t) == "table" and tonumber(t[id]) or 0
    if not n or n ~= n then B.__r23_cov.branches["29-persona-skill.lua:16:686"]=true;  return 0 end
    return math.max(0, math.min(10, math.floor(n)))
  end
  function B.ps_clean(raw) B.__r23_cov.calls["29-persona-skill.lua:19"]=true; 
    raw = type(raw) == "table" and raw or {}
    local p, s = part("prefixes", raw.prefix), part("suffixes", raw.suffix)
    local out = { prefix = p and p.id or "", suffix = "", prefix_lv = {}, suffix_lv = {} }
    if B.ps_compatible(p, s) then B.__r23_cov.branches["29-persona-skill.lua:23:1030"]=true;  out.suffix = s.id end
    for _, x in ipairs(C.prefixes) do B.__r23_cov.branches["29-persona-skill.lua:24:1092"]=true;  local n = lvl(raw.prefix_lv, x.id); if n > 0 then B.__r23_cov.branches["29-persona-skill.lua:24:1140"]=true;  out.prefix_lv[x.id] = n end end
    for _, x in ipairs(C.suffixes) do B.__r23_cov.branches["29-persona-skill.lua:25:1212"]=true;  local n = lvl(raw.suffix_lv, x.id); if n > 0 then B.__r23_cov.branches["29-persona-skill.lua:25:1260"]=true;  out.suffix_lv[x.id] = n end end
    return out
  end
  function B.ps_parts(raw) B.__r23_cov.calls["29-persona-skill.lua:28"]=true; 
    local v = B.ps_clean(raw)
    return part("prefixes", v.prefix), part("suffixes", v.suffix), v
  end
  function B.ps_ready(raw) B.__r23_cov.calls["29-persona-skill.lua:32"]=true;  local p, s = B.ps_parts(raw); return p ~= nil and s ~= nil end
  function B.ps_cost(n) B.__r23_cov.calls["29-persona-skill.lua:33"]=true;  return C.cost.base + C.cost.step * n * n end
  local function num(n) B.__r23_cov.calls["29-persona-skill.lua:34"]=true;  return (string.format("%.2f", n):gsub("0+$", ""):gsub("%.$", "")) end
  local function pct(n) B.__r23_cov.calls["29-persona-skill.lua:35"]=true;  return B.floor(n * 100 + 0.5) end
  function B.ps_name(raw, force_en) B.__r23_cov.calls["29-persona-skill.lua:36"]=true; 
    local p, s = B.ps_parts(raw)
    if not s then B.__r23_cov.branches["29-persona-skill.lua:38:1843"]=true;  return B.U("아직 조합하지 않음") end
    return (force_en or B.LANG == "en") and (p.en .. " " .. s.en) or (p.name .. " " .. s.name)
  end
  function B.ps_desc(raw, force_en) B.__r23_cov.calls["29-persona-skill.lua:41"]=true; 
    local p, s, v = B.ps_parts(raw)
    if not s then B.__r23_cov.branches["29-persona-skill.lua:43:2063"]=true;  return B.U("길드장 로레다나에게서 조합할 수 있습니다.") end
    local a, b = lvl(v.prefix_lv, p.id), lvl(v.suffix_lv, s.id)
    local power = p.power + p.step * a
    local val = s.value + s.step * b
    local en = force_en or B.LANG == "en"
    local body
    if attack(p) then B.__r23_cov.branches["29-persona-skill.lua:49:2324"]=true; 
      local who = p.kind == "volley" and (en and "all enemies" or "적 전체") or (en and "one enemy" or "적 1명")
      body = en and (who .. " ×" .. num(power) .. ", abyss -" .. p.brk) or (who .. " ×" .. num(power) .. ", 심연 −" .. p.brk)
    else B.__r23_cov.branches["29-persona-skill.lua:52:2565"]=true; 
      local who = (p.kind == "heal_all" or p.kind == "shield_all") and (en and "all allies" or "아군 전체") or (en and "one ally" or "아군 1명")
      local fx = (p.kind == "heal" or p.kind == "heal_all") and (en and "heal" or "회복") or (en and "shield" or "보호막")
      body = who .. " " .. fx .. " ×" .. num(power)
    end
    local tail = {
      bane = en and ("+" .. pct(val) .. "% damage vs debuffed foes") or ("약화된 적 피해 +" .. pct(val) .. "%"),
      tempo = en and ("on kill, gauge +" .. pct(val) .. "%") or ("처치 시 행동 게이지 +" .. pct(val) .. "%"),
      bleed = en and ("damage over time ×" .. num(2 * val) .. " for 2 turns") or ("지속 피해 ×" .. num(2 * val) .. " 2턴"),
      weaken = en and ("enemy attack -" .. pct(val) .. "% for 2 turns") or ("적 공격 −" .. pct(val) .. "% 2턴"),
      regen = en and ("regen ×" .. num(2 * val) .. " for 2 rounds") or ("재생 ×" .. num(2 * val) .. " 2라운드"),
      guard = en and ("damage taken -" .. pct(val) .. "% for 2 turns") or ("받는 피해 −" .. pct(val) .. "% 2턴"),
      crit = en and ("critical chance +" .. pct(val) .. " points for 2 turns") or ("치명 +" .. pct(val) .. "%p 2턴"),
      abyss = en and ("extra abyss -" .. num(val)) or ("심연 추가 −" .. num(val)),
    }
    return body .. "; " .. tail[s.kind] .. (en and (" (prefix +" .. a .. ", suffix +" .. b .. ")") or (" (접두 +" .. a .. ", 접미 +" .. b .. ")"))
  end
  function B.ps_skill(raw) B.__r23_cov.calls["29-persona-skill.lua:69"]=true; 
    local p, s, v = B.ps_parts(raw)
    if not s then B.__r23_cov.branches["29-persona-skill.lua:71:3984"]=true;  return nil end
    return { id = "persona_skill", cid = "persona", pv = true, row = "com", name = B.ps_name(v), mp = p.mp,
      tgt = p.target, ic = attack(p) and "attack" or "bless", d = B.ps_desc(v) }
  end
  B.PRUN.persona = function(st, i, tgt, sk) B.__r23_cov.calls["29-persona-skill.lua:75"]=true; 
    local p, s, v = B.ps_parts(B.DEF[i].skill)
    if not s then B.__r23_cov.branches["29-persona-skill.lua:77:4303"]=true;  return end
    local a, b = lvl(v.prefix_lv, p.id), lvl(v.suffix_lv, s.id)
    local power, val = p.power + p.step * a, s.value + s.step * b
    B.push(st, { k = "cut", a = i, t = st.ev.T, nm = sk.name, pc = 1 })   -- 프로필 이미지 컷인(40-fx B.fx_pcutin) — 길이 1.9초
    st.ev.T = st.ev.T + 1.9
    local u, T = st.u[i], st.ev.T
    if attack(p) then B.__r23_cov.branches["29-persona-skill.lua:83:4645"]=true; 
      local opt = { m = power, brk = p.brk, name = sk.name, sk = sk.name, vb = "내리쳤다", hit = 0.45, dur = 1.5,
        el = p.id == "element" and C.class_elements[B.DEF[i].clsid] or B.DEF[i].el, ps_bane = s.kind == "bane" and val or nil }
      local results = {}
      if p.kind == "volley" then B.__r23_cov.branches["29-persona-skill.lua:87:4941"]=true; 
        opt.k = "wave"
        B.volley(st, i, opt)
        for n = #st.ev.list, 1, -1 do B.__r23_cov.branches["29-persona-skill.lua:90:5033"]=true; 
          local e = st.ev.list[n]
          if e.k == "wave" and e.a == i then B.__r23_cov.branches["29-persona-skill.lua:92:5110"]=true;  results = e.tg or {}; break end
        end
      else B.__r23_cov.branches["29-persona-skill.lua:94:5165"]=true;  results[1] = B.attack(st, i, tgt, opt) end
      for _, r in ipairs(results) do B.__r23_cov.branches["29-persona-skill.lua:95:5247"]=true; 
        local t = r.i
        if s.kind == "tempo" and r.kill == 1 then B.__r23_cov.branches["29-persona-skill.lua:97:5317"]=true;  u.g = u.g - B.floor(10000 * val + 0.5) end
        if st.u[t].al == 1 then B.__r23_cov.branches["29-persona-skill.lua:98:5392"]=true; 
          if s.kind == "bleed" then B.__r23_cov.branches["29-persona-skill.lua:99:5428"]=true;  B.dot_push(st, st.u[t], B.floor(u.cs * 2 * val + 0.5), 2, i)
          elseif s.kind == "weaken" then B.__r23_cov.branches["29-persona-skill.lua:100:5530"]=true;  B.badd(st.u[t], "adn", val, 2)
          elseif s.kind == "abyss" then B.__r23_cov.branches["29-persona-skill.lua:101:5601"]=true; 
            local ab, list = B.abyss(st, i, t, val, opt.el, st.ev.T)
            r.ab = (r.ab or 0) + (ab or 0)
            if list then B.__r23_cov.branches["29-persona-skill.lua:104:5738"]=true; 
              r.list = r.list or {}
              for _, item in ipairs(list) do B.__r23_cov.branches["29-persona-skill.lua:106:5821"]=true;  r.list[#r.list + 1] = item end
            end
          end
        end
      end
    else B.__r23_cov.branches["29-persona-skill.lua:111:5911"]=true; 
      local targets = {}
      if p.kind == "heal_all" or p.kind == "shield_all" then B.__r23_cov.branches["29-persona-skill.lua:113:5997"]=true; 
        for t = 1, 4 do B.__r23_cov.branches["29-persona-skill.lua:114:6023"]=true;  if st.u[t].al == 1 then B.__r23_cov.branches["29-persona-skill.lua:114:6045"]=true;  targets[#targets + 1] = t end end
      elseif tgt and st.u[tgt] and st.u[tgt].al == 1 then B.__r23_cov.branches["29-persona-skill.lua:115:6137"]=true;  targets[1] = tgt end
      local amount = B.floor(u.cs * 2 * power + 0.5)
      local hits = {}
      for _, t in ipairs(targets) do B.__r23_cov.branches["29-persona-skill.lua:118:6272"]=true; 
        local w = st.u[t]
        if p.kind == "heal" or p.kind == "heal_all" then B.__r23_cov.branches["29-persona-skill.lua:120:6353"]=true;  B.heal(st, t, amount, T + 0.7)
        else B.__r23_cov.branches["29-persona-skill.lua:121:6397"]=true;  B.setf(st, t, "sh", math.max(w.sh, amount), T + 0.7); w.shT = 3 end
        if s.kind == "regen" then B.__r23_cov.branches["29-persona-skill.lua:122:6499"]=true; 
          w.x = type(w.x) == "table" and w.x or {}
          w.x.psrg = { d = B.floor(u.cs * 2 * val + 0.5), n = 2, s = st.n }
        elseif s.kind == "guard" then B.__r23_cov.branches["29-persona-skill.lua:125:6664"]=true;  B.badd(w, "psguard", val, 2)
        elseif s.kind == "crit" then B.__r23_cov.branches["29-persona-skill.lua:126:6730"]=true;  B.badd(w, "pscrit", val, 2) end
        hits[#hits + 1] = { i = t, d = amount }
      end
      B.push(st, { k = "shield", a = i, t = T, tg = hits, nm = sk.name })
      B.say(st, B.U("<b>{who}</b>{particle} {skill:을를} 펼쳤다. {effect}", { who = B.T(B.DEF[i].name), particle = B.josa(B.T(B.DEF[i].name), "이가"), skill = sk.name, effect = B.ps_desc(v) }), T + 0.8)
      st.ev.T = T + 1.8
    end
  end
  B.TR.persona = {
    round = function(st, o) B.__r23_cov.calls["29-persona-skill.lua:135"]=true; 
      for t = 1, 4 do B.__r23_cov.branches["29-persona-skill.lua:136:7199"]=true; 
        local w = st.u[t]
        local r = type(w.x) == "table" and w.x.psrg
        if w.al == 1 and r then B.__r23_cov.branches["29-persona-skill.lua:139:7307"]=true; 
          B.heal(st, t, r.d, st.ev.T + 0.3)
          r.n = r.n - 1
          if r.n <= 0 then B.__r23_cov.branches["29-persona-skill.lua:142:7402"]=true;  w.x.psrg = nil end
        end
      end
    end,
  }
  local function label(x) B.__r23_cov.calls["29-persona-skill.lua:147"]=true;  return B.LANG == "en" and x.en or x.name end
  -- 편집 중인 조합(G.ui.psd) — 저장 전까지는 전투에 쓰지 않는 임시 칸이다. 클라우드에도 싣지 않는다(68-cloud).
  local function work(G) B.__r23_cov.calls["29-persona-skill.lua:149"]=true; 
    return B.ps_clean(type(G.ui.psd) == "table" and G.ui.psd or G.persona.skill)
  end
  local function same(a, b) B.__r23_cov.calls["29-persona-skill.lua:152"]=true; 
    if a.prefix ~= b.prefix or a.suffix ~= b.suffix then B.__r23_cov.branches["29-persona-skill.lua:153:7801"]=true;  return false end
    for _, kind in ipairs({ "prefixes", "suffixes" }) do B.__r23_cov.branches["29-persona-skill.lua:154:7877"]=true; 
      local key = kind == "prefixes" and "prefix_lv" or "suffix_lv"
      for _, x in ipairs(C[kind]) do B.__r23_cov.branches["29-persona-skill.lua:156:7982"]=true;  if lvl(a[key], x.id) ~= lvl(b[key], x.id) then B.__r23_cov.branches["29-persona-skill.lua:156:8027"]=true;  return false end end
    end
    return true
  end
  function B.ps_dirty(G) B.__r23_cov.calls["29-persona-skill.lua:160"]=true; 
    return type(G.ui) == "table" and type(G.ui.psd) == "table" and not same(B.ps_clean(G.ui.psd), B.ps_clean(G.persona.skill))
  end
  function B.ps_guild_tab(G) B.__r23_cov.calls["29-persona-skill.lua:163"]=true; 
    local v = work(G)
    local dirty = B.ps_dirty(G)
    local p, s = B.ps_parts(v)
    local out = { '<div class="dk-card gold"><div class="dk-title">' .. B.U("로레다나의 스킬 조합") .. '</div><div class="dk-text">' .. B.U("몸통과 덧효과를 고른 뒤 저장하면 로레다나와 이야기가 이어집니다. 바꾸기는 무료, 강화는 조각에 남습니다.") .. '</div>',
      '<div class="dk-sub">' .. B.U(dirty and "편집 중" or "현재 스킬") .. ': <b>' .. B.esc(B.ps_name(v)) .. '</b></div><div class="dk-sub">' .. B.esc(B.ps_desc(v)) .. '</div>' ..
      (dirty and ('<div class="dk-sub">' .. B.U("변경 사항이 있습니다. 저장하기 전에는 전투에 쓰이지 않습니다.") .. '</div>') or '') .. '</div>',
      '<div class="dk-card"><div class="px-sec">' .. B.U("접두어 · 몸통") .. '</div><div class="dk-row">' }
    for _, x in ipairs(C.prefixes) do B.__r23_cov.branches["29-persona-skill.lua:171:8993"]=true; 
      local n = lvl(v.prefix_lv, x.id)
      out[#out + 1] = B.btn("gd_ps_pre_" .. x.id, '<i class="im im-psk-' .. x.id .. ' psk-ic"></i>' .. B.esc(label(x)) .. " +" .. n, "sm" .. (v.prefix == x.id and " on" or ""), (B.LANG == "en" and x.note_en or x.note) .. " ×" .. num(x.power + x.step * n))
    end
    out[#out + 1] = '</div></div><div class="dk-card"><div class="px-sec">' .. B.U("접미어 · 덧효과") .. '</div><div class="dk-row">'
    for _, x in ipairs(C.suffixes) do B.__r23_cov.branches["29-persona-skill.lua:176:9462"]=true; 
      if p and B.ps_compatible(p, x) then B.__r23_cov.branches["29-persona-skill.lua:177:9502"]=true; 
        local n = lvl(v.suffix_lv, x.id)
        out[#out + 1] = B.btn("gd_ps_suf_" .. x.id, '<i class="im im-psk-' .. x.id .. ' psk-ic"></i>' .. B.esc(label(x)) .. " +" .. n, "sm" .. (v.suffix == x.id and " on" or ""), B.LANG == "en" and x.note_en or x.note)
      end
    end
    out[#out + 1] = '</div></div><div class="dk-card"><div class="px-sec">' .. B.U("강화") .. '</div><div class="dk-row">'
    for _, pair in ipairs({ { "pre", p, v.prefix_lv }, { "suf", s, v.suffix_lv } }) do B.__r23_cov.branches["29-persona-skill.lua:183:9990"]=true; 
      local kind, x, levels = pair[1], pair[2], pair[3]
      if x then B.__r23_cov.branches["29-persona-skill.lua:185:10060"]=true; 
        local n = lvl(levels, x.id)
        local en = B.LANG == "en"
        local gain = x.kind == "abyss" and ((en and "abyss -" or "심연 −") .. x.step)
          or (x == p and ((en and "multiplier +" or "배율 +") .. num(x.step)) or ((en and "effect +" or "효과 +") .. pct(x.step) .. "%"))
        local sub = n >= 10 and B.U("최대 단계") or B.U("금화 {cost} · 단계마다 {gain}", { cost = B.ps_cost(n + 1), gain = gain })
        out[#out + 1] = B.btn("gd_ps_up_" .. kind, B.U("{name} 강화 +{lv}", { name = label(x), lv = n }), "sm" .. (n >= 10 and " off" or ""), sub)
      end
    end
    out[#out + 1] = '</div><div class="dk-sub">' .. B.U("가진 금화 {gold}", { gold = G.gold or 0 }) .. '</div></div>'
    local ready = B.ps_ready(v)
    local sub = not dirty and B.U("바꾼 내용이 없습니다") or (not ready and B.U("덧효과를 먼저 고르세요")) or B.U("저장하면 로레다나와 이야기합니다")
    out[#out + 1] = '<div class="dk-row">' .. B.btn("gd_ps_save", B.U("저장"), "go" .. ((dirty and ready) and "" or " off"), sub) .. '</div>'
    return table.concat(out)
  end
  -- 이번에 바꾼 내용을 영어 한 줄씩(장면 지시용)
  local function changes(old, new) B.__r23_cov.calls["29-persona-skill.lua:201"]=true; 
    local list = {}
    if old.prefix ~= new.prefix or old.suffix ~= new.suffix then B.__r23_cov.branches["29-persona-skill.lua:203:11221"]=true; 
      list[#list + 1] = "combination: " .. B.ps_name(old, true) .. " -> " .. B.ps_name(new, true)
    end
    for _, kind in ipairs({ "prefixes", "suffixes" }) do B.__r23_cov.branches["29-persona-skill.lua:206:11386"]=true; 
      local key = kind == "prefixes" and "prefix_lv" or "suffix_lv"
      for _, x in ipairs(C[kind]) do B.__r23_cov.branches["29-persona-skill.lua:208:11491"]=true; 
        local a, b = lvl(old[key], x.id), lvl(new[key], x.id)
        if a ~= b then B.__r23_cov.branches["29-persona-skill.lua:210:11574"]=true;  list[#list + 1] = x.en .. " reinforced +" .. a .. " -> +" .. b end
      end
    end
    return list
  end
  local function save(G, id) B.__r23_cov.calls["29-persona-skill.lua:215"]=true; 
    if not B.ps_dirty(G) then B.__r23_cov.branches["29-persona-skill.lua:216:11740"]=true;  G.ui.msg = B.U("바꾼 내용이 없습니다."); return end
    local v = work(G)
    if not B.ps_ready(v) then B.__r23_cov.branches["29-persona-skill.lua:218:11835"]=true;  G.ui.msg = B.U("덧효과를 먼저 고르세요."); return end
    if B.pend_busy(G, id) then B.__r23_cov.branches["29-persona-skill.lua:219:11910"]=true;  G.ui.msg = B.U("앞의 장면이 아직 이어지지 않았습니다. 보내기를 눌러 먼저 이어 주세요."); return end
    local list = changes(B.ps_clean(G.persona.skill), v)
    G.persona.skill = v
    G.ui.psd, G.ui.psd_gold = nil, nil
    B.pend_hard(G, "[Persona skill confirmed] At the Union Guild Hall, Guildmaster Loredana finished reworking the user's persona signature skill. New skill: " ..
      B.ps_name(v, true) .. " (" .. B.ps_desc(v, true) .. "). What changed: " .. table.concat(list, "; ") ..
      ". Write Loredana's reaction and a short conversation about the new skill. Do not write the user's words or actions.", id, B.U("(로레다나에게 새 스킬 조합을 보여 준다)"))
    G.ui.msg = B.U("저장했습니다. 보내기를 누르면 로레다나와 이야기가 이어집니다.")
  end
  function B.ps_guild_action(G, arg, chat) B.__r23_cov.calls["29-persona-skill.lua:228"]=true; 
    if arg == "ps_save" then B.__r23_cov.branches["29-persona-skill.lua:229:12669"]=true;  save(G, chat); return end
    local kind, id = arg:match("^ps_([a-z]+)_([a-z]+)$")
    local v = work(G)
    if kind == "pre" then B.__r23_cov.branches["29-persona-skill.lua:232:12800"]=true; 
      local p = part("prefixes", id)
      if not p then B.__r23_cov.branches["29-persona-skill.lua:234:12857"]=true;  return end
      v.prefix = id
      if not B.ps_compatible(p, part("suffixes", v.suffix)) then B.__r23_cov.branches["29-persona-skill.lua:236:12953"]=true;  v.suffix = "" end
    elseif kind == "suf" then B.__r23_cov.branches["29-persona-skill.lua:237:13001"]=true; 
      if not B.ps_compatible(part("prefixes", v.prefix), part("suffixes", id)) then B.__r23_cov.branches["29-persona-skill.lua:238:13085"]=true;  return end
      v.suffix = id
    elseif kind == "up" and (id == "pre" or id == "suf") then B.__r23_cov.branches["29-persona-skill.lua:240:13178"]=true; 
      local selected = id == "pre" and v.prefix or v.suffix
      local x = part(id == "pre" and "prefixes" or "suffixes", selected)
      if not x then B.__r23_cov.branches["29-persona-skill.lua:243:13331"]=true;  return end
      local levels = id == "pre" and v.prefix_lv or v.suffix_lv
      local n = lvl(levels, selected)
      if n >= 10 then B.__r23_cov.branches["29-persona-skill.lua:246:13466"]=true;  G.ui.msg = B.U("이미 최대 단계입니다."); return end
      local cost = B.ps_cost(n + 1)
      if (G.gold or 0) < cost then B.__r23_cov.branches["29-persona-skill.lua:248:13580"]=true;  G.ui.msg = B.U("금화가 모자랍니다. 필요 금화 {cost}", { cost = cost }); return end
      G.gold = G.gold - cost
      G.ui.psd_gold = (tonumber(G.ui.psd_gold) or 0) + cost   -- 강화 금화는 바로 나간다(저장 전에도). 클라우드 저장 때만 이 값을 되돌려 싣는다(68-cloud)
      levels[selected] = n + 1
    else B.__r23_cov.branches["29-persona-skill.lua:252:13842"]=true;  return end
    G.ui.psd = v
    if not B.ps_dirty(G) then B.__r23_cov.branches["29-persona-skill.lua:254:13900"]=true;  G.ui.psd = nil; G.ui.psd_gold = nil end
    G.ui.msg = B.ps_ready(v) and B.U("고유 스킬: {name}. 저장하면 확정됩니다.", { name = B.ps_name(v) }) or B.U("덧효과를 고르면 스킬이 완성됩니다.")
  end
end
