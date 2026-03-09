// Cardboard Box Handle/Latch - Two Piece Design
// ================================================
// A two-piece mechanism that goes through a slot in cardboard.
//
// Piece 1 (Handle): Outside the box - has a rotating grip handle
//   and a shaft that passes through the cardboard.
//
// Piece 2 (Hook/Latch): Inside the box - slides onto the shaft,
//   has a hook arm that rotates to grip the cardboard.
//
// Assembly:
//   1. Push the handle shaft through a round hole in the cardboard
//   2. From inside, slide the hook piece onto the shaft
//   3. The hook piece snaps/friction-fits onto the shaft
//   4. Rotating the handle rotates the hook on the other side
//
// The shaft uses a D-shaped cross section so the two pieces
// rotate together as one unit.

/* [Main Parameters] */
// Thickness of the cardboard (mm)
cardboard_thickness = 3.0;

// Diameter of the shaft that goes through the cardboard (mm)
shaft_diameter = 8.0;

// Total length of the shaft (extends through cardboard + both sides)
shaft_length = 12.0;

// Clearance/tolerance for fitting parts together (mm)
tolerance = 0.3;

/* [Handle Parameters] */
// Length of the handle grip (mm)
handle_length = 50.0;

// Width of the handle grip (mm)
handle_width = 12.0;

// Height/thickness of the handle grip (mm)
handle_height = 6.0;

// Fillet radius on handle edges (mm)
handle_fillet = 2.0;

// Diameter of the flange that sits against the cardboard (mm)
flange_diameter = 18.0;

// Thickness of the flange (mm)
flange_thickness = 2.0;

/* [Hook Parameters] */
// Length of the hook arm from center (mm)
hook_arm_length = 20.0;

// Width of the hook arm (mm)
hook_arm_width = 10.0;

// Thickness of the hook arm (mm)
hook_arm_thickness = 4.0;

// Height of the hook lip that grabs the cardboard (mm)
hook_lip_height = 5.0;

// Width of the hook lip (mm)
hook_lip_width = 3.0;

/* [Display] */
// What to show
display_mode = "both"; // ["both", "handle", "hook", "assembled"]

// Angle of hook rotation for assembled view (degrees)
assembled_angle = 90; // [0:5:360]

/* [Advanced] */
// Resolution
$fn = 60;

// D-flat depth as fraction of shaft radius
d_flat_fraction = 0.25;


// ---- Modules ----

// D-shaped shaft cross section
module d_shaft_2d(diameter, flat_fraction=0.25) {
    r = diameter / 2;
    flat_depth = r * flat_fraction;
    intersection() {
        circle(d=diameter);
        translate([-r, -r])
            square([2*r, 2*r - flat_depth]);
    }
}

// D-shaped hole (with tolerance)
module d_hole_2d(diameter, flat_fraction=0.25, tol=0.3) {
    d = diameter + tol;
    r = d / 2;
    flat_depth = (diameter/2) * flat_fraction - tol/2;
    intersection() {
        circle(d=d);
        translate([-r, -r])
            square([2*r, 2*r - flat_depth]);
    }
}

// Rounded rectangle
module rounded_rect(size, radius) {
    x = size[0];
    y = size[1];
    r = min(radius, min(x,y)/2);
    hull() {
        for (sx = [r, x-r])
            for (sy = [r, y-r])
                translate([sx, sy])
                    circle(r=r);
    }
}

// === HANDLE PIECE ===
// The outside piece with a grip handle, flange, and D-shaft
module handle_piece() {
    shaft_r = shaft_diameter / 2;

    // The shaft
    linear_extrude(height=shaft_length)
        d_shaft_2d(shaft_diameter, d_flat_fraction);

    // Flange at the base (sits against cardboard)
    translate([0, 0, shaft_length])
        cylinder(d=flange_diameter, h=flange_thickness);

    // Handle grip on top of flange
    translate([0, 0, shaft_length + flange_thickness]) {
        // Rounded bar handle
        linear_extrude(height=handle_height) {
            translate([-handle_length/2, -handle_width/2])
                rounded_rect([handle_length, handle_width], handle_fillet);
        }

        // Slight dome/rounding on top for comfort
        translate([0, 0, handle_height])
            scale([handle_length/2, handle_width/2, 2])
                intersection() {
                    sphere(r=1);
                    translate([0,0,0]) cube([2,2,1], center=true);
                }
    }
}


// === HOOK/LATCH PIECE ===
// The inside piece with a D-hole socket and hook arm
module hook_piece() {
    socket_depth = 5.0;
    base_thickness = hook_arm_thickness;

    difference() {
        union() {
            // Central hub with D-hole socket
            cylinder(d=flange_diameter - 2, h=base_thickness);

            // Hook arm extending to one side
            translate([0, -hook_arm_width/2, 0])
                cube([hook_arm_length, hook_arm_width, hook_arm_thickness]);

            // Hook arm extending to the other side (symmetric)
            translate([-hook_arm_length, -hook_arm_width/2, 0])
                cube([hook_arm_length, hook_arm_width, hook_arm_thickness]);

            // Hook lips at the ends (these grab the cardboard)
            for (side = [1, -1]) {
                translate([side * hook_arm_length, -hook_arm_width/2, 0])
                    cube([side > 0 ? hook_lip_width : 0,
                          hook_arm_width,
                          hook_arm_thickness + hook_lip_height]);
                if (side < 0)
                    translate([side * hook_arm_length - hook_lip_width,
                              -hook_arm_width/2, 0])
                        cube([hook_lip_width,
                              hook_arm_width,
                              hook_arm_thickness + hook_lip_height]);
            }
        }

        // D-shaped socket hole going through
        translate([0, 0, -0.1])
            linear_extrude(height=base_thickness + 0.2)
                d_hole_2d(shaft_diameter, d_flat_fraction, tolerance);
    }

    // Snap ring / retention ridge inside the socket
    // Small ridge at the bottom to hold the shaft in place
    translate([0, 0, 0])
        difference() {
            cylinder(d=shaft_diameter + tolerance + 1.5, h=0.8);
            translate([0, 0, -0.1])
                cylinder(d=shaft_diameter + tolerance, h=1.0);
        }
}


// === DISPLAY ===

module show_assembled() {
    // Cardboard representation (translucent)
    color("burlywood", 0.4)
        translate([-30, -30, 0])
            cube([60, 60, cardboard_thickness]);

    // Handle on top (outside)
    color("DodgerBlue")
        translate([0, 0, cardboard_thickness])
            handle_piece();

    // Hook on bottom (inside), rotated
    color("Tomato")
        translate([0, 0, 0])
            mirror([0, 0, 1])
                rotate([0, 0, assembled_angle])
                    hook_piece();
}

module show_print_layout() {
    // Handle piece
    color("DodgerBlue")
        translate([-35, 0, 0])
            handle_piece();

    // Hook piece - flipped for printing
    color("Tomato")
        translate([35, 0, hook_arm_thickness])
            mirror([0, 0, 1])
                hook_piece();
}

// Main display logic
if (display_mode == "both") {
    show_print_layout();
} else if (display_mode == "handle") {
    handle_piece();
} else if (display_mode == "hook") {
    hook_piece();
} else if (display_mode == "assembled") {
    show_assembled();
}
