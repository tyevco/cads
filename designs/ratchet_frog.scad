// @name Croaking Ratchet Frog
// @description A frog noisemaker: spin the ratchet wheel on its back with your thumb and a springy pawl tongue clicks over the teeth to croak.
// @tags toy, frog, ratchet, noisemaker, snap-fit
//
// Two printed parts:
//   1. The frog body - a flat frog silhouette (head, eyes, four legs)
//      carrying a central snap post (chamfered ridge on a cross-slotted
//      shaft) and an integral thin-wall pawl cantilevered from the left
//      front leg. A slot in the base frees the pawl so it can flex
//      sideways.
//   2. The ratchet wheel - a sawtooth ratchet ring with a fluted thumb
//      knob on top and a bore that snaps over the post.
//
// Assembly: press the wheel down over the post; the lead-in chamfer
// compresses the slotted shaft until the ridge snaps over the bore.
// Rub the knob with a thumb and the pawl tip rides the tooth ramps,
// snapping into each valley with a croaky click. The pawl tip is
// modeled with a small deliberate interference against the tooth ramp
// (the click preload) - in plastic the pawl simply sits pre-bent.
//
// Printing: both parts flat as laid out in "all" mode, no supports
// (the snap ridge underside is a 45-degree overhang).
//
// Modes: "all" = both parts in print layout (default gallery view),
// "body" / "wheel" = single parts, "assembled" = wheel snapped on.

/* [Ratchet Wheel] */
// Number of ratchet teeth
tooth_count = 12; // [8:1:20]

// Tooth tip circle diameter (mm)
wheel_diameter = 26; // [20:1:34]

// Radial tooth depth (mm)
tooth_depth = 1.6; // [1.0:0.1:2.5]

// Thickness of the toothed ring (mm)
ratchet_thickness = 3; // [2.5:0.5:5]

// Height of the thumb knob above the ring (mm)
knob_height = 4; // [3:0.5:6]

/* [Snap Post & Pawl] */
// Post shaft diameter (mm)
post_diameter = 7; // [6:0.5:9]

// Running clearance between bore and post (mm)
fit_clearance = 0.25; // [0.15:0.05:0.4]

// Pawl tip interference against the tooth ramp at rest (mm) - the
// click preload
pawl_preload = 0.3; // [0.1:0.05:0.6]

// Pawl beam wall thickness (mm)
pawl_thickness = 1.7; // [1.2:0.1:2.4]

/* [Frog Body] */
// Base plate thickness (mm)
body_thickness = 5; // [4:0.5:7]

/* [Display] */
// What to show
_display_mode = "all"; // ["all", "body", "wheel", "assembled"]

/* [Advanced] */
$fn = 64;


// ---- Derived ----

_bh = body_thickness;
_rt = wheel_diameter / 2;              // tooth tip radius
_rr = _rt - tooth_depth;               // tooth root radius
_sa = 360 / tooth_count;               // tooth pitch angle
_drop = _sa * 0.12;                    // angular width of the steep face
_bore_r = post_diameter / 2 + fit_clearance;
_post_r = post_diameter / 2;
_ridge = 0.6;                          // snap ridge radial protrusion

_body_r = max(17, _rt + 2);            // frog back radius grows with wheel
_wheel_z = _bh + 0.3;                  // wheel floats over the base
_wheel_h = ratchet_thickness + knob_height;
_knob_r = min(8, _rr - 2);

// Snap joint: the ridge snaps into a counterbore inside the knob and its
// 45-degree underside bears on the counterbore's internal ledge.
_cbore_depth = 1.8;
_cbore_r = _post_r + _ridge + 0.25;
_ledge_z = _wheel_z + _wheel_h - _cbore_depth;
_ridge_z = _ledge_z + 0.15;            // axial play above the ledge

// Pawl: a tall thin wall along x, north of the wheel, rooted in an
// anchor block on the left front leg. Its triangular tip hangs down to
// just above the tooth root circle at the 12 o'clock position.
_beam_y0 = _rt + 0.3;                  // beam inner edge clears tooth tips
_beam_y1 = _beam_y0 + pawl_thickness;
_beam_x0 = -(_rt + 3.5);
_beam_x1 = 2.2;
_pawl_h = _wheel_z + ratchet_thickness + 0.5;
_tip_y = _rr + 0.3;                    // pawl tip apex radius

// Wheel rest angle: park a tooth valley under the pawl tip so the ramp
// flank overlaps the apex by pawl_preload (the click preload). The ramp
// is a straight chord from the root (r=_rr) to the next crest (r=_rt),
// so solve |P1 + t*(P2-P1)| = _tip_y + pawl_preload for t, then take
// the angle of that chord point past the root.
_p1 = [_rr, 0];
_p2 = _rt * [cos(_sa - _drop), sin(_sa - _drop)];
_pd = _p2 - _p1;
_qa = _pd * _pd;
_qb = 2 * (_p1 * _pd);
_qc = _rr * _rr - pow(_tip_y + pawl_preload, 2);
_qt = (-_qb + sqrt(_qb * _qb - 4 * _qa * _qc)) / (2 * _qa);
_preload_ang = atan2(_p1[1] + _qt * _pd[1], _p1[0] + _qt * _pd[0]);
_rest_angle = 90 - _drop - _preload_ang;

assert(_rr - _bore_r >= 2.2,
    str("Wheel hub wall is only ", _rr - _bore_r, "mm between bore and ",
        "tooth roots: enlarge wheel_diameter or shrink post_diameter."));
assert(2 * PI * _rr / tooth_count >= 2.2,
    str(tooth_count, " teeth on a ", 2 * _rr, "mm root circle are finer ",
        "than 2.2mm pitch and will not click: use fewer/larger teeth."));
assert(_knob_r - _cbore_r >= 2.4,
    str("Knob wall around the snap counterbore is only ",
        _knob_r - _cbore_r, "mm: enlarge wheel_diameter or shrink ",
        "post_diameter."));
assert(pawl_preload <= tooth_depth - 0.4,
    str("pawl_preload ", pawl_preload, "mm leaves under 0.4mm of tooth ",
        "ramp (depth ", tooth_depth, "mm): reduce the preload."));

// Accessors for the verification harness
function wheel_position() = [0, 0, _wheel_z];
function wheel_rest_angle() = _rest_angle;
function tooth_pitch() = _sa;


// ---- Wheel ----

module ratchet_2d() {
    polygon([for (i = [0 : tooth_count - 1], p = [0, 1])
        p == 0 ? _rt * [cos(i * _sa), sin(i * _sa)]
               : _rr * [cos(i * _sa + _drop), sin(i * _sa + _drop)]]);
}

module knob_2d() {
    difference() {
        circle(_knob_r);
        for (i = [0 : 7])
            rotate([0, 0, i * 45 + 22.5])
                translate([_knob_r + 0.8, 0])
                    circle(1.6, $fn = 24);
    }
}

// The ratchet wheel, band bottom on z=0, printed as-is (knob up).
module wheel() {
    difference() {
        union() {
            linear_extrude(ratchet_thickness) ratchet_2d();
            translate([0, 0, ratchet_thickness - 0.1])
                linear_extrude(knob_height + 0.1) knob_2d();
        }
        translate([0, 0, -0.1])
            cylinder(r = _bore_r, h = _wheel_h + 0.2);
        // Counterbore the ridge snaps into; its floor is the retention
        // ledge the ridge underside bears against
        translate([0, 0, _wheel_h - _cbore_depth])
            cylinder(r = _cbore_r, h = _cbore_depth + 0.1);
        // Lead-in chamfer at the bore bottom (entry side)
        translate([0, 0, -0.1])
            cylinder(r1 = _bore_r + 0.5, r2 = _bore_r, h = 0.8);
    }
}

// Wheel in its assembled position over the post.
module wheel_assembled(a = _rest_angle) {
    translate(wheel_position()) rotate([0, 0, a]) wheel();
}


// ---- Body ----

// Cross-slotted shaft with a chamfered snap ridge: 45-degree underside
// (printable, retains the wheel), long lead-in cone on top.
module snap_post() {
    difference() {
        union() {
            translate([0, 0, _bh - 0.3])
                cylinder(r = _post_r, h = _ridge_z - _bh + 0.4);
            translate([0, 0, _ridge_z])
                cylinder(r1 = _post_r, r2 = _post_r + _ridge, h = _ridge);
            translate([0, 0, _ridge_z + _ridge])
                cylinder(r1 = _post_r + _ridge, r2 = _post_r - 0.5, h = 1.0);
        }
        // Flex slots so the ridge can compress through the bore
        for (a = [0, 90])
            rotate([0, 0, a])
                translate([-0.7, -_post_r - _ridge - 0.5, _ridge_z - 3.5])
                    cube([1.4, 2 * (_post_r + _ridge) + 1,
                          _ridge + 1.0 + 3.7]);
    }
}

module beam_2d() {
    translate([_beam_x0, _beam_y0])
        square([_beam_x1 - _beam_x0, pawl_thickness]);
}

module tip_2d() {
    polygon([[-1.3, _beam_y0 + 0.9], [1.3, _beam_y0 + 0.9], [0, _tip_y]]);
}

module pawl_2d() {
    beam_2d();
    tip_2d();
}

// Anchor block footprint: welds the pawl root to the body.
module block_2d() {
    translate([-(_rt + 7), _beam_y0 - 2.5])
        square([5, pawl_thickness + 5]);
}

// The pawl alone (for the verification harness).
module pawl() {
    linear_extrude(_pawl_h) pawl_2d();
}

module base_2d() {
    circle(_body_r);
    translate([0, _body_r + 3]) circle(9.5);          // head
    for (s = [-1, 1]) {
        hull() {                                       // front legs
            translate([s * 11, 9]) circle(4);
            translate([s * (_body_r + 1), _body_r - 3]) circle(4.5);
        }
        hull() {                                       // rear legs
            translate([s * 11, -10]) circle(4.5);
            translate([s * _body_r, -_body_r + 1]) circle(5);
        }
    }
    block_2d();
}

// Slot freeing the pawl from the base plate (stops at the anchor block).
module pawl_slot_2d() {
    difference() {
        offset(r = 0.7) pawl_2d();
        block_2d();
    }
}

module frog_body(include_pawl = true) {
    // Base plate with the pawl slot and nostrils cut
    difference() {
        linear_extrude(_bh) base_2d();
        translate([0, 0, -0.1]) linear_extrude(_bh + 0.2) pawl_slot_2d();
        for (s = [-1, 1])                              // nostrils
            translate([s * 1.6, _body_r + 11.2, _bh - 0.8])
                cylinder(r = 0.7, h = 1.0, $fn = 24);
    }
    // Eyes (sunk 0.3 into the plate so they weld)
    for (s = [-1, 1])
        translate([s * 4, _body_r + 7.5, _bh - 0.3])
            cylinder(r1 = 3, r2 = 2.2, h = 3.8);
    // Pawl anchor block and pawl
    linear_extrude(_pawl_h) block_2d();
    if (include_pawl) pawl();
    snap_post();
}


// ---- Display ----

module show_all() {
    color("YellowGreen") frog_body();
    translate([_body_r + _rt + 9.5, 0, 0]) color("Orange") wheel();
}

module show_assembled() {
    color("YellowGreen") frog_body();
    color("Orange") wheel_assembled();
}

if (_display_mode == "all") {
    show_all();
} else if (_display_mode == "body") {
    frog_body();
} else if (_display_mode == "wheel") {
    wheel();
} else if (_display_mode == "assembled") {
    show_assembled();
}
