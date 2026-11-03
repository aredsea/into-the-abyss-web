-- ===== 동료 개인 스킬 · 특성 이식 (A조 13명) =====
-- 할드리크 · 에르데네 · 비앙카 · 사야 · 게르다 · 유디트 · 우르다 · 리네트 · 펠리스 · 소렐 · 티카 · 헤드비히 · 힐데가
-- 꼴은 30-engine.lua 끝 4명(레비아·마르셀린·나란·테이리스)과 같다. 특성 수치는 B.GEN.tr[cid](traits_v2.json), 스킬 수치는 아래 SKN
-- (design/stats.json companions[].skill 의 power · turns · brk — 빌드가 MP·대상만 내보내서 여기 옮겨 적었다. 사장님이 고치면 같이 고칠 것).
-- 버프 "N턴" = 적의 공격 N번을 막는다: 자기 차례에 건 버프는 그 차례 끝에 줄지 않는다(엔진 규칙) — 쓴 사람도 다른 아군·적도 N.
-- 파일 전체를 do ... end 로 감싼다(최상위 local 수를 늘리지 않으려고).
do B.__expe_cov.branches["32-personal-a.lua:7:465"]=true; 
local nm = B.nm
local SKN = {
  haldric = { red = 0.20, n = 3 },
  erdene = { adn = 0.15, n = 2, brk = 20, tau = 3 },   -- tau = 도발 지속(자기 차례 수) — MP 15 ÷ 3턴 = 턴당 5 = 회복량(도발 유지 가능 · 10-10)
  bianca = { m = 1.4, dbf = 0.40 },
  saya = { delay = 0.40, brk = 3 },
  gerda = { m = 1.3, brk = 3 },
  judith = { ddn = 0.20, spd = 0.15, adn = 0.15, n = 3, brk = 3 },
  urda = { mult = 2.0 },
  lynette = { k = 0.5, n = 2 },
  sorel = { k = 1.0, rk = 0.3, n = 2 },
  tika = { hp = 0.10, free = 2 },
  hedwig = { m = 1.2, brk = 15, amp = 0.10 },
  hildegard = { red = 0.25, n = 2, brk = 15, tau = 2 },   -- 도발 지속 2턴 · MP 10 ÷ 2턴 = 턴당 5
  felice = { k = 0.4 },
}

local function xs(st, i) B.__expe_cov.calls["32-personal-a.lua:25"]=true; 
  local u = st.u[i]
  if type(u.x) ~= "table" then B.__expe_cov.branches["32-personal-a.lua:27:1192"]=true;  u.x = {} end
  return u.x
end
local function foes(st) B.__expe_cov.calls["32-personal-a.lua:30"]=true; 
  local l = {}
  for t = 5, #st.u do B.__expe_cov.branches["32-personal-a.lua:32:1285"]=true;  if st.u[t].al == 1 then B.__expe_cov.branches["32-personal-a.lua:32:1307"]=true;  l[#l + 1] = t end end
  return l
end
-- 표적 뒤의 적 1명: 전열이면 살아 있는 후열 첫 적, 아니면(또는 후열이 없으면) 표적 말고 살아 있는 첫 적
local function behind(st, t) B.__expe_cov.calls["32-personal-a.lua:36"]=true; 
  local ts = foes(st)
  if B.DEF[t].row == "전열" then B.__expe_cov.branches["32-personal-a.lua:38:1492"]=true; 
    for _, j in ipairs(ts) do B.__expe_cov.branches["32-personal-a.lua:39:1524"]=true;  if j ~= t and B.DEF[j].row == "후열" then B.__expe_cov.branches["32-personal-a.lua:39:1562"]=true;  return j end end
  end
  for _, j in ipairs(ts) do B.__expe_cov.branches["32-personal-a.lua:41:1615"]=true;  if j ~= t then B.__expe_cov.branches["32-personal-a.lua:41:1628"]=true;  return j end end
  return nil
end
local function lowest_foe(st) B.__expe_cov.calls["32-personal-a.lua:44"]=true; 
  local best
  for _, j in ipairs(foes(st)) do B.__expe_cov.branches["32-personal-a.lua:46:1741"]=true; 
    if not best or st.u[j].hp < st.u[best].hp then B.__expe_cov.branches["32-personal-a.lua:47:1790"]=true;  best = j end
  end
  return best
end
local function lowest_ally(st) B.__expe_cov.calls["32-personal-a.lua:51"]=true; 
  local best, br = nil, 2
  for a = 1, 4 do B.__expe_cov.branches["32-personal-a.lua:53:1904"]=true; 
    local w = st.u[a]
    if w.al == 1 then B.__expe_cov.branches["32-personal-a.lua:55:1946"]=true; 
      local r = w.hp / w.mhp
      if r < br then B.__expe_cov.branches["32-personal-a.lua:57:1996"]=true;  best, br = a, r end
    end
  end
  return best
end
local function pct(x) B.__expe_cov.calls["32-personal-a.lua:62"]=true;  return B.floor(x * 100 + 0.5) end
-- 스킬 이름 뒤의 (…) 꼬리표는 설정집 메모라 로그·연출에는 빼고 쓴다
local function sn(name) B.__expe_cov.calls["32-personal-a.lua:64"]=true;  return (tostring(name):gsub("%s*%b()", "")) end

-- ============ 할드리크: 면책 조항 · 연대 보증 책임 ============
-- 받는 피해 감소 버프(red20)는 시전자의 특성 훅(take)이 계산한다 — 시전자가 쓰러지면 효과가 없으니 상태에서도 지운다.
-- 버프에 건 사람(src)을 적어 두고, 시전자가 쓰러지는 순간 지우는 일은 32-personal-b 끝(damaged 사건)이 맡는다.
B.PSK.haldric = { id = "contract3", ic = "defend", d = "개인 스킬: 자신과 같은 줄 아군 받는 피해 −20% (3턴), 쓰러지면 사라짐" }
B.PRUN.haldric = function(st, i, tgt, sk) B.__expe_cov.calls["32-personal-a.lua:70"]=true; 
  local u, T = st.u[i], st.ev.T
  local n = SKN.haldric
  B.badd(u, "red20", n.red, n.n)
  u.bf.red20.src = i
  local names, first = {}, nil
  for a = 1, 4 do B.__expe_cov.branches["32-personal-a.lua:76:2734"]=true; 
    local w = st.u[a]
    if a ~= i and w.al == 1 and B.DEF[a].row == B.DEF[i].row then B.__expe_cov.branches["32-personal-a.lua:78:2820"]=true; 
      B.badd(w, "red20", n.red, n.n)
      w.bf.red20.src = i
      names[#names + 1] = nm(a)
      first = first or a
    end
  end
  if first then B.__expe_cov.branches["32-personal-a.lua:85:2969"]=true; 
    B.push(st, { k = "oath", a = i, t = T, tg = { { i = first } }, nm = sk.name })
  else B.__expe_cov.branches["32-personal-a.lua:87:3059"]=true; 
    B.push(st, { k = "def", a = i, t = T, nm = sk.name })
  end
  local who = B.U("자신")
  if #names > 0 then B.__expe_cov.branches["32-personal-a.lua:91:3168"]=true;  who = B.U("자신과 {names}", { names = table.concat(names, ", ") }) end
  B.say(st, B.U("<b>{who}</b>{particle} {skill:을를} 읊었다. {allies}{allies_particle} 받는 피해 <em>−{red}%</em> ({turns}턴)", { who = nm(i), particle = B.josa(nm(i), "이가"), skill = sk.name, allies = who, allies_particle = B.josa(who, "이가"), red = pct(n.red), turns = n.n }), T + 0.6)
  st.ev.T = T + 1.4
end
B.TR.haldric = {
  take = function(st, o, t, dmg, src) B.__expe_cov.calls["32-personal-a.lua:96"]=true; 
    local tr = B.GEN.tr.haldric
    local x = xs(st, o)
    local f = 1
    if t == o or st.u[o].tau > 0 then B.__expe_cov.branches["32-personal-a.lua:100:3701"]=true; 
      f = f * (1 - tr.red)
      if t ~= o and x.ann ~= 1 then B.__expe_cov.branches["32-personal-a.lua:102:3764"]=true; 
        x.ann = 1
        B.trait_line(st, o, "연대 보증 책임: 도발 중 파티 전원 받는 피해 −" .. pct(tr.red) .. "%")
      end
    end
    local r = B.bget(st.u[t], "red20")
    if r > 0 then B.__expe_cov.branches["32-personal-a.lua:108:3939"]=true;  f = f * (1 - r) end
    if f < 1 then B.__expe_cov.branches["32-personal-a.lua:109:3977"]=true;  return dmg * f end
  end,
  turn_end = function(st, o, i) B.__expe_cov.calls["32-personal-a.lua:111"]=true; 
    if i == o and st.u[o].tau <= 0 then B.__expe_cov.branches["32-personal-a.lua:112:4075"]=true;  xs(st, o).ann = 0 end
  end,
}

-- ============ 에르데네: 스포트라이트 효과 · 캐시백 이벤트 ============
B.PSK.erdene = { id = "howl", ic = "taunt", d = "개인 스킬: 적 전체 공격 −15%, 자신은 도발(3턴), <em>심연 −20씩</em>" }
B.PRUN.erdene = function(st, i, tgt, sk) B.__expe_cov.calls["32-personal-a.lua:118"]=true; 
  local u, T = st.u[i], st.ev.T
  local n = SKN.erdene
  u.tau = n.tau   -- 도발 지속 규칙: 30-engine B.begin_turn
  B.erdene_settle(st, i)   -- 도발을 새로 걸면 그때까지 막은 피해를 먼저 정산한다(계속 도발해도 회복이 굶지 않게)
  local first, fab, flist, tot = nil, 0, nil, {}
  for _, t in ipairs(foes(st)) do B.__expe_cov.branches["32-personal-a.lua:124:4578"]=true; 
    B.badd(st.u[t], "adn", n.adn, n.n)
    local ab, list = B.abyss(st, i, t, n.brk, B.DEF[i].el, T + 0.9)
    if not first then B.__expe_cov.branches["32-personal-a.lua:127:4705"]=true;  first, fab, flist = t, ab, list end
    if (ab or 0) > 0 then B.__expe_cov.branches["32-personal-a.lua:128:4767"]=true;  tot[#tot + 1] = nm(t) .. " −" .. ab end
  end
  B.push(st, { k = "taunt", a = i, t = T, nm = sk.name, tg = { { i = first or 5, ab = fab, list = flist } } })
  B.say(st, B.U("<b>{who}</b>{particle} 「{skill}」 하고 내질렀다. 적 전체 공격 <em>−{red}%</em> ({turns}턴){boss}, 도발{abyss}", { who = nm(i), particle = B.josa(nm(i), "이가"), skill = sk.name, red = pct(n.adn), turns = n.n, boss = B.boss_half(st), abyss = (#tot > 0 and B.U(", <i>심연 깎기: {targets}</i>", { targets = table.concat(tot, ", ") }) or "") }), T + 0.9)
  st.ev.T = T + 1.9
end
-- 캐시백 이벤트: 막은 피해(x.blk)의 25% 를 돌려받는다. 도발이 끝난 차례의 끝, 또는 도발을 새로 걸 때(끊김 없이 이어 걸어도 정산된다).
function B.erdene_settle(st, o) B.__expe_cov.calls["32-personal-a.lua:135"]=true; 
  local x = xs(st, o)
  if (x.blk or 0) > 0 then B.__expe_cov.branches["32-personal-a.lua:137:5463"]=true; 
    local blk = B.floor(x.blk + 0.5)
    local h = B.heal(st, o, B.GEN.tr.erdene.heal * x.blk, st.ev.T + 0.2)
    x.blk = 0
    if h > 0 then B.__expe_cov.branches["32-personal-a.lua:141:5605"]=true; 
      B.trait_line(st, o, "캐시백 이벤트: 막은 피해 " .. blk .. "의 " .. pct(B.GEN.tr.erdene.heal) .. "% 회복 +" .. h)
      B.say(st, "<b>" .. nm(o) .. "</b>의 <b>캐시백 이벤트</b>. 도발이 끝나며 막아 낸 피해 " .. blk .. "의 일부로 HP <em>" .. h .. "</em> 회복", st.ev.T + 0.3)
      st.ev.T = st.ev.T + 0.6
    end
  end
end
B.TR.erdene = {
  take = function(st, o, t, dmg, src) B.__expe_cov.calls["32-personal-a.lua:149"]=true; 
    if t ~= o or st.u[o].tau <= 0 then B.__expe_cov.branches["32-personal-a.lua:150:5988"]=true;  return nil end
    local tr = B.GEN.tr.erdene
    local x = xs(st, o)
    x.blk = (x.blk or 0) + dmg * tr.red
    return dmg * (1 - tr.red)
  end,
  turn_end = function(st, o, i) B.__expe_cov.calls["32-personal-a.lua:156"]=true; 
    if i ~= o then B.__expe_cov.branches["32-personal-a.lua:157:6186"]=true;  return end
    if st.u[o].tau <= 0 then B.__expe_cov.branches["32-personal-a.lua:158:6226"]=true;  B.erdene_settle(st, o) end
  end,
}

-- ============ 비앙카: 엎친 데 덮친 격 · 손절 타이밍 ============
B.PSK.bianca = { id = "ledger", ic = "stab", d = "개인 스킬: 단일 ×1.4, 디버프가 걸린 적에게 +40%" }
B.PRUN.bianca = function(st, i, tgt, sk) B.__expe_cov.calls["32-personal-a.lua:164"]=true; 
  B.attack(st, i, tgt, { m = SKN.bianca.m, brk = 0, name = sk.name, sk = "「" .. sk.name .. "」", vb = "찔렀다", hit = 0.5, dur = 1.5, dbf = SKN.bianca.dbf })
end
-- 「보스」= 구역 보스 · 층 끝 우두머리(chief) · 균열 핵(core) · 수호자. 🔴 우두머리는 kind 가 정예라 kind 만 보면 처형이 들어갔다(10-13 유저 제보).
local function bianca_boss(d) B.__expe_cov.calls["32-personal-a.lua:168"]=true;  return d.kind == "boss" or d.kind == "guardian" or d.grade == "chief" or d.grade == "boss" or d.grade == "core" end
B.TR.bianca = {
  deal = function(st, o, a, t, m, tags, opt) B.__expe_cov.calls["32-personal-a.lua:170"]=true; 
    if a ~= o then B.__expe_cov.branches["32-personal-a.lua:171:6932"]=true;  return nil end
    local d = B.DEF[t]
    if opt and opt.dbf and B.has_debuff(st.u[t]) then B.__expe_cov.branches["32-personal-a.lua:173:7024"]=true; 
      m = m * (1 + opt.dbf)
      tags[#tags + 1] = "디버프 +" .. pct(opt.dbf) .. "%"
    end
    if bianca_boss(d) then B.__expe_cov.branches["32-personal-a.lua:177:7142"]=true; 
      m = m * (1 + B.GEN.tr.bianca.boss)
      tags[#tags + 1] = "손절 타이밍 +" .. pct(B.GEN.tr.bianca.boss) .. "%"
    end
    return m
  end,
  hit_after = function(st, o, a, t, res, opt, at) B.__expe_cov.calls["32-personal-a.lua:183"]=true; 
    if a ~= o or t < 5 or res.kill == 1 then B.__expe_cov.branches["32-personal-a.lua:184:7377"]=true;  return end
    local v, d = st.u[t], B.DEF[t]
    if v.al ~= 1 or bianca_boss(d) then B.__expe_cov.branches["32-personal-a.lua:186:7463"]=true;  return end
    local tr = B.GEN.tr.bianca
    if v.hp > tr.thr * v.mhp then B.__expe_cov.branches["32-personal-a.lua:188:7539"]=true;  return end
    local hp0 = v.hp
    local T = st.ev.T
    local r = B.strike(st, t, hp0 * 2 + 1, T + 0.4)   -- 방어 자세(×0.6)여도 쓰러지도록 넉넉히
    r.d, r.c, r.tags, r.ab = hp0, 0, { B.U("처형") }, 0
    st.kill = B.U("{who}의 손절 타이밍", { who = B.DEF[o].full })
    B.push(st, { k = "atk", a = o, t = T, ht = T + 0.4, tg = { r }, nm = "손절 타이밍" })
    B.say(st, B.U("<b>{who}</b>의 <b>손절 타이밍</b>. {target:을를} 손절했다. <em>{damage}</em> 처형", { who = nm(o), target = nm(t), damage = hp0 }), T + 0.5)
    st.ev.T = T + 1.1
    local u = st.u[o]
    u.g = u.g - 10000 * tr.pull
    B.trait_line(st, o, B.U("손절 타이밍: 행동 게이지 {n}% 회복", { n = pct(tr.pull) }), T + 0.6)
  end,
}

-- ============ 사야: 발목 뜨개질 · 삼십육계 역습 ============
B.PSK.saya = { id = "knot", ic = "weaken", d = "개인 스킬: 적 1명의 다음 차례를 40% 뒤로, <em>심연 −3</em>" }
B.PRUN.saya = function(st, i, tgt, sk) B.__expe_cov.calls["32-personal-a.lua:205"]=true; 
  local T = st.ev.T
  local n = SKN.saya
  local v = st.u[tgt]
  v.g = v.g + 10000 * n.delay * B.rdm(v)   -- 구역 보스는 지연을 절반만(레이드 감경)
  local ab, list = B.abyss(st, i, tgt, n.brk, B.DEF[i].el, T + 0.8)
  B.push(st, { k = "mark", a = i, t = T, tg = { { i = tgt, ab = ab, list = list } }, nm = sk.name })
  B.say(st, B.U("<b>{who}</b>{particle} {skill:으로} {target}의 발목을 감았다. 다음 차례가 <em>{delay}%</em> 밀렸다{abyss}", { who = nm(i), particle = B.josa(nm(i), "이가"), skill = sk.name, target = nm(tgt), delay = pct(n.delay), abyss = ((ab or 0) > 0 and B.U(". <i>심연 −{n}</i>", { n = ab }) or "") }), T + 0.8)
  st.ev.T = T + 1.7
end
B.TR.saya = {
  -- 적 e 의 공격이 사야에게 빗나갈지(엔진이 chain 으로 부르니 인자는 (st, o, 빈 값, t, e))
  evade = function(st, o, _, t, e) B.__expe_cov.calls["32-personal-a.lua:217"]=true; 
    if t ~= o then B.__expe_cov.branches["32-personal-a.lua:218:9128"]=true;  return nil end
    local tr = B.GEN.tr.saya
    if B.rnd(st) * 100 >= tr.dodge then B.__expe_cov.branches["32-personal-a.lua:220:9212"]=true;  return nil end
    B.trait_line(st, o, "삼십육계 역습: 회피 후 반격")
    if st.u[e].al == 1 then B.__expe_cov.branches["32-personal-a.lua:222:9299"]=true; 
      B.attack(st, o, e, { m = tr.k, name = "삼십육계 역습", vb = "받아쳤다", hit = 0.3, dur = 0.9 })
    end
    return true
  end,
}

-- ============ 게르다: 일석이조 기원 · 도미노 이론 ============
B.PSK.gerda = { id = "luckbolt", ic = "shoot", tgt = "enemy", d = "개인 스킬: 표적과 그 뒤의 적 1명을 ×1.3씩 꿰뚫는다, <em>심연 −3씩</em>" }
B.PRUN.gerda = function(st, i, tgt, sk) B.__expe_cov.calls["32-personal-a.lua:231"]=true; 
  local n = SKN.gerda
  local x = xs(st, i)
  local bh = behind(st, tgt)
  x.inx = 1   -- 이 스킬이 스스로 꿰뚫으니 특성 관통은 끈다
  B.attack(st, i, tgt, { m = n.m, brk = n.brk, name = sk.name, sk = sk.name, vb = "꿰뚫었다", hit = 0.8, dur = 1.5 })
  if bh and st.u[bh].al == 1 then B.__expe_cov.branches["32-personal-a.lua:237:9899"]=true; 
    B.attack(st, i, bh, { m = n.m, brk = n.brk, name = sk.name, sk = sk.name, vb = "꿰뚫었다", hit = 0.5, dur = 1.5 })
  end
  x.inx = 0
end
B.TR.gerda = {
  hit_after = function(st, o, a, t, res, opt, at) B.__expe_cov.calls["32-personal-a.lua:243"]=true; 
    if a ~= o or t < 5 then B.__expe_cov.branches["32-personal-a.lua:244:10129"]=true;  return end
    local x = xs(st, o)
    if x.inx == 1 then B.__expe_cov.branches["32-personal-a.lua:246:10187"]=true;  return end
    local tr = B.GEN.tr.gerda
    local tg, mul = behind(st, t), tr.pen
    if not tg then B.__expe_cov.branches["32-personal-a.lua:249:10289"]=true; 
      if st.u[t].al ~= 1 then B.__expe_cov.branches["32-personal-a.lua:250:10319"]=true;  return end
      tg, mul = t, tr.pen * 0.5   -- 적이 하나뿐이면 같은 적에게 절반(30%)
    end
    x.inx = 1
    B.trait_line(st, o, "도미노 이론: " .. nm(tg) .. "까지 관통 " .. pct(mul) .. "%", st.ev.T)
    B.attack(st, o, tg, { m = (opt.m or 1) * mul, brk = 0, name = "도미노 이론", vb = "관통했다", hit = 0.4, dur = 1.0 })
    x.inx = 0
  end,
}

-- ============ 유디트: 머피의 법칙 · 바이럴 확산 ============
-- 부식 = 적의 지속 피해 목록(v.dot)에 c=1 항목 하나로 둔다(중첩 수 × 지능 ×k, 2턴). 중첩 수는 적의 x.cor.
B.PSK.judith = { id = "forbidden", ic = "dark", d = "개인 스킬: 방어↓, 속도↓, 공격↓ 3개를 차례로 걸고 부식 +1, <em>심연 −3</em>" }
-- 부식 줄(c=1)이 하나도 남지 않았으면(2턴 지나 만료) 중첩 수도 0 이다 — 새로 걸 때·옮길 때 먼저 확인한다
local function cor_live(v) B.__expe_cov.calls["32-personal-a.lua:264"]=true; 
  local x = v.x
  if type(x) ~= "table" then B.__expe_cov.branches["32-personal-a.lua:266:11014"]=true;  return 0 end
  for _, d in ipairs(v.dot or {}) do B.__expe_cov.branches["32-personal-a.lua:267:11066"]=true; 
    if d.c == 1 then B.__expe_cov.branches["32-personal-a.lua:268:11085"]=true;  return x.cor or 0 end
  end
  x.cor = 0
  return 0
end
local function corrode(st, o, t, stacks) B.__expe_cov.calls["32-personal-a.lua:273"]=true; 
  local v, u, tr = st.u[t], st.u[o], B.GEN.tr.judith
  local x = v.x
  if type(x) ~= "table" then B.__expe_cov.branches["32-personal-a.lua:276:11279"]=true;  x = {}; v.x = x end
  local n = math.min(3, cor_live(v) + (stacks or 1))
  x.cor = n
  local Kc = st.K or B.K_of(st.el or 40)
  local dc = Kc / (Kc + v.de * (1 - B.bget(v, "ddn")))
  local per = B.floor(u.cs * 2 * tr.k * (1 - (1 - dc) / 2))
  if per < 1 then B.__expe_cov.branches["32-personal-a.lua:282:11538"]=true;  per = 1 end
  v.dot = v.dot or {}
  for k = #v.dot, 1, -1 do B.__expe_cov.branches["32-personal-a.lua:284:11601"]=true;  if v.dot[k].c == 1 then B.__expe_cov.branches["32-personal-a.lua:284:11623"]=true;  table.remove(v.dot, k) end end
  v.dot[#v.dot + 1] = { d = per * n, n = 2, c = 1, by = o }   -- by = 건 사람(지속 피해로 처치해도 악마 시너지가 돈다 · 6차 검수 #3)
  return n, per
end
local function unslow(st) B.__expe_cov.calls["32-personal-a.lua:288"]=true; 
  for t = 5, #st.u do B.__expe_cov.branches["32-personal-a.lua:289:11834"]=true; 
    local v = st.u[t]
    local x = v.x
    if type(x) == "table" and x.slow and st.rd >= x.slow.rd then B.__expe_cov.branches["32-personal-a.lua:292:11937"]=true; 
      v.sp = x.slow.sp0
      x.slow = nil
    end
  end
end
B.PRUN.judith = function(st, i, tgt, sk) B.__expe_cov.calls["32-personal-a.lua:298"]=true; 
  local T = st.ev.T
  local n = SKN.judith
  local v = st.u[tgt]
  B.badd(v, "ddn", n.ddn, n.n)
  B.badd(v, "spd", n.spd, n.n)
  if type(v.x) ~= "table" then B.__expe_cov.branches["32-personal-a.lua:304:12197"]=true;  v.x = {} end
  if v.x.slow then B.__expe_cov.branches["32-personal-a.lua:305:12229"]=true; 
    v.x.slow.rd = st.rd + n.n
  else B.__expe_cov.branches["32-personal-a.lua:307:12266"]=true; 
    v.x.slow = { sp0 = v.sp, rd = st.rd + n.n }
    v.sp = B.floor(v.sp * (1 - n.spd) + 0.5)
  end
  B.badd(v, "adn", n.adn, n.n)
  local ab, list = B.abyss(st, i, tgt, n.brk, B.DEF[i].el, T + 0.8)
  local c = corrode(st, i, tgt, 1)
  B.push(st, { k = "mark", a = i, t = T, tg = { { i = tgt, ab = ab, list = list } }, nm = sk.name })
  B.say(st, B.U("<b>{who}</b>{particle} {skill:을를} 펼쳤다. {target} 방어 <em>−{def}%</em>, 속도 <em>−{speed}%</em>, 공격 <em>−{attack}%</em> ({turns}턴), 부식 {stacks}중첩{abyss}", { who = nm(i), particle = B.josa(nm(i), "이가"), skill = sk.name, target = nm(tgt), def = pct(n.ddn * B.rdm(v)), speed = pct(n.spd), attack = pct(n.adn * B.rdm(v)), turns = n.n, stacks = c, abyss = ((ab or 0) > 0 and B.U(". <i>심연 −{n}</i>", { n = ab }) or "") }), T + 0.8)
  st.ev.T = T + 1.7
end
B.TR.judith = {
  hit_after = function(st, o, a, t, res, opt, at) B.__expe_cov.calls["32-personal-a.lua:319"]=true; 
    if a ~= o or t < 5 or res.kill == 1 or st.u[t].al ~= 1 then B.__expe_cov.branches["32-personal-a.lua:320:13192"]=true;  return end
    local c = corrode(st, o, t, 1)
    B.trait_line(st, o, "바이럴 확산: " .. nm(t) .. " 부식 " .. c .. "중첩", st.ev.T)
  end,
  enemy_dead = function(st, o, t) B.__expe_cov.calls["32-personal-a.lua:324"]=true; 
    local c = cor_live(st.u[t])
    if c <= 0 then B.__expe_cov.branches["32-personal-a.lua:326:13407"]=true;  return end
    local to
    for _, j in ipairs(foes(st)) do B.__expe_cov.branches["32-personal-a.lua:328:13469"]=true;  if j ~= t then B.__expe_cov.branches["32-personal-a.lua:328:13482"]=true;  to = j; break end end
    if not to then B.__expe_cov.branches["32-personal-a.lua:329:13523"]=true;  return end
    local n = corrode(st, o, to, c)
    B.trait_line(st, o, "바이럴 확산: 부식이 " .. nm(to) .. "에게 옮았다 (" .. n .. "중첩)")
    B.say(st, "<b>" .. nm(t) .. "</b>의 부식이 <b>" .. nm(to) .. "</b>에게 옮았다. " .. n .. "중첩", st.ev.T + 0.2)
  end,
  round = function(st, o) B.__expe_cov.calls["32-personal-a.lua:334"]=true;  unslow(st) end,
  turn_end = function(st, o, i) B.__expe_cov.calls["32-personal-a.lua:335"]=true;  unslow(st) end,
}

-- ============ 우르다: 레버리지 효과 · 소울푸드 ============
local DBL = { "atk", "def", "red20", "red25" }   -- 두 배로 만들 수 있는 버프(값이 있는 것)
local function best_dbl(u) B.__expe_cov.calls["32-personal-a.lua:340"]=true; 
  local bk, bv
  for _, k in ipairs(DBL) do B.__expe_cov.branches["32-personal-a.lua:342:14052"]=true; 
    local b = u.bf and u.bf[k]
    if b and not b.d and (bv == nil or b.v > bv) then B.__expe_cov.branches["32-personal-a.lua:344:14135"]=true;  bk, bv = k, b.v end
  end
  return bk
end
B.PSK.urda = { id = "twogods", ic = "holy", d = "개인 스킬: 아군 1명의 버프 하나를 두 배로(지속 시간 그대로)" }
B.PRUN.urda = function(st, i, tgt, sk) B.__expe_cov.calls["32-personal-a.lua:349"]=true; 
  local T = st.ev.T
  local w = st.u[tgt]
  local k = best_dbl(w)
  B.push(st, { k = "oath", a = i, t = T, tg = { { i = tgt } }, nm = sk.name })
  if k then B.__expe_cov.branches["32-personal-a.lua:354:14462"]=true; 
    local b = w.bf[k]
    local old = b.v
    b.v = b.v * SKN.urda.mult
    if (k == "red20" or k == "red25") and b.v > 0.7 then B.__expe_cov.branches["32-personal-a.lua:358:14591"]=true;  b.v = 0.7 end
    b.d = 1
    B.say(st, "<b>" .. nm(i) .. "</b>" .. B.josa(nm(i), "이가") .. " " .. B.p(sk.name, "을를") .. " 내렸다. " .. nm(tgt) .. "의 버프가 <em>" .. pct(old) .. "% → " .. pct(b.v) .. "%</em> (남은 " .. b.n .. "턴 그대로)", T + 0.7)
  else B.__expe_cov.branches["32-personal-a.lua:361:14834"]=true; 
    B.say(st, B.U("<b>{who}</b>{particle} {skill:을를} 내렸지만 {target}에게는 두 배로 만들 버프가 없었다", { who = nm(i), particle = B.josa(nm(i), "이가"), skill = sk.name, target = nm(tgt) }), T + 0.7)
  end
  st.ev.T = T + 1.6
end
B.TR.urda = {
  can = function(st, i, sk) B.__expe_cov.calls["32-personal-a.lua:367"]=true; 
    for a = 1, 4 do B.__expe_cov.branches["32-personal-a.lua:368:15110"]=true; 
      if a ~= i and st.u[a].al == 1 and best_dbl(st.u[a]) then B.__expe_cov.branches["32-personal-a.lua:369:15171"]=true;  return true end
    end
    return false
  end,
  round = function(st, o) B.__expe_cov.calls["32-personal-a.lua:373"]=true; 
    local t = lowest_ally(st)
    if not t then B.__expe_cov.branches["32-personal-a.lua:375:15293"]=true;  return end
    local w = st.u[t]
    local u = st.u[o]
    local tr = B.GEN.tr.urda
    local h = B.heal(st, t, u.cs * 2 * tr.k, st.ev.T + 0.3)
    local cleansed
    if B.bhas(w, "adn") then B.__expe_cov.branches["32-personal-a.lua:381:15485"]=true;  w.bf.adn = nil; cleansed = B.U("공격 약화") elseif B.bhas(w, "ddn") then B.__expe_cov.branches["32-personal-a.lua:381:15554"]=true;  w.bf.ddn = nil; cleansed = B.U("방어 약화") end
    if h > 0 or cleansed then B.__expe_cov.branches["32-personal-a.lua:382:15628"]=true; 
      B.trait_line(st, o, B.U("소울푸드: {target}{heal}{cleanse}", { target = nm(t), heal = h > 0 and B.U(" +{n}", { n = h }) or "", cleanse = cleansed and B.U(", {debuff} 해제", { debuff = cleansed }) or "" }))
      B.say(st, B.U("<b>{owner}</b>의 <b>소울푸드</b>. {target}{heal}{cleanse}", { owner = nm(o), target = nm(t), heal = h > 0 and B.U(" HP <em>{n}</em> 회복", { n = h }) or "", cleanse = cleansed and B.U("{sep}{debuff} 해제", { sep = h > 0 and ", " or " ", debuff = cleansed }) or "" }), st.ev.T + 0.4)
      st.ev.T = st.ev.T + 0.6
    end
  end,
}

-- ============ 리네트: 끼워 팔기 · 단체 할인 ============
B.PSK.lynette = { id = "twotongues", ic = "bless", d = "개인 스킬: 아군 전체 회복 + 보호막(각각 절반 효과)" }
B.PRUN.lynette = function(st, i, tgt, sk) B.__expe_cov.calls["32-personal-a.lua:392"]=true; 
  local u, T = st.u[i], st.ev.T
  local n = SKN.lynette
  local amt = B.floor(u.cs * 2 * n.k)
  local tgs, hs = {}, 0
  for a = 1, 4 do B.__expe_cov.branches["32-personal-a.lua:397:16496"]=true; 
    local w = st.u[a]
    if w.al == 1 then B.__expe_cov.branches["32-personal-a.lua:399:16538"]=true; 
      hs = hs + B.heal(st, a, amt, T + 1.0)
      if w.sh < amt then B.__expe_cov.branches["32-personal-a.lua:401:16607"]=true;  B.setf(st, a, "sh", amt, T + 1.5) end
      w.shT = n.n + 1
      tgs[#tgs + 1] = { i = a, d = amt }
    end
  end
  B.push(st, { k = "shield", a = i, t = T, tg = tgs, nm = sk.name })
  B.say(st, B.U("<b>{who}</b>{particle} {skill:을를} 올렸다. 아군 전체 HP 회복(합 <em>{healed}</em>), 보호막 <em>{shield}</em>", { who = nm(i), particle = B.josa(nm(i), "이가"), skill = sk.name, healed = hs, shield = amt }), T + 1.6)
  st.ev.T = T + 2.8
end
B.TR.lynette = {}
-- 리네트가 전투에 살아 있는 동안 아군 전원의 스킬 MP 비용을 깎는다(엔진 B.mpc 가 부른다 — 장비가 깎은 값 위에 한 번 더). 값은 반올림, 0 이 되지는 않는다
function B.mp_lyn(st) B.__expe_cov.calls["32-personal-a.lua:412"]=true; 
  for o = 1, 4 do B.__expe_cov.branches["32-personal-a.lua:413:17191"]=true; 
    local d = B.DEF[o]
    if d and d.cid == "lynette" and st.u[o].al == 1 then B.__expe_cov.branches["32-personal-a.lua:415:17269"]=true;  return o end
  end
  return nil
end
function B.mp_cut(st, mp) B.__expe_cov.calls["32-personal-a.lua:419"]=true; 
  if not B.mp_lyn(st) then B.__expe_cov.branches["32-personal-a.lua:420:17358"]=true;  return mp end
  return math.max(1, B.floor(mp * (1 - B.GEN.tr.lynette.cut) + 0.5 + 1e-9))
end
function B.mp_note(st, i, base, mpc) B.__expe_cov.calls["32-personal-a.lua:423"]=true; 
  if mpc >= base then B.__expe_cov.branches["32-personal-a.lua:424:17511"]=true;  return end
  local o = B.mp_lyn(st)
  if o then B.__expe_cov.branches["32-personal-a.lua:426:17559"]=true;  B.trait_line(st, o, "단체 할인: " .. nm(i) .. " MP −" .. (base - mpc)) end
end

-- ============ 펠리스: 가성비 처방 · 패자 부활전 ============
-- 스킬: 엔진에 전투 중 아이템이 없어 「쓴 아이템 한 번 더」는 성립하지 않는다 → 약을 즉석에서 섞는 쪽으로 바꿨다(회복약 + 해독약 한 병씩): 아군 1 회복 + 디버프 1개 해제.
B.PSK.felice = { id = "improvise", ic = "bless", d = "개인 스킬: 아군 1명 소량 회복(지능 ×0.4), 디버프 1개 해제" }
B.PRUN.felice = function(st, i, tgt, sk) B.__expe_cov.calls["32-personal-a.lua:432"]=true; 
  local u, T = st.u[i], st.ev.T
  local w = st.u[tgt]
  local h = B.heal(st, tgt, u.cs * 2 * SKN.felice.k, T + 1.0)
  local cleansed
  for _, k in ipairs({ "adn", "ddn", "zdn" }) do B.__expe_cov.branches["32-personal-a.lua:437:18113"]=true; 
    if w.bf and w.bf[k] then B.__expe_cov.branches["32-personal-a.lua:438:18140"]=true; 
      w.bf[k] = nil
      cleansed = (k == "adn") and "공격 약화" or "방어 약화"
      break
    end
  end
  B.push(st, { k = "shield", a = i, t = T, tg = { { i = tgt, d = h } }, nm = sn(sk.name) })
  B.say(st, B.U("<b>{who}</b>{particle} {skill:을를} 건넸다. {target} HP <em>+{heal}</em>{cleanse}", { who = nm(i), particle = B.josa(nm(i), "이가"), skill = sn(sk.name), target = nm(tgt), heal = h, cleanse = cleansed and B.U(", {debuff} 해제", { debuff = cleansed }) or "" }), T + 1.1)
  st.ev.T = T + 1.8
end
local function felice_scan(st, o) B.__expe_cov.calls["32-personal-a.lua:448"]=true; 
  local x = xs(st, o)
  local tr = B.GEN.tr.felice
  if (x.rv or 0) >= tr.times then B.__expe_cov.branches["32-personal-a.lua:451:18752"]=true;  return end
  local best, brdy
  for a = 1, 4 do B.__expe_cov.branches["32-personal-a.lua:453:18802"]=true; 
    local w = st.u[a]
    if a ~= o and w.al == 0 and w.empty ~= 1 then B.__expe_cov.branches["32-personal-a.lua:455:18872"]=true; 
      if type(w.x) ~= "table" then B.__expe_cov.branches["32-personal-a.lua:456:18907"]=true;  w.x = {} end
      if not w.x.dtk then B.__expe_cov.branches["32-personal-a.lua:457:18946"]=true;  w.x.dtk = st.tk end
      local rdy = w.x.dtk + math.ceil(math.max(w.g, 0) / w.sp)
      if st.tk >= rdy and (best == nil or rdy < brdy) then B.__expe_cov.branches["32-personal-a.lua:459:19088"]=true;  best, brdy = a, rdy end
    end
  end
  if not best then B.__expe_cov.branches["32-personal-a.lua:462:19145"]=true;  return end
  local w, T = st.u[best], st.ev.T
  local h = math.max(1, B.floor(tr.hp * w.mhp))
  w.al, w.bf, w.tau, w.df, w.mk, w.chg = 1, {}, 0, 0, 0, 0
  w.g = 0
  w.x.dtk = nil
  B.setf(st, best, "hp", h, T + 0.4)
  x.rv = (x.rv or 0) + 1
  B.trait_line(st, o, "패자 부활전: " .. nm(best) .. " HP " .. pct(tr.hp) .. "%로 일어났다", T)
  B.say(st, "<b>" .. nm(o) .. "</b>의 <b>패자 부활전</b>. 쓰러졌던 <b>" .. nm(best) .. "</b>" .. B.josa(nm(best), "이가") .. " HP <em>" .. h .. "</em> 상태로 일어났다", T + 0.5)
  st.ev.T = T + 0.8
end
B.TR.felice = {
  save = function(st, o, t, at) B.__expe_cov.calls["32-personal-a.lua:475"]=true; 
    if t ~= o then B.__expe_cov.branches["32-personal-a.lua:476:19722"]=true; 
      local w = st.u[t]
      if type(w.x) ~= "table" then B.__expe_cov.branches["32-personal-a.lua:478:19781"]=true;  w.x = {} end
      w.x.dtk = st.tk
    end
    return nil
  end,
  turn_end = function(st, o, i) B.__expe_cov.calls["32-personal-a.lua:483"]=true;  felice_scan(st, o) end,
  round = function(st, o) B.__expe_cov.calls["32-personal-a.lua:484"]=true;  felice_scan(st, o) end,
  evade = function(st, o) B.__expe_cov.calls["32-personal-a.lua:485"]=true;  felice_scan(st, o) end,
}

-- ============ 소렐: 시간이 약이다 · 골든타임 ============
B.PSK.sorel = { id = "sap", ic = "bless", d = "개인 스킬: 아군 전체 HP 회복 + 다음 2라운드 재생" }
B.PRUN.sorel = function(st, i, tgt, sk) B.__expe_cov.calls["32-personal-a.lua:490"]=true; 
  local u, T = st.u[i], st.ev.T
  local n = SKN.sorel
  local amt = u.cs * 2 * n.k
  local rg = B.floor(u.cs * 2 * n.rk)
  local tgs, sum = {}, 0
  for a = 1, 4 do B.__expe_cov.branches["32-personal-a.lua:496:20341"]=true; 
    local w = st.u[a]
    if w.al == 1 then B.__expe_cov.branches["32-personal-a.lua:498:20383"]=true; 
      local h = B.heal(st, a, amt, T + 1.0)
      sum = sum + h
      xs(st, a).rg = { d = rg, n = n.n }
      tgs[#tgs + 1] = { i = a, d = h }
    end
  end
  B.push(st, { k = "shield", a = i, t = T, tg = tgs, nm = sk.name })
  B.say(st, B.U("<b>{who}</b>{particle} {skill:을를} 나눴다. 아군 전체 HP 회복(합 <em>{heal}</em>), 다음 {rounds}라운드 재생 {regen}", { who = nm(i), particle = B.josa(nm(i), "이가"), skill = sk.name, heal = sum, rounds = n.n, regen = rg }), T + 1.6)
  st.ev.T = T + 2.4
end
-- 골든타임: 아군이 피격으로 HP 25% 이하가 된 그 피해 직후(damaged 사건) 바로 치료한다. 쓰러진 사람은 치료하지 않는다.
local function sorel_aid(st, o, t, at) B.__expe_cov.calls["32-personal-a.lua:510"]=true; 
  local x = xs(st, o)
  local tr = B.GEN.tr.sorel
  if (x.emg or 0) >= tr.times then B.__expe_cov.branches["32-personal-a.lua:513:21066"]=true;  return end
  local w = st.u[t]
  if w.al ~= 1 or w.hp > tr.thr * w.mhp then B.__expe_cov.branches["32-personal-a.lua:515:21142"]=true;  return end
  local T = at or st.ev.T
  local h = B.heal(st, t, st.u[o].cs * 2 * tr.k, T + 0.3)
  x.emg = (x.emg or 0) + 1
  B.trait_line(st, o, "골든타임: " .. nm(t) .. " +" .. h .. " (" .. x.emg .. "/" .. tr.times .. ")", T)
  B.say(st, "<b>" .. nm(o) .. "</b>의 <b>골든타임</b>. HP가 바닥난 " .. B.p(nm(t), "을를") .. " 즉시 치료해 <em>" .. h .. "</em> 회복 (" .. x.emg .. "/" .. tr.times .. ")", T + 0.4)
  st.ev.T = math.max(st.ev.T, T + 0.7)
end
B.TR.sorel = {
  damaged = function(st, o, t, dmg, src, at) B.__expe_cov.calls["32-personal-a.lua:524"]=true;  sorel_aid(st, o, t, at) end,
  hp_cost = function(st, o, t, c, at) B.__expe_cov.calls["32-personal-a.lua:525"]=true;  sorel_aid(st, o, t, at) end,   -- 스킬 값으로 HP 를 깎아 25% 아래로 내려가도(검수 5차 #6)
  round = function(st, o) B.__expe_cov.calls["32-personal-a.lua:526"]=true; 
    for a = 1, 4 do B.__expe_cov.branches["32-personal-a.lua:527:21818"]=true; 
      local w = st.u[a]
      local r = w.al == 1 and type(w.x) == "table" and w.x.rg
      if r then B.__expe_cov.branches["32-personal-a.lua:530:21918"]=true; 
        local h = B.heal(st, a, r.d, st.ev.T + 0.3)
        r.n = r.n - 1
        if r.n <= 0 then B.__expe_cov.branches["32-personal-a.lua:533:22017"]=true;  w.x.rg = nil end
        if h > 0 then B.__expe_cov.branches["32-personal-a.lua:534:22056"]=true;  B.say(st, "<b>" .. nm(a) .. "</b>의 「시간이 약이다」 재생으로 HP <em>" .. h .. "</em> 회복", st.ev.T + 0.4) end
      end
    end
  end,
}

-- ============ 티카: 출혈 마케팅 · 앙코르 요청 쇄도 ============
-- 연속 행동 = x.free 만큼 차례 끝에 행동 게이지 비용을 돌려받아 곧바로 다시 움직인다.
B.PSK.tika = { id = "cheer", ic = "burn", d = "개인 스킬: HP 10% 소모, 다음 2회 공격이 연속 행동" }
B.PRUN.tika = function(st, i, tgt, sk) B.__expe_cov.calls["32-personal-a.lua:543"]=true; 
  local u, T = st.u[i], st.ev.T
  local x = xs(st, i)
  local c = B.floor(u.mhp * SKN.tika.hp)
  B.setf(st, i, "hp", u.hp - c, T + 0.3)
  B.fire(st, "hp_cost", i, c, T + 0.3)
  x.free = (x.free or 0) + SKN.tika.free
  x.inch = 1
  B.push(st, { k = "rev", a = i, t = T, nm = sn(sk.name), d = c })
  B.say(st, B.U("<b>{who}</b>{particle} <b>{skill}</b>에 들어간다. HP <em>{cost}</em> 소모, 다음 <em>{times}회</em> 연속 행동", { who = nm(i), particle = B.josa(nm(i), "이가"), skill = sn(sk.name), cost = c, times = SKN.tika.free }), T + 0.5)
  st.ev.T = T + 1.2
end
B.TR.tika = {
  can = function(st, i, sk) B.__expe_cov.calls["32-personal-a.lua:556"]=true; 
    local u = st.u[i]
    return (xs(st, i).inch or 0) ~= 1 and u.hp > B.floor(u.mhp * SKN.tika.hp)
  end,
  hit_after = function(st, o, a, t, res, opt, at) B.__expe_cov.calls["32-personal-a.lua:560"]=true; 
    if a ~= o then B.__expe_cov.branches["32-personal-a.lua:561:23178"]=true;  return end
    local x = xs(st, o)
    local roll = B.rnd(st)
    if (x.enc or 0) < 2 and roll < B.GEN.tr.tika.prob then B.__expe_cov.branches["32-personal-a.lua:564:23299"]=true; 
      x.enc = (x.enc or 0) + 1
      x.free = (x.free or 0) + 1
      B.trait_line(st, o, "앙코르 요청 쇄도: 곧바로 한 번 더 (" .. x.enc .. "/2)", st.ev.T)
    end
  end,
  turn_end = function(st, o, i) B.__expe_cov.calls["32-personal-a.lua:570"]=true; 
    if i ~= o then B.__expe_cov.branches["32-personal-a.lua:571:23508"]=true;  return end
    local u, x = st.u[o], xs(st, o)
    if (x.free or 0) > 0 then B.__expe_cov.branches["32-personal-a.lua:573:23585"]=true; 
      x.free = x.free - 1
      u.g = u.g - 10000
    else B.__expe_cov.branches["32-personal-a.lua:576:23644"]=true; 
      x.enc, x.inch = 0, 0
    end
  end,
}

-- ============ 헤드비히: 중2병 각성 · 삼세번의 법칙 ============
B.PSK.hedwig = { id = "lastdawn", ic = "bolt", d = "개인 스킬: 적 1명에게 지능 ×1.2, 다음 아군 마법 피해 +10%, <em>심연 −15</em>" }
B.PRUN.hedwig = function(st, i, tgt, sk) B.__expe_cov.calls["32-personal-a.lua:584"]=true; 
  local n = SKN.hedwig
  B.attack(st, i, tgt, { m = n.m, brk = n.brk, name = sn(sk.name), sk = sn(sk.name), vb = "내리꽂았다", hit = 0.8, dur = 1.7 })
  xs(st, i).mamp = n.amp
  B.say(st, B.U("<b>{who}</b>의 마법이 이름값을 했다. 다음 아군 마법 피해 <em>+{bonus}%</em>", { who = nm(i), bonus = pct(n.amp) }), st.ev.T)
end
B.TR.hedwig = {
  deal = function(st, o, a, t, m, tags, opt) B.__expe_cov.calls["32-personal-a.lua:591"]=true; 
    local x = xs(st, o)
    if a == o and x.decl == 1 then B.__expe_cov.branches["32-personal-a.lua:593:24313"]=true; 
      local b = B.GEN.tr.hedwig.bonus
      m = m * (1 + b)
      tags[#tags + 1] = "선언 +" .. pct(b) .. "%"
    end
    if (x.mamp or 0) > 0 and B.DEF[a].line == "지능" then B.__expe_cov.branches["32-personal-a.lua:598:24485"]=true; 
      m = m * (1 + x.mamp)
      tags[#tags + 1] = "이름값 +" .. pct(x.mamp) .. "%"
      x.mamp = 0
    end
    return m
  end,
  turn_end = function(st, o, i) B.__expe_cov.calls["32-personal-a.lua:605"]=true; 
    if i ~= o then B.__expe_cov.branches["32-personal-a.lua:606:24662"]=true;  return end
    local x = xs(st, o)
    local n = (x.hn or 0) + 1
    x.hn = n
    if x.decl == 1 and (x.dset or 0) < n then B.__expe_cov.branches["32-personal-a.lua:610:24786"]=true;  x.decl = 0 end   -- 선언한 다음 행동이 끝났다
    if n % B.GEN.tr.hedwig.every == 0 then B.__expe_cov.branches["32-personal-a.lua:611:24864"]=true; 
      x.decl, x.dset = 1, n
      B.trait_line(st, o, "삼세번의 법칙: 다음 공격 위력 +" .. pct(B.GEN.tr.hedwig.bonus) .. "%")
      B.say(st, "<b>" .. nm(o) .. "</b>의 <b>삼세번의 법칙</b>. 다음 공격 위력 <em>+" .. pct(B.GEN.tr.hedwig.bonus) .. "%</em>", st.ev.T + 0.2)
      st.ev.T = st.ev.T + 0.5
    end
  end,
}

-- ============ 힐데가: 전방 근무 개시 · 첫 번째 펭귄 ============
B.PSK.hildegard = { id = "frontier", ic = "taunt", d = "개인 스킬: 2턴 동안 받는 피해 −25%, 도발, <em>심연 −15</em>" }
B.PRUN.hildegard = function(st, i, tgt, sk) B.__expe_cov.calls["32-personal-a.lua:622"]=true; 
  local u, T = st.u[i], st.ev.T
  local n = SKN.hildegard
  u.tau = n.tau   -- 도발 지속 규칙: 30-engine B.begin_turn
  B.badd(u, "red25", n.red, n.n)
  local e = lowest_foe(st)
  local ab, list
  if e then B.__expe_cov.branches["32-personal-a.lua:629:25559"]=true;  ab, list = B.abyss(st, i, e, n.brk, B.DEF[i].el, T + 0.9) end
  B.push(st, { k = "taunt", a = i, t = T, nm = sk.name, tg = { { i = e or 5, ab = ab, list = list } } })
  B.say(st, B.U("<b>{who}</b>{particle} {skill:을를} 선언했다. 받는 피해 <em>−{red}%</em> ({turns}턴), 도발{abyss}", { who = nm(i), particle = B.josa(nm(i), "이가"), skill = sk.name, red = pct(n.red), turns = n.n, abyss = ((ab or 0) > 0 and B.U(", {target}에게 <i>심연 −{n}</i>", { target = nm(e), n = ab }) or "") }), T + 0.9)
  st.ev.T = T + 1.9
end
-- 쏠림: 적의 새 예고가 생기면 한 번 굴려 힐데가에게 돌린다(예고가 곧 표적이다). 도발이 있으면 도발이 우선이라 건드리지 않는다.
local function hg_scan(st, o) B.__expe_cov.calls["32-personal-a.lua:635"]=true; 
  local tr = B.GEN.tr.hildegard
  local taunted = false
  for a = 1, 4 do B.__expe_cov.branches["32-personal-a.lua:638:26242"]=true;  if st.u[a].al == 1 and st.u[a].tau > 0 then B.__expe_cov.branches["32-personal-a.lua:638:26284"]=true;  taunted = true end end
  for _, e in ipairs(foes(st)) do B.__expe_cov.branches["32-personal-a.lua:639:26343"]=true; 
    local ue = st.u[e]
    local act = B.DEF[e].acts[ue.ia]
    if type(ue.x) ~= "table" then B.__expe_cov.branches["32-personal-a.lua:642:26435"]=true;  ue.x = {} end
    if ue.x.hgk ~= ue.ia then B.__expe_cov.branches["32-personal-a.lua:643:26479"]=true; 
      ue.x.hgk = ue.ia
      ue.x.hg = 0
      if act and act.kind == "atk" and not taunted then B.__expe_cov.branches["32-personal-a.lua:646:26576"]=true; 
        local roll = B.rnd(st)
        if ue.it ~= o and roll < tr.pull then B.__expe_cov.branches["32-personal-a.lua:648:26653"]=true; 
          ue.it = o
          ue.x.hg = 1
          B.trait_line(st, o, "첫 번째 펭귄: " .. nm(e) .. "의 공격이 쏠린다", st.ev.T)
        end
      end
    end
  end
end
B.TR.hildegard = {
  start = function(st, o) B.__expe_cov.calls["32-personal-a.lua:658"]=true;  hg_scan(st, o) end,
  turn_end = function(st, o, i) B.__expe_cov.calls["32-personal-a.lua:659"]=true;  hg_scan(st, o) end,
  round = function(st, o) B.__expe_cov.calls["32-personal-a.lua:660"]=true;  hg_scan(st, o) end,
  hit_after = function(st, o) B.__expe_cov.calls["32-personal-a.lua:661"]=true;  hg_scan(st, o) end,
  take = function(st, o, t, dmg, src) B.__expe_cov.calls["32-personal-a.lua:662"]=true; 
    if t ~= o then B.__expe_cov.branches["32-personal-a.lua:663:27081"]=true;  return nil end
    local tr = B.GEN.tr.hildegard
    local f = 1 - tr.red
    local r = B.bget(st.u[o], "red25")
    if r > 0 then B.__expe_cov.branches["32-personal-a.lua:667:27212"]=true;  f = f * (1 - r) end
    if type(src) == "number" and src >= 5 then B.__expe_cov.branches["32-personal-a.lua:668:27279"]=true;    -- src 가 "fixed"(지속 피해)이면 적의 공격이 아니다
      local se = st.u[src].x
      if type(se) == "table" and se.hg == 1 then B.__expe_cov.branches["32-personal-a.lua:670:27396"]=true; 
        se.hg = 0
        local h = B.heal(st, o, tr.heal * st.u[o].mhp, st.ev.T + 0.3)
        if h > 0 then B.__expe_cov.branches["32-personal-a.lua:673:27506"]=true;  B.trait_line(st, o, "첫 번째 펭귄: 쏠려 온 공격을 받으며 +" .. h) end
      end
    end
    return dmg * f
  end,
}

end
