-- ===== 레이드 전투 화면 (정본 design/ENEMIES.md 「레이드 전투」) =====
-- 층 끝의 우두머리 · 구역 보스 · 균열 핵(st.raid == 1)은 일반 전투 화면의 「적 칸」 대신 이 보스 패널을 쓴다.
-- 위쪽 절반 = 보스 하나(큰 메달 · 이름 · 단계 표시 · 단계 눈금이 있는 긴 HP 막대 · 큰 심연 게이지 · 약점 · 다음 행동 깃발) + 보스 밑 작은 칸 둘까지(하수인 · 호위).
-- 아래쪽(아군 4 · 스킬 버튼 · 행동 순서표)은 일반 전투와 같다. CSS 는 css/raid.css.
-- 🔴 출력 HTML 에 빈 줄이 없고 줄머리 들여쓰기도 없다. 버튼 값은 tg_5 같은 소문자·숫자·밑줄.

local function f2(x) B.__r23_cov.calls["51-raid.lua:7"]=true;  return string.format("%.2f", x) end

-- 다음 큰 기술까지 몇 차례인지: 충전 중이면 1(다음 차례에 터진다), 다음 행동이 충전이면 2. 아니면 nil.
function B.raid_charge_info(st, i) B.__r23_cov.calls["51-raid.lua:10"]=true; 
  local u, d = st.u[i], B.DEF[i]
  local acts = d.acts
  local a = acts[u.ia]
  if not a then B.__r23_cov.branches["51-raid.lua:14:616"]=true;  return nil end
  if u.cq == 1 then B.__r23_cov.branches["51-raid.lua:15:651"]=true;  return 1, a.name, a end
  if a.kind == "charge" then B.__r23_cov.branches["51-raid.lua:16:704"]=true; 
    local nx = acts[u.ia % #acts + 1]
    return 2, nx.name, a
  end
  return nil
end

local function pips(st, i) B.__r23_cov.calls["51-raid.lua:23"]=true; 
  local u, d = st.u[i], B.DEF[i]
  local f = B.FOES[d.foe or ""]
  if not (f and f.ph2) then B.__r23_cov.branches["51-raid.lua:26:911"]=true;  return "" end
  local on = (u.ph == 2) and 2 or 1
  return '<span class="rdp"><b class="pip' .. (on == 1 and " on" or "") .. '">1</b><b class="pip' .. (on == 2 and " on" or "") .. '">2</b><small>' .. B.U("단계") .. '</small></span>'
end

function B.r_boss(st, i, L, K, vis) B.__r23_cov.calls["51-raid.lua:31"]=true; 
  local u, d = st.u[i], B.DEF[i]
  local ev = st.ev
  local cls = "en rdb" .. (d.elite and " elite" or "") .. (d.boss and " boss" or "") .. (d.deepn and " deep" or "")
  local dies
  if u.al == 0 then B.__r23_cov.branches["51-raid.lua:36:1384"]=true; 
    if ev then B.__r23_cov.branches["51-raid.lua:37:1399"]=true; 
      for _, x in ipairs(ev.h[i]) do B.__r23_cov.branches["51-raid.lua:38:1438"]=true;  if x.f == "hp" and x.v <= 0 then B.__r23_cov.branches["51-raid.lua:38:1469"]=true;  dies = x.t end end
    end
    cls = cls .. (dies and " dying" or " gone")
  end
  local ws = {}
  if dies then B.__r23_cov.branches["51-raid.lua:43:1581"]=true;  ws[#ws + 1] = "--dt:" .. f2(dies + 0.4) .. "s" end
  if L.lun[i] then B.__r23_cov.branches["51-raid.lua:44:1651"]=true;  cls = cls .. " lun"; ws[#ws + 1] = "--lt:" .. f2(L.lun[i]) .. "s" end
  local pend = (st.pend > 0 and st.over == "" and u.al == 1 and B.SK[st.cur][st.pend].tgt == "enemy")
  -- 다음 행동 깃발 / 큰 기술 경고
  local int = ""
  if u.al == 1 and st.over == "" then B.__r23_cov.branches["51-raid.lua:48:1902"]=true; 
    local act = d.acts[u.ia]
    if u.dr == 1 then B.__r23_cov.branches["51-raid.lua:50:1953"]=true; 
      int = '<div class="rdi dep">' .. B.U("고갈: 차례 상실. 지금이 기회다") .. '</div>'
    else B.__r23_cov.branches["51-raid.lua:52:2039"]=true; 
      local n, nm2, cact = B.raid_charge_info(st, i)
      if n then B.__r23_cov.branches["51-raid.lua:54:2108"]=true; 
        int = '<div class="rdi chg"><i class="im im-' .. B.icn("charge") .. '"></i><b>' .. B.U("{n}차례 뒤 {name}", { n = n, name = nm2 }) .. '</b><small>' ..
          B.U(n == 1 and "{name} 충전 중" or "{name} 준비", { name = cact.name }) .. B.U('. 심연을 0으로 깎으면 끊긴다') .. '</small></div>'
      else B.__r23_cov.branches["51-raid.lua:57:2400"]=true; 
        int = B.intent_text(st, i, act, L):gsub('class="int', 'class="rdi', 1)
      end
    end
  end
  local cdc = "cd rdc"
  local cs = {}
  if L.hit[i] then B.__r23_cov.branches["51-raid.lua:64:2561"]=true;  cdc = cdc .. " hit"; cs[#cs + 1] = "--kt:" .. f2(L.hit[i]) .. "s" .. ((L.hk[i] or 1) > 1 and (";--k:" .. L.hk[i]) or "") end
  if u.dr == 1 and u.al == 1 then B.__r23_cov.branches["51-raid.lua:65:2720"]=true; 
    if L.drn[i] then B.__r23_cov.branches["51-raid.lua:66:2741"]=true;  cdc = cdc .. " drn"; cs[#cs + 1] = "--dt2:" .. f2(L.drn[i]) .. "s"; cdc = cdc:gsub(" hit", "")
    else B.__r23_cov.branches["51-raid.lua:67:2845"]=true;  cdc = cdc .. " dr" end
  end
  local wk = {}
  for _, e in ipairs(d.wk) do B.__r23_cov.branches["51-raid.lua:70:2922"]=true;  wk[#wk + 1] = '<i class="el im im-' .. e .. '"></i>' end
  local notch = (d.ph2 and u.ph == 1) and string.format("%d", B.floor(B.BOSSR.phase_hp * 100 + 0.5)) or nil
  return '<div class="' .. cls .. '" data-u="' .. i .. '"' .. (#ws > 0 and (' style="' .. table.concat(ws, ";") .. '"') or '') .. '>' ..
    ((d.elite or d.boss) and ('<i class="eb im im-elite big"></i>') or '') ..
    '<div class="' .. cdc .. '"' .. (#cs > 0 and (' style="' .. table.concat(cs, ";") .. '"') or '') .. '>' ..
    '<div class="rdh"><div class="rdm"><i class="im im-' .. d.ic .. '"></i></div>' ..
     '<div class="rdn"><b>' .. B.T(d.name) .. '</b><small>' .. B.T(d.lv) .. '</small>' .. pips(st, i) .. '</div></div>' ..
    int ..
    '<div class="rdg">' ..
    B.hp_stat("HP", "hp", u, "hp", u.mhp, K, i, true, false, notch) ..
     B.hp_stat(B.U("심연"), "ab", u, "ay", u.ym, K, i, true, true) ..
    '</div>' ..
     '<div class="wk"><b>' .. B.U("약점") .. '</b>' .. table.concat(wk) .. '</div>' ..
    '<div class="sts">' .. B.chips(st, i) .. '</div><i class="crk fx-crack"></i></div>' ..
    '<div class="fxl">' .. (L.u[i] or "") .. '</div>' ..
     (pend and ('<button type="button" class="tgt" risu-btn="tg_' .. i .. '">' .. B.U("대상 선택") .. '</button>') or '') ..
    '</div>'
end

-- 보스 패널 + 보스 밑 작은 칸(하수인 · 호위). B.render 가 st.raid == 1 일 때 일반 적 칸 대신 부른다.
function B.raid_field(st, L, K, vis, target) B.__r23_cov.calls["51-raid.lua:90"]=true; 
  local boss = B.r_boss(st, 5, L, K, vis)
  local adds = {}
  for j = 6, #st.u do B.__r23_cov.branches["51-raid.lua:93:4389"]=true; 
    local dj = B.DEF[j]
    if st.u[j].empty ~= 1 and not dj.empty then B.__r23_cov.branches["51-raid.lua:95:4459"]=true;  adds[#adds + 1] = B.r_enemy(st, j, L, K, vis) end
  end
  return '<section class="fld rdf" data-dk-zone="foe"' .. (target and ' data-dk-anchor="target"' or '') .. '>' .. boss .. (#adds > 0 and ('<div class="rdadds">' .. table.concat(adds) .. '</div>') or '') ..
    '<div class="fldfx">' .. L.field .. '</div></section>'
end
