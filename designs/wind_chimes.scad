// @name Pentatonic Wind Chimes
// @description Five printed bars tuned to a major pentatonic scale by the free-free beam equation, with hanger disc, striker and wind catcher. String the parts with fishing line.
// @tags wind-chime, acoustics, pentatonic, music, parametric, decorative
//
// PHYSICS - fundamental of a free-free rectangular bar (Euler-Bernoulli):
//
//     f1 = (22.373 / (2*pi*L^2)) * sqrt( E*I / (rho*A) )
//
//   with I = b*h^3/12 and A = b*h  =>  sqrt(I/A) = h/sqrt(12), so
//
//     f1 = (22.373 / (2*pi*L^2)) * h * sqrt( E / (12*rho) )
//
//   E   = Young's modulus of printed PLA  ~3.5 GPa (published values for
//         solid printed PLA span roughly 2.8-4.2 GPa depending on brand,
//         infill and layer adhesion => f uncertainty around +-10%; the
//         RATIOS between bars - the musical intervals - are exact)
//   rho = density of solid PLA ~1240 kg/m^3
//   h   = bar thickness in the strike/bend direction; width b cancels.
//
// Bar lengths are found by inverting:  L = sqrt( 3.5608 * h * cb / f ),
// cb = sqrt(E/(12*rho)) (= 485.0 m/s at the defaults).  The five notes
// are the major pentatonic degrees [0,2,4,7,9] semitones above the root
// (default C6):  f_i = f_root * 2^(s_i/12).
//
// Frequency table at the defaults (C6 root, 6 mm bars, E=3.5 GPa):
//     C6  1046.5 Hz  L= 99.5 mm   hole at 22.31 mm
//     D6  1174.7 Hz  L= 93.9 mm   hole at 21.06 mm
//     E6  1318.5 Hz  L= 88.7 mm   hole at 19.88 mm
//     G6  1568.0 Hz  L= 81.3 mm   hole at 18.23 mm
//     A6  1760.0 Hz  L= 76.7 mm   hole at 17.20 mm
//
// NODAL SUSPENSION: the free-free fundamental mode shape has two nodes
// (zero-motion points) at 22.42% of the length from each end.  Each bar
// hangs from a hole drilled at 0.2242*L from its top end, so the string
// sits where the bar does not move and steals the least energy - any
// other point would damp the note almost immediately.  (The small hole
// itself shifts f1 by well under 1%.)
//
// HONESTY NOTE: PLA's internal damping (tan-delta ~0.03-0.05) is orders
// of magnitude higher than aluminium's, so these bars ring for a short
// "tock" rather than a long chime - the pitches are real and in tune,
// but this is a DECORATIVE chime set.  Print bars solid (100% infill)
// and flat, so the layers run along the length, for the best tone.
//
// BARS ARE PLAIN RECTANGULAR PRISMS on purpose: any chamfer or fillet
// would vary the cross-section along the length and invalidate the
// uniform-beam formula above.
//
// STRINGING (holes only - no printed string): a loop of line through
// each disc edge hole down to the matching bar's node hole; main cord
// and the striker/catcher line share the 4 mm center hole (cord knotted
// above, striker line knotted below - striker at bar mid-height, wind
// catcher ~100 mm below the bars).
//
// PRINT: everything flat on the plate, no supports.
// Modes: "all" = full print layout (8 bodies); "bars" = the five bars
// (5); "hanger" = disc + striker + catcher (3); "assembled" = hanging
// display arrangement, strings implied (8 bodies).

/* [Tuning] */
// Root note of the major pentatonic scale
root_note = "C6"; // ["A5", "C6", "D6", "E6"]

/* [Bars] */
// Bar width - cancels out of the pitch, sets loudness/stiffness (mm)
bar_width = 12; // [8:1:16]
// Bar thickness in the strike direction - sets the pitch scale (mm)
bar_thickness = 6; // [4:0.5:8]
// String hole diameter in bars and disc (mm)
string_hole_d = 2.5; // [2:0.25:3.5]

/* [Material - printed PLA] */
// Young's modulus of solid printed PLA (GPa)
youngs_gpa = 3.5; // [2.8:0.1:4.2]
// Density of solid PLA (kg/m^3)
density = 1240; // [1150:10:1350]

/* [Hanger] */
// Hanger disc diameter (mm)
disc_d = 72; // [60:2:90]
// Hanger disc thickness (mm)
disc_t = 4; // [3:0.5:6]
// Striker puck diameter (mm)
striker_d = 28; // [20:2:36]
// Striker puck thickness (mm)
striker_t = 8; // [6:1:12]
// Wind catcher width (mm)
catcher_d = 42; // [30:2:54]
// Wind catcher thickness (mm)
catcher_t = 2.4; // [2:0.2:3.2]

/* [Display] */
// What to show
_display_mode = "all"; // ["all", "bars", "hanger", "assembled"]

/* [Advanced] */
// Resolution
$fn = 64;

// ---- Acoustic sizing (SI internally, mm out) --------------------------
_semitones = [0, 2, 4, 7, 9];            // major pentatonic degrees
_names = root_note == "A5" ? ["A5", "B5", "C#6", "E6", "F#6"]
       : root_note == "C6" ? ["C6", "D6", "E6", "G6", "A6"]
       : root_note == "D6" ? ["D6", "E6", "F#6", "A6", "B6"]
       :                     ["E6", "F#6", "G#6", "B6", "C#7"];
_root_hz = root_note == "A5" ? 880.00
         : root_note == "C6" ? 1046.50
         : root_note == "D6" ? 1174.66
         :                     1318.51;  // E6 (equal temperament, A4=440)
_cb = sqrt(youngs_gpa * 1e9 / (12 * density));   // h-normalized bar speed, m/s
_node_frac = 0.2242;                     // free-free fundamental node

function bar_hz(i) = _root_hz * pow(2, _semitones[i] / 12);
// Invert f1 = (22.373/(2*pi*L^2)) * h * cb  ->  L (mm)
function bar_len(i) =
    sqrt(22.373 / (2 * PI) * (bar_thickness / 1000) * _cb / bar_hz(i)) * 1000;
// Hang hole center, measured from the bar's TOP end (mm)
function bar_hole_from_end(i) = _node_frac * bar_len(i);
// Hole center in the bar's own coordinates (bar spans y = 0..L, top at L)
function bar_hole_y(i) = bar_len(i) - bar_hole_from_end(i);

echo(str("Pentatonic chime bars (", root_note, " root, E=", youngs_gpa,
    " GPa, rho=", density, " kg/m^3, h=", bar_thickness, " mm):"));
for (i = [0:4])
    echo(str("  ", _names[i], "  f=", bar_hz(i), " Hz  L=", bar_len(i),
        " mm  node hole at ", bar_hole_from_end(i), " mm from top end"));

// Node holes must sit at 22.4% of L within 0.5 mm (spec check)
for (i = [0:4])
    assert(abs(bar_hole_from_end(i) - 0.224 * bar_len(i)) < 0.5,
        str("Bar ", i, " hang hole off the 22.4% nodal point"));

// ---- Geometry guards ---------------------------------------------------
assert(bar_thickness <= bar_width - 2, str("Bars must be at least 2 mm ",
    "wider than thick to print flat and bend in the tuned direction"));
assert((bar_width - string_hole_d) / 2 >= 2.5,
    "String hole leaves <2.5 mm of bar on each side");
_hang_r = disc_d / 2 - 6;                // bar-string circle on the disc
assert(2 * _hang_r * sin(36) >= bar_width + 4, str("Disc too small: ",
    "adjacent hanging bars would be <4 mm apart - enlarge disc_d"));
assert(_hang_r - bar_thickness / 2 - 3 >= striker_d / 2 + 4,
    "Striker too wide to swing between the bars - shrink striker_d or enlarge disc_d");

// ---- Parts -------------------------------------------------------------

// Uniform rectangular bar, y = 0..L, resting flat on z=0; node hole
// through the strike faces near the top (y=L) end.
module chime_bar(i) {
    difference() {
        translate([-bar_width / 2, 0, 0])
            cube([bar_width, bar_len(i), bar_thickness]);
        translate([0, bar_hole_y(i), -0.5])
            cylinder(h = bar_thickness + 1, d = string_hole_d);
    }
}

module hanger_disc() {
    difference() {
        cylinder(h = disc_t, d = disc_d);
        translate([0, 0, -0.5]) cylinder(h = disc_t + 1, d = 4); // main cord
        for (i = [0:4])
            rotate([0, 0, i * 72]) translate([_hang_r, 0, -0.5])
                cylinder(h = disc_t + 1, d = string_hole_d);
    }
}

module striker() {
    difference() {
        cylinder(h = striker_t, d = striker_d);
        translate([0, 0, -0.5]) cylinder(h = striker_t + 1, d = 3);
    }
}

// Teardrop sail, flat on the plate, line hole in the narrow end
module wind_catcher() {
    difference() {
        linear_extrude(height = catcher_t) hull() {
            circle(d = catcher_d);
            translate([0, catcher_d * 0.75]) circle(d = 8);
        }
        translate([0, catcher_d * 0.75, -0.5])
            cylinder(h = catcher_t + 1, d = 3);
    }
}

// ---- Layouts -----------------------------------------------------------
_gap = 6;
function bar_px(i) = i * (bar_width + _gap);   // equal widths, equal pitch

module bars_layout() {
    for (i = [0:4]) translate([bar_px(i), 0, 0])
        color("LightSteelBlue") chime_bar(i);
}

module hanger_layout() {
    color("SlateGray") hanger_disc();
    color("SlateGray")
        translate([0, disc_d / 2 + _gap + striker_d / 2, 0]) striker();
    color("LightSteelBlue")
        translate([-(disc_d / 2 + _gap + catcher_d / 2), 0, 0])
            wind_catcher();
}

// Assembled display: strings implied, every part separated in space.
// Bar tops hang _drop below the disc; striker at mid-bar height; the
// catcher (shortened line for display) sits at the bottom, z=0.
_drop = 12;
_Lmax = bar_len(0);
_bar_bot = catcher_t + 8;                // catcher + display gap
_z_tops = _bar_bot + _Lmax;              // all bar TOPS align here
_disc_z = _z_tops + _drop;

module assembled() {
    translate([0, 0, _disc_z]) color("SlateGray") hanger_disc();
    for (i = [0:4])
        rotate([0, 0, i * 72])
            translate([0, _hang_r + bar_thickness / 2,
                       _z_tops - bar_len(i)])
                rotate([90, 0, 0])
                    color("LightSteelBlue") chime_bar(i);
    translate([0, 0, _z_tops - 0.5 * _Lmax])
        color("SlateGray") striker();
    color("LightSteelBlue") wind_catcher();
}

// ---- Display ------------------------------------------------------------
if (_display_mode == "all") {
    bars_layout();
    translate([-_gap - 2 - disc_d / 2 - bar_width / 2, disc_d / 2, 0])
        hanger_layout();
} else if (_display_mode == "bars") {
    bars_layout();
} else if (_display_mode == "hanger") {
    hanger_layout();
} else if (_display_mode == "assembled") {
    assembled();
}
