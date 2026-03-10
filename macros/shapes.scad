// shapes.scad - Shared shape primitives for use across designs
//
// Usage: use <../macros/shapes.scad>
//   (from the designs/ directory)

// 2D rounded rectangle centered at origin
// size: [x, y] dimensions
// radius: corner fillet radius (clamped to half the smallest dimension)
module rounded_rect(size, radius) {
    x = size[0];
    y = size[1];
    r = min(radius, min(x,y)/2);
    hull() {
        for (sx = [r, x-r])
            for (sy = [r, y-r])
                translate([sx, sy])
                    circle(r=r);
    }
}

// 3D rounded cube (minkowski of cube + sphere)
// size: [x, y, z] dimensions (outer)
// radius: edge fillet radius
module rounded_cube(size, radius) {
    r = min(radius, min(size[0], min(size[1], size[2]))/2);
    minkowski() {
        cube([size[0] - 2*r, size[1] - 2*r, size[2] - 2*r]);
        sphere(r=r);
    }
}

// 2D stadium / pill shape centered at origin
// length: total length end-to-end
// width: total width (diameter of the end caps)
module stadium_2d(length, width) {
    hull() {
        translate([-(length - width)/2, 0]) circle(d=width);
        translate([ (length - width)/2, 0]) circle(d=width);
    }
}
