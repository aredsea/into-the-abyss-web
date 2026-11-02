"""Exercise new-register false positives and retain wrong-register rejection."""
from copy import deepcopy
from dialogue_r21_build import ROOT, IDS, read_json, write_json, lexicon
from dialogue_r21_check import validate
from dialogue_r21_round4 import NEW_IDS, OUT

def main():
    results=[]
    dictionary=lexicon()
    corpus={cid:read_json(ROOT/f'project/data/dialogue-r21/{cid}.json') for cid in NEW_IDS}
    def probe(cid,line,accept):
        d=deepcopy(corpus[cid]);d['inn'][0]['lines'][0]=line
        errors,metrics=validate(d,cid,dictionary)
        violated=any('speech endings violated' in e['message'] for e in errors)
        ok=(not errors) if accept else violated
        results.append(dict(name=cid+':'+line,expected='accept' if accept else 'reject',passed=ok))
    for cid in NEW_IDS:
        formal=corpus[cid]['speech']['allowed_endings']
        probe(cid,'함께 가겠소.',False)
        probe(cid,'같이 천천히 갈게요.','해요체' in formal)
        probe(cid,'지금 확인하겠습니다.','하십시오체' in formal)
        probe(cid,'나는 여기서 좀 쉴게.','해체' in formal)
    for line in ['잠깐 멈춰.','물이 아직 차.','잔은 내가 씻어 써.','오늘 손바닥이 좀 아파.',
                 '손 놓고 천천히 마셔.','아프면 바로 소리 내.','여긴 무릎이 잘 부딪혀.']:
        probe('zahar',line,True)
    for cid in ['jorund','colette']:
        for line in ['네. 오늘도 확인했습니다.','예, 먼저 말씀하십시오.']:
            probe(cid,line,True)
        for line in ['오늘은 편하군요.','응. 확인하겠습니다.','멈춰.','그것은 내 뜻이 아니다.']:
            probe(cid,line,False)
    for cid in ['ornel','miko']:
        probe(cid,'네. 오늘은 같이 걸을게요.',True)
        probe(cid,'응. 오늘은 같이 걸을게요.',False)
    for cid in ['tove','zahar']:
        probe(cid,'응. 오늘은 같이 걸어가자.',True)
        probe(cid,'네. 오늘은 같이 걸어가자.',False)
    result={'checks':len(results),'failures':sum(not r['passed'] for r in results),'results':results}
    write_json(OUT/'selftest4-registers.json',result)
    print({k:v for k,v in result.items() if k!='results'})
    for r in results:
        if not r['passed']:print('FAIL',r)
    return int(bool(result['failures']))

if __name__=='__main__':raise SystemExit(main())
