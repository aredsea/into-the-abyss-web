-- ===== 동료 개인 스킬 · 특성 이식 (b) : 베렌가 · 군힐트 · 바르굿 · 알탄 · 콜레트 · 셀바 · 오르넬 · 자하르 · 요르드 · 라비니아 · 토베 · 미코 · 아델린 =====
-- 정본: design/stats.json(스킬) · proto/sim_traits/traits_v2.json → B.GEN.tr(특성 수치) · 참고 구현 proto/sim_traits/sim.py. 꼴은 PERSONAL-PORT.md.
-- 🔴 최상위 local 을 늘리지 않는다(한 청크 local 200 한계) — 아래는 전부 do ... end 안에서만 쓴다.
-- 🔴 엔진 파일은 고치지 않는다. 엔진에 없는 사건·표식은 여기서 흉내 내지 않고 보고(엔진 요청)로 남긴다.
--   · 적에게 「마법」 표식이 없다 → 콜레트·라비니아는 B.DEF[적].magic 또는 행동 ic == "spell" 을 읽는다(지금은 감시관의 강타 하나뿐).
--   · 적 차례 사건 · 전투 끝 사건 · 치명 확률 사건 · 버프 칩(red · zdn · 봉인 · 계약 표식)이 없다 → 각 사람 주석 참조.
do B.__r23_cov.branches["32-personal-b.lua:7:562"]=true; 
  local TR = B.GEN.tr

  local function nm(i) B.__r23_cov.calls["32-personal-b.lua:10"]=true;  return B.T(B.DEF[i].name) end
  local function sub(i) B.__r23_cov.calls["32-personal-b.lua:11"]=true;  return "<b>" .. nm(i) .. "</b>" .. B.josa(nm(i), "이가") end
  local function bp(word, key) B.__r23_cov.calls["32-personal-b.lua:12"]=true;  return "<b>" .. word .. "</b>" .. B.josa(word, key) end
  local function short(n) B.__r23_cov.calls["32-personal-b.lua:13"]=true;  return (tostring(n):gsub("%s*%b()", "")) end   -- 이름 뒤 농담 괄호는 로그에서 뺀다(버튼·컷인에는 그대로)
  local function pct(x) B.__r23_cov.calls["32-personal-b.lua:14"]=true;  return B.floor(x * 100 + 0.5) end
  local function Kc(st) B.__r23_cov.calls["32-personal-b.lua:15"]=true;  return st.K or B.K_of(st.el or 40) end

  -- ---------- 베렌가 : 트리아지 · 한계효용 체감 ----------
  -- 특성(회복량이 대상의 잃은 HP 비례로 최대 +60%)은 회복 스킬을 쓰는 그 자리에서 곱한다 — 엔진에 「회복」 사건이 없고 사제의 직업 스킬에 회복도 없다.
  local DEB = { adn = "공격 약화", ddn = "방어 약화", zdn = "방어 약화" }
  local function clear_debuff(u) B.__r23_cov.calls["32-personal-b.lua:20"]=true; 
    for _, k in ipairs({ "adn", "ddn", "zdn" }) do B.__r23_cov.branches["32-personal-b.lua:21:1328"]=true; 
      if u.bf and u.bf[k] then B.__r23_cov.branches["32-personal-b.lua:22:1357"]=true;  u.bf[k] = nil; return DEB[k] end
    end
    return nil
  end
  B.PSK.berenga = { id = "round_bless", ic = "bless", d = "개인 스킬: 아군 1명 회복(잃은 HP가 클수록 더 많이), 디버프 1개 해제" }
  B.PRUN.berenga = function(st, i, tgt, sk) B.__r23_cov.calls["32-personal-b.lua:27"]=true; 
    local u, T = st.u[i], st.ev.T
    local w = st.u[tgt]
    local k = TR.berenga.k
    local lost = 1 - w.hp / w.mhp
    local h = B.heal(st, tgt, u.cs * 2 * 1.0 * (1 + k * lost), T + 1.0)
    local cl = clear_debuff(w)
    B.push(st, { k = "shield", a = i, t = T, tg = { { i = tgt, d = h } }, nm = short(sk.name) })
    B.say(st, B.U("{who} {skill:을를} 베풀었다. {target} HP <em>+{heal}</em>{bonus}{cleanse}", { who = sub(i), skill = short(sk.name), target = nm(tgt), heal = h,
      bonus = lost > 0 and B.U(" (잃은 HP 비례 +{n}%)", { n = pct(k * lost) }) or "", cleanse = cl and B.U(", {debuff} 해제", { debuff = cl }) or "" }), T + 1.1)
    st.ev.T = T + 1.8
  end
  B.TR.berenga = {}

  -- ---------- 군힐트 : 엄근진 일격 · 선택과 집중 ----------
  B.PSK.gunhild = { id = "halen_cry", ic = "bash", d = "개인 스킬: 적 1명에게 위력 ×1.2, <em>심연 −15</em>" }
  B.PRUN.gunhild = function(st, i, tgt, sk) B.__r23_cov.calls["32-personal-b.lua:43"]=true; 
    B.attack(st, i, tgt, { m = 1.2, brk = 15, name = short(sk.name), sk = short(sk.name), vb = "내리쳤다", hit = 0.5, dur = 1.5 })
  end
  B.TR.gunhild = {
    -- 같은 적을 연달아 칠 때마다 피해 +per 씩 쌓임(최대 +max), 다른 적을 치면 처음부터. 쌓임은 군힐트의 행동 단위로 센다(한 행동의 여러 타는 한 번)
    deal = function(st, o, a, t, m, tags) B.__r23_cov.calls["32-personal-b.lua:48"]=true; 
      if a ~= o then B.__r23_cov.branches["32-personal-b.lua:49:2753"]=true;  return nil end
      local P, x = TR.gunhild, st.u[o].x
      if x.gn ~= st.n then B.__r23_cov.branches["32-personal-b.lua:51:2836"]=true; 
        x.gn = st.n
        x.gs = (x.gt == t) and ((x.gs or 0) + 1) or 0
        x.gt = t
      end
      if x.gt ~= t then B.__r23_cov.branches["32-personal-b.lua:56:2961"]=true;  return nil end
      local b = math.min(P.max, P.per * (x.gs or 0))
      if b <= 0 then B.__r23_cov.branches["32-personal-b.lua:58:3050"]=true;  return nil end
      tags[#tags + 1] = "선택과 집중 +" .. pct(b) .. "%"
      return m * (1 + b)
    end,
    -- 친 적이 쓰러지면 그 자리를 비운다(같은 자리에 소환된 적과 이어지지 않게)
    enemy_dead = function(st, o, t) B.__r23_cov.calls["32-personal-b.lua:63"]=true; 
      local x = st.u[o].x
      if x.gt == t then B.__r23_cov.branches["32-personal-b.lua:65:3287"]=true;  x.gt = nil; x.gs = 0 end
    end,
  }

  -- ---------- 바르굿 : 선점 효과 · 스노우볼 효과 ----------
  -- 스킬은 위력 1.2 로 때리는 기술이라 표적이 필요하다 — stats.json 의 대상 「자신」 대신 적 1명을 고른다(PSK.tgt).
  B.PSK.bargut = { id = "mtn_ambush", ic = "stab", tgt = "enemy", d = "개인 스킬: 적 1명에게 위력 ×1.2, 내가 가장 빠르면 피해 +50%, <em>심연 −15</em>" }
  B.PRUN.bargut = function(st, i, tgt, sk) B.__r23_cov.calls["32-personal-b.lua:72"]=true; 
    local u = st.u[i]
    local fast = true
    for j = 1, #st.u do B.__r23_cov.branches["32-personal-b.lua:75:3702"]=true;    -- 가장 빠름 = 속도가 살아 있는 모든 사람 이상(sim.py p_bargut)
      if j ~= i and st.u[j].al == 1 and st.u[j].sp > u.sp then B.__r23_cov.branches["32-personal-b.lua:76:3812"]=true;  fast = false; break end
    end
    B.attack(st, i, tgt, { m = 1.2, brk = 15, name = short(sk.name), sk = short(sk.name), vb = "먼저 찔렀다", amb = fast or nil, hit = 0.45, dur = 1.4 })
    if not fast then B.__r23_cov.branches["32-personal-b.lua:79:4014"]=true; 
      B.say(st, "<b>" .. nm(i) .. "</b>보다 빠른 자가 있어 기습 보너스는 받지 못했다", st.ev.T)
    end
  end
  B.TR.bargut = {
    deal = function(st, o, a, t, m, tags, opt) B.__r23_cov.calls["32-personal-b.lua:84"]=true; 
      if a ~= o or not opt then B.__r23_cov.branches["32-personal-b.lua:85:4202"]=true;  return nil end
      local u = st.u[o]
      -- 치명 확률 +30%p: 엔진에 확률 사건이 없어 B.hit 이 읽는 opt.cc(고정 확률)에 미리 더해 둔다. 일발필살처럼 확률이 정해진 공격은 그대로(sim.py 도 같다)
      if opt.cc == nil then B.__r23_cov.branches["32-personal-b.lua:88:4377"]=true;  opt.cc = u.cr + u.ag / 20 + (B.bhas(u, "bl") and 30 or 0) + TR.bargut.crit end
      if opt.amb then B.__r23_cov.branches["32-personal-b.lua:89:4478"]=true; 
        tags[#tags + 1] = B.U("선점 효과 +50%")
        return m * 1.5
      end
      return nil
    end,
    -- 치명타가 나면 다음 차례 30% 당김
    hit_after = function(st, o, a, t, res, opt, at) B.__r23_cov.calls["32-personal-b.lua:96"]=true; 
      if a ~= o or res.c ~= 1 then B.__r23_cov.branches["32-personal-b.lua:97:4696"]=true;  return end
      local u = st.u[o]
      u.x.pull = math.max(u.x.pull or 0, TR.bargut.pull)
      B.trait_line(st, o, B.U("스노우볼 효과: 다음 차례 {n}% 당김", { n = pct(TR.bargut.pull) }), at + 0.2)
    end,
    turn_end = function(st, o, i) B.__r23_cov.calls["32-personal-b.lua:102"]=true; 
      if i ~= o then B.__r23_cov.branches["32-personal-b.lua:103:4948"]=true;  return end
      local u = st.u[o]
      local p = u.x.pull or 0
      if p <= 0 then B.__r23_cov.branches["32-personal-b.lua:106:5034"]=true;  return end
      u.x.pull = 0
      u.g = u.g - 10000 * p
      if u.g < 0 then B.__r23_cov.branches["32-personal-b.lua:109:5114"]=true;  u.g = 0 end
    end,
  }

  -- ---------- 알탄 : 규모의 경제 · 리스크 헤지 ----------
  B.PSK.altan = { id = "brew", ic = "buff", d = "개인 스킬: 아군 전체 공격 또는 방어 +15% (2턴)" }
  B.PRUN.altan = function(st, i, tgt, sk) B.__r23_cov.calls["32-personal-b.lua:115"]=true; 
    local T = st.ev.T
    local anyatk, anydef = false, false
    for a = 1, 4 do B.__r23_cov.branches["32-personal-b.lua:118:5398"]=true; 
      local w = st.u[a]
      if w.al == 1 then B.__r23_cov.branches["32-personal-b.lua:120:5444"]=true; 
        if B.bhas(w, "atk") then B.__r23_cov.branches["32-personal-b.lua:121:5477"]=true;  anyatk = true end
        if B.bhas(w, "def") then B.__r23_cov.branches["32-personal-b.lua:122:5528"]=true;  anydef = true end
      end
    end
    local kind = (anyatk and not anydef) and "def" or "atk"   -- 「1종을 고른다」: 공격이 이미 걸려 있고 방어가 비었으면 방어
    for a = 1, 4 do B.__r23_cov.branches["32-personal-b.lua:126:5687"]=true; 
      local w = st.u[a]
      if w.al == 1 then B.__r23_cov.branches["32-personal-b.lua:128:5733"]=true;  B.badd(w, kind, 0.15, 2) end
    end
    B.push(st, { k = "shield", a = i, t = T, tg = {}, nm = short(sk.name) })
    B.say(st, B.U("{who} {skill:을를} 돌렸다. 아군 전체 {stat} <em>+15%</em> (2턴)", { who = sub(i), skill = short(sk.name), stat = (kind == "atk" and "공격" or "방어") }), T + 0.8)
    st.ev.T = T + 1.6
  end
  B.TR.altan = {
    -- 전투 시작: 아군 전원에게 보호막(알탄 지능 ×1.0, 3턴)
    start = function(st, o) B.__r23_cov.calls["32-personal-b.lua:136"]=true; 
      local u = st.u[o]
      local amt = B.floor(u.cs * 2 * TR.altan.k)
      u.x.ab = 0
      for a = 1, 4 do B.__r23_cov.branches["32-personal-b.lua:140:6244"]=true; 
        local w = st.u[a]
        if w.al == 1 then B.__r23_cov.branches["32-personal-b.lua:142:6294"]=true; 
          if w.sh < amt then B.__r23_cov.branches["32-personal-b.lua:143:6323"]=true;  B.setf(st, a, "sh", amt, st.ev.T) end
          w.shT = 3
        end
      end
      B.trait_line(st, o, "리스크 헤지: 아군 전원 보호막 " .. amt)
    end,
    -- 강공격(위력 ×1.5 이상의 단일 공격)이 표적을 때리기 직전 그 표적의 보호막을 다시 채운다(전투당 2회). 엔진에 「예고」 사건이 없어 공격 순간에 건다
    evade = function(st, o, ...) B.__r23_cov.calls["32-personal-b.lua:150"]=true; 
      local a = { ... }
      local t, e = a[#a - 1], a[#a]
      local u = st.u[o]
      if (u.x.ab or 0) >= TR.altan.times then B.__r23_cov.branches["32-personal-b.lua:154:6725"]=true;  return nil end
      local act = B.DEF[e].acts and B.DEF[e].acts[st.u[e].ia]
      if not (act and act.kind == "atk" and (act.m or 0) >= 1.5) then B.__r23_cov.branches["32-personal-b.lua:156:6872"]=true;  return nil end
      local w = st.u[t]
      local amt = B.floor(u.cs * 2 * TR.altan.k)
      if w.al ~= 1 or w.sh >= amt then B.__r23_cov.branches["32-personal-b.lua:159:6999"]=true;  return nil end
      u.x.ab = (u.x.ab or 0) + 1
      B.setf(st, t, "sh", amt, st.ev.T + 0.3)
      w.shT = 3
      B.trait_line(st, o, "리스크 헤지: " .. nm(t) .. " 보호막을 다시 " .. amt .. "까지 채움", st.ev.T + 0.3)
      return nil
    end,
  }

  -- ---------- 콜레트 : 침묵의 나선 · 위축 효과 ----------
  -- 「마법 피해」: 엔진에 마법/물리 구분이 없어 B.DEF[적].magic 또는 행동의 magic / ic == "spell"(지금은 감시관의 강타뿐)로 본다. 봉인 = 그 적의 마법 행동을 2라운드 동안 무효로 한다.
  local function has_magic(e) B.__r23_cov.calls["32-personal-b.lua:170"]=true; 
    local d = B.DEF[e]
    if d.magic then B.__r23_cov.branches["32-personal-b.lua:172:7483"]=true;  return true end
    for _, ac in ipairs(d.acts or {}) do B.__r23_cov.branches["32-personal-b.lua:173:7542"]=true;  if ac.magic or ac.ic == "spell" then B.__r23_cov.branches["32-personal-b.lua:173:7577"]=true;  return true end end
    return false
  end
  local function magic_now(st, e) B.__r23_cov.calls["32-personal-b.lua:176"]=true; 
    local d = B.DEF[e]
    local ac = d.acts and d.acts[st.u[e].ia]
    return d.magic == true or (ac ~= nil and (ac.magic == true or ac.ic == "spell"))
  end
  local function sealed(st, e) B.__r23_cov.calls["32-personal-b.lua:181"]=true;  return (st.u[e].x.seal or 0) > st.tk end
  -- 콜레트의 공격·스킬 : 적 전체에 2턴 약화(주는 피해 −15%)
  local function weaken_all(st, o, at) B.__r23_cov.calls["32-personal-b.lua:183"]=true; 
    local red = TR.colette.red
    local did = false
    for j = 5, #st.u do B.__r23_cov.branches["32-personal-b.lua:186:8045"]=true; 
      local w = st.u[j]
      if w.al == 1 then B.__r23_cov.branches["32-personal-b.lua:188:8091"]=true; 
        local cur = w.bf and w.bf.adn
        if not (cur and (cur.v > red or (cur.v == red and cur.n >= 2))) then B.__r23_cov.branches["32-personal-b.lua:190:8206"]=true;  B.badd(w, "adn", red, 2); did = true end
      end
    end
    local u = st.u[o]
    if did and u.x.cw ~= st.n then B.__r23_cov.branches["32-personal-b.lua:194:8322"]=true; 
      u.x.cw = st.n
      B.trait_line(st, o, B.U("위축 효과: 적 전체 공격 −{n}% (2턴){boss}", { n = pct(red), boss = B.boss_half(st) }), at)
    end
  end
  B.PSK.colette = { id = "seal_oath", ic = "weaken", d = "개인 스킬: 적 1명의 마법 공격 2턴 봉인, <em>심연 −15</em>" }
  B.PRUN.colette = function(st, i, tgt, sk) B.__r23_cov.calls["32-personal-b.lua:200"]=true; 
    local T = st.ev.T
    local magic = magic_now(st, tgt) or has_magic(tgt)
    local ab, list = B.abyss(st, i, tgt, 15, B.DEF[i].el, T + 0.8)
    local sealed = magic and (st.u[tgt].rd ~= 1 or B.rnd(st) < B.BOSSR.reduce)   -- 구역 보스는 봉인 확률 절반
    if sealed then B.__r23_cov.branches["32-personal-b.lua:205:8878"]=true;  st.u[tgt].x.seal = st.tk + 2 * B.ROUND end
    weaken_all(st, i, T + 0.9)
    B.push(st, { k = "mark", a = i, t = T, tg = { { i = tgt, ab = ab, list = list } }, nm = short(sk.name) })
    B.say(st, B.U("{who} {skill:을를} 내밀었다. {target}{result}{abyss}", { who = sub(i), skill = short(sk.name), target = nm(tgt), result = sealed and B.U(" 마법 공격 <em>2턴 봉인</em>") or (magic and B.U("의 마법을 봉인하지 못했다") or B.U("에게는 봉인할 마법이 없다")),
      abyss = ((ab or 0) > 0 and B.U(". <i>심연 −{n}</i>", { n = ab }) or "") }), T + 0.8)
    st.ev.T = T + 1.7
  end
  B.TR.colette = {
    -- 봉인할 마법이 있는 적이 없으면 스킬 버튼을 끈다(sim.py p_colette 와 같다)
    can = function(st, i) B.__r23_cov.calls["32-personal-b.lua:214"]=true; 
      for j = 5, #st.u do B.__r23_cov.branches["32-personal-b.lua:215:9548"]=true; 
        if st.u[j].al == 1 and has_magic(j) and not sealed(st, j) then B.__r23_cov.branches["32-personal-b.lua:216:9617"]=true;  return true end
      end
      return false
    end,
    hit_after = function(st, o, a, t, res, opt, at) B.__r23_cov.calls["32-personal-b.lua:220"]=true; 
      if a ~= o then B.__r23_cov.branches["32-personal-b.lua:221:9744"]=true;  return end
      weaken_all(st, o, at + 0.3)
    end,
    -- 봉인된 적의 마법 행동은 빗나간 것으로 처리된다(엔진이 「피했다」로 그린다 — 문구는 엔진 요청)
    evade = function(st, o, ...) B.__r23_cov.calls["32-personal-b.lua:225"]=true; 
      local a = { ... }
      local e = a[#a]
      if sealed(st, e) and magic_now(st, e) then B.__r23_cov.branches["32-personal-b.lua:228:9988"]=true; 
        B.trait_line(st, o, "침묵의 나선: " .. nm(e) .. "의 마법이 봉인되었다", st.ev.T + 0.4)
        return true
      end
      return nil
    end,
  }

  -- ---------- 셀바 : 성과급 챙기기 · 복리 효과 ----------
  B.PSK.selva = { id = "settle", ic = "attack", d = "개인 스킬: 위력 ×1.2, <em>심연 −15</em>, 쓰러뜨리면 MP 6 회복" }
  B.PRUN.selva = function(st, i, tgt, sk) B.__r23_cov.calls["32-personal-b.lua:238"]=true; 
    local u = st.u[i]
    local res = B.attack(st, i, tgt, { m = 1.2, brk = 15, name = short(sk.name), sk = "「" .. short(sk.name) .. "」", vb = "받아 냈다", hit = 0.45, dur = 1.4 })
    if res.kill == 1 then B.__r23_cov.branches["32-personal-b.lua:241:10526"]=true; 
      local gain = math.min(u.mmp, u.mp + 6) - u.mp
      if gain > 0 then B.__r23_cov.branches["32-personal-b.lua:243:10601"]=true; 
        B.setf(st, i, "mp", u.mp + gain, st.ev.T)
      B.say(st, B.U("{who} 잔금을 마나로 받아 냈다. MP <em>+{gain}</em>", { who = sub(i), gain = gain }), st.ev.T)
      end
    end
  end
  B.TR.selva = {
    -- 맞히기 직전에 표적의 HP 를 적어 둔다(흡수는 실제로 준 피해 기준)
    deal = function(st, o, a, t, m, tags) B.__r23_cov.calls["32-personal-b.lua:251"]=true; 
      if a ~= o then B.__r23_cov.branches["32-personal-b.lua:252:10907"]=true;  return nil end
      st.u[o].x.hp0 = st.u[t].hp + st.u[t].sh
      return nil
    end,
    hit_after = function(st, o, a, t, res, opt, at) B.__r23_cov.calls["32-personal-b.lua:256"]=true; 
      if a ~= o then B.__r23_cov.branches["32-personal-b.lua:257:11067"]=true;  return end
      local u = st.u[o]
      -- 넘친 회복량은 치명 배율을 받지 않는 고정 피해로, 공격이 끝난 뒤 따로 더한다(표적이 이미 쓰러졌으면 다음 공격으로 남긴다)
      local carry = B.floor(u.x.ov or 0)
      -- 주 공격이 표적을 쓰러뜨려도 이번 공격에서 쓴 것으로 친다(다음 적까지 이월하지 않는다 · 검수 5차 #8)
      if carry >= 1 and t >= 5 then B.__r23_cov.branches["32-personal-b.lua:262:11329"]=true;  u.x.ov = 0 end
      if carry >= 1 and t >= 5 and res.kill ~= 1 and st.u[t].al == 1 then B.__r23_cov.branches["32-personal-b.lua:263:11418"]=true; 
        local T = at + 0.3
        local r = B.strike(st, t, carry, T, nil, "fixed")   -- 고정 피해 — 방어 자세에 깎이지 않는다
        r.c, r.tags, r.ab = 0, { "넘친 회복 +" .. carry }, 0
        B.push(st, { k = "atk", a = o, t = T, ht = T + 0.1, tg = { r }, nm = "복리 효과" })
        B.say(st, sub(o) .. " 넘친 회복 <em>+" .. carry .. "</em>를 고정 피해로 더해 " .. nm(t) .. "에게 <em>" .. r.d .. "</em> 피해를 입혔다" .. (r.kill == 1 and (". <b>" .. nm(t) .. "</b>" .. B.josa(nm(t), "이가") .. " 쓰러졌다") or ""), T + 0.1)
        if r.kill == 1 then B.__r23_cov.branches["32-personal-b.lua:269:11927"]=true;  st.kill = B.DEF[o].full .. "의 복리 효과" end
        st.ev.T = math.max(st.ev.T, T + 0.5)
      end
      local dealt = math.min(res.d, u.x.hp0 or res.d)
      local hl = TR.selva.steal * dealt
      local got = math.min(hl, u.mhp - u.hp)
      local h = (got > 0) and B.heal(st, o, got, at + 0.2) or 0
      local over = hl - got
      if over > 0 then B.__r23_cov.branches["32-personal-b.lua:277:12277"]=true;  u.x.ov = (u.x.ov or 0) + over end
      if h > 0 or over >= 1 then B.__r23_cov.branches["32-personal-b.lua:278:12344"]=true; 
        B.trait_line(st, o, B.U("복리 효과: HP +{heal}{overflow}", { heal = h, overflow = (over >= 1) and B.U(", 넘친 양({n})은 다음 공격에", { n = B.floor(over) }) or "" }), at + 0.3)
      end
    end,
  }

  -- ---------- 오르넬 : 덫 놓은 화살 · 모난 돌이 정 맞는다 ----------
  -- 덫: 명중한 적의 공격 −20% 2턴(버프 칸 adn). 엔진에 이동이 없어 「이동 불가」 대신 묶는 쪽으로 바꿨다. 더 센 약화가 이미 걸려 있으면 덮어쓰지 않는다(콜레트와 같은 규칙).
  B.PSK.ornel = { id = "ranger_arrow", ic = "shoot", d = "개인 스킬: 위력 ×1.2, <em>심연 −15</em>, 덫(명중한 적의 공격 −20%, 2턴)" }
  B.PRUN.ornel = function(st, i, tgt, sk) B.__r23_cov.calls["32-personal-b.lua:287"]=true; 
    local res = B.attack(st, i, tgt, { m = 1.2, brk = 15, name = short(sk.name), sk = short(sk.name), vb = "쏘았다", hit = 0.6, dur = 1.5 })
    local w = st.u[tgt]
    if res and res.kill ~= 1 and w.al == 1 then B.__r23_cov.branches["32-personal-b.lua:290:13074"]=true; 
      local cur = w.bf and w.bf.adn
      if not (cur and (cur.v > 0.20 or (cur.v == 0.20 and cur.n >= 2))) then B.__r23_cov.branches["32-personal-b.lua:292:13187"]=true;  B.badd(w, "adn", 0.20, 2) end
      B.say(st, B.U("{target}의 발목에 덫이 걸렸다. 공격 <em>−{red}%</em> (2턴)", { target = nm(tgt), red = B.floor(20 * B.rdm(w) + 0.5) }), st.ev.T)
    end
  end
  B.TR.ornel = {
    -- HP 70% 이상인 적에게 피해 +60%
    deal = function(st, o, a, t, m, tags) B.__r23_cov.calls["32-personal-b.lua:298"]=true; 
      if a ~= o then B.__r23_cov.branches["32-personal-b.lua:299:13479"]=true;  return nil end
      local P, v = TR.ornel, st.u[t]
      if v.hp >= P.thr * v.mhp then B.__r23_cov.branches["32-personal-b.lua:301:13567"]=true; 
        tags[#tags + 1] = B.U("모난 돌이 정 맞는다 +{n}%", { n = pct(P.bonus) })
        return m * (1 + P.bonus)
      end
      return nil
    end,
  }

  -- ---------- 자하르 : 번아웃 증후군 · 짬밥 보정 ----------
  -- 「받는 물리 피해」: 엔진에 마법 피해 구분이 없어 적의 공격 전부를 물리로 본다. 방어 감소는 버프 칸 「zdn」(방어 +% 버프와 따로 쌓인다).
  B.PSK.zahar = { id = "mine_might", ic = "bash", d = "개인 스킬: 적 전체 ×1.2, <em>심연 −15씩</em>, 내 방어 1턴 −20%" }
  B.PRUN.zahar = function(st, i, tgt, sk) B.__r23_cov.calls["32-personal-b.lua:312"]=true; 
    B.volley(st, i, { m = 1.2, brk = 15, name = short(sk.name), k = "wave", hit = 0.6, dur = 2.0, line = "적 전체를 힘으로 밀어붙였다" })
    if st.u[i].al == 1 then B.__r23_cov.branches["32-personal-b.lua:314:14155"]=true; 
      B.badd(st.u[i], "zdn", 0.2, 2)
      B.say(st, B.U("{who} 자세가 흐트러졌다. 다음 차례까지 방어 <em>−20%</em>", { who = sub(i) }), st.ev.T)
    end
  end
  B.TR.zahar = {
    take = function(st, o, t, dmg) B.__r23_cov.calls["32-personal-b.lua:320"]=true; 
      if t ~= o then B.__r23_cov.branches["32-personal-b.lua:321:14372"]=true;  return nil end
      local u = st.u[o]
      local out = dmg * (1 - TR.zahar.red)
      local z = B.bget(u, "zdn")
      if z > 0 then B.__r23_cov.branches["32-personal-b.lua:325:14507"]=true; 
        local d0 = u.de * (1 + B.bget(u, "def"))
        local d1 = u.de * (1 + B.bget(u, "def") - z)
        out = out * (Kc(st) + d0) / (Kc(st) + d1)
      end
      return out
    end,
  }

  -- ---------- 요르드 : 연체 이자 · 티핑 포인트 ----------
  -- 레이드 특화: 보스 감경(차례 지연 ×0.5)은 보스가 없는 지금 걸리지 않는다. 일반 전투의 출혈·폭발·지연만 넣었다.
  -- 빠진 것: 출혈 틱으로 인한 차례 지연(엔진에 지속 피해 틱 사건이 없다).
  local function jr_per(st, u, w) B.__r23_cov.calls["32-personal-b.lua:337"]=true;    -- 출혈 한 중첩의 틱 피해(방어는 절반만 먹는다 — sim.py)
    local k = Kc(st)
    local dc = k / (k + w.de * (1 - B.bget(w, "ddn")))
    return u.cs * 2 * TR.jorund.k * (1 - (1 - dc) / 2)
  end
  local function jd_delay(st, t, want) B.__r23_cov.calls["32-personal-b.lua:342"]=true;    -- 적의 한 차례에 한 번만, 더 큰 값이 우선
    local w = st.u[t]
    local cur = w.x.jd or 0
    if want > cur and w.al == 1 then B.__r23_cov.branches["32-personal-b.lua:345:15237"]=true; 
      w.g = w.g + 10000 * (want - cur) * B.rdm(w)
      w.x.jd = want
    end
  end
  B.PSK.jorund = { id = "contract_blade", ic = "stab", d = "개인 스킬: 적 1명에게 위력 ×1.2, <em>심연 −15</em>, 계약 표식 대상 +40%" }
  B.PRUN.jorund = function(st, i, tgt, sk) B.__r23_cov.calls["32-personal-b.lua:351"]=true; 
    local w = st.u[tgt]
    local marked = (w.x.jm == 1)
    local res = B.attack(st, i, tgt, { m = 1.2, brk = 15, name = short(sk.name), sk = short(sk.name), vb = "가르듯 벴다", jmk = marked or nil, hit = 0.45, dur = 1.4 })
    if res.kill ~= 1 and not marked then B.__r23_cov.branches["32-personal-b.lua:355:15742"]=true; 
      w.x.jm = 1
      B.say(st, B.U("{who} <b>{target}</b>에게 계약 표식을 새겼다. 다음 연체 이자는 <em>+40%</em>", { who = sub(i), target = nm(tgt) }), st.ev.T)
    end
  end
  B.TR.jorund = {
    deal = function(st, o, a, t, m, tags, opt) B.__r23_cov.calls["32-personal-b.lua:361"]=true; 
      if a == o and opt and opt.jmk then B.__r23_cov.branches["32-personal-b.lua:362:16008"]=true; 
        tags[#tags + 1] = "계약 표식 +40%"
        return m * 1.4
      end
      return nil
    end,
    hit_after = function(st, o, a, t, res, opt, at) B.__r23_cov.calls["32-personal-b.lua:368"]=true; 
      if a ~= o or res.kill == 1 or t < 5 then B.__r23_cov.branches["32-personal-b.lua:369:16205"]=true;  return end
      local P, u, w = TR.jorund, st.u[o], st.u[t]
      if w.al ~= 1 then B.__r23_cov.branches["32-personal-b.lua:371:16290"]=true;  return end
      w.dot = w.dot or {}
      local bleeding = false   -- 출혈 줄(bld)이 하나도 남지 않았으면(3턴 지나 만료) 중첩 수도 0 에서 다시 시작한다
      for _, d in ipairs(w.dot) do B.__r23_cov.branches["32-personal-b.lua:374:16450"]=true;  if d.bld then B.__r23_cov.branches["32-personal-b.lua:374:16462"]=true;  bleeding = true; break end end
      if not bleeding then B.__r23_cov.branches["32-personal-b.lua:375:16520"]=true;  w.x.bn = 0 end
      local n = math.min(3, (w.x.bn or 0) + 1)
      local per = jr_per(st, u, w)
      for k = #w.dot, 1, -1 do B.__r23_cov.branches["32-personal-b.lua:378:16650"]=true;  if w.dot[k].bld then B.__r23_cov.branches["32-personal-b.lua:378:16669"]=true;  table.remove(w.dot, k) end end   -- 출혈 줄은 하나만 둔다
      if n >= 3 then B.__r23_cov.branches["32-personal-b.lua:379:16739"]=true; 
        w.x.bn = 0
        local ex = math.max(1, B.floor(3 * per * 3 * (1 + P.burst)))   -- 3중첩 × 남은 3틱 × 틱 피해 × (1 + 폭발 배율)
        local r = B.strike(st, t, ex, at + 0.3)
        B.trait_line(st, o, B.U("티핑 포인트: 출혈 3중첩 폭발 {damage}", { damage = r.d }), at + 0.3)
        B.say(st, "<b>" .. nm(o) .. "</b>의 <b>티핑 포인트</b>. " .. nm(t) .. "의 출혈이 한꺼번에 터졌다. <em>" .. r.d .. "</em> 피해를 입혔다" .. (r.kill == 1 and ". 쓰러졌다" or ""), at + 0.4)
        if r.kill == 1 then B.__r23_cov.branches["32-personal-b.lua:385:17200"]=true;  st.kill = B.DEF[o].full .. "의 티핑 포인트"; if B.kill_credit then B.__r23_cov.branches["32-personal-b.lua:385:17261"]=true;  B.kill_credit(st, o, at + 0.3) end else B.__r23_cov.branches["32-personal-b.lua:385:17301"]=true;  jd_delay(st, t, P.z2) end
      else B.__r23_cov.branches["32-personal-b.lua:386:17338"]=true; 
        w.x.bn = n
        w.dot[#w.dot + 1] = { d = math.max(1, B.floor(n * per)), n = 3, bld = 1, by = o }
        B.trait_line(st, o, B.U("티핑 포인트: 출혈 {n}중첩", { n = n }), at + 0.3)
        jd_delay(st, t, P.z)
      end
    end,
    -- 「한 차례에 한 번」의 기준: 적이 공격할 때 · 라운드가 바뀔 때 지연 기록을 비운다
    evade = function(st, o, ...) B.__r23_cov.calls["32-personal-b.lua:394"]=true; 
      local a = { ... }
      st.u[a[#a]].x.jd = 0
      return nil
    end,
    round = function(st, o) B.__r23_cov.calls["32-personal-b.lua:399"]=true; 
      for j = 5, #st.u do B.__r23_cov.branches["32-personal-b.lua:400:17791"]=true;  st.u[j].x.jd = 0 end
    end,
  }

  -- ---------- 라비니아 : 불허 도장 쾅 · 에코 챔버 ----------
  -- 「마법을 쓰려는 적」: 적의 지금 예고(B.DEF[적].acts[ia])가 주문·약화·소환 깃발이면 +30%(ENEMIES.md 깃발). 엔진 적에는 지금 감시관의 강타(ic = "spell") 하나뿐이고, 약화·소환 깃발은 적이 늘 때 같은 꼴(ic 또는 kind)로 읽힌다.
  local CAST = { spell = true, weaken = true, summon = true }
  local function casting(st, e) B.__r23_cov.calls["32-personal-b.lua:407"]=true; 
    local d = B.DEF[e]
    local ac = d and d.acts and d.acts[st.u[e].ia]
    return ac ~= nil and (CAST[ac.ic] == true or CAST[ac.kind] == true)
  end
  B.PSK.lavinia = { id = "branch_license", ic = "bolt", d = "개인 스킬: 위력 ×1.2, <em>심연 −15</em>, 주문, 약화, 소환 중 하나를 예고한 적 +30%" }
  B.PRUN.lavinia = function(st, i, tgt, sk) B.__r23_cov.calls["32-personal-b.lua:413"]=true; 
    B.attack(st, i, tgt, { m = 1.2, brk = 15, name = short(sk.name), sk = short(sk.name), vb = "내리쳤다", lvk = true, hit = 0.5, dur = 1.5 })
  end
  B.TR.lavinia = {
    deal = function(st, o, a, t, m, tags, opt) B.__r23_cov.calls["32-personal-b.lua:417"]=true; 
      if a == o and opt and opt.lvk and casting(st, t) then B.__r23_cov.branches["32-personal-b.lua:418:18721"]=true; 
        tags[#tags + 1] = "시전 단속 +30%"
        return m * 1.3
      end
      return nil
    end,
    -- 행동마다 한 번 굴려 성공하면 피해를 준 적에게 70% 위력으로 한 번 더(메아리, 심연 깎기 없음)
    hit_after = function(st, o, a, t, res, opt, at) B.__r23_cov.calls["32-personal-b.lua:425"]=true; 
      if a ~= o or res.kill == 1 then B.__r23_cov.branches["32-personal-b.lua:426:18973"]=true;  return end
      local u = st.u[o]
      if u.x.echoing == 1 then B.__r23_cov.branches["32-personal-b.lua:428:19039"]=true;  return end
      if u.x.echo_n ~= st.n then B.__r23_cov.branches["32-personal-b.lua:429:19083"]=true; 
        u.x.echo_n = st.n
        u.x.echo = (B.rnd(st) < TR.lavinia.prob) and 1 or 0
      end
      if u.x.echo ~= 1 or st.u[t].al ~= 1 then B.__r23_cov.branches["32-personal-b.lua:433:19226"]=true;  return end
      u.x.echoing = 1
      B.trait_line(st, o, B.U("에코 챔버: 메아리(피해 70%)"), at + 0.2)
      B.attack(st, o, t, { m = (opt.m or 1) * 0.7, brk = 0, name = "에코 챔버", sk = "메아리", vb = "한 번 더 내리쳤다", el = opt.el, cc = opt.cc, cm = opt.cm, hit = 0.4, dur = 1.0 })
      u.x.echoing = 0
    end,
  }

  -- ---------- 토베 : 꽁꽁 언 어그로 · 공격이 최선의 방어 ----------
  -- 심연 깎기는 stats.json 의 15 가 아니라 40 — 「대폭 감소」 정의와 sim.py(p_tove)가 40 이다.
  B.PSK.tove = { id = "frozen_barracks", ic = "ice", d = "개인 스킬: 적 1명 <em>심연 −40</em>, 2턴 도발" }
  B.PRUN.tove = function(st, i, tgt, sk) B.__r23_cov.calls["32-personal-b.lua:444"]=true; 
    local u, T = st.u[i], st.ev.T
    u.tau = 2   -- 도발 지속 2턴(자기 차례 기준 · 규칙은 30-engine B.begin_turn) · MP 10 ÷ 2턴 = 턴당 5
    local ab, list = B.abyss(st, i, tgt, 40, B.DEF[i].el, T + 0.9)
    B.push(st, { k = "taunt", a = i, t = T, nm = short(sk.name), tg = { { i = tgt, ab = ab, list = list } } })
    B.say(st, B.U("{who} {skill:을를} 펼쳤다. {target}{abyss}, 적의 공격이 {actor}에게 몰린다(2턴)", { who = sub(i), skill = short(sk.name), target = nm(tgt), abyss = ((ab or 0) > 0 and B.U(" <i>심연 −{n}</i>", { n = ab }) or ""), actor = nm(i) }), T + 0.9)
    st.ev.T = T + 1.9
  end
  local function tove_shield(st, o) B.__r23_cov.calls["32-personal-b.lua:452"]=true; 
    local u = st.u[o]
    local cap = B.floor(u.mhp * 0.30)
    local ns = math.min(cap, u.sh + B.floor(u.mhp * TR.tove.shield + 0.5))
    u.shT = 4
    if ns > u.sh then B.__r23_cov.branches["32-personal-b.lua:457:20567"]=true; 
      B.setf(st, o, "sh", ns, st.ev.T)
      B.trait_line(st, o, "공격이 최선의 방어: 보호막 " .. ns)
    end
  end
  B.TR.tove = {
    start = tove_shield,
    round = tove_shield,
    -- 보호막이 남아 있는 동안 피해 +35%
    deal = function(st, o, a, t, m, tags) B.__r23_cov.calls["32-personal-b.lua:466"]=true; 
      if a ~= o or st.u[o].sh <= 0 then B.__r23_cov.branches["32-personal-b.lua:467:20849"]=true;  return nil end
      tags[#tags + 1] = "공격이 최선의 방어 +" .. pct(TR.tove.bonus) .. "%"
      return m * (1 + TR.tove.bonus)
    end,
  }

  -- ---------- 미코 : 링거 투혼 · 약발 받는 한 방 / 러버밴드 효과 ----------
  -- 특성은 후보가 둘이다. 어느 쪽을 켤지는 자료 한 칸(traits_v2.json miko.p.variant → B.GEN.tr.miko.variant)이 정한다:
  --   1 = 약발 받는 한 방  : 미코의 스킬로 회복한 아군의 다음 공격 한 번에 피해 +bonus (그 공격이 여러 표적을 때려도 한 번으로 친다)
  --   2 = 러버밴드 효과 : 라운드가 시작될 때(차례를 쓰지 않는다) 다음 차례가 가장 먼 아군(미코 자신 제외)의 행동 게이지를 pull 만큼 당긴다
  -- 이름은 design/stats.json 의 trait.name 과 글자까지 같아야 한다(harness_personal_b 가 대조한다).
  local MIKO_TR = { "약발 받는 한 방", "러버밴드 효과" }
  B.MIKO_TR_NAMES = MIKO_TR
  B.PSK.miko = { id = "camp_tonic", ic = "bless", d = "개인 스킬: 아군 1명 회복, 그 사람의 다음 차례 30% 당김" }
  B.PRUN.miko = function(st, i, tgt, sk) B.__r23_cov.calls["32-personal-b.lua:481"]=true; 
    local u, T = st.u[i], st.ev.T
    local w = st.u[tgt]
    local h = B.heal(st, tgt, u.cs * 2 * 1.0, T + 1.0)
    w.g = w.g - 10000 * 0.3
    if w.g < 0 then B.__r23_cov.branches["32-personal-b.lua:486:21769"]=true;  w.g = 0 end
    local boost = TR.miko.variant == 1
    if boost then B.__r23_cov.branches["32-personal-b.lua:488:21838"]=true;  w.x.mk = TR.miko.bonus end   -- 약발 받는 한 방: 이 사람의 다음 공격 한 번(아래 deal)
    B.push(st, { k = "shield", a = i, t = T, tg = { { i = tgt, d = h } }, nm = short(sk.name) })
    B.say(st, B.U("{who} 「{skill}」 하며 약을 건넸다. {target} HP <em>+{heal}</em>, 다음 차례가 <em>당겨졌다</em>", { who = sub(i), skill = short(sk.name), target = nm(tgt), heal = h }), T + 1.1)
    if boost then B.__r23_cov.branches["32-personal-b.lua:491:22200"]=true; 
      B.trait_line(st, i, MIKO_TR[1] .. ": " .. nm(tgt) .. " 다음 공격 피해 +" .. pct(TR.miko.bonus) .. "%", T + 1.2)
      B.say(st, "<b>" .. nm(i) .. "</b>의 <b>" .. MIKO_TR[1] .. "</b>. " .. nm(tgt) .. B.josa(nm(tgt), "은는") .. " 약발이 올라 다음 공격 피해 <em>+" .. pct(TR.miko.bonus) .. "%</em>", T + 1.3)
    end
    st.ev.T = T + 1.8
  end
  B.TR.miko = {
    deal = function(st, o, a, t, m, tags, opt) B.__r23_cov.calls["32-personal-b.lua:498"]=true; 
      if TR.miko.variant ~= 1 then B.__r23_cov.branches["32-personal-b.lua:499:22626"]=true;  return nil end
      local x = st.u[a].x
      local v = opt and opt.mkv
      if v == nil then B.__r23_cov.branches["32-personal-b.lua:502:22722"]=true; 
        v = x.mk or 0
        x.mk = 0   -- 쓰든 안 쓰든 이 공격 한 번에 쓰고 사라진다
        if opt then B.__r23_cov.branches["32-personal-b.lua:505:22812"]=true;  opt.mkv = v end
      end
      if v <= 0 then B.__r23_cov.branches["32-personal-b.lua:507:22859"]=true;  return nil end
      tags[#tags + 1] = MIKO_TR[1] .. " +" .. pct(v) .. "%"
      return m * (1 + v)
    end,
    round = function(st, o) B.__r23_cov.calls["32-personal-b.lua:511"]=true; 
      if TR.miko.variant ~= 2 then B.__r23_cov.branches["32-personal-b.lua:512:23031"]=true;  return end
      local pick, late = nil, -1
      for a = 1, 4 do B.__r23_cov.branches["32-personal-b.lua:514:23099"]=true; 
        local w = st.u[a]
        if a ~= o and w.al == 1 then B.__r23_cov.branches["32-personal-b.lua:516:23160"]=true; 
          local wait = w.g / B.spd(st, a)
          if wait > late then B.__r23_cov.branches["32-personal-b.lua:518:23232"]=true;  pick, late = a, wait end
        end
      end
      if not pick then B.__r23_cov.branches["32-personal-b.lua:521:23302"]=true;  return end
      local w = st.u[pick]
      w.g = w.g - 10000 * TR.miko.pull
      if w.g < 0 then B.__r23_cov.branches["32-personal-b.lua:524:23401"]=true;  w.g = 0 end
      B.trait_line(st, o, MIKO_TR[2] .. ": " .. nm(pick) .. " 차례 " .. pct(TR.miko.pull) .. "% 당김", st.ev.T + 0.3)
      B.say(st, "<b>" .. nm(o) .. "</b>의 <b>" .. MIKO_TR[2] .. "</b>. " .. nm(pick) .. "의 다음 차례가 <em>" .. pct(TR.miko.pull) .. "% 당겨졌다</em>", st.ev.T + 0.4)
      st.ev.T = st.ev.T + 0.6
    end,
  }

  -- ---------- 아델린 : 플라시보 효과 · 무상 애프터서비스 ----------
  -- 재생은 받은 사람의 차례가 끝날 때마다 들어간다(아델린이 쓰러지면 멈춘다 — 훅이 아델린 소유라서). 받는 피해 −10% 도 같다.
  B.PSK.adeline = { id = "let_us_win", ic = "holy", d = "개인 스킬: 아군 전체 소량 회복, 2턴 동안 받는 피해 −10%와 재생, 쓰러지면 사라짐" }
  B.PRUN.adeline = function(st, i, tgt, sk) B.__r23_cov.calls["32-personal-b.lua:534"]=true; 
    local u, T = st.u[i], st.ev.T
    local P = TR.adeline
    local amt = u.cs * 2 * 0.4
    local tgs, sum = {}, 0
    for a = 1, 4 do B.__r23_cov.branches["32-personal-b.lua:539:24154"]=true; 
      local w = st.u[a]
      if w.al == 1 then B.__r23_cov.branches["32-personal-b.lua:541:24200"]=true; 
        local h = B.heal(st, a, amt, T + 1.0)
        B.badd(w, "red", 0.10, 2)
        w.bf.red.src = i
        -- 🔴 아델린 재생 = x.areg(배열 { a 양, n 남은 턴, s 건 행동 번호 }) — 소렐의 x.rg(표 하나)와 칸을 나눈다(검수 C1 · 10-08: 섞이면 저장 실패·크래시)
        w.x.areg = w.x.areg or {}
        w.x.areg[#w.x.areg + 1] = { a = u.cs * 2 * P.k, n = P.turns, s = st.n }   -- s: 건 행동 번호(그 행동이 끝날 때는 안 들어간다)
        tgs[#tgs + 1] = { i = a, d = h }
        sum = sum + h
      end
    end
    B.push(st, { k = "shield", a = i, t = T, tg = tgs, nm = short(sk.name) })
    B.say(st, B.U("{who} 두 손을 모았다. <b>{skill}</b>: 아군 전체 HP <em>+{heal}</em>, 2턴 받는 피해 −10%, 재생 {turns}턴", { who = sub(i), skill = short(sk.name), heal = sum, turns = P.turns }), T + 1.1)
    st.ev.T = T + 1.8
  end
  B.TR.adeline = {
    take = function(st, o, t, dmg) B.__r23_cov.calls["32-personal-b.lua:557"]=true; 
      local r = B.bget(st.u[t], "red")
      if r > 0 then B.__r23_cov.branches["32-personal-b.lua:559:25058"]=true;  return dmg * (1 - r) end
      return nil
    end,
    turn_end = function(st, o, i) B.__r23_cov.calls["32-personal-b.lua:562"]=true; 
      local w = st.u[i]
      local rg = w.x.areg
      if not rg or #rg == 0 or w.al ~= 1 then B.__r23_cov.branches["32-personal-b.lua:565:25239"]=true;  return end
      local sum, keep = 0, {}
      for _, r in ipairs(rg) do B.__r23_cov.branches["32-personal-b.lua:567:25314"]=true; 
        if r.s ~= st.n then B.__r23_cov.branches["32-personal-b.lua:568:25340"]=true; 
          sum = sum + r.a
          r.n = r.n - 1
        end
        if r.n > 0 then B.__r23_cov.branches["32-personal-b.lua:572:25426"]=true;  keep[#keep + 1] = r end
      end
      w.x.areg = (#keep > 0) and keep or nil
      local h = B.heal(st, i, sum, st.ev.T + 0.2)
      if h > 0 then B.__r23_cov.branches["32-personal-b.lua:576:25575"]=true;  B.trait_line(st, o, "무상 애프터서비스: " .. nm(i) .. " 재생 HP +" .. h, st.ev.T + 0.2) end
    end,
  }
  -- ---------- 시전자가 쓰러지면 그 사람이 건 효과가 사라진다 (할드리크 · 아델린) ----------
  -- 훅은 살아 있는 소유자 것만 돌아서 쓰러진 시전자 본인의 훅은 못 쓴다 — 모든 특성 표의 damaged 사건에 걸어, 아무 생존 아군의 훅이 쓰러진 시전자의 효과를 지운다.
  local function drop_caster_buffs(st, c) B.__r23_cov.calls["32-personal-b.lua:581"]=true;    -- 건 사람(src)이 c 인 받는 피해 감소 버프(할드리크 red20 · 아델린 red)를 모두 지운다
    for a = 1, 4 do B.__r23_cov.branches["32-personal-b.lua:582:25966"]=true; 
      local bf = st.u[a].bf
      if bf then B.__r23_cov.branches["32-personal-b.lua:584:26009"]=true; 
        for _, k in ipairs({ "red20", "red" }) do B.__r23_cov.branches["32-personal-b.lua:585:26061"]=true; 
          if bf[k] and bf[k].src == c then B.__r23_cov.branches["32-personal-b.lua:586:26102"]=true;  bf[k] = nil end
        end
      end
    end
  end
  local trs = {}
  for _, tr in pairs(B.TR) do B.__r23_cov.branches["32-personal-b.lua:592:26203"]=true;  trs[#trs + 1] = tr end   -- 순회 중 새 칸을 더하지 않으려고 먼저 모은다
  for _, tr in ipairs(trs) do B.__r23_cov.branches["32-personal-b.lua:593:26287"]=true; 
    local old = tr.damaged
    tr.damaged = function(st, o, t, dmg, src, at) B.__r23_cov.calls["32-personal-b.lua:595"]=true; 
      if old then B.__r23_cov.branches["32-personal-b.lua:596:26380"]=true;  old(st, o, t, dmg, src, at) end
      if st.u[t].al == 0 then B.__r23_cov.branches["32-personal-b.lua:597:26442"]=true; 
        drop_caster_buffs(st, t)
        if B.cid(t) == "adeline" then B.__r23_cov.branches["32-personal-b.lua:599:26513"]=true; 
          for a = 1, 4 do B.__r23_cov.branches["32-personal-b.lua:600:26541"]=true; 
            local x = st.u[a].x
            if type(x) == "table" then B.__r23_cov.branches["32-personal-b.lua:602:26610"]=true;  x.areg = nil end
          end
        end
      end
    end
  end
end
