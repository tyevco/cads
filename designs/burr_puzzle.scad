// @name Six-Piece Burr Puzzle
// @description Classic interlocking six-piece burr with one solid key piece and a printable fit clearance.
// @tags puzzle, burr, interlocking, toy, classic
//
// A classic notchable six-piece burr (2x2x6-unit sticks). The piece set
// was derived from the pairwise overlap blocks of the six assembled
// sticks and verified solvable by exhaustive straight-slide search:
//
//   - 1x KEY (piece 0): completely solid stick.
//   - 3x HALF-LAP (pieces 1, 4, 5): a notch 2 units long, full width,
//     half depth, centered on one face (the classic "simple notch"
//     piece, cut over the central 4 half-units).
//   - 2x CORNER (pieces 2, 3): a half-lap along the inner face over the
//     central 4 half-units, plus a full-thickness half-depth notch for
//     the key. The two are mirror images, but the shape is y-symmetric,
//     so they are the SAME printed part (one is rotated 180 degrees).
//
// Interlock (verified by search + boolean intersection tests): in the
// assembled state only the key can move, sliding out along its own
// axis (+x). Every other piece is blocked on all six directions until
// the key is removed.
//
// Disassembly: key +x  ->  corner B1 +z  ->  corner B2 +z  ->
//              lap A2 +x  ->  lap C1 +x  ->  lap C2 free.
// Assembly is the reverse.
//
// Printing: every piece lies flat on the plate with all notches facing
// up or cut clear through - vertical walls only, no supports, no
// bridges. Fit is controlled by fit_clearance: every piece is shrunk
// by clearance/2 per face and every notch is enlarged by clearance/2
// per face, so any two mating surfaces are separated by exactly
// fit_clearance.

/* [Puzzle Size] */
// Stick cross-section width (mm) - the puzzle is ~3x this across
stick_size = 24; // [12:2:40]

// Stick length as a multiple of the cross-section (3 = classic 2x2x6)
length_ratio = 3; // [2.5:0.25:4]

/* [Fit] */
// Clearance between mating faces (mm). 0.25 suits most FDM printers; increase for a looser fit.
fit_clearance = 0.25; // [0.1:0.05:0.6]

/* [Print Layout] */
// Gap between pieces on the plate (mm)
part_gap = 8; // [4:1:15]

/* [Display] */
// What to show
_display_mode = "all"; // ["all", "pieces", "assembled"]

// ---- Derived geometry ----

// Half-unit: sticks are 2u x 2u in cross-section, notches are on a u grid
_u = stick_size / 2;
// Half-length of a stick
_hl = length_ratio * stick_size / 2;
// Per-face inset/outset that realizes the clearance
_c2 = fit_clearance / 2;

assert(length_ratio >= 2.5,
    str("length_ratio ", length_ratio, " too short: notches span the central 4 half-units (2x stick_size)"));
assert(fit_clearance < _u / 2,
    str("fit_clearance ", fit_clearance, " too large for stick_size ", stick_size));

// Piece order: 0=A1 key (x axis, top), 1=A2 (x axis, bottom),
// 2=B1 (y axis, +x side), 3=B2 (y axis, -x side),
// 4=C1 (z axis, +y side), 5=C2 (z axis, -y side)

// Blanks as [min_corner, max_corner] in mm (assembled frame)
_blanks = [
    [[-_hl, -_u,     0], [ _hl,  _u, 2*_u]],   // A1 key
    [[-_hl, -_u, -2*_u], [ _hl,  _u,    0]],   // A2
    [[    0, -_hl, -_u], [2*_u,  _hl,  _u]],   // B1
    [[-2*_u, -_hl, -_u], [   0,  _hl,  _u]],   // B2
    [[ -_u,     0, -_hl], [ _u, 2*_u,  _hl]],  // C1
    [[ -_u, -2*_u, -_hl], [ _u,    0,  _hl]],  // C2
];

// Notch boxes per piece (assembled frame). Each is the union of the
// overlap blocks assigned to that piece by the verified solution.
_notches = [
    [],                                                              // A1: solid key
    [[[-2*_u, -_u, -_u], [2*_u, _u, 0]]],                            // A2: half-lap, opens +z
    [[[0, -_u, 0], [2*_u, _u, _u]],                                  // B1: key notch, opens +z
     [[0, -2*_u, -_u], [_u, 2*_u, _u]]],                             // B1: inner lap, opens -x
    [[[-2*_u, -_u, 0], [0, _u, _u]],                                 // B2: key notch, opens +z
     [[-_u, -2*_u, -_u], [0, 2*_u, _u]]],                            // B2: inner lap, opens +x
    [[[-_u, 0, -2*_u], [_u, _u, 2*_u]]],                             // C1: half-lap, opens -y
    [[[-_u, -_u, -2*_u], [_u, 0, 2*_u]]],                            // C2: half-lap, opens +y
];

_colors = ["Gold", "DodgerBlue", "Tomato", "LimeGreen", "Orchid", "SlateGray"];

// ---- Accessors (also used by the verification harness) ----

function burr_piece_count() = 6;
function burr_stick_len() = 2 * _hl;
function burr_unit() = _u;
function burr_clearance() = fit_clearance;
// Extraction axis of the key (piece 0): +x
function burr_key_axis() = [1, 0, 0];

// ---- Modules ----

// A box from [min,max] corners, grown by g on every face
module _box(b, g) {
    translate([b[0][0] - g, b[0][1] - g, b[0][2] - g])
        cube([b[1][0] - b[0][0] + 2*g,
              b[1][1] - b[0][1] + 2*g,
              b[1][2] - b[0][2] + 2*g]);
}

// One puzzle piece in its assembled position/orientation.
// Blank shrunk by clearance/2 per face; notches grown by clearance/2
// per face (which also makes every cutter overshoot the surface).
module burr_piece(i) {
    difference() {
        _box(_blanks[i], -_c2);
        for (n = _notches[i]) _box(n, _c2);
    }
}

// Union of all pieces except piece i (for intersection tests)
module burr_others(i) {
    for (j = [0:5]) if (j != i) burr_piece(j);
}

module show_assembled() {
    for (i = [0:5]) color(_colors[i]) burr_piece(i);
}

// Print pose: rotate piece i so its stick axis lies along x and every
// notch opens upward or cuts clear through, then rest it on the plate.
// Rotations are proper (det +1) - verified per piece in the header.
module _print_pose(i) {
    if (i == 0 || i == 1) {
        // A pieces: axis already x; A1 sits at z[0,2u], A2 at z[-2u,0]
        // with its lap opening +z (up).
        translate([0, 0, (i == 0 ? 0 : 2*_u) - _c2]) children();
    } else if (i == 2) {
        // B1: axis y->x, inner face (x=0) up: (x,y,z) -> (y,-z,-x)
        translate([0, 0, 2*_u - _c2]) rotate([90, 0, 0]) rotate([0, 0, -90]) children();
    } else if (i == 3) {
        // B2: axis y->x, inner face (x=0) up: (x,y,z) -> (y,z,x)
        translate([0, 0, 2*_u - _c2]) rotate([-90, 0, 0]) rotate([0, 0, -90]) children();
    } else if (i == 4) {
        // C1: axis z->x, lap face (y=0) up: (x,y,z) -> (z,-x,-y)
        translate([0, 0, 2*_u - _c2]) rotate([-90, 0, 0]) rotate([0, 90, 0]) children();
    } else {
        // C2: axis z->x, lap face (y=0) up: (x,y,z) -> (z,x,y)
        translate([0, 0, 2*_u - _c2]) rotate([90, 0, 0]) rotate([0, 90, 0]) children();
    }
}

module show_print_layout() {
    for (i = [0:5])
        color(_colors[i])
            translate([0, i * (2*_u + part_gap), 0])
                _print_pose(i) burr_piece(i);
}

// ---- Dispatch ----

if (_display_mode == "all") {
    show_print_layout();
} else if (_display_mode == "pieces") {
    show_print_layout();
} else if (_display_mode == "assembled") {
    show_assembled();
}
