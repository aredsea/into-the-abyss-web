import json
import sys
from pathlib import Path
root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(root / 'tools'))
from en_r24 import load, write_en

# Explicit editorial revisions after reading all source lines and the final sample.
edits = {
 'ornel': {
  'If your hand moves, show a little.': 'If you can move your hand, let me see.',
  'Lowering the bow, my arm aches.': "My arm aches now I've lowered my bow.",
  "There's breeze even here.": "There's a breeze even here.",
  'Now, footing before bow.': 'Right now I should watch my footing, rather than my bow.',
  "Lower some of what's on your back.": 'Set down some of the weight on your back.',
  'Then I\'ll call before sleeping.': "Then I'll call you before I go to sleep.",
  'People\'s voices again.': 'I can hear people again.',
  'Bow ready.': 'My bow is ready.',
  'Less echo by the wall.': "There's less echo by the wall.",
  'Poor view?': 'Is the view unclear?',
 },
 'saya': {
  "Instead of leaving, I'll see your face today.": "Today I'll stay to see your face when you receive it.",
  'Then I carry the debt away alone.': "Then I'm left carrying that debt away alone.",
  "Even late, leaving word is enough?": "Even if I'm late, I can still leave word, right?",
  "You heard empty hands as only a need for rest.": "You thought coming empty-handed only meant I needed rest.",
  'Knitted a likeness.': 'I knitted it to look like someone.',
  'Hands warm first.': "I'll warm my hands first.",
  'Need your measurements.': 'I need your measurements.',
  "Won't hide silently.": "I won't hide without a word.",
  'No words of repayment needed.': "I could come without talking about repayment.",
 },
 'selva': {
  'I will see through unpacking on return too.': 'I will see the work through to unpacking when we return.',
  'Stronger wind.': 'The wind has picked up.',
  'Set a formal meeting time?': 'Shall we set a regular time to meet?',
  'Even briefly, sitting helps.': 'Even a short sit helps.',
  'A wash before dinner.': 'I should wash before dinner.',
  'Tomorrow\'s work stays tomorrow.': 'I will do that tomorrow.',
  'No soup ordered yet.': 'I have not ordered soup yet.',
  'Less draft here.': 'There is less draft here.',
  'No more jobs today.': 'I will take no more jobs today.',
  'No overreaching to undertake everything.': 'Do not overburden yourself by taking everything on.',
  'Condition before lifting.': 'Let us check their condition before lifting them.',
 },
 'sorel': {
  "I can't even call it misunderstanding yet.": "I can't even say it was a misunderstanding yet.",
  "I'll tell why I don't erase it too.": "I'll tell you why I haven't erased it too.",
  "You may come without buying.": "You're welcome even if you aren't buying.",
  'Collecting twice is easy.': 'Taking payment twice is easy.',
  "I avoided saying it lest you suggest returning.": "I avoided saying it because you might tell me to go back.",
  'This is the agreed price now.': "This is the price I've set now.",
  'My current name includes that forest.': 'That forest is part of the name I use now.',
  'No conclusions before checking.': "Don't reach a conclusion before checking.",
 },
 'teiris': {
  'How did you see it? I\'d like that after a breath.': "What did you see? I'd like to hear once we've caught our breath.",
  "Strange. Without planning questions, my feet came here.": "Strange. I found myself coming here without even thinking of a question.",
  'Outside must give you much to consider.': 'Being outside must have given you a lot to think about.',
  'No conclusion on the overturned sheet yet.': "I still haven't written a conclusion on that sheet.",
  'No rushing for reported achievements.': "I won't rush just to have an achievement for my report.",
  'Understanding can move at different speeds too.': 'We can take different amounts of time to understand too.',
  'Read them slowly?': 'Would you read them slowly?',
  'Once confirmed, I\'ll pack.': "Once I've confirmed it, I'll have my things packed.",
  'Notebook packed. Ahead needs attention now.': "I'll put the notebook away. I need to watch ahead now.",
  'Today, unwritten shared rest.': "Today I want us to rest together without taking notes.",
  'Not every question at once. Rest before talk.': "I won't ask everything at once. Let's rest before talking.",
 },
 'tika': {
  'No loud laughter now.': "I can't laugh loudly right now.",
  'That hid what was inside.': "Laughing like that makes it hard to see how I really feel.",
  'No enduring behind a smile.': "I shouldn't hide the pain behind a smile.",
  'I want to try sitting without deciding too.': "I'd like to try sitting here without making any plans too.",
  "I won't take even our laughter onto the stage.": "I don't want even our laughter here to become part of my act.",
  'No noisy group needed, right?': "It's all right if we aren't all talking at once, isn't it?",
  'Today, both rest.': "Let's both rest today.",
  'My plan, briefly.': "I'll keep my plan brief.",
 },
 'tove': {
  'Packs slowly tomorrow.': "We can take our time with the packs tomorrow.",
  'Brief fresh air.': "I'll just get some fresh air and come back.",
  'Today, even seeing outside, I can sit again.': 'Today I can look outside and still choose to sit back down.',
  'I wanted here today.': 'I wanted to sit here today.',
  'Want here today.': 'I want to be here today.',
  'Food came slowly today.': 'The food took a while today.',
  "Won't need it today.": "I won't need it today.",
  'Still wearable.': 'I can still wear it.',
  'Need my hand stretched open.': 'I need to stretch my hand.',
  'Sleep here today.': "I'll sleep here tonight.",
  'Sleep inside today.': "I'll sleep inside tonight.",
  'Morning water together when awake.': "Let's have water together when we wake up.",
  'A little sleepiness can stay.': "If I get a little sleepy, I'll let myself be.",
  'Not going in now.': "I'm not going in now.",
  'My hand\'s movement first.': "I'll check whether I can move my hand first.",
  'Pack down. Lying down briefly.': "I'll leave the pack and lie down for a while.",
  'Tomorrow\'s choice tomorrow.': "I'll decide about tomorrow when it comes.",
  'Today I waited inside.': 'Today I waited for you inside.',
  'Even briefly, sitting helps.': 'Even sitting for a moment helps.',
 },
 'urda': {
  'Then silent prayer.': 'Then I shall pray silently.',
  'Read conditions before touching.': 'Let us read the conditions before touching it.',
  'Leave it, even cooled, until prayer ends.': 'Leave it there until the prayer ends, even if it cools.',
  'Count my work too.': 'Do not leave my work out of the count either.',
  'No answer fixed beforehand.': 'I will not settle the answer beforehand.',
  'Today my own day first.': 'Today I shall tell you about my own day first.',
  'No god\'s name makes a guess an answer.': 'I will not invoke a god to make a guess sound certain.',
  'Today I want a shared table, notebook closed.': 'Today I want to sit with you, with the notebook closed.',
  'Missing hands, I\'ll call immediately.': 'If I need another hand, I shall call at once.',
  'Hungry people first?': 'Shall we check who is hungry first?',
 },
 'zahar': {
  'Driven out early summer.': 'They drove me out in early summer.',
  "I'll check surroundings further.": "I'll keep checking around us.",
  'No overreaching to block everything.': "Don't wear yourself out trying to block everything.",
  'Check we can go together, then move.': 'Make sure we can go together before moving.',
  'Other business tomorrow.': 'Anything else can wait until tomorrow.',
  'Hands washed first for me.': "I'll wash my hands first.",
  'Packs in the morning.': "We'll check the packs in the morning.",
  'No paper before an empty bowl.': "I'm not looking at that paper until I've finished eating.",
  'No staying alone.': "Don't think of staying behind alone.",
  'Back now.': 'We need to fall back now.',
  'One more cup, then ready.': "One more cup, and I'll be ready.",
  'No forced choice.': 'Nobody forced my choice.',
 },
 'lynette': {
  'Will people close their purses at my face now?': 'Will people close their purses as soon as they see my face now?',
  'Ask for cost price. It\'s charity.': "It's for a good cause. Ask them to sell at cost.",
 },
 'judith': {
  "I didn't want to send one more person away.": "I didn't want to send anyone else away.",
 },
}
changes = []
for cid, replacements in edits.items():
    path, data = load(cid)
    for key, old in list(data['en']['display'].items()):
        if old in replacements:
            new = replacements[old]
            data['en']['display'][key] = new
            changes.append({'id': cid, 'field': key, 'before': old, 'after': new})
    write_en(path, data['en'])
(Path(__file__).with_name('editorial-revisions-round3.json')).write_text(json.dumps(changes,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print('Editorial revisions:', len(changes))
