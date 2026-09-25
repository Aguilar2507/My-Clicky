#!/usr/bin/env python3
"""Marks tasks done in a Spec Kit tasks.md and appends implementation notes.

Usage: mark_tasks.py <tasks.md> <T001,T002,...|all-except:T027> [notes.md]
Tasks not listed stay "- [ ]". Notes (markdown) are appended under "## Implementation notes".
"""
import re, sys

path, spec = sys.argv[1], sys.argv[2]
notes = open(sys.argv[3]).read().strip() if len(sys.argv) > 3 else ""
text = open(path).read()
ids = re.findall(r"^- \[[ Xx]\] (T\d{3})", text, flags=re.M)
if spec.startswith("all-except:"):
    skip = set(spec.split(":", 1)[1].split(",")) - {""}
    done = [i for i in ids if i not in skip]
else:
    done = spec.split(",")
for task in done:
    text = re.sub(rf"^- \[[ Xx]\] {task}\b", f"- [X] {task}", text, flags=re.M)
if notes:
    text = re.sub(r"\n## Implementation notes\n.*", "", text, flags=re.S).rstrip() + "\n\n## Implementation notes\n\n" + notes + "\n"
open(path, "w").write(text)
total = len(ids)
checked = len(re.findall(r"^- \[X\] T\d{3}", text, flags=re.M))
print(f"{path}: {checked}/{total} done")
