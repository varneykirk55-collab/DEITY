"""Run Godot recovery checks; fail on engine errors even if Godot returns zero."""
import argparse
import pathlib
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument('godot', help='Path to Godot 4.7.2 standard executable')
args = parser.parse_args()
root = pathlib.Path(__file__).resolve().parents[1]
logs = root / 'docs' / 'test-results'
logs.mkdir(parents=True, exist_ok=True)
suites = [
    ('editor', ['--editor', '--quit']),
    ('main-menu', ['--quit-after', '120']),
    ('world', ['res://scenes/game/GameWorld.tscn', '--quit-after', '120']),
    ('recovery', ['res://tests/recovery_smoke.tscn']),
    ('controls-stress', ['res://tests/controls_stress.tscn']),
]
failed = False
for name, tail in suites:
    command = [args.godot, '--headless', '--path', str(root), *tail]
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=120)
        output = result.stdout + result.stderr
        bad = result.returncode != 0 or any(token in output for token in ['SCRIPT ERROR:', 'ERROR:', 'FAIL ', 'WARNING:'])
        if name in ('recovery', 'controls-stress') and '0 failures' not in output:
            bad = True
    except subprocess.TimeoutExpired as exc:
        output = f'TIMEOUT after 120 seconds: {exc}\n'
        bad = True
    (logs / f'{name}.log').write_text(output)
    print(f'{"FAIL" if bad else "PASS"} {name}', flush=True)
    failed |= bad
sys.exit(1 if failed else 0)
