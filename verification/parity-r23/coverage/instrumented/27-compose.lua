-- ===== 적 조합기 · 층 규칙 (정본 design/ENEMIES.md 「한 전투의 적 조합」 · 「끝없는 층」 · design/enemies.json) =====
-- B.compose(seed, ctx) → 한 전투의 적 편성. 난수는 seed 하나에서 나오는 국소 Park-Miller 뿐이다(같은 seed · 같은 ctx = 같은 편성).
--   ctx = { kind = "battle" | "elite" | "chief" | "boss" | "rift_core",   (균열 핵은 "rift_core"; 브리프의 "rift" = rift_id 를 준 battle/elite/rift_core)
--           zone = 구역 id(B.ZONE_ORDER) 또는 floor = 층 번호(구역 · 구역 안 순서 · 심층 규칙으로 정한다),
--           rift_id = 균열 id(있으면 그 균열의 계통 + 공통), stars = 균열 의뢰 ★(1~3 — 위협 한도의 층 순서로 쓴다),
--           order = 구역 안 층 순서(1~3 — floor 가 없을 때), party_n = 출전 인원(1~4 — 적 수를 맞춘다) }
--   돌려주는 값 = { kind, tmpl, zone, order, fl = {적 id…}, fg = {등급 덮어쓰기…}, ne = 적 칸 수, raid = bool, star, dk, dc, floor, n, nonraid_union }
-- 지켜야 할 것(전부 ENEMIES.md): 전열 ≥ 1 · 지원 ≤ 1 · 소환 ≤ 1 · 같은 적 ≤ 3(무리 제외) · 충전은 정예/보스만 · 한 전투에 충전 ≤ 1 ·
--   약점 합집합 ≥ 4(일반·정예만 — 검수 6차 #14) · 위협 점수 ≤ 층 한도 · 공통 계통 ≤ 1.

local function mkrng(seed) B.__r23_cov.calls["27-compose.lua:11"]=true; 
  local s = (math.floor(tonumber(seed) or 1) % 2147483646) + 1
  for _ = 1, 4 do B.__r23_cov.branches["27-compose.lua:13:1010"]=true;  s = (s * 16807) % 2147483647 end
  return function() B.__r23_cov.calls["27-compose.lua:14"]=true;  s = (s * 16807) % 2147483647; return s / 2147483647 end
end
B.mkrng = mkrng

-- ---------- 층 번호 → 구역 · 순서 · 심층 ----------
function B.floor_info(floor) B.__r23_cov.calls["27-compose.lua:19"]=true; 
  floor = math.max(1, math.floor(tonumber(floor) or 1))
  if floor <= 27 then B.__r23_cov.branches["27-compose.lua:21:1290"]=true; 
    local zi = (floor - 1) // 3 + 1
    return { floor = floor, zi = zi, zone = B.ZONE_ORDER[zi], ord = (floor - 1) % 3 + 1, dk = 0, dc = 0 }
  end
  local zi = ((floor - 28) // 3) % 9 + 1
  return { floor = floor, zi = zi, zone = B.ZONE_ORDER[zi], ord = (floor - 28) % 3 + 1, dk = (floor - 25) // 3, dc = (floor - 28) // 27 + 1 }
end
-- 층의 ★ (심층은 ★9 값에서 이어 오른다 — 보상 표시용)
function B.floor_star(info) B.__r23_cov.calls["27-compose.lua:29"]=true;  return (info.dk > 0) and 9 or B.ZONES[info.zone].star end
-- 층 끝 보스 종류: 구역 안 1·2층 = 우두머리, 3층 = 구역 보스
function B.floor_boss_kind(info) B.__r23_cov.calls["27-compose.lua:31"]=true;  return (info.ord >= 3) and "boss" or "chief" end
-- 적 레벨: 파티 평균을 따라가되 구역 안 순서만큼 +(0~2), 구역 하한 ~ 레벨 상한 사이(레벨 상한 40). 심층은 늘 상한.
function B.floor_level(avg, info) B.__r23_cov.calls["27-compose.lua:33"]=true; 
  local lo = (info.dk > 0) and B.LEVEL_MAX or (B.ZONES[info.zone].lv_lo or 1)
  local v = math.floor((tonumber(avg) or 1) + 0.5) + (info.ord - 1)
  return math.max(lo, math.min(B.LEVEL_MAX, v))
end
-- 층의 ★ 배수(HP · 공격 · 보상) — 층이 깊어질수록 줄어들지 않아야 한다(harness_raid 가 확인)
function B.floor_mult(floor) B.__r23_cov.calls["27-compose.lua:39"]=true; 
  local info = B.floor_info(floor)
  local m = B.star_mult({ star = B.floor_star(info), dk = info.dk })
  if info.dk == 0 then B.__r23_cov.branches["27-compose.lua:42:2405"]=true; 
    local next_reward = (info.zi < 9) and B.STARS[info.zi + 1].reward or B.DEEP.reward0 * B.DEEP.reward1
    m.reward = m.reward * (next_reward / m.reward) ^ ((info.ord - 1) / 3)
  end
  return m
end

-- ---------- 풀 ----------
local POOLS
local function pools() B.__r23_cov.calls["27-compose.lua:51"]=true; 
  if POOLS then B.__r23_cov.branches["27-compose.lua:52:2684"]=true;  return POOLS end
  POOLS = { mobs = {}, elites = {}, common_mobs = {}, common_elites = {}, all_elites = {} }
  for _, id in ipairs(B.FOE_ORDER) do B.__r23_cov.branches["27-compose.lua:54:2833"]=true; 
    local f = B.FOES[id]
    local z = f.zone
    local common = (z == "common")
    if f.grade == "mob" or f.grade == "swarm" then B.__r23_cov.branches["27-compose.lua:58:2963"]=true; 
      local t = common and POOLS.common_mobs or (POOLS.mobs[z] or {})
      if not common then B.__r23_cov.branches["27-compose.lua:60:3058"]=true;  POOLS.mobs[z] = t end
      t[#t + 1] = id
    elseif f.grade == "elite" then B.__r23_cov.branches["27-compose.lua:62:3136"]=true; 
      if common then B.__r23_cov.branches["27-compose.lua:63:3157"]=true; 
        POOLS.common_elites[#POOLS.common_elites + 1] = id
      else B.__r23_cov.branches["27-compose.lua:65:3227"]=true; 
        POOLS.elites[z] = POOLS.elites[z] or {}
        POOLS.elites[z][#POOLS.elites[z] + 1] = id
      end
      if string.sub(z, 1, 5) ~= "rift_" then B.__r23_cov.branches["27-compose.lua:69:3381"]=true;  POOLS.all_elites[#POOLS.all_elites + 1] = id end   -- 빌려 올 정예: 대던전 구역 + 공통 (균열의 정예는 균열에서만)
    end
  end
  return POOLS
end

local function has_summon(f) B.__r23_cov.calls["27-compose.lua:75"]=true; 
  for _, a in ipairs(f.acts) do B.__r23_cov.branches["27-compose.lua:76:3569"]=true;  if a.kind == "summon" then B.__r23_cov.branches["27-compose.lua:76:3594"]=true;  return true end end
  if f.ph2 then B.__r23_cov.branches["27-compose.lua:77:3630"]=true; 
    for _, a in ipairs(f.ph2.acts) do B.__r23_cov.branches["27-compose.lua:78:3670"]=true;  if a.kind == "summon" then B.__r23_cov.branches["27-compose.lua:78:3695"]=true;  return true end end
    if f.ph2.entry and f.ph2.entry.kind == "summon" then B.__r23_cov.branches["27-compose.lua:79:3772"]=true;  return true end
  end
  return false
end
local function has_charge(f) B.__r23_cov.calls["27-compose.lua:83"]=true; 
  for _, a in ipairs(f.acts) do B.__r23_cov.branches["27-compose.lua:84:3876"]=true;  if a.kind == "charge" then B.__r23_cov.branches["27-compose.lua:84:3901"]=true;  return true end end
  return false
end

-- 한 전투 편성(적 id 목록 + 등급 덮어쓰기)의 검사. 위반 개수와 이유를 돌려준다.
function B.check_comp(fl, fg, o) B.__r23_cov.calls["27-compose.lua:89"]=true; 
  o = o or {}
  local bad = {}
  local front, sup, sum, charge, common = 0, 0, 0, 0, 0
  local cnt, union, nu = {}, {}, 0
  local threat = 0
  for k, id in ipairs(fl) do B.__r23_cov.branches["27-compose.lua:95:4198"]=true; 
    local f = B.FOES[id]
    local g = (fg and fg[k] ~= "" and fg[k]) or f.grade
    if f.row == "전열" then B.__r23_cov.branches["27-compose.lua:98:4303"]=true;  front = front + 1 end
    if f.role == "지원" then B.__r23_cov.branches["27-compose.lua:99:4352"]=true;  sup = sup + 1 end
    if f.role == "소환" or has_summon(f) then B.__r23_cov.branches["27-compose.lua:100:4414"]=true;  sum = sum + 1 end
    if has_charge(f) then B.__r23_cov.branches["27-compose.lua:101:4458"]=true;  charge = charge + 1 end
    if f.zone == "common" then B.__r23_cov.branches["27-compose.lua:102:4513"]=true;  common = common + 1 end
    cnt[id] = (cnt[id] or 0) + 1
    if cnt[id] > 3 and f.grade ~= "swarm" then B.__r23_cov.branches["27-compose.lua:104:4617"]=true;  bad[#bad + 1] = "같은 적 3 초과" end
    for _, w in ipairs(f.wk) do B.__r23_cov.branches["27-compose.lua:105:4683"]=true;  if not union[w] then B.__r23_cov.branches["27-compose.lua:105:4702"]=true;  union[w] = true; nu = nu + 1 end end
    if g == "elite" or g == "eliteb" then B.__r23_cov.branches["27-compose.lua:106:4781"]=true;  threat = threat + B.THREAT.elite
    elseif g == "chief" or g == "chiefb" or g == "boss" or g == "core" then B.__r23_cov.branches["27-compose.lua:107:4890"]=true;  threat = threat + 0
    else B.__r23_cov.branches["27-compose.lua:108:4919"]=true;  threat = threat + (B.ROLES[f.role] or B.ROLES["돌격"]).threat end
  end
  if front < 1 then B.__r23_cov.branches["27-compose.lua:110:5009"]=true;  bad[#bad + 1] = "전열 없음" end
  if sup > 1 then B.__r23_cov.branches["27-compose.lua:111:5055"]=true;  bad[#bad + 1] = "지원 2 이상" end
  if sum > 1 then B.__r23_cov.branches["27-compose.lua:112:5103"]=true;  bad[#bad + 1] = "소환 2 이상" end
  if charge > 1 then B.__r23_cov.branches["27-compose.lua:113:5154"]=true;  bad[#bad + 1] = "충전 2 이상" end
  if common > 1 then B.__r23_cov.branches["27-compose.lua:114:5205"]=true;  bad[#bad + 1] = "공통 계통 2 이상" end
  if o.union and nu < (o.umin or 4) then B.__r23_cov.branches["27-compose.lua:115:5279"]=true;  bad[#bad + 1] = "약점 합집합 " .. (o.umin or 4) .. " 미만" end
  if o.limit and threat > o.limit + 1e-9 then B.__r23_cov.branches["27-compose.lua:116:5381"]=true;  bad[#bad + 1] = "위협 점수 초과" end
  return bad, { threat = threat, union = nu, front = front }
end

-- 위협 한도(일반 3 + 0.5 × (순서 − 1) · 정예 +2)
function B.threat_limit(order, elite) B.__r23_cov.calls["27-compose.lua:121"]=true; 
  local T = B.THREAT
  return T.base + T.per_order * ((order or 1) - 1) + (elite and T.elite_bonus or 0) + (T.zone_bonus or 0)
end

local function pickl(rng, list) B.__r23_cov.calls["27-compose.lua:126"]=true; 
  local k = math.floor(rng() * #list) + 1
  if k > #list then B.__r23_cov.branches["27-compose.lua:128:5782"]=true;  k = #list end
  return list[k]
end

-- 후보 중 규칙 위반 없이 들어갈 수 있는 것
local function fits(f, cur, spec) B.__r23_cov.calls["27-compose.lua:133"]=true; 
  if spec.grade then B.__r23_cov.branches["27-compose.lua:134:5901"]=true; 
    local ok = false
    for _, g in ipairs(spec.grade) do B.__r23_cov.branches["27-compose.lua:136:5962"]=true;  if g == f.grade then B.__r23_cov.branches["27-compose.lua:136:5981"]=true;  ok = true end end
    if not ok then B.__r23_cov.branches["27-compose.lua:137:6018"]=true;  return false end
  end
  if spec.role then B.__r23_cov.branches["27-compose.lua:139:6061"]=true; 
    local ok = false
    for _, r in ipairs(spec.role) do B.__r23_cov.branches["27-compose.lua:141:6121"]=true;  if r == f.role then B.__r23_cov.branches["27-compose.lua:141:6139"]=true;  ok = true end end
    if not ok then B.__r23_cov.branches["27-compose.lua:142:6176"]=true;  return false end
  end
  if spec.row then B.__r23_cov.branches["27-compose.lua:144:6218"]=true; 
    if (spec.row == "front") ~= (f.row == "전열") then B.__r23_cov.branches["27-compose.lua:145:6271"]=true;  return false end
  end
  -- 지원 ≤ 1 · 소환 ≤ 1 · 공통 ≤ 1 · 같은 적 ≤ 3(무리 제외) · 충전은 정예/보스에 한 명
  local sup, sum, com, same, chg = 0, 0, 0, 0, 0
  for _, id in ipairs(cur) do B.__r23_cov.branches["27-compose.lua:149:6440"]=true; 
    local g = B.FOES[id]
    if g.role == "지원" then B.__r23_cov.branches["27-compose.lua:151:6490"]=true;  sup = sup + 1 end
    if g.role == "소환" or has_summon(g) then B.__r23_cov.branches["27-compose.lua:152:6552"]=true;  sum = sum + 1 end
    if g.zone == "common" then B.__r23_cov.branches["27-compose.lua:153:6601"]=true;  com = com + 1 end
    if id == f.id then B.__r23_cov.branches["27-compose.lua:154:6642"]=true;  same = same + 1 end
    if has_charge(g) then B.__r23_cov.branches["27-compose.lua:155:6688"]=true;  chg = chg + 1 end
  end
  if f.role == "지원" and sup >= 1 then B.__r23_cov.branches["27-compose.lua:157:6750"]=true;  return false end
  if (f.role == "소환" or has_summon(f)) and sum >= 1 then B.__r23_cov.branches["27-compose.lua:158:6824"]=true;  return false end
  if f.zone == "common" and com >= 1 then B.__r23_cov.branches["27-compose.lua:159:6883"]=true;  return false end
  if f.grade ~= "swarm" and same >= 3 then B.__r23_cov.branches["27-compose.lua:160:6943"]=true;  return false end
  if has_charge(f) and chg >= 1 then B.__r23_cov.branches["27-compose.lua:161:6997"]=true;  return false end
  return true
end

local function party_target(n, order, rng, tcount) B.__r23_cov.calls["27-compose.lua:165"]=true; 
  if tcount then B.__r23_cov.branches["27-compose.lua:166:7101"]=true;  return tcount end
  n = math.max(1, math.min(4, n or 4))
  local base = ({ 2, 2, 3, 4 })[n]
  if n >= 2 and (order or 1) >= 2 and rng() < 0.35 then B.__r23_cov.branches["27-compose.lua:169:7249"]=true;  base = base + 1 end
  return math.min(5, base)
end

local FILL = { { role = { "돌격" } }, { role = { "사격", "주술" } }, { role = { "방어", "돌격" } }, { role = { "무리", "돌격" } } }

function B.compose(seed, ctx) B.__r23_cov.calls["27-compose.lua:175"]=true; 
  ctx = ctx or {}
  local rng = mkrng(seed)
  local P = pools()
  local info
  if ctx.floor then B.__r23_cov.branches["27-compose.lua:180:7547"]=true;  info = B.floor_info(ctx.floor) end
  local zone, order = ctx.zone, ctx.order or 1
  local rift = ctx.rift_id and B.RIFTS[ctx.rift_id] or nil
  local dk, dc, flo = 0, 0, ctx.floor
  if info then B.__r23_cov.branches["27-compose.lua:184:7741"]=true;  zone, order, dk, dc = info.zone, info.ord, info.dk, info.dc end
  if rift then B.__r23_cov.branches["27-compose.lua:185:7820"]=true;  order = math.max(1, math.min(3, tonumber(ctx.stars) or 1)) end
  local kind = ctx.kind or "battle"
  local n = math.max(1, math.min(4, tonumber(ctx.party_n) or 4))
  local Z = zone and B.ZONES[zone] or nil
  local star = info and B.floor_star(info) or (Z and Z.star) or math.max(1, math.min(4, tonumber(ctx.stars) or 1))
  if rift then B.__r23_cov.branches["27-compose.lua:190:8156"]=true;  star = math.max(1, math.min(3, tonumber(ctx.stars) or 1)) end
  local zkey = rift and ("rift_" .. rift.id) or zone

  -- 이 전투의 잡몹 / 정예 풀
  local mobs, elites = {}, {}
  if rift then B.__r23_cov.branches["27-compose.lua:195:8338"]=true; 
    for _, id in ipairs(rift.mobs) do B.__r23_cov.branches["27-compose.lua:196:8378"]=true;  mobs[#mobs + 1] = id end
    for _, id in ipairs(P.common_mobs) do B.__r23_cov.branches["27-compose.lua:197:8445"]=true;  mobs[#mobs + 1] = id end
    elites[1] = rift.elite
  else B.__r23_cov.branches["27-compose.lua:199:8502"]=true; 
    for _, id in ipairs(P.mobs[zkey] or {}) do B.__r23_cov.branches["27-compose.lua:200:8551"]=true;  mobs[#mobs + 1] = id end
    for _, id in ipairs(P.common_mobs) do B.__r23_cov.branches["27-compose.lua:201:8618"]=true;  mobs[#mobs + 1] = id end
    local own = P.elites[zkey] or {}
    if #own == 0 then B.__r23_cov.branches["27-compose.lua:203:8700"]=true;  own = P.all_elites end        -- 밑바닥 — 고유 정예가 없다. 다른 구역 정예를 「깊은」 이름으로 세운다
    for _, id in ipairs(own) do B.__r23_cov.branches["27-compose.lua:204:8808"]=true;  elites[#elites + 1] = id end
    for _, id in ipairs(P.common_elites) do B.__r23_cov.branches["27-compose.lua:205:8881"]=true;  elites[#elites + 1] = id end
  end
  local borrowed = (not rift) and (#(P.elites[zkey] or {}) == 0)

  local function result(fl, fg, tmpl, raid) B.__r23_cov.calls["27-compose.lua:209"]=true; 
    local ne = #fl
    local summ = false
    for _, id in ipairs(fl) do B.__r23_cov.branches["27-compose.lua:212:9099"]=true;  if has_summon(B.FOES[id]) then B.__r23_cov.branches["27-compose.lua:212:9128"]=true;  summ = true end end
    if summ then B.__r23_cov.branches["27-compose.lua:213:9165"]=true;  ne = ne + 2 end
    return { kind = kind, tmpl = tmpl, zone = zkey, order = order, fl = fl, fg = fg, ne = ne, raid = raid and true or false,
      star = star, zk = zkey, dk = dk, dc = dc, floor = flo, n = #fl, rift = rift and rift.id or nil }
  end

  -- ---------- 레이드: 우두머리 · 구역 보스 · 균열 핵 ----------
  if kind == "chief" or kind == "boss" or kind == "rift_core" then B.__r23_cov.branches["27-compose.lua:219:9535"]=true; 
    local lead, lg = nil, ""
    if kind == "boss" then B.__r23_cov.branches["27-compose.lua:221:9591"]=true; 
      lead = Z and Z.boss
    elseif kind == "rift_core" then B.__r23_cov.branches["27-compose.lua:223:9653"]=true; 
      lead = rift and rift.core
    else B.__r23_cov.branches["27-compose.lua:225:9694"]=true; 
      local pool = (Z and Z.chiefs) or {}
      if #pool == 0 then B.__r23_cov.branches["27-compose.lua:227:9761"]=true;  pool = P.all_elites; lg = "chiefb" else B.__r23_cov.branches["27-compose.lua:227:9801"]=true;  lg = "chief" end
      lead = pickl(rng, pool)
      if lg == "chief" and (Z and Z.chief_borrow) then B.__r23_cov.branches["27-compose.lua:229:9903"]=true;  lg = "chiefb" end
    end
    if not lead then B.__r23_cov.branches["27-compose.lua:231:9950"]=true;  error("compose: 보스를 정할 수 없다 " .. tostring(kind) .. "/" .. tostring(zkey)) end
    local fl, fg = { lead }, { lg }
    if kind ~= "boss" and not has_summon(B.FOES[lead]) then B.__r23_cov.branches["27-compose.lua:233:10124"]=true; 
      local esc = (n <= 2) and 1 or 2
      local pool = {}
      for _, id in ipairs(mobs) do B.__r23_cov.branches["27-compose.lua:236:10221"]=true;  if B.FOES[id].grade == "mob" then B.__r23_cov.branches["27-compose.lua:236:10253"]=true;  pool[#pool + 1] = id end end
      -- 호위 두 칸: 전열이 하나는 서야 한다(우두머리가 후열이면 호위 한 명은 전열)
      for k = 1, esc do B.__r23_cov.branches["27-compose.lua:238:10362"]=true; 
        local cand = {}
        for _, id in ipairs(pool) do B.__r23_cov.branches["27-compose.lua:240:10423"]=true; 
          local f = B.FOES[id]
          local want_front = (k == 1) and (B.FOES[lead].row ~= "전열")
          if fits(f, fl, {}) and (not want_front or f.row == "전열") then B.__r23_cov.branches["27-compose.lua:243:10593"]=true;  cand[#cand + 1] = id end
        end
        if #cand == 0 then B.__r23_cov.branches["27-compose.lua:245:10657"]=true;  cand = pool end
        fl[#fl + 1] = pickl(rng, cand)
        fg[#fg + 1] = ""
      end
    end
    -- 레이드 화면: 보스 밑 작은 칸은 둘까지 — 우두머리의 호위 둘 / 구역 보스·소환형 우두머리의 하수인 둘(소환형은 호위를 두지 않는다)
    return result(fl, fg, kind, true)
  end

  -- ---------- 일반 · 정예 전투 ----------
  local elite = (kind == "elite")
  local limit = B.threat_limit(order, elite)
  local best, bestscore
  local tc0 = party_target(n, order, rng)
  local tmpls, totw = {}, 0
  for _, tp in ipairs(B.TEMPLATES) do B.__r23_cov.branches["27-compose.lua:260:11135"]=true; 
    local okk = false
    for _, k in ipairs(tp.kinds) do B.__r23_cov.branches["27-compose.lua:262:11193"]=true;  if k == kind then B.__r23_cov.branches["27-compose.lua:262:11209"]=true;  okk = true end end
    if okk and (tp.min_order or 1) <= order then B.__r23_cov.branches["27-compose.lua:263:11277"]=true;  tmpls[#tmpls + 1] = tp; totw = totw + (tp.weight or 1) end
  end
  if #tmpls == 0 then B.__r23_cov.branches["27-compose.lua:265:11364"]=true;  error("compose: 쓸 수 있는 틀이 없다 " .. tostring(kind)) end
  -- 틀의 슬롯 목록을 적 수 tc 에 맞춘다(첫 칸은 틀의 중심이라 늘 남긴다)
  local function build_slots(t, tc) B.__r23_cov.calls["27-compose.lua:267"]=true; 
    local slots = {}
    for _, sp in ipairs(t.slots) do B.__r23_cov.branches["27-compose.lua:269:11561"]=true;  slots[#slots + 1] = sp end
    while #slots > tc and #slots > 1 do B.__r23_cov.branches["27-compose.lua:270:11628"]=true;  table.remove(slots) end
    local ext = 0
    while #slots < tc do B.__r23_cov.branches["27-compose.lua:272:11695"]=true; 
      ext = ext + 1
      slots[#slots + 1] = (elite and { grade = { "mob", "swarm" } }) or FILL[(ext % #FILL) + 1]
    end
    return slots
  end
  for try = 1, 40 do B.__r23_cov.branches["27-compose.lua:278:11863"]=true; 
    local t
    do B.__r23_cov.branches["27-compose.lua:280:11882"]=true;    -- 틀 고르기
      local r = rng() * totw
      for _, tp in ipairs(tmpls) do B.__r23_cov.branches["27-compose.lua:282:11958"]=true; 
        r = r - (tp.weight or 1)
        if r <= 0 then B.__r23_cov.branches["27-compose.lua:284:12012"]=true;  t = tp; break end
      end
      t = t or tmpls[#tmpls]
    end
    -- 위협 한도가 적 수를 정한다: 안 맞는 틀이 이어지면 적 한 마리씩 줄여 본다
    local tc = math.max(2, tc0 - (try - 1) // 10)
    if elite then B.__r23_cov.branches["27-compose.lua:290:12196"]=true;  tc = math.max(2, tc) end
    local slots = build_slots(t, tc)
    local fl, fg = {}, {}
    local okfill = true
    for _, sp in ipairs(slots) do B.__r23_cov.branches["27-compose.lua:294:12344"]=true; 
      local pool = (sp.grade and sp.grade[1] == "elite") and elites or mobs
      local cand = {}
      for _, id in ipairs(pool) do B.__r23_cov.branches["27-compose.lua:297:12477"]=true; 
        if fits(B.FOES[id], fl, sp) then B.__r23_cov.branches["27-compose.lua:298:12516"]=true;  cand[#cand + 1] = id end
      end
      if #cand == 0 then B.__r23_cov.branches["27-compose.lua:300:12576"]=true;  okfill = false; break end
      local id = pickl(rng, cand)
      fl[#fl + 1] = id
      fg[#fg + 1] = (sp.grade and sp.grade[1] == "elite" and borrowed) and "eliteb" or ""
    end
    if okfill then B.__r23_cov.branches["27-compose.lua:305:12776"]=true; 
      -- 후열이 앞에 오지 않게: 전열 → 후열 순서(칸 번호 = 턴 동률 때의 차례)
      local bad, info2 = B.check_comp(fl, fg, { union = true, limit = limit })
      local score = #bad * 10 + math.abs(info2.threat - limit) * 0.01 - info2.union * 0.001
      if #bad == 0 then B.__r23_cov.branches["27-compose.lua:309:13024"]=true; 
        best, bestscore = { fl, fg, t.id }, -1
        break
      end
      if not bestscore or score < bestscore then B.__r23_cov.branches["27-compose.lua:313:13144"]=true;  best, bestscore = { fl, fg, t.id }, score end
    end
  end
  -- 무작위로 못 찾았으면 깊이 우선 탐색: 모든 규칙을 만족하는 편성이 풀 안에 있으면 반드시 찾는다(적은 풀 — 밑바닥 · 균열 — 에서 약점 합집합 4가지를 지킨다)
  if bestscore == nil or bestscore >= 0 then B.__r23_cov.branches["27-compose.lua:317:13347"]=true; 
    local function shuffle(l) B.__r23_cov.calls["27-compose.lua:318"]=true; 
      for k = #l, 2, -1 do B.__r23_cov.branches["27-compose.lua:319:13406"]=true; 
        local j = math.floor(rng() * k) + 1
        if j > k then B.__r23_cov.branches["27-compose.lua:321:13470"]=true;  j = k end
        l[k], l[j] = l[j], l[k]
      end
    end
    local umin = 4
    local function dfs(slots, k, fl, fg, budget) B.__r23_cov.calls["27-compose.lua:326"]=true; 
      if k > #slots then B.__r23_cov.branches["27-compose.lua:327:13623"]=true; 
        local bad = B.check_comp(fl, fg, { union = true, limit = limit, umin = umin })
        return #bad == 0
      end
      local sp = slots[k]
      local is_el = sp.grade and sp.grade[1] == "elite"
      local cand = {}
      for _, id in ipairs(is_el and elites or mobs) do B.__r23_cov.branches["27-compose.lua:334:13906"]=true; 
        if fits(B.FOES[id], fl, sp) then B.__r23_cov.branches["27-compose.lua:335:13945"]=true;  cand[#cand + 1] = id end
      end
      shuffle(cand)
      for _, id in ipairs(cand) do B.__r23_cov.branches["27-compose.lua:338:14037"]=true; 
        budget.n = budget.n - 1
        if budget.n <= 0 then B.__r23_cov.branches["27-compose.lua:340:14097"]=true;  return false end
        fl[#fl + 1] = id
        fg[#fg + 1] = (is_el and borrowed) and "eliteb" or ""
        local _, inf = B.check_comp(fl, fg, {})
        if inf.threat <= limit + 1e-9 and dfs(slots, k + 1, fl, fg, budget) then B.__r23_cov.branches["27-compose.lua:344:14330"]=true;  return true end
        fl[#fl] = nil
        fg[#fg] = nil
      end
      return false
    end
    local found
    -- 약점 합집합 4가지가 이 풀·이 적 수로는 불가능하면(적 둘이 서로 겹치지 않는 약점 넷을 가져야 한다) 3가지까지 낮춘다(relaxed 표시)
    for _, um in ipairs({ 4, 3 }) do B.__r23_cov.branches["27-compose.lua:352:14570"]=true; 
      umin = um
      for tc = math.max(2, tc0), 2, -1 do B.__r23_cov.branches["27-compose.lua:354:14628"]=true; 
        local order_t = {}
        for _, tp in ipairs(tmpls) do B.__r23_cov.branches["27-compose.lua:356:14693"]=true;  order_t[#order_t + 1] = tp end
        shuffle(order_t)
        for _, t in ipairs(order_t) do B.__r23_cov.branches["27-compose.lua:358:14788"]=true; 
          local fl, fg = {}, {}
          if dfs(build_slots(t, tc), 1, fl, fg, { n = 4000 }) then B.__r23_cov.branches["27-compose.lua:360:14885"]=true;  found = { fl, fg, t.id, um < 4 }; break end
        end
        if found then B.__r23_cov.branches["27-compose.lua:362:14963"]=true;  break end
      end
      if found then B.__r23_cov.branches["27-compose.lua:364:15003"]=true;  break end
    end
    if found then B.__r23_cov.branches["27-compose.lua:366:15039"]=true;  best, bestscore = found, -1 end
  end
  if not best then B.__r23_cov.branches["27-compose.lua:368:15096"]=true;  error("compose: 편성을 만들 수 없다 " .. tostring(zkey)) end
  -- 전열 먼저(칸 5·6 이 전열인 옛 배치와 같다)
  local fl, fg, tid, relaxed = best[1], best[2], best[3], best[4]
  local idx = {}
  for k = 1, #fl do B.__r23_cov.branches["27-compose.lua:372:15287"]=true;  idx[k] = k end
  table.sort(idx, function(a, b) B.__r23_cov.calls["27-compose.lua:373"]=true; 
    local fa, fb = B.FOES[fl[a]].row == "전열", B.FOES[fl[b]].row == "전열"
    if fa ~= fb then B.__r23_cov.branches["27-compose.lua:375:15426"]=true;  return fa end
    return a < b
  end)
  local f2, g2 = {}, {}
  for k, i in ipairs(idx) do B.__r23_cov.branches["27-compose.lua:379:15519"]=true;  f2[k], g2[k] = fl[i], fg[i] end
  local res = result(f2, g2, tid, false)
  res.relaxed = relaxed and true or nil
  return res
end

-- ---------- 대던전 한 층의 계획(순수 함수 — 게임 흐름 76-dungeon 과 밸런스 도구가 같이 쓴다) ----------
-- stage 1 = 그 층의 일반 전투(구역 풀 조합) · stage 2 = 층 끝 보스(우두머리 / 구역 보스, 레이드 화면)
-- avg = 파티 평균 레벨 · party_n = 출전 인원 · seed = 정수. 돌려주는 값 = { enc = 조합, el = 적 레벨, star, info }
function B.floor_plan(floor, avg, party_n, stage, seed) B.__r23_cov.calls["27-compose.lua:388"]=true; 
  local info = B.floor_info(floor)
  local kind = (stage == 2) and B.floor_boss_kind(info) or "battle"
  local enc = B.compose(seed, { kind = kind, floor = floor, party_n = party_n })
  enc.dn = { floor = floor, stage = stage }
  return { enc = enc, el = B.floor_level(avg, info), star = enc.star, info = info }
end

-- 탐색 한 번의 전투 계획(77-explore · 밸런스 도구가 같이 쓴다): kind = "battle" | "elite" | "boss"(그 층의 보스 — 우두머리 / 구역 보스).
function B.floor_enc(floor, avg, party_n, kind, seed) B.__r23_cov.calls["27-compose.lua:397"]=true; 
  local info = B.floor_info(floor)
  local ck = (kind == "boss") and B.floor_boss_kind(info) or kind
  local enc = B.compose(seed, { kind = ck, floor = floor, party_n = party_n })
  enc.dn = { floor = floor, kind = (kind == "boss") and "boss" or "explore", party_n = party_n }
  return { enc = enc, el = B.floor_level(avg, info), star = enc.star, info = info }
end
