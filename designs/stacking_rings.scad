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
//   - Print the cap flat-face down; it press-fits onto the stud on
//     top of the post AFTER the rings are loaded, so it can actually
//     retain them (it is wider than the upper rings' holes)
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

// Stud/socket press-fit interference (mm)
cap_fit_interference = 0.2;

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

// Effective post height: stack all rings plus gaps plus headroom
_post_h = (post_height > 0) ? post_height :
    ring_count * ring_height + (ring_count - 1) * ring_gap + cap_height + 5;

// Cap press-fit stud on top of the post
_stud_d = post_dia_top * 0.5;
_stud_len = min(cap_height - 2, 6);

// The post must taper inward going up, or rings sized at their resting
// height would jam lower down
assert(post_dia_top <= post_dia_bottom,
    "post_dia_top must not exceed post_dia_bottom");

// Ring diameters, linearly interpolated
function ring_od(i) =
    max_ring_od - (max_ring_od - min_ring_od) * i / max(ring_count - 1, 1);

// Post diameter at a given height
function post_dia_at(z) =
    post_dia_bottom + (post_dia_top - post_dia_bottom) * min(z, _post_h) / _post_h;

// Ring inner diameter needs to clear the post at its stacking height
function ring_id(i) =
    post_dia_at(i * (ring_height + ring_gap)) + post_clearance * 2 + ring_tube_dia * 0.2;

// Actual ring height (the tube radius is clamped by the annulus width,
// so upper rings can be shorter than ring_height)
function ring_h(i) =
    2 * min((ring_od(i) - ring_id(i)) / 4, ring_height / 2);

// Resting height of ring i: cumulative sum of the actual heights below it
function stack_z(i) =
    i <= 0 ? 0 : stack_z(i - 1) + ring_h(i - 1) + ring_gap;


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

    // Press-fit stud for the separate cap piece
    translate([0, 0, _post_h])
        cylinder(d=_stud_d, h=_stud_len);
}

// Separate top cap: press-fits onto the post stud after the rings are
// loaded. Printed flat-face down.
module cap_piece() {
    difference() {
        intersection() {
            sphere(d=cap_diameter);
            cylinder(d=cap_diameter + 1, h=cap_height);
        }
        // Press-fit socket (undersized by the interference)
        translate([0, 0, -0.1])
            cylinder(d=_stud_d - cap_fit_interference, h=_stud_len + 0.1);
    }
}

// Ring: torus resting tangent on z=0, plus a thin disc that gives the
// first layer a flat adhesion band
module ring_v2(index) {
    od = ring_od(index);
    id = ring_id(index);
    assert(od - id >= 2,
        str("ring ", index, " annulus too thin: od=", od, " id=", id,
            " - reduce post diameter or increase ring diameters"));
    mid_r = (od/2 + id/2) / 2;
    tube_r = (od/2 - id/2) / 2;
    actual_tube_r = min(tube_r, ring_height/2);

    rotate_extrude()
        translate([mid_r, actual_tube_r, 0])
            circle(r=actual_tube_r);

    // Flat bottom disc
    difference() {
        cylinder(r=mid_r + actual_tube_r, h=0.6);
        translate([0, 0, -0.1])
            cylinder(r=mid_r - actual_tube_r, h=0.8);
    }
}


// ---- Ring colors ----

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

    // Rings stacked on post (largest at bottom), resting on each other
    for (i = [0:ring_count-1]) {
        color(_ring_colors[i % len(_ring_colors)])
            translate([0, 0, base_height + stack_z(i) + i * _explode])
                ring_v2(i);
    }

    // Cap pressed onto the post stud
    color("BurlyWood")
        translate([0, 0, base_height + _post_h])
            cap_piece();
}

module show_print_layout() {
    // Base + post
    color("BurlyWood") {
        base();
        translate([0, 0, base_height])
            post();
    }

    // Rings laid out in a row, clear of the base
    ring_row_x = base_diameter/2 + max_ring_od/2 + 10;
    for (i = [0:ring_count-1]) {
        color(_ring_colors[i % len(_ring_colors)])
            translate([ring_row_x + i * (max_ring_od + 5), 0, 0])
                ring_v2(i);
    }

    // Cap, flat-face down
    color("BurlyWood")
        translate([0, -(base_diameter/2 + cap_diameter/2 + 10), 0])
            cap_piece();
}

// Main display logic
if (_display_mode == "assembled") {
    show_assembled();
} else if (_display_mode == "print_layout") {
    show_print_layout();
} else if (_display_mode == "base") {
    // The non-ring parts: base+post plus the separate cap
    base();
    translate([0, 0, base_height]) post();
    translate([base_diameter/2 + cap_diameter/2 + 10, 0, 0]) cap_piece();
} else if (_display_mode == "rings") {
    for (i = [0:ring_count-1]) {
        color(_ring_colors[i % len(_ring_colors)])
            translate([i * (max_ring_od + 5), 0, 0])
                ring_v2(i);
    }
}
