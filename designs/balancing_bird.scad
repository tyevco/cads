// @name Balancing Bird
// @description Center-of-mass toy: a bird that balances on its beak tip, plus a cone stand to perch it on.
// @tags toy, physics, balance, bird, educational
//
// The classic balancing-bird toy. The bird is a flat plate with
// forward-swept wings; heavy wingtip bosses hang BELOW beak level and
// ahead of the beak, pulling the center of mass to a point directly
// under the beak tip. Resting the beak in the stand's dimple, the bird
// hangs pendulum-stable because its center of mass sits below the
// support point.
//
// The bird is modeled in its balance frame: BEAK TIP AT THE ORIGIN,
// +x forward, z up. Balance is verified on the rendered mesh with
// scripts/check_stl.js (volume centroid, uniform-density assumption -
// valid for a solid single-material print):
//
//   BALANCE REQUIREMENT (assert-style, checked on the exported mesh):
//     |centroid.x| <= 1.5  &&  |centroid.y| <= 1.5  &&  centroid.z < 0
//   VERIFIED at the defaults below (weight_mode="solid",
//   wingspan=140, sweep_angle=35, body_length=80, plate_thickness=3,
//   pocket_diameter=20, tip_drop=14):
//     centroid = [-0.42, 0.00, -2.87] mm, volume = 26631 mm^3
//   i.e. the center of mass sits 0.4mm behind and 2.9mm BELOW the beak
//   tip contact point - pendulum-stable. If you change bird parameters,
//   re-render and re-check the centroid (uniform density assumed).
//
// Wingtip weights: weight_mode="solid" prints solid PLA bosses sized
// to balance on their own. weight_mode="coin" opens a pocket in each
// boss (facing DOWN in use, facing UP on the print bed) for coins -
// with EMPTY pockets the centroid measures [-3.29, 0.00, -1.22] (tail
// heavy): coin mode balances once coins are inserted (coin mass sits
// low and forward of the beak, which restores and deepens stability).
//
// Printing: the bird prints FLAT ON ITS BACK - its top surface is one
// flat plane (plate top, boss tops flush), so flipped upside-down the
// whole silhouette rests on the bed and the wingtip bosses are plain
// vertical cylinders growing upward. No supports, no bridges; coin
// pockets print as upward-facing blind holes. The stand prints upright
// on its base (wall angle ~74 degrees from horizontal, dimple faces up).

/* [Bird] */
// Wingtip-to-wingtip span (mm)
wingspan = 140; // [100:10:200]

// Forward wing sweep, degrees from straight-sideways
sweep_angle = 35; // [20:1:45]

// Beak tip to tail length (mm)
body_length = 80; // [60:5:110]

// Plate thickness (mm)
plate_thickness = 3; // [2:0.5:5]

/* [Wingtip Weights] */
// Solid printed tips, or open pockets for coins
weight_mode = "solid"; // ["solid", "coin"]

// Weight pocket diameter (mm) - also sets boss size (pocket + 5mm wall). 20 fits most small coins.
pocket_diameter = 20; // [14:1:26]

// Pocket depth for coins (mm)
pocket_depth = 8; // [4:1:12]

// How far the wingtip bosses hang below beak level (mm)
tip_drop = 14; // [8:2:24]

/* [Stand] */
// Cone stand height (mm)
stand_height = 70; // [50:5:100]

// Cone stand base diameter (mm)
stand_base = 46; // [36:2:60]

/* [Display] */
// What to show
_display_mode = "all"; // ["all", "bird", "stand", "balanced"]

/* [Advanced] */
$fn = 48;

// ---- Derived geometry (balance frame: beak tip at origin) ----

_t = plate_thickness;
_half = wingspan / 2;
_wall = 2.5;
_boss_d = pocket_diameter + 2 * _wall;

// Silhouette anchors (tuned together with the defaults above so the
// centroid lands under the beak tip - see VERIFIED comment)
_beak_tip_r = 1.5;
_head_c = [-16, 0];   _head_r = 8;
_sh_x = 22;           _sh_y = 9;    _sh_r = 9;   // wing shoulder
_tail_r = 9;
_tail_c = [-body_length + _tail_r, 0];

// Wingtip boss centers: outer edge of the boss defines the wingspan
_tip_y = _half - _boss_d / 2;
_tip_x = -_sh_x + (_tip_y - _sh_y) * tan(sweep_angle);

// Display gap between bird and stand in "balanced" mode
_eps = 0.3;

assert(_tip_y > _sh_y + 5,
    str("Wingspan ", wingspan, " too small for pocket_diameter ", pocket_diameter));
assert(pocket_depth <= tip_drop + _t - 1.5,
    str("pocket_depth ", pocket_depth, " leaves <1.5mm floor; increase tip_drop"));
assert(tip_drop < stand_height - 10,
    str("tip_drop ", tip_drop, " too large: wingtips would hit the table before the beak reaches the stand"));
assert(body_length > _sh_x + _sh_r + _tail_r + 5,
    "body_length too short for the wing shoulder");

// ---- Bird ----

module _silhouette_2d() {
    // beak + head
    hull() {
        translate([-_beak_tip_r, 0]) circle(_beak_tip_r); // tip reaches x=0
        translate(_head_c) circle(_head_r);
    }
    // body: head to tail teardrop
    hull() {
        translate(_head_c) circle(_head_r);
        translate(_tail_c) circle(_tail_r);
    }
    // tail fan
    hull() {
        translate(_tail_c) circle(_tail_r);
        translate([-body_length + 2, -6]) circle(2);
        translate([-body_length + 2, 6]) circle(2);
    }
    // forward-swept wings
    for (s = [-1, 1]) hull() {
        translate([-_sh_x, s * _sh_y]) circle(_sh_r);
        translate([_tip_x, s * _tip_y]) circle(_boss_d / 2);
    }
}

// The bird in its balance frame: beak tip at [0,0,0], plate on z[0,t],
// wingtip bosses hanging down to z = -tip_drop.
module bird_balance() {
    difference() {
        union() {
            linear_extrude(height = _t) _silhouette_2d();
            for (s = [-1, 1])
                translate([_tip_x, s * _tip_y, -tip_drop])
                    cylinder(d = _boss_d, h = tip_drop + _t);
        }
        if (weight_mode == "coin")
            for (s = [-1, 1])
                translate([_tip_x, s * _tip_y, -tip_drop - 0.1])
                    cylinder(d = pocket_diameter, h = pocket_depth + 0.1);
    }
}

// Print pose: flipped onto its flat back, everything on the plate
module bird_print() {
    translate([0, 0, _t]) rotate([180, 0, 0]) bird_balance();
}

// ---- Stand ----

// Cone stand, base on z=0, beak dimple in the top face
module stand() {
    difference() {
        cylinder(d1 = stand_base, d2 = 8, h = stand_height);
        // conical dimple, overshooting the top face
        translate([0, 0, stand_height - 2.5])
            cylinder(d1 = 0, d2 = 7.3, h = 2.6);
    }
}

// ---- Display ----

// Accessor for the verification harness
function bird_tip_drop() = tip_drop;

if (_display_mode == "all") {
    color("SkyBlue") bird_print();
    color("BurlyWood")
        translate([0, _half + stand_base / 2 + 10, 0]) stand();
} else if (_display_mode == "bird") {
    color("SkyBlue") bird_print();
} else if (_display_mode == "stand") {
    color("BurlyWood") stand();
} else if (_display_mode == "balanced") {
    // Beak tip at the origin; stand rim a display-epsilon below it.
    // The bird touches the stand only (conceptually) at the beak point.
    color("SkyBlue") bird_balance();
    color("BurlyWood") translate([0, 0, -stand_height - _eps]) stand();
}
