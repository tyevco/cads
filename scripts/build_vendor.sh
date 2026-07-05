#!/usr/bin/env bash
# build_vendor.sh - Rebuild the vendored JS bundles in docs/vendor/
#
# The site is a static GitHub Pages deploy with no build step, so
# third-party libraries are committed as pre-built, tree-shaken ESM
# bundles. Re-run this script to upgrade them.
#
# Requires: node + npm (uses npx esbuild)

set -euo pipefail

THREE_VERSION="0.170.0"
CODEMIRROR_VERSION="6"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VENDOR_DIR="$REPO_DIR/docs/vendor"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

cd "$BUILD_DIR"
npm init -y >/dev/null
npm install --no-audit --no-fund \
    esbuild \
    "three@$THREE_VERSION" \
    "codemirror@$CODEMIRROR_VERSION" \
    @codemirror/language @codemirror/state @codemirror/view \
    @codemirror/commands @codemirror/theme-one-dark @lezer/highlight

cat > entry-three.js <<'EOF'
export * from 'three';
export { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
export { STLLoader } from 'three/examples/jsm/loaders/STLLoader.js';
EOF

cat > entry-codemirror.js <<'EOF'
export { EditorView, basicSetup } from 'codemirror';
export { EditorState, Compartment } from '@codemirror/state';
export { keymap } from '@codemirror/view';
export { indentWithTab } from '@codemirror/commands';
export { StreamLanguage, HighlightStyle, syntaxHighlighting } from '@codemirror/language';
export { oneDark } from '@codemirror/theme-one-dark';
export { tags } from '@lezer/highlight';
EOF

three_v=$(node -p "JSON.parse(require('fs').readFileSync('node_modules/three/package.json')).version")
cm_v=$(node -p "JSON.parse(require('fs').readFileSync('node_modules/codemirror/package.json')).version")

mkdir -p "$VENDOR_DIR"
npx esbuild entry-three.js --bundle --format=esm --minify \
    --banner:js="/* three.js ${three_v} + OrbitControls + STLLoader | MIT | https://threejs.org | bundled for CADS */" \
    --outfile="$VENDOR_DIR/three.js"
npx esbuild entry-codemirror.js --bundle --format=esm --minify \
    --banner:js="/* CodeMirror ${cm_v} (basicSetup, one-dark) | MIT | https://codemirror.net | bundled for CADS */" \
    --outfile="$VENDOR_DIR/codemirror.js"

echo "Vendored bundles written to $VENDOR_DIR"
