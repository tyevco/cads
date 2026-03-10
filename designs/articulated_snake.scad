// @name Articulated Snake
// @description A print-in-place articulated snake toy with ball-and-socket joints. Prints flat, flexes when freed.
// @tags toy, articulated, snake, print-in-place, flexible
//
// A segmented snake that prints as a single piece lying flat.
// Each segment connects to the next via a ball-and-socket joint
// with enough clearance to move freely after printing.
//
// The snake tapers from head to tail, and the head has a
// simple face with eye sockets and a forked tongue slot.
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
segment_length = 10; // [7:2:16]

// Body height / thickness (mm)
body_height = 10; // [6:1:16]

/* [Joint Parameters] */
// Ball diameter (mm)
ball_diameter = 6.0; // [4:0.5:10]

// Joint clearance gap (mm) - tune for your printer
joint_clearance = 0.35; // [0.2:0.05:0.6]

// Socket opening angle (degrees) - how wide the socket mouth is
socket_opening = 100; // [80:5:130]

/* [Head Details] */
// Eye socket diameter (mm)
eye_diameter = 5; // [3:0.5:8]

// Eye socket depth (mm)
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

// Scale depth (mm)
scale_depth = 0.6; // [0.3:0.1:1.2]

/* [Display] */
// What to show
_display_mode = "full"; // ["full", "head", "segment", "tail"]

// Curve the snake for display (degrees per joint)
_curve_angle = 0; // [-30:5:30]

/* [Advanced] */
$fn = 40;


// ---- Derived ----

// Width taper per segment
function seg_width(i) =
    head_width - (head_width - tail_width) * (i + 1) / (segment_count + 1);

// Height taper (slight)
function seg_height(i) =
    body_height - (body_height - body_height * 0.6) * i / (segment_count + 1);


// ---- Modules ----

// Ball joint (the ball part, attached to back of a segment)
module joint_ball() {
    sphere(d=ball_diameter);
}

// Socket joint (the receiving part, cut into front of a segment)
module joint_socket() {
    d = ball_diameter + joint_clearance * 2;
    // Sphere with an opening
    difference() {
        sphere(d=d + 3);
        sphere(d=d);
        // Opening cone
        rotate([0, -90, 0])
            cylinder(d1=0, d2=d*2, h=d, $fn=30);
    }
}

// Cutout for socket (boolean difference)
module joint_socket_cutout() {
    d = ball_diameter + joint_clearance * 2;
    sphere(d=d);
    // Entry channel
    rotate([0, -90, 0])
        cylinder(d1=d * sin(socket_opening/2) * 2,
                 d2=d * sin(socket_opening/2) * 2,
                 h=d/2 + 2);
}

// Scale pattern for decoration
module scale_pattern(width, length, height) {
    if (enable_scales) {
        scale_size = 3;
        cols = floor(width / scale_size);
        rows = floor(length / scale_size);
        for (r = [0:rows-1]) {
            offset_x = (r % 2 == 0) ? 0 : scale_size / 2;
            for (c = [0:cols-1]) {
                translate([
                    -width/2 + c * scale_size + offset_x + scale_size/2,
                    -length/2 + r * scale_size + scale_size/2,
                    height/2
                ])
                    scale([1, 1.3, 1])
                        sphere(d=scale_size * 0.8);
            }
        }
    }
}

// Single body segment
module body_segment(width, height, length) {
    seg_r = min(width, height) * 0.15;

    difference() {
        // Main body shape - rounded rectangle cross section
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

// Head piece
module head() {
    h = body_height;
    w = head_width;
    r = 3;

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

        // Eye sockets
        for (side = [-1, 1]) {
            translate([side * w * 0.28, head_length * 0.2, h * 0.7])
                sphere(d=eye_diameter);
        }

        // Tongue slot
        if (enable_tongue) {
            translate([0, head_length * 0.3, h * 0.25])
                cube([tongue_width, tongue_length * 2, h * 0.3], center=true);
            // Fork
            for (side = [-1, 1]) {
                translate([side * tongue_width, head_length * 0.6 + tongue_length * 0.3, h * 0.25])
                    rotate([0, 0, side * 20])
                        cube([tongue_width, tongue_length * 0.6, h * 0.3], center=true);
            }
        }

        // Socket cutout at back of head
        translate([0, -head_length * 0.3, h / 2])
            joint_socket_cutout();
    }
}

// Tail tip
module tail_tip() {
    h = seg_height(segment_count);
    w = tail_width;

    // Tapered tail
    hull() {
        // Base (connects to last segment)
        for (x = [-w/2 + 1, w/2 - 1]) {
            translate([x, 0, 1])
                sphere(r=1);
            translate([x, 0, h - 1])
                sphere(r=1);
        }
        // Tip
        translate([0, segment_length * 1.5, h * 0.3])
            sphere(r=1.5);
    }

    // Ball at front for connecting to last segment
    translate([0, 0, h / 2])
        rotate([0, 0, 0])
            joint_ball();
}

// Complete body segment with joints
module full_segment(index) {
    w = seg_width(index);
    h = seg_height(index);
    len = segment_length;
    next_w = seg_width(index + 1);

    difference() {
        union() {
            // Body
            body_segment(w, h, len);

            // Ball joint at back (connects to next segment)
            translate([0, -len/2, h/2])
                joint_ball();
        }

        // Socket cutout at front
        translate([0, len/2, h/2])
            joint_socket_cutout();
    }
}


// ---- Display ----

module show_full_snake() {
    // Head
    color("ForestGreen")
        head();

    // Body segments laid out in a line
    for (i = [0:segment_count-1]) {
        h = seg_height(i);
        y_pos = -head_length * 0.3 - (i + 1) * (segment_length + ball_diameter * 0.3);

        rotate([0, 0, _curve_angle * (i + 1)])
        translate([0, y_pos, 0])
            color("ForestGreen", 0.9 - i * 0.02)
                full_segment(i);
    }

    // Tail
    tail_y = -head_length * 0.3 - (segment_count + 1) * (segment_length + ball_diameter * 0.3);
    color("ForestGreen", 0.7)
        translate([0, tail_y, 0])
            tail_tip();
}

module show_print_flat() {
    // All pieces in a line, ready to print as one piece
    // Head
    color("ForestGreen") head();

    // Segments
    for (i = [0:segment_count-1]) {
        y_offset = -head_length * 0.3
                   - (i + 1) * (segment_length + ball_diameter * 0.6);
        color("ForestGreen", 0.95 - i * 0.03)
            translate([0, y_offset, 0])
                full_segment(i);
    }

    // Tail
    tail_y = -head_length * 0.3
             - (segment_count + 1) * (segment_length + ball_diameter * 0.6);
    color("ForestGreen", 0.7)
        translate([0, tail_y, 0])
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
