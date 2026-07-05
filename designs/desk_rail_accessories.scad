// @name Desk Rail Accessories
// @description Under-desk accessories - headphone hook, pen tray and cable catch - that slide onto the dovetail rails of the Gridfinity Under-Desk Drawer housing.
// @tags desk, accessories, dovetail, gridfinity, organization
//
// A family of accessories for the Gridfinity Under-Desk Drawer
// (gridfinity_drawer.scad). Each accessory is a vertical mount plate
// carrying female dovetail channels that slide onto the housing's
// RIGHT-side rails, plus a functional feature on the outboard face:
//
//   headphone_hook : wide J-hook (rounded, ~20mm throat) - hang a
//                    headset under the desk
//   pen_tray       : small open-top tray for pens / small parts
//   cable_catch    : open C-profile clip - press a cable bundle up
//                    through the bottom gap
//
// Interface: the "Drawer Housing Interface" parameters MUST match the
// housing they mount on. The defaults here match gridfinity_drawer.scad
// at ITS defaults:
//   rail_mount_height 38.9 = rail_height 4 + drawer 31.6 + clearance 0.3
//                            + top_plate 3   (the housing _housing_z)
//   rail centers at rail_mount_height*(i+1)/(rail_count+1)
//                 = 12.967 / 25.933 mm for 2 rails
//   dovetail 6mm at the wall, 10mm at the tip, 4mm deep, 0.3 clearance
//   housing_outer_width 134.6 = 3*42 + 2*2 + 2*0.3 + 2*2 (mounted view
//                               and fit tests only)
//
// Assembly: slide the accessory onto the housing's right-side rails
// from the housing front, exactly like chaining a second housing.
// The wide-at-the-tip trapezoid locks the pull-apart (x) direction;
// the channel walls lock z.
//
// Printing ("all" mode): every accessory prints STANDING ON ITS FRONT
// (y=0) FACE, exactly like the housing prints. Justification: the
// mount plate + dovetail-channel cross-section is constant along y, so
// the channels print as vertical features (dimensionally accurate, no
// support), and the hook and catch profiles are pure prisms with zero
// overhangs. The pen tray's far end wall prints as a short horizontal
// bridge (~tray_depth wide) anchored on three sides by the plate,
// floor and outer wall - prints support-free. Nothing else overhangs.

// Imported for the "mounted" preview (housing()); `use` brings in
// modules/functions only and renders nothing.
use <gridfinity_drawer.scad>

/* [Headphone Hook] */
// Hook throat: clear horizontal gap between plate face and tip (mm)
hook_depth = 20; // [12:2:40]

// Hook arm/tip bar thickness (mm)
hook_thickness = 5; // [4:1:8]

// Height of the upturned tip above the arm (mm)
hook_tip_height = 12; // [6:2:20]

/* [Pen Tray] */
// Tray outer depth away from the plate (mm)
tray_depth = 25; // [15:5:45]

// Tray outer height (mm)
tray_height = 25; // [15:5:40]

/* [Cable Catch] */
// Inner diameter of the C-catch - size of the cable bundle (mm)
catch_dia = 16; // [8:2:26]

/* [Mount Plate] */
// Plate length along the rails (mm)
plate_length = 40; // [30:5:80]

// Backplate thickness (mm)
plate_thickness = 4.0;

/* [Drawer Housing Interface] */
// Housing height = rail mount span (mm) - gridfinity_drawer _housing_z
rail_mount_height = 38.9;

// Number of dovetail rails (must match the housing's dovetail_count)
rail_count = 2; // [1:1:5]

// Dovetail rail width at the wall (mm) - match housing dovetail_narrow
dovetail_narrow = 6.0;

// Dovetail rail width at the tip (mm) - match housing dovetail_wide
dovetail_wide = 10.0;

// Dovetail rail protrusion depth (mm) - match housing dovetail_depth
dovetail_depth = 4.0;

// Sliding clearance around the rail (mm) - match housing clearance
clearance = 0.3;

// Housing outer width at its defaults (mm) - mounted view / fit tests
housing_outer_width = 134.6;

/* [Display] */
// What to show
_display_mode = "all"; // ["all", "hook", "pen_tray", "cable_catch", "mounted"]

/* [Advanced] */
// Resolution
$fn = 48;

// Catch ring wall thickness (mm)
catch_wall = 4.0; // [3:1:6]

// ---- Derived dimensions ----

// Female boss depth: channel + backing material (same as the housing)
_boss_d = dovetail_depth + 2;

// Boss slab height per rail (same 2.4mm margin as the housing bosses)
_boss_h = dovetail_wide + 4.8;

// Plate spans the full housing height
_plate_h = rail_mount_height;

// Tray wall/floor thickness
_tray_wall = 2.4;

// Cable catch opening half-angle (about straight down)
_catch_gap = 35;

// Rail center heights - same formula as the housing's dovetail_z()
function rail_z(i) = rail_mount_height * (i + 1) / (rail_count + 1);

// Assembled position of an accessory on the housing (housing frame):
// its boss face sits against the housing's right wall, y = slide
// position along the rails. Used by the mounted view and fit tests.
function rail_mount_offset(y = 0) = [housing_outer_width + _boss_d, y, 0];

// ---- Envelope asserts ----

assert(dovetail_wide > dovetail_narrow,
    "Dovetail must be wider at the tip than at the wall or it cannot lock");

assert(rail_mount_height / (rail_count + 1) > dovetail_wide / 2 + clearance,
    str("Rails too close together: ", rail_count, " rails need spacing > ",
        dovetail_wide / 2 + clearance, "mm; got ",
        rail_mount_height / (rail_count + 1), "mm"));

assert(hook_thickness + hook_tip_height <= rail_mount_height - 2,
    str("Hook tip reaches z=", hook_thickness + hook_tip_height,
        " and would hit the desk (limit ", rail_mount_height - 2, ")"));

assert(catch_dia / 2 + catch_wall <= _plate_h / 2,
    str("Cable catch outer radius ", catch_dia / 2 + catch_wall,
        " does not fit on a ", _plate_h, "mm plate"));

assert(tray_depth > _tray_wall + 5 && tray_height > _tray_wall + 5,
    "Pen tray too small to have a cavity");

// ---- Modules ----

// Extrude a 2D profile (drawn in the x-z plane: 2D y maps to +z)
// along +y from y=0 to y=length.
module y_prism(length) {
    translate([0, length, 0])
        rotate([90, 0, 0])
            linear_extrude(height = length)
                children();
}

// === MOUNT PLATE ===
// Origin: plate back face (housing side) at x=0, front face at y=0,
// bottom at z=0. Bosses protrude to x=-_boss_d; the dovetail channels
// (oversized by the clearance, same as the housing's own left-side
// channels) open toward -x and run the full length in y.
module mount_plate() {
    difference() {
        union() {
            // Backplate
            cube([plate_thickness, plate_length, _plate_h]);

            // Female bosses, one band per rail (clamped to the plate;
            // adjacent bands merge when rails are close together)
            for (i = [0 : rail_count - 1]) {
                z0 = max(0, rail_z(i) - _boss_h / 2);
                z1 = min(_plate_h, rail_z(i) + _boss_h / 2);
                translate([-_boss_d, 0, z0])
                    cube([_boss_d + 0.05, plate_length, z1 - z0]);
            }
        }

        // Dovetail channels, oversized by the clearance so the rail
        // slides in from the front (geometry copied from the housing)
        for (i = [0 : rail_count - 1])
            translate([-_boss_d, -0.5, rail_z(i)])
                dovetail_rail(dovetail_narrow + clearance * 2,
                              dovetail_wide + clearance * 2,
                              dovetail_depth + clearance,
                              plate_length + 1);
    }
}

// 2D J-hook profile in the x-z plane: horizontal arm out of the plate
// at the bottom, rounded upturned tip. Throat = hook_depth.
module hook_profile() {
    r = hook_thickness / 2;
    tip_cx = plate_thickness + hook_depth + r;
    // Arm (sunk 1mm into the plate to weld)
    hull() {
        translate([plate_thickness - 1, r]) circle(r = r);
        translate([tip_cx, r]) circle(r = r);
    }
    // Upturned tip
    hull() {
        translate([tip_cx, r]) circle(r = r);
        translate([tip_cx, r + hook_tip_height]) circle(r = r);
    }
}

// 2D open-C profile in the x-z plane, opening facing straight down so
// a cable bundle pushes up past the rounded lips and is retained.
module catch_profile() {
    inner_r = catch_dia / 2;
    outer_r = inner_r + catch_wall;
    cx = plate_thickness + outer_r - 1;  // ring sunk 1mm into the plate
    cz = _plate_h / 2;
    mid_r = (inner_r + outer_r) / 2;
    lip_r = catch_wall / 2 - 0.2;        // inset: no tangent contact
    big = outer_r + 5;

    translate([cx, cz]) {
        difference() {
            circle(r = outer_r);
            circle(r = inner_r);
            // Opening wedge, centered straight down
            polygon([[0, 0],
                     [-big * sin(_catch_gap), -big * cos(_catch_gap)],
                     [ big * sin(_catch_gap), -big * cos(_catch_gap)]]);
        }
        // Rounded lips on the cut ends
        for (s = [-1, 1])
            translate([s * mid_r * sin(_catch_gap), -mid_r * cos(_catch_gap)])
                circle(r = lip_r);
    }
}

// === ACCESSORIES ===
// Each is mount_plate() plus its feature, welded as one body.

module headphone_hook() {
    mount_plate();
    y_prism(plate_length) hook_profile();
}

module pen_tray() {
    mount_plate();
    difference() {
        // Tray shell, overlapped 0.5mm into the plate to weld; the
        // plate itself is the tray's back wall
        translate([plate_thickness - 0.5, 0, 0])
            cube([tray_depth + 0.5, plate_length, tray_height]);
        // Cavity: opens through the top (cutter overshoots the rim)
        translate([plate_thickness, _tray_wall, _tray_wall])
            cube([tray_depth - _tray_wall,
                  plate_length - 2 * _tray_wall,
                  tray_height]);
    }
}

module cable_catch() {
    mount_plate();
    y_prism(plate_length) catch_profile();
}

// ---- Layout helpers ----

// Overall x footprint of each accessory (from boss tip to feature tip)
function w_hook()  = _boss_d + plate_thickness + hook_depth + hook_thickness;
function w_tray()  = _boss_d + plate_thickness + tray_depth;
function w_catch() = _boss_d + plate_thickness + catch_dia + 2 * catch_wall - 1;

// === DISPLAY ===

// Print layout: all three accessories standing on their front (y=0)
// face - the same orientation the housing prints in. See header.
module layout_all() {
    gap = 15;
    x_hook  = 0;
    x_tray  = x_hook + w_hook() + gap;
    x_catch = x_tray + w_tray() + gap;

    color("Coral")
        translate([x_hook + _boss_d, _plate_h, 0])
            rotate([90, 0, 0]) headphone_hook();
    color("MediumSeaGreen")
        translate([x_tray + _boss_d, _plate_h, 0])
            rotate([90, 0, 0]) pen_tray();
    color("SteelBlue")
        translate([x_catch + _boss_d, _plate_h, 0])
            rotate([90, 0, 0]) cable_catch();
}

// Mounted view: headphone hook on the actual drawer housing's
// right-side rails (housing at gridfinity_drawer defaults)
module show_mounted() {
    eps = 0.05;  // keep touching faces apart in the exported mesh
    color("SlateGray", 0.6)
        housing();
    color("Coral")
        translate(rail_mount_offset(20) + [eps, 0, 0])
            headphone_hook();
}

if (_display_mode == "all") {
    layout_all();
} else if (_display_mode == "hook") {
    headphone_hook();
} else if (_display_mode == "pen_tray") {
    pen_tray();
} else if (_display_mode == "cable_catch") {
    cable_catch();
} else if (_display_mode == "mounted") {
    show_mounted();
}
