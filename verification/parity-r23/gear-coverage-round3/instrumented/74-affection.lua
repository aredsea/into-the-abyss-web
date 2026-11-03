B.__r23_gear_cov=B.__r23_gear_cov or {calls={},branches={}}
-- ===== 호감도 (사장님 10-10: 최대 200 · 100 부터는 더 천천히) =====
-- 정본 design/PERSONALITY.md 「호감 — 엔진이 세는 것」. 값은 G.aff[cid] — 동료마다 -100 ~ 200, 영입 때 0. 모든 수치 [제안].
-- 오르는 길은 전부 B.aff_add 한 곳을 지난다(여관 · 함께 싸운 승리). 100 을 넘는 몫은 SLOW 배로만 오른다.
B.AFF = {
  MAX = 200, MIN = -100,
  SOFT = 100, SLOW = 0.4,        -- 100 이상 구간은 ×0.4 (같은 몫이 2.5배 걸린다)
  BATTLE = 1,                    -- 탐색 전투를 이겼을 때 출전한 동료 각자 (정예도 같다)
  BOSS = 3,                      -- 층 보스를 쓰러뜨려 층을 마쳤을 때
  QUEST = 2,                     -- 길드 의뢰 전투를 이겼을 때
}

-- 단계 이름: 낯섦 -19~19 · 신뢰 20~49 · 유대 50~79 · 깊은 인연 80~99 (여기까지 PERSONALITY.md 확정) · 맹세 100~149 · 운명 150~200 ([제안] 이름)
function B.aff_stage(a) B.__r23_gear_cov.calls["74-affection.lua:13"]=true; 
  a = tonumber(a) or 0
  if a <= -60 then B.__r23_gear_cov.branches["74-affection.lua:15:688"]=true;  return "적대" elseif a <= -20 then B.__r23_gear_cov.branches["74-affection.lua:15:721"]=true;  return "불신" elseif a < 20 then B.__r23_gear_cov.branches["74-affection.lua:15:752"]=true;  return "낯섦"
  elseif a < 50 then B.__r23_gear_cov.branches["74-affection.lua:16:785"]=true;  return "신뢰" elseif a < 80 then B.__r23_gear_cov.branches["74-affection.lua:16:816"]=true;  return "유대" elseif a < 100 then B.__r23_gear_cov.branches["74-affection.lua:16:848"]=true;  return "깊은 인연"
  elseif a < 150 then B.__r23_gear_cov.branches["74-affection.lua:17:885"]=true;  return "맹세" end
  return "운명"
end

function B.aff_r2(x) B.__r23_gear_cov.calls["74-affection.lua:21"]=true;  return math.floor(x * 100 + 0.5) / 100 end   -- 소수 둘째 자리까지(떠다니는 소수 오차를 막는다)

-- 현재 값 a 에 amt(양수)를 더한 새 값: 100 까지는 그대로, 넘는 몫은 SLOW 배, 200 에서 멈춘다. 음수는 그대로 더하고 -100 에서 멈춘다.
function B.aff_next(a, amt) B.__r23_gear_cov.calls["74-affection.lua:24"]=true; 
  local A = B.AFF
  a = tonumber(a) or 0
  amt = tonumber(amt) or 0
  if amt <= 0 then B.__r23_gear_cov.branches["74-affection.lua:28:1226"]=true;  return math.max(A.MIN, B.aff_r2(a + amt)) end
  local room = math.max(0, A.SOFT - a)
  local v
  if amt <= room then B.__r23_gear_cov.branches["74-affection.lua:31:1343"]=true;  v = a + amt else B.__r23_gear_cov.branches["74-affection.lua:31:1360"]=true;  v = math.max(a, A.SOFT) + (amt - room) * A.SLOW end
  return math.min(A.MAX, B.aff_r2(v))
end

-- G.aff[cid] 에 amt 를 더하고 실제로 오른 양을 돌려준다. 동료가 아니거나 알 수 없는 id 면 아무것도 하지 않는다(0).
function B.aff_add(G, cid, amt) B.__r23_gear_cov.calls["74-affection.lua:36"]=true; 
  if type(G.aff) ~= "table" then B.__r23_gear_cov.branches["74-affection.lua:37:1599"]=true;  G.aff = {} end
  if cid == nil or cid == "" or cid == "persona" then B.__r23_gear_cov.branches["74-affection.lua:38:1668"]=true;  return 0 end
  local a = tonumber(G.aff[cid]) or 0
  local v = B.aff_next(a, amt)
  G.aff[cid] = v
  if B.chron_aff then B.__r23_gear_cov.branches["74-affection.lua:42:1789"]=true;  B.chron_aff(G, cid, a, v) end   -- 호감 단계가 바뀌면 모험 연대기에 한 줄(89-memory)
  return B.aff_r2(v - a)
end

-- 출전 편성 pm(목록 {id = ...})의 동료마다 amt 를 더한다(페르소나·빈 자리·영입하지 않은 id 는 제외). 돌려주는 값 = { cid → 오른 양 }
function B.aff_party(G, pm, amt) B.__r23_gear_cov.calls["74-affection.lua:47"]=true; 
  local out = {}
  if type(pm) ~= "table" then B.__r23_gear_cov.branches["74-affection.lua:49:2063"]=true;  return out end
  if B.tx_aff then B.__r23_gear_cov.branches["74-affection.lua:50:2097"]=true;  amt = amt * B.tx_aff(pm) end   -- 출신 시너지(솔렌 3명): 함께 싸운 호감 +20% (34-traits)
  for _, m in ipairs(pm) do B.__r23_gear_cov.branches["74-affection.lua:51:2202"]=true; 
    local cid = type(m) == "table" and m.id or m
    if cid and cid ~= "" and cid ~= "persona" and not out[cid] and B.has(G.roster or {}, cid) then B.__r23_gear_cov.branches["74-affection.lua:53:2348"]=true; 
      out[cid] = B.aff_add(G, cid, amt)
    end
  end
  return out
end

-- 오른 양을 화면 글로: 4 → "4" · 1.6 → "1.6" · 0.4 → "0.4"
function B.aff_fmt(x) B.__r23_gear_cov.calls["74-affection.lua:61"]=true; 
  x = B.aff_r2(tonumber(x) or 0)
  if x == math.floor(x) then B.__r23_gear_cov.branches["74-affection.lua:63:2556"]=true;  return string.format("%d", x) end
  return string.format("%.1f", x)
end
