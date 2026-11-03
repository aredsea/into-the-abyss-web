B.__r23_gear_cov=B.__r23_gear_cov or {calls={},branches={}}
-- 한나의 대장간 (장면 smithy): 탭 「제련」(강화) · 「장비 가공」(뽑기). 거점에서 들어가고 「토르바로 돌아가기」로 나온다.
-- 🔴 일을 한 번이라도 했으면 돌아가기가 막히고 「제련 및 가공 완료」가 나온다 — 누르면 이번에 한 일을 장면 지시로 걸어 한나와 대화로 잇는다.
-- 상태: G.town.process_n(가공 횟수 — 계정 저장에 실린다) · G.sm_work = { forge = { {code, ok, lv} … }, proc = { 코드 … } }(이번 방문, 저장 안 함)
--       G.forge_fx / G.proc_fx(방금 한 일의 연출 — 탭을 옮기거나 다음 일을 하면 지운다)
-- 확률표·가격은 design/shop.json 의 process, 결과 계산은 81-gear.lua B.process_roll.

-- 가방과 착용 장비를 같은 규칙으로 제련한다.
function B.smithy_list(G, id) B.__r23_gear_cov.calls["82-smithy.lua:8"]=true; 
  local out, seen = {}, {}
  local function add(code) B.__r23_gear_cov.calls["82-smithy.lua:10"]=true; 
    if type(code) == "string" and B.gear_roll(code) and not seen[code] then B.__r23_gear_cov.branches["82-smithy.lua:11:611"]=true; 
      seen[code] = true
      out[#out + 1] = code
    end
  end
  for _, code in ipairs(B.bag_load(id)) do B.__r23_gear_cov.branches["82-smithy.lua:16:721"]=true;  add(code) end
  for _, eq in pairs(G.equip or {}) do B.__r23_gear_cov.branches["82-smithy.lua:17:774"]=true; 
    if type(eq) == "table" then B.__r23_gear_cov.branches["82-smithy.lua:18:804"]=true; 
      for _, slot in ipairs({ "weapon", "armor", "acc" }) do B.__r23_gear_cov.branches["82-smithy.lua:19:867"]=true;  add(eq[slot]) end
    end
  end
  table.sort(out)
  return out
end

-- (최상위 local 개수 한계 때문에 do 블록 안에 둔다)
do B.__r23_gear_cov.branches["82-smithy.lua:27:975"]=true; 
  local function work_of(G) B.__r23_gear_cov.calls["82-smithy.lua:28"]=true; 
    local w = G.sm_work
    if type(w) ~= "table" then B.__r23_gear_cov.branches["82-smithy.lua:30:1056"]=true;  return nil end
    if #(w.forge or {}) + #(w.proc or {}) == 0 then B.__r23_gear_cov.branches["82-smithy.lua:31:1123"]=true;  return nil end
    return w
  end

  local function fx_clear(G) B.__r23_gear_cov.calls["82-smithy.lua:35"]=true;  G.forge_fx, G.proc_fx = nil, nil end

  local function pct(v) B.__r23_gear_cov.calls["82-smithy.lua:37"]=true;  return string.format("%g", v or 0) end

  local function tab_forge(G, id) B.__r23_gear_cov.calls["82-smithy.lua:39"]=true; 
    local out = { '<div class="dk-sub">' .. B.U("실패해도 장비는 그대로입니다.") .. '</div>' }
    local list = B.smithy_list(G, id)
    for i, code in ipairs(list) do B.__r23_gear_cov.branches["82-smithy.lua:42:1480"]=true; 
      local f = (G.forge and G.forge[code]) or { lv = 0, tries = 0 }
      local cost = B.forge_cost(code, f.lv + 1)
      local chance = cost and B.gear().fx.forge.success[f.lv + 1]
      out[#out + 1] = '<div class="dk-card tw-item"><span class="dk-title">' .. B.esc(B.T(B.gear_roll(code).item.name)) .. ' +' .. f.lv .. '</span>' ..
        (cost and B.btn("sm_try_" .. i, B.U("제련"), "sm" .. ((G.gold or 0) < cost and " dim" or ""), B.U("금화 {cost} · 성공 {chance}%", { cost = cost, chance = chance })) or '<span class="dk-tag">+10</span>') .. '</div>'
    end
    if #list == 0 then B.__r23_gear_cov.branches["82-smithy.lua:49:2061"]=true;  out[#out + 1] = '<div class="dk-card dk-sub">' .. B.U("제련할 장비가 없습니다.") .. '</div>' end
    local fx = G.forge_fx
    if type(fx) == "table" then B.__r23_gear_cov.branches["82-smithy.lua:51:2206"]=true; 
      out[#out + 1] = '<div class="dk-card forge-show"><i class="im im-forge-hammer forge-hammer"></i><i class="im im-forge-spark forge-spark"></i><span class="forge-result">' .. B.U(fx.ok and "제련 성공!" or "제련 실패. 장비는 그대로입니다.") .. '</span></div>'
    end
    return table.concat(out)
  end

  local function tab_process(G, id) B.__r23_gear_cov.calls["82-smithy.lua:57"]=true; 
    local T = B.tw_T(G)
    local band = B.process_band(G)
    local lv = B.process_lv(G)
    local rows = {}
    for _, r in ipairs(B.RARITY_ORDER) do B.__r23_gear_cov.branches["82-smithy.lua:62:2686"]=true; 
      local w = band.w[r] or 0
      rows[#rows + 1] = '<div class="proc-rate bg-r-' .. r .. (w == 0 and " zero" or "") .. '"><span class="bg-nm">' .. B.esc(B.T(B.RARITY[r].name)) .. '</span><b>' .. pct(w) .. '%</b></div>'
    end
    local gold = G.gold or 0
    local short = band.price - gold
    local out = {
      '<div class="dk-card"><div class="dk-text">' .. B.U("금화를 내면 대장간이 쇳덩이를 가공해 장비 한 점을 내어 준다. 어떤 장비가 나올지는 누르기 전에 이미 정해져 있어서, 되돌리거나 다시 불러와도 같은 차례에는 같은 장비가 나온다.") .. '</div>' ..
      '<div class="dk-row"><span class="dk-tag">' .. B.U("기준 Lv {lv}", { lv = lv }) .. '</span><span class="dk-tag">' .. B.U("가공 1회 금화 {n}", { n = band.price }) .. '</span><span class="dk-tag">' .. B.U("지금까지 {n}회", { n = tonumber(T.process_n) or 0 }) .. '</span></div></div>',
      '<div class="dk-card"><div class="dk-title">' .. B.U("등급별 확률") .. '</div><div class="proc-rates">' .. table.concat(rows) .. '</div>' ..
      '<div class="dk-sub">' .. B.U("Lv {from}~{to} 구간 · 확률은 바뀔 수 있습니다.", { from = band.from, to = band.to }) .. '</div>' ..
      '<div class="dk-sub">' .. B.U("출전할 수 있는 동료 가운데 가장 높은 레벨이 기준이고, 나오는 장비는 지금 모험가들의 직업에서 정해진다.") .. '</div></div>',
      '<div class="dk-row">' .. B.btn("sm_proc", B.U("장비 가공"), "go" .. (short > 0 and " dim" or ""), short > 0 and B.U("금화 {n} 모자란다", { n = short }) or B.U("금화 {n}", { n = band.price })) .. '</div>',
    }
    local fx = G.proc_fx
    local r = type(fx) == "table" and B.gear_roll(fx.code, lv) or nil
    if r then B.__r23_gear_cov.branches["82-smithy.lua:78:4152"]=true; 
      out[#out + 1] = '<div class="dk-card proc-show bg-r-' .. r.item.rarity .. '"><i class="proc-glow"></i><i class="im im-forge-hammer proc-seal"></i><i class="im im-forge-spark proc-spark"></i>' ..
        '<span class="proc-name bg-nm">' .. B.esc(B.T(r.item.name)) .. '</span></div>'
      out[#out + 1] = '<div class="proc-card">' .. B.PX.gear_card(r) .. '</div>'
    end
    return table.concat(out)
  end

  B.SCREENS.smithy = function(G, id) B.__r23_gear_cov.calls["82-smithy.lua:86"]=true; 
    B.tw_T(G)
    local tab = (G.ui.tab == "process") and "process" or "forge"
    local function tb(k, label) B.__r23_gear_cov.calls["82-smithy.lua:89"]=true;  return B.btn("sm_tab_" .. k, B.U(label), "sm" .. (tab == k and " on" or "")) end
    local work = work_of(G)
    local foot
    if work then B.__r23_gear_cov.branches["82-smithy.lua:92:4854"]=true; 
      foot = '<div class="dk-row">' .. B.btn("sm_done", B.U("제련 및 가공 완료"), "sm go", B.U("한나와 이야기를 나눈다")) ..
        B.btn("sm_back", B.U("토르바로 돌아가기"), "sm dim", B.U("먼저 「제련 및 가공 완료」를 눌러 주세요")) .. '</div>'
    else B.__r23_gear_cov.branches["82-smithy.lua:95:5068"]=true; 
      foot = '<div class="dk-row">' .. B.btn("sm_back", B.U("토르바로 돌아가기"), "sm") .. '</div>'
    end
    return '<div class="dk-card gold">' .. B.tw_hd("pl-smithy", B.T(B.PLACE.smithy.name)) ..
      '<div class="dk-text">' .. B.T(B.PLACE.smithy.d) .. '</div>' ..
      B.tw_npcs({ { "hanna", "한나", "대장간 주인" } }) .. '</div>' ..
      '<div class="dk-tabs">' .. tb("forge", "제련") .. tb("process", "장비 가공") .. '</div>' ..
      (tab == "process" and tab_process(G, id) or tab_forge(G, id)) .. foot
  end

  -- 이번에 한 일을 영어 한 줄씩(AI 에게 넘길 장면 지시)
  local function work_note(w) B.__r23_gear_cov.calls["82-smithy.lua:106"]=true; 
    local function cut(list, f) B.__r23_gear_cov.calls["82-smithy.lua:107"]=true; 
      local out = {}
      for i, v in ipairs(list) do B.__r23_gear_cov.branches["82-smithy.lua:109:5727"]=true; 
        if i > 8 then B.__r23_gear_cov.branches["82-smithy.lua:110:5747"]=true;  out[#out + 1] = "and " .. (#list - 8) .. " more"; break end
        out[#out + 1] = f(v)
      end
      return table.concat(out, "; ")
    end
    local parts = {}
    if #(w.forge or {}) > 0 then B.__r23_gear_cov.branches["82-smithy.lua:116:5945"]=true; 
      parts[#parts + 1] = "Refining: " .. cut(w.forge, function(e) B.__r23_gear_cov.calls["82-smithy.lua:117"]=true; 
        return B.C1_en_gear_label(e.code) .. (e.ok and (" succeeded, now +" .. e.lv) or (" failed, stays at +" .. e.lv))
      end) .. "."
    end
    if #(w.proc or {}) > 0 then B.__r23_gear_cov.branches["82-smithy.lua:121:6191"]=true; 
      parts[#parts + 1] = "Processing: " .. cut(w.proc, function(code) B.__r23_gear_cov.calls["82-smithy.lua:122"]=true;  return B.C1_en_gear_label(code) end) .. " received."
    end
    return table.concat(parts, " ")
  end

  B.H.sm = function(G, arg, id) B.__r23_gear_cov.calls["82-smithy.lua:127"]=true; 
    if G.scene ~= "smithy" then B.__r23_gear_cov.branches["82-smithy.lua:128:6430"]=true;  return end
    local T = B.tw_T(G)
    local tab = arg:match("^tab_(%a+)$")
    if tab then B.__r23_gear_cov.branches["82-smithy.lua:131:6522"]=true; 
      if tab == "forge" or tab == "process" then B.__r23_gear_cov.branches["82-smithy.lua:132:6571"]=true;  G.ui.tab = tab; fx_clear(G) end
      return
    end
    if arg == "back" then B.__r23_gear_cov.branches["82-smithy.lua:135:6650"]=true; 
      if work_of(G) then B.__r23_gear_cov.branches["82-smithy.lua:136:6675"]=true;  G.ui.msg = B.U("제련이나 가공을 마쳤다면 「제련 및 가공 완료」를 눌러 한나와 이야기를 나눈 뒤 돌아갈 수 있습니다."); return end
      G.scene = "town"; G.ui.sel, G.ui.tab = "", ""
      G.sm_work = nil
      fx_clear(G)
      return
    end
    if arg == "done" then B.__r23_gear_cov.branches["82-smithy.lua:142:6901"]=true; 
      local w = work_of(G)
      if not w then B.__r23_gear_cov.branches["82-smithy.lua:144:6948"]=true;  G.ui.msg = B.U("아직 제련이나 가공을 하지 않았습니다."); return end
      local note = work_note(w)
      G.sm_work = nil
      fx_clear(G)
      G.pending_at = nil   -- 새 지시: 처음 실리는 요청에서 채팅 위치를 잡는다(90-triggers)
      B.pend_hard(G, "[Smithy work confirmed] At Hanna's Smithy in Torva, the user has finished having gear refined and processed. " .. note ..
        " Write a short scene where Hanna reacts to these results in her own voice. The outcomes are final; do not change them. Do not write the user's words or actions.",
        id, B.U("(제련과 가공을 마치고 한나와 이야기를 나눈다)"))
      return
    end
    local index = tonumber(arg:match("^try_(%d+)$"))
    if index then B.__r23_gear_cov.branches["82-smithy.lua:155:7599"]=true; 
      local code = B.smithy_list(G, id)[index]
      if not code then B.__r23_gear_cov.branches["82-smithy.lua:157:7669"]=true;  return end
      local ok, info = B.forge_try(G, id, code)
      if ok == nil then B.__r23_gear_cov.branches["82-smithy.lua:159:7752"]=true;  G.ui.msg = B.U(info); return end
      fx_clear(G)
      G.forge_fx = { ok = ok, code = code }
      if type(G.sm_work) ~= "table" then B.__r23_gear_cov.branches["82-smithy.lua:162:7888"]=true;  G.sm_work = { forge = {}, proc = {} } end
      local list = G.sm_work.forge
      list[#list + 1] = { code = code, ok = ok, lv = B.forge_state(G, code).lv }
      if B.npc_like then B.__r23_gear_cov.branches["82-smithy.lua:165:8071"]=true;  B.npc_like(G, "smithy") end   -- 대장간 행동마다 한나 호감 +1(79-sex)
      G.ui.msg = ""
      return
    end
    if arg == "proc" then B.__r23_gear_cov.branches["82-smithy.lua:169:8197"]=true; 
      local band = B.process_band(G)
      if (G.gold or 0) < band.price then B.__r23_gear_cov.branches["82-smithy.lua:171:8275"]=true; 
        G.ui.msg = B.U("금화가 모자랍니다. 가공 값 {cost}, 가진 금화 {gold}", { cost = band.price, gold = G.gold or 0 })
        return
      end
      if #B.bag_load(id) >= B.BAG_MAX then B.__r23_gear_cov.branches["82-smithy.lua:175:8449"]=true;  G.ui.msg = B.U("가방이 가득 찼습니다."); return end
      local n = (tonumber(T.process_n) or 0) + 1
      local code = B.process_roll(G, n)
      if not code or not B.bag_add(id, code) then B.__r23_gear_cov.branches["82-smithy.lua:178:8631"]=true;  G.ui.msg = B.U("지금은 가공할 수 없습니다."); return end
      G.gold = G.gold - band.price
      T.process_n = n
      fx_clear(G)
      G.proc_fx = { code = code }
      if type(G.sm_work) ~= "table" then B.__r23_gear_cov.branches["82-smithy.lua:183:8827"]=true;  G.sm_work = { forge = {}, proc = {} } end
      local list = G.sm_work.proc
      list[#list + 1] = code
      if B.npc_like then B.__r23_gear_cov.branches["82-smithy.lua:186:8957"]=true;  B.npc_like(G, "smithy") end
      G.ui.msg = ""
    end
  end
end
