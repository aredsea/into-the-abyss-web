# R24 영어 동료 대사 독립 검수

## 범위와 판정

`project/data/dialogue-r21/*.json` 30개 파일에서 인물마다 영어 표시 필드 60개씩, 총 1,800개를 한국어 원문과 대조했다. 인물별로 여관 장면 필드 30개(상황·대사·선택지·응답·재방문 대사), 던전 대사 15개, 단계 전환 대사 15개를 고르게 뽑았다. 아래 평점은 표본에서 본 자연스러움·의미 보존·인물 말투의 일관성을 합산한 편집 점수다.

**반복되는 문제:** 한국어의 생략을 영어에도 그대로 남겨 주어·관사·전치사·목적어가 빠진 문장이 반복된다. 어휘를 일대일로 옮긴 표현(예: *my hand*, *the surroundings are not*, *belatedly awesome*)은 영어 관용 표현과 맞지 않거나 뜻을 흐린다. 인물별 짧은 말투는 살릴 수 있지만, 완결된 원문을 문장 조각으로 줄이는 경우까지 캐릭터 음성으로 처리하면 안 된다. 표본에서 고유명사 철자 오류나 명백한 표기 불일치는 두드러지지 않았다.

## 인물별 점수

| 인물 | 점수 | 표본 평가 |
|---|---:|---|
| Adeline | 8.0 | 공손한 말투는 유지되나 일부 문장이 지시적으로 들림 |
| Altan | 7.6 | 사무적 어조는 잘 잡았으나 거래·회계 표현이 직역투 |
| Bargut | 7.8 | 짧고 무뚝뚝한 음성은 잘 살아 있으나 일부 문장 조각이 부자연스러움 |
| Berenga | 8.5 | 대체로 자연스럽고 따뜻한 말투가 일관됨 |
| Bianca | 8.2 | 부드러운 말투는 안정적이나 일부 문장 조각과 표현이 어색함 |
| Colette | 8.0 | 격식은 일관되나 문장 구조가 뻣뻣한 곳이 있음 |
| Erdene | 8.2 | 편한 반말과 직설적인 성격이 대체로 잘 전달됨 |
| Felice | 8.0 | 대체로 자연스럽고 친근함; 일부 구어가 단정적임 |
| Gerda | 7.8 | 회의적인 목소리는 유지되나 직역 표현이 눈에 띔 |
| Gunhild | 8.3 | 명령조와 단호한 목소리가 잘 맞음 |
| Haldric | 7.1 | 격식 있는 어조는 맞지만 계약 용어를 지나치게 직역함 |
| Hedwig | 8.0 | 문서 중심의 말투가 일관되나 일부 어휘 선택이 부정확함 |
| Hildegard | 8.5 | 차분하고 책임감 있는 어조가 자연스럽게 유지됨 |
| Jorund | 7.5 | 신중한 말투는 맞지만 질문·절차 표현에서 의미가 흐려짐 |
| Judith | 7.7 | 분석적인 목소리는 선명하나 몇몇 표현이 번역투임 |
| Lavinia | 7.3 | 절제된 격식은 적절하나 확인 응답 한 곳에서 뜻이 뒤집힘 |
| Levia | 8.0 | 조심스러운 목소리는 자연스러우나 감정 표현이 직역됨 |
| Lynette | 8.3 | 따뜻하고 실무적인 말투가 대체로 안정적임 |
| Marceline | 7.2 | 공손함은 일관되나 기본 영어 문장과 연결 표현을 다듬어야 함 |
| Miko | 7.9 | 담담한 말투는 맞지만 일부 압축이 뜻을 불분명하게 함 |
| Naran | 7.7 | 거래 어휘와 장난스러운 어조는 유지되나 관용 표현이 어색함 |
| Ornel | 7.2 | 조용한 말투는 유지되나 일부 표현이 의미를 잘못 전달함 |
| Saya | 7.5 | 절제된 말투는 살아 있지만 축약·직역이 잦음 |
| Selva | 8.0 | 절제되고 실무적인 음성은 일관되나 일부 완결 문장이 조각남 |
| Sorel | 7.5 | 건조한 말투는 맞지만 물건·문맥에 맞지 않는 어휘가 있음 |
| Teiris | 7.2 | 관찰하는 말투는 유지되나 영어 관용구 오역과 번역투가 반복됨 |
| Tika | 7.4 | 활달함과 취약함의 대비는 보이나 자연스러운 문장 다듬기가 필요함 |
| Tove | 8.2 | 짧은 말투는 잘 맞으나 일부 축약에서 뜻이 빠짐 |
| Urda | 7.3 | 사제다운 말투는 있으나 핵심 문장 한 곳에서 의미가 달라짐 |
| Zahar | 7.4 | 거친 간결체는 대체로 맞지만 문법 조각이 자주 나타남 |

## 수정 제안

표기: 심각도는 `틀림`(뜻 오류·누락), `어색`(부자연스러운 영어·직역), `권함`(말투나 문맥을 더 잘 살리는 편집)으로 구분했다. 각 경로는 JSON의 영어 필드 경로다.

### Adeline — 8.0/10

- **`inn/8/choices/2/text` · 어색** — 원문: `기도는 짧게 하고 바로 저랑 가요.` 현재: “Keep your prayers short and come with me.” 문제: 상대를 재촉하는 명령처럼 들려 공손한 말투와 어긋난다. 제안: “Say a brief prayer, then come with me.”
- **`inn/12/choices/1/text` · 권함** — 원문: `그래도 특별히 인정받은 거니 기뻐하세요.` 현재: “Still, you received special recognition. You should be happy.” 문제: 감정을 지시하는 듯한 직역이다. 제안: “Still, they recognized you in a special way. You can be glad of that.”

### Altan — 7.6/10

- **`inn/22/lines/0` · 어색** — 원문: `이번에는 바로 손해가 났습니다.` 현재: “This time, I made an immediate loss.” 문제: *make a loss*는 자연스러운 영어 용법이 아니다. 제안: “This time, I took a loss right away.”
- **`dungeon/26/variants/1` · 어색** — 원문: `확인도 없이 기록을 닫진 않겠습니다.` 현재: “I will not close the record without even checking.” 문제: *without even checking*이 겹쳐 들린다. 제안: “I will not close the record before checking.”

### Bargut — 7.8/10

- **`dungeon/18/variants/0` · 어색** — 원문: `큰 건 끝났다. 주변은 남았다.` 현재: “The big one is done. The surroundings are not.” 문제: 두 번째 문장이 영어로 성립하지 않고 의미도 흐린다. 제안: “The big one is down. We still need to check the area.”
- **`transitions/0/situation` · 어색** — 원문: `막았던 짐을 자기 손으로 옮긴다.` 현재: “Bargut moves the baggage that you were stopped from touching.” 문제: 관계절이 뒤엉켜 누가 누구를 막았는지 읽기 어렵다. 제안: “Bargut moves the pack he had stopped you from touching.”

### Berenga — 8.5/10

표본에서 뜻을 바꾸는 문제는 발견하지 못했다. 따뜻하고 협력적인 말투가 여관·던전·전환 대사에 고르게 유지된다.

### Bianca — 8.2/10

- **`inn/17/lines/2` · 어색** — 원문: `그냥 앉으면 될 걸요.` 현재: “When I could simply sit.” 문제: 원문의 완결된 생각이 영어에서는 종속절 조각으로 남는다. 제안: “I could have simply sat down.”
- **`inn/24/lines/0` · 어색** — 원문: `물어올 소식은 없었어요.` 현재: “I had no news to ask after.” 문제: *ask after*와 목적어 결합이 부자연스럽다. 제안: “There was no news to ask about.”

### Colette — 8.0/10

- **`inn/14/choices/0/response/0` · 어색** — 원문: `엎지르지 않게 조금 멀리 두십시오.` 현재: “Far enough away that I will not spill it, please.” 문제: 문장 성분이 빠진 파편이다. 제안: “Please set it far enough away that I won’t spill it.”
- **`transitions/8/lines/1` · 권함** — 원문: `조금만 더 웃고 말씀드리겠습니다.` 현재: “I will laugh a little longer, then speak.” 문제: 자연스러운 순서는 맞지만 공손한 어조가 다른 대사보다 갑자기 평평해진다. 제안: “Allow me to enjoy the laughter a little longer; then I will tell you.”

### Erdene — 8.2/10

- **`dungeon/26/variants/1` · 어색** — 원문: `앞자리 비워도 지금은 곁에 있을래.` 현재: “Even leaving the front empty, I'd rather stay beside them now.” 문제: 분사구문과 *them*이 어색하고, 가까운 상대를 가리키는 정서가 흐려진다. 제안: “Even if we leave the lead spot open, I want to stay by your side for now.”

### Felice — 8.0/10

- **`dungeon/12/variants/0` · 권함** — 원문: `싸움 끝났어요! 손은 다 괜찮아요?` 현재: “The fight's over! Everyone's hands all right?” 문제: *hands*가 실제 손 부상만 묻는 것처럼 좁아진다. 제안: “The fight's over! Is everyone all right?”
- **`transitions/6/lines/1` · 권함** — 원문: `제가 어떻게 그 골목에서 자랐는지 들어요.` 현재: “Hear how I grew up in that lane.” 문제: 영어에서 *Hear how…*는 명령처럼 들린다. 제안: “Let me tell you how I grew up in that lane.”

### Gerda — 7.8/10

- **`dungeon/6/variants/0` · 어색** — 원문: `찾은 것부터 봐요. 행운 덕이라고는 나중에 해요.` 현재: “Look at the find first. Credit luck later.” 문제: *the find*와 *credit luck*이 직역투다. 제안: “Let’s inspect what we found first. We can talk about luck later.”
- **`inn/24/lines/1` · 어색** — 원문: `입 푸는 거 아니에요.` 현재: “I wasn't warming up my mouth.” 문제: 한국어 관용 표현을 신체 동작으로 옮겨 뜻이 잘 전달되지 않는다. 제안: “I wasn’t just making small talk.”

### Gunhild — 8.3/10

- **`dungeon/0/variants/0` · 권함** — 원문: `출발할 준비가 됐으면 말해라.` 현재: “Say when you are ready to leave.” 문제: 문법상 가능하지만 상대에게 말하라고만 해 지휘관다운 명확성이 약하다. 제안: “Tell me when you’re ready to leave.”
- **`dungeon/18/variants/0` · 어색** — 원문: `큰 싸움은 끝났군. 다들 답해라.` 현재: “That great fight is over. Everyone, answer.” 문제: *great fight*는 대단한 싸움이라는 칭찬으로 읽힌다. 제안: “The major battle is over. Everyone, report in.”

### Haldric — 7.1/10

- **`inn/3/choices/2/response/0` · 어색** — 원문: `종이 놓을 자리만 비워 주면 되오.` 현재: “Only clear room for the paper.” 문제: 관사와 목적어가 빠져 명령이 부자연스럽다. 제안: “Just clear a space for the paper.”
- **`inn/23/situation` · 어색** — 원문: `할드리크가 보증 이름을 끝까지 적는다.` 현재: “Haldric writes the full name of surety.” 문제: *surety*를 사람의 이름 앞에 붙인 용례가 부자연스럽다. 제안: “Haldric writes out the guarantor’s full name.”
- **`dungeon/41/variants/1` · 틀림** — 원문: `오늘은 조항 대신 돌아오라는 말을 듣겠소.` 현재: “Today I will hear come back rather than a clause.” 문제: 문서 조항과 상대의 말을 대비하는 구조가 영어에서 무너졌다. 제안: “Today, I want to hear you tell me to come back, not read another clause.”

### Hedwig — 8.0/10

- **`inn/24/lines/0` · 틀림** — 원문: `기록은 끝났습니다.` 현재: “The recording is finished.” 문제: 문서 기록을 오디오 녹음으로 바꿔 읽힌다. 제안: “The record is complete.”
- **`dungeon/38/variants/1` · 어색** — 원문: `남은 인사는 말로 드리겠습니다.` 현재: “I will give the remaining greetings aloud.” 문제: *give greetings*가 부자연스럽고 영어 화법도 어색하다. 제안: “I’ll say my remaining goodbyes aloud.”

### Hildegard — 8.5/10

- **`dungeon/41/variants/1` · 어색** — 원문: `져도 같이 돌아갑니다. 제 손이 필요한 분 계십니까?` 현재: “Even in defeat, we return together. Does anyone need my hand?” 문제: *need my hand*는 도움을 청하는 관용 표현이 아니다. 제안: “Even if we lose, we’ll return together. Does anyone need help?”

### Jorund — 7.5/10

- **`inn/16/choices/0/text` · 틀림** — 원문: `돌아가는 데 얼마나 걸려요?` 현재: “How long will it add?” 문제: 귀환에 걸리는 시간을 묻는 뜻이 영어에 보존되지 않았다. 제안: “How long will it take to get back?”
- **`inn/17/choices/0/text` · 어색** — 원문: `종이에 안 쓰면 잊어도 괜찮겠네요.` 현재: “Without paper, forgetting's fine then.” 문제: 어순과 *fine then*이 부자연스럽다. 제안: “So it’s all right to forget if we don’t write it down.”

### Judith — 7.7/10

- **`inn/9/choices/2/response/0` · 어색** — 원문: `모른다는 말로 구경만 하진 말아요.` 현재: “Don't use ignorance to become a mere spectator.” 문제: 의미는 짐작되지만 *use ignorance to become*은 번역투다. 제안: “Don’t just stand by and say you don’t know.”
- **`inn/14/choices/1/text` · 권함** — 원문: `배울지와 힘을 쓸지를 먼저 물어봐야겠어요.` 현재: “Ask whether she wants to learn or use that power first.” 문제: *first*가 힘을 먼저 쓰라는 뜻으로 붙을 수 있다. 제안: “First, ask whether she wants to learn or use the power.”

### Lavinia — 7.3/10

- **`inn/11/choices/1/response/0` · 틀림** — 원문: `예. 이곳에서 먹을 생각이었어요.` 현재: “No. I intended to eat here.” 문제: 긍정 응답 `예`가 `No`로 뒤집혔다. 제안: “Yes. I was planning to eat here.”
- **`transitions/8/lines/1` · 어색** — 원문: `그 마음까지 모른 척하진 않겠습니다.` 현재: “I will not pretend that feeling is absent too.” 문제: *feeling is absent*는 직역투다. 제안: “I won’t pretend I don’t see that feeling, either.”

### Levia — 8.0/10

- **`dungeon/23/variants/1` · 어색** — 원문: `누구도 안 아팠으면 했는데 지금을 먼저 볼게요.` 현재: “I wished no one would hurt. But I'll attend to now first.” 문제: 소망 표현과 *attend to now*가 부자연스럽다. 제안: “I wish no one had to get hurt, but I’ll focus on what’s happening now.”
- **`inn/16/choices/0/response/1` · 권함** — 원문: `내일도 할지는 내일 물어봐 주세요.` 현재: “Ask tomorrow whether I want to do it tomorrow.” 문제: *tomorrow*가 반복되어 말이 뻣뻣하다. 제안: “Ask me tomorrow if I want to do it again.”

### Lynette — 8.3/10

- **`dungeon/18/variants/0` · 권함** — 원문: `큰 싸움이 끝났네요.` 현재: “That was a great battle.” 문제: *great*가 규모가 아니라 훌륭했다는 평가로 읽혀 `큰`의 의미와 어조를 바꾼다. 제안: “That was a major battle.”
- **`inn/26/seen` · 권함** — 원문: `오늘 못한 일을 잘한 일로 덮지는 않을래요.` 현재: “I won't cover today's failings with successes.” 문제: *cover … with successes*는 다소 추상적이고 직역투다. 제안: “I won’t try to make up for what I failed to do today by listing what I did well.”

### Marceline — 7.2/10

- **`dungeon/0/variants/0` · 어색** — 원문: `물은 챙기셨습니까? 남는 잔은 여기 두었습니다.` 현재: “Have you water? Spare cups are here.” 문제: 첫 문장이 비문에 가깝고 두 번째도 필요한 동사가 빠졌다. 제안: “Did you bring water? I left extra cups here.”
- **`inn/4/choices/2/response/0` · 어색** — 원문: `쏟지 않게 가방 옆은 피해 두십시오.` 현재: “Away from the bag, to avoid spills, please.” 문제: 행동 주체와 대상이 빠진 파편이다. 제안: “Please keep it away from the bag so it doesn’t spill.”
- **`inn/24/lines/0` · 틀림** — 원문: `다녀오라고 맡기신 일도 없는데 문 앞에서 잠깐 망설였습니다.` 현재: “No errand brought me back, so I hesitated at the door.” 문제: 원문은 돌아올 일을 맡긴 사람이 없는데도 문 앞에서 망설였다는 뜻이다. 현재 번역은 심부름이 돌아오게 했다는 의미로 바뀐다. 제안: “No one had sent me on an errand, yet I still hesitated at the door.”
- **`inn/27/seen` · 어색** — 원문: `별일 없는 날에도 안부는 여쭙고 싶습니다.` 현재: “Even uneventful days deserve asking how you are.” 문제: *days deserve asking*이 부자연스럽다. 제안: “Even on an uneventful day, I still want to ask how you are.”

### Miko — 7.9/10

- **`dungeon/6/variants/0` · 어색** — 원문: `손대기 전에 상태를 보죠.` 현재: “Condition before touching.” 문제: 원문이 완결된 제안인데 영어는 메모 조각이다. 제안: “Let’s check its condition before touching it.”
- **`transitions/3/situation` · 권함** — 원문: `미코가 가방 마개를 닫는다.` 현재: “Miko closes her bag's stopper.” 문제: *stopper*는 병마개에 쓰이며 가방의 여밈을 뜻하지 않는다. 제안: “Miko closes the clasp on her bag.”

### Naran — 7.7/10

- **`inn/6/choices/2/response/0` · 어색** — 원문: `제 입이 불편해 보였어요?` 현재: “Did my tongue look uncomfortable?” 문제: 혀가 불편해 보인다는 표현은 영어에서 의도한 표정·말하기의 불편함을 전달하지 못한다. 제안: “Did I look uncomfortable?”
- **`dungeon/0/variants/0` · 권함** — 원문: `먼저 가는 길값은 누구 몫이에요?` 현재: “Who pays for taking the road first?” 문제: *taking the road first*가 길을 먼저 이용하는 것으로 읽혀 앞장서는 대가라는 말장난이 흐려진다. 제안: “Who pays the price for taking the lead?”

### Ornel — 7.2/10

- **`inn/13/choices/0/response/1` · 어색** — 원문: `일부러 더 보고 싶지는 않아요.` 현재: “I don't want extra exposure deliberately.” 문제: *exposure*는 노출·폭로를 뜻해 원문의 ‘더 들여다보고 싶지 않다’와 맞지 않는다. 제안: “I don’t want to look any further on purpose.”
- **`inn/21/lines/1` · 틀림** — 원문: `그래도 전처럼 말없이 사라지진 않았죠.` 현재: “But didn't vanish silently as before.” 문제: 주어와 조동사가 빠져 문장이 성립하지 않고, 누가 사라지지 않았는지도 흐려진다. 제안: “But I didn’t disappear without a word like before.”

### Saya — 7.5/10

- **`inn/10/choices/1/response/1` · 어색** — 원문: `손이 느려졌네요.` 현재: “My hands slowed.” 문제: 영어의 시제·표현이 부자연스럽다. 제안: “My hands have slowed down.”
- **`dungeon/29/variants/1` · 어색** — 원문: `그래도 받아 둘게요. 손 빌려 줘서 고마워요.` 현재: “Still, I'll accept. Thank you for your hand.” 문제: `손 빌려 주다`를 신체 부위로 직역했다. 제안: “I’ll accept it, then. Thank you for helping me.”

### Selva — 8.0/10

- **`inn/27/seen` · 어색** — 원문: `이번에는 짐을 두고 밥 먹으러 가겠습니다.` 현재: “This time, leaving my bag to go eat.” 문제: 원문의 완결된 의지가 영어에서 문장 조각이 됐다. 제안: “This time, I’ll leave my bag here and go eat.”
- **`inn/10/choices/1/response/0` · 어색** — 원문: `저는 모래 냄새가 싫지 않습니다.` 현재: “I do not dislike sand's smell.” 문제: 소유격과 부정 표현이 모두 영어답지 않다. 제안: “I don’t mind the smell of sand.”

### Sorel — 7.5/10

- **`inn/2/situation` · 틀림** — 원문: `봉투 입구에 묻은 가루를 턴다.` 현재: “She brushes powder off a packet's mouth.” 문제: 봉투의 입구를 *mouth*로 옮겨 물리적 의미가 잘못됐다. 제안: “She brushes the powder off the packet’s opening.”
- **`inn/12/choices/1/text` · 어색** — 원문: `적힌 그대로 불러 드릴게요.` 현재: “I'll call you as written.” 문제: 사람에게 *as written*이라고 한다는 영어가 부자연스럽다. 제안: “I’ll address you exactly as it’s written.”

### Teiris — 7.2/10

- **`inn/5/choices/2/response/0` · 틀림** — 원문: `그럼 지금 맛있다고 해도 조금 늦은 대박인가요?` 현재: “Then calling it delicious now is belatedly awesome?” 문제: 한국어의 장난스러운 표현을 영어 관용구처럼 옮기려다 *belatedly awesome*이라는 무의미한 결합이 됐다. 제안: “Then am I too late to say it’s delicious?”
- **`inn/9/choices/1/response/1` · 틀림** — 원문: `교리서라고 하시면 저도 노트는 꺼내지 않을게요. 조금 기다릴 수 있어요.` 현재: “If she says doctrine, no notebook from me. I can wait.” 문제: 주어가 `she`로 바뀌고 *says doctrine*도 의미가 성립하지 않는다. 제안: “If you mean it’s a book of doctrine, I won’t take out my notebook. I can wait a little.”
- **`transitions/6/lines/1` · 어색** — 원문: `종이에 남길 말부터 고르지 않아도 편해요.` 현재: “Comfortable, without choosing recordable words first.” 문제: 완결된 생각이 메모 형태의 조각으로 축약됐다. 제안: “It’s a relief not to choose what to write down before I speak.”

### Tika — 7.4/10

- **`inn/8/choices/1/response/1` · 어색** — 원문: `입구까지 왔다가 한참 서 있었어요.` 현재: “I reached the entrance and stood ages.” 문제: `for`가 빠져 시간 표현이 비문이다. 제안: “I reached the entrance and stood there for ages.”
- **`inn/10/choices/1/response/0` · 어색** — 원문: `고르는 걸 연습해 보려던 건데요.` 현재: “I wanted practice choosing.” 문제: 명사·동사 결합이 부자연스럽다. 제안: “I wanted to practice making the choice.”
- **`transitions/11/lines/1` · 어색** — 원문: `같이 있고 싶어서 한 약속이에요.` 현재: “A promise made for company.” 문제: 원문은 화자가 함께 있고 싶어 약속했다는 뜻인데, 현재 문구는 막연한 동기로 바뀐 조각이다. 제안: “I made that promise because I wanted to be with you.”

### Tove — 8.2/10

- **`inn/19/lines/2` · 틀림** — 원문: `잔 잡고 있으니 풀렸어.` 현재: “Cup warmed them.” 문제: 잔이 손을 따뜻하게 했다는 뜻으로 바뀌어 긴장이 풀렸다는 내용이 빠졌다. 제안: “Holding my cup helped me loosen up.”
- **`dungeon/26/variants/1` · 어색** — 원문: `같이 나갈 방법을 생각하자.` 현재: “Think how we leave together.” 문제: 연결어와 어순이 빠져 영어로 매끄럽지 않다. 제안: “Let’s figure out how to leave together.”

### Urda — 7.3/10

- **`inn/4/choices/2/response/1` · 틀림** — 원문: `배부터 채우고 나서도 기도는 할 수 있소.` 현재: “Prayers work after filling bellies too.” 문제: 식사 뒤에도 기도할 수 있다는 말을 기도가 효과를 낸다는 뜻으로 바꿨다. 제안: “We can still pray after we’ve eaten.”
- **`inn/19/choices/0/response/0` · 어색** — 원문: `말 많은 사람이 빚진 밤도 있지요.` 현재: “Even talkative people owe some nights.” 문제: 직역 때문에 무엇을 빚졌다는지 뜻을 파악하기 어렵다. 제안: 문맥상 `말 많은 사람이 빚진 밤`이 무엇을 가리키는지 확인한 뒤 자연스러운 영어 관용 표현으로 다시 옮길 것.

### Zahar — 7.4/10

- **`inn/19/lines/2` · 어색** — 원문: `손을 좀 펴고 있어야겠어.` 현재: “Need my hand stretched open.” 문제: 부정사 조각처럼 들리고 `hand`도 어색하게 단수로 특정된다. 제안: “I need to keep my hands stretched out for a while.”
- **`dungeon/23/variants/1` · 어색** — 원문: `더 버틸 때까지 기다리지 마.` 현재: “Don't wait to endure more.” 문제: 영어에서는 더 버티는 행동을 기다리라는 뜻처럼 읽힌다. 제안: “Don’t wait until you’ve pushed yourself any further.”
- **`dungeon/32/variants/1` · 어색** — 원문: `깨면 내 물부터 한 잔 마실게.` 현재: “Awake, my water first.” 문제: 주어·동사·시제가 빠져 문장으로 읽히지 않는다. 제안: “When I wake up, I’ll have a glass of water first.”

## 총평

표본에서는 인물의 큰 말투 차이(격식·반말·단답형)는 대체로 보존됐으나, 간결체를 넘어서 영어 문장 성분이 빠진 사례가 여러 인물에게 반복된다. 특히 Marceline, Teiris, Haldric, Ornel, Lavinia, Urda, Zahar의 항목은 의미나 문법이 명확히 깨져 우선 수정할 만하다. 나머지 지적은 자연스러운 영어와 장면의 정서를 맞추기 위한 편집 제안이다. 이 보고서는 표본 검수이며 표본 밖 모든 필드까지 검수했다는 뜻은 아니다.
