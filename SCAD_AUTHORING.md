# OpenSCAD Authoring Guide

How to create design files for this repo that are **manifold** (clean,
watertight, printable meshes) and **functional** (parts that actually fit,
move, and assemble as claimed). Every rule below corresponds to a real
defect class that has been found and fixed in this repo — none of this is
theoretical.

The audit tooling referenced throughout lives in `scripts/`:

```bash
./scripts/audit_designs.sh              # render + validate every design/mode
./scripts/audit_designs.sh gear_fidget  # just one design
node scripts/check_stl.js out.stl       # watertight / bodies / volume check
```

---

## 1. Repo conventions

Every file in `designs/*.scad` must have:

- **Frontmatter** — the first comment lines feed `generate_manifest.sh`:
  ```
  // @name Human Readable Name
  // @description One sentence. Shown on the gallery card.
  // @tags comma, separated, tags
  ```
- **Display modes** — a `_display_mode` variable listing every renderable
  view, and a dispatch at the bottom of the file that implements *exactly*
  that list:
  ```
  _display_mode = "both"; // ["both", "housing", "drawer", "assembled"]
  ```
  CI renders one STL per listed mode. Conventions: the first mode is the
  default gallery view; a print-layout mode shows every part in its print
  orientation, on the plate, not overlapping; an `assembled` mode shows the
  parts in their real assembled positions.
- **Customizer comments** — `// [min:step:max]` for sliders,
  `// ["a", "b"]` for dropdowns, and a human description in the comment
  line *above* the parameter (the web editor shows it as the label).
  The default value must be **on the step grid**: `10` is invalid for
  `[7:2:16]` (7, 9, 11, 13, 15).
- Prefix internal/derived variables with `_` — they are hidden from the
  parameter panel and the manifest.
- Shared modules live in `macros/shapes.scad`, imported with
  `use <../macros/shapes.scad>`. Remember `use` imports **modules and
  functions only** — never rely on another file's top-level variables.

## 2. Manifold-safe modeling

The mesh must be watertight, with no degenerate faces, no self-intersection,
and no accidental extra bodies. The recurring traps:

- **Overshoot every cut.** A `difference()` whose cutter face lies exactly
  on the parent's surface produces coincident faces — the classic
  "not a valid 2-manifold" warning. Extend cutters past every surface they
  should breach: start holes at `z = -0.1` and make them `h + 0.2` long.
- **Cuts must reach a surface.** A cutter fully *inside* the solid creates a
  sealed internal void: an invisible feature, an extra mesh body, and wasted
  print volume. (This repo once had a "tongue slot" nobody could see.) After
  modeling a cut, ask: through which face does this open?
- **Exact face-on-face contact between unioned parts** is usually merged
  fine, but *edge-on-edge* or tangent contact creates non-manifold edges.
  In display/assembled modes, separate independent parts by a small epsilon
  (0.05mm) instead of placing them in exact contact.
- **No zero-size geometry.** `cube([0, y, z])`, `circle(r=0)`, and a
  `minkowski()` over a degenerate operand all warn or corrupt CSG. When a
  loop generates conditional geometry, guard with `if` rather than emitting
  a zero-dimension shape. Clamp computed radii/thicknesses:
  `r = max(computed, 0.5)`.
- **`mirror([0,0,0])` is a silent no-op** (a degenerate mirror). The
  `for (side = [0, 1]) mirror([side, 0, 0])` pattern is broken for
  `side = 0`; write the two placements explicitly or use `side = [-1, 1]`
  with real math.
- **Variables are bindings, not mutable state.** An assignment inside a
  `for` loop does not persist between iterations. For cumulative values
  (running x-offset in a print layout, stacked heights), write a recursive
  function:
  ```
  function row_x(i) = i <= 0 ? 0 : row_x(i - 1) + width(i - 1) + width(i) + gap;
  ```
- **Rotation direction matters.** `rotate([90,0,0])` maps +z to **-y**;
  `rotate([-90,0,0])` maps +z to **+y**. Getting this backwards points
  extrusions and socket openings the wrong way (a handle cutout in this repo
  once extruded *away* from the drawer it was meant to cut). When unsure,
  render the piece alone and look at it.
- **`assert()` your envelope.** Any parameter combination reachable from the
  declared Customizer ranges must either produce valid geometry or fail
  loudly with an actionable message:
  ```
  assert(_radius_step >= wall + clearance,
      str("Cups will not nest: step ", _radius_step, " < ", wall + clearance));
  ```

## 3. Functional design (parts that actually work)

A model can be perfectly manifold and still be a non-functional part. For
every mechanical claim in the header comment, the geometry must deliver it:

- **Clearance direction.** Holes get *bigger* by the clearance, shafts get
  *smaller*. Derive both sides of a fit from the same parameters so they
  cannot drift apart:
  `bore = d + clearance`, `pin = d - clearance` — never two independent
  magic numbers.
- **Mating features must be geometrically compatible.** A cap must pass
  over everything between it and its seat; a ball's socket opening must be
  smaller than the ball (retention) yet admit the neck (articulation); a
  dovetail must be *wide at the tip* and oriented so the taper locks the
  actual pull-apart direction, and its slot must be at least as deep as the
  tab protrudes. Trace the full assembly sequence step by step: "slide body
  onto axle — can it pass the ridge? Now push the cap on — what does it hit?"
- **Retention needs interference; sliding needs clearance.** A "snap ridge"
  whose diameter equals the bore is a no-op. Decide which fits are press/snap
  (0.1-0.4mm interference + lead-in chamfers + flex slots) and which are
  running fits (0.2-0.5mm clearance), and verify each numerically.
- **Print-in-place joints**: surround the moving part with a uniform gap
  (0.3-0.4mm at 0.2mm layers), keep at least 1.2mm of wall around every
  socket (clamp your taper functions so extreme parameters can't thin the
  walls to zero), and place chained pieces at the *exact* pitch where ball
  and socket centers coincide.
- **Every part printable as laid out.** In the print-layout mode: nothing
  below z=0, every part resting on the plate on a flat face, no overhang
  steeper than 45 degrees without an explicit support callout in the header.
  Domes and spheres dip below their equator — clip them. If a part has no
  good orientation, *change the part* (add a 45-degree transition cone,
  split it, or move a flange).
- **Layouts never overlap.** Space parts by *cumulative* sums of their
  actual sizes (recursive function), not by `i * constant` — tapered or
  mixed-size parts will collide otherwise.
- **Standards are numbers, not vibes.** Gridfinity: 42mm pitch, magnets at
  26mm spacing (13mm from cell center), 6x2mm pockets that need a real floor
  beneath them. Gears: center distance = (t1+t2)*module/2; a driven gear
  needs both the ratio rotation *and* a meshing phase offset; non-involute
  (trapezoidal) teeth need extra backlash because straight flanks are not
  conjugate. Look the standard up; don't eyeball it.
- **A parameter that changes nothing is a bug.** Either wire it up or
  delete it. Same for dead modules — they rot and mislead.

## 4. Verify by rendering, not by reading

Reading the code is not verification. OpenSCAD is on CI and the audit
scripts make real checks cheap:

1. **Render every mode** and check the mesh:
   ```bash
   ./scripts/audit_designs.sh my_design
   ```
   Zero warnings, watertight, and the expected number of bodies (e.g. a
   12-piece print-in-place chain should report `bodies=12`; 13 means a
   stray sliver, 11 means two parts fused).

2. **Prove clearances with boolean intersections.** For any two parts that
   must not touch, render their intersection — an empty result is proof:
   ```scad
   // test_fit.scad
   use <../designs/my_design.scad>
   intersection() {
       part_a();
       translate(assembled_offset) part_b();
   }
   ```
   ```bash
   openscad -o int.stl --export-format binstl test_fit.scad
   node scripts/check_stl.js int.stl   # volume=0 (or file empty) = no contact
   ```
   Expose positions/counts as functions (e.g. `function gear_position(i)`)
   so the test harness reuses the design's own math instead of duplicating it.

3. **Prove retention with a pull test.** Translate the captured part toward
   its escape direction by more than the clearance and intersect again — a
   *non-zero* volume proves it collides with the retaining wall:
   ```scad
   intersection() {
       segment_with_socket();
       translate([0, pull_distance, 0]) sphere(d=ball_diameter);
   }
   ```

4. **Sweep moving mechanisms.** One good position proves nothing for a
   mechanism. Sweep the drive angle across a full tooth pitch (or the
   drawer across its travel) and check the intersection at each sample.

5. **Test the parameter envelope.** Render at the extremes of the declared
   ranges and with each boolean toggled. Anything that breaks needs a clamp
   or an `assert`.

6. **`-D` override trap:** `-D var=value` appends the assignment at the end
   of the file and overrides `var` everywhere — but a *derived* variable you
   also `-D`-override won't re-derive its dependents. Override the base
   parameters, not derived values, and don't reuse a stale output STL after
   a failed render (delete outputs first; a failed render leaves the old
   file in place).

## 5. Keep renders fast

CI renders every mode of every design with CGAL; the web editor renders in
WASM (slower still). Budget roughly: a mode should render in well under a
minute; the whole repo audit in a few minutes.

- **Sphere/cylinder count dominates.** A decorative pattern of 20+ spheres
  per segment across 12 segments once pushed a render past 8 minutes.
  Give small decorative geometry a low local resolution (`$fn=16`) instead
  of inheriting the file default; keep the file default `$fn` at 40-80.
- `minkowski()` and `hull()` on high-`$fn` operands are the most expensive
  operations; prefer `offset()` in 2D before extruding.
- Decorative details that a viewer can't see (buried voids, sub-0.3mm
  texture) cost render time and print nothing — delete them.

## 6. Pre-merge checklist

- [ ] Frontmatter present; `_display_mode` list matches the dispatch exactly
- [ ] All customizer defaults inside their ranges and on the step grid
- [ ] No unused parameters, no dead modules
- [ ] `./scripts/audit_designs.sh <design>`: every mode OK, watertight,
      expected body count, no warnings
- [ ] Intersection tests: mating clearances empty, retention pull tests
      non-empty, mechanisms swept across their motion
- [ ] Print layout: nothing below the plate, flat contact faces, overhangs
      self-supporting, parts don't overlap
- [ ] Extreme parameter combos render or `assert` with a clear message
- [ ] Header comments describe what the geometry actually does (piece
      count, assembly steps, support requirements)
