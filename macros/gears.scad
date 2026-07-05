// gears.scad - Shared spur gear library
//
// Usage: use <../macros/gears.scad>
//   (from the designs/ directory)
//
// Simplified trapezoidal tooth profile, verified to mesh (intersection
// sweep over a full tooth pitch) in gear_fidget.scad. Within each tooth
// pitch (local_t in 0..1): root 0-0.15, rising flank 0.15-0.3, tip
// 0.3-0.55, falling flank 0.55-0.7, root 0.7-1. So the tooth center sits
// at 0.425 and the gap center at 0.925 of the pitch - the meshing phase
// functions below depend on these constants and are only valid for this
// profile.
//
// The straight flanks are not conjugate (not involute), so meshing pairs
// need real backlash: 0.5mm verified collision-free at gear_module 2.5.

// Pitch radius for a gear
function gear_pitch_radius(teeth, gear_module) = teeth * gear_module / 2;

// Center distance between two externally meshing gears
function gear_center_distance(t1, t2, gear_module) =
    (t1 + t2) * gear_module / 2;

// Center distance between a pinion and an internal (ring) gear
function gear_ring_center_distance(t_ring, t_pinion, gear_module) =
    (t_ring - t_pinion) * gear_module / 2;

// Rotation of a gear driven through an EXTERNAL mesh:
//   rd = driver rotation (deg), td/tg = driver/driven tooth counts,
//   a  = angle of the line from driver center to driven center (deg).
// The rolling term is -(rd - a) * td/tg; the phase terms put a driven-gear
// GAP center on the mesh line exactly when a driver TOOTH center is on it.
function gear_mesh_rotation(rd, td, tg, a) =
    -(rd - a) * td / tg + a + 180 - 180 / tg;

// Rotation of a RING (internal) gear driven by a pinion, or vice versa.
// Internal meshes roll in the SAME direction. rd = pinion rotation,
// tp = pinion teeth, tr = ring teeth, a = angle of the line from ring
// center to pinion center (deg). The ring's tooth gaps are cuts left by
// a same-profile cutter, so a pinion TOOTH center on the mesh line must
// meet a ring CUTTER-TOOTH center there.
function gear_ring_mesh_rotation(rd, tp, tr, a) =
    (rd - a) * tp / tr + a;

// 2D spur gear profile with backlash applied (tooth thinning + tip
// rounding via offset). points_per_tooth controls polygon resolution.
module gear_spur_2d(teeth, gear_module, backlash=0.5, points_per_tooth=8) {
    pitch_r = gear_pitch_radius(teeth, gear_module);
    outer_r = pitch_r + gear_module * 0.9;
    root_r = pitch_r - gear_module * 1.1;
    tooth_arc = 360 / teeth;
    total_points = teeth * points_per_tooth;

    offset(r=-backlash/2)
        polygon([
            for (t = [0:total_points-1])
                let(
                    tooth_idx = floor(t / points_per_tooth),
                    local_t = (t % points_per_tooth) / points_per_tooth,
                    base_angle = tooth_idx * tooth_arc,
                    r = (local_t < 0.15) ? root_r :
                        (local_t < 0.3) ? root_r + (outer_r - root_r) * (local_t - 0.15) / 0.15 :
                        (local_t < 0.55) ? outer_r :
                        (local_t < 0.7) ? outer_r - (outer_r - root_r) * (local_t - 0.55) / 0.15 :
                        root_r,
                    angle = base_angle + local_t * tooth_arc
                )
                [r * cos(angle), r * sin(angle)]
        ]);
}

// 2D internal (ring) gear: an annulus with inward-facing teeth, cut by
// the same profile ENLARGED by the backlash so the meshing pinion has
// running clearance. rim = radial thickness of the solid ring outside
// the tooth tips.
module gear_ring_2d(teeth, gear_module, backlash=0.5, rim=4, points_per_tooth=8) {
    pitch_r = gear_pitch_radius(teeth, gear_module);
    outer_r = pitch_r + gear_module * 0.9;

    difference() {
        circle(r=outer_r + rim);
        // Cutter: the spur profile grown by backlash/2 (negative backlash
        // on the spur module = positive offset)
        offset(r=backlash/2)
            gear_spur_2d(teeth, gear_module, backlash=0, points_per_tooth=points_per_tooth);
    }
}
