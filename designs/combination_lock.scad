// @name Combination Dial Lock
// @description Three-dial combination hasp lock: a finned shackle only pulls free of the slotted core when every dial's hidden gate lines up with its secret digit.
// @tags lock, combination, dial, puzzle, security, hasp, mechanism
//
// A stacked-dial combination lock (luggage-lock style hasp). Parts:
//
//   body    - base disc + fixed core tube. The tube has a full-length
//             fin channel at the 12 o'clock index (it also keys the
//             shackle against rotation, so gates cannot be picked one
//             at a time), a snap ridge near the top that retains the
//             cap, and a short key groove at 6 o'clock that clocks the
//             cap's fin opening to the channel.
//   dials   - one ring per combination digit. Each dial rides on the
//             tube and has an internal flange (45-degree coned
//             underside, self-supporting) with ONE gate slot, cut at
//             angle combination[i] * 360/digits. Digits 0..9 are
//             embossed around the rim with grip flutes between them.
//   cap     - washer that closes the dial stack; snaps over the tube
//             ridge; its fin opening doubles as the top index mark.
//   shackle - rod with one radial fin per dial and a wide head. When
//             every dial shows its combination digit at the index
//             marker, every gate lines up with the fin channel and the
//             shackle pulls straight out. Any dial off by even one
//             digit and a fin jams against that dial's flange.
//
// Use: with the shackle removed, thread zipper pulls / a hasp staple /
// keyrings over the rod (they must clear the fins), insert the shackle
// at the correct combination, then scramble the dials. The items are
// captive on the exposed neck between the shackle head and the cap.
//
// Assembly (once, after printing): slide each dial over the tube top,
// gate side up, and press it past the snap ridge (the ridge is split
// by the channel and groove, and the dial flange is split by its gate,
// so both flex); dials stack bottom-up in combination order. Align the
// cap's key tab with the 6 o'clock groove and press it past the ridge.
// Set the dials to the combination and insert the shackle, fin at the
// 12 o'clock marker.
//
// The combination is the `combination` vector (first dial_count
// entries). The dials are NOT interchangeable between stations unless
// their digits match - each is printed with its own gate angle.
//
// Printing: no supports. Body prints base down (ridge lead-ins are
// >= 45 degrees, flange cones face up); dials print gate side up
// (flange cone is a 45-degree internal overhang); cap prints flat;
// shackle prints lying down, fins up, on the head's flat chord.
// Dials spin freely (no detents) - scramble is manual.
//
// Modes: all = print plate layout; body / dial / cap / shackle =
// single part(s); assembled = locked, dials deliberately scrambled to
// a WRONG combination.

use <../macros/snapfit.scad>

/* [Lock] */
// Number of combination dials
dial_count = 3; // [2:1:4]
// Positions (digits) per dial
digits = 10; // [6:1:10]
// The secret combination, bottom dial first (first dial_count entries used; each 0..digits-1)
combination = [3, 7, 1, 5];

/* [Size] */
// Dial outer diameter (mm)
dial_od = 32; // [26:2:44]
// Shackle rod diameter (mm)
shaft_d = 8; // [6:1:10]
// Fin width across the channel (mm)
fin_w = 4; // [3:0.5:6]
// Exposed shackle neck between cap and head when locked (mm)
neck_len = 9; // [6:1:20]

/* [Fit] */
// Sliding clearance: rod in bore, fin in channel (mm)
slide_clearance = 0.3; // [0.2:0.05:0.5]
// Rotating clearance: dial and cap bores on the tube (mm)
rot_clearance = 0.3; // [0.2:0.05:0.5]
// Gate slot oversize per side vs the fin (mm)
gate_clearance = 0.35; // [0.2:0.05:0.6]
// Diametral snap interference of the cap-retaining ridge (mm)
snap_interference = 0.4; // [0.2:0.05:0.6]

/* [Display] */
// What to show
_display_mode = "all"; // ["all", "body", "dial", "cap", "shackle", "assembled"]

/* [Advanced] */
$fn = 48;

// ---- Derived: radii --------------------------------------------------
_rod_r = shaft_d / 2;
_bore_r = _rod_r + slide_clearance;      // body bore around the rod
_tube_wall = 2.4;
_tube_r = _bore_r + _tube_wall;          // core tube outer radius
_fb_r = _tube_r + rot_clearance;         // dial/cap flange bore radius
_fin_reach = 1.8;                        // fin engagement past the flange bore
_fin_r = _fb_r + _fin_reach;             // fin tip radius
_free_r = _fin_r + rot_clearance;        // dial free-bore radius (fin swept zone)
_ring_r = dial_od / 2;                   // dial outer radius
_base_r = _ring_r + 2;                   // base flange radius
_boss_r0 = _free_r + 0.7;                // friction-boss ring, inner
_boss_r1 = _boss_r0 + 1.6;               //                     outer
_cap_or = _boss_r1 + 1.8;                // cap outer radius
_head_d = 2 * _rod_r + 8;                // shackle head diameter

// ---- Derived: heights ------------------------------------------------
_floor = 2.4;                            // bore floor thickness
_base_h = 5;                             // base disc height
_boss_h = 0.8;
_fin_h = 3;
_cone_h = _free_r - _fb_r;               // 45-degree flange underside cone
_web_h = 1.6;                            // straight part of the flange
_flange_h = _cone_h + _web_h;
_free_h = _fin_h + 1.5;                  // free zone the fin parks in
_dial_h = _free_h + _flange_h;
_pitch = _dial_h + _boss_h + 0.3;        // dial station pitch
_cap_h = 4;
_head_h = 4;

function cl_dial_z(i) = _base_h + _boss_h + 0.1 + i * _pitch;  // dial i bottom
_cap_z = cl_dial_z(dial_count - 1) + _dial_h + _boss_h + 0.1;
_ridge_z = _cap_z + _cap_h + 0.2;
_ridge_h = 1.8;
_ridge_bite = rot_clearance + snap_interference / 2;
_tube_top = _ridge_z + _ridge_h + 1.2;
_seat_z = _floor + 0.6;                  // rod tip z when locked
_rod_len = _tube_top - _seat_z + neck_len;   // rod tip to head underside

// ---- Derived: channel / gate / key ------------------------------------
_step = 360 / digits;
_slot_w = fin_w + 2 * slide_clearance;   // fin channel + cap opening width
_gate_w = fin_w + 2 * gate_clearance;    // dial gate width
_groove_w = 3.6;                         // cap key groove (key tab is 3.0)
_key_w = 3.0;
_key_r0 = _tube_r - 0.7;                 // key tab inner radius (groove floor + 0.3)
_digit_size = min(0.55 * PI * dial_od / digits, _dial_h - 2.6);

// Shackle-local fin bottoms (rod tip at local z=0)
function cl_fin_lz(i) = cl_dial_z(i) + _free_h - 0.5 - _fin_h - _seat_z;

// ---- Accessors for the verification harness ---------------------------
function cl_dial_count() = dial_count;
function cl_digits() = digits;
function cl_combo(i) = combination[i];
// z-rotation that shows digit `d` at the 12 o'clock index marker
function cl_dial_rot(d) = -d * _step;
function cl_cap_z() = _cap_z;
function cl_seat_z() = _seat_z;
function cl_tube_top() = _tube_top;
// Axial pull that takes the lowest fin fully clear of the tube top
function cl_travel() = _tube_top - (_seat_z + cl_fin_lz(0)) + 0.5;

// ---- Envelope asserts --------------------------------------------------
assert(len(combination) >= dial_count,
    str("combination has ", len(combination), " digits but dial_count is ",
        dial_count, " - add entries"));
for (i = [0 : dial_count - 1])
    assert(combination[i] == floor(combination[i]) && combination[i] >= 0
           && combination[i] < digits,
        str("combination[", i, "] = ", combination[i],
            " is not an integer in 0..", digits - 1));
assert(fin_w / 2 + gate_clearance < _fb_r - 0.5,
    str("fin_w ", fin_w, " too wide for the flange bore radius ", _fb_r));
assert(fin_w <= shaft_d - 1.2,
    str("fin_w ", fin_w, " must be <= shaft_d - 1.2 (", shaft_d - 1.2,
        ") so the fin roots in the rod and its channel stays in the wall"));
// Gate must stay narrower than two digit pitches or neighbours blur together
assert(2 * asin((_gate_w / 2) / _fb_r) <= 2 * _step,
    str("gate spans ", 2 * asin((_gate_w / 2) / _fb_r),
        " deg > two digit steps (", 2 * _step,
        " deg): reduce fin_w/gate_clearance or digits"));
// A one-step-off gate must not swallow the fin whole (blocking guarantee)
assert(_step > asin((_gate_w / 2) / _fb_r) - asin((fin_w / 2) / _fb_r) + 4,
    str("digit step ", _step, " deg too fine vs gate/fin margin - fewer ",
        "digits or less gate_clearance"));
assert(_ring_r >= _free_r + 3.0,
    str("dial wall only ", _ring_r - _free_r, " mm around a ", 2 * _free_r,
        " mm fin bore: increase dial_od or reduce shaft_d/fin_w"));
assert(_boss_r1 <= _ring_r - 1.5,
    str("friction boss (r ", _boss_r1, ") too close to dial rim (r ",
        _ring_r, "): increase dial_od"));
assert(_digit_size >= 3,
    str("embossed digits would be ", _digit_size,
        " mm - illegible; increase dial_od or reduce digits"));

// ---- Parts -------------------------------------------------------------

// Base + core tube + snap ridge + index marker (one piece, prints base down)
module cl_body() {
    difference() {
        union() {
            cylinder(r = _base_r, h = _base_h);
            cylinder(r = _tube_r, h = _tube_top);
            // friction boss the bottom dial rides on (sunk 0.1 to weld)
            rotate_extrude(convexity = 2)
                polygon([[_boss_r0, _base_h - 0.1], [_boss_r1, _base_h - 0.1],
                         [_boss_r1, _base_h + _boss_h], [_boss_r0, _base_h + _boss_h]]);
            // cap-retaining snap ridge
            translate([0, 0, _ridge_z])
                snap_ridge(2 * _tube_r, _ridge_bite, _ridge_h);
            // 12 o'clock index marker on the base rim
            translate([0, 0, _base_h - 0.1])
                linear_extrude(height = 0.8)
                    polygon([[_ring_r + 0.4, -1.8], [_base_r - 0.3, 0],
                             [_ring_r + 0.4, 1.8]]);
        }
        // blind bore for the shackle rod
        translate([0, 0, _floor])
            cylinder(r = _bore_r, h = _tube_top - _floor + 0.3);
        // fin channel at 12 o'clock (through the wall, ridge included;
        // also the shackle's anti-rotation key). Starts well inside the
        // bore void so the fin's side corners clear the faceted bore wall.
        translate([_rod_r - 1.5, -_slot_w / 2, cl_dial_z(0) + 0.3])
            cube([_fin_r + 2.5 - (_rod_r - 1.5), _slot_w,
                  _tube_top - cl_dial_z(0) + 0.3]);
        // cap key groove at 6 o'clock
        rotate([0, 0, 180])
            translate([_tube_r - 1.0, -_groove_w / 2, _cap_z - 0.5])
                cube([_ridge_bite + 2.0, _groove_w,
                      _tube_top - _cap_z + 0.8]);
    }
}

// One dial. Gate angle encodes combination[i]; digit k is embossed at
// angle k*step, so the gate passes the fin exactly when digit
// combination[i] faces the index marker.
module cl_dial(i) {
    gate_a = combination[i] * _step;
    difference() {
        union() {
            // ring + flange (coned underside) + top friction boss
            rotate_extrude(convexity = 4)
                polygon([[_free_r, 0], [_ring_r, 0], [_ring_r, _dial_h],
                         [_boss_r1, _dial_h], [_boss_r1, _dial_h + _boss_h],
                         [_boss_r0, _dial_h + _boss_h], [_boss_r0, _dial_h],
                         [_fb_r, _dial_h], [_fb_r, _free_h + _cone_h],
                         [_free_r, _free_h]]);
            // embossed digits (sunk 0.3, proud 0.6)
            for (k = [0 : digits - 1])
                rotate([0, 0, k * _step])
                    translate([_ring_r - 0.3, 0, _dial_h / 2])
                        rotate([90, 0, 90])
                            linear_extrude(height = 0.9, convexity = 6)
                                text(str(k), size = _digit_size,
                                     font = "DejaVu Sans:style=Bold",
                                     halign = "center", valign = "center",
                                     $fn = 24);
        }
        // the gate slot through cone + web
        rotate([0, 0, gate_a])
            translate([_fb_r - 0.8, -_gate_w / 2, _free_h - 0.3])
                cube([_free_r - _fb_r + 1.3, _gate_w, _flange_h + 0.6]);
        // grip flutes between digits
        for (k = [0 : digits - 1])
            rotate([0, 0, (k + 0.5) * _step])
                translate([_ring_r, 0, -0.5])
                    cylinder(r = 1.1, h = _dial_h + 1, $fn = 16);
    }
}

// Stack-closing cap; the fin opening at 12 o'clock is the top index mark
module cl_cap() {
    union() {
        difference() {
            cylinder(r = _cap_or, h = _cap_h);
            translate([0, 0, -0.3])
                cylinder(r = _fb_r, h = _cap_h + 0.6);
            // fin opening (clocked to the channel by the key tab)
            translate([_fb_r - 0.8, -_slot_w / 2, -0.3])
                cube([_free_r - _fb_r + 1.3, _slot_w, _cap_h + 0.6]);
        }
        // key tab riding the 6 o'clock groove
        rotate([0, 0, 180])
            translate([_key_r0, -_key_w / 2, 0])
                cube([_fb_r - _key_r0 + 0.5, _key_w, _cap_h]);
    }
}

// Shackle in its working (vertical) frame: rod tip at z=0, fins at +x
module cl_shackle() {
    cylinder(r = _rod_r, h = _rod_len);
    // fins, tip rounded to _fin_r so the corners never exceed the
    // swept radius (a square tip's corners would poke past it)
    for (i = [0 : dial_count - 1])
        translate([0, 0, cl_fin_lz(i)])
            intersection() {
                translate([0, -fin_w / 2, 0])
                    cube([_fin_r + 1, fin_w, _fin_h]);
                cylinder(r = _fin_r, h = _fin_h);
            }
    // head, with a flat chord for printing lying down
    translate([0, 0, _rod_len - 0.1])
        difference() {
            cylinder(d = _head_d, h = _head_h + 0.1);
            translate([-_head_d / 2 - 1, -_head_d / 2 - 1, -0.3])
                cube([_head_d / 2 + 1 - _rod_r, _head_d + 2, _head_h + 0.7]);
        }
}

// ---- Placement helpers -------------------------------------------------

module cl_dial_placed(i, shown) {
    translate([0, 0, cl_dial_z(i)])
        rotate([0, 0, cl_dial_rot(shown)])
            cl_dial(i);
}

module cl_cap_placed() {
    translate([0, 0, _cap_z]) cl_cap();
}

// pull = axial displacement along the extraction path (0 = locked seat)
module cl_shackle_placed(pull = 0) {
    translate([0, 0, _seat_z + pull]) cl_shackle();
}

// Shackle in print orientation: lying along +x, fins up, head flat on plate
module cl_shackle_print() {
    translate([0, 0, _rod_r])
        rotate([0, 0, 180])
            rotate([0, -90, 0])
                cl_shackle();
}

// A deliberately wrong digit for dial i (never the correct one)
function cl_scramble(i) = (combination[i] + 1 + i) % digits;

// ---- Display -----------------------------------------------------------

_dial_colors = ["MediumSeaGreen", "IndianRed", "SteelBlue", "Goldenrod"];

if (_display_mode == "all") {
    color("SlateGray") cl_body();
    for (i = [0 : dial_count - 1])
        color(_dial_colors[i % 4])
            translate([i * (dial_od + 10), -(_base_r + _ring_r + 10), 0])
                cl_dial(i);
    color("Gold")
        translate([_base_r + _cap_or + 10, 0, 0])
            cl_cap();
    color("Tomato")
        translate([-_ring_r, _base_r + _head_d / 2 + 10, 0])
            cl_shackle_print();
} else if (_display_mode == "body") {
    cl_body();
} else if (_display_mode == "dial") {
    for (i = [0 : dial_count - 1])
        translate([i * (dial_od + 10), 0, 0])
            cl_dial(i);
} else if (_display_mode == "cap") {
    cl_cap();
} else if (_display_mode == "shackle") {
    cl_shackle_print();
} else if (_display_mode == "assembled") {
    // locked, dials scrambled to a WRONG combination
    color("SlateGray") cl_body();
    for (i = [0 : dial_count - 1])
        color(_dial_colors[i % 4]) cl_dial_placed(i, cl_scramble(i));
    color("Gold") cl_cap_placed();
    color("Tomato") cl_shackle_placed(0);
}
