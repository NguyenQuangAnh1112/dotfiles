#!/bin/sh

python3 - <<'PY'
import json
import subprocess
import sys

try:
    tree = json.loads(subprocess.check_output(["i3-msg", "-t", "get_tree"], text=True))
except Exception:
    sys.exit(0)

focused_id = None
pair = None

def contains_focused(node):
    global focused_id, pair
    if node.get("focused"):
        focused_id = node.get("id")
        return True

    child_nodes = node.get("nodes") or []
    floating_nodes = node.get("floating_nodes") or []
    focused_in_tiled_child = False

    for child in child_nodes:
        if contains_focused(child):
            focused_in_tiled_child = True

    for child in floating_nodes:
        contains_focused(child)

    if focused_in_tiled_child and pair is None and len(child_nodes) == 2:
        pair = [child.get("id") for child in child_nodes]

    return focused_in_tiled_child

contains_focused(tree)

if not focused_id or not pair:
    sys.exit(0)

other_id = pair[1] if pair[0] == focused_id else pair[0]
subprocess.call(["i3-msg", f"[con_id={focused_id}]", "swap", "container", "with", "con_id", str(other_id)], stdout=subprocess.DEVNULL)
PY
