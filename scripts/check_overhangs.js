#!/usr/bin/env node
// check_overhangs.js - FDM printability analysis of a binary STL.
//
// Classifies every downward-facing triangle (geometric normal z < 0) by
// how it prints, assuming the part is laid out on the plate as-is:
//
//   bed       resting on the plate (whole triangle within the first layer
//             of z=0) - the adhesion footprint. Never a problem.
//   bridge    a horizontal down-face (normal ~= [0,0,-1]) above the bed,
//             plus any steeper down-faces connected to it (the round
//             underside of a print-in-place hinge barrel is one bridge,
//             not a flat strip with two overhang skirts). Printable if
//             the span is short; reported as connected patches with
//             bounding boxes so the span is visible.
//   overhang  surface tilted more than the threshold from vertical
//             (default 45 deg, i.e. normal within 45 deg of straight
//             down) with no horizontal facet anywhere in its patch.
//             Needs support.
//   ok        downward-facing but self-supporting (tilt <= threshold).
//
// "floating" is the subset of overhang area whose triangles sit entirely
// above z_min + first-layer - i.e. genuinely in the air, not squashed
// into the first layer.
//
// Usage: node scripts/check_overhangs.js file.stl [options]
//   --threshold DEG         overhang threshold, degrees from vertical
//                           (default 45; faces tilted beyond this fail)
//   --max-overhang-area MM2 allowed overhang area before exit 1 (default 0)
//   --max-bridge MM2        bridge patches up to this area are excused;
//                           larger patches count as overhang (default 0)
//   --min-patch MM2         ignore overhang patches up to this area -
//                           tiny isolated facets (thread flanks) hang off
//                           supported perimeters and print fine (default 0)
//   --near-bed MM           excuse overhang patches lying entirely within
//                           this height of z_min - the first-layers squash
//                           zone (fillets/torus tangents at the plate)
//                           (default 0)
//   --first-layer MM        bed/first-layer tolerance (default 0.3)
//   --flat-tol DEG          how close to [0,0,-1] a normal must be to
//                           seed a bridge patch (default 5 - roughly the
//                           half-facet angle of a $fn=40 cylinder bottom)
//   --patches               list the largest bridge/overhang patches
//
// Exit 1 if overhang area (excluding bed contact, bridge patches no larger
// than --max-bridge, and overhang patches excused by --min-patch /
// --near-bed) exceeds --max-overhang-area. Exit 2 on usage errors, exit 1
// on an unreadable/non-binary STL (like check_stl.js).

const fs = require('fs');

const argv = process.argv.slice(2);
const file = argv[0];
if (!file || file.startsWith('--')) {
    console.error('usage: node check_overhangs.js file.stl [--threshold DEG] ' +
        '[--max-overhang-area MM2] [--max-bridge MM2] [--first-layer MM] ' +
        '[--flat-tol DEG] [--patches]');
    process.exit(2);
}
function opt(flag, def) {
    const i = argv.indexOf(flag);
    if (i < 0) return def;
    const v = parseFloat(argv[i + 1]);
    if (!isFinite(v)) { console.error(`bad value for ${flag}`); process.exit(2); }
    return v;
}
const THRESHOLD = opt('--threshold', 45);           // deg from vertical
const MAX_OVERHANG = opt('--max-overhang-area', 0); // mm2
const MAX_BRIDGE = opt('--max-bridge', 0);          // mm2 per bridge patch
const MIN_PATCH = opt('--min-patch', 0);            // mm2 per overhang patch
const NEAR_BED = opt('--near-bed', 0);              // mm above z_min
const FIRST_LAYER = opt('--first-layer', 0.3);      // mm
const FLAT_TOL = opt('--flat-tol', 5);              // deg
const SHOW_PATCHES = argv.includes('--patches');
const ANG_EPS = 0.05;   // deg slack so exactly-at-threshold faces pass
const AREA_EPS = 0.01;  // mm2: ignore numeric dust

const buf = fs.readFileSync(file);
if (buf.length < 84) {
    console.log('INVALID: file too small to be a binary STL');
    process.exit(1);
}
const n = buf.readUInt32LE(80);
if (buf.length !== 84 + n * 50) {
    console.log(`INVALID: size mismatch (ASCII STL?) tris=${n} bytes=${buf.length}`);
    process.exit(1);
}

// --- Pass 1: read triangles, geometric normals, global z_min -------------
const tris = []; // {v:[[x,y,z]x3], nz, alpha, area, minZ, maxZ, cat}
let zMin = Infinity;
for (let i = 0; i < n; i++) {
    const o = 84 + i * 50 + 12; // skip stored normal; recompute from vertices
    const v = [];
    for (let j = 0; j < 3; j++)
        v.push([buf.readFloatLE(o + j * 12), buf.readFloatLE(o + j * 12 + 4),
                buf.readFloatLE(o + j * 12 + 8)]);
    for (const p of v) zMin = Math.min(zMin, p[2]);
    const [a, b, c] = v;
    const u = [b[0] - a[0], b[1] - a[1], b[2] - a[2]];
    const w = [c[0] - a[0], c[1] - a[1], c[2] - a[2]];
    const cr = [u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2],
                u[0] * w[1] - u[1] * w[0]];
    const len = Math.hypot(cr[0], cr[1], cr[2]);
    if (len < 1e-12) continue; // degenerate: no area, nothing to print
    const nz = cr[2] / len;
    tris.push({
        v, nz, area: len / 2,
        alpha: Math.acos(Math.min(1, Math.max(-1, -nz))) * 180 / Math.PI,
        minZ: Math.min(a[2], b[2], c[2]),
        maxZ: Math.max(a[2], b[2], c[2]),
        cat: null,
    });
}

// --- Pass 2: classify downward-facing triangles ---------------------------
// alpha = angle between the face normal and straight down [0,0,-1]:
//   0 = horizontal ceiling, 90 = vertical wall. tilt-from-vertical = 90-alpha.
let downArea = 0, bedArea = 0;
const candidates = []; // tri indices that are either flat (bridge seeds)
                       // or steeper than the overhang threshold
for (let i = 0; i < tris.length; i++) {
    const t = tris[i];
    if (t.nz >= -1e-9) continue; // upward or vertical: never an overhang
    downArea += t.area;
    const tilt = 90 - t.alpha;
    if (t.maxZ <= FIRST_LAYER) {
        t.cat = 'bed'; bedArea += t.area;
    } else if (t.alpha <= FLAT_TOL) {
        t.cat = 'flat'; candidates.push(i);
    } else if (tilt > THRESHOLD + ANG_EPS) {
        t.cat = 'steep'; candidates.push(i);
    } else {
        t.cat = 'ok';
    }
}

// --- Connected-component patches (shared edges, like check_stl bodies) ---
// Flat facets and threshold-exceeding facets are grouped together; a patch
// containing at least one flat facet is a BRIDGE (e.g. the whole round
// underside of a horizontal hinge barrel), otherwise it is an OVERHANG.
const vmap = new Map();
const vid = p => {
    const k = p.join(',');
    if (!vmap.has(k)) vmap.set(k, vmap.size);
    return vmap.get(k);
};
const parent = candidates.map((_, i) => i);
const find = x => { while (parent[x] !== x) { parent[x] = parent[parent[x]]; x = parent[x]; } return x; };
const edgeOwner = new Map();
candidates.forEach((ti, local) => {
    const ids = tris[ti].v.map(vid);
    for (const [x, y] of [[0, 1], [1, 2], [2, 0]]) {
        const k = ids[x] < ids[y] ? `${ids[x]}|${ids[y]}` : `${ids[y]}|${ids[x]}`;
        if (edgeOwner.has(k)) {
            const a = find(edgeOwner.get(k)), b = find(local);
            if (a !== b) parent[a] = b;
        } else edgeOwner.set(k, local);
    }
});
const comps = new Map();
candidates.forEach((ti, local) => {
    const r = find(local);
    if (!comps.has(r)) comps.set(r, {
        area: 0, tris: 0, maxTilt: 0, hasFlat: false, minZ: Infinity,
        min: [1e9, 1e9, 1e9], max: [-1e9, -1e9, -1e9],
    });
    const c = comps.get(r);
    const t = tris[ti];
    c.area += t.area; c.tris++;
    c.maxTilt = Math.max(c.maxTilt, 90 - t.alpha);
    c.minZ = Math.min(c.minZ, t.minZ);
    if (t.cat === 'flat') c.hasFlat = true;
    for (const p of t.v) for (let k = 0; k < 3; k++) {
        c.min[k] = Math.min(c.min[k], p[k]);
        c.max[k] = Math.max(c.max[k], p[k]);
    }
});
const all = [...comps.values()].sort((a, b) => b.area - a.area);
const bridgePatches = all.filter(c => c.hasFlat);
const overhangPatches = all.filter(c => !c.hasFlat);
const bbox = c => `[${c.min.map(x => x.toFixed(1))}]..[${c.max.map(x => x.toFixed(1))}]`;

const bridgeArea = bridgePatches.reduce((s, c) => s + c.area, 0);
const overhangArea = overhangPatches.reduce((s, c) => s + c.area, 0);
// floating = overhang patches entirely above the first layer (truly in air)
const floatingArea = overhangPatches.reduce(
    (s, c) => s + (c.minZ > zMin + FIRST_LAYER ? c.area : 0), 0);

// --- Verdict ---------------------------------------------------------------
// Bridge patches larger than --max-bridge are treated as overhang; overhang
// patches smaller than --min-patch or entirely inside the --near-bed squash
// zone are excused.
let badBridgeArea = 0;
for (const p of bridgePatches) if (p.area > MAX_BRIDGE + AREA_EPS) badBridgeArea += p.area;
let badOverhangArea = 0;
for (const p of overhangPatches) {
    if (p.area <= MIN_PATCH + AREA_EPS) continue;
    if (p.max[2] <= zMin + NEAR_BED) continue;
    badOverhangArea += p.area;
}
const violation = badOverhangArea + badBridgeArea;
const ok = violation <= MAX_OVERHANG + AREA_EPS;

const largest = bridgePatches[0];
console.log(`tris=${n} down=${downArea.toFixed(1)}mm2 bed=${bedArea.toFixed(1)}mm2 ` +
    `bridge=${bridgeArea.toFixed(1)}mm2 bridgePatches=${bridgePatches.length}` +
    (largest ? ` largestBridge=${largest.area.toFixed(1)}mm2@${bbox(largest)}` : '') +
    ` overhang=${overhangArea.toFixed(1)}mm2 floating=${floatingArea.toFixed(1)}mm2 ` +
    `violation=${violation.toFixed(1)}mm2 threshold=${THRESHOLD}deg ` +
    `maxBridge=${MAX_BRIDGE}mm2 ${ok ? 'PRINTABLE' : 'OVERHANG-FAIL'}`);

if (SHOW_PATCHES) {
    for (const p of bridgePatches.slice(0, 12))
        console.log(`  bridge   area=${p.area.toFixed(1)}mm2 tris=${p.tris} ` +
            `bbox=${bbox(p)} size=[${p.max.map((x, k) => (x - p.min[k]).toFixed(1))}]` +
            (p.area > MAX_BRIDGE + AREA_EPS ? ' EXCEEDS-MAX-BRIDGE' : ''));
    for (const p of overhangPatches.slice(0, 12)) {
        const excused = p.area <= MIN_PATCH + AREA_EPS ? ' (under min-patch)'
            : p.max[2] <= zMin + NEAR_BED ? ' (near bed)' : '';
        console.log(`  overhang area=${p.area.toFixed(1)}mm2 tris=${p.tris} ` +
            `maxTilt=${p.maxTilt.toFixed(1)}deg bbox=${bbox(p)} ` +
            `size=[${p.max.map((x, k) => (x - p.min[k]).toFixed(1))}]${excused}`);
    }
}

process.exit(ok ? 0 : 1);
