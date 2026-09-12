#!/usr/bin/env python3
"""Fix all 5 characters — remove skeleton + skin= attributes (static posed meshes)."""
import re
from pathlib import Path

BASE = Path("/home/z/my-project/assets/characters/src")

for name in ["walker_zombie_male", "walker_zombie_female", "crawler_zombie", "npc_survivor", "npc_soldier"]:
    p = BASE / f"{name}.mog"
    text = p.read_text()

    # Remove skeleton "rig" { ... } block (matches the whole skeleton declaration)
    # Use regex to find `skeleton "rig" { ... }` (balanced braces — but ours are simple, no nested {})
    text = re.sub(
        r'\s*skeleton "rig" \{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}',
        '',
        text,
        count=1
    )

    # Remove all `skin="rig"` attributes from mesh declarations
    text = re.sub(r',\s*skin="rig"', '', text)
    text = re.sub(r'\s+skin="rig"', '', text)

    # Remove all the marker_* lines I added previously (they're useless now)
    text = re.sub(r'\n\s*box "marker_[^"]+" \([^)]*\) tags="floating"', '', text)

    p.write_text(text)
    print(f"  fixed {name}.mog (skeleton removed, {text.count(chr(10))} lines)")

print("\n=== All 5 characters fixed (skeleton + skin= removed) ===")
