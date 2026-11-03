-- ===== 레벨 · 경험치 (사장님 10-08) : 개인 레벨 =====
-- 규칙: 못 만난 동료 = Lv 1 · 영입한 동료 = 영입 순간 페르소나 레벨에서 시작 · 전투 뒤 경험치는 출전자 각자 전부,
--       페르소나가 출전하지 않았으면 50%(내림), 출전하지 않은 동료는 0. 최대 Lv 40.
-- 읽는 G 칸: persona.lv · persona.exp · lvl[cid] · exp[cid] · roster · party · persona.fight / 쓰는 칸: 같은 칸 + lv(옛 칸 거울) · town.xp_bn
-- 곡선 (60×L + 10×L²) × 완화 배율 — Lv1~9 는 40%(금방 찍는다), Lv10~29 는 60% 에서 100% 로 서서히, Lv30 부터 그대로. 조정은 B.exp_need 한 곳만.
B.LV_MAX = 40

local function clamp_lv(v) B.__expe_cov.calls["74-level.lua:8"]=true; 
  local L = math.floor(tonumber(v) or 1)
  if L < 1 then B.__expe_cov.branches["74-level.lua:10:517"]=true;  L = 1 elseif L > B.LV_MAX then B.__expe_cov.branches["74-level.lua:10:548"]=true;  L = B.LV_MAX end
  return L
end

-- 다음 레벨까지 필요한 경험치(레벨 L 에서)
function B.exp_need(L) B.__expe_cov.calls["74-level.lua:15"]=true; 
  L = clamp_lv(L)
  local k = (L < 10) and 0.4 or ((L < 30) and (0.6 + 0.4 * (L - 10) / 20) or 1)
  return math.floor((60 * L + 10 * L * L) * k + 0.5)
end

-- 곡선이 줄어 옛 저장의 경험치가 지금 레벨 필요치를 넘으면 그만큼 레벨을 올린다(불러올 때)
function B.exp_settle(G) B.__expe_cov.calls["74-level.lua:22"]=true; 
  if type(G) ~= "table" or type(G.persona) ~= "table" then B.__expe_cov.branches["74-level.lua:23:927"]=true;  return end
  local list = { "persona" }
  for _, cid in ipairs(G.roster or {}) do B.__expe_cov.branches["74-level.lua:25:1011"]=true;  list[#list + 1] = cid end
  for _, cid in ipairs(list) do B.__expe_cov.branches["74-level.lua:26:1069"]=true; 
    local L = B.lv_of(G, cid)
    if L < B.LV_MAX and B.exp_of(G, cid) >= B.exp_need(L) then B.__expe_cov.branches["74-level.lua:28:1160"]=true;  B.exp_give(G, cid, 0) end
  end
end

-- cid == "persona" → 페르소나 · 영입 동료 → G.lvl[cid](없으면 영입 값이 빠진 옛 저장 → 페르소나 레벨) · 못 만난 동료 → 1
function B.lv_of(G, cid) B.__expe_cov.calls["74-level.lua:33"]=true; 
  local P = G.persona
  local pl = clamp_lv(type(P) == "table" and P.lv or G.lv)
  if cid == "persona" then B.__expe_cov.branches["74-level.lua:36:1421"]=true;  return pl end
  if not B.has(G.roster, cid) then B.__expe_cov.branches["74-level.lua:37:1470"]=true;  return 1 end
  local v = type(G.lvl) == "table" and tonumber(G.lvl[cid])
  if v then B.__expe_cov.branches["74-level.lua:39:1555"]=true;  return clamp_lv(v) end
  return pl
end

-- 현재 경험치(다음 레벨까지의 진행분)
function B.exp_of(G, cid) B.__expe_cov.calls["74-level.lua:44"]=true; 
  if cid == "persona" then B.__expe_cov.branches["74-level.lua:45:1672"]=true;  return math.max(0, math.floor(tonumber(G.persona and G.persona.exp) or 0)) end
  return math.max(0, math.floor(tonumber(type(G.exp) == "table" and G.exp[cid]) or 0))
end

-- 영입하는 모든 곳에서 부른다(첫 만남 확정 · 길드 동료 소개): 그 순간 페르소나 레벨로 시작
function B.join_level(G, cid) B.__expe_cov.calls["74-level.lua:50"]=true; 
  if type(G.lvl) ~= "table" then B.__expe_cov.branches["74-level.lua:51:1963"]=true;  G.lvl = {} end
  if type(G.exp) ~= "table" then B.__expe_cov.branches["74-level.lua:52:2011"]=true;  G.exp = {} end
  G.lvl[cid] = B.lv_of(G, "persona")
  G.exp[cid] = 0
end

local function who(G, cid) B.__expe_cov.calls["74-level.lua:57"]=true; 
  if cid == "persona" then B.__expe_cov.branches["74-level.lua:58:2139"]=true; 
    local n = G.persona and G.persona.name or ""
    return (n ~= "" and n) or "당신"
  end
  local c = B.CAST and B.CAST[cid]
  return c and c.name or tostring(cid)
end

-- 한 사람에게 경험치를 더한다. 레벨업 여러 번 가능 · 40 에서 멈춤. 돌려주는 값: 오른 뒤 레벨, 이전 레벨
local function give(G, cid, amount) B.__expe_cov.calls["74-level.lua:67"]=true; 
  local L0 = B.lv_of(G, cid)
  local L, x = L0, B.exp_of(G, cid) + amount
  while L < B.LV_MAX and x >= B.exp_need(L) do B.__expe_cov.branches["74-level.lua:70:2534"]=true; 
    x = x - B.exp_need(L)
    L = L + 1
  end
  if L >= B.LV_MAX then B.__expe_cov.branches["74-level.lua:74:2602"]=true;  x = 0 end
  if cid == "persona" then B.__expe_cov.branches["74-level.lua:75:2639"]=true; 
    G.persona.lv, G.persona.exp = L, x
    G.lv = L                                  -- 옛 칸도 맞춘다
  else B.__expe_cov.branches["74-level.lua:78:2743"]=true; 
    if type(G.lvl) ~= "table" then B.__expe_cov.branches["74-level.lua:79:2778"]=true;  G.lvl = {} end
    if type(G.exp) ~= "table" then B.__expe_cov.branches["74-level.lua:80:2828"]=true;  G.exp = {} end
    G.lvl[cid], G.exp[cid] = L, x
  end
  return L, L0
end
B.exp_give = function(G, cid, amount) B.__expe_cov.calls["74-level.lua:85"]=true;  return give(G, cid, amount) end

-- 전투 상태 st 에서 st.exp(승리 때 엔진이 채우는 총 경험치)와 st.pm(출전 인원 {id=...}) 을 읽어 나눠 준다.
-- 돌려주는 값: 레벨업 문구 목록(예: "레비아 Lv 3 → 4"), 받은 경험치 표(cid → 정수)
function B.award_exp(G, st) B.__expe_cov.calls["74-level.lua:89"]=true; 
  local lines, gains = {}, {}
  if type(st) ~= "table" then B.__expe_cov.branches["74-level.lua:91:3198"]=true;  return lines, gains end
  local total = math.floor(tonumber(st.exp) or 0)
  if total <= 0 then B.__expe_cov.branches["74-level.lua:93:3293"]=true;  return lines, gains end       -- 옛 전투(exp 없음) · 0 이면 아무것도 안 한다
  if type(G.persona) ~= "table" then B.__expe_cov.branches["74-level.lua:94:3393"]=true;  return lines, gains end
  local T = B.tw_T and B.tw_T(G) or (type(G.town) == "table" and G.town or {})
  -- 입장 번호(다시 싸우기로 바뀌지 않는다 · 검수 4차 #15). sid 가 없는 옛 저장은 지금 거점 입장 번호로 본다 —
  -- 옛 다시 싸우기 전투의 bn 은 입장 번호보다 1 커서 다음 의뢰 번호와 겹쳤다(검수 5차 #7)
  local key = st.sid or (type(T.bn) == "number" and T.bn) or st.bn
  if type(key) == "number" and T.xp_bn == key then B.__expe_cov.branches["74-level.lua:99:3748"]=true;  return lines, gains end   -- 같은 전투로 두 번 주지 않는다
  -- 출전자 목록: st.pm 이 없으면 편성(G.party · persona.fight)으로
  local out, seen = {}, {}
  local function add(cid) B.__expe_cov.calls["74-level.lua:102"]=true; 
    if cid and cid ~= "" and not seen[cid] then B.__expe_cov.branches["74-level.lua:103:3951"]=true;  seen[cid] = true; out[#out + 1] = cid end   -- id "" = 빈 자리
  end
  if type(st.pm) == "table" and #st.pm > 0 then B.__expe_cov.branches["74-level.lua:105:4065"]=true; 
    for _, m in ipairs(st.pm) do B.__expe_cov.branches["74-level.lua:106:4100"]=true;  add(type(m) == "table" and m.id or m) end
  else B.__expe_cov.branches["74-level.lua:107:4147"]=true; 
    if G.persona.fight == 1 then B.__expe_cov.branches["74-level.lua:108:4180"]=true;  add("persona") end
    for _, cid in ipairs(G.party or {}) do B.__expe_cov.branches["74-level.lua:109:4244"]=true;  add(cid) end
  end
  if not seen["persona"] then B.__expe_cov.branches["74-level.lua:111:4291"]=true;  gains["persona"] = math.floor(total / 2) end   -- 미출전 페르소나 50%(내림)
  for _, cid in ipairs(out) do B.__expe_cov.branches["74-level.lua:112:4391"]=true; 
    if cid == "persona" or B.has(G.roster, cid) then B.__expe_cov.branches["74-level.lua:113:4442"]=true;  gains[cid] = total end
  end
  -- 페르소나 → 출전 동료 순서로 처리
  local order = { "persona" }
  for _, cid in ipairs(out) do B.__expe_cov.branches["74-level.lua:117:4559"]=true;  if cid ~= "persona" then B.__expe_cov.branches["74-level.lua:117:4582"]=true;  order[#order + 1] = cid end end
  for _, cid in ipairs(order) do B.__expe_cov.branches["74-level.lua:118:4649"]=true; 
    local g = gains[cid]
    if g then B.__expe_cov.branches["74-level.lua:120:4686"]=true; 
      local L, L0 = give(G, cid, g)
      if L > L0 then B.__expe_cov.branches["74-level.lua:122:4743"]=true;  lines[#lines + 1] = B.U("{name} Lv {before} → {after}", { name = who(G, cid), before = L0, after = L }) end
    end
  end
  if type(key) == "number" then B.__expe_cov.branches["74-level.lua:125:4897"]=true;  T.xp_bn = key end
  if #lines > 0 and B.chron_add then B.__expe_cov.branches["74-level.lua:126:4952"]=true;  B.chron_add(G, B.U("레벨이 올랐다: {lines}", { lines = table.concat(lines, ", ") })) end   -- 모험 연대기: 묶어서 한 줄(89-memory)
  return lines, gains
end
