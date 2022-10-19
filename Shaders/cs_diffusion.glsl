#version 430 core

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout (rgba32f, binding = 0) uniform readonly image2D in_tex; //must be the same format as in the host program
layout (binding = 1) uniform writeonly image2D out_tex; //must be the same format as in the host program

layout (location = 2) uniform float mu; //diffusion coefficient, set to 0.0 for no diffusion
layout (location = 3) uniform float lambda; //decay coefficient, set to 0.0 for no decay
layout (location = 4) uniform float dt; //time spent

// NOTE: dt*mu should be between 0 and 1/5
void main() {
    float decay = exp(-lambda*dt);
    float diff = min(dt*mu, 0.2);

    ivec2 pos = ivec2(gl_GlobalInvocationID.xy); //pixel to work on

    vec4 in_vals = imageLoad(in_tex, pos);
    vec3 central = in_vals.rgb; // current value in the cell

    // note that out of bounds imageLoad returns 0
    vec3 left = imageLoad(in_tex, pos + ivec2(-1,0)).rgb;
    vec3 right = imageLoad(in_tex, pos + ivec2(1,0)).rgb;
    vec3 up = imageLoad(in_tex, pos + ivec2(0,1)).rgb;
    vec3 down = imageLoad(in_tex, pos + ivec2(0,-1)).rgb;

    vec3 sum = left+right+up+down;

    vec3 res = decay * ((1-4*diff)*central + diff*sum);

    imageStore(out_tex, pos, vec4(res,in_vals.a));
}