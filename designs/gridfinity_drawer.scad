// @name Gridfinity Under-Desk Drawer
// @description A modular drawer system that mounts under a desk surface. Drawers are sized in Gridfinity units and slide into rail housings.
// @tags gridfinity, storage, modular, desk
//
// Drawers are sized in Gridfinity units (42mm grid) and slide
// into rail housings. Housings interconnect via dovetail rails
// so you can chain multiple drawers side by side.
//
// Components:
//   Housing: C-channel that screws to the desk underside. The two
//            side walls carry inward ledges at the bottom; the drawer
//            rests on the ledges and slides front-to-back.
//   Drawer:  Plain box with a Gridfinity baseplate grid inside and an
//            oversized front flange that covers the housing opening
//            and acts as the insertion stop.
//
// Assembly:
//   1. Screw the housing to the underside of the desk (4 screws
//      through the top plate; insert them from inside the channel)
//   2. Slide the drawer in from the front until the flange seats
//   3. Chain additional housings by sliding their left dovetail
//      channels onto the previous housing's right dovetail rails
//
// Printing:
//   - Housing: print standing on its FRONT face (the cross-section is
//     constant front-to-back, so there are no overhangs)
//   - Drawer: print upright as modeled
//   - No supports needed

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

// Ledge thickness the drawer rides on (mm)
rail_height = 4.0;

// Ledge depth under the drawer's side edges (mm)
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

// Baseplate magnet hole diameter (mm) - 0 to disable. Standard 6x2mm
// magnets need baseplate_height >= magnet_hole_depth + 1.4, so raise
// baseplate_height (e.g. to 4.0) when enabling this.
magnet_hole_dia = 0;

// Baseplate magnet hole depth (mm)
magnet_hole_depth = 2.4;

/* [Interconnect] */
// Enable dovetail interconnects on housing sides
enable_interconnect = true;

// Dovetail rail width at the wall (mm)
dovetail_narrow = 6.0;

// Dovetail rail width at the tip (mm)
dovetail_wide = 10.0;

// Dovetail rail protrusion depth (mm)
dovetail_depth = 4.0;

// Number of dovetail rails per side
dovetail_count = 2; // [1:1:5]

/* [Display] */
// What to show
_display_mode = "both"; // ["both", "housing", "drawer", "assembled"]

// Drawer slide-out distance for assembled view (mm)
_slide_out = 0; // [0:5:200]

/* [Advanced] */
// Resolution
$fn = 40;

// Housing top plate thickness (mounts against desk)
top_plate = 3.0;

// Retention detent height on the ledges near the front (mm, clamped
// to the drawer clearance so the drawer can ride over it)
front_lip_height = 0.25;

// Drawer front flange thickness (mm)
drawer_front_extra = 3.0;

// Pull handle width (mm)
handle_width = 30; // [15:5:60]

// Pull handle depth (mm)
handle_depth = 8.0;

// ---- Derived dimensions ----

// Interior drawer dimensions
_inner_x = grid_units_x * grid_size;
_inner_y = grid_units_y * grid_size;

// Drawer body (box) dimensions - front and back walls both present
_drawer_x = _inner_x + 2 * wall;
_drawer_body_y = _inner_y + 2 * wall;
_drawer_z = drawer_height + bottom_thickness;

// Front flange covers the housing opening (up to the top plate)
_flange_t = drawer_front_extra;

// Housing: C-channel around the drawer
_housing_inner_x = _drawer_x + 2 * clearance;
_housing_x = _housing_inner_x + 2 * wall;
_housing_y = _drawer_body_y + 1;
_housing_z = rail_height + _drawer_z + clearance + top_plate;

_flange_w = _housing_x;
_flange_h = _drawer_z + clearance;

_detent_h = min(front_lip_height, clearance);

// Dovetail female boss depth (channel + backing material)
_boss_d = dovetail_depth + 2;

// The ledges must leave a gap for the drawer bottom to span
assert(_housing_inner_x > 2 * (rail_width + clearance) + 10,
    "rail_width too large for this drawer width");

// Magnet pockets need enough baseplate under them
assert(magnet_hole_dia == 0 || baseplate_height >= magnet_hole_depth + 1.4,
    str("Magnet pockets need baseplate_height >= ",
        magnet_hole_depth + 1.4, "mm (magnet depth + 1.4mm floor)"));


// ---- Modules ----

// Dovetail rail cross-section, attached at x=0, protruding +x,
// extruded along +y for the given length. Wide at the tip so mating
// parts lock against pull-apart in x.
module dovetail_rail(narrow, wide, depth, length) {
    rotate([-90, 0, 0])
        linear_extrude(height=length)
            polygon([
                [0, -narrow/2],
                [depth, -wide/2],
                [depth, wide/2],
                [0, narrow/2]
            ]);
}

// Vertical center positions for the dovetail rails
function dovetail_z(i) = _housing_z * (i + 1) / (dovetail_count + 1);

// Gridfinity baseplate single cell
module baseplate_cell() {
    cell = grid_size;
    base_outer = cell - 0.5;  // slight undersize for fit
    base_inner = base_outer - 3.2;
    h = baseplate_height;

    difference() {
        union() {
            // Outer platform
            linear_extrude(height=h)
                offset(r=1) offset(r=-1)
                    square([base_outer, base_outer], center=true);
        }

        // Inner recess (bins sit in here); floor thick enough for the
        // magnet pockets when they are enabled
        recess_floor = (magnet_hole_dia > 0) ? magnet_hole_depth + 0.6 : 0.8;
        translate([0, 0, recess_floor])
            linear_extrude(height=h)
                offset(r=0.8) offset(r=-0.8)
                    square([base_inner, base_inner], center=true);

        // Magnet pockets: Gridfinity standard is 26mm spacing
        // (13mm from cell center), open from the recess floor
        if (magnet_hole_dia > 0) {
            for (cx = [-1, 1], cy = [-1, 1]) {
                translate([cx * 13, cy * 13, recess_floor - magnet_hole_depth])
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

// 2D finger-pull profile (rounded trapezoid)
module handle_profile() {
    h = min(handle_depth, drawer_height * 0.6);
    w = min(handle_width, _inner_x * 0.8);
    hull() {
        translate([-w/2, 0]) circle(r=2);
        translate([w/2, 0]) circle(r=2);
        translate([-w/2 + 4, h - 2]) circle(r=2);
        translate([w/2 - 4, h - 2]) circle(r=2);
    }
}


// === DRAWER ===
// Origin: flange front face at y=0, drawer bottom at z=0.
// Body occupies y in [_flange_t, _flange_t + _drawer_body_y].
module drawer() {
    difference() {
        union() {
            // Front flange: covers the housing opening, acts as the
            // insertion stop. Flush with the drawer bottom so the
            // drawer prints upright without overhangs.
            translate([-(wall + clearance), 0, 0])
                cube([_flange_w, _flange_t, _flange_h]);

            // Main box
            translate([0, _flange_t, 0])
                difference() {
                    cube([_drawer_x, _drawer_body_y, _drawer_z]);
                    // Interior cavity (walls on all four sides)
                    translate([wall, wall, bottom_thickness])
                        cube([_inner_x, _inner_y, drawer_height + 1]);
                }
        }

        // Finger pull: slot through the flange and front wall, low on
        // the face (this is an under-desk drawer - you reach up for it)
        translate([_drawer_x / 2, -0.01, bottom_thickness + 2])
            rotate([-90, 0, 0])
                linear_extrude(height=_flange_t + wall + 0.1)
                    handle_profile();
    }

    // Gridfinity baseplate inside drawer, sunk slightly into the floor
    // so the cells weld to it as one solid
    if (enable_baseplate) {
        translate([wall, _flange_t + wall, bottom_thickness - 0.05])
            baseplate_grid(grid_units_x, grid_units_y);
    }
}


// === HOUSING ===
// Origin: front face at y=0, bottom of the side walls at z=0, top
// plate (desk side) at z=_housing_z. Cross-section is constant along
// y, so it prints standing on its front face with no overhangs.
module housing() {
    difference() {
        union() {
            // Side walls
            for (x0 = [0, _housing_x - wall])
                translate([x0, 0, 0])
                    cube([wall, _housing_y, _housing_z]);

            // Top plate
            translate([0, 0, _housing_z - top_plate])
                cube([_housing_x, _housing_y, top_plate]);

            // Ledges the drawer rides on
            for (side = [0, 1])
                translate([
                    side == 0 ? wall : _housing_x - wall - rail_width,
                    0, 0
                ])
                    cube([rail_width, _housing_y, rail_height]);

            // Retention detents: rounded bumps across the ledge tops
            // near the front; the drawer clicks over them
            if (_detent_h > 0) {
                for (side = [0, 1])
                    translate([
                        side == 0 ? wall : _housing_x - wall - rail_width,
                        4, rail_height
                    ])
                        rotate([0, 90, 0])
                            scale([_detent_h, 2, 1])
                                cylinder(r=1, h=rail_width);
            }

            // Dovetail rails on the right side
            if (enable_interconnect) {
                for (i = [0:dovetail_count-1])
                    translate([_housing_x, 0, dovetail_z(i)])
                        dovetail_rail(dovetail_narrow, dovetail_wide,
                                      dovetail_depth, _housing_y);
            }

            // Dovetail bosses on the left side (channels cut below)
            if (enable_interconnect) {
                for (i = [0:dovetail_count-1])
                    translate([-_boss_d, 0,
                               dovetail_z(i) - dovetail_wide/2 - 2.4])
                        cube([_boss_d, _housing_y, dovetail_wide + 4.8]);
            }
        }

        // Dovetail channels through the left bosses (oversized by the
        // clearance so the mating rail slides in from the front)
        if (enable_interconnect) {
            for (i = [0:dovetail_count-1])
                translate([-_boss_d, -0.5, dovetail_z(i)])
                    dovetail_rail(dovetail_narrow + clearance * 2,
                                  dovetail_wide + clearance * 2,
                                  dovetail_depth + clearance,
                                  _housing_y + 1);
        }

        // Mounting screw holes through the top plate, countersunk on
        // the inside face (screws go in from inside the channel)
        screw_margin = 15;
        for (sx = [screw_margin, _housing_x - screw_margin]) {
            for (sy = [screw_margin, _housing_y - screw_margin]) {
                translate([sx, sy, _housing_z - top_plate - 0.01]) {
                    cylinder(d=screw_hole_dia, h=top_plate + 0.02);
                    cylinder(d1=screw_hole_dia + 3, d2=screw_hole_dia, h=1.5);
                }
            }
        }
    }
}


// === DISPLAY ===

module show_assembled() {
    // Tiny separation so touching parts don't create tangent
    // (non-manifold) geometry in the exported mesh
    eps = 0.05;

    // Housing (modeled in mounted orientation, top plate up)
    color("SlateGray", 0.6)
        housing();

    // Drawer resting on the ledges, flange in front of the housing
    color("SteelBlue")
        translate([wall + clearance, -_flange_t - _slide_out - eps, rail_height + eps])
            drawer();

    // Desk surface representation
    color("BurlyWood", 0.3)
        translate([-20, -20, _housing_z + eps])
            cube([_housing_x + 40, _housing_y + 60, 18]);

    // Second housing chained onto the right dovetail rails (ghost):
    // its left boss face sits against this housing's right wall, so
    // the rails run inside the channels
    if (enable_interconnect) {
        color("SlateGray", 0.2)
            translate([_housing_x + _boss_d + eps, 0, 0])
                housing();
    }
}

module show_print_layout() {
    // Housing standing on its front face (print orientation)
    color("SlateGray")
        translate([0, _housing_z, 0])
            rotate([90, 0, 0])
                housing();

    // Drawer upright, next to it
    color("SteelBlue")
        translate([_housing_x + _boss_d + 15 + wall + clearance, 0, 0])
            drawer();
}

// Main display logic
if (_display_mode == "both") {
    show_print_layout();
} else if (_display_mode == "housing") {
    housing();
} else if (_display_mode == "drawer") {
    drawer();
} else if (_display_mode == "assembled") {
    show_assembled();
}
