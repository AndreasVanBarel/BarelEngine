#version 430 core

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout (r8ui, binding = 0) uniform readonly uimage2D in_tex; //must be the same format as in the host program
layout (binding = 1) uniform writeonly uimage2D out_tex; //must be the same format as in the host program
layout (binding = 2) uniform writeonly image2D show_tex;
// note uimage2D (there is also iimage2D for signed int)

void main() {
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy); //conway pixel to work on

    uint v0 = imageLoad( in_tex, pos ).r; // current value in the cell

    // note that out of bounds imageLoad returns 0
    uint v1 = imageLoad( in_tex, pos + ivec2(-1,-1) ).r;
    uint v2 = imageLoad( in_tex, pos + ivec2(-1,0) ).r;
    uint v3 = imageLoad( in_tex, pos + ivec2(-1,1) ).r;
    uint v4 = imageLoad( in_tex, pos + ivec2(0,-1) ).r;
    uint v5 = imageLoad( in_tex, pos + ivec2(0,1) ).r;
    uint v6 = imageLoad( in_tex, pos + ivec2(1,-1) ).r;
    uint v7 = imageLoad( in_tex, pos + ivec2(1,0) ).r;
    uint v8 = imageLoad( in_tex, pos + ivec2(1,1) ).r;

    uint sum = v1+v2+v3+v4+v5+v6+v7+v8;

    uint result = v0; // default no state change
    if (v0 == 1) { //live cell
        if (sum == 2 || sum == 3) {
            result = 1;
        } else {
            result = 0;
        }
    } else { //dead cell
        if (sum == 3) {
            result = 1;
        }
    }

    imageStore(out_tex, pos, uvec4(result,0,0,0));
    imageStore(show_tex, pos, vec4(float(result),float(result),float(result),1.0));

    // imageStore(out_tex, pos, uvec4(255,0,0,0));
}