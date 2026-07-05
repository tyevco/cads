#!/usr/bin/env bash
# audit_designs.sh - Render every display mode of every design and
# validate the output meshes.
#
# For each designs/*.scad and each mode in its _display_mode list:
#   - renders a binary STL with OpenSCAD (per-render timeout)
#   - fails on OpenSCAD ERROR/WARNING lines (except localization noise)
#   - runs scripts/check_stl.js (watertight + degenerate-triangle check)
#
# Usage: ./scripts/audit_designs.sh [design-name]
#   e.g. ./scripts/audit_designs.sh              # audit everything
#        ./scripts/audit_designs.sh gear_fidget  # audit one design
#
# Requires: openscad and node on PATH.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="${AUDIT_OUT:-$(mktemp -d)}"
mkdir -p "$OUT_DIR"
TIMEOUT="${AUDIT_TIMEOUT:-480}"
FAILURES=0

command -v openscad >/dev/null || { echo "openscad not on PATH"; exit 2; }
command -v node >/dev/null || { echo "node not on PATH"; exit 2; }

for scad in "$REPO_DIR"/designs/${1:-*}.scad; do
    base="$(basename "$scad" .scad)"
    modes_line="$(grep '_display_mode.*\[' "$scad" | head -1 || true)"
    if [ -n "$modes_line" ]; then
        modes="$(echo "$modes_line" | grep -oP '\[.*\]' | tr -d '[]" ' | tr ',' ' ')"
    else
        modes="__default__"
    fi

    for mode in $modes; do
        stl="$OUT_DIR/${base}__${mode}.stl"
        log="$OUT_DIR/${base}__${mode}.log"
        if [ "$mode" = "__default__" ]; then
            timeout "$TIMEOUT" openscad -o "$stl" --export-format binstl "$scad" >"$log" 2>&1
        else
            timeout "$TIMEOUT" openscad -o "$stl" --export-format binstl \
                -D "_display_mode=\"$mode\"" "$scad" >"$log" 2>&1
        fi
        rc=$?

        problems="$(grep -E "WARNING|ERROR" "$log" | grep -v "localization\|fontconfig" || true)"
        if [ $rc -ne 0 ] || [ ! -s "$stl" ] || [ -n "$problems" ]; then
            echo "FAIL  $base [$mode] rc=$rc"
            [ -n "$problems" ] && echo "$problems" | head -5 | sed 's/^/      /'
            FAILURES=$((FAILURES + 1))
            continue
        fi

        if check="$(node "$SCRIPT_DIR/check_stl.js" "$stl")"; then
            echo "OK    $base [$mode]  $check"
        else
            echo "FAIL  $base [$mode]  $check"
            FAILURES=$((FAILURES + 1))
        fi
    done
done

echo ""
if [ $FAILURES -gt 0 ]; then
    echo "$FAILURES render(s) failed. STLs and logs in: $OUT_DIR"
    exit 1
fi
echo "All renders clean. STLs in: $OUT_DIR"
