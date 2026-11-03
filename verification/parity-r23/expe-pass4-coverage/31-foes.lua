-- ===== 조합 전투의 적 행동 · 규칙 (정본 design/enemies.json · ENEMIES.md) =====
-- 30-engine.lua 의 enemy_turn 이 st.fl(조합 전투)일 때 여기를 부른다. 옛 4칸 전투(st.fl 없음)는 이 파일을 타지 않는다.
-- 행동 종류: 공격 계열(atk · shoot · aimed · spell · big_one · big_all — 모두 kind = "atk", 꼴은 act.shoot · low · magic · all · big) ·
--   guard · buff · debuff · dot · heal · summon · protect · charge · special.
-- 🔴 결정론: 난수는 B.rnd 만, 순서가 필요한 곳은 고정 배열. 저장 상태는 문자열 키 표와 숫자뿐(u.edot 은 배열).

local function nm(i) B.__expe_cov.calls["31-foes.lua:7"]=true;  return B.T(B.DEF[i].name) end
B.ELEMS = { "fire", "ice", "bolt", "wind", "holy", "dark" }
local STAT_KO = { atk = "공격력", def = "방어", spd = "속도" }
local STRIP_ORDER = { "atk", "def", "bs", "bl", "g2", "red", "red20", "red25" }

local function foes_alive(st, except) B.__expe_cov.calls["31-foes.lua:12"]=true; 
  local l = {}
  for j = 5, #st.u do B.__expe_cov.branches["31-foes.lua:14:760"]=true; 
    if st.u[j].al == 1 and j ~= except then B.__expe_cov.branches["31-foes.lua:15:802"]=true;  l[#l + 1] = j end
  end
  return l
end
local function allies_alive(st) B.__expe_cov.calls["31-foes.lua:19"]=true; 
  local l = {}
  for a = 1, 4 do B.__expe_cov.branches["31-foes.lua:21:908"]=true;  if st.u[a].al == 1 then B.__expe_cov.branches["31-foes.lua:21:930"]=true;  l[#l + 1] = a end end
  return l
end
local function pct(x) B.__expe_cov.calls["31-foes.lua:24"]=true;  return B.floor(x * 100 + 0.5) end

-- 조합 전투의 적 공격 한 줄: 「X의 행동이 Y에게 N 피해를 입혔다(덧붙임)」. 행동 이름이 이미 동작이라 옛 「…를 …했다」 꼴을 쓰지 않는다.
function B.foe_line(st, i, act, res) B.__expe_cov.calls["31-foes.lua:27"]=true; 
  local tg = nm(res.i)
  local s = B.U("<b>{who}</b>의 <b>{action}</b>{particle} {target}에게 <em>{damage}</em> 피해를 입혔다", { who = nm(i), action = act.name, particle = B.josa(act.name, "이가"), target = tg, damage = res.d })
  local ex = {}
  for _, x in ipairs(res.tags or {}) do B.__expe_cov.branches["31-foes.lua:31:1424"]=true;  ex[#ex + 1] = x end
  if (res.sh or 0) > 0 then B.__expe_cov.branches["31-foes.lua:32:1470"]=true;  ex[#ex + 1] = B.U("보호막 {n} 흡수", { n = res.sh }) end
  if #ex > 0 then B.__expe_cov.branches["31-foes.lua:33:1540"]=true;  s = s .. "(" .. table.concat(ex, ", ") .. ")" end
  if res.kill == 1 then B.__expe_cov.branches["31-foes.lua:34:1614"]=true;  s = s .. B.U(". <b>{target}</b>{particle} 부상으로 물러났다", { target = tg, particle = B.josa(tg, "이가") }) end
  return s
end

-- ---------- 전투 시작 ----------
function B.foe_start(st) B.__expe_cov.calls["31-foes.lua:39"]=true; 
  if not st.fl then B.__expe_cov.branches["31-foes.lua:40:1810"]=true;  return end
  for j = 5, #st.u do B.__expe_cov.branches["31-foes.lua:41:1845"]=true; 
    local d = B.DEF[j]
    if st.u[j].al == 1 and d.rules and d.rules.first_move then B.__expe_cov.branches["31-foes.lua:43:1929"]=true;  st.u[j].g = 0 end   -- 철 전차: 행동 순서 맨 앞
  end
end

-- ---------- 받는 쪽 규칙(아군이 적을 칠 때 B.hit 이 곱한다) ----------
function B.foe_defense(st, a, t, o, tags) B.__expe_cov.calls["31-foes.lua:48"]=true; 
  local d, u = B.DEF[t], st.u[t]
  local R = d.rules
  if not R then B.__expe_cov.branches["31-foes.lua:51:2147"]=true;  return 1 end
  local m = 1
  if R.dr_while_ally then B.__expe_cov.branches["31-foes.lua:53:2200"]=true; 
    for _, j in ipairs(foes_alive(st, t)) do B.__expe_cov.branches["31-foes.lua:54:2247"]=true; 
      if B.DEF[j].foe == R.dr_while_ally.enemy then B.__expe_cov.branches["31-foes.lua:55:2297"]=true; 
        m = m * R.dr_while_ally.mult
        tags[#tags + 1] = nm(j) .. B.josa(nm(j), "이가") .. " 서 있다 −" .. pct(1 - R.dr_while_ally.mult) .. "%"
        break
      end
    end
  end
  local melee = (B.DEF[a].line == "힘")
  if R.melee_dr and melee then B.__expe_cov.branches["31-foes.lua:63:2550"]=true; 
    m = m * (1 - R.melee_dr)
    tags[#tags + 1] = "비행 −" .. pct(R.melee_dr) .. "%"
  end
  if R.ranged_dr and (u.hid or 0) == 1 and not melee then B.__expe_cov.branches["31-foes.lua:67:2698"]=true; 
    m = m * (1 - R.ranged_dr)
    tags[#tags + 1] = "은신 −" .. pct(R.ranged_dr) .. "%"
  end
  return m
end

-- 보호 중인 적이 있으면 그 적이 대신 맞는다
function B.protector_of(st, t) B.__expe_cov.calls["31-foes.lua:75"]=true; 
  for e = 5, #st.u do B.__expe_cov.branches["31-foes.lua:76:2889"]=true; 
    local w = st.u[e]
    if e ~= t and w.al == 1 and w.pt == t and w.dr ~= 1 then B.__expe_cov.branches["31-foes.lua:78:2970"]=true;  return e end
  end
  return t
end

-- 적이 맞은 뒤: 되치기(방어 중) · 번짐(약점 속성에 맞으면 다음 차례가 밀린다)
function B.foe_hit_after(st, a, t, res, o, hitT) B.__expe_cov.calls["31-foes.lua:84"]=true; 
  local u, d = st.u[t], B.DEF[t]
  local R = d.rules
  if not R or u.al ~= 1 then B.__expe_cov.branches["31-foes.lua:87:3186"]=true;  return end
  if R.weak_hit_delay and o.el == R.weak_hit_delay.el then B.__expe_cov.branches["31-foes.lua:88:3256"]=true; 
    u.g = u.g + 10000 * R.weak_hit_delay.amount * B.rdm(u)
    B.say(st, "<b>" .. nm(t) .. "</b>의 윤곽이 번진다. 다음 차례가 <em>밀렸다</em>", hitT + 0.2)
  end
  if R.counter_when_guard and u.df == 1 and not st.cgd and st.u[a].al == 1 and a <= 4 then B.__expe_cov.branches["31-foes.lua:92:3494"]=true; 
    st.cgd = 1
    B.e_counter(st, t, a, R.counter_when_guard, hitT + 0.3)
    st.cgd = nil
  end
end

-- 되치기: 적 t 가 아군 a 를 친다(방어에 막히지 않는 한 번의 단일 공격)
function B.e_counter(st, e, a, c, at) B.__expe_cov.calls["31-foes.lua:100"]=true; 
  local u = st.u[e]
  local v = st.u[a]
  local Kc = st.K or B.K_of(st.el or 40)
  local de = v.de * (1 + B.bget(v, "def") - B.bget(v, "ddn"))
  local raw = B.floor(u.cs * (c.m or 0.6) * u.am * (1 - B.bget(u, "adn")) * Kc / (Kc + de))
  if raw < 1 then B.__expe_cov.branches["31-foes.lua:106:3935"]=true;  raw = 1 end
  local res = B.strike(st, a, raw, at, nil, e)
  res.tags = { "되치기" }
  B.push(st, { k = "eatk", a = e, t = math.max(0, at - 0.5), tg = { res }, nm = "되치기", ic = "attack", shoot = 0 })
  B.say(st, B.foe_line(st, e, { name = "되치기" }, res), at + 0.1)
end

-- ---------- 공격 배율(분노 · 장기전 · 오라) ----------
function B.foe_atk_mul(st, i) B.__expe_cov.calls["31-foes.lua:114"]=true; 
  local u, d = st.u[i], B.DEF[i]
  local m, tags = 1, {}
  local R = d.rules
  if R and R.hp_atk and u.hp <= u.mhp * R.hp_atk.thr then B.__expe_cov.branches["31-foes.lua:118:4412"]=true; 
    m = m * (1 + R.hp_atk.amount)
    tags[#tags + 1] = "분노 +" .. pct(R.hp_atk.amount) .. "%"
  end
  if d.grade == "chief" and u.hp <= u.mhp * B.BOSSR.rage_hp then B.__expe_cov.branches["31-foes.lua:122:4577"]=true;    -- 우두머리 분노
    m = m * (1 + B.BOSSR.rage_atk)
    tags[#tags + 1] = "분노 +" .. pct(B.BOSSR.rage_atk) .. "%"
  end
  local au = B.bget(u, "atk")
  if au ~= 0 then B.__expe_cov.branches["31-foes.lua:127:4740"]=true;  m = m * (1 + au) end
  local lead = (d.grade == "chief" or d.grade == "boss" or d.grade == "core")   -- 장기전은 우두머리 · 구역 보스 · 균열 핵만(호위 · 하수인은 제외 — 검수 7차 #7)
  if st.raid == 1 and lead and st.rd > B.BOSSR.enrage_round then B.__expe_cov.branches["31-foes.lua:129:4960"]=true;    -- 장기전: 20라운드를 넘으면 라운드마다 +10%(최대 +100%)
    local x = math.min(B.BOSSR.enrage_max, B.BOSSR.enrage_step * (st.rd - B.BOSSR.enrage_round))
    m = m * (1 + x)
    tags[#tags + 1] = "장기전 +" .. pct(x) .. "%"
  end
  return m, (#tags > 0) and table.concat(tags, ", ") or nil
end

-- ---------- 지속 피해(적이 아군에게) ----------
function B.edot_add(st, t, e, per, n) B.__expe_cov.calls["31-foes.lua:138"]=true; 
  local v = st.u[t]
  v.edot = v.edot or {}
  while #v.edot >= 4 do B.__expe_cov.branches["31-foes.lua:141:5385"]=true;  table.remove(v.edot, 1) end
  v.edot[#v.edot + 1] = { d = math.max(1, per), n = n, by = e }
end
-- 한 아군의 차례 시작: 쌓인 지속 피해를 한 번에. 쓰러지면 true.
function B.edot_tick(st, i) B.__expe_cov.calls["31-foes.lua:145"]=true; 
  local u = st.u[i]
  local sum, keep = 0, {}
  for _, x in ipairs(u.edot) do B.__expe_cov.branches["31-foes.lua:148:5630"]=true; 
    sum = sum + x.d
    x.n = x.n - 1
    if x.n > 0 then B.__expe_cov.branches["31-foes.lua:151:5686"]=true;  keep[#keep + 1] = x end
  end
  u.edot = keep
  local T = st.ev.T
  local res = B.strike(st, i, sum, T + 0.3, nil, "fixed")
  B.push(st, { k = "adot", a = i, t = T, tg = { res } })
  B.say(st, "<b>" .. nm(i) .. "</b>" .. B.josa(nm(i), "은는") .. " 지속 피해로 <em>" .. res.d .. "</em> 피해를 입었다" .. (res.kill == 1 and ". 부상으로 물러났다" or ""), T + 0.4)
  st.ev.T = T + 0.9
  return res.kill == 1
end
local function dot_per(st, e, t, coef) B.__expe_cov.calls["31-foes.lua:161"]=true; 
  local u, v = st.u[e], st.u[t]
  local Kc = st.K or B.K_of(st.el or 40)
  local de = v.de * (1 + B.bget(v, "def") - B.bget(v, "ddn"))
  return B.floor(u.cs * coef * u.am * (1 - B.bget(u, "adn")) * Kc / (Kc + de))
end

-- 공격이 들어간 뒤의 덧붙임: 차례 밀기 · 흡혈 · 지속 피해 · 이름 빼앗기
function B.e_after_hit(st, i, act, t, res, hitT) B.__expe_cov.calls["31-foes.lua:169"]=true; 
  local v = st.u[t]
  if v.al ~= 1 then B.__expe_cov.branches["31-foes.lua:171:6467"]=true;  return end
  if act.push then B.__expe_cov.branches["31-foes.lua:172:6497"]=true; 
    v.g = v.g + 10000 * act.push
    B.say(st, nm(t) .. "의 차례가 <em>밀렸다</em>", hitT + 0.2)
  end
  if act.drain and (res.d or 0) > 0 then B.__expe_cov.branches["31-foes.lua:176:6634"]=true; 
    local u = st.u[i]
    local h = B.floor(res.d * act.drain)
    if h > 0 and u.al == 1 and u.hp < u.mhp then B.__expe_cov.branches["31-foes.lua:179:6746"]=true; 
      if u.hp + h > u.mhp then B.__expe_cov.branches["31-foes.lua:180:6777"]=true;  h = u.mhp - u.hp end
      B.setf(st, i, "hp", u.hp + h, hitT + 0.2)
      B.say(st, "<b>" .. nm(i) .. "</b>" .. B.josa(nm(i), "이가") .. " 피를 빨아 <em>" .. h .. "</em> 회복", hitT + 0.3)
    end
  end
  if act.dot then B.__expe_cov.branches["31-foes.lua:185:6991"]=true; 
    B.edot_add(st, t, i, dot_per(st, i, t, act.dot.m), act.dot.turns or 3)
    B.say(st, nm(t) .. "에게 지속 피해가 번졌다", hitT + 0.2)
  end
  if act.strip then B.__expe_cov.branches["31-foes.lua:189:7144"]=true; 
    for _, k in ipairs(STRIP_ORDER) do B.__expe_cov.branches["31-foes.lua:190:7185"]=true; 
      if v.bf and v.bf[k] then B.__expe_cov.branches["31-foes.lua:191:7214"]=true; 
        v.bf[k] = nil
        B.say(st, nm(t) .. "의 강화 하나가 <em>지워졌다</em>", hitT + 0.3)
        break
      end
    end
  end
end

-- ---------- 차례 앞 · 뒤 ----------
function B.foe_turn_start(st, i) B.__expe_cov.calls["31-foes.lua:201"]=true; 
  local u, d = st.u[i], B.DEF[i]
  u.pt = 0      -- 보호는 보호한 적의 다음 차례까지
  u.hid = 0     -- 은신도 다음 차례까지
  u.tn = (u.tn or 0) + 1
  if d.ph2 and d.ph2.cycle and u.ph == 2 then B.__expe_cov.branches["31-foes.lua:206:7584"]=true;    -- 밑바닥의 메아리: 차례마다 약점이 바뀐다(바뀐 약점은 바로 보인다)
    local a = B.floor(B.rnd(st) * 6) + 1
    if a > 6 then B.__expe_cov.branches["31-foes.lua:208:7686"]=true;  a = 6 end
    local b = B.floor(B.rnd(st) * 5) + 1
    if b > 5 then B.__expe_cov.branches["31-foes.lua:210:7755"]=true;  b = 5 end
    if b >= a then B.__expe_cov.branches["31-foes.lua:211:7784"]=true;  b = b + 1 end
    u.cwk = { B.ELEMS[a], B.ELEMS[b] }
    d.wk = u.cwk
  end
end
function B.foe_turn_end(st, i, act) B.__expe_cov.calls["31-foes.lua:216"]=true; 
  local u, d = st.u[i], B.DEF[i]
  if act.big then B.__expe_cov.branches["31-foes.lua:218:7951"]=true;  u.cq = 0 end
  local R = d.rules
  if R and R.hide_every and u.tn % R.hide_every == 0 then B.__expe_cov.branches["31-foes.lua:220:8042"]=true; 
    u.hid = 1
    B.say(st, "<b>" .. nm(i) .. "</b>" .. B.josa(nm(i), "은는") .. " 몸을 숨겼다. 다음 차례까지 사격과 주문 피해 <em>−" .. pct(R.ranged_dr or 0.5) .. "%</em>", st.ev.T)
  end
end

-- ---------- 행동 ----------
local function pick_lowest(st, from, prefer_back) B.__expe_cov.calls["31-foes.lua:227"]=true; 
  local best, bk
  for _, j in ipairs(from) do B.__expe_cov.branches["31-foes.lua:229:8343"]=true; 
    local w = st.u[j]
    local k = (prefer_back and B.DEF[j].row == "후열" and 0 or 1) * 10 + w.hp / w.mhp
    if bk == nil or k < bk then B.__expe_cov.branches["31-foes.lua:232:8479"]=true;  best, bk = j, k end
  end
  return best
end

function B.e_buff(st, i, act) B.__expe_cov.calls["31-foes.lua:237"]=true; 
  local ev, T = st.ev, st.ev.T
  local u = st.u[i]
  local stat, amt, turns = act.stat, act.amount or 0, act.turns or 3
  local who = act.target or "self"
  local list
  if who == "self" then B.__expe_cov.branches["31-foes.lua:243:8746"]=true;  list = { i }
  elseif who == "allies" then B.__expe_cov.branches["31-foes.lua:244:8789"]=true;  list = foes_alive(st)
  else B.__expe_cov.branches["31-foes.lua:245:8818"]=true; 
    local o = pick_lowest(st, foes_alive(st, i), false)
    list = { o or i }
  end
  local tgs = {}
  for _, j in ipairs(list) do B.__expe_cov.branches["31-foes.lua:250:8951"]=true; 
    local w = st.u[j]
    if stat == "atk" then B.__expe_cov.branches["31-foes.lua:252:8997"]=true; 
      if who == "self" and not act.until_down then B.__expe_cov.branches["31-foes.lua:253:9048"]=true; 
        w.am = 1 + amt
        w.bt = turns + 1
      else B.__expe_cov.branches["31-foes.lua:256:9107"]=true; 
        B.badd(w, "atk", amt, act.until_down and 99 or (turns + 1))
        if act.until_down then B.__expe_cov.branches["31-foes.lua:258:9206"]=true;  w.bf.atk.src, w.bf.atk.au = i, 1 end
      end
    elseif stat == "spd" or stat == "def" then B.__expe_cov.branches["31-foes.lua:260:9300"]=true; 
      B.badd(w, stat, amt, turns + 1)
    elseif stat == "shield" then B.__expe_cov.branches["31-foes.lua:262:9371"]=true; 
      local sh = B.floor(w.mhp * amt)
      if sh > w.sh then B.__expe_cov.branches["31-foes.lua:264:9433"]=true;  B.setf(st, j, "sh", sh, T + 0.6) end
      w.shT = 3
    elseif stat == "pull" then B.__expe_cov.branches["31-foes.lua:266:9517"]=true; 
      w.g = math.max(0, w.g - 10000 * amt)
    end
    tgs[#tgs + 1] = { i = j }
  end
  local eff
  if stat == "shield" then B.__expe_cov.branches["31-foes.lua:272:9643"]=true;  eff = "보호막을 둘렀다"
  elseif stat == "pull" then B.__expe_cov.branches["31-foes.lua:273:9689"]=true;  eff = "차례가 앞당겨졌다"
  else B.__expe_cov.branches["31-foes.lua:274:9714"]=true;  eff = (STAT_KO[stat] or stat) .. " +" .. pct(amt) .. "% (" .. turns .. "턴)" end
  local to = (who == "allies") and "적 전체" or ((who == "ally" and list[1] ~= i) and nm(list[1]) or "")
  B.push(st, { k = "ebuff", a = i, t = T, nm = act.name, tg = tgs })
  B.say(st, "<b>" .. nm(i) .. "</b>의 " .. act.name .. ". " .. (to ~= "" and (to .. " ") or "") .. eff .. (act.until_down and ", 쓰러지거나 고갈될 때까지" or ""), T + 0.5)
  ev.T = T + 1.2
end

local DEB_KEY = { atk = "adn", def = "ddn", spd = "sdn" }
function B.e_debuff(st, i, act) B.__expe_cov.calls["31-foes.lua:282"]=true; 
  local ev, T = st.ev, st.ev.T
  local targets
  if act.target == "all" then B.__expe_cov.branches["31-foes.lua:285:10314"]=true;  targets = allies_alive(st)
  else B.__expe_cov.branches["31-foes.lua:286:10348"]=true;  targets = { (B.enemy_target(st, i)) } end
  local stat, amt, turns = act.stat, act.amount or 0.2, act.turns or 2
  local tgs, names = {}, {}
  for _, t in ipairs(targets) do B.__expe_cov.branches["31-foes.lua:289:10524"]=true; 
    local v = st.u[t]
    if stat == "delay" then B.__expe_cov.branches["31-foes.lua:291:10572"]=true; 
      v.g = v.g + 10000 * amt
    else B.__expe_cov.branches["31-foes.lua:293:10611"]=true; 
      B.badd(v, DEB_KEY[stat] or "adn", amt, turns)
    end
    tgs[#tgs + 1] = { i = t }
    names[#names + 1] = nm(t)
  end
  local eff = (stat == "delay") and ("다음 차례가 " .. pct(amt) .. "% 밀렸다") or ((STAT_KO[stat] or stat) .. " −" .. pct(amt) .. "% (" .. turns .. "턴)")
  B.push(st, { k = "edeb", a = i, t = T, nm = act.name, tg = tgs })
  B.say(st, "<b>" .. nm(i) .. "</b>의 " .. act.name .. ". " .. ((act.target == "all") and "아군 전체" or names[1]) .. " " .. eff, T + 0.6)
  ev.T = T + 1.3
end

function B.e_dot(st, i, act) B.__expe_cov.calls["31-foes.lua:305"]=true; 
  local ev, T = st.ev, st.ev.T
  local t = B.enemy_target(st, i)
  if B.chain(st, "evade", nil, t, i) then B.__expe_cov.branches["31-foes.lua:308:11243"]=true; 
    B.push(st, { k = "eatk", a = i, t = T, tg = { { i = t, d = 0, sh = 0, kill = 0, c = 0, miss = 1 } }, nm = act.name, ic = act.ic, shoot = 1 })
    B.say(st, "<b>" .. nm(i) .. "</b>의 " .. act.name .. ". " .. B.p(nm(t), "이가") .. " <em>피했다</em>", T + 0.7)
    ev.T = T + 1.4
    return
  end
  local per = dot_per(st, i, t, (act.m or 1.0) * (act.tick or 0.3))
  B.edot_add(st, t, i, per, act.turns or 3)
  B.push(st, { k = "edeb", a = i, t = T, nm = act.name, tg = { { i = t } } })
  B.say(st, "<b>" .. nm(i) .. "</b>의 " .. act.name .. ". " .. nm(t) .. "에게 지속 피해 <em>" .. math.max(1, per) .. "</em>씩 " .. (act.turns or 3) .. "턴", T + 0.6)
  ev.T = T + 1.3
end

function B.e_heal(st, i, act) B.__expe_cov.calls["31-foes.lua:321"]=true; 
  local ev, T = st.ev, st.ev.T
  local u = st.u[i]
  local list
  if act.target == "self" then B.__expe_cov.branches["31-foes.lua:325:12029"]=true;  list = { i } else B.__expe_cov.branches["31-foes.lua:325:12047"]=true;  list = foes_alive(st) end
  local hurt = {}
  for _, j in ipairs(list) do B.__expe_cov.branches["31-foes.lua:327:12123"]=true;  if st.u[j].hp < st.u[j].mhp then B.__expe_cov.branches["31-foes.lua:327:12154"]=true;  hurt[#hurt + 1] = j end end
  local j = pick_lowest(st, hurt, false)
  if not j then B.__expe_cov.branches["31-foes.lua:329:12239"]=true; 
    B.push(st, { k = "edef", a = i, t = T, nm = act.name })
    B.say(st, "<b>" .. nm(i) .. "</b>의 " .. act.name .. ". 회복할 대상이 없다", T + 0.5)
    ev.T = T + 1.0
    return
  end
  local w = st.u[j]
  local h = B.floor(w.mhp * (act.amount or 0.2))
  if w.hp + h > w.mhp then B.__expe_cov.branches["31-foes.lua:337:12512"]=true;  h = w.mhp - w.hp end
  B.setf(st, j, "hp", w.hp + h, T + 0.6)
  B.push(st, { k = "eheal", a = i, t = T, nm = act.name, tg = { { i = j, d = h } } })
  B.say(st, "<b>" .. nm(i) .. "</b>의 " .. act.name .. ". " .. nm(j) .. " HP <em>+" .. h .. "</em>", T + 0.7)
  ev.T = T + 1.3
end

-- 하수인 한 마리를 소환한다. 돌려주는 값 = 칸 번호(자리가 없거나 한도면 nil)
function B.summon_one(st, i, foe_id) B.__expe_cov.calls["31-foes.lua:345"]=true; 
  local adds = 0
  for j = 5, #st.u do B.__expe_cov.branches["31-foes.lua:347:12919"]=true;  if st.u[j].al == 1 and st.u[j].add == 1 then B.__expe_cov.branches["31-foes.lua:347:12962"]=true;  adds = adds + 1 end end
  if adds >= B.BOSSR.summon_cap then B.__expe_cov.branches["31-foes.lua:348:13023"]=true;  return nil end
  local slot
  for j = 5, #st.u do B.__expe_cov.branches["31-foes.lua:350:13075"]=true; 
    local w = st.u[j]
    if w.empty == 1 then B.__expe_cov.branches["31-foes.lua:352:13120"]=true;  slot = j; break end
  end
  if not slot then B.__expe_cov.branches["31-foes.lua:354:13165"]=true; 
    for j = 5, #st.u do B.__expe_cov.branches["31-foes.lua:355:13191"]=true; 
      local w = st.u[j]
      if w.al == 0 and w.add == 1 and (not st.ev or #st.ev.h[j] == 0) then B.__expe_cov.branches["31-foes.lua:357:13288"]=true;  slot = j; break end   -- 앞 장면에서 쓰러진 하수인의 칸을 다시 쓴다
    end
  end
  if not slot then B.__expe_cov.branches["31-foes.lua:360:13371"]=true;  return nil end
  st.fl[slot - 4] = foe_id
  st.fg[slot - 4] = "minion"
  B.DEF[slot] = B.foe_def(st, slot - 4)
  local u = B.blank_u(st, slot)
  u.g = 10000
  st.u[slot] = u
  u.it = B.pick_target(st, slot)
  return slot
end
function B.e_summon(st, i, act) B.__expe_cov.calls["31-foes.lua:370"]=true; 
  local ev, T = st.ev, st.ev.T
  local made, tgs = {}, {}
  for _ = 1, act.count or 1 do B.__expe_cov.branches["31-foes.lua:373:13719"]=true; 
    local j = B.summon_one(st, i, act.enemy)
    if not j then B.__expe_cov.branches["31-foes.lua:375:13780"]=true;  break end
    made[#made + 1] = nm(j)
    tgs[#tgs + 1] = { i = j }
  end
  B.push(st, { k = "esum", a = i, t = T, nm = act.name, tg = tgs })
  if #made == 0 then B.__expe_cov.branches["31-foes.lua:380:13943"]=true; 
    B.say(st, "<b>" .. nm(i) .. "</b>의 " .. act.name .. ". 이미 하수인이 가득해 아무도 나오지 못했다", T + 0.6)
  else B.__expe_cov.branches["31-foes.lua:382:14044"]=true; 
    B.say(st, "<b>" .. nm(i) .. "</b>의 " .. act.name .. ". <em>" .. table.concat(made, ", ") .. "</em> 등장", T + 0.7)
  end
  ev.T = T + 1.5
end

function B.e_protect(st, i, act) B.__expe_cov.calls["31-foes.lua:388"]=true; 
  local ev, T = st.ev, st.ev.T
  local u = st.u[i]
  local o = pick_lowest(st, foes_alive(st, i), true)
  if act.guard then B.__expe_cov.branches["31-foes.lua:392:14346"]=true;  u.df = 1 end
  if o then B.__expe_cov.branches["31-foes.lua:393:14371"]=true;  u.pt = o end
  B.push(st, { k = "edef", a = i, t = T, nm = act.name })
  B.say(st, "<b>" .. nm(i) .. "</b>의 " .. act.name .. (o and (". " .. nm(o) .. " 대신 맞는다(다음 차례까지)") or ". 감쌀 동료가 없다") .. (act.guard and ", 받는 피해 -40%" or ""), T + 0.5)
  ev.T = T + 1.2
end

function B.e_charge(st, i, act) B.__expe_cov.calls["31-foes.lua:399"]=true; 
  local ev, T = st.ev, st.ev.T
  st.u[i].cq = 1
  B.push(st, { k = "echg", a = i, t = T, nm = act.name })
  B.say(st, "<b>" .. nm(i) .. "</b>" .. B.josa(nm(i), "이가") .. " 큰 기술 <em>" .. act.name .. "</em>" .. B.josa(act.name, "을를") .. " 준비한다. 심연을 0으로 깎으면 끊긴다", T + 0.6)
  ev.T = T + 1.4
end

function B.e_special(st, i, act) B.__expe_cov.calls["31-foes.lua:407"]=true; 
  local ev, T = st.ev, st.ev.T
  if act.fx == "silence" then B.__expe_cov.branches["31-foes.lua:409:15048"]=true; 
    local al = allies_alive(st)
    local cand = {}
    for _, a in ipairs(al) do B.__expe_cov.branches["31-foes.lua:412:15132"]=true; 
      for k, sk in ipairs(B.SK[a] or {}) do B.__expe_cov.branches["31-foes.lua:413:15176"]=true; 
        if k > 1 and sk.id ~= "df" and sk.id ~= "atk" then B.__expe_cov.branches["31-foes.lua:414:15233"]=true;  cand[#cand + 1] = { a, sk } end
      end
    end
    if #cand > 0 then B.__expe_cov.branches["31-foes.lua:417:15305"]=true; 
      local k = B.floor(B.rnd(st) * #cand) + 1
      if k > #cand then B.__expe_cov.branches["31-foes.lua:419:15376"]=true;  k = #cand end
      local a, sk = cand[k][1], cand[k][2]
      st.u[a].sil = sk.id
      B.push(st, { k = "edeb", a = i, t = T, nm = act.name, tg = { { i = a } } })
      B.say(st, "<b>" .. nm(i) .. "</b>의 " .. act.name .. ". " .. nm(a) .. "의 「" .. sk.name .. "」 <em>1차례 봉인</em>", T + 0.6)
      ev.T = T + 1.3
      return
    end
  end
  B.push(st, { k = "edef", a = i, t = T, nm = act.name })
  B.say(st, "<b>" .. nm(i) .. "</b>의 " .. act.name .. ". 아무 일도 일어나지 않았다", T + 0.5)
  ev.T = T + 1.0
end

local DISPATCH = { dot = "e_dot", debuff = "e_debuff", buff = "e_buff", heal = "e_heal", summon = "e_summon", protect = "e_protect", charge = "e_charge", special = "e_special" }
function B.e_act(st, i, act) B.__expe_cov.calls["31-foes.lua:434"]=true; 
  local f = B[DISPATCH[act.kind] or ""]
  if f then B.__expe_cov.branches["31-foes.lua:436:16136"]=true;  f(st, i, act) end
end

-- ---------- 충전 끊김 ----------
function B.charge_cancel(st, i) B.__expe_cov.calls["31-foes.lua:440"]=true; 
  local u, d = st.u[i], B.DEF[i]
  u.cq = 0
  u.ia = u.ia % #d.acts + 1   -- 예고했던 큰 기술을 건너뛴다
  B.push(st, { k = "ecut", a = i, t = st.ev.T })
  B.say(st, "<b>" .. nm(i) .. "</b>의 충전이 <em>끊겼다</em>. 큰 기술이 취소됐다", st.ev.T + 0.2)
  local R = d.rules
  if R and R.break_self then B.__expe_cov.branches["31-foes.lua:447:16496"]=true; 
    local c = B.floor(u.mhp * R.break_self)
    local res = B.strike(st, i, c, st.ev.T + 0.3, nil, "fixed")
    B.say(st, "<b>" .. nm(i) .. "</b>의 과열이 풀리며 스스로 <em>" .. res.d .. "</em> 피해", st.ev.T + 0.4)
  end
end

-- ---------- 단계 전환(구역 보스) ----------
function B.enter_phase2(st, j) B.__expe_cov.calls["31-foes.lua:455"]=true; 
  local u, d = st.u[j], B.DEF[j]
  local ph = d.ph2
  local ev = st.ev
  u.ph = 2
  u.ia, u.cq = 1, 0
  u.g = 10000          -- 행동 순서가 처음으로 돌아간다
  u.dr = 0                                          -- 단계가 바뀔 때마다 심연은 가득 차고 고갈은 풀린다(ENEMIES.md)
  B.setf(st, j, "ay", u.ym, ev.T)
  if ph.cycle then B.__expe_cov.branches["31-foes.lua:464:17074"]=true; 
    local a = B.floor(B.rnd(st) * 6) + 1
    if a > 6 then B.__expe_cov.branches["31-foes.lua:466:17133"]=true;  a = 6 end
    local b = B.floor(B.rnd(st) * 5) + 1
    if b > 5 then B.__expe_cov.branches["31-foes.lua:468:17202"]=true;  b = 5 end
    if b >= a then B.__expe_cov.branches["31-foes.lua:469:17231"]=true;  b = b + 1 end
    u.cwk = { B.ELEMS[a], B.ELEMS[b] }
  end
  B.DEF[j] = B.foe_def(st, j - 4)
  local nd = B.DEF[j]
  local wk = {}
  for _, e in ipairs(nd.wk) do B.__expe_cov.branches["31-foes.lua:475:17395"]=true;  wk[#wk + 1] = B.EL_KO and B.EL_KO[e] or e end
  B.push(st, { k = "phase", a = j, t = ev.T, nm = nd.name })
  B.say(st, "<b>" .. nd.name .. "</b>: <em>2단계</em>! 약점이 바뀌고 행동 순서가 처음으로 돌아간다", ev.T + 0.3)
  ev.T = ev.T + 1.2
  if ph.entry then B.__expe_cov.branches["31-foes.lua:479:17631"]=true;  B.e_summon(st, j, ph.entry) end
  u.it = B.pick_target(st, j)
end
B.EL_KO = { fire = "화염", ice = "냉기", bolt = "번개", wind = "바람", holy = "신성", dark = "어둠" }

-- 단계 전환 검사 — HP 가 어디서 바뀌었든(공격 · 지속 피해 · 되치기 …) 같은 함수로. 전환한 칸 수를 돌려준다.
-- 한 번에 50% 위에서 0 까지 깎인 보스는 strike 가 문턱 바로 아래로 붙들어 두므로(30-engine) 여기서 반드시 2단계를 본다.
function B.phase_check(st) B.__expe_cov.calls["31-foes.lua:486"]=true; 
  if not st.ev then B.__expe_cov.branches["31-foes.lua:487:17989"]=true;  return 0 end
  local n = 0
  for j = 5, #st.u do B.__expe_cov.branches["31-foes.lua:489:18040"]=true; 
    local u = st.u[j]
    if u.al == 1 and u.ph == 1 then B.__expe_cov.branches["31-foes.lua:491:18096"]=true; 
      local d = B.DEF[j]
      if d.ph2 and u.hp <= u.mhp * B.BOSSR.phase_hp then B.__expe_cov.branches["31-foes.lua:493:18178"]=true;  B.enter_phase2(st, j); n = n + 1 end
    end
  end
  return n
end

-- 행동 하나가 끝난 뒤마다(B.run 맨 앞): 단계 전환
function B.after_action(st) B.__expe_cov.calls["31-foes.lua:500"]=true;  B.phase_check(st) end

-- 결과 줄에 붙일 한 줄: 장소(대던전 층 · 균열) · 맞선 적. 조합 전투(st.fl)만 — 옛 4칸 전투의 결과 줄은 그대로 둔다.
function B.result_context(st) B.__expe_cov.calls["31-foes.lua:503"]=true; 
  if not st.fl then B.__expe_cov.branches["31-foes.lua:504:18460"]=true;  return nil end
  local names, seen = {}, {}
  for j = 5, #st.u do B.__expe_cov.branches["31-foes.lua:506:18528"]=true; 
    local d = B.DEF[j]
    if st.u[j].empty ~= 1 and not d.empty and not seen[d.name] then B.__expe_cov.branches["31-foes.lua:508:18617"]=true;  seen[d.name] = true; names[#names + 1] = B.T(d.name) end
  end
  local s = ""
  if st.dn then B.__expe_cov.branches["31-foes.lua:511:18711"]=true; 
    local boss = (st.dn.kind == "boss") or (st.dn.stage == 2)
    s = B.U("장소: {place}{kind}. ", { place = st.place or "대던전", kind = B.U(boss and " (층 보스 레이드 전투)" or ((st.dn.stage == 1) and " (구역 전투, 층 보스가 아직 남아 있다)" or " (탐색 중 만난 전투, 층 보스가 아직 남아 있다)")) })
  elseif st.place and st.place ~= "" then B.__expe_cov.branches["31-foes.lua:514:19010"]=true; 
    s = B.U("장소: {place}. ", { place = st.place })
  end
  return s .. B.U("맞선 적: {names}.", { names = table.concat(names, ", ") })
end

-- ---------- 보상 ----------
-- 일반 전투: 적 레벨 × (잡몹 12 · 무리 6 · 정예 36 · 하수인 0) × ★ 보상 배수.
-- 레이드: 같은 층 일반 전투 한 번의 기준(레벨 × 12 × 3마리)에 우두머리 ×2.5 · 구역 보스 ×4 · 균열 핵 ×3 (design/ENEMIES.md 「레이드 전투」).
function B.exp_reward_foes(st) B.__expe_cov.calls["31-foes.lua:523"]=true; 
  local sm = B.star_mult(st)
  local s = 0
  local R = B.REWARDR
  if st.raid == 1 then B.__expe_cov.branches["31-foes.lua:527:19457"]=true; 
    local d = B.DEF[5]
    local mult = ({ chief = R.chief, boss = R.boss, core = R.core })[d.grade] or R.chief
    s = (st.el or 1) * 12 * R.exp_ref_enemies * mult
  else B.__expe_cov.branches["31-foes.lua:531:19629"]=true; 
    for j = 5, #st.u do B.__expe_cov.branches["31-foes.lua:532:19655"]=true; 
      local d = B.DEF[j]
      if st.u[j].empty ~= 1 and not d.empty then B.__expe_cov.branches["31-foes.lua:534:19727"]=true; 
        s = s + (d.lvn or st.el or 1) * ((B.GRADES[d.grade] or B.GRADES.mob).exp or 12)
      end
    end
  end
  local r = (st.dn and st.dn.floor) and B.floor_mult(st.dn.floor).reward or sm.reward
  if st.qmult then B.__expe_cov.branches["31-foes.lua:540:19944"]=true;  r = r * st.qmult end
  if B.GH.exp then B.__expe_cov.branches["31-foes.lua:541:19984"]=true;  r = r * B.GH.exp(st) end
  local e = B.floor(s * r)
  if st.dn and st.dn.ae then B.__expe_cov.branches["31-foes.lua:543:20065"]=true;  e = e + st.dn.ae end   -- 대던전 층의 앞 단계(일반 전투)에서 쌓은 경험치
  return e
end
