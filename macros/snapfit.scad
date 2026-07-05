// snapfit.scad - Shared snap-fit primitives
//
// Usage: use <../macros/snapfit.scad>
//   (from the designs/ directory)
//
// Two families of snap features:
//
// 1. snap_ridge() - an annular ridge for round shafts. Union it onto a
//    shaft of diameter d; the ridge stands proud by `bite` per side with
//    lead-in cones on BOTH faces so the shaft can be pushed through a
//    bore in either direction and then grips it.
//
//    Interference semantics: against a bore of diameter `bore_d`, the
//    radial interference per side is (d + 2*bite - bore_d) / 2. For a
//    printed snap choose 0.1-0.4 mm total diametral interference
//    (i.e. bore_d = d + 2*bite - 0.1..0.4) plus a flex slot in one part.
//    bite <= 0 would be a no-op ridge - it asserts instead.
//
// 2. cantilever_hook() / cantilever_window() - a matching cantilever
//    snap latch pair. Both are driven by the SAME parameters (arm_w,
//    barb_h, clearance) so hook and window cannot drift apart.
//
//    Hook local frame: the arm root is at z=0, the arm extends up +z
//    (length arm_l), spans x in [-arm_w/2, arm_w/2], and its body spans
//    y in [0, arm_t]. The barb protrudes from the y=arm_t face (toward
//    +y) by `bump`, occupying the top barb_h of the arm. The face from
//    the barb tip up to the arm tip is the insertion ramp; the lower
//    barb face is the retention ledge, raked back by ledge_angle
//    (0 = permanent snap, 30-45 deg = re-openable).
//
//    Window local frame: a CUTTER meant to be subtracted from a wall,
//    oriented like the hook's frame. x is centered, the wall is assumed
//    to span y in [0, wall_t] (the cutter overshoots both faces), z=0
//    is the CATCH EDGE (the opening edge on the hook-root side), and
//    the opening extends UP to z = +window_height() - i.e. toward the
//    hook tip, where the barb lies. If the hook arrives inverted (e.g.
//    folded over a hinge), flip the cutter to match.
//
//    Alignment/engagement semantics: place the parts so that
//      - the hook's barb face (y = arm_t plane) sits `face_gap` OUTSIDE
//        the wall outer face (a small sliding clearance, ~0.3);
//      - the hook's ledge plane, z = arm_l - barb_h in hook frame
//        (= hook_ledge_z()), sits `engage_gap` (~0.1-0.2) PAST the
//        window catch edge in the insertion direction (so the barb sits
//        fully inside the opening with the ledge just clear of the edge).
//    Then the barb reaches (bump - face_gap) through the wall face into
//    the window - that is the retention engagement; choose
//    bump >= face_gap + 0.6 for a positive snap. The window opening is
//    oversized by `clearance` on each side (width) and by 2*clearance
//    (height), so a hook seated per the above touches nothing until it
//    is pulled back (toward its root) by more than engage_gap, at which
//    point the ledge catches the wall at the catch edge.

// ---- snap_ridge ----------------------------------------------------

// Ridge outer diameter for a given shaft d and bite
function snap_ridge_od(d, bite) = d + 2 * bite;

// Chamfered annular ridge for a shaft of diameter d.
// d:    shaft diameter the ridge sits on (ridge base diameter)
// bite: radial protrusion per side (ridge OD = d + 2*bite)
// h:    total ridge height along the shaft axis (z, from z=0 up)
// land_frac: fraction of h that is full-diameter land (rest is the two
//            lead-in cones, split equally top and bottom)
module snap_ridge(d, bite, h, land_frac = 0.3) {
    assert(bite > 0, str("snap_ridge: bite must be > 0 (got ", bite,
                         "); a flush ridge retains nothing"));
    assert(h > 0, "snap_ridge: h must be > 0");
    lf = min(max(land_frac, 0.05), 0.9);
    lead = h * (1 - lf) / 2;
    od = snap_ridge_od(d, bite);
    union() {
        cylinder(d1 = d, d2 = od, h = lead);
        translate([0, 0, lead])
            cylinder(d = od, h = h * lf);
        translate([0, 0, lead + h * lf])
            cylinder(d1 = od, d2 = d, h = lead);
    }
}

// ---- cantilever hook / window pair ---------------------------------

// z of the retention ledge plane in the hook's local frame
function hook_ledge_z(arm_l, barb_h) = arm_l - barb_h;

// Opening sizes the window cutter will produce
function window_width(arm_w, clearance = 0.3) = arm_w + 2 * clearance;
function window_height(barb_h, clearance = 0.3) = barb_h + 2 * clearance;

// Cantilever snap hook (see frame/engagement notes at top of file).
// arm_l:  arm length from root (z=0) to tip
// arm_w:  arm width (x)
// arm_t:  arm thickness (y) - this is the flexing dimension
// bump:   barb protrusion beyond the y=arm_t face
// barb_h: barb height along z (top barb_h of the arm)
// ledge_angle: rake of the retention ledge from horizontal, degrees
//              (0 = square permanent snap; 30-45 = releasable)
module cantilever_hook(arm_l, arm_w, arm_t, bump, barb_h, ledge_angle = 35) {
    assert(arm_l > barb_h,
           str("cantilever_hook: arm_l (", arm_l,
               ") must exceed barb_h (", barb_h, ")"));
    assert(bump > 0 && barb_h > bump * tan(ledge_angle) + 0.2,
           str("cantilever_hook: barb_h (", barb_h,
               ") too small for bump ", bump, " at ledge_angle ",
               ledge_angle, " - no ramp left"));
    // Arm
    translate([-arm_w / 2, 0, 0])
        cube([arm_w, arm_t, arm_l]);
    // Barb: profile in the y-z plane, extruded across the arm width.
    // Sunk 0.2 into the arm face so the union is a real overlap.
    ledge_z = hook_ledge_z(arm_l, barb_h);
    rotate([90, 0, 90])
        translate([0, 0, -arm_w / 2])
            linear_extrude(height = arm_w)
                polygon([
                    [arm_t - 0.2, ledge_z],                       // in arm
                    [arm_t + bump, ledge_z + bump * tan(ledge_angle)], // barb tip
                    [arm_t - 0.2, arm_l]                          // ramp end
                ]);
}

// Matching window CUTTER (subtract from the wall the hook latches into).
// arm_w, barb_h: same values as the hook
// wall_t: thickness of the wall being cut (cutter overshoots 0.4 each face)
// clearance: opening oversize per side vs the barb (default 0.3)
module cantilever_window(arm_w, barb_h, wall_t, clearance = 0.3) {
    w = window_width(arm_w, clearance);
    h = window_height(barb_h, clearance);
    translate([-w / 2, -0.4, 0])
        cube([w, wall_t + 0.8, h]);
}
