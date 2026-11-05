# EN-R24 4차 영어 대사 다듬기 — 변경 대조

30명 전체 14,216개 영어 표시 필드를 파일 순서대로 읽었다. 실제 달라진 필드는 **1,268개**다. 같은 필드를 두 번 다듬어도 한 번만 센다. 의심되는 뜻·지시 대상·시제는 한국어 원문과 주변 장면을 함께 확인했다. 짧은 말투의 의도적인 단답·조각 문장은 유지했다.

독립 검수 보고서에는 지시서가 요약한 67건과 달리 **62건(틀림 11·어색 40·권함 11)**이 실제 열거되어 있다. 열거된 62건은 전부 수정했다. 나머지 5건은 경로·내용이 보고서에 없어 별도 지적으로 집계하지 않았다. 표본 밖에서도 전 인물의 공통 패턴을 점검했다.

| 인물 | 전체 표시 필드 | 바뀐 필드 |
| --- | ---: | ---: |
| adeline | 462 | 14 |
| altan | 468 | 16 |
| bargut | 468 | 25 |
| berenga | 468 | 16 |
| bianca | 475 | 23 |
| colette | 462 | 16 |
| erdene | 481 | 22 |
| felice | 468 | 24 |
| gerda | 470 | 28 |
| gunhild | 468 | 25 |
| haldric | 478 | 52 |
| hedwig | 468 | 20 |
| hildegard | 518 | 14 |
| jorund | 462 | 21 |
| judith | 477 | 34 |
| lavinia | 462 | 18 |
| levia | 471 | 21 |
| lynette | 468 | 28 |
| marceline | 518 | 53 |
| miko | 462 | 46 |
| naran | 490 | 48 |
| ornel | 462 | 49 |
| saya | 478 | 52 |
| selva | 462 | 54 |
| sorel | 468 | 60 |
| teiris | 518 | 123 |
| tika | 468 | 80 |
| tove | 462 | 54 |
| urda | 472 | 147 |
| zahar | 462 | 85 |

## 문맥에 따라 검수 제안을 조정한 곳

- 아델린의 강요하는 선택지는 부정적인 선택지 의미를 유지했다. 영어를 자연스럽게 하되 친절한 권유로 바꾸지 않았다.
- 바르구트는 기존 여성 인물 지시를 유지했다. 에르데네의 `ally_down` 문구는 쓰러진 동료를 가리키므로 `their side`로 다듬었다.
- 토베 `inn/19/lines/2`는 앞의 찬 손끝·잔·바람 문맥에 따라 손이 따뜻해지는 뜻을 살렸다. 긴장 해소로 바꾸지 않았다.
- 할드리크 `inn/23/situation`은 이어지는 계곡 이름·서약 문맥에 맞춰 보증으로 건 이름 전체를 적는 것으로 옮겼다.
- 우르다 `inn/19/choices/0/response/0`는 할드리크에게 도움받았던 밤에 대한 감사로 풀었다.
- 마르셀린 `inn/27/choices/0/response/0`의 원문에는 미래인 `내일`과 과거형 `계셨는지`가 함께 있다. 한국어는 그대로 두고, 영어는 안부를 묻고 다음 날도 평안하길 바라는 문맥으로 조정했다.

## 인물별 대표 전후 예시 5개

전체 변경 경로와 전후 문구는 [polish-edits-final.json](polish-edits-final.json), 검수 62건의 처리 내역은 [polish-review-items.json](polish-review-items.json)에 있다.

### adeline — 14개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/8/choices/2/text | 기도는 짧게 하고 바로 저랑 가요. | Keep your prayers short and come with me. | Say a brief prayer, then come straight with me. |
| inn/12/choices/1/text | 그래도 특별히 인정받은 거니 기뻐하세요. | Still, you received special recognition. You should be happy. | Still, you were singled out for recognition. You should be pleased. |
| inn/1/choices/0/text | 늘 양보하시니 이번에도 부탁드릴게요. | You always give way, so I will ask you again. | You always give up your seat, so I will ask you again. |
| inn/11/lines/0 | 아까 제 뒤는 못 보셨죠? | You did not see behind me earlier, did you? | You did not see what was behind me earlier, did you? |
| inn/16/lines/2 | 같이 앉아 있어도 그 말을 들으면 멀어져요. | Even sitting together, I feel farther away when I hear it. | Even when we sit together, I feel farther away when I hear it. |

### altan — 16개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/22/lines/0 | 이번에는 바로 손해가 났습니다. | This time, I made an immediate loss. | This time, I took a loss right away. |
| dungeon/26/variants/1 | 확인도 없이 기록을 닫진 않겠습니다. | I will not close the record without even checking. | I will not close the record before checking. |
| inn/1/choices/1/response/0 | 두 줄을 비교할 만큼이면 됩니다. | Enough to compare the two entries will do. | A sheet large enough to compare the two entries will do. |
| inn/16/situation | 장부 없이 앉았다가 빈손을 확인한다. | Altan sits without a ledger and looks at empty hands. | Altan sits without a ledger and looks at her empty hands. |
| inn/17/lines/1 | 제 이름을 부른 말입니다. | The words in which you called my name. | The moment you called me by my name. |

### bargut — 25개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| dungeon/18/variants/0 | 큰 건 끝났다. 주변은 남았다. | The big one is done. The surroundings are not. | The big one is down. We still need to check the area. |
| transitions/0/situation | 막았던 짐을 자기 손으로 옮긴다. | Bargut moves the baggage that you were stopped from touching. | Bargut moves the pack she had stopped you from touching. |
| inn/4/choices/0/response/0 | 나는 지금 덜 어색하다. | I'm less awkward as I'm. | I'm more comfortable where I am. |
| inn/5/seen | 매듭은 내가 고쳤으니 컵을 줘라. | Knot is fixed. Give me the cup. | The knot's fixed. Give me the cup. |
| inn/6/choices/1/response/0 | 참고 있어야 할 자리는 아니다. | This is no place I have to endure. | I don't have to put up with this place. |

### berenga — 16개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/3/choices/1/response/0 | 서로 얼굴 볼 만큼만 붙여 주세요. | Just bring them close enough to see each other's faces. | Just move the chairs close enough that we can see each other's faces. |
| inn/4/lines/1 | 처음 뵙는 건가요? 제가 성급했네요. | Have we never met? I got ahead of myself. | Haven't we met? I got ahead of myself. |
| inn/5/lines/0 | 따뜻하네요. 숟가락 잡은 손까지 풀려요. | It's warm. Even my spoon hand is loosening up. | It's warm. Even the hand holding my spoon is warming up. |
| inn/7/lines/0 | 쇠붙이가 없으니 가볍겠다고요? | You think I'd be lighter without the metal? | You think I travel light because I wear no metal? |
| inn/9/choices/0/response/1 | 끈이 마른 뒤에도 할 얘기가 남아 있었어요. | I still had things to say after the strap dried. | Even after the strap dries, I'll still have things to say. |

### bianca — 23개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/17/lines/2 | 그냥 앉으면 될 걸요. | When I could simply sit. | I could have simply sat down. |
| inn/24/lines/0 | 물어올 소식은 없었어요. | I had no news to ask after. | There was no news to ask about. |
| inn/0/seen | 덮은 종이에까지 웃음을 옮기지는 않았어요. | My smile didn't extend to the covered paper. | My smile wasn't an invitation to read the paper I covered. |
| inn/3/seen | 빠진 줄은 조용히 줄여 쓰지 않겠어요. | I won't quietly shrink the missing line. | I won't quietly write down a smaller amount on the missing line. |
| inn/5/choices/2/response/0 | 제가 짚는 곳을 같이 보세요. | Look with me where I'm pointing. | Look at the line I'm pointing to with me. |

### colette — 16개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/14/choices/0/response/0 | 엎지르지 않게 조금 멀리 두십시오. | Far enough away that I will not spill it, please. | Please set it far enough away that I will not spill it. |
| transitions/8/lines/1 | 조금만 더 웃고 말씀드리겠습니다. | I will laugh a little longer, then speak. | Please let me laugh a little longer before I tell you. |
| inn/1/choices/1/response/0 | 종이 없는 곳은 괜찮습니다. | Where there is no paper is fine. | You may wipe where there is no paper. |
| inn/5/choices/2/response/0 | 입꼬리가 자꾸 올라가니 잠시만 못 본 척해 주십시오. | My mouth keeps turning up. Please pretend not to notice a moment. | I keep starting to smile. Please pretend not to notice for a moment. |
| inn/12/lines/2 | 웃음이 나면 입부터 다물게 됐습니다. | When laughter came, I began shutting my mouth first. | When I felt laughter coming, I learned to press my lips together. |

### erdene — 22개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| dungeon/26/variants/1 | 앞자리 비워도 지금은 곁에 있을래. | Even leaving the front empty, I'd rather stay beside them now. | Even if it leaves the front line open, I want to stay by their side for now. |
| inn/0/choices/0/response/0 | 싸웠어도 쓸 곳은 남겨 둔 거야? | Even after fighting, you kept a use for me? | Even after that fight, you're still thinking of how to use me? |
| inn/2/lines/1 | 누가 어느 줄인지. | Who's in which line. | And who goes in each line? |
| inn/4/choices/2/text | 이름보다 실력을 보면 금방 친해지겠죠? | We'll get friendly quicker by looking at skill than names, won't we? | We'll get to know each other faster by showing our skills than trading names, won't we? |
| inn/7/choices/2/response/0 | 빠졌다고 알아보는 사람이 나뿐이면 누가 불러? | If I'm the only one who notices what's missing, who'll call it? | If I'm the only one who notices what's missing, who'll know to call me by it? |

### felice — 24개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| dungeon/12/variants/0 | 싸움 끝났어요! 손은 다 괜찮아요? | The fight's over! Everyone's hands all right? | The fight's over! Is everyone all right? |
| transitions/6/lines/1 | 제가 어떻게 그 골목에서 자랐는지 들어요. | Hear how I grew up in that lane. | Let me tell you how I grew up in that lane. |
| inn/0/lines/2 | 당사자한테 직접 물어봐 주세요. | Please ask them yourselves. | Please ask them yourself. |
| inn/2/choices/0/response/0 | 직접 확인하면 제 말 때문에 헷갈리진 않겠어요. | Checking yourself should keep my words from confusing things. | Checking for yourself should keep my words from muddling things. |
| inn/2/choices/2/response/0 | 제 이름이 붙으면 없던 신뢰도 생겨요. | Put my name on it and you create trust that wasn't there. | Use my name and it'll sound as though I've vouched for it. |

### gerda — 28개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/24/lines/1 | 입 푸는 거 아니에요. | I wasn't warming up my mouth. | That wasn't just idle chatter. |
| dungeon/6/variants/0 | 찾은 것부터 봐요. 행운 덕이라고는 나중에 해요. | Look at the find first. Credit luck later. | Let’s inspect what we found first. We can talk about luck later. |
| inn/0/choices/0/response/0 | 안 들은 말로 달래 주려는 건가? | Soothing me with something you haven't even heard? | Trying to reassure me before you've even heard me out? |
| inn/5/lines/0 | 입 푸는 거예요. | Warming up my mouth. | Just warming up my voice. |
| inn/7/choices/2/response/0 | 무조건이 붙으면 나도 묻기가 어려워요. | Add just to that and even asking becomes difficult. | When you say 'just,' even asking becomes difficult. |

### gunhild — 25개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| dungeon/0/variants/0 | 출발할 준비가 됐으면 말해라. | Say when you are ready to leave. | Tell me when you are ready to leave. |
| dungeon/18/variants/0 | 큰 싸움은 끝났군. 다들 답해라. | That great fight is over. Everyone, answer. | The major battle is over. Everyone, report in. |
| inn/4/choices/1/response/0 | 남의 장비에 흠집 내고 할 말은 아니다. | Not something to say after scratching someone else's equipment. | That is no excuse for scratching someone else's equipment. |
| inn/4/choices/1/response/1 | 오래 쓴 것이라 더 함부로 놓고 싶지 않다. | Having used it so long makes me less willing to leave it carelessly. | I have used it too long to leave it lying carelessly. |
| inn/6/choices/0/response/0 | 그럼 그 말은 받겠다. 그, 잘 봤군. | Then I accept. You, ah, noticed well. | Then I accept. You, ah, were paying attention. |

### haldric — 52개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/3/choices/2/response/0 | 종이 놓을 자리만 비워 주면 되오. | Only clear room for the paper. | Just clear a space for the paper. |
| inn/23/situation | 할드리크가 보증 이름을 끝까지 적는다. | Haldric writes the full name of surety. | Haldric writes out the full name pledged as a guarantee. |
| dungeon/41/variants/1 | 오늘은 조항 대신 돌아오라는 말을 듣겠소. | Today I will hear come back rather than a clause. | Today, I would rather hear you tell me to come back than recite another clause. |
| inn/0/seen | 펼친 문서에서 확인할 줄만 남겨 두었소. | I have left only the lines to check on the open document. | I have left the document open only at the lines we need to check. |
| inn/1/choices/0/response/1 | 내가 읽은 문장도 그 결정에 들어가야 하오. | The words I read must be part of that decision, too. | The wording I have read must inform that decision, too. |

### hedwig — 20개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/24/lines/0 | 기록은 끝났습니다. | The recording is finished. | The record is complete. |
| dungeon/38/variants/1 | 남은 인사는 말로 드리겠습니다. | I will give the remaining greetings aloud. | I will say the rest of my goodbyes aloud. |
| inn/2/choices/2/response/0 | 그 순서로는 동의했다고 보기 어렵습니다. | That order makes it difficult to call this agreement. | Signing before reading makes it difficult to call this an agreement. |
| inn/3/choices/1/response/0 | 직접 적는 일까지 덜어 낼 생각은 없습니다. | I do not intend to spare myself the writing, too. | I do not intend to avoid the work of writing it myself. |
| inn/6/lines/1 | 부르기 위한 이름을 적는 중입니다. | I am writing a name to call it. | I am choosing what to call it. |

### hildegard — 14개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| dungeon/41/variants/1 | 져도 같이 돌아갑니다. 제 손이 필요한 분 계십니까? | Even in defeat, we return together. Does anyone need my hand? | Even if we lose, we will return together. Does anyone need help? |
| inn/1/choices/2/response/1 | 등은 제 눈으로 살피기 어렵습니다. 확인하겠습니다. | My back is difficult to inspect myself. I will check. | It is difficult to inspect my own back. I will check. |
| inn/5/choices/0/text | 기사 장비니까 알아서 튼튼하겠어요. | Knight's armor must hold up well on its own. | A knight's armor must hold up well on its own. |
| inn/7/choices/2/response/1 | 멈추라는 말도 따르겠습니다. 앞에서 안 보이는 것은 부탁드려야 합니다. | I will stop if asked. I must rely on you for what I cannot see ahead. | I will stop if asked. I must rely on you for what I cannot see behind me. |
| inn/9/choices/0/response/1 | 제가 먹는 동안은 부탁드리겠습니다. 한 숟갈쯤 늦어도 괜찮겠습니다. | Then I entrust that to you while I eat. A spoonful's delay should be all right. | Then I entrust that to you while I eat. Surely I can take a spoonful before looking again. |

### jorund — 21개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/16/choices/0/text | 돌아가는 데 얼마나 걸려요? | How long will it add? | How long will it take to get back? |
| inn/17/choices/0/text | 종이에 안 쓰면 잊어도 괜찮겠네요. | Without paper, forgetting's fine then. | So it is all right to forget if we do not write it down. |
| inn/0/choices/2/text | 편하게 얘기하면 생각도 달라질 거예요. | A relaxed talk might change your mind. | A relaxed conversation might change your mind. |
| inn/0/choices/2/response/0 | 제 판단은 분위기 때문에 바뀌지 않습니다. | Atmosphere does not change my judgment. | A pleasant atmosphere does not change my judgment. |
| inn/5/choices/2/response/0 | 방금 떠 와서 아직 차갑습니다. | Freshly drawn. Still cold. | It was freshly drawn. It is still cold. |

### judith — 34개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/9/choices/2/response/0 | 모른다는 말로 구경만 하진 말아요. | Don't use ignorance to become a mere spectator. | Don’t just stand by and say you don’t know. |
| inn/14/choices/1/text | 배울지와 힘을 쓸지를 먼저 물어봐야겠어요. | Ask whether she wants to learn or use that power first. | First, ask whether she wants to learn or use the power. |
| inn/0/choices/2/response/0 | 보호한다며 빼앗는 손도 있네요. | So even protection can have grasping hands. | So you can take control of my work in the name of protection, too. |
| inn/0/seen | 덮은 계산을 동의한 계산으로 읽진 마세요. | Don't read covered calculations as consent. | Covered calculations aren't an invitation to read them. |
| inn/2/lines/1 | 허가가 없다고요? | No permission? | Because I had no permission? |

### lavinia — 18개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/11/choices/1/response/0 | 예. 이곳에서 먹을 생각이었어요. | No. I intended to eat here. | Yes. I was planning to eat here. |
| transitions/8/lines/1 | 그 마음까지 모른 척하진 않겠습니다. | I will not pretend that feeling is absent too. | I will not pretend I do not feel that wish to help, either. |
| inn/3/choices/1/response/1 | 잠깐 다녀오는 동안 그대로 두세요. | Leave it while I am briefly away. | Please leave the choice to me, even if I am away for a moment. |
| inn/6/lines/1 | 밥 먹기에도 덜 어둡겠어요. | Less gloomy for eating too. | It is less gloomy here for eating, too. |
| inn/7/lines/1 | 같은 뜻인 줄 알고 읽다가 멈췄어요. | I stopped after assuming the wording meant the same. | I had to stop after assuming the wording meant the same thing. |

### levia — 21개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/16/choices/0/response/1 | 내일도 할지는 내일 물어봐 주세요. | Ask tomorrow whether I want to do it tomorrow. | Ask me tomorrow if I want to do it again. |
| dungeon/23/variants/1 | 누구도 안 아팠으면 했는데 지금을 먼저 볼게요. | I wished no one would hurt. But I'll attend to now first. | I wish no one had to get hurt, but I’ll focus on what’s happening now. |
| inn/3/choices/1/response/1 | 아직 못 나가겠다는 답도 잠깐 남겨 주세요. | Let my answer that I can't go out stand a moment too. | Please let my answer stand for a moment. I can't go out yet. |
| inn/6/choices/1/text | 참으면 곧 따뜻해져요. 저도 그래요. | Bear it a little. You'll warm up. I do. | Bear it a little. You'll warm up. I do, too. |
| inn/7/lines/1 | 그런데 조금 모자란 것 같아요. | But it seems a little short. | But I don't think it's quite enough. |

### lynette — 28개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/26/seen | 오늘 못한 일을 잘한 일로 덮지는 않을래요. | I won't cover today's failings with successes. | I won't cover up what I failed to do today by listing what I did well. |
| dungeon/18/variants/0 | 큰 싸움이 끝났네요. | That was a great battle. | That was a major battle. |
| inn/2/choices/0/response/0 | 먹을 수 없는 걸 많이 받아도 곤란해요. | Plenty they can't eat would be troublesome. | A large amount of something they can't eat would be troublesome. |
| inn/4/choices/0/response/0 | 글씨를 덧쓸 때 쓰면 되겠어요. | Good for tracing the letters. | It will be good for going over the letters. |
| inn/7/choices/1/response/0 | 제 밥까지 마음대로 나누진 말아 주세요. | Please don't give my dinner away without asking too. | Please don't give my dinner away without asking, either. |

### marceline — 53개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/4/choices/2/response/0 | 쏟지 않게 가방 옆은 피해 두십시오. | Away from the bag, to avoid spills, please. | Please keep it away from the bag so it does not spill. |
| inn/24/lines/0 | 다녀오라고 맡기신 일도 없는데 문 앞에서 잠깐 망설였습니다. | No errand brought me back, so I hesitated at the door. | No one had sent me on an errand, yet I still hesitated at the door. |
| inn/27/seen | 별일 없는 날에도 안부는 여쭙고 싶습니다. | Even uneventful days deserve asking how you are. | Even on an uneventful day, I still want to ask how you are. |
| dungeon/0/variants/0 | 물은 챙기셨습니까? 남는 잔은 여기 두었습니다. | Have you water? Spare cups are here. | Did you bring water? I left extra cups here. |
| inn/0/choices/1/response/1 | 마시라고 내민 건데, 그냥 두고 가기는 어렵군요. | I offered it for you to drink. Leaving it untouched feels difficult. | I offered it for you to drink. I find it hard to leave while it is untouched. |

### miko — 46개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| dungeon/6/variants/0 | 손대기 전에 상태를 보죠. | Condition before touching. | Let’s check its condition before touching it. |
| transitions/3/situation | 미코가 가방 마개를 닫는다. | Miko closes her bag's stopper. | Miko closes the clasp on her bag. |
| inn/2/lines/1 | 부스러기라고 털어 버리지 마세요. | Don't shake it out as scraps. | Don't shake them out as though they were scraps. |
| inn/3/lines/1 | 손을 보고 있으면 말씀을 놓쳐요. | Watching my hands, I miss your words. | When I focus on my hands, I miss what you're saying. |
| inn/4/lines/2 | 목소리가 작아도 들으니 편하게 말하세요. | I hear soft voices too. Speak comfortably. | I can hear you even when you speak softly. Use whatever voice is comfortable. |

### naran — 48개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/6/choices/2/response/0 | 제 입이 불편해 보였어요? | Did my tongue look uncomfortable? | Did I look uncomfortable? |
| dungeon/0/variants/0 | 먼저 가는 길값은 누구 몫이에요? | Who pays for taking the road first? | Who pays the price for taking the lead? |
| inn/0/choices/1/response/0 | 시각은 들었어요. 저도 늦지 않을게요. | Heard. I'll be punctual too. | Heard you. I'll be on time, too. |
| inn/1/seen | 손 아래 종이는 아직 누구 값에도 안 들어갔어요. | The paper under my hand belongs to no bargain yet. | The paper under my hand isn't part of any bargain yet. |
| inn/4/seen | 이번 얼굴은 맞힐수록 값이 달라지겠어요. | This face's price changes with each guess. | The price of reading this face changes with every correct guess. |

### ornel — 49개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/13/choices/0/response/1 | 일부러 더 보고 싶지는 않아요. | I don't want extra exposure deliberately. | I do not want to seek out more of them just to get used to them. |
| inn/21/lines/1 | 그래도 전처럼 말없이 사라지진 않았죠. | But didn't vanish silently as before. | But I didn’t disappear without a word like before. |
| inn/0/seen | 그쪽에서도 제 말은 들리겠어요. | You should hear me there too. | You should be able to hear me from there, too. |
| inn/1/choices/2/response/0 | 주전자는 식탁 끝에 있어요. | At the table's end. | It's at the end of the table. |
| inn/2/choices/1/response/0 | 발소리도 평소보다 겹쳐 들려요. | More overlapping footsteps than usual too. | I can hear more footsteps overlapping than usual, too. |

### saya — 52개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/10/choices/1/response/1 | 손이 느려졌네요. | My hands slowed. | My hands have slowed down. |
| dungeon/29/variants/1 | 그래도 받아 둘게요. 손 빌려 줘서 고마워요. | Still, I'll accept. Thank you for your hand. | I'll accept it, then. Thank you for helping me. |
| inn/0/choices/1/response/0 | 편한 일과 보여 주는 일은 달라요. | Enjoying it and showing it are different. | Enjoying it is different from wanting to show it. |
| inn/0/choices/1/response/1 | 지금은 손도 좀 숨길래요. | Right now I'll hide my hands too. | Right now I'd rather keep my hands out of sight, too. |
| inn/2/lines/1 | 어디까지인지는 못 들었고요. | Not how far. | But not how far. |

### selva — 54개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/10/choices/1/response/0 | 저는 모래 냄새가 싫지 않습니다. | I do not dislike sand's smell. | I don’t mind the smell of sand. |
| inn/27/seen | 이번에는 짐을 두고 밥 먹으러 가겠습니다. | This time, leaving my bag to go eat. | This time, I will leave my bag here and go eat. |
| inn/2/choices/0/response/1 | 괜찮은지는 제게 물으셨어야죠. | Whether I am willing required asking me. | You still needed to ask whether I was willing. |
| inn/4/lines/0 | 처음 같이 나가는 일이군요. | Our first journey together. | This is our first journey together. |
| inn/4/choices/1/response/0 | 지금 정해 두는 편이 편합니다. | Easier to settle now. | It is easier to settle the money now. |

### sorel — 60개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/2/situation | 봉투 입구에 묻은 가루를 턴다. | She brushes powder off a packet's mouth. | She brushes the powder off the packet’s opening. |
| inn/12/choices/1/text | 적힌 그대로 불러 드릴게요. | I'll call you as written. | I'll address you exactly as it's written. |
| inn/0/lines/1 | 필요해도 묻고 가져가세요. | Even if you need some, ask before taking it. | Even if you need some, ask before taking any. |
| inn/0/choices/1/response/0 | 쓰임을 알면 내줄지 정할 수 있어요. | Knowing the use lets me decide. | Knowing what you'll use it for lets me decide. |
| inn/0/choices/2/response/0 | 봉투를 놓을 만큼만 비켜 주세요. | Just room for the packet. | Just leave room for the packet. |

### teiris — 123개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/5/choices/2/response/0 | 그럼 지금 맛있다고 해도 조금 늦은 대박인가요? | Then calling it delicious now is belatedly awesome? | Then am I too late to say it's delicious? |
| inn/9/choices/1/response/1 | 교리서라고 하시면 저도 노트는 꺼내지 않을게요. 조금 기다릴 수 있어요. | If she says doctrine, no notebook from me. I can wait. | If you mean it's a book of doctrine, I won't take out my notebook. I can wait a little. |
| transitions/6/lines/1 | 종이에 남길 말부터 고르지 않아도 편해요. | Comfortable, without choosing recordable words first. | It is a relief not to choose what to write down before I speak. |
| inn/0/choices/0/response/0 | 정리하지 않은 말도 들을 수 있어요. | I can hear unorganized words too. | I can listen even if you haven't organized your thoughts. |
| inn/0/choices/0/response/1 | 제가 적을 것만 말하시려는 것 같아서 조금 멀게 들리네요. | Speaking only for my notes sounds a little distant. | Speaking only to help me take notes feels a little distant. |

### tika — 80개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/8/choices/1/response/1 | 입구까지 왔다가 한참 서 있었어요. | I reached the entrance and stood ages. | I reached the entrance and stood there for ages. |
| inn/10/choices/1/response/0 | 고르는 걸 연습해 보려던 건데요. | I wanted practice choosing. | I wanted to practice making the choice. |
| transitions/11/lines/1 | 같이 있고 싶어서 한 약속이에요. | A promise made for company. | I made that promise because I wanted to be with you. |
| inn/0/situation | 식탁에서 큰소리로 웃다가 둘만 남자 굳는다. | Her loud table laughter freezes when only two remain. | Her loud laughter at the table stops when only the two of you remain. |
| inn/0/choices/2/response/1 | 둘이 남으면 아까 하던 말도 잘 안 나와요. | Alone together, even those words won't come. | When it's just us, even those words won't come. |

### tove — 54개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/19/lines/2 | 잔 잡고 있으니 풀렸어. | Cup warmed them. | Holding the cup helped my fingers warm up. |
| dungeon/26/variants/1 | 같이 나갈 방법을 생각하자. | Think how we leave together. | Let's figure out how to leave together. |
| inn/0/seen | 코트가 있으니 나는 좀 더 있을게. | I've my coat. I'll stay longer. | I've got my coat. I'll stay longer. |
| inn/2/lines/2 | 금방 옮길 수 있게 두고 싶어. | Want it easy to move. | I want it easy to move. |
| inn/2/choices/2/text | 통로만 비우면 괜찮겠네요. | Clear passage, and it's fine. | Keep the passage clear, and it's fine. |

### urda — 147개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/4/choices/2/response/1 | 배부터 채우고 나서도 기도는 할 수 있소. | Prayers work after filling bellies too. | We can still pray after we've eaten. |
| inn/19/choices/0/response/0 | 말 많은 사람이 빚진 밤도 있지요. | Even talkative people owe some nights. | Even someone as talkative as I am has nights when I owe someone my thanks. |
| inn/0/choices/0/response/0 | 국까지 내 말의 편을 들 필요는 없는데요. | Even soup needn't take my side. | Even sharing soup need not mean taking my side. |
| inn/0/choices/2/response/0 | 먹는 동안 들을 귀는 있소. | I have ears while eating. | I can listen while I eat. |
| inn/0/seen | 말 적게 하는 날에도 국은 내줄 수 있소. | Even quiet days allow soup offered. | I can offer soup even on quiet days. |

### zahar — 85개

| 필드 | 한국어 원문 | 전 | 후 |
| --- | --- | --- | --- |
| inn/19/lines/2 | 손을 좀 펴고 있어야겠어. | Need my hand stretched open. | I need to keep my hands open for a while. |
| dungeon/23/variants/1 | 더 버틸 때까지 기다리지 마. | Don't wait to endure more. | Do not wait just to see how much more you can endure. |
| dungeon/32/variants/1 | 깨면 내 물부터 한 잔 마실게. | Awake, my water first. | When I wake up, I'll have some water first. |
| inn/0/choices/0/response/0 | 남았는지 보이는 게 다야? | Looks tell you all my strength? | Can you tell how much strength I have just by looking? |
| inn/2/choices/0/response/0 | 발에 걸리는 것만 치워 줘. | Just trip hazards out. | Just clear anything we could trip on. |

