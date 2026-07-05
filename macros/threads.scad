// threads.scad - Coarse printable trapezoidal thread library
//
// Usage (from designs/): use <../macros/threads.scad>
//
// PROFILE
//   Single-start right-hand trapezoidal thread, generated as a twisted
//   linear_extrude of a 2D cross-section: a root circle plus ONE radial
//   trapezoidal lobe. Twist = -360*length/pitch, so the lobe traces a
//   helix with lead = pitch (one turn per pitch of height).
//
//   In the axial (r/z) plane the tooth is a trapezoid with 45-degree
//   flanks (self-supporting for FDM with the thread axis vertical):
//     depth       = depth_ratio * pitch   (radial;  default 0.30*pitch)
//     crest width = crest_ratio * pitch   (axial;   default 0.20*pitch)
//     root width  = crest + 2*depth       (= 0.80*pitch at the defaults)
//
// SIZES
//   d is the MAJOR (crest) diameter of the external thread. The rod core
//   ("root") diameter is thread_root_d(d, pitch) = d - 2*depth.
//
// CLEARANCE SEMANTICS
//   thread_cutout(d, pitch, len, clearance) is the SAME solid grown by
//   `clearance`:
//     - radially everywhere (root circle and crest each +clearance), and
//     - axially on the flanks by min(clearance, remaining root gap), so
//       adjacent turns of the cutter can never fuse into a cylinder.
//   Subtract it from a lid/nut body to get an internal thread that mates
//   with external_thread(d, pitch, ...) leaving `clearance` of radial
//   play (and at least ~0.7*clearance normal to the 45-degree flanks).
//   0.25-0.40 mm suits typical FDM prints. The widest radius the cutter
//   reaches is thread_cutout_max_r(d, clearance); keep at least a full
//   wall beyond it.
//
// ANGULAR PHASE (for assembled views and mate tests)
//   The lobe is centred on angle 0 at the extrusion base (z=0) and at
//   height z above the base it sits at angle +360*z/pitch. Both modules
//   share this phase, so a cutout whose base plane and angle-0 direction
//   coincide with the thread's is exactly centred on it; screwing motion
//   couples translation and rotation as angle = 360*dz/pitch.
//
// SPEED
//   Cost scales with profile points (fn) and slices (slices_per_turn *
//   turns). The defaults (fn=40, slices_per_turn=16) render a 3-turn
//   thread in a few seconds; don't raise them casually.

// ---- Derived-size helper functions ----

// Radial depth of the thread tooth
function thread_depth(pitch, depth_ratio = 0.3) = pitch * depth_ratio;

// Core (root) diameter of an external thread of major diameter d
function thread_root_d(d, pitch, depth_ratio = 0.3) =
    d - 2 * thread_depth(pitch, depth_ratio);

// Faceting compensation applied to the cutter's radii: a twisted
// linear_extrude is chordal both around the profile (fn) and along the
// twist (slices), so its faceted surfaces dip INSIDE the nominal ones
// by up to r*(1-cos(180/fn)) + r*(1-cos(180/slices_per_turn)). For an
// external thread that only shrinks it (safe); for a subtracted cutter
// it would shrink the hole and eat the clearance, so thread_cutout
// pushes its root/crest radii outward by this much - the faceted hole
// is then never tighter than the nominal clearance.
function thread_facet_comp(d, clearance = 0.3,
                           fn = 40, slices_per_turn = 16) =
    (d / 2 + clearance) * ((1 - cos(180 / fn))
                           + (1 - cos(180 / slices_per_turn)));

// Largest radius reached by the internal cutter (size internal walls off this)
function thread_cutout_max_r(d, clearance = 0.3,
                             fn = 40, slices_per_turn = 16) =
    d / 2 + clearance + thread_facet_comp(d, clearance, fn, slices_per_turn);

// Minimum internal bore left by the cutter (its grown root circle)
function thread_bore_d(d, pitch, clearance = 0.3, depth_ratio = 0.3) =
    thread_root_d(d, pitch, depth_ratio) + 2 * clearance;

// Axial flank growth actually applied to the cutter: the requested
// clearance, capped so at least 0.1*pitch of root gap survives between
// adjacent turns of the grown lobe.
function thread_axial_grow(pitch, clearance,
                           crest_ratio = 0.2, depth_ratio = 0.3) =
    max(0, min(clearance,
               (pitch - (crest_ratio + 2 * depth_ratio) * pitch) / 2
                   - 0.05 * pitch));

// ---- 2D cross-section ----
//
// Root circle of radius r_root+grow plus one trapezoidal lobe out to
// r_root+depth+grow, centred on angle 0. Axial tooth widths map to
// angles via angle = 360 * width / pitch. Flanks are sampled along the
// spiral r(theta) so they stay outside the root circle (the angular
// spans here are large - a straight chord would gouge the core).
// radial_comp is added to the root/crest radii only (angular widths
// untouched) - see thread_facet_comp.
module thread_profile(r_root, pitch, crest_w,
                      depth_ratio = 0.3, grow = 0, axial_grow = 0,
                      radial_comp = 0, fn = 40) {
    depth = pitch * depth_ratio;
    rr = r_root + grow + radial_comp; // grown root radius
    rc = r_root + depth + grow + radial_comp; // grown crest radius
    w_crest = crest_w + 2 * axial_grow;
    w_root  = crest_w + 2 * depth + 2 * axial_grow;
    ha_c = 180 * w_crest / pitch;     // crest half-angle
    ha_r = 180 * w_root / pitch;      // root half-angle
    assert(ha_r < 178,
        str("thread tooth root width ", w_root,
            " does not fit in one pitch ", pitch,
            " - reduce depth_ratio/crest_ratio or the clearance"));
    assert(rr > 0.5, str("thread root radius too small: ", rr));

    // flank/crest chords only ever move the surface in the loosening
    // direction, so they get half density
    n_root  = max(8, ceil(fn * (360 - 2 * ha_r) / 360));
    n_flank = max(4, ceil(fn * (ha_r - ha_c) / 720));
    n_crest = max(4, ceil(fn * 2 * ha_c / 720));

    polygon(concat(
        // root arc, CCW the long way round: ha_r .. 360-ha_r
        [for (i = [0 : n_root])
            let (a = ha_r + i * (360 - 2 * ha_r) / n_root)
                [rr * cos(a), rr * sin(a)]],
        // rising flank: spiral from (-ha_r, rr) to (-ha_c, rc)
        [for (i = [1 : n_flank])
            let (t = i / n_flank,
                 a = -ha_r + t * (ha_r - ha_c),
                 r = rr + t * (rc - rr))
                [r * cos(a), r * sin(a)]],
        // crest arc: -ha_c .. +ha_c
        [for (i = [1 : n_crest])
            let (a = -ha_c + i * 2 * ha_c / n_crest)
                [rc * cos(a), rc * sin(a)]],
        // falling flank: spiral from (+ha_c, rc) back toward (+ha_r, rr)
        [for (i = [1 : n_flank - 1])
            let (t = i / n_flank,
                 a = ha_c + t * (ha_r - ha_c),
                 r = rc - t * (rc - rr))
                [r * cos(a), r * sin(a)]]
    ));
}

// ---- Core helical solid (shared by external thread and cutter) ----
module helical_thread(d, pitch, length,
                      grow = 0, axial_grow = 0, radial_comp = 0,
                      crest_ratio = 0.2, depth_ratio = 0.3,
                      fn = 40, slices_per_turn = 16) {
    assert(pitch > 0 && length > 0 && d > 0, "d, pitch, length must be > 0");
    r_root = thread_root_d(d, pitch, depth_ratio) / 2;
    turns = length / pitch;
    linear_extrude(height = length,
                   twist = -360 * turns,
                   slices = max(8, ceil(turns * slices_per_turn)),
                   convexity = 10)
        thread_profile(r_root, pitch, crest_ratio * pitch,
                       depth_ratio, grow, axial_grow, radial_comp, fn);
}

// ---- External thread ----
//
// A threaded rod section from z=0 to z=length, major diameter d.
// The crest fades to the root diameter over `depth` (45 degrees) at
// each end (fade=true), so the end faces are clean discs and the
// thread starts without a snag when a nut is offered up.
module external_thread(d, pitch, length,
                       crest_ratio = 0.2, depth_ratio = 0.3,
                       fade = true, fn = 40, slices_per_turn = 16) {
    depth = thread_depth(pitch, depth_ratio);
    r_root = thread_root_d(d, pitch, depth_ratio) / 2;
    assert(length > 2 * depth + pitch,
        str("thread length ", length, " too short for pitch ", pitch,
            " with end fades (needs > ", 2 * depth + pitch, ")"));
    if (fade) {
        // Envelope margin must exceed the rotate_extrude facet sagitta,
        // or the envelope's flat facets graze the thread crest mid-span
        // and leave non-manifold micro-edges.
        m = 0.06 + (d / 2) * (1 - cos(180 / fn));
        intersection() {
            helical_thread(d, pitch, length,
                           crest_ratio = crest_ratio, depth_ratio = depth_ratio,
                           fn = fn, slices_per_turn = slices_per_turn);
            // envelope: full major diameter mid-span, coning down to just
            // above the root at both ends (45-degree crest fade)
            rotate_extrude(convexity = 4, $fn = fn)
                polygon([[0, -0.01],
                         [r_root + m, -0.01],
                         [d / 2 + m, depth],
                         [d / 2 + m, length - depth],
                         [r_root + m, length + 0.01],
                         [0, length + 0.01]]);
        }
    } else {
        helical_thread(d, pitch, length,
                       crest_ratio = crest_ratio, depth_ratio = depth_ratio,
                       fn = fn, slices_per_turn = slices_per_turn);
    }
}

// ---- Internal thread cutter ----
//
// The matching internal thread as a subtractable cutter: the external
// solid grown by `clearance` (see CLEARANCE SEMANTICS above). Spans
// exactly z=0..length with no end fade - give it extra length and let
// it overshoot the mouth of the part you subtract it from.
module thread_cutout(d, pitch, length, clearance = 0.3,
                     crest_ratio = 0.2, depth_ratio = 0.3,
                     fn = 40, slices_per_turn = 16) {
    helical_thread(d, pitch, length,
                   grow = clearance,
                   axial_grow = thread_axial_grow(pitch, clearance,
                                                  crest_ratio, depth_ratio),
                   radial_comp = thread_facet_comp(d, clearance,
                                                   fn, slices_per_turn),
                   crest_ratio = crest_ratio, depth_ratio = depth_ratio,
                   fn = fn, slices_per_turn = slices_per_turn);
}
