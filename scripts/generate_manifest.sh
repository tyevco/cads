#!/usr/bin/env bash
# generate_manifest.sh - Build designs.json from SCAD files
#
# Scans designs/*.scad and extracts metadata from @-tag frontmatter
# into docs/designs.json so the editor and gallery can discover
# designs at runtime without hardcoding.
#
# Supported frontmatter tags (in // comments at top of file):
#   @name         Display name for the design
#   @description  Short description
#   @tags         Comma-separated tags
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

    # Parse @-tag frontmatter from leading comments
    name=""
    description=""
    tags=""
    while IFS= read -r line; do
        # Stop at first non-comment line
        [[ "$line" =~ ^// ]] || break
        # Extract @tags
        if [[ "$line" =~ ^//[[:space:]]*@name[[:space:]]+(.*) ]]; then
            name="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^//[[:space:]]*@description[[:space:]]+(.*) ]]; then
            description="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^//[[:space:]]*@tags[[:space:]]+(.*) ]]; then
            tags="${BASH_REMATCH[1]}"
        fi
    done < "$scad_file"

    # Fallback: name from slug if @name not set
    if [ -z "$name" ]; then
        name="$(echo "$slug" | sed 's/_/ /g; s/\b\w/\U&/g')"
    fi

    # Build tags JSON array
    if [ -n "$tags" ]; then
        tags_json="["
        tags_first=true
        IFS=',' read -ra tag_arr <<< "$tags"
        for t in "${tag_arr[@]}"; do
            t="$(echo "$t" | xargs)"  # trim whitespace
            $tags_first || tags_json+=", "
            tags_first=false
            tags_json+="\"$t\""
        done
        tags_json+="]"
    else
        tags_json="[]"
    fi

    # Display modes from: _display_mode = "x"; // ["a", "b", "c"]
    modes_line="$(grep '_display_mode.*\[' "$scad_file" 2>/dev/null | head -1 || true)"
    if [ -n "$modes_line" ]; then
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
    # Exclude $-prefixed vars (OpenSCAD special) and _-prefixed vars (internal)
    params="$(grep -oP '^\w+(?=\s*=\s*[^;]+;)' "$scad_file" | grep -v '^\$' | grep -v '^_' || true)"
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
    "tags": $tags_json,
    "parameters": $params_json
  }
ENTRY

done

echo "]" >> "$OUTPUT"

echo "Wrote $OUTPUT with ${#SCAD_FILES[@]} design(s)."
