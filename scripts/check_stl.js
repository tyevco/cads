#!/usr/bin/env node
// check_stl.js - Validate a binary STL file.
//
// Reports: triangle count, degenerate triangles, watertightness
// (every edge shared by exactly 2 triangles), connected components
// (bodies), and enclosed volume.
//
// Usage: node scripts/check_stl.js file.stl [--expect-bodies N]
// Exit code 1 if the mesh is not clean (or body count mismatches).

const fs = require('fs');

const file = process.argv[2];
if (!file) {
    console.error('usage: node check_stl.js file.stl [--expect-bodies N]');
    process.exit(2);
}
const expectIdx = process.argv.indexOf('--expect-bodies');
const expectBodies = expectIdx > 0 ? parseInt(process.argv[expectIdx + 1], 10) : null;

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

const edges = new Map();
const vmap = new Map();
const parent = [];
const find = x => { while (parent[x] !== x) { parent[x] = parent[parent[x]]; x = parent[x]; } return x; };
const uni = (a, b) => { a = find(a); b = find(b); if (a !== b) parent[a] = b; };
const key = (a, b) => a < b ? `${a}|${b}` : `${b}|${a}`;

let degenerate = 0;
let volume = 0;
const triRoot = [];

for (let i = 0; i < n; i++) {
    const o = 84 + i * 50 + 12;
    const v = [];
    const ids = [];
    for (let j = 0; j < 3; j++) {
        const p = [buf.readFloatLE(o + j*12), buf.readFloatLE(o + j*12 + 4), buf.readFloatLE(o + j*12 + 8)];
        v.push(p);
        const k = p.join(',');
        if (!vmap.has(k)) { vmap.set(k, parent.length); parent.push(parent.length); }
        ids.push(vmap.get(k));
    }
    const [a, b, c] = v;
    volume += (a[0]*(b[1]*c[2]-b[2]*c[1]) - a[1]*(b[0]*c[2]-b[2]*c[0]) + a[2]*(b[0]*c[1]-b[1]*c[0])) / 6;
    if (ids[0] === ids[1] || ids[1] === ids[2] || ids[0] === ids[2]) { degenerate++; triRoot.push(-1); continue; }
    uni(ids[0], ids[1]); uni(ids[1], ids[2]);
    triRoot.push(ids[0]);
    for (const [x, y] of [[0, 1], [1, 2], [2, 0]]) {
        const k = key(ids[x], ids[y]);
        edges.set(k, (edges.get(k) || 0) + 1);
    }
}

let open = 0, over = 0;
for (const c of edges.values()) { if (c === 1) open++; else if (c > 2) over++; }

const roots = new Set();
for (const r of triRoot) if (r >= 0) roots.add(find(r));
const bodies = roots.size;

const clean = open === 0 && over === 0 && degenerate === 0;
const bodiesOk = expectBodies === null || bodies === expectBodies;
console.log(`tris=${n} degenerate=${degenerate} openEdges=${open} overusedEdges=${over} ` +
    `bodies=${bodies} volume=${Math.abs(volume).toFixed(1)}mm3 ` +
    `${clean ? 'WATERTIGHT' : 'NOT-MANIFOLD'}${bodiesOk ? '' : ` (expected ${expectBodies} bodies)`}`);
process.exit(clean && bodiesOk ? 0 : 1);
