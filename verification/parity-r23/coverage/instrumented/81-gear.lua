-- ===== 장비 1,030종 = 1,000종 + 새 전설 장신구 30종 (design/gear.json · gear_effects.json) =====
-- 데이터는 build.py 가 B.GEAR_RAW(압축 JSON 한 줄)로 05-gen.lua 에 넣는다. B.gear() 가 처음 부를 때 한 번 풀어 캐시한다.
-- 항목 = 직업 10 × 100칸. 칸·등급·레벨은 직업 공통 틀(d.pat), id 는 접두(d.px)+번호, base 키는 d.bk[직업][칸] · 값은 d.bv[칸번호][번호] — build.py gen_gear 참고.
-- 한 줄 = { 이름, 모양번호, base 값 번호, [전설: { key, p, x, n, 이름, 짧은 글 }] }
-- 새 전설 장신구 30종(2026-10-10, 직업마다 Lv20·30·40) 은 틀 밖이라 d.la 에 따로 둔다: { 직업 번호, 레벨, cap, 이름, 모양 번호, stat, 효과 키, 수치 배열, 고유 효과 이름, 짧은 글, eff }
-- id = 직업 접두 + "l" + 레벨/10 (예: wal2). 고유 효과는 it.unique = { key, v, name, text, sig = true, e = eff }.
do B.__r23_cov.branches["81-gear.lua:7:617"]=true; 
  local cache
  B.GEAR_VERSIONS = {}

  function B.gear() B.__r23_cov.calls["81-gear.lua:11"]=true; 
    if cache then B.__r23_cov.branches["81-gear.lua:12:691"]=true;  return cache end
    local d = json.decode(B.GEAR_RAW)
    local fx = d.fx
    local items, order, by = {}, {}, {}
    local shape_css = {}
    for _, sh in ipairs(d.sh) do B.__r23_cov.branches["81-gear.lua:17:866"]=true;  shape_css[sh] = "gear-" .. sh:gsub("_", "-") end
    for ci, cls in ipairs(d.cl) do B.__r23_cov.branches["81-gear.lua:18:950"]=true; 
      local c = {}
      by[cls] = c
      for k, r in ipairs(d.it[ci]) do B.__r23_cov.branches["81-gear.lua:21:1025"]=true; 
        local p = d.pat[k]
        local slot = d.sl[p[1] + 1]
        local keys, base = d.bk[cls][slot], {}
        local vals = d.bv[k][r[3] + 1]
        for j, key in ipairs(keys) do B.__r23_cov.branches["81-gear.lua:26:1212"]=true;  base[key] = vals[j] end
        local it = { id = d.px[ci] .. string.format("%02d", k % 100), cls = cls, slot = slot, rarity = d.ra[p[2] + 1], lv = p[3], name = r[1], shape = d.sh[r[2] + 1], base = base }
        local u = r[4]
        if u then B.__r23_cov.branches["81-gear.lua:29:1456"]=true; 
          local t = fx.proc[u[1]].text
          t = t:gsub("{p}", tostring(u[2])):gsub("{x}", tostring(u[3])):gsub("{n}", tostring(u[4]))
          it.unique = { key = u[1], p = u[2], x = u[3], n = u[4], name = u[5], text = t }
          it.flavor = u[6]
        end
        items[it.id] = it
        order[#order + 1] = it.id
        local s = c[slot]
        if not s then B.__r23_cov.branches["81-gear.lua:38:1832"]=true;  s = {}; c[slot] = s end
        s[#s + 1] = it.id
      end
    end
    for _, r in ipairs(d.la or {}) do B.__r23_cov.branches["81-gear.lua:42:1940"]=true; 
      local v = r[8]
      local t = fx.sig[r[7]].text:gsub("{(%d)}", function(k) B.__r23_cov.calls["81-gear.lua:44"]=true;  return tostring(v[tonumber(k)]) end)
      local it = { id = d.px[r[1] + 1] .. "l" .. string.format("%d", r[2] // 10), cls = d.cl[r[1] + 1], slot = "acc", rarity = "legend", lv = r[2], cap = r[3], name = r[4], shape = d.sh[r[5] + 1], base = { stat = r[6] } }
      it.unique = { key = r[7], v = v, name = r[9], text = t, sig = true, e = r[11] }
      if r[10] ~= "" then B.__r23_cov.branches["81-gear.lua:47:2391"]=true;  it.flavor = r[10] end
      items[it.id] = it
      order[#order + 1] = it.id
      local c = by[it.cls]
      c.acc[#c.acc + 1] = it.id
    end
    local gl = {}
    for _, id in ipairs(B.GEAR_GL or {}) do B.__r23_cov.branches["81-gear.lua:54:2600"]=true;  gl[id] = true end
    B.GEAR_VERSIONS[d.v] = true   -- 지원하는 표 버전(코드의 세 번째 칸). 표를 새로 낼 때 옛 버전을 여기 남기면 옛 코드도 읽힌다
    cache = { v = d.v, items = items, order = order, by = by, pools = d.pools, range = d.ar, fx = fx, shape_css = shape_css, gl = gl }
    return cache
  end

  -- 화면에 쓸 그림 클래스 이름(.im-<이름>): 전설 전용 그림이 있으면 gl-<id>, 아니면 모양 그림 gear-<모양>
  function B.gear_icon(item) B.__r23_cov.calls["81-gear.lua:61"]=true; 
    local g = B.gear()
    if g.gl[item.id] then B.__r23_cov.branches["81-gear.lua:63:3021"]=true;  return "gl-" .. item.id end
    return g.shape_css[item.shape]
  end
end

-- ===== 인스턴스 코드 · 씨앗 옵션 · 20% 상한 · 판매가 =====
-- 코드 "<id>.<씨앗 36진>.<표 버전>" 한 줄이 장비 한 개다. 옵션은 코드에서 매번 같은 값으로 다시 계산한다(저장하지 않는다).
do B.__r23_cov.branches["81-gear.lua:70:3227"]=true; 
  local DIGITS = "0123456789abcdefghijklmnopqrstuvwxyz"

  local function to36(n) B.__r23_cov.calls["81-gear.lua:73"]=true; 
    if n == 0 then B.__r23_cov.branches["81-gear.lua:74:3326"]=true;  return "0" end
    local s = ""
    while n > 0 do B.__r23_cov.branches["81-gear.lua:76:3379"]=true; 
      local d = n % 36
      s = DIGITS:sub(d + 1, d + 1) .. s
      n = n // 36
    end
    return s
  end

  local function round1(x) B.__r23_cov.calls["81-gear.lua:84"]=true;  return math.floor(x * 10 + 0.5) / 10 end

  function B.gear_code(id, seed) B.__r23_cov.calls["81-gear.lua:86"]=true; 
    local n = (math.tointeger(math.floor(math.abs(tonumber(seed) or 0))) or 0) % 4738381338321616896   -- 36^12 — 12자리 안에 담는다
    return id .. "." .. to36(n) .. "." .. B.gear().v
  end

  -- 코드 → id, 씨앗(정수), 표 버전. 형식이 틀리면 nil.
  function B.gear_parse(code) B.__r23_cov.calls["81-gear.lua:92"]=true; 
    if type(code) ~= "string" then B.__r23_cov.branches["81-gear.lua:93:3880"]=true;  return nil end
    local id, s, v = code:match("^([a-z0-9]+)%.([0-9a-z]+)%.([0-9]+)$")
    if not id or #s > 12 then B.__r23_cov.branches["81-gear.lua:95:3997"]=true;  return nil end
    B.gear()   -- 지원 버전 목록(B.GEAR_VERSIONS)을 채운다
    if not B.GEAR_VERSIONS[tonumber(v)] then B.__r23_cov.branches["81-gear.lua:97:4106"]=true;  return nil end   -- 모르는 표 버전의 코드는 받지 않는다
    return id, tonumber(s, 36), tonumber(v)
  end

  -- 고유 효과의 점수(gear_check.py unique_score 와 같다)
  local function unique_score(u, proc) B.__r23_cov.calls["81-gear.lua:102"]=true; 
    if u.sig then B.__r23_cov.branches["81-gear.lua:103:4303"]=true;  return u.e end   -- 새 전설 장신구: 측정한 효율(bot/legacc_eff.mjs)
    local rule = proc[u.key]
    if rule.k and rule.k ~= 0 then B.__r23_cov.branches["81-gear.lua:105:4424"]=true;  return u.p * u.x * math.max(u.n, 1) * rule.k end
    return u.x * (rule.flat_eff or 0)
  end

  function B.gear_roll(code, wearer_lv, forge_lv) B.__r23_cov.calls["81-gear.lua:109"]=true; 
    local id, seed, v = B.gear_parse(code)
    if not id then B.__r23_cov.branches["81-gear.lua:111:4630"]=true;  return nil end
    local g = B.gear()
    local item = g.items[id]
    if not item then B.__r23_cov.branches["81-gear.lua:114:4718"]=true;  return nil end
    local fx = g.fx
    local mix = B.ex_mix
    local pool = {}
    for i, k in ipairs(g.pools[item.cls][item.slot]) do B.__r23_cov.branches["81-gear.lua:118:4856"]=true;  pool[i] = k end
    local lvm = 0.4 + 0.6 * item.lv / 40
    local n = math.min(fx.rarity[item.rarity].affix, #pool)
    local affix, raw = {}, 0
    for i = 1, n do B.__r23_cov.branches["81-gear.lua:122:5022"]=true; 
      local j = i + math.floor(mix(seed, 1, i, 0) * (#pool - i + 1))   -- 겹치지 않게 뽑기(부분 섞기)
      pool[i], pool[j] = pool[j], pool[i]
      local key = pool[i]
      local rg = g.range[key]
      local val = rg[1] + (rg[2] - rg[1]) * mix(seed, 2, i, 0) * lvm
      affix[i] = { key, val }
      raw = raw + val * fx.affix[key].eff
    end
    local fixed = 0
    for k, val in pairs(item.base) do B.__r23_cov.branches["81-gear.lua:132:5418"]=true;  fixed = fixed + val * fx.base[k].eff end
    if item.unique then B.__r23_cov.branches["81-gear.lua:133:5481"]=true;  fixed = fixed + unique_score(item.unique, fx.proc) end
    local function settle(scale) B.__r23_cov.calls["81-gear.lua:134"]=true; 
      local out, score = {}, fixed
      for k, val in pairs(item.base) do B.__r23_cov.branches["81-gear.lua:136:5646"]=true;  out[k] = val end
      for i = 1, n do B.__r23_cov.branches["81-gear.lua:137:5685"]=true; 
        local a = affix[i]
        local val = scale and math.floor(a[2] * scale * 10) / 10 or round1(a[2])   -- 깎을 때는 내림 — 반올림이 상한을 다시 넘기지 않게
        a[2] = val
        out[a[1]] = (out[a[1]] or 0) + val
        score = score + val * fx.affix[a[1]].eff
      end
      return out, score
    end
    local raws = {}
    for i = 1, n do B.__r23_cov.branches["81-gear.lua:147:6021"]=true;  raws[i] = affix[i][2] end
    local out, score = settle(nil)
    local cap = item.cap or fx.cap   -- 새 전설 장신구 30종만 항목마다 상한(20·30·35)
    if score > cap + 1e-9 then B.__r23_cov.branches["81-gear.lua:150:6183"]=true;    -- 🔴 부위 효율 상한: base·고유는 그대로 두고 옵션 값만 비율로 깎는다
      for i = 1, n do B.__r23_cov.branches["81-gear.lua:151:6254"]=true;  affix[i][2] = raws[i] end
      local room = cap - fixed
      out, score = settle(room > 0 and room / raw or 0)
    end
    if wearer_lv then B.__r23_cov.branches["81-gear.lua:155:6395"]=true; 
      local level = math.max(1, math.min(40, math.floor(tonumber(wearer_lv) or 1)))
      local scale = (0.4 + 0.6 * level / 40) / (0.4 + 0.6 * item.lv / 40)
      scale = scale * (1 + (math.max(0, math.min(10, tonumber(forge_lv) or 0))) * fx.forge.bonus_per_level)
      for k, val in pairs(out) do B.__r23_cov.branches["81-gear.lua:159:6697"]=true;  out[k] = round1(val * scale) end
      for _, a in ipairs(affix) do B.__r23_cov.branches["81-gear.lua:160:6765"]=true;  a[2] = round1(a[2] * scale) end
      score = score * scale
    end
    return { id = id, item = item, lv = fx.equip_lv[item.rarity], slot = item.slot, rarity = item.rarity, fx = out, affix = affix, unique = item.unique, score = score, v = v, seed = seed }
  end

  -- 판매가(금화): gear_effects.sell[등급] = { 기본, 레벨당 }
  function B.gear_price(code) B.__r23_cov.calls["81-gear.lua:167"]=true; 
    local id = B.gear_parse(code)
    local item = id and B.gear().items[id]
    if not item then B.__r23_cov.branches["81-gear.lua:170:7205"]=true;  return nil end
    local s = B.gear().fx.sell[item.rarity]
    return s[1] + s[2] * item.lv
  end
end

-- ===== 가방(dk_bag) · 장착 · 해제 · 판매 =====
-- 가방 = 채팅 변수 dk_bag 에 코드를 ";" 로 이은 문자열 하나(빈 문자열 = 빈 가방). dk_game 과 따로 둔다. 장착 칸은 G.equip[cid][칸] = 코드.
do B.__r23_cov.branches["81-gear.lua:178:7457"]=true; 
  B.BAG_KEY, B.BAG_MAX = "dk_bag", 2000

  function B.bag_load(id) B.__r23_cov.calls["81-gear.lua:181"]=true; 
    local ok, raw = pcall(getChatVar, id, B.BAG_KEY)
    local out = {}
    if ok and type(raw) == "string" then B.__r23_cov.branches["81-gear.lua:184:7635"]=true; 
      -- 🔴 리수는 한 번도 안 쓴 채팅 변수를 문자열 "null" 로 준다 — 그대로 넣으면 빈 가방이 「1 / 2000」이 되고, 넣을 때 "null;코드"로 저장돼
      --    클라우드 검증에서 거절된다(실기 10-11). 알려진 장비 코드만 받는다.
      local items = B.gear().items
      for c in raw:gmatch("[^;]+") do B.__r23_cov.branches["81-gear.lua:188:7863"]=true; 
        local gid = B.gear_parse(c)
        if gid and items[gid] then B.__r23_cov.branches["81-gear.lua:190:7932"]=true;  out[#out + 1] = c end
      end
    end
    return out
  end

  function B.bag_save(id, list) B.__r23_cov.calls["81-gear.lua:196"]=true; 
    setChatVar(id, B.BAG_KEY, table.concat(list, ";"))
  end

  -- 버튼 값에는 "." 을 쓰지 않는다(버튼 값 규칙 [a-z_0-9]) — 코드의 "." 를 "_" 로 바꿔 싣고, 돌아와서 되돌린다
  function B.gear_btn(code) B.__r23_cov.calls["81-gear.lua:201"]=true;  return (code:gsub("%.", "_")) end
  function B.gear_unbtn(s) B.__r23_cov.calls["81-gear.lua:202"]=true; 
    local id, seed, v = s:match("^([a-z0-9]+)_([0-9a-z]+)_([0-9]+)$")
    return id and (id .. "." .. seed .. "." .. v) or nil
  end

  function B.bag_add(id, code) B.__r23_cov.calls["81-gear.lua:207"]=true; 
    local list = B.bag_load(id)
    if #list >= B.BAG_MAX or not B.gear_parse(code) then B.__r23_cov.branches["81-gear.lua:209:8510"]=true;  return false end
    list[#list + 1] = code
    B.bag_save(id, list)
    return true
  end

  function B.bag_take(id, code) B.__r23_cov.calls["81-gear.lua:215"]=true; 
    local list = B.bag_load(id)
    for i, c in ipairs(list) do B.__r23_cov.branches["81-gear.lua:217:8700"]=true; 
      if c == code then B.__r23_cov.branches["81-gear.lua:218:8722"]=true; 
        table.remove(list, i)
        B.bag_save(id, list)
        return true
      end
    end
    return false
  end

  -- 직업 id: 페르소나 G.persona.cls(이름이거나 id) · 동료 B.CAST[cid].cls
  local function cls_id(G, cid) B.__r23_cov.calls["81-gear.lua:228"]=true; 
    local raw
    if cid == "persona" then B.__r23_cov.branches["81-gear.lua:230:8980"]=true;  raw = G.persona and G.persona.cls
    else B.__r23_cov.branches["81-gear.lua:231:9023"]=true;  raw = B.CAST[cid] and B.CAST[cid].cls end
    local c = raw and B.cls_of(raw)
    return c and c.id or nil
  end

  function B.gear_can_equip(G, cid, code) B.__r23_cov.calls["81-gear.lua:236"]=true; 
    local r = B.gear_roll(code)
    if not r then B.__r23_cov.branches["81-gear.lua:238:9229"]=true;  return false, "알 수 없는 장비입니다." end
    local c = cls_id(G, cid)
    if not c then B.__r23_cov.branches["81-gear.lua:240:9310"]=true;  return false, "직업을 알 수 없습니다." end
    if r.item.cls ~= c then B.__r23_cov.branches["81-gear.lua:241:9372"]=true;  return false, "다른 직업 전용 장비입니다." end
    local lv = B.lv_of(G, cid)
    if r.lv > lv then B.__r23_cov.branches["81-gear.lua:243:9461"]=true;  return false, "Lv " .. r.lv .. "부터 낄 수 있습니다." end
    return true
  end

  function B.gear_restrict(G, id) B.__r23_cov.calls["81-gear.lua:247"]=true; 
    if type(G.equip) ~= "table" then B.__r23_cov.branches["81-gear.lua:248:9605"]=true;  return end
    local changed = false
    for cid, eq in pairs(G.equip) do B.__r23_cov.branches["81-gear.lua:250:9681"]=true; 
      if type(eq) == "table" then B.__r23_cov.branches["81-gear.lua:251:9713"]=true; 
        for _, slot in ipairs({ "weapon", "armor", "acc" }) do B.__r23_cov.branches["81-gear.lua:252:9778"]=true; 
          local code = eq[slot]
          if type(code) == "string" and code ~= "" and not B.gear_can_equip(G, cid, code) then B.__r23_cov.branches["81-gear.lua:254:9903"]=true; 
            if B.bag_add(id, code) then B.__r23_cov.branches["81-gear.lua:255:9943"]=true;  eq[slot] = ""; changed = true end
          end
        end
      end
    end
    return changed
  end

  function B.forge_state(G, code) B.__r23_cov.calls["81-gear.lua:263"]=true; 
    G.forge = type(G.forge) == "table" and G.forge or {}
    local f = G.forge[code]
    if type(f) ~= "table" then B.__r23_cov.branches["81-gear.lua:266:10197"]=true;  f = { lv = 0, tries = 0 }; G.forge[code] = f end
    return f
  end

  function B.forge_cost(code, next_lv) B.__r23_cov.calls["81-gear.lua:270"]=true; 
    local id = B.gear_parse(code)
    local it = id and B.gear().items[id]
    local base = it and B.gear().fx.forge.cost_base[it.rarity]
    if not base or next_lv < 1 or next_lv > 10 then B.__r23_cov.branches["81-gear.lua:274:10495"]=true;  return nil end
    return base * next_lv * next_lv
  end

  function B.forge_try(G, id, code) B.__r23_cov.calls["81-gear.lua:278"]=true; 
    local in_bag = false
    for _, c in ipairs(B.bag_load(id)) do B.__r23_cov.branches["81-gear.lua:280:10658"]=true;  if c == code then B.__r23_cov.branches["81-gear.lua:280:10674"]=true;  in_bag = true; break end end
    if not in_bag then B.__r23_cov.branches["81-gear.lua:281:10726"]=true; 
      for _, eq in pairs(G.equip or {}) do B.__r23_cov.branches["81-gear.lua:282:10771"]=true; 
        if type(eq) == "table" then B.__r23_cov.branches["81-gear.lua:283:10805"]=true; 
          for _, slot in ipairs({ "weapon", "armor", "acc" }) do B.__r23_cov.branches["81-gear.lua:284:10872"]=true;  if eq[slot] == code then B.__r23_cov.branches["81-gear.lua:284:10895"]=true;  in_bag = true end end
        end
      end
    end
    if not in_bag or not B.gear_roll(code) then B.__r23_cov.branches["81-gear.lua:288:10995"]=true;  return nil, "장비를 찾을 수 없습니다." end
    local f = B.forge_state(G, code)
    if f.lv >= 10 then B.__r23_cov.branches["81-gear.lua:290:11088"]=true;  return nil, "이미 +10입니다." end
    local next_lv = f.lv + 1
    local cost = B.forge_cost(code, next_lv)
    if (G.gold or 0) < cost then B.__r23_cov.branches["81-gear.lua:293:11224"]=true;  return nil, "금화가 모자랍니다." end
    local code_key = 0
    for i = 1, #code do B.__r23_cov.branches["81-gear.lua:295:11302"]=true;  code_key = (code_key * 131 + code:byte(i)) % 2147483647 end
    local roll = B.ex_mix((tonumber(G.seed) or 0) + code_key, f.tries + 1, next_lv, 41)
    local success = roll * 100 < B.gear().fx.forge.success[next_lv]
    G.gold = G.gold - cost
    f.tries = f.tries + 1
    if success then B.__r23_cov.branches["81-gear.lua:300:11589"]=true;  f.lv = next_lv end
    return success, cost
  end

  function B.gear_equip(G, id, cid, code) B.__r23_cov.calls["81-gear.lua:304"]=true; 
    local ok, why = B.gear_can_equip(G, cid, code)
    if not ok then B.__r23_cov.branches["81-gear.lua:306:11752"]=true;  return false, why end
    local slot = B.gear_roll(code).slot
    if type(G.equip) ~= "table" then B.__r23_cov.branches["81-gear.lua:308:11851"]=true;  G.equip = {} end
    G.equip[cid] = G.equip[cid] or {}
    local eq = G.equip[cid]
    if not B.bag_take(id, code) then B.__r23_cov.branches["81-gear.lua:311:11971"]=true;  return false, "가방에 없는 장비입니다." end
    local old = eq[slot]
    eq[slot] = code
    if type(old) == "string" and old ~= "" then B.__r23_cov.branches["81-gear.lua:314:12098"]=true;  B.bag_add(id, old) end   -- 방금 한 칸을 비웠으니 들어간다
    return true
  end

  function B.gear_unequip(G, id, cid, slot) B.__r23_cov.calls["81-gear.lua:318"]=true; 
    local eq = G.equip and G.equip[cid]
    local cur = eq and eq[slot]
    if type(cur) ~= "string" or cur == "" then B.__r23_cov.branches["81-gear.lua:321:12330"]=true;  return false, "끼고 있는 장비가 없습니다." end
    if not B.bag_add(id, cur) then B.__r23_cov.branches["81-gear.lua:322:12401"]=true;  return false, "가방이 가득 찼습니다." end
    eq[slot] = ""
    return true
  end

  function B.gear_sell(G, id, code) B.__r23_cov.calls["81-gear.lua:327"]=true; 
    local p = B.gear_price(code)
    if not p then B.__r23_cov.branches["81-gear.lua:329:12562"]=true;  return false end
    if not B.bag_take(id, code) then B.__r23_cov.branches["81-gear.lua:330:12616"]=true;  return false end
    G.gold = (G.gold or 0) + p
    return true, p
  end

  -- 일반(common) 등급 전부 판매 → 판 개수, 번 금화
  function B.gear_sell_common(G, id) B.__r23_cov.calls["81-gear.lua:336"]=true; 
    local list, keep, n, gold = B.bag_load(id), {}, 0, 0
    local items = B.gear().items
    for _, c in ipairs(list) do B.__r23_cov.branches["81-gear.lua:339:12889"]=true; 
      local gid = B.gear_parse(c)
      local it = gid and items[gid]
      if it and it.rarity == "common" then B.__r23_cov.branches["81-gear.lua:342:13000"]=true; 
        n = n + 1
        gold = gold + B.gear_price(c)
      else B.__r23_cov.branches["81-gear.lua:345:13067"]=true; 
        keep[#keep + 1] = c
      end
    end
    if n > 0 then B.__r23_cov.branches["81-gear.lua:349:13131"]=true; 
      B.bag_save(id, keep)
      G.gold = (G.gold or 0) + gold
    end
    return n, gold
  end

  -- 옛 저장 이주: 능력치 없던 시제품 24종(eq_*)을 비운다. 저장마다 한 번만(G.settings.gear_v) — 바꾼 게 있으면 true.
  function B.gear_migrate(G) B.__r23_cov.calls["81-gear.lua:357"]=true; 
    if type(G.settings) ~= "table" or G.settings.gear_v then B.__r23_cov.branches["81-gear.lua:358:13405"]=true;  return false end
    G.settings.gear_v = 1
    local hit = false
    if type(G.equip) == "table" then B.__r23_cov.branches["81-gear.lua:361:13507"]=true; 
      for _, eq in pairs(G.equip) do B.__r23_cov.branches["81-gear.lua:362:13546"]=true; 
        if type(eq) == "table" then B.__r23_cov.branches["81-gear.lua:363:13580"]=true; 
          for s, v in pairs(eq) do B.__r23_cov.branches["81-gear.lua:364:13617"]=true; 
            if type(v) == "string" and v:sub(1, 3) == "eq_" then B.__r23_cov.branches["81-gear.lua:365:13680"]=true;  eq[s] = ""; hit = true end
          end
        end
      end
    end
    if type(G.items) == "table" then B.__r23_cov.branches["81-gear.lua:370:13788"]=true; 
      for k in pairs(G.items) do B.__r23_cov.branches["81-gear.lua:371:13823"]=true; 
        if type(k) == "string" and k:sub(1, 3) == "eq_" then B.__r23_cov.branches["81-gear.lua:372:13882"]=true;  G.items[k] = nil; hit = true end
      end
    end
    if hit and type(G.ui) == "table" then B.__r23_cov.branches["81-gear.lua:375:13975"]=true; 
      G.ui.msg = "옛 장비(능력치 없던 시제품)는 새 장비 체계로 바뀌며 정리되었습니다."
    end
    return hit
  end
end

-- ===== 전투 반영: 장착 능력치·효과 → u.gq · u.gu, 엔진 훅 =====
-- 전투를 만들 때(20-state blank_u → B.gear_init) 낀 장비 셋의 효과를 딱 한 번 합쳐 u.gq = { [효과 키] = 합 } 으로 둔다.
-- 능력치 키(stat def hp mp spd crit)는 그때 유닛 수치에 바로 곱해 넣고, 나머지는 아래 훅이 읽기만 한다(값이 없으면 0).
-- 전설 고유 효과는 u.gu = { {key, p, x, n}... }. 새 전설 장신구 30종의 효과는 { key, v = {수치…} } (st.gk[key] = true 표시도 단다). 장비가 없는 유닛은 gq · gu 가 nil 이라 아무 일도 없고 난수도 쓰지 않는다.
-- 🔴 확률 효과는 B.rnd(st) 만, 그 효과를 가진 유닛이 있을 때만 굴린다(장비 없는 전투의 로그가 달라지면 안 된다).
do B.__r23_cov.branches["81-gear.lua:387:14534"]=true; 
  local SLOTS = { "weapon", "armor", "acc" }
  local function r1(x) B.__r23_cov.calls["81-gear.lua:389"]=true;  return math.floor(x * 10 + 0.5) / 10 end
  local function pct(v) B.__r23_cov.calls["81-gear.lua:390"]=true;  return 1 + v / 100 end
  -- 새 전설 장신구 중 기존 능력치 칸에 그대로 얹히는 효과: 키 → { 칸, 수치 번호 } (전투 시작 때 u.gq 에 더한다)
  local SIGQ = { pa_layer = { "shield", 1 }, as_vital = { "critdmg", 1 }, al_brew = { "heal", 1 }, un_seep = { "dot", 1 }, ch_rift = { "abyss", 1 } }

  -- 출전 편성 항목에 붙일 장착 코드 { weapon, armor, acc } — 하나도 안 끼면 nil(편성 표가 이전과 같다)
  function B.gear_eq_of(G, cid) B.__r23_cov.calls["81-gear.lua:395"]=true; 
    local eq = type(G.equip) == "table" and G.equip[cid]
    if type(eq) ~= "table" then B.__r23_cov.branches["81-gear.lua:397:15112"]=true;  return nil end
    local out, any = {}, false
    for _, s in ipairs(SLOTS) do B.__r23_cov.branches["81-gear.lua:399:15193"]=true; 
      local c = eq[s]
      if type(c) == "string" and c ~= "" then B.__r23_cov.branches["81-gear.lua:401:15259"]=true;  out[s] = c; any = true end
    end
    return any and out or nil
  end

  -- 휴식 중 장비를 바꿨을 수 있다 — 다음 전투 전에 편성의 장착 코드를 지금 장비로 다시 맞춘다
  function B.gear_pm_refresh(G, pm) B.__r23_cov.calls["81-gear.lua:407"]=true; 
    for _, m in ipairs(pm or {}) do B.__r23_cov.branches["81-gear.lua:408:15464"]=true; 
      if m.id ~= "" then B.__r23_cov.branches["81-gear.lua:409:15487"]=true;  m.eq = B.gear_eq_of(G, m.id); m.forge = G.forge end
    end
  end

  -- 유닛 u 가 가진 전설 고유 효과 key 의 {key, p, x, n}(없으면 nil)
  local function uq(u, key) B.__r23_cov.calls["81-gear.lua:414"]=true; 
    local l = u.gu
    if l then B.__r23_cov.branches["81-gear.lua:416:15669"]=true; 
      for i = 1, #l do B.__r23_cov.branches["81-gear.lua:417:15694"]=true; 
        if l[i].key == key then B.__r23_cov.branches["81-gear.lua:418:15724"]=true;  return l[i] end
      end
    end
    return nil
  end
  B.gear_uq = uq

  function B.gear_init(st, u, m) B.__r23_cov.calls["81-gear.lua:425"]=true; 
    local eq = m and m.eq
    if type(eq) ~= "table" then B.__r23_cov.branches["81-gear.lua:427:15888"]=true;  return end
    local q, list, n = {}, nil, 0
    local mc = m.cls and B.cls_of(m.cls)
    for _, s in ipairs(SLOTS) do B.__r23_cov.branches["81-gear.lua:430:16009"]=true; 
      local code = eq[s]
      if type(code) == "string" and code ~= "" then B.__r23_cov.branches["81-gear.lua:432:16084"]=true; 
        local r = B.gear_roll(code, m.L, m.forge and m.forge[code] and m.forge[code].lv or 0)
        if r and mc and m.L and (r.item.cls ~= mc.id or r.lv > m.L) then B.__r23_cov.branches["81-gear.lua:434:16251"]=true;  r = nil end   -- 다른 직업·레벨 미달 장비는 합산하지 않는다(장착 규칙의 이중 방어)
        if r then B.__r23_cov.branches["81-gear.lua:435:16325"]=true; 
          n = n + 1
          for k, v in pairs(r.fx) do B.__r23_cov.branches["81-gear.lua:437:16384"]=true;  q[k] = (q[k] or 0) + v end
          local un = r.unique
          if un then B.__r23_cov.branches["81-gear.lua:439:16460"]=true; 
            list = list or {}
            if un.sig then B.__r23_cov.branches["81-gear.lua:441:16517"]=true;    -- 새 전설 장신구: 수치 배열 v, 전투 상태에 이 효과가 있다는 표시(st.gk)
              list[#list + 1] = { key = un.key, v = un.v }
              st.gk = st.gk or {}
              st.gk[un.key] = true
              local sq = SIGQ[un.key]
              if sq then B.__r23_cov.branches["81-gear.lua:446:16759"]=true;  q[sq[1]] = (q[sq[1]] or 0) + un.v[sq[2]] end
            else B.__r23_cov.branches["81-gear.lua:447:16821"]=true; 
              list[#list + 1] = { key = un.key, p = un.p, x = un.x, n = un.n }
            end
          end
        end
      end
    end
    if n == 0 then B.__r23_cov.branches["81-gear.lua:454:16979"]=true;  return end
    for k, v in pairs(q) do B.__r23_cov.branches["81-gear.lua:455:17020"]=true;  q[k] = r1(v) end
    u.gq = q
    u.gu = list
    if q.stat then B.__r23_cov.branches["81-gear.lua:458:17083"]=true;  u.cs = u.cs * pct(q.stat) end
    if q.def then B.__r23_cov.branches["81-gear.lua:459:17131"]=true;  u.de = u.de * pct(q.def) end
    if q.hp then B.__r23_cov.branches["81-gear.lua:460:17177"]=true; 
      local h = B.floor(u.mhp * pct(q.hp) + 0.5)
      u.mhp, u.hp = h, h
    end
    if q.mp and u.mmp > 0 then B.__r23_cov.branches["81-gear.lua:464:17290"]=true; 
      local h = B.floor(u.mmp * pct(q.mp) + 0.5)
      u.mmp, u.mp = h, h
    end
    if q.spd then B.__r23_cov.branches["81-gear.lua:468:17390"]=true;  u.sp = B.floor(u.sp * pct(q.spd) + 0.5) end
    if q.crit then B.__r23_cov.branches["81-gear.lua:469:17453"]=true;  u.cr = u.cr + q.crit end
  end

  local function line(st, i, txt, at) B.__r23_cov.calls["81-gear.lua:472"]=true;  B.trait_line(st, i, txt, at) end
  local function idx_of(st, u) B.__r23_cov.calls["81-gear.lua:473"]=true; 
    for i = 1, 4 do B.__r23_cov.branches["81-gear.lua:474:17609"]=true; 
      if st.u[i] == u then B.__r23_cov.branches["81-gear.lua:475:17634"]=true;  return i end
    end
    return st.cur
  end

  -- ---------- 주는 피해 (B.hit 의 deal 사건) ----------
  local function gear_deal(st, a, t, m, tags, opt) B.__r23_cov.calls["81-gear.lua:481"]=true; 
    local u = st.u[a]
    local sum, mm = 0, 1
    local q = u.gq
    if q then B.__r23_cov.branches["81-gear.lua:485:17862"]=true; 
      sum = q.dmg or 0
      if q.elite then B.__r23_cov.branches["81-gear.lua:487:17907"]=true; 
        local d = B.DEF[t]
        if d.kind == "elite" or d.kind == "boss" or d.elite then B.__r23_cov.branches["81-gear.lua:489:17999"]=true;  sum = sum + q.elite end
      end
      if q.lowhp and u.hp <= u.mhp * 0.5 then B.__r23_cov.branches["81-gear.lua:491:18079"]=true;  sum = sum + q.lowhp end
      if q.shdmg and u.sh > 0 then B.__r23_cov.branches["81-gear.lua:492:18138"]=true;  sum = sum + q.shdmg end
      if q.first and u.x.f1 == st.n then B.__r23_cov.branches["81-gear.lua:493:18203"]=true;  sum = sum + q.first end
    end
    if u.gu then B.__r23_cov.branches["81-gear.lua:495:18252"]=true; 
      local ar = uq(u, "abyss_res")
      if ar and st.u[t].dr == 1 then B.__r23_cov.branches["81-gear.lua:497:18325"]=true;  sum = sum + ar.x end
      local x = u.x
      if x.ch then B.__r23_cov.branches["81-gear.lua:499:18385"]=true;    -- 연쇄: 처치한 그 행동의 다음 행동에서 하는 공격에 얹는다(그 행동의 모든 타격)
        if x.chk ~= st.n then B.__r23_cov.branches["81-gear.lua:500:18466"]=true; 
          if x.chu == nil then B.__r23_cov.branches["81-gear.lua:501:18497"]=true;  x.chu = st.n end
          if x.chu == st.n then B.__r23_cov.branches["81-gear.lua:502:18546"]=true; 
            sum = sum + x.ch
          else B.__r23_cov.branches["81-gear.lua:504:18590"]=true; 
            x.ch, x.chu, x.chk = nil, nil, nil
          end
        end
      end
      local e = uq(u, "pa_wrath")   -- 새 전설 장신구: 피해 증가 효과들
      if e and u.sh > 0 then B.__r23_cov.branches["81-gear.lua:510:18761"]=true;  sum = sum + e.v[1] end
      e = uq(u, "ar_high")
      if e and B.DEF[a].row == "후열" then B.__r23_cov.branches["81-gear.lua:512:18852"]=true;  sum = sum + e.v[1] end
      e = uq(u, "sa_comp")
      if e and opt and opt.k == "burst" then B.__r23_cov.branches["81-gear.lua:514:18947"]=true;  sum = sum + e.v[1] end
      if (x.sws or 0) > 0 and opt and opt.k == "burst" then B.__r23_cov.branches["81-gear.lua:515:19030"]=true;    -- 방벽 영창: 충전 중 막은 피해를 이 폭발(의 첫 타)에 더한다
        tags[#tags + 1] = "방벽 영창 +" .. B.floor(x.sws)
        m = m + x.sws
        x.sws = 0
      end
      e = uq(u, "un_blood")
      if e and (x.blc or 0) > 0 then B.__r23_cov.branches["81-gear.lua:521:19240"]=true;    -- 피의 대가: 이 행동의 모든 타격에 쌓인 만큼 얹고 비운다
        if x.blk ~= st.n then B.__r23_cov.branches["81-gear.lua:522:19308"]=true;  x.blk, x.blu, x.blc = st.n, x.blc, 0 end
      end
      if e and x.blk == st.n and (x.blu or 0) > 0 then B.__r23_cov.branches["81-gear.lua:524:19414"]=true;  sum = sum + e.v[2] * x.blu end
      e = uq(u, "gl_hunger")
      if e and u.hp <= u.mhp * e.v[1] / 100 then B.__r23_cov.branches["81-gear.lua:526:19523"]=true;  sum = sum + e.v[2] end
      e = uq(u, "ch_rift")
      if e and st.u[t].dr == 1 then B.__r23_cov.branches["81-gear.lua:528:19609"]=true;  sum = sum + e.v[2] end
      e = uq(u, "as_hunt")
      if e and x.hbk and x.hbk ~= st.n then B.__r23_cov.branches["81-gear.lua:530:19703"]=true;    -- 사냥꾼의 흐름: 덤 행동의 모든 타격(연쇄와 같은 방식)
        if x.hbu == nil then B.__r23_cov.branches["81-gear.lua:531:19769"]=true;  x.hbu = st.n end
        if x.hbu == st.n then B.__r23_cov.branches["81-gear.lua:532:19816"]=true;  sum = sum + e.v[2] else B.__r23_cov.branches["81-gear.lua:532:19840"]=true;  x.hbk, x.hbu = nil, nil end
      end
      e = uq(u, "ch_full")
      if e and st.u[t].dr == 1 then B.__r23_cov.branches["81-gear.lua:535:19941"]=true; 
        mm = e.v[1] / 2.5
        if opt and opt.name == "혼돈 파동" then B.__r23_cov.branches["81-gear.lua:537:20011"]=true;  mm = mm * e.v[2] end
      end
      if (x.scr or 0) > 0 then B.__r23_cov.branches["81-gear.lua:539:20073"]=true;    -- 되갚는 상처: 쌓아 둔 피해를 이 공격(의 첫 타)에 더한다
        tags[#tags + 1] = "되갚는 상처 +" .. B.floor(x.scr)
        m = m + x.scr
        x.scr = 0
      end
    end
    local pd = 0   -- 전장의 함성: 출전한 아군 중 가장 큰 한 사람 몫만(겹쳐 쌓이지 않는다)
    for i = 1, 4 do B.__r23_cov.branches["81-gear.lua:546:20311"]=true; 
      local w = st.u[i]
      if w.gu and w.al == 1 then B.__r23_cov.branches["81-gear.lua:548:20366"]=true; 
        local g = uq(w, "party_dmg")
        if g and g.x > pd then B.__r23_cov.branches["81-gear.lua:550:20434"]=true;  pd = g.x end
      end
    end
    sum = sum + pd
    if mm ~= 1 then B.__r23_cov.branches["81-gear.lua:554:20504"]=true; 
      tags[#tags + 1] = "완전한 공명 ×" .. r1(mm)
      m = m * mm
    end
    if sum ~= 0 then B.__r23_cov.branches["81-gear.lua:558:20595"]=true; 
      tags[#tags + 1] = "장비 " .. (sum > 0 and "+" or "") .. r1(sum) .. "%"
      return m * (1 + sum / 100)
    end
    return m
  end

  -- 처치 직후(34-traits B.kill_credit 이 부른다): 처치 시 MP · 연쇄
  function B.gear_kill(st, a, at) B.__r23_cov.calls["81-gear.lua:566"]=true; 
    local u = st.u[a]
    if not u.gq and not u.gu then B.__r23_cov.branches["81-gear.lua:568:20877"]=true;  return end
    local q = u.gq
    if q and q.killmp then B.__r23_cov.branches["81-gear.lua:570:20934"]=true; 
      local n = B.floor(q.killmp + 0.5)
      if n > 0 and u.mp < u.mmp then B.__r23_cov.branches["81-gear.lua:572:21011"]=true; 
        B.setf(st, a, "mp", math.min(u.mmp, u.mp + n), at + 0.3)
        line(st, a, "처치의 기운: MP +" .. n, at + 0.3)
      end
    end
    local ch = uq(u, "chain")
    if ch then B.__r23_cov.branches["81-gear.lua:578:21190"]=true; 
      u.x.ch, u.x.chk, u.x.chu = ch.x, st.n, nil
      line(st, a, "연쇄: 다음 공격의 피해 +" .. ch.x .. "%", at + 0.3)
    end
    if u.gu then B.__r23_cov.branches["81-gear.lua:582:21326"]=true;    -- 새 전설 장신구: 처치 효과
      local x = u.x
      local e = uq(u, "as_hunt")
      if e and B.ACT == u and (x.huc or 0) < e.v[1] then B.__r23_cov.branches["81-gear.lua:585:21457"]=true; 
        x.huc = (x.huc or 0) + 1
        x.hbk, x.hbu = st.n, nil   -- 이 행동 다음의 첫 행동(= 덤으로 얻은 행동)에 피해 보너스
        B.gear_adv(st, a, 10000)
        line(st, a, "사냥꾼의 흐름: 바로 한 번 더 행동한다", at + 0.3)
      end
      e = uq(u, "ar_chain")
      if e and B.SKON == "snipe" and B.ACT == u then B.__r23_cov.branches["81-gear.lua:592:21743"]=true; 
        local back = B.floor((x.lmc or 0) * e.v[2] / 100 + 0.5)
        if back > 0 and u.mp < u.mmp then B.__r23_cov.branches["81-gear.lua:594:21849"]=true;  B.setf(st, a, "mp", math.min(u.mmp, u.mp + back), at + 0.3) end
        B.gear_adv(st, a, e.v[1] * 100)
        line(st, a, "연쇄 사격: MP " .. B.p(tostring(back), "을를") .. " 돌려받고 다음 차례가 " .. e.v[1] .. "% 빨라진다", at + 0.3)
      end
      e = uq(u, "gl_king")
      if e then B.__r23_cov.branches["81-gear.lua:599:22120"]=true; 
        local sk = B.SKON
        B.SKON = nil
        local h = B.heal(st, a, u.mhp * e.v[1] / 100, at + 0.3)
        B.SKON = sk
        if h > 0 then B.__r23_cov.branches["81-gear.lua:604:22273"]=true;  line(st, a, "투기장의 왕: 처치로 HP +" .. h, at + 0.3) end
      end
    end
  end

  -- 아군 i 의 다음 차례를 amt(10000 = 한 차례) 만큼 당긴다. 자기 차례 중이면 차례가 끝난 뒤(turn_end)에 당긴다
  function B.gear_adv(st, i, amt) B.__r23_cov.calls["81-gear.lua:610"]=true; 
    local w = st.u[i]
    if i == st.cur then B.__r23_cov.branches["81-gear.lua:612:22508"]=true;  w.x.adv = (w.x.adv or 0) + amt
    else B.__r23_cov.branches["81-gear.lua:613:22548"]=true;  w.g = math.max(0, w.g - amt) end
  end

  -- 스킬을 쓰고 난 직후(B.player): 도발 뒤 피해 감소 · 파티 보호막 뒤 가속 · 회복 뒤 보호막 합
  function B.gear_skill(st, i, id) B.__r23_cov.calls["81-gear.lua:617"]=true; 
    local u = st.u[i]
    local x = u.x
    local T = st.ev.T
    if id == "taunt" then B.__r23_cov.branches["81-gear.lua:621:22777"]=true; 
      local e = uq(u, "wa_wall")
      if e then B.__r23_cov.branches["81-gear.lua:623:22826"]=true; 
        x.wwn = e.v[2] + 1   -- +1 은 이 차례 끝에 깎이는 몫
        line(st, i, "철벽 함성: " .. e.v[2] .. "턴 동안 받는 피해 −" .. e.v[1] .. "%", T)
      end
    elseif id == "pshield" then B.__r23_cov.branches["81-gear.lua:627:22998"]=true; 
      local e = uq(u, "pr_swift")
      if e then B.__r23_cov.branches["81-gear.lua:629:23048"]=true; 
        for a = 1, 4 do B.__r23_cov.branches["81-gear.lua:630:23074"]=true; 
          if st.u[a].al == 1 then B.__r23_cov.branches["81-gear.lua:631:23106"]=true;  B.gear_adv(st, a, e.v[1] * 100) end
        end
        line(st, i, "신속의 기도: 파티의 다음 차례가 " .. e.v[1] .. "% 빨라진다", T)
      end
    elseif id == "heal" and (x.sgs or 0) > 0 then B.__r23_cov.branches["81-gear.lua:635:23282"]=true; 
      line(st, i, "넘치는 생기: 넘친 회복이 보호막 " .. B.p(tostring(x.sgs), "이가") .. " 되었다", T)
      x.sgs = nil
    end
  end

  -- 스킬의 MP 비용: 「바람 읽기」가 일발필살 비용을 깎는다
  function B.gear_mpc(u, sk) B.__r23_cov.calls["81-gear.lua:642"]=true; 
    local mp = sk.mp or 0
    local e = sk.id == "snipe" and uq(u, "ar_wind")
    if e and mp > 0 then B.__r23_cov.branches["81-gear.lua:645:23569"]=true;  return B.floor(mp * (1 - e.v[1] / 100) + 0.5) end
    return mp
  end

  -- 「마지막 성벽」: 쓰러질 일격을 받으면 전투당 한 번 HP v1% 로 버티고 v2 라운드 동안 파티가 받는 피해 −v3%(B.strike 가 부른다 — 돌려주는 값 1 = 버텼다)
  function B.gear_save(st, t, at) B.__r23_cov.calls["81-gear.lua:650"]=true; 
    local u = st.u[t]
    local e = uq(u, "wa_last")
    if not e or u.x.wlu then B.__r23_cov.branches["81-gear.lua:653:23862"]=true;  return 0 end
    u.x.wlu = 1
    B.setf(st, t, "hp", math.max(1, B.floor(u.mhp * e.v[1] / 100 + 0.5)), at)
    st.gw = { n = e.v[2] + (st.cur == t and 1 or 0), p = e.v[3], who = t }   -- 착용자 자신의 차례 e.v[2] 번(자기 차례 중에 버텼으면 그 차례의 끝은 세지 않는다)
    line(st, t, "마지막 성벽: HP " .. e.v[1] .. "%로 버티고 자신의 " .. e.v[2] .. "턴 동안 파티가 받는 피해 −" .. e.v[3] .. "%", at)
    B.say(st, "<b>" .. B.nm(t) .. "</b>의 <b>마지막 성벽</b> 덕에 쓰러질 일격을 버텨 냈다", at + 0.2)
    return 1
  end

  -- 「번지는 약병」: 약화 약병이 대상 양옆의 적에게도 같은 약화를 건다
  function B.gear_splash(st, i, tgt, val) B.__r23_cov.calls["81-gear.lua:663"]=true; 
    if not uq(st.u[i], "al_splash") then B.__r23_cov.branches["81-gear.lua:664:24442"]=true;  return end
    for _, j in ipairs({ tgt - 1, tgt + 1 }) do B.__r23_cov.branches["81-gear.lua:665:24503"]=true; 
      local w = st.u[j]
      if j >= 5 and w and w.al == 1 then B.__r23_cov.branches["81-gear.lua:667:24566"]=true;  B.badd(w, "ddn", val, 3) end
    end
  end

  -- 「피의 대가」: 지속 피해가 들어갈 때마다(그 줄을 건 착용자마다 한 번) MP 회복
  function B.gear_dottick(st, wb, at) B.__r23_cov.calls["81-gear.lua:672"]=true; 
    local seen = {}
    for _, w in ipairs(wb) do B.__r23_cov.branches["81-gear.lua:674:24753"]=true; 
      if not seen[w] then B.__r23_cov.branches["81-gear.lua:675:24777"]=true; 
        seen[w] = true
        local u = st.u[w]
        local e = uq(u, "un_blood")
        if e and u.al == 1 then B.__r23_cov.branches["81-gear.lua:679:24894"]=true; 
          u.x.blc = math.min(e.v[3], (u.x.blc or 0) + 1)
          if u.mp < u.mmp then B.__r23_cov.branches["81-gear.lua:681:24982"]=true;  B.setf(st, w, "mp", math.min(u.mmp, u.mp + e.v[1]), at) end
          line(st, w, "피의 대가: MP +" .. e.v[1] .. ", 다음 공격 피해 +" .. (u.x.blc * e.v[2]) .. "%", at)
        end
      end
    end
  end

  -- 「연쇄 폭발」: 한 적의 지속 피해가 v1 줄이 되면 남은 지속 피해를 전부 즉시 한 번에 준다(B.dot_push 가 부른다)
  function B.gear_dotchain(st, v, by) B.__r23_cov.calls["81-gear.lua:689"]=true; 
    local e = uq(st.u[by], "un_chain")
    if not e or v.al ~= 1 then B.__r23_cov.branches["81-gear.lua:691:25362"]=true;  return end
    local c, sum = 0, 0
    for _, x in ipairs(v.dot) do B.__r23_cov.branches["81-gear.lua:693:25432"]=true; 
      if x.k == 1 then B.__r23_cov.branches["81-gear.lua:694:25453"]=true;  c = c + 1 end
      sum = sum + x.d * x.n
    end
    if c < e.v[1] then B.__r23_cov.branches["81-gear.lua:697:25526"]=true;  return end
    sum = B.floor(sum * (1 + e.v[2] / 100))
    local j
    for k = 5, #st.u do B.__r23_cov.branches["81-gear.lua:700:25619"]=true; 
      if st.u[k] == v then B.__r23_cov.branches["81-gear.lua:701:25644"]=true;  j = k end
    end
    if not j then B.__r23_cov.branches["81-gear.lua:703:25680"]=true;  return end
    v.dot = {}
    local T = st.ev.T
    local res = B.strike(st, j, sum, T + 0.3)
    B.push(st, { k = "dot", a = j, t = T, tg = { res } })
    B.say(st, "<b>" .. B.nm(by) .. "</b>의 <b>연쇄 폭발</b>. " .. B.p(B.nm(j), "에게") .. " 남은 지속 피해가 한꺼번에 들어가 <em>" .. res.d .. "</em> 피해를 입혔다" .. (res.kill == 1 and ". 쓰러졌다" or ""), T + 0.5)
    if res.kill == 1 then B.__r23_cov.branches["81-gear.lua:709:26044"]=true; 
       st.kill = B.U("{name}의 연쇄 폭발", { name = B.DEF[by].full })
      B.kill_credit(st, by, T + 0.3)
    end
  end

  -- 차례 시작(B.begin_turn, 아군): 차례마다 MP 회복 · 도발 중 HP 회복
  function B.gear_begin(st, i) B.__r23_cov.calls["81-gear.lua:716"]=true; 
    local u = st.u[i]
    local q = u.gq
    if q and q.mpreg then B.__r23_cov.branches["81-gear.lua:719:26313"]=true; 
      local n = B.floor(q.mpreg + 0.5)
      if n > 0 and u.mp < u.mmp then B.__r23_cov.branches["81-gear.lua:721:26389"]=true;  B.setf(st, i, "mp", math.min(u.mmp, u.mp + n), st.ev.T) end
    end
    local th = uq(u, "taunt_heal")
    if th and u.tau > 0 then B.__r23_cov.branches["81-gear.lua:724:26521"]=true; 
      local h = B.heal(st, i, u.mhp * th.x / 100, st.ev.T + 0.2)
      if h > 0 then B.__r23_cov.branches["81-gear.lua:726:26606"]=true;  line(st, i, "버티는 자: HP +" .. h, st.ev.T + 0.2) end
    end
  end

  -- 스킬 MP 소비 직후(B.player): 메아리
  function B.gear_echo(st, i, cost) B.__r23_cov.calls["81-gear.lua:731"]=true; 
    local u = st.u[i]
    u.x.lmc = cost   -- 마지막으로 쓴 MP(연쇄 사격이 돌려준다)
    local e = uq(u, "echo")
    if not e or B.rnd(st) * 100 >= e.p then B.__r23_cov.branches["81-gear.lua:735:26882"]=true;  return end
    local back = B.floor(cost * e.x / 100 + 0.5)
    if back <= 0 or u.mp >= u.mmp then B.__r23_cov.branches["81-gear.lua:737:26981"]=true;  return end
    B.setf(st, i, "mp", math.min(u.mmp, u.mp + back), st.ev.T)
    line(st, i, "메아리: MP " .. back .. " 되돌려 받는다", st.ev.T)
  end

  -- 지속 피해를 거는 사람(B.dot_push): 지속 피해 % · 독 폭발 표식
  function B.gear_dot(st, by, d) B.__r23_cov.calls["81-gear.lua:743"]=true; 
    local w = st.u[by]
    if not w or by > 4 then B.__r23_cov.branches["81-gear.lua:745:27254"]=true;  return d, nil end
    local q = w.gq
    if q and q.dot then B.__r23_cov.branches["81-gear.lua:747:27315"]=true;  d = B.floor(d * pct(q.dot) + 0.5) end
    local bx = uq(w, "dot_burst")
    return d, bx and bx.x or nil
  end

  -- 보호막이 깨지는 순간(B.strike): 가시 방벽이 있으면 깨진 양을 적어 둔다(처리는 그 적의 공격이 끝난 뒤 — attacked)
  function B.gear_shbreak(st, t, ab, src) B.__r23_cov.calls["81-gear.lua:753"]=true; 
    if st.gk and st.gk.pa_echo then B.__r23_cov.branches["81-gear.lua:754:27586"]=true;  st.gb = { t = t, d = ab } end   -- 은총의 반향: 피해 종류와 상관없이 깨질 때마다 한 번(B.strike 끝에서 gear_echo)
    if type(src) ~= "number" or src < 5 then B.__r23_cov.branches["81-gear.lua:755:27721"]=true;  return end
    local th = uq(st.u[t], "thorns_shd")
    if th then B.__r23_cov.branches["81-gear.lua:757:27788"]=true;  st.gt = { t = t, e = src, d = ab, x = th.x, n = st.n } end
  end

  -- 「은총의 반향」: 깨진 보호막의 일부만큼 그 아군을 회복(B.strike 가 HP 를 깎은 직후 부른다)
  function B.gear_pecho(st, t, at) B.__r23_cov.calls["81-gear.lua:761"]=true; 
    local gb = st.gb
    st.gb = nil
    if not gb or gb.t ~= t or st.u[t].al ~= 1 then B.__r23_cov.branches["81-gear.lua:764:28041"]=true;  return end
    local bw, be   -- 여러 명이 껴도 파티에 한 번만 걸린다. 가장 높은 수치를 쓴다
    for w = 1, 4 do B.__r23_cov.branches["81-gear.lua:766:28132"]=true; 
      local pw = st.u[w]
      local e = pw.al == 1 and pw.gu and uq(pw, "pa_echo")
      if e and (not be or e.v[1] > be.v[1]) then B.__r23_cov.branches["81-gear.lua:769:28263"]=true;  bw, be = w, e end
    end
    if be then B.__r23_cov.branches["81-gear.lua:771:28304"]=true; 
      local h = B.heal(st, t, gb.d * be.v[1] / 100, at + 0.3)
      if h > 0 then B.__r23_cov.branches["81-gear.lua:773:28386"]=true;  line(st, bw, "은총의 반향: " .. B.nm(t) .. " HP +" .. h, at + 0.3) end
    end
  end

  -- 아군 대상 버프의 세기(B.badd): 행동 중인 시전자의 버프 효과 %
  function B.gear_buff(v) B.__r23_cov.calls["81-gear.lua:778"]=true; 
    local c = B.ACT
    local q = c and c.gq
    if q and q.buff and v > 0 and B.SKON then B.__r23_cov.branches["81-gear.lua:781:28630"]=true;  v = v * pct(q.buff) end   -- 스킬이 건 버프만(아이템·특성은 제외)
    if c and c.gu and B.SKON == "bless" and v > 0 then B.__r23_cov.branches["81-gear.lua:782:28736"]=true;    -- 「넓은 축복」: 파티 능력치 상향의 수치
      local e = uq(c, "pr_bless")
      if e then B.__r23_cov.branches["81-gear.lua:784:28814"]=true;  v = v * pct(e.v[1]) end
    end
    return v
  end

  -- ---------- 전역 훅(B.GH)에 덧씌운다 ----------
  local G = B.GH

  local o_deal = G.deal
  G.deal = function(st, a, t, m, tags, opt) B.__r23_cov.calls["81-gear.lua:793"]=true; 
    if o_deal then B.__r23_cov.branches["81-gear.lua:794:29015"]=true; 
      local r = o_deal(st, a, t, m, tags, opt)
      if r ~= nil then B.__r23_cov.branches["81-gear.lua:796:29085"]=true;  m = r end
    end
    return gear_deal(st, a, t, m, tags, opt)
  end

  local o_crit = G.crit
  G.crit = function(st, a, t, opt) B.__r23_cov.calls["81-gear.lua:802"]=true; 
    local r = o_crit and o_crit(st, a, t, opt) or 0
    local x = st.u[a].x
    if x and x.fzn and x.fzn > 0 then B.__r23_cov.branches["81-gear.lua:805:29328"]=true;  r = r + x.fzx end   -- 광기
    if x and x.kg then B.__r23_cov.branches["81-gear.lua:806:29377"]=true;    -- 투기장의 왕: 처치마다 쌓이는 치명 확률
      local e = uq(st.u[a], "gl_king")
      if e then B.__r23_cov.branches["81-gear.lua:808:29460"]=true;  r = r + x.kg * e.v[2] end
    end
    return r
  end

  local o_take = G.take
  G.take = function(st, t, dmg, src) B.__r23_cov.calls["81-gear.lua:814"]=true; 
    local r = o_take and o_take(st, t, dmg, src)
    local u = st.u[t]
    local f = 1
    local q = u.gq
    if q and q.dr then B.__r23_cov.branches["81-gear.lua:819:29704"]=true;  f = f * (1 - q.dr / 100) end
    if u.x.lsn and u.x.lsn > 0 then B.__r23_cov.branches["81-gear.lua:820:29769"]=true;  f = f * 0.7 end   -- 최후의 저항
    if u.gu then B.__r23_cov.branches["81-gear.lua:821:29814"]=true;    -- 새 전설 장신구: 받는 피해 감소
      local e = uq(u, "wa_wall")
      if e and (u.x.wwn or 0) > 0 then B.__r23_cov.branches["81-gear.lua:823:29910"]=true;  f = f * (1 - e.v[1] / 100) end
      e = uq(u, "pa_wrath")
      if e and u.sh > 0 then B.__r23_cov.branches["81-gear.lua:825:29998"]=true;  f = f * (1 - e.v[2] / 100) end
      e = uq(u, "sa_ward")
      if e and u.chg == 1 then B.__r23_cov.branches["81-gear.lua:827:30087"]=true; 
        f = f * (1 - e.v[1] / 100)
        local kept = (r or dmg) * e.v[1] / 100 * e.v[2] / 100   -- 막은 피해의 일부를 마력 폭발에 쌓는다
        u.x.sws = math.min(u.mhp, (u.x.sws or 0) + kept)
      end
    end
    if st.gw then B.__r23_cov.branches["81-gear.lua:833:30304"]=true;  f = f * (1 - st.gw.p / 100) end   -- 마지막 성벽: 파티 전체
    if f < 1 then B.__r23_cov.branches["81-gear.lua:834:30373"]=true;  return (r or dmg) * f end
    return r
  end

  local o_heal = G.heal
  G.heal = function(st, t, amt) B.__r23_cov.calls["81-gear.lua:839"]=true; 
    local r = o_heal and o_heal(st, t, amt)
    local c = B.ACT
    local changed = r
    if r ~= nil then B.__r23_cov.branches["81-gear.lua:843:30582"]=true;  amt = r end
    if c and B.SKON then B.__r23_cov.branches["81-gear.lua:844:30619"]=true;    -- 스킬이 한 회복만(물약·악마 처치 회복 같은 것은 제외)
      local q = c.gq
      if q and q.heal then B.__r23_cov.branches["81-gear.lua:846:30704"]=true;  amt = amt * pct(q.heal); changed = amt end
      local hh = c.gu and uq(c, "heal_haste")
      if hh and amt > 0 and c.x.hh ~= st.n then B.__r23_cov.branches["81-gear.lua:848:30841"]=true;    -- 축복의 바람: 회복 스킬 한 번에 한 번만 굴린다
        c.x.hh = st.n
        if B.rnd(st) * 100 < hh.p then B.__r23_cov.branches["81-gear.lua:850:30935"]=true; 
          for i = 1, 4 do B.__r23_cov.branches["81-gear.lua:851:30963"]=true; 
            local w = st.u[i]
            if w.al == 1 then B.__r23_cov.branches["81-gear.lua:853:31021"]=true;  w.g = math.max(0, w.g - 10000 * hh.x / 100) end
          end
          line(st, idx_of(st, c), "축복의 바람: 파티의 다음 차례가 " .. hh.x .. "% 빨라진다", st.ev.T)
        end
      end
    end
    local rq = st.u[t].gq
    if rq and rq.healrecv then B.__r23_cov.branches["81-gear.lua:860:31256"]=true;  amt = amt * pct(rq.healrecv); changed = amt end
    local su = c and B.SKON and c.gu and uq(c, "al_surge")   -- 「넘치는 생기」: 최대 HP 를 넘친 회복의 일부를 보호막으로
    if su then B.__r23_cov.branches["81-gear.lua:862:31418"]=true; 
      local v = st.u[t]
      local over = v.hp + B.floor(amt + 0.5) - v.mhp
      local s = over > 0 and B.floor(over * su.v[1] / 100) or 0
      s = math.min(s, math.max(0, B.floor(v.mhp * 0.5) - v.sh))   -- 이 효과로 쌓는 보호막은 최대 HP 의 50% 까지
      if s > 0 and v.al == 1 then B.__r23_cov.branches["81-gear.lua:867:31691"]=true; 
        B.setf(st, t, "sh", v.sh + s, st.ev.T + 0.3)
        v.shT = math.max(v.shT, su.v[2])
        c.x.sgs = (c.x.sgs or 0) + s
      end
    end
    return changed
  end

  local o_shield = G.shield
  G.shield = function(st, i, amt) B.__r23_cov.calls["81-gear.lua:877"]=true; 
    local r = o_shield and o_shield(st, i, amt)
    local changed = r
    if r ~= nil then B.__r23_cov.branches["81-gear.lua:880:32019"]=true;  amt = r end
    local u = st.u[i]
    local q = u.gq
    if q and q.shield then B.__r23_cov.branches["81-gear.lua:883:32099"]=true;  amt = amt * pct(q.shield); changed = amt end
    local gd = u.gu and uq(u, "guardian")
    if gd and B.rnd(st) * 100 < gd.p then B.__r23_cov.branches["81-gear.lua:885:32228"]=true; 
      amt = amt * pct(gd.x); changed = amt
      line(st, i, "수호: 보호막 +" .. gd.x .. "%", st.ev.T)
    end
    return changed
  end

  G.abyss_mul = function(st, a, t, amt) B.__r23_cov.calls["81-gear.lua:892"]=true; 
    local q = st.u[a].gq
    if q and q.abyss then B.__r23_cov.branches["81-gear.lua:894:32451"]=true;  return amt * pct(q.abyss) end
  end

  -- 공격 하나가 끝난 뒤: 광기(확률로 치명타 확률 상승)
  local o_hit_after = G.hit_after
  G.hit_after = function(st, a, t, res, opt, at) B.__r23_cov.calls["81-gear.lua:899"]=true; 
    if o_hit_after then B.__r23_cov.branches["81-gear.lua:900:32631"]=true;  o_hit_after(st, a, t, res, opt, at) end
    local u = st.u[a]
    if not u.gu then B.__r23_cov.branches["81-gear.lua:902:32714"]=true;  return end
    local fz = uq(u, "frenzy")
    if fz and u.x.fzr ~= st.n then B.__r23_cov.branches["81-gear.lua:904:32791"]=true; 
      u.x.fzr = st.n   -- 행동 하나에 한 번만 굴린다
      if B.rnd(st) * 100 < fz.p then B.__r23_cov.branches["81-gear.lua:906:32870"]=true; 
        u.x.fzx, u.x.fzn = fz.x, (fz.n or 1) + 1   -- +1 은 이 행동의 차례 끝에 깎이는 몫
        line(st, a, "광기: " .. (fz.n or 1) .. "턴 동안 치명타 확률 +" .. fz.x .. "%p", at + 0.3)
      end
    end
    local hg = uq(u, "gl_hunger")   -- 굶주린 칼: 준 피해의 일부를 회복
    if hg and u.al == 1 and (res.d or 0) > 0 then B.__r23_cov.branches["81-gear.lua:912:33162"]=true; 
      local h = B.heal(st, a, res.d * hg.v[3] / 100, at + 0.3)
      if h > 0 then B.__r23_cov.branches["81-gear.lua:914:33245"]=true;  line(st, a, "굶주린 칼: HP +" .. h, at + 0.3) end
    end
  end

  -- 피해를 입은 뒤: 최후의 저항(전투당 한 번)
  local o_damaged = G.damaged
  G.damaged = function(st, t, dmg, src, at) B.__r23_cov.calls["81-gear.lua:920"]=true; 
    if o_damaged then B.__r23_cov.branches["81-gear.lua:921:33433"]=true;  o_damaged(st, t, dmg, src, at) end
    local u = st.u[t]
    local sc = u.gu and uq(u, "wa_scar")   -- 되갚는 상처: 받은 피해의 일부를 쌓아 둔다
    if sc then B.__r23_cov.branches["81-gear.lua:924:33576"]=true;  u.x.scr = math.min(u.mhp * sc.v[2] / 100, (u.x.scr or 0) + dmg * sc.v[1] / 100) end
    if u.gu and u.al == 1 and not u.x.lsd then B.__r23_cov.branches["81-gear.lua:925:33707"]=true; 
      local ls = uq(u, "last_stand")
      if ls and u.hp < u.mhp * ls.x / 100 then B.__r23_cov.branches["81-gear.lua:927:33791"]=true; 
        u.x.lsd, u.x.lsn = 1, ls.n or 1
        line(st, t, "최후의 저항: " .. (ls.n or 1) .. "턴 동안 받는 피해 −30%", at + 0.2)
      end
    end
  end

  -- 적 공격이 아군에게 들어간 뒤: 받은 피해 반사 · 가시 방벽
  local o_attacked = G.attacked
  G.attacked = function(st, t, e, res, at) B.__r23_cov.calls["81-gear.lua:936"]=true; 
    if o_attacked then B.__r23_cov.branches["81-gear.lua:937:34072"]=true;  o_attacked(st, t, e, res, at) end
    if e < 5 then B.__r23_cov.branches["81-gear.lua:938:34124"]=true;  return end
    local q = st.u[t].gq
    if q and q.reflect and st.u[e].al == 1 then B.__r23_cov.branches["81-gear.lua:940:34208"]=true; 
      local d = B.floor((res.d or 0) * q.reflect / 100)
      if d >= 1 then B.__r23_cov.branches["81-gear.lua:942:34285"]=true; 
        local r2 = B.strike(st, e, d, at + 0.2, nil, "fixed")   -- 고정 피해: 방어 자세를 받지 않고, 반사한 피해는 다시 반사되지 않는다
        B.say(st, "<b>" .. B.nm(t) .. "</b>의 장비가 충격을 되돌렸다. " .. B.p(B.nm(e), "에게") .. " <em>" .. r2.d .. "</em> 반사 피해를 입혔다" .. (r2.kill == 1 and ". 쓰러졌다" or ""), at + 0.4)
        if r2.kill == 1 then B.__r23_cov.branches["81-gear.lua:945:34594"]=true;  B.kill_credit(st, t, at + 0.2) end
      end
    end
    local gt = st.gt
    if gt then B.__r23_cov.branches["81-gear.lua:949:34683"]=true; 
      st.gt = nil
      if gt.t == t and gt.n == st.n and st.u[gt.e].al == 1 then B.__r23_cov.branches["81-gear.lua:951:34765"]=true; 
        local d = B.floor(gt.d * gt.x / 100)
        if d >= 1 then B.__r23_cov.branches["81-gear.lua:953:34833"]=true; 
          local r2 = B.strike(st, gt.e, d, at + 0.3, nil, "fixed")
          B.say(st, "<b>" .. B.nm(t) .. "</b>의 보호막이 깨지며 가시가 튀었다. " .. B.p(B.nm(gt.e), "에게") .. " <em>" .. r2.d .. "</em> 피해를 입혔다" .. (r2.kill == 1 and ". 쓰러졌다" or ""), at + 0.5)
          if r2.kill == 1 then B.__r23_cov.branches["81-gear.lua:956:35109"]=true;  B.kill_credit(st, t, at + 0.3) end
        end
      end
    end
  end

  -- 차례 끝: 광기 · 최후의 저항의 남은 턴을 깎는다
  local o_turn_end = G.turn_end
  G.turn_end = function(st, i) B.__r23_cov.calls["81-gear.lua:964"]=true; 
    if o_turn_end then B.__r23_cov.branches["81-gear.lua:965:35301"]=true;  o_turn_end(st, i) end
    if i > 4 then B.__r23_cov.branches["81-gear.lua:966:35341"]=true;  return end
    local x = st.u[i].x
    if x.fzn and x.fzn > 0 then B.__r23_cov.branches["81-gear.lua:968:35408"]=true;  x.fzn = x.fzn - 1 end
    if x.lsn and x.lsn > 0 then B.__r23_cov.branches["81-gear.lua:969:35462"]=true;  x.lsn = x.lsn - 1 end
    if x.wwn and x.wwn > 0 then B.__r23_cov.branches["81-gear.lua:970:35516"]=true;  x.wwn = x.wwn - 1 end
    local gw = st.gw   -- 마지막 성벽: 착용자 자신의 차례가 끝날 때마다 깎는다
    if gw and gw.who == i then B.__r23_cov.branches["81-gear.lua:972:35626"]=true; 
      gw.n = gw.n - 1
      if gw.n <= 0 then B.__r23_cov.branches["81-gear.lua:974:35672"]=true;  st.gw = nil end
    end
    if (x.adv or 0) > 0 then B.__r23_cov.branches["81-gear.lua:976:35725"]=true;    -- 처치 뒤 한 번 더 · 연쇄 사격 · 신속의 기도: 이 차례가 끝난 뒤 다음 차례를 당긴다
      local u = st.u[i]
      if u.al == 1 then B.__r23_cov.branches["81-gear.lua:978:35829"]=true;  u.g = math.max(0, u.g - x.adv) end
      x.adv = nil
    end
  end

  local o_ed = G.enemy_dead   -- 투기장의 왕: 적이 쓰러질 때마다 살아 있는 착용자의 치명 확률이 쌓인다
  G.enemy_dead = function(st, t) B.__r23_cov.calls["81-gear.lua:984"]=true; 
    if o_ed then B.__r23_cov.branches["81-gear.lua:985:36021"]=true;  o_ed(st, t) end
    if not (st.gk and st.gk.gl_king) then B.__r23_cov.branches["81-gear.lua:986:36079"]=true;  return end
    for i = 1, 4 do B.__r23_cov.branches["81-gear.lua:987:36112"]=true; 
      local w = st.u[i]
      local e = w.al == 1 and w.gu and uq(w, "gl_king")
      if e and (w.x.kg or 0) < e.v[3] then B.__r23_cov.branches["81-gear.lua:990:36233"]=true; 
        w.x.kg = (w.x.kg or 0) + 1
        line(st, i, "투기장의 왕: 치명 확률 +" .. (w.x.kg * e.v[2]) .. "%p", st.ev.T)
      end
    end
  end

  local o_round = G.round
  G.round = function(st) B.__r23_cov.calls["81-gear.lua:998"]=true; 
    if o_round then B.__r23_cov.branches["81-gear.lua:999:36441"]=true;  o_round(st) end
    local w = st.gw   -- 마지막 성벽: 착용자가 쓰러져 차례가 없으면 라운드마다 깎는다
    if w and st.u[w.who].al ~= 1 then B.__r23_cov.branches["81-gear.lua:1001:36555"]=true; 
      w.n = w.n - 1
      if w.n <= 0 then B.__r23_cov.branches["81-gear.lua:1003:36598"]=true;  st.gw = nil end
    end
  end

  -- 심연 깎기 뒤: 공허 흡수(적을 고갈시키면 MP 회복)
  local o_aa = G.abyss_after
  G.abyss_after = function(st, a, t, amt, at, list) B.__r23_cov.calls["81-gear.lua:1009"]=true; 
    if o_aa then B.__r23_cov.branches["81-gear.lua:1010:36763"]=true;  o_aa(st, a, t, amt, at, list) end
    local u = st.u[a]
    if u.gu and st.u[t].dr == 1 then B.__r23_cov.branches["81-gear.lua:1012:36856"]=true; 
      local e = uq(u, "ch_void")
      if e then B.__r23_cov.branches["81-gear.lua:1014:36905"]=true; 
        local n = B.floor(u.mmp * e.v[1] / 100 + 0.5)
        if u.mp < u.mmp then B.__r23_cov.branches["81-gear.lua:1016:36988"]=true;  B.setf(st, a, "mp", math.min(u.mmp, u.mp + n), at + 0.4) end
        B.gear_adv(st, a, e.v[2] * 100)
        line(st, a, "공허 흡수: MP +" .. n .. ", 다음 차례가 " .. e.v[2] .. "% 빨라진다", at + 0.4)
      end
    end
  end
end

-- ===== 드랍: 층 · 종류 · 출전 직업 → 장비 코드 =====
-- kind = "battle"(탐색 발견) | "elite" | "chief"(층 우두머리) | "boss"(구역 보스). 확률표는 gear_effects.json 의 drop.
-- 레벨 = B.dn_rec_lv(층) ± spread(씨앗), 직업 = 출전 파티 직업 80% · 나머지 20%, 칸은 균등.
-- 고른 직업·칸·등급에 목표 레벨 ±spread 안의 아이템이 없으면 한 등급 아래로(전설은 20·30·40 레벨뿐이라 그 근처 층에서만 나온다).
do B.__r23_cov.branches["81-gear.lua:1028:37512"]=true; 
  local ORDER = { "common", "fine", "rare", "epic", "legend" }
  local SLOTS = { "weapon", "armor", "acc" }
  local classes

  local function all_classes() B.__r23_cov.calls["81-gear.lua:1033"]=true; 
    if classes then B.__r23_cov.branches["81-gear.lua:1034:37686"]=true;  return classes end
    local g, seen = B.gear(), {}
    classes = {}
    for _, id in ipairs(g.order) do B.__r23_cov.branches["81-gear.lua:1037:37793"]=true; 
      local c = g.items[id].cls
      if not seen[c] then B.__r23_cov.branches["81-gear.lua:1039:37849"]=true;  seen[c] = true; classes[#classes + 1] = c end
    end
    return classes
  end

  -- 출전 편성(pm) → 직업 id 목록(중복 없이)
  function B.gear_party_cls(pm) B.__r23_cov.calls["81-gear.lua:1045"]=true; 
    local out, seen = {}, {}
    for _, m in ipairs(pm or {}) do B.__r23_cov.branches["81-gear.lua:1047:38061"]=true; 
      if m.id ~= "" and m.cls and m.cls ~= "" then B.__r23_cov.branches["81-gear.lua:1048:38110"]=true; 
        local c = B.cls_of(m.cls)
        if c and not seen[c.id] then B.__r23_cov.branches["81-gear.lua:1050:38181"]=true;  seen[c.id] = true; out[#out + 1] = c.id end
      end
    end
    return out
  end

  -- 그 종류의 장비가 떨어질 확률(정예 35% · 우두머리 55% · 구역 보스 85%)
  function B.gear_drop_p(kind) B.__r23_cov.calls["81-gear.lua:1057"]=true; 
    return B.gear().fx.drop.chance[kind] or 0
  end

  local function pick_item(g, cls, slot, rar, mix, seed) B.__r23_cov.calls["81-gear.lua:1061"]=true; 
    local best, n = nil, 0
    for _, id in ipairs(g.by[cls][slot]) do B.__r23_cov.branches["81-gear.lua:1063:38532"]=true; 
      local it = g.items[id]
      if it.rarity == rar then B.__r23_cov.branches["81-gear.lua:1065:38590"]=true; 
        n = n + 1
        if mix(seed, 5, n, 0) * n < 1 then B.__r23_cov.branches["81-gear.lua:1067:38651"]=true;  best = id end
      end
    end
    return best
  end

  -- 돌려주는 값 = 코드 | nil, 아이템 표(레벨 · 등급), 목표 레벨(시험용)
  function B.gear_drop(seed, floor, kind, party_cls) B.__r23_cov.calls["81-gear.lua:1074"]=true; 
    local g = B.gear()
    local D = g.fx.drop
    local mix = B.ex_mix
    local w
    for _, band in ipairs(D.bands) do B.__r23_cov.branches["81-gear.lua:1079:38934"]=true; 
      if floor >= band.from then B.__r23_cov.branches["81-gear.lua:1080:38965"]=true;  w = band.w[kind] end
    end
    if not w then B.__r23_cov.branches["81-gear.lua:1082:39012"]=true;  return nil end
    -- 직업: 파티 80% · 나머지 20%
    local all = all_classes()
    local inp, party, others = {}, {}, {}
    for _, c in ipairs(party_cls or {}) do B.__r23_cov.branches["81-gear.lua:1086:39172"]=true; 
      if g.by[c] and not inp[c] then B.__r23_cov.branches["81-gear.lua:1087:39207"]=true;  inp[c] = true; party[#party + 1] = c end
    end
    for _, c in ipairs(all) do B.__r23_cov.branches["81-gear.lua:1089:39289"]=true;  if not inp[c] then B.__r23_cov.branches["81-gear.lua:1089:39306"]=true;  others[#others + 1] = c end end
    local pool = all
    if #party > 0 and #others > 0 then B.__r23_cov.branches["81-gear.lua:1091:39398"]=true;  pool = (mix(seed, 1, 0, 0) * 100 < D.party_pct) and party or others
    elseif #party > 0 then B.__r23_cov.branches["81-gear.lua:1092:39493"]=true;  pool = party end
    local cls = pool[math.floor(mix(seed, 2, 0, 0) * #pool) + 1]
    local slot = SLOTS[math.floor(mix(seed, 3, 0, 0) * #SLOTS) + 1]
    -- 등급 가중치만 적용한다. 아이템의 옛 개별 레벨은 코드 호환용 데이터로 남긴다.
    local tot = 0
    for _, r in ipairs(ORDER) do B.__r23_cov.branches["81-gear.lua:1097:39748"]=true;  tot = tot + (w[r] or 0) end
    if tot <= 0 then B.__r23_cov.branches["81-gear.lua:1098:39795"]=true;  return nil end
    local x, ri = mix(seed, 6, 0, 0) * tot, 1
    for k, r in ipairs(ORDER) do B.__r23_cov.branches["81-gear.lua:1100:39891"]=true; 
      local v = w[r] or 0
      if v > 0 then B.__r23_cov.branches["81-gear.lua:1102:39935"]=true; 
        ri = k
        x = x - v
        if x < 0 then B.__r23_cov.branches["81-gear.lua:1105:39990"]=true;  break end
      end
    end
    for k = ri, 1, -1 do B.__r23_cov.branches["81-gear.lua:1108:40045"]=true; 
      local id = pick_item(g, cls, slot, ORDER[k], mix, seed)
      if id then B.__r23_cov.branches["81-gear.lua:1110:40122"]=true;  return B.gear_code(id, math.floor(mix(seed, 7, 0, 0) * 1099511627776) + 1), g.items[id], B.gear().fx.equip_lv[ORDER[k]] end
    end
    return nil
  end

  -- ===== 장비 가공(대장간 뽑기 — design/shop.json process) =====
  -- 기준 레벨 = 출전 가능 캐릭터(페르소나 + 영입한 동료) 최고 레벨. 구간마다 가격과 등급 확률이 다르다.
  -- 결과는 (계정 씨앗, 가공 횟수) 로만 정해진다 — 되돌리거나 불러와 같은 회차를 다시 해도 같은 장비다.
  function B.process_lv(G) B.__r23_cov.calls["81-gear.lua:1118"]=true; 
    local top = B.lv_of(G, "persona")
    for _, cid in ipairs(G.roster or {}) do B.__r23_cov.branches["81-gear.lua:1120:40576"]=true;  top = math.max(top, B.lv_of(G, cid)) end
    return top
  end

  function B.process_band(G) B.__r23_cov.calls["81-gear.lua:1124"]=true; 
    local lv = B.process_lv(G)
    local bands = B.SHOP.process.bands
    for _, b in ipairs(bands) do B.__r23_cov.branches["81-gear.lua:1127:40771"]=true; 
      if lv >= b.from and lv <= b.to then B.__r23_cov.branches["81-gear.lua:1128:40811"]=true;  return b end
    end
    return lv < bands[1].from and bands[1] or bands[#bands]
  end

  -- 직업 풀: 페르소나와 영입한 동료의 직업(중복 없이, 고정 순서). 직업이 하나도 없으면 전 직업.
  local function process_classes(G) B.__r23_cov.calls["81-gear.lua:1134"]=true; 
    local g, out, seen = B.gear(), {}, {}
    local function add(raw) B.__r23_cov.calls["81-gear.lua:1136"]=true; 
      local c = raw and B.cls_of(raw)
      if c and g.by[c.id] and not seen[c.id] then B.__r23_cov.branches["81-gear.lua:1138:41154"]=true;  seen[c.id] = true; out[#out + 1] = c.id end
    end
    add(type(G.persona) == "table" and G.persona.cls or nil)
    for _, cid in ipairs(G.roster or {}) do B.__r23_cov.branches["81-gear.lua:1141:41313"]=true;  add(B.CAST[cid] and B.CAST[cid].cls or nil) end
    return #out > 0 and out or all_classes()
  end

  -- n번째 가공의 결과 코드 · 아이템 · 등급. 같은 (씨앗, n, 직업 풀, 구간) 이면 늘 같다.
  function B.process_roll(G, n) B.__r23_cov.calls["81-gear.lua:1146"]=true; 
    local g, mix = B.gear(), B.ex_mix
    local seed = tonumber(G.seed) or 0
    local w = B.process_band(G).w
    local pool = process_classes(G)
    local cls = pool[math.floor(mix(seed, n, 1, 61) * #pool) + 1]
    local slot = SLOTS[math.floor(mix(seed, n, 2, 61) * #SLOTS) + 1]
    local tot = 0
    for _, r in ipairs(ORDER) do B.__r23_cov.branches["81-gear.lua:1154:41839"]=true;  tot = tot + (w[r] or 0) end
    local x, ri = mix(seed, n, 3, 61) * tot, 1
    for k, r in ipairs(ORDER) do B.__r23_cov.branches["81-gear.lua:1156:41947"]=true; 
      local v = w[r] or 0
      if v > 0 then B.__r23_cov.branches["81-gear.lua:1158:41991"]=true; 
        ri = k
        x = x - v
        if x < 0 then B.__r23_cov.branches["81-gear.lua:1161:42046"]=true;  break end
      end
    end
    for k = ri, 1, -1 do B.__r23_cov.branches["81-gear.lua:1164:42101"]=true; 
      local id = pick_item(g, cls, slot, ORDER[k], mix, seed + n * 7919)
      if id then B.__r23_cov.branches["81-gear.lua:1166:42189"]=true;  return B.gear_code(id, math.floor(mix(seed, n, 4, 61) * 1099511627776) + 1), g.items[id], ORDER[k] end
    end
    return nil
  end
end

-- 결과 글에 쓰는 이름: "이름 (희귀 · Lv 12)"
function B.gear_label(code) B.__r23_cov.calls["81-gear.lua:1173"]=true; 
  local r = B.gear_roll(code)
  if not r then B.__r23_cov.branches["81-gear.lua:1175:42434"]=true;  return "알 수 없는 장비" end
  local rn = B.RARITY and B.RARITY[r.rarity] and B.RARITY[r.rarity].name or r.rarity
  return r.item.name .. " (" .. rn .. ", Lv " .. r.lv .. ")"
end

-- AI 요청 문맥: 지금 출전한 사람이 끼고 있는 전설 장비의 고유 효과만, 한 사람에 한 줄. 가방·일반 장비는 싣지 않는다(토큰 상한).
B.CTX["23-gear"] = function(G) B.__r23_cov.calls["81-gear.lua:1181"]=true; 
  if type(G.equip) ~= "table" then B.__r23_cov.branches["81-gear.lua:1182:42755"]=true;  return "" end
  local items = B.gear().items
  local who = {}
  if type(G.persona) == "table" and G.persona.fight ~= 0 then B.__r23_cov.branches["81-gear.lua:1185:42879"]=true;  who[1] = "persona" end
  for _, cid in ipairs(G.party or {}) do B.__r23_cov.branches["81-gear.lua:1186:42945"]=true;  who[#who + 1] = cid end
  local lines = {}
  for _, cid in ipairs(who) do B.__r23_cov.branches["81-gear.lua:1188:43019"]=true; 
    local eq = G.equip[cid]
    local parts = {}
    if type(eq) == "table" then B.__r23_cov.branches["81-gear.lua:1191:43098"]=true; 
      for _, slot in ipairs({ "weapon", "armor", "acc" }) do B.__r23_cov.branches["81-gear.lua:1192:43161"]=true; 
        local gid = type(eq[slot]) == "string" and B.gear_parse(eq[slot])
        local it = gid and items[gid]
        if it and it.rarity == "legend" then B.__r23_cov.branches["81-gear.lua:1195:43316"]=true;  parts[#parts + 1] = it.name end   -- 이름만(효과는 엔진이 계산 — AI 요청 토큰 상한, 10-10)
      end
    end
    if #parts > 0 then B.__r23_cov.branches["81-gear.lua:1198:43431"]=true; 
      local c = B.CAST and B.CAST[cid]
      lines[#lines + 1] = (cid == "persona" and "{{user}}" or (c and c.name or cid)) .. "의 전설 장비: " .. table.concat(parts, ", ")
    end
  end
  return table.concat(lines, "\n")
end
