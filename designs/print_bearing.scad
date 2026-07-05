// @name Print-in-Place Roller Bearing
// @description A roller bearing that prints fully assembled: chamfered cylindrical rollers captive between interlocking V-lipped races. Spins after a first gentle twist.
// @tags bearing, print-in-place, mechanical, roller, functional
//
// Three-part-in-one bearing: an outer race, an inner race, and N
// cylindrical rollers, printed in place. Each roller is a cylinder with
// 45-degree chamfered ends; the races carry a matching toroidal channel
// (the roller profile grown by a uniform gap) whose lips overhang the
// roller chamfers at top and bottom. The lips capture the rollers
// axially and interlock the two races - the bearing cannot be
// disassembled, only spun.
//
// Roller flats stand directly on the print bed through the annular
// opening between the race lips; the chamfer regions bridge the gap onto
// the 45-degree race surfaces below (standard print-in-place practice).
//
// Printing:
//   - Print flat as it comes, no supports (all overhangs are 45 degrees)
//   - 0.2mm layers; give the first layer time to cool before twisting
//   - Break in by twisting the inner race back and forth
//
// Modes: "bearing" = the printable assembly (default gallery view),
// "cutaway" = bearing minus a 90-degree wedge so the roller capture is
// visible, "races" = axially exploded (races + roller ring separated).

/* [Bearing Dimensions] */
// Outer diameter of the bearing (mm)
outer_diameter = 40; // [25:1:80]

// Bore (inner race hole) diameter (mm)
bore_diameter = 15; // [6:1:40]

// Bearing height (mm)
height = 12; // [8:1:24]

// Number of rollers
roller_count = 8; // [5:1:16]

/* [Fit] */
// Printed gap around every roller (mm) - tune for your printer
roller_gap = 0.4; // [0.25:0.05:0.6]

// Radial wall thickness of each race outside the groove (mm)
race_wall = 3; // [2:0.5:6]

/* [Display] */
// What to show
_display_mode = "bearing"; // ["bearing", "cutaway", "races"]

/* [Advanced] */
$fn = 72;


// ---- Derived ----

_r_out = outer_diameter / 2;
_r_bore = bore_diameter / 2;
_r_pitch = (_r_out + _r_bore) / 2;        // roller axis circle

// Roller radius fills the radial budget between the two race walls,
// minus the running gap on each side.
_roller_r = (_r_out - _r_bore - 2 * race_wall) / 2 - roller_gap;
_roller_d = 2 * _roller_r;

// 45-degree end chamfer: the race lips overhang this much. Clamped so
// the roller keeps a flat end wide enough to stand on the bed, and so
// the lip engagement always exceeds the printed gap.
_chamfer = min(_roller_r * 0.45, height * 0.2);

// Radial half-width of the annular opening between the lips (the
// roller's flat end plus the gap passes through it; the chamfered
// shoulder does not).
_lip_open_r = _roller_r - _chamfer + roller_gap;

// Roller center-to-center chord; rollers need daylight between them.
_roller_chord = 2 * _r_pitch * sin(180 / roller_count);
_max_rollers = floor(180 / asin((_roller_d + 0.8) / (2 * _r_pitch)));

assert(_r_out - _r_bore >= 2 * race_wall + 3,
    str("No radial room for rollers: (OD-ID)/2 = ", _r_out - _r_bore,
        "mm must exceed 2*race_wall + 3 = ", 2 * race_wall + 3, "mm."));
assert(_roller_r >= 1.5,
    str("Rollers too thin (r=", _roller_r, "mm): increase OD, or reduce ",
        "bore_diameter/race_wall."));
assert(_chamfer >= roller_gap + 0.3,
    str("Lip engagement too shallow: chamfer ", _chamfer, "mm must exceed ",
        "roller_gap + 0.3 = ", roller_gap + 0.3,
        "mm. Increase height or roller size."));
assert(_roller_chord >= _roller_d + 0.8,
    str(roller_count, " rollers of d=", _roller_d,
        "mm do not fit the pitch circle with 0.8mm spacing: max ",
        _max_rollers, " rollers at these dimensions."));

// Accessors for the verification harness
function roller_angle(i) = i * 360 / roller_count;
function roller_pitch_r() = _r_pitch;
function bearing_gap() = roller_gap;
function roller_pitch_angle() = 360 / roller_count;


// ---- Modules ----

// One roller: a cylinder with 45-degree chamfered ends, axis vertical,
// standing at the origin from z=0 to z=height.
module roller() {
    rotate_extrude($fn = 48)
        polygon([
            [0, 0],
            [_roller_r - _chamfer, 0],
            [_roller_r, _chamfer],
            [_roller_r, height - _chamfer],
            [_roller_r - _chamfer, height],
            [0, height]
        ]);
}

// Roller i in its printed position.
module roller_at(i) {
    rotate([0, 0, roller_angle(i)])
        translate([_r_pitch, 0, 0])
            roller();
}

// The full roller set, rotated by `spin` degrees about the bearing axis.
module rollers(spin = 0) {
    rotate([0, 0, spin])
        for (i = [0 : roller_count - 1])
            roller_at(i);
}

// Toroidal channel carved into the races: the roller cross-section
// (in the r-z plane through the bearing axis) grown by a uniform
// roller_gap, revolved about the bearing axis. The offset makes the
// cutter overshoot the top and bottom faces by the gap, opening an
// annular slot just wide enough for the roller flats - the lips it
// leaves behind overhang the roller chamfers and capture everything.
module race_channel() {
    rotate_extrude()
        offset(r = roller_gap)
            polygon([
                [_r_pitch - _roller_r + _chamfer, 0],
                [_r_pitch + _roller_r - _chamfer, 0],
                [_r_pitch + _roller_r, _chamfer],
                [_r_pitch + _roller_r, height - _chamfer],
                [_r_pitch + _roller_r - _chamfer, height],
                [_r_pitch - _roller_r + _chamfer, height],
                [_r_pitch - _roller_r, height - _chamfer],
                [_r_pitch - _roller_r, _chamfer]
            ]);
}

// Inner race: bore-to-groove ring with the channel cut away.
module inner_race() {
    difference() {
        rotate_extrude()
            polygon([
                [_r_bore, 0], [_r_pitch, 0],
                [_r_pitch, height], [_r_bore, height]
            ]);
        race_channel();
    }
}

// Outer race: groove-to-OD ring with the channel cut away.
module outer_race() {
    difference() {
        rotate_extrude()
            polygon([
                [_r_pitch, 0], [_r_out, 0],
                [_r_out, height], [_r_pitch, height]
            ]);
        race_channel();
    }
}


// ---- Display ----

module show_bearing() {
    color("SteelBlue") outer_race();
    color("LightSteelBlue") inner_race();
    color("Orange") rollers();
}

// Bearing minus a 90-degree wedge over the first quadrant. Rollers whose
// bodies would be sliced by the wedge planes are omitted entirely, so
// every remaining part is a clean whole body.
module show_cutaway() {
    _margin = asin((_roller_r + roller_gap + 0.4) / _r_pitch);
    difference() {
        union() {
            color("SteelBlue") outer_race();
            color("LightSteelBlue") inner_race();
        }
        translate([0, 0, -1])
            cube([_r_out + 1, _r_out + 1, height + 2]);
    }
    for (i = [0 : roller_count - 1]) {
        a = roller_angle(i);
        if (a > 90 + _margin && a < 360 - _margin)
            color("Orange") roller_at(i);
    }
}

// Axially exploded view: outer race on the plate, roller ring above it,
// inner race on top. (The printed bearing cannot actually be taken
// apart - this view is how it would look if it could.)
module show_races() {
    _lift = height + 8;
    color("SteelBlue") outer_race();
    translate([0, 0, _lift]) color("Orange") rollers();
    translate([0, 0, 2 * _lift]) color("LightSteelBlue") inner_race();
}

if (_display_mode == "bearing") {
    show_bearing();
} else if (_display_mode == "cutaway") {
    show_cutaway();
} else if (_display_mode == "races") {
    show_races();
}
