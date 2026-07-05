// @name Cable Clips
// @description Parametric C-shaped cable clips sized from the cable diameter, with an optional screw tab and a desk-edge hook variant.
// @tags cable, clip, organizer, desk, snap-fit
//
// A C-profile ring whose opening is derived from the cable it holds:
// the seat bore is cable_d + fit_clearance (cable slides/rotates
// freely) while the mouth gap is cable_d * gap_ratio (default 0.75) -
// smaller than the cable - so the cable pushes in past the rounded
// lips and is retained. Retention interference = cable_d * (1 -
// gap_ratio) at the mouth; the arms flex to admit the cable.
//
// Variants:
//   - "clip": one clip, optionally with a screw-mount tab (hole has a
//     45-degree teardrop roof so it prints cleanly on its side).
//   - "edge_hook": the same clip welded to a push-on desk-edge hook
//     (a C-channel sized to desk_t with a small grip nub); cables run
//     vertically past the desk edge.
//   - "set": a row of clips for a few common cable sizes
//     (3 / 5 / 8 mm - headphone, USB, mains) spaced by their actual
//     widths.
//
// Print as laid out: every part is an extrusion standing on its flat
// face - vertical walls, no supports.

/* [Clip] */
// Cable diameter the clip is rated for (mm)
cable_d = 6; // [2:0.5:12]
// Mouth gap as a fraction of the cable diameter (smaller = stronger grip)
gap_ratio = 0.75; // [0.5:0.05:0.9]
// Clip wall thickness (mm)
clip_wall = 2; // [1.2:0.2:3]
// Clip depth along the cable (mm)
clip_h = 10; // [6:1:25]
// Diametral clearance of the cable seat (mm)
fit_clearance = 0.3; // [0.15:0.05:0.5]

/* [Screw tab] */
// Add a screw-mount tab to the clip
screw_tab = true;
// Screw hole diameter (mm)
screw_d = 3.5; // [2.5:0.5:5]

/* [Desk edge hook] */
// Desktop thickness the edge hook pushes onto (mm)
desk_t = 19; // [10:1:40]
// How far the hook reaches over the desktop (mm)
hook_reach = 20; // [12:2:40]

/* [Display] */
// What to show
_display_mode = "set"; // ["set", "clip", "edge_hook"]

/* [Advanced] */
// Resolution
$fn = 64;

// Cable sizes used by the "set" mode (mm)
_set_sizes = [3, 5, 8];
// Spacing between parts in the set layout (mm)
_set_gap = 4;
// Desk hook plate thickness
_hp = 3;
// Desk channel fit allowance
_desk_fit = 0.3;

// ---- Derived / checks -------------------------------------------------
function seat_r(d) = (d + fit_clearance) / 2;
function outer_r(d) = seat_r(d) + clip_wall;
function mouth_gap(d) = d * gap_ratio;

_tab_len = screw_d + 8;              // tab length beyond the clip OD

// teardrop apex reaches (r * sqrt(2)) above the hole center; keep 0.8
// of tab material above it and a matching margin below the circle
assert(!screw_tab || clip_h / 2 >= (screw_d / 2 + 0.1) * sqrt(2) + 0.8,
    str("clip_h ", clip_h, " too short for a ", screw_d,
        " mm screw hole - increase clip_h or reduce screw_d"));

// ---- 2D profiles -------------------------------------------------------

// C-shaped clip cross-section, cable axis at the origin, mouth toward +y.
// The mouth is cut (gap + wall) wide, then lip circles of d=wall centered
// on the cut faces at mid-wall radius take back wall/2 per side, leaving
// exactly mouth_gap(d) between the rounded lips.
module clip_profile(d) {
    sr = seat_r(d);
    or_ = outer_r(d);
    mid = sr + clip_wall / 2;
    hw = (mouth_gap(d) + clip_wall) / 2;   // mouth cut half-width
    ym = sqrt(mid * mid - hw * hw);        // lip circle center height
    union() {
        difference() {
            circle(r = or_);
            circle(r = sr);
            translate([-hw, 0]) square([2 * hw, or_ + 1]);
        }
        for (s = [-1, 1])
            translate([s * hw, ym]) circle(d = clip_wall);
    }
}

// Screw tab outline: a stadium plate along the wall plane y = -outer_r
module tab_profile(d) {
    or_ = outer_r(d);
    hull() {
        translate([0, -or_ + clip_wall / 2]) circle(d = clip_wall);
        translate([or_ + _tab_len - clip_wall / 2, -or_ + clip_wall / 2])
            circle(d = clip_wall);
    }
}

// Teardrop hole section (radius r, 45-degree roof toward +y) - keeps a
// horizontal hole printable without supports
module teardrop_2d(r) {
    union() {
        circle(r = r);
        polygon([[-r / sqrt(2), r / sqrt(2)],
                 [r / sqrt(2), r / sqrt(2)],
                 [0, r * sqrt(2)]]);
    }
}

// ---- Parts --------------------------------------------------------------

// One clip, extruded upright (prints as-is), cable axis = z
module cable_clip(d, with_tab = false) {
    or_ = outer_r(d);
    hx = or_ + _tab_len / 2;             // screw hole center
    difference() {
        linear_extrude(height = clip_h) {
            clip_profile(d);
            if (with_tab) tab_profile(d);
        }
        if (with_tab)
            translate([hx, -or_ + clip_wall + 0.3, clip_h / 2])
                rotate([90, 0, 0])
                    linear_extrude(height = clip_wall + 0.6)
                        teardrop_2d(screw_d / 2 + 0.1);
    }
}

// Desk-edge hook with the clip welded to its outer face.
// Desk corner at the origin: desktop occupies x <= 0, y in [-desk_t, 0].
module edge_hook(d) {
    or_ = outer_r(d);
    ch = desk_t + _desk_fit;             // channel opening
    y_bot = -ch - _hp;                   // bottom lip plate
    lip = min(hook_reach * 0.7, 14);
    linear_extrude(height = clip_h) union() {
        // top arm over the desktop
        translate([-hook_reach, 0]) square([hook_reach + _hp, _hp]);
        // front plate down the desk edge
        translate([0, y_bot]) square([_hp, ch + 2 * _hp]);
        // bottom lip under the desktop, with a grip nub (0.4 proud)
        translate([-lip, y_bot]) square([lip + _hp, _hp]);
        translate([-lip + 2, -ch - 0.6]) circle(d = 2);
        // the clip, mouth facing +x (away from the desk), welded 0.4
        // into the front plate
        translate([_hp + or_ - 0.4, (y_bot + _hp) / 2])
            rotate(-90) clip_profile(d);
    }
}

// Cumulative x-position of clip i in the set row (parts advance by
// their real widths: left radius + previous part's right extent + gap)
function set_right(i) =
    outer_r(_set_sizes[i]) + (screw_tab ? _tab_len : 0);
function set_x(i) =
    i <= 0 ? outer_r(_set_sizes[0])
           : set_x(i - 1) + set_right(i - 1) + _set_gap
             + outer_r(_set_sizes[i]);

// ---- Display -------------------------------------------------------------

if (_display_mode == "set") {
    for (i = [0 : len(_set_sizes) - 1])
        translate([set_x(i), 0, 0])
            cable_clip(_set_sizes[i], screw_tab);
} else if (_display_mode == "clip") {
    cable_clip(cable_d, screw_tab);
} else if (_display_mode == "edge_hook") {
    edge_hook(cable_d);
}
