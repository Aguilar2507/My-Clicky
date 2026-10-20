# Helpers for MyClicky end-to-end checks. Source it: `source scripts/e2e/lib.sh`.
# Needs Accessibility for the calling app (Terminal / VS Code). Builds the driver on first use.
E2E_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../.." && pwd)"
D="$E2E_ROOT/.build/e2e-drive"
[ -x "$D" ] || swiftc -O "$E2E_ROOT/scripts/e2e/drive.swift" -o "$D"
APP=com.myclicky.app
DATA="$HOME/Library/Application Support/MyClicky"
OUT="${E2E_OUT:-$E2E_ROOT/docs/e2e/$(date +%F)}"
mkdir -p "$OUT"

wait_s() { perl -e "select(undef,undef,undef,$1)"; }
mark() { date '+%Y-%m-%d %H:%M:%S'; }
# events since a mark: `events "$m"`
events() { /usr/bin/log show --start "$1" --predicate 'subsystem == "com.myclicky.app"' --style compact 2>/dev/null | grep -v '^Timestamp' | sed -E 's/^[0-9-]+ ([0-9:.]+) [A-Za-z]+ MyClicky\[[0-9:a-f]+\] \[com\.myclicky\.app:/\1 [/'; }
frontmost() { "$D" apps | awk '/\(active\)/ {print $2}'; }
# open-window shortcut from settings.json (press gesture)
open_window_shortcut() { "$D" down ctrl,opt,shift,cmd; "$D" key 3 ctrl,opt,shift,cmd; "$D" up ctrl,opt,shift,cmd; }
# push to talk: hold ⌃⌥ while a voice speaks. `talk "Jarvis, what app am I in?" [voice]`
talk() { "$D" down ctrl,opt; wait_s 0.6; say -v "${2:-Zoe}" "$1"; wait_s 0.8; "$D" up ctrl,opt; }
# dictation: hold ⌃fn while a voice speaks
dictate() { "$D" down fn,ctrl; wait_s 0.6; say -v "${2:-Zoe}" "$1"; wait_s 0.9; "$D" up fn,ctrl; }
# full-size screenshots through MyClicky's own Screen Recording permission: `shot name` → $OUT/name-1.png …
shot() { rm -f "$OUT/$1".txt; open -n -g "$HOME/Applications/MyClicky.app" --args --screenshot "$OUT/$1.png"; for _ in $(seq 1 40); do [ -f "$OUT/$1.txt" ] && break; wait_s 0.25; done; cat "$OUT/$1.txt"; }
# wait until an events line matches a pattern (seconds): `wait_event "$m" "talk answered" 30`
wait_event() { for _ in $(seq 1 $(( ${3:-30} * 2 ))); do events "$1" | grep -q -E "$2" && return 0; wait_s 0.5; done; return 1; }
reinstall() { (cd "$E2E_ROOT" && ./build.sh >/dev/null 2>&1) && osascript -e 'tell application id "com.myclicky.app" to quit' >/dev/null 2>&1; wait_s 2; open "$HOME/Applications/MyClicky.app"; wait_s 4; }
talk_chat() { python3 -I - "$DATA" "$@" <<'EOF'
import json, glob, sys
for f in glob.glob(sys.argv[1] + "/chats/*.json"):
    d = json.load(open(f))
    if d.get("kind") == "talk":
        n = int(sys.argv[2]) if len(sys.argv) > 2 else 4
        for m in d["messages"][-n:]: print(m["role"], "|", m.get("via"), "|", m["text"][:300].replace("\n", " "))
EOF
}
# bring MyClicky's window forward (the shell's app tends to take focus between commands)
front_app() { osascript -e 'tell application id "com.myclicky.app" to activate' >/dev/null 2>&1; wait_s 0.8; }
in_dock() { "$D" find com.apple.dock "MyClicky" AXDockItem >/dev/null 2>&1 && "$D" find com.apple.dock "MyClicky" AXDockItem | grep -q . && echo yes || echo no; }
setting() { python3 -I -c "import json,os,sys;print(json.load(open(os.path.expanduser('~/Library/Application Support/MyClicky/settings.json'))).get(sys.argv[1]))" "$1"; }
# Pointing accuracy: `point_test <bundle-id> "<x,y,w,h AX frame>" "<question>"` → HIT/MISS line.
# The app logs the point in AppKit coordinates (origin bottom-left of the main screen); AX frames are top-left.
MAIN_H=$(osascript -l JavaScript -e 'ObjC.import("AppKit"); $.NSScreen.screens.js[0].frame.size.height' 2>/dev/null)
point_test() {
  osascript -e "tell application id \"$1\" to activate" >/dev/null; wait_s 1.2
  local m; m=$(mark); talk "$3"
  if ! wait_event "$m" "pointed x=" 45; then echo "MISS (no pointing) | $3"; return; fi
  events "$m" | grep -o 'pointed x=[-0-9]* y=[-0-9]*' | tail -1 | python3 -I -c "
import sys,re
x,y=map(int,re.findall(r'-?\d+',sys.stdin.read()))
fx,fy,fw,fh=map(float,sys.argv[1].split(','))
ay=float(sys.argv[2])-y; m=25
hit=fx-m<=x<=fx+fw+m and fy-m<=ay<=fy+fh+m
print(('HIT ' if hit else 'MISS'),f'point=({x},{ay:.0f}) target={sys.argv[1]} |',sys.argv[3])" "$2" "$MAIN_H" "$3"
  wait_s 7
}
