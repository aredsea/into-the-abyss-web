-- ===== 균열 입장 화면 (장면 sortie · 버튼 접두 so) : 출정 전에 파티를 고른다 =====
-- 토르바 「출정」(tw_sortie)이 G.scene = "sortie" 로 이 화면을 연다. 정본은 G.party(동료 id, 순서 = 슬롯 순서) + G.persona.fight.
-- 읽는 G 칸: party · roster · aff · persona(fight · name · cls) · lvl/exp(B.lv_of) · guild(quests · active) · ui.tab(열 필터: "" 전체 · front · back)
-- 쓰는 G 칸: party · persona.fight · ui(tab · msg) · town.bn(입장 때 +1) · scene
-- 참고(refs/Parma_Knights/ANALYSIS.md): 카드 = 토글, 누를 때마다 Lua 커밋 · 상한이 차면 고르지 않은 카드는 흐리게 · 공백은 경고만(막지 않는다).
-- 경고 기준(전열 0명 · 평균 레벨이 적보다 5 이상 낮음)과 후보 정렬(출전 중 → 레벨 높은 순)은 [제안].
-- 🔴 B.battle_start(G, id, q) 는 메인이 전투 엔진 쪽에 만든다. 있으면 그것이 전투 상태를 만들고 저장하고 G.scene = "battle" 로 바꾼다.
--    없으면 아래 옛 출정 코드(B.fresh + st.rg)가 대신한다. 어느 쪽이든 G.town.bn 은 이 파일이 먼저 +1 한다.

B.SO = {}
do B.__expe_cov.branches["75-sortie.lua:11:750"]=true; 
  local SO = B.SO
  SO.DANGER_GAP = 5                       -- 적 레벨이 파티 평균보다 이만큼 높으면 「위험」 [제안]

  function SO.cap(G) B.__expe_cov.calls["75-sortie.lua:15"]=true;  return (G.persona and G.persona.fight == 1) and 3 or 4 end

  -- 편성 정리: roster 에 없는 id · 중복 제거, 상한(페르소나 출전 3 / 지휘 4)을 넘는 뒤쪽은 대기로
  function SO.clean(G) B.__expe_cov.calls["75-sortie.lua:18"]=true; 
    local out, seen = {}, {}
    for _, cid in ipairs(G.party or {}) do B.__expe_cov.branches["75-sortie.lua:20:1091"]=true; 
      if B.CAST[cid] and B.has(G.roster, cid) and not seen[cid] then B.__expe_cov.branches["75-sortie.lua:21:1158"]=true;  seen[cid] = true; out[#out + 1] = cid end
    end
    local cap = SO.cap(G)
    while #out > cap do B.__expe_cov.branches["75-sortie.lua:24:1260"]=true;  table.remove(out) end
    G.party = out
    return out
  end

  function SO.pname(G) B.__expe_cov.calls["75-sortie.lua:29"]=true; 
    local n = G.persona and G.persona.name or ""
    return (n ~= "" and n) or "당신"
  end
  function SO.prow(G) B.__expe_cov.calls["75-sortie.lua:33"]=true; 
    local cl = B.PX and B.PX.cls(G.persona and G.persona.cls)
    return cl and cl.row or "", cl and cl.name or ((G.persona and G.persona.cls) or "")
  end

  -- 출전자 목록(슬롯 순서): { {id="persona"|cid, name, cls, row, lv}, ... }
  function SO.members(G) B.__expe_cov.calls["75-sortie.lua:39"]=true; 
    local m = {}
    if G.persona and G.persona.fight == 1 then B.__expe_cov.branches["75-sortie.lua:41:1769"]=true; 
      local row, cls = SO.prow(G)
      m[#m + 1] = { id = "persona", name = SO.pname(G), cls = cls, row = row, lv = B.lv_of(G, "persona") }
    end
    for _, cid in ipairs(SO.clean(G)) do B.__expe_cov.branches["75-sortie.lua:45:1961"]=true; 
      local c = B.CAST[cid]
      m[#m + 1] = { id = cid, name = c.name, cls = c.cls, row = c.row, lv = B.lv_of(G, cid) }
    end
    return m
  end

  local function face(id, name) B.__expe_cov.calls["75-sortie.lua:52"]=true; 
    if id == "persona" then B.__expe_cov.branches["75-sortie.lua:53:2169"]=true;  return '<span class="dk-face so-f">' .. B.pimg(nil, "px-ph") .. '</span>' end
    return B.PX.face(id, name, "so-f")
  end

  -- ① 의뢰 카드
  local function quest_card(G, q) B.__expe_cov.calls["75-sortie.lua:58"]=true; 
    if not q then B.__expe_cov.branches["75-sortie.lua:59:2358"]=true; 
      return '<div class="dk-card gold"><div class="dk-title">' .. B.U("균열 입장") .. '</div><div class="dk-sub">' .. B.U("받아 둔 의뢰가 없습니다. 토르바로 돌아가 길드 의뢰판을 먼저 보세요.") .. '</div></div>'
    end
    return '<div class="dk-card gold so-quest"><div class="tw-q-h"><span class="dk-title tw-item-n"><i class="im im-pl-rift tw-iico"></i>' .. B.esc(B.gd_title(q)) .. '</span><span class="tw-stars">' .. B.tw_stars(q.stars) ..
      '</span></div><div class="dk-sub">' .. B.esc(B.T(q.d or "")) .. '</div><div class="dk-row"><span class="dk-tag">' .. B.U(q.kind or "") ..
      '</span><span class="dk-tag">' .. B.U("난이도 {difficulty}", { difficulty = B.U(B.gd_difficulty(q)) }) .. '</span><span class="dk-tag">' .. B.U("보상 금화 {gold}", { gold = B.gd_gold(G, q) }) .. '</span><span class="dk-tag so-elv">' .. B.U("적 Lv {lv}", { lv = B.gd_qlv(G, q) }) .. '</span></div></div>'
  end

  -- ② 출전 슬롯 4칸
  local function slots(G, m) B.__expe_cov.calls["75-sortie.lua:68"]=true; 
    local cells = {}
    for i = 1, 4 do B.__expe_cov.branches["75-sortie.lua:70:3312"]=true; 
      local x = m[i]
      if x then B.__expe_cov.branches["75-sortie.lua:72:3347"]=true; 
        cells[#cells + 1] = '<button type="button" class="dk-btn so-slot pick" risu-btn="so_rm_' .. x.id .. '">' .. face(x.id, x.name) ..
          '<span class="t so-t">' .. B.esc(B.T(x.name)) .. '<span class="d">' .. B.U("{cls}, {row}, Lv {lv}", { cls = B.esc(x.cls), row = B.esc(x.row), lv = x.lv }) .. '</span></span></button>'
      else B.__expe_cov.branches["75-sortie.lua:75:3690"]=true; 
        cells[#cells + 1] = '<div class="so-slot so-empty"><span class="so-n">' .. i .. '</span><span class="dk-sub">' .. B.U("비어 있음") .. '</span></div>'
      end
    end
    return '<div class="dk-card"><div class="so-h"><span class="dk-title">' .. B.U("출전 인원") .. '</span><span class="dk-sub">' .. B.U("{n} / 4 (칸을 누르면 뺀다)", { n = #m }) .. '</span></div>' ..
      '<div class="so-slots">' .. table.concat(cells) .. '</div></div>'
  end

  -- ③ 페르소나 출전 토글
  local function fight_row(G) B.__expe_cov.calls["75-sortie.lua:84"]=true; 
    local f = G.persona and G.persona.fight == 1
    return '<div class="dk-card"><div class="so-h"><span class="dk-title">' .. B.esc(B.T(SO.pname(G))) .. '</span><span class="dk-sub">' ..
      B.U(f and '직접 싸운다. 동료는 최대 3명' or '지휘만 한다. 동료 4명으로 나선다') .. '</span></div><div class="dk-row">' ..
      B.btn("so_fight_1", B.U("직접 싸운다"), "sm" .. (f and " on" or "")) .. B.btn("so_fight_0", B.U("지휘만 한다"), "sm" .. (f and "" or " on")) .. '</div></div>'
  end

  -- ④ 후보 카드 그리드
  local function filt(G) B.__expe_cov.calls["75-sortie.lua:92"]=true; 
    local f = G.ui and G.ui.tab
    return (f == "front" or f == "back") and f or ""
  end
  local function ordered(G) B.__expe_cov.calls["75-sortie.lua:96"]=true; 
    local idx = {}
    for i, cid in ipairs(B.CAST_ORDER or {}) do B.__expe_cov.branches["75-sortie.lua:98:4864"]=true;  idx[cid] = i end
    local list = {}
    for _, cid in ipairs(G.roster or {}) do B.__expe_cov.branches["75-sortie.lua:100:4945"]=true; 
      local c = B.CAST[cid]
      if c then B.__expe_cov.branches["75-sortie.lua:102:4987"]=true; 
        local f = filt(G)
        if f == "" or (f == "front" and c.row == "전열") or (f == "back" and c.row == "후열") then B.__expe_cov.branches["75-sortie.lua:104:5108"]=true; 
          list[#list + 1] = { cid = cid, on = B.has(G.party, cid), lv = B.lv_of(G, cid), i = idx[cid] or 99 }
        end
      end
    end
    table.sort(list, function(a, b) B.__expe_cov.calls["75-sortie.lua:109"]=true; 
      if a.on ~= b.on then B.__expe_cov.branches["75-sortie.lua:110:5311"]=true;  return a.on end
      if a.lv ~= b.lv then B.__expe_cov.branches["75-sortie.lua:111:5354"]=true;  return a.lv > b.lv end
      return a.i < b.i
    end)
    return list
  end

  local function cards(G) B.__expe_cov.calls["75-sortie.lua:117"]=true; 
    local PX = B.PX
    local cap, full = SO.cap(G), #G.party >= SO.cap(G)
    local function ft(k, label) B.__expe_cov.calls["75-sortie.lua:120"]=true;  return B.btn("so_f_" .. k, B.U(label), "sm" .. ((filt(G) == "" and k == "all" or filt(G) == k) and " on" or "")) end
    local o = { '<div class="dk-card"><div class="so-h"><span class="dk-title">' .. B.U("동료 고르기") .. '</span><span class="dk-sub">' .. B.U("동료 {n} / {cap}명 (카드를 눌러 넣고 뺀다)", { n = #G.party, cap = cap }) .. '</span></div>',
      '<div class="dk-tabs">' .. ft("all", "전체") .. ft("front", "전열") .. ft("back", "후열") .. '</div>' }
    local list = ordered(G)
    if #(G.roster or {}) == 0 then B.__expe_cov.branches["75-sortie.lua:124:6071"]=true; 
      o[#o + 1] = '<div class="dk-sub">' .. B.U("아직 동료가 없다. 길드의 「동료 소개」 창구에서 사람을 이어 받을 수 있다.") .. '</div>'
    elseif #list == 0 then B.__expe_cov.branches["75-sortie.lua:126:6205"]=true; 
      o[#o + 1] = '<div class="dk-sub">' .. B.U("이 열에는 동료가 없다.") .. '</div>'
    else B.__expe_cov.branches["75-sortie.lua:128:6291"]=true; 
      o[#o + 1] = '<div class="dk-grid so-grid">'
      for _, x in ipairs(list) do B.__expe_cov.branches["75-sortie.lua:130:6377"]=true; 
        local c = B.CAST[x.cid]
        local a = PX.aff(G, x.cid)
        local dim = full and not x.on
        o[#o + 1] = '<button type="button" class="dk-btn so-card' .. (x.on and " pick" or "") .. (dim and " off" or "") .. '" risu-btn="so_tg_' .. x.cid .. '">' .. face(x.cid, c.name) ..
          '<span class="t so-t">' .. B.esc(B.T(c.name)) .. (x.on and ('<i class="so-on">' .. B.U("출전") .. '</i>') or '') .. '<span class="d">' .. B.U("{cls}, {row}", { cls = B.esc(c.cls), row = B.esc(c.row) }) ..
          '</span><span class="d">' .. B.U("Lv {lv} · {el}속성", { lv = x.lv, el = PX.EL[c.el] or "무" }) .. '</span>' .. PX.bar("aff", math.max(a, 0), B.AFF.MAX) .. '</span></button>'
      end
      o[#o + 1] = '</div>'
    end
    o[#o + 1] = '</div>'
    return table.concat(o)
  end

  -- ⑤ 요약 + 부드러운 경고(막지 않는다)
  function SO.summary(G, q, m) B.__expe_cov.calls["75-sortie.lua:145"]=true; 
    local n, sum, front = #m, 0, 0
    for _, x in ipairs(m) do B.__expe_cov.branches["75-sortie.lua:147:7291"]=true;  sum = sum + x.lv; if x.row == "전열" then B.__expe_cov.branches["75-sortie.lua:147:7329"]=true;  front = front + 1 end end
    local avg = (n > 0) and math.floor(sum / n) or 0
    local elv = q and B.gd_qlv(G, q) or 0
    local warns = {}
    if n > 0 and front == 0 then B.__expe_cov.branches["75-sortie.lua:151:7504"]=true;  warns[#warns + 1] = B.U("앞에서 막을 사람이 없습니다. 전열이 한 명도 없으면 후열이 바로 맞습니다.") end
    if n > 0 and q and elv - avg >= SO.DANGER_GAP then B.__expe_cov.branches["75-sortie.lua:152:7633"]=true; 
      warns[#warns + 1] = B.U("위험합니다. 적이 파티 평균보다 {gap}레벨 높습니다.", { gap = elv - avg })
    end
    return { n = n, avg = avg, elv = elv, front = front, warns = warns }
  end

  local function summary_card(G, q, m) B.__expe_cov.calls["75-sortie.lua:158"]=true; 
    local s = SO.summary(G, q, m)
    local w = {}
    for _, t in ipairs(s.warns) do B.__expe_cov.branches["75-sortie.lua:161:7934"]=true;  w[#w + 1] = '<div class="so-warn">' .. B.esc(B.U(t)) .. '</div>' end
    return '<div class="dk-card so-sum"><div class="dk-row"><span class="dk-tag">' .. B.U("출전 {n}명", { n = s.n }) .. '</span><span class="dk-tag">' ..
      (s.n > 0 and B.U("평균 Lv {avg}", { avg = s.avg }) or B.U("평균 -")) .. '</span><span class="dk-tag so-elv">' .. B.U("적 Lv {lv}", { lv = s.elv }) .. '</span><span class="dk-tag">' .. B.U("전열 {n}명", { n = s.front }) .. '</span></div>' ..
      table.concat(w) .. '</div>'
  end

  B.SCREENS.sortie = function(G, id) B.__expe_cov.calls["75-sortie.lua:167"]=true; 
    B.tw_T(G)
    local D = B.dn_G(G)
    local dn = (D.mode == 1)
    local q = B.gd_find(G, G.guild.active)
    local m = SO.members(G)
    local ready = (dn or q) and #m > 0
    local qq = q
    if dn then B.__expe_cov.branches["75-sortie.lua:175:8678"]=true;    -- 경고 줄(적이 평균보다 높은가)에 쓸 가짜 의뢰: 고른 층의 적 레벨
      local _, _, avg = B.dn_party(G)
      qq = { lv = B.dn_floor_view(D.sel, avg).el, stars = 1 }
    end
    local modes = '<div class="dk-tabs">' .. B.btn("so_mode_0", B.U("의뢰 출정"), "sm" .. (dn and "" or " on")) .. B.btn("so_mode_1", B.U("대던전 도전"), "sm" .. (dn and " on" or "")) .. '</div>'
    return modes .. (dn and B.dn_card(G) or quest_card(G, q)) .. slots(G, m) .. fight_row(G) .. cards(G) .. summary_card(G, qq, m) ..
      '<div class="so-go">' .. B.btn("so_go", B.U(dn and "대던전에 도전한다" or "균열로 들어간다"), "go" .. (ready and "" or " off"), (#m == 0) and B.U("출전할 사람이 없다") or nil) ..
      B.btn("so_back", B.U("토르바로"), "sm") .. '</div>'
  end

  -- 옛 출정 코드(B.battle_start 가 없을 때): 전투 엔진 파티는 고정(레비아·마르셀린·나란·테이리스)
  local function legacy_start(G, id, q) B.__expe_cov.calls["75-sortie.lua:186"]=true; 
    local T = G.town
    local st = B.fresh(T.bn, B.DIFF_MUL and B.DIFF_MUL(G) or nil)
    st.rg = B.gd_gold(G, q)                            -- 전투 결과 줄의 금화 = 의뢰 보상(정산과 같은 값 · 레벨 배수 포함)
  if q.reward_v == 2 then B.__expe_cov.branches["75-sortie.lua:190:9694"]=true;  st.qmult = B.GD_DIFFICULTY[B.gd_difficulty(q)].reward end
    B.save(id, st)
    G.scene = "battle"
    G.ui.panel = ""
  end

  B.H.so = function(G, arg, id) B.__expe_cov.calls["75-sortie.lua:196"]=true; 
    if G.scene ~= "sortie" then B.__expe_cov.branches["75-sortie.lua:197:9885"]=true;  return end             -- 같은 버튼 두 번: 이미 전투 장면이면 무시
    local T = B.tw_T(G)
    SO.clean(G)
    local cap = SO.cap(G)
    local rm = arg:match("^rm_(.+)$")
    local tg = arg:match("^tg_(.+)$")
    local fl = arg:match("^f_(%a+)$")
    local fi = arg:match("^fight_([01])$")
    local md = arg:match("^mode_([01])$")
    local fno = arg:match("^fl_(%d+)$")
    local pgn = arg:match("^pg_(%d+)$")
    local D = B.dn_G(G)
    if arg == "back" then B.__expe_cov.branches["75-sortie.lua:209:10331"]=true; 
      G.scene = "town"; G.ui.tab = ""
    elseif md then B.__expe_cov.branches["75-sortie.lua:211:10388"]=true; 
      D.mode = tonumber(md)
    elseif fno then B.__expe_cov.branches["75-sortie.lua:213:10436"]=true; 
      local f = tonumber(fno)
      if B.dn_allowed(G, f) then B.__expe_cov.branches["75-sortie.lua:215:10499"]=true;  D.sel = f end
    elseif pgn then B.__expe_cov.branches["75-sortie.lua:216:10533"]=true; 
      D.pg = math.max(1, tonumber(pgn))
    elseif fl then B.__expe_cov.branches["75-sortie.lua:218:10592"]=true; 
      if fl == "all" then B.__expe_cov.branches["75-sortie.lua:219:10618"]=true;  G.ui.tab = "" elseif fl == "front" or fl == "back" then B.__expe_cov.branches["75-sortie.lua:219:10674"]=true;  G.ui.tab = fl end
    elseif rm then B.__expe_cov.branches["75-sortie.lua:220:10711"]=true; 
      if rm == "persona" then B.__expe_cov.branches["75-sortie.lua:221:10741"]=true; 
        G.persona.fight = 0
      else B.__expe_cov.branches["75-sortie.lua:223:10780"]=true; 
        for i = #G.party, 1, -1 do B.__expe_cov.branches["75-sortie.lua:224:10817"]=true;  if G.party[i] == rm then B.__expe_cov.branches["75-sortie.lua:224:10840"]=true;  table.remove(G.party, i) end end
      end
    elseif tg then B.__expe_cov.branches["75-sortie.lua:226:10902"]=true; 
      if not (B.CAST[tg] and B.has(G.roster, tg)) then B.__expe_cov.branches["75-sortie.lua:227:10957"]=true;  return end
      if B.has(G.party, tg) then B.__expe_cov.branches["75-sortie.lua:228:11001"]=true; 
        for i = #G.party, 1, -1 do B.__expe_cov.branches["75-sortie.lua:229:11038"]=true;  if G.party[i] == tg then B.__expe_cov.branches["75-sortie.lua:229:11061"]=true;  table.remove(G.party, i) end end
      elseif #G.party >= cap then B.__expe_cov.branches["75-sortie.lua:230:11128"]=true; 
        G.ui.msg = B.U("출전 자리가 찼습니다(최대 {cap}명). 한 명을 빼고 다시 고르세요.", { cap = cap })
      else B.__expe_cov.branches["75-sortie.lua:232:11221"]=true; 
        G.party[#G.party + 1] = tg
      end
    elseif fi then B.__expe_cov.branches["75-sortie.lua:235:11285"]=true; 
      G.persona.fight = tonumber(fi)
      if G.persona.fight == 1 and #G.party > 3 then B.__expe_cov.branches["75-sortie.lua:237:11374"]=true; 
        local drop = table.remove(G.party)
        G.ui.msg = B.U("출전이 4명이 되어 마지막 동료 {name:은는} 대기로 돌렸습니다.", { name = B.esc(B.tw_name(drop)) })
      end
    elseif arg == "go" and D.mode == 1 then B.__expe_cov.branches["75-sortie.lua:241:11571"]=true;    -- 대던전 도전(76-dungeon)
      if #SO.members(G) == 0 then B.__expe_cov.branches["75-sortie.lua:242:11629"]=true;  G.ui.msg = B.U("출전할 사람이 없습니다. 한 명 이상 고르세요."); return end
      T.bn = T.bn + 1
      B.dn_start(G, id)
      if G.scene == "battle" then B.__expe_cov.branches["75-sortie.lua:245:11766"]=true;  G.ui.panel, G.ui.tab = "", "" end
    elseif arg == "go" then B.__expe_cov.branches["75-sortie.lua:246:11828"]=true; 
      local q = B.gd_find(G, G.guild.active)
      if not q then B.__expe_cov.branches["75-sortie.lua:248:11893"]=true;  G.ui.msg = B.U("받아 둔 의뢰가 없습니다. 길드 본관의 의뢰판을 먼저 보세요."); G.scene = "town"; return end
      if #SO.members(G) == 0 then B.__expe_cov.branches["75-sortie.lua:249:12010"]=true;  G.ui.msg = B.U("출전할 사람이 없습니다. 한 명 이상 고르세요."); return end
      T.bn = T.bn + 1
      if B.battle_start then B.__expe_cov.branches["75-sortie.lua:251:12118"]=true;  B.battle_start(G, id, q) else B.__expe_cov.branches["75-sortie.lua:251:12148"]=true;  legacy_start(G, id, q) end
      if G.scene == "battle" then B.__expe_cov.branches["75-sortie.lua:252:12209"]=true;  G.ui.panel, G.ui.tab = "", "" end
    end
  end
end
