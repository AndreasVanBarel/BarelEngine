#version 430 core

layout (local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout (rgba32f, binding = 0) uniform image2D out_tex; //must be the same format as in the host program
//layout (rgba32f, binding = 1) uniform image1D colormap; //color values to cycle through
uniform sampler1D colors;
layout (location = 0) uniform float t;    
layout (location = 1) uniform vec2 center;
layout (location = 2) uniform float scale;  
// center (0.0) and scale 1 give unit square
layout (location = 3) uniform int maxit;

layout (location = 4) uniform float p1;    
layout (location = 5) uniform float p2;    


void main() {
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);

    vec2 npos; //normalized position between 0.0 and 1.0
    npos.x = float(pos.x)/(gl_NumWorkGroups.x * gl_WorkGroupSize.x);
    npos.y = float(pos.y)/(gl_NumWorkGroups.y * gl_WorkGroupSize.y);

    //normalized position between  and 1
    npos.x = (npos.x*2-1.0)*scale + center.x;
	npos.y = (npos.y*2-1.0)*scale + center.y;

    vec2 c = npos;
    vec2 z = c;

    int i;
    for(i=0; i<maxit; i++) {
        // z^2 + c
        float z_real = (z.x * z.x - z.y * z.y) + c.x;
        float z_imag = (z.y * z.x + z.x * z.y) + c.y;

        // z^3 + c
        // float z_real = (z.x*z.x*z.x - 3*z.x*z.y*z.y) + c.x;
        // float z_imag = (3*z.x*z.x*z.y - z.y*z.y*z.y) + c.y;

        if((z_real * z_real + z_imag * z_imag) > 4.0) break;
        z.x = z_real;
        z.y = z_imag;
    }

    // float result = (i == maxit ? 0.0 : float(i)) / (maxit-1); // color result between 0 and 1
    // vec4 value = vec4(result, result, result, 1.0);

    float result = float(i) / 25;
    result = mod(log(result), 1.0); //result between 0.0 and 1.0

    result = p1 + (p2-p1)*result;

    vec4 value = i == maxit ? vec4(0.0,0.0,0.0,1.0) : texture(colors, result);

    imageStore(out_tex, pos, value);
}