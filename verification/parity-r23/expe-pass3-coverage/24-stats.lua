-- ===== 레벨별 능력치(정본 design/stats.json — 표는 05-gen.lua 의 B.CURVES · B.CLS · B.STARS · B.ENEMY_STD) =====
-- 밸런스 시뮬레이터(proto/sim_traits/sim.py party_unit · enemy_unit)와 같은 식이다. 바꾸면 둘 다.

function B.fc(name, L, m) B.__expe_cov.calls["24-stats.lua:4"]=true; 
  local c = B.CURVES[name]
  local x = (L or 1) - 1
  return 1 + (m or 1) * (c.a * x + c.b * x * x)
end

B.LINE_KEY = { ["힘"] = "str", ["민첩"] = "agi", ["지능"] = "int" }

-- 직업 id(또는 한글 이름) → B.CLS 항목
function B.cls_of(cls) B.__expe_cov.calls["24-stats.lua:13"]=true; 
  if B.CLS[cls] then B.__expe_cov.branches["24-stats.lua:14:449"]=true;  return B.CLS[cls] end
  for _, c in pairs(B.CLS) do B.__expe_cov.branches["24-stats.lua:15:503"]=true;  if c.name == cls then B.__expe_cov.branches["24-stats.lua:15:523"]=true;  return c end end
  return nil
end

-- cls = 직업 id/이름, L = 레벨, cid = 동료 id(페르소나는 nil — 보정 없음)
-- 돌려주는 값: hp · mp · cs(주 능력치 = 공격 계수) · ag(민첩) · de(방어) · sp(속도) · cr(치명%) · str · agi · int · def
function B.party_stats(cls, L, cid) B.__expe_cov.calls["24-stats.lua:21"]=true; 
  local c = B.cls_of(cls)
  if not c then B.__expe_cov.branches["24-stats.lua:23:794"]=true;  return nil end
  L = math.max(1, math.min(B.LEVEL_MAX or 40, tonumber(L) or 1))
  local b, g = c.base, c.grow
  local mod = (cid and B.CAST and B.CAST[cid] and B.CAST[cid].mod) or {}
  local function st(key, curve) B.__expe_cov.calls["24-stats.lua:27"]=true;  return b[key] * (1 + (mod[key] or 0) / 100) * B.fc(curve, L, g[key]) end
  local s = { str = st("str", "atk"), agi = st("agi", "atk"), int = st("int", "atk") }
  local o = {
    hp = math.floor(st("hp", "hp") + 0.5), mp = math.floor(st("mp", "mp") + 0.5),
    de = st("def", "def"), ag = s.agi,
    sp = b.spd + (mod.spd or 0) + B.CURVES.spd.add * (L - 1),
    cr = (b.crit or 0) + (mod.crit or 0),
    str = s.str, agi = s.agi, int = s.int,
  }
  o.def = o.de
  o.cs = s[B.LINE_KEY[c.line] or "str"]
  return o
end

-- 같은 레벨 표준 적의 방어 상수(피해 = 공격 × K / (K + 방어))
function B.K_of(L) B.__expe_cov.calls["24-stats.lua:42"]=true; 
  return B.FM.def_k_ratio * B.FM.def_std_base * B.fc("def", L or 1)
end

-- 적 수치. kind = mob · elite · boss, star = 의뢰 ★(1~4)
B.EKIND = { mob = { 1.0, 1.0 }, elite = { 3.5, 1.2 }, boss = { 8.0, 1.35 } }
function B.enemy_stats(kind, L, star) B.__expe_cov.calls["24-stats.lua:48"]=true; 
  local s = B.STARS[star or 1] or B.STARS[1]
  local fa, fd = B.fc("atk", L), B.fc("def", L)
  local k = B.EKIND[kind] or B.EKIND.mob
  local E = B.ENEMY_STD
  return {
    hp = E.hp * fa * k[1] * s.hp,
    atk = E.str * 2 * fa * k[2] * s.atk,
    de = E.def * fd,
    ay = B.GAUGE[kind] or B.GAUGE.mob,
    sp = E.spd,
  }
end

-- ---------- 조합 전투의 적 수치(정본 design/enemies.json · ENEMIES.md 「수치」 · 「끝없는 층」) ----------
-- 적 HP = 표준 HP(레벨) × 역할 × 등급 × ★ 배수(stats.json meta.stars) × tune.star(★별 보정 = B.TUNE_FLOOR) × 구역 보정(zones[].tune / rifts[].tune)
-- 28층부터(st.dk = k = ⌈(층 − 27) ÷ 3⌉ ≥ 1)는 ★ 배수(stats.json) 대신 ★9 값에서 이어 오른다: HP ×3.0·1.12^k · 공격 ×1.8·1.05^k · 보상 ×16·1.10^k.
-- 🔴 「층이 깊어질수록 세진다」(검수 6차 #11)는 ★ 배수 · tune.star · deep 이 층마다 줄지 않는다는 뜻이다 — 구역 보정은 그 구역 적 풀의 거칠기를 맞추는 값이라 따로 둔다.
function B.star_mult(st) B.__expe_cov.calls["24-stats.lua:66"]=true; 
  local k = st.dk or 0
  if k > 0 then B.__expe_cov.branches["24-stats.lua:68:2683"]=true; 
    local D, tu = B.DEEP, B.TUNE_FLOOR[9]
    return { hp = D.hp0 * D.hpk ^ k * tu.hp, atk = D.atk0 * D.atk1 ^ k * tu.atk, reward = D.reward0 * D.reward1 ^ k }
  end
  local star = math.max(1, math.min(9, st.star or 1))
  local s, tu = B.STARS[star], B.TUNE_FLOOR[star]
  return { hp = s.hp * tu.hp, atk = s.atk * tu.atk, reward = s.reward }
end

-- 이 전투의 구역(대던전 구역 id 또는 rift_<id>) 보정표 { hp, atk, chief_hp, chief_atk, boss_hp, boss_atk }
function B.zone_tune(st) B.__expe_cov.calls["24-stats.lua:78"]=true; 
  local zk = st.zk
  local z = zk and (B.ZONES[zk] or (string.sub(zk, 1, 5) == "rift_" and B.RIFTS[string.sub(zk, 6)])) or nil
  return (z and z.tune) or { hp = 1, atk = 1, chief_hp = 1, chief_atk = 1, boss_hp = 1, boss_atk = 1 }
end

-- ---------- 층별 최종 배율 — 종류(일반 · 우두머리 · 구역 보스)마다 층 번호만의 매끄러운 곡선(design/enemies.json tune.curve → B.CURVE) ----------
-- kind = "normal"(일반 · 정예 · 하수인) · "chief"(1·2번째 층 우두머리) · "boss"(구역 보스). 곡선 = 제어점 [층, HP 배율] ≤ 4개를 log 척도로 이은 꺾은선(첫 점 앞은 평평, 끝점 뒤는 마지막 구간 기울기로 이어 감).
-- 공격 배율 = HP 배율 ^ pow. 구역은 세기를 바꾸지 않는다(약점 · 행동 같은 특징만). 곡선이 단조라 아래 클램프는 평소에 일할 일이 없다(harness_raid 가 1~420층에서 확인).
local function curve_hp(c, floor) B.__expe_cov.calls["24-stats.lua:87"]=true; 
  local p = c.pts
  local n = #p
  if floor <= p[1][1] then B.__expe_cov.branches["24-stats.lua:90:3860"]=true;  return p[1][2] end
  for i = 2, n do B.__expe_cov.branches["24-stats.lua:91:3899"]=true; 
    if floor <= p[i][1] then B.__expe_cov.branches["24-stats.lua:92:3926"]=true; 
      local t = (floor - p[i - 1][1]) / (p[i][1] - p[i - 1][1])
      return math.exp(math.log(p[i - 1][2]) + t * (math.log(p[i][2]) - math.log(p[i - 1][2])))
    end
  end
  local slope = (math.log(p[n][2]) - math.log(p[n - 1][2])) / (p[n][1] - p[n - 1][1])
  return p[n][2] * math.exp(slope * (floor - p[n][1]))
end
B.curve_hp = curve_hp   -- 탐색 전투 배율(B.EX.FOE — 77-explore)도 같은 꺾은선 읽기를 쓴다
local function floor_raw(floor, kind) B.__expe_cov.calls["24-stats.lua:101"]=true; 
  local c = B.CURVE[kind] or B.CURVE.normal
  local h = curve_hp(c, floor)
  return h, h ^ (c.pow or 0.55)
end
local FM_CACHE = {}
function B.floor_final_reset() B.__expe_cov.calls["24-stats.lua:107"]=true;  FM_CACHE = {} end   -- 곡선을 실행 중에 바꿔 볼 때(tune_floor.mjs)
-- 돌려주는 값: hp, atk, 원래 값(raw)에서 올렸는지(clamped)
function B.floor_final(floor, kind) B.__expe_cov.calls["24-stats.lua:109"]=true; 
  floor = math.max(1, math.floor(tonumber(floor) or 1))
  local c = FM_CACHE[kind]
  if not c then B.__expe_cov.branches["24-stats.lua:112:4755"]=true;  c = { n = 0, hp = {}, atk = {}, raw = {} }; FM_CACHE[kind] = c end
  while c.n < floor do B.__expe_cov.branches["24-stats.lua:113:4847"]=true; 
    local f = c.n + 1
    local info = B.floor_info(f)
    local mine = (kind == "normal") or (kind == B.floor_boss_kind(info))
    local ph, pa = c.hp[c.n] or 0, c.atk[c.n] or 0
    if mine then B.__expe_cov.branches["24-stats.lua:118:5041"]=true; 
      local rh, ra = floor_raw(f, kind)
      c.hp[f], c.atk[f] = math.max(ph, rh), math.max(pa, ra)
      c.raw[f] = (rh < ph - 1e-12 or ra < pa - 1e-12) and 1 or 0
    else B.__expe_cov.branches["24-stats.lua:122:5216"]=true; 
      c.hp[f], c.atk[f], c.raw[f] = ph, pa, 0
    end
    c.n = f
  end
  return c.hp[floor], c.atk[floor], c.raw[floor] == 1
end

-- d = B.DEF[적] (등급 · 역할 · 레벨이 들어 있다)
function B.foe_stats(st, d) B.__expe_cov.calls["24-stats.lua:131"]=true; 
  local L = d.lvn or st.el or 1
  local fa, fd = B.fc("atk", L), B.fc("def", L)
  local r = B.ROLES[d.srole] or B.ROLES["돌격"]
  local g = B.GRADES[d.grade] or B.GRADES.mob
  local sm = B.star_mult(st)
  local zt = B.zone_tune(st)
  local E = B.ENEMY_STD
  local bh, ba = 1, 1   -- 층 끝 보스만 따로 맞추는 손잡이: 우두머리 = 구역 보정 chief_hp/atk · 구역 보스·균열 핵 = boss_hp/atk · 심층은 deep.boss_hp/atk 를 더 곱한다
  if d.grade == "chief" or d.grade == "boss" or d.grade == "core" then B.__expe_cov.branches["24-stats.lua:140:5869"]=true; 
    if d.grade == "chief" then B.__expe_cov.branches["24-stats.lua:141:5900"]=true;  bh, ba = zt.chief_hp or 1, zt.chief_atk or 1 else B.__expe_cov.branches["24-stats.lua:141:5950"]=true;  bh, ba = zt.boss_hp or 1, zt.boss_atk or 1 end
    if (st.dk or 0) > 0 then B.__expe_cov.branches["24-stats.lua:142:6026"]=true;  bh, ba = bh * (B.DEEP.boss_hp or 1), ba * (B.DEEP.boss_atk or 1) end
  end
  local mh, ma = sm.hp * (zt.hp or 1) * bh, sm.atk * (zt.atk or 1) * ba
  local fl = st.enc and st.enc.floor
  if fl then B.__expe_cov.branches["24-stats.lua:146:6223"]=true;    -- 대던전 층: 최종 배율이 앞 층보다 줄지 않게(층 번호가 없는 균열 의뢰 · 시험 전투는 그대로)
    local kind = (d.grade == "chief") and "chief" or ((d.grade == "boss") and "boss" or "normal")
    mh, ma = B.floor_final(fl, kind)
    if kind == "chief" then B.__expe_cov.branches["24-stats.lua:149:6446"]=true;    -- 구역마다 우두머리 세기를 따로 맞춘다(enemies.json zones[].tune 의 chief_hp/atk — 그 구역 우두머리 풀이 약하거나 센 만큼. 심층에서도 같은 우두머리라 그대로 따른다)
      mh, ma = mh * (zt.chief_hp or 1), ma * (zt.chief_atk or 1)
      if (st.dk or 0) > 0 then B.__expe_cov.branches["24-stats.lua:151:6659"]=true;  mh, ma = mh * (zt.chief_deep_hp or 1), ma * (zt.chief_deep_atk or 1) end   -- 심층(28층~)에서만 더 곱하는 구역별 보정
    elseif kind == "boss" and (st.dk or 0) == 0 then B.__expe_cov.branches["24-stats.lua:152:6815"]=true;    -- 1~27층 구역 보스: boss_hp/atk (심층은 아래 deep 이 대신한다)
      mh, ma = mh * (zt.boss_hp or 1), ma * (zt.boss_atk or 1)
    end
    if kind == "boss" and (st.dk or 0) > 0 and d.deep then B.__expe_cov.branches["24-stats.lua:155:6996"]=true;  mh, ma = mh * (d.deep.hp or 1), ma * (d.deep.atk or 1) end   -- 심층(28층~) 구역 보스만: 보스마다 행동이 달라 같은 곡선에서도 승률이 갈리므로 enemies.json 의 boss.deep {hp, atk} 로 맞춘다(곡선 자체는 그대로 단조)
    local dn = st.enc.dn
    if dn and dn.kind == "explore" and B.EX and B.EX.FOE then B.__expe_cov.branches["24-stats.lua:157:7250"]=true;    -- 탐색 전투(층 보스 아님)는 자기 곡선(B.EX.FOE — 77-explore)을 쓴다: 층 일반 곡선을 대신한다(호위 · 하수인은 층 보스 전투라 그대로)
      local F = B.EX.FOE
      local el = (d.grade == "elite") and (F.elite or 1) or 1
      local pw = F.pow or 0.55
      local h = curve_hp(F, fl)
      local o3 = (((st.enc.order or 1) >= 3) and (F.ord3 or 1) or 1) * ((F.zone and F.zone[st.zk]) or 1)   -- 구역 마지막 층(순서 3)은 위협 한도가 높아 적이 더 많이 나온다 — 그만큼 한 마리를 약하게 · F.zone[구역] = 그 구역의 적 풀이 유난히 거칠 때 구역별 보정
      mh, ma = h * el * o3, (h ^ pw) * ((el * o3) ^ pw)
    end
    local ea = dn and B.EX and B.EX.EARLY
    local newbie = dn and B.EX and B.EX.NEWBIE and B.EX.NEWBIE[dn.party_n]
    local scale = newbie and newbie[dn.kind]
    if scale and (fl <= 3 or (ea and fl < ea.to)) then B.__expe_cov.branches["24-stats.lua:168:7980"]=true;    -- 소인원 보정: 1~3층 그대로, 그 뒤로는 입문 구간 끝(ea.to)까지 1배로 서서히 줄인다(4층 절벽 없게)
      local k = (fl <= 3) and 1 or (1 - (fl - 3) / (ea.to - 3))
      mh, ma = mh * scale[1] ^ k, ma * scale[2] ^ k
    end
    if ea and fl < ea.to then B.__expe_cov.branches["24-stats.lua:172:8202"]=true;    -- 입문 구간(Lv10 ≈ 7층 전): 1층 배율에서 ea.to 층의 1배까지 오른다(ea.curve > 1 이면 앞 층에서 더 오래 낮게) — 힐러 없는 파티도 앞 층을 넘게
      local t = ((fl - 1) / (ea.to - 1)) ^ (ea.curve or 1)
      mh, ma = mh * ea.hp ^ (1 - t), ma * ea.atk ^ (1 - t)
    end
  end
  return {
    hp = E.hp * fa * r.hp * g.hp * mh,
    atk = E.str * 2 * fa * r.atk * g.atk * ma,
    de = E.def * fd * r.de,
    ay = d.gauge or g.gauge or r.gauge,
    sp = E.spd * r.spd,
  }
end
