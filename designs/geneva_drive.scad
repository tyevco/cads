// @name Geneva Drive Fidget
// @description Hand-cranked Geneva mechanism: a drive wheel with pin and locking disc indexes a slotted wheel in precise steps, with a genuine dwell lock between steps.
// @tags toy, fidget, geneva, mechanism, mechanical, educational
//
// A base plate with two posts. The drive wheel (crank disc + locking
// disc + pin + crank knob) spins on one post; the slotted Geneva wheel
// spins on the other. Crank the knob: while the pin runs through a
// slot the Geneva wheel turns by one pitch (360/N degrees); the rest
// of the revolution the locking disc rides in a concave arc on the
// Geneva rim and holds it perfectly still (the dwell).
//
// -------------------------------------------------------------------
// GENEVA GEOMETRY DERIVATION
//
// N slots, slot half-pitch a = 180/N. For shock-free operation the
// pin must enter and leave the slot TANGENTIALLY: at the entry pose
// the pin's velocity (perpendicular to the crank arm O1->P) must lie
// along the slot (the line O2->P). So the triangle O1-P-O2 has a
// right angle at the pin P. At entry the active slot points at the
// half-pitch angle a from the center line, hence with center distance
// d = |O1 O2|:
//   pin orbit radius   r = d * sin(a)
//   geneva slot radius R = d * cos(a)   (slot mouth = pin entry point)
// This file takes R (geneva_radius) as primary, so
//   d = R / cos(180/N)        r = R * tan(180/N)
// The pin is engaged while the crank is within b = 90 - a of the
// center line (engagement window 2b = 180 - 360/N of crank travel;
// the remaining 180 + 360/N is dwell). While engaged, with crank at
// angle u from the center line, the slot must point at the pin:
//   theta(u) = -atan2( r*sin(u), d - r*cos(u) )
// which runs from +a (entry, u=-b) to -a (exit, u=+b): exactly one
// pitch 360/N per crank revolution (asserted below). During dwell the
// wheel rests at -a (mod pitch); the locking disc (radius L on the
// drive axis) sits inside a concave rim arc of radius L +
// lock_clearance centered on the drive axis, so the wheel cannot turn.
//
// The disc's clearance CRESCENT is generated exactly: the Geneva
// profile (inflated by lock_clearance) is swept through the true
// engagement kinematics in the drive wheel's rotating frame and
// subtracted from the disc, so the rim tips clear the disc while the
// pin indexes the wheel, and the disc stays solid everywhere else.
// -------------------------------------------------------------------
//
// Pieces (print layout "all"): base plate, drive wheel, geneva wheel.
// All print flat with no supports (drive wheel stacks shrinking
// diameters; the crank knob flares at 45 degrees which is
// self-supporting; geneva wheel prints face down with its hub up).
//
// Assembly: drop the geneva wheel (hub down) onto the far post, drop
// the drive wheel onto the near post, crank the knob.

/* [Geneva Configuration] */
// Number of slots in the geneva wheel (steps per full geneva turn)
slot_count = 6; // [4:1:7]

// Geneva wheel radius (mm) - slot mouths open at this radius
geneva_radius = 34; // [26:2:48]

// Drive pin diameter (mm)
pin_diameter = 5; // [4:0.5:6]

/* [Dimensions] */
// Geneva wheel / engagement layer thickness (mm)
wheel_thickness = 6; // [4:1:8]

// Crank disc thickness (mm)
crank_thickness = 5; // [4:1:7]

// Crank knob diameter on top of the pin (mm)
knob_diameter = 10; // [8:1:14]

// Base plate thickness (mm)
plate_thickness = 4; // [3:1:6]

// Plate border padding around the wheels (mm)
plate_padding = 8; // [4:1:12]

/* [Tolerances] */
// Bore diameter for both wheels (mm) - posts are derived smaller
bore_diameter = 5; // [4:0.5:7]

// Clearance between bore and post (mm, per side)
bore_clearance = 0.3; // [0.15:0.05:0.5]

// Clearance between pin and slot flanks (mm, per side)
slot_clearance = 0.3; // [0.15:0.05:0.5]

// Clearance between locking disc and geneva locking arcs (mm)
lock_clearance = 0.3; // [0.15:0.05:0.5]

/* [Display] */
// What to show
_display_mode = "all"; // ["all", "plate", "drive_wheel", "geneva_wheel", "assembled"]

// Crank angle for the assembled view (0 = pin deepest in a slot)
_crank_angle = 0; // [0:5:360]

/* [Advanced] */
$fn = 60;

// ---- Derived geometry (see header derivation) ----

_alpha = 180 / slot_count;              // slot half-pitch
_beta  = 90 - _alpha;                   // engagement half-window (crank)
_d     = geneva_radius / cos(_alpha);   // center distance
_r_pin = geneva_radius * tan(_alpha);   // pin orbit radius (= d*sin(a))

_pin_r    = pin_diameter / 2;
_slot_w   = pin_diameter + 2 * slot_clearance;   // slot gets BIGGER
_slot_in  = _d - _r_pin;                // pin center at deepest engagement

// Locking disc on the drive axis; concave rim arcs on the geneva
_lock_r = max(0.60 * _r_pin, _d - geneva_radius + 2.5);
_arc_r  = _lock_r + lock_clearance;     // hole gets BIGGER

_bore_r  = bore_diameter / 2;
_post_d  = bore_diameter - 2 * bore_clearance;   // shaft gets SMALLER

// Vertical stack (z relative to plate top)
_gap_v    = 0.4;                                  // running gap over crank disc
_crank_r  = _r_pin + _pin_r + 2;                  // crank disc rim beyond pin
_disc_h   = _gap_v + wheel_thickness + 0.4;       // locking disc spans geneva layer
_hub_r    = min(8, _d - _crank_r - 0.5);          // geneva spacer hub
_hub_h    = crank_thickness + _gap_v;
_post_h   = crank_thickness + wheel_thickness;    // below both bore tops
_knob_r   = knob_diameter / 2;
_pin_free = _gap_v + wheel_thickness + 0.5;       // pin above crank disc to knob flare
_drive_reach = max(_crank_r, _r_pin + _knob_r);   // widest plan reach of drive wheel

// Crescent sweep sampling: 2-degree steps across the engagement window
// plus margin into the dwell (dwell poses clear the disc by construction,
// so the margin only guards the hand-off). Sagitta between 2-degree
// samples is < 0.05mm, far under the 0.3mm inflation.
_sweep_max  = _beta + 8;
_sweep_step = 2;

// ---- Kinematics (also used by the verification harness) ----

// Geneva wheel angle for crank angle phi (crank 0 = pin deepest).
// Engaged for |phi mod 360| <= beta, at rest (dwell) otherwise;
// advances exactly -360/N per crank revolution.
function geneva_angle(phi) =
    let(k = floor((phi + 180) / 360),   // which crank revolution
        u = phi - 360 * k)              // local angle in [-180, 180)
    -k * 360 / slot_count + (
        u < -_beta ?  _alpha :
        u >  _beta ? -_alpha :
        -atan2(_r_pin * sin(u), _d - _r_pin * cos(u)));

// Accessors for the test harness
function geneva_center()  = [_d, 0, 0];
function geneva_beta()    = _beta;
function drive_reach()    = _drive_reach;
function geneva_outer_r() = geneva_radius;

// ---- Constraint asserts ----

// Tangential entry identity: r and R must come from the same right triangle
assert(abs(_r_pin * _r_pin + geneva_radius * geneva_radius - _d * _d) < 1e-6,
    "Geneva right-triangle identity violated (internal)");

// Indexing: exactly one pitch of geneva rotation per crank revolution,
// and the engaged branch is continuous with the dwell branches.
assert(abs(geneva_angle(123 + 360) - geneva_angle(123) + 360 / slot_count) < 1e-9,
    "Geneva must advance exactly 360/N per crank revolution");
assert(abs(geneva_angle(-_beta) - _alpha) < 1e-9 &&
       abs(geneva_angle(_beta) + _alpha) < 1e-9,
    "Engagement branch must meet the dwell rest angles at +/-beta");
assert(abs(geneva_angle(0)) < 1e-9, "Deepest engagement must be at angle 0");

// The geneva rim sweeps within (d - R) of the drive axis during
// indexing; the crescent cut there must leave a wall around the bore.
assert(_d - geneva_radius - lock_clearance >= _bore_r + 1.2,
    str("Crescent cuts to ", _d - geneva_radius - lock_clearance,
        "mm of the drive axis, bore needs ", _bore_r + 1.2,
        "mm - increase geneva_radius or reduce slot_count"));

// Slot must not reach the geneva bore/hub
assert(_slot_in - _slot_w / 2 >= _bore_r + 1.2,
    str("Slots reach within ", _slot_in - _slot_w / 2,
        "mm of the geneva axis - bore wall needs ", _bore_r + 1.2, "mm"));

// Locking arcs must actually bite into the rim to lock
assert(_d - _arc_r <= geneva_radius - 1.5,
    "Locking arcs too shallow to lock the geneva wheel");

// Geneva hub must clear the crank disc, and keep a wall around its bore
assert(_d - _crank_r - _hub_r >= 0.5,
    str("Geneva hub hits the crank disc (gap ", _d - _crank_r - _hub_r,
        "mm) - increase geneva_radius"));
assert(_hub_r >= _bore_r + 1.6,
    str("Geneva hub radius ", _hub_r, " leaves <1.6mm wall around the bore"));

// Locking disc must clear the pin root
assert(_lock_r + 0.5 <= _r_pin - _pin_r,
    "Locking disc overlaps the drive pin - reduce pin_diameter");

assert(slot_clearance > 0 && lock_clearance > 0 && bore_clearance > 0,
    "All clearances must be positive");

// ---- 2D profiles ----

// Geneva wheel profile: disc, N through-slots (stadiums opening
// through the rim), N concave locking arcs between the slots.
// Local frame: slot 0 centerline points along -x (toward the drive
// axis at geneva_angle = 0, i.e. deepest engagement).
module geneva_2d() {
    difference() {
        circle(r = geneva_radius);
        for (i = [0:slot_count - 1]) {
            // Slot: from the deepest pin position out through the rim
            rotate(180 + i * 360 / slot_count) hull() {
                translate([_slot_in, 0]) circle(d = _slot_w);
                translate([geneva_radius + 2, 0]) circle(d = _slot_w);
            }
            // Locking arc: centered where the drive axis sits at rest
            rotate(180 + (i + 0.5) * 360 / slot_count)
                translate([_d, 0]) circle(r = _arc_r);
        }
    }
}

// Geneva profile inflated by the locking clearance (conservative
// envelope used to carve the crescent)
module geneva_2d_inflated() {
    offset(r = lock_clearance) geneva_2d();
}

// Exact crescent: union of the inflated geneva profile at every
// sampled pose of the true engagement kinematics, expressed in the
// drive wheel's rotating frame (drive frame = global rotated by -phi).
module crescent_2d() {
    for (phi = [-_sweep_max:_sweep_step:_sweep_max])
        rotate(-phi) translate([_d, 0]) rotate(geneva_angle(phi))
            geneva_2d_inflated();
}

module lock_disc_2d() {
    difference() {
        circle(r = _lock_r);
        crescent_2d();
    }
}

// ---- Part modules ----

// Drive wheel, local frame: axis at origin, pin at azimuth 0.
// Stack: crank disc, locking disc (with crescent), pin rising through
// the geneva layer into a 45-degree flare and the crank knob.
module drive_wheel_part() {
    difference() {
        union() {
            cylinder(r = _crank_r, h = crank_thickness);
            translate([0, 0, crank_thickness - 0.05])
                linear_extrude(height = _disc_h + 0.05)
                    lock_disc_2d();
            // Pin + crank knob (sunk 0.05 into the crank disc)
            translate([_r_pin, 0, crank_thickness - 0.05]) {
                cylinder(r = _pin_r, h = _pin_free + 0.05);
                translate([0, 0, _pin_free])
                    cylinder(r1 = _pin_r, r2 = _knob_r,
                             h = _knob_r - _pin_r);   // 45-degree flare
                translate([0, 0, _pin_free + _knob_r - _pin_r - 0.01])
                    cylinder(r = _knob_r, h = 6);
            }
        }
        // Bore (through crank disc and locking disc)
        translate([0, 0, -0.1])
            cylinder(d = bore_diameter, h = crank_thickness + _disc_h + 0.2);
        // Bore entry chamfer (post lead-in)
        translate([0, 0, -0.01])
            cylinder(d1 = bore_diameter + 1.2, d2 = bore_diameter, h = 0.61);
        // Grip flutes around the crank disc rim
        for (i = [0:23])
            rotate([0, 0, i * 15])
                translate([_crank_r + 0.4, 0, -0.1])
                    cylinder(r = 1.3, h = crank_thickness + 0.2, $fn = 16);
    }
}

// Geneva wheel, local frame as assembled: spacer hub below (rides on
// the plate, keeps the wheel above the crank disc), slotted wheel on top.
module geneva_wheel_part() {
    difference() {
        union() {
            cylinder(r = _hub_r, h = _hub_h + 0.05);
            translate([0, 0, _hub_h])
                linear_extrude(height = wheel_thickness)
                    geneva_2d();
        }
        // Through bore
        translate([0, 0, -0.1])
            cylinder(d = bore_diameter, h = _hub_h + wheel_thickness + 0.2);
        // Bore entry chamfer at the hub end (post lead-in)
        translate([0, 0, -0.01])
            cylinder(d1 = bore_diameter + 1.2, d2 = bore_diameter, h = 0.61);
    }
}

// Base plate: hull of two discs around the axes, one post each
module plate_part() {
    linear_extrude(height = plate_thickness) hull() {
        circle(r = _drive_reach + plate_padding);
        translate([_d, 0]) circle(r = geneva_radius + plate_padding);
    }
    for (p = [[0, 0], [_d, 0]])
        translate([p[0], p[1], plate_thickness - 0.05]) {
            cylinder(d = _post_d, h = _post_h - 0.55);
            translate([0, 0, _post_h - 0.56])
                cylinder(d1 = _post_d, d2 = _post_d - 1.2, h = 0.61);
        }
}

// ---- Display ----

module show_assembled() {
    color("SlateGray") plate_part();
    color("Gold")
        translate([0, 0, plate_thickness + 0.05])
            rotate([0, 0, _crank_angle])
                drive_wheel_part();
    color("DodgerBlue")
        translate([_d, 0, plate_thickness + 0.05])
            rotate([0, 0, geneva_angle(_crank_angle)])
                geneva_wheel_part();
}

// Print layout: plate as printed, both wheels in a row below it.
// Geneva wheel is flipped so its slotted face lies on the plate.
module show_print_layout() {
    color("SlateGray") plate_part();
    _row_y = -(geneva_radius + plate_padding) - _drive_reach - 6;
    color("Gold")
        translate([0, _row_y, 0]) drive_wheel_part();
    color("DodgerBlue")
        translate([_drive_reach + geneva_radius + 8, _row_y,
                   _hub_h + wheel_thickness])
            rotate([180, 0, 0]) geneva_wheel_part();
}

if (_display_mode == "all") {
    show_print_layout();
} else if (_display_mode == "plate") {
    plate_part();
} else if (_display_mode == "drive_wheel") {
    drive_wheel_part();
} else if (_display_mode == "geneva_wheel") {
    geneva_wheel_part();
} else if (_display_mode == "assembled") {
    show_assembled();
}
