#!/usr/bin/env bash
# Usage: tools/balance/run.sh <games> <seed> <tag> [shards=4] [policy.json]
# Runs the simulator in parallel shards (games are independent: game i uses seed*1000003+i*101+1, so the result does not depend on the
# shard count), merges them and writes design/balance/report-<tag>.md. GODOT can override the binary path.
set -euo pipefail
GAMES=${1:-500}; SEED=${2:-1}; TAG=${3:-run}; SHARDS=${4:-4}; POLICY=${5:-}
GODOT=${GODOT:-/root/godot/Godot_v4.6.3-stable_linux.x86_64}
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
OUT=${TMPDIR:-/tmp}/balance-$TAG; mkdir -p "$OUT"; rm -f "$OUT"/shard*.json
PER=$(( (GAMES + SHARDS - 1) / SHARDS ))
for s in $(seq 0 $((SHARDS - 1))); do
  OFF=$((s * PER)); N=$(( GAMES - OFF < PER ? GAMES - OFF : PER ))
  [ "$N" -le 0 ] && continue
  ARGS=(--games=$N --seed=$SEED --offset=$OFF --out="$OUT/shard$s.json")
  [ -n "$POLICY" ] && ARGS+=(--policy="$POLICY")
  "$GODOT" --headless --path "$ROOT" -s res://tools/balance/simulate.gd -- "${ARGS[@]}" > "$OUT/shard$s.log" 2>&1 &
done
wait
python3 "$ROOT/tools/balance/make_report.py" --tag="$TAG" "$OUT"/shard*.json
