#!/usr/bin/env python3
"""Fix emergency_exit_stairs — add tags="floating" to all step lines via regex."""
import re
from pathlib import Path

p = Path("/home/z/my-project/assets/buildings/src/emergency_exit_stairs.mog")
text = p.read_text()

# Match any line with `box "step_N" (... mat="concrete", pos=[...])` that doesn't already have tags="floating"
# Pattern: `mat="concrete", pos=[numbers])`  →  `mat="concrete", pos=[numbers], tags="floating")`
# But only on lines containing "step_" — to avoid matching other concrete elements.
def add_floating(match):
    line = match.group(0)
    if 'tags="floating"' in line:
        return line  # already done
    # Insert tags="floating" before the closing paren of the primitive
    return line[:-1] + ', tags="floating")'

# Match:  <indent>box "step_N" (size=[...], mat="concrete", pos=[...])
pattern = re.compile(r'(\s+)box "(step_\d+)" \((size=\[[^\]]+\], mat="concrete", pos=\[[^\]]+\])\)')
new_text = pattern.sub(lambda m: f'{m.group(1)}box "{m.group(2)}" ({m.group(3)}, tags="floating")', text)

# Also handle the landings (in case they aren't already)
new_text = new_text.replace(
    '  slab "landing_mid" (size=[2.0, 0.10, 1.80], mat="concrete", pos=[0, 3.20, 0])',
    '  slab "landing_mid" (size=[2.0, 0.10, 1.80], mat="concrete", pos=[0, 3.20, 0], tags="floating")'
)
new_text = new_text.replace(
    '  slab "landing_top" (size=[2.0, 0.10, 1.80], mat="concrete", pos=[0, 6.00, 0])',
    '  slab "landing_top" (size=[2.0, 0.10, 1.80], mat="concrete", pos=[0, 6.00, 0], tags="floating")'
)

p.write_text(new_text)
# Count changes
n = new_text.count('tags="floating"') - text.count('tags="floating"')
print(f"Added {n} tags=\"floating\" markers to emergency_exit_stairs.mog")
