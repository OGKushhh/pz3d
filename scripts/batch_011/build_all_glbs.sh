#!/bin/bash
# Build all 40 batch 011 .mog files to .glb
set -u
export PATH="$PATH:/home/z/.local/bin"
cd /home/z/my-project

declare -a ASSETS=(
  "buildings:hospital"
  "buildings:police_station"
  "buildings:highrise_office"
  "buildings:parking_garage"
  "buildings:broadcast_tower"
  "buildings:railway_station"
  "buildings:grain_silo"
  "buildings:windmill"
  "buildings:tractor_shed"
  "buildings:farmhouse"
  "buildings:hunting_cabin"
  "buildings:ranger_station"
  "buildings:camping_tent"
  "buildings:deer_stand"
  "buildings:lighthouse"
  "buildings:fishing_hut"
  "buildings:pier_dock"
  "buildings:houseboat"
  "buildings:bridge_section"
  "buildings:military_checkpoint"
  "buildings:watchtower"
  "buildings:bunker_entrance"
  "buildings:helipad"
  "buildings:field_hospital_tent"
  "buildings:subway_platform"
  "buildings:subway_tunnel"
  "buildings:subway_train_car"
  "buildings:ticket_booth"
  "buildings:strip_mall"
  "buildings:auto_repair_shop"
  "buildings:laundromat"
  "buildings:barber_shop"
  "buildings:treehouse"
  "environment:campfire_ring"
  "environment:barbed_wire_fence"
  "environment:turnstile"
  "environment:crop_field_corn"
  "environment:seesaw"
  "props:basketball_hoop"
  "props:traffic_camera"
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
  # mogen build — quiet on success, capture stderr
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