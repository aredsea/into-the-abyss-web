-- ===== 거점(토르바) : 장소 이동 · 출정 · 전투 뒤 정산 =====
-- 🔴 계약: 01-game.lua 를 고치지 않는다. 화면은 B.SCREENS.town, 버튼은 B.H.tw(접두 tw), AI 문맥은 B.CTX["20-town"].
-- 거점 쪽에서 새로 쓰는 칸: G.town = { bn(전투 번호) · day(날짜) · acts(오늘 한 일) · rr(의뢰 갱신 횟수) · meet(방금 만난 동료) }
--   G.guild.qn(의뢰 번호표). 둘 다 없는 옛 저장은 B.tw_T 가 처음 쓸 때 채운다.

B.TW_PLACES = {
  { scene = "guild", ic = "pl-guild", name = "연합 길드 본관", d = "의뢰판과 동료 소개 창구" },
  { scene = "shop", ic = "pl-shop", name = "마렌토 상회", d = "물약(체력, 마나, 보호막), 해독약, 귀환 두루마리" },
  { scene = "inn", ic = "pl-inn", name = "아랫마을 여관", d = "동료와 이야기하고 식사하고 쉰다" },
  { scene = "smithy", ic = "pl-smithy", name = "한나의 대장간", d = "장비를 제련하고 가공한다" },
}

function B.tw_T(G) B.__expe_cov.calls["70-town.lua:13"]=true; 
  if type(G.town) ~= "table" then B.__expe_cov.branches["70-town.lua:14:700"]=true;  G.town = {} end
  local t = G.town
  t.bn = t.bn or 0
  t.day = t.day or 1
  t.rr = t.rr or 0
  if type(t.acts) ~= "table" then B.__expe_cov.branches["70-town.lua:19:828"]=true;  t.acts = {} end
  if type(G.guild) ~= "table" then B.__expe_cov.branches["70-town.lua:20:879"]=true;  G.guild = { quests = {}, active = "", done = 0, recruits = 0, tickets = 0 } end
  if type(G.guild.quests) ~= "table" then B.__expe_cov.branches["70-town.lua:21:1001"]=true;  G.guild.quests = {} end
  return t
end

function B.tw_name(cid) B.__expe_cov.calls["70-town.lua:25"]=true; 
  local c = B.CAST and B.CAST[cid]
  return c and c.name or tostring(cid)
end

-- 지금 출전 이름들(페르소나 출전이면 맨 앞)
function B.tw_party(G) B.__expe_cov.calls["70-town.lua:31"]=true; 
  local names = {}
  if G.persona and G.persona.fight == 1 then B.__expe_cov.branches["70-town.lua:33:1259"]=true;  names[#names + 1] = (G.persona.name ~= "" and G.persona.name or "당신") end
  for _, cid in ipairs(G.party or {}) do B.__expe_cov.branches["70-town.lua:34:1376"]=true;  names[#names + 1] = B.tw_name(cid) end
  return names
end

function B.tw_tags(list) B.__expe_cov.calls["70-town.lua:38"]=true; 
  local t = {}
  for _, n in ipairs(list) do B.__expe_cov.branches["70-town.lua:40:1505"]=true;  t[#t + 1] = '<span class="dk-tag">' .. B.esc(B.T(n)) .. '</span>' end
  return table.concat(t)
end

-- 동료 얼굴 칸. 초상 담당(85-portrait)이 B.portrait 를 만들면 그 그림을, 아니면 이름 첫 글자를 쓴다.
function B.tw_face(cid, cls) B.__expe_cov.calls["70-town.lua:45"]=true; 
  local inner
  if type(B.portrait) == "function" then B.__expe_cov.branches["70-town.lua:47:1760"]=true; 
    local ok, h = pcall(B.portrait, cid, "default")
    if ok and type(h) == "string" and h:sub(1, 1) == "<" then B.__expe_cov.branches["70-town.lua:49:1874"]=true;  inner = h end
  end
  if not inner then B.__expe_cov.branches["70-town.lua:51:1914"]=true;  inner = '<b class="tw-ph">' .. B.esc(utf8.char(utf8.codepoint(B.T(B.tw_name(cid)), 1))) .. '</b>' end
  return '<span class="dk-face tw-face ' .. (cls or "") .. '">' .. inner .. '</span>'
end

-- 장소 카드 머리(아이콘 + 제목)
function B.tw_hd(ic, title) B.__expe_cov.calls["70-town.lua:56"]=true;  return '<div class="tw-hd"><i class="im im-' .. ic .. ' tw-hico"></i><div class="dk-title">' .. title .. '</div></div>' end

-- 아이콘 + 글자 카드 버튼(장소·출정)
function B.tw_pbtn(val, ic, label, sub, cls) B.__expe_cov.calls["70-town.lua:59"]=true; 
  return '<button type="button" class="dk-btn tw-place ' .. (cls or "") .. '" risu-btn="' .. val .. '"><i class="im im-' .. ic .. ' tw-ic"></i>' ..
    '<span class="t">' .. label .. '<span class="d">' .. sub .. '</span></span></button>'
end

function B.tw_stars(n) B.__expe_cov.calls["70-town.lua:64"]=true;  return string.rep("★", n or 1) end

-- 카드 첫머리용 안내 한 줄(빈 칸 대신)
function B.tw_hint(txt) B.__expe_cov.calls["70-town.lua:67"]=true;  return '<div class="dk-sub tw-hint">' .. txt .. '</div>' end

B.SCREENS.town = function(G, id) B.__expe_cov.calls["70-town.lua:69"]=true; 
  local T = B.tw_T(G)
  local q = B.gd_find and B.gd_find(G, G.guild.active)
  local party = B.tw_party(G)
  local row = '<div class="dk-row tw-sum"><span class="dk-tag">' .. B.U("{n}일째", { n = T.day }) .. '</span>' ..
    (#party > 0 and B.tw_tags(party) or '<span class="dk-sub">' .. B.U("출전자 없음. 출정할 때 균열 입장 화면에서 파티를 고른다") .. '</span>') .. '</div>'
  local places = {}
  for _, p in ipairs(B.TW_PLACES) do B.__expe_cov.branches["70-town.lua:76:3210"]=true;  places[#places + 1] = B.tw_pbtn("tw_" .. p.scene, p.ic, B.U(p.name), B.U(p.d)) end
    if q then B.__expe_cov.branches["70-town.lua:77:3305"]=true; 
  places[#places + 1] = B.tw_pbtn("tw_sortie", "pl-rift", B.U("출정"), B.U("{title} {stars}, 보상 금화 {gold}", { title = B.esc(B.gd_title(q)), stars = B.tw_stars(q.stars), gold = B.gd_gold(G, q) }) .. " · " .. B.U("난이도 {difficulty}", { difficulty = B.U(B.gd_difficulty(q)) }), "go")
  else B.__expe_cov.branches["70-town.lua:79:3590"]=true; 
    places[#places + 1] = '<div class="dk-btn tw-place off"><i class="im im-pl-rift tw-ic"></i><span class="t">' .. B.U("출정") .. '<span class="d">' .. B.U("길드 의뢰판에서 의뢰를 받으면 나설 수 있다") .. '</span></span></div>'
  end
  if B.dn_G then B.__expe_cov.branches["70-town.lua:82:3822"]=true;    -- 대던전: 층에는 끝이 없다(76-dungeon)
    local D = B.dn_G(G)
    places[#places + 1] = B.tw_pbtn("tw_dungeon", "pl-rift", B.U("대던전 도전"), B.U("{best}층까지 도달", { best = D.best }), "go")
  end
  places[#places + 1] = B.tw_pbtn("tw_rose", "pl-inn", B.U("장미 골목"), B.U("아랫마을의 유흥가, 창관"))
  -- 글로 거점 안 다른 곳(대장간 · 장미 골목 …)으로 옮겼으면 제목과 설명이 그곳을 따른다(88-lore.lua)
  local pid = B.place_id and B.place_id(G)
  local at = (pid and pid ~= "town" and B.PLACE[pid]) or nil
  return '<div class="dk-card gold tw-hero"><div class="dk-title">' .. (at and B.U("토르바 {place}", { place = at.name }) or B.U("토르바")) .. '</div>' ..
    '<div class="dk-text">' .. (at and B.T(at.d) or B.U("케른 용병단과 마렌토 상인들이 함께 다스리는 도시. 여기서는 어디서 왔는지 캐묻는 사람이 없고, 다들 계약서부터 내민다. 성문 밖으로 옛 학술원 폐허가 보인다.")) .. '</div>' .. row .. '</div>' ..
    ((pid == "rose" and B.sx_rose_card) and B.sx_rose_card(G, id) or "") ..
    '<div class="tw-places">' .. table.concat(places) .. '</div>'
end

B.H.tw = function(G, arg, id) B.__expe_cov.calls["70-town.lua:96"]=true; 
  local T = B.tw_T(G)
  G.ui.sel, G.ui.tab = "", ""
  if arg == "smithy" then B.__expe_cov.branches["70-town.lua:99:4858"]=true; 
    if G.scene ~= "town" then B.__expe_cov.branches["70-town.lua:100:4888"]=true;  return end
    B.place_set(G, "smithy")   -- 대장간은 따로 들어가는 장면(82-smithy)
  elseif arg == "guild" or arg == "shop" or arg == "inn" then B.__expe_cov.branches["70-town.lua:102:5022"]=true; 
    if G.scene ~= "town" then B.__expe_cov.branches["70-town.lua:103:5052"]=true;  return end
    G.scene = arg
    if arg == "shop" then B.__expe_cov.branches["70-town.lua:105:5107"]=true;  G.shop_got = nil end   -- 이번 방문에 산 것(71-shop — 나설 때 대화로 잇는다)
    if arg == "guild" and B.gd_fill then B.__expe_cov.branches["70-town.lua:106:5209"]=true;  B.gd_fill(G) end
  elseif arg == "town" then B.__expe_cov.branches["70-town.lua:107:5254"]=true; 
    G.scene = "town"
  elseif arg == "rose" then B.__expe_cov.branches["70-town.lua:109:5303"]=true;    -- 장미 골목(88-lore B.PLACE.rose) — 창관은 79-sex.lua
    if G.scene ~= "town" then B.__expe_cov.branches["70-town.lua:110:5383"]=true;  return end
    B.place_set(G, "rose")
  elseif arg == "sortie" then B.__expe_cov.branches["70-town.lua:112:5451"]=true; 
    if G.scene ~= "town" then B.__expe_cov.branches["70-town.lua:113:5481"]=true;  return end              -- 같은 버튼 두 번: 이미 전투 장면이면 무시
    local q = B.gd_find(G, G.guild.active)
    if not q then B.__expe_cov.branches["70-town.lua:115:5594"]=true;  G.ui.msg = B.U("받아 둔 의뢰가 없습니다. 길드 본관의 의뢰판을 먼저 보세요."); return end
    G.scene = "sortie"                                 -- 균열 입장 화면(75-sortie): 파티를 고르고 거기서 전투를 시작한다
    if B.dn_G then B.__expe_cov.branches["70-town.lua:117:5778"]=true;  B.dn_G(G).mode = 0 end              -- 「출정」은 늘 의뢰 모드로 연다(대던전은 「대던전 도전」 버튼)
    G.ui.panel = ""
  elseif arg == "dungeon" then B.__expe_cov.branches["70-town.lua:119:5904"]=true; 
    if G.scene ~= "town" then B.__expe_cov.branches["70-town.lua:120:5934"]=true;  return end
    B.dn_G(G).mode = 1
    G.scene = "sortie"
    G.ui.panel = ""
  elseif arg == "return" then B.__expe_cov.branches["70-town.lua:124:6041"]=true; 
    B.tw_settle(G, id)
  end
end

-- 전투가 끝난 뒤 거점으로: 보상·손실 정산, 의뢰 완료, 날짜 +1
function B.tw_settle(G, id) B.__expe_cov.calls["70-town.lua:130"]=true; 
  local T = B.tw_T(G)
  if G.scene ~= "battle" then B.__expe_cov.branches["70-town.lua:132:6196"]=true;  return end
  local st = B.load(id)
  if st.over == "" then B.__expe_cov.branches["70-town.lua:134:6255"]=true;  G.ui.msg = B.U("전투가 아직 끝나지 않았습니다."); return end
  if st.dn and B.dn_settle then B.__expe_cov.branches["70-town.lua:135:6335"]=true;  return B.dn_settle(G, id, st) end   -- 대던전 층은 의뢰와 따로 정산한다(76-dungeon)
  local q = B.gd_find(G, G.guild.active)
    local title = q and B.gd_title(q) or "의뢰"
    local title_en = q and B.gd_title_en(q) or "quest"
  local note
  if st.over == "win" then B.__expe_cov.branches["70-town.lua:140:6587"]=true; 
    local gold = tonumber(st.rg) or (q and B.gd_gold(G, q)) or 0   -- 전투가 정한 보상(마렌토 보너스 등 st.rg) — 결과 줄과 같은 값
    G.gold = G.gold + gold
    G.guild.done = (G.guild.done or 0) + 1
    if q and B.gd_difficulty(q) == "엘리트" then B.__expe_cov.branches["70-town.lua:144:6813"]=true; 
      local count = B.GUILD.elite.gear_min + math.floor(B.ex_mix((tonumber(G.seed) or 0) + (tonumber((q.id or ""):match("%d+")) or 0), 1, 9, 0) * (B.GUILD.elite.gear_max - B.GUILD.elite.gear_min + 1))
      local got = 0
      for j = 1, count do B.__expe_cov.branches["70-town.lua:147:7062"]=true; 
        local code = B.gd_gear(G, q, st.pm, j)
        if code and B.bag_add(id, code) then B.__expe_cov.branches["70-town.lua:149:7152"]=true;  got = got + 1 end
      end
      G.elite_got = got
    end
    G.ui.msg = B.U("의뢰 「{title}」 완료. 금화 {gold:을를} 받았다.", { title = B.esc(title), gold = gold })
    if G.elite_got then B.__expe_cov.branches["70-town.lua:154:7332"]=true;  G.ui.msg = G.ui.msg .. " " .. B.U("장비 {n}개를 받았습니다.", { n = G.elite_got }); G.elite_got = nil end
    note = "Completed the quest '" .. title_en .. "' and received " .. gold .. " gold as a reward."
    if B.chron_add then B.__expe_cov.branches["70-town.lua:156:7553"]=true;  B.chron_add(G, "의뢰 「" .. title .. "」를 완료했다") end   -- 모험 연대기(89-memory)
    -- 경험치(74-level): 출전자 전부 · 미출전 페르소나 50%. 정산은 이 한 번(위 scene 검사 + award_exp 의 전투 번호 표식)
    if B.award_exp then B.__expe_cov.branches["70-town.lua:158:7739"]=true; 
      local okx, lines = pcall(B.award_exp, G, st)
      if okx and type(lines) == "table" then B.__expe_cov.branches["70-town.lua:160:7835"]=true; 
        local xp = math.floor(tonumber(st.exp) or 0)
        if xp > 0 then B.__expe_cov.branches["70-town.lua:162:7911"]=true; 
          G.ui.msg = G.ui.msg .. B.U(" 경험치 {xp}.", { xp = xp })
          note = note .. " Gained " .. xp .. " experience."
        end
        if #lines > 0 then B.__expe_cov.branches["70-town.lua:166:8074"]=true; 
          G.ui.msg = G.ui.msg .. " " .. B.esc(table.concat(lines, ", "))
          note = note .. " Leveled up: " .. table.concat(lines, ", ") .. "."
        end
      end
    end
    -- 함께 싸운 호감(74-affection): 의뢰 전투를 이기면 출전한 동료 각자 +QUEST. 정산은 이 한 번(위 scene 검사)
    if B.aff_party and B.AFF then B.__expe_cov.branches["70-town.lua:173:8370"]=true; 
      local oka, got = pcall(B.aff_party, G, st.pm, B.AFF.QUEST)
      if oka and type(got) == "table" and next(got) then B.__expe_cov.branches["70-town.lua:175:8492"]=true;  G.ui.msg = G.ui.msg .. B.U(" 함께 싸운 동료와 가까워졌다.") end
    end
  else B.__expe_cov.branches["70-town.lua:177:8559"]=true; 
    local carry = math.min(G.gold, 100 * (q and q.stars or 1))
    local loss = math.floor(carry / 2)
    G.gold = G.gold - loss
    G.ui.msg = B.U("의뢰 「{title}」 실패. 들고 간 금화 {carry}의 절반인 {loss:을를} 잃었다.", { title = B.esc(title), carry = carry, loss = loss })
    note = "Failed the quest '" .. title_en .. "' and retreated, losing " .. loss .. " carried gold."
    if B.chron_add then B.__expe_cov.branches["70-town.lua:183:8943"]=true;  B.chron_add(G, "의뢰 「" .. title .. "」에 실패했다") end   -- 모험 연대기(89-memory)
  end
  if q then B.__expe_cov.branches["70-town.lua:185:9033"]=true;  B.gd_remove(G, q.id) end
  G.guild.active = ""
  T.rr = 0
  T.day = T.day + 1
  B.gd_fill(G)
  if B.npc_like then B.__expe_cov.branches["70-town.lua:190:9147"]=true;  B.npc_like(G, "guild") end   -- 의뢰 정산은 길드 접수 담당 호감 +1(79-sex)
  G.scene = "town"
  G.pending_at = nil   -- 새 지시: 처음 실리는 요청에서 채팅 위치를 잡는다(90-triggers)
  B.pend_hard(G, "[Quest settlement confirmed] " .. note, id, B.U("(의뢰를 마치고 토르바로 돌아간다)"))   -- 앞 장면 지시에 덧붙이지 않는다(출정할 때 이미 비웠다 · 검수 5차 #4)
end

-- 전투 끝 → 돌아가기 버튼(HUD)
B.HUD_EXTRA[#B.HUD_EXTRA + 1] = function(G, id) B.__expe_cov.calls["70-town.lua:197"]=true; 
  if G.scene ~= "battle" or not id then B.__expe_cov.branches["70-town.lua:198:9550"]=true;  return "" end
  if not (type(G.town) == "table" and (G.town.bn or 0) > 0) then B.__expe_cov.branches["70-town.lua:199:9629"]=true;  return "" end   -- 출정으로 시작한 전투일 때만(전투 시험 하네스는 거점 없이 전투 장면만 쓴다)
  local ok, st = pcall(B.load, id)
  if not ok or type(st) ~= "table" or st.over == "" then B.__expe_cov.branches["70-town.lua:201:9784"]=true;  return "" end
  if st.dn and st.over == "win" and (st.dn.kind == "explore" or st.dn.stage == 1) then B.__expe_cov.branches["70-town.lua:202:9885"]=true;  return "" end   -- 탐색 전투 뒤에는 정산하지 않는다 — 전투 화면의 「탐색 계속」(ex_cont)으로 던전에 돌아간다(77-explore)
  local q = B.gd_find(G, G.guild.active)
  local sub = (st.over == "win") and B.U("의뢰 보상 금화 {gold}", { gold = tonumber(st.rg) or (q and B.gd_gold(G, q)) or 0 }) or B.U("의뢰 실패 정산")
  if st.dn then B.__expe_cov.branches["70-town.lua:205:10168"]=true;  sub = (st.over == "win") and B.U("대던전 {floor}층 정산, 층 보스 처치", { floor = st.dn.floor }) or B.U("대던전 도전 실패 정산") end
  local label = (st.dn and st.over == "win") and B.U("층 정산") or B.U("토르바로 돌아가기")
  if st.dn and st.over == "win" then B.__expe_cov.branches["70-town.lua:207:10399"]=true;  sub = B.U("보상을 받고, 더 내려갈지 돌아갈지 고른다") end
  return '<span class="tw-ret">' .. B.btn("tw_return", label, "sm go", sub) .. '</span>'
end

B.CTX["20-town"] = function(G) B.__expe_cov.calls["70-town.lua:211"]=true; 
  local where = ({ town = "Torva town", shop = "Marento Trading House (shop)", guild = "Union Guild Hall", inn = "Lower Town Inn", smithy = "Hanna's Smithy (refining and gear processing)", battle = "in battle" })[G.scene]
  if not where then B.__expe_cov.branches["70-town.lua:213:10807"]=true;  return "" end
  local pid = B.place_id and B.place_id(G)
  if G.scene == "town" and pid and pid ~= "town" then B.__expe_cov.branches["70-town.lua:215:10918"]=true;  where = "Torva " .. B.C1_en(B.PLACE[pid].name) end
  local q = B.gd_find and B.gd_find(G, G.guild and G.guild.active or "")
  local party = B.tw_party(G)
  for i, name in ipairs(party) do B.__expe_cov.branches["70-town.lua:218:11108"]=true;  party[i] = B.C1_en(name) end
  return "Base: " .. where .. ", quest: " .. (q and (B.gd_title_en(q) .. " ★" .. q.stars) or "none") ..
    ", sortie party: " .. (#party > 0 and table.concat(party, ", ") or "none") .. ", gold " .. (G.gold or 0)
end
