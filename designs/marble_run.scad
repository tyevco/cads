// @name Modular Marble Run
// @description Interlocking marble-run tiles (straight, curve, funnel, drop) with a dovetail edge connector and a constant fall per tile.
// @tags marble, toy, modular, dovetail, tiles
//
// A tile system for building marble runs. Every tile is a square block
// (tile_size x tile_size) with an open U-channel (semicircular floor,
// vertical side walls, open top) sized for a marble of marble_d plus
// side_clearance per side.
//
// FALL GRADIENT
//   Channel floor at every ENTRY face:  entry_floor_h        (default 14mm)
//   Channel floor at every EXIT  face:  entry_floor_h - tile_fall (default 10mm)
//   => every tile drops the marble by tile_fall (default 4mm):
//      straight: linear slope   | curve: slope along the 90-degree arc
//      drop:     vertical ledge | funnel: bowl depth + 2mm center-to-exit slope
//   When tiles are chained, each tile sits tile_fall lower than the one
//   before (a staircase); the connector itself registers that step.
//
// CONNECTOR STANDARD (extend future tiles with these rules)
//   * MALE dovetail tab on every EXIT face, FEMALE slot in every ENTRY face.
//   * Plan-view trapezoid, wide at the tip: neck _tab_neck, tip _tab_tip
//     (defaults 7 / 11 mm), protruding _tab_depth = 6 mm, centered on the
//     channel centerline. The tab is a vertical prism from the tile base
//     (z = 0) up to the EXIT floor height minus 0.05 (top ~flush with the
//     mated tile's entry floor, so the tab completes the channel floor
//     across the joint).
//   * The female slot is the same trapezoid grown by conn_clear = 0.3 mm
//     per surface (neck/tip half-widths +0.3, depth +0.3). It starts
//     tile_fall below the ENTRY floor and is cut open all the way up
//     through the channel floor (an insertion chimney), so the mating tile
//     drops in vertically from above.
//   * Assembly: hold the new tile tile_fall higher, drop it so the
//     previous tile's tab slides down the chimney into the slot. The tab
//     bottom rests on the slot floor -> the tile_fall step is set by the
//     connector. The dovetail taper locks the pull-apart (channel)
//     direction; gravity holds the vertical direction.
//   * Slot tip width (_tab_tip + 2*conn_clear) is kept smaller than
//     marble_d so a marble cannot fall into an unmated entry chimney.
//
// PRINTING
//   Print the "set" mode (all four tiles on the plate). Everything rests
//   flat on the bed, tabs included; no supports needed. Funnel bowl wall
//   is ~48 degrees from horizontal (self-supporting).

/* [Marble + Channel] */
// Marble (ball) diameter (mm)
marble_d = 12.7; // [8:0.1:19]
// Side clearance between marble and channel wall, per side (mm)
side_clearance = 1.5; // [1:0.25:3]
// Channel floor height at every tile ENTRY face (mm above tile base)
entry_floor_h = 14; // [12:1:20]
// Drop from entry floor to exit floor across one tile (mm)
tile_fall = 4; // [2:1:6]
// Channel wall height above the entry floor (mm)
wall_above = 8; // [6:1:12]

/* [Tile + Connector] */
// Square tile footprint edge (mm)
tile_size = 50; // [40:5:70]
// Dovetail clearance per surface (mm) - tune for your printer
conn_clear = 0.3; // [0.15:0.05:0.5]

/* [Funnel] */
// Funnel bowl depth from rim to throat (mm)
funnel_depth = 16; // [12:1:22]

/* [Display] */
// What to show
_display_mode = "set"; // ["set", "straight", "curve", "funnel", "drop", "chained"]

/* [Advanced] */
$fn = 48;

// ---- Derived ----
_T = tile_size;
_chan_w = marble_d + 2 * side_clearance;   // channel width
_chan_r = _chan_w / 2;                     // groove radius
_exit_floor = entry_floor_h - tile_fall;   // exit-face floor height
_block_h = entry_floor_h + wall_above;     // straight/curve/drop block height

// Connector dimensions (see standard above)
_tab_tip = min(11, _chan_w - 2);   // tip width (wide end, at full depth)
_tab_neck = _tab_tip - 4;          // neck width (at the tile face)
_tab_depth = 6;                    // protrusion from the face
_tab_h = _exit_floor - 0.05;       // tab top ~flush with mated entry floor
_slot_bottom = tile_fall;          // slot floor height (entry_floor - tab rest)

// Funnel geometry
_fun_center_floor = _exit_floor + tile_fall / 2;  // floor under the throat
_fun_top = _fun_center_floor + funnel_depth;      // funnel block height
_fun_rim_d = _T - 6;                              // bowl rim diameter

// Chained-display epsilons: face gap + extra sink per joint so separate
// bodies never share coincident faces in the display mesh.
_eps = 0.05;
_step = tile_fall + _eps;   // vertical drop per chained tile

assert(_T - _chan_w >= 6,
    str("Channel (", _chan_w, ") leaves <3mm side walls in a ", _T, " tile"));
assert(tile_fall >= 2, "tile_fall < 2 leaves no floor under the dovetail slot");
assert(_exit_floor >= 6,
    str("Exit floor ", _exit_floor, " < 6mm: raise entry_floor_h or lower tile_fall"));
assert(_tab_neck >= 3.5, "Marble too small for the dovetail: connector neck < 3.5mm");
assert(_tab_tip + 2 * conn_clear < marble_d + 2,
    "Dovetail chimney nearly passes the marble: increase marble_d");
assert(_fun_rim_d > _chan_w + 8, "Funnel rim too small vs channel");

// ---- Channel cutter ----

// U profile in 2D: x = transverse, y = height above the local floor line.
module _uprofile() {
    translate([0, _chan_r]) circle(r=_chan_r);
    translate([-_chan_r, _chan_r]) square([_chan_w, 60]);
}

// Thin profile slice at plan position p, floor height fl, plan heading
// h_ang (degrees, 0 = +x travel). The slice is perpendicular to travel.
module _slice(p, h_ang, fl) {
    translate([p[0], p[1], fl])
        rotate([0, 0, h_ang - 90])
            rotate([90, 0, 0])
                linear_extrude(height=0.2, center=true)
                    _uprofile();
}

// Straight sloped channel from x=x0 (floor f0) to x=x1 (floor f1) at y=yc.
module _straight_cut(x0, f0, x1, f1, yc) {
    // Overshoot 0.6 past both ends, extrapolating the slope so the floor
    // heights at the faces stay exactly f0/f1.
    s = (f1 - f0) / (x1 - x0);
    hull() {
        _slice([x0 - 0.6, yc], 0, f0 - 0.6 * s);
        _slice([x1 + 0.6, yc], 0, f1 + 0.6 * s);
    }
}

// ---- Connector ----

// Male tab plan outline, +x outward from the face at x=0 (0.5 sunk weld).
module _tab_2d() {
    polygon([[-0.5, -_tab_neck/2], [_tab_depth, -_tab_tip/2],
             [_tab_depth, _tab_tip/2], [-0.5, _tab_neck/2]]);
}

// Female slot plan outline, +x into the tile from the face at x=0.
// Grown by conn_clear per surface; mouth extrapolated 0.5 outside.
module _slot_2d() {
    n = _tab_neck/2 + conn_clear;
    t = _tab_tip/2 + conn_clear;
    d = _tab_depth + conn_clear;
    m = n - (t - n) / d * 0.5; // extrapolated half-width at x=-0.5
    polygon([[-0.5, -m], [d, -t], [d, t], [-0.5, m]]);
}

// Male tab: place at the exit point, h_ang = exit heading.
module connector_tab(p, h_ang) {
    translate([p[0], p[1], 0])
        rotate([0, 0, h_ang])
            linear_extrude(height=_tab_h)
                _tab_2d();
}

// Female slot + insertion chimney cutter: place at entry point/heading.
module connector_slot_cut(p, h_ang) {
    translate([p[0], p[1], _slot_bottom])
        rotate([0, 0, h_ang])
            linear_extrude(height=60)
                _slot_2d();
}

// ---- Tiles (local frame: base on z=0, footprint [0,T]x[0,T]) ----

// Straight: entry x=0 y=T/2 heading +x; exit x=T y=T/2 heading +x.
module tile_straight() {
    difference() {
        cube([_T, _T, _block_h]);
        _straight_cut(0, entry_floor_h, _T, _exit_floor, _T/2);
        connector_slot_cut([0, _T/2], 0);
    }
    connector_tab([_T, _T/2], 0);
}

// Curve: entry x=0 y=T/2 heading +x; exit x=T/2 y=0 heading -y.
// Quarter-circle arc of radius T/2 centered on the (0,0) tile corner.
module tile_curve() {
    R = _T / 2;
    n = 12;
    difference() {
        cube([_T, _T, _block_h]);
        for (k = [0 : n - 1]) {
            a0 = 91.5 - k * 93 / n;
            a1 = 91.5 - (k + 1) * 93 / n;
            hull() {
                _slice([R*cos(a0), R*sin(a0)], a0 - 90, _curve_floor(a0));
                _slice([R*cos(a1), R*sin(a1)], a1 - 90, _curve_floor(a1));
            }
        }
        connector_slot_cut([0, _T/2], 0);
    }
    connector_tab([_T/2, 0], -90);
}
function _curve_floor(a) = entry_floor_h - tile_fall * (90 - a) / 90;

// Drop: entry x=0 heading +x; flat shelf at entry height, vertical ledge
// at 0.55*T, flat shelf at exit height; exit x=T heading +x.
module tile_drop() {
    sx = 0.55 * _T;
    difference() {
        cube([_T, _T, _block_h]);
        hull() { _slice([-0.6, _T/2], 0, entry_floor_h);
                 _slice([sx,   _T/2], 0, entry_floor_h); }
        hull() { _slice([sx,      _T/2], 0, _exit_floor);
                 _slice([_T + 0.6, _T/2], 0, _exit_floor); }
        connector_slot_cut([0, _T/2], 0);
    }
    connector_tab([_T, _T/2], 0);
}

// Funnel: run starter. Cone bowl from the top rim down to a channel-width
// throat over the tile center; channel from center to exit x=T heading +x.
// No entry connector; male tab on the exit only.
module tile_funnel() {
    difference() {
        cube([_T, _T, _fun_top]);
        translate([_T/2, _T/2, _fun_center_floor])
            cylinder(d1=_chan_w, d2=_fun_rim_d, h=funnel_depth + 0.6);
        _straight_cut(_T/2 - 2,
                      _fun_center_floor
                          + 2 * (_fun_center_floor - _exit_floor) / (_T/2),
                      _T, _exit_floor, _T/2);
    }
    connector_tab([_T, _T/2], 0);
}

// ---- Chain math (exposed for the verification harness) ----

// Mating offset from a tile to the next tile chained straight off its
// +x exit: face gap _eps, drop _step.
function mr_mate_offset() = [_T + _eps, 0, -_step];

// Chained demo: funnel -> straight -> curve -> drop (drop rotated -90,
// heading -y after the curve). Returns [tx, ty, tz, rotz] for tile i.
function mr_chain_xform(i) =
    i == 0 ? [_chain_lift(0), 0, 3 * _step, 0] :
    i == 1 ? [_T + _eps, 0, 2 * _step, 0] :
    i == 2 ? [2 * (_T + _eps), 0, _step, 0] :
             [2 * (_T + _eps) + 0, -_eps, 0, -90];
function _chain_lift(i) = 0;

module mr_chained_tile(i) {
    x = mr_chain_xform(i);
    translate([x[0], x[1], x[2]]) rotate([0, 0, x[3]]) {
        if (i == 0) tile_funnel();
        else if (i == 1) tile_straight();
        else if (i == 2) tile_curve();
        else tile_drop();
    }
}

// Marble probe: center of a marble resting in the channel of tile `kind`
// at parameter t in [0,1] along the run, +0.15 float. Local tile frame.
function mr_probe(kind, t) =
    kind == "straight" ?
        [t * _T, _T/2,
         entry_floor_h - tile_fall * t + marble_d/2 + 0.15] :
    kind == "curve" ?
        [_T/2 * cos(90 - 90*t), _T/2 * sin(90 - 90*t),
         entry_floor_h - tile_fall * t + marble_d/2 + 0.15] :
    kind == "drop" ?
        [t * _T, _T/2,
         (t < 0.55 ? entry_floor_h : _exit_floor) + marble_d/2 + 0.15] :
    // funnel: t=0 hovering in the bowl throat, then along the channel
    kind == "funnel" ?
        (t == 0 ? [_T/2, _T/2, _fun_center_floor + marble_d/2 + 0.15]
                : [_T/2 + t * _T/2, _T/2,
                   _fun_center_floor
                   + (_exit_floor - _fun_center_floor) * t
                   + marble_d/2 + 0.15]) :
    undef;

// ---- Display ----

module show_set() {
    g = 8;
    color("SteelBlue")   tile_straight();
    color("DarkOrange")  translate([_T + g, 0, 0]) tile_curve();
    color("MediumSeaGreen") translate([0, _T + g, 0]) tile_drop();
    color("IndianRed")   translate([_T + g, _T + g, 0]) tile_funnel();
}

module show_chained() {
    cols = ["IndianRed", "SteelBlue", "DarkOrange", "MediumSeaGreen"];
    for (i = [0:3]) color(cols[i]) mr_chained_tile(i);
}

if (_display_mode == "set") show_set();
else if (_display_mode == "straight") tile_straight();
else if (_display_mode == "curve") tile_curve();
else if (_display_mode == "funnel") tile_funnel();
else if (_display_mode == "drop") tile_drop();
else if (_display_mode == "chained") show_chained();
