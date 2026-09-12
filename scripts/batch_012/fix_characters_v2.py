#!/usr/bin/env python3
"""Properly remove skeleton block (with nested braces) + add tags=floating to all primitives."""
from pathlib import Path

BASE = Path("/home/z/my-project/assets/characters/src")

def remove_skeleton_block(text):
    """Remove the skeleton "rig" { ... } block (handles nested braces)."""
    # Find `skeleton "rig" {`
    marker = 'skeleton "rig" {'
    idx = text.find(marker)
    if idx == -1:
        return text
    # Find matching close brace
    depth = 1
    pos = idx + len(marker)
    while depth > 0 and pos < len(text):
        c = text[pos]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
        pos += 1
    # Remove from idx to pos (inclusive of close brace)
    # Also remove leading whitespace + trailing newline
    # Find start of line
    line_start = text.rfind('\n', 0, idx) + 1
    # Find end of line (after closing brace)
    end = pos
    if end < len(text) and text[end] == '\n':
        end += 1
    return text[:line_start] + text[end:]

def add_floating_to_primitives(text):
    """For every primitive declaration line, add tags="floating" if not present."""
    import re
    # Match lines starting with whitespace + primitive type + name + (...)
    # Then close paren
    lines = text.split('\n')
    out = []
    prim_types = ['rounded_box', 'box', 'sphere', 'cylinder', 'cone', 'torus', 'slab', 'prism', 'wall']
    for line in lines:
        stripped = line.lstrip()
        if any(stripped.startswith(p + ' ') for p in prim_types):
            # This is a primitive line
            if 'tags="floating"' not in line:
                # Find the last `)` and insert `, tags="floating"` before it
                last_paren = line.rfind(')')
                if last_paren > 0:
                    line = line[:last_paren] + ', tags="floating")' + line[last_paren+1:]
        out.append(line)
    return '\n'.join(out)

for name in ["walker_zombie_male", "walker_zombie_female", "crawler_zombie", "npc_survivor", "npc_soldier"]:
    p = BASE / f"{name}.mog"
    text = p.read_text()
    before_len = len(text)
    before_skel = text.count('skeleton "rig"')

    text = remove_skeleton_block(text)
    text = add_floating_to_primitives(text)

    # Also remove `skin="rig"` if any remain
    text = text.replace(', skin="rig"', '').replace(' skin="rig"', '').replace(',skin="rig"', '')

    p.write_text(text)
    after_len = len(text)
    after_skel = text.count('skeleton "rig"')
    print(f"  {name}: skeleton blocks {before_skel}→{after_skel}, length {before_len}→{after_len}")

print("\n=== Done ===")
