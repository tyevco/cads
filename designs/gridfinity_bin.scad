// @name Gridfinity Bin
// @description Parametric Gridfinity-compatible storage bins with dividers, front scoop, label lip and stacking lip. Drops into the under-desk drawer's baseplate grid.
// @tags gridfinity, storage, bin, modular, organizer
//
// Companion to gridfinity_drawer.scad: the stepped feet on the underside
// drop into that design's baseplate cells (42mm grid, 38.3mm recess,
// recess floor 0.8mm below the 2.4mm platform top).
//
// Geometry (z=0 at the bottom of the feet):
//   Feet:  one 37.8mm square foot per grid cell (38.3mm recess minus
//          2 x 0.25mm fit clearance), 1.4mm tall so the body underside
//          rests on the platform top while the foot floats 0.2mm above
//          the recess floor.
//   Body:  41.5mm-per-cell footprint (42mm pitch minus 2 x 0.25mm),
//          height_units x 7mm tall, rounded r=1 corners.
//   Lip:   optional 1.6mm stacking lip on top whose inner opening
//          replicates the baseplate recess (body inset 1.6mm, r=0.8),
//          so the feet of another bin drop in with the same clearance.
//   Extras: interior dividers, front scoop fillet, 45-degree-backed
//          label lip along the front top edge.
//
// Stacking: a bin placed at z = height_units*7 + 1.65 above another
// bin's origin seats on its lip (see bin_stack_z()). Seating on a
// baseplate cell puts the bin origin at z = 1.05 (see bin_seat_z()).
//
// Printing:
//   - Print as modeled, standing on the feet ("bin"/"divided" modes).
//   - The 1.85mm underside ring around each foot (and the 4.2mm spans
//     between feet on multi-cell bins) print as short bridges - no
//     supports needed.
//   - Scoop fillet and label lip underside are 45 degrees or shallower.

use <gridfinity_drawer.scad>

/* [Size] */
// Width in Gridfinity units (1 unit = 42mm)
grid_units_x = 2; // [1:1:4]

// Depth in Gridfinity units (1 unit = 42mm)
grid_units_y = 1; // [1:1:4]

// Height in Gridfinity height units (1 unit = 7mm)
height_units = 3; // [2:1:8]

/* [Interior] */
// Dividers across the width (walls perpendicular to x, "divided" mode)
divider_count_x = 2; // [0:1:3]

// Dividers across the depth (walls perpendicular to y, "divided" mode)
divider_count_y = 0; // [0:1:3]

// Front scoop fillet radius (mm) - 0 disables
scoop_radius = 6; // [0:1:12]

// Label lip along the front top edge
label_lip = true;

// Label lip depth into the bin (mm)
label_depth = 12; // [8:1:16]

/* [Stacking] */
// Stacking lip on top (mates with the feet of the bin above)
stacking_lip = true;

/* [Advanced] */
// Wall thickness (mm)
wall = 1.2; // [0.8:0.1:2.4]

// Floor thickness above the feet (mm)
floor_thickness = 2; // [1:0.5:3]

// Divider wall thickness (mm)
divider_thickness = 1.2; // [0.8:0.1:2]

// Foot fit clearance per side against the baseplate recess (mm)
fit_clearance = 0.25; // [0.1:0.05:0.4]

// Resolution
$fn = 40;

/* [Display] */
// What to show
_display_mode = "bin"; // ["bin", "divided", "seated", "stacked"]

// ---- Baseplate interface constants (from gridfinity_drawer.scad's
// baseplate_cell(): platform 41.5 r=1, recess 38.3 r=0.8, recess floor
// at z=0.8, platform top at z=2.4). use<> imports modules, not
// variables, so the numbers are replicated here. ----
_pitch = 42;            // Gridfinity grid pitch
_cell_inset = 0.25;     // body inset per side (41.5 per cell)
_recess = 38.3;         // baseplate recess opening
_recess_floor = 0.8;    // recess floor height inside the cell
_plate_h = 2.4;         // platform top height
_lip_h = 1.6;           // stacking lip height = recess depth (2.4 - 0.8)
_lip_wall = 1.6;        // lip wall width = (41.5 - 38.3) / 2

// ---- Derived dimensions ----
_foot_s = _recess - 2 * fit_clearance;        // foot square (37.8 default)
_foot_h = _lip_h - 0.2;                       // 0.2mm float above recess floor
_body_x = grid_units_x * _pitch - 2 * _cell_inset;
_body_y = grid_units_y * _pitch - 2 * _cell_inset;
_top = _foot_h + height_units * 7;            // wall-top height (z from foot bottom)
_x0 = _cell_inset + wall;                     // interior cavity extents
_y0 = _cell_inset + wall;
_inner_x = _body_x - 2 * wall;
_inner_y = _body_y - 2 * wall;
_floor_top = _foot_h + floor_thickness;
_lip_ov = max(0, _lip_wall - wall);           // lip inward overhang past the wall
_eps = 0.05;                                  // weld sink / display separation

// Seated-on-baseplate z for the bin origin: foot bottom 0.2mm above the
// recess floor puts the body underside on the platform top; +eps keeps
// display/test contact faces separated.
function bin_seat_z() = _recess_floor + 0.2 + _eps;

// Stacked-on-bin z offset: body underside on the lower bin's lip top,
// feet engaged inside its lip opening.
function bin_stack_z(hu = height_units) = hu * 7 + _lip_h + _eps;

// ---- Asserts ----
assert(wall >= 0.8, str("wall = ", wall, "mm is too thin to print (min 0.8)"));
assert(floor_thickness >= 1,
    str("floor_thickness = ", floor_thickness, "mm; need >= 1mm above the feet"));
assert(divider_thickness >= 0.8,
    str("divider_thickness = ", divider_thickness, "mm is too thin (min 0.8)"));
assert(divider_count_x == 0 ||
       (_inner_x - divider_count_x * divider_thickness) / (divider_count_x + 1) >= 6,
    str(divider_count_x, " x-dividers leave compartments under 6mm wide; ",
        "reduce divider_count_x or increase grid_units_x"));
assert(divider_count_y == 0 ||
       (_inner_y - divider_count_y * divider_thickness) / (divider_count_y + 1) >= 6,
    str(divider_count_y, " y-dividers leave compartments under 6mm wide; ",
        "reduce divider_count_y or increase grid_units_y"));
assert(scoop_radius == 0 ||
       scoop_radius <= min(_inner_y / 2, height_units * 7 - floor_thickness),
    str("scoop_radius = ", scoop_radius, "mm does not fit the interior"));
assert(!label_lip || _top - label_depth - 0.85 >= _floor_top + 3,
    str("label lip needs a taller bin: height_units*7 must exceed ",
        label_depth + 0.85 + floor_thickness + 3, "mm"));

// ---- Modules ----

// Rounded-corner square (size vector s, corner radius r), corner at origin
module _bin_rsq(s, r) {
    offset(r = r) offset(r = -r) square(s);
}

// One stepped foot, centered on a cell, welded 0.05 up into the floor
module _bin_foot() {
    translate([-_foot_s / 2, -_foot_s / 2, 0])
        linear_extrude(height = _foot_h + _eps)
            _bin_rsq([_foot_s, _foot_s], 0.8);
}

// The bin. Origin: grid corner at x=y=0 (cells centered on
// (i + 0.5) * 42), z=0 at the bottom of the feet.
module bin(gx = grid_units_x, gy = grid_units_y, hu = height_units,
           divx = divider_count_x, divy = divider_count_y) {
    bx = gx * _pitch - 2 * _cell_inset;
    by = gy * _pitch - 2 * _cell_inset;
    top = _foot_h + hu * 7;
    ix = bx - 2 * wall;   // interior spans
    iy = by - 2 * wall;
    // Straight cavity ends where the lip taper takes over. With a lip
    // but no taper (wall >= lip wall) it hands over to the opening
    // cutter just past the lip base; with no lip it overshoots the top.
    cav_top = !stacking_lip ? top + 0.1
            : _lip_ov > 0.05 ? top - _lip_ov + 0.01
            : top + 0.01;

    union() {
        // Shell: body + stacking lip slab, minus interior cavity
        difference() {
            union() {
                // Body
                translate([_cell_inset, _cell_inset, _foot_h])
                    linear_extrude(height = hu * 7)
                        _bin_rsq([bx, by], 1);
                // Stacking lip slab (opening cut below), sunk into the body
                if (stacking_lip)
                    translate([_cell_inset, _cell_inset, top - _eps])
                        linear_extrude(height = _lip_h + _eps)
                            _bin_rsq([bx, by], 1);
            }

            // Interior cavity, straight walls
            translate([_x0, _y0, _floor_top])
                linear_extrude(height = cav_top - _floor_top)
                    _bin_rsq([ix, iy], 0.8);

            // 45-degree-or-shallower taper from the cavity out to the lip
            // opening, so the lip's inward overhang is self-supporting
            if (stacking_lip && _lip_ov > 0.05)
                hull() {
                    translate([_x0, _y0, top - _lip_ov])
                        linear_extrude(height = 0.01)
                            _bin_rsq([ix, iy], 0.8);
                    translate([_cell_inset + _lip_wall, _cell_inset + _lip_wall, top])
                        linear_extrude(height = 0.01)
                            _bin_rsq([bx - 2 * _lip_wall, by - 2 * _lip_wall], 0.8);
                }

            // Lip opening: replicates the baseplate recess profile so the
            // feet of the bin above drop in (overshoots the lip top)
            if (stacking_lip)
                translate([_cell_inset + _lip_wall, _cell_inset + _lip_wall, top - 0.01])
                    linear_extrude(height = _lip_h + 0.11)
                        _bin_rsq([bx - 2 * _lip_wall, by - 2 * _lip_wall], 0.8);
        }

        // Feet: one per cell
        for (cx = [0 : gx - 1], cy = [0 : gy - 1])
            translate([(cx + 0.5) * _pitch, (cy + 0.5) * _pitch, 0])
                _bin_foot();

        // Front scoop fillet (welded 0.05 into floor and walls)
        if (scoop_radius > 0) {
            r = scoop_radius;
            difference() {
                translate([_x0 - _eps, _y0 - _eps, _floor_top - _eps])
                    cube([ix + 2 * _eps, r + _eps, r + _eps]);
                translate([_x0 - _eps - 0.1, _y0 + r, _floor_top + r])
                    rotate([0, 90, 0])
                        cylinder(r = r, h = ix + 2 * _eps + 0.2);
            }
        }

        // Label lip along the front top edge: flat top, 0.8mm tip,
        // 45-degree underside back to the wall (welded 0.05 in)
        if (label_lip)
            translate([_x0 - _eps, _y0, 0])
                rotate([90, 0, 90])
                    linear_extrude(height = ix + 2 * _eps)
                        polygon([
                            [-_eps, top],
                            [label_depth, top],
                            [label_depth, top - 0.8],
                            [-_eps, top - 0.8 - label_depth - _eps]
                        ]);

        // Dividers (welded 0.05 into floor and side walls)
        if (divx > 0) {
            cw = (ix - divx * divider_thickness) / (divx + 1);
            for (i = [1 : divx])
                translate([_x0 + i * cw + (i - 1) * divider_thickness,
                           _y0 - _eps, _floor_top - _eps])
                    cube([divider_thickness, iy + 2 * _eps,
                          top - _floor_top + _eps]);
        }
        if (divy > 0) {
            cd = (iy - divy * divider_thickness) / (divy + 1);
            for (i = [1 : divy])
                translate([_x0 - _eps,
                           _y0 + i * cd + (i - 1) * divider_thickness,
                           _floor_top - _eps])
                    cube([ix + 2 * _eps, divider_thickness,
                          top - _floor_top + _eps]);
        }
    }
}

// ---- Display ----

// Bin seated in a baseplate grid (cells from gridfinity_drawer.scad,
// welded onto a display plate so the mode is 2 bodies: plate + bin)
module show_seated() {
    translate([0, 0, 1.6]) {   // lift so the plate bottom sits on z=0
        color("SlateGray") union() {
            translate([-3, -3, -1.6])
                cube([grid_units_x * _pitch + 6, grid_units_y * _pitch + 6,
                      1.6 + _eps]);
            baseplate_grid(grid_units_x, grid_units_y);
        }
        color("SteelBlue")
            translate([0, 0, bin_seat_z()])
                bin(divx = 0, divy = 0);
    }
}

// Two bins stacked, the upper bin's feet engaged in the lower bin's lip
module show_stacked() {
    color("SteelBlue")
        bin(divx = 0, divy = 0);
    color("LightSteelBlue")
        translate([0, 0, bin_stack_z()])
            bin(divx = 0, divy = 0);
}

if (_display_mode == "bin") {
    bin(divx = 0, divy = 0);
} else if (_display_mode == "divided") {
    bin();
} else if (_display_mode == "seated") {
    show_seated();
} else if (_display_mode == "stacked") {
    show_stacked();
}
