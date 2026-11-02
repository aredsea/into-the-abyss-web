-- ===== 종족·국가 특성 · 시너지 · 직업 패시브 (정본 design/TRAITS.md · CLASSES.md · stats.json classes[].passive) =====
-- 엔진(30-engine)의 전역 훅 B.GH[사건] 에 꽂는다. 사람 개인 특성(B.TR[cid])과는 따로 돈다.
-- 표식: 전투 유닛 u.rc(종족 id) · u.ln(수인 계통 dog/cat) · u.na(국가 id) — B.tr_init 이 전투를 만들 때 붙인다.
-- 시너지 = 살아 있는 아군 중 같은 표식 수. 2명 → 2단계, 3명 이상 → 3단계(2단계를 대신한다 · TRAITS.md 「시너지 규칙」).
-- 🔴 10-10 사장님 개편: 종족은 1명 ≈ 있으나마나 · 3명이면 전투 효율 최대 15% (balance_synergy.mjs 로 잰다) · 출신(국가)은 3명이 모여도 전투 효율 5% 내외 + 전투 밖 효과(경험치·상점·휴식·발견·패배 손실).
--   예외: 최대 HP(인간)는 시작 때 출전 편성으로 한 번 센다. 전투 밖 효과(B.tx_*: 휴식·발견·패배·상점)는 편성 목록(pm)의 표식 수로 센다.
-- 🔴 결정론: 난수는 B.rnd 만, 순서가 필요한 곳은 고정 배열(pairs 금지). 저장 상태는 문자열 키 표와 숫자뿐.
do B.__r23_cov.branches["34-traits.lua:8:652"]=true; 
local P = {   -- 직업 패시브 수치 (stats.json classes[].passive 와 같다 — harness_traits 가 대조한다)
  assassin = { crit = 50, extra = 0.20 },   -- 사장님 10-10: 치명 +50%p · 공격 시 20% 추가 공격(차례는 늘지 않는다)
  sanctioned = { delay = 0.08 },
  unsanctioned = { dot = 0.12, cap = 5 },
  alchemist = { spd = 0.06 },
  gladiator = { atk = 0.20, def = 0.10, spd = 0.08, crit = 8 },
}
B.PASS = P

-- 측정용 스위치(6차 검수 #5·#6 — 결정은 메인 세션). 지금 값이 켜져 있다. 🔴 B.PASS 는 stats.json 과 같아야 해서(harness_traits) 따로 둔다.
--   priest_cap  : 사제 「이탈 방지」 전투당 파티 전체 발동 상한 — 0 = 상한 없음(파티원마다 1회 · 지금) · 2 = 후보 B
--   priest_heal : 붙들었을 때 HP 비율 — 0.5 = 지금 · 0.3 = 후보 C
B.VAR = { priest_cap = 0, priest_heal = 0.5 }   -- 사제 50% 는 사장님 원문 수치라 유지 — 30% 안은 질문(docs/QUESTIONS-2026-10-11.md)

local X = {   -- 종족·국가 수치 (TRAITS.md) — 전부 [제안]. 종족은 balance_synergy.mjs 로 「3명 ≤ 15%」, 출신은 「3명 ≤ 5% 내외」를 확인한다.
  human = { hp2 = 0.04, hp3 = 0.07, heal3 = 0.10 },
  elf = { magic = 0.03, mp = 6, spd2 = 0.01, spd3 = 0.02 },
  demon = { thr = 0.30, atk = 0.12, heal2 = 0.03, heal3 = 0.03, mp3 = 2 },
  halfelf = { res = 0.02, res3 = 0.02 },
  nox = { deb = 0.30, red2 = 0.03, red3 = 0.05, tau3 = 0.08 },
  beast = { pack = 0.08, ambush = 15, spd2 = 0.01, spd3 = 0.01, dbl3 = 0.04 },
  seredia = { def = 0.04, front2 = 0.03, exp3 = 0.10 },
  karashin = { spd = 0.01, rd1 = 0.03, stack = 0.01, cap = 3, find3 = 0.40 },
  solen = { elite = 0.03, shield2 = 0.03, rest3 = 0.04, aff3 = 0.20 },
  marento = { gold = 0.15, item2 = 0.10, shop2 = 0.06, shop3 = 0.12 },
  naerin = { eva = 0.01, herb2 = 0.50, herb3 = 1.00, rest_mp3 = 0.03 },
  morgas = { hpc = 0.30, dot2 = 0.10, cap3 = 1 },
  kern = { red = 0.02, ch3 = 0.05, dm = 0.7, dm3 = 0.10, lose2 = 0.30, keep3 = 0.40 },
  border = { exp = 0.10, dup2 = 0.30, dup3 = 0.60 },
}
B.TXN = X

local RACE = { ["인간"] = "human", ["엘프"] = "elf", ["악마"] = "demon", ["하프엘프"] = "halfelf", ["녹스"] = "nox", ["수인"] = "beast" }
local NAT = { ["신성 세레디아 제국"] = "seredia", ["대카라쉰"] = "karashin", ["솔렌 성왕국"] = "solen", ["마렌토 공화국"] = "marento",
  ["나에린"] = "naerin", ["모르가스 신관국"] = "morgas", ["케른 연방"] = "kern", ["경계도시"] = "border" }
local LIN = { ["개"] = "dog", ["여우"] = "dog", ["늑대"] = "dog", ["개과"] = "dog", ["고양이"] = "cat", ["표범"] = "cat", ["고양이과"] = "cat" }
-- 시너지 표시 순서·이름 (고정 배열)
local ORDER = { "human", "elf", "demon", "halfelf", "nox", "beast", "seredia", "karashin", "solen", "marento", "naerin", "morgas", "kern", "border" }
-- 이름·시너지 글은 design/passives.json(B.PASSIVES — build.py 가 05-gen.lua 로 내보낸다) 한 곳에 둔다. 도감·상태창이 같은 글을 읽는다.
-- 글 속 {칸.이름%} 자리표시자는 여기서 수치로 채운다: 칸 = 종족·국가(B.TXN) · 직업(B.PASS) · var(B.VAR), % 를 붙이면 0.08 → 8.
local function ptx(s) B.__r23_cov.calls["34-traits.lua:49"]=true; 
  return (tostring(s):gsub("{([%w_]+)%.([%w_]+)(%%?)}", function(a, b, pc) B.__r23_cov.calls["34-traits.lua:50"]=true; 
    local t = (a == "var") and B.VAR or X[a] or P[a]
    local v = t and t[b]
    if type(v) ~= "number" then B.__r23_cov.branches["34-traits.lua:53:3446"]=true;  return "{" .. a .. "." .. b .. pc .. "}" end   -- 모르는 칸은 그대로 두어 하네스가 잡는다
    if pc == "%" then B.__r23_cov.branches["34-traits.lua:54:3541"]=true;  v = B.floor(v * 100 + 0.5) end
    if v == B.floor(v) then B.__r23_cov.branches["34-traits.lua:55:3600"]=true;  return string.format("%d", v) end
    return tostring(v)
  end))
end
B.ptx = ptx
local function pnode(k) B.__r23_cov.calls["34-traits.lua:60"]=true;  return B.PASSIVES.races[k] or B.PASSIVES.nations[k] end

local POS = { atk = 1, def = 1, bs = 1, bl = 1, g2 = 1, red = 1, red20 = 1, red25 = 1 }   -- 아군에게 거는 이로운 버프 키
local NEG = { adn = 1, ddn = 1, zdn = 1 }                                                   -- 아군에게 걸릴 수 있는 약화 키

local function xs(u) B.__r23_cov.calls["34-traits.lua:65"]=true; 
  if type(u.x) ~= "table" then B.__r23_cov.branches["34-traits.lua:66:4038"]=true;  u.x = {} end
  return u.x
end

-- (종족 id, 계통 id, 국가 id) — m = 전투 편성 항목({ id, race, lin, nat }) 또는 동료 id
function B.tr_ids(m) B.__r23_cov.calls["34-traits.lua:71"]=true; 
  local race, lin, nat = "", "", ""
  if type(m) == "table" and m.id == "persona" then B.__r23_cov.branches["34-traits.lua:73:4250"]=true; 
    race, lin, nat = m.race or "", m.lin or "", m.nat or ""
  else B.__r23_cov.branches["34-traits.lua:75:4317"]=true; 
    local k = B.CAST and B.CAST[type(m) == "table" and m.id or m]
    if k then B.__r23_cov.branches["34-traits.lua:77:4397"]=true;  race, lin, nat = k.race or "", k.lineage or "", k.nation or "" end
  end
  local r = RACE[race] or ""
  return r, (r == "beast") and (LIN[lin] or "") or "", NAT[nat] or ""
end

local function lv(n) B.__r23_cov.calls["34-traits.lua:83"]=true;  return (n >= 3) and 3 or ((n >= 2) and 2 or 0) end

-- 살아 있는 아군의 표식 수 → { human = 2, ... }
local function counts(st) B.__r23_cov.calls["34-traits.lua:86"]=true; 
  local c = {}
  for i = 1, 4 do B.__r23_cov.branches["34-traits.lua:88:4747"]=true; 
    local u = st.u[i]
    if u.al == 1 and not u.empty then B.__r23_cov.branches["34-traits.lua:90:4805"]=true; 
      if type(u.rc) == "string" and u.rc ~= "" then B.__r23_cov.branches["34-traits.lua:91:4857"]=true;  c[u.rc] = (c[u.rc] or 0) + 1 end   -- 옛 저장·깨진 칸(nil · 표)은 세지 않는다(6차 검수 #1)
      if type(u.na) == "string" and u.na ~= "" then B.__r23_cov.branches["34-traits.lua:92:4984"]=true;  c[u.na] = (c[u.na] or 0) + 1 end
    end
  end
  return c
end
-- 출전 편성(pm 목록) 기준 수 — 시작 때 한 번 정하는 효과 · 전투 밖 효과용
local function counts_of(pm) B.__r23_cov.calls["34-traits.lua:98"]=true; 
  local c = {}
  for i = 1, 4 do B.__r23_cov.branches["34-traits.lua:100:5160"]=true; 
    local m = pm and pm[i]
    if m and m.id ~= "" then B.__r23_cov.branches["34-traits.lua:102:5214"]=true; 
      local r, _, n = B.tr_ids(m)
      if r ~= "" then B.__r23_cov.branches["34-traits.lua:104:5270"]=true;  c[r] = (c[r] or 0) + 1 end
      if n ~= "" then B.__r23_cov.branches["34-traits.lua:105:5319"]=true;  c[n] = (c[n] or 0) + 1 end
    end
  end
  return c
end
local function counts_pm(st) B.__r23_cov.calls["34-traits.lua:110"]=true;  return counts_of(st.pm) end
local function L(st, k) B.__r23_cov.calls["34-traits.lua:111"]=true;  return lv(counts(st)[k] or 0) end
B.tlv = L

-- 전투 유닛 만들기(20-state blank_u): 표식 · 최대 HP/MP · 방어
function B.tr_init(st, u, m) B.__r23_cov.calls["34-traits.lua:115"]=true; 
  local r, l, n = B.tr_ids(m)
  u.rc, u.ln, u.na = r, l, n
  if r == "elf" then B.__r23_cov.branches["34-traits.lua:118:5661"]=true;  u.mmp = u.mmp + X.elf.mp; u.mp = u.mp + X.elf.mp end
  if n == "seredia" then B.__r23_cov.branches["34-traits.lua:119:5739"]=true;  u.de = u.de * (1 + X.seredia.def) end
  local c = counts_pm(st)
  local hl = lv(c.human or 0)
  if hl >= 2 then B.__r23_cov.branches["34-traits.lua:122:5851"]=true; 
    local h = B.floor(u.mhp * (1 + ((hl == 3) and X.human.hp3 or X.human.hp2)) + 0.5)
    u.mhp, u.hp = h, h
  end
end

-- 버프·약화 보정(B.badd): 인간 「적응」(약화 지속 −1턴, 최소 1) · 녹스 「타고난 내성」(약화 30% 약하게) · 하프엘프 시너지(이로운 버프 +1턴)
function B.badj(u, k, v, n) B.__r23_cov.calls["34-traits.lua:129"]=true; 
  if NEG[k] then B.__r23_cov.branches["34-traits.lua:130:6111"]=true; 
    if u.rc == "human" and n > 1 then B.__r23_cov.branches["34-traits.lua:131:6149"]=true;  n = n - 1 end
    if u.rc == "nox" then B.__r23_cov.branches["34-traits.lua:132:6189"]=true;  v = v * (1 - X.nox.deb) end
  elseif POS[k] and u.bx == 1 then B.__r23_cov.branches["34-traits.lua:133:6252"]=true; 
    n = n + 1
  end
  return v, n
end

-- 모르가스 「혈통 서열」: HP 를 쓰는 스킬의 비용 −30%
function B.hpc(st, i, c) B.__r23_cov.calls["34-traits.lua:140"]=true; 
  if st.u[i].na ~= "morgas" then B.__r23_cov.branches["34-traits.lua:141:6386"]=true;  return c end
  return math.max(1, B.floor(c * (1 - X.morgas.hpc)))
end

-- 마렌토 시너지 2명 이상: 아이템(연금술사의 약 · 전투 중 물약) 효과 +10%
function B.item_mul(st) B.__r23_cov.calls["34-traits.lua:146"]=true; 
  return (L(st, "marento") >= 2) and (1 + X.marento.item2) or 1
end

-- ---------- 전투 밖 효과(출신 시너지) — 출전 편성 pm(목록)의 표식 수로 센다 ----------
-- pm = B.battle_pm(G) 또는 R.pm. 돌려주는 값은 호출하는 쪽(77-explore · 71-shop)이 쓴다.
-- 휴식 추가 회복(최대치의 비율): 솔렌 3명 HP +4%p · 나에린 3명 MP +3%p
function B.tx_rest(pm) B.__r23_cov.calls["34-traits.lua:153"]=true; 
  local c = counts_of(pm)
  local hp, mp = 0, 0
  if lv(c.solen or 0) == 3 then B.__r23_cov.branches["34-traits.lua:156:6896"]=true;  hp = hp + X.solen.rest3 end
  if lv(c.naerin or 0) == 3 then B.__r23_cov.branches["34-traits.lua:157:6957"]=true;  mp = mp + X.naerin.rest_mp3 end
  return hp, mp
end
-- 함께 싸운 호감 배수: 솔렌 3명 +20% (74-affection 의 B.aff_party 가 곱한다)
function B.tx_aff(pm) B.__r23_cov.calls["34-traits.lua:161"]=true; 
  return (lv(counts_of(pm).solen or 0) == 3) and (1 + X.solen.aff3) or 1
end
-- 탐색 발견: 카라쉰 3명 → 주운 금화 ×1.4 · 경계도시 2명 30% / 3명 60% → 주운 물건이 하나 더 · 나에린 2명 50% / 3명 100% → 주운 회복약이 하나 더
-- (결정론 난수는 호출자가 준다). 돌려주는 값 = 금화 배수, 물건 하나 더 확률, 회복약 하나 더 확률
function B.tx_find(pm) B.__r23_cov.calls["34-traits.lua:166"]=true; 
  local c = counts_of(pm)
  local coin = (lv(c.karashin or 0) == 3) and (1 + X.karashin.find3) or 1
  local bl = lv(c.border or 0)
  local dup = (bl == 3) and X.border.dup3 or ((bl == 2) and X.border.dup2 or 0)
  local nl = lv(c.naerin or 0)
  local herb = (nl == 3) and X.naerin.herb3 or ((nl == 2) and X.naerin.herb2 or 0)
  return coin, dup, herb
end
-- 패배 정산: 케른 2명 이상 → 들고 간 금화를 덜 잃는다(−30%) · 3명 → 탐색에서 모은 금화·물건의 40% 는 챙겨 돌아온다. (잃는 비율 배수, 챙기는 비율)
function B.tx_defeat(pm) B.__r23_cov.calls["34-traits.lua:176"]=true; 
  local kl = lv(counts_of(pm).kern or 0)
  return (kl >= 2) and (1 - X.kern.lose2) or 1, (kl == 3) and X.kern.keep3 or 0
end
-- 상점 가격 배수(마렌토 2명 −6% · 3명 −12%): 지금 편성(B.battle_pm)으로 센다
function B.tx_shop(G) B.__r23_cov.calls["34-traits.lua:181"]=true; 
  local ok, pm = pcall(B.battle_pm, G)
  if not ok or type(pm) ~= "table" then B.__r23_cov.branches["34-traits.lua:183:8122"]=true;  return 1 end
  local ml = lv(counts_of(pm).marento or 0)
  return (ml == 3) and (1 - X.marento.shop3) or ((ml == 2) and (1 - X.marento.shop2) or 1)
end

-- 전투 보상 금화: 마렌토 「장부」 출전자마다 +15%(더한다). base 가 없으면 그대로 돌려준다.
function B.reward_gold(st, base) B.__r23_cov.calls["34-traits.lua:189"]=true; 
  if base == nil then B.__r23_cov.branches["34-traits.lua:190:8390"]=true;  return nil end
  local n = counts_pm(st).marento or 0
  return B.floor(base * (1 + X.marento.gold * n) + 0.5)
end

local function trait(st, o, txt, at) B.__r23_cov.calls["34-traits.lua:195"]=true;  B.trait_line(st, o, txt, at) end

local function refresh(st) B.__r23_cov.calls["34-traits.lua:197"]=true;    -- 하프엘프 시너지 표식(버프 +1턴) · st.sy(정보용: 켜진 시너지 단계 — 거점 쪽 상점·보상 선택 연결이 읽는다)
  local c = counts(st)
  local hl = lv(c.halfelf or 0)
  for i = 1, 4 do B.__r23_cov.branches["34-traits.lua:200:8751"]=true;  st.u[i].bx = (hl >= 2) and 1 or 0 end
  local sy = {}
  for _, k in ipairs(ORDER) do B.__r23_cov.branches["34-traits.lua:202:8836"]=true; 
    local l = lv(c[k] or 0)
    if l >= 2 then B.__r23_cov.branches["34-traits.lua:204:8881"]=true;  sy[k] = l end
  end
  st.sy = sy
end

local G = B.GH

-- ---------- 시너지 표시(전투 머리 칩 · B.r_head) ----------
local base_syn = B.syn
function B.syn(st) B.__r23_cov.calls["34-traits.lua:213"]=true; 
  local out = base_syn(st)   -- 지능 계열 2명 = 라운드마다 MP 4 회복(20-state)
  local c = counts(st)
  for _, k in ipairs(ORDER) do B.__r23_cov.branches["34-traits.lua:216:9152"]=true; 
    local l = lv(c[k] or 0)
    if l >= 2 then B.__r23_cov.branches["34-traits.lua:218:9197"]=true;  out[#out + 1] = { t = pnode(k).short, n = c[k], fx = ptx(B.T(pnode(k).tier[l - 1])) } end
  end
  return out
end

-- ---------- 속도 ----------
function G.speed(st, i) B.__r23_cov.calls["34-traits.lua:224"]=true; 
  local u = st.u[i]
  if i > 4 then B.__r23_cov.branches["34-traits.lua:226:9399"]=true;  return 1 end
  local c = counts(st)
  local m = 1
  local el, bl = lv(c.elf or 0), lv(c.beast or 0)
  if el >= 2 then B.__r23_cov.branches["34-traits.lua:230:9517"]=true;  m = m * (1 + ((el == 3) and X.elf.spd3 or X.elf.spd2)) end
  if bl >= 2 then B.__r23_cov.branches["34-traits.lua:231:9594"]=true;  m = m * (1 + ((bl == 3) and X.beast.spd3 or X.beast.spd2)) end
  if u.na == "karashin" then B.__r23_cov.branches["34-traits.lua:232:9686"]=true;  m = m * (1 + X.karashin.spd) end
  if lv(c.karashin or 0) == 3 then B.__r23_cov.branches["34-traits.lua:233:9754"]=true;  m = m * (1 + X.karashin.stack * (st.ks or 0)) end
  if B.DEF[i].clsid == "gladiator" then B.__r23_cov.branches["34-traits.lua:234:9844"]=true;  m = m * (1 + P.gladiator.spd * u.hp / u.mhp) end
  for o = 1, 4 do B.__r23_cov.branches["34-traits.lua:235:9913"]=true;    -- 연금술사 패시브 「아군 차례 단축」: 다른 아군의 속도
    if o ~= i and st.u[o].al == 1 and B.DEF[o].clsid == "alchemist" then B.__r23_cov.branches["34-traits.lua:236:10020"]=true;  m = m * (1 + P.alchemist.spd); break end
  end
  return m
end

-- ---------- 내가 주는 피해 ----------
function G.deal(st, a, t, m, tags, opt) B.__r23_cov.calls["34-traits.lua:242"]=true; 
  local u = st.u[a]
  local d = B.DEF[a]
  local c = counts(st)
  if d.clsid == "gladiator" then B.__r23_cov.branches["34-traits.lua:246:10254"]=true;  m = m * (1 + P.gladiator.atk * u.hp / u.mhp) end   -- 검투사 「체력 비례 강화」
  if u.rc == "elf" and d.line == "지능" then B.__r23_cov.branches["34-traits.lua:247:10366"]=true; 
    m = m * (1 + X.elf.magic)
     tags[#tags + 1] = B.U("혈통 마법 +{n}%", { n = B.floor(X.elf.magic * 100) })
  end
  if u.rc == "demon" and u.hp <= u.mhp * X.demon.thr then B.__r23_cov.branches["34-traits.lua:251:10538"]=true; 
    m = m * (1 + X.demon.atk)
     tags[#tags + 1] = B.U("피의 계약 +{n}%", { n = B.floor(X.demon.atk * 100) })
  end
  if u.na == "solen" then B.__r23_cov.branches["34-traits.lua:255:10678"]=true; 
    local k = B.DEF[t].kind
    if k == "elite" or k == "boss" then B.__r23_cov.branches["34-traits.lua:257:10746"]=true; 
      m = m * (1 + X.solen.elite)
       tags[#tags + 1] = B.U("주신의 이름 +{n}%", { n = B.floor(X.solen.elite * 100) })
    end
  end
  if u.ln == "dog" and st.tl == t and st.tla and st.tla ~= a then B.__r23_cov.branches["34-traits.lua:262:10943"]=true; 
    m = m * (1 + X.beast.pack)
     tags[#tags + 1] = B.U("무리 사냥 +{n}%", { n = B.floor(X.beast.pack * 100) })
  end
  if lv(c.karashin or 0) == 2 and (st.rd or 0) == 0 then B.__r23_cov.branches["34-traits.lua:266:11116"]=true; 
    m = m * (1 + X.karashin.rd1)
     tags[#tags + 1] = B.U("선봉 +{n}%", { n = B.floor(X.karashin.rd1 * 100) })
  end
  return m
end

-- ---------- 치명 확률 가산(%p) ----------
function G.crit(st, a, t, opt) B.__r23_cov.calls["34-traits.lua:274"]=true; 
  local u = st.u[a]
  local add = 0
  if B.DEF[a].clsid == "gladiator" then B.__r23_cov.branches["34-traits.lua:277:11394"]=true;  add = add + P.gladiator.crit * u.hp / u.mhp end
  if B.DEF[a].clsid == "assassin" then B.__r23_cov.branches["34-traits.lua:278:11481"]=true;  add = add + P.assassin.crit end   -- 암살자 「치명타 강화」
  if u.ln == "cat" then B.__r23_cov.branches["34-traits.lua:279:11555"]=true;    -- 고양이과 「기습」: 전투에서 처음 하는 공격(한 행동 안의 여러 표적 포함)
    local x = xs(u)
    if x.fa == nil or x.fa == st.n then B.__r23_cov.branches["34-traits.lua:281:11663"]=true; 
      x.fa = st.n
      add = add + X.beast.ambush
    end
  end
  return add
end

-- ---------- 암살자 「추가 공격」: 단일 공격 뒤 20% 확률로 같은 대상을 한 번 더 친다(차례 소비 없음) ----------
function G.extra_hit(st, a, t, o, res, hitT) B.__r23_cov.calls["34-traits.lua:290"]=true; 
  if st.u[a].al ~= 1 then B.__r23_cov.branches["34-traits.lua:291:11897"]=true;  return end   -- 반격에 쓰러졌으면 추가 공격 없음
  if o.extra or a > 4 or B.DEF[a].clsid ~= "assassin" then B.__r23_cov.branches["34-traits.lua:292:11991"]=true;  return end
  if st.u[t].al ~= 1 or (res and res.kill == 1) then B.__r23_cov.branches["34-traits.lua:293:12055"]=true;  return end
  local sw = st.u[a].gu and B.gear_uq(st.u[a], "as_shadow")   -- 장비 「그림자 연타」: 추가 공격 확률(81-gear)
  if B.rnd(st) >= (sw and sw.v[1] / 100 or P.assassin.extra) then B.__r23_cov.branches["34-traits.lua:295:12228"]=true;  return end
  trait(st, a, "추가 공격")
  -- 추가 공격은 「피해만 한 번 더」(사장님 10-10) — 원래 스킬의 배율·확정 치명·심연 깎기를 베끼지 않고 일반 공격 피해로 친다
  local atk = B.ATK[B.DEF[a].clsid] or B.ATK.warrior
  B.attack(st, a, t, { m = atk.m, brk = 0, el = o.el, extra = true, name = "추가 공격", sk = "추가 공격", vb = atk.vb, hit = 0.25, dur = 0.8 })
end

-- ---------- 내가 받는 피해 ----------
function G.take(st, t, dmg, src) B.__r23_cov.calls["34-traits.lua:303"]=true; 
  local u = st.u[t]
  local c = counts(st)
  local f = 1
  if B.DEF[t].clsid == "gladiator" then B.__r23_cov.branches["34-traits.lua:307:12701"]=true;  f = f * (1 - P.gladiator.def * u.hp / u.mhp) end
  if u.rc == "halfelf" then B.__r23_cov.branches["34-traits.lua:308:12778"]=true;  f = f * (1 - X.halfelf.res) end
  if lv(c.halfelf or 0) == 3 then B.__r23_cov.branches["34-traits.lua:309:12844"]=true;  f = f * (1 - X.halfelf.res3) end
  if u.na == "kern" and u.tau > 0 then B.__r23_cov.branches["34-traits.lua:310:12916"]=true;  f = f * (1 - X.kern.red) end
  local nl = lv(c.nox or 0)
  if nl == 2 then B.__r23_cov.branches["34-traits.lua:312:12991"]=true;  f = f * (1 - X.nox.red2) end
  if nl == 3 then B.__r23_cov.branches["34-traits.lua:313:13038"]=true; 
    f = f * (1 - X.nox.red3)
    if u.tau > 0 then B.__r23_cov.branches["34-traits.lua:315:13089"]=true;  f = f * (1 - X.nox.tau3) end
  end
  if lv(c.seredia or 0) >= 2 and B.DEF[t].row == "전열" then B.__r23_cov.branches["34-traits.lua:317:13183"]=true;  f = f * (1 - X.seredia.front2) end
  if f < 1 then B.__r23_cov.branches["34-traits.lua:318:13234"]=true;  return dmg * f end
end

-- ---------- 회피(나에린 「숲지기」) ----------
function G.evade(st, v, t, e) B.__r23_cov.calls["34-traits.lua:322"]=true; 
  if v then B.__r23_cov.branches["34-traits.lua:323:13339"]=true;  return nil end
  local u = st.u[t]
  local p = 0
  if u.na == "naerin" then B.__r23_cov.branches["34-traits.lua:326:13415"]=true;  p = p + X.naerin.eva end
  if u.gq and u.gq.evade then B.__r23_cov.branches["34-traits.lua:327:13470"]=true;  p = p + u.gq.evade / 100 end   -- 장비 회피(%p) — 같은 판정에 더한다(81-gear)
  if p <= 0 then B.__r23_cov.branches["34-traits.lua:328:13553"]=true;  return nil end
  if B.rnd(st) < p then B.__r23_cov.branches["34-traits.lua:329:13592"]=true;  return true end
  return nil
end

-- ---------- 회복·보호막·지속 피해·경험치 ----------
function G.heal(st, t, amt) B.__r23_cov.calls["34-traits.lua:334"]=true; 
  if L(st, "human") == 3 then B.__r23_cov.branches["34-traits.lua:335:13726"]=true;  return amt * (1 + X.human.heal3) end
end
function G.shield(st, i, amt) B.__r23_cov.calls["34-traits.lua:337"]=true; 
  if L(st, "solen") >= 2 then B.__r23_cov.branches["34-traits.lua:338:13827"]=true;  return amt * (1 + X.solen.shield2) end
end
function G.dotmul(st) B.__r23_cov.calls["34-traits.lua:340"]=true; 
  return (L(st, "morgas") >= 2) and (1 + X.morgas.dot2) or 1
end
function G.dotcap(st) B.__r23_cov.calls["34-traits.lua:343"]=true; 
  return P.unsanctioned.cap + ((L(st, "morgas") == 3) and X.morgas.cap3 or 0)
end
function G.exp(st) B.__r23_cov.calls["34-traits.lua:346"]=true; 
  local c = counts_pm(st)
  local m = 1 + X.border.exp * (c.border or 0)
  if lv(c.seredia or 0) == 3 then B.__r23_cov.branches["34-traits.lua:349:14187"]=true;  m = m + X.seredia.exp3 end   -- 세레디아 3명: 제국 학술원 후원 — 획득 경험치 +10%
  return m
end

-- ---------- 전투 시작 · 라운드 · 차례 끝 ----------
function G.start(st) B.__r23_cov.calls["34-traits.lua:354"]=true; 
  refresh(st)
end

function G.round(st) B.__r23_cov.calls["34-traits.lua:358"]=true; 
  refresh(st)
  local c = counts(st)
  if lv(c.halfelf or 0) == 3 then B.__r23_cov.branches["34-traits.lua:361:14444"]=true;    -- 하프엘프 시너지 3명: 라운드마다 약화 1개 정화
    for i = 1, 4 do B.__r23_cov.branches["34-traits.lua:362:14499"]=true; 
      local u = st.u[i]
      if u.al == 1 and u.bf then B.__r23_cov.branches["34-traits.lua:364:14554"]=true; 
        for _, k in ipairs({ "adn", "ddn", "zdn" }) do B.__r23_cov.branches["34-traits.lua:365:14611"]=true; 
          if u.bf[k] then B.__r23_cov.branches["34-traits.lua:366:14635"]=true;  u.bf[k] = nil; break end
        end
      end
    end
  end
end

function G.ally_down(st, t) B.__r23_cov.calls["34-traits.lua:373"]=true;  refresh(st); B.dot_trim(st) end

-- 2회 행동: 수인 시너지 3명 모든 아군 확률. 두 번째 행동은 또 이어지지 않는다.
function G.turn_end(st, i) B.__r23_cov.calls["34-traits.lua:376"]=true; 
  if i > 4 then B.__r23_cov.branches["34-traits.lua:377:14856"]=true;  return end
  refresh(st)
  local u = st.u[i]
  if u.al ~= 1 then B.__r23_cov.branches["34-traits.lua:380:14921"]=true;  return end
  local x = xs(u)
  if x.dbl == 1 then B.__r23_cov.branches["34-traits.lua:382:14971"]=true;  x.dbl = 0; return end
  local p = 0
  if L(st, "beast") == 3 then B.__r23_cov.branches["34-traits.lua:384:15037"]=true;  p = p + X.beast.dbl3 end
  if p <= 0 then B.__r23_cov.branches["34-traits.lua:385:15079"]=true;  return end
  if B.rnd(st) < p then B.__r23_cov.branches["34-traits.lua:386:15114"]=true; 
    x.dbl = 1
    u.g = math.max(0, u.g - 10000)
    trait(st, i, "2회 행동: 바로 한 번 더")
    B.say(st, "<b>" .. B.nm(i) .. "</b>" .. B.josa(B.nm(i), "은는") .. " 틈을 놓치지 않는다. <em>2회 행동</em>, 바로 한 번 더 움직인다", st.ev.T + 0.2)
    st.ev.T = st.ev.T + 0.6
  end
end

-- ---------- 공격이 끝난 뒤 ----------
function G.hit_after(st, a, t, res, opt, at) B.__r23_cov.calls["34-traits.lua:396"]=true; 
  local u, d = st.u[a], B.DEF[a]
  st.tl, st.tla = t, a   -- 무리 사냥: 직전에 친 적
  local c = counts(st)
  -- 공인 마법사 패시브 「상대 차례 지연」: 일반 공격 · 마력 폭발이 맞힌 적의 차례를 늦춘다
  if d.clsid == "sanctioned" and res.kill ~= 1 and st.u[t].al == 1 and (opt.name == "일반 공격" or (opt.k == "burst" and opt.seal ~= 1)) then B.__r23_cov.branches["34-traits.lua:401:15741"]=true; 
    local sw = u.gu and B.gear_uq(u, "sa_warp")   -- 장비 「시간 왜곡」: 상대 차례 지연(81-gear)
    local dl = 10000 * (sw and sw.v[1] / 100 or P.sanctioned.delay) * B.rdm(st.u[t])
    st.u[t].g = st.u[t].g + dl
    if sw then B.__r23_cov.branches["34-traits.lua:405:15955"]=true;  B.gear_adv(st, a, dl * sw.v[3] / 100) end   -- 늦춘 시간의 일부를 자신의 다음 차례로(81-gear)
  end
  -- 비공인 마법사 패시브 「지속 피해 중첩」: 일반 공격이 지속 피해 한 줄을 쌓는다
  if d.clsid == "unsanctioned" and res.kill ~= 1 and st.u[t].al == 1 and opt.name == "일반 공격" then B.__r23_cov.branches["34-traits.lua:408:16188"]=true; 
    B.dot_push(st, st.u[t], math.max(1, B.floor(u.cs * 2 * P.unsanctioned.dot)), 3, a)
  end
  if res.kill == 1 then B.__r23_cov.branches["34-traits.lua:411:16305"]=true;  B.kill_credit(st, a, at) end
end

-- 처치 공통 처리(6차 검수 #3): 직접 공격 · 지속 피해(dot_tick) · 출혈 폭발이 모두 여기를 지난다. 악마 시너지 「피의 대가」.
function B.kill_credit(st, a, at) B.__r23_cov.calls["34-traits.lua:415"]=true; 
  if not a or a < 1 or a > 4 then B.__r23_cov.branches["34-traits.lua:416:16491"]=true;  return end
  local u = st.u[a]
  if not u or u.al ~= 1 then B.__r23_cov.branches["34-traits.lua:418:16551"]=true;  return end
  if u.gq or u.gu then B.__r23_cov.branches["34-traits.lua:419:16585"]=true;  B.gear_kill(st, a, at) end   -- 장비: 처치 시 MP · 연쇄(81-gear)
  local dl = lv(counts(st).demon or 0)
  local skon = B.SKON
  B.SKON = nil   -- 처치 회복은 스킬이 한 회복이 아니다 — 장비 회복 보너스 제외(81-gear)
  if dl == 2 then B.__r23_cov.branches["34-traits.lua:423:16787"]=true; 
    local h = B.heal(st, a, u.mhp * X.demon.heal2, at + 0.3)
    if h > 0 then B.__r23_cov.branches["34-traits.lua:425:16866"]=true;  trait(st, a, "피의 대가: 처치로 HP +" .. h, at + 0.3) end
  elseif dl == 3 then B.__r23_cov.branches["34-traits.lua:426:16939"]=true; 
    local h = B.heal(st, a, u.mhp * X.demon.heal3, at + 0.3)
    if h > 0 then B.__r23_cov.branches["34-traits.lua:428:17018"]=true;  trait(st, a, "피의 대가: 처치로 HP +" .. h, at + 0.3) end
    local any = false
    for i = 1, 4 do B.__r23_cov.branches["34-traits.lua:430:17113"]=true; 
      local w = st.u[i]
      if w.al == 1 and w.mp < w.mmp then B.__r23_cov.branches["34-traits.lua:432:17176"]=true; 
        B.setf(st, i, "mp", math.min(w.mmp, w.mp + X.demon.mp3), at + 0.3)
        any = true
      end
    end
    if any then B.__r23_cov.branches["34-traits.lua:437:17304"]=true;  trait(st, a, "피의 대가: 처치로 파티 MP +" .. X.demon.mp3, at + 0.3) end
  end
  B.SKON = skon
end

-- 모르가스 시너지 3명(지속 피해 중첩 +1)이 풀렸을 때: 직업 지속 피해(k = 1) 줄이 한도를 넘으면 오래된 것부터 뺀다(6차 검수 #4)
function B.dot_trim(st) B.__r23_cov.calls["34-traits.lua:443"]=true; 
  local cap = G.dotcap(st)
  for j = 5, #st.u do B.__r23_cov.branches["34-traits.lua:445:17554"]=true; 
    local v = st.u[j]
    if v.al == 1 and v.dot then B.__r23_cov.branches["34-traits.lua:447:17606"]=true; 
      local c = 0
      for _, x in ipairs(v.dot) do B.__r23_cov.branches["34-traits.lua:449:17661"]=true;  if x.k == 1 then B.__r23_cov.branches["34-traits.lua:449:17676"]=true;  c = c + 1 end end
      while c > cap do B.__r23_cov.branches["34-traits.lua:450:17719"]=true; 
        for k, x in ipairs(v.dot) do B.__r23_cov.branches["34-traits.lua:451:17756"]=true; 
          if x.k == 1 then B.__r23_cov.branches["34-traits.lua:452:17781"]=true;  table.remove(v.dot, k); c = c - 1; break end
        end
      end
    end
  end
end

function G.enemy_dead(st, t) B.__r23_cov.calls["34-traits.lua:459"]=true; 
  if L(st, "karashin") == 3 and (st.ks or 0) < X.karashin.cap then B.__r23_cov.branches["34-traits.lua:460:17963"]=true;    -- 카라쉰 시너지 3명: 처치할 때마다 속도 +5%(중첩 3)
    st.ks = (st.ks or 0) + 1
  end
end

-- 케른 시너지 3명: 공격받으면 반격 (2명은 전투 밖 효과만 — 패배 정산)
function G.attacked(st, t, e, res, at) B.__r23_cov.calls["34-traits.lua:466"]=true; 
  local kl = L(st, "kern")
  if kl < 3 or e < 5 or st.u[e].al ~= 1 then B.__r23_cov.branches["34-traits.lua:468:18198"]=true;  return end
  if B.rnd(st) >= X.kern.ch3 then B.__r23_cov.branches["34-traits.lua:469:18243"]=true;  return end
  local m = X.kern.dm * (1 + X.kern.dm3)
  local a = B.ATK[B.DEF[t].clsid] or B.ATK.warrior
  B.trait_line(st, t, "계약은 지킨다: 반격", at + 0.2)
  B.attack(st, t, e, { m = m, brk = 0, name = "반격", vb = "맞받아쳤다", hit = 0.3, dur = 0.9 })
end

end
