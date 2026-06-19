#!/bin/bash
# Script de statusline para Claude Code
# Lee JSON por stdin y escribe una sola línea ANSI con: cwd (cyan), barra de progreso (verde), branch (amarillo) y modelo (magenta).

json=$(cat)

STATUSLINE_JSON="$json" python3 <<'PY'
import sys, json, subprocess, os, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

try:
    data = json.loads(os.environ.get('STATUSLINE_JSON', '{}'))
except Exception:
    data = {}

cwd = (data.get('workspace') or {}).get('current_dir') or data.get('cwd') or os.getcwd()
try:
    cwd_name = os.path.basename(cwd.rstrip('\\/')) or cwd
except Exception:
    cwd_name = cwd

model_obj = data.get('model') or {}
if isinstance(model_obj, dict):
    model = model_obj.get('display_name') or model_obj.get('id') or ''
else:
    model = str(model_obj)

ctx = data.get('context_window') or {}
used_raw = ctx.get('used_percentage', None)
if used_raw is None:
    window_size = ctx.get('context_window_size') or ctx.get('max_tokens') or ctx.get('total_tokens')
    usage = ctx.get('current_usage') or {}
    used_tokens = (
        (usage.get('input_tokens') or 0)
        + (usage.get('cache_creation_input_tokens') or 0)
        + (usage.get('cache_read_input_tokens') or 0)
    )
    if window_size and used_tokens:
        used_raw = (used_tokens / window_size) * 100
has_usage = used_raw is not None
try:
    used = float(used_raw) if has_usage else 0.0
except Exception:
    used = 0.0
    has_usage = False
used = max(0.0, min(100.0, used))

units = 12
filled = int(round((used / 100.0) * units))
filled = max(0, min(units, filled))
bar = '█' * filled + '░' * (units - filled)
percent = f"{int(round(used))}%" if has_usage else "--"

branch = '-'
try:
    branch_bytes = subprocess.check_output(
        ['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
        cwd=cwd, stderr=subprocess.DEVNULL
    )
    branch = branch_bytes.decode().strip()
except Exception:
    try:
        head_path = os.path.join(cwd, '.git', 'HEAD')
        with open(head_path, 'r', encoding='utf-8') as f:
            ref = f.readline().strip()
            if ref.startswith('ref:'):
                branch = os.path.basename(ref.split()[-1])
            else:
                branch = ref[:7]
    except Exception:
        branch = '-'

C_RESET   = '\033[0m'
C_CYAN    = '\033[36m'
C_GREEN   = '\033[32m'
C_YELLOW  = '\033[33m'
C_MAGENTA = '\033[35m'
C_ORANGE  = '\033[33m'
C_RED     = '\033[31m'

rl = (data.get('rate_limits') or {}).get('five_hour') or {}
rl_pct_raw = rl.get('used_percentage')
if rl_pct_raw is not None:
    rl_pct = max(0.0, min(100.0, float(rl_pct_raw)))
    rl_filled = int(round((rl_pct / 100.0) * units))
    rl_filled = max(0, min(units, rl_filled))
    rl_bar = '█' * rl_filled + '░' * (units - rl_filled)
    rl_percent = f"{int(round(rl_pct))}%"
    rl_color = C_RED if rl_pct >= 90 else C_ORANGE
    resets_at = rl.get('resets_at')
    reset_str = ""
    if resets_at:
        import time
        secs_left = int(resets_at) - int(time.time())
        if secs_left > 0:
            h, m = divmod(secs_left // 60, 60)
            reset_str = f" ↺{h}h{m:02d}m" if h else f" ↺{m}m"
    rl_part = f"  {rl_color}{rl_bar} {rl_percent}{reset_str}{C_RESET}"
else:
    rl_part = ""

out = (
    f"{C_CYAN}{cwd_name}{C_RESET}  "
    f"{C_GREEN}{bar} {percent}{C_RESET}"
    f"{rl_part}  "
    f"{C_YELLOW}({branch}){C_RESET}\n"
    f"{C_MAGENTA}{model}{C_RESET}"
)
print(out)
PY
