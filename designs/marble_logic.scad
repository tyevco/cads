// @name Marble Run Logic Tiles
// @description Flip-flop (toggle), manual switch and merge tiles that snap onto the modular marble run's dovetail tile system - chain k flip-flops to count marbles in binary to 2^k.
// @tags marble, toy, modular, logic, flip-flop, counter
//
// Logic tiles for the Modular Marble Run (designs/marble_run.scad).
// Same tile footprint (tile_size x tile_size), same open U-channel, and
// the SAME edge-connector standard, so these tiles mate directly with the
// existing straight/curve/funnel/drop tiles.
//
// TILES
//   flipflop - 1 entry (x=0 face), 2 exits (y=0 "R" and y=T "L" faces).
//     A rocker (separate snap-in part) pivots about a vertical printed pin
//     (pin d4.0 in a d4.7 bore = 0.35 mm clearance per side). The pin tip
//     carries a 45-degree barbed arrowhead that snaps through the bore
//     into an open counterbore chamber, making the rocker CAPTIVE.
//     Hard stops: a fixed post on the tile floor rides in an arc slot cut
//     through the rocker hub; the slot ends stop the swing at +/-23 deg
//     (the two stable states, resting at +/-21 deg).
//     Routing: the rocker vane blocks one branch mouth and deflects the
//     arriving marble into the other. Toggling: past the vane tip the
//     routed marble rolls over a low dome cam attached to the rocker,
//     offset outboard of the marble path; the contact normal pushes the
//     cam sideways, swinging the rocker to the opposite stop. Each marble
//     therefore exits on alternate sides - a binary "bit".
//   switch   - same tile + a rocker WITHOUT toggle cams: a manually set
//     router (flick the exposed vane); marbles always exit the set side,
//     and the deflection force presses the vane INTO its stop (stable).
//   merge    - two entries (x=0 and y=T faces) converge to one exit
//     (x=T face); pure channel geometry, no moving parts (marble OR).
//
// BINARY COUNTING (why the flip-flop is a counter bit)
//   Feed marbles into flip-flop FF0. Every 2nd marble leaves on FF0's
//   carry side; route that exit into FF1's entry, FF1's carry into FF2,
//   etc. After N marbles the rocker states of FFk-1..FF0 read N in
//   binary (state flips = arrivals mod 2), so k chained flip-flops count
//   to 2^k marbles before rolling over. Use merge tiles to recombine the
//   non-carry exits back into one stream. counter_demo shows FF0's carry
//   exit chained into FF1 (a 2-bit counter, counts to 4).
//
// CONNECTOR STANDARD (replicated 1:1 from marble_run.scad - see there)
//   MALE dovetail tab on every EXIT face (neck 7 / tip 11 / depth 6 mm at
//   default marble_d, prism z=0..exit_floor-0.05), FEMALE slot + vertical
//   insertion chimney in every ENTRY face, grown conn_clear per surface,
//   slot floor tile_fall below the entry floor. Entry floor 14 mm, exit
//   floor 10 mm: every route through a tile drops the marble tile_fall.
//   Asserts below verify the replicated dimensions match the documented
//   marble_run standard at the shared defaults.
//
// FALL PROFILE (flipflop/switch): entry ramp 14->12 into a round basin
//   (flat floor at 12, crossed on momentum like the funnel tile), then a
//   walled trough 12->10 to either exit face. Merge: main channel 14->10
//   linear; side channel 14->13 drop-in then 13->11.2 diagonal joining
//   the main channel, ->10 at the exit. Every entry->exit drop = 4 mm.
//
// PRINTING
//   "set" mode = print layout: 3 tiles + 2 rockers flat on the plate, no
//   supports (rockers print inverted, snap-pin up, barb chamfers 45 deg;
//   the toggle cams become <=3.5 mm domed undersides that bridge fine).
//   Assembly: drop the rocker into the basin, arc slot over the stop
//   post, and press until the barb snaps through the floor bore.

/* [Marble + Channel] */
// Marble (ball) diameter (mm) - rocker geometry is tuned for ~12.7
marble_d = 12.7; // [10:0.1:14]
// Side clearance between marble and channel wall, per side (mm)
side_clearance = 1.5; // [1:0.25:2]
// Channel floor height at every tile ENTRY face (mm above tile base)
entry_floor_h = 14; // [12:1:16]
// Drop from entry floor to exit floor across one tile (mm)
tile_fall = 4; // [2:1:6]
// Channel wall height above the entry floor (mm)
wall_above = 8; // [6:1:12]

/* [Tile + Connector] */
// Square tile footprint edge (mm) - must match your marble_run tiles
tile_size = 50; // [50:5:70]
// Dovetail clearance per surface (mm) - tune for your printer
conn_clear = 0.3; // [0.15:0.05:0.5]

/* [Rocker] */
// Pivot pin clearance per side (mm)
pin_clear = 0.35; // [0.25:0.05:0.5]

/* [Display] */
// What to show
_display_mode = "set"; // ["set", "flipflop", "switch", "merge", "counter_demo"]

/* [Advanced] */
$fn = 48;

// ---- Derived: channel + connector (formulas identical to marble_run) ----
_T = tile_size;
_chan_w = marble_d + 2 * side_clearance;   // channel width
_chan_r = _chan_w / 2;                     // groove radius
_exit_floor = entry_floor_h - tile_fall;   // exit-face floor height
_block_h = entry_floor_h + wall_above;     // tile block height

_tab_tip = min(11, _chan_w - 2);   // tip width (wide end, at full depth)
_tab_neck = _tab_tip - 4;          // neck width (at the tile face)
_tab_depth = 6;                    // protrusion from the face
_tab_h = _exit_floor - 0.05;       // tab top ~flush with mated entry floor
_slot_bottom = tile_fall;          // slot floor height

_eps = 0.05;
_step = tile_fall + _eps;          // vertical drop per chained tile

// ---- Derived: junction (flipflop/switch) geometry ----
_piv = [_T/2 + 10, _T/2];                    // rocker pivot (plan)
_basin_r = _T/2 - 7;                         // open junction basin radius
_bfl = entry_floor_h - tile_fall/2;          // basin floor height
_tr0 = _T/2 - 8;                             // trough start (dist from face)
_rk_bot = _bfl + 0.4;                        // rocker underside (floor gap)
_rk_top = _bfl + 9;                          // rocker top
_vane_len = 15;                              // vane reach upstream of pivot
_vane_w = 5;                                 // vane thickness
_disc_r = 7.2;                               // rocker hub disc radius
_pin_d = 4;                                  // pivot pin diameter
_bore_d = _pin_d + 2 * pin_clear;            // pivot bore in the floor
_barb_d = _pin_d + 1.4;                      // snap barb max diameter
_chamber_d = _barb_d + 1.1;                  // counterbore for the barb
_chamber_top = _bfl - 4;                     // barb chamber ceiling
_slot_r = 4.5;                               // stop-arc slot radius
_stop_pin_d = 3;                             // fixed stop post diameter
_stop_ang = 23;                              // hard-stop swing angle
_rest_ang = _stop_ang - 2;                   // resting state angle
_slot_half = _stop_ang + asin(_stop_pin_d/2 / _slot_r); // arc slot half-span
_cam_w = [_T/2 + 1.5, _T/2 - 7.8];           // cam A center at state "R"

function _ml_rot(v, a) = [v[0]*cos(a) - v[1]*sin(a),
                          v[0]*sin(a) + v[1]*cos(a)];
_cam_l = _ml_rot([_cam_w[0]-_piv[0], _cam_w[1]-_piv[1]], _rest_ang);

// ---- Asserts ----
assert(_T - _chan_w >= 6,
    str("Channel (", _chan_w, ") leaves <3mm side walls in a ", _T, " tile"));
assert(tile_fall >= 2, "tile_fall < 2 leaves no floor under the dovetail slot");
assert(_exit_floor >= 6,
    str("Exit floor ", _exit_floor, " < 6mm: raise entry_floor_h or lower tile_fall"));
assert(_tab_neck >= 3.5, "Marble too small for the dovetail: connector neck < 3.5mm");
assert(_tab_tip + 2 * conn_clear < marble_d + 2,
    "Dovetail chimney nearly passes the marble: increase marble_d");
// Connector must equal the marble_run standard at the shared defaults
assert(marble_d != 12.7
       || (abs(_tab_tip - 11) < 1e-9 && abs(_tab_neck - 7) < 1e-9
           && _tab_depth == 6 && _slot_bottom == tile_fall),
    "Connector deviates from the marble_run dovetail standard");
assert(marble_d >= 10 && marble_d <= 14,
    "Rocker/junction geometry is tuned for marble_d 10-14");
assert(_piv[0] + _disc_r <= _T/2 + _basin_r - 0.3,
    "Rocker hub does not clear the basin wall");
assert(_slot_r - _stop_pin_d/2 - _bore_d/2 >= 0.5,
    "Stop post too close to the pivot bore");
assert(_chamber_top >= 2, "No room for the snap-barb chamber under the basin");

// ---- Channel cutters (same technique as marble_run) ----
module _ml_uprofile() {
    translate([0, _chan_r]) circle(r=_chan_r);
    translate([-_chan_r, _chan_r]) square([_chan_w, 60]);
}

module _ml_slice(p, h_ang, fl) {
    translate([p[0], p[1], fl])
        rotate([0, 0, h_ang - 90])
            rotate([90, 0, 0])
                linear_extrude(height=0.2, center=true)
                    _ml_uprofile();
}

// Straight sloped channel between plan points p0 (floor f0) and p1 (f1),
// overshooting 0.6 past both ends along the extrapolated slope.
module _ml_seg(p0, f0, p1, f1) {
    L = norm([p1[0]-p0[0], p1[1]-p0[1]]);
    u = [(p1[0]-p0[0])/L, (p1[1]-p0[1])/L];
    h = atan2(u[1], u[0]);
    s = (f1 - f0) / L;
    hull() {
        _ml_slice([p0[0]-0.6*u[0], p0[1]-0.6*u[1]], h, f0 - 0.6*s);
        _ml_slice([p1[0]+0.6*u[0], p1[1]+0.6*u[1]], h, f1 + 0.6*s);
    }
}

// ---- Connector (replicated 1:1 from marble_run.scad) ----
module _ml_tab_2d() {
    polygon([[-0.5, -_tab_neck/2], [_tab_depth, -_tab_tip/2],
             [_tab_depth, _tab_tip/2], [-0.5, _tab_neck/2]]);
}

module _ml_slot_2d() {
    n = _tab_neck/2 + conn_clear;
    t = _tab_tip/2 + conn_clear;
    d = _tab_depth + conn_clear;
    m = n - (t - n) / d * 0.5;
    polygon([[-0.5, -m], [d, -t], [d, t], [-0.5, m]]);
}

module ml_connector_tab(p, h_ang) {
    translate([p[0], p[1], 0])
        rotate([0, 0, h_ang])
            linear_extrude(height=_tab_h)
                _ml_tab_2d();
}

module ml_connector_slot_cut(p, h_ang) {
    translate([p[0], p[1], _slot_bottom])
        rotate([0, 0, h_ang])
            linear_extrude(height=60)
                _ml_slot_2d();
}

// ---- Junction tile (shared by flipflop and switch) ----
// Entry x=0 y=T/2 heading +x (floor entry_floor_h); exits y=0 heading -y
// ("R") and y=T heading +y ("L"), floors _exit_floor. Basin floor _bfl.
module ml_stop_post() {
    translate([_piv[0] + _slot_r, _piv[1], _bfl - 0.1])
        cylinder(d=_stop_pin_d, h=8.1);
}

module ml_junction_tile() {
    difference() {
        cube([_T, _T, _block_h]);
        // entry ramp: face floor -> basin floor at the basin edge, plus a
        // flat continuation past the basin-circle boundary so no wall
        // wedge survives at the basin mouth
        _ml_seg([0, _T/2], entry_floor_h, [_T/2 - _basin_r, _T/2], _bfl);
        _ml_seg([_T/2 - _basin_r, _T/2], _bfl,
                [_T/2 - _basin_r + 4, _T/2], _bfl);
        // open basin
        translate([_T/2, _T/2, _bfl]) cylinder(r=_basin_r, h=60);
        // exit troughs (both sides), basin floor -> exit floor at the face
        _ml_seg([_T/2, _tr0], _bfl, [_T/2, 0], _exit_floor);
        _ml_seg([_T/2, _T - _tr0], _bfl, [_T/2, _T], _exit_floor);
        // entry dovetail slot + chimney
        ml_connector_slot_cut([0, _T/2], 0);
        // pivot bore + open barb chamber (through the tile base)
        translate([_piv[0], _piv[1], -0.1])
            cylinder(d=_chamber_d, h=_chamber_top + 0.1);
        translate([_piv[0], _piv[1], _chamber_top - 0.1])
            cylinder(d=_bore_d, h=_bfl - _chamber_top + 0.6);
    }
    ml_stop_post();
    ml_connector_tab([_T/2, 0], -90);
    ml_connector_tab([_T/2, _T], 90);
}

// ---- Rocker (local frame: pivot on the z axis, absolute z heights) ----
module _ml_slot_arc_2d() {
    ro = _slot_r + _stop_pin_d/2 + pin_clear;
    ri = _slot_r - _stop_pin_d/2 - pin_clear;
    polygon(concat(
        [for (a = [-_slot_half : _slot_half/8 : _slot_half]) [ro*cos(a), ro*sin(a)]],
        [for (a = [_slot_half : -_slot_half/8 : -_slot_half]) [ri*cos(a), ri*sin(a)]]));
}

module _ml_cam() {
    ca = atan2(_cam_l[1], _cam_l[0]);
    // low dome the marble rolls over (its push toggles the rocker)
    translate([_cam_l[0], _cam_l[1], _bfl])
        intersection() {
            scale([1, 1, 8/15]) sphere(r=3);
            translate([-4, -4, 0.35]) cube([8, 8, 3]);
        }
    // spoke joining the cam to the hub disc
    rotate([0, 0, ca])
        translate([_disc_r - 0.7, -1.5, _bfl + 0.35])
            cube([norm(_cam_l) - _disc_r - 0.3, 3, 1.2]);
}

module ml_rocker(cams=true) {
    difference() {
        union() {
            translate([0, 0, _rk_bot]) cylinder(r=_disc_r, h=_rk_top - _rk_bot);
            translate([-_vane_len, -_vane_w/2, _rk_bot])
                cube([_vane_len + 3, _vane_w, _rk_top - _rk_bot]);
        }
        // stop arc slot (through cut; ends are the hard stops)
        translate([0, 0, _rk_bot - 0.1])
            linear_extrude(height=_rk_top - _rk_bot + 0.2)
                _ml_slot_arc_2d();
    }
    // pivot pin + snap barb (45-degree chamfers)
    translate([0, 0, _bfl - 4.1]) cylinder(d=_pin_d, h=4.6);
    translate([0, 0, _bfl - 4.8]) cylinder(d1=_barb_d, d2=_pin_d, h=0.7);
    translate([0, 0, _bfl - 5.5]) cylinder(d1=_barb_d - 2.8, d2=_barb_d, h=0.7);
    if (cams) {
        _ml_cam();
        mirror([0, 1, 0]) _ml_cam();
    }
}

// Rocker placed in the tile at swing angle `ang` (deg, 0 = centered).
module ml_rocker_at_angle(ang, cams=true) {
    translate([_piv[0], _piv[1], 0])
        rotate([0, 0, ang])
            ml_rocker(cams);
}

// route "R": marble exits the y=0 face; route "L": the y=T face.
function ml_theta(route) = (route == "R") ? -_rest_ang : _rest_ang;
module ml_rocker_at(route, cams=true) {
    ml_rocker_at_angle(ml_theta(route), cams);
}

// Print pose: inverted (flat top on the plate, snap-pin up).
module ml_rocker_print(cams=true) {
    translate([0, 0, _rk_top]) rotate([180, 0, 0]) ml_rocker(cams);
}

// ---- Merge tile ----
// Entries x=0 y=T/2 heading +x and x=T/2 y=T heading -y (floors
// entry_floor_h); single exit x=T y=T/2 heading +x (floor _exit_floor).
module ml_merge_tile() {
    jx = _T/2 + 10;                                // junction x
    jf = entry_floor_h - tile_fall * jx / _T;      // main floor at junction
    kp = [_T/2, _T - 10];                          // side-channel kink
    kf = entry_floor_h - 1;
    dh = atan2(_T/2 - kp[1], jx - kp[0]);          // diagonal heading
    hm = (-90 + dh) / 2;                           // mitered kink heading
    L2 = norm([jx - kp[0], _T/2 - kp[1]]);
    s2 = (jf - kf) / L2;
    difference() {
        cube([_T, _T, _block_h]);
        _ml_seg([0, _T/2], entry_floor_h, [_T, _T/2], _exit_floor);
        // side channel as chained hulls SHARING the mitered kink slice
        // exactly (the curve-tile pattern; separate overlapping segments
        // leave tangent cutter walls -> non-manifold at some parameters)
        hull() {
            _ml_slice([_T/2, _T + 0.6], -90, entry_floor_h + 0.06);
            _ml_slice(kp, hm, kf);
        }
        hull() {
            _ml_slice(kp, hm, kf);
            _ml_slice([jx + 0.6*cos(dh), _T/2 + 0.6*sin(dh)], dh,
                      jf + 0.6*s2);
        }
        ml_connector_slot_cut([0, _T/2], 0);
        ml_connector_slot_cut([_T/2, _T], -90);
    }
    ml_connector_tab([_T, _T/2], 0);
}

// ---- Accessors for the verification harness ----
function ml_tile_size() = _T;
function ml_marble_d() = marble_d;
function ml_mate_offset() = [_T + _eps, 0, -_step];
function ml_pivot() = _piv;
function ml_rest_ang() = _rest_ang;
function ml_stop_ang() = _stop_ang;

// Marble-center probe stations along the routed path, junction tile.
// route "R" = rocker at ml_theta("R"), marble exits y=0. i = 0..6.
function _ml_ramp_z(x) =
    entry_floor_h - (entry_floor_h - _bfl) * x / (_T/2 - _basin_r)
    + marble_d/2 + 0.15;
function _ml_trough_z(dy) =   // dy = distance from the exit face
    _exit_floor + (_bfl - _exit_floor) * dy / _tr0 + marble_d/2 + 0.15;
function _ml_route_r(i) =
    i == 0 ? [3, _T/2, _ml_ramp_z(3)] :
    i == 1 ? [_T/2 - 14, _T/2,       _bfl + marble_d/2 + 0.15] :
    i == 2 ? [_T/2 - 8,  _T/2 - 3.5, _bfl + marble_d/2 + 0.15] :
    i == 3 ? [_T/2 - 4,  _T/2 - 8,   _bfl + marble_d/2 + 0.15] :
    i == 4 ? [_T/2 - 0.5, _T/2 - 9.5, _bfl + 1.6 + marble_d/2 + 0.15] : // cam ride
    i == 5 ? [_T/2, 9, _ml_trough_z(9)] :
             [_T/2, 3, _ml_trough_z(3)];
function ml_ff_probe_count() = 7;
function ml_ff_probe(route, i) =
    let (p = _ml_route_r(i))
    route == "R" ? p : [p[0], _T - p[1], p[2]];
// Probe at the mouth of the branch the rocker is blocking.
function ml_blocked_probe(route) =
    [_T/2, route == "R" ? _T/2 + 7 : _T/2 - 7, _bfl + marble_d/2 + 0.15];

// Merge probes: branch "A" (x=0 entry) / "B" (y=T entry), i = 0..3.
function _ml_main_z(x) =
    entry_floor_h - tile_fall * x / _T + marble_d/2 + 0.15;
function ml_merge_probe_count() = 4;
function ml_merge_probe(branch, i) =
    branch == "A" ?
        (i == 0 ? [3,      _T/2, _ml_main_z(3)] :
         i == 1 ? [15,     _T/2, _ml_main_z(15)] :
         i == 2 ? [_T/2 + 5, _T/2, _ml_main_z(_T/2 + 5)] :
                  [_T - 5, _T/2, _ml_main_z(_T - 5)]) :
        (i == 0 ? [_T/2, _T - 6,
                   entry_floor_h - 0.6 + marble_d/2 + 0.15] :
         i == 1 ? [_T/2 + 5, (_T - 10 + _T/2)/2,
                   (entry_floor_h - 1
                    + entry_floor_h - tile_fall*(_T/2 + 10)/_T)/2
                   + marble_d/2 + 0.15] :
         i == 2 ? [_T/2 + 10, _T/2, _ml_main_z(_T/2 + 10)] :
                  [_T - 5, _T/2, _ml_main_z(_T - 5)]);

// Entry/exit floor drops per route (documentation + gravity check)
function ml_drops() = [
    ["flipflop entry->R", entry_floor_h, _exit_floor],
    ["flipflop entry->L", entry_floor_h, _exit_floor],
    ["merge A->exit", entry_floor_h, _exit_floor],
    ["merge B->exit", entry_floor_h, _exit_floor]];

// ---- Display ----
module show_set() {
    g = 8;
    color("SteelBlue")      ml_junction_tile();
    color("DarkOrange")     translate([_T + g, 0, 0]) ml_junction_tile();
    color("MediumSeaGreen") translate([2*(_T + g), 0, 0]) ml_merge_tile();
    color("IndianRed")      translate([20, -22, 0]) ml_rocker_print(true);
    color("Gold")           translate([_T + g + 20, -22, 0]) ml_rocker_print(false);
}

module show_flipflop() {
    color("SteelBlue") ml_junction_tile();
    color("IndianRed") ml_rocker_at("R", true);
}

module show_switch() {
    color("DarkOrange") ml_junction_tile();
    color("Gold")       ml_rocker_at("L", false);
}

module show_counter_demo() {
    // FF0: entry at x=0; its "R" exit (carry) feeds FF1, rotated -90.
    translate([0, 0, _step]) {
        color("SteelBlue") ml_junction_tile();
        color("IndianRed") ml_rocker_at("R", true);
    }
    translate([0, -_eps, 0]) rotate([0, 0, -90]) {
        color("LightSkyBlue") ml_junction_tile();
        color("Salmon")       ml_rocker_at("L", true);
    }
}

if (_display_mode == "set") show_set();
else if (_display_mode == "flipflop") show_flipflop();
else if (_display_mode == "switch") show_switch();
else if (_display_mode == "merge") ml_merge_tile();
else if (_display_mode == "counter_demo") show_counter_demo();
