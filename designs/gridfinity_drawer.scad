// @name Gridfinity Under-Desk Drawer
// @description A modular drawer system that mounts under a desk surface. Drawers are sized in Gridfinity units and slide into rail housings.
// @tags gridfinity, storage, modular, desk
//
// Drawers are sized in Gridfinity units (42mm grid) and slide
// into rail housings. Housings interconnect via dovetail joints
// so you can chain multiple drawers side by side.
//
// Components:
//   Housing: Screws to desk underside, holds the drawer rails
//   Drawer:  Slides into housing, has Gridfinity baseplate grid
//
// Assembly:
//   1. Screw housing to underside of desk
//   2. Slide drawer into housing from the front
//   3. Snap additional housings onto the side dovetails

/* [Drawer Size] */
// Width in Gridfinity units (1 unit = 42mm)
grid_units_x = 3; // [1:1:8]

// Depth in Gridfinity units (1 unit = 42mm)
grid_units_y = 3; // [1:1:8]

// Interior drawer height (mm)
drawer_height = 30; // [15:5:80]

/* [Main Parameters] */
// Gridfinity grid spacing (mm) - standard is 42
grid_size = 42.0;

// Wall thickness (mm)
wall = 2.0;

// Drawer bottom thickness (mm)
bottom_thickness = 1.6;

// Rail height - how tall the slide rails are (mm)
rail_height = 4.0;

// Rail width - depth of the slide channel (mm)
rail_width = 3.0;

// Clearance between drawer and housing (mm)
clearance = 0.3;

// Mounting screw hole diameter (mm)
screw_hole_dia = 4.5;

/* [Gridfinity Base] */
// Enable Gridfinity baseplate grid inside drawer
enable_baseplate = true;

// Baseplate grid height (mm)
baseplate_height = 2.4;

// Baseplate magnet hole diameter (mm) - 0 to disable
magnet_hole_dia = 6.2;

// Baseplate magnet hole depth (mm)
magnet_hole_depth = 2.4;

/* [Interconnect] */
// Enable dovetail interconnects on housing sides
enable_interconnect = true;

// Dovetail width at narrow end (mm)
dovetail_narrow = 6.0;

// Dovetail width at wide end (mm)
dovetail_wide = 10.0;

// Dovetail height/depth (mm)
dovetail_height = 8.0;

// Number of dovetail joints per side
dovetail_count = 2; // [1:1:5]

/* [Display] */
// What to show
display_mode = "both"; // ["both", "housing", "drawer", "assembled"]

// Drawer slide-out distance for assembled view (mm)
slide_out = 0; // [0:5:200]

/* [Advanced] */
// Resolution
$fn = 40;

// Housing top plate thickness (mounts against desk)
top_plate = 3.0;

// Front lip height on housing (drawer stop)
front_lip_height = 2.0;

// Drawer front face extra thickness (mm)
drawer_front_extra = 1.5;

// Pull handle width (mm)
handle_width = 30; // [15:5:60]

// Pull handle depth (mm)
handle_depth = 8.0;

// ---- Derived dimensions ----

// Interior drawer dimensions
inner_x = grid_units_x * grid_size;
inner_y = grid_units_y * grid_size;

// Outer drawer dimensions
drawer_outer_x = inner_x + 2 * wall;
drawer_outer_y = inner_y + wall + drawer_front_extra;
drawer_outer_z = drawer_height + bottom_thickness;

// Housing interior (drawer + clearance + rails)
housing_inner_x = drawer_outer_x + 2 * clearance;
housing_inner_y = drawer_outer_y + clearance;
housing_inner_z = drawer_outer_z + clearance;

// Housing outer dimensions
housing_outer_x = housing_inner_x + 2 * wall;
housing_outer_y = housing_inner_y + wall;
housing_outer_z = housing_inner_z + top_plate + rail_height;


// ---- Modules ----

// 2D dovetail profile (centered, pointing up in +Y)
module dovetail_2d(narrow, wide, h) {
    hull() {
        translate([-narrow/2, 0])
            square([narrow, 0.01]);
        translate([-wide/2, h])
            square([wide, 0.01]);
    }
}

// Single dovetail tab (extruded along Z)
module dovetail_tab(narrow, wide, h, length) {
    rotate([90, 0, 0])
        rotate([0, 90, 0])
            linear_extrude(height=length, center=true)
                dovetail_2d(narrow, wide, h);
}

// Dovetail interconnect tabs along a side
module interconnect_tabs(side_length, count, narrow, wide, h) {
    spacing = side_length / (count + 1);
    for (i = [1:count]) {
        translate([0, 0, i * spacing])
            dovetail_tab(narrow, wide, h, dovetail_height);
    }
}

// Dovetail interconnect slots (for the receiving side)
module interconnect_slots(side_length, count, narrow, wide, h, depth) {
    tol = clearance;
    spacing = side_length / (count + 1);
    for (i = [1:count]) {
        translate([0, 0, i * spacing])
            dovetail_tab(narrow + tol, wide + tol, h + tol/2, depth + 1);
    }
}

// Gridfinity baseplate single cell
module baseplate_cell() {
    cell = grid_size;
    base_outer = cell - 0.5;  // slight undersize for fit
    base_inner = base_outer - 3.2;
    h = baseplate_height;

    difference() {
        // Outer platform
        translate([0, 0, 0])
            linear_extrude(height=h)
                offset(r=1) offset(r=-1)
                    square([base_outer, base_outer], center=true);

        // Inner recess
        translate([0, 0, 0.8])
            linear_extrude(height=h)
                offset(r=0.8) offset(r=-0.8)
                    square([base_inner, base_inner], center=true);

        // Magnet holes at corners
        if (magnet_hole_dia > 0) {
            for (cx = [-1, 1], cy = [-1, 1]) {
                translate([cx * (cell/2 - 4.8), cy * (cell/2 - 4.8), -0.01])
                    cylinder(d=magnet_hole_dia, h=magnet_hole_depth + 0.01);
            }
        }
    }
}

// Full Gridfinity baseplate grid
module baseplate_grid(nx, ny) {
    for (ix = [0:nx-1], iy = [0:ny-1]) {
        translate([
            (ix + 0.5) * grid_size,
            (iy + 0.5) * grid_size,
            0
        ])
            baseplate_cell();
    }
}

// Drawer pull handle (recessed finger pull)
module drawer_handle() {
    h = min(handle_depth, drawer_height * 0.6);
    w = min(handle_width, inner_x * 0.8);
    translate([0, 0, 0])
        rotate([90, 0, 0])
            linear_extrude(height=drawer_front_extra + wall + 0.1)
                hull() {
                    translate([-w/2, 0]) circle(r=2);
                    translate([w/2, 0]) circle(r=2);
                    translate([-w/2 + 4, h - 2]) circle(r=2);
                    translate([w/2 - 4, h - 2]) circle(r=2);
                }
}


// === DRAWER ===
module drawer() {
    difference() {
        union() {
            // Main box
            difference() {
                // Outer shell
                cube([drawer_outer_x, drawer_outer_y, drawer_outer_z]);

                // Interior cavity
                translate([wall, drawer_front_extra, bottom_thickness])
                    cube([inner_x, inner_y + wall + 1, drawer_height + 1]);
            }

            // Rail runners on each side (protrude outward)
            for (side = [0, 1]) {
                translate([
                    side * (drawer_outer_x - 0.01),
                    0,
                    bottom_thickness + clearance
                ]) {
                    mirror([side, 0, 0])
                        translate([-0.01, rail_width, 0])
                            cube([
                                rail_width + 0.01,
                                drawer_outer_y - 2 * rail_width,
                                rail_height
                            ]);
                }
            }
        }

        // Finger pull cutout on front face
        translate([drawer_outer_x / 2, 0.1, bottom_thickness + drawer_height * 0.15])
            drawer_handle();
    }

    // Gridfinity baseplate inside drawer
    if (enable_baseplate) {
        translate([wall, drawer_front_extra, bottom_thickness])
            baseplate_grid(grid_units_x, grid_units_y);
    }
}


// === HOUSING ===
module housing() {
    difference() {
        union() {
            // Main housing shell
            difference() {
                // Outer box
                cube([housing_outer_x, housing_outer_y, housing_outer_z]);

                // Interior cavity for the drawer
                translate([wall, -0.01, 0])
                    cube([
                        housing_inner_x,
                        housing_inner_y + 0.02,
                        housing_inner_z + rail_height
                    ]);
            }

            // Rail channels on inner side walls
            for (side = [0, 1]) {
                translate([
                    wall + (side * (housing_inner_x - rail_width - clearance)),
                    0,
                    bottom_thickness + clearance * 2
                ]) {
                    // Rail ledge
                    cube([
                        rail_width + clearance,
                        housing_inner_y - rail_width,
                        rail_height + clearance
                    ]);
                }
            }

            // Front lip (drawer stop)
            translate([wall, 0, 0])
                cube([housing_inner_x, wall, front_lip_height]);

            // Dovetail interconnect tabs on the right side
            if (enable_interconnect) {
                translate([housing_outer_x, housing_outer_y / 2, 0])
                    rotate([0, 0, 0])
                        interconnect_tabs(
                            housing_outer_z,
                            dovetail_count,
                            dovetail_narrow,
                            dovetail_wide,
                            wall
                        );
            }
        }

        // Dovetail slots on the left side
        if (enable_interconnect) {
            translate([-0.01, housing_outer_y / 2, 0])
                interconnect_slots(
                    housing_outer_z,
                    dovetail_count,
                    dovetail_narrow,
                    dovetail_wide,
                    wall,
                    wall + 0.5
                );
        }

        // Mounting screw holes through top plate
        screw_margin = 15;
        for (sx = [screw_margin, housing_outer_x - screw_margin]) {
            for (sy = [screw_margin, housing_outer_y - screw_margin]) {
                translate([sx, sy, housing_outer_z - top_plate - 0.01]) {
                    // Through hole
                    cylinder(d=screw_hole_dia, h=top_plate + 0.02);
                    // Countersink
                    translate([0, 0, top_plate - 1.5])
                        cylinder(d1=screw_hole_dia, d2=screw_hole_dia + 3, h=1.52);
                }
            }
        }

        // Open front for drawer entry
        translate([wall, -0.01, front_lip_height])
            cube([housing_inner_x, wall + 0.02, housing_inner_z + rail_height]);
    }
}


// === DISPLAY ===

module show_assembled() {
    // Housing
    color("SlateGray", 0.6)
        // Flip housing so top plate faces up (against desk)
        translate([0, 0, housing_outer_z])
            rotate([0, 180, 0])
                translate([-housing_outer_x, 0, 0])
                    housing();

    // Drawer inside housing
    color("SteelBlue")
        translate([
            wall + clearance,
            -slide_out,
            clearance
        ])
            drawer();

    // Desk surface representation
    color("BurlyWood", 0.3)
        translate([-20, -20, housing_outer_z])
            cube([housing_outer_x + 40, housing_outer_y + 60, 18]);

    // Second housing (interconnected) shown as ghost
    if (enable_interconnect) {
        color("SlateGray", 0.2)
            translate([housing_outer_x, 0, housing_outer_z])
                rotate([0, 180, 0])
                    translate([-housing_outer_x, 0, 0])
                        housing();
    }
}

module show_print_layout() {
    // Housing
    color("SlateGray")
        housing();

    // Drawer offset to the right
    color("SteelBlue")
        translate([housing_outer_x + 15, 0, 0])
            drawer();
}

// Main display logic
if (display_mode == "both") {
    show_print_layout();
} else if (display_mode == "housing") {
    housing();
} else if (display_mode == "drawer") {
    drawer();
} else if (display_mode == "assembled") {
    show_assembled();
}
