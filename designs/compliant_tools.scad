// @name Compliant Tool Set
// @description Three one-piece spring tools - a croc clip, squeeze tongs, and a phone pinch-stand - whose leaf-spring flexures are sized by real cantilever strain math.
// @tags compliant, spring, clip, tongs, clamp, one-piece, flexure
//
// Three tools, each printed flat as ONE piece with no supports and no
// assembly - the springs are the structure:
//
//   clip  - a crocodile clip: two rigid jaws on a C-shaped leaf spring.
//           At rest the jaws sit 0.4mm apart; pushing a plate of
//           `plate_thickness` into the flared mouth spreads them and
//           the C-spring grips it.
//   tongs - squeeze tongs: a rigid back block with two long straight
//           leaf-spring arms ending in toothed pads. Squeeze to close;
//           the arms themselves are the springs.
//   clamp - a phone pinch-stand: a flat foot with two curved leaf
//           arms rising to padded jaws. Push a phone edge-first down
//           between the pads; it seats on the lips and the arms pinch
//           its faces. Best for light phones - the foot is only as
//           deep as the extrusion.
//
// Every flexure is sized with flex_stroke() from macros/flexures.scad
// (cantilever root-strain limit, eps_max = max_strain_pct, rigid-lever
// corrected). Asserts fail loudly if a parameter combination would
// yield the spring; the echo lines report the safety margins.
// Springs flex in the layer plane (bands extruded in z) - print flat
// exactly as laid out.
//
// Modes: "set" = all three tools on the plate (default, 3 bodies),
// "clip" / "tongs" / "clamp" = one tool each (1 body).

use <../macros/flexures.scad>

/* [General] */
// Working strain limit for the PLA springs, percent (0.8 = safe for repeated cycles)
max_strain_pct = 0.8; // [0.5:0.05:1.0]

/* [Clip] */
// Thickness of the plate/sheet the clip grips (mm)
plate_thickness = 3; // [1:0.5:6]

// C-spring band thickness (mm)
clip_spring_t = 1.6; // [1.2:0.1:2.2]

// Jaw length from the spring to the pad tip (mm)
clip_jaw_len = 28; // [22:1:40]

/* [Tongs] */
// Flexible arm length (mm)
tongs_arm_len = 62; // [45:1:80]

// Arm thickness - the flexing dimension (mm)
tongs_arm_t = 2.4; // [1.8:0.1:3.0]

// Opening between the pad faces at rest (mm)
tongs_gap = 7; // [4:0.5:12]

/* [Clamp] */
// Phone edge thickness the stand pinches (mm); the jaws are cut 2mm tighter
phone_thickness = 8.5; // [6:0.5:12]

// Curved arm band thickness (mm)
clamp_arm_t = 2.2; // [1.6:0.1:2.8]

/* [Display] */
// What to show
_display_mode = "set"; // ["set", "clip", "tongs", "clamp"]

/* [Advanced] */
$fn = 48;


// ---- Shared ----------------------------------------------------------

_eps = max_strain_pct / 100;

// ---- Clip: derived + mechanics ---------------------------------------

_clip_depth = 10;
_cs_half = 9;              // C-spring chord half-length
_cs_sag = 7;               // C-spring sagitta
_clip_half_gap = 0.2;      // jaw pad half-gap at rest (jaws "closed")
_clip_pad_len = 9;

// Flexure: each jaw flexes half the C-band; the rigid jaw is the lever
_clip_flex_l = leaf_length(2 * _cs_half, _cs_sag) / 2;
_clip_lever = norm([clip_jaw_len - _clip_pad_len / 2, _cs_half]);
_clip_limit = flex_stroke(_clip_flex_l, clip_spring_t, _eps, _clip_lever);
_clip_need = (plate_thickness - 2 * _clip_half_gap) / 2;   // per jaw

assert(_clip_need <= _clip_limit,
    str("Clip: gripping a ", plate_thickness, "mm plate needs ",
        _clip_need, "mm deflection per jaw but the C-spring's safe ",
        "stroke is ", _clip_limit, "mm at ", max_strain_pct,
        "% strain - thinner spring band, longer jaws, or thinner plate."));
echo(str("CLIP: need ", _clip_need, "mm/jaw, safe stroke ", _clip_limit,
         "mm, margin x", _clip_limit / _clip_need,
         " (flex L=", _clip_flex_l, " lever=", _clip_lever, ")"));

// Accessors for the verification harness: the test plate seated in the
// closed jaws (position = corner, size = box dimensions)
function clip_plate_pos() = [clip_jaw_len - _clip_pad_len - 0.5,
                             -plate_thickness / 2, -1];
function clip_plate_size() = [_clip_pad_len + 4.5, plate_thickness,
                              _clip_depth + 2];

// ---- Tongs: derived + mechanics --------------------------------------

_tg_depth = 8;
_tg_arc = 2.5;                              // slight outward bow (looks)
_tg_y0 = tongs_gap / 2 + 8;                 // arm centerline offset
_tg_tooth = 0.9;                            // grip tooth height
_tg_flex_l = leaf_length(tongs_arm_len, _tg_arc);
_tg_lever = 10;                             // rigid pad beyond the arm
_tg_limit = flex_stroke(_tg_flex_l, tongs_arm_t, _eps, _tg_lever);
_tg_need = (tongs_gap - 2 * _tg_tooth) / 2; // close to tooth contact

assert(_tg_need <= _tg_limit,
    str("Tongs: closing needs ", _tg_need, "mm per arm but the safe ",
        "stroke is ", _tg_limit, "mm - longer/thinner arms or a ",
        "smaller tongs_gap."));
echo(str("TONGS: close ", _tg_need, "mm/arm, safe stroke ", _tg_limit,
         "mm, margin x", _tg_limit / _tg_need, "; max item ~",
         tongs_gap + 2 * _tg_limit, "mm"));

// ---- Clamp: derived + mechanics --------------------------------------

_cl_depth = 20;
_cl_gap = phone_thickness - 2;   // pad gap at rest: 2mm total pinch
_cl_pad_x0 = _cl_gap / 2;        // pad inner face
_cl_root = [28, 5];              // right arm root (in the foot)
_cl_tip = [_cl_pad_x0 + 2.2, 30];// right arm tip (in the pad)
_cl_sag = 6;
_cl_chord = norm(_cl_tip - _cl_root);
_cl_ang = atan2(_cl_tip[1] - _cl_root[1], _cl_tip[0] - _cl_root[0]);
// welded root boss + pad intrusion eat ~6mm of the band
_cl_flex_l = leaf_length(_cl_chord, _cl_sag) - 6;
_cl_limit = flex_stroke(_cl_flex_l, clamp_arm_t, _eps, lever = 3);
_cl_need = 1.0;                  // (phone - gap)/2, gap = phone - 2

assert(_cl_need <= _cl_limit,
    str("Clamp: pinching the phone needs ", _cl_need, "mm per arm but ",
        "the safe stroke is ", _cl_limit, "mm - thinner arms."));
echo(str("CLAMP: pinch ", _cl_need, "mm/arm, safe stroke ", _cl_limit,
         "mm, margin x", _cl_limit / _cl_need,
         " (flex L=", _cl_flex_l, ")"));

// Verification-harness accessors: phone test plate seated on the lips
function clamp_plate_pos() = [-phone_thickness / 2, 29, -1];
function clamp_plate_size() = [phone_thickness, 21, _cl_depth + 2];


// ---- Clip geometry ----------------------------------------------------

module clip_jaw_2d() {
    hull() {
        translate([1.2, _cs_half - 0.2]) circle(2.4);
        translate([clip_jaw_len - 3, 3.6]) circle(2.0);
    }
    // pad
    translate([clip_jaw_len - _clip_pad_len, _clip_half_gap])
        square([_clip_pad_len, 3.2]);
    // flared lead-in at the mouth
    polygon([[clip_jaw_len - 0.1, _clip_half_gap],
             [clip_jaw_len + 3, _clip_half_gap + 2.3],
             [clip_jaw_len - 0.1, _clip_half_gap + 3.2]]);
}

module tool_clip() {
    // C-spring: chord vertical at x=0 from -_cs_half to +_cs_half,
    // bulging toward -x
    translate([0, -_cs_half, 0])
        rotate([0, 0, 90])
            leaf_spring(2 * _cs_half, _clip_depth, clip_spring_t, _cs_sag);
    linear_extrude(_clip_depth) clip_jaw_2d();
    linear_extrude(_clip_depth) mirror([0, 1]) clip_jaw_2d();
}

// ---- Tongs geometry ---------------------------------------------------

module tongs_pad_2d() {
    translate([tongs_arm_len - 2, tongs_gap / 2])
        square([12, _tg_y0 + tongs_arm_t / 2 - tongs_gap / 2]);
    for (k = [0 : 2])
        translate([tongs_arm_len + 0.5 + k * 3.2, 0])
            polygon([[0, tongs_gap / 2 + 0.05],
                     [2.4, tongs_gap / 2 + 0.05],
                     [1.2, tongs_gap / 2 - _tg_tooth]]);
}

module tongs_arm_2d_solid() {
    // pad + weld handled in 3D; this is just the pad profile
    tongs_pad_2d();
}

module tongs_half() {
    translate([0, _tg_y0, 0])
        leaf_spring(tongs_arm_len, _tg_depth, tongs_arm_t, _tg_arc);
    linear_extrude(_tg_depth) tongs_pad_2d();
}

module tool_tongs() {
    // rigid back block joining the arm roots
    linear_extrude(_tg_depth) hull()
        for (bx = [-8, -1], by = [-1, 1])
            translate([bx, by * (_tg_y0 + tongs_arm_t / 2 - 2.8)])
                circle(4);
    tongs_half();
    mirror([0, 1, 0]) tongs_half();
}

// ---- Clamp geometry ---------------------------------------------------

module clamp_pad_2d() {
    translate([_cl_pad_x0, 28]) square([3.5, 14]);
    // seat lip the phone edge rests on
    polygon([[_cl_pad_x0 + 0.1, 31.5],
             [_cl_pad_x0 - 1.6, 28.5],
             [_cl_pad_x0 + 0.1, 28.5]]);
}

module clamp_arm() {
    // curved leaf from foot to pad, bulging outward (local -y after
    // the flip below)
    translate([_cl_root[0], _cl_root[1], 0])
        rotate([0, 0, _cl_ang])
            scale([1, -1, 1])
                leaf_spring(_cl_chord, _cl_depth, clamp_arm_t, _cl_sag);
    // rigid root boss welding the band into the foot
    translate([_cl_root[0], _cl_root[1], 0])
        cylinder(r = 4, h = _cl_depth);
}

module clamp_half() {
    clamp_arm();
    linear_extrude(_cl_depth) clamp_pad_2d();
}

module tool_clamp() {
    // foot
    linear_extrude(_cl_depth) hull()
        for (fx = [-31, 31]) translate([fx, 3]) circle(3);
    clamp_half();
    mirror([1, 0, 0]) clamp_half();
}

// ---- Layout -----------------------------------------------------------

// print-layout offsets, derived from the tools' actual extents
_clip_ymax = _cs_half + 2.2;                      // top of jaw root hull
_tg_yhalf = _tg_y0 + tongs_arm_t / 2 + 1.2;       // block outer edge
_set_tongs = [0, _clip_ymax + 8 + _tg_yhalf, 0];
_set_clamp = [0, -(_clip_ymax + 8 + 42), 0];      // clamp spans y 0..42

module show_set() {
    color("SteelBlue") tool_clip();
    translate(_set_tongs) color("Orange") tool_tongs();
    translate(_set_clamp) color("YellowGreen") tool_clamp();
}

if (_display_mode == "set") {
    show_set();
} else if (_display_mode == "clip") {
    tool_clip();
} else if (_display_mode == "tongs") {
    tool_tongs();
} else if (_display_mode == "clamp") {
    tool_clamp();
}
