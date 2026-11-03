B.__r23_gear_cov=B.__r23_gear_cov or {calls={},branches={}}
-- ===== 아랫마을 여관 : 동료와 상호작용 =====
-- 행동마다 호감이 조금 오르고(성향 룰북은 단순화 — 고정치), 하루에 한 번씩만 한다. AI 는 그 장면을 쓴다(G.pending + addChat 유저 줄).
-- 🔴 호감은 던전과 같다(사장님 10-10 「호감도 증감은 여관이나 던전이나 같게」): 행동 하나 = 탐색 전투 한 번 이긴 것(B.AFF.BATTLE, +1).
--    값만 다르다: 대화(무료) · 식사(금화 25) · 작은 선물(금화 30) · 곁에서 쉬기(방값 20, 하루가 지난다). 100 을 넘는 몫은 ×0.4.
-- 옛 「둘만의 밤」(성인 행동)은 없앴다 — 여관에서도 휴식 칸과 같은 「섹스 제안」(79-sex.lua B.sx_inn_card)으로 청한다. 받아 주면 호감 +3(옛 값을 옮겼다).
B.INN_ACTS = {
  talk = { name = "대화하기", cost = 0, aff = 1, d = "곁에 앉아 이야기를 나눈다" },
  meal = { name = "함께 식사", cost = 25, aff = 1, d = "같은 식탁에서 한 끼를 먹는다" },
  gift = { name = "작은 선물", cost = 30, aff = 1, d = "장터에서 산 작은 선물을 건넨다" },
  rest = { name = "곁에서 쉬기", cost = 20, aff = 1, d = "방을 잡고 하룻밤 쉰다(하루가 지난다)", day = 1 },
}
B.INN_ORDER = { "talk", "meal", "gift", "rest" }

local function nsfw_on(G) B.__r23_gear_cov.calls["73-inn.lua:14"]=true;  return (G.settings and G.settings.nsfw) ~= 0 end

-- 이 행동이 지금 보이는가
local function act_visible(G, act, cid) B.__r23_gear_cov.calls["73-inn.lua:17"]=true; 
  return true
end

-- 유저 줄 · AI 에게 넘길 지시
local function act_texts(G, act, cid) B.__r23_gear_cov.calls["73-inn.lua:22"]=true; 
  local n = B.tw_name(cid)
  local tier = B.gd_tier(G.aff[cid] or 0)
  local line, what
  if act == "talk" then B.__r23_gear_cov.branches["73-inn.lua:26:1108"]=true; 
    line = B.U("(여관에서 {name}에게 말을 건다)", { name = n })
    what = "The user speaks to " .. B.C1_en(n) .. " at the Lower Town Inn. Write a short conversation."
  elseif act == "meal" then B.__r23_gear_cov.branches["73-inn.lua:29:1294"]=true; 
    line = B.U("(여관에서 {name:와과} 함께 식사를 한다)", { name = n })
    what = "The user shares a table and a meal with " .. B.C1_en(n) .. " in the inn's dining room. Write their conversation over the meal."
  elseif act == "gift" then B.__r23_gear_cov.branches["73-inn.lua:32:1521"]=true; 
    line = B.U("(여관에서 {name}에게 작은 선물을 건넨다)", { name = n })
    what = "The user gives " .. B.C1_en(n) .. " a small gift bought at the market for 30 gold. Describe the gift being received and the reaction."
  else B.__r23_gear_cov.branches["73-inn.lua:35:1734"]=true; 
    line = B.U("(여관에서 {name} 곁에서 쉰다)", { name = n })
    what = "The user rents a room and rests beside " .. B.C1_en(n) .. " overnight. Write a quiet scene from evening to morning."
  end
  local tail = " Affection stage: " .. B.C1_en(tier) .. ". Keep their conversational distance appropriate to that stage. Follow the lorebook for " .. B.C1_en(n) .. "'s personality and speech. Do not write the user's words or actions."
  if not nsfw_on(G) then B.__r23_gear_cov.branches["73-inn.lua:40:2182"]=true;  tail = tail .. " No adult scene; preserve the mood and move on." end
  return line, "[Inn action confirmed] " .. what .. tail
end

B.SCREENS.inn = function(G, id) B.__r23_gear_cov.calls["73-inn.lua:44"]=true; 
  local T = B.tw_T(G)
  local head = '<div class="dk-card gold">' .. B.tw_hd("pl-inn", B.U("아랫마을 여관")) ..
    '<div class="dk-text">' .. B.U("성벽 밖으로 넘쳐 자란 시가지 한쪽, 약방과 주점 사이에 낡은 여관이 서 있다. 저녁이면 모험가들이 아래층 식당에 모인다.") .. '</div>' ..
    B.tw_npcs({ { "dorothea", "도로테아", "여관 주인" } }) .. '</div>'
  if #G.roster == 0 then B.__r23_gear_cov.branches["73-inn.lua:49:2661"]=true; 
    return head .. '<div class="dk-card"><div class="dk-sub">' .. B.U("함께할 동료가 아직 없다. 길드 본관의 동료 소개 창구에서 사람을 이어 받자.") .. '</div></div>' ..
      '<div class="dk-row">' .. B.btn("in_back", B.U("토르바로 돌아가기"), "sm") .. '</div>'
  end
  local sel = G.ui.sel
  if sel ~= "" and B.has(G.roster, sel) and B.CAST[sel] then B.__r23_gear_cov.branches["73-inn.lua:54:2974"]=true; 
    local c = B.CAST[sel]
    local a = math.floor(G.aff[sel] or 0)
    local btns = {}
    for _, act in ipairs(B.INN_ORDER) do B.__r23_gear_cov.branches["73-inn.lua:58:3105"]=true; 
      if act_visible(G, act, sel) then B.__r23_gear_cov.branches["73-inn.lua:59:3142"]=true; 
        local def = B.INN_ACTS[act]
        local done = (not def.day) and T.acts[sel .. "_" .. act] == T.day
        local sub = done and B.U("오늘은 이미 했다") or B.U("{action}{cost}", { action = B.T(def.d), cost = def.cost > 0 and B.U(", 금화 {n}", { n = def.cost }) or "" })
        if done then B.__r23_gear_cov.branches["73-inn.lua:63:3434"]=true; 
          btns[#btns + 1] = '<div class="dk-btn off"><span class="t">' .. B.T(def.name) .. '<span class="d">' .. sub .. '</span></span></div>'
        else B.__r23_gear_cov.branches["73-inn.lua:65:3590"]=true; 
          btns[#btns + 1] = B.btn("in_" .. act .. "_" .. sel, B.T(def.name), "", sub)
        end
      end
    end
    local hint = nsfw_on(G) and "" or B.tw_hint(B.U("NSFW가 꺼져 있어 섹스 제안은 보이지 않는다(설정에서 켠다)."))
    return head .. '<div class="dk-card tw-who">' .. B.tw_face(sel, "") .. '<div class="tw-who-t"><div class="dk-title tw-item-n">' .. B.T(c.name) ..
      '</div><div class="dk-sub">' .. B.U("{race}, {cls}", { race = c.race, cls = c.cls }) .. '</div><div class="dk-row"><span class="dk-tag">' .. B.T(B.gd_tier(a)) ..
      '</span><span class="dk-sub">' .. B.U("호감 {a}", { a = a }) .. '</span></div><div class="dk-bar aff"><i style="transform:scaleX(' .. string.format("%.2f", math.max(a, 0) / B.AFF.MAX) ..
      ')"></i></div></div></div><div class="dk-btns tw-acts">' .. table.concat(btns) .. '</div>' .. (B.sx_inn_card and B.sx_inn_card(G) or "") .. hint ..
      '<div class="dk-row">' .. B.btn("in_list", B.U("다른 동료"), "sm") .. B.btn("in_back", B.U("토르바로 돌아가기"), "sm") .. '</div>'
  end
  local rows = {}
  for _, cid in ipairs(G.roster) do B.__r23_gear_cov.branches["73-inn.lua:78:4649"]=true; 
    local c = B.CAST[cid]
    local a = math.floor(G.aff[cid] or 0)
    rows[#rows + 1] = '<button type="button" class="dk-btn tw-mem" risu-btn="in_pick_' .. cid .. '">' .. B.tw_face(cid, "sm") ..
      '<span class="t">' .. B.T(c and c.name or cid) .. '<span class="d">' .. B.U("{stage}, 호감 {a}", { stage = B.gd_tier(a), a = a }) .. '</span></span></button>'
  end
  return head .. '<div class="dk-sub">' .. B.U("누구와 시간을 보낼까.") .. '</div><div class="dk-grid tw-mems">' .. table.concat(rows) .. '</div>' ..
    '<div class="dk-row">' .. B.btn("in_back", B.U("토르바로 돌아가기"), "sm") .. '</div>'
end

B["H"]["in"] = function(G, arg, id) B.__r23_gear_cov.calls["73-inn.lua:88"]=true; 
  local T = B.tw_T(G)
  if G.scene ~= "inn" then B.__r23_gear_cov.branches["73-inn.lua:90:5327"]=true;  return end
  if arg == "back" then B.__r23_gear_cov.branches["73-inn.lua:91:5362"]=true;  G.scene = "town"; G.ui.sel = ""; return end
  if arg == "list" then B.__r23_gear_cov.branches["73-inn.lua:92:5430"]=true;  G.ui.sel = ""; return end
  local verb, cid = arg:match("^(%a+)_(.+)$")
  if not verb or not B.has(G.roster, cid) or not B.CAST[cid] then B.__r23_gear_cov.branches["73-inn.lua:94:5568"]=true;  return end
  if verb == "pick" then B.__r23_gear_cov.branches["73-inn.lua:95:5604"]=true;  G.ui.sel = cid; return end
  local def = B.INN_ACTS[verb]
  if not def then B.__r23_gear_cov.branches["73-inn.lua:97:5680"]=true;  return end
  if not act_visible(G, verb, cid) then B.__r23_gear_cov.branches["73-inn.lua:98:5731"]=true;  G.ui.msg = B.U("지금은 할 수 없는 행동입니다."); return end
  if B.pend_busy(G, id) then B.__r23_gear_cov.branches["73-inn.lua:99:5808"]=true;    -- 앞 장면이 아직 AI 답을 받지 못했으면 막는다(답을 받은 뒤엔 새 행동이 덮어쓴다)
    G.ui.msg = B.U("앞의 장면이 아직 이어지지 않았습니다. 보내기를 눌러 먼저 이어 주세요.")
    return
  end
  local key = cid .. "_" .. verb
  if not def.day and T.acts[key] == T.day then B.__r23_gear_cov.branches["73-inn.lua:104:6021"]=true;  G.ui.msg = B.U("오늘은 이미 했습니다. 하룻밤 쉬고 나면 다시 할 수 있습니다."); return end
  if (G.gold or 0) < def.cost then B.__r23_gear_cov.branches["73-inn.lua:105:6122"]=true;  G.ui.msg = B.U("금화가 모자랍니다. {action} 값 {cost}, 가진 금화 {gold}", { action = def.name, cost = def.cost, gold = G.gold or 0 }); return end
  G.gold = G.gold - def.cost
  if def.day then B.__r23_gear_cov.branches["73-inn.lua:107:6302"]=true; 
    T.day = T.day + 1                       -- 하룻밤 — 오늘 한 일 기록은 날짜가 달라져 저절로 비워진다
  else B.__r23_gear_cov.branches["73-inn.lua:109:6390"]=true; 
    T.acts[key] = T.day
  end
  if verb == "meal" or verb == "rest" then B.__r23_gear_cov.branches["73-inn.lua:112:6463"]=true;  B.npc_like(G, "inn") end   -- 식사·숙박은 여관 주인 도로테아의 일 — 호감 +1(79-sex)
  local gained = B.aff_add(G, cid, def.aff)   -- 100 을 넘는 몫은 ×0.4 · 200 에서 멈춘다(74-affection)
  local line, pend = act_texts(G, verb, cid)
  G.pending_at = nil   -- 새 지시: 처음 실리는 요청에서 채팅 위치를 잡는다(90-triggers)
  G.pending = pend
  G.pend_soft = nil
  local ok, r = pcall(function() B.__r23_gear_cov.calls["73-inn.lua:118"]=true;  return addChat(id, "user", line) end)
  local sent = ok and r ~= false
  G.ui.msg = B.U("{name} ▲ 호감 +{a}. {next}", { name = B.tw_name(cid), a = B.aff_fmt(gained), next = sent and B.U("보내기를 누르면 이어집니다.") or B.U("채팅에 줄을 넣지 못했습니다. 한 줄 적어 보내 주세요.") })
end
