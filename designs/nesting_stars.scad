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


// ---- Modules ----

// 2D star shape centered at origin
module star_2d(outer_r, inner_r, points, rounding) {
    r_out = outer_r - rounding;
    r_in = inner_r - rounding;
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

module show_nested() {
    for (i = [0:cup_count-1]) {
        color(_cup_colors[i % len(_cup_colors)])
            translate([0, 0, i * _explode])
                star_cup(i);
    }
}

module show_tower() {
    // Stack cups inverted, largest at bottom
    z = 0;
    for (i = [0:cup_count-1]) {
        h = cup_height(i);
        stack_z = (i == 0) ? 0 :
            let(prev_heights = [for (j = [0:i-1]) cup_height(j)])
            let(sum = [for (j = [0:len(prev_heights)-1])
                        prev_heights[j]])
            // Manual sum
            sum[0] + (len(sum) > 1 ? sum[1] : 0) +
            (len(sum) > 2 ? sum[2] : 0) +
            (len(sum) > 3 ? sum[3] : 0) +
            (len(sum) > 4 ? sum[4] : 0) +
            (len(sum) > 5 ? sum[5] : 0) +
            (len(sum) > 6 ? sum[6] : 0) +
            (len(sum) > 7 ? sum[7] : 0);

        color(_cup_colors[i % len(_cup_colors)])
            translate([0, 0, stack_z + h])
                mirror([0, 0, 1])
                    star_cup(i);
    }
}

module show_row() {
    for (i = [0:cup_count-1]) {
        x_offset = (i == 0) ? 0 :
            max_diameter * 0.6 * i;
        color(_cup_colors[i % len(_cup_colors)])
            translate([x_offset, 0, 0])
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
