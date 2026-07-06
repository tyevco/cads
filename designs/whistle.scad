// @name Helmholtz Whistle
// @description Pea-less referee-style whistle whose chamber is sized from the Helmholtz equation to hit a target frequency (default 2500 Hz). Two pieces: body plus glue-in side cap, with a lanyard ring.
// @tags whistle, acoustics, helmholtz, referee, parametric, two-piece
//
// PHYSICS - Helmholtz resonator:
//
//     f = (c / 2*pi) * sqrt( A / (V * Leff) )
//
//   c    = speed of sound, 343 m/s (343000 mm/s) at 20 C
//   A    = duct exit area = duct_w * duct_h                     [mm^2]
//   Leff = duct_len + 1.7 * r_eq   (flanged-end correction),
//          r_eq = sqrt(A/pi) = equivalent duct radius           [mm]
//   V    = resonant chamber volume                              [mm^3]
//
// This file INVERTS the formula to size the chamber from the target
// frequency:  V = c^2 * A / (4*pi^2 * f^2 * Leff).  The chamber is a
// cylinder lying ACROSS the body (axis = X), interior width equal to
// duct_w, so its diameter is  D = 2 * sqrt( V / (pi * duct_w) ).
//
// Defaults:  A = 28 mm^2, r_eq = 2.985 mm, Leff = 21.075 mm
//            -> V = 633.5 mm^3 -> chamber D = 10.04 mm -> f = 2500 Hz.
// The formula is a lumped-element model; the real note also depends on
// blowing pressure and the jet/labium interaction (expect a few percent).
//
// GEOMETRY (referee-whistle cross-section, all in the YZ plane):
//   - Mouthpiece duct: rectangular windway, floor at z=0, from the mouth
//     face (y=0) to the window (y=duct_len).
//   - Window + labium: an opening in the top from the duct exit to a
//     SHARP wedge edge (the labium) at height labium_h (~0.4*duct_h),
//     which splits the air jet.  The wedge top rises at labium_angle.
//   - Chamber: transverse cylinder tangent-crossing the duct floor plane
//     so the window opens straight into it (the "mouth" of the resonator).
//
// TWO PIECES - why: the chamber is a closed transverse cylinder.  Printed
// in one piece it would need either internal supports (impossible to
// remove, wrecks the resonance) or a long flat bridge across the chamber
// ceiling (saggy, leaky).  Instead the body prints lying on its side, so
// every cavity wall is vertical and support-free, and the chamber's open
// side is sealed by a flat cap: plug depth = wall thickness, so the plug
// face sits exactly flush with the interior wall and the chamber volume
// is preserved.  Glue the cap on (the 0.12 mm radial glue gap adds
// ~1.8% of V while the glue cures - within the model's accuracy).
//
// PRINT: no supports.  "all" mode is the print layout - body on its
// side, cap flange-down.  0.2 mm layers, 100% infill recommended (a
// stiff shell gives a cleaner tone).
//
// ASSEMBLY: drop of CA glue around the cap plug, press flush, wipe.
// Thread a lanyard through the ring under the mouthpiece.
//
// Modes: "all" = print layout (2 bodies); "body" / "cap" = single
// pieces; "cutaway" = body halved lengthwise, upright, showing the
// duct, window, labium wedge and chamber.

/* [Acoustics] */
// Target fundamental frequency (Hz)
target_hz = 2500; // [1800:100:3200]
// Speed of sound (m/s) - 343 at 20 C
speed_of_sound = 343; // [330:1:355]

/* [Duct] */
// Duct (windway) width across the whistle; also the chamber interior width (mm)
duct_w = 8; // [6:0.5:10]
// Duct height (mm)
duct_h = 3.5; // [2.5:0.25:4.5]
// Duct length, mouth face to window (mm)
duct_len = 16; // [12:1:22]

/* [Fipple] */
// Window length, duct exit to labium edge (mm)
win_len = 7; // [5:0.5:9]
// Labium edge height above the duct floor (mm) - ~40% of duct height
labium_h = 1.4; // [0.8:0.1:2.2]
// Labium wedge angle above horizontal (degrees)
labium_angle = 28; // [20:1:35]

/* [Build] */
// Wall thickness (mm)
wall = 2.4; // [2:0.2:3.2]
// Radial glue clearance, cap plug to chamber bore (mm)
cap_clearance = 0.12; // [0.05:0.01:0.25]

/* [Display] */
// What to show
_display_mode = "all"; // ["all", "body", "cap", "cutaway"]

/* [Advanced] */
// Resolution
$fn = 64;
// Chamber / cap facets (higher = truer chamber volume)
_fn_chamber = 96;

// ---- Helmholtz sizing (mm units; c in mm/s) --------------------------
_c = speed_of_sound * 1000;              // mm/s
_A = duct_w * duct_h;                    // duct exit area, mm^2
_r_eq = sqrt(_A / PI);                   // equivalent duct radius, mm
_Leff = duct_len + 1.7 * _r_eq;          // neck + end correction, mm
// Invert f = (c/2pi)*sqrt(A/(V*Leff))  ->  chamber volume, mm^3
_V_req = _c * _c * _A / (4 * PI * PI * target_hz * target_hz * _Leff);
// Chamber: cylinder along X, interior width duct_w -> diameter
_r_ch = sqrt(_V_req / (PI * duct_w));    // chamber interior radius
_f_check = _c / (2 * PI) * sqrt(_A / (_V_req * _Leff));

echo(str("Helmholtz sizing: A=", _A, " mm^2  r_eq=", _r_eq,
    " mm  Leff=", _Leff, " mm  V=", _V_req, " mm^3  chamber D=",
    2 * _r_ch, " mm  -> predicted f=", _f_check, " Hz"));
assert(abs(_f_check - target_hz) < 0.01 * target_hz,
    "internal error: inverted Helmholtz formula does not round-trip");

// ---- Derived geometry ------------------------------------------------
_w_in = duct_w;                          // interior width (X)
_w_out = _w_in + 2 * wall;               // exterior width (X)
_mouth_t = 3;                            // outer shell above/below duct at mouth
_r_m = 1.8;                              // mouthpiece profile corner radius
_y_edge = duct_len + win_len;            // labium edge Y
// Chamber crosses the duct-floor plane (z=0) so the window opens into it.
// Half-chord of that crossing = win_len/2 + 0.3 so both window-cutter
// bottom corners land strictly INSIDE the cavity (no tangent contacts).
_hc = win_len / 2 + 0.3;
assert(_r_ch > _hc + 0.15, str("Chamber radius ", _r_ch,
    " mm is too small for a ", win_len,
    " mm window: shorten win_len, enlarge the duct, or lower target_hz"));
_y_c = duct_len + win_len / 2 + 0.15;    // chamber center Y
_z_c = -sqrt(_r_ch * _r_ch - _hc * _hc); // chamber center Z (below floor)
_r_out = _r_ch + wall;                   // chamber outer radius
_z_sky = duct_h + _mouth_t + _r_ch + 10; // safely above any body surface
_lab_run = (_z_sky - labium_h) / tan(labium_angle);

// Lanyard ring: centered on the chord between the mouthpiece bottom
// point and the chamber bottom point (both on the body, so the chord is
// inside the convex hull => the ring is always welded to the body).
// The ring slides forward (toward the mouth) until its hole clears the
// chamber cavity by >= 1.2 mm of wall.
_ring_r = 4;
_ring_hole_r = 2.2;
_zb_mouth = -_mouth_t;                   // mouth-bottom point (y=_r_m)
_zb_ch = _z_c - _r_out;                  // chamber bottom point (y=_y_c)
function _ring_z_at(y) =
    _zb_mouth + (y - _r_m) / (_y_c - _r_m) * (_zb_ch - _zb_mouth);
function _ring_ok(y) =
    norm([_y_c - y, _z_c - _ring_z_at(y)]) >= _r_ch + _ring_hole_r + 1.2;
function _find_ring_y(y) = y < _ring_r ? -1
    : _ring_ok(y) ? y : _find_ring_y(y - 0.25);
_y_r = _find_ring_y(6);
assert(_y_r > 0,
    "No room for the lanyard ring in front of the chamber - lower target_hz or lengthen duct_len");
_z_r = _ring_z_at(_y_r);
assert(_z_r + _ring_hole_r <= -1.2, str("Lanyard hole (top at ",
    _z_r + _ring_hole_r, " mm) leaves <1.2 mm under the duct floor - ",
    "lower target_hz or shrink the duct"));

// Cap: plug fills the wall opening flush with the chamber interior wall
_flange_r = _r_ch + wall - 0.3;          // always inside the side face
_flange_t = 2.2;
_plug_r = _r_ch - cap_clearance;

// Body extents (for print placement / cutaway)
_z_top = max(duct_h + _mouth_t, _z_c + _r_out);
_z_lo = min(_zb_ch, _z_r - _ring_r);

// ---- Body ------------------------------------------------------------

// 2D outline in the (y,z) plane
module _body_profile() {
    hull() {
        translate([_r_m, duct_h + _mouth_t - _r_m]) circle(r = _r_m);
        translate([_r_m, -_mouth_t + _r_m]) circle(r = _r_m);
        translate([_y_c, _z_c]) circle(r = _r_out);
    }
    translate([_y_r, _z_r]) circle(r = _ring_r);
}

// Solid body before any cavity is cut (public: used by the volume harness)
module body_envelope() {
    translate([-_w_out / 2, 0, 0])
        rotate([90, 0, 90])                 // 2D x->Y, 2D y->Z, extrude->X
            linear_extrude(height = _w_out) _body_profile();
}

// The resonant chamber cavity, exactly as subtracted from the body
// (public: the harness intersects this with body_envelope() and measures
// the mesh volume to verify the Helmholtz sizing).
module chamber_cavity() {
    translate([-_w_in / 2, _y_c, _z_c])
        rotate([0, 90, 0])
            cylinder(h = _w_in, r = _r_ch, $fn = _fn_chamber);
}

// Rectangular windway; floor at z=0. Overshoots the mouth face and pokes
// 0.3 mm past the window start so the two cutters overlap in volume.
module _duct_cutter() {
    translate([-_w_in / 2, -1, 0])
        cube([_w_in, duct_len + 1.3, duct_h]);
}

// Window opening + labium wedge: vertical face under the sharp edge at
// (_y_edge, labium_h), then the wedge top rising at labium_angle.
module _window_cutter() {
    translate([-_w_in / 2, 0, 0])
        rotate([90, 0, 90])
            linear_extrude(height = _w_in)
                polygon([[duct_len, 0], [_y_edge, 0], [_y_edge, labium_h],
                         [_y_edge + _lab_run, _z_sky], [duct_len, _z_sky]]);
}

// Side opening for the cap plug (same bore as the chamber, coaxial)
module _cap_bore() {
    translate([_w_in / 2 - 0.1, _y_c, _z_c])
        rotate([0, 90, 0])
            cylinder(h = wall + 1, r = _r_ch, $fn = _fn_chamber);
}

module _ring_hole() {
    translate([-_w_out / 2 - 0.5, _y_r, _z_r])
        rotate([0, 90, 0])
            cylinder(h = _w_out + 1, r = _ring_hole_r);
}

module whistle_body() {
    difference() {
        body_envelope();
        _duct_cutter();
        _window_cutter();
        chamber_cavity();
        _cap_bore();
        _ring_hole();
    }
}

// Print pose: lying on its flat -X side face, every cavity wall vertical
module body_print() {
    translate([0, 0, _w_out / 2]) rotate([0, -90, 0]) whistle_body();
}

// ---- Cap (modeled in print pose: flange down on the plate) ------------
module whistle_cap() {
    cylinder(h = _flange_t, r = _flange_r, $fn = _fn_chamber);
    translate([0, 0, _flange_t - 0.1])
        cylinder(h = wall + 0.1, r = _plug_r, $fn = _fn_chamber);
}

// Cap in its glued position on the +X face (public: fit-test harness)
module cap_assembled() {
    translate([_w_out / 2 + _flange_t, _y_c, _z_c])
        rotate([0, -90, 0]) whistle_cap();
}

// ---- Display ----------------------------------------------------------
if (_display_mode == "all") {
    color("Gold") body_print();
    color("OrangeRed")
        translate([-_z_lo + _flange_r + 8, _y_c, 0]) whistle_cap();
} else if (_display_mode == "body") {
    color("Gold") body_print();
} else if (_display_mode == "cap") {
    color("OrangeRed") whistle_cap();
} else if (_display_mode == "cutaway") {
    // Halved on the mid-plane, stood upright: duct, window, labium
    // wedge and chamber all visible in section.
    color("Gold") translate([0, 0, -_z_lo])
        difference() {
            whistle_body();
            translate([0, -5, _z_lo - 5])
                cube([_w_out, _y_edge + _lab_run + 10,
                      _z_top - _z_lo + 20]);
        }
}
