// @name Articulated Snake
// @description A print-in-place articulated snake toy with ball-and-socket joints. Prints flat, flexes when freed.
// @tags toy, articulated, snake, print-in-place, flexible
//
// A segmented snake that prints as a single piece lying flat.
// Each segment carries a ball on a short neck at its tail end,
// captured inside a recessed socket in the next segment. The
// socket opening is smaller than the ball, so the joints hold
// together but pivot freely after printing.
//
// Chain layout (head at +y, tail at -y):
//   head(ball) -> segment0(socket ... ball) -> ... -> tail(socket)
//
// The snake tapers from head to tail, and the head has a
// simple face with eye dimples and a forked tongue slot.
//
// Printing:
//   - Print flat on the bed as a single piece
//   - Use 0.2mm layer height for best joint clearance
//   - After printing, gently flex each joint to break free
//   - No supports needed

/* [Snake Dimensions] */
// Number of body segments (not counting head/tail)
segment_count = 10; // [4:1:20]

// Head width (mm)
head_width = 20; // [14:1:30]

// Head length (mm)
head_length = 22; // [16:1:30]

// Tail tip width (mm)
tail_width = 6; // [4:1:12]

// Segment length (mm)
segment_length = 10; // [7:1:16]

// Body height / thickness (mm)
body_height = 10; // [6:1:16]

/* [Joint Parameters] */
// Ball diameter (mm)
ball_diameter = 6.0; // [4:0.5:10]

// Joint clearance gap (mm) - tune for your printer
joint_clearance = 0.35; // [0.2:0.05:0.6]

// Socket opening cone angle (degrees) - wider allows more articulation
// but weakens retention
socket_opening = 100; // [80:5:130]

/* [Head Details] */
// Eye dimple diameter (mm)
eye_diameter = 5; // [3:0.5:8]

// Eye dimple depth (mm)
eye_depth = 2; // [1:0.5:4]

// Enable tongue slot
enable_tongue = true;

// Tongue slot width (mm)
tongue_width = 1.5;

// Tongue length (mm)
tongue_length = 8;

/* [Decoration] */
// Scale pattern on top surface
enable_scales = true;

// Scale indentation depth (mm)
scale_depth = 0.6; // [0.3:0.1:1.2]

/* [Display] */
// What to show
_display_mode = "full"; // ["full", "head", "segment", "tail"]

/* [Advanced] */
$fn = 40;


// ---- Derived ----

// Joint geometry.
// The socket cavity center sits _socket_recess behind the front face, so
// the opening in the face is a chord smaller than the ball - that is what
// retains the joint. The ball hangs _neck_len beyond its parent's back
// face on a thin neck that passes through the flared opening cone.
_socket_d = ball_diameter + joint_clearance * 2;
_socket_recess = ball_diameter * 0.35;
_face_gap = 0.8;                       // printed gap between segment faces
_neck_len = _socket_recess + _face_gap; // ball center past parent back face
_neck_d = ball_diameter * 0.5;
_joint_pitch = segment_length + _face_gap; // center-to-center spacing

// Retention sanity: the socket mouth (sphere-cap chord and opening cone,
// both measured at the front face) must be smaller than the ball.
_mouth_chord_r = sqrt(pow(_socket_d/2, 2) - pow(_socket_recess, 2));
_mouth_cone_r = _socket_recess * tan(socket_opening / 2);
assert(_mouth_chord_r < ball_diameter / 2,
    str("Socket mouth (", _mouth_chord_r*2, "mm) is wider than the ball (",
        ball_diameter, "mm): reduce joint_clearance or ball taper."));
assert(_mouth_cone_r < ball_diameter / 2,
    str("Opening cone (", _mouth_cone_r*2, "mm at the face) releases the ",
        "ball: reduce socket_opening."));

// Minimum cross-section that leaves 1.2mm of wall around a socket
_min_joint_size = _socket_d + 2.4;

// Width taper per segment, clamped so sockets always have side walls
function seg_width(i) =
    max(head_width - (head_width - tail_width) * (i + 1) / (segment_count + 1),
        _min_joint_size);

// Height taper (slight), clamped so sockets keep floors and ceilings
function seg_height(i) =
    max(body_height - body_height * 0.4 * i / (segment_count + 1),
        _min_joint_size);

// Joint height between piece i and piece i+1: the smaller neighbor's
// midline (heights shrink toward the tail)
function joint_z(i) = seg_height(i + 1) / 2;


// ---- Modules ----

// Socket cutout, opening toward +y. Place at the cavity center.
module joint_socket_cutout() {
    sphere(d=_socket_d);
    // Flared neck channel: cone with its apex at the cavity center,
    // opening through the front face
    rotate([-90, 0, 0])
        cylinder(d1=0,
                 d2=2 * tan(socket_opening/2) * (_socket_d/2 + 2),
                 h=_socket_d/2 + 2);
}

// Ball on a neck, hanging in -y off a parent whose back face passes
// through y=0. Place at [x, back_face_y, joint_z].
module joint_ball_assembly() {
    translate([0, -_neck_len, 0]) {
        sphere(d=ball_diameter);
        // Neck back into the parent body
        rotate([-90, 0, 0])
            cylinder(d=_neck_d, h=_neck_len + 1);
    }
}

// Scale indentation pattern: spheres dipping scale_depth into the top
// surface (z = height plane). Coarse $fn - these are tiny dents, and the
// sphere count dominates render time.
module scale_pattern(width, length, height) {
    scale_size = 3;
    r_z = scale_size * 0.8 / 2;
    cols = max(floor(width / scale_size), 1);
    rows = max(floor(length / scale_size), 1);
    for (r = [0:rows-1]) {
        offset_x = (r % 2 == 0) ? 0 : scale_size / 2;
        for (c = [0:cols-1]) {
            translate([
                -width/2 + c * scale_size + offset_x + scale_size/2,
                -length/2 + r * scale_size + scale_size/2,
                height + r_z - scale_depth
            ])
                scale([1, 1.3, 1])
                    sphere(d=scale_size * 0.8, $fn=16);
        }
    }
}

// Single body segment: rounded-rectangle cross section along y
module body_segment(width, height, length) {
    seg_r = min(width, height) * 0.15;

    difference() {
        hull() {
            for (x = [-width/2 + seg_r, width/2 - seg_r]) {
                for (z = [seg_r, height - seg_r]) {
                    translate([x, 0, z])
                        rotate([-90, 0, 0])
                            cylinder(r=seg_r, h=length, center=true);
                }
            }
        }

        // Scale indentations on top
        if (enable_scales) {
            scale_pattern(width - 2, length, height);
        }
    }
}

// Head piece: ball at the back (received by segment 0's socket)
module head() {
    h = body_height;
    w = head_width;
    r = 3;
    back_y = -head_length * 0.3 - r; // rearmost point of the head hull

    difference() {
        // Head shape - slightly pointed at front
        hull() {
            // Back (wide)
            for (x = [-w/2 + r, w/2 - r]) {
                translate([x, -head_length * 0.3, r])
                    sphere(r=r);
                translate([x, -head_length * 0.3, h - r])
                    sphere(r=r);
            }
            // Front (narrow, pointed)
            translate([0, head_length * 0.6, r])
                sphere(r=r);
            translate([0, head_length * 0.6, h * 0.7])
                sphere(r=r * 0.7);
        }

        // Eye dimples, eye_depth into the (sloped) top surface
        for (side = [-1, 1]) {
            translate([side * w * 0.28, head_length * 0.2,
                       h * 0.95 + eye_diameter/2 - eye_depth])
                sphere(d=eye_diameter);
        }

        // Tongue: a groove up the underside of the snout that splits into
        // two prongs which exit through the tip (open cuts, no sealed voids)
        if (enable_tongue) {
            groove_top = h * 0.3;
            translate([-tongue_width/2, head_length * 0.1, -0.5])
                cube([tongue_width, head_length * 0.62, groove_top + 0.5]);
            for (side = [-1, 1]) {
                translate([side * tongue_width * 0.4, head_length * 0.68, 0])
                    rotate([0, 0, side * 18])
                        translate([-tongue_width/2, 0, -0.5])
                            cube([tongue_width, tongue_length, groove_top + 0.5]);
            }
        }
    }

    // Ball at the back, at segment 0's joint height
    translate([0, back_y, joint_z(-1)])
        joint_ball_assembly();
}

// Tail tip: socket at the front, tapering away toward -y
module tail_tip() {
    h = seg_height(segment_count);
    w = seg_width(segment_count);
    front_y = 1; // front face of the base (hull spheres r=1 at y=0)

    // Keep the full cross-section until safely past the socket cavity,
    // then taper to the tip
    taper_start = -(_socket_recess + _socket_d/2 + 1.5);

    difference() {
        hull() {
            // Base block (receives the last segment's ball)
            for (y = [0, taper_start]) {
                for (x = [-w/2 + 1, w/2 - 1]) {
                    translate([x, y, 1])
                        sphere(r=1);
                    translate([x, y, h - 1])
                        sphere(r=1);
                }
            }
            // Tip, pointing away from the chain
            translate([0, taper_start - segment_length * 1.5, 1.2])
                sphere(r=1.2);
        }

        // Socket recessed behind the front face
        translate([0, front_y - _socket_recess, h / 2])
            joint_socket_cutout();
    }
}

// Complete body segment: socket at the front (+y), ball at the back (-y)
module full_segment(index) {
    w = seg_width(index);
    h = seg_height(index);
    len = segment_length;

    difference() {
        union() {
            body_segment(w, h, len);

            // Ball at the back, at the next piece's joint height
            translate([0, -len/2, joint_z(index)])
                joint_ball_assembly();
        }

        // Socket recessed behind the front face, at this piece's midline
        translate([0, len/2 - _socket_recess, h / 2])
            joint_socket_cutout();
    }
}


// ---- Display ----

// Chain positions: each piece's socket center lands exactly on the
// previous piece's ball center.
_head_back_y = -head_length * 0.3 - 3;
_head_ball_y = _head_back_y - _neck_len;
function seg_y(i) = _head_ball_y - (segment_length/2 - _socket_recess)
    - i * _joint_pitch;
_last_ball_y = seg_y(segment_count - 1) - segment_length/2 - _neck_len;
_tail_y = _last_ball_y - (1 - _socket_recess);

module show_print_flat() {
    // Head
    color("ForestGreen") head();

    // Segments
    for (i = [0:segment_count-1]) {
        color("ForestGreen", 0.95 - i * 0.03)
            translate([0, seg_y(i), 0])
                full_segment(i);
    }

    // Tail
    color("ForestGreen", 0.7)
        translate([0, _tail_y, 0])
            tail_tip();
}


// Main display logic
if (_display_mode == "full") {
    show_print_flat();
} else if (_display_mode == "head") {
    head();
} else if (_display_mode == "segment") {
    full_segment(0);
} else if (_display_mode == "tail") {
    tail_tip();
}
