#!/usr/bin/env python3
"""Exercise AeroSpace on a temporary workspace in the current Hyprland session."""
import json, os, subprocess, time, uuid, sys

def ctl(*args):
    p = subprocess.run(['hyprctl', *args], text=True, capture_output=True)
    if p.returncode: raise RuntimeError('hyprctl ' + repr(args) + ': ' + p.stdout + p.stderr)
    return p.stdout.strip()
def data(name): return json.loads(ctl('-j', name))
def wait_for(fn):
    for _ in range(100):
        if fn(): return
        time.sleep(.1)
    raise RuntimeError('Timed out waiting for test windows')
def check():
    errors = ctl('configerrors')
    if errors: raise RuntimeError('Hyprland config errors: ' + errors)
def evaluate(code):
    out = ctl('eval', code)
    if 'error' in out.lower(): raise RuntimeError(out)

original = data('activeworkspace')['id']
focus = data('activewindow').get('address')
used = {w['id'] for w in data('workspaces')}
workspace = next(i for i in range(9000, 9999) if i not in used)
name = 'aerospace-test-' + uuid.uuid4().hex
processes = []
start = subprocess.run(['journalctl', '--user', '-n', '0', '--show-cursor', '--no-pager'], text=True, capture_output=True).stdout.split('-- cursor: ')
cursor = start[-1].strip() if len(start) > 1 else None
try:
    evaluate("hl.dispatch(hl.dsp.focus({workspace='%d'}))" % workspace)
    for i in range(3):
        processes.append(subprocess.Popen(['foot', '--app-id', name, '--title', name, 'sleep', '120'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
        wait_for(lambda: len([w for w in data('clients') if w['class'] == name]) >= i + 1)
        check()
    windows = [w for w in data('clients') if w['class'] == name]
    if any(w['workspace']['id'] != workspace for w in windows): raise RuntimeError('Test windows opened on wrong workspace')
    for code in ["hl.dispatch(hl.dsp.layout('toggle'))", "hl.dispatch(hl.dsp.layout('accordion'))", "hl.dispatch(hl.dsp.layout('move l'))", "hl.dispatch(hl.dsp.layout('join r'))", "require('hypr.aerospace').focus('l')", "hl.dispatch(hl.dsp.layout('resize 50'))", "hl.dispatch(hl.dsp.layout('flatten'))"]:
        evaluate(code); time.sleep(.2); check()
    ctl('reload'); time.sleep(1); check()
    evaluate("hl.dispatch(hl.dsp.layout('toggle'))"); check()
    if cursor:
        log = subprocess.run(['journalctl', '--user', '--after-cursor', cursor, '--no-pager', '-o', 'cat'], text=True, capture_output=True).stdout
        bad = [line for line in log.splitlines() if ('lua' in line.lower() or 'aerospace' in line.lower()) and ('error' in line.lower() or 'traceback' in line.lower())]
        if bad: raise RuntimeError('Runtime errors:\n' + '\n'.join(bad))
    print('PASS: three windows, toggles, move, join, focus, resize, flatten and reload')
finally:
    for p in processes: p.terminate()
    for p in processes:
        try: p.wait(timeout=3)
        except subprocess.TimeoutExpired: p.kill(); p.wait()
    evaluate("hl.dispatch(hl.dsp.focus({workspace='%d'}))" % original)
    if focus and focus != '0x0': evaluate("hl.dispatch(hl.dsp.focus({window='address:%s'}))" % focus)
