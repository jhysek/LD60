shader_type canvas_item;

const int MAX_HOLES = 32 * 9;

uniform vec2 holes[MAX_HOLES];
uniform int hole_count = 0;
uniform float hole_radius = 6.0;

varying vec2 world_uv;

void vertex() {
    world_uv = VERTEX;
}

void fragment() {
	// calculate distance of current pixel to each hole
	// when the distance is lower than hole radius (i.e. pixel is inside a hole), set alpha to zero 
    for (int i = 0; i < hole_count; i++) {
        float distance_to_hole = distance(world_uv, holes[i]);

        if (distance_to_hole < hole_radius) {
            COLOR.a = 0.0;
            break;
        }
    }
}