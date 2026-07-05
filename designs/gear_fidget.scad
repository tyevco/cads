// @name Gear Fidget Toy
// @description A handheld gear train where spinning one gear drives the others. All gears mesh on a flat plate frame.
// @tags toy, fidget, gears, mechanical, educational
//
use <../macros/gears.scad>
//
// A flat plate with meshing spur gears that spin freely on
// posts. Turn one gear and watch them all move together.
// Great desk fidget toy and teaches gear ratios.
//
// Gears use a simplified trapezoidal tooth profile with backlash
// (tooth_clearance), which meshes smoothly at toy tolerances.
// Different gear sizes create visible speed differences.
//
// Printing:
//   - Print the base plate first
//   - Print gears separately, flat side down
//   - Press gears onto the posts
//   - No supports needed

/* [Gear Configuration] */
// Number of teeth on the main (drive) gear
drive_teeth = 20; // [12:1:36]

// Number of teeth on the second gear
gear2_teeth = 12; // [8:1:30]

// Number of teeth on the third gear
gear3_teeth = 16; // [8:1:30]

// Enable a fourth gear
enable_gear4 = true;

// Number of teeth on the fourth gear
gear4_teeth = 10; // [8:1:30]

/* [Gear Dimensions] */
// Module (tooth size factor, mm) - standard gear parameter
gear_module = 2.5; // [1.5:0.5:4]

// Gear thickness (mm)
gear_thickness = 6; // [4:1:10]

// Gear bore diameter (mm) - hole for the post
bore_diameter = 5.0; // [3:0.5:8]

// Hub diameter around bore (mm)
hub_diameter = 12; // [8:1:16]

// Hub extra height above gear (mm)
hub_height = 2; // [0:0.5:4]

/* [Base Plate] */
// Plate thickness (mm)
plate_thickness = 4; // [2:1:6]

// Plate corner radius (mm)
plate_fillet = 5;

// Plate border padding around gears (mm)
plate_padding = 8; // [4:1:15]

// Post height above plate (mm)
post_height = 0; // auto if 0

// Post diameter (mm)
post_diameter = 0; // auto if 0

/* [Tolerances] */
// Backlash between gear teeth (mm). The straight trapezoid flanks are
// not perfectly conjugate, so they need this much running clearance to
// rotate without binding (verified by intersection sweep).
tooth_clearance = 0.5;

// Clearance between gear bore and post (mm)
bore_clearance = 0.3;

/* [Display] */
// What to show
_display_mode = "all"; // ["all", "plate", "gears", "assembled"]

// Rotation angle of drive gear for assembled view
_drive_angle = 0; // [0:5:360]

/* [Advanced] */
$fn = 60;

// ---- Gear math ----

// Thin wrappers over macros/gears.scad with this design's module size
function pitch_radius(teeth) = gear_pitch_radius(teeth, gear_module);
function center_distance(t1, t2) = gear_center_distance(t1, t2, gear_module);

// Gear positions (gear 1 at origin, others placed around it)
_g1_pos = [0, 0];

// Place gear 2 to the right of gear 1
_g2_pos = [center_distance(drive_teeth, gear2_teeth), 0];

// Place gear 3 meshing with gear 2, angled up
_g2g3_dist = center_distance(gear2_teeth, gear3_teeth);
_g3_angle = 70; // degrees from horizontal
_g3_pos = [_g2_pos[0] + _g2g3_dist * cos(_g3_angle),
           _g2_pos[1] + _g2g3_dist * sin(_g3_angle)];

// Place gear 4 meshing with gear 1, angled up-left
_g1g4_dist = center_distance(drive_teeth, gear4_teeth);
_g4_angle = 120;
_g4_pos = [_g1_pos[0] + _g1g4_dist * cos(_g4_angle),
           _g1_pos[1] + _g1g4_dist * sin(_g4_angle)];

// Collect all gear positions and teeth counts
_all_positions = enable_gear4 ?
    [_g1_pos, _g2_pos, _g3_pos, _g4_pos] :
    [_g1_pos, _g2_pos, _g3_pos];

_all_teeth = enable_gear4 ?
    [drive_teeth, gear2_teeth, gear3_teeth, gear4_teeth] :
    [drive_teeth, gear2_teeth, gear3_teeth];

_num_gears = enable_gear4 ? 4 : 3;

// Derived dimensions
_post_dia = (post_diameter > 0) ? post_diameter : bore_diameter - bore_clearance * 2;
_post_h = (post_height > 0) ? post_height : gear_thickness + hub_height + 1;


// ---- Modules ----

// 3D gear
module gear_3d(teeth) {
    difference() {
        union() {
            // Gear body (the library profile applies tooth_clearance as
            // backlash and rounds the tooth tips)
            linear_extrude(height=gear_thickness)
                gear_spur_2d(teeth, gear_module, tooth_clearance);

            // Center hub (raised)
            cylinder(d=hub_diameter, h=gear_thickness + hub_height);
        }

        // Bore hole
        translate([0, 0, -0.1])
            cylinder(d=bore_diameter, h=gear_thickness + hub_height + 0.2);

        // Chamfer top of bore
        translate([0, 0, gear_thickness + hub_height - 0.8])
            cylinder(d1=bore_diameter, d2=bore_diameter + 1.6, h=0.81);

        // Lightening holes for larger gears: sized to the solid annulus
        // between the hub and the tooth roots, with margin on both sides
        if (teeth > 16) {
            root_r = pitch_radius(teeth) - gear_module * 1.1;
            ring_in = hub_diameter/2 + 1.5;
            ring_out = root_r - 1.5;
            hole_r = (ring_out - ring_in) / 2;
            hole_pos_r = (ring_in + ring_out) / 2;
            hole_count = floor(teeth / 6);
            if (hole_r > 2) {
                for (i = [0:hole_count-1]) {
                    rotate([0, 0, i * 360 / hole_count])
                        translate([hole_pos_r, 0, -0.1])
                            cylinder(r=hole_r, h=gear_thickness + 0.2);
                }
            }
        }
    }
}

// Base plate
module base_plate() {
    // Find bounding box of all gear positions
    all_r = [for (i = [0:_num_gears-1])
                pitch_radius(_all_teeth[i]) + gear_module + plate_padding];

    // Simple approach: hull around circles at each gear position
    linear_extrude(height=plate_thickness)
        offset(r=plate_fillet) offset(r=-plate_fillet)
            hull() {
                for (i = [0:_num_gears-1]) {
                    translate(_all_positions[i])
                        circle(r=pitch_radius(_all_teeth[i]) + gear_module + plate_padding);
                }
            }

    // Posts for each gear
    for (i = [0:_num_gears-1]) {
        translate([_all_positions[i][0], _all_positions[i][1], plate_thickness])
            cylinder(d=_post_dia, h=_post_h);
    }
}


// ---- Display ----

// Accessors (also used by the verification harness)
function gear_position(i) = _all_positions[i];
function gear_teeth(i) = _all_teeth[i];

// Meshing phase math lives in macros/gears.scad
function mesh_rotation(rd, td, tg, a) = gear_mesh_rotation(rd, td, tg, a);

// Rotation angle of each gear for a given drive-gear angle.
// Gear 2 (index 1) is driven by the drive gear along a=0; gear 3 is
// driven by gear 2 along _g3_angle; gear 4 by the drive gear along _g4_angle.
function gear_angle(i, theta) =
    (i == 0) ? theta :
    (i == 1) ? mesh_rotation(theta, drive_teeth, gear2_teeth, 0) :
    (i == 2) ? mesh_rotation(gear_angle(1, theta), gear2_teeth, gear3_teeth, _g3_angle) :
    mesh_rotation(theta, drive_teeth, gear4_teeth, _g4_angle);

// Print-layout x positions: cumulative so gears never overlap
function gear_outer_r(i) = pitch_radius(_all_teeth[i]) + gear_module;
function gear_row_x(i) =
    i <= 0 ? 0 : gear_row_x(i - 1) + gear_outer_r(i - 1) + gear_outer_r(i) + 5;

// Lowest y the plate reaches (for placing the gear row clear of it)
_plate_min_y = min([for (i = [0:_num_gears-1])
    _all_positions[i][1] - (pitch_radius(_all_teeth[i]) + gear_module + plate_padding)]);
_max_gear_r = max([for (i = [0:_num_gears-1]) gear_outer_r(i)]);

_gear_colors = ["DodgerBlue", "Tomato", "LimeGreen", "Gold"];

module show_assembled() {
    // Base plate
    color("SlateGray")
        base_plate();

    // Gears on posts
    for (i = [0:_num_gears-1]) {
        color(_gear_colors[i])
            translate([_all_positions[i][0], _all_positions[i][1],
                       plate_thickness + 0.5])
                rotate([0, 0, gear_angle(i, _drive_angle)])
                    gear_3d(_all_teeth[i]);
    }
}

module show_print_layout() {
    // Base plate
    color("SlateGray")
        base_plate();

    // Gears laid out in a row below the plate
    for (i = [0:_num_gears-1]) {
        color(_gear_colors[i])
            translate([gear_row_x(i) - 20, _plate_min_y - _max_gear_r - 5, 0])
                gear_3d(_all_teeth[i]);
    }
}

// Main display logic
if (_display_mode == "all") {
    show_print_layout();
} else if (_display_mode == "plate") {
    base_plate();
} else if (_display_mode == "gears") {
    for (i = [0:_num_gears-1]) {
        color(_gear_colors[i])
            translate([gear_row_x(i), 0, 0])
                gear_3d(_all_teeth[i]);
    }
} else if (_display_mode == "assembled") {
    show_assembled();
}
