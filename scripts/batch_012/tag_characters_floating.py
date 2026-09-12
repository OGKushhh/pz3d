#!/usr/bin/env python3
"""Tag all character body parts as floating — they're all disconnected from each other."""
import re
from pathlib import Path

BASE = Path("/home/z/my-project/assets/characters/src")

for name in ["walker_zombie_male", "walker_zombie_female", "crawler_zombie", "npc_survivor", "npc_soldier"]:
    p = BASE / f"{name}.mog"
    text = p.read_text()

    # For every primitive line (rounded_box, box, sphere, cylinder, cone, torus, slab, prism, wall) inside scene { },
    # add tags="floating" if not already present.
    # Match: <indent><primitive> "name" (... ) <end-of-line, no continuation>
    # The closing `)` may or may not be followed by `tags="floating"` already.

    # Simple regex: find `)` at end of a primitive line that doesn't already have tags="floating"
    # Match lines that start with whitespace + primitive keyword
    prim_pattern = re.compile(
        r'^(\s+)((?:rounded_box|box|sphere|cylinder|cone|torus|slab|prism|wall)\s+"[^"]+"\s*\([^)]*\))(\s*\))\s*$',
        re.MULTILINE
    )

    def add_tag(m):
        indent, body, close = m.group(1), m.group(2), m.group(3)
        if 'tags="floating"' in body:
            return m.group(0)
        return f'{indent}{body}, tags="floating"{close}'

    new_text = prim_pattern.sub(add_tag, text)

    p.write_text(new_text)
    diff = new_text.count('tags="floating"') - text.count('tags="floating"')
    print(f"  {name}: added {diff} tags=\"floating\"")

print("\n=== All character body parts tagged floating ===")
