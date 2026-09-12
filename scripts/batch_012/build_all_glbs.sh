#!/bin/bash
# Build all 40 batch 012 .mog files to .glb
set -u
export PATH="$PATH:/home/z/.local/bin"
cd /home/z/my-project

declare -a ASSETS=(
  # Fixes (2)
  "buildings:broadcast_tower"
  "buildings:parking_garage"
  # Heroes (4)
  "buildings:government_palace"
  "buildings:stadium"
  "buildings:old_royal_palace"
  "buildings:fort_sarran"
  # Characters (5)
  "characters:walker_zombie_male"
  "characters:walker_zombie_female"
  "characters:crawler_zombie"
  "characters:npc_survivor"
  "characters:npc_soldier"
  # Decals (4)
  "decals:blood_splatter"
  "decals:poster_torn"
  "decals:grime_dirt"
  "decals:crack_road"
  # Forest (3)
  "buildings:cave_entrance"
  "buildings:logging_camp_shed"
  "buildings:ranger_lean_to"
  # Farmland (3)
  "environment:irrigation_canal"
  "environment:hay_bale"
  "buildings:grain_storage_shed"
  # Coastal (3)
  "environment:boardwalk_section"
  "foliage:marsh_grass"
  "buildings:marsh_pier"
  # Subway (3)
  "buildings:maintenance_tunnel_junction"
  "buildings:emergency_exit_stairs"
  "buildings:subway_pipe_cluster"
  # Military (2)
  "environment:mass_grave"
  "buildings:helipad_control_room"
  # Commercial (3)
  "buildings:salon"
  "buildings:grocery_store"
  "buildings:bank_branch"
  # Suburban (2)
  "props:bird_house"
  "props:garden_pergola"
  # Misc (2)
  "buildings:apartment_tower_high"
  "buildings:train_boxcar_derelict"
)

OK=0
FAIL=0
declare -a FAILED=()

for entry in "${ASSETS[@]}"; do
  cat="${entry%%:*}"
  name="${entry##*:}"
  src="assets/${cat}/src/${name}.mog"
  out="assets/${cat}/out/${name}.glb"
  mkdir -p "assets/${cat}/out"
  if [ ! -f "$src" ]; then
    echo "MISSING: $src"
    FAILED+=("${name}")
    FAIL=$((FAIL+1))
    continue
  fi
  out_log=$(mogen build "$src" --out "$out" 2>&1)
  rc=$?
  if [ $rc -eq 0 ] && [ -f "$out" ]; then
    size=$(stat -c%s "$out")
    echo "  OK  ${name}  (${size} bytes)"
    OK=$((OK+1))
  else
    echo "  FAIL ${name} (rc=${rc})"
    echo "    ${out_log}" | head -3
    FAILED+=("${name}")
    FAIL=$((FAIL+1))
  fi
done

echo ""
echo "=========================================="
echo "Build summary: ${OK} ok, ${FAIL} failed"
if [ ${FAIL} -gt 0 ]; then
  echo "Failed assets:"
  for f in "${FAILED[@]}"; do
    echo "  - ${f}"
  done
fi
echo "=========================================="