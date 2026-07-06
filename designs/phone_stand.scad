// @name Folding Phone Stand
// @description Print-in-place folding phone stand: a captive-pin barrel hinge plus a ratchet detent arc that clicks into 3-5 preset viewing angles.
// @tags stand, phone, hinge, ratchet, print-in-place
//
// Two plates print flat and coplanar, joined by a barrel hinge whose pin
// prints CAPTIVE inside the knuckles (hinge_clearance all round, trapped
// axially by the blind outer faces of the base plate's end knuckles).
// The hinge line has 7 slots: base, phone, base, RATCHET FIN (phone),
// base, phone, base - the base plate owns both blind ends.
//
// The center slot's knuckle grows into a quarter-disk ratchet fin fixed
// to the phone plate. Detent notches are cut into its rim at each preset
// recline angle. A flexible catch arm rooted in the base plate arcs
// around the outside of the fin; its wedge tip digs catch_preload into
// the rim land, clicking into each notch as the phone plate is reclined.
// At a preset the notch is placed 0.55 mm past the tip so the tip sits
// pressed against the notch flank (detent preload) and resists the
// phone's weight collapsing the stand. Over-rotation past the last
// preset is stopped by the fin's leading face landing on the base plate.
//
// The phone plate carries a two-segment lip (split around the ratchet
// slot) 20 mm up from the hinge: the phone drops into a phone_slot-wide
// channel between the plate face and a 45-degree-supported overhang that
// hooks over the phone's lower edge.
//
// Print notes:
//   - Print in "flat" mode, NO supports (supports would fuse the hinge
//     and the catch). The knuckle barrels float 0.55 mm over the bed on
//     a round underside and the pin bridges the small gaps between
//     knuckles - standard print-in-place hinge bridging.
//   - The catch tip's 1.5 mm underside prints as a tiny unsupported
//     shelf (like a snap-hook barb) - harmless at this size.
//   - The lip overhang is backed by a 45-degree chamfer; all other
//     overhangs are 45 degrees or better.
//   - After printing, flex the phone plate a few degrees to free the
//     hinge, then recline it - the catch clicks at each preset angle.
//
// Modes: "flat" = print layout (both plates coplanar + captive pin,
// 3 bodies); "plate_a" = base plate with catch; "plate_b" = phone plate
// with fin and lip; "deployed" = standing at the default preset angle.

/* [Plates] */
// Stand width along the hinge (mm)
stand_w = 80; // [60:5:110]
// Base plate length, hinge to front edge (mm)
base_len = 70; // [55:5:100]
// Phone plate length, hinge to top edge (mm)
phone_plate_len = 95; // [70:5:130]
// Plate thickness (mm)
plate_t = 4; // [3:0.5:5]

/* [Hinge] */
// Hinge pin diameter (mm)
pin_d = 4; // [3:0.5:5]
// Clearance around the captive pin and between moving hinge parts (mm)
hinge_clearance = 0.35; // [0.25:0.05:0.5]

/* [Ratchet] */
// Shallowest preset recline angle, up from flat (degrees)
first_preset = 60; // [58:2:68]
// Angle between adjacent presets (degrees)
preset_step = 8; // [7:1:12]
// Number of preset angles
preset_count = 4; // [3:1:5]
// Radial depth of the detent notches in the ratchet rim (mm)
tooth_depth = 1.4; // [1:0.1:2]
// Catch tip preload into the rim land between detents (mm)
catch_preload = 0.5; // [0.3:0.05:0.7]

/* [Phone Lip] */
// Channel width between plate face and lip overhang - max phone thickness (mm)
phone_slot = 13; // [12:0.5:18]
// How far the lip overhang reaches up the phone's front face (mm)
lip_height = 6; // [4:1:10]
// Lip body footprint along the plate (mm)
lip_depth = 4; // [3:0.5:6]

/* [Display] */
// Which preset the deployed mode stands at (0 = shallowest)
deployed_preset = 1; // [0:1:4]
// What to show
_display_mode = "flat"; // ["flat", "plate_a", "plate_b", "deployed"]

/* [Advanced] */
// Resolution
$fn = 48;

// ---- Derived hinge geometry -----------------------------------------
_g = hinge_clearance;
_g0 = 0.5;                        // plate edge standoff from the axis plane
_knuckle_wall = 1.6;              // wall around the pin bore
_r_k = pin_d / 2 + _g + _knuckle_wall;   // knuckle barrel radius
_r_n = _r_k + _g;                 // relief (scallop) radius in the mate
_a = max(plate_t + 0.5, _r_k);    // hinge axis height above the bed
_cap = 1.2;                       // blind end-cap thickness in end knuckles
_bore_d = pin_d + 2 * _g;
_w_fin = 5;                       // ratchet fin slot width along the hinge
_w_catch = 4;                     // catch arm width (rides inside fin slot)
_seg = (stand_w - _w_fin) / 6;    // width of the 6 ordinary knuckle slots
// Slot boundaries and owners along the hinge (0=base, 1=phone, 2=fin)
_sx = [0, _seg, 2 * _seg, 3 * _seg, 3 * _seg + _w_fin,
       4 * _seg + _w_fin, 5 * _seg + _w_fin, stand_w];
_owner = [0, 1, 0, 2, 0, 1, 0];

// ---- Derived ratchet geometry ----------------------------------------
// Angles are measured in the y-z plane about the hinge axis, from +y
// (toward the base plate front) toward +z. The phone plate lies at 180
// when flat; reclining it by theta moves its material to (angle - theta).
_R = 16;                          // ratchet rim radius
_mu_c = 35;                       // catch tip angle (fixed, over the base)
_mu_lead = 90;                    // fin leading face at print (vertical)
_mu_trail = 183;                  // fin trailing face (dips into the plate)
_flank = 25;                      // notch flank half-angle vs the ray
_tip_half = 20;                   // catch tip half-angle vs the ray
// Detent preload: each notch is offset along the rim so the seated tip
// apex presses 0.15mm (chordwise) into the notch flank instead of
// floating free in the void - solved on the flank chord like the
// ratchet_frog pawl. _w_notch is the notch half-width at the rim.
_w_notch = tooth_depth * tan(_flank);
_bias_mm = _w_notch * (1 - catch_preload / tooth_depth) + 0.15;
_bias = atan(_bias_mm / _R);      // ... as an angle
_notch_half = atan(_w_notch / _R);              // notch half-width angle
_last_preset = first_preset + (preset_count - 1) * preset_step;
_band_in = _R + 0.4;              // catch arm inner radius (clears the rim)
_band_t = 1.8;                    // catch arm thickness (flexing dimension)
_band_out = _band_in + _band_t;
_mu_root = -10;                   // catch arm root angle (buried in plate A)
_mu_end = _mu_c + 2;              // catch arm free end
_tip_base_r = _band_in + 0.5;     // tip wedge base radius (sunk into arm)
_tw = (_tip_base_r - (_R - catch_preload)) * tan(_tip_half);

// ---- Derived lip geometry ---------------------------------------------
_lip_y = _R + 4;                  // lip channel face distance from the hinge
_lip_top = plate_t + phone_slot + lip_height + 2;
_lip_gap_half = _w_fin / 2 + 1;   // lip splits around the ratchet slot

// ---- Envelope checks ---------------------------------------------------
assert(first_preset >= _mu_lead - _mu_c + 3,
    str("first_preset ", first_preset, " is below the ratchet engagement ",
        "angle (needs >= ", _mu_lead - _mu_c + 3, "): raise first_preset"));
assert(_last_preset <= 88,
    str("last preset ", _last_preset, " exceeds the 88 degree travel ",
        "(fin hits the base plate at ~92): reduce preset_step or count"));
assert(preset_step >= 2 * _notch_half + 3,
    str("preset_step ", preset_step, " leaves no rim land between ",
        2 * _notch_half, "-degree-wide notches: increase the step or ",
        "reduce tooth_depth"));
assert(catch_preload <= tooth_depth - 0.4,
    str("catch_preload ", catch_preload, " leaves under 0.4mm of detent ",
        "flank (tooth_depth ", tooth_depth, "): reduce the preload"));
assert(deployed_preset < preset_count,
    str("deployed_preset ", deployed_preset, " must be < preset_count (",
        preset_count, ")"));
assert(_seg - _g >= 2.5,
    str("knuckle segments too short (", _seg - _g,
        " mm): increase stand_w"));
assert(_r_k - _bore_d / 2 >= 1.2,
    str("knuckle wall ", _r_k - _bore_d / 2, "mm around the pin bore is ",
        "under 1.2mm"));
assert(phone_slot >= 12,
    str("phone_slot ", phone_slot, " must be >= 12mm"));
assert(phone_plate_len >= _lip_y + lip_height + 35,
    str("phone_plate_len ", phone_plate_len, " too short for the lip at ",
        _lip_y, "mm plus phone support: lengthen the plate"));

// ---- Accessors (used by the verification harness) ----------------------
function ps_preset_angle(i) = first_preset + i * preset_step;
function ps_axis_z() = _a;
function ps_bias() = _bias;
function ps_rim_r() = _R;
function ps_lip_face_y() = -_lip_y;
function ps_deploy_angle() = ps_preset_angle(deployed_preset) + _bias;
function ps_plate_t() = plate_t;
function ps_slot() = phone_slot;
function ps_width() = stand_w;

// ---- Shared helpers -----------------------------------------------------
function _dirp(mu, r) = [r * cos(mu), r * sin(mu)];

// Pie wedge covering angles [mu0, mu1] out to radius rr
module _fan(mu0, mu1, rr) {
    n = max(2, ceil((mu1 - mu0) / 12));
    polygon(concat([[0, 0]],
        [for (i = [0 : n]) _dirp(mu0 + (mu1 - mu0) * i / n, rr)]));
}

// Extrude a 2D profile drawn in the (y, z-about-axis) plane along x
module _yz_extrude(x0, w) {
    translate([x0, 0, _a]) rotate([90, 0, 90])
        linear_extrude(w) children();
}

// Knuckle barrel for slot i (welds into its plate's hinge edge)
module _barrel(i) {
    x0 = (i == 0) ? 0 : _sx[i] + _g / 2;
    x1 = (i == 6) ? stand_w : _sx[i + 1] - _g / 2;
    translate([x0, 0, _a]) rotate([0, 90, 0]) cylinder(r = _r_k, h = x1 - x0);
}

// Relief cut in the OTHER plate for slot i's knuckle
module _hinge_notch(i) {
    x0 = (i == 0) ? -0.5 : _sx[i] - _g / 2;
    x1 = (i == 6) ? stand_w + 0.5 : _sx[i + 1] + _g / 2;
    translate([x0, 0, _a]) rotate([0, 90, 0]) cylinder(r = _r_n, h = x1 - x0);
}

module _pin_bore() {
    translate([_cap, 0, _a]) rotate([0, 90, 0])
        cylinder(d = _bore_d, h = stand_w - 2 * _cap);
}

// ---- Ratchet fin (phone plate, center slot) ----------------------------

// Detent notch cutter at rim angle nu: a wedge, apex at the notch floor,
// overshooting the rim
module _notch_2d(nu) {
    wo = (tooth_depth + 1) * tan(_flank);
    p = [-sin(nu), cos(nu)];
    polygon([_dirp(nu, _R - tooth_depth),
             _dirp(nu, _R + 1) + wo * p,
             _dirp(nu, _R + 1) - wo * p]);
}

module _fin_2d() {
    difference() {
        union() {
            circle(_r_k);                          // hinge hub
            intersection() {                       // toothed quarter disk
                circle(_R, $fn = 144);
                _fan(_mu_lead, _mu_trail, _R + 9);
            }
            polygon([[-12, -2.2], [-2.5, -2.2],    // root weld block
                     [-2.5, 1.5], [-12, 1.5]]);
        }
        for (i = [0 : preset_count - 1])
            _notch_2d(_mu_c + ps_preset_angle(i) + _bias);
    }
}

// ---- Catch arm (base plate) --------------------------------------------
module _catch_2d() {
    p = [-sin(_mu_c), cos(_mu_c)];
    union() {
        intersection() {                           // flexible arc arm
            difference() {
                circle(_band_out, $fn = 144);
                circle(_band_in, $fn = 144);
            }
            _fan(_mu_root, _mu_end, _band_out + 5);
        }
        polygon([_dirp(_mu_c, _R - catch_preload), // detent tip wedge
                 _dirp(_mu_c, _tip_base_r) + _tw * p,
                 _dirp(_mu_c, _tip_base_r) - _tw * p]);
    }
}

// ---- Phone lip (phone plate, split around the ratchet slot) ------------
module _lip() {
    y1 = -_lip_y;
    for (xr = [[3, stand_w / 2 - _lip_gap_half],
               [stand_w / 2 + _lip_gap_half, stand_w - 3]])
        translate([xr[0], 0, 0]) rotate([90, 0, 90])
            linear_extrude(xr[1] - xr[0])
                polygon([[y1 + lip_depth, plate_t - 0.3],
                         [y1, plate_t - 0.3],
                         [y1, plate_t + phone_slot],
                         [y1 - lip_height, plate_t + phone_slot + lip_height],
                         [y1 - lip_height, _lip_top],
                         [y1 + lip_depth, _lip_top]]);
}

// ---- Parts ---------------------------------------------------------------

module ps_base() {
    difference() {
        union() {
            translate([0, _g0, 0])
                cube([stand_w, base_len - _g0, plate_t]);
            for (i = [0 : 6]) if (_owner[i] == 0) _barrel(i);
            _yz_extrude(stand_w / 2 - _w_catch / 2, _w_catch) _catch_2d();
        }
        for (i = [0 : 6]) if (_owner[i] != 0) _hinge_notch(i);
        _pin_bore();
    }
}

module ps_phone_plate() {
    difference() {
        union() {
            translate([0, -phone_plate_len, 0])
                cube([stand_w, phone_plate_len - _g0, plate_t]);
            for (i = [0 : 6]) if (_owner[i] == 1) _barrel(i);
            _yz_extrude(_sx[3] + _g / 2, _w_fin - _g) _fin_2d();
            _lip();
        }
        for (i = [0 : 6]) if (_owner[i] == 0) _hinge_notch(i);
        _pin_bore();
    }
}

module ps_pin() {
    translate([_cap + _g, 0, _a]) rotate([0, 90, 0])
        cylinder(d = pin_d, h = stand_w - 2 * (_cap + _g));
}

// Recline transform: rotates the phone plate up by `angle` about the
// hinge axis (0 = flat print position)
module ps_fold(angle) {
    translate([0, 0, _a]) rotate([-angle, 0, 0]) translate([0, 0, -_a])
        children();
}

// ---- Display --------------------------------------------------------------

if (_display_mode == "flat") {
    color("SteelBlue") ps_base();
    color("Tomato") ps_phone_plate();
    color("Gold") ps_pin();
} else if (_display_mode == "plate_a") {
    ps_base();
} else if (_display_mode == "plate_b") {
    ps_phone_plate();
} else if (_display_mode == "deployed") {
    color("SteelBlue") ps_base();
    color("Tomato") ps_fold(ps_deploy_angle()) ps_phone_plate();
    color("Gold") ps_pin();
}
