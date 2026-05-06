#!/bin/sh

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

tree_json="$(i3-msg -t get_tree)"

focused_id="$(printf '%s' "$tree_json" | jq -r 'first(.. | objects | select(.focused == true) | .id) // empty')"

if [ -z "$focused_id" ]; then
    exit 0
fi

pair="$(printf '%s' "$tree_json" | jq -r --argjson fid "$focused_id" '
    first(
        ..
        | objects
        | select((.nodes | type) == "array" and (.nodes | length) == 2)
        | select(any(.nodes[]; .id == $fid))
        | [.nodes[0].id, .nodes[1].id]
        | @tsv
    ) // empty
')"

if [ -z "$pair" ]; then
    exit 0
fi

tab="$(printf '\t')"
left_id="${pair%%$tab*}"
right_id="${pair#*$tab}"

if [ "$left_id" = "$focused_id" ]; then
    other_id="$right_id"
else
    other_id="$left_id"
fi

i3-msg "[con_id=$focused_id] swap container with con_id $other_id" >/dev/null
