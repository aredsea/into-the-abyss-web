"""Hand-reviewed, path-specific fifth-pass edits for the first twelve voices."""
import json,sys
from pathlib import Path
from collections import Counter
sys.path.insert(0,'tools')
from dialogue_r21_build import ROOT,display_fields,replace_at,write_json
OUT=ROOT/'verification/dialogue-r21'
IDS=['hildegard','marceline','teiris','naran','haldric','erdene','bianca','saya','gerda','judith','levia','urda']
REASONS={
 '비유':'한국어 지침 1.1·1.4: 반복되는 추상 비유를 장면의 행동과 부탁으로 풀었다.',
 '원칙':'한국어 지침 2.2·5.4: 대구·원칙 요약을 상대에게 하는 구체적인 말로 바꿨다.',
 '해설':'한국어 지침 3.1: 앞에서 드러난 마음을 다시 해설하는 말을 줄였다.',
 '부정':'한국어 지침 2.2·3.3: 부정 되받기를 줄이고 원래 바람을 직접 말했다.',
 '먼저':'한국어 지침 3.3: 순서 강조가 불필요한 곳의 먼저 반복을 덜었다.',
 '문서':'한국어 지침 1.3·5.4: 사적인 대화에서 문서·보고 어휘를 입말로 풀었다.',
 '선택':'한국어 지침 5.4·5.5: 평가 문항 같은 선택을 실제 행동·제안으로 바꿨다.',
 '연어':'한국어 지침 1.1: 장면에서 바로 뜻을 알 수 있도록 낱말의 짝을 고쳤다.'}
TEXT='''
hildegard|inn/0/choices/2/response/1|제 역할을 정하기 전에 제게도 물어 주십시오.|비유
hildegard|inn/1/choices/2/response/1|등은 제 눈으로 살피기 어렵습니다. 확인하겠습니다.|원칙
hildegard|inn/2/choices/0/response/1|제게 주셔도 됩니다만, 그분에게도 들 수 있는지 물어 주십시오.|비유
hildegard|inn/2/choices/1/response/0|들고 조금 걸어 보시겠습니까?|부정
hildegard|inn/3/choices/2/response/0|믿습니다. 그래도 만날 곳은 정해 두겠습니다.|원칙
hildegard|inn/3/choices/2/response/1|흩어지면 돕고 싶어도 못 돕습니다.|해설
hildegard|inn/4/choices/1/response/1|안쪽 의자를 내드리겠습니다. 여기 계셔도 됩니다.|해설
hildegard|inn/4/choices/2/response/1|그럼 안쪽으로 오시겠습니까?|해설
hildegard|inn/4/seen|의자는 안쪽으로 들여놓았습니다.|먼저
hildegard|inn/6/choices/1/response/1|그럼 잔은 여기 두겠습니다.|해설
hildegard|inn/8/choices/1/response/0|귀환할 때는 뒤를 부탁드리겠습니다.|해설
hildegard|inn/9/choices/0/response/0|덕분에 따뜻할 때 먹겠습니다.|해설
hildegard|inn/10/choices/2/response/1|둘이 나누면 다친 분의 짐도 무리 없이 들겠습니다.|비유
hildegard|inn/11/lines/0|보폭을 얼마나 줄여야 할지 생각했습니다.|먼저
hildegard|inn/12/lines/0|봉투만 들었다 놨다 했습니다. 무슨 말을 쓸지 못 골랐습니다.|먼저
hildegard|inn/16/choices/0/response/0|다 쓰면 읽어 주시겠습니까?|먼저
hildegard|inn/16/choices/0/response/1|중간에 고칠지도 모르니 잠시만 기다려 주십시오.|해설
hildegard|inn/18/choices/0/response/0|예, 저도 앉겠습니다.|해설
hildegard|inn/19/lines/1|의견을 듣고 나서 쓰겠습니다.|먼저
hildegard|inn/19/choices/2/response/1|짧게 말씀하셔도 듣겠습니다. 펜은 내려놓겠습니다.|먼저
hildegard|inn/19/seen|종이를 뒤집어 놓고 말씀을 듣겠습니다.|비유
hildegard|inn/20/choices/1/response/0|저도 힘들 때는 말씀드리겠습니다.|원칙
hildegard|inn/22/choices/2/response/0|제가 늦을 때도 기다려 주시겠습니까?|비유
hildegard|inn/24/choices/2/response/1|지금은 함께 먹고 싶습니다. 준비는 조금 뒤에 하겠습니다.|해설
hildegard|inn/25/choices/2/response/1|제 준비가 늦었는데도 기다려 주셨습니다. 감사합니다.|해설
marceline|inn/2/choices/2/response/1|조금만 기다려 주시겠습니까? 곧 앉겠습니다.|해설
marceline|inn/3/choices/1/response/1|말씀은 고맙습니다만, 이 책은 가지고 있겠습니다.|해설
marceline|inn/4/choices/1/response/0|그럼 제 것도 받아 두겠습니다.|해설
marceline|inn/6/choices/2/response/1|그럼 안쪽에 앉겠습니다. 여기는 바람이 덜 드는군요.|해설
marceline|inn/8/choices/0/response/0|여기서 한참 망설였습니다.|해설
marceline|inn/9/choices/2/response/0|그럼 책을 내려놓겠습니다.|비유
marceline|inn/10/choices/1/response/0|앉아서 같이 먹겠습니다.|해설
marceline|inn/10/choices/1/response/1|기다려 주셔서 감사합니다.|해설
marceline|inn/11/choices/0/response/1|얼마나 기다리실 수 있는지 여쭙겠습니다.|해설
marceline|inn/12/choices/2/response/1|판결문을 읽어도 그 사람 앞에 섰던 일이 떠올랐습니다.|해설
marceline|inn/14/choices/0/response/0|그럼 옆에 앉겠습니다.|해설
marceline|inn/14/choices/0/response/1|책만 보고 한참을 기다릴 뻔했습니다.|해설
marceline|inn/15/choices/2/response/1|내일부터는 제 잔도 놓겠습니다.|해설
marceline|inn/15/seen|제 잔에도 물을 따라 두었습니다.|먼저
marceline|inn/17/lines/0|종이에 쓰기 전에 말씀드리고 싶었습니다.|먼저
marceline|inn/19/choices/1/response/1|말하다가 좀 멈추더라도 기다려 주십시오.|해설
marceline|inn/21/choices/2/response/1|마음에 드는 곳이 나오면 책을 덮겠습니다. 그때 들어 주시겠습니까?|먼저
marceline|inn/22/choices/0/response/1|전에는 물이 남아야 제 잔을 챙겼습니다. 이제는 같이 마시겠습니다.|해설
marceline|inn/22/choices/1/response/1|같이 쉬어 주시겠다는 말이 반갑습니다.|해설
marceline|inn/23/choices/0/response/0|지금 죄송하다고 말씀드리겠습니다.|부정
marceline|inn/23/choices/0/response/1|제 사정은 그 뒤에 들어 주시겠습니까?|해설
marceline|inn/24/choices/2/response/0|그럼 빈손으로도 찾아오겠습니다.|해설
marceline|inn/25/choices/0/response/1|다시 읽으면 전과 다른 곳에서 멈출 것 같습니다.|부정
marceline|inn/25/choices/0/text|다 읽으셨으면 제가 책을 치워 둘게요.|선택
marceline|inn/25/choices/0/response/0|아직 읽던 중입니다. 제가 가지고 있겠습니다.|선택
marceline|inn/25/choices/0/reason|독서를 마쳤다고 여기고 책을 치우려 해, 함께 다시 읽고 싶은 마음과 어긋난다.|선택
marceline|inn/26/choices/0/response/0|예, 같이 마시겠습니다.|원칙
marceline|inn/26/choices/0/response/1|좋으시다면 내일도 두 잔을 놓겠습니다.|해설
marceline|inn/27/lines/2|그냥 안부를 묻고 싶었습니다.|부정
marceline|dungeon/31/variants/0|여길 비워 주셨군요. 잠깐 앉겠습니다.|비유
marceline|transitions/3/lines/0|그날 제가 무엇을 했는지 말씀드리고 싶습니다.|비유
teiris|inn/1/choices/2/response/1|다만 저는 다른 걸 봤어요. 제가 본 것도 적고 싶어요.|비유
teiris|inn/2/choices/2/response/1|펜은 나중에 들게요. 지금은 그 소리를 듣고 싶어요.|먼저
teiris|inn/3/choices/1/response/1|지금 말씀하기 어려운 건 나중에 여쭤볼게요.|비유
teiris|inn/3/seen|노트 끈을 묶기 전에 여쭤볼 게 있어요.|먼저
teiris|inn/6/choices/1/response/0|아무 일 없이 보내는 시간도 있군요.|비유
teiris|inn/6/choices/2/response/0|배가 고파서야 시간이 지난 걸 알 때도 있네요.|비유
teiris|inn/7/choices/0/response/1|책을 내밀기 전에 어떤 부분이 좋았는지 여쭤볼게요.|먼저
teiris|inn/8/choices/1/response/1|그냥 궁금해서 적은 것도 읽어 주시면 좋겠어요.|문서
teiris|inn/9/choices/0/response/0|제가 좋아해도 그분은 지금 얘기하기 싫을 수 있겠어요.|원칙
teiris|inn/9/choices/2/response/1|괜찮다고 하시면 의자를 하나 더 가져올게요.|먼저
teiris|inn/11/choices/1/response/0|아직 모르는 말도 써 보고 싶어요.|비유
teiris|inn/12/lines/0|첫 장을 펴면 그날 일이 떠오를 것 같아요.|비유
teiris|inn/12/choices/0/response/1|노트를 여는 것도 자꾸 망설이게 돼요.|부정
teiris|inn/12/choices/1/response/0|보여 드리겠다고 한 건 기억해요.|부정
teiris|inn/14/choices/0/response/1|떠오르는 모습부터 차근차근 말씀드릴게요.|먼저
teiris|inn/15/choices/1/response/1|얘기까지 그만할 뻔했어요. 아직 듣고 계시다면 다시 말할게요.|비유
teiris|inn/16/lines/0|맨 끝 칸은 제 얘기를 적으려고 남겼어요.|부정
teiris|inn/17/choices/1/response/0|보고서에 안 넣어도 제 노트에는 적어 둘래요.|원칙
teiris|inn/19/choices/0/response/1|대답은 들으면서 생각할게요. 지금 궁금한 걸 물어봐 주세요.|먼저
teiris|inn/20/choices/1/response/1|가볍게 하신 말도 저는 기억해요. 적게 약속해도 지키고 싶어요.|연어
teiris|inn/20/choices/2/response/1|못 갔으면 왜 못 갔는지 같이 얘기하면 좋겠어요.|비유
teiris|inn/20/seen|노트를 채우려고 약속을 늘리지는 않을래요.|비유
teiris|inn/23/choices/0/response/1|보고서는 짧게 쓰고 돌아와서 더 말씀드릴게요.|비유
teiris|inn/24/choices/0/response/1|여기서 함께 앉아 있고 싶어서 왔어요.|해설
teiris|inn/24/choices/1/response/0|그럼 무슨 말을 할지 미리 고르지 않고 올게요.|비유
teiris|inn/25/choices/2/response/0|다시 오니 전에 못 본 게 눈에 들어와요.|부정
teiris|transitions/2/lines/1|여기 적힌 음식 중에 궁금한 게 있나요?|문서
teiris|dungeon/21/variants/0|조금 멈춰요. 얼굴이 아까와 달라 보여요.|연어
naran|inn/1/lines/2|들은 얘기를 어디까지 전할지 아직 못 맞췄잖아요.|문서
naran|inn/2/choices/0/response/0|어머, 제 얘기를 더 듣고 고르셔도 되는데요.|비유
naran|inn/2/seen|빈 잔을 만지작거리며 대답을 골랐어요.|부정
naran|inn/7/choices/2/response/0|그럼 저도 읽고 정할게요.|비유
naran|inn/7/seen|웃었어도 서명하기 전에는 읽어 볼게요.|원칙
naran|inn/8/choices/1/response/1|그러면 들려주세요.|먼저
naran|inn/9/seen|틀리게 짐작하느니 물어보고 싶었어요.|비유
naran|inn/10/choices/1/response/0|이 시간에는 의뢰를 안 받을래요.|부정
naran|inn/10/seen|할 일을 안 잡아 두니 이렇게 앉아 있을 수 있네요.|비유
naran|inn/11/choices/0/response/0|제가 전할지 말지 정하고 싶은 얘기도 있어요.|비유
naran|inn/11/choices/1/response/1|저도 팔기 전에 여쭤볼게요.|비유
naran|inn/11/seen|이 얘기는 같이 들었다고 적어 뒀어요.|비유
naran|inn/13/choices/2/response/1|제가 왜 두 계약을 택했는지부터 말해 볼게요.|비유
naran|inn/15/choices/2/response/0|받을 돈을 정하자는 얘기만 하러 온 게 아닌데요.|비유
naran|inn/15/seen|종이를 가져왔으니 같이 읽고 정해요.|비유
naran|inn/16/choices/2/text|나가고 싶어지는 날에는 얘기해 줘요.|비유
naran|inn/16/choices/2/response/0|그런 말까지 들어 주시는군요.|비유
naran|inn/17/seen|빈 종이는 치우고 차나 마실래요.|부정
naran|inn/19/seen|이번 얘기는 값이 올라도 안 팔 거예요.|원칙
naran|inn/20/lines/1|많으면 못 지킨 것도 슬쩍 넘기기 쉽고요.|비유
naran|inn/20/lines/2|저는 하나만 약속할래요.|비유
naran|inn/20/choices/2/text|어떤 약속인지 들어 볼게요.|비유
naran|inn/20/seen|서로 묻겠다는 약속 하나는 지키고 싶어요.|비유
naran|inn/21/choices/0/response/1|저는 일 끝나고도 밥을 같이 먹고 싶었어요.|원칙
naran|inn/21/seen|의뢰가 끝나도 저녁은 같이 먹어요.|비유
naran|inn/22/choices/2/text|재미있는 얘기가 없어도 듣고 싶어요.|선택
naran|inn/22/seen|안 웃고 와도 괜찮은지 물어보길 잘했네요.|비유
naran|inn/23/choices/0/response/0|지난 일도 제가 한 일이에요.|비유
naran|inn/23/choices/1/response/1|제가 한 일부터 짚어 드릴게요.|비유
naran|inn/23/seen|앞으로 어떻게 할지 정하려고 예전 일을 보고 있어요.|비유
naran|inn/24/choices/2/response/1|할 일을 찾아주실 필요는 없어요. 좀 더 앉아 있어요.|부정
naran|inn/25/choices/2/text|자주 옮겨 다니셔도 돌아오면 같이 앉아요.|비유
naran|inn/25/choices/2/response/0|그럼 떠나기 전에도 말씀드릴게요.|비유
naran|inn/25/choices/2/response/1|이번에도 돌아오면 여기로 올래요.|비유
naran|inn/26/choices/1/response/0|기다려 주셔서 고마워요.|비유
naran|inn/26/choices/1/response/1|이번엔 농담보다 그 말을 하고 싶네요.|해설
naran|dungeon/18/variants/0|수고한 분들 모두 확인해요.|비유
naran|dungeon/39/variants/0|웃고 넘기기는 어렵겠네요.|비유
naran|dungeon/41/variants/1|졌어도 함께 돌아가요.|비유
haldric|inn/1/seen|앉아서 듣겠소. 동의할지는 듣고 정하겠소.|부정
haldric|inn/3/choices/2/response/1|그대로 앉아 계시오.|부정
haldric|inn/6/seen|조금 물러나서 무슨 소리인지 들어 보겠소.|문서
haldric|inn/7/seen|손해를 보더라도 서명한 대로 지키겠소.|비유
haldric|inn/9/choices/1/response/0|옆에서 함께 앉고 싶었소.|부정
haldric|inn/10/choices/1/response/0|조항을 지키면서 도울 방법을 보자는 말이구려.|부정
haldric|inn/11/choices/2/response/1|잔을 마저 마실 때까지 같이 앉아 있고 싶소.|비유
haldric|inn/13/choices/2/response/0|그럼 부탁하겠소.|먼저
haldric|inn/14/choices/0/response/0|예, 떠들면서도 곁에 있어 주니 좋소.|비유
haldric|inn/15/lines/1|글자는 읽히는데 뜻이 들어오지 않았소.|부정
haldric|inn/15/seen|문서는 내려놓고 옆을 좀 보겠소.|비유
haldric|inn/17/choices/0/response/1|겁이 나면 그 소리를 듣고 싶소.|먼저
haldric|inn/17/seen|격식 차리지 않고 불러 주니 좀 낫소.|문서
haldric|inn/19/seen|내가 돌아올 때도 기다려 준다는 말이 고맙소.|비유
haldric|inn/20/choices/2/response/1|생각이 바뀌면 말을 꺼내겠소.|먼저
haldric|inn/21/choices/1/response/1|함께 가려고 기다렸으니 내게는 아깝지 않소.|부정
haldric|inn/22/seen|문서는 덮었소. 잠깐 들어 주시겠소?|문서
haldric|inn/23/seen|계곡 이야기도 지금 하고 싶은 말도 함께 하겠소.|비유
haldric|inn/24/choices/1/response/1|문서는 일부러 두고 왔소.|부정
haldric|inn/25/choices/0/response/0|오래 봐도 여전히 무섭소.|부정
haldric|inn/27/choices/1/response/0|지금 이름으로 불러 주면 좋겠소.|부정
haldric|dungeon/9/variants/0|맡은 곳은 내가 지키겠소.|비유
haldric|dungeon/11/variants/1|내가 조항만 읊으면 좀 불러 주시오.|연어
haldric|dungeon/14/variants/1|함께 버텨 줘서 고맙소.|비유
haldric|dungeon/23/variants/0|다친 사람을 불러 보겠소.|비유
haldric|dungeon/28/variants/0|맡은 곳을 잠시 바꾸겠소.|비유
haldric|dungeon/32/variants/1|같이 조금 쉬다 가겠소.|문서
haldric|dungeon/38/variants/0|계약서는 두고 와도 같이 앉겠소?|비유
haldric|transitions/3/lines/1|내가 읽을 시간도 주시오.|비유
haldric|transitions/11/lines/1|내게도 다시 물어 주시오.|비유
erdene|inn/2/choices/1/response/1|끝에서 걷는 사람도 확인해 줘.|비유
erdene|inn/2/seen|끝에 걷는 사람 이름도 잘 보이게 적어.|연어
erdene|inn/5/seen|그 접시는 늦게 올 사람한테 줘.|비유
erdene|inn/6/seen|앞에서 길을 보면 신호할게.|원칙
erdene|inn/8/choices/1/response/0|앞을 보느라 대답이 늦을 수도 있어.|부정
erdene|inn/8/choices/1/response/1|그래도 부르면 들을게.|해설
erdene|inn/8/seen|뒤에서 누가 오는지 아니까 앞을 맡을 수 있어.|비유
erdene|inn/9/choices/0/response/0|나도 걱정이 되니 물어는 볼게.|비유
erdene|inn/9/choices/0/response/1|다 알아서 해 주려고 하지는 마.|비유
erdene|inn/11/seen|부탁하려니 말이 천천히 나왔어.|비유
erdene|inn/12/choices/0/response/0|지금 이름도 좋아. 그래도 잃은 게 있어.|부정
erdene|inn/12/choices/0/response/1|그 얘기도 좀 들어 줘.|해설
erdene|inn/12/seen|지금 이름을 아껴도 잃어버린 얘기는 하고 싶어.|부정
erdene|inn/13/choices/1/response/0|그럼 좀 쉬었다 가도 되겠어?|부정
erdene|inn/14/seen|지난 일은 남아도 오늘은 같이 서 볼게.|원칙
erdene|inn/15/seen|몸부터 나가다가도 부르면 들을게.|비유
erdene|inn/16/choices/0/response/0|느리게 걸어도 내가 앞에서 볼 수 있어.|부정
erdene|inn/19/seen|여기서 내 이름을 불러 주던 것도 기억할게.|비유
erdene|inn/19/choices/2/response/1|뭘 되찾아야만 축하받으면 좀 서운하잖아.|해설
erdene|inn/21/choices/1/response/1|그럼 앉아서 기다려 볼게.|먼저
erdene|inn/21/seen|앞장서던 날처럼 오늘은 늦게 온 사람을 기다릴게.|비유
erdene|inn/24/choices/0/response/1|할 일이 없어도 같이 앉고 싶어.|비유
erdene|inn/26/seen|종이에 쓰지 않고 바로 불러 주니까 좋네.|비유
erdene|inn/27/seen|앞서가더라도 돌아와서는 같이 앉을게.|비유
erdene|dungeon/7/variants/0|찾은 사람만 적지 말고 같이 본 것도 남겨.|비유
erdene|dungeon/13/variants/1|다들 버티느라 애썼어.|비유
erdene|dungeon/29/variants/1|지쳤어. 잠깐 쉬어도 되겠지?|비유
erdene|dungeon/36/variants/0|안 돌아온 사람 없어?|비유
erdene|dungeon/41/variants/1|오늘 돌아온 사람들도 빠짐없이 적어.|비유
erdene|transitions/10/lines/1|나도 다 돌아왔는지 봐 줘.|비유
erdene|transitions/12/lines/0|앞을 안 맡아도 같이 있을 수 있네.|비유
bianca|inn/0/choices/2/text|앉으시라니 편하게 다 물어봐도 되겠죠?|선택
bianca|inn/0/choices/2/response/0|오늘은 필요한 말씀만 듣고 싶어요.|원칙
bianca|inn/0/choices/2/response/1|얼마나 말할지는 제가 고를게요.|해설
bianca|inn/0/choices/2/reason|자리를 권한 것을 사적인 질문까지 허락한 것으로 받아들여 경계를 넘는다.|선택
bianca|inn/1/seen|계산은 맞아요. 받으실지는 여쭤봐야겠어요.|원칙
bianca|inn/2/choices/0/response/0|아는 척은 해도 모르는 얘기가 많아요.|부정
bianca|inn/4/choices/1/response/0|그렇게 서두르시면 저는 좀 불편해요.|선택
bianca|inn/5/choices/0/response/1|적은 돈이라도 누가 받는지는 봐야 해요.|비유
bianca|inn/6/choices/2/response/1|질문을 안 할 때도 편하게 앉아 있고 싶어요.|비유
bianca|inn/8/seen|질문 대신 제 얘기를 하니 좀 낯서네요.|비유
bianca|inn/9/choices/2/response/0|많이 안다고 들어갈 수 있는 곳은 아니거든요.|비유
bianca|inn/9/seen|가문 이름을 대도 들여보내 주지는 않아요.|비유
bianca|inn/11/choices/0/response/1|믿으셔도 지금 같이 확인해 주세요.|비유
bianca|inn/12/seen|기각됐을 때 이야기를 좀 더 해도 될까요?|문서
bianca|inn/13/choices/1/response/0|시킨 사람이 있어도 제가 보고한 건 맞아요.|비유
bianca|inn/14/choices/1/response/0|제가 세 인장을 드릴 수는 없어요.|비유
bianca|inn/14/choices/0/text|그럼 위원회 답이 올 때까지 다른 준비는 미룰까요?|선택
bianca|inn/14/choices/0/response/0|기다리기만 해서는 어려울 것 같아요.|부정
bianca|inn/14/choices/0/response/1|제가 해야 할 일도 남아 있어요.|해설
bianca|inn/14/seen|아는 만큼 말씀드리고 나니 좀 후련하네요.|비유
bianca|inn/16/choices/1/response/1|이번에 안 쓰기로 한 말은 끝까지 안 쓰겠어요.|비유
bianca|inn/16/choices/2/response/0|그 얘기는 안 물으시는군요.|비유
bianca|inn/16/seen|무엇을 쓰지 않을지도 제가 정했어요.|비유
bianca|inn/17/seen|억지로 미소 짓지 않고 앉아 있어도 편하네요.|비유
bianca|inn/18/choices/0/text|보수는 받으세요. 그 뒤에도 같이 있고 싶어요.|선택
bianca|inn/18/choices/2/response/1|같이 있고 싶어도 보수를 포기하긴 어려워요.|비유
bianca|inn/18/seen|보수를 받고 나서도 여기 앉아 있고 싶어요.|비유
bianca|inn/20/choices/1/response/0|그럼 저도 바꾸기 전에 여쭤볼게요.|비유
bianca|inn/20/seen|가까운 사이에도 돈 얘기는 정확히 하고 싶어요.|비유
bianca|inn/21/seen|보고서는 치워 두고 안부를 물었어요.|문서
bianca|inn/21/choices/2/response/0|어떻게 지내셨는지 궁금해서 물었어요.|부정
bianca|inn/22/lines/0|제가 정해 놓고도 마음이 무거워요.|비유
bianca|inn/22/lines/2|조금 쉬었다 얘기해도 될까요?|해설
bianca|inn/22/choices/0/response/0|다음 얘기는 내일 할게요.|비유
bianca|inn/22/choices/1/response/1|후회해도 제가 정한 일은 마저 해 볼게요.|비유
bianca|inn/22/seen|고르기 힘들었다는 말도 숨기지 않고 해 볼래요.|비유
bianca|inn/23/choices/1/response/0|떠나고 싶어지면 여기서 말씀드릴게요.|비유
bianca|inn/25/choices/2/response/0|제 말을 그대로 들어 주시네요.|비유
bianca|inn/24/choices/2/text|차 마시면서 다음에 알아볼 소식도 정해 볼까요?|선택
bianca|inn/24/choices/2/response/0|오늘은 소식 얘기를 쉬고 싶어요.|문서
bianca|inn/24/choices/2/response/1|빈손으로 와도 차는 같이 마실 수 있겠죠?|해설
bianca|inn/24/choices/2/reason|평범하게 안부를 나누러 온 사람에게 다음 정보 수집 일을 제안한다.|선택
bianca|dungeon/5/variants/0|같이 보니 더 궁금한 게 많아지네요.|비유
bianca|dungeon/8/variants/0|보고서에 적기엔 좀 아까운 얘기네요.|문서
bianca|dungeon/17/variants/1|겁난다고 말해도 곁에 계셔 줄래요?|비유
bianca|dungeon/22/variants/1|쉴 수 있도록 주위를 봐 줘요.|비유
bianca|dungeon/26/variants/0|아직 여기 있어요. 상태부터 봐요.|비유
bianca|dungeon/29/variants/1|이번에는 저도 좀 도와주세요.|비유
bianca|dungeon/35/variants/0|못 열었다고 솔직하게 적어 두죠.|비유
bianca|dungeon/41/variants/1|졌던 얘기도 돌아가서 같이 해요.|비유
bianca|transitions/6/lines/0|가문 이름을 대도 들어갈 수 없는 곳이 있어요.|비유
bianca|transitions/8/lines/0|이번 얘기는 안 쓰기로 했어요.|비유
bianca|transitions/11/lines/1|가까운 사이에도 금액은 같이 확인해요.|비유
saya|inn/3/lines/0|이 부분은 이렇게 뜨는 거예요.|부정
saya|inn/4/choices/1/response/0|이번 일은 갚지 않아도 돼요.|부정
saya|inn/5/choices/2/response/0|뜨는 동안이 좋아요.|부정
saya|inn/6/choices/1/response/0|억지로 데려오진 말아요.|원칙
saya|inn/8/lines/0|일부러 놓고 간 거예요.|부정
saya|inn/9/choices/1/response/0|저도 다음에 길을 보고 싶어요.|비유
saya|inn/10/choices/0/response/0|이번 건 쓸 분이 정해져 있어요.|부정
saya|inn/10/choices/0/response/1|그래서 치수도 물었어요.|해설
saya|inn/11/choices/2/response/1|다 갚고 나서도 같이 앉으면 좋겠어요.|비유
saya|inn/12/seen|실을 처음 쥐던 때가 아직 생각나요.|비유
saya|inn/13/seen|풀기 전에 쓸 수 있는 부분을 볼게요.|비유
saya|inn/14/seen|닮게 뜨려고 애썼어요. 놀리지는 말아요.|부정
saya|inn/16/choices/0/response/1|쓰셨으면 해서 드리는 거예요.|부정
saya|inn/17/lines/1|그대로 내놓을게요.|부정
saya|inn/18/choices/1/response/0|그분 얘기는 직접 들어 봐요.|원칙
saya|inn/18/seen|잔은 여기 둘게요. 천천히 대답해요.|부정
saya|inn/19/lines/0|갚을 일 없이도 오고 싶었어요.|부정
saya|inn/19/choices/0/response/0|그냥 같이 앉고 싶었어요.|부정
saya|inn/21/lines/0|이건 그냥 드릴래요.|부정
saya|inn/22/seen|필요하면 소리 내서 부를게요.|비유
saya|inn/23/choices/2/response/0|여기 있고 싶어서 왔어요.|부정
saya|inn/24/choices/1/response/0|다음에 뜰 얘기는 조금 뒤에 할래요.|부정
saya|inn/24/seen|아무것도 안 떴어도 인사하러 올게요.|먼저
saya|inn/26/seen|고친 부분도 오래 쓰면 좋겠어요.|비유
saya|inn/27/choices/1/response/0|제가 있고 싶어서 있는 거예요.|부정
saya|dungeon/1/variants/0|돌아올 길도 봐 뒀어요.|연어
saya|dungeon/30/variants/1|여기선 손을 좀 쉬겠네요.|비유
saya|dungeon/32/variants/1|느리게 움직여도 기다려 주시네요.|비유
gerda|inn/0/seen|옷 속에 넣어 둘게요. 지금은 안 보여 줄래요.|부정
gerda|inn/3/choices/0/response/1|어느 길로 갈지는 같이 봐요.|부정
gerda|inn/5/seen|아직 기도 중이니 출발은 잠깐 기다려요.|원칙
gerda|inn/8/seen|여기로 와 줘요. 같이 앉아 있고 싶어요.|부정
gerda|inn/9/choices/0/response/1|징조를 봐도 모르는 건 여전히 많아요.|부정
gerda|inn/10/seen|말도 하기 전에 부적부터 쥐었네요.|먼저
gerda|inn/12/choices/0/response/1|기억하는 사람까지 잊으라고 하진 말아요.|비유
gerda|inn/13/choices/0/text|그때 뭘 할 수 있었는지 기억나는 것만 말해 주세요.|선택
gerda|inn/13/choices/0/response/0|그때 할 수 있었던 게 뭔지 잘 모르겠어요.|원칙
gerda|inn/13/choices/2/text|그 부적은 잠깐 치워 두고 다른 얘기 해요.|선택
gerda|inn/13/choices/2/response/0|그날 얘기를 조금 더 하고 싶어요.|부정
gerda|inn/13/choices/2/reason|위로하려고 부적과 화제를 치우지만 게르다는 그날의 책임감부터 말하고 싶다.|선택
gerda|inn/15/seen|같이 밥 먹으면서 다른 생각도 말할 수 있죠.|원칙
gerda|inn/16/seen|부적을 벗어도 여전히 믿어요.|부정
gerda|inn/17/seen|피하지 않고 얘기할 테니 옆에 좀 있어 줘요.|비유
gerda|inn/19/choices/0/text|저는 왼쪽에 앉을게요. 오른쪽은 게르다 씨가 써요.|선택
gerda|inn/19/choices/0/response/0|그럼 옆에 좀 있어 줘요.|원칙
gerda|inn/20/choices/2/text|싫으면 거절해 주세요. 다시 얘기하면 되죠.|비유
gerda|inn/20/seen|싫다고 말해도 된다면 무슨 약속인지 들어 볼래요.|비유
gerda|inn/21/choices/0/response/0|여전히 믿으니까 맡긴 거예요.|부정
gerda|inn/21/choices/0/response/1|부적은 잘 가지고 있어 줘요.|해설
gerda|inn/23/seen|아무 말 없이 잔을 두 개 놓을게요.|비유
gerda|inn/25/seen|옆에 앉아요. 같이 있으려고 골라 뒀어요.|부정
gerda|inn/26/choices/1/response/0|그냥 보고 싶어서 왔어요.|먼저
gerda|inn/26/seen|왜 왔는지 길게 말하지 않아도 되네요.|먼저
gerda|inn/27/choices/0/response/1|옛날 얘기는 조금씩 해도 될까요?|해설
gerda|dungeon/7/variants/0|본 건 적고 모르는 건 남겨 둬요.|비유
gerda|dungeon/24/variants/1|대답이 없어도 좀 더 살펴봐요.|부정
gerda|dungeon/34/variants/0|믿는다고 다 아는 건 아니니 더 봐요.|원칙
gerda|dungeon/35/variants/0|안 열리면 돌아가서 더 알아봐요.|원칙
gerda|dungeon/38/variants/1|정말로 같이 돌아왔네요.|부정
gerda|transitions/8/lines/0|저는 여전히 믿고 있어요.|부정
gerda|transitions/10/lines/1|따르기 전에 물어볼 시간도 줘요.|비유
gerda|transitions/13/lines/0|편해졌는데도 여전히 겁이 나네요.|부정
judith|inn/6/lines/2|아직 못 푼 건 다음에 봐요.|문서
judith|inn/6/seen|아직 못 푼 곳도 보여 드릴게요.|문서
judith|inn/7/choices/1/response/1|스승 얘기를 빼고 제 답을 좀 봐 주세요.|원칙
judith|inn/7/seen|제 책을 읽고 나서 어떻게 생각하는지 들려줘요.|부정
judith|inn/10/seen|등잔을 옮겨도 글씨는 잘 보이네요.|비유
judith|inn/11/choices/1/response/0|이 사람들까지 생각하면 간단히 정할 순 없겠네요.|비유
judith|inn/12/choices/2/response/1|잊고 나면 그때 제가 한 일까지 모른 척하게 돼요.|비유
judith|inn/13/choices/0/response/0|고맙네요. 조금만 들어 줘요.|해설
judith|inn/13/seen|제적된 뒤에도 이 이름으로 살고 싶었어요.|비유
judith|inn/15/choices/2/response/0|저는 제가 배운 대로 생각해 볼래요.|부정
judith|inn/15/seen|같은 스승에게 배웠어도 저는 이렇게 답할래요.|비유
judith|inn/16/choices/2/response/1|우선 다들 돌아왔는지 볼게요.|비유
judith|inn/18/choices/2/response/0|어떻게 풀었는지도 같이 봐 줘요.|부정
judith|inn/19/lines/1|계산은 제가 하고요.|부정
judith|inn/19/lines/2|그냥 일찍 와 주면 좋겠어서요.|먼저
judith|inn/19/choices/1/response/0|할 일 없어도 앉아 있어 줘요.|부정
judith|inn/19/choices/1/response/1|혼자 계산하는 것보다 좋아요.|해설
judith|inn/19/seen|옆 의자는 비었어요. 계산은 안 도와줘도 돼요.|비유
judith|inn/20/lines/1|고칠 데가 있으면 말해 줘요.|부정
judith|inn/20/seen|계획은 읽어 보고 반대해도 돼요.|비유
judith|inn/21/choices/2/response/0|나중에 다시 볼 때 도움이 돼요.|원칙
judith|inn/21/seen|틀린 데를 누가 고쳤는지도 적어 둘게요.|비유
judith|inn/23/lines/1|제가 지쳐서 멈췄어요.|부정
judith|inn/23/lines/2|쉬고 나서 다시 봐야겠네요.|문서
judith|inn/23/choices/0/response/1|이번엔 제가 쉬겠다고 했으니 좀 기다려 줘요.|비유
judith|inn/23/seen|쉬고 싶을 때는 제가 펜을 놓을게요.|비유
judith|inn/24/choices/2/response/0|답 얘기는 나중에 하고요.|부정
judith|inn/24/choices/2/response/1|못 푼 채로도 같이 앉아 있고 싶었어요.|비유
judith|inn/25/choices/2/response/1|그때 제가 한 말은 고칠래요.|비유
judith|inn/25/choices/1/response/1|기다려 주신 게 고맙다는 얘기예요.|해설
judith|inn/25/choices/2/text|그날 기다린 걸 기억하셨네요.|선택
judith|inn/25/seen|늦게 알았어도 이제는 제대로 말할래요.|비유
judith|inn/27/choices/0/text|제 얘기를 물으시니 좀 놀랐어요.|선택
judith|inn/27/choices/0/response/0|걱정됐어요.|부정
judith|inn/27/choices/0/response/1|발견 얘기는 그 뒤에 들어도 되니까요.|해설
judith|inn/27/seen|발견한 건 나중에 말할게요. 오늘은 어땠어요?|문서
judith|dungeon/2/variants/0|모두 돌아올 수 있는지도 생각했어요.|비유
judith|dungeon/14/variants/1|다들 돌아갈 수 있겠네요. 다행이에요.|비유
judith|dungeon/27/variants/1|다쳤네요. 계획을 좀 바꿀게요.|비유
judith|dungeon/31/variants/0|못 푼 건 두고 잠깐 쉴게요.|문서
judith|dungeon/32/variants/0|아직 답은 못 찾았어요. 앉아도 돼요?|비유
judith|dungeon/35/variants/1|아직 몰라도 같이 기다려 주시네요.|비유
judith|dungeon/38/variants/1|계산은 그만하고 함께 앉아 있을래요.|비유
levia|inn/2/choices/2/response/1|싫을 때 안 한다고 말씀드리고 싶어요.|먼저
levia|inn/4/seen|구석에 앉아도 듣고 있어요.|부정
levia|inn/8/choices/2/response/0|아직 어려운 것도 있어요.|부정
levia|inn/9/lines/2|말 안 하려다 지금 말씀드렸네요.|먼저
levia|inn/9/choices/1/response/1|참다가 너무 늦게 말씀드릴까 봐 걱정됐어요.|먼저
levia|inn/9/seen|말할 수 있을 때 아프다고 해 봤어요.|먼저
levia|inn/10/choices/0/response/1|말이 없어도 곁에 있고 싶어요.|비유
levia|inn/10/choices/1/response/0|잠깐 생각하다 대답해도 되겠네요.|부정
levia|inn/11/seen|할 수 없는 것도 말씀드려 볼게요.|비유
levia|inn/13/seen|어떻게 적혔는지보다 그때 얘기를 하고 싶었어요.|비유
levia|inn/15/choices/2/response/0|성을 새로 붙이지 않아도 되는군요.|비유
levia|inn/16/choices/0/response/1|내일도 할지는 내일 물어봐 주세요.|부정
levia|inn/17/choices/0/response/0|죄송하다는 말 없이도 물을 부탁할 수 있네요.|먼저
levia|inn/18/choices/2/response/0|그러면 싫을 때 싫다고 해 볼게요.|먼저
levia|inn/19/choices/1/response/0|대답을 못 골라도 찾아와 볼게요.|부정
levia|inn/19/seen|무섭다고 말했어도 좀 더 앉아 있을래요.|비유
levia|inn/20/seen|천천히 생각하고 대답할게요.|비유
levia|inn/21/lines/0|제 것도 꺼내 놓았어요.|먼저
levia|inn/23/lines/0|얘기를 듣자마자 제 탓이라고 했네요.|먼저
levia|inn/26/lines/2|아직 어려운 일도 있지만요.|부정
levia|inn/27/seen|돌아온 뒤에도 차 마시고 싶어서 여쭤봤어요.|비유
levia|dungeon/16/variants/1|할 수 있는 일과 싫은 일은 말할게요.|비유
levia|dungeon/17/variants/1|그렇게 말해도 같이 가 주실래요?|비유
levia|dungeon/40/variants/1|다음에 무서울 때는 바로 말씀드릴게요.|비유
levia|transitions/4/lines/1|제가 오고 싶었어요.|부정
urda|inn/2/seen|농담은 그만하겠소. 하던 얘기를 들어 봅시다.|먼저
urda|inn/3/choices/0/response/0|그분이 하려던 일까지 다 맡으면 답답하겠소.|비유
urda|inn/3/choices/0/response/1|도와줘도 좋은지 물어보겠소.|비유
urda|inn/3/choices/1/response/0|그릇을 채우기 전에 물었어야 했군요.|비유
urda|inn/5/choices/1/response/0|많이 배고픈 사람이 있으면 좀 기다립시다.|원칙
urda|inn/6/choices/0/response/0|지금은 웃어도 그때 들은 말은 아팠소.|부정
urda|inn/7/choices/0/text|기도하고 싶으신가요? 허락된 곳부터 볼까요?|선택
urda|inn/8/seen|다르게 믿어도 같이 밥은 먹읍시다.|원칙
urda|inn/13/choices/0/text|계곡에선 어땠고 산 밖에선 어땠는지 들려주세요.|선택
urda|inn/13/choices/2/response/0|산 밖에서 잘 지내도 고향은 그립소.|부정
urda|inn/13/choices/2/response/1|계곡 얘기도 조금 더 들어 주겠소?|해설
urda|inn/13/seen|산 밖을 떠돌다가도 계곡 생각은 나지요.|원칙
urda|inn/14/choices/0/response/0|그럼 말없이 기도하겠소.|비유
urda|inn/14/choices/1/response/1|이름을 몰라도 오늘 그분들을 위해 기도하겠소.|비유
urda|inn/14/choices/2/response/0|예, 그분들이 있었다는 건 알지요.|비유
urda|inn/14/seen|이름은 모르지만 그분들께도 기도하겠소.|비유
urda|inn/19/choices/1/response/0|그 사람 얘기도 같이 하겠소.|비유
urda|inn/19/seen|곁에서 도와준 사람 얘기도 하고 싶소.|비유
urda|inn/20/choices/1/response/0|누구든 돕겠소만, 믿음 얘기도 하고 싶소.|원칙
urda|inn/20/choices/1/response/1|다르게 믿어도 그 사람 말은 들어 봅시다.|비유
urda|inn/21/choices/0/response/0|예, 하던 일부터 마치겠소.|비유
urda|inn/21/choices/1/response/0|그럼 어려울 때는 어렵다고 하겠소.|비유
urda|inn/23/choices/2/text|성표가 달라도 같이 앉을 수 있죠.|비유
urda|inn/23/seen|서로 밀어내지 말고 내 성표도 꺼내겠소.|비유
urda|inn/24/choices/0/response/1|밥을 안 떠 주는 날도 같이 앉고 싶소.|비유
urda|inn/24/seen|빈손으로 왔으니 같이 앉아 볼게요.|먼저
urda|inn/27/choices/1/response/1|그럼 밥 얘기 전에 반갑다고 하겠소.|먼저
urda|inn/26/choices/1/text|그럼 답을 들으실 때까지 기도를 더 해 보세요.|선택
urda|inn/26/choices/1/response/0|기도는 이쯤에서 마치고 싶소.|부정
urda|dungeon/11/variants/0|오늘은 나도 함께 도울게요.|비유
urda|dungeon/15/variants/1|서 있는 사람부터 함께 봅시다.|비유
urda|dungeon/20/variants/0|무사히 돌아갈 수 있으니 다행이오.|비유
urda|dungeon/29/variants/0|나도 조금 도와주오.|비유
urda|dungeon/32/variants/1|답을 못 찾아도 좀 쉬었다 갑시다.|비유
urda|transitions/9/lines/0|답을 못 드리는 날도 찾아왔으면 하오.|비유
urda|inn/20/choices/0/response/0|이번엔 개수만 세어 봅시다.|연어
'''

def main():
 corpus={cid:json.loads((OUT/f'draft5/{cid}.json').read_text(encoding='utf8')) for cid in IDS}
 edits=[];decisions=[]
 def apply(cid,path,after,reason,pattern):
  node=corpus[cid]
  for key in path.split('/'):node=node[int(key)] if isinstance(node,list) else node[key]
  if node==after:return
  assert isinstance(node,str),(cid,path)
  edits.append(dict(character_id=cid,path=path,before=node,after=after,reason=reason,pattern=pattern))
  replace_at(corpus[cid],path,after)
 custom={
 'KR-004':'괜찮은 척도 못 하겠네요. 조금 무서워요.',
 'KR-011':'옆에서 걸음을 맞추겠소.',
 'KR-012':'그럼 제 의견부터 말씀드리겠습니다.',
 'KR-016':'잔을 건넨 뒤 안부를 물으라고 읽었습니다. 아, 교리서에서요.',
 'KR-025':'어떻게 지내셨는지 길게 들어도 괜찮아요.',
 'KR-026':'그날 오기 전에도 내 이름을 불러 줬으면 해.'}
 for r in json.loads((OUT/'kreview-2.json').read_text(encoding='utf8')):
  found=[(cid,p) for cid,d in corpus.items() for p,t,_ in display_fields(d) if t==r['before']]
  assert len(found)==1,(r['id'],found)
  cid,path=found[0];after=custom.get(r['id'],r['suggestion'])
  apply(cid,path,after,r['problem']+' 독립 검수 취지를 반영하되 인물 화계·장면을 유지했다.','독립검수')
  decisions.append({**r,'character_id':cid,'path':path,'status':'반영','after':after,'reason':r['problem']+(' 제안은 화계·장면 연결에 맞춰 다시 썼다.' if r['id'] in custom else ' 제안을 문맥에 맞게 반영했다.')})
 for row in TEXT.strip().splitlines():
  cid,path,after,pattern=row.split('|')
  apply(cid,path,after,REASONS[pattern],pattern)
 for cid,d in corpus.items():write_json(ROOT/f'project/data/dialogue-r21/{cid}.json',d)
 write_json(OUT/'edits5-first12.json',edits)
 write_json(OUT/'decisions5-first12.json',decisions)
 print('edits',len(edits),'reviews',len(decisions),'per character',dict(Counter(e['character_id'] for e in edits)))

if __name__=='__main__':main()
