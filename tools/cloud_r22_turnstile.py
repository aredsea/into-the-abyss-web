"""Browser contract for the shipped HTML widget bridge. No external tokens or network.

The provider API is a test double; token delivery, cancellation, errors and retry
run in Chromium against the production shell's JavaScript, not a second bridge.
"""
from pathlib import Path
import json, re
from playwright.sync_api import sync_playwright
root=Path(__file__).resolve().parents[1]
out=root/'verification/cloud-r22/p9b';out.mkdir(exist_ok=True)
shell=(root/'project/web_shell.html').read_text(encoding='utf-8')
shell=re.sub(r'<script src="\$GODOT_URL".*?</script>', '', shell)
shell=re.sub(r'<script>\s*\(\(\) => \{\s*const config=\$GODOT_CONFIG;.*?</script>', '', shell, flags=re.S)
checks=[]
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path='C:/Program Files/Google/Chrome/Application/chrome.exe',headless=True)
    page=browser.new_page(viewport={'width':360,'height':780})
    page.route('**/*',lambda route:route.abort())
    page.set_content(shell)
    assert page.evaluate('typeof window.abyssTurnstile')=='object', 'HTML shell has no Turnstile bridge'
    checks.append('shipped-shell-bridge')
    page.evaluate("""window.turnstile={render(el,options){window.widgetOptions=options;el.textContent='테스트 인증 위젯';return 'test-widget'},remove(){},reset(){}}""")
    page.evaluate("abyssTurnstile.begin('test-site-key')")
    page.wait_for_function('window.widgetOptions?.action==="account"')
    assert page.locator('#cloud-challenge').is_visible()
    page.screenshot(path=str(out/'turnstile-360x780.png'))
    page.evaluate("widgetOptions.callback('synthetic-local-token')")
    assert page.evaluate('JSON.parse(abyssTurnstile.poll()).token')=='synthetic-local-token'
    checks.append('action-and-token-delivery')
    page.evaluate('abyssTurnstile.finish()')
    assert not page.locator('#cloud-challenge').is_visible()
    assert page.evaluate('JSON.parse(abyssTurnstile.poll()).token')==''
    checks.append('consumed-token-cleared')
    page.evaluate("abyssTurnstile.begin('test-site-key')")
    page.locator('#cloud-challenge-cancel').click()
    assert page.evaluate('JSON.parse(abyssTurnstile.poll()).status')=='cancelled'
    checks.append('cancel-with-keyboard-focus')
    page.evaluate("async()=>{await abyssTurnstile.begin('test-site-key');widgetOptions['error-callback']()}")
    assert page.evaluate('JSON.parse(abyssTurnstile.poll()).status')=='error'
    page.evaluate("async()=>{abyssTurnstile.finish();await abyssTurnstile.begin('test-site-key');widgetOptions.callback('second-synthetic-token')}")
    assert page.evaluate('JSON.parse(abyssTurnstile.poll()).token')=='second-synthetic-token'
    page.evaluate("widgetOptions['expired-callback']()")
    assert page.evaluate('JSON.parse(abyssTurnstile.poll()).token')==''
    checks.extend(['error-retry','expiry-clears-token'])
    browser.close()
(out/'turnstile-results.json').write_text(json.dumps({'checks':checks,'failures':0,'provider':'local test double; no live service/token'},ensure_ascii=False,indent=2),encoding='utf-8')
print('TURNSTILE BRIDGE CHECKS',len(checks),'FAILURES 0')
