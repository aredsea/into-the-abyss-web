-- ===== 버튼 처리 =====
-- 버튼 한 번 = 상태 갱신 → (전투 끝이면 결과 줄 addChat 한 번) → 저장 → reloadDisplay → 보강.
-- 보조 모델·AI 생성 호출은 어디에도 없다.

function B.act(st, act) B.__r23_cov.calls["80-press.lua:5"]=true; 
  if act == "reset" then B.__r23_cov.branches["80-press.lua:6:167"]=true; 
    if st.qid then B.__r23_cov.branches["80-press.lua:7:186"]=true;  return st end   -- 의뢰 전투는 다시 싸울 수 없다(결과 고르기 방지 · 검수 4차 #15)
    return B.again(st)   -- 같은 파티·같은 적·같은 의뢰 보상
  end
  if st.over ~= "" then B.__r23_cov.branches["80-press.lua:10:324"]=true;  return st end
  if st.imenu == 1 then B.__r23_cov.branches["80-press.lua:11:362"]=true;  st.imenu, st.ipk = 0, "" end   -- 아이템 고르기 중에 스킬 버튼을 누르면 아이템 고르기는 접는다(78-battle-item)
  if act == "cancel" then B.__r23_cov.branches["80-press.lua:12:473"]=true; 
    st.pend, st.pid = 0, nil
    st.ev = nil
    return st
  end
  local kind, num = tostring(act):match("^(%a+)_(%d+)$")
  num = tonumber(num)
  if kind == "sk" and num then B.__r23_cov.branches["80-press.lua:19:648"]=true; 
    local i = st.cur
    local sk = B.SK[i] and B.SK[i][num]
    if not sk then B.__r23_cov.branches["80-press.lua:22:728"]=true;  return st end
    if not B.can_use(st, i, sk) then B.__r23_cov.branches["80-press.lua:23:779"]=true;  return st end
    if sk.tgt == "none" then B.__r23_cov.branches["80-press.lua:24:822"]=true; 
      B.begin_ev(st)
      st.pend = 0
      B.player(st, num, 0)
      B.run(st)
    else B.__r23_cov.branches["80-press.lua:29:913"]=true; 
      st.pend = num
      st.pid = sk.id   -- 옛 저장 · 스킬 목록 순서가 바뀐 판에서 번호를 다시 찾는 데 쓴다(20-state B.bind)
      st.ev = nil
    end
  elseif kind == "tg" and num then B.__r23_cov.branches["80-press.lua:34:1076"]=true; 
    local slot = st.pend
    if slot == 0 then B.__r23_cov.branches["80-press.lua:36:1123"]=true;  return st end
    local i = st.cur
    local sk = B.SK[i][slot]
    if not sk or not B.can_use(st, i, sk) then B.__r23_cov.branches["80-press.lua:39:1234"]=true;  st.pend, st.pid = 0, nil; return st end   -- 못 쓰게 된 스킬(MP 부족 · 목록 변경)이면 대기를 취소한다
    if sk.tgt == "enemy" and not (num >= 5 and num <= #st.u and st.u[num].al == 1) then B.__r23_cov.branches["80-press.lua:40:1403"]=true;  return st end
    if sk.tgt == "ally" and not (num >= 1 and num <= 4 and st.u[num].al == 1 and (num ~= i or not B.NOSELF[sk.cid or ""])) then B.__r23_cov.branches["80-press.lua:41:1545"]=true;  return st end
    B.begin_ev(st)
    st.pend, st.pid = 0, nil
    B.player(st, slot, num)
    B.run(st)
  end
  return st
end

-- 화면 갱신 보강(fxtest 와 같은 방식 — 포켓리스 실기에서 통과). same: 마지막 캐릭터 메시지를 같은 내용으로 다시 쓴다.
function B.nudge(id) B.__r23_cov.calls["80-press.lua:51"]=true; 
  pcall(function() B.__r23_cov.calls["80-press.lua:52"]=true; 
    local idx = B.last_char(id)
    if idx == nil or idx < 0 then B.__r23_cov.branches["80-press.lua:54:1856"]=true;  return end
    if type(reloadChat) == "function" then B.__r23_cov.branches["80-press.lua:55:1910"]=true;  pcall(reloadChat, id, idx) end
    if type(setChat) ~= "function" then B.__r23_cov.branches["80-press.lua:56:1981"]=true;  return end
    local c = getChat(id, idx)
    local text = type(c) == "table" and c.data or nil
    if type(text) ~= "string" or text == "" then B.__r23_cov.branches["80-press.lua:59:2126"]=true;  return end
    setChat(id, idx, text)
  end)
end

-- 전투 끝: 결과 줄을 유저 메시지로 한 번만 넣는다(버튼으로 끝났든, 입장하자마자 끝났든)
function B.send_result(id, st) B.__r23_cov.calls["80-press.lua:65"]=true; 
  if st.over == "" or st.sent ~= 0 then B.__r23_cov.branches["80-press.lua:66:2301"]=true;  return end
  if st.dn and st.dn.kind == "explore" and st.over == "win" then B.__r23_cov.branches["80-press.lua:67:2377"]=true;  st.sent = 3; return end   -- 대던전 탐색 전투의 승리 줄은 채팅에 넣지 않는다 — 층 정산 때 한 번에(77-explore)
  if st.dn and not st.dn.stage and (st.dn.kind ~= "explore" or st.over ~= "win") then B.__r23_cov.branches["80-press.lua:68:2546"]=true;  st.sent = 4; return end   -- 층 보스 전투(이기든 지든)·탐색 전투 패배: 정산 때 채팅 한 번으로(사장님 10-11 「채팅을 두 번 강제」)
  st.sent = 2
  if type(addChat) == "function" then B.__r23_cov.branches["80-press.lua:70:2691"]=true; 
    local ok, res = pcall(addChat, id, "user", st.res)
    if ok and res ~= false then B.__r23_cov.branches["80-press.lua:72:2778"]=true;  st.sent = 1 end
  end
end

function B.press(id, act) B.__r23_cov.calls["80-press.lua:76"]=true; 
  B.pimg_kick(id, false)
  local st = B.load(id)
  st = B.act(st, tostring(act or ""))
  B.send_result(id, st)
  B.save(id, st)
  local okg, G = pcall(B.G_load, id)
  B.refresh(id, okg and G or nil, act)
end
