// @name Cardboard Box Latch
// @description A two-piece handle/latch mechanism for cardboard boxes. Features a D-shaped shaft for aligned rotation.
// @tags box, latch, handle, cardboard

use <../macros/shapes.scad>
//
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
_display_mode = "both"; // ["both", "handle", "hook", "assembled"]

// Angle of hook rotation for assembled view (degrees)
_assembled_angle = 90; // [0:5:360]

/* [Advanced] */
// Resolution
$fn = 60;

// D-flat depth as fraction of shaft radius
_d_flat_fraction = 0.25;


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

// === HANDLE PIECE ===
// The outside piece with a grip handle, flange, and D-shaft.
// Modeled shaft-tip-down: shaft z=0..shaft_length, flange above it,
// grip on top. The print layout flips it grip-down.
module handle_piece() {
    grip_z = shaft_length + flange_thickness;

    // The shaft
    linear_extrude(height=shaft_length)
        d_shaft_2d(shaft_diameter, _d_flat_fraction);

    // Flange at the base (sits against cardboard)
    translate([0, 0, shaft_length])
        cylinder(d=flange_diameter, h=flange_thickness);

    // 45-degree transition from grip up to flange so the flange edge is
    // self-supporting when printed grip-down (flange is wider than the grip)
    translate([0, 0, grip_z])
        cylinder(d1=flange_diameter, d2=handle_width,
                 h=(flange_diameter - handle_width)/2);

    // Handle grip: rounded block, flat faces with filleted edges
    // (rounded_cube spans [-r..size-r], so recenter in x/y and lift by r)
    translate([-(handle_length/2 - handle_fillet),
               -(handle_width/2 - handle_fillet),
               grip_z + handle_fillet])
        rounded_cube([handle_length, handle_width, handle_height], handle_fillet);
}

// Total height of the handle piece (for print-layout flipping)
function handle_total_height() = shaft_length + flange_thickness + handle_height;


// === HOOK/LATCH PIECE ===
// The inside piece with a D-hole socket and hook arm.
// Modeled base-down: base plate z=0..hook_arm_thickness, lips rising above.
// The shaft is inserted from the top face (the face toward the cardboard).
module hook_piece() {
    base_thickness = hook_arm_thickness;
    bore_d = shaft_diameter + tolerance;
    ridge_h = 0.8;
    ridge_bite = 0.3; // radial interference per side against the shaft

    union() {
        difference() {
            union() {
                // Central hub with D-hole socket
                cylinder(d=flange_diameter - 2, h=base_thickness);

                // Hook arms extending symmetrically to both sides
                translate([-hook_arm_length, -hook_arm_width/2, 0])
                    cube([2 * hook_arm_length, hook_arm_width, hook_arm_thickness]);

                // Hook lips at the arm ends (these grab the cardboard)
                for (side = [1, -1])
                    translate([side > 0 ? hook_arm_length
                                        : -hook_arm_length - hook_lip_width,
                               -hook_arm_width/2, 0])
                        cube([hook_lip_width,
                              hook_arm_width,
                              hook_arm_thickness + hook_lip_height]);
            }

            // D-shaped socket hole going through
            translate([0, 0, -0.1])
                linear_extrude(height=base_thickness + 0.2)
                    d_hole_2d(shaft_diameter, _d_flat_fraction, tolerance);
        }

        // Friction/retention ridge: intrudes slightly into the bore at the
        // exit (bottom) face, tapering open toward the insertion side so the
        // shaft slides in and is then gripped by the interference.
        difference() {
            cylinder(d=bore_d + 1.5, h=ridge_h);
            translate([0, 0, -0.05])
                cylinder(d1=bore_d - 2*ridge_bite, d2=bore_d, h=ridge_h + 0.1);
        }
    }
}


// === DISPLAY ===

module show_assembled() {
    // Cardboard panel with the shaft hole (translucent)
    color("burlywood", 0.4)
        difference() {
            translate([-30, -30, 0])
                cube([60, 60, cardboard_thickness]);
            translate([0, 0, -0.5])
                cylinder(d=shaft_diameter + tolerance + 1,
                         h=cardboard_thickness + 1);
        }

    // The two pieces rotate together as one unit (that's the point of
    // the D-shaft), so the assembly angle applies to both.
    rotate([0, 0, _assembled_angle]) {
        // Handle outside: flange resting on the panel, shaft pointing
        // down through the hole
        color("DodgerBlue")
            translate([0, 0, cardboard_thickness - shaft_length])
                handle_piece();

        // Hook inside: socket on the shaft, lips reaching up to the
        // panel's inside face
        color("Tomato")
            translate([0, 0, -(hook_arm_thickness + hook_lip_height)])
                hook_piece();
    }
}

module show_print_layout() {
    // Handle piece: grip-down (flat grip face on the plate; the flange
    // transition cone keeps every overhang at 45 degrees or less)
    color("DodgerBlue")
        translate([-35, 0, handle_total_height()])
            mirror([0, 0, 1])
                handle_piece();

    // Hook piece: base-down, lips up - already in print orientation
    color("Tomato")
        translate([35, 0, 0])
            hook_piece();
}

// Main display logic
if (_display_mode == "both") {
    show_print_layout();
} else if (_display_mode == "handle") {
    handle_piece();
} else if (_display_mode == "hook") {
    hook_piece();
} else if (_display_mode == "assembled") {
    show_assembled();
}
