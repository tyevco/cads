// @name Nesting Screw Capsules
// @description Matryoshka-style set of screw-top capsules that nest inside each other, with coarse printable threads.
// @tags capsule, container, screw, thread, nesting, matryoshka, storage
//
// A set of 2-3 cylindrical capsules, each with a screw-on lid, sized so
// every closed capsule fits through the neck of the next one up and
// nests inside it (matryoshka style).
//
// Construction per capsule:
//   - Body: a cup with a flat floor, a 45-degree internal shoulder cone,
//     and a reduced-diameter externally-threaded neck on top.
//   - Lid: a flush-diameter cap with the matching internal thread
//     (thread_cutout grown by thread_clearance) and a chamfered mouth.
//
// Printing: every part prints open-side-up with no supports - bodies
//   neck-up, lids mouth-up. Threads have 45-degree flanks and the
//   internal shoulder cone is 45 degrees, all self-supporting.
//
// Assembly: screw each lid on (right-hand, ~2.5 effective turns at the
//   defaults); drop each closed capsule into the next larger body.
//
// Uses macros/threads.scad for the thread geometry.

use <../macros/threads.scad>

/* [Capsules] */
// How many nesting capsules
capsule_count = 3; // [2:1:3]

// Outer diameter of the largest capsule (mm)
outer_diameter = 60; // [40:5:90]

// Closed height of the largest capsule (mm)
outer_height = 70; // [40:5:110]

// Wall / floor / lid-top thickness (mm)
wall = 2.0; // [1.6:0.2:3]

/* [Thread] */
// Thread pitch (mm per turn)
pitch = 3; // [2:0.5:4]

// Radial thread clearance between lid and neck (mm)
thread_clearance = 0.3; // [0.15:0.05:0.5]

// Full-depth thread turns of engagement
engage_turns = 2.5; // [2:0.5:4]

/* [Nesting] */
// Gap around a nested capsule, radial and axial (mm)
nest_clearance = 0.5; // [0.3:0.1:1]

/* [Display] */
// What to show
_display_mode = "all"; // ["all", "capsule", "lid", "assembled"]

/* [Advanced] */
$fn = 48;

// ---- Derived ----

_depth = thread_depth(pitch);              // radial tooth depth (0.3*pitch)
_neck_h = engage_turns * pitch + 2 * _depth; // thread length incl. end fades
_lid_top = wall;                           // lid closed-face thickness
_seal_gap = 0.15;                          // neck-top / socket-ceiling gap
_rim_gap = 0.15;                           // lid-rim / shoulder gap at seat
_lid_h = _lid_top + _neck_h;               // lid overall height
_cone_h = wall + thread_clearance + _depth; // internal 45-deg shoulder height
_layout_gap = 8;                           // spacing between parts on plate

// Thread mesh density: profile points, and twist slices per turn (the
// largest capsule gets 24; smaller radii tolerate proportionally fewer)
_thread_fn = 32;
function _spt(i) = max(18, ceil(24 * sqrt(cap_r(i) / cap_r(0))));

// Cutter faceting-compensation factor (see thread_facet_comp in
// macros/threads.scad): the lid's cutter reaches (major/2 +
// thread_clearance) * (1 + _comp_f), and that must sit a full wall
// inside the lid, so cap_major is solved from it below.
function _comp_f(i) = (1 - cos(180 / _thread_fn)) + (1 - cos(180 / _spt(i)));

// Axial shrink per nesting level: lid top + floor + nesting gap
_step_h = 2 * wall + nest_clearance;

// ---- Accessor functions (index 0 = largest capsule) ----

function cap_count() = capsule_count;
function cap_pitch() = pitch;
function cap_wall() = wall;

// Outer radius: each capsule must pass through the neck opening of the
// one before it, with nest_clearance of radial play
function cap_r(i) = i <= 0 ? outer_diameter / 2
                           : cap_bore_r(i - 1) - nest_clearance;
function cap_h(i) = outer_height - i * _step_h;

// Thread major diameter: leaves a full wall outside the lid's cutter
// (cutter max radius incl. faceting compensation = cap_r - wall)
function cap_major(i) = 2 * ((cap_r(i) - wall) / (1 + _comp_f(i))
                             - thread_clearance);
function cap_root_r(i) = thread_root_d(cap_major(i), pitch) / 2;
function cap_bore_r(i) = cap_root_r(i) - wall; // neck opening radius
function cap_body_h(i) = cap_h(i) - _neck_h - _lid_top - _seal_gap;

// Seated lid pose: the lid (modeled mouth-up) is flipped over, rotated
// about z and set down so its socket ceiling sits _seal_gap above the
// neck top. The angle phase-matches the internal thread to the external
// one: cutter base offset (_lid_top) and neck base (body_h - 0.1, the
// thread is sunk 0.1 into the shoulder) both enter via the thread
// library's angle = 360*dz/pitch rule.
function cap_seat_z(i) = cap_h(i);
function cap_seat_rot(i) = 360 * (_neck_h + _seal_gap + 0.1) / pitch;

// Resting z of nested capsule i (each sits 0.1 above the floor below it)
function nest_z(i) = i <= 0 ? 0 : nest_z(i - 1) + wall + 0.1;

// Print-layout x of part i in a row (cumulative - radii differ)
function row_x(i) = i <= 0 ? 0 : row_x(i - 1) + cap_r(i - 1) + cap_r(i) + _layout_gap;

// ---- Sanity asserts ----

assert(engage_turns >= 2,
    str("Thread engagement ", engage_turns, " turns < 2 - lid would strip"));
assert(cap_bore_r(capsule_count - 1) >= 3,
    str("Capsules will not nest: smallest neck opening radius is ",
        cap_bore_r(capsule_count - 1),
        "mm - increase outer_diameter or reduce capsule_count/wall/pitch"));
assert(cap_body_h(capsule_count - 1) >= _cone_h + wall + 1,
    str("Smallest capsule body too short (", cap_body_h(capsule_count - 1),
        "mm) for its shoulder cone - increase outer_height or reduce ",
        "engage_turns/pitch/wall"));

// ---- Parts ----

_body_colors = ["SteelBlue", "MediumSeaGreen", "IndianRed"];
_lid_colors = ["LightSteelBlue", "DarkSeaGreen", "RosyBrown"];

// Cup with externally threaded neck. Prints as-modeled (neck up).
module capsule_body(i) {
    R = cap_r(i);
    bh = cap_body_h(i);
    cav_r = R - wall;
    bore = cap_bore_r(i);
    difference() {
        union() {
            cylinder(r = R, h = bh);
            // neck thread, sunk 0.1 into the shoulder so the union welds
            translate([0, 0, bh - 0.1])
                external_thread(cap_major(i), pitch, _neck_h + 0.1,
                                fn = _thread_fn, slices_per_turn = _spt(i));
        }
        // cavity: floor, chamber, 45-degree shoulder cone, neck bore
        // (one profile - no internal coincident faces), open through
        // the neck top with 0.2 overshoot
        rotate_extrude(convexity = 4)
            polygon([[0, wall],
                     [cav_r, wall],
                     [cav_r, bh - _cone_h],
                     [bore, bh],
                     [bore, bh + _neck_h + 0.2],
                     [0, bh + _neck_h + 0.2]]);
    }
}

// Cap with internal thread, modeled in print orientation: closed face
// down at z=0, threaded mouth up.
module capsule_lid(i) {
    R = cap_r(i);
    maj = cap_major(i);
    difference() {
        cylinder(r = R, h = _lid_h);
        // internal thread: cutter base at the socket ceiling, running
        // 0.2 past the mouth
        translate([0, 0, _lid_top])
            thread_cutout(maj, pitch, _lid_h - _lid_top + 0.2,
                          thread_clearance,
                          fn = _thread_fn, slices_per_turn = _spt(i));
        // mouth entry chamfer
        translate([0, 0, _lid_h - _depth])
            cylinder(r1 = cap_root_r(i) + thread_clearance,
                     r2 = thread_cutout_max_r(maj, thread_clearance,
                                              _thread_fn, _spt(i)) + 0.5,
                     h = _depth + 0.1);
    }
}

// Closed capsule: body + lid screwed to its seated pose
module capsule_assembled(i) {
    color(_body_colors[i % 3]) capsule_body(i);
    color(_lid_colors[i % 3])
        translate([0, 0, cap_seat_z(i)])
            rotate([0, 0, cap_seat_rot(i)])
                rotate([180, 0, 0])
                    capsule_lid(i);
}

// ---- Display ----

module show_bodies() {
    for (i = [0 : capsule_count - 1])
        color(_body_colors[i % 3])
            translate([row_x(i), 0, 0])
                capsule_body(i);
}

module show_lids() {
    for (i = [0 : capsule_count - 1])
        color(_lid_colors[i % 3])
            translate([row_x(i), 0, 0])
                capsule_lid(i);
}

if (_display_mode == "all") {
    // print layout: bodies in one row, lids in a second row, all
    // open-side-up on the plate
    show_bodies();
    translate([0, -(2 * cap_r(0) + _layout_gap), 0])
        show_lids();
} else if (_display_mode == "capsule") {
    show_bodies();
} else if (_display_mode == "lid") {
    show_lids();
} else if (_display_mode == "assembled") {
    // every capsule closed and nested inside the next larger one
    for (i = [0 : capsule_count - 1])
        translate([0, 0, nest_z(i)])
            capsule_assembled(i);
}
