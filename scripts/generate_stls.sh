#!/usr/bin/env bash
# generate_stls.sh - Generate STL files from OpenSCAD designs
#
# Usage: ./scripts/generate_stls.sh [output_dir]
#
# Requires: OpenSCAD installed and available on PATH
# Install: https://openscad.org/downloads.html
#   Ubuntu/Debian: sudo apt-get install openscad
#   macOS: brew install openscad
#   Or use the AppImage from the website

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DESIGNS_DIR="$REPO_DIR/designs"
OUTPUT_DIR="${1:-$REPO_DIR/docs/models}"

# Display modes to render for each design
DISPLAY_MODES=("both" "handle" "hook" "assembled")

# Check for OpenSCAD
if ! command -v openscad &>/dev/null; then
    echo "Error: OpenSCAD is not installed or not on PATH."
    echo "Install it from https://openscad.org/downloads.html"
    exit 1
fi

echo "OpenSCAD version: $(openscad --version 2>&1 || true)"
echo "Designs directory: $DESIGNS_DIR"
echo "Output directory: $OUTPUT_DIR"
echo ""

DOCS_DESIGNS_DIR="$REPO_DIR/docs/designs"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$DOCS_DESIGNS_DIR"

# Copy SCAD sources into docs/ so they're accessible from the web
echo "Copying SCAD sources to docs/designs/ ..."
cp "$DESIGNS_DIR"/*.scad "$DOCS_DESIGNS_DIR/" 2>/dev/null || true
echo ""

# Track generated files for manifest
declare -a MANIFEST_ENTRIES

# Find all .scad files
shopt -s nullglob
SCAD_FILES=("$DESIGNS_DIR"/*.scad)

if [ ${#SCAD_FILES[@]} -eq 0 ]; then
    echo "No .scad files found in $DESIGNS_DIR"
    exit 0
fi

for scad_file in "${SCAD_FILES[@]}"; do
    base_name="$(basename "$scad_file" .scad)"
    echo "Processing: $base_name"

    # Check if the file uses display_mode parameter
    has_display_mode=false
    if grep -q 'display_mode' "$scad_file"; then
        has_display_mode=true
    fi

    stl_files="{"

    if $has_display_mode; then
        for mode in "${DISPLAY_MODES[@]}"; do
            output_file="$OUTPUT_DIR/${base_name}_${mode}.stl"
            echo "  Rendering mode: $mode -> $(basename "$output_file")"

            openscad \
                -o "$output_file" \
                -D "display_mode=\"$mode\"" \
                "$scad_file" 2>&1 | sed 's/^/    /'

            if [ -f "$output_file" ]; then
                echo "  OK: $(du -h "$output_file" | cut -f1)"
            else
                echo "  WARN: Failed to generate $output_file"
            fi

            stl_files+="\"$mode\": \"models/${base_name}_${mode}.stl\","
        done
    else
        output_file="$OUTPUT_DIR/${base_name}.stl"
        echo "  Rendering -> $(basename "$output_file")"

        openscad -o "$output_file" "$scad_file" 2>&1 | sed 's/^/    /'

        if [ -f "$output_file" ]; then
            echo "  OK: $(du -h "$output_file" | cut -f1)"
        fi

        stl_files+="\"default\": \"models/${base_name}.stl\","
    fi

    stl_files="${stl_files%,}}"

    # Extract description from file comments
    description=$(head -5 "$scad_file" | grep -oP '(?<=// ).*' | head -1 || echo "")

    MANIFEST_ENTRIES+=("{\"name\": \"$(echo "$base_name" | sed 's/_/ /g; s/\b\w/\U&/g')\", \"slug\": \"$base_name\", \"description\": \"$description\", \"scadFile\": \"designs/$base_name.scad\", \"stlFiles\": $stl_files}")

    echo ""
done

# Generate manifest.json
MANIFEST_FILE="$OUTPUT_DIR/manifest.json"
echo "[" > "$MANIFEST_FILE"
for i in "${!MANIFEST_ENTRIES[@]}"; do
    if [ $i -gt 0 ]; then
        echo "," >> "$MANIFEST_FILE"
    fi
    echo "  ${MANIFEST_ENTRIES[$i]}" >> "$MANIFEST_FILE"
done
echo "]" >> "$MANIFEST_FILE"

echo "Manifest written to $MANIFEST_FILE"
echo "Done! Generated STL files for ${#SCAD_FILES[@]} design(s)."
