-- ===== 연출 조각 (기록장 st.ev 의 사건 → HTML 조각) =====
-- 🔴 여기서 만든 문자열에는 빈 줄도, 줄머리 들여쓰기도 없다. 모든 시간은 인라인 CSS 변수 --t(= animation-delay).
-- 사건 e = { k, a(행동자), t(시작 초), ht(맞는 시각), tg = { {i, d, sh, c, kill, ab, list, tags} }, nm }

local function f2(x) B.__r23_cov.calls["40-fx.lua:5"]=true;  return string.format("%.2f", x) end
local function sv(t, x) B.__r23_cov.calls["40-fx.lua:6"]=true;  return 'style="--t:' .. f2(t) .. 's' .. (x and (';' .. x) or '') .. '"' end
local function put(L, i, s) B.__r23_cov.calls["40-fx.lua:7"]=true;  L.u[i] = (L.u[i] or "") .. s end

function B.fx_dn(txt, t, cls, left, top) B.__r23_cov.calls["40-fx.lua:9"]=true; 
  return '<b class="dn ' .. (cls or "") .. '" ' .. sv(t, (left and ('left:' .. left .. '%;') or '') .. (top and ('top:' .. top .. '%') or '')) .. '>' .. txt .. '</b>'
end

function B.fx_cn(txt, t) B.__r23_cov.calls["40-fx.lua:13"]=true; 
   return '<b class="cn" ' .. sv(t) .. '><small>' .. B.U("치명타") .. '</small>' .. txt .. '</b>'
end

function B.fx_plaque(txt, t, cls) B.__r23_cov.calls["40-fx.lua:17"]=true; 
  return '<span class="sk ' .. (cls or "") .. '" ' .. sv(t) .. '>' .. txt .. '</span>'
end

-- ===== 명중 묶음(영상 연출 순서 틀: 명중 t₀ → 히트스탑 → 넉백·흔들림·숫자) =====
-- 연출 강도 tier: 0 일반 · 1 중요(스킬·약점·치명) · 2 클라이맥스(마지막 일격). 시트는 CSS 클래스 fx-<이름> (webp data URI).
local ELF = { fire = "fire", ice = "ice", bolt = "bolt", wind = "wind", holy = "holy", dark = "dark" }
local HS = { [0] = 0, [1] = 0.10, [2] = 0.15 }
local SZ = { [0] = 84, [1] = 112, [2] = 150 }

local function kx(k) B.__r23_cov.calls["40-fx.lua:27"]=true;  return (k and k > 1) and (';--k:' .. k) or '' end

-- 판 흔들림·줌 펀치 후보. 렌더가 가장 센 둘을 고른다.
function B.bz_add(L, cls, t, k, rank) B.__r23_cov.calls["40-fx.lua:30"]=true; 
  L.bz[#L.bz + 1] = { cls = cls, t = t, k = k, rank = rank }
end

-- 표적 i 에 명중. 돌려주는 값 = 히트스탑(초)
function B.fx_hit(L, i, t, o) B.__r23_cov.calls["40-fx.lua:35"]=true; 
  local tier, k = o.tier or 0, o.k
  local hs = HS[tier]
  local ex = kx(k)
  if o.arc then B.__r23_cov.branches["40-fx.lua:39:1614"]=true;  put(L, i, '<i class="arc fx-arc" ' .. sv(t - 0.16, '--s:' .. o.arc .. 'px;--r:' .. (o.r or -18) .. 'deg' .. ex) .. '></i>') end
  put(L, i, '<i class="spr fx-' .. (ELF[o.el or ""] or "hit") .. '" ' .. sv(t, '--s:' .. SZ[tier] .. 'px' .. ex) .. '></i>')
  if o.crit then B.__r23_cov.branches["40-fx.lua:41:1884"]=true;  put(L, i, '<i class="crt fx-crit" ' .. sv(t, '--s:' .. (tier == 2 and 200 or 150) .. 'px' .. ex) .. '></i>') end
  if i <= 4 then B.__r23_cov.branches["40-fx.lua:42:2014"]=true; 
    if not L.icwf[i] then B.__r23_cov.branches["40-fx.lua:43:2040"]=true;  L.icwf[i] = t end
  else B.__r23_cov.branches["40-fx.lua:44:2065"]=true; 
    put(L, i, '<i class="wf" ' .. sv(t, '--p:' .. ((tier == 2) and '.75' or (tier == 1 and '.55' or '.4')) .. ex) .. '></i>')
  end
  if o.abfx then B.__r23_cov.branches["40-fx.lua:47:2214"]=true;  put(L, i, '<i class="hf ab" ' .. sv(t) .. '></i>') end
  if not L.hit[i] then B.__r23_cov.branches["40-fx.lua:48:2292"]=true;  L.hit[i] = t + hs; L.hk[i] = k end
  if tier == 1 then B.__r23_cov.branches["40-fx.lua:49:2347"]=true;  B.bz_add(L, "z3", t + hs, nil, 1) end
  if tier == 2 then B.__r23_cov.branches["40-fx.lua:50:2405"]=true;  B.bz_add(L, "z6", t + hs, k, 3) end
  return hs
end

local function tagcls(s) B.__r23_cov.calls["40-fx.lua:54"]=true; 
  if s:find("약점", 1, true) then B.__r23_cov.branches["40-fx.lua:55:2515"]=true;  return "w" end
  if s:find("고갈", 1, true) then B.__r23_cov.branches["40-fx.lua:56:2562"]=true;  return "a" end
  if s:find("여우불", 1, true) then B.__r23_cov.branches["40-fx.lua:57:2610"]=true;  return "f" end
  return ""
end

-- 심연 깎기 숫자(표적 + 전염 받은 적들)
function B.fx_abyss(L, r, t) B.__r23_cov.calls["40-fx.lua:62"]=true; 
  if (r.ab or 0) > 0 then B.__r23_cov.branches["40-fx.lua:63:2724"]=true; 
     put(L, r.i, '<b class="abl" ' .. sv(t) .. '><small>' .. B.U("심연") .. '</small>−' .. r.ab .. '</b>')
  end
  for n, c in ipairs(r.list or {}) do B.__r23_cov.branches["40-fx.lua:66:2875"]=true; 
     put(L, c.i, '<b class="abl" ' .. sv(t + 0.35 + n * 0.08) .. '><small>' .. B.U("깨진 유리창 이론") .. '</small>−' .. c.n .. '</b>')
  end
end

-- 표적에 뜨는 피해 숫자 + 반응. o = { el, tier, arc, r, last, abfx }
function B.fx_result(L, r, t, o) B.__r23_cov.calls["40-fx.lua:72"]=true; 
  o = o or {}
  local i = r.i
  local tier = o.tier or 0
  local weak = false
  for _, x in ipairs(r.tags or {}) do B.__r23_cov.branches["40-fx.lua:77:3223"]=true;  if x:find("약점", 1, true) then B.__r23_cov.branches["40-fx.lua:77:3251"]=true;  weak = true end end
  if (r.c == 1 or weak) and tier < 1 then B.__r23_cov.branches["40-fx.lua:78:3313"]=true;  tier = 1 end
  local k = nil
  if o.last then B.__r23_cov.branches["40-fx.lua:80:3359"]=true;  tier = 2; k = 2 end
  local hs = B.fx_hit(L, i, t, { el = o.el, tier = tier, arc = o.arc, r = o.r, k = k, crit = (r.c == 1), abfx = o.abfx })
  local td = t + hs
  local ex = kx(k)
  if r.c == 1 then B.__r23_cov.branches["40-fx.lua:84:3559"]=true; 
    put(L, i, B.fx_cn(r.d, td))
  elseif r.sh >= r.d then B.__r23_cov.branches["40-fx.lua:86:3617"]=true; 
     put(L, i, B.fx_dn(B.U("막음 {n}", { n = r.d }), td, "sh"))
  else B.__r23_cov.branches["40-fx.lua:88:3686"]=true; 
    local cls = (i <= 4) and "h" or ((r.d >= 600) and "huge" or ((r.d >= 300) and "big" or ""))
    put(L, i, B.fx_dn(r.d, td, cls))
  end
   if r.sh > 0 and r.sh < r.d then B.__r23_cov.branches["40-fx.lua:92:3860"]=true;  put(L, i, B.fx_dn(B.U("보호막 -{n}", { n = r.sh }), td + 0.25, "g", 50, 56)) end
  if r.tags and #r.tags > 0 then B.__r23_cov.branches["40-fx.lua:93:3971"]=true; 
    local tg = {}
    for _, x in ipairs(r.tags) do B.__r23_cov.branches["40-fx.lua:95:4025"]=true;  tg[#tg + 1] = '<span class="' .. tagcls(x) .. '">' .. x .. '</span>' end
    put(L, i, '<span class="tg" ' .. sv(td) .. '>' .. table.concat(tg) .. '</span>')
  end
  B.fx_abyss(L, r, td + 0.1)
end

function B.fx_cutin(L, a, nm, line, t) B.__r23_cov.calls["40-fx.lua:101"]=true; 
  B.bz_add(L, "zz", t, nil, 2.5)
  if L.cuts then B.__r23_cov.branches["40-fx.lua:103:4310"]=true;  L.cuts[#L.cuts + 1] = B.floor(t * 1000 + 0.5) end   -- 편의 플러그인이 컷인 시각에 화면을 컷인으로 옮긴다(data-dk-mark 넷째 칸)
  L.panel = L.panel .. '<div class="cut" data-dk-cut="1" ' .. sv(t) .. '><div class="band"><i class="spd"></i><div class="art art-' .. B.DEF[a].art .. '"></div></div>' ..
     '<div class="txt"><small>' .. B.U("고유 스킬: {name}", { name = B.DEF[a].name }) .. '</small><b>' .. B.T(nm) .. '</b>' .. ((line and line ~= "") and ('<em>「' .. B.T(line) .. '」</em>') or '') .. '</div></div>'
end

-- 페르소나 고유 스킬 컷인: 프로필 이미지(채팅 변수 dk_pimg — 인레이 토큰 · data: · https)가 가운데에서 커지며 금빛 테두리와 스킬 이름 띠가 나온다.
-- 이미지를 못 받았으면 직업 아이콘을 크게 보여 준다. 편의 플러그인이 읽는 data-dk-cut · L.cuts 는 동료 컷인과 같다.
function B.fx_pcutin(L, a, nm, t) B.__r23_cov.calls["40-fx.lua:110"]=true; 
  B.bz_add(L, "zz", t, nil, 2.5)
  if L.cuts then B.__r23_cov.branches["40-fx.lua:112:5061"]=true;  L.cuts[#L.cuts + 1] = B.floor(t * 1000 + 0.5) end
  local ok, s = false, nil
  if B.VID then B.__r23_cov.branches["40-fx.lua:114:5154"]=true;  ok, s = pcall(getChatVar, B.VID, B.PIMG_KEY) end
  local has = ok and type(s) == "string" and (s:match("^{{inlayed::[^}]+}}$") or s:match("^data:image/") or s:match("^https?://")) ~= nil
  local pic
  if has then B.__r23_cov.branches["40-fx.lua:117:5367"]=true; 
    pic = (s:sub(1, 2) == "{{") and ('<span class="pc-img">' .. s .. '</span>') or ('<img class="pc-img" src="' .. B.esc(s) .. '" alt="">')
  else B.__r23_cov.branches["40-fx.lua:119:5514"]=true; 
    -- 포켓리스는 페르소나 그림 받아 오기(getPersonaImage)가 서버 오류로 실패한다 — 전투 카드(B.pimg)처럼 {{source::user}} 를 직업 아이콘 위에 덮는다.
    -- 페르소나 그림이 없으면 빈 주소라 아이콘이 그대로 보인다.
    pic = '<span class="pc-img pc-ic"><i class="im im-cls-' .. (B.DEF[a].clsid or "") .. '"></i><span class="pc-src" style="background-image:url(\'{{source::user}}\')"></span></span>'
  end
  L.panel = L.panel .. '<div class="cut pcut" data-dk-cut="1" ' .. sv(t) .. '><div class="pc-ring">' .. pic .. '</div>' ..
    '<div class="pc-name"><small>' .. B.U("고유 스킬: {name}", { name = B.DEF[a].name }) .. '</small><b>' .. B.T(nm) .. '</b></div></div>'
end

function B.fx_event(st, e, L) B.__r23_cov.calls["40-fx.lua:128"]=true; 
  local t, k, a = e.t, e.k, e.a
  if k == "atk" or k == "snipe" then B.__r23_cov.branches["40-fx.lua:130:6215"]=true; 
    local r = e.tg[1]
    local ht = e.ht or (t + 0.4)
     put(L, a, '<i class="av" ' .. sv(t) .. '></i>' .. ((e.nm ~= "일반 공격") and B.fx_plaque(B.T(e.nm), t + 0.1, (a == 1) and "ab" or "") or ""))
    if k == "snipe" then B.__r23_cov.branches["40-fx.lua:134:6438"]=true; 
      put(L, r.i, '<i class="xh" ' .. sv(ht - 0.75) .. '></i><i class="ar" ' .. sv(ht - 0.3) .. '></i>')
    end
    B.fx_result(L, r, ht, { el = e.el, tier = (e.nm == "일반 공격") and 0 or 1, arc = (a == 2) and 96 or nil, r = 24, last = e.last, abfx = (a == 1) })
  elseif k == "wave" then B.__r23_cov.branches["40-fx.lua:138:6725"]=true; 
    put(L, a, B.fx_plaque(B.T(e.nm), t + 0.1, "ab"))
    L.field = L.field .. '<i class="fflash" ' .. sv(e.ht - 0.2) .. '></i>'
    for n, r in ipairs(e.tg) do B.__r23_cov.branches["40-fx.lua:141:6887"]=true; 
      B.fx_result(L, r, e.ht + (n - 1) * 0.07, { el = e.el, tier = 1, last = e.last, abfx = true })
    end
  elseif k == "burst" then B.__r23_cov.branches["40-fx.lua:144:7020"]=true; 
    put(L, a, B.fx_plaque(B.T(e.nm), t + 1.2))
    L.field = L.field .. '<div class="mcw" ' .. sv(t + 1.3) .. '><i class="mc m1"></i><i class="mc m2"></i><i class="mc m3"></i><i class="mc m4"></i><i class="mc m5"></i><i class="mc m6"></i></div>' ..
      '<i class="shw" ' .. sv(e.ht - 0.25) .. '></i>'
    for n, r in ipairs(e.tg) do B.__r23_cov.branches["40-fx.lua:148:7357"]=true; 
      B.fx_result(L, r, e.ht + 0.05 + (n - 1) * 0.07, { el = e.el, tier = 1, last = e.last })
    end
  elseif k == "eatk" then B.__r23_cov.branches["40-fx.lua:151:7483"]=true; 
    put(L, a, '<i class="av" ' .. sv(t) .. '></i>' .. (e.nm and ('<span class="sk e" ' .. sv(t) .. '>' .. B.T(e.nm) .. '</span>') or ''))
    L.lun[a] = t + 0.15
    local r = e.tg[1]
    local tr = (e.big == 1) and 1 or 0   -- 충전 뒤 큰 기술은 한 단계 크게
    if e.shoot == 1 then B.__r23_cov.branches["40-fx.lua:156:7755"]=true; 
      put(L, r.i, '<i class="bolt" ' .. sv(t + 0.28) .. '></i>')
      B.fx_result(L, r, t + 0.62, { tier = tr })
    else B.__r23_cov.branches["40-fx.lua:159:7878"]=true; 
      B.fx_result(L, r, t + 0.52, { tier = tr, arc = 92, r = 24 })
    end
  elseif k == "shield" then B.__r23_cov.branches["40-fx.lua:162:7981"]=true; 
    put(L, a, B.fx_plaque(B.T(e.nm), t + 1.0))
    L.party = L.party .. '<div class="dome" ' .. sv(t + 1.0) .. '><i class="dglow"></i><i class="lat"></i><i class="rimg"></i></div>'
    for n = 1, 14 do B.__r23_cov.branches["40-fx.lua:165:8185"]=true; 
      local x = (n * 37) % 92 + 4
      local dx = ((n * 53) % 50) - 25
      L.party = L.party .. '<i class="mo" ' .. sv(t + 1.2 + (n % 7) * 0.18, 'left:' .. x .. '%;--x:' .. dx .. 'px') .. '></i>'
    end
    for n, r in ipairs(e.tg) do B.__r23_cov.branches["40-fx.lua:170:8424"]=true; 
      put(L, r.i, B.fx_dn("+" .. r.d, t + 1.5 + n * 0.1, "sh", 20, 40))
      L.cls[r.i] = (L.cls[r.i] or "") .. " shd"
      L.vars[r.i] = '--t:' .. f2(t + 1.45 + n * 0.1) .. 's'
    end
  elseif k == "taunt" then B.__r23_cov.branches["40-fx.lua:175:8637"]=true; 
    put(L, a, B.fx_plaque(B.T(e.nm), t + 0.1))
    for i = 5, #st.u do B.__r23_cov.branches["40-fx.lua:177:8710"]=true; 
      if st.u[i].al == 1 or (st.ev.pre[i].hp > 0) then B.__r23_cov.branches["40-fx.lua:178:8763"]=true; 
        put(L, i, '<i class="rg" ' .. sv(t + 0.2 + (i - 5) * 0.08) .. '></i><i class="tf0" ' .. sv(t + 0.2) .. '></i>')
      end
    end
    local r = e.tg[1]
    local hs = B.fx_hit(L, r.i, t + 0.9, { el = "holy", tier = 1 })
    B.fx_abyss(L, r, t + 0.95 + hs)
    L.taunt = t + 0.3
  elseif k == "def" then B.__r23_cov.branches["40-fx.lua:186:9074"]=true; 
    put(L, a, B.fx_plaque(B.T(e.nm), t + 0.05))
    L.cls[a] = (L.cls[a] or "") .. " shd"
    L.vars[a] = '--t:' .. f2(t + 0.1) .. 's'
  elseif k == "oath" then B.__r23_cov.branches["40-fx.lua:190:9235"]=true; 
    put(L, a, B.fx_plaque(B.T(e.nm), t + 0.1))
    L.cls[a] = (L.cls[a] or "") .. " shd"
    L.vars[a] = '--t:' .. f2(t + 0.2) .. 's'
    local ti = e.tg[1].i
    if ti ~= a then B.__r23_cov.branches["40-fx.lua:195:9414"]=true; 
      L.cls[ti] = (L.cls[ti] or "") .. " shd"
      L.vars[ti] = '--t:' .. f2(t + 0.5) .. 's'
    end
  elseif k == "mark" then B.__r23_cov.branches["40-fx.lua:199:9542"]=true; 
    put(L, a, B.fx_plaque(B.T(e.nm), t + 0.1))
    local r = e.tg[1]
    put(L, r.i, '<i class="xh keep" ' .. sv(t + 0.3) .. '></i>')
    B.fx_abyss(L, r, t + 0.85)
  elseif k == "rev" then B.__r23_cov.branches["40-fx.lua:204:9732"]=true; 
    put(L, a, B.fx_plaque(B.T(e.nm), t + 0.1, "ab"))
    put(L, a, B.fx_dn("-" .. e.d, t + 0.3, "h"))
    put(L, a, '<i class="hf" ' .. sv(t + 0.3) .. '></i>')
  elseif k == "chg" then B.__r23_cov.branches["40-fx.lua:208:9917"]=true; 
     put(L, a, B.fx_plaque(B.U("마력 폭발 - 충전"), t + 0.1))
    local ti = e.tg[1].i
     put(L, ti, B.fx_dn(B.U("지연"), t + 0.8, "g") .. '<i class="hf w" ' .. sv(t + 0.7) .. '></i>')
  elseif k == "cut" then B.__r23_cov.branches["40-fx.lua:212:10121"]=true; 
    if e.pc then B.__r23_cov.branches["40-fx.lua:213:10138"]=true;  B.fx_pcutin(L, a, e.nm, t) else B.__r23_cov.branches["40-fx.lua:213:10170"]=true;  B.fx_cutin(L, a, e.nm, e.line, t) end
  elseif k == "trait" then B.__r23_cov.branches["40-fx.lua:214:10235"]=true; 
    put(L, a, '<span class="trp' .. (e.ab == 1 and " ab" or "") .. '" ' .. sv(t) .. '><i class="im im-t-' .. B.DEF[a].art .. '"></i>' .. B.T(e.nm) .. '</span>')
    L.trg[a] = t
  elseif k == "deplete" then B.__r23_cov.branches["40-fx.lua:217:10442"]=true; 
     put(L, a, '<i class="hf ab" ' .. sv(t) .. '></i><i class="spr fx-burst" ' .. sv(t, '--s:220px') .. '></i><div class="drb" ' .. sv(t + 0.05) .. '><b>' .. B.U("심연 고갈") .. '</b><small>' .. B.U("다음 차례 상실, 받는 피해 ×1.5") .. '</small></div>')
    L.drn[a] = t
    L.panel = L.panel .. '<i class="vig" ' .. sv(t) .. '></i>'
    B.bz_add(L, "z6", t, nil, 3)
  elseif k == "recover" then B.__r23_cov.branches["40-fx.lua:222:10824"]=true; 
     put(L, a, B.fx_dn(B.U("심연 회복"), t + 0.5, "ab"))
  elseif k == "edef" then B.__r23_cov.branches["40-fx.lua:224:10903"]=true; 
    put(L, a, '<span class="sk e" ' .. sv(t) .. '>' .. B.T(e.nm) .. '</span>')
  elseif k == "ebuff" then B.__r23_cov.branches["40-fx.lua:226:11009"]=true; 
    put(L, a, '<span class="sk e" ' .. sv(t) .. '>' .. B.T(e.nm) .. '</span><i class="hf" ' .. sv(t + 0.1) .. '></i>')
    for _, r in ipairs(e.tg or {}) do B.__r23_cov.branches["40-fx.lua:228:11168"]=true; 
      if r.i ~= a then B.__r23_cov.branches["40-fx.lua:229:11189"]=true;  put(L, r.i, '<i class="hf" ' .. sv(t + 0.3) .. '></i>') end
    end
  elseif k == "eall" then B.__r23_cov.branches["40-fx.lua:231:11283"]=true;    -- 적 전체 공격 · 전체 큰 기술
    put(L, a, '<i class="av" ' .. sv(t) .. '></i><span class="sk e" ' .. sv(t) .. '>' .. B.T(e.nm) .. '</span>')
    L.lun[a] = t + 0.15
    local tr = (e.big == 1) and 1 or 0
    if tr == 1 then B.__r23_cov.branches["40-fx.lua:235:11502"]=true;  L.party = L.party .. '<i class="fflash" ' .. sv(t + 0.45) .. '></i>' end
    for n, r in ipairs(e.tg) do B.__r23_cov.branches["40-fx.lua:236:11609"]=true; 
      B.fx_result(L, r, t + 0.62 + (n - 1) * 0.07, { tier = tr })
    end
  elseif k == "edeb" then B.__r23_cov.branches["40-fx.lua:239:11707"]=true;    -- 약화 · 지속 피해 · 침묵
    put(L, a, '<span class="sk e" ' .. sv(t) .. '>' .. B.T(e.nm) .. '</span>')
     for _, r in ipairs(e.tg or {}) do B.__r23_cov.branches["40-fx.lua:241:11848"]=true;  put(L, r.i, '<i class="hf w" ' .. sv(t + 0.45) .. '></i>' .. B.fx_dn(B.U("약화"), t + 0.6, "g")) end
  elseif k == "eheal" then B.__r23_cov.branches["40-fx.lua:242:11972"]=true; 
    put(L, a, '<span class="sk e" ' .. sv(t) .. '>' .. B.T(e.nm) .. '</span>')
    for _, r in ipairs(e.tg or {}) do B.__r23_cov.branches["40-fx.lua:244:12091"]=true;  put(L, r.i, B.fx_dn("+" .. r.d, t + 0.7, "sh", 20, 40) .. '<i class="hf" ' .. sv(t + 0.5) .. '></i>') end
  elseif k == "item" then B.__r23_cov.branches["40-fx.lua:245:12221"]=true;    -- 아이템 사용(78-battle-item): 이름표 + 대상에 회복 숫자
    put(L, a, B.fx_plaque(B.T(e.nm), t + 0.1))
    for _, r in ipairs(e.tg or {}) do B.__r23_cov.branches["40-fx.lua:247:12353"]=true; 
       local txt = (r.f == "mp") and ("MP +" .. r.d) or ((r.f == "cure") and B.U("해제") or ((r.f == "sh") and B.U("보호막 +{n}", { n = r.d }) or ("+" .. r.d)))
      put(L, r.i, B.fx_dn(txt, t + 0.7, (r.f == "mp") and "ab" or "sh", 20, 40) .. '<i class="hf" ' .. sv(t + 0.5) .. '></i>')
    end
  elseif k == "esum" then B.__r23_cov.branches["40-fx.lua:251:12668"]=true;    -- 소환: 새 칸이 번쩍이며 나타난다
    put(L, a, '<span class="sk e" ' .. sv(t) .. '>' .. B.T(e.nm) .. '</span>')
    L.spawn = L.spawn or {}
    for _, r in ipairs(e.tg or {}) do B.__r23_cov.branches["40-fx.lua:254:12839"]=true;  L.spawn[r.i] = t + 0.6 end
  elseif k == "echg" then B.__r23_cov.branches["40-fx.lua:255:12890"]=true;    -- 충전
    put(L, a, '<span class="sk e" ' .. sv(t) .. '>' .. B.T(e.nm) .. '</span><i class="hf ab" ' .. sv(t + 0.2) .. '></i>')
  elseif k == "ecut" then B.__r23_cov.branches["40-fx.lua:257:13046"]=true;    -- 충전이 끊겼다
     put(L, a, B.fx_dn(B.U("충전 끊김"), t + 0.3, "ab"))
  elseif k == "phase" then B.__r23_cov.branches["40-fx.lua:259:13139"]=true;   -- 단계 전환
     L.panel = L.panel .. '<div class="phb" ' .. sv(t) .. '><b>' .. B.U("2단계") .. '</b><small>' .. B.T(e.nm) .. '</small></div>'
    B.bz_add(L, "z6", t + 0.2, 2, 3)
  elseif k == "adot" then B.__r23_cov.branches["40-fx.lua:262:13341"]=true;    -- 아군이 받는 지속 피해
    B.fx_result(L, e.tg[1], t + 0.3, { tier = 0 })
  elseif k == "end" then B.__r23_cov.branches["40-fx.lua:264:13435"]=true; 
    if e.win == 1 then B.__r23_cov.branches["40-fx.lua:265:13458"]=true; 
       L.panel = L.panel .. '<div class="vic" ' .. sv(t) .. '><i class="dim"></i><i class="vsw"></i><i class="vem"></i><i class="vem e2"></i><div class="vban"><b>' .. B.U("승리") .. '</b></div><i class="vfl"></i></div>'
    else B.__r23_cov.branches["40-fx.lua:267:13685"]=true; 
       L.panel = L.panel .. '<div class="vic lose" ' .. sv(t) .. '><i class="dim"></i><div class="vban"><b>' .. B.U("퇴각") .. '</b><small>' .. B.U("전원 부상") .. '</small></div></div>'
    end
  end
end
