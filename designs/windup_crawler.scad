// @name Wind-Up Crawler
// @description A wind-up crawling toy: a printed spiral power spring drives eccentric cam feet through a 2.5:1 gear pair, with a click-pawl ratchet to hold the wind.
// @tags toy, windup, spiral-spring, ratchet, gears, compliant, crawler
//
// Five printed parts, no supports:
//   1. chassis  - deck with two bearing walls (printed deck-down, walls
//      up; flip to use). Integral: a flexible click-pawl with a release
//      paddle, a slotted anchor bar for the spring's outer tab, snap
//      nubs in the axle notches, and 45-degree rear skid fingers.
//   2. spring   - the spiral power spring cartridge, printed flat:
//      Archimedean band + square-bore hub + outer anchor tab, ONE body.
//   3. arbor    - wind axle, printed standing on its 20T gear face:
//      gear + 10T ratchet at one end, square spring seat between the
//      journals, and the wind knob on a 45-degree cone at the far end
//      (outboard of the right cam so they cannot collide).
//   4. legaxle  - leg axle, printed standing on the left cam: eccentric
//      cam foot, 8T pinion, journals, square boss + cross-slotted snap
//      ridge for the second cam.
//   5. cam      - right cam foot, printed flat; square bore keys it to
//      the boss, the snap ridge (macros/snapfit.scad) retains it. Its
//      lobe is baked 180 degrees out of phase for a waddling gait.
//
// Assembly: slide the spring hub over the arbor tip onto the square
// seat; drop arbor+spring down into the rear wall notches so the
// journals snap past the nubs and the spring tab enters the anchor-bar
// slot; drop the legaxle into the front notches (wiggle so the pinion
// meshes past the gear; the pawl tooth also snaps over the ratchet);
// press the right cam onto the square boss (lobe OPPOSITE the left
// cam) until the ridge snaps. Wind the knob to the strain limit
// (~half a turn, echoed at render - the pawl clicks and holds), flick
// the release paddle under the belly, and it waddles forward: the
// spring unwinds the arbor, the gear pair spins the cams 2.5x, and
// the eccentric feet shove against the ground while the angled rear
// skids resist backsliding.
//
// HONEST LIMITS (torque cannot be proven geometrically): with E(PLA)
// ~2400 MPa the fully wound spring stores ~E*h*t^2*eps/6 = ~37 N*mm,
// about 15 N*mm / 1.3 N of push at the cams after the 2.5:1 speedup -
// several times the ~0.4 N needed to shove a ~40 g toy, but E varies
// +-40% with print settings and bearing/mesh friction is unmodeled.
// Safe windup is strain-limited to well under one knob turn (echoed at
// render time); expect a couple of leg cycles per wind.
//
// Modes: "all" = print layout (5 bodies), "assembled" = working pose
// (pawl preload merges chassis+arbor: 4 bodies), one mode per part.

use <../macros/flexures.scad>
use <../macros/gears.scad>
use <../macros/snapfit.scad>

/* [Spring] */
// Number of spiral coils
spring_turns = 4; // [3:1:5]

// Spiral band thickness (mm)
spring_t = 1.2; // [1.0:0.05:1.4]

// Spiral band height along the arbor (mm)
spring_h = 8; // [6:1:10]

/* [Drive] */
// Cam eccentricity - half the foot lift per revolution (mm)
cam_ecc = 3; // [2:0.5:4]

// Wind knob diameter (mm)
knob_d = 18; // [17:1:22]

/* [Springs safety] */
// Working strain limit for the PLA flexures, percent
max_strain_pct = 0.8; // [0.5:0.05:1.0]

/* [Display] */
// What to show
_display_mode = "all"; // ["all", "assembled", "chassis", "spring", "arbor", "legaxle", "cam"]

/* [Advanced] */
$fn = 48;


// ---- Layout constants (assembled frame: x forward, y across, z up;
// ---- knob side is -y) --------------------------------------------------

_eps = max_strain_pct / 100;

// Gears: 20T ring drives an 8T pinion, module 1.25 (2.5x speedup)
_g1t = 20; _g2t = 8; _gm = 1.25;
_cd = gear_center_distance(_g1t, _g2t, _gm);   // 17.5
_g1_or = gear_pitch_radius(_g1t, _gm) + _gm * 0.9;

// Axle positions
_ax = -15;  _az = 2;                            // arbor axis (x, z)
_lz = -6;                                       // legaxle z
_lx = _ax + sqrt(_cd * _cd - (_az - _lz) * (_az - _lz));

// Cams: eccentric discs, contact radius _cam_r +- cam_ecc
_cam_r = 11;
_ground = _lz - _cam_r;                         // mean stance line

// Chassis
_deck_z0 = 18.5; _deck_t = 3;                   // deck 18.5..21.5
_wall_in = 6; _wall_t = 3;                      // walls |y| 6..9
_wall_bot = -11;
_deck_x0 = -32; _deck_x1 = 16; _deck_y = 19;
_journal_d = 5; _notch_c = 0.4;                 // bore clearance (dia)
_nub = 0.4;                                     // snap nub bite per side

// Spring cartridge
_s_od = 29; _s_id = 10;
_sq = 5;                                        // arbor square seat
_s_y0 = -5;                                     // spring near face y
_tab_t = 3;                                     // anchor tab thickness (x)

// Anchor bar under the spring; the tab reaches to just above its bottom
_bar_top = -14.6; _bar_bot = -16.4;
_slot_w = _tab_t + 0.6;
_tab_r1 = _az - _bar_bot - 0.2;                 // tab tip radius (18.2)

// Ratchet
_r_teeth = 10; _r_tip = 7; _r_root = 6.1;
_rsa = 360 / _r_teeth;
_rdrop = _rsa * 0.12;
_pawl_t = 1.0;                                  // pawl blade thickness
_pawl_x = 7.1;                                  // blade inner face (rel arbor)
_pawl_az = -25;                                 // engagement azimuth (deg)
_pawl_preload = 0.2;
_pawl_tip_r = _r_root + _pawl_preload;          // pawl tooth apex radius

// Arbor local stack (printed standing on the G1 face; local z from the
// G1 outer face, assembled y = local z - 17). The knob sits at the FAR
// +y end, past the right cam, on a 45-degree cone.
_a_g1_h = 4;                                    // G1 at y -17..-13
_a_rat_z = 3.9; _a_rat_h = 3.1;                 // ratchet y -13.1..-10
_a_frus_z = 11.2;                               // square entry frustum
_a_sq_z = 12.3; _a_sq_h = 10.7;                 // square seat y -4.7..+6
_a_knob_z = 43.5;                               // knob base (y 26.5)
_a_knob_h = 6;
_a_len = _a_knob_z + _a_knob_h;

// Legaxle local stack (z from left cam outer face; y = local z - 26)
_l_cam_h = 8.7;                                 // cam y -26..-17.3
_l_pin_z = 8.7; _l_pin_h = 4.3;                 // pinion y -17.3..-13
_l_boss_z = 35.25; _l_boss_h = 4.5;             // square boss y 9.25..13.75
_l_tip_z = 39.75;                               // ridge shaft start
_l_tip_d = 3.4; _l_ridge_bite = 0.8; _l_ridge_h = 3.2;
_l_len = 43.8;
_cam_boss_sq = 4;                               // boss square side
_cam_bore_sq = _cam_boss_sq + 0.4;              // cam square bore
_cam_y0 = 9.5;                                  // cam inner face y

// ---- Mechanics asserts -------------------------------------------------

_windup = spiral_windup_turns(_s_od, _s_id, spring_turns, spring_t, _eps);
_torque = spiral_torque(_s_od, _s_id, spring_turns, spring_t, spring_h,
                        _windup);
assert(spring_t >= 0.8, "spring band below 0.8mm minimum");  // also in macro
assert(_windup >= 0.3,
    str("Windup of ", _windup, " turns is uselessly small: more coils, ",
        "thinner band, or higher max_strain_pct."));
assert(_az + _s_od / 2 <= _deck_z0,
    str("Spring od ", _s_od, " hits the deck"));
assert(_az - _s_od / 2 >= _bar_top + 0.4,
    str("Spring od ", _s_od, " hits the anchor bar"));
assert(_az - _g1_or > _ground + 2,
    str("Gear grazes the ground: clearance ", _az - _g1_or - _ground));
assert(_cd - _s_od / 2 - _journal_d / 2 >= 0.4,
    str("Spring od ", _s_od, " would rub the leg axle: clearance ",
        _cd - _s_od / 2 - _journal_d / 2));
echo(str("SPRING: L=", spiral_length(_s_od, _s_id, spring_turns),
         "mm, coil gap ", spiral_coil_gap(_s_od, _s_id, spring_turns, spring_t),
         "mm, safe windup ", _windup, " turns, torque ", _torque,
         " N*mm (E=2400MPa +-40%), at cams ~", _torque / (_g1t / _g2t),
         " N*mm -> ~", _torque / (_g1t / _g2t) / _cam_r, " N push"));

// Pawl: blade flexes from the deck down to the tooth
_pawl_tooth_z = _az + _pawl_tip_r * sin(_pawl_az);  // tooth apex height
_pawl_flex_l = _deck_z0 - _pawl_tooth_z;
_pawl_need = (_r_tip - _r_root) + _pawl_preload;
_pawl_limit = flex_stroke(_pawl_flex_l, _pawl_t, _eps);
assert(_pawl_need <= _pawl_limit,
    str("Pawl click needs ", _pawl_need, "mm but safe stroke is ",
        _pawl_limit, "mm"));
echo(str("PAWL: click stroke ", _pawl_need, "mm, safe ", _pawl_limit,
         "mm, margin x", _pawl_limit / _pawl_need));
echo(str("CAMS: contact radius ", _cam_r - cam_ecc, "..", _cam_r + cam_ecc,
         "mm, mean stance z=", _ground));

// ---- Accessors for the verification harness ---------------------------

function crawler_arbor_pos() = [_ax, 0, _az];
function crawler_legaxle_pos() = [_lx, 0, _lz];
function crawler_ground_z() = _ground;
// mesh line angle in the gears' local (pre-tilt) frame
_mesh_a = atan2(-(_lz - _az), _lx - _ax);
function crawler_mesh_rot(a_arbor) =
    gear_mesh_rotation(a_arbor, _g1t, _g2t, _mesh_a);
// The displayed arbor rotation: 0 keeps the square seat aligned with
// the spring hub; the ratchet's phase is baked into the part so a
// tooth valley faces the pawl at this angle.
function crawler_park_rot() = 0;


// ---- Spring cartridge (printed flat, axis +z) --------------------------

module spring_part() {
    spiral_spring(_s_od, _s_id, spring_turns, spring_t, spring_h);
    // hub: square bore, welded into the first coil
    difference() {
        cylinder(r = _s_id / 2 + 0.3, h = spring_h);
        translate([0, 0, -0.1]) linear_extrude(spring_h + 0.2)
            square(_sq + 0.4, center = true);
    }
    // outer anchor tab (at the band's end azimuth, angle 0 -> +x);
    // starts just inside the band's inner surface so it welds to the
    // last coil without touching the one before it
    translate([_s_od / 2 - spring_t - 0.1, -_tab_t / 2, 0])
        cube([_tab_r1 - _s_od / 2 + spring_t + 0.1, _tab_t, spring_h]);
}

// assembled: plane xz, axis +y, tab pointing down (-z)
module spring_assembled() {
    translate([_ax, _s_y0, _az])
        rotate([-90, 0, 0]) rotate([0, 0, 90])
            spring_part();
}

// ---- Arbor (printed standing on the knob, axis +z) ---------------------

module knob_2d() {
    difference() {
        circle(knob_d / 2);
        for (i = [0 : 7])
            rotate([0, 0, i * 45 + 22.5])
                translate([knob_d / 2 + 0.9, 0]) circle(1.8, $fn = 24);
    }
}

module ratchet_2d() {
    polygon([for (i = [0 : _r_teeth - 1], p = [0, 1])
        p == 0 ? _r_tip * [cos(i * _rsa), sin(i * _rsa)]
               : _r_root * [cos(i * _rsa + _rdrop), sin(i * _rsa + _rdrop)]]);
}

module arbor_part() {
    _cone_h = (knob_d - _journal_d) / 2;
    // the cone up to the knob must stay clear of the right cam's sweep
    assert(_a_knob_z - _cone_h - 17 >= 18,
        str("knob_d ", knob_d, ": the knob cone would reach into the ",
            "right cam's sweep"));
    // G1 - the print base
    linear_extrude(_a_g1_h) gear_spur_2d(_g1t, _gm);
    // ratchet, phased so a tooth valley faces the pawl at rotation 0
    // (the square seat must stay axis-aligned with the spring hub)
    translate([0, 0, _a_rat_z])
        linear_extrude(_a_rat_h)
            rotate([0, 0, -_pawl_az - _rdrop]) ratchet_2d();
    // core shaft
    translate([0, 0, _a_g1_h - 0.1])
        cylinder(d = _journal_d, h = _a_knob_z - _cone_h - _a_g1_h + 0.2);
    // square spring seat; its 45-degree entry frustum is slim enough to
    // hide inside the hub bore, clear of the wall notch
    translate([0, 0, _a_frus_z])
        linear_extrude(_a_sq_z - _a_frus_z,
                       scale = (_sq * sqrt(2)) / _journal_d)
            rotate([0, 0, 45]) circle(d = _journal_d, $fn = 4);
    translate([0, 0, _a_sq_z])
        linear_extrude(_a_sq_h) square(_sq, center = true);
    // 45-degree cone out to the wind knob at the far end
    translate([0, 0, _a_knob_z - _cone_h])
        cylinder(d1 = _journal_d, d2 = knob_d, h = _cone_h);
    translate([0, 0, _a_knob_z - 0.1])
        linear_extrude(_a_knob_h + 0.1) knob_2d();
}

// assembled: axis +y, gear at -y, knob at +y, rotated `a` about the axis
module arbor_at(a = crawler_park_rot()) {
    translate([_ax, -17, _az])
        rotate([-90, 0, 0]) rotate([0, 0, a])
            arbor_part();
}

// ---- Leg axle (printed standing on the left cam, axis +z) --------------

module cam_2d(ecc) {
    translate([ecc, 0]) circle(_cam_r);
}

module legaxle_part() {
    // left cam foot (lobe toward local +x)
    linear_extrude(_l_cam_h) cam_2d(cam_ecc);
    // pinion directly on the cam
    translate([0, 0, _l_pin_z - 0.1])
        linear_extrude(_l_pin_h + 0.1) gear_spur_2d(_g2t, _gm);
    // core shaft
    translate([0, 0, _l_pin_z])
        cylinder(d = _journal_d, h = _l_boss_z - _l_pin_z + 0.1);
    // square boss for the right cam
    translate([0, 0, _l_boss_z])
        linear_extrude(_l_boss_h) square(_cam_boss_sq, center = true);
    // snap tip: shaft + ridge, cross-slotted so it can compress
    difference() {
        union() {
            translate([0, 0, _l_boss_z + _l_boss_h - 0.1])
                cylinder(d = _l_tip_d, h = _l_len - _l_boss_z - _l_boss_h - 0.2);
            // snap ridge: 45-degree lead cones keep it printable
            // standing; the cam gains ~1mm axial play before the flats
            // engage the ridge land (harmless foot wobble)
            translate([0, 0, _l_tip_z + 0.25])
                snap_ridge(_l_tip_d, _l_ridge_bite, _l_ridge_h);
            translate([0, 0, _l_len - 0.5])
                cylinder(d1 = _l_tip_d, d2 = _l_tip_d - 1.2, h = 0.5);
        }
        for (sa = [0, 90])
            rotate([0, 0, sa])
                translate([-0.6, -(_l_tip_d / 2 + _l_ridge_bite + 0.5),
                           _l_tip_z - 3])
                    cube([1.2, _l_tip_d + 2 * _l_ridge_bite + 1,
                          _l_len - _l_tip_z + 3.1]);
    }
}

// assembled: axis +y, cam at -y, rotated `a` about the axis
module legaxle_at(a = crawler_mesh_rot(crawler_park_rot())) {
    translate([_lx, -26, _lz])
        rotate([-90, 0, 0]) rotate([0, 0, a])
            legaxle_part();
}

// ---- Right cam (printed flat) ------------------------------------------

module cam2_part() {
    difference() {
        // lobe toward local -x: mounted on the same square as the left
        // cam it lands 180 degrees out of phase
        linear_extrude(_l_cam_h) cam_2d(-cam_ecc);
        translate([0, 0, -0.1]) linear_extrude(_l_cam_h + 0.2)
            square(_cam_bore_sq, center = true);
        // counterbore the snap ridge expands into; its ledge sits 0.3
        // inboard of the ridge base
        translate([0, 0, _l_cam_h - 4.3])
            cylinder(d = _l_tip_d + 2 * _l_ridge_bite + 0.8, h = 4.4);
    }
}

// assembled: outer face at +y, same rotation as the legaxle
module cam2_at(a = crawler_mesh_rot(crawler_park_rot())) {
    translate([_lx, _cam_y0, _lz])
        rotate([-90, 0, 0]) rotate([0, 0, a])
            cam2_part();
}

// ---- Chassis ------------------------------------------------------------

module notch_2d(cx, cz) {
    // U-slot in the wall (xz plane), opening downward
    hull() {
        translate([cx, cz]) circle(d = _journal_d + _notch_c);
        translate([cx - (_journal_d + _notch_c) / 2, _wall_bot - 1])
            square([_journal_d + _notch_c, 0.1]);
    }
}

module nub_2d(cx, cz) {
    // diamond snap nubs on the slot lips, 3mm below the seated journal
    for (s = [-1, 1])
        translate([cx + s * (_journal_d + _notch_c) / 2, cz - 3.0])
            rotate([0, 0, 45]) square(_nub * sqrt(2), center = true);
}

module wall_2d() {
    difference() {
        union() {
            translate([-28, _wall_bot])
                square([41, _deck_z0 - _wall_bot + 0.1]);
            // rear skid finger, raked back >45deg so it prints (inverted)
            // and digs in against backsliding
            polygon([[-21, _wall_bot + 0.1], [-26, _ground],
                     [-24, _ground], [-19.5, _wall_bot + 1.5],
                     [-19.5, _wall_bot + 0.1]]);
        }
        notch_2d(_ax, _az);
        notch_2d(_lx, _lz);
    }
    nub_2d(_ax, _az);
    nub_2d(_lx, _lz);
}

module chassis_walls() {
    for (sy = [-1, 1])
        translate([0, sy == -1 ? -_wall_in - _wall_t : _wall_in, 0])
            rotate([90, 0, 0]) translate([0, 0, -_wall_t])
                linear_extrude(_wall_t) wall_2d();
}

module chassis_deck() {
    translate([_deck_x0, -_deck_y, _deck_z0])
        cube([_deck_x1 - _deck_x0, 2 * _deck_y, _deck_t]);
}

module chassis_bar() {
    // slotted anchor bar under the spring, spanning the walls
    difference() {
        translate([_ax - 3.3, -_wall_in - 1, _bar_bot])
            cube([6.6, 2 * _wall_in + 2, _bar_top - _bar_bot]);
        // slot is cut through the bar's full height so the tab can seat
        translate([_ax - _slot_w / 2, -_wall_in - 2, _bar_bot - 0.5])
            cube([_slot_w, 2 * _wall_in + 4, 3.5]);
    }
    // legs welding the bar into both walls
    for (sy = [-1, 1])
        translate([_ax - 3.3, sy == -1 ? -_wall_in - 2 : _wall_in - 0.1,
                   _bar_bot])
            cube([6.6, 2.1, _wall_bot - _bar_bot + 0.2]);
}

module chassis_pawl() {
    // flexible blade hanging from the deck beside the ratchet; the
    // tooth points -x into the teeth; release paddle at the bottom tip
    bx = _ax + _pawl_x;
    translate([bx, -12.7, _az - 5])
        cube([_pawl_t, 4.7, _deck_z0 - _az + 5.1]);
    // tooth: prism across the ratchet's y-band (profile in xz)
    translate([bx + 0.01, -9.4, 0])
        rotate([90, 0, 0])
            linear_extrude(3.2)
                polygon([[0, _az - 4.2], [0, _az - 1.2],
                         [_pawl_tip_r * cos(_pawl_az) - _pawl_x,
                          _az + _pawl_tip_r * sin(_pawl_az)]]);
    // release paddle
    translate([bx, -12.7, _az - 5]) cube([2.5, 4.7, 2]);
}

module chassis() {
    chassis_deck();
    chassis_walls();
    chassis_bar();
    chassis_pawl();
}

// ---- Display ------------------------------------------------------------

module chassis_printed() {
    // deck-side down on the plate
    translate([0, 0, _deck_z0 + _deck_t]) rotate([180, 0, 0]) chassis();
}

module show_all() {
    color("SteelBlue") chassis_printed();
    color("Orange") translate([45, -22, 0]) spring_part();
    color("YellowGreen") translate([45, 14, 0]) arbor_part();
    color("Tomato") translate([82, 14, 0]) legaxle_part();
    color("Gold") translate([82, -22, 0]) cam2_part();
}

module show_assembled() {
    color("SteelBlue") chassis();
    color("Orange") spring_assembled();
    color("YellowGreen") arbor_at();
    color("Tomato") legaxle_at();
    color("Gold") cam2_at();
}

if (_display_mode == "all") {
    show_all();
} else if (_display_mode == "assembled") {
    show_assembled();
} else if (_display_mode == "chassis") {
    chassis_printed();
} else if (_display_mode == "spring") {
    spring_part();
} else if (_display_mode == "arbor") {
    arbor_part();
} else if (_display_mode == "legaxle") {
    legaxle_part();
} else if (_display_mode == "cam") {
    cam2_part();
}
