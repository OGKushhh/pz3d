#!/usr/bin/env python3
"""Auto-generate shell .mog files + component manifests for all buildings.

For each building .mog that has doors/windows:
1. Copy the file as _shell.mog
2. Remove all module definitions for doors/windows
3. Remove all `group "front_door_group"`, `group "window_*"`, `group "garage_door*"` lines
4. Keep wall holes intact
5. Generate a _components.json with positions extracted from the group lines

This is a text transformation — we don't parse the .mog AST, we pattern-match.
"""
import re
import json
from pathlib import Path

SRC_DIR = Path("/home/z/my-project/assets/buildings/src")
COMP_DIR = Path("/home/z/my-project/assets/components/src")

# Component type mapping
COMPONENT_TYPES = {
    "front_door": "door_front",
    "garage_door": "door_garage",
    "window": "window_unit",
}

def process_building(mog_path: Path):
    name = mog_path.stem
    if name.endswith("_shell") or name.endswith("_textured"):
        return None  # Skip existing shells and textured variants
    
    text = mog_path.read_text()
    
    # Check if it has doors/windows
    has_components = bool(re.search(r'group\s+"(front_door|garage_door|window)', text))
    if not has_components:
        return None
    
    # Extract component positions from group lines
    components = []
    comp_id = 0
    
    # Pattern: group "name" (pos=[x, y, z]) { use "module_name" () }
    # or:     group "name" (pos=[x, y, z], rot=[0, 90, 0]) { use "module_name" () }
    pattern = re.compile(
        r'group\s+"([^"]+)"\s*\(\s*pos=\[([^\]]+)\](?:,\s*rot=\[([^\]]+)\])?\)\s*\{\s*use\s+"([^"]+)"\s*\(\)\s*\}'
    )
    
    for match in pattern.finditer(text):
        group_name = match.group(1)
        pos_str = match.group(2)
        rot_str = match.group(3) or "0, 0, 0"
        module_name = match.group(4)
        
        # Parse position
        pos_parts = [float(x.strip()) for x in pos_str.split(",")]
        # Parse rotation (only Y matters for buildings)
        rot_parts = [float(x.strip()) for x in rot_str.split(",")]
        rot_y = rot_parts[1] if len(rot_parts) > 1 else 0.0
        
        # Determine component type
        if "door" in module_name.lower() and "garage" in module_name.lower():
            comp_type = "door_garage"
            can_open = True
            can_lock = True
            can_break = False
            extra = {"open_type": "roll_up"}
        elif "door" in module_name.lower():
            comp_type = "door_front"
            can_open = True
            can_lock = True
            can_break = False
            extra = {"hinge_side": "left"}
        elif "window" in module_name.lower():
            comp_type = "window_unit"
            can_open = True
            can_lock = False
            can_break = True
            extra = {"can_climb": True}
        else:
            comp_type = module_name
            can_open = False
            can_lock = False
            can_break = False
            extra = {}
        
        comp = {
            "id": group_name,
            "type": comp_type,
            "pos": pos_parts,
            "rot_y": rot_y,
            "interactive": True,
            "can_open": can_open,
            "can_lock": can_lock,
            "can_break": can_break,
            **extra
        }
        components.append(comp)
        comp_id += 1
    
    if not components:
        return None
    
    # Create shell .mog: remove group lines that place doors/windows
    shell_text = text
    # Remove lines matching: group "xxx" (pos=...) { use "door/window" () }
    shell_text = re.sub(
        r'\s*group\s+"(?:front_door|garage_door|window|door|front_window|back_window|left_window|right_window|amb|wfg|wfu|wf|wb|wl|wr|door_g|d_|w_)[^"]*"\s*\([^)]*\)\s*\{[^}]*\}\s*',
        '\n',
        shell_text
    )
    # Also remove module definitions for doors/windows
    # Match: module "name" () { ... } blocks
    shell_text = re.sub(
        r'\n\s*module\s+"(?:front_door|window_unit|garage_door_unit|door|window|hc_door|cc_door|rs_door|fh_door|bs_door|t_door|r_win|gp_win|ps_win|amb_door|sm_door|lm_door|sm_win)[^"]*"\s*\(\)\s*\{[^}]*\}',
        '',
        shell_text
    )
    
    # Update meta name
    shell_text = re.sub(
        r'name\s*=\s*"' + re.escape(name) + '"',
        f'name = "{name}_shell"',
        shell_text
    )
    # Update description
    shell_text = re.sub(
        r'description\s*=\s*"([^"]*)"',
        f'description = "\\1 (shell only — doors/windows loaded as child GLBs)"',
        shell_text,
        count=1
    )
    
    # Write shell .mog
    shell_path = SRC_DIR / f"{name}_shell.mog"
    shell_path.write_text(shell_text)
    
    # Write component manifest JSON
    manifest = {
        "building_id": name,
        "shell": f"{name}_shell",
        "components": components,
    }
    manifest_path = SRC_DIR / f"{name}_components.json"
    manifest_path.write_text(json.dumps(manifest, indent=2))
    
    return name, len(components)

# Process all buildings
processed = []
skipped = []

for mog_file in sorted(SRC_DIR.glob("*.mog")):
    result = process_building(mog_file)
    if result:
        processed.append(result)
    else:
        skipped.append(mog_file.stem)

print(f"=== Processed {len(processed)} buildings ===")
for name, count in processed:
    print(f"  {name}: {count} components")
print(f"\n=== Skipped {len(skipped)} (no doors/windows) ===")
for name in skipped[:10]:
    print(f"  {name}")
if len(skipped) > 10:
    print(f"  ... and {len(skipped) - 10} more")
