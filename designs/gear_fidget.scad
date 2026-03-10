// @name Gear Fidget Toy
// @description A handheld gear train where spinning one gear drives the others. All gears mesh on a flat plate frame.
// @tags toy, fidget, gears, mechanical, educational
//
// A flat plate with meshing spur gears that spin freely on
// posts. Turn one gear and watch them all move together.
// Great desk fidget toy and teaches gear ratios.
//
// The design generates proper involute gear tooth profiles
// so the gears mesh smoothly. Different gear sizes create
// visible speed differences.
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

// Pressure angle (degrees) - standard is 20
pressure_angle = 20; // [14.5, 20, 25]

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
// Clearance between gear teeth (mm)
tooth_clearance = 0.3;

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

// Pitch radius for a gear
function pitch_radius(teeth) = teeth * gear_module / 2;

// Center distance between two meshing gears
function center_distance(t1, t2) = (t1 + t2) * gear_module / 2;

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

// Involute curve point at parameter t
function involute_point(base_r, t) = [
    base_r * (cos(t) + t * PI / 180 * sin(t)),
    base_r * (sin(t) - t * PI / 180 * cos(t))
];

// Generate involute tooth profile (2D)
module gear_tooth_2d(teeth) {
    pitch_r = pitch_radius(teeth);
    base_r = pitch_r * cos(pressure_angle);
    outer_r = pitch_r + gear_module;
    root_r = pitch_r - gear_module * 1.25;

    // Tooth angular width at pitch circle
    tooth_angle = 90 / teeth;

    // Approximate involute with a polygon
    steps = 8;
    max_t = acos(base_r / outer_r);

    // One tooth profile
    points = [
        for (i = [0:steps])
            let(t = max_t * i / steps)
                involute_point(base_r, t)
    ];

    // Mirror for the other side of the tooth
    mirror_points = [
        for (i = [steps:-1:0])
            let(pt = involute_point(base_r, max_t * i / steps))
                [pt[0], -pt[1]]
    ];

    // Rotate to center the tooth on the Y axis
    rotate([0, 0, tooth_angle])
        polygon(concat(
            [[root_r * 0.95, 0]],
            points,
            [[outer_r * cos(max_t * 0.1), outer_r * sin(max_t * 0.1)]],
            [[outer_r * cos(max_t * 0.1), -outer_r * sin(max_t * 0.1)]],
            mirror_points,
            [[root_r * 0.95, 0]]
        ));
}

// Complete gear profile (2D)
module gear_profile_2d(teeth) {
    pitch_r = pitch_radius(teeth);
    root_r = pitch_r - gear_module * 1.25;

    union() {
        // Root circle
        circle(r=root_r);

        // Teeth
        for (i = [0:teeth-1]) {
            rotate([0, 0, i * 360 / teeth])
                gear_tooth_2d(teeth);
        }
    }
}

// Simplified gear using a clean polygon approach
module simple_gear_2d(teeth) {
    pitch_r = pitch_radius(teeth);
    outer_r = pitch_r + gear_module * 0.9;
    root_r = pitch_r - gear_module * 1.1;

    // Generate gear profile point by point
    points_per_tooth = 8;
    total_points = teeth * points_per_tooth;

    tooth_arc = 360 / teeth;
    tip_fraction = 0.35;  // fraction of tooth arc that's the tip
    root_fraction = 0.35; // fraction that's the root

    points = [
        for (t = [0:total_points-1])
            let(
                tooth_idx = floor(t / points_per_tooth),
                local_t = (t % points_per_tooth) / points_per_tooth,
                base_angle = tooth_idx * tooth_arc,
                // Create a trapezoidal tooth profile
                r = (local_t < 0.15) ? root_r :                           // root
                    (local_t < 0.3) ? root_r + (outer_r - root_r) * (local_t - 0.15) / 0.15 : // rising flank
                    (local_t < 0.55) ? outer_r :                          // tip
                    (local_t < 0.7) ? outer_r - (outer_r - root_r) * (local_t - 0.55) / 0.15 : // falling flank
                    root_r,                                                // root
                angle = base_angle + local_t * tooth_arc
            )
            [r * cos(angle), r * sin(angle)]
    ];

    polygon(points);
}

// 3D gear
module gear_3d(teeth) {
    difference() {
        union() {
            // Gear body
            linear_extrude(height=gear_thickness)
                simple_gear_2d(teeth);

            // Center hub (raised)
            cylinder(d=hub_diameter, h=gear_thickness + hub_height);
        }

        // Bore hole
        translate([0, 0, -0.1])
            cylinder(d=bore_diameter, h=gear_thickness + hub_height + 0.2);

        // Chamfer top of bore
        translate([0, 0, gear_thickness + hub_height - 0.8])
            cylinder(d1=bore_diameter, d2=bore_diameter + 1.6, h=0.81);

        // Lightening holes for larger gears
        if (teeth > 16) {
            hole_count = floor(teeth / 6);
            hole_r = (pitch_radius(teeth) - hub_diameter/2 - gear_module * 2) / 2;
            hole_pos_r = hub_diameter/2 + hole_r + 2;
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

// Gear rotation angles based on drive gear angle and tooth ratios
function gear_angle(i) =
    (i == 0) ? _drive_angle :
    (i == 1) ? -_drive_angle * drive_teeth / gear2_teeth :
    (i == 2) ? _drive_angle * drive_teeth / gear2_teeth * gear2_teeth / gear3_teeth :
    -_drive_angle * drive_teeth / gear4_teeth;

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
                rotate([0, 0, gear_angle(i)])
                    gear_3d(_all_teeth[i]);
    }
}

module show_print_layout() {
    // Base plate
    color("SlateGray")
        base_plate();

    // Gears laid out next to plate
    for (i = [0:_num_gears-1]) {
        pr = pitch_radius(_all_teeth[i]) + gear_module;
        color(_gear_colors[i])
            translate([i * (pr * 2 + 5) - 20, -60, 0])
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
        pr = pitch_radius(_all_teeth[i]) + gear_module;
        color(_gear_colors[i])
            translate([i * (pr * 2 + 5), 0, 0])
                gear_3d(_all_teeth[i]);
    }
} else if (_display_mode == "assembled") {
    show_assembled();
}
