---
name: scad-debug
description: Diagnose and debug OpenSCAD design output - render errors/warnings/timeouts, non-manifold or empty meshes, wrong body counts, invisible features, parts that don't fit or retain, and slow renders. Use whenever a designs/*.scad file misbehaves or a design change needs mechanical verification before claiming it works.
---

# Debugging OpenSCAD output

You are diagnosing a `.scad` design in this repo. Work from evidence
(rendered meshes, measured volumes), never from reading the code alone.
`SCAD_AUTHORING.md` has the fix patterns; this skill is the diagnostic
procedure. Use a scratch directory for all outputs.

## Step 0 - Reproduce and classify

Render the failing design/mode and keep the full log:

```bash
timeout 480 openscad -o /tmp/scad-dbg/out.stl --export-format binstl \
    -D '_display_mode="<mode>"' designs/<design>.scad 2>&1 | tee /tmp/scad-dbg/out.log
node scripts/check_stl.js /tmp/scad-dbg/out.stl --components
```

Or sweep everything at once: `./scripts/audit_designs.sh [design]`.

Classify the symptom and jump to the matching section:

| Symptom | Section |
|---|---|
| `ERROR:` / `Assertion` in log | 1 |
| `WARNING: ... not a valid 2-manifold`, `openEdges`/`overusedEdges` > 0 | 2 |
| Wrong body count (extra or missing bodies) | 3 |
| Renders clean but geometry is wrong / parts won't fit or retain | 4 |
| Timeout or multi-minute render | 5 |
| Empty output ("Current top level object is empty") | 6 |

**Stale-output trap:** a failed render leaves the previous STL on disk.
Delete outputs before re-rendering, or you will validate the old file.

**`-D` trap:** `-D` overrides append at the end of the file and only
override that variable; derived variables recompute from it, but
overriding a *derived* variable directly does not update its dependents.
Override base parameters only.

## 1 - Errors and assertion failures

Read the first `ERROR:` line; OpenSCAD reports file/line. Typical causes:
undefined variable/module (check `use <>` - it imports modules and
functions but NOT top-level variables), syntax errors, or a repo `assert()`
firing (the message says which constraint broke - fix the parameters or
the geometry, don't delete the assert).

## 2 - Non-manifold mesh

`check_stl.js` distinguishes the failure:

- **openEdges > 0**: holes in the surface - usually a self-intersecting
  polygon (star/gear profiles at extreme parameters) or a degenerate
  `hull()`/`minkowski()` operand.
- **overusedEdges > 0**: an edge shared by >2 triangles - almost always
  exact face-on-face or edge-on-edge contact between parts, or a cutter
  face coincident with the surface it cuts. Find the touching pair, then:
  cutters overshoot by 0.1; separate display-only contacts by 0.05;
  deliberately weld intended fusions by sinking one part 0.05 into the
  other.
- **degenerate > 0**: zero-area triangles - look for zero-size primitives
  (`cube([0,..])`, `circle(r=0)`, `mirror([0,0,0])` no-ops, unclamped
  computed radii).

To localize: bisect. Render sub-modules alone (`-D` a mode that shows one
part, or a scratch harness that calls one module), or comment out halves
of a union/difference until the warning disappears.

## 3 - Wrong body count

Expected bodies = number of physically separate parts in that mode
(a print-in-place chain of N pieces = N bodies; a single part = 1).

```bash
node scripts/check_stl.js out.stl --components --expect-bodies <N>
```

Components are listed smallest-first with bounding boxes:

- **Extra tiny body** (few triangles, small bbox): either a stray sliver
  severed by overlapping cuts, or a **sealed internal void** - a cutter
  that never reaches any surface (a box-shaped 12-triangle body exactly
  the cutter's size is the giveaway). Recut it so it opens through a face.
- **Extra body the size of a real feature**: a part that should be welded
  is only face-touching. Sink it slightly into its neighbor.
- **Too few bodies**: parts fused - print-in-place clearance collapsed to
  zero somewhere, or layout spacing lets parts overlap. Use the bbox list
  to see which expected body is missing, then intersect the two suspects
  (section 4) to find the contact.

## 4 - Mechanical verification (fit, retention, motion)

Geometry that renders clean can still be a non-functional part. Prove
claims with boolean intersections in a scratch harness:

```scad
// /tmp/scad-dbg/test.scad
use </full/path/to/designs/<design>.scad>
_test = "fit"; // select via -D
if (_test == "fit") {
    // Parts that must NOT touch: expect an empty result
    intersection() {
        part_a();
        translate([/* assembled offset */]) part_b();
    }
} else if (_test == "pull") {
    // Retention: displace the captured part past its clearance toward the
    // escape direction; expect a NON-empty result (it hits the wall)
    intersection() {
        socket_part();
        translate([0, 1.2, 0]) sphere(d=ball_d);
    }
}
```

```bash
openscad -o /tmp/scad-dbg/int.stl --export-format binstl -D '_test="fit"' /tmp/scad-dbg/test.scad
node scripts/check_stl.js /tmp/scad-dbg/int.stl   # volume=0 / empty file = no contact
```

Rules of evidence:

- A **clearance fit** is proven by an empty intersection, at the real
  assembled transform, taken from the design's own math - add accessor
  `function`s to the design (e.g. `gear_position(i)`) rather than
  duplicating coordinates in the harness.
- **Retention** is proven by a non-empty intersection under displacement
  (pull test). A snap/press fit should show a small volume at exactly the
  intended interference feature - a large volume means real collision.
- **Mechanisms must be swept**: check the intersection at 7-10 samples
  across the full motion (gear tooth pitch, drawer travel). One good
  position proves nothing.
- Intersection volumes below ~0.01mm³ are numeric slivers; treat as zero.

## 5 - Slow renders and timeouts

Budget: any single mode should render in well under a minute (the snake's
full chain, the repo's heaviest, takes ~2.5min).

```bash
grep "Total rendering time" /tmp/scad-dbg/out.log
```

Find the cost: render each sub-module alone and time it. The usual
culprits, in order: many-sphere decorative patterns inheriting a high
global `$fn` (give tiny geometry a local `$fn=16`), `minkowski()`,
high-`$fn` `hull()`, and unions of hundreds of primitives. Also check the
CGAL cache lines in the log - "Polyhedrons in cache" ballooning means the
tree re-evaluates variants of the same expensive shape. Invisible geometry
(sealed voids, sub-0.3mm detail) costs full price; delete it.

## 6 - Empty output

"Current top level object is empty": the selected `_display_mode` doesn't
match any dispatch branch (check the list against the if/else chain), a
boolean subtracted everything, or an `if` guard is false at these
parameters. Echo the dispatch inputs: `echo(_display_mode, _num_parts);`.

## Wrap up

After any fix, re-run the full check - not just the case you fixed:

```bash
./scripts/audit_designs.sh <design>
```

plus the section-4 harness tests for every mechanical claim the design
makes, at default AND extreme parameter values. Report what you verified
with numbers (volumes, body counts, render times), not adjectives.
