-- ===== 전투 중 아이템 사용 (사장님 10-10 「전투 중 물약 먹을 수 있으니까」) =====
-- 파티가 가진 소모품(G.items)을 전투 중에 쓴다. 한 번 쓰면 그 차례를 쓴다 [제안]. 일반 전투 화면과 레이드 화면 둘 다에서 같다(r_act 가 공유).
-- 버튼(접두 it, 전투 장면에서만): it_open(아이템 고르기 열기) · it_pick_<아이템> · it_to_<자리 1~4>(대상) · it_cancel
-- 읽는 G 칸: items · dungeon.run.loot.items(탐색 중 모은 주머니 — 먼저 쓴다) / 쓰는 칸: 같은 칸 / 전투 상태: st.bag(개수 사본 — 화면용) · st.imenu · st.ipk
-- 물약 9종(체력 · 마나 · 보호막 × 소 · 중 · 대 — 사장님 10-10, 정본 표 B.POTION 은 71-shop.lua): 마시는 사람(= 대상 아군)의 레벨이 크기의 최소 레벨(소 1 · 중 15 · 대 30 [제안]) 이상이어야 한다.
--   효과 [제안]: 체력 = 최대 HP 20/35/50% · 마나 = 최대 MP 15/25/40% · 보호막 = 최대 HP 15/25/40% 만큼 보호막(3턴 — 파티 보호막과 같은 규칙: 더 큰 보호막이 이미 있으면 그대로).
--   해독약 = 지속 피해 · 여우불 해제 · 붕대 = 쓰러진 아군을 최대 HP 25% 로 일으킨다. 마렌토 시너지 2명 「아이템 효과 +20%」(B.item_mul)는 물약 효과량에 곱한다. 결정론 — 난수 없음.
local nm = B.nm
B.IT = { order = {}, bandage_hp = 0.25 }
for _, id in ipairs(B.POTION_IDS) do B.__expe_cov.branches["78-battle-item.lua:10:860"]=true;  B.IT.order[#B.IT.order + 1] = id end
B.IT.order[#B.IT.order + 1] = "antidote"
B.IT.order[#B.IT.order + 1] = "bandage"
function B.it_need(iid) B.__expe_cov.calls["78-battle-item.lua:13"]=true;  return (B.ITEMS[iid] and B.ITEMS[iid].lv) or 0 end
function B.it_amount(iid, u, mul) B.__expe_cov.calls["78-battle-item.lua:14"]=true;    -- 물약 한 병의 효과량(대상의 최대치 기준)
  local d = B.ITEMS[iid]
  local K = B.POTION.kinds[d.kind]
  local base = (d.kind == "mp") and u.mmp or u.mhp
  return B.floor(base * K.frac[d.size] * (mul or 1) + 0.5)
end

-- ---------- 재고: G.items + 탐색 주머니 ----------
function B.ex_pouch(G) B.__expe_cov.calls["78-battle-item.lua:22"]=true; 
  local D = type(G.dungeon) == "table" and G.dungeon or nil
  local R = D and D.run
  if type(R) == "table" and R.phase ~= "done" and type(R.loot) == "table" and type(R.loot.items) == "table" then B.__expe_cov.branches["78-battle-item.lua:25:1555"]=true;  return R.loot.items end
  return nil
end
function B.ex_have(G, iid) B.__expe_cov.calls["78-battle-item.lua:28"]=true; 
  local n = tonumber(type(G.items) == "table" and G.items[iid]) or 0
  local p = B.ex_pouch(G)
  if p then B.__expe_cov.branches["78-battle-item.lua:31:1730"]=true;  n = n + (tonumber(p[iid]) or 0) end
  return n
end
-- 하나 쓴다(탐색 주머니 먼저). 돌려주는 값 = 썼는가
function B.ex_take(G, iid) B.__expe_cov.calls["78-battle-item.lua:35"]=true; 
  local p = B.ex_pouch(G)
  if p and (tonumber(p[iid]) or 0) > 0 then B.__expe_cov.branches["78-battle-item.lua:37:1912"]=true; 
    p[iid] = p[iid] - 1
    if p[iid] <= 0 then B.__expe_cov.branches["78-battle-item.lua:39:1960"]=true;  p[iid] = nil end
    return true
  end
  if type(G.items) == "table" and (tonumber(G.items[iid]) or 0) > 0 then B.__expe_cov.branches["78-battle-item.lua:42:2072"]=true; 
    G.items[iid] = G.items[iid] - 1
    if G.items[iid] <= 0 then B.__expe_cov.branches["78-battle-item.lua:44:2138"]=true;  G.items[iid] = nil end
    return true
  end
  return false
end
function B.ex_bag(G) B.__expe_cov.calls["78-battle-item.lua:49"]=true; 
  local b = {}
  for _, iid in ipairs(B.IT.order) do B.__expe_cov.branches["78-battle-item.lua:51:2278"]=true;  b[iid] = B.ex_have(G, iid) end
  return b
end

-- ---------- 대상이 맞는가 ----------
local function has_dot(u) B.__expe_cov.calls["78-battle-item.lua:56"]=true; 
  return (u.dot and #u.dot > 0) or (u.edot and #u.edot > 0) or (u.fx or 0) > 0
end
function B.it_state_ok(st, iid, t) B.__expe_cov.calls["78-battle-item.lua:59"]=true;    -- 레벨 말고 상태만 본다
  local u = st.u[t]
  if not u or t < 1 or t > 4 or u.empty == 1 or B.DEF[t].empty then B.__expe_cov.branches["78-battle-item.lua:61:2606"]=true;  return false end
  if iid == "bandage" then B.__expe_cov.branches["78-battle-item.lua:62:2650"]=true;  return u.al == 0 end
  if u.al ~= 1 then B.__expe_cov.branches["78-battle-item.lua:63:2691"]=true;  return false end
  local d = B.ITEMS[iid]
  if d and d.kind == "hp" then B.__expe_cov.branches["78-battle-item.lua:65:2764"]=true;  return u.hp < u.mhp end
  if d and d.kind == "mp" then B.__expe_cov.branches["78-battle-item.lua:66:2819"]=true;  return u.mmp > 0 and u.mp < u.mmp end
  if d and d.kind == "sh" then B.__expe_cov.branches["78-battle-item.lua:67:2888"]=true;  return u.sh < B.it_amount(iid, u, 1) end
  if iid == "antidote" then B.__expe_cov.branches["78-battle-item.lua:68:2957"]=true;  return has_dot(u) and true or false end
  return false
end
function B.it_ok(st, iid, t) B.__expe_cov.calls["78-battle-item.lua:71"]=true; 
  if not B.it_state_ok(st, iid, t) then B.__expe_cov.branches["78-battle-item.lua:72:3085"]=true;  return false end
  return (tonumber(B.DEF[t].lv) or 1) >= B.it_need(iid)
end
function B.it_any(st, iid) B.__expe_cov.calls["78-battle-item.lua:75"]=true; 
  for t = 1, 4 do B.__expe_cov.branches["78-battle-item.lua:76:3209"]=true;  if B.it_ok(st, iid, t) then B.__expe_cov.branches["78-battle-item.lua:76:3235"]=true;  return true end end
  return false
end

-- 상태로는 쓸 수 있는데 레벨 때문에 막힌 대상이 있는가(화면 설명용)
function B.it_blocked(st, iid) B.__expe_cov.calls["78-battle-item.lua:81"]=true; 
  for t = 1, 4 do B.__expe_cov.branches["78-battle-item.lua:82:3368"]=true;  if B.it_state_ok(st, iid, t) and not B.it_ok(st, iid, t) then B.__expe_cov.branches["78-battle-item.lua:82:3428"]=true;  return true end end
  return false
end

-- ---------- 효과(전투 상태만 만진다) ----------
-- 지금 차례(st.cur)가 t 에게 iid 를 쓴다. 호출 전: B.begin_ev(st). 돌려주는 값 = 효과량(회복 · 해제한 줄 수)
local function cur_i(st) B.__expe_cov.calls["78-battle-item.lua:88"]=true;  return st.cur end
function B.it_apply(st, iid, t) B.__expe_cov.calls["78-battle-item.lua:89"]=true; 
  local i = st.cur
  local u, T = st.u[t], st.ev.T
  local def = B.ITEMS[iid]
  local mul = B.item_mul and B.item_mul(st) or 1
  local d, f = 0, "hp"
  local kind = def.kind
  if kind == "hp" then B.__expe_cov.branches["78-battle-item.lua:96:3862"]=true; 
    d = B.heal(st, t, B.it_amount(iid, u, mul), T + 0.8)
  elseif kind == "mp" then B.__expe_cov.branches["78-battle-item.lua:98:3946"]=true; 
    local to = math.min(u.mmp, u.mp + B.it_amount(iid, u, mul))
    d = to - u.mp
    f = "mp"
    if d > 0 then B.__expe_cov.branches["78-battle-item.lua:102:4059"]=true;  B.setf(st, t, "mp", to, T + 0.8) end
  elseif kind == "sh" then B.__expe_cov.branches["78-battle-item.lua:103:4123"]=true; 
    d = B.it_amount(iid, u, mul)
    if B.GH.shield then B.__expe_cov.branches["78-battle-item.lua:105:4180"]=true;  d = B.floor(B.GH.shield(st, cur_i(st), d) or d) end
    B.setf(st, t, "sh", math.max(u.sh, d), T + 0.8)
    u.shT = 3
    f = "sh"
  elseif iid == "antidote" then B.__expe_cov.branches["78-battle-item.lua:109:4343"]=true; 
    d = (u.dot and #u.dot or 0) + (u.edot and #u.edot or 0) + (((u.fx or 0) > 0) and 1 or 0)
    u.dot, u.edot, u.fx = {}, {}, 0
    f = "cure"
  elseif iid == "bandage" then B.__expe_cov.branches["78-battle-item.lua:113:4518"]=true; 
    local h = math.max(1, B.floor(u.mhp * B.IT.bandage_hp))
    u.al, u.g, u.df, u.tau, u.chg, u.mk, u.dr = 1, 10000, 0, 0, 0, 0, 0
    u.dot, u.edot, u.fx, u.bf = {}, {}, 0, {}
    B.setf(st, t, "hp", h, T + 0.8)
    d = h
    f = "up"
  end
  B.push(st, { k = "item", a = i, t = T, nm = def.name, tg = { { i = t, d = d, f = f } } })
  local who, tn = nm(i), nm(t)
  local eff
  if f == "hp" then B.__expe_cov.branches["78-battle-item.lua:124:4916"]=true;  eff = "HP <em>+" .. d .. "</em>"
  elseif f == "sh" then B.__expe_cov.branches["78-battle-item.lua:125:4973"]=true;  eff = B.U("보호막 <em>{n}</em>", { n = d })
  elseif f == "mp" then B.__expe_cov.branches["78-battle-item.lua:126:5038"]=true;  eff = "MP <em>+" .. d .. "</em>"
  elseif f == "cure" then B.__expe_cov.branches["78-battle-item.lua:127:5097"]=true;  eff = B.U("지속 상태 해제")
  else B.__expe_cov.branches["78-battle-item.lua:128:5126"]=true;  eff = B.U("쓰러진 몸을 일으켰다. HP <em>{n}</em>", { n = d }) end
  B.say(st, B.U("<b>{who}</b>{suffix} {item:을를} 썼다. <b>{target}</b> {effect}", { who = who, suffix = B.josa(who, "이가"), item = def.name, target = tn, effect = eff }), T + 0.9)
  st.ev.T = T + 1.4
  return d
end

-- ---------- 화면 ----------
local function itname(iid) B.__expe_cov.calls["78-battle-item.lua:135"]=true;  return B.ITEMS[iid] and B.ITEMS[iid].name or iid end

-- 평소 행동 칸 맨 끝에 붙는 「물약」 버튼(r_act 가 부른다). 재고가 전부 0 이면 꺼진다.
function B.it_button(st) B.__expe_cov.calls["78-battle-item.lua:138"]=true; 
  if type(st.bag) ~= "table" then B.__expe_cov.branches["78-battle-item.lua:139:5621"]=true;  return "" end
  local total, parts = 0, {}
  for _, iid in ipairs(B.IT.order) do B.__expe_cov.branches["78-battle-item.lua:141:5704"]=true; 
    local n = tonumber(st.bag[iid]) or 0
    total = total + n
    if n > 0 then B.__expe_cov.branches["78-battle-item.lua:144:5783"]=true;  parts[#parts + 1] = itname(iid) .. " " .. n end
  end
  local inner = '<i class="bi im im-it-hp"></i><span class="t">' .. B.U("물약") .. '<span class="d">' ..
    (total > 0 and B.U("아이템 {n}개, 쓰면 이번 차례를 씁니다", { n = total }) or B.U("남은 아이템이 없다")) .. '</span></span>'
  if total > 0 then B.__expe_cov.branches["78-battle-item.lua:148:6067"]=true;  return '<button type="button" class="btn" risu-btn="it_open">' .. inner .. '</button>' end
  return '<div class="btn off">' .. inner .. '</div>'
end

-- 아이템 고르기 · 대상 고르기 칸(st.imenu == 1)
function B.r_items(st, late) B.__expe_cov.calls["78-battle-item.lua:153"]=true; 
  local i = st.cur
  local d = B.DEF[i]
  local ic = B.ITEM_IC or {}
  if st.ipk and st.ipk ~= "" then B.__expe_cov.branches["78-battle-item.lua:157:6386"]=true; 
    return '<section class="ap' .. late .. '"><div class="acth"><span class="hd">' .. B.U("{name} / {item}", { name = d.name, item = itname(st.ipk) }) .. '</span><span>' ..
      B.U(st.ipk == "bandage" and '쓰러진 아군을 누르세요' or '대상 아군을 누르세요') .. '</span></div>' ..
      '<div class="btns"><button type="button" class="btn" risu-btn="it_cancel"><i class="bi im im-defend"></i><span class="t">' .. B.U("취소") .. '<span class="d">' .. B.U("다른 행동을 고릅니다") .. '</span></span></button></div></section>'
  end
  local bs = {}
  for _, iid in ipairs(B.IT.order) do B.__expe_cov.branches["78-battle-item.lua:163:6941"]=true; 
    local n = tonumber(st.bag and st.bag[iid]) or 0
    if n > 0 then B.__expe_cov.branches["78-battle-item.lua:165:7009"]=true; 
      local def = B.ITEMS[iid]
      local use = B.it_any(st, iid)
      local desc = B.U("{description} (보유 {n})", { description = B.T(def.d), n = n })
      if not use then B.__expe_cov.branches["78-battle-item.lua:169:7184"]=true; 
        desc = B.it_blocked(st, iid) and B.U("<b>Lv {lv}부터 쓸 수 있습니다</b>. {description}", { lv = B.it_need(iid), description = def.d }) or B.U("<b>쓸 대상이 없습니다</b>. {description}", { description = def.d })
      end
      local inner = '<i class="bi im im-' .. (ic[iid] or "it-hp") .. '"></i><span class="t">' .. B.T(def.name) .. '<span class="d">' .. desc .. '</span></span>'
      if use then B.__expe_cov.branches["78-battle-item.lua:173:7576"]=true;  bs[#bs + 1] = '<button type="button" class="btn" risu-btn="it_pick_' .. iid .. '">' .. inner .. '</button>'
      else B.__expe_cov.branches["78-battle-item.lua:174:7695"]=true;  bs[#bs + 1] = '<div class="btn off">' .. inner .. '</div>' end
    end
  end
  bs[#bs + 1] = '<button type="button" class="btn" risu-btn="it_cancel"><i class="bi im im-defend"></i><span class="t">' .. B.U("취소") .. '<span class="d">' .. B.U("행동 고르기로 돌아간다") .. '</span></span></button>'
  return '<section class="ap' .. late .. '"><div class="acth"><span class="hd">' .. B.U("{name} / 아이템", { name = d.name }) .. '</span><span>' .. B.U("무엇을 쓸까요? 쓰면 이번 차례를 씁니다") .. '</span></div><div class="btns">' .. table.concat(bs) .. '</div></section>'
end

-- ---------- 버튼 ----------
B.H.it = function(G, arg, id) B.__expe_cov.calls["78-battle-item.lua:182"]=true; 
  if G.scene ~= "battle" then B.__expe_cov.branches["78-battle-item.lua:183:8327"]=true;  return end
  local st = B.load(id)
  if st.over ~= "" or type(st.bag) ~= "table" or st.cur < 1 or st.cur > 4 then B.__expe_cov.branches["78-battle-item.lua:185:8441"]=true;  return end
  if arg == "open" then B.__expe_cov.branches["78-battle-item.lua:186:8476"]=true; 
    local any = false
    for _, iid in ipairs(B.IT.order) do B.__expe_cov.branches["78-battle-item.lua:188:8540"]=true;  if B.ex_have(G, iid) > 0 then B.__expe_cov.branches["78-battle-item.lua:188:8568"]=true;  any = true end end
    if not any then B.__expe_cov.branches["78-battle-item.lua:189:8607"]=true;  return end
    st.pend, st.ev, st.imenu, st.ipk = 0, nil, 1, ""
    st.bag = B.ex_bag(G)
  elseif arg == "cancel" then B.__expe_cov.branches["78-battle-item.lua:192:8726"]=true; 
    if st.imenu ~= 1 then B.__expe_cov.branches["78-battle-item.lua:193:8752"]=true;  return end
    st.imenu, st.ipk, st.ev = 0, "", nil
  elseif arg:match("^pick_[a-z_]+$") then B.__expe_cov.branches["78-battle-item.lua:195:8846"]=true; 
    local iid = arg:sub(6)
    if st.imenu ~= 1 or not B.ITEMS[iid] or B.ex_have(G, iid) <= 0 or not B.it_any(st, iid) then B.__expe_cov.branches["78-battle-item.lua:197:8970"]=true;  return end
    local ok = false
    for _, k in ipairs(B.IT.order) do B.__expe_cov.branches["78-battle-item.lua:199:9042"]=true;  if k == iid then B.__expe_cov.branches["78-battle-item.lua:199:9057"]=true;  ok = true end end
    if not ok then B.__expe_cov.branches["78-battle-item.lua:200:9094"]=true;  return end
    st.ipk = iid
  elseif arg:match("^to_[1-4]$") then B.__expe_cov.branches["78-battle-item.lua:202:9160"]=true; 
    local t = tonumber(arg:sub(4))
    local iid = st.ipk
    if st.imenu ~= 1 or not iid or iid == "" or B.ex_have(G, iid) <= 0 or not B.it_ok(st, iid, t) then B.__expe_cov.branches["78-battle-item.lua:205:9321"]=true;  return end
    B.begin_ev(st)
    st.pend, st.imenu, st.ipk = 0, 0, ""
    B.ex_take(G, iid)
    st.n = st.n + 1
    B.rbegin(st)
    local u = st.u[st.cur]
    local cur = st.cur
    B.ACT = u
    B.SKON = nil
    B.it_apply(st, iid, t)
    B.end_turn(st, cur, 10000)
    B.ACT = nil
    B.run(st)
    st.bag = B.ex_bag(G)
  else B.__expe_cov.branches["78-battle-item.lua:220:9652"]=true; 
    return
  end
  B.send_result(id, st)
  B.save(id, st)
end
