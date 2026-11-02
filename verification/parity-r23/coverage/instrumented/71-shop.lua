-- ===== 마렌토 상회(상점) : 소모품 구입 =====
-- 가격·효과는 전부 [제안] — DUNGEON.md 의 소모품(회복 · 부상 치료 · 귀환 두루마리)과 COMPANIONS.md 에 나온 해독약·붕대를 따랐다.
-- 효과는 원정 쪽 구현 때 연결한다(지금은 보유 개수만 센다). 장비는 EQUIPMENT.md 수치가 미확정이라 「준비 중」.
-- 🔴 물약 개편(사장님 10-10 「물약은 소중대로 레벨별 사용 제한 걸고 체력 마나 쉴드 3개 종류로」): 물약 = 체력(hp) · 마나(mp) · 보호막(sh) × 소(s) · 중(m) · 대(l) = 9종.
--   마시는 사람(전투 중엔 대상 아군)의 레벨이 크기의 최소 레벨 이상이어야 한다. 수치는 전부 [제안] — 한 곳(B.POTION)에서 고친다. 옛 칸 potion → hp_s · mana → mp_s 로 저장을 옮긴다(77-explore).
B.POTION = {
  sizes = { s = { name = "소형", lv = 1 }, m = { name = "중형", lv = 15 }, l = { name = "대형", lv = 30 } },
  kinds = {
    hp = { name = "회복약", frac = { s = 0.20, m = 0.35, l = 0.50 }, price = { s = 40, m = 90, l = 180 }, ic = "it-hp", what = "최대 HP" },
    mp = { name = "마나 물약", frac = { s = 0.15, m = 0.25, l = 0.40 }, price = { s = 50, m = 110, l = 220 }, ic = "it-mp", what = "최대 MP" },
    sh = { name = "보호막 물약", frac = { s = 0.15, m = 0.25, l = 0.40 }, price = { s = 60, m = 130, l = 260 }, ic = "defend", what = "최대 HP" },   -- 보호막 아이콘은 새 그림이 필요하다(지금은 ic_defend 를 빌린다)
  },
}
B.ITEMS = {
  antidote = { id = "antidote", name = "해독약", price = 30, d = "독이나 화상 같은 지속 상태를 지운다" },
  bandage = { id = "bandage", name = "붕대", price = 15, d = "쓰러진 동료를 최대 HP 의 25% 로 일으킨다" },
  scroll = { id = "scroll", name = "귀환 두루마리", price = 120, d = "원정 중 어느 지점에서든 거점으로 돌아온다 (원정당 1개)" },
}
B.SHOP = json.decode(B.SHOP_RAW)
B.ITEMS.level_scroll = { id = "level_scroll", name = "레벨업 스크롤", price = B.SHOP.level_scroll.price, d = "동료 한 명의 레벨을 1 올린다. Lv40까지." }
-- 매혹의 비약: 상점에서 팔지 않는다 — 피에트로 호감 50 이상이면 거래할 때마다 30% 로 덤이 나온다(B.shop_after_buy). 쓰는 곳은 대던전 휴식(79-sex B.sx_potion_*).
B.CHARM = { aff = 50, chance = 0.30, max = 99 }
B.ITEMS.charm_potion = { id = "charm_potion", name = "매혹의 비약", nosale = true, d = "함께 마시면 휴식 중 동료와 은밀한 시간을 보낼 수 있다. 상점에서는 팔지 않는다(피에트로의 덤)." }
B.ITEM_IC = { antidote = "it-cure", bandage = "it-band", scroll = "it-return", level_scroll = "it-scroll", charm_potion = "it-charm" }
B.ITEM_ORDER = {}
B.POTION_IDS = {}
for _, k in ipairs({ "hp", "mp", "sh" }) do B.__r23_cov.branches["71-shop.lua:27:2035"]=true; 
  for _, z in ipairs({ "s", "m", "l" }) do B.__r23_cov.branches["71-shop.lua:28:2078"]=true; 
    local K, Z = B.POTION.kinds[k], B.POTION.sizes[z]
    local id = k .. "_" .. z
    B.ITEMS[id] = { id = id, name = Z.name .. " " .. K.name, price = K.price[z], kind = k, size = z, lv = Z.lv,
      d = K.what .. "의 " .. math.floor(K.frac[z] * 100 + 0.5) .. "% " .. (k == "hp" and "를 되살린다" or (k == "mp" and "를 되살린다" or "만큼 보호막을 두른다(3턴)")) .. " (Lv " .. Z.lv .. "부터)" }
    B.ITEM_IC[id] = K.ic
    B.ITEM_ORDER[#B.ITEM_ORDER + 1] = id
    B.POTION_IDS[#B.POTION_IDS + 1] = id
  end
end
for _, id in ipairs({ "antidote", "bandage", "scroll", "level_scroll", "charm_potion" }) do B.__r23_cov.branches["71-shop.lua:38:2659"]=true;  B.ITEM_ORDER[#B.ITEM_ORDER + 1] = id end

function B.shop_stock(G, cls, slot) B.__r23_cov.calls["71-shop.lua:40"]=true; 
  local out, g = {}, B.gear()
  local day = (G.town and G.town.day) or 1
  local seed = (tonumber(G.seed) or 0) + day * 7919
  local ids = g.by[cls] and g.by[cls][slot] or {}
  for _, rarity in ipairs(B.SHOP.gear.rarities) do B.__r23_cov.branches["71-shop.lua:45:2963"]=true; 
    local pool = {}
    for _, gid in ipairs(ids) do B.__r23_cov.branches["71-shop.lua:47:3016"]=true;  if g.items[gid].rarity == rarity then B.__r23_cov.branches["71-shop.lua:47:3052"]=true;  pool[#pool + 1] = gid end end
    for j = 1, B.SHOP.gear.stock_per_slot do B.__r23_cov.branches["71-shop.lua:48:3129"]=true; 
      if #pool > 0 then B.__r23_cov.branches["71-shop.lua:49:3151"]=true; 
        local k = math.floor(B.ex_mix(seed, #cls + j, #slot, #out + 1) * #pool) + 1
        local gid = table.remove(pool, k)
        local code = B.gear_code(gid, math.floor(B.ex_mix(seed, #cls + j, #slot, #out + 31) * 1099511627776) + 1)
        out[#out + 1] = { code = code, item = g.items[gid], price = (g.fx.sell[rarity][1] + g.fx.sell[rarity][2] * g.fx.equip_lv[rarity]) * B.SHOP.gear.buy_multiplier }
      end
    end
  end
  return out
end

-- 장소 담당 NPC 얼굴 한 줄(작게). list = { {id, 이름, 역할}, ... }. 그림이 없는 사람은 뺀다 — 전부 없으면 빈 문자열.
-- 72-guild · 73-inn 의 머리 카드도 이 함수를 쓴다(71 이 먼저 올라온다).
-- 호감(G.npcs[id].aff)은 직함 줄 끝에 「 · 호감 N」으로 붙는다. 지금 그리는 장면의 G 는 B.NPC_G(79-sex 가 장면 화면을 감싸 심는다).
function B.tw_npcs(list) B.__r23_cov.calls["71-shop.lua:63"]=true; 
  local out = {}
  for _, n in ipairs(list) do B.__r23_cov.branches["71-shop.lua:65:3911"]=true; 
    local h = type(B.portrait) == "function" and B.portrait(n[1], "default") or nil
    if type(h) == "string" and h:sub(1, 1) == "<" then B.__r23_cov.branches["71-shop.lua:67:4048"]=true; 
      local like = (B.NPC_G and B.npc_aff) and (" · " .. B.U("호감 {n}", { n = B.npc_aff(B.NPC_G, n[1]) })) or ""
      out[#out + 1] = '<span class="tw-npc"><span class="dk-face tw-face sm">' .. h .. '</span><span class="tw-npc-t"><b>' ..
        B.esc(B.T(n[2])) .. '</b><span class="d">' .. B.esc(B.T(n[3])) .. like .. '</span></span></span>'
    end
  end
  if #out == 0 then B.__r23_cov.branches["71-shop.lua:73:4426"]=true;  return "" end
  return '<div class="tw-npcs">' .. table.concat(out) .. '</div>'
end

-- 값: 마렌토 출신이 편성에 2명 −6% · 3명 −12%(34-traits B.tx_shop · 사장님 10-10 출신 시너지는 전투 밖으로)
function B.shop_price(G, it) B.__r23_cov.calls["71-shop.lua:78"]=true; 
  local m = B.tx_shop and B.tx_shop(G) or 1
  return math.max(1, B.floor(it.price * m + 0.5))
end

B.SCREENS.shop = function(G, id) B.__r23_cov.calls["71-shop.lua:83"]=true; 
  local rows = {}
  local mul = B.tx_shop and B.tx_shop(G) or 1
  for _, iid in ipairs(B.ITEM_ORDER) do B.__r23_cov.branches["71-shop.lua:86:4861"]=true; 
    local it = B.ITEMS[iid]
    local own = (G.items and G.items[iid]) or 0
    if it.nosale then B.__r23_cov.branches["71-shop.lua:89:4957"]=true; 
      if own > 0 then B.__r23_cov.branches["71-shop.lua:90:4979"]=true;    -- 팔지 않는 물건(매혹의 비약): 가진 때만 줄이 보이고 구입 버튼은 없다
        rows[#rows + 1] = '<div class="dk-card tw-item"><div class="tw-item-h"><span class="dk-title tw-item-n">' .. B.T(it.name) ..
          '</span><span class="dk-tag">' .. B.U("보유 {n}", { n = own }) .. '</span></div><div class="dk-sub">' .. B.T(it.d) .. '</div></div>'
      end
    else B.__r23_cov.branches["71-shop.lua:94:5318"]=true; 
    local pr = B.shop_price(G, it)
    rows[#rows + 1] = '<div class="dk-card tw-item"><div class="tw-item-h"><span class="dk-title tw-item-n">' .. (B.ITEM_IC[iid] and ('<i class="im im-' .. B.ITEM_IC[iid] .. ' tw-iico"></i>') or '') .. B.T(it.name) ..
      '</span><span class="dk-tag">' .. B.U("보유 {n}", { n = own }) .. '</span></div><div class="dk-sub">' .. B.T(it.d) .. '</div>' ..
      '<div class="tw-item-f">' .. B.btn("sh_buy_" .. iid, B.U("구입"), "sm" .. ((G.gold or 0) < pr and " dim" or ""), B.U("금화 {n}", { n = pr })) .. (iid == "level_scroll" and B.btn("sh_scroll", B.U("사용"), "sm", B.U("보유 {n}", { n = own })) or "") .. '</div></div>'
    end
  end
  local extra = {}
  if G.ui.sel == "level_scroll" then B.__r23_cov.branches["71-shop.lua:102:6038"]=true; 
    extra[#extra + 1] = '<div class="dk-card"><div class="dk-title"><i class="im im-it-scroll tw-iico"></i>' .. B.U("레벨을 올릴 사람") .. '</div>'
    local owners = { "persona" }
    for _, cid in ipairs(G.roster or {}) do B.__r23_cov.branches["71-shop.lua:105:6258"]=true;  owners[#owners + 1] = cid end
    for _, cid in ipairs(owners) do B.__r23_cov.branches["71-shop.lua:106:6324"]=true; 
      local lv = B.lv_of(G, cid)
      if lv < 40 then B.__r23_cov.branches["71-shop.lua:108:6377"]=true;  extra[#extra + 1] = B.btn("sh_target_" .. cid, cid == "persona" and B.U("페르소나") or B.esc(B.T(B.tw_name(cid))), "sm", "Lv " .. lv) end
    end
    extra[#extra + 1] = '</div>'
  end
  local cl = G.ui.tab ~= "" and G.ui.tab or (G.persona and B.cls_of(G.persona.cls) and B.cls_of(G.persona.cls).id) or "warrior"
  if not B.gear().by[cl] then B.__r23_cov.branches["71-shop.lua:113:6716"]=true;  cl = "warrior" end
  local slot = ({ weapon = true, armor = true, acc = true })[G.shop_slot] and G.shop_slot or "weapon"
  extra[#extra + 1] = '<div class="dk-card"><div class="dk-title">' .. B.U("장비 진열") .. '</div><div class="dk-row">'
  for cls in pairs(B.gear().by) do B.__r23_cov.branches["71-shop.lua:116:6990"]=true;  extra[#extra + 1] = B.btn("sh_cls_" .. cls, B.esc(B.T(B.CLS[cls] and B.CLS[cls].name or cls)), "sm" .. (cls == cl and " on" or "")) end
  extra[#extra + 1] = '</div><div class="dk-row">'
  for _, s in ipairs({ "weapon", "armor", "acc" }) do B.__r23_cov.branches["71-shop.lua:118:7231"]=true;  extra[#extra + 1] = B.btn("sh_slot_" .. s, B.U(({ weapon = "무기", armor = "방어구", acc = "장신구" })[s]), "sm" .. (s == slot and " on" or "")) end
  extra[#extra + 1] = '</div></div>'
  local stock = B.shop_stock(G, cl, slot)
  local bought = type(G.shop_stock) == "table" and G.shop_stock.day == ((G.town and G.town.day) or 1) and G.shop_stock.bought or {}
  for i, v in ipairs(stock) do B.__r23_cov.branches["71-shop.lua:122:7614"]=true; 
    local lv = B.gear().fx.equip_lv[v.item.rarity]
    if lv <= B.gd_base_lv(G) then B.__r23_cov.branches["71-shop.lua:124:7697"]=true; 
      local sold = bought[v.code]
      local price = B.shop_price(G, { price = v.price })
      extra[#extra + 1] = '<div class="dk-card tw-item"><span class="dk-title">' .. B.esc(B.T(v.item.name)) .. '</span> <span class="dk-tag">Lv ' .. lv .. '</span>' .. B.btn("sh_gear_" .. i, sold and B.U("품절") or B.U("구입"), "sm" .. (sold and " dim" or ""), B.U("금화 {n}", { n = price })) .. '</div>'
    end
  end
  return '<div class="dk-card gold">' .. B.tw_hd("pl-shop", B.U("마렌토 상회")) ..
    '<div class="dk-text">' .. B.U("심연 재료를 사들이고 유물을 경매에 부치는 상관이다. 입구 쪽 진열대에는 약방에서 받아 온 보급품이 줄지어 있다.") .. '</div>' ..
    B.tw_npcs({ { "pietro", "피에트로", "토르바 지배인" } }) .. '</div>' ..
    ((mul < 1) and B.tw_hint(B.U("마렌토 출신이 편성에 있어 모든 값이 {pct}% 싸다.", { pct = B.floor((1 - mul) * 100 + 0.5) })) or "") ..
    '<div class="tw-items">' .. table.concat(rows) .. '</div>' ..
    table.concat(extra) ..
    '<div class="dk-row">' .. B.btn("sh_back", B.U("토르바로 돌아가기"), "sm") .. '</div>'
end

-- 구입 한 번이 끝난 뒤(사장님 10-13): 피에트로 호감 +1 · 호감이 50 이상이었다면 30% 로 매혹의 비약 덤 1개.
-- 확률은 (피에트로와 거래한 횟수, 계정 씨앗) 으로만 정한다 — 같은 거래 순서면 같은 결과(되돌려 다시 사도 같다). 호감은 거래 전 값으로 본다.
function B.shop_after_buy(G) B.__r23_cov.calls["71-shop.lua:141"]=true; 
  local st = B.sx_npcst(G, "pietro")
  local aff0 = st.aff
  st.buys = math.floor(tonumber(st.buys) or 0) + 1
  B.npc_like(G, "pietro")
  if aff0 >= B.CHARM.aff and B.ex_mix(tonumber(G.seed) or 0, 9157, st.buys, 3) < B.CHARM.chance then B.__r23_cov.branches["71-shop.lua:146:9091"]=true; 
    if type(G.items) ~= "table" then B.__r23_cov.branches["71-shop.lua:147:9128"]=true;  G.items = {} end
    if (tonumber(G.items.charm_potion) or 0) < B.CHARM.max then B.__r23_cov.branches["71-shop.lua:148:9209"]=true; 
      G.items.charm_potion = (tonumber(G.items.charm_potion) or 0) + 1
      G.ui.msg = (G.ui.msg or "") .. " " .. B.U("피에트로가 덤으로 「{item}」 하나를 슬쩍 얹어 주었다. (보유 {n})", { item = B.ITEMS.charm_potion.name, n = G.items.charm_potion })
    end
  end
end

B.H.sh = function(G, arg, id) B.__r23_cov.calls["71-shop.lua:155"]=true; 
  if G.scene ~= "shop" then B.__r23_cov.branches["71-shop.lua:156:9515"]=true;  return end
  local cls = arg:match("^cls_(.+)$")
  if cls and B.gear().by[cls] then B.__r23_cov.branches["71-shop.lua:158:9599"]=true;  G.ui.tab = cls; return end
  local slot = arg:match("^slot_(.+)$")
  if slot and ({ weapon = true, armor = true, acc = true })[slot] then B.__r23_cov.branches["71-shop.lua:160:9737"]=true;  G.shop_slot = slot; return end
  if arg == "scroll" then B.__r23_cov.branches["71-shop.lua:161:9794"]=true;  G.ui.sel = "level_scroll"; return end
  local target = arg:match("^target_(.+)$")
  if target then B.__r23_cov.branches["71-shop.lua:163:9893"]=true; 
    if (G.items.level_scroll or 0) < 1 then B.__r23_cov.branches["71-shop.lua:164:9937"]=true;  G.ui.msg = B.U("레벨업 스크롤이 없습니다. 먼저 구입하세요."); return end
    if G.ui.sel ~= "level_scroll" or (target ~= "persona" and not B.has(G.roster, target)) or B.lv_of(G, target) >= 40 then B.__r23_cov.branches["71-shop.lua:165:10116"]=true;  return end
    local lv = B.lv_of(G, target) + 1
    if target == "persona" then B.__r23_cov.branches["71-shop.lua:167:10197"]=true;  G.persona.lv, G.persona.exp, G.lv = lv, 0, lv else B.__r23_cov.branches["71-shop.lua:167:10248"]=true;  G.lvl[target], G.exp[target] = lv, 0 end
    G.items.level_scroll = G.items.level_scroll - 1
    G.ui.sel = ""
    G.ui.msg = B.U("레벨이 올랐습니다. Lv {lv}.", { lv = lv })
    return
  end
  local gi = tonumber(arg:match("^gear_(%d+)$"))
  if gi then B.__r23_cov.branches["71-shop.lua:174:10493"]=true; 
    local cl = G.ui.tab ~= "" and G.ui.tab or (G.persona and B.cls_of(G.persona.cls) and B.cls_of(G.persona.cls).id) or "warrior"
    local v = B.shop_stock(G, cl, G.shop_slot or "weapon")[gi]
    local day = (G.town and G.town.day) or 1
    if not v then B.__r23_cov.branches["71-shop.lua:178:10749"]=true;  return end
    local price = B.shop_price(G, { price = v.price })
    if B.gear().fx.equip_lv[v.item.rarity] > B.gd_base_lv(G) or (G.gold or 0) < price then B.__r23_cov.branches["71-shop.lua:180:10906"]=true;  return end
    if type(G.shop_stock) ~= "table" or G.shop_stock.day ~= day then B.__r23_cov.branches["71-shop.lua:181:10986"]=true;  G.shop_stock = { day = day, bought = {} } end
    if G.shop_stock.bought[v.code] or not B.bag_add(id, v.code) then B.__r23_cov.branches["71-shop.lua:182:11101"]=true;  return end
    G.shop_stock.bought[v.code] = true
    G.gold = G.gold - price
    G.shop_got = type(G.shop_got) == "table" and G.shop_got or {}
    G.shop_got[v.code] = (G.shop_got[v.code] or 0) + 1
    G.ui.msg = B.U("장비를 샀습니다: {item}", { item = v.item.name })
    B.shop_after_buy(G)
    return
  end
  if arg == "back" then B.__r23_cov.branches["71-shop.lua:191:11428"]=true; 
    G.scene = "town"
    -- 🔴 산 것이 있으면 상회를 나서는 장면을 대화로 한 번 잇는다(사장님 10-10 「장비를 구매하고 나오면 창이 잠기고 대화」)
    if type(G.shop_got) == "table" and next(G.shop_got) then B.__r23_cov.branches["71-shop.lua:194:11588"]=true; 
      local ids = {}
      for iid in pairs(G.shop_got) do B.__r23_cov.branches["71-shop.lua:196:11649"]=true;  ids[#ids + 1] = iid end
      table.sort(ids)
      local got = {}
      for _, iid in ipairs(ids) do B.__r23_cov.branches["71-shop.lua:199:11751"]=true; 
        local gr = B.gear_roll(iid)
        got[#got + 1] = B.C1_en((B.ITEMS[iid] and B.ITEMS[iid].name) or (gr and gr.item.name) or iid) .. " x" .. G.shop_got[iid]
      end
      B.pend_hard(G, "[Shop purchase confirmed] {{user}} bought " .. table.concat(got, ", ") .. " at Marento Trading House and left with " .. (G.gold or 0) ..
        " gold. Write a brief exchange with the manager Pietro and the departure. Do not change the prices or items.", id, B.U("(마렌토 상회에서 물건을 사고 나선다)"))
    end
    G.shop_got = nil
    return
  end
  local iid = arg:match("^buy_(.+)$")
  local it = iid and B.ITEMS[iid]
  if not it or it.slot or it.nosale then B.__r23_cov.branches["71-shop.lua:211:12395"]=true;  return end   -- 장비(slot 이 있는 것)는 상점에서 팔지 않는다 — 탐색에서 발견한다(77-explore)
  local pr = B.shop_price(G, it)
  if (G.gold or 0) < pr then B.__r23_cov.branches["71-shop.lua:213:12526"]=true; 
    G.ui.msg = B.U("금화가 모자랍니다. {item} 값은 {price}, 가진 금화는 {gold}.", { item = it.name, price = pr, gold = G.gold or 0 })
    return
  end
  G.gold = G.gold - pr
  if type(G.items) ~= "table" then B.__r23_cov.branches["71-shop.lua:218:12720"]=true;  G.items = {} end
  G.items[iid] = (G.items[iid] or 0) + 1
  if type(G.shop_got) ~= "table" then B.__r23_cov.branches["71-shop.lua:220:12816"]=true;  G.shop_got = {} end
  G.shop_got[iid] = (G.shop_got[iid] or 0) + 1
  G.ui.msg = B.U("{item} 하나를 샀습니다. (보유 {n}, 남은 금화 {gold})", { item = it.name, n = G.items[iid], gold = G.gold })
  B.shop_after_buy(G)
end
