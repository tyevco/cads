#!/usr/bin/env bash
# generate_manifest.sh - Build designs.json from SCAD files
#
# Scans designs/*.scad and extracts metadata (name, description,
# display modes, parameters) into docs/designs.json so the editor
# and gallery can discover designs at runtime without hardcoding.
#
# Usage: ./scripts/generate_manifest.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DESIGNS_DIR="$REPO_DIR/designs"
OUTPUT="$REPO_DIR/docs/designs.json"

shopt -s nullglob
SCAD_FILES=("$DESIGNS_DIR"/*.scad)

if [ ${#SCAD_FILES[@]} -eq 0 ]; then
    echo "[]" > "$OUTPUT"
    echo "No designs found."
    exit 0
fi

first=true
echo "[" > "$OUTPUT"

for scad_file in "${SCAD_FILES[@]}"; do
    slug="$(basename "$scad_file" .scad)"

    # Pretty name from slug
    name="$(echo "$slug" | sed 's/_/ /g; s/\b\w/\U&/g')"

    # Description: first non-decoration comment line after the title
    description="$(sed -n '2,10{/^\/\/ [^=]/{ s/^\/\/ //; p; q; }}' "$scad_file")"

    # Display modes from: display_mode = "x"; // ["a", "b", "c"]
    modes_line="$(grep 'display_mode.*\[' "$scad_file" 2>/dev/null | head -1 || true)"
    if [ -n "$modes_line" ]; then
        # Extract quoted strings inside the brackets
        modes_json="$(echo "$modes_line" | grep -oP '\[.*\]' | head -1 | sed 's/"/"/g')"
    else
        modes_json='["default"]'
    fi

    # Build stlFiles map from modes
    stl_files="{"
    stl_first=true
    for mode in $(echo "$modes_json" | tr -d '[]"' | tr ',' ' '); do
        $stl_first || stl_files+=", "
        stl_first=false
        if [ "$mode" = "default" ]; then
            stl_files+="\"default\": \"models/${slug}.stl\""
        else
            stl_files+="\"$mode\": \"models/${slug}_${mode}.stl\""
        fi
    done
    stl_files+="}"

    # Extract parameter names (lines matching: name = value;)
    params="$(grep -oP '^\w+(?=\s*=\s*[^;]+;)' "$scad_file" | grep -v '^\$' | grep -v '^display_mode$' || true)"
    params_json="["
    params_first=true
    while IFS= read -r p; do
        [ -z "$p" ] && continue
        $params_first || params_json+=", "
        params_first=false
        params_json+="\"$p\""
    done <<< "$params"
    params_json+="]"

    if $first; then
        first=false
    else
        # Append comma to previous entry
        sed -i '$ s/$/,/' "$OUTPUT"
    fi

    cat >> "$OUTPUT" <<ENTRY
  {
    "name": "$name",
    "slug": "$slug",
    "description": "$description",
    "scadFile": "designs/$slug.scad",
    "stlFiles": $stl_files,
    "parameters": $params_json
  }
ENTRY

done

echo "]" >> "$OUTPUT"

echo "Wrote $OUTPUT with ${#SCAD_FILES[@]} design(s)."
