-- ===== 상태 (채팅 변수 JSON) · 결정론 난수 =====
-- 난수: 전투 씨앗 + 행동 번호로 매 행동마다 다시 씨앗을 정한다(Park-Miller, 곱이 2^46 미만이라 실수형 Lua 에서도 같다).
function B.rbegin(st) B.__r23_cov.calls["20-state.lua:3"]=true; 
  st.rs = ((st.seed * 31 + st.n * 977 + 13) % 2147483646) + 1
end

function B.rnd(st) B.__r23_cov.calls["20-state.lua:7"]=true; 
  st.rs = (st.rs * 16807) % 2147483647
  return st.rs / 2147483647
end

function B.floor(x) B.__r23_cov.calls["20-state.lua:12"]=true;  return math.floor(x + 1e-9) end

function B.count_alive(st, lo, hi) B.__r23_cov.calls["20-state.lua:14"]=true; 
  local c = 0
  for i = lo, hi or #st.u do B.__r23_cov.branches["20-state.lua:16:431"]=true;  if st.u[i].al == 1 then B.__r23_cov.branches["20-state.lua:16:453"]=true;  c = c + 1 end end
  return c
end

-- 시너지: 살아 있는 아군의 직업 계열 표식을 센다(이 파티는 종족·국가 겹침 없음). 지능 2명 = 라운드마다 MP 4 회복.
function B.syn(st) B.__r23_cov.calls["20-state.lua:21"]=true; 
  local cnt = 0
  for i = 1, 4 do B.__r23_cov.branches["20-state.lua:23:616"]=true; 
    if st.u[i].al == 1 and B.DEF[i].line == "지능" then B.__r23_cov.branches["20-state.lua:24:668"]=true;  cnt = cnt + 1 end
  end
  if cnt >= 2 then B.__r23_cov.branches["20-state.lua:26:711"]=true;  return { { t = "지능", n = cnt, fx = "라운드마다 MP 4 회복" } } end
  return {}
end

function B.say(st, html, at) B.__r23_cov.calls["20-state.lua:30"]=true; 
  st.log[#st.log + 1] = { h = html, t = at or 0 }
  while #st.log > 6 do B.__r23_cov.branches["20-state.lua:32:891"]=true;  table.remove(st.log, 1) end
end

B.FIELDS = { "hp", "mp", "sh", "ay" }

-- 한 번 누를 때의 기록장(연출은 이 기록에서 그린다)
function B.begin_ev(st) B.__r23_cov.calls["20-state.lua:38"]=true; 
  local pre, h = {}, {}
  for i = 1, #st.u do B.__r23_cov.branches["20-state.lua:40:1066"]=true; 
    local u = st.u[i]
    pre[i] = { hp = u.hp, mp = u.mp, sh = u.sh, ay = u.ay }
    h[i] = {}
  end
  for _, l in ipairs(st.log) do B.__r23_cov.branches["20-state.lua:45:1200"]=true;  l.t = -1 end
  st.ev = { pre = pre, h = h, list = {}, T = 0.15, q0 = st.q or {} }
end

function B.setf(st, i, f, v, at) B.__r23_cov.calls["20-state.lua:49"]=true; 
  st.u[i][f] = v
  if st.ev and (f == "hp" or f == "mp" or f == "sh" or f == "ay") then B.__r23_cov.branches["20-state.lua:51:1406"]=true; 
    local hh = st.ev.h[i]
    hh[#hh + 1] = { f = f, t = at or st.ev.T, v = v }
  end
end

function B.push(st, e) B.__r23_cov.calls["20-state.lua:57"]=true; 
  local l = st.ev.list
  l[#l + 1] = e
  return e
end

-- ---------- 파티 정의(전투마다) ----------
-- st.pm[i] = { id = "persona" | 동료 id | "", cls = 직업 id, L = 레벨 } (i = 1~4, id "" = 빈 자리)
-- 기본 파티(시험 하네스·옛 저장): 시험판 2와 같은 레비아·마르셀린·나란·테이리스 Lv40
B.DEFAULT_PM = {
  { id = "levia", cls = "chaos", L = 40 }, { id = "marceline", cls = "paladin", L = 40 },
  { id = "naran", cls = "archer", L = 40 }, { id = "teiris", cls = "sanctioned", L = 40 },
}

-- 한 사람의 표시·판정 정의(B.DEF[i] 자리)
function B.member_def(m) B.__r23_cov.calls["20-state.lua:72"]=true; 
  local c = B.CLS[m.cls] or B.CLS.warrior
  if m.id == "persona" then B.__r23_cov.branches["20-state.lua:74:2085"]=true; 
    return { cid = "persona", name = "{{user}}", full = "{{user}}", cls = c.name, clsid = c.id, row = c.row, line = c.line,
      el = "none", art = "", trn = "", lv = m.L, skill = m.skill }
  end
  local k = B.CAST[m.id] or {}
  return { cid = m.id, name = k.name or m.id, full = k.name or m.id, cls = c.name, clsid = c.id, row = k.row ~= "" and k.row or c.row,
    line = c.line, el = (k.el and k.el ~= "") and k.el or "none", art = m.id, trn = k.trait or "", lv = m.L }
end

-- 한 사람의 스킬: [일반 공격, 직업 스킬 0~3, 개인(동료만), 방어] — 번호(sk_N)는 이 순서. 화면은 row 로 두 줄(직업 · 공통)에 나눈다(10-10)
function B.member_skills(d) B.__r23_cov.calls["20-state.lua:84"]=true; 
  local a = B.ATK[d.clsid] or B.ATK.warrior
  local list = { { id = "atk", name = "일반 공격", mp = 0, tgt = "enemy", ic = a.ic, d = a.d, row = "com" } }
  for _, s in ipairs(B.KIT[d.clsid] or {}) do B.__r23_cov.branches["20-state.lua:87:2887"]=true; 
    local c = {}
    for k, v in pairs(s) do B.__r23_cov.branches["20-state.lua:89:2932"]=true;  c[k] = v end
    c.row = "cls"
    list[#list + 1] = c
  end
  if d.cid == "persona" and B.ps_ready and B.ps_ready(d.skill) then B.__r23_cov.branches["20-state.lua:93:3059"]=true; 
    list[#list + 1] = B.ps_skill(d.skill)
  elseif d.cid ~= "persona" then B.__r23_cov.branches["20-state.lua:95:3134"]=true; 
    local k = B.CAST[d.cid] or {}
    local p = B.PSK[d.cid] or {}
    list[#list + 1] = { id = p.id or ("p_" .. d.cid), name = k.skill or "개인 스킬", mp = k.skill_mp or 0, tgt = p.tgt or k.skill_tgt or "none",
      ic = p.ic or "buff", d = p.d or ("개인 스킬: " .. (k.skill_d or "")), pv = true, cid = d.cid, row = "com" }
  end
  local df = {}
  for k, v in pairs(B.DF) do B.__r23_cov.branches["20-state.lua:102:3505"]=true;  df[k] = v end
  df.row = "com"
  list[#list + 1] = df
  return list
end

function B.sk_slot(i, id) B.__r23_cov.calls["20-state.lua:108"]=true; 
  for k, s in ipairs(B.SK[i] or {}) do B.__r23_cov.branches["20-state.lua:109:3643"]=true;  if s.id == id then B.__r23_cov.branches["20-state.lua:109:3660"]=true;  return k end end
  return nil
end

-- 전투 상태 → B.DEF · B.SK 다시 만들기(불러올 때마다). 적 자리는 레벨 표시만 바꾼다.
function B.bind(st) B.__r23_cov.calls["20-state.lua:114"]=true; 
  for i = 1, 4 do B.__r23_cov.branches["20-state.lua:115:3794"]=true; 
    local m = st.pm[i]
    if m and m.id ~= "" then B.__r23_cov.branches["20-state.lua:117:3844"]=true; 
      B.DEF[i] = B.member_def(m)
      B.SK[i] = B.member_skills(B.DEF[i])
    else B.__r23_cov.branches["20-state.lua:120:3928"]=true; 
      B.DEF[i] = { cid = "", name = "빈 자리", full = "빈 자리", cls = "", clsid = "", row = "", line = "", el = "none", art = "", trn = "", empty = true }
      B.SK[i] = {}
    end
  end
  B.bind_foes(st)
  -- 대상 고르는 중이던 스킬: 번호는 목록 순서에 달려 있으니 id 로 다시 찾는다(id 가 없는 옛 저장은 취소)
  if (st.pend or 0) > 0 then B.__r23_cov.branches["20-state.lua:127:4226"]=true; 
    local slot = (st.pid and st.cur) and B.sk_slot(st.cur, st.pid) or nil
    if slot then B.__r23_cov.branches["20-state.lua:129:4317"]=true;  st.pend = slot else B.__r23_cov.branches["20-state.lua:129:4337"]=true;  st.pend, st.pid = 0, nil end
  end
end

-- 적 자리 정의. 옛 전투(st.fl 없음)는 고정 4칸 B.EDEF, 조합 전투는 st.fl[j] = 적 id(빈 자리 "") 로 B.FOES 에서 만든다.
-- st.fg[j] = 등급 덮어쓰기("chief" 우두머리 · "minion" 하수인 · ""). 단계·약점 순환은 그 칸 유닛(st.u[4+j])의 ph · cwk.
local GRADE_TAG = { elite = " 정예", chief = " 우두머리", boss = " 구역 보스", core = " 균열 핵", minion = " 하수인" }
function B.foe_def(st, j) B.__r23_cov.calls["20-state.lua:136"]=true; 
  local id = st.fl[j]
  local f = id and id ~= "" and B.FOES[id] or nil
  if not f then B.__r23_cov.branches["20-state.lua:139:4781"]=true; 
    return { name = "", full = "", glyph = "", lv = "", wk = {}, acts = { { id = "none", name = "", kind = "guard", ic = "defend" } }, row = "전열", spd = 100, kind = "mob", empty = true }
  end
  local u = st.u and st.u[4 + j]
  local d = {}
  for k, v in pairs(f) do B.__r23_cov.branches["20-state.lua:144:5050"]=true;  d[k] = v end
  d.id = id
  d.foe = id
  local gr = st.fg and st.fg[j]
  local deepn = (st.dk or 0) > 0
  if gr == "chiefb" then B.__r23_cov.branches["20-state.lua:149:5176"]=true;  gr, deepn = "chief", true elseif gr == "eliteb" then B.__r23_cov.branches["20-state.lua:149:5229"]=true;  gr, deepn = "elite", true end   -- 다른 구역에서 빌려 온 적은 「깊은」
  d.grade = (gr and gr ~= "") and gr or f.grade
  d.deepn = deepn
  d.kind = (B.GRADES[d.grade] or B.GRADES.mob).kind
  d.elite = (d.kind == "elite")
  if d.grade == "minion" then B.__r23_cov.branches["20-state.lua:154:5465"]=true;  d.srole = "하수인" end
  d.boss = (d.kind == "boss")
  d.glyph = "적"
  d.ic = "fam-" .. string.format("%02d", f.fam)
  d.name = (deepn and B.U("깊은 ") or "") .. B.T(f.name)
  d.full = d.name
  d.lvn = math.min(B.LEVEL_MAX, st.el or 1)
  d.lv = "Lv." .. d.lvn .. B.U(GRADE_TAG[d.grade] or "")
  if f.ph2 and u and u.ph == 2 then B.__r23_cov.branches["20-state.lua:162:5789"]=true; 
    d.wk = f.ph2.cycle and u.cwk and #u.cwk == 2 and u.cwk or f.ph2.wk
    d.acts = f.ph2.acts
  end
  return d
end
function B.bind_foes(st) B.__r23_cov.calls["20-state.lua:168"]=true; 
  if st.fl then B.__r23_cov.branches["20-state.lua:169:5946"]=true; 
    local ne = st.ne or #st.fl
    for j = 1, ne do B.__r23_cov.branches["20-state.lua:171:6000"]=true;  B.DEF[4 + j] = B.foe_def(st, j) end
    for k = 5 + ne, 16 do B.__r23_cov.branches["20-state.lua:172:6062"]=true;  B.DEF[k] = nil end
    return
  end
  for j = 1, 4 do B.__r23_cov.branches["20-state.lua:175:6116"]=true; 
    local e = B.EDEF[j]
    local d = {}
    for k, v in pairs(e) do B.__r23_cov.branches["20-state.lua:178:6185"]=true;  d[k] = v end
    d.lvn = math.min(B.LEVEL_MAX + 2, (st.el or 40) + (e.lvo or 0))
    d.lv = "Lv." .. d.lvn .. (e.elite and B.U(" 정예") or "")
    B.DEF[4 + j] = d
  end
  for k = 9, 16 do B.__r23_cov.branches["20-state.lua:183:6372"]=true;  B.DEF[k] = nil end
end

local function unit0() B.__r23_cov.calls["20-state.lua:186"]=true; 
  return { hp = 0, mhp = 1, mp = 0, mmp = 0, sh = 0, shT = 0, g = 10000, al = 1,
    tau = 0, df = 0, chg = 0, oath = 0, oT = 0, mk = 0, am = 1, bt = 0, rv = 0, lf = 0, nu = 0, seal = 0,
    ay = 0, ym = 0, dr = 0, fx = 0, fb = 0, ia = 1, it = 0, sp = 100, cs = 0, de = 0, ag = 0, cr = 0, bf = {}, x = {},
    rc = "", ln = "", na = "", bx = 0 }   -- 종족 · 계통 · 국가 표식(34-traits) · bx = 버프 +1턴 표식
end

function B.blank_u(st, i) B.__r23_cov.calls["20-state.lua:193"]=true; 
  local u = unit0()
  if i <= 4 then B.__r23_cov.branches["20-state.lua:195:6880"]=true; 
    local m = st.pm[i]
    if not m or m.id == "" then B.__r23_cov.branches["20-state.lua:197:6935"]=true; 
      u.al, u.mhp, u.g = 0, 1, 10 ^ 9
      u.empty = 1
      return u
    end
    local s = B.party_stats(m.cls, m.L, m.id ~= "persona" and m.id or nil)
    if m.id == "persona" and type(m.ps) == "table" and m.ps.str then B.__r23_cov.branches["20-state.lua:203:7158"]=true; 
      -- 페르소나: 만들 때 고른 능력치(직업 기본 + 보너스)를 살리고 레벨 성장분만 얹는다 — 상태창(66-status PX.st_persona)과 같은 계산.
      -- 곱 비율(HP·MP·힘·민첩·지능·방어), 속도는 덧셈. 🔴 전에는 직업 기본값만 써서 보너스가 전투에 전혀 안 먹었다(10-13 유저 제보).
      local s1 = B.party_stats(m.cls, 1, nil)
      local function r(k, k1) B.__r23_cov.calls["20-state.lua:207"]=true;  local b = tonumber(s1[k1 or k]) or 0; local v = tonumber(m.ps[k]); return (b > 0 and v) and (v / b) or 1 end
      s.hp, s.mp = math.floor(s.hp * r("hp") + 0.5), math.floor(s.mp * r("mp") + 0.5)
      s.str, s.agi, s.int = s.str * r("str"), s.agi * r("agi"), s.int * r("int")
      s.de = s.de * r("def", "de"); s.def = s.de; s.ag = s.agi
      s.sp = s.sp + ((tonumber(m.ps.spd) or s1.sp) - s1.sp)
      local cl = B.cls_of(m.cls)
      s.cs = s[(cl and B.LINE_KEY[cl.line]) or "str"]
    end
    u.hp, u.mhp, u.mp, u.mmp = s.hp, s.hp, s.mp, s.mp
    u.sp, u.cs, u.de, u.ag, u.cr = B.floor(s.sp + 0.5), s.cs, s.de, s.ag, s.cr
    if B.tr_init then B.__r23_cov.branches["20-state.lua:217:8069"]=true;  B.tr_init(st, u, m) end   -- 종족·국가 표식 · 최대 HP/MP · 방어 보정(34-traits)
    if m.eq and B.gear_init then B.__r23_cov.branches["20-state.lua:218:8170"]=true;  B.gear_init(st, u, m) end   -- 장비: 능력치 곱 · u.gq/u.gu 합산 — 전투 시작 때 한 번(81-gear)
    return u
  end
  if st.fl then B.__r23_cov.branches["20-state.lua:221:8284"]=true;    -- 조합 전투: 적 id 는 st.fl, 수치는 역할 × 등급 × ★/심층(24-stats B.foe_stats)
    local d = B.DEF[i]
    if not d or d.empty then B.__r23_cov.branches["20-state.lua:223:8403"]=true; 
      u.al, u.mhp, u.g = 0, 1, 10 ^ 9
      u.empty = 1
      return u
    end
    local s = B.foe_stats(st, d)
    local dm = st.dm or { hp = 1, atk = 1 }
    u.hp = B.floor(s.hp * (dm.hp or 1) + 0.5)
    if u.hp < 1 then B.__r23_cov.branches["20-state.lua:231:8626"]=true;  u.hp = 1 end
    u.mhp = u.hp
    u.ay, u.ym = s.ay, s.ay
    u.sp, u.cs, u.de = s.sp, s.atk * (dm.atk or 1), s.de
    u.ph = d.ph2 and 1 or 0
    u.rd = (d.grade == "boss") and 1 or 0   -- 레이드 감경(FORMULA.md): 구역 보스만 약화·지연·표식을 절반만 받는다
    u.add = (d.grade == "minion") and 1 or 0
    return u
  end
  if st.foe and not B.has(st.foe, i - 4) then B.__r23_cov.branches["20-state.lua:240:8971"]=true;    -- 이번 전투에 안 나오는 적 자리
    u.al, u.mhp, u.g = 0, 1, 10 ^ 9
    u.empty = 1
    return u
  end
  local d = B.DEF[i]
  local s = B.enemy_stats(d.kind or "mob", st.el or 40, st.star or 1)   -- 수치는 의뢰 레벨(표시 레벨의 +1·+2 는 이름표뿐 — 시험판 2와 같다)
  local dm = st.dm or { hp = 1, atk = 1 }
  local tu = (st.foe and B.TUNE_STAR[st.star or 1]) or B.TUNE   -- 의뢰 전투는 ★별 · 시험 하네스(기본 파티)는 시험판 2 값
  u.hp = B.floor(s.hp * d.hpm * tu.hp * (dm.hp or 1) + 0.5)
  u.mhp = u.hp
  u.ay, u.ym = s.ay, s.ay
  u.sp, u.cs, u.de = d.spd, s.atk * d.am * tu.atk * (dm.atk or 1), s.de
  return u
end

-- 이어 받기(대던전 탐색 — design/DUNGEON.md [확정 10-10]): carry.hp[i] · carry.mp[i] 는 앞 전투가 끝날 때의 값(없으면 가득).
-- hp ≤ 0 이면 쓰러진 채 이어진다(부상 이탈 — 휴식 · 붕대로 일으킨다). 최대치는 새로 센 값이 정한다(넘으면 깎는다).
function B.apply_carry(st, c) B.__r23_cov.calls["20-state.lua:258"]=true; 
  for i = 1, 4 do B.__r23_cov.branches["20-state.lua:259:9762"]=true; 
    local u = st.u[i]
    if u and u.empty ~= 1 then B.__r23_cov.branches["20-state.lua:261:9813"]=true; 
      local h, m = c.hp and tonumber(c.hp[i]), c.mp and tonumber(c.mp[i])
      if h then B.__r23_cov.branches["20-state.lua:263:9903"]=true; 
        if h <= 0 then B.__r23_cov.branches["20-state.lua:264:9926"]=true; 
          u.hp, u.al, u.g = 0, 0, 10 ^ 9
        else B.__r23_cov.branches["20-state.lua:266:9980"]=true; 
          u.hp = math.max(1, math.min(u.mhp, math.floor(h)))
        end
      end
      if m then B.__r23_cov.branches["20-state.lua:270:10079"]=true;  u.mp = math.max(0, math.min(u.mmp, math.floor(m))) end
    end
  end
end

-- 새 전투. bn = 전투 번호(씨앗) · dm = 난이도 배율 · o = { pm = 파티(없으면 기본), el = 적 레벨, star = ★, foe = 옛 고정 편성(자리 번호),
--   enc = 조합 결과(27-compose B.compose — 적 id 목록 fl · 등급 덮어쓰기 fg · 심층 dk/dc · 레이드 raid · 대던전 dn …) }
function B.fresh(bn, dm, o) B.__r23_cov.calls["20-state.lua:277"]=true; 
  o = o or {}
  local enc = o.enc
  local st = { ver = B.VER, bn = bn, seed = 20261007 + bn * 7919, n = 0, rs = 1, u = {}, cur = 0, q = {},
    pend = 0, log = {}, over = "", sent = 0, tk = 0, rd = 0, nd = 0, res = "", kill = "",
    dm = dm and { hp = dm.hp or 1, atk = dm.atk or 1 } or nil,
    pm = o.pm or B.DEFAULT_PM, el = o.el or 40, star = o.star or 1, foe = o.foe }
  if enc then B.__r23_cov.branches["20-state.lua:284:10776"]=true; 
    local fl, fg = {}, {}
    for j = 1, enc.ne do B.__r23_cov.branches["20-state.lua:286:10829"]=true;  fl[j] = enc.fl[j] or ""; fg[j] = enc.fg and enc.fg[j] or "" end
    st.enc, st.fl, st.fg, st.ne = enc, fl, fg, enc.ne
    st.dk, st.dc, st.raid, st.dn, st.zk = enc.dk or 0, enc.dc or 0, enc.raid and 1 or 0, enc.dn, enc.zk
    st.foe = {}
    for j = 1, enc.ne do B.__r23_cov.branches["20-state.lua:290:11092"]=true;  if fl[j] ~= "" then B.__r23_cov.branches["20-state.lua:290:11110"]=true;  st.foe[#st.foe + 1] = j end end
    if o.star == nil and enc.star then B.__r23_cov.branches["20-state.lua:291:11181"]=true;  st.star = enc.star end
  end
  st.K = B.K_of(st.el)
  B.bind(st)
  local nu = 4 + (st.ne or 4)
  for i = 1, nu do B.__r23_cov.branches["20-state.lua:296:11297"]=true;  st.u[i] = B.blank_u(st, i) end
  if o.carry then B.__r23_cov.branches["20-state.lua:297:11344"]=true;  B.apply_carry(st, o.carry) end   -- 대던전 탐색: 앞 전투의 HP · MP 를 이어 받는다(77-explore)
  B.begin_ev(st)
  B.rbegin(st)
  for i = 5, nu do B.__r23_cov.branches["20-state.lua:300:11476"]=true; 
    if not st.fl or st.u[i].empty ~= 1 then B.__r23_cov.branches["20-state.lua:301:11518"]=true;  st.u[i].it = B.pick_target(st, i) end
  end
  if B.foe_start then B.__r23_cov.branches["20-state.lua:303:11584"]=true;  B.foe_start(st) end
  B.say(st, B.U(st.raid == 1 and "레이드 전투 시작. 보스의 행동이 <b>예고</b>된다. 약점은 모두 보인다." or "전투 시작. 적의 행동이 <b>예고</b>된다. 약점은 모두 보인다."), 0.2)
  B.fire(st, "start")
  B.run(st)
  st.first = 1
  if st.ev and #st.ev.list == 0 then B.__r23_cov.branches["20-state.lua:308:11820"]=true;  st.ev = nil end
  return st
end

-- 같은 파티·같은 적으로 다시(전투 번호만 +1)
function B.again(st) B.__r23_cov.calls["20-state.lua:313"]=true; 
  local n = B.fresh((st.bn or 0) + 1, st.dm, { pm = st.pm, el = st.el, star = st.star, foe = (not st.enc) and st.foe or nil, enc = st.enc })
  n.rg, n.qid, n.place, n.sid = st.rg, st.qid, st.place, st.sid
  return n
end

-- 같은 전투 번호로 처음부터(첫 화면이 비었을 때 다시 그리기용)
function B.redo(st) B.__r23_cov.calls["20-state.lua:320"]=true; 
  local n = B.fresh(st.bn or 0, st.dm, { pm = st.pm, el = st.el, star = st.star, foe = (not st.enc) and st.foe or nil, enc = st.enc })
  n.rg, n.qid, n.place, n.sid = st.rg, st.qid, st.place, st.sid
  return n
end

-- 옛 전투 저장(VER 2)을 지금 꼴로: 아군 종족·계통·국가 표식(u.rc/ln/na)은 6차 검수 #1 때문에 st.pm 으로 다시 붙인다
-- (옛 저장에는 표식이 없거나 문자열이 아니었다). 적 칸은 옛 고정 4칸이라 st.fl 이 없는 채로 둔다 — 엔진이 옛 편성으로 읽는다.
function B.migrate(t) B.__r23_cov.calls["20-state.lua:328"]=true; 
  if t.ver == 2 and type(t.u) == "table" and #t.u == 8 and type(t.pm) == "table" then B.__r23_cov.branches["20-state.lua:329:12671"]=true; 
    for i = 1, 4 do B.__r23_cov.branches["20-state.lua:330:12693"]=true; 
      local u, m = t.u[i], t.pm[i]
      if type(u) == "table" then B.__r23_cov.branches["20-state.lua:332:12759"]=true; 
        if type(u.rc) ~= "string" or type(u.ln) ~= "string" or type(u.na) ~= "string" then B.__r23_cov.branches["20-state.lua:333:12850"]=true; 
          local r, l, n = "", "", ""
          if type(m) == "table" and m.id ~= "" and B.tr_ids then B.__r23_cov.branches["20-state.lua:335:12952"]=true;  r, l, n = B.tr_ids(m) end
          u.rc, u.ln, u.na = r, l, n
        end
        if type(u.bx) ~= "number" then B.__r23_cov.branches["20-state.lua:338:13066"]=true;  u.bx = 0 end
        if type(u.x) ~= "table" then B.__r23_cov.branches["20-state.lua:339:13116"]=true;  u.x = {} end
      end
    end
    t.ver = B.VER
  end
  return t
end

function B.load(id) B.__r23_cov.calls["20-state.lua:347"]=true; 
  local raw = getChatVar(id, B.KEY)
  local ok, t = pcall(json.decode, raw)
  if ok and type(t) == "table" then B.__r23_cov.branches["20-state.lua:350:13319"]=true;  B.migrate(t) end
  if not ok or type(t) ~= "table" or t.ver ~= B.VER or type(t.u) ~= "table" or #t.u ~= 4 + (tonumber(t.ne) or 4) or type(t.pm) ~= "table" then B.__r23_cov.branches["20-state.lua:351:13479"]=true; 
    t = B.fresh(0)
  else B.__r23_cov.branches["20-state.lua:353:13505"]=true; 
    B.bind(t)
  end
  return t
end

function B.save(id, st) B.__r23_cov.calls["20-state.lua:359"]=true; 
  setChatVar(id, B.KEY, json.encode(st))
end

-- 마지막 캐릭터 메시지 자리. 길이를 모르는 호스트면 nil.
function B.last_char(id) B.__r23_cov.calls["20-state.lua:364"]=true; 
  if B.NO_CHAT_LEN then B.__r23_cov.branches["20-state.lua:365:13697"]=true;  return nil end
  for i = getChatLength(id) - 1, 0, -1 do B.__r23_cov.branches["20-state.lua:366:13756"]=true; 
    if getChatRole(id, i) == "char" then B.__r23_cov.branches["20-state.lua:367:13795"]=true;  return i end
  end
  return -1
end
