-- ===== 연합 길드 본관 : 의뢰판 · 동료 소개 창구 (파티 편성은 75-sortie 의 균열 입장 화면) =====
-- 의뢰판은 낮음 · 중간 · 높음 세 칸이다. ★는 균열 편성에만 쓰며 보상과 적 레벨은 난이도가 정한다.
-- 동료 소개 규칙(RECRUIT.md): 금화 100 + 20 × 영입 수 · 아직 동료가 아닌 사람 중 무작위 1명 · 만나면 바로 동료 · 등급 없음
B.QUEST_RIFTS = { "남서 설산 균열", "남동 숲 균열" }
B.QUEST_KINDS = {
  { k = "토벌", t = "균열 핵 토벌", d = "균열 안쪽에 자리 잡은 핵을 부순다." },
  { k = "구조", t = "고립된 탐사대 구조", d = "갇힌 길드 탐사대에게 닿는 길을 막은 균열의 적을 물리친다." },
  { k = "회수", t = "잃어버린 유품 회수", d = "숨진 모험가의 유품이 놓인 자리를 지키는 균열의 적을 물리친다." },
}
B.QUEST_BOARD = 4
B.GUILD = json.decode(B.GUILD_RAW)
function B.gd_title(q) B.__expe_cov.calls["72-guild.lua:12"]=true; 
  local prefix = (q.rift or "") .. ", "
  if (q.title or ""):sub(1, #prefix) == prefix then B.__expe_cov.branches["72-guild.lua:14:657"]=true;  return B.U("{rift}, {title}", { rift = q.rift, title = q.title:sub(#prefix + 1) }) end
  return B.T(q.title or "")
end
function B.gd_title_en(q) B.__expe_cov.calls["72-guild.lua:17"]=true; 
  local prefix = (q.rift or "") .. ", "
  if (q.title or ""):sub(1, #prefix) == prefix then B.__expe_cov.branches["72-guild.lua:19:894"]=true;  return B.C1_en(q.rift) .. ", " .. B.C1_en(q.title:sub(#prefix + 1)) end
  return B.C1_en(q.title or "")
end

function B.gd_find(G, qid) B.__expe_cov.calls["72-guild.lua:23"]=true; 
  if not qid or qid == "" then B.__expe_cov.branches["72-guild.lua:24:1061"]=true;  return nil end
  for _, q in ipairs((G.guild and G.guild.quests) or {}) do B.__expe_cov.branches["72-guild.lua:25:1138"]=true;  if q.id == qid then B.__expe_cov.branches["72-guild.lua:25:1156"]=true;  return q end end
  return nil
end

function B.gd_remove(G, qid) B.__expe_cov.calls["72-guild.lua:29"]=true; 
  for i, q in ipairs(G.guild.quests) do B.__expe_cov.branches["72-guild.lua:30:1262"]=true; 
    if q.id == qid then B.__expe_cov.branches["72-guild.lua:31:1284"]=true;  table.remove(G.guild.quests, i) return true end
  end
  return false
end

-- 새 의뢰 하나. 같은 (균열, 종류)가 판에 이미 있으면 몇 번 다시 뽑는다. 난수는 B.G_rnd 만 쓴다.
function B.gd_rnd(G) B.__expe_cov.calls["72-guild.lua:37"]=true;  return B.G_rnd(G) end   -- 코어 G_rnd 가 연속 호출 상관을 없앴다(10-08)

B.GD_DIFFICULTY = { ["낮음"] = { delta = -3, reward = 0.7 }, ["중간"] = { delta = 0, reward = 1 }, ["높음"] = { delta = 3, reward = 1.6 }, ["엘리트"] = { delta = 0, reward = B.GUILD.elite.reward } }
function B.gd_difficulty(q) B.__expe_cov.calls["72-guild.lua:40"]=true; 
  if q and B.GD_DIFFICULTY[q.difficulty] then B.__expe_cov.branches["72-guild.lua:41:1768"]=true;  return q.difficulty end
  local stars = tonumber(q and q.stars) or 1
  return (stars >= 3) and "높음" or ((stars >= 2) and "중간" or "낮음")
end
function B.gd_base_lv(G) B.__expe_cov.calls["72-guild.lua:45"]=true; 
  local lv = B.lv_of(G, "persona")
  for _, cid in ipairs(G.roster or {}) do B.__expe_cov.branches["72-guild.lua:47:2011"]=true;  lv = math.max(lv, B.lv_of(G, cid)) end
  return lv
end
-- 실제 플레이의 Lv17 · 최고 5층을 기준으로 레벨을 대표 층에 잇는다.
-- 높은 레벨 구간은 40레벨에서 25층 배수까지 매끄럽게 연장한다.
function B.lv_reward(lv) B.__expe_cov.calls["72-guild.lua:52"]=true; 
  lv = math.max(1, math.min(40, tonumber(lv) or 1))
  local points = { { 1, 1 }, { 5, 2 }, { 10, 4 }, { 17, 5 }, { 20, 7 }, { 30, 13 }, { 40, 25 } }
  local target = 25
  for i = 2, #points do B.__expe_cov.branches["72-guild.lua:56:2369"]=true; 
    local a, b = points[i - 1], points[i]
    if lv <= b[1] then B.__expe_cov.branches["72-guild.lua:58:2432"]=true;  target = a[2] + (b[2] - a[2]) * (lv - a[1]) / (b[1] - a[1]); break end
  end
  local lo = math.floor(target)
  local frac = target - lo
  local a = B.floor_mult(lo).reward
  return a * (B.floor_mult(math.min(25, lo + 1)).reward / a) ^ frac
end
-- 새 의뢰의 기본 금화는 100, 옛 의뢰는 저장된 기본 금화를 사용한다.
function B.gd_gold(G, q) B.__expe_cov.calls["72-guild.lua:66"]=true; 
  if type(q) ~= "table" then B.__expe_cov.branches["72-guild.lua:67:2774"]=true;  return 0 end
  local mult = q.reward_v == 2 and B.GD_DIFFICULTY[B.gd_difficulty(q)].reward or 1
  local lv = B.gd_qlv(G, q)
  if q.reward_v == 2 and B.gd_difficulty(q) == "엘리트" then B.__expe_cov.branches["72-guild.lua:70:2956"]=true;  lv = math.min(40, lv + 3) end
  return B.floor((tonumber(q.gold) or 0) * B.lv_reward(lv) * mult + 0.5)
end

function B.gd_qlv(G, q) B.__expe_cov.calls["72-guild.lua:74"]=true; 
  local v = tonumber(q and q.lv)
  if v then B.__expe_cov.branches["72-guild.lua:76:3133"]=true;  return math.max(1, math.min(40, math.floor(v))) end
  local base = B.gd_base_lv(G)
  local delta = B.GD_DIFFICULTY[B.gd_difficulty(q)].delta
  return math.max(1, math.min(40, base + delta))
end

-- 의뢰가 실제로 치르는 전투: "core"(균열 핵 레이드) · "elite"(정예 조합 전투) · "battle"(일반 조합 전투). 의뢰판 표시와 출정 편성이 같이 읽는다.
function B.gd_fight(q) B.__expe_cov.calls["72-guild.lua:83"]=true; 
  if B.gd_difficulty(q) == "엘리트" then B.__expe_cov.branches["72-guild.lua:84:3490"]=true;  return q.kind == "토벌" and "core" or "elite" end
  if q.kind == "토벌" then B.__expe_cov.branches["72-guild.lua:85:3563"]=true;  return "core" end
  return B.gd_difficulty(q) == "낮음" and "battle" or "elite"
end
B.GD_FIGHT_TAG = { core = "균열 핵 레이드", elite = "정예 전투", battle = "일반 전투" }

-- 균열 하나의 의뢰 ★ 범위(균열 표 star_min~star_max). 모르는 균열은 1~3.
function B.gd_star_range(rift) B.__expe_cov.calls["72-guild.lua:91"]=true; 
  local rid = B.rift_id_of and B.rift_id_of(rift)
  local R = rid and B.RIFTS[rid]
  if not R then B.__expe_cov.branches["72-guild.lua:94:3906"]=true;  return 1, 3 end
  return math.max(1, R.star_min or 1), math.min(3, R.star_max or 3)   -- 조합기는 균열 ★ 를 3 까지만 안다(27-compose) — ★4 균열(북동 화산)을 의뢰에 넣으면 3 으로 눌린다
end

function B.gd_new(G) B.__expe_cov.calls["72-guild.lua:98"]=true; 
  B.tw_T(G)
  local gd = G.guild
  gd.qn = (gd.qn or 0) + 1
  local counts = { ["낮음"] = 0, ["중간"] = 0, ["높음"] = 0, ["엘리트"] = 0 }
  for _, q in ipairs(gd.quests) do B.__expe_cov.branches["72-guild.lua:103:4253"]=true;  local d = B.gd_difficulty(q); counts[d] = counts[d] + 1 end
  local missing = {}
  for _, d in ipairs({ "낮음", "중간", "높음", "엘리트" }) do B.__expe_cov.branches["72-guild.lua:105:4387"]=true;  if counts[d] == 0 then B.__expe_cov.branches["72-guild.lua:105:4408"]=true;  missing[#missing + 1] = d end end
  local rift, kind, stars
  -- 의뢰 하나가 쓰는 난수: 코어 G_rnd 는 연속 호출이 등차수열이라(한 번 부를 때마다 약 0.03 씩 어긋난다) 한 의뢰 안에서 여러 번 부르면 균열 · ★ · 종류가 서로 묶인다.
  -- G_rnd 를 한 번만 불러 씨앗으로 쓰고, 이 의뢰의 나머지 선택은 국소 난수(27-compose mkrng)에서 뽑는다 — 같은 G 상태면 같은 의뢰(결정론 유지).
  local rr = B.mkrng(math.floor(B.gd_rnd(G) * 2147483646))
  local difficulty = missing[math.floor(rr() * #missing) + 1] or "중간"
  for _ = 1, 6 do B.__expe_cov.branches["72-guild.lua:111:4826"]=true; 
    rift = B.QUEST_RIFTS[math.floor(rr() * #B.QUEST_RIFTS) + 1] or B.QUEST_RIFTS[1]
    local lo, hi = B.gd_star_range(rift)
    stars = (difficulty == "높음" or difficulty == "엘리트") and hi or (difficulty == "낮음" and lo or lo + math.floor(rr() * (hi - lo + 1)))
    local kinds = {}
    for _, kd in ipairs(B.QUEST_KINDS) do B.__expe_cov.branches["72-guild.lua:116:5149"]=true; 
      if kd.k ~= "토벌" or difficulty == "높음" or difficulty == "엘리트" then B.__expe_cov.branches["72-guild.lua:117:5219"]=true;  kinds[#kinds + 1] = kd end
    end
    kind = kinds[math.floor(rr() * #kinds) + 1] or kinds[1]
    local dup = false
    for _, q in ipairs(gd.quests) do B.__expe_cov.branches["72-guild.lua:121:5375"]=true;  if q.rift == rift and q.kind == kind.k then B.__expe_cov.branches["72-guild.lua:121:5417"]=true;  dup = true end end
    if not dup then B.__expe_cov.branches["72-guild.lua:122:5456"]=true;  break end
  end
  local lv = math.min(40, math.max(1, B.gd_base_lv(G) + B.GD_DIFFICULTY[difficulty].delta))
  local strength = difficulty == "엘리트" and (B.GUILD.elite.strength_min + math.floor(rr() * B.GUILD.elite.strength_steps) * B.GUILD.elite.strength_step) or nil
  return { id = "q" .. gd.qn, title = rift .. ", " .. kind.t, rift = rift, kind = kind.k, stars = stars, difficulty = difficulty, gold = 100, reward_v = 2, d = kind.d, lv = lv, cmp = 1, strength = strength }
end

function B.gd_gear(G, q, pm, index) B.__expe_cov.calls["72-guild.lua:129"]=true; 
  local cfg = B.GUILD.elite
  local seed = (tonumber(G.seed) or 0) + (tonumber((q.id or ""):match("%d+")) or 0) * 7919
  local x = B.ex_mix(seed, index, 2, 0) * 100
  local rarity = "rare"
  for _, r in ipairs({ "rare", "epic", "legend" }) do B.__expe_cov.branches["72-guild.lua:134:6217"]=true;  x = x - cfg.gear_rarities[r]; if x < 0 then B.__expe_cov.branches["72-guild.lua:134:6259"]=true;  rarity = r; break end end
  local cls = B.gear_party_cls(pm)
  if #cls == 0 then B.__expe_cov.branches["72-guild.lua:136:6340"]=true;  cls = { "warrior" } end
  local c = cls[math.floor(B.ex_mix(seed, index, 3, 0) * #cls) + 1]
  local slots = { "weapon", "armor", "acc" }
  local slot = slots[math.floor(B.ex_mix(seed, index, 4, 0) * 3) + 1]
  local pool = {}
  for _, gid in ipairs(B.gear().by[c][slot]) do B.__expe_cov.branches["72-guild.lua:141:6615"]=true;  if B.gear().items[gid].rarity == rarity then B.__expe_cov.branches["72-guild.lua:141:6658"]=true;  pool[#pool + 1] = gid end end
  if #pool == 0 then B.__expe_cov.branches["72-guild.lua:142:6709"]=true;  return nil end
  local gid = pool[math.floor(B.ex_mix(seed, index, 5, 0) * #pool) + 1]
  return B.gear_code(gid, math.floor(B.ex_mix(seed, index, 6, 0) * 1099511627776) + 1)
end

-- 판을 3개로 채운다
function B.gd_fill(G) B.__expe_cov.calls["72-guild.lua:148"]=true; 
  B.tw_T(G)
  while #G.guild.quests < B.QUEST_BOARD do B.__expe_cov.branches["72-guild.lua:150:6981"]=true; 
    G.guild.quests[#G.guild.quests + 1] = B.gd_new(G)
  end
end

function B.gd_refresh_cost(G) B.__expe_cov.calls["72-guild.lua:155"]=true; 
  local T = B.tw_T(G)
  return 10 * (1 << math.min(T.rr or 0, 4))   -- 10 → 20 → 40 → 80 → 160(정수로)
end

function B.gd_recruit_cost(G) B.__expe_cov.calls["72-guild.lua:160"]=true;  return 100 + 20 * ((G.guild and G.guild.recruits) or 0) end

-- 아직 roster 에 없는 동료 id 목록(B.CAST_ORDER 순)
function B.gd_candidates(G) B.__expe_cov.calls["72-guild.lua:163"]=true; 
  local out = {}
  for _, cid in ipairs(B.CAST_ORDER or {}) do B.__expe_cov.branches["72-guild.lua:165:7406"]=true; 
    if not B.has(G.roster, cid) then B.__expe_cov.branches["72-guild.lua:166:7441"]=true;  out[#out + 1] = cid end
  end
  return out
end

-- 호감 단계 이름(0~200 — 정본은 74-affection 의 B.aff_stage. 맹세 100~ · 운명 150~ 는 10-10 확장 [제안])
function B.gd_tier(a) B.__expe_cov.calls["72-guild.lua:172"]=true; 
  a = a or 0
  if a >= 150 then B.__expe_cov.branches["72-guild.lua:174:7630"]=true;  return "운명" elseif a >= 100 then B.__expe_cov.branches["72-guild.lua:174:7663"]=true;  return "맹세" elseif a >= 80 then B.__expe_cov.branches["72-guild.lua:174:7695"]=true;  return "깊은 인연" elseif a >= 50 then B.__expe_cov.branches["72-guild.lua:174:7730"]=true;  return "유대" elseif a >= 20 then B.__expe_cov.branches["72-guild.lua:174:7762"]=true;  return "신뢰" end
  return "낯섦"
end

function B.gd_quest_card(G, q, active) B.__expe_cov.calls["72-guild.lua:178"]=true; 
  local btns
  if active then B.__expe_cov.branches["72-guild.lua:180:7866"]=true; 
    btns = '<span class="dk-tag">' .. B.U("진행 중") .. '</span>' .. B.btn("gd_drop", B.U("포기"), "sm warn")
  else B.__expe_cov.branches["72-guild.lua:182:7978"]=true; 
    btns = B.btn("gd_acc_" .. q.id, B.U("수락"), "sm go") .. B.btn("gd_rej_" .. q.id, B.U("거절"), "sm")
  end
  return '<div class="dk-card tw-quest' .. (active and " gold" or "") .. '"><div class="tw-q-h"><span class="dk-title tw-item-n">' .. (B.gd_difficulty(q) == "엘리트" and '<i class="im im-elite-q tw-iico"></i>' or '') .. B.esc(B.gd_title(q)) ..
    '</span><span class="tw-stars">' .. B.tw_stars(q.stars) .. '</span></div><div class="dk-sub">' .. B.esc(B.T(q.d)) ..
    '</div><div class="dk-row"><span class="dk-tag">' .. B.U("난이도 {difficulty}", { difficulty = B.U(B.gd_difficulty(q)) }) .. '</span><span class="dk-tag">' .. B.U(q.kind) .. '</span><span class="dk-tag">' .. B.U(B.GD_FIGHT_TAG[B.gd_fight(q)]) .. '</span><span class="dk-tag">' .. B.U("보상 금화 {gold}", { gold = B.gd_gold(G, q) }) .. '</span><span class="dk-tag">' .. B.U("적 Lv {lv}", { lv = B.gd_qlv(G, q) }) .. '</span>' .. (q.strength and '<span class="dk-tag">' .. B.U("적 강도 ×{n}", { n = string.format("%.1f", q.strength) }) .. '</span><span class="dk-tag">' .. B.U("장비 1~2개 확정") .. '</span>' or "") .. '</div>' ..
    '<div class="dk-row tw-q-f">' .. btns .. '</div></div>'
end

local function tab_board(G) B.__expe_cov.calls["72-guild.lua:191"]=true; 
  local qs = G.guild.quests
  if #qs == 0 then B.__expe_cov.branches["72-guild.lua:193:9204"]=true; 
    return '<div class="dk-card"><div class="dk-sub">' .. B.U("의뢰판이 비어 있다.") .. '</div>' .. B.btn("gd_fill", B.U("의뢰판 살펴보기"), "sm") .. '</div>'
  end
  local out = {}
  for _, q in ipairs(qs) do B.__expe_cov.branches["72-guild.lua:197:9401"]=true;  out[#out + 1] = B.gd_quest_card(G, q, q.id == G.guild.active) end
  local cost = B.gd_refresh_cost(G)
  return table.concat(out) .. '<div class="dk-row tw-q-r">' ..
    B.btn("gd_refresh", B.U("의뢰판 새로 걸기"), "sm", B.U("금화 {n}", { n = cost })) .. '<span class="dk-sub">' .. B.U("받은 의뢰는 그대로 두고 나머지를 바꾼다") .. '</span></div>'
end

-- (최상위 local 개수 한계 때문에 do 블록 안에 둔다 — 밖으로는 B.gd_recruit_tab 하나만 나간다)
-- 동료 소개 창구 화면(사장님 10-10): 소개비·금화·명단 수 → 소개받기 → 방금 만난 사람 카드 → 만난 동료 목록. 동료 등급·확률표 없음.
do B.__expe_cov.branches["72-guild.lua:205:9885"]=true; 
  local function recruit_cell(label, val, sub, cls) B.__expe_cov.calls["72-guild.lua:206"]=true; 
    return '<div class="gd-cell' .. (cls and (" " .. cls) or "") .. '"><small>' .. B.U(label) .. '</small><b>' .. val .. '</b>' .. (sub and ('<span class="d">' .. sub .. '</span>') or '') .. '</div>'
end

  local function recruit_result(G, id) B.__expe_cov.calls["72-guild.lua:210"]=true; 
    local T = B.tw_T(G)
    local cid = T.meet
    local c = cid and B.CAST[cid]
    if not c or not B.has(G.roster, cid) then B.__expe_cov.branches["72-guild.lua:214:10306"]=true;  return "" end
    local PX = B.PX
    local race = c.race .. ((c.lineage or "") ~= "" and ("(" .. c.lineage .. ")") or "")
    local a = PX.aff(G, cid)
    local busy = B.pend_busy(G, id)
    return '<div class="dk-card gold gd-result"><div class="dk-sub">' .. B.U(busy and "방금 이어진 사람" or "가장 최근에 소개받은 사람") .. '</div>' ..
      '<div class="gd-hero">' .. PX.face(cid, c.name, "gd-f") .. '<div class="gd-info"><div class="dk-title">' .. B.esc(B.T(c.full)) .. '</div><div class="dk-row">' ..
      '<span class="dk-tag">' .. B.esc((c.lineage or "") ~= "" and B.U("{race}({lineage})", { race = c.race, lineage = c.lineage }) or B.T(race)) .. '</span><span class="dk-tag">' .. B.esc(B.T(c.nation)) .. '</span><span class="dk-tag">' .. B.esc(B.T(c.cls)) ..
      '</span><span class="dk-tag">' .. B.esc(B.T(c.row)) .. '</span>' .. PX.eltag(c.el) .. '</div>' ..
      '<div class="dk-row gd-aff"><span class="dk-sub">' .. B.U("호감 {stage} ({a} / {max})", { stage = B.gd_tier(a), a = a, max = B.AFF.MAX }) .. '</span></div>' .. PX.bar("aff", math.max(a, 0), B.AFF.MAX) .. '</div></div>' ..
    '<div class="gd-skills"><div class="gd-sk"><small>' .. B.U("개인 스킬") .. B.C1_chip(true) .. '</small><b>' .. B.esc(B.T(c.skill)) .. '</b></div>' ..
    '<div class="gd-sk"><small>' .. B.U("개인 특성") .. B.C1_chip(false) .. '</small><b><i class="im im-t-' .. cid .. ' gd-ti"></i>' .. B.esc(B.T(c.trait)) .. '</b></div></div>' ..
      '<div class="gd-next">' .. (busy and B.U("「보내기」를 누르면 {name:와과}의 첫 만남 장면이 이어집니다.", { name = B.esc(c.name) }) or B.U("첫 만남 장면이 이어졌다. 이제 {name:은는} 동료다.", { name = B.esc(c.name) })) .. '</div></div>'
end

  local function recruit_roster(G) B.__expe_cov.calls["72-guild.lua:229"]=true; 
    local PX = B.PX
    local mem, last = {}, B.tw_T(G).meet
    for i = #G.roster, 1, -1 do B.__expe_cov.branches["72-guild.lua:232:12052"]=true; 
      local cid = G.roster[i]
      local c = B.CAST[cid]
      if c then B.__expe_cov.branches["72-guild.lua:235:12124"]=true; 
        mem[#mem + 1] = '<div class="gd-mem' .. (cid == last and " new" or "") .. '">' .. PX.face(cid, c.name, "gd-mf") .. '<span class="t">' .. B.esc(B.T(c.name)) ..
          '<span class="d">' .. B.U("{cls}, Lv {lv}", { cls = B.esc(c.cls), lv = B.lv_of and B.lv_of(G, cid) or 1 }) .. '</span></span></div>'
      end
    end
    local total = #(B.CAST_ORDER or {})
    local left = total - #G.roster
    return '<div class="dk-card"><div class="so-h"><span class="dk-title">' .. B.U("만난 동료") .. '</span><span class="dk-sub">' .. #G.roster .. ' / ' .. total .. '</span></div>' ..
      (#mem > 0 and ('<div class="gd-roster">' .. table.concat(mem) .. '</div>') or '<div class="dk-sub">' .. B.U("아직 만난 동료가 없다.") .. '</div>') ..
      '<div class="dk-row gd-codex"><span class="dk-sub">' .. (left > 0 and B.U("아직 만나지 못한 {n}명은 도감에 흐리게 보인다.", { n = left }) or B.U("길드 장부의 모험가를 모두 만났다.")) .. '</span>' ..
      B.btn("hd_codex", B.U("도감에서 보기"), "sm") .. '</div></div>'
end

  function B.gd_recruit_tab(G, id) B.__expe_cov.calls["72-guild.lua:248"]=true; 
    local cands = B.gd_candidates(G)
    local cost = B.gd_recruit_cost(G)
    local gold = G.gold or 0
    local total = #(B.CAST_ORDER or {})
    local short = cost - gold
    local head = '<div class="dk-card gold"><div class="dk-title">' .. B.U("동료 소개 창구") .. '</div><div class="dk-text">' ..
      B.U("길드가 모험가에게 사람을 이어 준다. 누구를 만날지는 길드도 모른다. 아직 동료가 아닌 사람 가운데 한 명이 나오고, 만나면 곧 동료가 된다. 등급도 확률표도 없다.") .. '</div>' ..
      B.tw_npcs({ { "fenella", "페넬라", "소개 창구" } }) ..
      '<div class="gd-stats">' .. recruit_cell("소개비", B.U("금화 {n}", { n = cost }), B.U("한 명 늘 때마다 +20")) ..
      recruit_cell("가진 금화", tostring(gold), (short > 0 and #cands > 0) and B.U("금화 {n} 모자라다", { n = short }) or nil, (short > 0 and #cands > 0) and "short" or nil) ..
      recruit_cell("동료", #G.roster .. " / " .. total, nil) .. '</div><div class="gd-bar">' .. B.PX.bar("exp", #G.roster, total) .. '</div>' ..
      '<div class="dk-sub gd-scale">' .. B.U("소개비는 100 → 120 → 140 … 만난 사람이 늘수록 20씩 오른다{next}.", { next = #cands > 0 and B.U(" (이번 뒤에는 {cost})", { cost = cost + 20 }) or "" }) .. '</div></div>'
    local body
    if #cands == 0 then B.__expe_cov.branches["72-guild.lua:262:14253"]=true; 
      body = '<div class="dk-card"><div class="dk-text">' .. B.U("더 이을 사람이 없다. 길드 장부에 오른 모험가는 모두 당신의 동료다.") .. '</div></div>'
    else B.__expe_cov.branches["72-guild.lua:264:14388"]=true; 
      local busy = B.pend_busy(G, id)
      local sub, cls = B.U("금화 {n}", { n = cost }), "go gd-meet"
      if busy then B.__expe_cov.branches["72-guild.lua:267:14510"]=true;  sub, cls = B.U("앞의 장면을 먼저 이어 주세요 (보내기)"), "go gd-meet off"
      elseif short > 0 then B.__expe_cov.branches["72-guild.lua:268:14597"]=true;  sub, cls = B.U("금화 {n} 모자란다", { n = short }), "go gd-meet off" end
      body = '<div class="dk-row gd-act">' .. B.btn("gd_meet", B.U("소개받기"), cls, sub) .. '</div>'
    end
    return head .. recruit_result(G, id) .. body .. recruit_roster(G)
end
end

B.SCREENS.guild = function(G, id) B.__expe_cov.calls["72-guild.lua:275"]=true; 
  B.tw_T(G)
  local tab = (G.ui.tab ~= "") and G.ui.tab or "board"
  local function tb(k, label) B.__expe_cov.calls["72-guild.lua:278"]=true;  return B.btn("gd_tab_" .. k, B.U(label), "sm" .. (tab == k and " on" or "")) end
  local body
  if tab == "recruit" then B.__expe_cov.branches["72-guild.lua:280:15101"]=true;  body = B.gd_recruit_tab(G, id)
  elseif tab == "loredana" then B.__expe_cov.branches["72-guild.lua:281:15164"]=true;  body = B.ps_guild_tab(G)
  else B.__expe_cov.branches["72-guild.lua:282:15196"]=true;  body = tab_board(G) end
  return '<div class="dk-card gold">' .. B.tw_hd("pl-guild", B.U("연합 길드 본관")) ..
    '<div class="dk-text">' .. B.U("의뢰판 앞은 늘 시끄럽다. 접수대 너머에서 서기들이 계약서를 넘긴다.") .. '</div>' ..
    B.tw_npcs({ { "fenella", "페넬라", "접수" }, { "loredana", "로레다나", "길드장" } }) .. '</div>' ..
    '<div class="dk-tabs">' .. tb("board", "의뢰판") .. tb("recruit", "동료 소개") .. tb("loredana", "길드장 로레다나") .. '</div>' .. body .. B.tw_hint(B.U("파티는 출정할 때 균열 입장 화면에서 고른다.")) ..
    '<div class="dk-row">' .. (B.ps_dirty(G) and B.btn("gd_back", B.U("토르바로 돌아가기"), "sm off", B.U("먼저 저장하세요")) or B.btn("gd_back", B.U("토르바로 돌아가기"), "sm")) .. '</div>'
end

-- 동료 소개 확정(엔진이 정한다 — AI 는 서술만, 번복 금지)
local function meet(G, id) B.__expe_cov.calls["72-guild.lua:291"]=true; 
  if B.pend_busy(G, id) then B.__expe_cov.branches["72-guild.lua:292:15929"]=true;    -- 앞 장면이 아직 AI 답을 받지 못했으면 막는다(답을 받은 뒤엔 새 행동이 덮어쓴다)
    G.ui.msg = B.U("앞의 장면이 아직 이어지지 않았습니다. 보내기를 눌러 먼저 이어 주세요.")
    return
  end
  local cands = B.gd_candidates(G)
  if #cands == 0 then B.__expe_cov.branches["72-guild.lua:297:16119"]=true;  G.ui.msg = B.U("더 이을 사람이 없다."); return end
  local cost = B.gd_recruit_cost(G)
  if (G.gold or 0) < cost then B.__expe_cov.branches["72-guild.lua:299:16229"]=true;  G.ui.msg = B.U("금화가 모자랍니다. 소개비 {cost}, 가진 금화 {gold}", { cost = cost, gold = G.gold or 0 }); return end
  local k = math.floor(B.gd_rnd(G) * #cands) + 1
  if k > #cands then B.__expe_cov.branches["72-guild.lua:301:16402"]=true;  k = #cands end
  local cid = cands[k]
  local c = B.CAST[cid]
  G.gold = G.gold - cost
  G.roster[#G.roster + 1] = cid
  G.aff[cid] = 0
  if B.join_level then B.__expe_cov.branches["72-guild.lua:307:16561"]=true;  B.join_level(G, cid) end   -- 영입 순간 페르소나 레벨로 시작(74-level)
  G.guild.recruits = (G.guild.recruits or 0) + 1
  B.npc_like(G, "guild")   -- 동료 소개: 소개 창구 페넬라 호감 +1
  if B.chron_add then B.__expe_cov.branches["72-guild.lua:310:16743"]=true;  B.chron_add(G, B.U("{name:이가} 길드 소개로 동료가 되었다", { name = c.name })) end   -- 모험 연대기(89-memory)
  B.tw_T(G).meet = cid
  G.pending_at = nil   -- 새 지시: 처음 실리는 요청에서 채팅 위치를 잡는다(90-triggers)
  G.pend_soft = nil
  G.pending = "[Companion introduction confirmed] At the Union Guild Hall reception desk, the guild introduced an adventurer: " .. B.C1_en(c.full) .. " (" .. B.C1_en(c.name) .. ", " .. B.C1_en(c.race) .. ", " .. B.C1_en(c.nation) .. ", " .. B.C1_en(c.cls) ..
    "). Write their first meeting near the guild reception desk. Follow the lorebook for their personality and speech. This person immediately joins as a companion; do not reverse that. Do not write the user's words or actions."
  local ok, r = pcall(function() B.__expe_cov.calls["72-guild.lua:316"]=true;  return addChat(id, "user", B.U("(길드 접수처에서 동료 소개를 부탁한다)")) end)
  local sent = ok and r ~= false
  G.ui.msg = B.U("{name:이가} 소개됐습니다. {next}", { name = c.name, next = sent and B.U("보내기를 누르면 이어집니다.") or B.U("채팅에 줄을 넣지 못했습니다. 한 줄 적어 보내 주세요.") })
end

B.H.gd = function(G, arg, id) B.__expe_cov.calls["72-guild.lua:321"]=true; 
  B.tw_T(G)
  if G.scene ~= "guild" then B.__expe_cov.branches["72-guild.lua:323:17787"]=true;  return end
  local tab = arg:match("^tab_(%a+)$")
  local acc = arg:match("^acc_(.+)$")
  local rej = arg:match("^rej_(.+)$")
  if arg == "back" then B.__expe_cov.branches["72-guild.lua:327:17937"]=true; 
    if B.ps_dirty(G) then B.__expe_cov.branches["72-guild.lua:328:17963"]=true;  G.ui.msg = B.U("먼저 저장하세요. 로레다나의 스킬 조합에 저장하지 않은 변경이 있습니다."); return end
    G.scene = "town"; G.ui.tab = ""
  elseif tab then B.__expe_cov.branches["72-guild.lua:330:18088"]=true; 
    if tab == "board" or tab == "recruit" or tab == "loredana" then B.__expe_cov.branches["72-guild.lua:331:18156"]=true;  G.ui.tab = tab end
  elseif arg == "ps_save" or arg:match("^ps_[a-z]+_[a-z]+$") then B.__expe_cov.branches["72-guild.lua:332:18241"]=true; 
    B.ps_guild_action(G, arg, id)
  elseif arg == "fill" then B.__expe_cov.branches["72-guild.lua:334:18303"]=true; 
    B.gd_fill(G)
  elseif acc then B.__expe_cov.branches["72-guild.lua:336:18338"]=true; 
    local q = B.gd_find(G, acc)
    if not q then B.__expe_cov.branches["72-guild.lua:338:18388"]=true;  G.ui.msg = B.U("그 의뢰는 이미 판에서 내려갔습니다."); return end
    if G.guild.active ~= "" then B.__expe_cov.branches["72-guild.lua:339:18472"]=true;  G.ui.msg = B.U("이미 받은 의뢰가 있습니다. 끝내거나 포기한 뒤에 새로 받을 수 있습니다."); return end
    G.guild.active = q.id
    B.npc_like(G, "guild")   -- 의뢰 수락: 접수 페넬라 호감 +1
    G.ui.msg = B.U("의뢰 「{title}」를 받았습니다. 토르바 시내에서 출정할 수 있습니다.", { title = B.esc(B.gd_title(q)) })
  elseif rej then B.__expe_cov.branches["72-guild.lua:343:18738"]=true; 
    local q = B.gd_find(G, rej)
    if not q then B.__expe_cov.branches["72-guild.lua:345:18788"]=true;  return end
    if q.id == G.guild.active then B.__expe_cov.branches["72-guild.lua:346:18834"]=true;  G.ui.msg = B.U("받아 둔 의뢰는 거절할 수 없습니다. 포기를 누르세요."); return end
    B.gd_remove(G, q.id)
    B.gd_fill(G)
    G.ui.msg = B.U("의뢰 하나를 거절했다. 판에 새 의뢰가 걸렸다.")
  elseif arg == "drop" then B.__expe_cov.branches["72-guild.lua:350:19014"]=true; 
    local q = B.gd_find(G, G.guild.active)
    if not q then B.__expe_cov.branches["72-guild.lua:352:19075"]=true;  return end
    B.gd_remove(G, q.id)
    G.guild.active = ""
    B.gd_fill(G)
    G.ui.msg = B.U("의뢰 「{title}」를 포기했다.", { title = B.esc(B.gd_title(q)) })
  elseif arg == "refresh" then B.__expe_cov.branches["72-guild.lua:357:19259"]=true; 
    local cost = B.gd_refresh_cost(G)
    if (G.gold or 0) < cost then B.__expe_cov.branches["72-guild.lua:359:19330"]=true;  G.ui.msg = B.U("금화가 모자랍니다. 새로 거는 값 {cost}", { cost = cost }); return end
    G.gold = G.gold - cost
    G.town.rr = (G.town.rr or 0) + 1
    local keep = {}
    for _, q in ipairs(G.guild.quests) do B.__expe_cov.branches["72-guild.lua:363:19531"]=true;  if q.id == G.guild.active then B.__expe_cov.branches["72-guild.lua:363:19560"]=true;  keep[#keep + 1] = q end end
    G.guild.quests = keep
    B.gd_fill(G)
    G.ui.msg = B.U("의뢰판을 새로 걸었다. (금화 {cost})", { cost = cost })
  elseif arg == "meet" then B.__expe_cov.branches["72-guild.lua:367:19723"]=true; 
    meet(G, id)
  end
end
