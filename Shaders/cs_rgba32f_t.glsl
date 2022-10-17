#version 430 core

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout (rgba32f, binding = 0) uniform image2D out_tex; //must be the same format as in the host program
layout (location = 0) uniform float t;                

void main() {
    vec4 value = vec4(0.0, 0.0, 0.0, 1.0);
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);

    float width = gl_NumWorkGroups.x; // the width of the texture
    float speed = 0.25;

    value.x = mod(float(pos.x)/(gl_NumWorkGroups.x * gl_WorkGroupSize.x) + t * speed, 1.0);
    value.y = float(pos.y)/(gl_NumWorkGroups.y * gl_WorkGroupSize.y);
	
    imageStore(out_tex, pos, value);


    // get position to read/write data from
    // ivec2 pos = ivec2( gl_GlobalInvocationID.xy );    // get value stored in the image
    // float in_val = imageLoad( out_tex, pos ).r;    // store new value in image
    // imageStore( out_tex, pos, vec4( in_val + 1, 0.0, 0.0, 0.0 ) );
}