-- ===== 엔진: 행동 순서표(CTB) · 판정 · 심연/고갈 · 스킬 · 적 예고 · 전투 끝 =====
-- 한국어 문자열은 바이트 단위로 자르지 않는다(이 파일은 sub 를 쓰지 않는다).
-- 🔴 파티 일반화(10-08): 자리 번호로 사람을 가리지 않는다. 사람은 B.DEF[i].cid, 직업은 B.DEF[i].clsid.
--    직업 스킬 = B.RUN[스킬 id](st, i, tgt, sk) · 개인 스킬 = B.PRUN[cid](st, i, tgt, sk) · 특성 = B.TR[cid].<사건>(아래 「특성 훅」).

local function nm(i) B.__expe_cov.calls["30-engine.lua:6"]=true;  return B.T(B.DEF[i].name) end
B.nm = nm

local function isweak(t, el) B.__expe_cov.calls["30-engine.lua:9"]=true; 
  local w = B.DEF[t].wk
  if not w or not el then B.__expe_cov.branches["30-engine.lua:11:442"]=true;  return false end
  for _, e in ipairs(w) do B.__expe_cov.branches["30-engine.lua:12:488"]=true;  if e == el then B.__expe_cov.branches["30-engine.lua:12:502"]=true;  return true end end
  return false
end
B.isweak = isweak

function B.cid(i) B.__expe_cov.calls["30-engine.lua:17"]=true;  return B.DEF[i] and B.DEF[i].cid or "" end
function B.slot_of(st, cid) B.__expe_cov.calls["30-engine.lua:18"]=true; 
  for i = 1, 4 do B.__expe_cov.branches["30-engine.lua:19:669"]=true;  if B.DEF[i].cid == cid then B.__expe_cov.branches["30-engine.lua:19:695"]=true;  return i end end
  return nil
end

-- ---------- 버프(전투 상태에 저장 — 키는 문자열) ----------
-- u.bf[k] = { v = 값, n = 남은 차례(보유자 차례 끝마다 −1) }. 같은 키는 덮어쓴다(중첩 없음).
-- 쓰는 키: atk 공격+ · def 방어+ · adn 공격− · ddn 방어− · bs 백스텝(확정 치명) · bl 피의 갈증(치명+30 · 치명 피해+0.5) · g2 굳건한 방어
-- 자기 차례에 자기에게 건 버프는 그 차례 끝에 깎지 않는다(f 표시) — 「2턴」이면 다음 자기 차례 두 번을 온전히 간다(검수 4차 #8).
-- 레이드 감경(FORMULA.md): 구역 보스(u.rd == 1)는 약화·지연·표식 같은 효과를 절반만 받는다
function B.rdm(u) B.__expe_cov.calls["30-engine.lua:28"]=true;  return (u.rd == 1) and B.BOSSR.reduce or 1 end
local DEBUFF_KEY = { adn = 1, ddn = 1, zdn = 1, sdn = 1 }
function B.badd(u, k, v, n) B.__expe_cov.calls["30-engine.lua:30"]=true; 
  if u.rd == 1 and DEBUFF_KEY[k] then B.__expe_cov.branches["30-engine.lua:31:1289"]=true;  v = v * B.BOSSR.reduce end
  if B.ACT and B.ACT.gq and (k == "atk" or k == "def" or k == "spd") then B.__expe_cov.branches["30-engine.lua:32:1390"]=true;  v = B.gear_buff(v) end   -- 장비 「버프 효과」: 시전자가 거는 이로운 버프만(81-gear)
  if B.badj then B.__expe_cov.branches["30-engine.lua:33:1472"]=true;  v, n = B.badj(u, k, v, n) end   -- 종족 특성(34-traits): 인간 적응 · 녹스 저항 · 하프엘프 시너지(버프 +1턴)
  u.bf = u.bf or {}; u.bf[k] = { v = v, n = n, f = (u == B.ACT) or nil }
end
function B.bget(u, k) B.__expe_cov.calls["30-engine.lua:36"]=true;  local b = u.bf and u.bf[k]; return b and b.v or 0 end
function B.boss_half(st) B.__expe_cov.calls["30-engine.lua:37"]=true;    -- 살아 있는 적 가운데 구역 보스가 있으면 " (보스는 절반)"
  for j = 5, #st.u do B.__expe_cov.branches["30-engine.lua:38:1800"]=true;  local w = st.u[j]; if w and w.al == 1 and w.rd == 1 then B.__expe_cov.branches["30-engine.lua:38:1855"]=true;  return " (보스는 절반)" end end
  return ""
end
function B.bhas(u, k) B.__expe_cov.calls["30-engine.lua:41"]=true;  return u.bf ~= nil and u.bf[k] ~= nil end
function B.btick(u) B.__expe_cov.calls["30-engine.lua:42"]=true; 
  if not u.bf then B.__expe_cov.branches["30-engine.lua:43:2001"]=true;  return end
  for k, b in pairs(u.bf) do B.__expe_cov.branches["30-engine.lua:44:2043"]=true; 
    if b.f then B.__expe_cov.branches["30-engine.lua:45:2057"]=true; 
      b.f = nil
    else B.__expe_cov.branches["30-engine.lua:47:2082"]=true; 
      b.n = b.n - 1
      if b.n <= 0 then B.__expe_cov.branches["30-engine.lua:49:2125"]=true;  u.bf[k] = nil end
    end
  end
end
function B.has_debuff(u) B.__expe_cov.calls["30-engine.lua:53"]=true;  return B.bhas(u, "adn") or B.bhas(u, "ddn") or (u.dot and #u.dot > 0) or (u.fx or 0) > 0 end

-- ---------- 특성 훅 ----------
-- B.TR[cid] = { 사건 = function(st, owner, ...) }. owner = 그 특성을 가진 동료의 자리. 살아 있는 아군의 특성만 돈다.
-- 사건 목록(값을 고치는 사건은 고친 값을 돌려준다 — 안 고치면 받은 값 그대로):
--   start(st, o)                             전투 시작
--   deal(st, o, a, t, m, tags, opt) → m       아군 a 가 적 t 에게 주는 피해(치명 전)
--   take(st, o, t, dmg, src) → dmg            아군 t 가 받는 피해(보호막 전)
--   save(st, o, t, at) → true|nil             아군 t 가 쓰러질 일격 — true 면 엔진은 쓰러뜨리지 않는다(HP 는 훅이 정한다)
--   hit_after(st, o, a, t, res, opt, at)      아군 a 의 공격 하나가 끝난 뒤(res.kill 등)
--   hp_cost(st, o, t, c, at)                 아군 t 가 스킬 값으로 HP c 를 스스로 깎았다(피격이 아니라 damaged 는 안 난다)
--   abyss_mul(st, o, a, t, amt) → amt         아군 a 의 심연 깎기 양
--   abyss_after(st, o, a, t, amt, at, list)   심연 깎기 뒤(list 에 {i, n} 을 더하면 화면에 같이 보인다)
--   turn_end(st, o, i)                        아무 아군 i 의 차례 끝(행동 뒤)
--   round(st, o)                              라운드 경계
--   evade(st, o, _, t, e) → true|nil          적 e 의 공격이 아군 t 를 빗나가게 할지(빗나가면 엔진은 피해를 주지 않는다 · 셋째 인자는 쓰지 않는다)
--   damaged(st, o, t, dmg, src, at)           아군 t 가 피해를 입은 뒤(HP 반영 뒤 · 쓰러졌으면 st.u[t].al == 0)
--   enemy_end(st, o, e)                       적 e 의 차례 끝(행동·예고 뒤)
--   enemy_dead(st, o, t)                      적 t 가 쓰러짐
--   attacked(st, o, t, e, res, at)           적 e 의 공격이 아군 t 에게 들어갔다(피하지 않았고 t 는 살아 있다 · res = B.strike 결과)
--   ally_down(st, o, t)                      아군 t 가 부상으로 이탈했다(시너지 다시 셈)
-- 🔴 전역 훅 B.GH[사건] (34-traits.lua — 종족·국가 시너지 · 직업 패시브): 위 사건과 같은 인자에서 owner 만 뺀 꼴로 「한 번만」 불린다.
--    사람 훅(B.TR)이 다 돈 뒤에 불리고, 값을 돌려주는 사건은 같은 규칙으로 이어 받는다. B.GH 가 비어 있으면 아무 일도 없다.
B.GH = B.GH or {}
function B.fire(st, ev, ...) B.__expe_cov.calls["30-engine.lua:77"]=true; 
  for o = 1, 4 do B.__expe_cov.branches["30-engine.lua:78:3945"]=true; 
    local d = B.DEF[o]
    local tr = d and B.TR[d.cid]
    if tr and tr[ev] and st.u[o].al == 1 then B.__expe_cov.branches["30-engine.lua:81:4045"]=true;  tr[ev](st, o, ...) end
  end
  local g = B.GH[ev]
  if g then B.__expe_cov.branches["30-engine.lua:84:4107"]=true;  g(st, ...) end
end
function B.chain(st, ev, v, ...) B.__expe_cov.calls["30-engine.lua:86"]=true; 
  for o = 1, 4 do B.__expe_cov.branches["30-engine.lua:87:4179"]=true; 
    local d = B.DEF[o]
    local tr = d and B.TR[d.cid]
    if tr and tr[ev] and st.u[o].al == 1 then B.__expe_cov.branches["30-engine.lua:90:4279"]=true; 
      local sk = B.SKON
      B.SKON = nil   -- 특성 훅이 하는 회복·버프는 스킬 몫이 아니다(장비 회복·버프 보너스 제외 — 81-gear)
      local r = tr[ev](st, o, v, ...)
      B.SKON = sk
      if r ~= nil then B.__expe_cov.branches["30-engine.lua:95:4459"]=true;  v = r end
    end
  end
  local g = B.GH[ev]
  if g then B.__expe_cov.branches["30-engine.lua:99:4516"]=true; 
    local r = g(st, v, ...)
    if r ~= nil then B.__expe_cov.branches["30-engine.lua:101:4565"]=true;  v = r end
  end
  return v
end
-- 값 앞에 다른 인자가 오는 사건(deal · take · abyss_mul)용
function B.chain_at(st, ev, pos, args) B.__expe_cov.calls["30-engine.lua:106"]=true; 
  for o = 1, 4 do B.__expe_cov.branches["30-engine.lua:107:4702"]=true; 
    local d = B.DEF[o]
    local tr = d and B.TR[d.cid]
    if tr and tr[ev] and st.u[o].al == 1 then B.__expe_cov.branches["30-engine.lua:110:4802"]=true; 
      local sk = B.SKON
      B.SKON = nil
      local r = tr[ev](st, o, table.unpack(args))
      B.SKON = sk
      if r ~= nil then B.__expe_cov.branches["30-engine.lua:115:4936"]=true;  args[pos] = r end
    end
  end
  local g = B.GH[ev]
  if g then B.__expe_cov.branches["30-engine.lua:119:5001"]=true; 
    local r = g(st, table.unpack(args))
    if r ~= nil then B.__expe_cov.branches["30-engine.lua:121:5062"]=true;  args[pos] = r end
  end
  return args[pos]
end
-- 지금 속도(행동 순서표가 읽는다): 기본 속도 × 전역 훅 speed(종족·국가 시너지 · 직업 패시브). 소수 둘째 자리까지.
function B.spd(st, i) B.__expe_cov.calls["30-engine.lua:126"]=true; 
  local u = st.u[i]
  local g = B.GH.speed
  local m = 1
  if g then B.__expe_cov.branches["30-engine.lua:130:5275"]=true;  m = g(st, i) or 1 end
  -- 속도 강화·약화(bf spd / sdn — 적의 약화 행동 · 태엽 감기 …) · 체력이 줄면 빨라지는 적(rules.hp_spd)
  local bs = B.bget(u, "spd") - B.bget(u, "sdn")
  if bs ~= 0 then B.__expe_cov.branches["30-engine.lua:133:5443"]=true;  m = m * (1 + bs) end
  if i > 4 and st.fl then B.__expe_cov.branches["30-engine.lua:134:5490"]=true; 
    local R = B.DEF[i].rules
    if R and R.hp_spd and u.hp <= u.mhp * R.hp_spd.thr then B.__expe_cov.branches["30-engine.lua:136:5579"]=true;  m = m * (1 + R.hp_spd.amount) end
  end
  if m < 0.3 then B.__expe_cov.branches["30-engine.lua:138:5637"]=true;  m = 0.3 end
  if m == 1 then B.__expe_cov.branches["30-engine.lua:139:5666"]=true;  return u.sp end
  return math.floor(u.sp * m * 100 + 0.5) / 100
end
function B.trait_line(st, o, txt, at, ab) B.__expe_cov.calls["30-engine.lua:142"]=true; 
  B.push(st, { k = "trait", a = o, t = at or st.ev.T, nm = txt, ab = ab })
end

function B.pick_target(st, i) B.__expe_cov.calls["30-engine.lua:146"]=true; 
  local d = B.DEF[i]
  local act = d.acts[st.u[i].ia]
  local K = act.kind
  if K == "buff" or K == "guard" or K == "heal" or K == "summon" or K == "protect" or K == "charge" then B.__expe_cov.branches["30-engine.lua:150:6066"]=true;  return i end
  local list = {}
  for a = 1, 4 do B.__expe_cov.branches["30-engine.lua:152:6117"]=true;  if st.u[a].al == 1 then B.__expe_cov.branches["30-engine.lua:152:6139"]=true;  list[#list + 1] = a end end
  if #list == 0 then B.__expe_cov.branches["30-engine.lua:153:6188"]=true;  return 1 end
  if act.low then B.__expe_cov.branches["30-engine.lua:154:6219"]=true; 
    local best, br = list[1], 2
    for _, a in ipairs(list) do B.__expe_cov.branches["30-engine.lua:156:6285"]=true; 
      local r = st.u[a].hp / st.u[a].mhp
      if r < br then B.__expe_cov.branches["30-engine.lua:158:6345"]=true;  best, br = a, r end
    end
    return best
  end
  local k = B.floor(B.rnd(st) * #list) + 1
  if k > #list then B.__expe_cov.branches["30-engine.lua:163:6458"]=true;  k = #list end
  return list[k]
end

-- 처음 적 수(빈 자리 없는 4)
function B.enemy0(st) B.__expe_cov.calls["30-engine.lua:168"]=true;  return st.foe and #st.foe or 4 end

-- ---------- 행동 순서표 ----------
-- 라운드 틱: 시너지(계열 2명) · 특성(round)
function B.round_tick(st) B.__expe_cov.calls["30-engine.lua:172"]=true; 
  for _, s in ipairs(B.syn(st)) do B.__expe_cov.branches["30-engine.lua:173:6701"]=true; 
    if s.t == "지능" then B.__expe_cov.branches["30-engine.lua:174:6723"]=true; 
      for i = 1, 4 do B.__expe_cov.branches["30-engine.lua:175:6747"]=true; 
        local u = st.u[i]
        if u.al == 1 and B.DEF[i].line == "지능" and u.mp < u.mmp then B.__expe_cov.branches["30-engine.lua:177:6840"]=true; 
          local v = u.mp + 4
          if v > u.mmp then B.__expe_cov.branches["30-engine.lua:179:6897"]=true;  v = u.mmp end
          B.setf(st, i, "mp", v, st.ev and st.ev.T or 0)
        end
      end
    end
  end
  if st.ev then B.__expe_cov.branches["30-engine.lua:185:7020"]=true;  B.fire(st, "round") end
end

function B.advance(st) B.__expe_cov.calls["30-engine.lua:188"]=true; 
  local best, bt
  local sp = {}
  local nu = #st.u
  for i = 1, nu do B.__expe_cov.branches["30-engine.lua:192:7145"]=true;  sp[i] = B.spd(st, i) end
  for i = 1, nu do B.__expe_cov.branches["30-engine.lua:193:7189"]=true; 
    local u = st.u[i]
    if u.al == 1 then B.__expe_cov.branches["30-engine.lua:195:7231"]=true; 
      local g = u.g
      if g < 0 then B.__expe_cov.branches["30-engine.lua:197:7271"]=true;  g = 0 end
      local t = math.ceil(g / sp[i])
      if bt == nil or t < bt then B.__expe_cov.branches["30-engine.lua:199:7352"]=true;  best, bt = i, t end
    end
  end
  for i = 1, nu do B.__expe_cov.branches["30-engine.lua:202:7407"]=true; 
    local u = st.u[i]
    if u.al == 1 then B.__expe_cov.branches["30-engine.lua:204:7449"]=true;  u.g = u.g - bt * sp[i] end
  end
  st.tk = st.tk + bt
  while st.rd < B.floor(st.tk / B.ROUND) do B.__expe_cov.branches["30-engine.lua:207:7549"]=true; 
    st.rd = st.rd + 1
    B.round_tick(st)
  end
  st.cur = best
  return best
end

-- 다음 n 차례(현재 차례 포함)를 사본에서 미리 계산한다.
function B.preview(st, n) B.__expe_cov.calls["30-engine.lua:216"]=true; 
  local g, sp, al = {}, {}, {}
  local nu = #st.u
  for i = 1, nu do B.__expe_cov.branches["30-engine.lua:219:7764"]=true; 
    local u = st.u[i]
    g[i], sp[i], al[i] = u.g, B.spd(st, i), (u.al == 1)
  end
  local out = {}
  if st.cur > 0 and al[st.cur] then B.__expe_cov.branches["30-engine.lua:224:7899"]=true; 
    out[1] = st.cur
    g[st.cur] = g[st.cur] + 10000
  end
  local guard = 0
  while #out < n and guard < 60 do B.__expe_cov.branches["30-engine.lua:229:8014"]=true; 
    guard = guard + 1
    local best, bt
    for i = 1, nu do B.__expe_cov.branches["30-engine.lua:232:8076"]=true; 
      if al[i] then B.__expe_cov.branches["30-engine.lua:233:8094"]=true; 
        local x = g[i]
        if x < 0 then B.__expe_cov.branches["30-engine.lua:235:8139"]=true;  x = 0 end
        local t = math.ceil(x / sp[i])
        if bt == nil or t < bt then B.__expe_cov.branches["30-engine.lua:237:8224"]=true;  best, bt = i, t end
      end
    end
    if best == nil then B.__expe_cov.branches["30-engine.lua:240:8286"]=true;  break end
    for i = 1, nu do B.__expe_cov.branches["30-engine.lua:241:8319"]=true;  if al[i] then B.__expe_cov.branches["30-engine.lua:241:8331"]=true;  g[i] = g[i] - bt * sp[i] end end
    out[#out + 1] = best
    g[best] = g[best] + 10000
  end
  return out
end

function B.begin_turn(st, i) B.__expe_cov.calls["30-engine.lua:248"]=true; 
  local u = st.u[i]
  -- 도발 지속(사장님 10-10): 도발한 사람 자신의 차례가 올 때마다(그 차례 행동 전에) 1씩 준다. 건 차례에는 줄지 않으니
  -- 「n턴」 = 건 뒤 자기 차례 n−1번까지 적의 모든 행동을 끌어온다. 0 이 된 차례(= 만료로 보이는 차례)에 다시 걸면 틈이 없다.
  if u.tau > 0 then B.__expe_cov.branches["30-engine.lua:252:8671"]=true;  u.tau = u.tau - 1 end
  u.df = B.bhas(u, "g2") and 1 or 0
  if i <= 4 then B.__expe_cov.branches["30-engine.lua:254:8746"]=true; 
    local nmp = u.mp + (B.FM.mp_regen or 5)
    if nmp > u.mmp then B.__expe_cov.branches["30-engine.lua:256:8814"]=true;  nmp = u.mmp end
    if nmp ~= u.mp then B.__expe_cov.branches["30-engine.lua:257:8854"]=true;  B.setf(st, i, "mp", nmp, st.ev.T) end
    if u.gq or u.gu then B.__expe_cov.branches["30-engine.lua:258:8917"]=true;  B.gear_begin(st, i) end   -- 장비: 차례마다 MP 회복 · 도발 중 HP 회복(81-gear)
  end
end

function B.end_turn(st, i, cost) B.__expe_cov.calls["30-engine.lua:262"]=true; 
  local u = st.u[i]
  if u.oT > 0 then B.__expe_cov.branches["30-engine.lua:264:9066"]=true; 
    u.oT = u.oT - 1
    if u.oT == 0 then B.__expe_cov.branches["30-engine.lua:266:9108"]=true;  u.oath = 0 end
  end
  if u.bt > 0 then B.__expe_cov.branches["30-engine.lua:268:9148"]=true; 
    u.bt = u.bt - 1
    if u.bt == 0 then B.__expe_cov.branches["30-engine.lua:270:9190"]=true;  u.am = 1 end
  end
  if u.shT > 0 then B.__expe_cov.branches["30-engine.lua:272:9229"]=true; 
    u.shT = u.shT - 1
    if u.shT == 0 and u.sh > 0 then B.__expe_cov.branches["30-engine.lua:274:9287"]=true;  B.setf(st, i, "sh", 0, st.ev.T) end
  end
  B.btick(u)
  if u.sil and u.sil ~= "" then B.__expe_cov.branches["30-engine.lua:277:9374"]=true;  u.sil = "" end   -- 침묵(적 특수 행동)은 한 차례
  u.g = u.g + (cost or 10000)
  if i <= 4 then B.__expe_cov.branches["30-engine.lua:279:9459"]=true;  B.fire(st, "turn_end", i) else B.__expe_cov.branches["30-engine.lua:279:9490"]=true;  B.fire(st, "enemy_end", i) end
end

-- ---------- 판정 ----------
-- 아군이 때리는 피해. 난수는 치명타 한 번만 쓴다(항상 소비 — 결정론).
function B.hit(st, a, t, o) B.__expe_cov.calls["30-engine.lua:284"]=true; 
  local u, v = st.u[a], st.u[t]
  local d = B.DEF[a]
  local Kc = st.K or B.K_of(st.el or 40)
  local de = v.de * (1 + B.bget(v, "def") - B.bget(v, "ddn"))
  local dc = Kc / (Kc + de)
  local tags = {}
  local b = 1
  if (v.fx or 0) > 0 then B.__expe_cov.branches["30-engine.lua:292:9869"]=true; 
    b = b + v.fb
     tags[#tags + 1] = B.U("여우불 ×{n}", { n = string.format("%.1f", 1 + v.fb) })
  end
  local m = u.cs * 2 * o.m * dc * b * (1 + B.bget(u, "atk") - B.bget(u, "adn"))
  if o.ps_bane and B.has_debuff(v) then B.__expe_cov.branches["30-engine.lua:297:10092"]=true;  m = m * (1 + o.ps_bane); tags[#tags + 1] = B.U("약화 추가 피해") end
  if isweak(t, o.el) then B.__expe_cov.branches["30-engine.lua:298:10181"]=true; 
    m = m * 1.3
     tags[#tags + 1] = B.U("약점 ×1.3")
  end
  if v.dr == 1 then B.__expe_cov.branches["30-engine.lua:302:10261"]=true; 
    if d.clsid == "chaos" then B.__expe_cov.branches["30-engine.lua:303:10292"]=true; 
      m = m * 2.5
       tags[#tags + 1] = B.U("고갈 공명 ×2.5")
    else B.__expe_cov.branches["30-engine.lua:306:10362"]=true; 
      m = m * 1.5
       tags[#tags + 1] = B.U("고갈 ×1.5")
    end
  end
  if t >= 5 and st.fl then B.__expe_cov.branches["30-engine.lua:311:10461"]=true;  m = m * B.foe_defense(st, a, t, o, tags) end   -- 적 규칙: 조교 보호 · 비행 · 은신(31-foes)
  m = B.chain_at(st, "deal", 3, { a, t, m, tags, o })
  local roll = B.rnd(st)
  local marked = (v.mk == 1) or B.bhas(u, "bs") or (o.force == true)
  local chance = o.cc or (u.cr + u.ag / 20 + (B.bhas(u, "bl") and 30 or 0))
  chance = chance + B.bget(u, "pscrit") * 100
  if B.GH.crit then B.__expe_cov.branches["30-engine.lua:317:10832"]=true;  chance = chance + (B.GH.crit(st, a, t, o) or 0) end   -- 직업 패시브(검투사) · 종족(고양이과 기습)
  local crit = marked or (roll * 100 < chance)
  local cm = (o.cm or 1.5) + (B.bhas(u, "bl") and 0.5 or 0) + (u.gq and u.gq.critdmg and u.gq.critdmg / 100 or 0)   -- 장비 치명타 피해(81-gear)
  if crit then B.__expe_cov.branches["30-engine.lua:320:11115"]=true; 
    m = m * cm
     tags[#tags + 1] = B.U("{certain}치명 ×{n}", { certain = marked and B.U("확정 ") or "", n = string.format("%.1f", cm) })
  end
  local raw = B.floor(m)
  if raw < 1 then B.__expe_cov.branches["30-engine.lua:325:11300"]=true;  raw = 1 end
  return raw, crit, tags, marked
end

-- 방어자 보정 + 보호막 + HP. 쓰러지면 al=0.
function B.strike(st, t, raw, at, mul, src) B.__expe_cov.calls["30-engine.lua:330"]=true; 
  local u = st.u[t]
  local dmg = raw
  if u.df == 1 and src ~= "fixed" then B.__expe_cov.branches["30-engine.lua:333:11504"]=true;  dmg = B.floor(dmg * 0.6) end   -- src "fixed" = 고정 피해(방어 자세를 받지 않는다)
  if mul then B.__expe_cov.branches["30-engine.lua:334:11587"]=true;  dmg = B.floor(dmg * mul) end
  if t <= 4 then B.__expe_cov.branches["30-engine.lua:335:11633"]=true;  dmg = B.floor(B.chain_at(st, "take", 2, { t, dmg, src }) + 0.5) end
  if t <= 4 and B.bget(u, "psguard") > 0 then B.__expe_cov.branches["30-engine.lua:336:11747"]=true;  dmg = B.floor(dmg * (1 - B.bget(u, "psguard")) + 0.5) end
  if dmg < 1 then B.__expe_cov.branches["30-engine.lua:337:11823"]=true;  dmg = 1 end
  local ab = 0
  if u.sh > 0 then B.__expe_cov.branches["30-engine.lua:339:11869"]=true; 
    ab = (u.sh < dmg) and u.sh or dmg
    B.setf(st, t, "sh", u.sh - ab, at)
    if u.sh == 0 then B.__expe_cov.branches["30-engine.lua:342:11968"]=true;  u.shT = 0 end
    if u.sh == 0 and t <= 4 and (u.gu or st.gk) then B.__expe_cov.branches["30-engine.lua:343:12035"]=true;  B.gear_shbreak(st, t, ab, src) end   -- 장비 가시 방벽 · 은총의 반향: 깨진 양을 적어 둔다(81-gear)
  end
  local nh = u.hp - (dmg - ab)
  local ls = 0
  if nh <= 0 and t >= 5 and st.fl and u.ph == 1 and B.DEF[t].ph2 then B.__expe_cov.branches["30-engine.lua:347:12237"]=true;    -- 2단계가 있는 보스는 1단계에서 쓰러지지 않는다: 문턱 바로 아래에서 버티고 2단계로(검수 7차 #1)
    local cap = math.max(1, B.floor(u.mhp * B.BOSSR.phase_hp) - 1)
    if u.hp > cap then B.__expe_cov.branches["30-engine.lua:349:12390"]=true; 
      B.say(st, "<b>" .. nm(t) .. "</b> 쓰러지기 직전에 <em>버텼다</em>! 2단계로 넘어간다", at + 0.1)
      nh = cap
    else B.__expe_cov.branches["30-engine.lua:352:12499"]=true; 
      nh = math.max(1, u.hp)   -- 이미 문턱 아래(전환 직전): 같은 행동의 남은 타격이 더 깎지 못한다
    end
  end
  if nh <= 0 and t <= 4 then B.__expe_cov.branches["30-engine.lua:356:12616"]=true; 
    B.setf(st, t, "hp", 0, at)
    for o = 1, 4 do B.__expe_cov.branches["30-engine.lua:358:12669"]=true; 
      local tr = B.TR[B.DEF[o].cid]
      if tr and tr.save and (st.u[o].al == 1) and tr.save(st, o, t, at) then B.__expe_cov.branches["30-engine.lua:360:12780"]=true;  ls = 1; break end
    end
    if ls == 0 and u.gu then B.__expe_cov.branches["30-engine.lua:362:12835"]=true;  ls = B.gear_save(st, t, at) end   -- 장비 「마지막 성벽」: 전투당 한 번 버틴다(81-gear)
    -- 사제 직업 패시브 「이탈 방지」: 사제가 살아 있으면 파티원마다 전투당 1회, 최대 HP 50% 로 버틴다(CLASSES.md 열린 질문 5 [제안] · 검수 4차 #4)
    -- 측정용 스위치 B.VAR(34-traits): priest_cap = 전투당 파티 전체 발동 상한(0 = 파티원마다 1회, 상한 없음 — 지금 값) · priest_heal = 붙들 때 HP 비율
    local VR = B.VAR or { priest_cap = 0, priest_heal = 0.5 }
    if ls == 0 and (u.ps or 0) == 0 and (VR.priest_cap == 0 or (st.pk or 0) < VR.priest_cap) then B.__expe_cov.branches["30-engine.lua:366:13286"]=true; 
      for o = 1, 4 do B.__expe_cov.branches["30-engine.lua:367:13310"]=true; 
        if B.DEF[o].clsid == "priest" and st.u[o].al == 1 then B.__expe_cov.branches["30-engine.lua:368:13371"]=true;    -- 사제 자신도 지킨다(사장님 10-10)
          local mr = st.u[o].gu and B.gear_uq(st.u[o], "pr_miracle")   -- 장비 「두 번째 기적」: 더 높은 HP · 보호막(81-gear)
          local ph = mr and mr.v[1] / 100 or VR.priest_heal
          u.ps = 1
          st.pk = (st.pk or 0) + 1
          ls = 1
          B.setf(st, t, "hp", B.floor(u.mhp * ph + 0.5), at)
          if mr then B.__expe_cov.branches["30-engine.lua:375:13722"]=true; 
            B.setf(st, t, "sh", math.max(u.sh, B.floor(u.mhp * mr.v[2] / 100)), at + 0.1)
            u.shT = 3
          end
          B.say(st, "<b>" .. B.DEF[o].name .. "</b>의 기도가 " .. B.p(B.DEF[t].name, "을를") .. " 붙들었다. <em>HP " .. B.floor(ph * 100 + 0.5) .. "%</em>로 버틴다", at)
          break
        end
      end
    end
    if ls == 1 then B.__expe_cov.branches["30-engine.lua:384:14070"]=true;  nh = st.u[t].hp end
  end
  if nh < 0 then B.__expe_cov.branches["30-engine.lua:386:14113"]=true;  nh = 0 end
  if ls == 0 then B.__expe_cov.branches["30-engine.lua:387:14142"]=true;  B.setf(st, t, "hp", nh, at) end
  local kill = false
  if nh <= 0 then B.__expe_cov.branches["30-engine.lua:389:14213"]=true; 
    kill = true
    u.al = 0
    if t <= 4 then B.__expe_cov.branches["30-engine.lua:392:14261"]=true; 
      B.fire(st, "ally_down", t)
      u.tau, u.chg, u.oath, u.oT = 0, 0, 0, 0
      if u.sh > 0 then B.__expe_cov.branches["30-engine.lua:395:14363"]=true;  B.setf(st, t, "sh", 0, at) end
      -- 쓰러진 사람이 건 버프(bf[k].src == t)는 함께 사라진다(검수 5차 #11 — 특성 훅이 아니라 엔진이 지운다)
      B.drop_src(st, t, false)
    else B.__expe_cov.branches["30-engine.lua:398:14512"]=true; 
      B.drop_src(st, t, true)   -- 쓰러진 적이 건 깃발·오라도 함께 사라진다
      u.pt, u.cq = 0, 0
    end
  end
  if st.u[t].mk == 1 then B.__expe_cov.branches["30-engine.lua:403:14635"]=true;  st.u[t].mk = 0 end
  if kill and t >= 5 then B.__expe_cov.branches["30-engine.lua:404:14680"]=true;  B.fire(st, "enemy_dead", t) end
  if t <= 4 and (dmg - ab) > 0 then B.__expe_cov.branches["30-engine.lua:405:14748"]=true;  B.fire(st, "damaged", t, dmg - ab, src, at) end
  if st.gb then B.__expe_cov.branches["30-engine.lua:406:14812"]=true;  B.gear_pecho(st, t, at) end   -- 장비 「은총의 반향」: 깨진 보호막 회복(81-gear)
  return { i = t, d = dmg, sh = ab, kill = kill and 1 or 0, c = 0, ls = ls }
end

-- 쓰러진(또는 고갈된) 자리가 건 버프를 모두 지운다. aura_only = 「쓰러지거나 고갈될 때까지」 오라(b.au)만
function B.drop_src(st, t, aura_only) B.__expe_cov.calls["30-engine.lua:411"]=true; 
  for j = 1, #st.u do B.__expe_cov.branches["30-engine.lua:412:15092"]=true; 
    local w = st.u[j]
    if w and w.bf then B.__expe_cov.branches["30-engine.lua:414:15135"]=true; 
      local gone = {}
      for k, b in pairs(w.bf) do B.__expe_cov.branches["30-engine.lua:416:15192"]=true;  if b.src == t and (not aura_only or b.au) then B.__expe_cov.branches["30-engine.lua:416:15237"]=true;  gone[#gone + 1] = k end end
      for _, k in ipairs(gone) do B.__expe_cov.branches["30-engine.lua:417:15301"]=true;  w.bf[k] = nil end
    end
  end
end

-- 심연 고갈: 다음 차례를 잃고(예고 취소), 그 차례가 지나갈 때까지 받는 피해 ×1.5(심연 마도사 ×2.5)
function B.deplete(st, t, at) B.__expe_cov.calls["30-engine.lua:423"]=true; 
  local v = st.u[t]
  v.dr = 1
  st.nd = st.nd + 1
  if t >= 5 then B.__expe_cov.branches["30-engine.lua:427:15500"]=true;  B.drop_src(st, t, true) end   -- 근위 기수의 깃발은 고갈되면 걷힌다
  B.push(st, { k = "deplete", a = t, t = at })
  B.say(st, B.U("<b>{target}</b> <i>심연 0, 심연 고갈!</i> 다음 차례를 잃고 받는 피해가 커진다", { target = nm(t) }), at + 0.3)
end

-- 심연 깎기. a = 행동자, brk = 스킬의 심연 깎기, mulb = 스킬 쪽 배율(하이 리스크 하이 리턴)
function B.abyss(st, a, t, brk, el, at, mulb) B.__expe_cov.calls["30-engine.lua:433"]=true; 
  local v = st.u[t]
  if brk <= 0 or v.al == 0 or v.dr == 1 then B.__expe_cov.branches["30-engine.lua:435:15888"]=true;  return 0, nil end
  local amt = brk * (mulb or 1)
  if isweak(t, el) then B.__expe_cov.branches["30-engine.lua:437:15962"]=true;  amt = amt * 1.5 end
  amt = B.chain_at(st, "abyss_mul", 3, { a, t, amt })
  amt = B.floor(amt + 0.5)
  if amt < 1 then B.__expe_cov.branches["30-engine.lua:440:16081"]=true;  amt = 1 end
  local nv = v.ay - amt
  if nv < 0 then B.__expe_cov.branches["30-engine.lua:442:16134"]=true;  nv = 0 end
  B.setf(st, t, "ay", nv, at)
  local list = {}
  if nv <= 0 then B.__expe_cov.branches["30-engine.lua:445:16211"]=true;  B.deplete(st, t, at + 0.2) end
  B.fire(st, "abyss_after", a, t, amt, at, list)
  return amt, list
end

-- 종결형 동사(「베었다」)를 연결형(「베어」)으로. 마지막 글자의 받침 ㅆ 을 떼고 「다」를 지운다. 못 바꾸면 nil.
function B.vconn(vb) B.__expe_cov.calls["30-engine.lua:451"]=true; 
  vb = tostring(vb or "")
  if vb:sub(-3) ~= "다" then B.__expe_cov.branches["30-engine.lua:453:16460"]=true;  return nil end
  local body = vb:sub(1, -4)
  local n = utf8.len(body)
  if not n or n == 0 then B.__expe_cov.branches["30-engine.lua:456:16557"]=true;  return nil end
  local lastp = utf8.offset(body, n)
  local cp = utf8.codepoint(body, lastp)
  if cp < 0xAC00 or cp > 0xD7A3 or (cp - 0xAC00) % 28 ~= 20 then B.__expe_cov.branches["30-engine.lua:459:16715"]=true;  return nil end
  local head = body:sub(1, lastp - 1)
  if cp == 0xBCB4 then B.__expe_cov.branches["30-engine.lua:461:16791"]=true;  return head .. "베어" end   -- 벴 → 베어
  return head .. utf8.char(cp - 20)
end

-- 피해 한 줄: 「레비아가 고블린을 베어 12 피해를 입혔다(치명). 고블린이 쓰러졌다」
function B.dmg_line(st, a, res, o) B.__expe_cov.calls["30-engine.lua:466"]=true; 
  local who, tg = nm(a), nm(res.i)
  local sk = o.sk and B.U("{skill:으로} ", { skill = o.sk }) or ""
  local vc = B.vconn(o.vb)
  local s
  if vc then B.__expe_cov.branches["30-engine.lua:471:17105"]=true; 
    if o.vb:find("을 ", 1, true) or o.vb:find("를 ", 1, true) then B.__expe_cov.branches["30-engine.lua:472:17170"]=true;    -- 동사 쪽에 목적어가 있으면 표적은 「에게」로
      s = B.U("<b>{who}</b>{particle} {skill}{verb} {target}에게 <em>{damage}</em> 피해를 입혔다", { who = who, particle = B.josa(who, "이가"), skill = sk, verb = vc, target = tg, damage = res.d })
    else B.__expe_cov.branches["30-engine.lua:474:17397"]=true; 
      s = B.U("<b>{who}</b>{particle} {skill}{target:을를} {verb} <em>{damage}</em> 피해를 입혔다", { who = who, particle = B.josa(who, "이가"), skill = sk, target = tg, verb = vc, damage = res.d })
    end
  else B.__expe_cov.branches["30-engine.lua:477:17601"]=true; 
    s = B.U("<b>{who}</b>{particle} {skill}{target:을를} {verb}. <em>{damage}</em> 피해를 입혔다", { who = who, particle = B.josa(who, "이가"), skill = sk, target = tg, verb = o.vb, damage = res.d })
  end
  local ex = {}
  for _, x in ipairs(res.tags or {}) do B.__expe_cov.branches["30-engine.lua:481:17855"]=true;  ex[#ex + 1] = x end
  if res.sh > 0 then B.__expe_cov.branches["30-engine.lua:482:17894"]=true;  ex[#ex + 1] = B.U("보호막 {n} 흡수", { n = res.sh }) end
  if #ex > 0 then B.__expe_cov.branches["30-engine.lua:483:17964"]=true;  s = s .. "(" .. table.concat(ex, ", ") .. ")" end
  if (res.ab or 0) > 0 then B.__expe_cov.branches["30-engine.lua:484:18042"]=true;  s = s .. B.U(". {target}의 <i>심연 −{n}</i>", { target = tg, n = res.ab }) end
  if res.kill == 1 then B.__expe_cov.branches["30-engine.lua:485:18142"]=true; 
    s = s .. B.U(res.i >= 5 and ". <b>{target}</b>{particle} 쓰러졌다" or ". <b>{target}</b>{particle} 부상으로 물러났다", { target = tg, particle = B.josa(tg, "이가") })
  end
  return s
end

-- ---------- 아군 행동 ----------
-- 단일 표적 공격
function B.attack(st, a, t, o) B.__expe_cov.calls["30-engine.lua:493"]=true; 
  local ev = st.ev
  local T = ev.T
  local hitT = T + (o.hit or 0.4)
  o.el = o.el or B.DEF[a].el
  local t0 = t
  if st.fl and t >= 5 then B.__expe_cov.branches["30-engine.lua:499:18536"]=true;  t = B.protector_of(st, t) end   -- 보호 중인 적이 대신 맞는다(31-foes)
  local raw, crit, tags = B.hit(st, a, t, o)
  if t ~= t0 then B.__expe_cov.branches["30-engine.lua:501:18659"]=true;  tags[#tags + 1] = nm(t0) .. " 대신 맞음" end
  local res = B.strike(st, t, raw, hitT)
  res.c = crit and 1 or 0
  res.tags = tags
  res.ab, res.list = 0, nil
  if res.kill == 1 then B.__expe_cov.branches["30-engine.lua:506:18837"]=true; 
     st.kill = B.U("{name}의 {skill}", { name = B.DEF[a].full, skill = o.name })
  else B.__expe_cov.branches["30-engine.lua:508:18924"]=true; 
    res.ab, res.list = B.abyss(st, a, t, o.brk or 0, o.el, hitT + 0.1, o.mulb)
  end
  B.push(st, { k = o.k or "atk", a = a, t = T, ht = hitT, tg = { res }, nm = o.name, el = o.el, big = o.big })
  B.say(st, B.dmg_line(st, a, res, { sk = o.sk, vb = o.vb }), hitT + 0.1)
  ev.T = T + (o.dur or 1.3)
  B.fire(st, "hit_after", a, t, res, o, hitT)
  if st.fl and t >= 5 then B.__expe_cov.branches["30-engine.lua:515:19295"]=true;  B.foe_hit_after(st, a, t, res, o, hitT) end   -- 되치기 · 번짐(31-foes)
  if B.GH.extra_hit then B.__expe_cov.branches["30-engine.lua:516:19387"]=true;  B.GH.extra_hit(st, a, t, o, res, hitT) end   -- 암살자 추가 공격(34-traits)
  return res
end

-- 적 전체 공격(혼돈 파동 · 마력 폭발 · 파괴적 마법)
function B.volley(st, a, o) B.__expe_cov.calls["30-engine.lua:521"]=true; 
  local ev = st.ev
  local T = ev.T
  o.el = o.el or B.DEF[a].el
  local tgs = {}
  local n = 0
  for t = 5, #st.u do B.__expe_cov.branches["30-engine.lua:527:19657"]=true; 
    if st.u[t].al == 1 then B.__expe_cov.branches["30-engine.lua:528:19683"]=true; 
      n = n + 1
      local at = T + (o.hit or 0.5) + (n - 1) * 0.07
      local raw, crit, tags = B.hit(st, a, t, o)
      local res = B.strike(st, t, raw, at)
      res.c = crit and 1 or 0
      res.tags = tags
      res.ab, res.list = 0, nil
      if res.kill == 1 then B.__expe_cov.branches["30-engine.lua:536:19956"]=true; 
         st.kill = B.U("{name}의 {skill}", { name = B.DEF[a].full, skill = o.name })
      else B.__expe_cov.branches["30-engine.lua:538:20051"]=true; 
        res.ab, res.list = B.abyss(st, a, t, o.brk or 0, o.el, at + 0.1, o.mulb)
        if o.each then B.__expe_cov.branches["30-engine.lua:540:20155"]=true;  o.each(st, a, t, at) end
      end
      tgs[#tgs + 1] = res
    end
  end
  B.push(st, { k = o.k or "volley", a = a, t = T, ht = T + (o.hit or 0.5), tg = tgs, nm = o.name, el = o.el, seal = o.seal })
  local parts = {}
  for _, r in ipairs(tgs) do B.__expe_cov.branches["30-engine.lua:547:20406"]=true; 
    parts[#parts + 1] = nm(r.i) .. " <em>" .. r.d .. "</em>" ..
      (r.c == 1 and B.U("(치명타)") or "") .. ((r.tags and r.tags[1] and r.tags[1]:find("약점", 1, true)) and B.U("(약점)") or "") ..
      (r.kill == 1 and B.U("(쓰러짐)") or "") .. ((r.ab or 0) > 0 and B.U(" <i>심연 −{n}</i>", { n = r.ab }) or "")
  end
  B.say(st, B.U("<b>{who}</b>{particle} {skill:으로} {action}. {targets}", { who = nm(a), particle = B.josa(nm(a), "이가"), skill = o.name, action = o.line or "적 전체를 휩쓸었다", targets = table.concat(parts, ", ") }), T + (o.hit or 0.5) + 0.2)
  ev.T = T + (o.dur or 2.0)
  for _, r in ipairs(tgs) do B.__expe_cov.branches["30-engine.lua:554:21006"]=true;  B.fire(st, "hit_after", a, r.i, r, o, T + (o.hit or 0.5)) end
end

function B.release(st, a, seal) B.__expe_cov.calls["30-engine.lua:557"]=true; 
  B.volley(st, a, { m = 1.9, name = seal and "마감 전날 대폭발" or "마력 폭발", k = "burst", seal = seal and 1 or 0,
    hit = 2.45, dur = 3.9, line = "적 전체를 휩쓸었다" })
end

-- 아군 전체 보호막(성기사 ×1.2 · 사제 ×1.0)
function B.party_shield(st, i, mult, name) B.__expe_cov.calls["30-engine.lua:563"]=true; 
  local u, T = st.u[i], st.ev.T
  local amt = B.floor(u.cs * 2 * mult)
  if B.GH.shield then B.__expe_cov.branches["30-engine.lua:566:21433"]=true;  amt = B.floor(B.GH.shield(st, i, amt) or amt) end   -- 솔렌 시너지 보호막량 +20%
  local tgs = {}
  for a = 1, 4 do B.__expe_cov.branches["30-engine.lua:568:21542"]=true; 
    if st.u[a].al == 1 then B.__expe_cov.branches["30-engine.lua:569:21568"]=true; 
      local cur = st.u[a].sh
      B.setf(st, a, "sh", (cur > amt) and cur or amt, T + 1.5)
      st.u[a].shT = 3
      tgs[#tgs + 1] = { i = a, d = amt }
    end
  end
  B.push(st, { k = "shield", a = i, t = T, tg = tgs, nm = name })
  B.say(st, "<b>" .. nm(i) .. "</b>" .. B.josa(nm(i), "이가") .. " " .. B.p(name, "을를") .. " 펼쳤다. 아군 전체 보호막 <em>" .. amt .. "</em>", T + 1.6)
  st.ev.T = T + 2.8
end

-- 아군 회복(최대 HP 를 넘지 않는다). 돌려주는 값 = 실제 회복량
function B.heal(st, t, amt, at) B.__expe_cov.calls["30-engine.lua:582"]=true; 
  local v = st.u[t]
  if v.al ~= 1 then B.__expe_cov.branches["30-engine.lua:584:22082"]=true;  return 0 end
  if B.GH.heal then B.__expe_cov.branches["30-engine.lua:585:22115"]=true;  amt = B.GH.heal(st, t, amt) or amt end   -- 인간 시너지 3명 회복량 +10%
  local h = B.floor(amt + 0.5)
  if v.hp + h > v.mhp then B.__expe_cov.branches["30-engine.lua:587:22236"]=true;  h = v.mhp - v.hp end
  if h > 0 then B.__expe_cov.branches["30-engine.lua:588:22273"]=true;  B.setf(st, t, "hp", v.hp + h, at or st.ev.T) end
  return h
end

local function cutin(st, i, id, name) B.__expe_cov.calls["30-engine.lua:592"]=true; 
  local ev = st.ev
  local line = B.CUTLINE[id]
  B.push(st, { k = "cut", a = i, t = ev.T, nm = name, line = line })
  ev.T = ev.T + (line and 1.9 or 1.4)   -- 대사가 없으면 짧게(따옴표만 남지 않게 — 40-fx)
end
B.cutin = cutin

-- ---------- 직업 스킬 처리기 ----------
B.RUN = {}
B.RUN.atk = function(st, i, tgt) B.__expe_cov.calls["30-engine.lua:602"]=true; 
  local a = B.ATK[B.DEF[i].clsid] or B.ATK.warrior
  local o = { m = a.m, brk = a.brk, name = "일반 공격", vb = a.vb, hit = 0.45 }
  if B.DEF[i].cid == "levia" then B.__expe_cov.branches["30-engine.lua:605:22828"]=true;  o.vb = "마력으로 내리쳤다" end
  B.attack(st, i, tgt, o)
end
B.RUN.df = function(st, i) B.__expe_cov.calls["30-engine.lua:608"]=true; 
  local u, T = st.u[i], st.ev.T
  u.df = 1
  B.push(st, { k = "def", a = i, t = T, nm = "방어" })
  B.say(st, "<b>" .. nm(i) .. "</b>" .. B.josa(nm(i), "은는") .. " 방어 태세를 취했다. 이번 차례 받는 피해 -40%", T + 0.3)
  st.ev.T = T + 1.0
end
B.RUN.guard2 = function(st, i) B.__expe_cov.calls["30-engine.lua:615"]=true; 
  local u, T = st.u[i], st.ev.T
  u.df = 1
  B.badd(u, "g2", 1, 2)
  B.push(st, { k = "def", a = i, t = T, nm = "굳건한 방어" })
  B.say(st, "<b>" .. nm(i) .. "</b>" .. B.josa(nm(i), "이가") .. " 굳건히 버틴다. 2턴 동안 받는 피해 -40%", T + 0.3)
  st.ev.T = T + 1.0
end
B.RUN.taunt = function(st, i, tgt) B.__expe_cov.calls["30-engine.lua:623"]=true; 
  local u, T = st.u[i], st.ev.T
  u.tau = 2   -- 「공격 유도 2턴」 — 지속 규칙은 B.begin_turn
  local ab, list = B.abyss(st, i, tgt, 20, B.DEF[i].el, T + 0.9)
  B.push(st, { k = "taunt", a = i, t = T, nm = "도발, 위압", tg = { { i = tgt, ab = ab, list = list } } })
  B.say(st, B.U("<b>{who}</b>의 도발. 적의 공격이 {who}에게 몰린다. 위압을 받은 쪽은 {target}{abyss}", { who = nm(i), target = nm(tgt), abyss = ((ab or 0) > 0 and B.U(" <i>심연 −{n}</i>", { n = ab }) or "") }), T + 0.9)
  st.ev.T = T + 1.9
end
B.RUN.shield = function(st, i) B.__expe_cov.calls["30-engine.lua:631"]=true;  B.party_shield(st, i, 1.2, "파티 보호막") end
B.RUN.pshield = function(st, i) B.__expe_cov.calls["30-engine.lua:632"]=true;  B.party_shield(st, i, 1.0, "파티 보호막") end
B.RUN.snipe = function(st, i, tgt) B.__expe_cov.calls["30-engine.lua:633"]=true; 
  local aw = st.u[i].gu and B.gear_uq(st.u[i], "ar_wind")   -- 장비 「바람 읽기」: 치명 확률(81-gear)
  B.attack(st, i, tgt, { m = 2.0, cc = aw and aw.v[2] or 70, cm = 2.0, brk = 0, name = "일발필살", sk = "일발필살", vb = "꿰뚫었다", k = "snipe", hit = 1.0, dur = 1.9, big = 1 })
end
B.RUN.burst = function(st, i, tgt) B.__expe_cov.calls["30-engine.lua:637"]=true; 
  local u, T = st.u[i], st.ev.T
  u.chg = 1
  local v = st.u[tgt]
  local sw = u.gu and B.gear_uq(u, "sa_warp")   -- 장비 「시간 왜곡」: 지정한 적의 지연(81-gear)
  local dl = (sw and sw.v[2] * 100 or 2500) * B.rdm(v)   -- 실제로 늦춘 시간(보스는 레이드 감소로 절반)
  v.g = v.g + dl
  if sw then B.__expe_cov.branches["30-engine.lua:644:24661"]=true;  B.gear_adv(st, i, dl * sw.v[3] / 100) end   -- 늦춘 시간의 일부를 자신의 다음 차례로(81-gear)
  B.push(st, { k = "chg", a = i, t = T, tg = { { i = tgt } }, nm = "마력 폭발" })
  B.say(st, "<b>" .. nm(i) .. "</b>" .. B.josa(nm(i), "이가") .. " 마력 폭발을 충전한다. " .. nm(tgt) .. "의 차례가 <em>밀렸다</em>", T + 0.9)
  st.ev.T = T + 2.0
  return 20000
end
-- 비공인 마법사 패시브 「지속 피해 중첩」: 이 직업이 거는 지속 피해(k = 1)는 적마다 한도(기본 5 · 모르가스 시너지 3명 +1)까지 쌓인다.
-- 한도를 넘으면 가장 오래된 직업 줄부터 빠진다. 다른 사람의 지속 피해 줄(부식 · 출혈)은 건드리지 않는다.
function B.dot_push(st, v, d, n, by) B.__expe_cov.calls["30-engine.lua:652"]=true; 
  local bu
  if by and st.u[by] and (st.u[by].gq or st.u[by].gu) then B.__expe_cov.branches["30-engine.lua:654:25240"]=true;  d, bu = B.gear_dot(st, by, d) end   -- 장비 지속 피해 % · 독 폭발(81-gear)
  v.dot = v.dot or {}
  local cap = (B.GH.dotcap and B.GH.dotcap(st)) or 5
  local c = 0
  for _, x in ipairs(v.dot) do B.__expe_cov.branches["30-engine.lua:658:25428"]=true;  if x.k == 1 then B.__expe_cov.branches["30-engine.lua:658:25443"]=true;  c = c + 1 end end
  while c >= cap do B.__expe_cov.branches["30-engine.lua:659:25483"]=true; 
    for k, x in ipairs(v.dot) do B.__expe_cov.branches["30-engine.lua:660:25516"]=true; 
      if x.k == 1 then B.__expe_cov.branches["30-engine.lua:661:25537"]=true;  table.remove(v.dot, k); c = c - 1; break end
    end
  end
  v.dot[#v.dot + 1] = { d = d, n = n, k = 1, by = by, bu = bu, n0 = bu and n or nil }
  if by and st.u[by] and st.u[by].gu then B.__expe_cov.branches["30-engine.lua:665:25724"]=true;  B.gear_dotchain(st, v, by) end   -- 장비 「연쇄 폭발」(81-gear)
end
B.RUN.ruin = function(st, i) B.__expe_cov.calls["30-engine.lua:667"]=true; 
  local u = st.u[i]
  local per = B.floor(u.cs * 2 * 0.5)
  B.volley(st, i, { m = 0.6, brk = 0, name = "파괴적 마법", k = "wave", hit = 0.6, dur = 2.0, line = "적 전체를 불태웠다",
    each = function(st2, a, t) B.__expe_cov.calls["30-engine.lua:671"]=true; 
      local v = st2.u[t]
      B.dot_push(st2, v, per, 3, i)
      B.badd(v, "adn", 0.15, 3)
    end })
end
B.RUN.bless = function(st, i) B.__expe_cov.calls["30-engine.lua:677"]=true; 
  local T = st.ev.T
  for a = 1, 4 do B.__expe_cov.branches["30-engine.lua:679:26190"]=true; 
    if st.u[a].al == 1 then B.__expe_cov.branches["30-engine.lua:680:26216"]=true;  B.badd(st.u[a], "atk", 0.15, 3); B.badd(st.u[a], "def", 0.15, 3) end
  end
  B.push(st, { k = "shield", a = i, t = T, tg = {}, nm = "파티 능력치 상향" })
  local bv = B.bget(st.u[i], "atk")   -- 실제로 걸린 수치(「넓은 축복」 등 반영)
  B.say(st, "<b>" .. nm(i) .. "</b>의 축복. 아군 전체의 공격과 방어가 <em>+" .. B.floor(bv * 100 + 0.5) .. "%</em> (3턴)", T + 0.8)
  st.ev.T = T + 1.6
end
B.RUN.heal = function(st, i) B.__expe_cov.calls["30-engine.lua:687"]=true; 
  local u, T = st.u[i], st.ev.T
  local amt = u.cs * 2 * 1.4 * (B.item_mul and B.item_mul(st) or 1)   -- 마렌토 시너지 「아이템 효과 +20%」: 연금술사의 약
  local tgs, sum = {}, 0
  for a = 1, 4 do B.__expe_cov.branches["30-engine.lua:691:26779"]=true; 
    local h = B.heal(st, a, amt, T + 1.0)
    if st.u[a].al == 1 then B.__expe_cov.branches["30-engine.lua:693:26847"]=true;  tgs[#tgs + 1] = { i = a, d = h }; sum = sum + h end
  end
  B.push(st, { k = "shield", a = i, t = T, tg = tgs, nm = "파티 회복" })
  B.say(st, "<b>" .. nm(i) .. "</b>" .. B.josa(nm(i), "이가") .. " 회복약을 뿌렸다. 아군 전체 HP 회복(합 <em>" .. sum .. "</em>)", T + 1.1)
  st.ev.T = T + 1.8
end
B.RUN.defdn = function(st, i, tgt) B.__expe_cov.calls["30-engine.lua:699"]=true; 
  local T = st.ev.T
  local sp = st.u[i].gu and B.gear_uq(st.u[i], "al_splash")   -- 장비 「번지는 약병」: 방어 약화가 깊어지고 양옆으로 번진다(81-gear)
  local dv = (sp and sp.v[1] / 100 or 0.20) * (B.item_mul and B.item_mul(st) or 1)
  B.badd(st.u[tgt], "ddn", dv, 3)
  if sp then B.__expe_cov.branches["30-engine.lua:704:27415"]=true;  B.gear_splash(st, i, tgt, dv) end
  local ab, list = B.abyss(st, i, tgt, 12, B.DEF[i].el, T + 0.7)
  B.push(st, { k = "mark", a = i, t = T, tg = { { i = tgt, ab = ab, list = list } }, nm = "약화 약병" })
  B.say(st, "<b>" .. nm(i) .. "</b>" .. B.josa(nm(i), "이가") .. " " .. B.p(nm(tgt), "에게") .. " 약화 약병을 던졌다. 방어 <em>−" .. B.floor(B.bget(st.u[tgt], "ddn") * 100 + 0.5) .. "%</em> (3턴)" .. ((ab or 0) > 0 and (". <i>심연 −" .. ab .. "</i>") or ""), T + 0.7)
  st.ev.T = T + 1.5
end
B.RUN.tonic = function(st, i, tgt) B.__expe_cov.calls["30-engine.lua:710"]=true; 
  local T = st.ev.T
  local v = 0.15 * (B.item_mul and B.item_mul(st) or 1)   -- 마렌토 「아이템 효과」 배수(연금술사의 약)
  B.badd(st.u[tgt], "atk", v, 3)
  B.push(st, { k = "def", a = tgt, t = T, nm = "아군 능력 버프" })
  B.say(st, "<b>" .. nm(i) .. "</b>" .. B.josa(nm(i), "이가") .. " " .. B.p(nm(tgt), "에게") .. " 강화 약을 건넸다. 공격 <em>+" .. B.floor(v * 100 + 0.5) .. "%</em> (3턴)", T + 0.6)
  st.ev.T = T + 1.3
end
-- 피의 갈증의 HP 비용(쓰는 조건과 쓸 때 같은 값을 본다)
function B.blood_cost(st, i) B.__expe_cov.calls["30-engine.lua:719"]=true; 
  local u = st.u[i]
  local c = B.floor(u.mhp * 0.15)
  if B.hpc then B.__expe_cov.branches["30-engine.lua:722:28453"]=true;  c = B.hpc(st, i, c) end   -- 모르가스 「혈통 서열」 HP 비용 −30%
  local bo = u.gu and B.gear_uq(u, "gl_boil")   -- 장비 「끓는 피」: HP 소모가 줄어든다(81-gear)
  if bo then B.__expe_cov.branches["30-engine.lua:724:28602"]=true;  c = B.floor(c * (1 - bo.v[1] / 100) + 0.5) end
  return c
end
B.RUN.blood = function(st, i) B.__expe_cov.calls["30-engine.lua:727"]=true; 
  local u, T = st.u[i], st.ev.T
  local c = B.blood_cost(st, i)
  if c > 0 then B.__expe_cov.branches["30-engine.lua:730:28774"]=true; 
    B.setf(st, i, "hp", math.max(1, u.hp - c), T + 0.3)
    B.fire(st, "hp_cost", i, c, T + 0.3)
  end
  B.badd(u, "bl", 1, 2)
  B.push(st, { k = "rev", a = i, t = T, nm = "피의 갈증", d = c })
  B.say(st, "<b>" .. nm(i) .. "</b>" .. B.josa(nm(i), "이가") .. " 피의 갈증에 몸을 맡긴다. " .. (c > 0 and ("HP <em>" .. c .. "</em> 소모") or "HP 소모 없음") .. ", 2턴 동안 치명 +30%p, 치명 피해 +50%", T + 0.5)
  st.ev.T = T + 1.2
end
B.RUN.rift = function(st, i, tgt) B.__expe_cov.calls["30-engine.lua:739"]=true; 
  local u = st.u[i]
  local mb = (u.rv == 1) and 1.5 or nil
  u.rv = 0
  B.attack(st, i, tgt, { m = 0.6, brk = 40, mulb = mb, name = "균열", sk = "균열", vb = "갈랐다", hit = 0.5, dur = 1.6 })
end
B.RUN.wave = function(st, i) B.__expe_cov.calls["30-engine.lua:745"]=true; 
  local u = st.u[i]
  local mb = (u.rv == 1) and 1.5 or nil
  u.rv = 0
  B.volley(st, i, { m = 0.4, brk = 20, mulb = mb, name = "혼돈 파동", k = "wave", hit = 0.6, dur = 2.0, line = "적 전체에 퍼뜨렸다" })
end

-- 스킬의 MP 비용(장비 「바람 읽기」가 일발필살 비용을 깎는다 — 81-gear). mpb = 개인 특성 할인 전
function B.mpb(st, i, sk) B.__expe_cov.calls["30-engine.lua:753"]=true; 
  local u = st.u[i]
  if u.gu then B.__expe_cov.branches["30-engine.lua:755:29754"]=true;  return B.gear_mpc(u, sk) end
  return sk.mp or 0
end
-- 아군 전원의 비용을 깎는 개인 특성은 B.mp_cut(st, mp) → mp 로 건다(리네트 「단체 할인」 — 32-personal-a)
function B.mpc(st, i, sk) B.__expe_cov.calls["30-engine.lua:759"]=true; 
  local mp = B.mpb(st, i, sk)
  if mp > 0 and B.mp_cut then B.__expe_cov.branches["30-engine.lua:761:29973"]=true;  mp = B.mp_cut(st, mp) end
  return mp
end

-- 스킬을 쓸 수 있나(MP · 개인 스킬 조건). 버튼 그리기와 누르기 둘 다 이걸 본다.
function B.can_use(st, i, sk) B.__expe_cov.calls["30-engine.lua:766"]=true; 
  local u = st.u[i]
  if not sk or u.mp < B.mpc(st, i, sk) then B.__expe_cov.branches["30-engine.lua:768:30163"]=true;  return false end
  if sk.pv and not B.PRUN[sk.cid] then B.__expe_cov.branches["30-engine.lua:769:30219"]=true;  return false end
  local tr = sk.pv and B.TR[sk.cid]
  if tr and tr.can and not tr.can(st, i, sk) then B.__expe_cov.branches["30-engine.lua:771:30322"]=true;  return false end
  if sk.id == "blood" then B.__expe_cov.branches["30-engine.lua:772:30366"]=true; 
    local c = B.blood_cost(st, i)
    if c > 0 and u.hp <= c then B.__expe_cov.branches["30-engine.lua:774:30432"]=true;  return false end   -- 줄어든 비용 기준(「끓는 피」·「혈통 서열」)
  end
  if u.sil and u.sil ~= "" and u.sil == sk.id then B.__expe_cov.branches["30-engine.lua:776:30537"]=true;  return false end   -- 침묵에 봉인된 스킬
  return true
end

-- slot 번 스킬. tgt = 표적 자리(없으면 0)
function B.player(st, slot, tgt) B.__expe_cov.calls["30-engine.lua:781"]=true; 
  local i = st.cur
  local u = st.u[i]
  local sk = B.SK[i][slot]
  st.n = st.n + 1
  B.rbegin(st)
  if u.gq and u.gq.first and u.x.f1 == nil then B.__expe_cov.branches["30-engine.lua:787:30802"]=true;  u.x.f1 = st.n end   -- 장비 「첫 행동」 표식(81-gear)
  if sk.pv and sk.cid ~= "persona" then B.__expe_cov.branches["30-engine.lua:788:30887"]=true;  cutin(st, i, sk.id, sk.name) end
  local mpc = B.mpc(st, i, sk)
  if mpc > 0 then B.__expe_cov.branches["30-engine.lua:790:30969"]=true; 
    B.setf(st, i, "mp", u.mp - mpc, st.ev.T)
    if u.gu then B.__expe_cov.branches["30-engine.lua:792:31031"]=true;  B.gear_echo(st, i, mpc) end   -- 장비 메아리(81-gear)
    if B.mp_note then B.__expe_cov.branches["30-engine.lua:793:31102"]=true;  B.mp_note(st, i, B.mpb(st, i, sk), mpc) end   -- 할인을 받았으면 한 줄(리네트 「단체 할인」)
  end
  local cost
  B.ACT = u   -- 지금 행동하는 아군(B.badd 의 자기 버프 표시)
  B.SKON = sk.id or true   -- 스킬 실행 중 표시(값 = 스킬 id): 장비 회복·버프 보너스는 스킬이 한 것에만 붙는다(81-gear)
  if sk.pv then B.__expe_cov.branches["30-engine.lua:798:31349"]=true; 
    cost = B.PRUN[sk.cid](st, i, tgt, sk)
  else B.__expe_cov.branches["30-engine.lua:800:31398"]=true; 
    local f = B.RUN[sk.id]
    if f then B.__expe_cov.branches["30-engine.lua:802:31439"]=true;  cost = f(st, i, tgt, sk) end
  end
  B.SKON = nil
  if u.gu then B.__expe_cov.branches["30-engine.lua:805:31504"]=true;  B.gear_skill(st, i, sk.id) end   -- 장비: 도발 뒤 피해 감소 · 파티 보호막 뒤 가속(81-gear)
  B.end_turn(st, i, cost or 10000)
  B.ACT = nil
end

-- ---------- 적 행동 ----------
function B.enemy_target(st, i) B.__expe_cov.calls["30-engine.lua:811"]=true; 
  local u = st.u[i]
  local t, why = u.it, ""
  for a = 1, 4 do B.__expe_cov.branches["30-engine.lua:814:31759"]=true; 
    if st.u[a].al == 1 and st.u[a].tau > 0 then B.__expe_cov.branches["30-engine.lua:815:31805"]=true; 
      if t ~= a then B.__expe_cov.branches["30-engine.lua:816:31826"]=true;  why = "taunt" end
      t = a
      break
    end
  end
  if t < 1 or t > 4 or st.u[t].al ~= 1 then B.__expe_cov.branches["30-engine.lua:821:31926"]=true; 
    for a = 1, 4 do B.__expe_cov.branches["30-engine.lua:822:31948"]=true;  if st.u[a].al == 1 then B.__expe_cov.branches["30-engine.lua:822:31970"]=true;  t = a; break end end
  end
  return t, why
end

-- 적 한 번의 단일 공격(옛 4칸 · 새 조합 공통). 큰 기술(act.big)도 이 길을 탄다.
function B.e_attack(st, i, act) B.__expe_cov.calls["30-engine.lua:828"]=true; 
  local ev = st.ev
  local T = ev.T
  local u = st.u[i]
  if act.all then B.__expe_cov.branches["30-engine.lua:832:32181"]=true;  return B.e_attack_all(st, i, act) end
  local t, why = B.enemy_target(st, i)
  local redirect = false
  for g = 1, 4 do B.__expe_cov.branches["30-engine.lua:835:32303"]=true;    -- 총대 메기: 그 아군을 지키기로 한 사람이 대신 맞는다
    local m = st.u[g]
    if g ~= t and m.al == 1 and m.oath == t then B.__expe_cov.branches["30-engine.lua:837:32408"]=true; 
      t = g; redirect = true; m.oath = 0; m.oT = 0
      break
    end
  end
  local v = st.u[t]
  local hitT = T + (act.shoot and 0.62 or 0.52)
  if B.chain(st, "evade", nil, t, i) then B.__expe_cov.branches["30-engine.lua:844:32595"]=true; 
    B.push(st, { k = "eatk", a = i, t = T, tg = { { i = t, d = 0, sh = 0, kill = 0, c = 0, miss = 1 } }, nm = act.name, ic = act.ic, shoot = act.shoot and 1 or 0, big = act.big and 1 or 0 })
     B.say(st, B.U("<b>{who}</b>의 {action}. {target:이가} <em>피했다</em>", { who = nm(i), action = act.name, target = nm(t) }), hitT + 0.1)
    ev.T = T + 1.4
  else B.__expe_cov.branches["30-engine.lua:848:32948"]=true; 
    local Kc = st.K or B.K_of(st.el or 40)
    local de = v.de * (1 + B.bget(v, "def") - B.bget(v, "ddn"))
    local fm, ftag = 1, nil
    if st.fl then B.__expe_cov.branches["30-engine.lua:852:33101"]=true;  fm, ftag = B.foe_atk_mul(st, i) end
    local raw = B.floor(u.cs * act.m * u.am * (1 - B.bget(u, "adn")) * fm * Kc / (Kc + de))
    if raw < 1 then B.__expe_cov.branches["30-engine.lua:854:33249"]=true;  raw = 1 end
    local res = B.strike(st, t, raw, hitT, redirect and 0.7 or nil, i)
    B.push(st, { k = "eatk", a = i, t = T, tg = { res }, nm = act.name, ic = act.ic, shoot = act.shoot and 1 or 0, big = act.big and 1 or 0 })
    local ex = {}
     if redirect then B.__expe_cov.branches["30-engine.lua:858:33515"]=true;  ex[1] = B.U("총대 메기 -30%") elseif why == "taunt" then B.__expe_cov.branches["30-engine.lua:858:33568"]=true;  ex[1] = B.U("도발에 이끌림") end
    if ftag then B.__expe_cov.branches["30-engine.lua:859:33612"]=true;  ex[#ex + 1] = ftag end
    res.tags = ex
    B.say(st, st.fl and B.foe_line(st, i, act, res) or B.dmg_line(st, i, res, { vb = act.vb }), hitT + 0.1)
    ev.T = T + 1.4
    if st.fl then B.__expe_cov.branches["30-engine.lua:863:33798"]=true;  B.e_after_hit(st, i, act, t, res, hitT) end
    if st.u[t].al == 1 then B.__expe_cov.branches["30-engine.lua:864:33870"]=true;  B.fire(st, "attacked", t, i, res, hitT) end
  end
end

-- 적 전체 공격(전체 공격 · 전체 큰 기술). 한 사람씩 회피·피해를 따로 굴린다.
function B.e_attack_all(st, i, act) B.__expe_cov.calls["30-engine.lua:869"]=true; 
  local ev = st.ev
  local T = ev.T
  local u = st.u[i]
  local Kc = st.K or B.K_of(st.el or 40)
  local fm, ftag = 1, nil
  if st.fl then B.__expe_cov.branches["30-engine.lua:875:34150"]=true;  fm, ftag = B.foe_atk_mul(st, i) end
  local tgs, parts, n = {}, {}, 0
  for t = 1, 4 do B.__expe_cov.branches["30-engine.lua:877:34240"]=true; 
    local v = st.u[t]
    if v.al == 1 then B.__expe_cov.branches["30-engine.lua:879:34282"]=true; 
      n = n + 1
      local hitT = T + (act.shoot and 0.62 or 0.52) + (n - 1) * 0.07
      if B.chain(st, "evade", nil, t, i) then B.__expe_cov.branches["30-engine.lua:882:34413"]=true; 
        tgs[#tgs + 1] = { i = t, d = 0, sh = 0, kill = 0, c = 0, miss = 1 }
         parts[#parts + 1] = B.U("{name} <em>피함</em>", { name = nm(t) })
      else B.__expe_cov.branches["30-engine.lua:885:34573"]=true; 
        local de = v.de * (1 + B.bget(v, "def") - B.bget(v, "ddn"))
        local raw = B.floor(u.cs * act.m * u.am * (1 - B.bget(u, "adn")) * fm * Kc / (Kc + de))
        if raw < 1 then B.__expe_cov.branches["30-engine.lua:888:34761"]=true;  raw = 1 end
        local res = B.strike(st, t, raw, hitT, nil, i)
        res.tags = ftag and { ftag } or {}
        tgs[#tgs + 1] = res
         parts[#parts + 1] = B.U("{name} <em>{damage}</em>{down}", { name = nm(t), damage = res.d, down = res.kill == 1 and B.U("(부상 이탈)") or "" })
        if st.fl then B.__expe_cov.branches["30-engine.lua:893:35069"]=true;  B.e_after_hit(st, i, act, t, res, hitT) end
        if st.u[t].al == 1 then B.__expe_cov.branches["30-engine.lua:894:35145"]=true;  B.fire(st, "attacked", t, i, res, hitT) end
      end
    end
  end
  B.push(st, { k = "eall", a = i, t = T, tg = tgs, nm = act.name, ic = act.ic, shoot = act.shoot and 1 or 0, big = act.big and 1 or 0 })
   B.say(st, B.U("<b>{who}</b>의 {action}. {parts}{tag}", { who = nm(i), action = act.name, parts = table.concat(parts, ", "), tag = ftag and (" (" .. ftag .. ")") or "" }), T + 0.8)
  ev.T = T + 1.9
end

function B.enemy_turn(st, i) B.__expe_cov.calls["30-engine.lua:903"]=true; 
  local ev = st.ev
  local T = ev.T
  local u, d = st.u[i], B.DEF[i]
  local act = d.acts[u.ia]
  st.n = st.n + 1
  B.rbegin(st)
  local K = act.kind
  if st.fl then B.__expe_cov.branches["30-engine.lua:911:35749"]=true;  B.foe_turn_start(st, i) end   -- 보호·은신 해제 · 약점 순환 · 차례 수(31-foes)
  if K == "atk" then B.__expe_cov.branches["30-engine.lua:912:35836"]=true; 
    B.e_attack(st, i, act)
  elseif K == "guard" then B.__expe_cov.branches["30-engine.lua:914:35890"]=true; 
    u.df = 1
    B.push(st, { k = "edef", a = i, t = T, nm = act.name })
     B.say(st, B.U("<b>{who}</b>{particle} 방어 자세를 취했다. 다음 차례까지 받는 피해 -40%", { who = nm(i), particle = B.josa(nm(i), "이가") }), T + 0.5)
    ev.T = T + 1.2
  elseif K == "buff" and act.am then B.__expe_cov.branches["30-engine.lua:919:36154"]=true; 
    u.am = act.am
    u.bt = 4
    B.push(st, { k = "ebuff", a = i, t = T, nm = act.name })
     B.say(st, B.U("<b>{who}</b>{particle} {verb}. 공격력 상승 (3턴)", { who = nm(i), particle = B.josa(nm(i), "이가"), verb = act.vb }), T + 0.5)
    ev.T = T + 1.2
  elseif st.fl then B.__expe_cov.branches["30-engine.lua:925:36424"]=true; 
    B.e_act(st, i, act)   -- 강화 · 약화 · 지속 피해 · 회복 · 소환 · 보호 · 충전 · 특수(31-foes)
  end
  if st.fl then B.__expe_cov.branches["30-engine.lua:928:36525"]=true;  B.foe_turn_end(st, i, act) end
  -- 다음 행동을 정하고 예고한다
  u.ia = u.ia % #B.DEF[i].acts + 1
  u.it = B.pick_target(st, i)
end

-- 지속 피해(적 차례 시작): 쌓인 것을 한 번에
function B.dot_tick(st, i) B.__expe_cov.calls["30-engine.lua:935"]=true; 
  local u = st.u[i]
  if not u.dot or #u.dot == 0 then B.__expe_cov.branches["30-engine.lua:937:36759"]=true;  return end
  local sum, keep, by, wb = 0, {}, nil, nil
  for _, x in ipairs(u.dot) do B.__expe_cov.branches["30-engine.lua:939:36847"]=true; 
    if x.by and st.u[x.by] and st.u[x.by].gu then B.__expe_cov.branches["30-engine.lua:940:36895"]=true;  wb = wb or {}; wb[#wb + 1] = x.by end   -- 장비 「피의 대가」: 지속 피해를 건 장비 착용자(81-gear)
    sum = sum + x.d
    x.n = x.n - 1
    if x.n > 0 then B.__expe_cov.branches["30-engine.lua:943:37033"]=true; 
      keep[#keep + 1] = x
    elseif x.bu then B.__expe_cov.branches["30-engine.lua:945:37080"]=true; 
      sum = sum + B.floor(x.d * x.n0 * x.bu / 100)   -- 장비 독 폭발: 줄이 끝나는 순간 그 줄 총 피해의 x% 를 한 번에(81-gear)
    end
    if x.by then B.__expe_cov.branches["30-engine.lua:948:37209"]=true;  by = x.by end   -- 마지막으로 쌓은 줄을 건 사람이 처치를 이어 받는다(악마 시너지 — 6차 검수 #3)
  end
  u.dot = keep
  if B.GH.dotmul then B.__expe_cov.branches["30-engine.lua:951:37319"]=true;  sum = B.floor(sum * B.GH.dotmul(st) + 0.5) end   -- 모르가스 시너지 지속 피해 +25%
  local T = st.ev.T
  local res = B.strike(st, i, sum, T + 0.3)
  if wb then B.__expe_cov.branches["30-engine.lua:954:37468"]=true;  B.gear_dottick(st, wb, T + 0.3) end
  B.push(st, { k = "dot", a = i, t = T, tg = { res } })
  B.say(st, "<b>" .. nm(i) .. "</b>" .. B.josa(nm(i), "이가") .. " 지속 피해로 <em>" .. res.d .. "</em> 피해를 입었다" .. (res.kill == 1 and ". 쓰러졌다" or ""), T + 0.4)
  st.ev.T = T + 0.9
  if res.kill == 1 then B.__expe_cov.branches["30-engine.lua:958:37758"]=true; 
    st.kill = "지속 피해"
    if by and B.kill_credit then B.__expe_cov.branches["30-engine.lua:960:37813"]=true;  B.kill_credit(st, by, T + 0.4) end
  end
end

-- 고갈된 적의 차례: 잃는다. 심연이 다시 가득 찬다.
function B.lost_turn(st, i) B.__expe_cov.calls["30-engine.lua:965"]=true; 
  local ev = st.ev
  local u = st.u[i]
  u.dr = 0
  B.setf(st, i, "ay", u.ym, ev.T + 0.6)
  B.push(st, { k = "recover", a = i, t = ev.T })
  B.say(st, "<b>" .. nm(i) .. "</b>" .. B.josa(nm(i), "은는") .. " 고갈에서 헤어나지 못해 <i>차례를 잃었다</i>. 심연이 다시 가득 찼다", ev.T + 0.4)
  ev.T = ev.T + 1.2
  st.n = st.n + 1
  B.rbegin(st)
  if st.fl and u.cq == 1 then B.__expe_cov.branches["30-engine.lua:975:38263"]=true;  B.charge_cancel(st, i) end   -- 충전하던 큰 기술이 끊긴다(31-foes)
  u.it = B.pick_target(st, i)
end

-- ---------- 전투 끝 ----------
-- 경험치(승리): 적 레벨 × (잡몹 12 · 정예 36) × ★ 보상 배수 [제안 — 사장님 확인 대기]
function B.exp_reward(st) B.__expe_cov.calls["30-engine.lua:981"]=true; 
  if st.fl then B.__expe_cov.branches["30-engine.lua:982:38488"]=true;  return B.exp_reward_foes(st) end
  local s = 0
  for j = 5, #st.u do B.__expe_cov.branches["30-engine.lua:984:38559"]=true; 
    local d = B.DEF[j]
    if st.u[j].empty ~= 1 then B.__expe_cov.branches["30-engine.lua:986:38611"]=true;  s = s + (d.lvn or st.el or 1) * ((d.kind == "elite") and 36 or 12) end
  end
  local r = (B.STARS[st.star or 1] or B.STARS[1]).reward or 1
  if st.qmult then B.__expe_cov.branches["30-engine.lua:989:38769"]=true;  r = r * st.qmult end
  if B.GH.exp then B.__expe_cov.branches["30-engine.lua:990:38809"]=true;  r = r * B.GH.exp(st) end   -- 경계도시 「떠돌이」 경험치 +10%(출전자마다)
  return B.floor(s * r)
end

function B.finish(st, result) B.__expe_cov.calls["30-engine.lua:994"]=true; 
  if st.over ~= "" then B.__expe_cov.branches["30-engine.lua:995:38949"]=true;  return end
  st.over = result
  local ev = st.ev
  local T = ev and ev.T or 0
  local win = (result == "win")
  local hurt, parts = {}, {}
  for i = 1, 4 do B.__expe_cov.branches["30-engine.lua:1001:39108"]=true; 
    local u = st.u[i]
    if not B.DEF[i].empty then B.__expe_cov.branches["30-engine.lua:1003:39159"]=true; 
       parts[#parts + 1] = B.T(B.DEF[i].full) .. " " .. u.hp .. "/" .. u.mhp
       if u.al == 0 then B.__expe_cov.branches["30-engine.lua:1005:39261"]=true;  hurt[#hurt + 1] = B.T(B.DEF[i].full) end
    end
  end
  st.exp = win and B.exp_reward(st) or 0
  local lines = {}
  local ctx = B.result_context and B.result_context(st) or nil   -- 조합 전투: 장소 · 맞선 적(AI 서술용 — 31-foes)
  if win then B.__expe_cov.branches["30-engine.lua:1011:39493"]=true; 
     lines[#lines + 1] = B.U("[전투 결과 - 승리]")
    if ctx then B.__expe_cov.branches["30-engine.lua:1013:39554"]=true;  lines[#lines + 1] = ctx end
     lines[#lines + 1] = B.U("적을 모두 물리쳤다. 마지막 일격은 {last} 행동 {turns}번 만에 끝났다. 심연 고갈 {depletions}회.", { last = st.kill ~= "" and (st.kill .. B.josa(st.kill, "이다") .. ".") or "알 수 없다.", turns = st.n, depletions = st.nd })
     lines[#lines + 1] = B.U("남은 체력: {party}", { party = table.concat(parts, ", ") })
     lines[#lines + 1] = B.U("부상자: {party}", { party = #hurt > 0 and table.concat(hurt, ", ") or "없음" })
    if st.dn and st.dn.kind == "explore" then B.__expe_cov.branches["30-engine.lua:1017:40038"]=true;    -- 대던전 탐색 전투: 보상은 층을 마칠 때(정산) 합산해 받는다 — 이 전투 몫은 지금 모으는 중
       lines[#lines + 1] = B.U("얻은 것: 경험치 {exp}, 금화 {gold} (층 정산 때 합산해 받는다. 퇴각해도 모은 것은 가져간다)", { exp = st.exp, gold = st.rg or 0 })
    elseif st.dn and st.dn.stage == 1 then B.__expe_cov.branches["30-engine.lua:1019:40272"]=true;    -- (옛 저장) 구역 전투: 보상은 층 보스 뒤에 합산해 받는다(아직 아무것도 받지 않았다)
       lines[#lines + 1] = B.U("얻은 것: 아직 없음 (층 보스를 쓰러뜨리면 이 구역 전투 몫까지 합산해 받는다)")
    else B.__expe_cov.branches["30-engine.lua:1021:40416"]=true; 
       lines[#lines + 1] = B.U("얻은 것: 경험치 {exp}, 금화 {gold}{item}", { exp = st.exp, gold = st.rg or B.REWARD.gold, item = (B.REWARD.item ~= "") and (", " .. B.REWARD.item) or "" })
    end
  else B.__expe_cov.branches["30-engine.lua:1024:40611"]=true; 
     lines[#lines + 1] = B.U("[전투 결과 - 패배]")
    if ctx then B.__expe_cov.branches["30-engine.lua:1026:40672"]=true;  lines[#lines + 1] = ctx end
     lines[#lines + 1] = B.U("파티가 버티지 못했다. 전원 부상으로 퇴각한다. 사망자는 없다. 행동 {turns}번째에 무너졌다.", { turns = st.n })
     lines[#lines + 1] = B.U("남은 체력: {party}", { party = table.concat(parts, ", ") })
     lines[#lines + 1] = B.U("부상자: {party}", { party = #hurt > 0 and table.concat(hurt, ", ") or "없음" })
     lines[#lines + 1] = B.U("얻은 것: 없음 (원정 물자 일부 분실)")
  end
   lines[#lines + 1] = B.U("이 결과는 확정이다. 번복하지 말고 장면으로 서술하라. 위 숫자는 화면에 이미 보이니 대사로 읊지 않는다.")
  st.res = table.concat(lines, "\n")
  if ev then B.__expe_cov.branches["30-engine.lua:1034:41198"]=true;  B.push(st, { k = "end", t = T + 0.3, win = win and 1 or 0 }) end
  if win then B.__expe_cov.branches["30-engine.lua:1035:41277"]=true; 
     B.say(st, B.U("<b>승리</b>. 전투가 끝났다."), T + 0.6)
  else B.__expe_cov.branches["30-engine.lua:1037:41336"]=true; 
     B.say(st, B.U("<b>퇴각</b>. 파티 전원이 부상으로 물러난다."), T + 0.6)
  end
  st.cur = 0
  st.q = {}
end

function B.check_end(st) B.__expe_cov.calls["30-engine.lua:1044"]=true; 
  if st.over ~= "" then B.__expe_cov.branches["30-engine.lua:1045:41482"]=true;  return true end
  if B.count_alive(st, 5) == 0 then B.__expe_cov.branches["30-engine.lua:1046:41534"]=true;  B.finish(st, "win"); return true end
  if B.count_alive(st, 1, 4) == 0 then B.__expe_cov.branches["30-engine.lua:1047:41610"]=true;  B.finish(st, "lose"); return true end
  if st.n >= B.MAX_ACTIONS then B.__expe_cov.branches["30-engine.lua:1048:41680"]=true;  B.finish(st, "lose"); return true end
  return false
end

-- 플레이어 입력이 필요한 아군 차례가 올 때까지(또는 전투가 끝날 때까지) 자동 진행
function B.run(st) B.__expe_cov.calls["30-engine.lua:1053"]=true; 
  local guard = 0
  while guard < 80 do B.__expe_cov.branches["30-engine.lua:1055:41849"]=true; 
    guard = guard + 1
    if st.fl then B.__expe_cov.branches["30-engine.lua:1057:41887"]=true;  B.after_action(st) end   -- 단계 전환 · 분노(31-foes)
    if B.check_end(st) then B.__expe_cov.branches["30-engine.lua:1058:41963"]=true;  return end
    local i = B.advance(st)
    B.begin_turn(st, i)
    local u = st.u[i]
    if i >= 5 then B.__expe_cov.branches["30-engine.lua:1062:42067"]=true; 
      if (u.fx or 0) > 0 then B.__expe_cov.branches["30-engine.lua:1063:42097"]=true;  u.fx = u.fx - 1 end
      B.dot_tick(st, i)
      if u.al == 1 and st.fl and B.phase_check(st) > 0 then B.__expe_cov.branches["30-engine.lua:1065:42201"]=true;  u.g = 0 end   -- 지속 피해로 문턱을 넘으면 1단계 행동을 더 하지 않고 2단계 첫 행동으로(이 차례의 값은 end_turn 이 낸다)
      if u.al == 1 then B.__expe_cov.branches["30-engine.lua:1066:42308"]=true; 
        if u.dr == 1 then B.__expe_cov.branches["30-engine.lua:1067:42334"]=true;  B.lost_turn(st, i) else B.__expe_cov.branches["30-engine.lua:1067:42358"]=true;  B.enemy_turn(st, i) end
      end
      B.end_turn(st, i, 10000)
    else B.__expe_cov.branches["30-engine.lua:1070:42432"]=true; 
      local down = false
      if u.edot and #u.edot > 0 then B.__expe_cov.branches["30-engine.lua:1072:42494"]=true;  down = B.edot_tick(st, i) end   -- 적이 건 지속 피해(31-foes) — 쓰러지면 그 차례는 없다
      if down then B.__expe_cov.branches["30-engine.lua:1073:42584"]=true; 
        -- 쓰러진 사람은 더 이어지지 않는다(advance 가 al == 0 을 건너뛴다)
      elseif u.chg == 1 then B.__expe_cov.branches["30-engine.lua:1075:42669"]=true; 
        st.n = st.n + 1
        B.rbegin(st)
        u.chg = 0
        B.release(st, i, false)
        B.end_turn(st, i, 10000)
      else B.__expe_cov.branches["30-engine.lua:1081:42808"]=true; 
        break
      end
    end
  end
  if B.check_end(st) then B.__expe_cov.branches["30-engine.lua:1086:42872"]=true;  return end
  st.q = B.preview(st, 9)
end

-- ---------- 처음 네 사람의 개인 스킬 · 특성(나머지는 32-personal-*.lua) ----------
-- 레비아: 하이 리스크 하이 리턴 · 깨진 유리창 이론
B.PRUN.levia = function(st, i, tgt, sk) B.__expe_cov.calls["30-engine.lua:1092"]=true; 
  local u, T = st.u[i], st.ev.T
  local c = B.floor(u.mhp * 0.1)
  if B.hpc then B.__expe_cov.branches["30-engine.lua:1095:43137"]=true;  c = B.hpc(st, i, c) end   -- 모르가스 「혈통 서열」 HP 비용 −30%
  B.setf(st, i, "hp", u.hp - c, T + 0.3)
  B.fire(st, "hp_cost", i, c, T + 0.3)
  u.rv = 1
  B.push(st, { k = "rev", a = i, t = T, nm = sk.name, d = c })
  B.say(st, B.U("<b>{who}</b>가 <b>하이 리스크 하이 리턴</b>에 걸었다. HP <em>{cost}</em> 소모, 다음 균열과 혼돈 파동의 심연 깎기 ×1.5", { who = nm(i), cost = c }), T + 0.5)
  st.ev.T = T + 1.2
end
-- 레비아 「깨진 유리창 이론」: 적이 줄수록 고갈 대미지가 커진다(1 + y × (처음 적 수 − 지금 적 수) / (처음 − 1))
function B.lmult(st) B.__expe_cov.calls["30-engine.lua:1104"]=true; 
  local y = B.GEN.tr.levia.y
  local al = B.count_alive(st, 5)
  local n0 = st.foe and #st.foe or 4
  local ratio = (al <= 1) and 1 or ((n0 > 1) and (n0 - al) / (n0 - 1) or 1)
  return 1 + y * ratio
end
B.TR.levia = {
  can = function(st, i) B.__expe_cov.calls["30-engine.lua:1112"]=true;  return st.u[i].hp > B.floor(st.u[i].mhp * 0.1) end,
  deal = function(st, o, a, t, m, tags) B.__expe_cov.calls["30-engine.lua:1113"]=true; 
    if a ~= o or st.u[t].dr ~= 1 then B.__expe_cov.branches["30-engine.lua:1114:43982"]=true;  return nil end
    local lm = B.lmult(st)
    if lm > 1.0001 then B.__expe_cov.branches["30-engine.lua:1116:44048"]=true;  tags[#tags + 1] = string.format("깨진 유리창 이론 ×%.2f", lm); return m * lm end
  end,
  abyss_mul = function(st, o, a, t, amt) B.__expe_cov.calls["30-engine.lua:1118"]=true;  if a == o then B.__expe_cov.branches["30-engine.lua:1118:44185"]=true;  return amt * B.lmult(st) end end,
  abyss_after = function(st, o, a, t, amt, at, list) B.__expe_cov.calls["30-engine.lua:1119"]=true; 
    if a ~= o then B.__expe_cov.branches["30-engine.lua:1120:44291"]=true;  return end
    local c = B.floor(amt * B.GEN.tr.levia.x + 0.5)
    if c < 1 then B.__expe_cov.branches["30-engine.lua:1122:44372"]=true;  return end
    for j = 5, #st.u do B.__expe_cov.branches["30-engine.lua:1123:44409"]=true; 
      local w = st.u[j]
      if j ~= t and w.al == 1 and w.dr == 0 then B.__expe_cov.branches["30-engine.lua:1125:44480"]=true; 
        local n2 = w.ay - c
        if n2 < 0 then B.__expe_cov.branches["30-engine.lua:1127:44531"]=true;  n2 = 0 end
        B.setf(st, j, "ay", n2, at + 0.5)
        list[#list + 1] = { i = j, n = c }
        if n2 <= 0 then B.__expe_cov.branches["30-engine.lua:1130:44651"]=true;  B.deplete(st, j, at + 0.7) end
      end
    end
    if #list > 0 then B.__expe_cov.branches["30-engine.lua:1133:44722"]=true;  B.trait_line(st, o, "깨진 유리창 이론: 다른 적 심연 −" .. c, at + 0.4, 1) end
  end,
}
-- 마르셀린: 총대 메기 · 9회말 2아웃
B.PRUN.marceline = function(st, i, tgt, sk) B.__expe_cov.calls["30-engine.lua:1137"]=true; 
  local u, T = st.u[i], st.ev.T
  u.oath = tgt
  u.oT = 4
  B.push(st, { k = "oath", a = i, t = T, tg = { { i = tgt } }, nm = sk.name })
  B.say(st, B.U("<b>{who}</b>이 「총대 메기」 하고 나서서 {target:을를} 지킨다. 다음 적 공격을 몸으로 받는다(받는 피해 −30%)", { who = nm(i), target = nm(tgt) }), T + 0.7)
  st.ev.T = T + 1.6
end
B.TR.marceline = {
  save = function(st, o, t, at) B.__expe_cov.calls["30-engine.lua:1146"]=true; 
    if t ~= o then B.__expe_cov.branches["30-engine.lua:1147:45236"]=true;  return nil end
    local u = st.u[o]
    local tr = B.GEN.tr.marceline
    if u.lf >= tr.times then B.__expe_cov.branches["30-engine.lua:1150:45336"]=true;  return nil end
    u.lf = u.lf + 1
    local h = 1 + B.floor(tr.heal * u.mhp)
    if h > u.mhp then B.__expe_cov.branches["30-engine.lua:1153:45436"]=true;  h = u.mhp end
    B.setf(st, o, "hp", 1, at)
    B.setf(st, o, "hp", h, at + 0.4)
    B.setf(st, o, "sh", B.floor(tr.shield * u.mhp), at + 0.4)
    u.shT = 3
    B.trait_line(st, o, "9회말 2아웃: HP 1로 버티고 회복, 보호막", at)
    B.say(st, "<b>" .. nm(o) .. "</b>의 <b>9회말 2아웃</b>. HP 1로 버티고 <em>" .. (h - 1) .. "</em> 회복, 보호막 " .. B.floor(tr.shield * u.mhp), at + 0.5)
    return true
  end,
}
-- 나란: 낙인 효과(개인) · 여우불(특성)
B.PRUN.naran = function(st, i, tgt, sk) B.__expe_cov.calls["30-engine.lua:1164"]=true; 
  local T = st.ev.T
  local ok = st.u[tgt].rd ~= 1 or B.rnd(st) < B.BOSSR.reduce   -- 구역 보스는 표식 확률 절반(레이드 감경)
  if ok then B.__expe_cov.branches["30-engine.lua:1167:46010"]=true;  st.u[tgt].mk = 1 end
  local ab, list = B.abyss(st, i, tgt, 3, B.DEF[i].el, T + 0.8)
  B.push(st, { k = "mark", a = i, t = T, tg = { { i = tgt, ab = ab, list = list } }, nm = sk.name })
  B.say(st, B.U("<b>{who}</b>이 「낙인 효과」 하고 {target}{result}{abyss}", { who = nm(i), target = nm(tgt), result = ok and B.U("에게 여우불 표식을 새겼다. 다음 피격은 확정 치명타") or B.U("에게 여우불을 던졌지만 표식이 붙지 않았다"), abyss = ((ab or 0) > 0 and B.U(". <i>심연 −{n}</i>", { n = ab }) or "") }), T + 0.8)
  st.ev.T = T + 1.7
end
B.TR.naran = {
  hit_after = function(st, o, a, t, res, opt, at) B.__expe_cov.calls["30-engine.lua:1174"]=true; 
    if a ~= o or res.kill == 1 then B.__expe_cov.branches["30-engine.lua:1175:46593"]=true;  return end
    local tr = B.GEN.tr.naran
    local v = st.u[t]
    local fresh = ((v.fx or 0) == 0)
    v.fx, v.fb = tr.turns, tr.bonus * B.rdm(v)
    if fresh then B.__expe_cov.branches["30-engine.lua:1180:46758"]=true;  B.trait_line(st, o, "밴드왜건 효과: " .. nm(t) .. "에게 여우불, 받는 피해 +" .. B.floor(tr.bonus * 100) .. "%", at + 0.5) end
  end,
}
-- 테이리스: 마감 전날 대폭발 · 상대성 이론
B.PRUN.teiris = function(st, i, tgt, sk) B.__expe_cov.calls["30-engine.lua:1184"]=true; 
  st.u[i].seal = 1
  B.release(st, i, true)
end
B.TR.teiris = {
  can = function(st, i) B.__expe_cov.calls["30-engine.lua:1189"]=true;  return st.u[i].seal ~= 1 end,
  turn_end = function(st, o, i) B.__expe_cov.calls["30-engine.lua:1190"]=true; 
    if i ~= o then B.__expe_cov.branches["30-engine.lua:1191:47116"]=true;  return end
    local u = st.u[o]
    u.nu = u.nu + 1
    local tr = B.GEN.tr.teiris
    if u.nu % tr.every == 0 then B.__expe_cov.branches["30-engine.lua:1195:47233"]=true; 
      u.g = u.g - 10000 * tr.pull
      if u.g < 0 then B.__expe_cov.branches["30-engine.lua:1197:47289"]=true;  u.g = 0 end
      B.trait_line(st, o, B.U("상대성 이론: 행동 게이지가 가득 차 바로 한 번 더"))
      B.say(st, B.U("<b>{name}</b>의 <b>상대성 이론</b>. 게이지가 가득 차 <em>바로 한 번 더</em> 움직인다", { name = nm(o) }), st.ev.T + 0.2)
      st.ev.T = st.ev.T + 0.6
    end
  end,
}
