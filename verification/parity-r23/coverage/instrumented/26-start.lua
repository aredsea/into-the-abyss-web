-- ===== 균열 입장 → 전투 상태 만들기(거점 G → 전투 st) =====
-- 75-sortie.lua 의 「균열로 들어간다」(so_go)가 부른다. G.town.bn 은 부르는 쪽이 이미 올렸다(여기서 올리지 않는다).
-- 출전 순서: 페르소나(출전이면) → G.party 순서. 4칸이 안 차면 빈 자리.
function B.battle_pm(G) B.__r23_cov.calls["26-start.lua:4"]=true; 
  local pm = {}
  if (G.persona.fight or 1) == 1 then B.__r23_cov.branches["26-start.lua:6:253"]=true; 
    local c = B.cls_of(G.persona.cls or "") or B.CLS.warrior
    -- race · lin · nat = 만들기에서 고른 종족 · 수인 계통 · 출신(이름 글자 그대로) — 종족·국가 특성(34-traits)이 읽는다
    pm[#pm + 1] = { id = "persona", cls = c.id, L = (B.lv_of and B.lv_of(G, "persona")) or (G.persona.lv or 1),
      race = G.persona.race or "", lin = G.persona.lineage or "", nat = G.persona.nation or "",
      ps = type(G.persona.stats) == "table" and G.persona.stats or nil,   -- 만들기에서 찍은 능력치(보너스 포함) — 20-state 가 레벨 성장분과 합친다(10-13 제보: 속도·민첩 보너스가 전투에 안 먹음)
      skill = B.ps_ready and B.ps_ready(G.persona.skill) and B.ps_clean(G.persona.skill) or nil,
      eq = B.gear_eq_of and B.gear_eq_of(G, "persona") or nil, forge = G.forge }   -- 낀 장비 코드와 제련 단계
  end
  for _, cid in ipairs(G.party or {}) do B.__r23_cov.branches["26-start.lua:15:1012"]=true; 
    if #pm >= 4 then B.__r23_cov.branches["26-start.lua:16:1031"]=true;  break end
    local k = B.CAST[cid]
    if k and B.has(G.roster, cid) then B.__r23_cov.branches["26-start.lua:18:1106"]=true; 
      local c = B.cls_of(k.cls) or B.CLS.warrior
      pm[#pm + 1] = { id = cid, cls = c.id, L = (B.lv_of and B.lv_of(G, cid)) or 1, eq = B.gear_eq_of and B.gear_eq_of(G, cid) or nil, forge = G.forge }
    end
  end
  while #pm < 4 do B.__r23_cov.branches["26-start.lua:23:1343"]=true;  pm[#pm + 1] = { id = "", cls = "", L = 1 } end
  return pm
end

-- 적 편성 [제안 10-08]: 출전 인원에 맞춘다 — 1~2명 → 사냥개 둘 · 3명 → + 궁수 · 4명 → + 감시관(정예). 던전 구성 정본은 DUNGEON.md(미정).
function B.foes_for(pm) B.__r23_cov.calls["26-start.lua:28"]=true; 
  local n = 0
  for _, m in ipairs(pm) do B.__r23_cov.branches["26-start.lua:30:1575"]=true;  if m.id ~= "" then B.__r23_cov.branches["26-start.lua:30:1592"]=true;  n = n + 1 end end
  if n <= 2 then B.__r23_cov.branches["26-start.lua:31:1627"]=true;  return { 1, 2 } elseif n == 3 then B.__r23_cov.branches["26-start.lua:31:1662"]=true;  return { 1, 2, 3 } end
  return { 1, 2, 3, 4 }
end

-- 균열 이름 → 균열 id (「남서 설산 균열」 · 「남서 설산」 둘 다). 모르는 균열이면 nil
function B.rift_id_of(name) B.__r23_cov.calls["26-start.lua:36"]=true; 
  name = tostring(name or "")
  for _, rid in ipairs(B.RIFT_ORDER) do B.__r23_cov.branches["26-start.lua:38:1872"]=true; 
    local r = B.RIFTS[rid]
    if name == r.quest_name or name == r.name then B.__r23_cov.branches["26-start.lua:40:1948"]=true;  return rid end
  end
  return nil
end

-- 의뢰의 적 편성(27-compose). 알려진 균열은 그 균열의 계통 + 공통. 난이도가 전투를 정한다(72-guild B.gd_fight): 낮음 일반 · 중간 정예 · 높음 정예 또는 균열 핵 레이드.
-- 의뢰에 cmp 표식이 없으면(손으로 만든 시험 의뢰 · 표식 이전의 옛 저장 의뢰) nil — 옛 고정 편성(B.foes_for · B.EDEF 4칸)을 그대로 쓴다.
-- 옛 시험·측정 도구(harness_personal_* · balance_class …)가 그 네 적을 가정한다. 길드가 새로 거는 의뢰(72-guild B.gd_new)에는 cmp = 1 이 붙는다.
function B.quest_compose(G, q, pm) B.__r23_cov.calls["26-start.lua:48"]=true; 
  local n = 0
  for _, m in ipairs(pm) do B.__r23_cov.branches["26-start.lua:50:2396"]=true;  if m.id ~= "" then B.__r23_cov.branches["26-start.lua:50:2413"]=true;  n = n + 1 end end
  local stars = math.max(1, math.min(4, tonumber(q.stars) or 1))
  local rid = B.rift_id_of(q.rift)
  if not rid or not q.cmp then B.__r23_cov.branches["26-start.lua:53:2562"]=true;  return nil end
  local seed = math.floor(B.G_rnd(G) * 2147483646)
  local fk = B.gd_fight(q)
  local kind = (fk == "core") and "rift_core" or fk
  return B.compose(seed, { kind = kind, rift_id = rid, stars = math.min(stars, 3), party_n = n })
end

function B.battle_start(G, id, q) B.__r23_cov.calls["26-start.lua:60"]=true; 
  local pm = B.battle_pm(G)
  local enc = B.quest_compose(G, q, pm)
  local el = (B.gd_qlv and B.gd_qlv(G, q)) or tonumber(q.lv) or 1
  local dm = B.DIFF_MUL and B.DIFF_MUL(G) or { hp = 1, atk = 1 }
  if B.gd_difficulty(q) == "엘리트" then B.__r23_cov.branches["26-start.lua:65:3081"]=true; 
    local power = math.max(1.5, math.min(2, tonumber(q.strength) or 1.5))
    dm = { hp = (dm.hp or 1) * power, atk = (dm.atk or 1) * power }
  end
  local st = B.fresh(G.town.bn or 0, dm,
    { pm = pm, el = math.max(1, math.min(B.LEVEL_MAX or 40, el)), star = math.max(1, math.min(4, tonumber(q.stars) or 1)), enc = enc, foe = (not enc) and B.foes_for(pm) or nil })
  if q.reward_v == 2 then B.__r23_cov.branches["26-start.lua:71:3475"]=true;  st.qmult = B.GD_DIFFICULTY[B.gd_difficulty(q)].reward end
  -- 전투 결과 줄의 금화 = 의뢰 보상 × (1 + 마렌토 「장부」 +15% × 출전한 마렌토 인원). 거점 정산(70-town tw_settle)이 st.rg 를 읽어야 실제 지급과 같아진다.
  local qg = B.gd_gold and B.gd_gold(G, q) or q.gold   -- 레벨 배수를 곱한 의뢰 보상(72-guild)
  st.rg, st.qid, st.place = (B.reward_gold and B.reward_gold(st, qg) or qg), q.id, q.rift
  st.sid = G.town.bn or 0   -- 입장 번호(정산·경험치 중복 방지의 기준 — 다시 싸우기로 바뀌지 않는다)
  st.bag = B.ex_bag and B.ex_bag(G) or nil   -- 전투 중 아이템(78-battle-item)이 보여 줄 재고 사본
  G.pending, G.pending_at, G.pend_soft = "", nil, nil   -- 출정하면 거점에서 보내지 않은 장면 지시는 버린다(장면이 바뀌었다 · 검수 5차 #4)
  if st.over ~= "" then B.__r23_cov.branches["26-start.lua:78:4109"]=true;    -- 첫 차례가 오기 전에 끝났다(적이 먼저 움직여 쓰러뜨림) — 결과 줄은 여기서
    if st.over == "win" then B.__r23_cov.branches["26-start.lua:79:4187"]=true;  st.exp = B.exp_reward(st) end
    st.res = st.res:gsub(B.U("금화 {gold}", { gold = B.REWARD.gold }), B.U("금화 {gold}", { gold = st.rg or 0 }), 1)
    B.send_result(id, st)
  end
  B.save(id, st)
  G.scene = "battle"
  G.ui.panel = ""
end
