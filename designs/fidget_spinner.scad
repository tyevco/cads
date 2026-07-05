// @name Fidget Spinner
// @description A bearing-less fidget spinner with weighted arms and pinch caps. Prints as 4 pieces.
// @tags toy, fidget, spinner, bearing
//
// A fidget spinner that uses a simple printed bushing instead
// of a bearing. The body spins freely on a plain axle; a pinch
// cap snaps over each axle end and retains the body.
//
// Components:
//   Body:     The main spinning piece with weighted arms
//   Axle:     Plain pin with a snap ridge near each end
//   Cap (x2): Finger caps that snap over the axle ends
//             (the caps act as the retaining flanges)
//
// Assembly: slide the body onto the axle, then push a cap onto
// each end until the snap ridge seats inside the cap socket.
//
// Printing:
//   - Print body flat, arms-down
//   - Print caps face-down, axle upright (use a brim)
//   - No supports needed
//   - Use 100% infill on the arm weights for best spin

/* [Spinner Body] */
// Number of arms
arm_count = 3; // [2:1:6]

// Arm length from center to weight center (mm)
arm_length = 30; // [20:2:50]

// Body thickness (mm)
body_thickness = 8; // [5:1:12]

// Arm width (mm)
arm_width = 14; // [10:1:20]

// Weight pocket diameter (mm) - for coins/hex nuts
weight_diameter = 20; // [14:1:28]

// Weight pocket depth (mm) - 0 to disable pockets
weight_depth = 4; // [0:0.5:8]

// Arm style
arm_style = "rounded"; // ["rounded", "tapered", "straight"]

/* [Center Hub] */
// Hub outer diameter (mm)
hub_diameter = 22; // [16:1:30]

// Axle hole diameter (mm) - the bore through the body
axle_hole_dia = 6.0; // [4:0.5:10]

/* [Axle] */
// Axle total length (mm) - auto-calculated if 0 (body + 2x cap engagement)
axle_length = 0;

// Axle diameter (mm) - sized to fit in axle hole with clearance
axle_diameter = 0; // auto-calculated if 0

// How far the axle protrudes into each cap (mm)
cap_engagement = 3.0;

/* [Finger Cap] */
// Cap outer diameter (mm)
cap_diameter = 20; // [14:1:28]

// Cap height (mm)
cap_height = 5; // [3:1:10]

// Cap grip style
cap_style = "knurled"; // ["smooth", "knurled", "domed"]

// Number of knurl ridges
knurl_count = 16; // [8:2:24]

/* [Tolerances] */
// Clearance between axle and hole (mm)
axle_clearance = 0.25;

// Cap snap-fit clearance (mm)
cap_clearance = 0.2;

/* [Display] */
// What to show
_display_mode = "all"; // ["all", "body", "axle", "cap", "assembled"]

/* [Advanced] */
$fn = 80;

// ---- Derived ----

_axle_dia = (axle_diameter > 0) ? axle_diameter : axle_hole_dia - axle_clearance * 2;
_axle_len = (axle_length > 0) ? axle_length : body_thickness + 2 * cap_engagement;
_cap_inner_dia = _axle_dia + cap_clearance * 2;


// ---- Modules ----

// Single arm profile (2D)
module arm_profile_2d(length, width, style) {
    if (style == "rounded") {
        hull() {
            circle(d=width);
            translate([length, 0]) circle(d=width);
        }
    } else if (style == "tapered") {
        hull() {
            circle(d=width);
            translate([length, 0]) circle(d=width * 1.4);
        }
    } else {
        // straight: parallel-sided bar with a squared-off tip
        // (the weight bulge at the tip rounds it off in 3D)
        circle(d=width);
        translate([0, -width/2]) square([length, width]);
    }
}

// Spinner body
module spinner_body() {
    difference() {
        union() {
            // Central hub
            cylinder(d=hub_diameter, h=body_thickness);

            // Arms radiating outward
            for (a = [0:arm_count-1]) {
                rotate([0, 0, a * 360 / arm_count])
                    linear_extrude(height=body_thickness)
                        arm_profile_2d(arm_length, arm_width, arm_style);
            }

            // Weight bulges at arm tips
            for (a = [0:arm_count-1]) {
                rotate([0, 0, a * 360 / arm_count])
                    translate([arm_length, 0, 0])
                        cylinder(d=weight_diameter, h=body_thickness);
            }
        }

        // Center axle hole
        translate([0, 0, -0.1])
            cylinder(d=axle_hole_dia, h=body_thickness + 0.2);

        // Weight pockets (for adding coins/nuts)
        if (weight_depth > 0) {
            for (a = [0:arm_count-1]) {
                rotate([0, 0, a * 360 / arm_count])
                    translate([arm_length, 0, body_thickness - weight_depth])
                        cylinder(d=weight_diameter - 2, h=weight_depth + 0.1);
            }
        }

        // Chamfer top and bottom of axle hole: each cone is widest at the
        // surface and narrows going into the body
        for (z = [0, body_thickness]) {
            translate([0, 0, z])
                mirror([0, 0, z == 0 ? 0 : 1])
                    translate([0, 0, -0.01])
                        cylinder(d1=axle_hole_dia + 2, d2=axle_hole_dia, h=1);
        }
    }
}

// Center axle: a plain pin. The caps are the retaining flanges, held by
// a chamfered snap ridge near each end (the cap's flex slots let the
// socket pop over the ridge).
module axle() {
    ridge_d = _axle_dia + 0.8;

    // Main shaft
    cylinder(d=_axle_dia, h=_axle_len);

    // Snap ridges, chamfered on both sides for easy insertion
    for (z = [1.5, _axle_len - 1.5]) {
        translate([0, 0, z - 0.6]) {
            cylinder(d1=_axle_dia, d2=ridge_d, h=0.6);
            translate([0, 0, 0.6])
                cylinder(d1=ridge_d, d2=_axle_dia, h=0.6);
        }
    }
}

// Finger cap
module finger_cap() {
    difference() {
        union() {
            if (cap_style == "domed") {
                // Domed top: upper half of a squashed sphere on a short
                // cylinder base (nothing dips below z=0)
                cylinder(d=cap_diameter, h=cap_height * 0.4);
                translate([0, 0, cap_height * 0.4])
                    intersection() {
                        scale([1, 1, cap_height * 0.6 / (cap_diameter / 2)])
                            sphere(d=cap_diameter);
                        cylinder(d=cap_diameter + 1, h=cap_height);
                    }
            } else if (cap_style == "knurled") {
                // Knurled cylinder
                difference() {
                    cylinder(d=cap_diameter, h=cap_height);
                    // Knurl grooves
                    for (a = [0:knurl_count-1]) {
                        rotate([0, 0, a * 360 / knurl_count])
                            translate([cap_diameter/2, 0, -0.1])
                                cylinder(d=2.0, h=cap_height + 0.2);
                    }
                }
                // Slight dome on top
                translate([0, 0, cap_height - 0.5])
                    scale([1, 1, 0.15])
                        sphere(d=cap_diameter - 2);
            } else {
                // Smooth with slight chamfer
                cylinder(d=cap_diameter, h=cap_height);
                translate([0, 0, cap_height - 0.01])
                    cylinder(d1=cap_diameter, d2=cap_diameter - 2, h=1);
            }
        }

        // Socket hole for axle
        translate([0, 0, -0.1])
            cylinder(d=_cap_inner_dia, h=cap_height * 0.7);

        // Snap-fit slot (allows flex for snap ridge)
        translate([0, 0, -0.1])
            for (a = [0, 90]) {
                rotate([0, 0, a])
                    translate([-0.5, -_cap_inner_dia, 0])
                        cube([1, _cap_inner_dia * 2, cap_height * 0.5]);
            }
    }
}


// ---- Display ----

module show_assembled() {
    spin_gap = 0.3; // running gap between each cap rim and the body face
    body_z = (_axle_len - body_thickness) / 2;

    // Body, centered on the axle
    color("DodgerBlue")
        translate([0, 0, body_z])
            spinner_body();

    // Axle
    color("Silver")
        axle();

    // Bottom cap: socket opening upward, rim just below the body
    color("Tomato")
        translate([0, 0, body_z - spin_gap])
            mirror([0, 0, 1])
                finger_cap();

    // Top cap: socket opening downward, rim just above the body
    color("Tomato")
        translate([0, 0, body_z + body_thickness + spin_gap])
            finger_cap();
}

module show_print_layout() {
    axle_x = arm_length + weight_diameter/2 + 15;

    // Body
    color("DodgerBlue")
        spinner_body();

    // Axle (printed upright)
    color("Silver")
        translate([axle_x, 0, 0])
            axle();

    // Two caps, face-down
    for (i = [0, 1]) {
        color("Tomato")
            translate([
                axle_x + _axle_dia + cap_diameter/2 + 5 + i * (cap_diameter + 5),
                0, 0
            ])
                finger_cap();
    }
}

// Main display logic
if (_display_mode == "all") {
    show_print_layout();
} else if (_display_mode == "body") {
    spinner_body();
} else if (_display_mode == "axle") {
    axle();
} else if (_display_mode == "cap") {
    finger_cap();
} else if (_display_mode == "assembled") {
    show_assembled();
}
