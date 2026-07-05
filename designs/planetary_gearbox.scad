// @name Planetary Gearbox Fidget
// @description A planetary gear fidget: spin the sun knob and three free planets orbit inside a fixed ring gear housing, retained by a snap-on cover.
// @tags toy, fidget, gears, planetary, mechanical, educational
//
use <../macros/gears.scad>
//
// A round housing with an internal ring gear and a center post. A sun
// gear with a grip knob rides on the post; free planet gears (no pins)
// mesh with both the sun and the fixed ring, trapped in the annular
// channel between the bottom plate and a snap-on cover ring. Spin the
// knob and the planets both spin and orbit (they carry themselves like
// an epicyclic with a virtual carrier).
//
// Retainer choice: a SNAP-ON COVER RING (not an integrated lip).
// An integrated lip would overhang the open gear channel (needs
// supports right above the moving teeth) and would block dropping the
// planets in. The cover prints flat as a separate ring, the parts drop
// in from the top, and a chamfered rim ridge snaps into a groove inside
// the housing wall. The groove leaves one 0.5mm-wide internal bridge
// ring in the housing - trivially printable.
//
// Pieces (print layout "all"): housing, cover ring, sun+knob,
// planet_count planets. Everything prints flat, no supports.
//
// Assembly: drop the sun over the center post, drop the planets into
// the channel (wiggle until teeth seat), press the cover in until it
// clicks. The knob protrudes through the cover's center hole.
//
// -------------------------------------------------------------------
// PLANET PHASE DERIVATION (why every planet meshes sun AND ring)
//
// Tooth counts: sun ts, planet tp, ring tr = ts + 2*tp (kinematic
// identity: sun-planet center distance (ts+tp)*m/2 must equal the
// ring-planet center distance (tr-tp)*m/2). With the ring fixed,
// driving the sun by theta moves the virtual carrier by
//   c(theta) = theta * ts/(ts+tr)                        (Willis)
// so planet i's center sits at angle  a_i = i*360/N + c(theta).
//
// Give the planet the spin required by its SUN mesh (library formula):
//   p_i = gear_mesh_rotation(theta + s0, ts, tp, a_i)
//       = -(theta + s0 - a_i)*ts/tp + a_i + 180 - 180/tp
// where s0 is a fixed phase added to the sun. The RING mesh is
// satisfied iff the ring rotation implied by that planet spin,
//   gear_ring_mesh_rotation(p_i, tp, tr, a_i) = (p_i - a_i)*tp/tr + a_i
// is a multiple of the ring's tooth pitch 360/tr. Substituting p_i and
// a_i and simplifying (the theta terms cancel exactly - the mesh holds
// while turning, not just at one pose):
//   implied_ring = i*(360/N)*(ts+tr)/tr + (180*(tp-1) - s0*ts)/tr
// Term 1 is i*((ts+tr)/N)*(360/tr): a multiple of 360/tr for EVERY
// planet i precisely when N divides (ts+tr) - that is the divisibility
// assert below. Term 2 vanishes when
//   s0 = 180*(tp-1)/ts
// which is the constant sun phase used here. The ring profile is
// tr-fold symmetric, so implied_ring = 0 (mod 360/tr) means the fixed
// ring meshes every planet at every drive angle.
// -------------------------------------------------------------------

/* [Gear Configuration] */
// Number of teeth on the sun gear
sun_teeth = 12; // [8:1:20]

// Number of teeth on each planet gear (ring teeth are derived: sun + 2*planet)
planet_teeth = 9; // [6:1:15]

// Number of planet gears (planet_count must divide sun_teeth + ring_teeth)
planet_count = 3; // [2:1:6]

/* [Gear Dimensions] */
// Module (tooth size factor, mm) - standard gear parameter
gear_module = 2.5; // [1.5:0.5:4]

// Gear thickness (mm)
gear_thickness = 8; // [5:1:12]

/* [Housing] */
// Bottom plate thickness (mm)
plate_thickness = 4; // [3:1:6]

// Solid rim outside the ring gear teeth (mm)
ring_rim = 4; // [3:1:8]

// Center post diameter (mm) - the sun spins on this
post_diameter = 8; // [6:1:10]

// Sun knob diameter (mm) - must fit through the cover's center hole
knob_diameter = 22; // [14:2:26]

// How far the knob sticks out above the housing rim (mm)
knob_grip = 4; // [2:1:8]

/* [Tolerances] */
// Backlash between gear teeth (mm). The trapezoidal flanks are not
// conjugate; 0.5 is verified collision-free at module 2.5.
tooth_clearance = 0.5; // [0.3:0.1:1]

// Radial clearance between sun bore and post (mm, per side)
bore_clearance = 0.3; // [0.1:0.1:0.6]

// Vertical clearance between gear tops and the cover underside (mm)
vertical_clearance = 0.6; // [0.3:0.1:1.2]

/* [Display] */
// What to show
_display_mode = "all"; // ["all", "housing", "sun", "planet", "cover", "assembled"]

// Drive angle of the sun for the assembled view (animates the mechanism)
_drive_angle = 0; // [0:5:360]

/* [Advanced] */
$fn = 60;

// ---- Derived geometry ----

_ring_teeth = sun_teeth + 2 * planet_teeth;

_sun_pitch_r    = gear_pitch_radius(sun_teeth, gear_module);
_sun_outer_r    = _sun_pitch_r + gear_module * 0.9;
_sun_root_r     = _sun_pitch_r - gear_module * 1.1;
_planet_pitch_r = gear_pitch_radius(planet_teeth, gear_module);
_planet_outer_r = _planet_pitch_r + gear_module * 0.9;
_ring_pitch_r   = gear_pitch_radius(_ring_teeth, gear_module);
_ring_cut_r     = _ring_pitch_r + gear_module * 0.9; // ring tooth roots

// Radius of the planet orbit (= sun-planet center distance, see header)
_carrier_r = gear_ring_center_distance(_ring_teeth, planet_teeth, gear_module);

_housing_outer_r = _ring_cut_r + ring_rim;
_wall_inner_r    = _ring_cut_r + 1.25;   // smooth upper wall the cover drops into
_cover_outer_r   = _wall_inner_r - 0.2;  // running fit into the wall
_ridge_r         = 0.6;                  // snap ridge protrusion beyond cover rim
_groove_depth    = 0.8;                  // snap groove depth into the wall
_cover_t         = 3;

_channel_top  = plate_thickness + gear_thickness + vertical_clearance; // cover ledge
_wall_h       = 4.5;
_housing_top  = _channel_top + _wall_h;

_post_r   = post_diameter / 2;
_post_h   = gear_thickness + 2;                 // above the plate
_sun_bore = post_diameter + 2 * bore_clearance;

_knob_r = knob_diameter / 2;
_knob_h = _housing_top + knob_grip - plate_thickness - gear_thickness;
_cover_hole_r = _knob_r + 1.0;                  // knob turns freely in the hole

// Sun phase making every planet's ring mesh consistent (see header)
_sun_phase = 180 * (planet_teeth - 1) / sun_teeth;

// ---- Constraint asserts ----

// Kinematic identity: ring teeth must equal sun + 2*planet so the two
// center distances coincide (guards the derivation above).
assert(_ring_teeth == sun_teeth + 2 * planet_teeth,
    str("Ring teeth ", _ring_teeth, " != sun + 2*planet = ",
        sun_teeth + 2 * planet_teeth));

// Evenly-spaced planets can only all mesh if N divides (ts + tr)
assert((sun_teeth + _ring_teeth) % planet_count == 0,
    str("planet_count ", planet_count, " must divide sun+ring teeth = ",
        sun_teeth + _ring_teeth, "; pick a divisor (e.g. 2, 3, or ",
        (sun_teeth + _ring_teeth) % 3 == 0 ? 3 : 6, ")"));

// Positive running clearances
assert(tooth_clearance > 0, "tooth_clearance must be positive");
assert(bore_clearance > 0, "bore_clearance must be positive");
assert(vertical_clearance > 0, "vertical_clearance must be positive");

// Adjacent planets must not touch (1mm minimum gap)
assert(planet_count < 2 ||
       2 * _carrier_r * sin(180 / planet_count) >= 2 * _planet_outer_r + 1,
    str("Planets collide: adjacent centers ",
        2 * _carrier_r * sin(180 / planet_count), "mm apart but planets are ",
        2 * _planet_outer_r, "mm wide - fewer planets or more teeth"));

// Sun must keep a wall around its bore
assert(_sun_root_r >= _sun_bore / 2 + 2,
    str("Sun bore ", _sun_bore, " leaves <2mm wall at root radius ",
        _sun_root_r, " - smaller post or bigger sun"));

// Cover must retain the sun (hole smaller than the sun teeth)...
assert(_sun_outer_r - _cover_hole_r >= 1.5,
    str("Cover hole r", _cover_hole_r, " too big to retain sun (outer r",
        _sun_outer_r, ") - smaller knob_diameter"));
// ...and the planets
assert(_carrier_r + _planet_outer_r - _cover_hole_r >= 2,
    "Cover hole too big to retain planets");

// Planets orbit clear of the center post
assert(_carrier_r - _planet_outer_r >= _post_r + 1,
    str("Planets hit the center post: inner reach ",
        _carrier_r - _planet_outer_r, " vs post radius ", _post_r));

// ---- Kinematics (also used by the verification harness) ----

function num_planets() = planet_count;

// Virtual carrier angle for sun drive angle t (fixed ring, Willis)
function carrier_angle(t) = t * sun_teeth / (sun_teeth + _ring_teeth);

// Absolute sun rotation (drive angle + meshing phase)
function sun_angle(t) = t + _sun_phase;

// Planet i center angle / position on the carrier circle
function planet_center_angle(i, t) = i * 360 / planet_count + carrier_angle(t);
function planet_position(i, t) =
    [_carrier_r * cos(planet_center_angle(i, t)),
     _carrier_r * sin(planet_center_angle(i, t))];

// Planet i spin: sun-mesh formula; ring mesh follows (header derivation)
function planet_spin(i, t) =
    gear_mesh_rotation(sun_angle(t), sun_teeth, planet_teeth,
                       planet_center_angle(i, t));

// Assembled z levels (0.05 display epsilon above the resting faces)
function gear_bottom_z() = plate_thickness + 0.05;
function cover_bottom_z() = _channel_top + 0.05;

// ---- Part modules ----

// Housing: bottom plate + center post + ring gear + snap-groove wall
module housing_part() {
    // Bottom plate
    cylinder(r=_housing_outer_r, h=plate_thickness);

    // Center post (sunk 0.05 into the plate), chamfered tip for the sun
    translate([0, 0, plate_thickness - 0.05]) {
        cylinder(r=_post_r, h=_post_h - 0.55);
        translate([0, 0, _post_h - 0.56])
            cylinder(r1=_post_r, r2=_post_r - 0.6, h=0.61);
    }

    // Ring gear section: teeth from the plate up to the cover ledge
    translate([0, 0, plate_thickness - 0.05])
        linear_extrude(height=_channel_top - plate_thickness + 0.05)
            gear_ring_2d(_ring_teeth, gear_module, tooth_clearance,
                         rim=ring_rim);

    // Upper wall with internal snap groove (revolved profile).
    // Groove: recess z ledge+1.5..ledge+3.0, then a 0.3 chamfer and a
    // 0.5mm bridge ring back to the wall inner face.
    _zl = _channel_top - 0.05;
    _g0 = _channel_top + 1.5;
    _g1 = _channel_top + 3.0;
    _zt = _channel_top + _wall_h;
    rotate_extrude()
        polygon([
            [_wall_inner_r, _zl],
            [_wall_inner_r, _g0],
            [_wall_inner_r + _groove_depth, _g0],
            [_wall_inner_r + _groove_depth, _g1],
            [_wall_inner_r + 0.5, _g1 + 0.3],
            [_wall_inner_r, _g1 + 0.3],
            [_wall_inner_r, _zt - 0.5],
            [_wall_inner_r + 0.5, _zt],       // lead-in chamfer for the cover
            [_housing_outer_r, _zt],
            [_housing_outer_r, _zl]
        ]);
}

// Sun gear + grip knob, through-bore for the post
module sun_part() {
    difference() {
        union() {
            linear_extrude(height=gear_thickness)
                gear_spur_2d(sun_teeth, gear_module, tooth_clearance);
            // Knob (sunk 0.05 into the gear top)
            translate([0, 0, gear_thickness - 0.05])
                cylinder(r=_knob_r, h=_knob_h + 0.05);
        }
        // Through bore
        translate([0, 0, -0.1])
            cylinder(d=_sun_bore, h=gear_thickness + _knob_h + 0.2);
        // Bore entry chamfer (post lead-in)
        translate([0, 0, -0.01])
            cylinder(d1=_sun_bore + 1.2, d2=_sun_bore, h=0.61);
        // Grip flutes around the knob rim
        for (i = [0:11]) {
            rotate([0, 0, i * 30])
                translate([_knob_r + 0.9, 0, gear_thickness - 0.3])
                    cylinder(r=1.5, h=_knob_h + 0.9, $fn=16);
        }
    }
}

// One free planet gear (no bore - it rides loose in the channel)
module planet_part() {
    linear_extrude(height=gear_thickness)
        gear_spur_2d(planet_teeth, gear_module, tooth_clearance);
}

// Snap-on cover ring: flat annulus with a chamfered snap ridge on the
// outer rim (revolved profile, local z = 0.._cover_t)
module cover_part() {
    _or = _cover_outer_r;
    rotate_extrude()
        polygon([
            [_cover_hole_r, 0],
            [_or, 0],
            [_or, 1.6],
            [_or + _ridge_r, 2.2],   // 45-degree insertion lead-in
            [_or + _ridge_r, 2.8],
            [_or, 2.8],              // square top face = retention
            [_or, _cover_t],
            [_cover_hole_r, _cover_t]
        ]);
}

// ---- Display ----

_part_colors = ["SlateGray", "Gainsboro", "Gold", "DodgerBlue", "Tomato",
                "LimeGreen", "Orchid", "Turquoise", "Coral"];

module show_assembled() {
    color(_part_colors[0]) housing_part();
    color(_part_colors[2])
        translate([0, 0, gear_bottom_z()])
            rotate([0, 0, sun_angle(_drive_angle)])
                sun_part();
    for (i = [0:planet_count - 1]) {
        color(_part_colors[3 + i % 6])
            translate(concat(planet_position(i, _drive_angle),
                             [gear_bottom_z()]))
                rotate([0, 0, planet_spin(i, _drive_angle)])
                    planet_part();
    }
    color(_part_colors[1])
        translate([0, 0, cover_bottom_z()])
            cover_part();
}

// Print layout: housing and cover side by side, sun + planets in a row
// below, spaced by cumulative radii so nothing overlaps.
function planet_row_x(i) =
    i <= 0 ? _sun_outer_r + _planet_outer_r + 6 :
             planet_row_x(i - 1) + 2 * _planet_outer_r + 6;

module show_print_layout() {
    color(_part_colors[0]) housing_part();
    color(_part_colors[1])
        translate([_housing_outer_r + _cover_outer_r + _ridge_r + 6, 0, 0])
            cover_part();
    _row_y = -(_housing_outer_r + _sun_outer_r + 6);
    color(_part_colors[2]) translate([0, _row_y, 0]) sun_part();
    for (i = [0:planet_count - 1]) {
        color(_part_colors[3 + i % 6])
            translate([planet_row_x(i), _row_y, 0])
                planet_part();
    }
}

if (_display_mode == "all") {
    show_print_layout();
} else if (_display_mode == "housing") {
    housing_part();
} else if (_display_mode == "sun") {
    sun_part();
} else if (_display_mode == "planet") {
    planet_part();
} else if (_display_mode == "cover") {
    cover_part();
} else if (_display_mode == "assembled") {
    show_assembled();
}
