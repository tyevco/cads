// @name Nesting Stars
// @description Concentric star-shaped cups that nest inside each other. A colorful stacking/nesting toy for toddlers.
// @tags toy, nesting, stars, stacking, toddler, educational
//
// A set of star-shaped cups in graduated sizes that nest
// inside one another. Each cup is a different size and can
// be stacked into a tower (inverted) or nested for storage.
//
// Stars have rounded points for child safety. The slight
// taper on the walls means they nest without getting stuck.
//
// Printing:
//   - Print each cup separately, open side up
//   - No supports needed
//   - Use different filament colors for each cup

/* [Cup Settings] */
// Number of nesting cups
cup_count = 5; // [3:1:8]

// Number of star points
star_points = 5; // [4:1:8]

// Largest cup outer diameter (point to point, mm)
max_diameter = 100; // [60:5:150]

// Smallest cup outer diameter (mm)
min_diameter = 35; // [20:5:60]

// Largest cup height (mm)
max_height = 40; // [25:5:60]

// Smallest cup height (mm)
min_height = 18; // [12:2:30]

// Wall thickness (mm)
wall_thickness = 2.0; // [1.2:0.2:3.0]

// Bottom thickness (mm)
bottom_thickness = 2.0; // [1.2:0.2:3.0]

/* [Star Shape] */
// Inner radius as fraction of outer (controls point depth)
inner_ratio = 0.55; // [0.4:0.05:0.75]

// Point rounding radius (mm) - for child safety
point_radius = 3; // [1:0.5:6]

// Star rotation per cup (degrees) - visual variety when nested
rotation_step = 0; // [0:5:30]

/* [Taper] */
// Draft angle for walls (degrees) - helps nesting
draft_angle = 4; // [2:1:8]

/* [Display] */
// What to show
_display_mode = "nested"; // ["nested", "tower", "row", "single"]

// Which single cup to show (0 = largest)
_single_index = 0; // [0:1:7]

// Explode distance for nested view (mm)
_explode = 0; // [0:2:30]

/* [Advanced] */
$fn = 60;

// Nesting clearance between cups (mm)
nest_clearance = 1.5;


// ---- Derived ----

function cup_od(i) =
    max_diameter - (max_diameter - min_diameter) * i / max(cup_count - 1, 1);

function cup_height(i) =
    max_height - (max_height - min_height) * i / max(cup_count - 1, 1);

// Nesting guarantee: each cup's top rim must fit inside its parent's
// cavity (which is narrower lower down because of the draft taper) with
// nest_clearance to spare.
_radius_step = (max_diameter - min_diameter) / 2 / max(cup_count - 1, 1);
_height_step = (max_height - min_height) / max(cup_count - 1, 1);
assert(_radius_step >= wall_thickness + nest_clearance
        + tan(draft_angle) * _height_step,
    str("Cups will not nest: per-cup radius step (", _radius_step,
        "mm) must be at least wall_thickness + nest_clearance + draft",
        " allowance (", wall_thickness + nest_clearance
        + tan(draft_angle) * _height_step,
        "mm). Increase the diameter spread or reduce cup_count."));


// ---- Modules ----

// 2D star shape centered at origin. The pre-offset radii are clamped
// positive so a large rounding radius can't flip the inner vertices
// through the origin (which would self-intersect the polygon).
module star_2d(outer_r, inner_r, points, rounding) {
    r_out = max(outer_r - rounding, 2);
    r_in = max(inner_r - rounding, 1);
    angle_step = 360 / points;

    offset(r=rounding)
        polygon([
            for (i = [0:points-1])
                each [
                    [r_out * cos(i * angle_step),
                     r_out * sin(i * angle_step)],
                    [r_in * cos(i * angle_step + angle_step/2),
                     r_in * sin(i * angle_step + angle_step/2)]
                ]
        ]);
}

// Single cup
module star_cup(index) {
    od = cup_od(index);
    h = cup_height(index);
    outer_r = od / 2;
    inner_r = outer_r * inner_ratio;

    // Taper: bottom is slightly smaller than top
    taper = tan(draft_angle) * h;
    bottom_scale = (od - taper * 2) / od;

    rot = index * rotation_step;

    difference() {
        // Outer shell
        rotate([0, 0, rot])
            linear_extrude(height=h, scale=1/bottom_scale)
                scale([bottom_scale, bottom_scale])
                    star_2d(outer_r, inner_r, star_points, point_radius);

        // Interior cavity
        rotate([0, 0, rot])
            translate([0, 0, bottom_thickness])
                linear_extrude(height=h, scale=1/bottom_scale)
                    scale([bottom_scale, bottom_scale])
                        star_2d(
                            outer_r - wall_thickness,
                            inner_r - wall_thickness,
                            star_points,
                            max(point_radius - wall_thickness/2, 0.5)
                        );
    }
}


// ---- Display ----

_cup_colors = ["Tomato", "Gold", "LimeGreen", "DodgerBlue",
               "BlueViolet", "DeepPink", "Orange", "Teal"];

// Physically nested, each cup resting on its parent's floor
function nested_z(i) = i * bottom_thickness;

// Tower: cumulative height of the inverted cups below
function tower_z(i) = i <= 0 ? 0 : tower_z(i - 1) + cup_height(i - 1);

// Row: cumulative spacing from actual neighbor radii
function row_x(i) = i <= 0 ? 0 : row_x(i - 1) + cup_od(i - 1)/2 + cup_od(i)/2 + 8;

module show_nested() {
    for (i = [0:cup_count-1]) {
        color(_cup_colors[i % len(_cup_colors)])
            translate([0, 0, nested_z(i) + i * _explode])
                star_cup(i);
    }
}

module show_tower() {
    // Stack cups inverted, largest at bottom
    for (i = [0:cup_count-1]) {
        color(_cup_colors[i % len(_cup_colors)])
            translate([0, 0, tower_z(i) + cup_height(i)])
                mirror([0, 0, 1])
                    star_cup(i);
    }
}

module show_row() {
    for (i = [0:cup_count-1]) {
        color(_cup_colors[i % len(_cup_colors)])
            translate([row_x(i), 0, 0])
                star_cup(i);
    }
}

// Main display logic
if (_display_mode == "nested") {
    show_nested();
} else if (_display_mode == "tower") {
    show_tower();
} else if (_display_mode == "row") {
    show_row();
} else if (_display_mode == "single") {
    idx = min(_single_index, cup_count - 1);
    color(_cup_colors[idx % len(_cup_colors)])
        star_cup(idx);
}
