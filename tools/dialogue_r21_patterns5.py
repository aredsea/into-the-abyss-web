"""Reproducible lexical screens, not automatic judgments of natural Korean."""
import re
from dialogue_r21_build import ROOT, OUT, IDS, read_json, write_json, display_fields

# These are deliberately broad screens. A literal chair, contract or name can
# match; human evidence is recorded separately instead of calling every hit bad.
PATTERNS = {
    '소재 비유 후보': r'자리|몫|이름|빈칸|문턱|(?<![가-힣])문(?:을|이)|(?<![가-힣])줄(?:을|이)',
    '원칙 요약 후보': r'(?:일|것|건|말|마음).*(?:따로|다르|달라)|(?:와|과).*(?:따로|다르|달라)',
    '뜻·감정 해설 후보': r'뜻(?:은|이|으로)|마음(?:은|이|을)|기분(?:은|이|을)',
    '부정 되받기 후보': r'라고 해서|다고 해서|그 뜻|(?:건|것은|게|말은) 아니|(?:진|지는) 않',
    '먼저': r'먼저',
    '오늘은': r'오늘은',
    '사적 문서어 후보': r'확보|절차|조항|문서|기록|보고|결론|요점|할당량',
    '선택지 성격·감정 진단 후보': r'우울|예민|외로|답(?:죠|네요|군요)|이제.*(?:겠네요|군요)|의외로|온순',
    '시적 결합 후보': r'(?:말|마음|이름|하루|질문|대답).*(?:놓|남|비워|접|세|막|닫)|(?:자리|몫|빈칸).*(?:마음|말|이름)',
    '검수 표기·연어': r'그만 둘|결론내리|이름에 걸고|쉼터에 두 겨울|고친 앞의 값|기억하고 나오|말의 행선지|간격을 확보',
    '같이·함께': r'같이|함께',
}


def eligible(path):
    return not path.endswith('/situation')


def hits(corpus, name):
    regex = re.compile(PATTERNS[name])
    records = []
    for cid, d in corpus.items():
        for p, t, _ in display_fields(d):
            if not eligible(p):
                continue
            if name.startswith('선택지') and not p.endswith('/text'):
                continue
            if name.startswith('사적') and not p.startswith('inn/'):
                continue
            matches = regex.findall(t)
            if matches:
                records.append(dict(character_id=cid, path=p, text=t, occurrences=len(matches)))
    return records


def main():
    before = {c: read_json(OUT/f'draft5/{c}.json') for c in IDS}
    after = {c: read_json(ROOT/f'project/data/dialogue-r21/{c}.json') for c in IDS}
    results = {}
    for name, regex in PATTERNS.items():
        b, a = hits(before, name), hits(after, name)
        results[name] = dict(regex=regex, before_occurrences=sum(x['occurrences'] for x in b),
                             after_occurrences=sum(x['occurrences'] for x in a),
                             before_fields=len(b), after_fields=len(a), before=b, after=a)
    write_json(OUT/'patterns5.json', {'scope': '표시용 발화만 센다. situation/reason 제외. 선택지 진단은 text만, 사적 문서어는 inn만.',
        'limitation': '후보 수이며 오용 수가 아니다. 실물·고유 소재·정당한 거절도 포함한다. 낱말 일괄 삭제에 쓰지 않는다.', 'patterns': results})
    for n, r in results.items():
        print(n, r['before_occurrences'], '->', r['after_occurrences'])


if __name__ == '__main__':
    main()
