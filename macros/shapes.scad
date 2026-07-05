// shapes.scad - Shared shape primitives for use across designs
//
// Usage: use <../macros/shapes.scad>
//   (from the designs/ directory)

// 2D rounded rectangle anchored at the origin corner (spans [0,0]..[x,y]).
// size: [x, y] dimensions
// radius: corner fillet radius (clamped to just under half the smallest
//         dimension; radius <= 0 falls back to a plain square)
module rounded_rect(size, radius) {
    x = size[0];
    y = size[1];
    r = min(radius, min(x, y)/2 - 0.01);
    if (r <= 0) {
        square([x, y]);
    } else {
        hull() {
            for (sx = [r, x-r])
                for (sy = [r, y-r])
                    translate([sx, sy])
                        circle(r=r);
        }
    }
}

// 3D rounded cube spanning [-r,-r,-r]..[x-r,y-r,z-r] (overall size as given).
// size: [x, y, z] dimensions (outer)
// radius: edge fillet radius (clamped to just under half the smallest
//         dimension; radius <= 0 falls back to a plain cube)
module rounded_cube(size, radius) {
    r = min(radius, min(size[0], min(size[1], size[2]))/2 - 0.01);
    if (r <= 0) {
        cube(size);
    } else {
        minkowski() {
            cube([size[0] - 2*r, size[1] - 2*r, size[2] - 2*r]);
            sphere(r=r);
        }
    }
}

// 2D stadium / pill shape centered at origin
// length: total length end-to-end (clamped to at least the width)
// width: total width (diameter of the end caps)
module stadium_2d(length, width) {
    if (length <= width) {
        circle(d=width);
    } else {
        hull() {
            translate([-(length - width)/2, 0]) circle(d=width);
            translate([ (length - width)/2, 0]) circle(d=width);
        }
    }
}
