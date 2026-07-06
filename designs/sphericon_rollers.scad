// @name Sphericon Rollers
// @description A pair of developable desk rollers: the classic sphericon (a split-and-twisted bicone that meanders in a straight-ish wobble) and an oloid (the convex hull of two perpendicular circles).
// @tags toy, fidget, sphericon, oloid, roller, mathematical, desk
//
// Two single-piece rolling solids whose entire surface touches the
// table as they roll (developable rollers):
//
// SPHERICON - exact construction:
//   1. Revolve a right isosceles triangle [[0,-R],[R,0],[0,R]] about
//      the z axis (rotate_extrude) -> a bicone with 90-degree apices
//      (equator radius R = half-height R). Its axial cross-section is
//      a square of diagonal 2R standing on a corner.
//   2. Split the bicone in half along a plane containing the axis
//      (the y=0 plane). The cut face is exactly that square.
//   3. Rotate one half by 90 degrees about the cut face's normal-space
//      diagonal (rotate([0,90,0]) maps the square's corners
//      (R,0,0)->(0,0,-R)->(-R,0,0)->(0,0,R) onto each other).
//   4. Rejoin. The two halves are welded with a 0.04mm overlap slab at
//      the seam so the union is a single manifold body rather than two
//      face-coincident shells.
//   Rolling property: each cone's slant surface makes 45 degrees with
//   its axis, so resting on any surface line the center sits at height
//   R*sin(45) = R/sqrt(2) - constant while it rolls (verified by
//   mesh centroid measurement in the repo's audit harness).
//
// OLOID - exact construction: convex hull of two circles of radius r
//   in perpendicular planes, each passing through the other's center
//   (centers r apart). Modeled as hull() of two 0.02mm-thin discs -
//   the hull of a disc equals the hull of its boundary circle, so this
//   is the standard oloid definition verbatim. It rolls developably
//   with a rhythmic wobble (its center height is NOT constant - that
//   is the charm; only the sphericon has the constant-height property).
//
// Print orientation (both modes pose the parts this way, min z = 0):
//   Each roller rests on its rolling contact - a straight line segment
//   (sphericon: a cone slant line; oloid: the symmetric two-point
//   pose with the center of mass directly above the midpoint). A flat
//   micro-facet (facet_depth, set 0 to disable) is shaved off at z=0
//   to turn the line contact into a real adhesion patch, exactly like
//   printing a lying cylinder with a small flat. The first ~1mm above
//   the facet locally exceeds 45 degrees but each layer overhangs the
//   last by well under a perimeter width (large radius of curvature,
//   developable surface) - self-supporting; use a brim, no supports.

/* [Sphericon] */
// Bicone equator radius (mm) - the sphericon spans 2x this
sphericon_radius = 25; // [15:1:35]

/* [Oloid] */
// Generating circle radius (mm) - the oloid is 3x this long
oloid_radius = 20; // [12:1:30]

/* [Printing] */
// Depth of the flat resting facet for bed adhesion (mm, 0 = knife-edge)
facet_depth = 0.6; // [0:0.2:2]

/* [Display] */
// What to show
_display_mode = "set"; // ["set", "sphericon", "oloid"]

/* [Advanced] */
$fn = 96;

// ---- Asserts ----

assert(facet_depth < sphericon_radius / 6 && facet_depth < oloid_radius / 6,
    str("facet_depth ", facet_depth, " would truncate the rollers - keep it under ",
        min(sphericon_radius, oloid_radius) / 6));

// ---- Accessors (used by the verification harness) ----

function sphericon_R() = sphericon_radius;
function oloid_R() = oloid_radius;
// Constant rolling height of the sphericon's center
function sphericon_rest_h() = sphericon_radius / sqrt(2);
// Height of the oloid center in the symmetric two-point rest pose
function oloid_rest_h() = oloid_radius / sqrt(2);
// Analytic bicone volume (= sphericon volume: the halves are rearranged)
function sphericon_volume() = 2 / 3 * PI * pow(sphericon_radius, 3);

// ---- Construction ----

// Bicone: right isosceles triangle revolved about z.
// Apices (0,0,+/-R), equator radius R at z=0.
module bicone(R) {
    rotate_extrude()
        polygon([[0, -R], [R, 0], [0, R]]);
}

// Sphericon in its construction frame (centered on the origin):
// half A = y<=0 half of the bicone (axis z), half B = y>=0 half
// rotated 90 degrees about y. Each half is cut 0.04mm past the y=0
// plane so they overlap and weld into one manifold body.
module sphericon_raw(R) {
    w = 0.04;
    big = 4 * R;
    union() {
        intersection() {
            bicone(R);
            translate([0, -big / 2 + w, 0]) cube(big, center = true);
        }
        rotate([0, 90, 0]) intersection() {
            bicone(R);
            translate([0, big / 2 - w, 0]) cube(big, center = true);
        }
    }
}

// Oloid in its construction frame: hull of a radius-r circle in the
// y=0 plane centered (-r/2,0,0) and one in the z=0 plane centered
// (+r/2,0,0). Perpendicular planes, centers r apart: each circle
// passes through the other's center.
module oloid_raw(r) {
    hull() {
        translate([-r / 2, 0, 0])
            rotate([90, 0, 0]) cylinder(h = 0.02, r = r, center = true);
        translate([r / 2, 0, 0])
            cylinder(h = 0.02, r = r, center = true);
    }
}

// Pose a child resting on z=0 given its centered rest height, shaving
// the facet off below z=0 (guarded: no degenerate cut when depth = 0)
module rest_on_plate(rest_h, depth) {
    if (depth > 0) {
        difference() {
            translate([0, 0, rest_h - depth]) children();
            translate([0, 0, -50]) cube([500, 500, 100], center = true);
        }
    } else {
        translate([0, 0, rest_h]) children();
    }
}

// Sphericon posed on its resting line: rotate([45,0,0]) lays the
// half-A lower-cone slant line (apex (0,0,-R) to equator (0,-R,0),
// mid-azimuth of the un-twisted half) horizontal along y at
// z = -R/sqrt(2); the line contact becomes the facet.
module sphericon_posed() {
    rest_on_plate(sphericon_rest_h(), facet_depth)
        rotate([45, 0, 0]) sphericon_raw(sphericon_radius);
}

// Oloid posed in its symmetric rest: rotate([45,0,0]) puts the
// oloid's 2-fold symmetry axis (x=0, y=z) vertical, leaving two
// diagonal lowest points at z = -r/sqrt(2) - circle A's bottom
// (-r/2, 0, -r) and circle B's point (r/2, -r, 0) - with the center
// of mass (the origin, by symmetry) directly above their midpoint.
module oloid_posed() {
    rest_on_plate(oloid_rest_h(), facet_depth)
        rotate([45, 0, 0]) oloid_raw(oloid_radius);
}

// ---- Display ----

// Set layout: x extents are +/-sphericon_radius and +/-1.5*oloid_radius
// (the posing rotations are about x, so x extents are unchanged)
_oloid_x = sphericon_radius + 1.5 * oloid_radius + 10;

if (_display_mode == "set") {
    color("Gold") sphericon_posed();
    color("DodgerBlue") translate([_oloid_x, 0, 0]) oloid_posed();
} else if (_display_mode == "sphericon") {
    color("Gold") sphericon_posed();
} else if (_display_mode == "oloid") {
    color("DodgerBlue") oloid_posed();
}
