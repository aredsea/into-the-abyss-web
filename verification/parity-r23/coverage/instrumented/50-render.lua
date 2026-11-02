-- ===== 화면 렌더 =====
-- 🔴 출력 HTML 에 빈 줄이 있으면 안 된다(markdown-it 이 HTML 블록을 거기서 끝낸다). 줄 첫머리 들여쓰기도 쓰지 않는다.
-- 🔴 risu-btn 값에는 콜론을 쓰지 않는다(sk_2 · tg_5 · cancel · reset).
B.SN = { "", "", "", "", "사냥개 A", "사냥개 B", "궁수", "감시관" }   -- 적 줄임 이름(아군은 B.DEF 이름)
function B.sn(i) B.__r23_cov.calls["50-render.lua:5"]=true; 
   if i <= 4 then B.__r23_cov.branches["50-render.lua:6:277"]=true;  return B.DEF[i] and B.T(B.DEF[i].name) or "" end
  local d = B.DEF[i]
   if d and d.foe then B.__r23_cov.branches["50-render.lua:8:370"]=true;  return B.T(d.name) end   -- 조합 전투의 적은 이름 그대로
   return B.T(B.SN[i] or "")
end

local function pct(v, m) B.__r23_cov.calls["50-render.lua:12"]=true; 
  if m <= 0 then B.__r23_cov.branches["50-render.lua:13:491"]=true;  return 0 end
  local p = v / m * 100
  if p > 100 then B.__r23_cov.branches["50-render.lua:15:546"]=true;  p = 100 end
  if p < 0 then B.__r23_cov.branches["50-render.lua:16:574"]=true;  p = 0 end
  return string.format("%.1f", p)
end

local function f2(x) B.__r23_cov.calls["50-render.lua:20"]=true;  return string.format("%.2f", x) end

-- 사건 기록에서 만든 막대·숫자 키프레임 (메시지 안 <style>)
function B.dyn(st, D) B.__r23_cov.calls["50-render.lua:23"]=true; 
  local K = {}
  for i = 1, #st.u do B.__r23_cov.branches["50-render.lua:25:783"]=true;  K[i] = {} end
  local ev = st.ev
  if not ev or D <= 0 then B.__r23_cov.branches["50-render.lua:27:841"]=true;  return "", K end
  local css = {}
  local dd = D
  for i = 1, #st.u do B.__r23_cov.branches["50-render.lua:30:914"]=true; 
    local u = st.u[i]
    for _, f in ipairs(B.FIELDS) do B.__r23_cov.branches["50-render.lua:32:972"]=true; 
      local pts = {}
      for _, x in ipairs(ev.h[i]) do B.__r23_cov.branches["50-render.lua:34:1030"]=true;  if x.f == f then B.__r23_cov.branches["50-render.lua:34:1045"]=true;  pts[#pts + 1] = x end end
      if #pts > 0 then B.__r23_cov.branches["50-render.lua:35:1094"]=true; 
        table.sort(pts, function(p, q) B.__r23_cov.calls["50-render.lua:36"]=true;  return p.t < q.t end)
        local mx = (f == "hp") and u.mhp or ((f == "mp") and u.mmp or ((f == "ay") and u.ym or u.mhp))
        local prev = ev.pre[i][f]
        local kf = { string.format("0%%{width:%s%%;--n:%d}", pct(prev, mx), prev) }
        local isHp = (f == "hp")
        local gk = { string.format("0%%{width:%s%%}", pct(prev, mx)) }       -- 뒤 막대(옅은 금): 맞은 +0.2초부터 0.7초
        local fk = { "0%{opacity:0;left:0;width:0}" }                          -- 잃은 구간 붉은 번쩍 0.1초
        local last = 0
        for _, x in ipairs(pts) do B.__r23_cov.branches["50-render.lua:44:1676"]=true; 
          local a = x.t
          if a < last + 0.002 then B.__r23_cov.branches["50-render.lua:46:1733"]=true;  a = last + 0.002 end
          local b = a + (isHp and 0.08 or 0.3)
          local pa, pb = a / dd * 100, b / dd * 100
          if pb > 99.5 then B.__r23_cov.branches["50-render.lua:49:1881"]=true;  pb = 99.5 end
          if pa > pb - 0.01 then B.__r23_cov.branches["50-render.lua:50:1928"]=true;  pa = pb - 0.01 end
          kf[#kf + 1] = string.format("%.2f%%{width:%s%%;--n:%d}", pa, pct(prev, mx), prev)
          kf[#kf + 1] = string.format("%.2f%%{width:%s%%;--n:%d}", pb, pct(x.v, mx), x.v)
          if isHp then B.__r23_cov.branches["50-render.lua:53:2152"]=true; 
            local ga, gb = (a + 0.2) / dd * 100, (a + 0.9) / dd * 100
            if x.v >= prev then B.__r23_cov.branches["50-render.lua:55:2254"]=true;  ga, gb = pa, pb end   -- 회복은 뒤 막대도 같이
            if gb > 99.7 then B.__r23_cov.branches["50-render.lua:56:2322"]=true;  gb = 99.7 end
            if ga > gb - 0.01 then B.__r23_cov.branches["50-render.lua:57:2371"]=true;  ga = gb - 0.01 end
            gk[#gk + 1] = string.format("%.2f%%{width:%s%%}", ga, pct(prev, mx))
            gk[#gk + 1] = string.format("%.2f%%{width:%s%%}", gb, pct(x.v, mx))
            if x.v < prev then B.__r23_cov.branches["50-render.lua:60:2582"]=true; 
              local l0, w0 = pct(x.v, mx), string.format("%.1f", tonumber(pct(prev, mx)) - tonumber(pct(x.v, mx)))
              local fa = pa - 0.02
              if fa < 0.01 then B.__r23_cov.branches["50-render.lua:63:2764"]=true;  fa = 0.01 end
              local fe = (a + 0.12) / dd * 100
              if fe > 99.6 then B.__r23_cov.branches["50-render.lua:65:2857"]=true;  fe = 99.6 end
              fk[#fk + 1] = string.format("%.2f%%{opacity:0;left:%s%%;width:%s%%}", fa, l0, w0)
              fk[#fk + 1] = string.format("%.2f%%{opacity:1;left:%s%%;width:%s%%}", pa, l0, w0)
              fk[#fk + 1] = string.format("%.2f%%{opacity:0;left:%s%%;width:%s%%}", fe, l0, w0)
            end
          end
          prev = x.v
          last = b
        end
        kf[#kf + 1] = string.format("100%%{width:%s%%;--n:%d}", pct(prev, mx), prev)
        local name = "k" .. st.n .. "u" .. i .. f
        css[#css + 1] = "@keyframes " .. name .. "{" .. table.concat(kf) .. "}"
        css[#css + 1] = "." .. name .. "{animation:" .. name .. " " .. f2(dd) .. "s linear both}"
        K[i][f] = name
        if isHp then B.__r23_cov.branches["50-render.lua:79:3598"]=true; 
          gk[#gk + 1] = string.format("100%%{width:%s%%}", pct(prev, mx))
          fk[#fk + 1] = "100%{opacity:0}"
          css[#css + 1] = "@keyframes " .. name .. "g{" .. table.concat(gk) .. "}"
          css[#css + 1] = "." .. name .. "g{animation:" .. name .. "g " .. f2(dd) .. "s linear both}"
          css[#css + 1] = "@keyframes " .. name .. "l{" .. table.concat(fk) .. "}"
          css[#css + 1] = "." .. name .. "l{animation:" .. name .. "l " .. f2(dd) .. "s linear both}"
        end
      end
    end
  end
  if #css == 0 then B.__r23_cov.branches["50-render.lua:90:4140"]=true;  return "", K end
  return "<style>" .. table.concat(css, "") .. "</style>", K
end

local function numspan(v, k) B.__r23_cov.calls["50-render.lua:94"]=true; 
  if k then B.__r23_cov.branches["50-render.lua:95:4264"]=true;  return '<span class="num ' .. k .. '" style="--n:' .. v .. '"></span>' end
  return tostring(v)
end

local function chip(c, txt) B.__r23_cov.calls["50-render.lua:99"]=true;  return '<span class="chip ' .. c .. '">' .. txt .. '</span>' end

-- (최상위 local 150 한도 때문에 B 필드로 둔다)
function B.chip_tn(b) B.__r23_cov.calls["50-render.lua:102"]=true;  return (b and b.n and b.n > 0) and B.U(" ({n}턴)", { n = b.n }) or "" end
function B.chip_dotn(list) B.__r23_cov.calls["50-render.lua:103"]=true;  local m = 0 for _, x in ipairs(list) do B.__r23_cov.branches["50-render.lua:103:4658"]=true;  if (x.n or 0) > m then B.__r23_cov.branches["50-render.lua:103:4679"]=true;  m = x.n end end return m end

function B.chips(st, i) B.__r23_cov.calls["50-render.lua:105"]=true; 
  local u = st.u[i]
  if u.al == 0 then B.__r23_cov.branches["50-render.lua:107:4773"]=true;  return chip("x", B.U(i <= 4 and "부상 이탈" or "쓰러짐")) end
  local c = {}
  if u.sh > 0 then B.__r23_cov.branches["50-render.lua:109:4862"]=true;  c[#c + 1] = chip("g", B.U("보호막 {n}", { n = u.sh })) end
  if u.tau > 0 then B.__r23_cov.branches["50-render.lua:110:4938"]=true;  c[#c + 1] = chip("r", B.U("도발")) end
  if u.df == 1 then B.__r23_cov.branches["50-render.lua:111:4995"]=true;  c[#c + 1] = chip("b", B.U("방어")) end
  if u.chg == 1 or u.cq == 1 then B.__r23_cov.branches["50-render.lua:112:5066"]=true;  c[#c + 1] = chip("p", B.U("충전 (다음 차례 발동)")) end
  if (u.pt or 0) > 0 then B.__r23_cov.branches["50-render.lua:113:5140"]=true;  c[#c + 1] = chip("g", B.U("보호 → {name}", { name = B.sn(u.pt) })) end
  if (u.hid or 0) == 1 then B.__r23_cov.branches["50-render.lua:114:5237"]=true;  c[#c + 1] = chip("b", B.U("은신")) end
  if (u.sil or "") ~= "" then B.__r23_cov.branches["50-render.lua:115:5304"]=true;  c[#c + 1] = chip("r", B.U("침묵")) end
  if u.oath > 0 then B.__r23_cov.branches["50-render.lua:116:5362"]=true;  c[#c + 1] = chip("g", B.U("서약 → {name}", { name = B.sn(u.oath) })) end
  if u.rv == 1 then B.__r23_cov.branches["50-render.lua:117:5453"]=true;  c[#c + 1] = chip("p", B.U("심연 깎기 ×1.5")) end
  if u.mk == 1 then B.__r23_cov.branches["50-render.lua:118:5518"]=true;  c[#c + 1] = chip("r", B.U("표식")) end
  if (u.fx or 0) > 0 then B.__r23_cov.branches["50-render.lua:119:5581"]=true;  c[#c + 1] = chip("r", B.U("여우불 {n}턴", { n = u.fx })) end
  local bf = u.bf or {}
  if bf.atk then B.__r23_cov.branches["50-render.lua:121:5679"]=true;  c[#c + 1] = chip("g", B.U("공격 +{n}%{turns}", { n = B.floor(bf.atk.v * 100), turns = B.chip_tn(bf.atk) })) end
  if bf.def then B.__r23_cov.branches["50-render.lua:122:5806"]=true;  c[#c + 1] = chip("g", B.U("방어 +{n}%{turns}", { n = B.floor(bf.def.v * 100), turns = B.chip_tn(bf.def) })) end
  if bf.adn then B.__r23_cov.branches["50-render.lua:123:5933"]=true;  c[#c + 1] = chip("r", B.U("공격 −{n}%{turns}", { n = B.floor(bf.adn.v * 100), turns = B.chip_tn(bf.adn) })) end
  if bf.ddn then B.__r23_cov.branches["50-render.lua:124:6060"]=true;  c[#c + 1] = chip("r", B.U("방어 −{n}%{turns}", { n = B.floor(bf.ddn.v * 100), turns = B.chip_tn(bf.ddn) })) end
  if bf.spd then B.__r23_cov.branches["50-render.lua:125:6187"]=true;  c[#c + 1] = chip("g", B.U("속도 +{n}%{turns}", { n = B.floor(bf.spd.v * 100), turns = B.chip_tn(bf.spd) })) end
  if bf.sdn then B.__r23_cov.branches["50-render.lua:126:6314"]=true;  c[#c + 1] = chip("r", B.U("속도 −{n}%{turns}", { n = B.floor(bf.sdn.v * 100), turns = B.chip_tn(bf.sdn) })) end
  if bf.bl then B.__r23_cov.branches["50-render.lua:127:6440"]=true;  c[#c + 1] = chip("r", B.U("피의 갈증{turns}", { turns = B.chip_tn(bf.bl) })) end
  if bf.g2 then B.__r23_cov.branches["50-render.lua:128:6533"]=true;  c[#c + 1] = chip("b", B.U("굳건한 방어{turns}", { turns = B.chip_tn(bf.g2) })) end
  if bf.bs then B.__r23_cov.branches["50-render.lua:129:6627"]=true;  c[#c + 1] = chip("p", B.U("백스텝{turns}", { turns = B.chip_tn(bf.bs) })) end   -- 옛 저장에 남은 버프(치명 판정이 아직 본다 · 30-engine)
  if u.dot and #u.dot > 0 then B.__r23_cov.branches["50-render.lua:130:6776"]=true;  c[#c + 1] = chip("r", B.U("지속 피해 ×{n} ({turns}턴)", { n = #u.dot, turns = B.chip_dotn(u.dot) })) end
  if u.edot and #u.edot > 0 then B.__r23_cov.branches["50-render.lua:131:6909"]=true;  c[#c + 1] = chip("r", B.U("지속 피해 ×{n} ({turns}턴)", { n = #u.edot, turns = B.chip_dotn(u.edot) })) end
  if u.am > 1 then B.__r23_cov.branches["50-render.lua:132:7030"]=true;  c[#c + 1] = chip("r", B.U("강화")) end
  if u.seal == 1 then B.__r23_cov.branches["50-render.lua:133:7089"]=true;  c[#c + 1] = chip("x", B.U("노트 사용")) end
  if u.lf > 0 then B.__r23_cov.branches["50-render.lua:134:7148"]=true;  c[#c + 1] = chip("x", B.U("판결 사용")) end
  return table.concat(c)
end

function B.hp_stat(label, cls, u, f, mx, K, i, show_num, ticks, notch) B.__r23_cov.calls["50-render.lua:138"]=true; 
  local k = K[i][f]
  local v = u[f]
  local low = (f == "hp" and v / mx <= 0.3) and " low" or ""
  local lay = ""
  if k and f == "hp" then B.__r23_cov.branches["50-render.lua:143:7430"]=true;  lay = '<i class="gh ' .. k .. 'g" style="width:' .. pct(v, mx) .. '%"></i><i class="fl ' .. k .. 'l"></i>' end
  return '<div class="stat' .. (cls == "ab" and " abr" or "") .. '"><b>' .. label .. '</b><div class="bar ' .. cls .. low .. '">' .. lay .. '<i class="' .. (k or "") .. '" style="width:' .. pct(v, mx) .. '%"></i>' ..
    (ticks and '<u></u>' or '') .. (notch and ('<u class="nt" style="left:' .. notch .. '%"></u>') or '') .. '</div>' ..
    '<em>' .. numspan(v, k) .. (show_num and ('/' .. mx) or '') .. '</em></div>'
end

-- 아이콘 이름: 소환 · 충전 · 회복 · 보호 깃발은 전용 그림(ic_int_*, 시트 19)을 쓴다
B.ICON = { summon = "int-summon", charge = "int-charge", heal = "int-heal", protect = "int-protect" }
function B.icn(ic) B.__r23_cov.calls["50-render.lua:151"]=true;  return B.ICON[ic] or ic end

-- 예고 한 줄: 행동 이름 → 표적. 새 행동 종류(전체 · 지속 피해 · 약화 · 소환 …)도 읽히게 쓴다.
function B.intent_text(st, i, act, L) B.__r23_cov.calls["50-render.lua:154"]=true; 
  local who, extra, tn, sty = B.U("자신"), "", "", ""
  local K = act.kind
  if K == "atk" then B.__r23_cov.branches["50-render.lua:157:8371"]=true; 
    if act.all then B.__r23_cov.branches["50-render.lua:158:8391"]=true;  who = B.U("아군 전체")
    else B.__r23_cov.branches["50-render.lua:159:8419"]=true; 
      local t, why = B.enemy_target(st, i)
      who = B.sn(t)
       if why == "taunt" then B.__r23_cov.branches["50-render.lua:162:8512"]=true;  extra = B.U(" (도발)"); tn = " tn"; sty = ' style="--t:' .. f2((L.taunt or 0) + 0.2) .. 's"' end
    end
  elseif K == "dot" or K == "special" or (K == "debuff" and act.target ~= "all") then B.__r23_cov.branches["50-render.lua:164:8701"]=true; 
    local t = B.enemy_target(st, i)
    who = B.sn(t)
  elseif K == "debuff" then B.__r23_cov.branches["50-render.lua:167:8783"]=true;  who = B.U("아군 전체")
  elseif K == "buff" then B.__r23_cov.branches["50-render.lua:168:8828"]=true;  who = B.U((act.target == "allies") and "적 전체" or ((act.target == "ally") and "동료" or "자신"))
  elseif K == "heal" then B.__r23_cov.branches["50-render.lua:169:8946"]=true;  who = B.U("동료")
  elseif K == "summon" then B.__r23_cov.branches["50-render.lua:170:8990"]=true;  who = B.U("하수인")
  elseif K == "protect" then B.__r23_cov.branches["50-render.lua:171:9036"]=true;  who = B.U("동료를 감싼다")
  elseif K == "charge" then B.__r23_cov.branches["50-render.lua:172:9085"]=true;  who = B.U("큰 기술 준비")
  end
   return '<div class="int' .. tn .. '"' .. sty .. '><i class="im im-' .. B.icn(act.ic) .. '"></i>' .. B.T(act.name) .. ' → ' .. who .. extra .. '</div>'
end

function B.r_enemy(st, i, L, K, vis) B.__r23_cov.calls["50-render.lua:177"]=true; 
  local u, d = st.u[i], B.DEF[i]
  if u.empty == 1 then B.__r23_cov.branches["50-render.lua:179:9364"]=true;  return '<div class="en gone empty" data-u="' .. i .. '"></div>' end
  local ev = st.ev
  local cls = "en" .. (d.elite and " elite" or "") .. (d.boss and " boss" or "") .. (d.deepn and " deep" or "") .. (u.add == 1 and " add" or "")
  local dies
  if u.al == 0 then B.__r23_cov.branches["50-render.lua:183:9629"]=true; 
    if ev then B.__r23_cov.branches["50-render.lua:184:9644"]=true; 
      for _, x in ipairs(ev.h[i]) do B.__r23_cov.branches["50-render.lua:185:9683"]=true;  if x.f == "hp" and x.v <= 0 then B.__r23_cov.branches["50-render.lua:185:9714"]=true;  dies = x.t end end
    end
    cls = cls .. (dies and " dying" or " gone")
  end
  local ws = {}
  if dies then B.__r23_cov.branches["50-render.lua:190:9826"]=true;  ws[#ws + 1] = "--dt:" .. f2(dies + 0.4) .. "s" end
  if L.lun[i] then B.__r23_cov.branches["50-render.lua:191:9896"]=true;  cls = cls .. " lun"; ws[#ws + 1] = "--lt:" .. f2(L.lun[i]) .. "s" end
  if L.spawn and L.spawn[i] then B.__r23_cov.branches["50-render.lua:192:9999"]=true;  cls = cls .. " spawn"; ws[#ws + 1] = "--sp:" .. f2(L.spawn[i]) .. "s" end
  local pend = (st.pend > 0 and st.over == "" and u.al == 1 and B.SK[st.cur][st.pend].tgt == "enemy")
  -- 예고
  local int = ""
  if u.al == 1 and st.over == "" then B.__r23_cov.branches["50-render.lua:196:10238"]=true; 
    local act = d.acts[u.ia]
    if u.dr == 1 then B.__r23_cov.branches["50-render.lua:198:10289"]=true; 
       int = '<div class="int dep">' .. B.U("고갈: 차례 상실") .. '</div>'
    elseif vis[i] then B.__r23_cov.branches["50-render.lua:200:10381"]=true; 
      int = B.intent_text(st, i, act, L)
    else B.__r23_cov.branches["50-render.lua:202:10431"]=true; 
       int = '<div class="int unk">' .. B.U("예고 전") .. '</div>'
    end
  end
  local cdc = "cd"
  local cs = {}
  if L.hit[i] then B.__r23_cov.branches["50-render.lua:208:10563"]=true;  cdc = cdc .. " hit"; cs[#cs + 1] = "--kt:" .. f2(L.hit[i]) .. "s" .. ((L.hk[i] or 1) > 1 and (";--k:" .. L.hk[i]) or "") end
  if u.dr == 1 and u.al == 1 then B.__r23_cov.branches["50-render.lua:209:10722"]=true; 
    if L.drn[i] then B.__r23_cov.branches["50-render.lua:210:10743"]=true;  cdc = cdc .. " drn"; cs[#cs + 1] = "--dt2:" .. f2(L.drn[i]) .. "s"; cdc = cdc:gsub(" hit", "")
    else B.__r23_cov.branches["50-render.lua:211:10847"]=true;  cdc = cdc .. " dr" end
  end
  local wk = {}
  for _, e in ipairs(d.wk) do B.__r23_cov.branches["50-render.lua:214:10924"]=true;  wk[#wk + 1] = '<i class="el im im-' .. e .. '"></i>' end
  return '<div class="' .. cls .. '" data-u="' .. i .. '"' .. (#ws > 0 and (' style="' .. table.concat(ws, ";") .. '"') or '') .. '>' ..
    ((d.elite or d.boss) and ('<i class="eb im im-elite' .. (d.boss and " big" or "") .. '"></i>') or '') .. int ..
    '<div class="' .. cdc .. '"' .. (#cs > 0 and (' style="' .. table.concat(cs, ";") .. '"') or '') .. '>' ..
    '<div class="bd">' .. (d.ic and ('<i class="im im-' .. d.ic .. '"></i>') or d.glyph) .. '</div>' ..
     '<div class="ei"><div class="nm">' .. B.T(d.name) .. '<small>' .. B.T(d.lv) .. '</small></div>' ..
    B.hp_stat("HP", "hp", u, "hp", u.mhp, K, i, true) ..
     B.hp_stat(B.U("심연"), "ab", u, "ay", u.ym, K, i, false, true) ..
     '<div class="wk"><b>' .. B.U("약점") .. '</b>' .. table.concat(wk) .. '</div>' ..
    '<div class="sts">' .. B.chips(st, i) .. '</div></div><i class="crk fx-crack"></i></div>' ..
    '<div class="fxl">' .. (L.u[i] or "") .. '</div>' ..
     (pend and ('<button type="button" class="tgt" risu-btn="tg_' .. i .. '">' .. B.U("대상 선택") .. '</button>') or '') ..
    '</div>'
end

-- 직업 패시브 배지(10-10). 사제 「이탈 방지」는 남은 횟수(전투당 1회 — u.ps == 1 이면 씀).
function B.pbadges(st, i, d) B.__r23_cov.calls["50-render.lua:230"]=true; 
  local list = B.PBADGE[d.clsid or ""]
  if not list then B.__r23_cov.branches["50-render.lua:232:12207"]=true;  return '' end
  local u, out = st.u[i], {}
  for _, ic in ipairs(list) do B.__r23_cov.branches["50-render.lua:234:12283"]=true; 
    local used = (d.clsid == "priest" and (u.ps or 0) == 1)
    out[#out + 1] = '<span class="pbg' .. (used and ' used' or '') .. '"><i class="im im-' .. ic .. '"></i>' ..
      ((d.clsid == "priest") and ('<b class="pbn">' .. (used and 0 or 1) .. '</b>') or '') .. '</span>'
  end
  return '<span class="pbgs">' .. table.concat(out) .. '</span>'
end

function B.r_ally(st, i, L, K) B.__r23_cov.calls["50-render.lua:242"]=true; 
  local u, d = st.u[i], B.DEF[i]
   if d.empty then B.__r23_cov.branches["50-render.lua:244:12716"]=true;  return '<div class="pc dead empty" data-u="' .. i .. '"><div class="mid"><div class="nm">' .. B.U("빈 자리") .. '</div></div></div>' end
  local awaiting = (st.cur == i and st.over == "")
  local cls = "pc" .. (awaiting and " act" or "") .. (u.chg == 1 and " chg" or "") .. (u.al == 0 and " dead" or "") .. (L.cls[i] or "")
  local vars = {}
  if L.hit[i] then B.__r23_cov.branches["50-render.lua:248:13074"]=true;  vars[#vars + 1] = "--kt:" .. f2(L.hit[i]) .. "s"; cls = cls .. " hit" end
  if L.vars[i] then B.__r23_cov.branches["50-render.lua:249:13168"]=true;  vars[#vars + 1] = L.vars[i] end
  if u.chg == 1 then B.__r23_cov.branches["50-render.lua:250:13221"]=true;  vars[#vars + 1] = "--nd:-" .. f2((st.n * 0.37) % 1.5) .. "s" end
  local style = #vars > 0 and (' style="' .. table.concat(vars, ";") .. '"') or ''
  local pend = (st.pend > 0 and st.over == "" and u.al == 1 and B.SK[st.cur][st.pend].tgt == "ally" and (i ~= st.cur or not B.NOSELF[B.SK[st.cur][st.pend].cid or ""]))
  local ipend = (st.imenu == 1 and (st.ipk or "") ~= "" and st.over == "" and B.it_ok and B.it_ok(st, st.ipk, i))   -- 아이템 대상(78-battle-item)
  local shown = (u.sh > 0) or (K[i].sh ~= nil)
  local trg = L.trg[i] and (' trg" style="--t:' .. f2(L.trg[i]) .. 's') or ''
  return '<div class="' .. cls .. '" data-u="' .. i .. '"' .. style .. '>' ..
    '<div class="ic"><div class="face' .. (d.art ~= "" and (' fc-' .. d.art) or ' fc-none') .. '">' .. (d.art == "" and ((d.cid == "persona") and B.pimg() or ('<i class="im im-cls-' .. d.clsid .. '"></i>')) or '') .. '</div>' .. (L.icwf[i] and ('<i class="wf" style="--t:' .. f2(L.icwf[i]) .. 's;--p:.85;border-radius:6px"></i>') or '') ..
    (d.art ~= "" and ('<i class="trb im im-t-' .. d.art .. trg .. '"></i>') or '') ..
    B.pbadges(st, i, d) ..
    '<div class="lvb im im-lv">' .. (d.lv or "") .. '</div><i class="clb im im-cls-' .. (d.clsid or "") .. '"></i></div>' ..
     '<div class="mid"><div class="nm">' .. B.T(d.name) .. '</div><div class="t2">' .. B.T(d.cls) .. ', ' .. B.T(d.row) .. '</div>' .. (d.trn ~= "" and ('<div class="trn"><span class="trl">' .. B.U("패시브") .. '</span> ' .. B.T(d.trn) .. '</div>') or '') ..
    B.hp_stat("HP", "hp", u, "hp", u.mhp, K, i, true) ..
    B.hp_stat("MP", "mp", u, "mp", u.mmp, K, i, true) ..
    (shown and B.hp_stat("SH", "sh", u, "sh", u.mhp, K, i, false) or '') ..
    '<div class="sts">' .. B.chips(st, i) .. '</div></div>' ..
    '<div class="fxl">' .. (L.u[i] or "") .. '</div>' ..
     (pend and ('<button type="button" class="tgt" risu-btn="tg_' .. i .. '">' .. B.U("대상 선택") .. '</button>') or '') ..
     (ipend and ('<button type="button" class="tgt" risu-btn="it_to_' .. i .. '">' .. B.U("대상 선택") .. '</button>') or '') ..
    '</div>'
end


local function tile(st, idx, pos, mk, lost) B.__r23_cov.calls["50-render.lua:273"]=true; 
  local d = B.DEF[idx]
  local foe = idx >= 5
  local fr = (pos == 1) and "f-cur" or (not foe and "f-ally" or (d.elite and "f-elite" or "f-foe"))
  local cls = "tq" .. (pos == 1 and " cur" or "") .. (lost and " lost" or "")
  local pt
  if idx <= 4 then B.__r23_cov.branches["50-render.lua:279:15589"]=true;  pt = (d.art ~= "") and ('<div class="pt fc-' .. d.art .. '"></div>') or ('<div class="pt">' .. ((d.cid == "persona") and B.pimg() or '<i class="im im-ph-persona"></i>') .. '</div>')
  else B.__r23_cov.branches["50-render.lua:280:15778"]=true;  pt = '<div class="pt">' .. (d.ic and ('<i class="im ' .. 'im-' .. d.ic .. '"></i>') or d.glyph) .. '</div>' end
   local m = mk and ('<span class="mk ' .. mk[1] .. '">' .. B.U(mk[2]) .. '</span>') or ''
  return '<div class="' .. cls .. '" data-u="' .. idx .. '"><i class="fr im im-' .. fr .. '"></i>' .. pt .. m .. '</div>'
end

function B.r_rail(st) B.__r23_cov.calls["50-render.lua:285"]=true; 
  local mk = {}
  local ev = st.ev
  for i = 1, 4 do B.__r23_cov.branches["50-render.lua:288:16185"]=true;  if st.u[i].chg == 1 then B.__r23_cov.branches["50-render.lua:288:16208"]=true;  mk[i] = { "chg", "충전" } end end
  if ev then B.__r23_cov.branches["50-render.lua:289:16253"]=true; 
    for _, e in ipairs(ev.list) do B.__r23_cov.branches["50-render.lua:290:16290"]=true; 
      if e.k == "chg" and not mk[e.tg[1].i] then B.__r23_cov.branches["50-render.lua:291:16337"]=true;  mk[e.tg[1].i] = { "dly", "밀림" } end
      if e.k == "trait" and e.a <= 4 and e.nm:find("상대성 이론", 1, true) and not mk[e.a] then B.__r23_cov.branches["50-render.lua:292:16464"]=true;  mk[e.a] = { "adv", "당김" } end
    end
  end
  local t = {}
  local seen = {}
  for pos, idx in ipairs(st.q) do B.__r23_cov.branches["50-render.lua:297:16577"]=true; 
    local m
    if not seen[idx] and mk[idx] then B.__r23_cov.branches["50-render.lua:299:16625"]=true;  m = mk[idx] end
    local lost = (not seen[idx]) and idx >= 5 and st.u[idx].dr == 1
    seen[idx] = true
    t[#t + 1] = tile(st, idx, pos, m, lost)
  end
   local now = (st.over == "") and B.U("지금: {name}", { name = B.DEF[st.cur].name }) or B.U("전투 종료")
   return '<div class="rail"><span class="rlb">' .. B.U("행동 순서") .. '</span>' .. table.concat(t) .. '<span class="rnow">' .. now .. '</span></div>'
end

function B.r_head(st) B.__r23_cov.calls["50-render.lua:308"]=true; 
  local syn = {}
  for _, s in ipairs(B.syn(st)) do B.__r23_cov.branches["50-render.lua:310:17109"]=true; 
     syn[#syn + 1] = '<span class="hc' .. (st.n == 0 and " syn" or "") .. '"' .. (st.n == 0 and ' style="--t:1.1s"' or '') .. '><i class="im im-spell"></i>' .. B.U("{type} {n}: {effect}", { type = s.t, n = s.n, effect = s.fx }) .. '</span>'
  end
  local n, sum, me = 0, 0, false
  for i = 1, 4 do B.__r23_cov.branches["50-render.lua:314:17407"]=true; 
    local d = B.DEF[i]
    if not d.empty then B.__r23_cov.branches["50-render.lua:316:17452"]=true;  n = n + 1; sum = sum + (d.lv or 1); if d.cid == "persona" then B.__r23_cov.branches["50-render.lua:316:17515"]=true;  me = true end end
  end
  local avg = (n > 0) and B.floor(sum / n + 0.5) or 0
   local stars = ((st.dk or 0) > 0) and B.U("심층 {n}", { n = st.dc or 1 }) or (((st.star or 1) > 5) and ("★" .. st.star) or string.rep("★", st.star or 1))
   return '<div class="bh"><span class="loc">' .. B.U("{place}, {stars}<small>평균 Lv.{avg}, 적 Lv.{enemy}</small>", { place = B.T(B.esc(st.place or "심연 균열")), stars = stars, avg = avg, enemy = st.el or 40 }) .. '</span><span class="hrt">' .. table.concat(syn) ..
     '<span class="hc pv">' .. B.U("출전 동료 {n}, 페르소나 {status}", { n = me and (n - 1) or n, status = me and B.U("출전") or B.U("대기") }) .. '</span></span></div>'
end

-- 액티브(버튼으로 쓰는 것) / 패시브(저절로 걸리는 것) 꼬리표. 전투, 도감, 길드가 같이 쓴다
function B.kchip(act) B.__r23_cov.calls["50-render.lua:325"]=true; 
   return act and ('<span class="dk-kind act">' .. B.U("액티브") .. '</span>') or ('<span class="dk-kind pas">' .. B.U("패시브") .. '</span>')
end

local function sbtn(st, i, idx, sk, u) B.__r23_cov.calls["50-render.lua:329"]=true; 
  local ok = B.can_use(st, i, sk)
  local mpc = B.mpc(st, i, sk)   -- 장비가 비용을 깎았으면 깎은 값(81-gear)
   local desc = (mpc > 0 and ('<b>MP ' .. mpc .. '</b>: ') or '') .. B.T(sk.d)
  if not ok then B.__r23_cov.branches["50-render.lua:333:18625"]=true; 
     if sk.pv and not B.PRUN[sk.cid] then B.__r23_cov.branches["50-render.lua:334:18667"]=true;  desc = B.U("<b>준비 중</b>. {description}", { description = sk.d })
     elseif u.mp < mpc then B.__r23_cov.branches["50-render.lua:335:18760"]=true;  desc = B.U("<b>MP가 모자랍니다</b>. {description}", { description = sk.d })
     elseif sk.id == "note" then B.__r23_cov.branches["50-render.lua:336:18863"]=true;  desc = B.U("이번 전투에서 이미 썼습니다")
     else B.__r23_cov.branches["50-render.lua:337:18903"]=true;  desc = B.U("<b>지금은 쓸 수 없습니다</b>. {description}", { description = sk.d }) end
  end
   local inner = '<i class="bi im im-' .. sk.ic .. '"></i><span class="t">' .. B.T(sk.name) .. (sk.pv and B.kchip(true) or '') .. '<span class="d">' .. desc .. '</span></span>'
  local pv = sk.pv and " pv" or ""
  if ok then B.__r23_cov.branches["50-render.lua:341:19211"]=true;  return '<button type="button" class="btn' .. pv .. '" risu-btn="sk_' .. idx .. '">' .. inner .. '</button>' end
  return '<div class="btn off' .. pv .. '">' .. inner .. '</div>'
end

function B.r_act(st, D) B.__r23_cov.calls["50-render.lua:345"]=true; 
  local late = (st.ev and D > 1) and (' late" style="--D:' .. f2(D - 0.4) .. 's') or ''
  if st.over ~= "" then B.__r23_cov.branches["50-render.lua:347:19530"]=true; 
    local lines = {}
    for ln in (st.res .. "\n"):gmatch("(.-)\n") do B.__r23_cov.branches["50-render.lua:349:19604"]=true; 
      if ln ~= "" then B.__r23_cov.branches["50-render.lua:350:19625"]=true; 
        if st.over == "win" and ln:find("^얻은 것") and st.dn and (st.dn.stage == 1 or st.dn.kind == "explore") then B.__r23_cov.branches["50-render.lua:351:19739"]=true;    -- 층 보스 전: 아직 받은 것이 없다 / 모으는 중(층 정산 때 받는다)
          lines[#lines + 1] = '<div class="rl">' .. ln .. '</div>'
        elseif st.over == "win" and ln:find("^얻은 것") then B.__r23_cov.branches["50-render.lua:353:19909"]=true;    -- 금화는 세어 올라간다(@property 정수 — 표시는 실기 확인 필요)
           lines[#lines + 1] = '<div class="rl">' .. B.U("얻은 것: 경험치 {exp}, 금화 ", { exp = st.exp or B.REWARD.exp }) .. '<b class="gd" style="--t:' .. f2(D + 0.2) .. 's;--gt:' .. (st.rg or B.REWARD.gold) .. '"></b>' .. ((B.REWARD.item ~= "") and (', ' .. B.T(B.REWARD.item)) or '') .. '</div>'
        else B.__r23_cov.branches["50-render.lua:355:20260"]=true; 
          lines[#lines + 1] = '<div class="rl">' .. ln .. '</div>'
        end
      end
    end
     return '<section class="ap' .. late .. '"><div class="acth"><span class="hd">' .. B.U(st.over == "win" and "승리" or "퇴각") .. '</span><span>' .. B.U("전투 종료") .. '</span></div>' ..
      '<div class="rs">' .. table.concat(lines) .. '</div>' ..
       '<div class="nt">' .. B.U((st.sent == 3) and '이번 전투의 결과는 <b>층 정산 때</b> 한꺼번에 이야기로 넘깁니다. 탐색을 계속하세요' or (st.sent == 4) and ((st.over == "win") and '위의 <b>층 정산</b>을 누르면 보상을 받고 다음 길을 고릅니다' or '위의 <b>토르바로 돌아가기</b>를 누르면 결과가 채팅에 들어갑니다') or (st.sent == 1 and '결과가 채팅에 들어갔습니다. <b>보내기를 누르면 이야기가 이어집니다</b>' or
         '결과를 채팅에 넣지 못했습니다. 위 결과를 직접 적어 보내 주세요')) .. '</div>' ..
       ((st.dn and st.over == "win" and st.dn.kind == "explore") and ('<div class="btns"><button type="button" class="btn pv" risu-btn="ex_cont"><i class="bi im im-nd-battle"></i><span class="t">' .. B.U("탐색 계속") .. '<span class="d">' .. B.U("던전으로 돌아갑니다. HP와 MP는 지금 그대로입니다") .. '</span></span></button></div>') or '') ..
       (st.qid and '' or ('<div class="btns"><button type="button" class="btn" risu-btn="reset"><i class="bi im im-buff"></i><span class="t">' .. B.U("다시 싸우기") .. '<span class="d">' .. B.U("새 전투를 시작합니다 (시험용)") .. '</span></span></button></div>')) .. '</section>'
  end
  local i = st.cur
  local u = st.u[i]
  local d = B.DEF[i]
  if st.imenu == 1 and B.r_items then B.__r23_cov.branches["50-render.lua:370:21661"]=true;  return B.r_items(st, late) end   -- 아이템 고르기 · 대상(78-battle-item)
  if st.pend > 0 then B.__r23_cov.branches["50-render.lua:371:21748"]=true; 
    local sk = B.SK[i][st.pend]
     return '<section class="ap' .. late .. '"><div class="acth"><span class="hd">' .. B.T(d.name) .. ' / ' .. B.T(sk.name) .. '</span><span>' ..
       B.U(sk.tgt == "ally" and '대상 아군을 누르세요' or '대상 적을 누르세요') .. '</span></div>' ..
       '<div class="btns"><button type="button" class="btn" risu-btn="cancel"><i class="bi im im-defend"></i><span class="t">' .. B.U("취소") .. '<span class="d">' .. B.U("다른 행동을 고릅니다") .. '</span></span></button></div></section>'
  end
  local cls, com = {}, {}
  for idx, sk in ipairs(B.SK[i]) do B.__r23_cov.branches["50-render.lua:378:22310"]=true; 
    local b = sbtn(st, i, idx, sk, u)
    if sk.row == "cls" then B.__r23_cov.branches["50-render.lua:380:22374"]=true;  cls[#cls + 1] = b else B.__r23_cov.branches["50-render.lua:380:22397"]=true;  com[#com + 1] = b end
  end
  if st.bag and B.it_button then B.__r23_cov.branches["50-render.lua:382:22458"]=true;  com[#com + 1] = B.it_button(st) end
  local P = B.PASSIVES and B.PASSIVES.classes and B.PASSIVES.classes[d.clsid]
  local psl = ''
  if P and P.name and P.name ~= "없음" then B.__r23_cov.branches["50-render.lua:385:22631"]=true; 
    -- 패시브가 둘이면(이름 「A · B」 + 문장 둘) 한 줄씩. 짝이 안 맞으면 한 줄로 둔다
     local names, sents = {}, {}
     for nmx in ((B.ptx(P.name):gsub(" · ", ", ")) .. ", "):gmatch("(.-), ") do B.__r23_cov.branches["50-render.lua:388:22804"]=true;  names[#names + 1] = nmx end
     local tx = B.ptx(P.text)
    local pos = 1
    while pos <= #tx do B.__r23_cov.branches["50-render.lua:391:22904"]=true; 
      local _, e = tx:find("다%.%s", pos)
      if e then B.__r23_cov.branches["50-render.lua:393:22959"]=true;  sents[#sents + 1] = tx:sub(pos, e - 1); pos = e + 1 else B.__r23_cov.branches["50-render.lua:393:23016"]=true;  sents[#sents + 1] = tx:sub(pos); break end
    end
     if B.LANG ~= "ko" then B.__r23_cov.branches["50-render.lua:395:23095"]=true; 
       psl = '<div class="psl"><b>' .. B.U("직업 패시브: {name}", { name = P.name }) .. '</b> ' .. B.ptx(B.T(P.text)) .. '</div>'
     elseif #names > 1 and #names == #sents then B.__r23_cov.branches["50-render.lua:397:23269"]=true; 
      for k = 1, #names do B.__r23_cov.branches["50-render.lua:398:23298"]=true; 
         psl = psl .. '<div class="psl"><b>' .. B.U("직업 패시브: {name}", { name = names[k] }) .. '</b> ' .. sents[k] .. '</div>'
      end
    else B.__r23_cov.branches["50-render.lua:401:23441"]=true; 
       psl = '<div class="psl"><b>' .. B.U("직업 패시브: {name}", { name = B.ptx(P.name) }) .. '</b> ' .. B.ptx(P.text) .. '</div>'
    end
  end
  -- 개인 스킬(액티브 — 버튼)과 개인 특성(패시브 — 늘 걸림)을 둘 다 적는다. 버튼 이름과 같은 이름·같은 꼬리표라 어느 줄이 어느 버튼인지 보인다
  --  (사장님 10-11 「스킬 이름이 툴팁과 버튼에서 서로 달라」 — 패시브 줄만 있어 버튼 설명처럼 읽혔다)
  for _, sk in ipairs(B.SK[i]) do B.__r23_cov.branches["50-render.lua:407:23773"]=true; 
    if sk.pv then B.__r23_cov.branches["50-render.lua:408:23789"]=true; 
      local sd = tostring(sk.d or ""):gsub("^개인 스킬:%s*", "")
      psl = psl .. '<div class="psl"><b>' .. B.U("개인 스킬: {name}", { name = sk.name }) .. '</b>' .. (B.kchip and B.kchip(true) or '') .. ' ' .. B.T(sd) .. '</div>'
      break
    end
  end
  local cc = d.cid and B.CAST and B.CAST[d.cid]
  if cc and (cc.trait or '') ~= '' then B.__r23_cov.branches["50-render.lua:415:24127"]=true;    -- 개인 특성은 늘 저절로 걸린다(34-traits)
     psl = psl .. '<div class="psl"><b>' .. B.U("개인 패시브: {name}", { name = B.esc(cc.trait) }) .. '</b>' .. (B.kchip and B.kchip(false) or '') .. ' ' .. B.T(B.esc(cc.trait_d or '')) .. '</div>'
  end
   local crow = (#cls > 0) and ('<div class="ar ar-cls"><span class="arl">' .. B.U("직업") .. '</span><div class="btns">' .. table.concat(cls) .. '</div></div>')
     or ('<div class="ar ar-cls none"><span class="arl">' .. B.U("직업") .. '</span><div class="arn">' .. B.U("직업 스킬이 없습니다. 패시브만으로 싸웁니다") .. '</div></div>')
   return '<section class="ap' .. late .. '"><div class="acth"><span class="hd">' .. B.T(d.name) .. ' / ' .. B.T(d.cls) .. '</span><span>' .. B.U("행동을 고르세요") .. '</span></div>' ..
    psl .. crow ..
     '<div class="ar ar-com"><span class="arl">' .. B.U("공통") .. '</span><div class="btns">' .. table.concat(com) .. '</div></div>' ..
     (st.qid and '' or ('<div class="rt"><button type="button" class="rst" risu-btn="reset">' .. B.U("다시 싸우기") .. '</button></div>')) .. '</section>'
end

function B.r_log(st) B.__r23_cov.calls["50-render.lua:426"]=true; 
  local out = {}
  for n, l in ipairs(st.log) do B.__r23_cov.branches["50-render.lua:428:25235"]=true; 
    local cur = (n == #st.log) and " cur" or ""
    if l.t >= 0 then B.__r23_cov.branches["50-render.lua:430:25302"]=true; 
      out[#out + 1] = '<div class="ln nw' .. cur .. '" style="--t:' .. f2(l.t) .. 's">' .. l.h .. '</div>'
    else B.__r23_cov.branches["50-render.lua:432:25418"]=true; 
      out[#out + 1] = '<div class="ln' .. cur .. '">' .. l.h .. '</div>'
    end
  end
  return '<section class="log">' .. table.concat(out) .. '</section>'
end

function B.render(st) B.__r23_cov.calls["50-render.lua:439"]=true; 
  local ev = st.ev
  local L = { u = {}, panel = "", field = "", party = "", hit = {}, hk = {}, icwf = {}, bz = {}, cls = {}, vars = {}, lun = {}, trg = {}, drn = {}, spawn = {}, taunt = nil, cuts = {} }
  local D = 0
  if ev then B.__r23_cov.branches["50-render.lua:443:25833"]=true; 
    if st.over == "win" then B.__r23_cov.branches["50-render.lua:444:25862"]=true;    -- 마지막 일격(슬로모션): 이기는 판에서 마지막으로 쓰러뜨린 사건
      local lastE
      for _, e in ipairs(ev.list) do B.__r23_cov.branches["50-render.lua:446:25960"]=true; 
        for _, r in ipairs(e.tg or {}) do B.__r23_cov.branches["50-render.lua:447:26002"]=true;  if r.kill == 1 and r.i >= 5 then B.__r23_cov.branches["50-render.lua:447:26033"]=true;  lastE = e end end
      end
      if lastE then B.__r23_cov.branches["50-render.lua:449:26081"]=true;  lastE.last = true end
    end
    for _, e in ipairs(ev.list) do B.__r23_cov.branches["50-render.lua:451:26148"]=true;  B.fx_event(st, e, L) end
    D = ev.T + 0.8
     if st.n == 0 then B.__r23_cov.branches["50-render.lua:453:26213"]=true;  L.field = L.field .. '<b class="intro" style="--t:.3s">' .. B.U("전투 시작") .. '</b>' end
  end
  local phase = "wait"
  if st.over == "" and st.cur >= 1 and st.cur <= 4 then B.__r23_cov.branches["50-render.lua:456:26385"]=true; 
    phase = ((st.pend or 0) > 0 or (st.imenu == 1 and (st.ipk or "") ~= "")) and "target" or "act"
  end
  local target = phase == "target" and ((st.imenu == 1 and (st.ipk or "") ~= "") or (B.SK[st.cur][st.pend].tgt == "ally")) and "ally" or "enemy"
  local seq = tostring(st.seed or 0) .. string.format("%06d%02d%02d%02d", st.n or 0, phase == "act" and 1 or (phase == "target" and 2 or 0), st.imenu or 0, st.pend or 0)
  local css, K = B.dyn(st, D)
  -- 예고 공개: 현재 차례를 1로 셀 때 순서표 2~4번째 안에 들어온 적만
  local vis = {}
  for pos, idx in ipairs(st.q) do B.__r23_cov.branches["50-render.lua:464:26934"]=true; 
    if pos >= 1 and pos <= 4 and idx >= 5 then B.__r23_cov.branches["50-render.lua:465:26979"]=true;  vis[idx] = true end
  end
  local en, al = {}, {}
  if st.fl then B.__r23_cov.branches["50-render.lua:468:27045"]=true;    -- 조합 전투: 후열 먼저, 그다음 전열. 빈 칸은 그리지 않는다
    local back, front = {}, {}
    for j = 5, #st.u do B.__r23_cov.branches["50-render.lua:470:27142"]=true; 
      local dj = B.DEF[j]
      if st.u[j].empty ~= 1 and not dj.empty then B.__r23_cov.branches["50-render.lua:472:27216"]=true; 
        local c = B.r_enemy(st, j, L, K, vis)
        if dj.row == "후열" then B.__r23_cov.branches["50-render.lua:474:27293"]=true;  back[#back + 1] = c else B.__r23_cov.branches["50-render.lua:474:27318"]=true;  front[#front + 1] = c end
      end
    end
     if #back > 0 then B.__r23_cov.branches["50-render.lua:477:27385"]=true;  en[#en + 1] = '<span class="rowlb">' .. B.U("후열") .. '</span>'; for _, c in ipairs(back) do B.__r23_cov.branches["50-render.lua:477:27479"]=true;  en[#en + 1] = c end end
     if #front > 0 then B.__r23_cov.branches["50-render.lua:478:27525"]=true;  en[#en + 1] = '<span class="rowlb">' .. B.U("전열") .. '</span>'; for _, c in ipairs(front) do B.__r23_cov.branches["50-render.lua:478:27620"]=true;  en[#en + 1] = c end end
  else B.__r23_cov.branches["50-render.lua:479:27649"]=true; 
     en[#en + 1] = '<span class="rowlb">' .. B.U("후열") .. '</span>'
    en[#en + 1] = B.r_enemy(st, 7, L, K, vis)
    en[#en + 1] = B.r_enemy(st, 8, L, K, vis)
     en[#en + 1] = '<span class="rowlb">' .. B.U("전열") .. '</span>'
    en[#en + 1] = B.r_enemy(st, 5, L, K, vis)
    en[#en + 1] = B.r_enemy(st, 6, L, K, vis)
  end
  for i = 1, 4 do B.__r23_cov.branches["50-render.lua:487:27995"]=true;  al[#al + 1] = B.r_ally(st, i, L, K) end
  table.sort(L.bz, function(p, q) B.__r23_cov.calls["50-render.lua:488"]=true;  if p.rank ~= q.rank then B.__r23_cov.branches["50-render.lua:488:28092"]=true;  return p.rank > q.rank end return p.t < q.t end)
  local bzs = {}
  for _, x in ipairs(L.bz) do B.__r23_cov.branches["50-render.lua:490:28190"]=true; 
    if #bzs == 0 or (#bzs == 1 and math.abs(x.t - bzs[1].t) > 0.25) then B.__r23_cov.branches["50-render.lua:491:28261"]=true;  bzs[#bzs + 1] = x end
  end
  local function bzo(c, x) B.__r23_cov.calls["50-render.lua:493"]=true; 
    if not x then B.__r23_cov.branches["50-render.lua:494:28334"]=true;  return '<div class="' .. c .. '">' end
    return '<div class="' .. c .. ' ' .. x.cls .. '" style="--bt:' .. f2(x.t) .. 's' .. ((x.k and x.k > 1) and (';--k:' .. x.k) or '') .. '">'
  end
  local p = {}
  p[#p + 1] = '<div class="bt-root" data-bt="1" data-dk-phase="' .. phase .. '" data-dk-seq="' .. seq .. '" data-dk-delay="' .. B.floor(D * 1000 + 0.5) .. '">' .. '<i data-dk-mark="1" style="display:none">' .. phase .. '|' .. seq .. '|' .. B.floor(D * 1000 + 0.5) .. '|' .. table.concat(L.cuts, ",") .. '</i>' .. css   -- 편의 플러그인(plugin/abyss-scroll.js)이 이 작은 글만 읽는다(전투 HTML 전체를 읽으면 폰에서 채팅이 멈췄다)
  p[#p + 1] = '<div class="bpw"><div class="bp">' .. bzo("bpi", bzs[1]) .. bzo("bpj", bzs[2])
  p[#p + 1] = B.r_head(st)
  p[#p + 1] = B.r_rail(st)
  if st.raid == 1 and st.fl and B.raid_field then B.__r23_cov.branches["50-render.lua:502:29131"]=true;    -- 레이드 화면(51-raid): 위쪽 절반을 보스 하나가 차지한다
    p[#p + 1] = B.raid_field(st, L, K, vis, phase == "target" and target == "enemy")
  else B.__r23_cov.branches["50-render.lua:504:29264"]=true; 
    p[#p + 1] = '<section class="fld" data-dk-zone="foe"' .. (phase == "target" and target == "enemy" and ' data-dk-anchor="target"' or '') .. '>' .. table.concat(en) .. '<div class="fldfx">' .. L.field .. '</div></section>'
  end
  p[#p + 1] = '<section class="pty" data-dk-zone="ally"' .. (phase == "target" and target == "ally" and ' data-dk-anchor="target"' or '') .. '><div class="pcs">' .. table.concat(al) .. '</div><div class="fxz">' .. L.party .. '</div></section>'
  local act = B.r_act(st, D)
  if phase == "act" then B.__r23_cov.branches["50-render.lua:509:29793"]=true;  act = act:gsub("^<section", '<section data-dk-anchor="act"', 1) end
  p[#p + 1] = act
  p[#p + 1] = B.r_log(st)
  p[#p + 1] = '</div></div><div class="pfx">' .. L.panel .. '</div></div></div></div>'
  local html = table.concat(p, "\n")
  html = html:gsub("\n\n+", "\n")
  return html
end
