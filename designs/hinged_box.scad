// @name Hinged Box
// @description Print-in-place box with a captive-pin barrel hinge and a cantilever snap latch. Prints open and flat; fold shut and it snaps closed.
// @tags box, hinge, print-in-place, snap-fit, latch
//
// Two equal box halves print open and flat (both cavities up), joined
// along the back edge by a barrel hinge whose pin prints CAPTIVE inside
// the knuckles: the pin floats in every knuckle bore with
// hinge_clearance (0.35 mm) all round and is trapped axially by the
// blind outer faces of the two end knuckles. Knuckles alternate
// base/lid along the hinge (odd count, base owns both ends). A
// cantilever snap hook on the lid front edge engages a window in the
// base front wall when the box is folded shut (re-openable: the barb
// ledge is raked 35 degrees).
//
// Print notes:
//   - Print as laid out in "open" mode, NO supports (supports would
//     fuse the hinge). The knuckle barrels sit at the parting-line
//     height and bridge over a ~7 mm round underside, and the pin
//     bridges the 0.35 mm gaps between knuckles - both standard for
//     print-in-place hinges. The 1.2 mm barb ledge on the latch hook
//     prints as a short raked overhang.
//   - After printing, flex the lid gently through a few degrees to
//     free the hinge.
//   - The hinge-side bottom edges of both halves are chamfered 45
//     degrees so they clear each other as the box folds.
//
// Modes: "open" = print layout (base + lid coplanar + captive pin,
// 3 bodies); "base"/"lid" = single halves; "closed" = folded assembled
// state (lid raised 0.05 mm so the touching rims stay separate meshes).

use <../macros/snapfit.scad>

/* [Box] */
// Box length along the hinge (mm)
box_l = 60; // [30:5:120]
// Box width, hinge to latch (mm)
box_w = 40; // [20:5:80]
// Closed box height; each half is box_h/2 (mm)
box_h = 30; // [24:2:60]
// Side wall thickness (mm)
wall = 2; // [1.6:0.2:3.2]
// Floor thickness of each half (mm)
floor_t = 2; // [1.6:0.2:3.2]

/* [Hinge] */
// Number of hinge knuckles (odd - the base owns both ends)
knuckles = 5; // [3:2:9]
// Hinge pin diameter (mm)
pin_d = 3; // [2:0.5:5]
// Clearance around the captive pin and between moving hinge parts (mm)
hinge_clearance = 0.35; // [0.25:0.05:0.5]

/* [Latch] */
// Snap hook width (mm)
latch_w = 12; // [8:1:20]
// Snap arm length above the rim (mm)
latch_arm = 8; // [6:1:12]
// Snap arm thickness - the flexing dimension (mm)
latch_arm_t = 1.8; // [1.2:0.2:2.6]
// Barb protrusion beyond the arm face (mm)
latch_bump = 1.2; // [0.8:0.1:1.8]
// Barb height along the arm (mm)
latch_barb = 2.4; // [1.6:0.2:3.2]
// Sliding clearance between hook, wall and window (mm)
latch_clearance = 0.3; // [0.2:0.05:0.5]

/* [Display] */
// What to show
_display_mode = "open"; // ["open", "base", "lid", "closed"]

/* [Advanced] */
// Resolution
$fn = 48;

// ---- Derived hinge geometry -----------------------------------------
_half_h = box_h / 2;              // height of each half = hinge axis z
_g = hinge_clearance;
_knuckle_wall = 1.6;
_r_k = pin_d / 2 + _g + _knuckle_wall;   // knuckle barrel radius
_r_n = _r_k + _g;                 // relief (notch) radius in the mate
_g0 = 0.5;                        // wall face standoff from the axis plane
_seg = box_l / knuckles;          // knuckle pitch along the hinge
_bore_d = pin_d + 2 * _g;         // knuckle bore
_cap = 1.2;                       // blind end-cap thickness in end knuckles
_chamfer = 1.5;                   // hinge-side bottom edge chamfer

// ---- Derived latch geometry ------------------------------------------
_e_gap = 0.15;                    // ledge-to-catch-edge seating gap
_y_of = _g0 + box_w;              // base front wall OUTER face (base frame)
// Hook ledge z once the lid is folded closed
_ledge_closed_z = _half_h - latch_arm + latch_barb;
// Window catch edge (top edge of the opening) in the base front wall
_win_catch_z = _ledge_closed_z + _e_gap;
_tab_o = latch_clearance + latch_arm_t;  // latch tab reach beyond lid face
_tab_t = 2;                       // latch tab plate thickness

// ---- Envelope checks --------------------------------------------------
assert(knuckles % 2 == 1 && knuckles >= 3,
    str("knuckles must be odd and >= 3 (got ", knuckles, ")"));
assert(_half_h >= _r_n + 3,
    str("box_h/2 = ", _half_h, " too small for the hinge barrel (needs >= ",
        _r_n + 3, "): increase box_h or reduce pin_d"));
assert(_seg - _g >= 2.5,
    str("knuckle segments too short (", _seg - _g,
        " mm): reduce knuckles or increase box_l"));
assert(latch_bump >= latch_clearance + 0.5,
    str("latch_bump ", latch_bump, " must exceed latch_clearance + 0.5 = ",
        latch_clearance + 0.5, " or the snap retains nothing"));
assert(latch_arm >= latch_barb + 1.7,
    str("latch_arm ", latch_arm, " too short for barb ", latch_barb));
assert(_win_catch_z - window_height(latch_barb, latch_clearance)
           >= floor_t + 1,
    "latch window would breach the base floor: shorten latch_arm or increase box_h");
assert(latch_w + 2 * latch_clearance + 2 <= box_l - 2 * wall,
    "latch_w too wide for the front wall");

// ---- Hinge sub-shapes (shared by both halves, built in +y frame) -----

// Knuckle barrel for slot i (welds into the back wall top edge)
module hb_barrel(i) {
    x0 = (i == 0) ? 0 : i * _seg + _g / 2;
    x1 = (i == knuckles - 1) ? box_l : (i + 1) * _seg - _g / 2;
    translate([x0, 0, _half_h])
        rotate([0, 90, 0])
            cylinder(r = _r_k, h = x1 - x0);
}

// Relief cut for the OTHER half's knuckle at slot i (covers the slot
// plus both axial gaps, ending flush with this half's own barrels)
module hb_notch(i) {
    x0 = (i == 0) ? -0.5 : i * _seg - _g / 2;
    x1 = (i == knuckles - 1) ? box_l + 0.5 : (i + 1) * _seg + _g / 2;
    translate([x0, 0, _half_h])
        rotate([0, 90, 0])
            cylinder(r = _r_n, h = x1 - x0);
}

// One box half in the base frame (y positive, hinge edge at y=_g0).
// barrel_parity: which knuckle slots this half owns (0 = even = base).
// with_window: cut the latch window in the front wall.
module hb_half(barrel_parity, with_window) {
    difference() {
        union() {
            difference() {
                // shell
                translate([0, _g0, 0])
                    cube([box_l, box_w, _half_h]);
                // cavity (overshoots the rim)
                translate([wall, _g0 + wall, floor_t])
                    cube([box_l - 2 * wall, box_w - 2 * wall, _half_h]);
                // relief scallops for the mate's knuckles
                for (i = [0 : knuckles - 1])
                    if (i % 2 != barrel_parity)
                        hb_notch(i);
                // 45-degree chamfer on the hinge-side bottom edge so the
                // halves' bottom edges clear each other while folding
                rotate([90, 0, 90])
                    translate([0, 0, -1])
                        linear_extrude(height = box_l + 2)
                            polygon([[_g0 - 0.1, -0.1],
                                     [_g0 + _chamfer, -0.1],
                                     [_g0 - 0.1, _chamfer]]);
                // latch window (base front wall only)
                if (with_window)
                    translate([box_l / 2, _y_of, _win_catch_z])
                        rotate([180, 0, 0])
                            cantilever_window(latch_w, latch_barb, wall,
                                              latch_clearance);
            }
            // this half's knuckle barrels
            for (i = [0 : knuckles - 1])
                if (i % 2 == barrel_parity)
                    hb_barrel(i);
        }
        // pin bore - blind at both ends (end knuckles cap the pin)
        translate([_cap, 0, _half_h])
            rotate([0, 90, 0])
                cylinder(d = _bore_d, h = box_l - 2 * _cap);
    }
}

// ---- Parts -----------------------------------------------------------

module hb_base() {
    hb_half(0, true);
}

module hb_lid() {
    // shell mirrored to the -y side of the hinge, odd knuckle slots
    mirror([0, 1, 0])
        hb_half(1, false);
    // latch tab: chamfered bracket on the lid front face, top flush
    // with the rim; the hook arm roots on it
    translate([box_l / 2, 0, 0])
        rotate([90, 0, 90])
            translate([0, 0, -(latch_w + 4) / 2])
                linear_extrude(height = latch_w + 4)
                    polygon([[-_y_of + 0.5, _half_h],
                             [-_y_of - _tab_o, _half_h],
                             [-_y_of - _tab_o, _half_h - _tab_t],
                             [-_y_of + 0.5, _half_h - _tab_t - _tab_o - 0.5]]);
    // snap hook, pointing up in the print layout, barb toward +y
    translate([box_l / 2, -_y_of - latch_clearance - latch_arm_t,
               _half_h - 0.2])
        cantilever_hook(latch_arm + 0.2, latch_w, latch_arm_t,
                        latch_bump, latch_barb);
}

module hb_pin() {
    translate([_cap + _g, 0, _half_h])
        rotate([0, 90, 0])
            cylinder(d = pin_d, h = box_l - 2 * (_cap + _g));
}

// Fold transform about the hinge axis (x-axis line at y=0, z=_half_h).
// angle=0 is the print layout, 180 is closed. lift separates the
// touching rims in display renders.
module hb_fold(angle, lift = 0) {
    translate([0, 0, lift])
        translate([0, 0, _half_h])
            rotate([-angle, 0, 0])
                translate([0, 0, -_half_h])
                    children();
}

// Accessors for the test harness
function hb_axis_z() = _half_h;
function hb_pin_diameter() = pin_d;
function hb_window_catch_z() = _win_catch_z;

// ---- Display ----------------------------------------------------------

if (_display_mode == "open") {
    color("SteelBlue") hb_base();
    color("Tomato") hb_lid();
    color("Gold") hb_pin();
} else if (_display_mode == "base") {
    hb_base();
} else if (_display_mode == "lid") {
    hb_lid();
} else if (_display_mode == "closed") {
    color("SteelBlue") hb_base();
    color("Tomato") hb_fold(180, 0.05) hb_lid();
    color("Gold") hb_pin();
}
