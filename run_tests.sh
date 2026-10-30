#!/usr/bin/env bash
# Runs the Godot test scene headless and prints only failures and the summary.
GODOT="/c/Users/Igueziri/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe"

cd "$(dirname "$0")"
"$GODOT" --headless --quit --path . res://scenes/main.tscn 2>&1 | grep -E "^(FAIL: |=== .* passed, .* failed ===)"
