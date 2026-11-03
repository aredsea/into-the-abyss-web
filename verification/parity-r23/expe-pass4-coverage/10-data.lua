-- ===== 정적 데이터 =====
-- 수치는 05-gen.lua(build.py 가 design/stats.json · sim.py · traits_v2.json 에서 뽑아 넣는다)와 24-stats.lua(레벨 곡선)에서 온다.
-- 🔴 파티 일반화(10-08): 아군 자리 1~4 는 전투마다 다르다 — 전투 상태 st.pm 에서 B.bind(st) 가 B.DEF[1..4] · B.SK[1..4] 를 다시 만든다.
--    엔진·화면은 지금처럼 B.DEF[i] · B.SK[i] 를 읽으면 된다. 자리 번호로 사람을 가리지 말고 B.DEF[i].cid 로 가린다.
-- 적 자리 5~8(옛 고정 편성 — 손으로 만든 시험 의뢰 · 시험 하네스가 가정한다. 던전 · 균열 조합 전투는 05-gen.lua 의 B.FOES). 메달은 계열 14(심연 사냥) 그림
B.EDEF = {
  { name = "심연 사냥개 A", glyph = "견", ic = "fam-14", lvo = 0, row = "전열", spd = 108, kind = "mob", hpm = 1.0, am = 1.0, wk = { "ice", "holy" },
    acts = { { id = "bite", name = "물어뜯기", ic = "attack", kind = "atk", m = 1.0, vb = "물어뜯었다" },
             { id = "bite", name = "물어뜯기", ic = "attack", kind = "atk", m = 1.0, vb = "물어뜯었다" },
             { id = "howl", name = "포효", ic = "buff", kind = "buff", am = 1.3, vb = "포효했다" } } },
  { name = "심연 사냥개 B", glyph = "견", ic = "fam-14", lvo = 0, row = "전열", spd = 108, kind = "mob", hpm = 1.0, am = 1.0, wk = { "ice", "holy" },
    acts = { { id = "bite", name = "물어뜯기", ic = "attack", kind = "atk", m = 1.0, vb = "물어뜯었다" },
             { id = "howl", name = "포효", ic = "buff", kind = "buff", am = 1.3, vb = "포효했다" },
             { id = "bite", name = "물어뜯기", ic = "attack", kind = "atk", m = 1.0, vb = "물어뜯었다" } } },
  { name = "그림자 궁수", glyph = "궁", ic = "fam-14", lvo = 1, row = "후열", spd = 100, kind = "mob", hpm = 1.0, am = 1.0, wk = { "ice", "dark" },
    acts = { { id = "shot", name = "사격", ic = "shoot", kind = "atk", m = 1.1, shoot = true, vb = "쏘았다" },
             { id = "aimed", name = "조준 사격", ic = "shoot", kind = "atk", m = 1.6, shoot = true, low = true, vb = "겨누어 쏘았다" },
             { id = "shade", name = "그림자 화살", ic = "spell", kind = "atk", m = 1.1, shoot = true, magic = true, vb = "그림자 화살을 날렸다" } } },   -- 마법(검수 4차 #9)
  { name = "던전 감시관", glyph = "감", ic = "fam-14", lvo = 2, row = "후열", spd = 88, kind = "elite", hpm = 1.0, am = 1.0, wk = { "dark", "holy", "bolt" }, elite = true,
    acts = { { id = "slam", name = "내려치기", ic = "attack", kind = "atk", m = 1.0, vb = "내려쳤다" },
             { id = "heavy", name = "강타", ic = "spell", kind = "atk", m = 1.5, magic = true, vb = "강타했다" },
             { id = "guard", name = "방어 자세", ic = "defend", kind = "guard" },
             { id = "slam", name = "내려치기", ic = "attack", kind = "atk", m = 1.0, vb = "내려쳤다" },
             { id = "chain", name = "쇠사슬 강화", ic = "buff", kind = "buff", am = 1.25, vb = "쇠사슬을 당겨 힘을 끌어올렸다" } } },
}
B.DEF = {}
B.SK = {}
-- 아군 대상 스킬 중 자기 자신을 고를 수 없는 것(대신 막아서기 등). 나머지 회복·축복은 자기에게도 쓴다(검수 4차 #7).
B.NOSELF = { marceline = true }
B.PRUN = B.PRUN or {}   -- 개인 스킬 처리기(cid → function(st, i, tgt, sk))
B.TR = B.TR or {}       -- 특성 훅(cid → { 사건 = function }) — 30-engine B.fire

-- 직업 스킬(직업마다 2개 — 동료는 [일반 공격, 직업 1, 개인, 직업 2], 페르소나는 [일반 공격, 직업 1, 직업 2, 방어]).
-- run = 30-engine.lua 의 B.RUN[run] 처리기. 수치 정본 design/stats.json classes.skills · CLASSES.md.
B.ATK = {   -- 일반 공격(직업마다 계수·심연 깎기)
  warrior = { m = 1.0, brk = 12, ic = "attack", vb = "베었다", d = "힘 ×1.0, <em>심연 −12</em>" },
  paladin = { m = 1.0, brk = 12, ic = "attack", vb = "베었다", d = "힘 ×1.0, <em>심연 −12</em>" },
  assassin = { m = 1.0, brk = 3, ic = "stab", vb = "찔렀다", d = "민첩 ×1.0, <em>심연 −3</em>" },
  archer = { m = 1.0, brk = 3, ic = "shoot", vb = "쏘았다", d = "민첩 ×1.0, <em>심연 −3</em>" },
  sanctioned = { m = 1.0, brk = 3, ic = "spell", vb = "마법으로 공격했다", d = "지능 ×1.0, <em>심연 −3</em>, 적 차례 8% 지연" },
  unsanctioned = { m = 1.0, brk = 3, ic = "spell", vb = "마법으로 공격했다", d = "지능 ×1.0, <em>심연 −3</em>, 지속 피해 1중첩" },
  priest = { m = 1.0, brk = 8, ic = "spell", vb = "빛으로 내리쳤다", d = "지능 ×1.0, <em>심연 −8</em>" },
  alchemist = { m = 1.0, brk = 8, ic = "spell", vb = "약병을 던졌다", d = "지능 ×1.0, <em>심연 −8</em>" },
  gladiator = { m = 1.0, brk = 3, ic = "attack", vb = "베었다", d = "힘 ×1.0, <em>심연 −3</em>" },
  chaos = { m = 0.7, brk = 20, ic = "spell", vb = "마력으로 내리쳤다", d = "지능 ×0.7, <em>심연 −20</em>" },
}
B.KIT = {
  warrior = { { id = "taunt", name = "도발", mp = 10, tgt = "enemy", ic = "sk-taunt", d = "위압 <em>심연 −20</em>, 공격 유도 2턴" },
              { id = "guard2", name = "굳건한 방어", mp = 8, tgt = "none", ic = "sk-guard2", d = "2턴 동안 받는 피해 −40%" } },
  paladin = { { id = "shield", name = "파티 보호막", mp = 30, tgt = "none", ic = "sk-shield", d = "아군 전체 보호막(힘 ×1.2)" },
              { id = "taunt", name = "도발", mp = 10, tgt = "enemy", ic = "sk-taunt", d = "위압 <em>심연 −20</em>, 공격 유도 2턴" } },
  assassin = { },
  archer = { { id = "snipe", name = "일발필살", mp = 24, tgt = "enemy", ic = "sk-snipe", d = "치명 70%, 치명 ×2.0" } },
  sanctioned = { { id = "burst", name = "마력 폭발", mp = 36, tgt = "enemy", ic = "sk-burst", d = "2턴 충전, 전체, 지정한 적 지연" } },
  unsanctioned = { { id = "ruin", name = "파괴적 마법", mp = 40, tgt = "none", ic = "sk-ruin", d = "전체 ×0.6, 지속 피해 3턴, 적 공격 −15%" } },
  priest = { { id = "pshield", name = "파티 보호막", mp = 30, tgt = "none", ic = "sk-shield", d = "아군 전체 보호막(지능 ×1.0)" },
             { id = "bless", name = "파티 능력치 상향", mp = 28, tgt = "none", ic = "sk-bless", d = "아군 전체 공격, 방어 +15% (3턴)" } },
  alchemist = { { id = "heal", name = "파티 회복", mp = 30, tgt = "none", ic = "sk-heal", d = "아군 전체 회복(지능 ×1.4)" },
                { id = "defdn", name = "약화 약병", mp = 20, tgt = "enemy", ic = "sk-defdn", d = "방어 −20% (3턴), <em>심연 −12</em>" },
                { id = "tonic", name = "아군 능력 버프", mp = 20, tgt = "ally", ic = "sk-tonic", d = "아군 1명 공격 +15% (3턴)" } },
  gladiator = { { id = "blood", name = "피의 갈증", mp = 0, tgt = "none", ic = "sk-blood", d = "HP 15%, 치명 +30%p (2턴), 치명 피해 +50%" } },
  chaos = { { id = "rift", name = "균열", mp = 24, tgt = "enemy", ic = "sk-rift", d = "<em>심연 −40</em>" },
            { id = "wave", name = "혼돈 파동", mp = 32, tgt = "none", ic = "sk-wave", d = "전체, <em>심연 −20씩</em>" } },
}
B.DF = { id = "df", name = "방어", mp = 0, tgt = "none", ic = "defend", d = "받는 피해 −40%" }

-- 개인 스킬(동료마다 하나). 처리기는 B.PRUN[cid](st, i, tgt, sk) — 30-engine(4명) · 32-personal-*.lua(나머지).
-- 표시 문구·아이콘은 여기, MP·대상은 stats.json(B.CAST.skill_mp · skill_tgt).
B.PSK = {
  levia = { id = "rev", ic = "burn", d = "개인 스킬: HP 10% 소모, 다음 균열과 혼돈 파동의 심연 깎기 ×1.5" },
  marceline = { id = "oath", ic = "bash", d = "개인 스킬: 아군 1명 대신 다음 적 공격 1회를 맞고, 받는 피해 −30%" },
  naran = { id = "mark", ic = "fire", d = "개인 스킬: 적 1명에 표식을 남겨, 그 적이 받는 다음 공격은 확정 치명타. <em>심연 −3</em>" },
  teiris = { id = "note", ic = "ice", d = "개인 스킬: 전투당 1회, 충전 없이 마력 폭발을 바로 발동, 적 전체 ×1.9" },
}

-- 컷인 대사(임의 — 사장님 확인 대기. 테이리스 대사만 stats.json 원문). 키 = 개인 스킬 id
B.CUTLINE = { rev = "아깝지 않아요. 피는 쓰려고 있는 거니까.", oath = "소설 속 기사는 이렇게 막아섰죠.", mark = "표식은 달았어. 이제 웃으면서 계산할 차례.", note = "이건 노트에 적어 둬야겠어요!" }

-- 난이도 조정은 적 수치(HP·공격)만 — 레벨 곡선 값에 곱한다(Lv40 4인 기준으로 맞춘 값)
B.TUNE = { hp = 1.8, atk = 1.6 }   -- ★4(시험판 2 「심연 회랑 32층」) 기준값
-- ★마다 [제안 10-08]: ★1 은 시작 파티(페르소나 + 동료 1~2명)가 이길 수 있게. ★ 배수(B.STARS)는 따로 곱해진다.
-- 옛 고정 4칸 전투(B.EDEF — 손으로 만든 시험 의뢰 · 시험 하네스)의 ★별 보정. 조합 전투(대던전 · 길드 균열)는 design/enemies.json tune.star 에서 온 B.TUNE_FLOOR 를 쓴다(05-gen.lua).
B.TUNE_STAR = { [1] = { hp = 1.0, atk = 1.0 }, [2] = { hp = 1.3, atk = 1.25 }, [3] = { hp = 1.55, atk = 1.45 }, [4] = { hp = 1.8, atk = 1.6 } }

B.REWARD = { exp = 480, gold = 340, item = "" }   -- item: 재료 체계가 생기기 전에는 비운다(지급하지 않는 것을 결과에 쓰지 않는다 · 검수 4차 #16)
-- 직업 패시브 배지(10-10) — 카드(B.pbadges)가 읽는다. 아이콘 키는 CSS .im-ps-*
B.PBADGE = { assassin = { "ps-crit", "ps-extra" }, sanctioned = { "ps-delay" }, unsanctioned = { "ps-dot" }, priest = { "ps-ward" }, alchemist = { "ps-haste" }, gladiator = { "ps-vigor" }, chaos = { "ps-reson" } }
B.MAX_ACTIONS = 400
B.ROUND = 100   -- 시간 틱 100 = 1라운드(행동 게이지 한 바퀴)
