// @name Stacking Rings Toy
// @description Classic toddler stacking rings toy with a tapered post and graduated rings. Prints without supports.
// @tags toy, stacking, rings, toddler, educational
//
// A classic stacking ring toy with a conical post on a round base.
// Rings graduate from large (bottom) to small (top), each a
// different thickness. The post tapers so rings slide on easily.
//
// Printing:
//   - Print the base+post as one piece
//   - Print each ring flat (they have a flat bottom)
//   - No supports needed

/* [Ring Settings] */
// Number of rings
ring_count = 5; // [3:1:8]

// Diameter of the largest (bottom) ring (mm)
max_ring_od = 60; // [40:5:100]

// Diameter of the smallest (top) ring (mm)
min_ring_od = 30; // [20:5:60]

// Ring height (mm)
ring_height = 12; // [8:2:20]

// Ring tube diameter (cross section thickness, mm)
ring_tube_dia = 12; // [8:1:20]

// Gap between rings when stacked (mm)
ring_gap = 1.0;

/* [Post Settings] */
// Post height above base (mm) - auto-calculated if 0
post_height = 0;

// Post bottom diameter (mm)
post_dia_bottom = 18; // [10:1:30]

// Post top diameter (mm)
post_dia_top = 10; // [6:1:20]

// Top cap diameter (prevents rings flying off, mm)
cap_diameter = 20; // [12:2:30]

// Top cap height (mm)
cap_height = 8; // [4:1:15]

/* [Base Settings] */
// Base diameter (mm)
base_diameter = 80; // [50:5:120]

// Base height (mm)
base_height = 8; // [4:1:15]

// Base edge fillet radius (mm)
base_fillet = 3;

/* [Display] */
// What to show
_display_mode = "assembled"; // ["assembled", "print_layout", "base", "rings"]

// Explode distance for assembled view (mm)
_explode = 0; // [0:2:50]

/* [Advanced] */
$fn = 60;

// Clearance between ring inner hole and post (mm)
post_clearance = 1.0;


// ---- Derived ----

// Effective post height: stack all rings plus gaps plus cap
_post_h = (post_height > 0) ? post_height :
    ring_count * ring_height + (ring_count - 1) * ring_gap + cap_height + 5;

// Ring diameters, linearly interpolated
function ring_od(i) =
    max_ring_od - (max_ring_od - min_ring_od) * i / max(ring_count - 1, 1);

// Post diameter at a given height
function post_dia_at(z) =
    post_dia_bottom + (post_dia_top - post_dia_bottom) * z / _post_h;

// Ring inner diameter needs to clear the post at its stacking height
function ring_id(i) =
    post_dia_at(i * (ring_height + ring_gap)) + post_clearance * 2 + ring_tube_dia * 0.2;


// ---- Modules ----

module base() {
    // Rounded base disc
    hull() {
        translate([0, 0, base_fillet])
            cylinder(d=base_diameter, h=base_height - base_fillet);
        translate([0, 0, base_fillet])
            rotate_extrude()
                translate([base_diameter/2 - base_fillet, 0])
                    circle(r=base_fillet);
    }
}

module post() {
    // Tapered post
    cylinder(d1=post_dia_bottom, d2=post_dia_top, h=_post_h);

    // Rounded top cap
    translate([0, 0, _post_h]) {
        // Sphere cap
        intersection() {
            sphere(d=cap_diameter);
            cylinder(d=cap_diameter + 1, h=cap_height);
        }
    }
}

module ring(index) {
    od = ring_od(index);
    id = ring_id(index);

    // Torus-like ring with flat bottom for printing
    rotate_extrude() {
        translate([(od + id) / 4, 0]) {
            intersection() {
                circle(d=ring_tube_dia);
                // Flat bottom: cut off the bottom of the circle
                translate([-ring_tube_dia, 0])
                    square([ring_tube_dia * 2, ring_tube_dia]);
            }
            // Flat bottom bridge
            translate([-ring_tube_dia/2, -ring_tube_dia/2 + ring_height/2])
                square([ring_tube_dia, 0.01]);
        }
    }

    // Fill in the flat bottom
    difference() {
        cylinder(d=od, h=ring_height * 0.15);
        translate([0, 0, -0.1])
            cylinder(d=id, h=ring_height * 0.15 + 0.2);
    }
}

// Ring as a proper donut with flat bottom
module ring_v2(index) {
    od = ring_od(index);
    id = ring_id(index);
    mid_r = (od/2 + id/2) / 2;
    tube_r = (od/2 - id/2) / 2;
    actual_tube_r = min(tube_r, ring_height/2);

    // Torus with flat bottom
    rotate_extrude()
        translate([mid_r, actual_tube_r, 0])
            intersection() {
                circle(r=actual_tube_r);
                translate([-actual_tube_r - 1, -actual_tube_r])
                    square([actual_tube_r * 2 + 2, actual_tube_r * 2]);
            }

    // Flat bottom disc
    difference() {
        cylinder(r=mid_r + actual_tube_r, h=0.6);
        translate([0, 0, -0.1])
            cylinder(r=mid_r - actual_tube_r, h=0.8);
    }
}


// ---- Ring colors ----
function ring_color(i, n) =
    let(hue = i / n * 0.8)
    [
        cos(hue * 360) * 0.3 + 0.5,
        cos((hue - 0.33) * 360) * 0.3 + 0.5,
        cos((hue - 0.66) * 360) * 0.3 + 0.5
    ];

// Simple rainbow-ish palette
_ring_colors = ["Red", "OrangeRed", "Gold", "LimeGreen",
                "DodgerBlue", "BlueViolet", "DeepPink", "Teal"];

// ---- Display ----

module show_assembled() {
    // Base + post
    color("BurlyWood") {
        base();
        translate([0, 0, base_height])
            post();
    }

    // Rings stacked on post (largest at bottom)
    for (i = [0:ring_count-1]) {
        stack_z = base_height + i * (ring_height + ring_gap)
                  + i * _explode;
        color(_ring_colors[i % len(_ring_colors)])
            translate([0, 0, stack_z])
                ring_v2(i);
    }
}

module show_print_layout() {
    // Base + post
    color("BurlyWood") {
        base();
        translate([0, 0, base_height])
            post();
    }

    // Rings laid out in a row
    for (i = [0:ring_count-1]) {
        color(_ring_colors[i % len(_ring_colors)])
            translate([base_diameter/2 + 10 + i * (max_ring_od + 5), 0, 0])
                ring_v2(i);
    }
}

// Main display logic
if (_display_mode == "assembled") {
    show_assembled();
} else if (_display_mode == "print_layout") {
    show_print_layout();
} else if (_display_mode == "base") {
    base();
    translate([0, 0, base_height]) post();
} else if (_display_mode == "rings") {
    for (i = [0:ring_count-1]) {
        color(_ring_colors[i % len(_ring_colors)])
            translate([i * (max_ring_od + 5), 0, 0])
                ring_v2(i);
    }
}
