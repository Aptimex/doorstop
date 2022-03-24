/* [General] */
//radius of the center cylinder that gets captured
circle_rad = 6;
//outer radius of the grabber
outer_rad = 10;
//how high to "extrude" evertyhing
height = 10;
//Desired total length of both parts when captured
total_len = 75;


/* [Grabber portion] */
//Base width
grabber_base_w = 40;
//Base depth (thickness)
grabber_base_d = 4;
//Arms depth (thickness)
grabber_arm_d = 1.2;
//Set the length of the grabber (circle center to end of base) instead of assuming half of total_len
grabber_len_override = -1;
grabber_arm_len = (grabber_len_override>0) ? grabber_len_override : total_len/2 - grabber_base_d;
//Radial gap between captured cylinder and grabber; 0 is probably best for most cases
grabber_gap = 0.0; //[0:0.1:5]
//Angle (degrees) of the open gap in the grabber that accepts the captured cylinder; smaller is tighter
grabber_open_angle = 120;


/* [Captured portion] */
//Base width
captured_base_w = 40;
//Base depth (thickness)
captured_base_d = 4;
//Arms depth (thickness)
captured_arm_d = 2.4;
//Set the length of the captured part (cylinder center to end of base) instead of assuming half of total_len
captured_len_override = -1;
captured_arm_len = (captured_len_override>0) ? captured_len_override : total_len/2 - captured_base_d;


/* [Render] */
//Set to false to render in the catpured orientation to see how they will fit
printable = true;


module blank() {
    //this just stops customizer variable parsing
}

e = 0.01;
$fa = 1;


//make stuff
if (printable) {
    grabber();
    translate([(outer_rad+circle_rad)+4, -circle_rad, 0]) captured();
} else {
    grabber();
    captured();
}


// Modules

module grabber() {
    grabber_hook();
    grabber_arms();
    //color([1, 0.5, 0, 0.5])
        grabber_base();
}

module grabber_hook() {
    
    ir = circle_rad+grabber_gap;
    or = outer_rad;
    //a = 240;
    a = 360-grabber_open_angle;
    
    cylinderSection(ir, or, height, a);
}

module grabber_base() {
    translate([0, grabber_base_d/2 + grabber_arm_len, 0])
        cube(size=[grabber_base_w, grabber_base_d, height], center=true);
}

module grabber_arms() {
    //gotta do a bunch of complicated triangle and circle chord math;
    //start by finding the straight-line distance between outer radius and end of base
    a = grabber_base_w/2 - outer_rad;
    b = grabber_arm_len;
    hyp = sqrt((a*a + b*b));
    
    //Calculate the acute angle between the long side and the hypotenuse; this is the tangent angle of the target arc relative to the hypotenuse.
    longSide = max(a, b);
    alpha = acos(longSide / hyp); //accute angle
    
    //calculate the angle between the hypotenuse and the line perpendicular to the long side; the perpendicular line will be the radius of the target arc
    aPrime = 90-alpha;
    
    //The line perpendicular to the hypotenuse (centered on its length) and perpendicular to the long side (at alpha) form a right triange
    //The hypteneus length of this triangle is the radius of the largest circle that will intersect both ends of the first hypotenuse without exceeding the long or short sides of the first triangle.
    rad = (hyp/2)/cos(aPrime);
    
    //calc the angle of the arc segment relative to the center point of its circle, based on the radius
    angle = 2*asin(hyp/(2*rad));
    
    if (b<a) { //wider than long; start parallel to base instead of Y axis
        mirror([1, 1, 0])
            translate([-rad-grabber_arm_len, -grabber_base_w/2, 0])
                gra(a, rad, angle);
        
                mirror([1, 1, 0])
                    rotate([0, 0, 180])
                        translate([rad+grabber_arm_len, -grabber_base_w/2, 0])
                            gla(a, rad, angle);
        
    } else { //longer than wide, most common
        gra(a, rad, angle);
        gla(a, rad, angle);
    }
}

module gra(a, rad, angle) {
    translate([rad+a, 0, 0])
        mirror([1, 0, 0])
            cylinderSection(rad, rad+grabber_arm_d, height, angle, false);
}

module gla(a, rad, angle) {
    translate([-rad-a, 0, 0])
            cylinderSection(rad, rad+grabber_arm_d, height, angle, false);
}



module captured() {
    captured_cyl();
    captured_arms();
    //color([1, 0.5, 0, 0.5])
        captured_base();
}

module captured_cyl() {
    cylinder(r=circle_rad, h=height, center=true);
}

module captured_base() {
    translate([0, -captured_base_d/2 - captured_arm_len, 0])
        cube(size=[captured_base_w, captured_base_d, height], center=true);
}

module captured_arms(right=true) {
    // Same math as in grabber_arms(), see comments there.
    a = captured_base_w/2 - captured_arm_d;
    b = captured_arm_len;
    hyp = sqrt((a*a + b*b));
    
    longSide = max(a, b);
    alpha = acos(longSide / hyp); //accute angle
    
    aPrime = 90-alpha;
    rad = (hyp/2)/cos(aPrime);
    angle = 2*asin(hyp/(2*rad));
    
    if (b<a) {
        //they don't quite meet at the origin (not sure why they should), but close enough for practical purposes
        translate([-captured_base_w/2, -captured_arm_len-captured_arm_d, 0])
            rotate([0, 0, -90])
                mirror([0, 1, 0])
                    cra(rad, angle);
        
        translate([captured_base_w/2, -captured_arm_len-captured_arm_d, 0])
            rotate([0, 0, 90])
                mirror([0, 1, 0])
                    cla(rad, angle);
        
    } else {
        cra(rad, angle);
        cla(rad, angle);
    }
}

//captured right arm, when arm length is longer than half the base width
module cra(rad, angle) {
    translate([-rad-captured_arm_d, 0, 0])
        mirror([0, 1, 0])
            cylinderSection(rad, rad+captured_arm_d, height, angle, false);
}

//captured left arm, when arm length is longer than half the base width
module cla(rad, angle) {
    mirror([1, 0, 0]) mirror([0, 1, 0])
        translate([-rad-captured_arm_d, 0, 0])
            cylinderSection(rad, rad+captured_arm_d, height, angle, false);
}



module cylinderSection(ir, or, h, a, sym=true) {
    if (sym) { //align to Y axis symmetry
        rotate([0, 0, -(a-180)/2]) cS(ir, or, h, a);
    } else {
        cS(ir, or, h, a);
    }
    
}

//Used by cylinderSection
module cS(ir, or, h, a) {
    ex = 0.01;
    difference() {
        translate([0, 0, -h/2]) //simulate center=true
            rotate_extrude(angle=a) square([or, h]);
        cylinder(r=ir, h=h+ex, center=true);
    }
}
