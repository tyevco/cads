// flexures.scad - Compliant-mechanism primitives (leaf springs, living
// hinges, flat spiral power springs) plus the beam-mechanics helper
// functions used to size them safely.
//
// Usage: use <../macros/flexures.scad>
//   (from the designs/ directory)
//
// ---- Mechanics assumptions (read before trusting the numbers) -------
//
// All helpers use linear-elastic Euler-Bernoulli beam theory with a
// rectangular cross-section (width w, thickness t; the beam flexes
// about the t direction, I = w*t^3/12). Assumptions:
//
//  - Small-to-moderate deflections (tip deflection up to ~15% of the
//    beam length; beyond that the linear formulas overestimate stroke
//    by a growing margin).
//  - Material behaves elastically up to a working strain eps_max.
//    Printed PLA yields at roughly 1.5-2.5% strain, but for a spring
//    that must survive repeated cycles, creep, and layer-adhesion
//    anisotropy, size to eps_max = 0.5-1% (default 0.008 = 0.8%).
//    Print springs with the flex plane IN the layer plane (bands
//    extruded in z, flexing in x/y) - flexing across layer lines
//    fails far earlier than these numbers.
//  - Young's modulus for printed PLA: E ~ 2400 MPa (2000-3500
//    depending on print settings). Only force/torque estimates depend
//    on E; the *stroke* limits depend on strain alone, which is why
//    they are the reliable ones.
//
// Key result encoded below: a cantilever of flexible length l and
// thickness t loaded by a tip force reaches root strain eps at tip
// deflection
//     delta = (2/3) * eps * l^2 / t
// (from delta = F*l^3/(3EI) and eps = F*l*t/(2EI)). flex_stroke()
// generalizes this to a flexure with a RIGID lever extension of length
// `lever` beyond the flexible part (force applied at the lever end):
//     M_root = F*(l+lever),  eps = M_root*t/(2EI)
//     delta_load = F*(l^3/3 + l^2*lever + l*lever^2)/(EI)
//  => delta_max = 2*eps*l*(l^2/3 + l*lever + lever^2)/(t*(l+lever))
// which reduces to (2/3)*eps*l^2/t at lever=0. For a CURVED leaf of
// the same developed length, the tip-force cantilever formula is
// conservative (a curved band carries a more uniform moment, so it
// yields slightly MORE stroke at the same peak strain) - safe to use.

// ---- Sizing functions ------------------------------------------------

// Max safe tip deflection (mm) of a cantilever flexure before the root
// strain reaches eps_max. l = flexible length, t = thickness (both mm),
// lever = rigid extension beyond the flexure at whose end the load acts.
function flex_stroke(l, t, eps_max = 0.008, lever = 0) =
    2 * eps_max * l * (l * l / 3 + l * lever + lever * lever)
        / (t * (l + lever));

// Minimum flexible length (mm) for a required tip stroke at eps_max
// (inverse of flex_stroke with lever = 0).
function flex_min_length(stroke, t, eps_max = 0.008) =
    sqrt(1.5 * stroke * t / eps_max);

// Tip force (N) to deflect a straight cantilever by `deflection` mm.
// e_mod in MPa (N/mm^2); result only as good as E (+-40% for prints).
function flex_force(deflection, l, w, t, e_mod = 2400) =
    3 * e_mod * (w * pow(t, 3) / 12) * deflection / pow(l, 3);

// ---- Leaf spring geometry helpers -----------------------------------

// Circular-arc radius for a chord l and sagitta (mid-rise) arc
function leaf_radius(l, arc) = (arc * arc + l * l / 4) / (2 * arc);

// Developed (flexible) length of leaf_spring(l, ..., arc): the arc
// length for a curved leaf, or l for a straight one. Use THIS as the
// flexible length in flex_stroke().
function leaf_length(l, arc = 0) =
    arc <= 0 ? l
             : let (r = leaf_radius(l, arc))
               2 * r * asin(min(l / (2 * r), 1)) * PI / 180;

// Straight or curved leaf spring. Local frame: the band runs from
// (0,0,0) to (l,0,0) (chord along +x), thickness t centered on the
// path in y, extruded `w` up +z (w is the printed band height - keep
// the flex plane in xy so the spring bends within print layers).
// arc = sagitta: 0 for a straight band, up to l/2 (a semicircle)
// bulging toward +y. Weld the ends into rigid bodies by overlapping
// them; the ends are cut square to the arc.
module leaf_spring(l, w, t, arc = 0, segments = 48) {
    assert(l > 0 && w > 0, "leaf_spring: l and w must be > 0");
    assert(t >= 0.4, str("leaf_spring: band thickness ", t,
                         "mm is below the 0.4mm printable minimum"));
    assert(arc >= 0 && arc <= l / 2 + 1e-9,
           str("leaf_spring: arc (sagitta) must be in [0, l/2]; got ",
               arc, " for l ", l));
    if (arc < 0.01) {
        translate([0, -t / 2, 0]) cube([l, t, w]);
    } else {
        r = leaf_radius(l, arc);
        c = [l / 2, arc - r];
        a0 = atan2(r - arc, -l / 2);  // angle of the (0,0) end
        a1 = atan2(r - arc, l / 2);   // angle of the (l,0) end
        outer = [for (i = [0 : segments])
            let (a = a0 + (a1 - a0) * i / segments)
                c + (r + t / 2) * [cos(a), sin(a)]];
        inner = [for (i = [segments : -1 : 0])
            let (a = a0 + (a1 - a0) * i / segments)
                c + (r - t / 2) * [cos(a), sin(a)]];
        linear_extrude(w) polygon(concat(outer, inner));
    }
}

// ---- Living hinge -----------------------------------------------------

// Rough elastic bend capacity (degrees) of a living_hinge panel folded
// about the slit (y) axis. Each slit column contributes links of
// length slit_w that bend about y; per-column angle at strain eps is
// 2*eps*slit_w/t. This is an ORDER-OF-MAGNITUDE estimate (+-50%):
// real slit hinges concentrate strain at the link roots. PLA living
// hinges are for SMALL angles or few cycles - use polypropylene for a
// true 180-degree production hinge.
function living_hinge_max_bend_deg(n_slits, slit_w, t, eps_max = 0.008) =
    n_slits * 2 * eps_max * slit_w / t * 180 / PI;

// Slit-pattern living hinge panel: a plate spanning [0,l] x [0,w],
// thickness t (extruded +z), with n_slits staggered slit columns cut
// through it. The panel folds about the y axis, distributed across the
// columns. Even columns hold one interior slit (webs at both y edges);
// odd columns hold two edge-open slits (web at the y center) - the
// classic lasercut stagger, so no straight uncut line crosses the
// hinge. All slits cut through both faces (no sealed voids).
// slit_w >= 0.8 so FDM can actually print the gaps.
module living_hinge(l, w, t, n_slits, slit_w = 1.2, web = 3) {
    pitch = l / (n_slits + 1);
    rib = pitch - slit_w;
    assert(n_slits >= 1, "living_hinge: n_slits must be >= 1");
    assert(slit_w >= 0.8, str("living_hinge: slit_w ", slit_w,
                              "mm is below the 0.8mm printable gap"));
    assert(rib >= 0.8, str("living_hinge: ribs between slit columns are ",
                           rib, "mm; need >= 0.8 - fewer slits or longer l"));
    assert(w > 3 * web, str("living_hinge: panel width ", w,
                            " too narrow for web ", web,
                            " (need w > 3*web)"));
    assert(t >= 0.4, "living_hinge: t below printable minimum 0.4");
    difference() {
        cube([l, w, t]);
        for (i = [0 : n_slits - 1]) {
            x = pitch * (i + 1) - slit_w / 2;
            if (i % 2 == 0) {
                // interior slit, webs at both edges
                translate([x, web, -0.1])
                    cube([slit_w, w - 2 * web, t + 0.2]);
            } else {
                // two edge-open slits, web at center
                translate([x, -0.1, -0.1])
                    cube([slit_w, (w - web) / 2 + 0.1, t + 0.2]);
                translate([x, (w + web) / 2, -0.1])
                    cube([slit_w, (w - web) / 2 + 0.1, t + 0.2]);
            }
        }
    }
}

// ---- Flat spiral power spring ----------------------------------------
//
// Archimedean spiral band, built as a single 2D polygon (NOT a twisted
// extrude) and extruded to height h. Interpretation of od/id: the band
// CENTERLINE runs from radius id/2 + t/2 (inner end, at angle 0, +x)
// out to od/2 - t/2 (outer end, at angle turns*360), so the innermost
// band surface sits at id/2 and the outermost at od/2.
//
// Winding mechanics (document + estimate, not proof):
//  - Band length L = pi * turns * (od + id) / 2   (mean circumference
//    x turns; exact for the centerline defined above).
//  - Winding the arbor by theta radians adds curvature d_kappa =
//    theta / L uniformly (ideal clamped spiral); peak bending strain
//    eps = t * d_kappa / 2, so the strain-limited windup is
//        theta_max = 2 * eps_max * L / t  [rad]
//    i.e. spiral_windup_turns() = eps_max * L / (pi * t) turns.
//    Printed spirals give roughly 1-2 turns of safe windup - gear UP
//    the output if you need more revolutions.
//  - Torque at windup theta: M = E * I * theta / L with I = h*t^3/12.
//    Depends on E: treat as +-40%.
//  - Geometry must also allow it: winding packs coils inward, so the
//    coil gap must not close. spiral_coil_gap() reports the printed
//    gap; keep it >= t * windup_turns / turns as a rule of thumb.

// Band centerline length (mm)
function spiral_length(od, id, turns) = PI * turns * (od + id) / 2;

// Radial clearance between adjacent coil surfaces as printed (mm)
function spiral_coil_gap(od, id, turns, t) =
    ((od - id) / 2 - t) / turns - t;

// Strain-limited safe windup, in TURNS of the arbor relative to the
// outer anchor
function spiral_windup_turns(od, id, turns, t, eps_max = 0.008) =
    eps_max * spiral_length(od, id, turns) / (PI * t);

// Torque (N*mm) at `windup_turns` of windup; e_mod in MPa
function spiral_torque(od, id, turns, t, h, windup_turns, e_mod = 2400) =
    e_mod * (h * pow(t, 3) / 12) * (windup_turns * 2 * PI)
        / spiral_length(od, id, turns);

// Band centerline endpoints - weld hub/anchor bodies over these
function spiral_inner_end(od, id, turns, t) = [id / 2 + t / 2, 0];
function spiral_outer_end(od, id, turns, t) =
    (od / 2 - t / 2) * [cos(turns * 360), sin(turns * 360)];

// The spiral band itself, centered on the origin, base on z=0.
module spiral_spring(od, id, turns, t, h, steps_per_turn = 72) {
    r_i = id / 2 + t / 2;
    r_o = od / 2 - t / 2;
    gap = spiral_coil_gap(od, id, turns, t);
    assert(t >= 0.8, str("spiral_spring: band t ", t,
                         "mm is too thin to print reliably (need >= 0.8)"));
    assert(h >= 1, "spiral_spring: band height h must be >= 1mm");
    assert(turns >= 1, "spiral_spring: need at least 1 turn");
    assert(r_o > r_i, str("spiral_spring: od ", od, " too small for id ",
                          id, " and band t ", t));
    assert(gap >= 0.3,
           str("spiral_spring: coil gap ", gap, "mm would fuse when ",
               "printed (need >= 0.3): fewer turns, thinner band, or ",
               "larger od"));
    n = ceil(turns * steps_per_turn);
    a_end = turns * 360;
    outer = [for (i = [0 : n])
        let (a = a_end * i / n,
             r = r_i + (r_o - r_i) * i / n + t / 2)
            r * [cos(a), sin(a)]];
    inner = [for (i = [n : -1 : 0])
        let (a = a_end * i / n,
             r = r_i + (r_o - r_i) * i / n - t / 2)
            r * [cos(a), sin(a)]];
    linear_extrude(h) polygon(concat(outer, inner));
}
