-- ===== 대던전 도전 (정본 design/DUNGEON.md [확정 10-10] · ENEMIES.md 「끝없는 층」 · 「레이드 전투」) =====
-- 층에는 끝이 없다. 한 층 = 입장 → 탐색 ×5(70% 전투 · 30% 발견) → 휴식(파티 HP +30% · 정비) → 층 보스(레이드) → 정산. 흐름 본체는 77-explore.lua.
-- 이 파일: 층 목록 · 고를 수 있는 층 · 층의 모습 · 기준 금화 · 출정 화면 카드(dn_card). 정산 · 시작 · 버튼은 77-explore.lua.
-- 읽는 G 칸: dungeon · party · roster · persona · gold / 쓰는 칸: dungeon(best · cleared_bosses · runs · sel · mode · pg · run) · gold · items · exp · town
-- 🔴 버튼: so_mode_0 · so_mode_1 · so_fl_<층> · so_pg_<쪽> · so_go(75-sortie 가 mode 1 일 때 B.dn_start) / 탐색 중 ex_*(77-explore)
-- TODO(DUNGEON.md 「갈림길 지도」): 옛 갈림길 지도 설계는 사장님 10-10 흐름(탐색 ×5)으로 대체됐다(DUNGEON.md 에 표시).

B.DN = { PAGE = 6 }

function B.dn_G(G) B.__expe_cov.calls["76-dungeon.lua:10"]=true; 
  if type(G.dungeon) ~= "table" then B.__expe_cov.branches["76-dungeon.lua:11:726"]=true;  G.dungeon = {} end
  local D = G.dungeon
  D.best = math.max(0, math.floor(tonumber(D.best) or 0))
  D.runs = math.max(0, math.floor(tonumber(D.runs) or 0))
  D.sel = math.max(1, math.floor(tonumber(D.sel) or 1))
  D.mode = (D.mode == 1) and 1 or 0
  D.pg = math.max(1, math.floor(tonumber(D.pg) or 1))
  if type(D.cleared_bosses) ~= "table" then B.__expe_cov.branches["76-dungeon.lua:18:1073"]=true;  D.cleared_bosses = {} end
  if D.run ~= nil and type(D.run) ~= "table" then B.__expe_cov.branches["76-dungeon.lua:19:1149"]=true;  D.run = nil end   -- 진행 중인 층(77-explore) — 깨진 값은 버린다
  return D
end

-- 고를 수 있는 가장 깊은 층: 가장 깊이 간 층 + 1, 또는 구역 보스를 처음 쓰러뜨려 열린 다음 구역의 첫 층(지름길)
function B.dn_max(G) B.__expe_cov.calls["76-dungeon.lua:24"]=true; 
  local D = B.dn_G(G)
  local m = D.best + 1
  for zi, zid in ipairs(B.ZONE_ORDER) do B.__expe_cov.branches["76-dungeon.lua:27:1399"]=true; 
    if B.has(D.cleared_bosses, zid) and zi < #B.ZONE_ORDER then B.__expe_cov.branches["76-dungeon.lua:28:1461"]=true;  m = math.max(m, 3 * zi + 1) end
  end
  return m
end
function B.dn_allowed(G, floor) B.__expe_cov.calls["76-dungeon.lua:32"]=true;  return floor >= 1 and floor <= B.dn_max(G) end

-- 파티 평균 레벨 · 인원
function B.dn_party(G) B.__expe_cov.calls["76-dungeon.lua:35"]=true; 
  local pm = B.battle_pm(G)
  local n, sum = 0, 0
  for _, m in ipairs(pm) do B.__expe_cov.branches["76-dungeon.lua:38:1714"]=true;  if m.id ~= "" then B.__expe_cov.branches["76-dungeon.lua:38:1731"]=true;  n = n + 1; sum = sum + (m.L or 1) end end
  return pm, n, (n > 0) and (sum / n) or 1
end

-- 층 하나의 모습(화면 · 보상용)
function B.dn_floor_view(floor, avg) B.__expe_cov.calls["76-dungeon.lua:43"]=true; 
  local info = B.floor_info(floor)
  local Z = B.ZONES[info.zone]
  local bk = B.floor_boss_kind(info)
  local sm = B.floor_mult(floor)
  local lead = (bk == "boss") and Z.boss or nil
  return { info = info, zone = Z, boss_kind = bk, el = B.floor_level(avg or 1, info), star = B.floor_star(info), reward = sm.reward, lead = lead }
end

-- 기준 금화: 일반 전투 한 번 = gold_ref × ★ 보상 배수. 우두머리 ×2.5 · 구역 보스 ×4 (ENEMIES.md)
function B.dn_gold(floor, kind) B.__expe_cov.calls["76-dungeon.lua:53"]=true; 
  local R = B.REWARDR
  local mult = (kind == "chief") and R.chief or ((kind == "boss") and R.boss or 1)
  return B.floor(R.gold_ref * B.floor_mult(floor).reward * mult + 0.5)
end

local function zone_title(info) B.__expe_cov.calls["76-dungeon.lua:59"]=true; 
  local Z = B.ZONES[info.zone]
  return B.T(Z.name) .. ((info.dk > 0) and B.U(" 심층 {n}", { n = info.dc }) or "")
end

-- 권장 레벨: 층 × 1.5(밸런스 측정의 기준 파티 — ENEMIES.md 「측정」, 4인) · 1~40
function B.dn_rec_lv(floor) B.__expe_cov.calls["76-dungeon.lua:65"]=true;  return math.max(1, math.min(B.LEVEL_MAX or 40, math.floor(floor * 1.5 + 0.5))) end
-- 추천 층(사장님 10-10 「적정 난이도 던전은 추천 표시」): 열린 층 가운데 파티 평균 레벨이 권장 레벨에 닿는 가장 깊은 층. 없으면 1층.
function B.dn_rec_floor(avg, mx) B.__expe_cov.calls["76-dungeon.lua:67"]=true; 
  local best = 1
  -- 상한(40)으로 자르지 않은 값으로 비교한다 — 깊은 층은 모두 「권장 Lv 40」이라 자른 값으로 고르면 늘 가장 깊은 층이 추천됐다
  for f = 1, math.max(1, mx) do B.__expe_cov.branches["76-dungeon.lua:70:3078"]=true;  if math.floor(f * 1.5 + 0.5) <= (tonumber(avg) or 1) + 0.0001 then B.__expe_cov.branches["76-dungeon.lua:70:3143"]=true;  best = f end end
  return best
end

-- ---------- 출정 화면: 대던전 카드 ----------
function B.dn_card(G) B.__expe_cov.calls["76-dungeon.lua:75"]=true; 
  local D = B.dn_G(G)
  local mx = B.dn_max(G)
  if D.sel > mx then B.__expe_cov.branches["76-dungeon.lua:78:3308"]=true;  D.sel = mx end
  local _, pn, avg = B.dn_party(G)
  local sel = B.dn_floor_view(D.sel, avg)
  local recf = B.dn_rec_floor(avg, mx)
  local lo = (D.pg - 1) * B.DN.PAGE + 1
  local pages = math.max(1, math.ceil((mx + 1) / B.DN.PAGE))
  if D.pg > pages then B.__expe_cov.branches["76-dungeon.lua:84:3563"]=true;  D.pg = pages; lo = (D.pg - 1) * B.DN.PAGE + 1 end
  local rows = {}
  for f = lo, math.min(lo + B.DN.PAGE - 1, mx + 1) do B.__expe_cov.branches["76-dungeon.lua:86:3687"]=true; 
    local v = B.dn_floor_view(f, avg)
    local ok = f <= mx
    local icon = (not ok) and "nd-locked" or ((f <= D.best) and "nd-done" or ((v.boss_kind == "boss") and "nd-boss" or "nd-elite"))
    local lead = (v.boss_kind == "boss") and B.U("구역 보스 {name}", { name = B.FOES[v.zone.boss].name }) or B.U("우두머리")
    local d = B.U("★{star}, 권장 Lv {rec}, 적 Lv {enemy}, 층 끝: {lead}", { star = v.star, rec = B.dn_rec_lv(f), enemy = v.el, lead = lead })
    if ok then B.__expe_cov.branches["76-dungeon.lua:92:4147"]=true; 
      rows[#rows + 1] = '<button type="button" class="dk-btn so-fl' .. (f == D.sel and " pick" or "") .. '" risu-btn="so_fl_' .. f .. '"><i class="im im-' .. icon .. ' so-nd"></i>' ..
        '<span class="t">' .. B.U("{floor}층 {zone}", { floor = f, zone = B.esc(zone_title(v.info)) }) .. '<span class="d">' .. B.esc(d) .. '</span></span>' ..
        (f == recf and ('<span class="dk-tag so-rec">' .. B.U("추천") .. '</span>') or '') ..
        (f <= D.best and ('<span class="dk-tag so-clr">' .. B.U("돌파") .. '</span>') or '') .. '</button>'
    else B.__expe_cov.branches["76-dungeon.lua:97:4697"]=true; 
      rows[#rows + 1] = '<div class="dk-btn so-fl off"><i class="im im-nd-locked so-nd"></i><span class="t">' .. B.U("{floor}층", { floor = f }) .. '<span class="d">' .. B.U("아래층의 보스를 쓰러뜨리면 열린다") .. '</span></span></div>'
    end
  end
  local nav = '<div class="dk-row so-pg">' ..
    B.btn("so_pg_" .. math.max(1, D.pg - 1), B.U("앞 쪽"), "sm" .. (D.pg <= 1 and " off" or "")) ..
    '<span class="dk-sub">' .. B.U("{page} / {pages} 쪽", { page = D.pg, pages = pages }) .. '</span>' ..
    B.btn("so_pg_" .. math.min(pages, D.pg + 1), B.U("다음 쪽"), "sm" .. (D.pg >= pages and " off" or "")) .. '</div>'
  local leadname = (sel.boss_kind == "boss") and B.T(B.FOES[sel.zone.boss].name) or B.U("우두머리(그 구역 정예를 키운 적)")
  local gold1 = B.dn_gold(D.sel, "battle")
  local gold2 = B.dn_gold(D.sel, sel.boss_kind)
  local detail = '<div class="dk-card gold so-dn"><div class="so-h"><span class="dk-title"><i class="im im-nd-boss so-nd"></i>' .. B.U("{floor}층 {zone}", { floor = D.sel, zone = B.esc(zone_title(sel.info)) }) ..
    '</span><span class="dk-sub">' .. B.U("{boss}가 층 끝을 지킨다", { boss = sel.boss_kind == "boss" and "구역 보스" or "우두머리" }) .. '</span></div>' ..
    '<div class="dk-sub">' .. B.U("입장 → 탐색 {steps}번(전투 70%, 발견 30%) → 휴식(HP +30%, 정비) → 층 끝 레이드 전투(4인, 상대는 {boss}). 전투가 이어져도 HP와 MP는 그대로다.", { steps = B.EX.STEPS, boss = B.esc(leadname) }) .. '</div>' ..
    '<div class="dk-row"><span class="dk-tag">' .. B.U("★{star}{deep}", { star = sel.star, deep = (sel.info.dk > 0) and B.U(" 심층") or "" }) .. '</span><span class="dk-tag so-elv">' .. B.U("적 Lv {lv}", { lv = sel.el }) ..
    '</span><span class="dk-tag">' .. B.U("보스 금화 {gold}", { gold = gold2 }) .. '</span><span class="dk-tag">' .. B.U("전투 한 번 금화 약 {gold}", { gold = B.floor(gold1 * B.EX.GOLD_BATTLE + 0.5) }) .. '</span></div>' ..
    '<div class="dk-sub so-recnote">' .. B.U("권장 Lv {rec}, 지금 파티 평균 Lv {avg}{mark}{extra}", { rec = B.dn_rec_lv(D.sel), avg = B.floor(avg * 10 + 0.5) / 10,
    mark = ((D.sel == recf) and B.U(" (<b>추천 층</b>)") or ((B.dn_rec_lv(D.sel) > avg + 0.0001) and B.U(" (버거울 수 있다)") or "")),
    extra = ((pn < 4) and B.U(". 추천은 4인 파티 기준이다(지금 {n}명). {tip}", { n = pn, tip = ((D.sel > 1) and B.U("한두 층 낮춰 보는 것이 안전하다") or B.U("길드에서 동료를 더 소개받아 4명을 채우는 것이 안전하다")) }) or "") }) .. '</div></div>'
  return '<div class="dk-card so-dnlist"><i class="im im-map-floor so-mapbg"></i><div class="so-h"><span class="dk-title"><i class="im im-rank so-rank-ic"></i>' .. B.U("대던전") .. '</span>' .. (B.rank_head and B.rank_head(G) or "") .. '<span class="dk-sub">' .. B.U("{best}층까지 도달 · 구역 보스 {bosses}개 처치 · 도전 {runs}회", { best = D.best, bosses = #D.cleared_bosses, runs = D.runs }) .. '</span></div><div class="so-fllist">' .. table.concat(rows) .. '</div>' .. nav .. '</div>' .. detail
end
