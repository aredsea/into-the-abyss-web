-- ===== 대던전 한 층의 흐름 (사장님 10-10 확정 — design/DUNGEON.md) =====
-- 입장 → 탐색 ×5 → 휴식 → 층 보스(레이드) → 정산. 탐색은 버튼 한 번 = 결과 하나(씨앗 + 층 + 번호로 결정론):
--   70% 전투(그 층의 일반 조합 · 3번째 탐색부터 20% 가 정예) · 30% 발견(주화 50% · 아이템 35% · 장비 15%).
--   전투가 끝나도 HP · MP 는 채우지 않고 이어진다 — 휴식(파티 전원 HP +30%)과 전투 중 물약이 의미를 갖는 까닭이다.
-- 상태: G.dungeon.run (아래 B.ex_new 가 만드는 표) — 저장은 게임 저장(G)에 같이. 장면: "dungeon"(탐색 · 휴식 · 정산 화면) ↔ "battle"(탐색 전투 · 층 보스).
-- 🔴 버튼 접두 ex (장면 dungeon): ex_go 탐색 · ex_cont 전투 뒤 돌아오기(장면 battle) · ex_boss 층 보스 · ex_retreat / ex_retreat_yes / ex_retreat_no ·
--    ex_u_<hp_s…mp_l|bandage>_<자리 1~4> 던전 안 아이템 · ex_who_<자리> 정비할 사람 · ex_eq_<칸>_<장비 id> · ex_un_<칸> · ex_home 정산 화면에서 거점으로.
--    전투 중 아이템은 it_*(78-battle-item). 정산은 전투 장면의 tw_return(70-town → B.dn_settle) — 층 보스를 이긴 뒤 · 진 뒤.
-- 🔴 보상 규칙 [제안 — 열린 결정]: 모은 것은 run 주머니(R.loot)에 담겨 있다가 층을 벗어날 때 한 번에 거점으로 옮겨진다.
--    클리어(보스 승리) = 전부 + 보스 보상 + 최심층 기록 · 퇴각 = 모은 것만(보스 보상 · 기록 없음) · 패배 = 모은 것 전부 잃고 금화도 일부 잃는다.
--    같은 정산은 두 번 일어나지 않는다(R.phase 가 "done" 이 되면 닫힌다) · 되감기(AI 다시 생성)는 버튼을 다시 누르지 않으므로 영향이 없다.
-- 모든 수치 [제안]: B.EX 한 곳.

B.EX = {
  STEPS = 5,
  P_BATTLE = 0.70,                                 -- 탐색 한 번이 전투일 확률
  LOOT_COIN = 0.50, LOOT_ITEM = 0.85,              -- 발견 안에서의 누적: 주화 50% / 아이템 35% / 장비 15%
  ELITE_P = 0.20, ELITE_FROM = 3, ELITE_MAX = 2,   -- 전투 중 정예 비율 · 몇 번째 탐색부터 · 한 층에 최대 (DUNGEON.md: 정예는 단계 3 부터 · 층당 둘까지)
  REST_HP = 0.30, REST_MP = 0.60,                  -- 휴식 회복(최대치의 비율) — HP 30% 는 사장님 확정 · MP 60% 는 [제안](밸런스 표본: MP 가 바닥나면 보스 승률이 20%p 쯤 깎인다)
  GOLD_BATTLE = 0.6, GOLD_ELITE = 1.2, GOLD_COIN = 1.0,   -- 기준 금화(B.dn_gold 전투 한 번)에 곱한다
  ITEM_W = { hp_s = 40, hp_m = 12, hp_l = 4, mp_s = 12, mp_m = 5, mp_l = 2, sh_s = 6, sh_m = 3, sh_l = 1, antidote = 8, bandage = 15 },   -- 발견 아이템 가중치(체력 물약 쪽으로 쏠림 · 귀환 두루마리는 안 나온다)
  ITEM_FROM = { hp_m = 8, mp_m = 8, sh_m = 8, hp_l = 18, mp_l = 18, sh_l = 18 },   -- 중형은 8층부터 · 대형은 18층부터 나온다(사용 레벨 15 · 30 ≈ 층 × 1.5)
  DOWN_HP = 0.20,                                  -- [제안] 쓰러진 아군이 다음 탐색 전투에 서는 HP 비율(0 = 쓰러진 채 — 휴식 · 붕대로 일으킨다). 층 보스 앞에서는 휴식이 +30% 를 더해 준다
  BOSS_SALT = 7,
  -- [제안] 첫 세 층의 소인원 보정. 각 값은 HP / 공격 배율(탐색 · 층 보스 순서).
  NEWBIE = { [1] = { explore = { 0.48, 0.48 }, boss = { 0.38, 0.38 } }, [2] = { explore = { 0.48, 0.48 }, boss = { 0.38, 0.38 } }, [3] = { explore = { 0.52, 0.52 }, boss = { 0.47, 0.47 } } },
  -- 입문 구간: 1층 적 HP · 공격 배율(탐색 · 층 보스 모두). to 층에서 1배가 되도록 log 로 오른다(Lv10 ≈ 7층부터 본래 세기)
  EARLY = { to = 7, hp = 0.45, atk = 0.5, curve = 2 },
  -- 탐색 전투 적 세기(층 보스와 따로 맞춘다 — 10-10 밸런스): 탐색 전투의 적 배율 곡선. pts = [층, HP 배율] log 척도 꺾은선(24-stats curve_hp — 층 일반 곡선을 대신한다), 공격 배율 = HP 배율 ^ pow, elite = 정예에만 더 곱하는 HP 배율. 호위 · 하수인(층 보스 전투)은 영향 없다. 층 보스 곡선(tune.curve chief / boss)은 그대로 둔다.
  FOE = { pow = 0.55, elite = 1, ord3 = 0.9, zone = { iron_tombs = 0.75 }, pts = { { 1, 1.56 }, { 6, 1.651 }, { 12, 1.804 }, { 18, 2.275 }, { 24, 3.203 }, { 30, 3.783 }, { 40, 3.9 }, { 55, 4.229 } } },   -- 10-10: 탐색 전투 ×1.3(후보 B — Jev 0.96 · conf 0.92, 탐색 전투가 위험을 가지게)
}

-- ---------- 결정론 난수: (씨앗, 층, 탐색 번호, 용도) → [0, 1) ----------
local function mix(seed, a, b, c) B.__expe_cov.calls["77-explore.lua:34"]=true; 
  local x = (math.tointeger(math.floor(tonumber(seed) or 0)) or 0) * 0x9E3779B97F4A7C15 + a * 0xBF58476D1CE4E5B9 + b * 0x94D049BB133111EB + c * 0x2545F4914F6CDD1D
  x = (x ~ (x >> 30)) * 0xBF58476D1CE4E5B9
  x = (x ~ (x >> 27)) * 0x94D049BB133111EB
  x = x ~ (x >> 31)
  return (x >> 11) / 9007199254740992.0
end
B.ex_mix = mix

-- 장비를 B.ITEMS 에도 올린다 — 도감(65-codex)의 장비 창이 B.ITEMS[id].slot 으로 장비를 찾는다. 상점 목록(B.ITEM_ORDER)에는 없다.
for _, iid in ipairs(B.EQUIP_ORDER or {}) do B.__expe_cov.branches["77-explore.lua:44:3550"]=true; 
  local e = B.EQUIP[iid]
  B.ITEMS[iid] = { id = iid, name = e.name, slot = e.slot, rarity = e.rarity, d = e.d }
end

-- 탐색 한 번의 결과. elites = 이 층에서 지금까지 나온 정예 수. 돌려주는 값 { kind = battle|elite|coin|item|equip, ... }
function B.ex_roll(seed, floor, step, elites, party_cls) B.__expe_cov.calls["77-explore.lua:50"]=true; 
  local X = B.EX
  local r = mix(seed, floor, step, 1)
  if r < X.P_BATTLE then B.__expe_cov.branches["77-explore.lua:53:3899"]=true; 
    if floor >= 3 and step >= X.ELITE_FROM and (elites or 0) < X.ELITE_MAX and mix(seed, floor, step, 5) < X.ELITE_P then B.__expe_cov.branches["77-explore.lua:54:4021"]=true;  return { kind = "elite" } end
    return { kind = "battle" }
  end
  local r2 = mix(seed, floor, step, 2)
  if r2 < X.LOOT_COIN then B.__expe_cov.branches["77-explore.lua:58:4154"]=true; 
    local g = B.floor(B.dn_gold(floor, "battle") * X.GOLD_COIN * (0.75 + 0.5 * mix(seed, floor, step, 6)) + 0.5)
    return { kind = "coin", gold = math.max(1, g) }
  elseif r2 < X.LOOT_ITEM then B.__expe_cov.branches["77-explore.lua:61:4350"]=true; 
    local tot = 0
    local function wt(iid) B.__expe_cov.calls["77-explore.lua:63"]=true;  return (floor >= (X.ITEM_FROM[iid] or 0)) and (X.ITEM_W[iid] or 0) or 0 end
    for _, iid in ipairs(B.IT.order) do B.__expe_cov.branches["77-explore.lua:64:4513"]=true;  tot = tot + wt(iid) end
    local x, pick = mix(seed, floor, step, 3) * tot, B.IT.order[1]
    for _, iid in ipairs(B.IT.order) do B.__expe_cov.branches["77-explore.lua:66:4644"]=true; 
      x = x - wt(iid)
      if x < 0 then B.__expe_cov.branches["77-explore.lua:68:4684"]=true;  pick = iid; break end
    end
    return { kind = "item", item = pick }
  end
  -- 장비: 새 장비 코드(81-gear B.gear_drop) — 층 추천 레벨 ±3 · 출전 직업 80%. party_cls = 출전 파티 직업 id 목록(없으면 전 직업)
  local code, item = B.gear_drop(math.floor(mix(seed, floor, step, 4) * 2147483646) + 1, floor, "battle", party_cls)
  if not code then B.__expe_cov.branches["77-explore.lua:74:4999"]=true;  return { kind = "coin", gold = math.max(1, B.dn_gold(floor, "battle")) } end   -- 장비 데이터가 없으면 주화로
  return { kind = "equip", code = code, rarity = item.rarity }
end

-- ---------- 진행 상태 ----------
function B.ex_run(G) B.__expe_cov.calls["77-explore.lua:79"]=true; 
  local D = B.dn_G(G)
  return D.run
end
function B.C1_gear_label(code) B.__expe_cov.calls["77-explore.lua:83"]=true; 
  local r = B.gear_roll and B.gear_roll(code)
  if not r then B.__expe_cov.branches["77-explore.lua:85:5351"]=true;  return B.U("알 수 없는 장비") end
  local rn = B.RARITY and B.RARITY[r.rarity] and B.RARITY[r.rarity].name or r.rarity
  return B.U("{item} ({rarity}, Lv {lv})", { item = r.item.name, rarity = rn, lv = r.lv })
end
function B.C1_en_gear_label(code) B.__expe_cov.calls["77-explore.lua:89"]=true; 
  local r = B.gear_roll and B.gear_roll(code)
  if not r then B.__expe_cov.branches["77-explore.lua:91:5655"]=true;  return "Unknown equipment" end
  local rn = B.RARITY and B.RARITY[r.rarity] and B.RARITY[r.rarity].name or r.rarity
  return B.C1_en(r.item.name) .. " (" .. B.C1_en(rn) .. ", Lv " .. r.lv .. ")"
end

local function zero4() B.__expe_cov.calls["77-explore.lua:96"]=true;  return { 0, 0, 0, 0 } end

-- 새 층 도전 상태. pm = 출전 편성 사본(B.battle_pm) · n = 인원 · avg = 평균 레벨
function B.ex_new(G, floor, pm, n, avg, sid) B.__expe_cov.calls["77-explore.lua:99"]=true; 
  local seed = math.floor(B.G_rnd(G) * 2147483646) + 1
  local hp, mp, mhp, mmp = zero4(), zero4(), zero4(), zero4()
  for i = 1, 4 do B.__expe_cov.branches["77-explore.lua:102:6151"]=true; 
    local m = pm[i]
    if m and m.id ~= "" then B.__expe_cov.branches["77-explore.lua:104:6198"]=true; 
      local ok, s = pcall(B.party_stats, m.cls, m.L, m.id ~= "persona" and m.id or nil)
      if ok and type(s) == "table" then B.__expe_cov.branches["77-explore.lua:106:6326"]=true; 
        mhp[i], mmp[i] = B.floor(s.hp + 0.5), B.floor(s.mp + 0.5)
        hp[i], mp[i] = mhp[i], mmp[i]
      end
    end
  end
  local R = { v = 1, floor = floor, step = 0, phase = "explore", seed = seed, sid = sid, pm = pm, n = n, avg = avg,
    loot = { gold = 0, items = {}, gear = {} }, exp = 0, elites = 0, wins = 0, hp = hp, mp = mp, mhp = mhp, mmp = mmp, real = false,
    log = {}, last = "", sel = 1, ask = false }
  -- 층 보스는 시작할 때 정해 둔다 — 화면의 이름과 실제 전투가 같아야 한다
  R.boss_seed = math.floor(mix(seed, floor, 99, B.EX.BOSS_SALT) * 2147483646) + 1
  local plan = B.floor_enc(floor, avg, n, "boss", R.boss_seed)
  R.boss_name = B.FOES[plan.enc.fl[1]].name
  R.boss_kind = plan.enc.kind
  return R
end

-- ---------- 작은 도구 ----------
local function pname(G) B.__expe_cov.calls["77-explore.lua:124"]=true; 
  local n = G.persona and G.persona.name or ""
  return (n ~= "" and n) or "당신"
end
local function member_name(G, m) B.__expe_cov.calls["77-explore.lua:128"]=true; 
  if m.id == "persona" then B.__expe_cov.branches["77-explore.lua:129:7233"]=true;  return pname(G) end
  return (B.CAST[m.id] and B.CAST[m.id].name) or m.id
end
local function members(R) B.__expe_cov.calls["77-explore.lua:132"]=true; 
  local out = {}
  for i = 1, 4 do B.__expe_cov.branches["77-explore.lua:134:7374"]=true; 
    local m = R.pm[i]
    if m and m.id ~= "" then B.__expe_cov.branches["77-explore.lua:136:7423"]=true;  out[#out + 1] = { slot = i, m = m } end
  end
  return out
end
local function push_log(R, line) B.__expe_cov.calls["77-explore.lua:140"]=true; 
  R.log[#R.log + 1] = line
  while #R.log > 8 do B.__expe_cov.branches["77-explore.lua:142:7570"]=true;  table.remove(R.log, 1) end
end
local function itname(iid) B.__expe_cov.calls["77-explore.lua:144"]=true; 
  local r = B.gear_roll and B.gear_roll(iid)
  if r then B.__expe_cov.branches["77-explore.lua:146:7683"]=true;  return r.item.name end
  return (B.ITEMS[iid] and B.ITEMS[iid].name) or iid
end
local function rar_of(iid) B.__expe_cov.calls["77-explore.lua:149"]=true; 
  local r = B.gear_roll and B.gear_roll(iid)
  if r then B.__expe_cov.branches["77-explore.lua:151:7847"]=true;  return r.rarity end
  return B.ITEMS[iid] and B.ITEMS[iid].rarity or nil
end

-- 장면 지시(AI 서술용). 앞 지시가 아직 AI 답을 받지 못했으면(B.pend_busy) 덮어쓰지 않고 줄로 덧붙인다 — 유저가 답을 받기 전에 탐색을 이어 가도 발견이 사라지지 않는다.
function B.ex_pend(G, id, line) B.__expe_cov.calls["77-explore.lua:156"]=true; 
  if (G.pending or "") ~= "" and B.pend_busy(G, id) then B.__expe_cov.branches["77-explore.lua:157:8123"]=true; 
    local lines = {}
    for ln in (G.pending .. "\n"):gmatch("(.-)\n") do B.__expe_cov.branches["77-explore.lua:159:8200"]=true;  if ln ~= "" then B.__expe_cov.branches["77-explore.lua:159:8215"]=true;  lines[#lines + 1] = ln end end
    lines[#lines + 1] = line
    while #lines > 4 do B.__expe_cov.branches["77-explore.lua:161:8301"]=true;  table.remove(lines, 1) end
    G.pending = table.concat(lines, "\n")
  else B.__expe_cov.branches["77-explore.lua:163:8375"]=true; 
    G.pending, G.pending_at, G.pend_soft = line, nil, true
  end
end

local function floor_label(R) B.__expe_cov.calls["77-explore.lua:168"]=true; 
  local info = B.floor_info(R.floor)
  return "floor " .. R.floor .. " (" .. B.C1_en(B.ZONES[info.zone].name) .. ((info.dk > 0) and (", depth " .. info.dc) or "") .. ")"
end

-- 던전 입장 장면 지시(잠금 — 01-game B.pend_hard). 탐색 결과는 아직 정하지 않았으니 입구까지만 쓴다.
function B.dn_enter_note(G, R) B.__expe_cov.calls["77-explore.lua:174"]=true; 
  local names = {}
  for _, e in ipairs(members(R)) do B.__expe_cov.branches["77-explore.lua:176:8809"]=true;  names[#names + 1] = B.C1_en(member_name(G, e.m)) end
  return "[Great Dungeon entry confirmed] The party (" .. table.concat(names, ", ") .. ") entered " .. floor_label(R) .. " of the Great Dungeon. " ..
    B.C1_en(R.boss_name or "층의 주인") .. " awaits at the end of this floor. Describe only the entrance's atmosphere and the companions' reactions. Do not decide what they encounter while exploring; the engine decides that."
end

-- ---------- 시작 (75-sortie so_go → 대던전 모드) ----------
function B.dn_start(G, id, pre, line) B.__expe_cov.calls["77-explore.lua:182"]=true; 
  local D = B.dn_G(G)
  local T = B.tw_T(G)
  local floor = D.sel
  if not B.dn_allowed(G, floor) then B.__expe_cov.branches["77-explore.lua:186:9433"]=true;  floor = B.dn_max(G) end
  local pm, n, avg = B.dn_party(G)
  if type(D.run) == "table" and type(D.run.pm) == "table" then B.__expe_cov.branches["77-explore.lua:188:9555"]=true;    -- 직전 층에 선 동료(79-sex 의 benched 조건)
    local prev = {}
    for i = 1, 4 do B.__expe_cov.branches["77-explore.lua:190:9634"]=true;  local m = D.run.pm[i]; if m and m.id ~= "" and m.id ~= "persona" then B.__expe_cov.branches["77-explore.lua:190:9702"]=true;  prev[#prev + 1] = m.id end end
    D.prev = prev
  end
  D.run = B.ex_new(G, floor, pm, n, avg, T.bn or 0)
  B.pend_hard(G, (pre and (pre .. "\n") or "") .. B.dn_enter_note(G, D.run), id, line or B.U("(대던전 {floor}층에 들어선다)", { floor = D.run.floor }))   -- 🔴 던전에 들어서면 대화로 한 번 잇는다(사장님 10-10) — 탐색 버튼은 AI 답 뒤에 열린다
  G.scene = "dungeon"
  G.ui.panel = ""
end

-- ---------- 전투 시작 (탐색 전투 · 층 보스) ----------
-- kind = "battle" | "elite" | "boss". 앞 전투의 HP · MP 를 이어 받는다(R.real — 첫 전투 전에는 가득).
function B.ex_battle(G, id, kind, step) B.__expe_cov.calls["77-explore.lua:201"]=true; 
  local D = B.dn_G(G)
  local R = D.run
  local T = B.tw_T(G)
  T.bn = (T.bn or 0) + 1
  local seed = (kind == "boss") and R.boss_seed or (math.floor(mix(R.seed, R.floor, step, 9) * 2147483646) + 1)
  local plan = B.floor_enc(R.floor, R.avg, R.n, kind, seed)
  local carry = R.real and { hp = R.hp, mp = R.mp } or nil
  if B.gear_pm_refresh then B.__expe_cov.branches["77-explore.lua:209:10574"]=true;  B.gear_pm_refresh(G, R.pm) end   -- 휴식 중 갈아 끼운 장비를 이번 전투에 반영(81-gear)
  local st = B.fresh(T.bn, B.DIFF_MUL and B.DIFF_MUL(G) or nil, { pm = R.pm, el = plan.el, enc = plan.enc, carry = carry })
  local info = plan.info
  local base
  if kind == "boss" then B.__expe_cov.branches["77-explore.lua:213:10831"]=true; 
    base = B.dn_gold(R.floor, plan.enc.kind)
    st.place = B.U("대던전 {floor}층 {zone}, {boss}", { floor = R.floor, zone = B.ZONES[info.zone].name, boss = plan.enc.kind == "boss" and "구역 보스" or "우두머리" })
  else B.__expe_cov.branches["77-explore.lua:216:11040"]=true; 
    base = B.floor(B.dn_gold(R.floor, "battle") * ((kind == "elite") and B.EX.GOLD_ELITE or B.EX.GOLD_BATTLE) + 0.5)
    st.place = B.U("대던전 {floor}층 {zone}, 탐색 {step}/{total}{elite}", { floor = R.floor, zone = B.ZONES[info.zone].name, step = step, total = B.EX.STEPS, elite = (kind == "elite") and B.U(", 정예") or "" })
  end
  st.rg = B.reward_gold and B.reward_gold(st, base) or base
  st.qid, st.sid = "dn", R.sid
  st.dn = st.dn or {}
  st.dn.floor, st.dn.step, st.dn.kind = R.floor, step, (kind == "boss") and "boss" or "explore"
  st.dn.boss_name = (kind == "boss") and R.boss_name or nil
  st.bag = B.ex_bag(G)
  R.phase, R.cur_bn, R.cur_kind = "battle", st.bn, kind
  if st.over ~= "" then B.__expe_cov.branches["77-explore.lua:227:11738"]=true; 
    if st.over == "win" then B.__expe_cov.branches["77-explore.lua:228:11767"]=true;  st.exp = B.exp_reward(st) end
    B.send_result(id, st)
  end
  B.save(id, st)
  G.scene = "battle"
  G.ui.panel = ""
end

-- ---------- 휴식: 파티 전원 HP +30% ----------
local function enter_rest(G, id, R) B.__expe_cov.calls["77-explore.lua:237"]=true; 
  R.phase = "rest"
  R.ask = false
  do B.__expe_cov.branches["77-explore.lua:240:12011"]=true;    -- 휴식 시작 때(회복 전) 파티 평균 HP·MP 비율 — 섹스 제안의 hp_low · hp_high · mp_low 조건(79-sex)
    local h, hm, p, pm_ = 0, 0, 0, 0
    for i = 1, 4 do B.__expe_cov.branches["77-explore.lua:242:12148"]=true; 
      local m = R.pm[i]
      if m and m.id ~= "" then B.__expe_cov.branches["77-explore.lua:244:12201"]=true;  h, hm, p, pm_ = h + (R.hp[i] or 0), hm + (R.mhp[i] or 0), p + (R.mp[i] or 0), pm_ + (R.mmp[i] or 0) end
    end
    R.sx0 = { hp = (hm > 0) and (h / hm) or 1, mp = (pm_ > 0) and (p / pm_) or 1 }
  end
  local rh, rm = 0, 0
  if B.tx_rest then B.__expe_cov.branches["77-explore.lua:249:12444"]=true;  rh, rm = B.tx_rest(R.pm) end   -- 출신 시너지: 솔렌 3명 · 나에린 3명이 휴식 회복을 더한다(34-traits)
  local gain = {}
  for i = 1, 4 do B.__expe_cov.branches["77-explore.lua:251:12562"]=true; 
    local m = R.pm[i]
    if m and m.id ~= "" and (R.mhp[i] or 0) > 0 then B.__expe_cov.branches["77-explore.lua:253:12635"]=true; 
      local h0, p0 = R.hp[i], R.mp[i]
      R.hp[i] = math.min(R.mhp[i], h0 + B.floor(R.mhp[i] * (B.EX.REST_HP + rh) + 0.5))
      R.mp[i] = math.min(R.mmp[i], p0 + B.floor(R.mmp[i] * (B.EX.REST_MP + rm) + 0.5))
      gain[#gain + 1] = B.T(member_name(G, m)) .. " HP +" .. (R.hp[i] - h0) .. (((R.mmp[i] or 0) > 0) and (", MP +" .. (R.mp[i] - p0)) or "")
    end
  end
  R.last = B.U("휴식. 파티 전원이 숨을 돌렸다({gain})", { gain = table.concat(gain, " / ") })
  push_log(R, B.U("휴식: 파티 HP +{pct}%", { pct = B.floor((B.EX.REST_HP + rh) * 100 + 0.5) }))
  B.ex_pend(G, id, "[Great Dungeon rest confirmed] After " .. B.EX.STEPS .. " explorations on " .. floor_label(R) .. ", the party rested briefly before the floor boss. They recovered some HP and can check their equipment. The next encounter is the floor boss, " .. B.C1_en(R.boss_name) .. ".")
end

B.ex_enter_rest = enter_rest   -- 시험(harness_expedition)이 휴식 회복량을 직접 확인한다

-- ---------- 탐색 한 번 ----------
local function do_explore(G, id) B.__expe_cov.calls["77-explore.lua:268"]=true; 
  local R = B.ex_run(G)
  if G.scene ~= "dungeon" or not R or R.phase ~= "explore" or R.step >= B.EX.STEPS or R.ask then B.__expe_cov.branches["77-explore.lua:270:13737"]=true;  return end   -- 같은 버튼 두 번 · 낡은 화면의 버튼
  local step = R.step + 1
  local o = B.ex_roll(R.seed, R.floor, step, R.elites, B.gear_party_cls(R.pm))
  R.step = step
  R.ask = false
  local head = "[Great Dungeon exploration " .. step .. "/" .. B.EX.STEPS .. " confirmed] " .. floor_label(R) .. ": "
  if o.kind == "battle" or o.kind == "elite" then B.__expe_cov.branches["77-explore.lua:276:14080"]=true; 
    if o.kind == "elite" then B.__expe_cov.branches["77-explore.lua:277:14110"]=true;  R.elites = R.elites + 1 end
    B.ex_battle(G, id, o.kind, step)
    return
  end
  local txt
  local cmul, dup, herb = 1, 0, 0
  if B.tx_find then B.__expe_cov.branches["77-explore.lua:283:14258"]=true;  cmul, dup, herb = B.tx_find(R.pm) end   -- 출신 시너지: 카라쉰 3명 주화 +40% · 경계도시 2~3명 물건이 하나 더 · 나에린 2~3명 회복약이 하나 더(34-traits)
  if o.kind == "coin" then B.__expe_cov.branches["77-explore.lua:284:14404"]=true; 
    local gold = math.max(1, B.floor(o.gold * cmul + 0.5))
    R.loot.gold = R.loot.gold + gold
    txt = B.U("낡은 주머니에서 주화 {gold}닢을 찾았다.", { gold = gold })
    B.ex_pend(G, id, head .. "Found " .. gold .. " coins in the belongings of a fallen adventurer while exploring.")
  elseif o.kind == "item" then B.__expe_cov.branches["77-explore.lua:289:14708"]=true; 
    local n = 1
    if dup > 0 and mix(R.seed, R.floor, step, 11) < dup then B.__expe_cov.branches["77-explore.lua:291:14785"]=true;  n = n + 1 end
    if herb > 0 and o.item:sub(1, 3) == "hp_" and mix(R.seed, R.floor, step, 12) < herb then B.__expe_cov.branches["77-explore.lua:292:14892"]=true;  n = n + 1 end   -- 약초: 주운 회복약(hp_s · hp_m · hp_l)
    R.loot.items[o.item] = (R.loot.items[o.item] or 0) + n
    local cnt = ({ "하나", "둘", "셋" })[n] or tostring(n)
    txt = B.U("{item} {count}{suffix} 주웠다.", { item = itname(o.item), count = cnt, suffix = (n == 1) and "를" or "을" })
    B.ex_pend(G, id, head .. "Found " .. n .. " " .. B.C1_en(itname(o.item)) .. " while exploring.")
  else B.__expe_cov.branches["77-explore.lua:297:15283"]=true; 
    B.ex_gear_add(R, o.code)
    local lb = B.C1_gear_label(o.code)
    txt = B.U("장비를 발견했다: {item}.", { item = lb })
    B.ex_pend(G, id, head .. "Found equipment, " .. B.C1_en_gear_label(o.code) .. ", while exploring.")
  end
  R.last = txt
  push_log(R, B.U("탐색 {step}: {result}", { step = step, result = txt }))
  if R.step >= B.EX.STEPS then B.__expe_cov.branches["77-explore.lua:305:15630"]=true;  enter_rest(G, id, R) end
end

-- ---------- 전투 뒤 돌아오기 (ex_cont — 장면 battle) ----------
local function snapshot_party(R, st) B.__expe_cov.calls["77-explore.lua:309"]=true; 
  for i = 1, 4 do B.__expe_cov.branches["77-explore.lua:310:15774"]=true; 
    local u = st.u[i]
    if u and u.empty ~= 1 then B.__expe_cov.branches["77-explore.lua:312:15825"]=true; 
      R.mhp[i], R.mmp[i] = math.floor(u.mhp), math.floor(u.mmp)
      R.hp[i] = (u.al == 1) and math.max(1, math.floor(u.hp)) or ((B.EX.DOWN_HP > 0) and math.max(1, math.floor(u.mhp * B.EX.DOWN_HP)) or 0)
      R.mp[i] = math.max(0, math.floor(u.mp))
      if u.al ~= 1 then B.__expe_cov.branches["77-explore.lua:316:16100"]=true;  R.fell = true end   -- 이번 층 전투에서 쓰러진 아군이 있었다(79-sex 의 fallen_ally · no_fall)
    end
  end
  R.real = true
end

local function do_cont(G, id) B.__expe_cov.calls["77-explore.lua:322"]=true; 
  local R = B.ex_run(G)
  if G.scene ~= "battle" or not R or R.phase ~= "battle" then B.__expe_cov.branches["77-explore.lua:324:16328"]=true;  return end
  local st = B.load(id)
  if st.over ~= "win" or not st.dn or st.dn.kind ~= "explore" or st.sid ~= R.sid or st.bn ~= R.cur_bn then B.__expe_cov.branches["77-explore.lua:326:16470"]=true;  return end
  snapshot_party(R, st)
  R.loot.gold = R.loot.gold + (tonumber(st.rg) or 0)
  R.exp = R.exp + (tonumber(st.exp) or 0)
  R.wins = R.wins + 1
  local gdrop = (R.cur_kind == "elite") and B.ex_gear_roll(R, "elite", mix(R.seed, R.floor, R.step, 21)) or nil   -- 정예 승리: 30% 로 장비
  local names, seen = {}, {}
  for j = 5, #st.u do B.__expe_cov.branches["77-explore.lua:333:16808"]=true; 
    local d = B.DEF[j]
    if st.u[j].empty ~= 1 and not d.empty and not seen[d.name] then B.__expe_cov.branches["77-explore.lua:335:16897"]=true;  seen[d.name] = true; names[#names + 1] = B.T(d.name) end
  end
  R.last = B.U("전투 승리: {names}. 금화 {gold}, 경험치 {exp:을를} 모았다.", { names = table.concat(names, ", "), gold = tonumber(st.rg) or 0, exp = tonumber(st.exp) or 0 })
  push_log(R, B.U("탐색 {step}: 전투 승리({names})", { step = R.step, names = table.concat(names, ", ") }))
  if gdrop then B.__expe_cov.branches["77-explore.lua:339:17238"]=true; 
    R.last = R.last .. B.U(" 장비를 얻었다: {item}.", { item = B.C1_gear_label(gdrop) })
    push_log(R, B.U("탐색 {step}: 정예가 장비를 떨어뜨렸다: {item}", { step = R.step, item = B.C1_gear_label(gdrop) }))
  end
  G.scene = "dungeon"
  R.phase = "explore"
  if R.step >= B.EX.STEPS then B.__expe_cov.branches["77-explore.lua:345:17509"]=true;  enter_rest(G, id, R) end
end

-- ---------- 층 보스 도전 (ex_boss) ----------
local function do_boss(G, id) B.__expe_cov.calls["77-explore.lua:349"]=true; 
  local R = B.ex_run(G)
  if G.scene ~= "dungeon" or not R or R.phase ~= "rest" then B.__expe_cov.branches["77-explore.lua:351:17697"]=true;  return end
  R.ask = false
  B.ex_battle(G, id, "boss", B.EX.STEPS + 1)
end

-- ---------- 장비 드랍 ----------
-- 모은 장비 코드는 R.loot.gear 에 담겼다가 층을 벗어날 때 가방으로 옮겨진다(금화·물건과 같은 규칙).
function B.ex_gear_add(R, code) B.__expe_cov.calls["77-explore.lua:358"]=true; 
  R.loot.gear = R.loot.gear or {}
  R.loot.gear[#R.loot.gear + 1] = code
end
-- 종류(elite · chief · boss)의 확률로 장비 하나를 굴려 R.loot.gear 에 넣는다. 돌려주는 값 = 코드 | nil
function B.ex_gear_roll(R, kind, seed) B.__expe_cov.calls["77-explore.lua:363"]=true; 
  if B.ex_mix(seed, 31, 0, 0) >= B.gear_drop_p(kind) then B.__expe_cov.branches["77-explore.lua:364:18157"]=true;  return nil end
  local code = B.gear_drop(math.floor(B.ex_mix(seed, 32, 0, 0) * 2147483646) + 1, R.floor, kind, B.gear_party_cls(R.pm))
  if code then B.__expe_cov.branches["77-explore.lua:366:18308"]=true;  B.ex_gear_add(R, code) end
  return code
end
-- 모은 장비를 가방에 넣는다. 가방이 가득 차면 넣지 못하고 버려진다. 돌려주는 값 = 들어간 코드 목록, 버려진 개수
function B.ex_gear_bank(G, id, list) B.__expe_cov.calls["77-explore.lua:370"]=true; 
  local ok, lost = {}, 0
  for _, code in ipairs(list or {}) do B.__expe_cov.branches["77-explore.lua:372:18525"]=true; 
    if B.bag_add(id, code) then B.__expe_cov.branches["77-explore.lua:373:18555"]=true;  ok[#ok + 1] = code else B.__expe_cov.branches["77-explore.lua:373:18579"]=true;  lost = lost + 1 end
  end
  return ok, lost
end

-- ---------- 정산 ----------
local function bank_items(G, items) B.__expe_cov.calls["77-explore.lua:379"]=true; 
  if type(G.items) ~= "table" then B.__expe_cov.branches["77-explore.lua:380:18727"]=true;  G.items = {} end
  local list = {}
  for iid, n in pairs(items or {}) do B.__expe_cov.branches["77-explore.lua:382:18802"]=true;  if (tonumber(n) or 0) > 0 then B.__expe_cov.branches["77-explore.lua:382:18831"]=true;  list[#list + 1] = iid end end
  table.sort(list)
  for _, iid in ipairs(list) do B.__expe_cov.branches["77-explore.lua:384:18914"]=true;  G.items[iid] = (tonumber(G.items[iid]) or 0) + items[iid] end
  return list
end

local function exp_note(G, R, exp, sum) B.__expe_cov.calls["77-explore.lua:388"]=true; 
  sum.exp, sum.lv = 0, {}
  if exp > 0 and B.award_exp then B.__expe_cov.branches["77-explore.lua:390:19093"]=true; 
    local okx, lines = pcall(B.award_exp, G, { exp = exp, pm = R.pm, sid = R.sid })
    if okx and type(lines) == "table" then B.__expe_cov.branches["77-explore.lua:392:19220"]=true; 
      sum.exp = exp
      sum.lv = lines
    end
  end
end

-- 함께 싸운 호감(74-affection): 이긴 탐색 전투마다 출전한 동료 각자 +BATTLE · 층 보스까지 쓰러뜨렸으면 +BOSS. 경험치처럼 정산 때 한 번에 준다(패배는 없음).
function B.ex_aff_note(G, R, result, sum) B.__expe_cov.calls["77-explore.lua:400"]=true;    -- (최상위 local 150개 한계 때문에 B 에 둔다)
  sum.aff = {}
  if not (B.aff_party and B.AFF) then B.__expe_cov.branches["77-explore.lua:402:19518"]=true;  return end
  local n = (R.wins or 0) * B.AFF.BATTLE + ((result == "clear") and B.AFF.BOSS or 0)
  if n <= 0 then B.__expe_cov.branches["77-explore.lua:404:19631"]=true;  return end
  local ok, got = pcall(B.aff_party, G, R.pm, n)
  if not ok or type(got) ~= "table" then B.__expe_cov.branches["77-explore.lua:406:19732"]=true;  return end
  for i = 1, 4 do B.__expe_cov.branches["77-explore.lua:407:19763"]=true; 
    local m = R.pm[i]
    if m and m.id ~= "" and got[m.id] ~= nil then B.__expe_cov.branches["77-explore.lua:409:19833"]=true;  sum.aff[#sum.aff + 1] = B.T(member_name(G, m)) .. " +" .. B.aff_fmt(got[m.id]) end
  end
end

-- result = "clear" | "retreat" | "defeat". st = 마지막 전투 상태(clear · defeat 일 때)
local function finish_run(G, id, R, result, st) B.__expe_cov.calls["77-explore.lua:414"]=true; 
  if R.phase == "done" then B.__expe_cov.branches["77-explore.lua:415:20082"]=true;  return end
  local D = B.dn_G(G)
  local T = B.tw_T(G)
  local info = B.floor_info(R.floor)
  local zname = B.ZONES[info.zone].name
  local sum = { result = result, floor = R.floor, gold = 0, exp = 0, items = {}, lv = {}, first = false, lost_gold = 0, lost_items = {}, steps = R.step, wins = R.wins, boss = R.boss_name }
  local note
  if result == "clear" or result == "retreat" then B.__expe_cov.branches["77-explore.lua:422:20467"]=true; 
    local gold = R.loot.gold + ((result == "clear") and (tonumber(st and st.rg) or 0) or 0)
    local exp = R.exp + ((result == "clear") and (tonumber(st and st.exp) or 0) or 0)
    G.gold = G.gold + gold
    sum.gold = gold
    local list = bank_items(G, R.loot.items)
    for _, iid in ipairs(list) do B.__expe_cov.branches["77-explore.lua:428:20773"]=true;  sum.items[iid] = R.loot.items[iid] end
    if result == "clear" then B.__expe_cov.branches["77-explore.lua:429:20840"]=true;  B.ex_gear_roll(R, R.boss_kind == "boss" and "boss" or "chief", mix(R.seed, R.floor, 99, 22)) end   -- 층 보스 승리: 우두머리 60% · 구역 보스 100%
    -- 모험 연대기(89-memory): 이 함수는 phase 가 done 이 아닐 때 한 번만 돈다
    B.chron_add(G, (result == "clear") and B.U("대던전 {floor}층 돌파, 보스 {boss}", { floor = R.floor, boss = tostring(R.boss_name) }) or B.U("대던전 {floor}층에서 퇴각", { floor = R.floor }))
    sum.gear, sum.gear_lost = B.ex_gear_bank(G, id, R.loot.gear)
    B.chron_gear(G, sum.gear)   -- 전설 장비를 얻었으면 연대기에 한 줄
    exp_note(G, R, exp, sum)
    B.ex_aff_note(G, R, result, sum)
    D.runs = D.runs + 1
    if result == "clear" then B.__expe_cov.branches["77-explore.lua:437:21452"]=true; 
      D.best = math.max(D.best, R.floor)
      if info.dk == 0 and info.ord >= 3 and not B.has(D.cleared_bosses, info.zone) then B.__expe_cov.branches["77-explore.lua:439:21581"]=true; 
        D.cleared_bosses[#D.cleared_bosses + 1] = info.zone
        sum.first = true
        B.chron_add(G, B.U("{zone} 구역 보스 {boss:을를} 처음 쓰러뜨렸다", { zone = zname, boss = tostring(R.boss_name) }))
      end
      D.sel = math.min(B.dn_max(G), R.floor + 1)
      D.pg = (D.sel - 1) // B.DN.PAGE + 1
    end
    local got = {}
    for _, iid in ipairs(list) do B.__expe_cov.branches["77-explore.lua:448:21941"]=true;  got[#got + 1] = B.C1_en(itname(iid)) .. ((sum.items[iid] > 1) and (" ×" .. sum.items[iid]) or "") end
    if result == "clear" then B.__expe_cov.branches["77-explore.lua:449:22071"]=true; 
      note = "Defeated the boss " .. B.C1_en(R.boss_name) .. " on " .. floor_label(R) .. " of the Great Dungeon" .. (sum.first and ", defeating this zone boss for the first time" or "") ..
        ". Received " .. gold .. " gold from exploration and the boss reward" .. (#got > 0 and (" (items: " .. table.concat(got, ", ") .. ")") or "") .. "."
      G.ui.msg = B.U("대던전 {floor}층 돌파{first}: 금화 {gold:을를} 받았다.", { floor = R.floor, first = sum.first and B.U(" (구역 보스 첫 처치)") or "", gold = gold })
    else B.__expe_cov.branches["77-explore.lua:453:22576"]=true; 
      note = "Retreated from " .. floor_label(R) .. " of the Great Dungeon " .. ((R.step >= B.EX.STEPS) and "before the floor boss" or "during exploration") .. ". Kept " .. gold .. " gold collected while exploring" .. (#got > 0 and (" (items: " .. table.concat(got, ", ") .. ")") or "") .. ". Did not fight the boss."
      G.ui.msg = B.U("대던전 {floor}층에서 퇴각했다. 모은 것만 가져왔다(금화 {gold}).", { floor = R.floor, gold = gold })
    end
    if #sum.gear > 0 then B.__expe_cov.branches["77-explore.lua:457:23030"]=true; 
      local gl = {}
      for _, c in ipairs(sum.gear) do B.__expe_cov.branches["77-explore.lua:459:23090"]=true;  gl[#gl + 1] = B.C1_gear_label(c) end
      G.ui.msg = G.ui.msg .. B.U(" 장비: {gear}", { gear = B.esc(table.concat(gl, ", ")) })
      local gl_en = {}
      for _, c in ipairs(sum.gear) do B.__expe_cov.branches["77-explore.lua:462:23278"]=true;  gl_en[#gl_en + 1] = B.C1_en_gear_label(c) end
      note = note .. " Equipment gained: " .. table.concat(gl_en, ", ") .. "."
    end
    if sum.gear_lost > 0 then B.__expe_cov.branches["77-explore.lua:465:23439"]=true; 
      G.ui.msg = G.ui.msg .. B.U(" 가방이 가득 찼습니다. 장비 {n}개는 버려졌습니다.", { n = sum.gear_lost })
      note = note .. " The bag was full, so " .. sum.gear_lost .. " equipment items were discarded."
    end
    if sum.exp > 0 then B.__expe_cov.branches["77-explore.lua:469:23662"]=true; 
      G.ui.msg = G.ui.msg .. B.U(" 경험치 {exp}.", { exp = sum.exp })
      note = note .. " Gained " .. sum.exp .. " experience."
    end
    if #sum.lv > 0 then B.__expe_cov.branches["77-explore.lua:473:23822"]=true; 
      G.ui.msg = G.ui.msg .. " " .. B.esc(table.concat(sum.lv, ", "))
      local lv_en = {}
      for _, line in ipairs(sum.lv) do B.__expe_cov.branches["77-explore.lua:476:23956"]=true; 
        local name, before, after = line:match("^(.-) Lv (%d+) → (%d+)$")
        lv_en[#lv_en + 1] = name and (B.C1_en(name) .. " Lv " .. before .. " → " .. after) or line
      end
      note = note .. " Leveled up: " .. table.concat(lv_en, ", ") .. "."
    end
    if #sum.aff > 0 then B.__expe_cov.branches["77-explore.lua:482:24243"]=true;  G.ui.msg = G.ui.msg .. B.U(" 호감 ▲ {list}", { list = B.esc(table.concat(sum.aff, ", ")) }) end
  else B.__expe_cov.branches["77-explore.lua:483:24344"]=true; 
    local carry = math.min(G.gold, 100 * math.max(1, math.min(4, (st and st.star) or 1)))
    local lmul, keep = 1, 0
    if B.tx_defeat then B.__expe_cov.branches["77-explore.lua:486:24486"]=true;  lmul, keep = B.tx_defeat(R.pm) end   -- 출신 시너지: 케른 2명 이상 잃는 금화 −30% · 3명 탐색 수확의 40% 를 챙김(34-traits)
    local loss = math.floor(carry / 2 * lmul)
    G.gold = G.gold - loss
    local kg, ki = 0, {}
    if keep > 0 then B.__expe_cov.branches["77-explore.lua:490:24705"]=true; 
      kg = math.floor(R.loot.gold * keep)
      for iid, n in pairs(R.loot.items) do B.__expe_cov.branches["77-explore.lua:492:24792"]=true; 
        local k = math.floor(n * keep)
        if k > 0 then B.__expe_cov.branches["77-explore.lua:494:24851"]=true;  ki[iid] = k end
      end
      G.gold = G.gold + kg
      bank_items(G, ki)
    end
    local gear_all = R.loot.gear or {}
    local gk = {}
    for i = 1, math.min(#gear_all, math.floor(#gear_all * keep)) do B.__expe_cov.branches["77-explore.lua:501:25063"]=true;  gk[i] = gear_all[i] end   -- 먼저 모은 것부터 챙긴다(결정론)
    sum.kept_gear = B.ex_gear_bank(G, id, gk)   -- 가방이 가득 차면 못 챙긴다
    sum.lost_gear = #gear_all - #sum.kept_gear
    sum.lost_gold = R.loot.gold - kg
    for iid, n in pairs(R.loot.items) do B.__expe_cov.branches["77-explore.lua:505:25303"]=true; 
      if n - (ki[iid] or 0) > 0 then B.__expe_cov.branches["77-explore.lua:506:25338"]=true;  sum.lost_items[iid] = n - (ki[iid] or 0) end
    end
    sum.penalty = loss
    sum.kept_gold = kg
    local kept_txt, kept_ui = "", ""
    local kgear = #sum.kept_gear
    if keep > 0 and (kg > 0 or next(ki) or kgear > 0) then B.__expe_cov.branches["77-explore.lua:512:25566"]=true; 
      kept_txt = " Thanks to the Kern pact, kept some of the collected loot (" .. kg .. " gold" .. (kgear > 0 and (", " .. kgear .. " equipment items") or "") .. ")."
      kept_ui = B.U(" 케른의 계약 덕에 모은 것의 일부(금화 {gold}{gear})는 챙겼다.", { gold = kg, gear = kgear > 0 and B.U(", 장비 {n}개", { n = kgear }) or "" })
      if sum.lost_gear > 0 then B.__expe_cov.branches["77-explore.lua:515:25906"]=true;  kept_txt = kept_txt .. " Lost " .. sum.lost_gear .. " equipment items."; kept_ui = kept_ui .. B.U(" 장비 {n}개는 잃었다.", { n = sum.lost_gear }) end
    end
    B.chron_add(G, B.U("대던전 {floor}층 도전 실패{boss}", { floor = R.floor, boss = (st and st.dn and st.dn.kind == "boss") and B.U(", 보스 {name} 앞에서 무너졌다", { name = tostring(R.boss_name) }) or "" }))   -- 모험 연대기(89-memory)
    note = "The party fell and retreated from " .. floor_label(R) .. " of the Great Dungeon. Lost all exploration loot and " .. loss .. " carried gold." .. kept_txt
    G.ui.msg = B.U("대던전 {floor}층 도전 실패. 모은 것을 잃고, 들고 간 금화 {carry}의 {part}{loss}도 잃었다.{kept}", { floor = R.floor, carry = carry, part = (lmul < 1) and B.U("일부 ") or B.U("절반 "), loss = loss, kept = kept_ui })
  end
  R.loot = { gold = 0, items = {}, gear = {} }
  R.summary = sum
  R.phase = "done"
  R.ask = false
  T.rr = 0
  T.day = T.day + 1
  G.scene = "dungeon"
  if result == "clear" then B.__expe_cov.branches["77-explore.lua:528:26832"]=true; 
    R.note = note   -- 다음 길을 고를 때(ex_next · ex_home) 이 정산 문장과 함께 채팅을 한 번 잇는다
    return
  end
  B.chap_mark(G, id)   -- 장의 경계: 퇴각 · 도전 실패(89-memory — 보조 모델은 이 뒤 첫 AI 답에서)
  B.pend_hard(G, "[Great Dungeon settlement confirmed] " .. note, id, B.U((result == "retreat") and "(대던전에서 물러난다)" or "(부상을 추스르며 토르바로 돌아간다)"))
  if result == "defeat" then B.__expe_cov.branches["77-explore.lua:534:27175"]=true;    -- 도전 실패: 채팅 한 번 뒤 바로 토르바(사장님 10-11). 정산 내용은 알림으로 남는다
    D.last = sum   -- 정산 요약(화면은 토르바 알림으로 — 하네스·진단용으로 남긴다)
    D.run = nil
    G.scene = "town"
    G.ui.tab, G.ui.sel = "", ""
  end
end

-- 70-town tw_settle 이 st.dn 이면 부른다(장면 battle · 전투가 끝났을 때)
function B.dn_settle(G, id, st) B.__expe_cov.calls["77-explore.lua:543"]=true; 
  if st.dn.stage then B.__expe_cov.branches["77-explore.lua:544:27482"]=true;  return B.dn_settle_legacy(G, id, st) end
  local R = B.ex_run(G)
  if not R or R.phase ~= "battle" or st.sid ~= R.sid or st.bn ~= R.cur_bn then B.__expe_cov.branches["77-explore.lua:546:27626"]=true; 
    G.scene = "town"; G.pending_at = nil   -- 진행 중인 층이 없다(깨진 저장) — 거점으로
    return
  end
  if st.over == "win" and st.dn.kind == "explore" then B.__expe_cov.branches["77-explore.lua:550:27770"]=true; 
    G.ui.msg = B.U("탐색 전투를 이겼습니다. 「탐색 계속」을 누르세요. 모은 것은 층을 마칠 때 받습니다.")
    return
  end
  if st.over == "win" then B.__expe_cov.branches["77-explore.lua:554:27885"]=true;  finish_run(G, id, R, "clear", st)
  else B.__expe_cov.branches["77-explore.lua:555:27926"]=true;  finish_run(G, id, R, "defeat", st) end
end

-- (옛 저장) 2단계 흐름 도중에 업데이트된 경우: 보스를 이겼으면 옛 방식으로 정산하고, 아니면 보상 없이 돌려보낸다
function B.dn_settle_legacy(G, id, st) B.__expe_cov.calls["77-explore.lua:559"]=true; 
  local T = B.tw_T(G)
  local D = B.dn_G(G)
  local floor = st.dn.floor
  local info = B.floor_info(floor)
  if st.over == "win" and st.dn.stage == 2 then B.__expe_cov.branches["77-explore.lua:564:28233"]=true; 
    local gold = tonumber(st.rg) or 0
    G.gold = G.gold + gold
    D.best = math.max(D.best, floor)
    D.runs = D.runs + 1
    D.sel = math.min(B.dn_max(G), floor + 1)
    D.pg = (D.sel - 1) // B.DN.PAGE + 1
    if info.dk == 0 and info.ord >= 3 and not B.has(D.cleared_bosses, info.zone) then B.__expe_cov.branches["77-explore.lua:571:28530"]=true;  D.cleared_bosses[#D.cleared_bosses + 1] = info.zone end
    if B.award_exp then B.__expe_cov.branches["77-explore.lua:572:28610"]=true;  pcall(B.award_exp, G, st) end
    if B.aff_party and B.AFF then B.__expe_cov.branches["77-explore.lua:573:28674"]=true;  pcall(B.aff_party, G, st.pm, B.AFF.BOSS) end
    G.ui.msg = B.U("대던전 {floor}층 돌파: 금화 {gold:을를} 받았다.", { floor = floor, gold = gold })
  else B.__expe_cov.branches["77-explore.lua:575:28815"]=true; 
    G.ui.msg = B.U("옛 방식으로 시작한 대던전 도전은 중단됐다. 보상 없이 거점으로 돌아왔다.")
  end
  T.rr = 0
  T.day = T.day + 1
  G.scene = "town"
  G.pending_at = nil
  G.pending, G.pend_soft = "", nil
end

-- ---------- 퇴각 ----------
local function do_retreat(G, id, arg) B.__expe_cov.calls["77-explore.lua:586"]=true; 
  local R = B.ex_run(G)
  if G.scene ~= "dungeon" or not R or (R.phase ~= "explore" and R.phase ~= "rest") then B.__expe_cov.branches["77-explore.lua:588:29174"]=true;  return end
  if arg == "retreat" then B.__expe_cov.branches["77-explore.lua:589:29212"]=true;  R.ask = true
  elseif arg == "retreat_no" then B.__expe_cov.branches["77-explore.lua:590:29259"]=true;  R.ask = false
  elseif arg == "retreat_yes" then B.__expe_cov.branches["77-explore.lua:591:29308"]=true; 
    if not R.ask then B.__expe_cov.branches["77-explore.lua:592:29330"]=true;  return end   -- 확인 없이 들어온 낡은 버튼
    finish_run(G, id, R, "retreat", nil)
  end
end

-- ---------- 던전 안 아이템 (전투 밖) ----------
local function out_mul(R) B.__expe_cov.calls["77-explore.lua:598"]=true; 
  local n = 0
  for i = 1, 4 do B.__expe_cov.branches["77-explore.lua:600:29515"]=true; 
    local m = R.pm[i]
    if m and m.id ~= "" then B.__expe_cov.branches["77-explore.lua:602:29564"]=true; 
      local _, _, nat = B.tr_ids(m)
      if nat == "marento" then B.__expe_cov.branches["77-explore.lua:604:29631"]=true;  n = n + 1 end
    end
  end
  return (n >= 2) and (1 + B.TXN.marento.item2) or 1   -- B.item_mul 과 같은 규칙(마렌토 2명 이상). 인간 시너지 회복 +% 는 전투 중에만 붙는다
end

local function do_use(G, id, iid, slot) B.__expe_cov.calls["77-explore.lua:610"]=true; 
  local R = B.ex_run(G)
  if G.scene ~= "dungeon" or not R or (R.phase ~= "explore" and R.phase ~= "rest") then B.__expe_cov.branches["77-explore.lua:612:29931"]=true;  return end
  local m = R.pm[slot]
  if not m or m.id == "" or not B.ITEMS[iid] or B.ex_have(G, iid) <= 0 then B.__expe_cov.branches["77-explore.lua:614:30041"]=true;  return end
  local mul = out_mul(R)
  local i = slot
  local d = B.ITEMS[iid]
  if d.kind == "hp" or d.kind == "mp" then B.__expe_cov.branches["77-explore.lua:618:30162"]=true; 
    if (tonumber(m.L) or 1) < B.it_need(iid) then B.__expe_cov.branches["77-explore.lua:619:30212"]=true;  return end   -- 마시는 사람의 레벨이 모자라다
    if R.hp[i] <= 0 then B.__expe_cov.branches["77-explore.lua:620:30270"]=true;  return end
    if d.kind == "hp" then B.__expe_cov.branches["77-explore.lua:621:30308"]=true; 
      if R.hp[i] >= R.mhp[i] then B.__expe_cov.branches["77-explore.lua:622:30342"]=true;  return end
      local h = math.min(R.mhp[i], R.hp[i] + B.it_amount(iid, { mhp = R.mhp[i], mmp = R.mmp[i] }, mul))
      B.ex_take(G, iid)
      R.last = B.U("{name}에게 {item}: HP +{n}", { name = member_name(G, m), item = itname(iid), n = h - R.hp[i] })
      R.hp[i] = h
    else B.__expe_cov.branches["77-explore.lua:627:30622"]=true; 
      if R.mmp[i] <= 0 or R.mp[i] >= R.mmp[i] then B.__expe_cov.branches["77-explore.lua:628:30673"]=true;  return end
      local p = math.min(R.mmp[i], R.mp[i] + B.it_amount(iid, { mhp = R.mhp[i], mmp = R.mmp[i] }, mul))
      B.ex_take(G, iid)
      R.last = B.U("{name}에게 {item}: MP +{n}", { name = member_name(G, m), item = itname(iid), n = p - R.mp[i] })
      R.mp[i] = p
    end
  elseif iid == "bandage" then B.__expe_cov.branches["77-explore.lua:634:30983"]=true; 
    if R.hp[i] > 0 then B.__expe_cov.branches["77-explore.lua:635:31007"]=true;  return end
    B.ex_take(G, iid)
    R.hp[i] = math.max(1, B.floor(R.mhp[i] * B.IT.bandage_hp))
    R.last = B.U("{name:을를} 붕대로 일으켰다. HP {hp}", { name = member_name(G, m), hp = R.hp[i] })
  end
end

-- ---------- 정비: 장비 갈아 끼우기 (휴식 화면) ----------
local function equip_key(R, slot) B.__expe_cov.calls["77-explore.lua:643"]=true; 
  local m = R.pm[slot]
  return m and m.id ~= "" and m.id or nil
end

local function do_equip(G, id, kind, slot, iid) B.__expe_cov.calls["77-explore.lua:648"]=true; 
  local R = B.ex_run(G)
  if G.scene ~= "dungeon" or not R or R.phase ~= "rest" then B.__expe_cov.branches["77-explore.lua:650:31490"]=true;  return end
  local key = equip_key(R, R.sel)
  if not key or not B.PX.slot_ok(slot) then B.__expe_cov.branches["77-explore.lua:652:31579"]=true;  return end
  local ok, why
  if kind == "un" then B.__expe_cov.branches["77-explore.lua:654:31629"]=true; 
    ok, why = B.gear_unequip(G, id, key, slot)
  else B.__expe_cov.branches["77-explore.lua:656:31683"]=true; 
    local r = iid and B.gear_roll(iid)
    if not (r and r.slot == slot) then B.__expe_cov.branches["77-explore.lua:658:31761"]=true;  return end
    ok, why = B.gear_equip(G, id, key, iid)
  end
  if not ok and why then B.__expe_cov.branches["77-explore.lua:661:31847"]=true;  R.last = why end
end

-- ---------- 버튼 ----------
B.H.ex = function(G, arg, id) B.__expe_cov.calls["77-explore.lua:665"]=true; 
  if arg == "go" then B.__expe_cov.branches["77-explore.lua:666:31949"]=true;  do_explore(G, id)
  elseif arg == "cont" then B.__expe_cov.branches["77-explore.lua:667:31995"]=true;  do_cont(G, id)
  elseif arg == "boss" then B.__expe_cov.branches["77-explore.lua:668:32038"]=true;  do_boss(G, id)
  elseif arg == "retreat" or arg == "retreat_yes" or arg == "retreat_no" then B.__expe_cov.branches["77-explore.lua:669:32131"]=true;  do_retreat(G, id, arg)
  elseif arg == "next" then B.__expe_cov.branches["77-explore.lua:670:32182"]=true; 
    local R = B.ex_run(G)
    if G.scene ~= "dungeon" or not R or R.phase ~= "done" or not R.note then B.__expe_cov.branches["77-explore.lua:672:32285"]=true;  return end   -- 층 돌파 직후 한 번만
    local nxt = R.floor + 1
    if not (B.dn_allowed and B.dn_allowed(G, nxt)) then B.__expe_cov.branches["77-explore.lua:674:32398"]=true;  return end
    local note = R.note
    R.note = nil
    B.dn_G(G).sel = nxt
    B.chron_add(G, B.U("대던전 {floor}층 돌파 뒤 곧장 {next}층으로 내려갔다", { floor = R.floor, next = nxt }))   -- 모험 연대기(89-memory) — R.note 가 한 번만 있으니 한 번만
    B.chap_mark(G, id)   -- 장의 경계: 다음 층으로 내려감
    B.dn_start(G, id, "[Great Dungeon settlement confirmed] " .. note .. " The party descended directly to the next floor without returning to Torva.", B.U("(층 보스를 쓰러뜨리고 {floor}층으로 내려간다)", { floor = nxt }))
  elseif arg == "home" then B.__expe_cov.branches["77-explore.lua:681:32899"]=true; 
    local R = B.ex_run(G)
    if G.scene ~= "dungeon" then B.__expe_cov.branches["77-explore.lua:683:32958"]=true;  return end
    if R and R.phase ~= "done" then B.__expe_cov.branches["77-explore.lua:684:33005"]=true;  return end   -- 정산 전에는 거점으로 못 나간다
    if R and R.note then B.__expe_cov.branches["77-explore.lua:685:33064"]=true;    -- 층 돌파 뒤 돌아가기: 정산과 귀환을 채팅 한 번으로
      B.chron_add(G, B.U("대던전 {floor}층 돌파 뒤 토르바로 돌아갔다", { floor = R.floor }))   -- 모험 연대기(89-memory)
      B.chap_mark(G, id)   -- 장의 경계: 거점 귀환
      B.pend_hard(G, "[Great Dungeon settlement confirmed] " .. R.note .. " The party returned to Torva.", id, B.U("(층 보스를 쓰러뜨리고 토르바로 돌아간다)"))
      R.note = nil
    end
    B.dn_G(G).run = nil
    G.scene = "town"
    G.ui.tab, G.ui.sel = "", ""
  else B.__expe_cov.branches["77-explore.lua:694:33497"]=true; 
    local iid, slot = arg:match("^u_([a-z_]+)_([1-4])$")
    if iid then B.__expe_cov.branches["77-explore.lua:696:33570"]=true;  return do_use(G, id, iid, tonumber(slot)) end
    local who = arg:match("^who_([1-4])$")
    if who then B.__expe_cov.branches["77-explore.lua:698:33675"]=true; 
      local R = B.ex_run(G)
      if G.scene == "dungeon" and R and R.phase == "rest" and equip_key(R, tonumber(who)) then B.__expe_cov.branches["77-explore.lua:700:33798"]=true;  R.sel = tonumber(who) end
      return
    end
    local sl, iid2 = arg:match("^eq_(%a+)_([a-z0-9_]+)$")
    if sl then B.__expe_cov.branches["77-explore.lua:704:33918"]=true;  return do_equip(G, id, "eq", sl, B.gear_unbtn(iid2)) end
    local sl2 = arg:match("^un_(%a+)$")
    if sl2 then B.__expe_cov.branches["77-explore.lua:706:34031"]=true;  return do_equip(G, id, "un", sl2, nil) end
  end
end

-- ---------- 화면 ----------
local function bar(kind, cur, max) B.__expe_cov.calls["77-explore.lua:711"]=true;  return B.PX.bar(kind, cur, max) end

local function pips(R) B.__expe_cov.calls["77-explore.lua:713"]=true; 
  local o = { '<div class="ex-pips">' }
  for k = 1, B.EX.STEPS do B.__expe_cov.branches["77-explore.lua:715:34277"]=true; 
    local cls = (k <= R.step) and " done" or ((R.phase == "explore" and k == R.step + 1) and " cur" or "")
    o[#o + 1] = '<span class="ex-pip' .. cls .. '">' .. k .. '</span>'
  end
  o[#o + 1] = '<span class="ex-pip ex-pw' .. (R.phase == "rest" and " cur" or ((R.step >= B.EX.STEPS) and " done" or "")) .. '"><i class="im im-nd-camp ex-pi"></i>' .. B.U("휴식") .. '</span>'
  o[#o + 1] = '<span class="ex-pip ex-pw"><i class="im im-nd-boss ex-pi"></i>' .. B.U("보스") .. '</span>'
  o[#o + 1] = '</div>'
  return table.concat(o)
end

local function head_card(G, R, sub) B.__expe_cov.calls["77-explore.lua:725"]=true; 
  local info = B.floor_info(R.floor)
  local zone = B.ZONES[info.zone]
  local el = B.floor_level(R.avg, info)
  local lead = (R.boss_kind == "boss") and B.U("구역 보스 {name}", { name = R.boss_name }) or B.U("우두머리 {name}", { name = R.boss_name })
  local got = 0
  for _, n in pairs(R.loot.items) do B.__expe_cov.branches["77-explore.lua:731:35143"]=true;  got = got + n end
  got = got + #(R.loot.gear or {})
  return '<div class="dk-card gold ex-head"><div class="so-h"><span class="dk-title"><i class="im im-nd-boss so-nd"></i>' .. B.U("{floor}층 {zone}{deep}", { floor = R.floor, zone = B.esc(zone.name), deep = (info.dk > 0) and B.U(" 심층 {n}", { n = info.dc }) or "" }) .. '</span><span class="dk-sub">' .. sub .. '</span></div>' .. pips(R) ..
    '<div class="dk-row ex-tags"><span class="dk-tag">★' .. B.floor_star(info) .. '</span><span class="dk-tag so-elv">' .. B.U("적 Lv {lv}", { lv = el }) .. '</span><span class="dk-tag">' .. B.U("층 끝: {lead}", { lead = B.esc(lead) }) ..
    '</span></div><div class="dk-row ex-loot"><span class="dk-tag">' .. B.U("모은 금화 {gold}", { gold = R.loot.gold }) .. '</span><span class="dk-tag">' .. B.U("물건 {n}개", { n = got }) .. '</span><span class="dk-tag">' .. B.U("경험치 {exp}", { exp = R.exp }) .. '</span></div></div>'
end

local function last_card(R) B.__expe_cov.calls["77-explore.lua:738"]=true; 
  if (R.last or "") == "" then B.__expe_cov.branches["77-explore.lua:739:36109"]=true;  return "" end
  return '<div class="dk-card ex-last"><div class="dk-text">' .. B.esc(R.last) .. '</div></div>'
end

-- 파티 줄: 얼굴 · 이름 · HP/MP · (던전 안에서 쓸 수 있는 아이템)
local function use_btn(G, iid, slot, label, can, why) B.__expe_cov.calls["77-explore.lua:744"]=true; 
  local have = B.ex_have(G, iid)
  local sub = why or B.U("보유 {n}", { n = have })
  if can and have > 0 then B.__expe_cov.branches["77-explore.lua:747:36435"]=true;  return B.btn("ex_u_" .. iid .. "_" .. slot, B.T(label), "sm", sub) end
  return '<div class="dk-btn sm off"><span class="t">' .. B.T(label) .. '<span class="d">' .. sub .. '</span></span></div>'
end
-- 던전 안에서 쓸 수 있는 물약 줄: 가진 크기만 보인다. 레벨이 모자라면 꺼지고 이유가 뜬다. (보호막 물약은 전투 중에만)
local function use_row(G, R, i, m, down) B.__expe_cov.calls["77-explore.lua:751"]=true; 
  local o = {}
  for _, iid in ipairs(B.POTION_IDS) do B.__expe_cov.branches["77-explore.lua:753:36805"]=true; 
    local d = B.ITEMS[iid]
    if (d.kind == "hp" or d.kind == "mp") and not down and B.ex_have(G, iid) > 0 then B.__expe_cov.branches["77-explore.lua:755:36916"]=true;    -- 쓰러진 사람에게는 붕대만
      local lvok = (tonumber(m.L) or 1) >= d.lv
      local need
      if d.kind == "hp" then B.__expe_cov.branches["77-explore.lua:758:37029"]=true;  need = R.hp[i] < R.mhp[i] else B.__expe_cov.branches["77-explore.lua:758:37060"]=true;  need = R.mmp[i] > 0 and R.mp[i] < R.mmp[i] end
      o[#o + 1] = use_btn(G, iid, i, d.name, (not down) and need and lvok, (not lvok) and B.U("Lv {lv} 필요", { lv = d.lv }) or nil)
    end
  end
  if down and B.ex_have(G, "bandage") > 0 then B.__expe_cov.branches["77-explore.lua:762:37299"]=true;  o[#o + 1] = use_btn(G, "bandage", i, "붕대", true) end
  return (#o > 0) and ('<div class="ex-use">' .. table.concat(o) .. '</div>') or ''
end

local function party_card(G, R, items) B.__expe_cov.calls["77-explore.lua:766"]=true; 
  local rows = {}
  for _, e in ipairs(members(R)) do B.__expe_cov.branches["77-explore.lua:768:37536"]=true; 
    local i, m = e.slot, e.m
    local hp, mhp, mp, mmp = R.hp[i], R.mhp[i], R.mp[i], R.mmp[i]
    local down = hp <= 0
    local cl = B.CLS[m.cls]
    local btns = ""
    if items then B.__expe_cov.branches["77-explore.lua:774:37720"]=true;  btns = use_row(G, R, i, m, down) end
    rows[#rows + 1] = '<div class="ex-mem' .. (down and " down" or "") .. '">' .. B.PX.face(m.id, member_name(G, m), "ex-f") ..
      '<div class="ex-mt"><div class="ex-nm"><b>' .. B.esc(B.T(member_name(G, m))) .. '</b><small>' .. B.U("{cls}, Lv {lv}{down}", { cls = B.esc(cl and cl.name or ""), lv = m.L, down = down and B.U(", 부상 이탈") or "" }) .. '</small></div>' ..
      '<div class="ex-bar">' .. bar("hp", hp, mhp) .. '<em>HP ' .. hp .. '/' .. mhp .. '</em></div>' ..
      (mmp > 0 and ('<div class="ex-bar">' .. bar("mp", mp, mmp) .. '<em>MP ' .. mp .. '/' .. mmp .. '</em></div>') or '') .. '</div>' .. btns .. '</div>'
  end
  return '<div class="dk-card ex-party"><div class="so-h"><span class="dk-title">' .. B.U("파티") .. '</span><span class="dk-sub">' .. B.U(R.real and 'HP와 MP는 전투를 거치며 이어진다' or '아직 싸우지 않아 가득 차 있다') .. '</span></div>' ..
    table.concat(rows) .. '</div>'
end

local function retreat_card(R) B.__expe_cov.calls["77-explore.lua:784"]=true; 
  if R.ask then B.__expe_cov.branches["77-explore.lua:785:38695"]=true; 
    return '<div class="dk-card ex-ask"><div class="dk-text">' .. B.U("정말 퇴각할까요? 지금까지 모은 금화 {gold}, 물건, 경험치 {exp}는 가져가지만 <b>층 보스 보상과 돌파 기록은 받지 못합니다.</b>", { gold = R.loot.gold, exp = R.exp }) .. '</div>' ..
      '<div class="dk-row">' .. B.btn("ex_retreat_yes", B.U("퇴각한다"), "sm warn") .. B.btn("ex_retreat_no", B.U("계속한다"), "sm go") .. '</div></div>'
  end
  return '<div class="dk-row ex-foot">' .. B.btn("ex_retreat", B.U("퇴각"), "sm", B.U("모은 것만 가져간다")) .. '</div>'
end

local function explore_screen(G, R) B.__expe_cov.calls["77-explore.lua:792"]=true; 
  local nxt = R.step + 1
  local go = B.btn("ex_go", B.U("탐색한다"), "go ex-go", B.U("{next}/{total}번째 (전투 {battle}%, 발견 {find}%)", { next = nxt, total = B.EX.STEPS, battle = B.floor(B.EX.P_BATTLE * 100), find = 100 - B.floor(B.EX.P_BATTLE * 100) }))
  return head_card(G, R, R.step == 0 and B.U("입장") or B.U("탐색 {step}/{total}", { step = R.step, total = B.EX.STEPS })) .. last_card(R) .. party_card(G, R, true) ..
    (R.ask and '' or ('<div class="ex-act">' .. go .. '</div>')) .. retreat_card(R)
end

local function slot_row(G, R, key) B.__expe_cov.calls["77-explore.lua:799"]=true; 
  local eq = (G.equip and G.equip[key]) or {}
  local o = { '<div class="px-slots ex-slots">' }
  for _, s in ipairs(B.PX.SLOTS) do B.__expe_cov.branches["77-explore.lua:802:39876"]=true; 
    local cur = eq[s[1]]
    local has = type(cur) == "string" and cur ~= ""
    local cls = has and (" ex-r-" .. (rar_of(cur) or "common")) or ""
    o[#o + 1] = '<div class="px-slot ex-slot' .. (has and " fill" or "") .. '"><i class="im im-sl-' .. s[1] .. ' px-sli"></i><small>' .. B.U(s[2]) .. '</small><span class="px-sn' .. cls .. '">' ..
      (has and B.esc(B.PX.item_name(cur)) or B.U('비어 있음')) .. '</span>'
    if has then B.__expe_cov.branches["77-explore.lua:808:40306"]=true;  o[#o + 1] = B.btn("ex_un_" .. s[1], B.U("해제"), "sm") end
    for _, iid in ipairs(B.PX.items_for(G, s[1], key)) do B.__expe_cov.branches["77-explore.lua:809:40423"]=true; 
      o[#o + 1] = B.btn("ex_eq_" .. s[1] .. "_" .. B.gear_btn(iid), '<span class="ex-r-' .. (rar_of(iid) or "common") .. '">' .. B.esc(B.T(itname(iid))) .. '</span>', "sm", B.U("장착"))
    end
    o[#o + 1] = '</div>'
  end
  o[#o + 1] = '</div>'
  return table.concat(o)
end

local function gear_card(G, R) B.__expe_cov.calls["77-explore.lua:818"]=true; 
  local tabs = {}
  for _, e in ipairs(members(R)) do B.__expe_cov.branches["77-explore.lua:820:40784"]=true; 
    tabs[#tabs + 1] = B.btn("ex_who_" .. e.slot, B.esc(B.T(member_name(G, e.m))), "sm" .. (R.sel == e.slot and " on" or ""))
  end
  local key = equip_key(R, R.sel)
  if not key then B.__expe_cov.branches["77-explore.lua:824:40965"]=true;  R.sel = (members(R)[1] or { slot = 1 }).slot; key = equip_key(R, R.sel) end
  return '<div class="dk-card ex-gear"><div class="so-h"><span class="dk-title">' .. B.U("정비") .. '</span><span class="dk-sub">' .. B.U("장비 능력치는 능력치 검수 뒤에 확정한다. 지금은 자리만 바꾼다") .. '</span></div>' ..
    '<div class="dk-tabs">' .. table.concat(tabs) .. '</div>' .. (key and slot_row(G, R, key) or '') .. '</div>'
end

local function rest_screen(G, R) B.__expe_cov.calls["77-explore.lua:829"]=true; 
  local boss = B.btn("ex_boss", B.U("층 보스에게 도전"), "go ex-go", B.U("{boss}, 레이드 전투(4인)", { boss = B.esc(R.boss_name) }))
  return head_card(G, R, B.U("휴식")) .. last_card(R) .. party_card(G, R, true) .. (B.sx_rest_card and B.sx_rest_card(G, R) or "") .. (B.sx_potion_card and B.sx_potion_card(G, R) or "") .. gear_card(G, R) ..
    (R.ask and '' or ('<div class="ex-act">' .. boss .. '</div>')) .. retreat_card(R)
end

local RESULT_TITLE = { clear = "층 돌파", retreat = "퇴각", defeat = "도전 실패" }
-- 층 돌파: 더 내려갈지 돌아갈지 고른다(고르면 채팅이 한 번 이어진다). 그 밖에는 돌아가기만.
local function done_act(G, R, S) B.__expe_cov.calls["77-explore.lua:837"]=true; 
  if S.result == "clear" and R.note then B.__expe_cov.branches["77-explore.lua:838:42011"]=true; 
    local nxt = R.floor + 1
    local can = B.dn_allowed and B.dn_allowed(G, nxt)
    return '<div class="ex-act">' .. (can and B.btn("ex_next", B.U("다음 층으로 내려간다"), "go ex-go", B.U("{floor}층으로 곧장 들어간다. 파티는 지금 그대로", { floor = nxt })) or '') ..
      B.btn("ex_home", B.U("토르바로 돌아간다"), can and "ex-go" or "go ex-go", B.U("정비하고 다음에 다시 출정한다"))
  end
  return '<div class="ex-act">' .. B.btn("ex_home", B.U("토르바로 돌아간다"), "go ex-go", B.U("다음 층은 출정 화면에서 고른다"))
end
local function done_screen(G, R) B.__expe_cov.calls["77-explore.lua:846"]=true; 
  local S = R.summary or { result = "retreat", gold = 0, exp = 0, items = {}, lv = {}, lost_items = {} }
  local rows = {}
  local function row(ic, txt) B.__expe_cov.calls["77-explore.lua:849"]=true;  rows[#rows + 1] = '<div class="ex-lr"><i class="im im-' .. ic .. ' ex-li"></i><span>' .. txt .. '</span></div>' end
  if S.result ~= "defeat" then B.__expe_cov.branches["77-explore.lua:850:42802"]=true; 
    row("nd-treasure", B.U("금화 <b>{gold}</b>", { gold = S.gold }))
    local ids = {}
    for iid in pairs(S.items) do B.__expe_cov.branches["77-explore.lua:853:42923"]=true;  ids[#ids + 1] = iid end
    table.sort(ids)
    for _, iid in ipairs(ids) do B.__expe_cov.branches["77-explore.lua:855:43000"]=true; 
      local d = B.ITEMS[iid]
      local ic = (d and d.slot) and ("sl-" .. d.slot) or ((B.ITEM_IC or {})[iid] or "it-hp")
      row(ic, '<span class="ex-r-' .. (rar_of(iid) or "common") .. '">' .. B.esc(B.T(itname(iid))) .. '</span> ×' .. S.items[iid])
    end
    for _, c in ipairs(S.gear or {}) do B.__expe_cov.branches["77-explore.lua:860:43301"]=true; 
      local gr = B.gear_roll(c)
       if gr then B.__expe_cov.branches["77-explore.lua:862:43349"]=true;  row("sl-" .. gr.slot, B.U("장비:") .. ' <span class="ex-r-' .. gr.rarity .. '">' .. B.esc(B.C1_gear_label(c)) .. '</span>') end
    end
    if (S.gear_lost or 0) > 0 then B.__expe_cov.branches["77-explore.lua:864:43518"]=true;  row("nd-return", B.U("가방이 가득 찼습니다. 장비 {n}개는 버려졌습니다", { n = S.gear_lost })) end
    row("nd-battle", B.U("경험치 <b>{exp}</b>{level}", { exp = S.exp, level = #S.lv > 0 and (' (' .. B.esc(table.concat(S.lv, ', ')) .. ')') or '' }))
    if S.aff and #S.aff > 0 then B.__expe_cov.branches["77-explore.lua:866:43778"]=true;  row("nd-battle", B.U("호감 ▲ {list}", { list = B.esc(table.concat(S.aff, ', ')) })) end
  else B.__expe_cov.branches["77-explore.lua:867:43871"]=true; 
    row("nd-return", B.U("모은 금화 {gold:와과} 물건을 잃었다. 들고 간 금화 {penalty:을를} 잃었다", { gold = S.lost_gold, penalty = S.penalty or 0 }))
    for _, c in ipairs(S.kept_gear or {}) do B.__expe_cov.branches["77-explore.lua:869:44047"]=true; 
      local gr = B.gear_roll(c)
      if gr then B.__expe_cov.branches["77-explore.lua:871:44094"]=true;  row("sl-" .. gr.slot, B.U("챙긴 장비:") .. ' <span class="ex-r-' .. gr.rarity .. '">' .. B.esc(B.C1_gear_label(c)) .. '</span>') end
    end
    if (S.lost_gear or 0) > 0 then B.__expe_cov.branches["77-explore.lua:873:44266"]=true;  row("nd-return", B.U("장비 {n}개는 잃었다", { n = S.lost_gear })) end
  end
  local sub = ({ clear = (S.first and B.U("구역 보스를 처음 쓰러뜨렸다") or B.U("{boss:을를} 쓰러뜨렸다", { boss = R.boss_name })), retreat = B.U("보스는 상대하지 않았다. 모은 것만 가져왔다"), defeat = B.U("파티가 무너졌다") })[S.result] or ""
  return '<div class="dk-card gold ex-done"><div class="so-h"><span class="dk-title"><i class="im im-' .. (S.result == "clear" and "nd-done" or "nd-return") .. ' so-nd"></i>' ..
    B.U("{floor}층 {result}", { floor = S.floor, result = B.U(RESULT_TITLE[S.result] or "") }) .. '</span><span class="dk-sub">' .. B.esc(sub) .. '</span></div>' .. table.concat(rows) ..
    '<div class="dk-sub ex-ln">' .. B.U("탐색 {steps}번, 전투 승리 {wins}번", { steps = S.steps, wins = S.wins }) .. '</div></div>' ..
    done_act(G, R, S) .. '</div>'
end

B.SCREENS.dungeon = function(G, id) B.__expe_cov.calls["77-explore.lua:882"]=true; 
  local R = B.ex_run(G)
  if not R then B.__expe_cov.branches["77-explore.lua:884:45141"]=true; 
    return '<div class="dk-card"><div class="dk-title">' .. B.U("대던전") .. '</div><div class="dk-sub">' .. B.U("진행 중인 층이 없습니다. 토르바에서 다시 출정하세요.") .. '</div></div><div class="ex-act">' ..
      B.btn("ex_home", B.U("토르바로"), "go ex-go") .. '</div>'
  end
  if R.phase == "done" then B.__expe_cov.branches["77-explore.lua:888:45420"]=true;  return done_screen(G, R) end
  if R.phase == "rest" then B.__expe_cov.branches["77-explore.lua:889:45477"]=true;  return rest_screen(G, R) end
  return explore_screen(G, R)
end

-- 이름표(HUD): 대던전 · n층 (88-lore 의 B.place_label 이 장면 dungeon 일 때 부른다)
function B.ex_label(G) B.__expe_cov.calls["77-explore.lua:894"]=true; 
  local R = type(G.dungeon) == "table" and G.dungeon.run
  return B.U("대던전{floor}", { floor = ((type(R) == "table" and R.floor) and B.U(" {n}층", { n = R.floor }) or "") })
end

B.CTX["21-dungeon"] = function(G) B.__expe_cov.calls["77-explore.lua:899"]=true; 
  local R = type(G.dungeon) == "table" and G.dungeon.run
  if G.scene ~= "dungeon" or type(R) ~= "table" then B.__expe_cov.branches["77-explore.lua:901:45954"]=true;  return "" end
  local ph = ({ explore = "exploring", rest = "resting before the floor boss", done = "settlement" })[R.phase] or "exploring"
  return "Great Dungeon: floor " .. R.floor .. ", " .. ph .. ", exploration " .. R.step .. "/" .. B.EX.STEPS
end

-- ---------- 저장 이어받기: 옛 물약 칸(potion · mana) → 소형(hp_s · mp_s) ----------
local function move_old(t) B.__expe_cov.calls["77-explore.lua:907"]=true; 
  if type(t) ~= "table" then B.__expe_cov.branches["77-explore.lua:908:46338"]=true;  return end
  for old, new in pairs({ potion = "hp_s", mana = "mp_s" }) do B.__expe_cov.branches["77-explore.lua:909:46414"]=true; 
    if t[old] ~= nil then B.__expe_cov.branches["77-explore.lua:910:46438"]=true; 
      t[new] = (tonumber(t[new]) or 0) + (tonumber(t[old]) or 0)
      t[old] = nil
    end
  end
end
local prev_migrate = B.G_migrate
function B.G_migrate(t) B.__expe_cov.calls["77-explore.lua:917"]=true; 
  t = prev_migrate(t)
  move_old(t.items)
  local R = type(t.dungeon) == "table" and t.dungeon.run
  if type(R) == "table" and type(R.loot) == "table" then B.__expe_cov.branches["77-explore.lua:921:46753"]=true;  move_old(R.loot.items) end
  return t
end
B.ex_move_old_items = move_old
